*! treecluster v1.0 30 Dec 2022. Beta release.
*! Asjad Naqvi 


cap program drop treecluster

program treecluster, // sortpreserve

version 15
 
	syntax varlist(numeric max=1) [if] [in], by(varlist) ///
		[ smooth(numlist max=1 >=1 <=8) gap(real 2) OFFset(real 0.3) polar NOSCale cuts(real 50) SCALEFACtor(real 0.15) Points(real 80)  ] ///
		[ RADius(numlist) THRESHold(numlist max=1 >=0) share format(str) LABOFFset(string) NOLABel ]   ///
		[ LColor(string) LABSize(string) msize(string) MColor(string) MLWidth(string) MSYMbol(string) MLColor(string) ]   ///
		[ legend(passthru) title(passthru) subtitle(passthru) note(passthru) scheme(passthru) name(passthru) text(passthru) xsize(numlist max=1 >0) ysize(numlist max=1 >0) aspect(passthru) ] 
		
	
		
	// check dependencies
	/*
	cap findfile colorpalette.ado
	if _rc != 0 {
		display as error "The palettes package is missing. Install the {stata ssc install palettes, replace:palettes} and {stata ssc install colrspace, replace:colrspace} packages."
		exit
	}
	*/
	
	marksample touse, strok
	
	

qui {
preserve		
	keep if `touse'
	keep `varlist' `by'
	drop if `varlist'==. |  `varlist'==0
	
	
	//////////////////////
	// prepare the data //
	//////////////////////
	
	local len : word count `by'   				// number of variables
	
	if `len' <= 1 {
		di as error "At least two {it:by()} variables need to be specified."
		exit
	}
	
	if `len' > 1 local second = `len' - 1    	// second last variable

	foreach v of local by {
		if substr("`: type `v''",1,3) != "str" {
			if "`: value label `v' '" != "" { 	// has value label
				decode `v', gen(`v'_temp)
				drop `v'
				ren `v'_temp `v'
			}
			else {								// has no value label
				gen `v'_temp = string(`v')
				drop `v'
				ren `v'_temp `v'
			}
		}
	}

	cap ren `varlist' value
	
	tokenize "`by'"
	
	forval i = 1/`len' {
		ren ``i'' var`i'
		local vars `vars' var`i'
	}

	local last : word `len' of `vars'     				// last variable
	if `len' > 1 local sec  : word `second' of `vars'  	// second last variable	
	
	
	// define a radius 
	if "`radius'"=="" {
		forval i = 1/`len' {
			local autorad = `i'  		// define an autogap of 1
			local radius `radius' `autorad'  
		}
	}
	
	local radlen : word count `radius'   // number of variables
	
	// radius error checks
	if "`radius'"!="" {
		if `radlen' != `len' {
			di as error "For `len' variables, `len' radii need to be defined."
			exit
		}
		
		local raderror = 0	
		forval i = 2/`len' {
			local j = `i' - 1
			
			local a : word `i' of `radius'
			local b : word `j' of `radius'
			
			if `a' < `b' {
				local raderror = 1
				break
			}
		}
		
		if `raderror' == 1 {
			di as error "The radius order is not correctly specified."
			exit
		}
	}
	
	// pass on as lists	
	forval i = 1/`len' {
		local rad `rad' rad`i'  
	}

	tokenize `radius'
	args `rad'
			
	// and move on	
	if "`threshold'"=="" local threshold = 0
	
	if `len' > 1 {  // only if there is more than one layer, then collpse categories
		gen tag`sec' = .
		levelsof `sec' , local(lvls)

		foreach x of local lvls {
			replace tag`sec' = 1 if `sec'=="`x'" & value < `threshold'
			replace `last' = "Rest of `x'" if tag`sec'==1 &  `sec' =="`x'"
		}
	}
	
	collapse (mean) value, by(`vars')

	gen var0 = "Total"
	egen double val0 = sum(value)  // global total

	if `len' > 1 {
		forval i = 1/`second' {   
			local j = `i' - 1
			bysort var`j' var`i' : egen double val`i' = sum(value)
		}
	}

	ren value val`len'  // individual total
	order var* val*
		
	local lclvar
	forval i = 1/`len' {
		local lclvar `lclvar' var`i'
		
		di "`lclvar'"
		egen grp`i' = group(`lclvar')
		egen tag`i' = tag(`lclvar')
	}
	
	// if there is a category with a grand total, then shift x to zero for polars
	
	local switch = 0
	sum tag1, meanonly
	if r(sum) == 1 local switch = 1
	
	
	local j = 0
	local mysum = 0

	forval i = 1/`len' {
		summ tag`i', meanonly
		if r(sum) > `mysum' {
			local mysum = r(sum)
			local j = `i'
		}
		
		gen x`i' = `rad`i'' - `switch' // x axis
	}	
	

	
	// split the highest grp into equal intervals between 0 and 1

	local lclvar

	*tempvar cuts
	gen double cuts = _n / `mysum'
	replace cuts = cuts + (grp`second' - 1) * `gap' / 100 
	summ cuts, meanonly
	replace cuts = cuts / r(max)
	

	gen double cuts`j' = cuts
	
	// the smaller layer determines the parents position.

	forval i = 2/`len' {
		local j = `len' - `i' + 1 // reverse
		local k = `j' + 1
		
		bysort grp`j': egen double cuts`j' = mean(cuts`k') if tag`k'==1
	}

	drop grp*	
	
	
	gen id = _n
	order id		

	
	// get a generic sigmoid in place	
	local newobs = `points'		
	expand `=`newobs' + 1'
	bysort id: gen seq = _n

	*** for the sigmoid box
		
	cap drop xnorm
	bysort id: gen double xnorm =  ((_n - 1) / (`newobs' - 1)) // scale from 0 to 1
	replace xnorm = . if seq==`=`newobs' + 1'


	if "`smooth'" == "" local smooth = 4
	cap drop ynorm
	gen double ynorm =  (1 / (1 + (xnorm / (1 - xnorm))^-`smooth'))

	// fill in the indeterminate points
	replace ynorm = 0 if seq==1
	replace ynorm = 1 if seq==`newobs'	
	
		
	forval i = 2/`len' {
		local j = `i' - 1
		
		
		gen double x`i'norm = .
		gen double y`i'norm = .
		
		
		levelsof id if tag`i'==1 , local(lvls)	
			
		foreach x of local lvls {
			
				// x
				summ x`j' if id==`x'  & tag`i'==1 , meanonly
				local xmin = r(min)
				summ x`i' if id==`x'  & tag`i'==1 , meanonly
				local xmax = r(max)
				replace x`i'norm = (`xmax' - `xmin') * (xnorm - 0) / (1 - 0) + `xmin'  if id==`x'  & tag`i'==1
				
				// y
				summ cuts`j' if id==`x'  & tag`i'==1 , meanonly
				local ymin = r(min)
				summ cuts`i' if id==`x'  & tag`i'==1 , meanonly
				local ymax = r(max)
				replace y`i'norm = (`ymax' - `ymin') * (ynorm - 0) / (1 - 0) + `ymin'  if id==`x'  & tag`i'==1
			
		}	
			
	}	
	
	egen tagid = tag(id) // to avoid overdoing the results
	

	
	// transform if polar is specified
	if "`polar'" != "" {
	
		// layers
		forval i = 2/`len' {
			gen double angle`i' = y`i'norm * 2 * _pi
			
			gen double px`i' = x`i'norm * cos(angle`i')
			gen double py`i' = x`i'norm * sin(angle`i')
			

		}
		
		// scatters
		
		if "`laboffset'" == "" local laboffset = 1.5
		
		forval i = 1/`len' {
			gen double cang`i' = cuts`i'	* 2 * _pi	if tag`i' ==1 & tagid==1
			
			gen double cx`i' = x`i' * cos(cang`i')
			gen double cy`i' = x`i' * sin(cang`i') 
			
			if `i' == `len' {
				gen double labx`i' = (x`i' + `laboffset') * cos(cang`i')
				gen double laby`i' = (x`i' + `laboffset') * sin(cang`i')
			}		
		
		gen quad`i' = .  // quadrants
			replace quad`i' = 1 if cx`i' >= 0 & cy`i' >= 0 & tag`i'==1 & tagid==1
			replace quad`i' = 2 if cx`i' <  0 & cy`i' >= 0 & tag`i'==1 & tagid==1
			replace quad`i' = 3 if cx`i' <  0 & cy`i' <  0 & tag`i'==1 & tagid==1
			replace quad`i' = 4 if cx`i' >= 0 & cy`i' <  0 & tag`i'==1 & tagid==1			

	
		gen ang`i' = .
			replace ang`i' = (cang`i' * (180 / _pi)) 		if quad`i' ==1
			replace ang`i' = (cang`i' * (180 / _pi)) - 180 	if quad`i' ==2
			replace ang`i' = (cang`i' * (180 / _pi)) - 180 	if quad`i' ==3
			replace ang`i' = (cang`i' * (180 / _pi))		if quad`i' ==4

		}
		
	}
	
	// split lines into weight groups

	local minval = 0	
	local maxval = 0

	forval i = 1/`len' {
		summ val`i' if tag`i'==1 & tagid==1 , meanonly
		if r(min) < `minval' local minval = r(min)
		if r(max) > `maxval' local maxval = r(max)
	}
		
	di "Highest value = `maxval'"	
		
	local lastval = `maxval' * 1.01 // to avoid precision errors
	local delta = (`lastval' - `minval') / `cuts'
	

	forval i = 1/`len' {
		egen scale`i' = cut(val`i'), at(`minval'(`delta')`lastval') icode
		replace scale`i' = scale`i' + 1				
	}		
	
	
	// generate the labels
	if "`format'"== "" {
		if "`share'" == "" {
			local format %9.0fc
		}		
		else {			
			local format %5.2f
		}
	}
		
	forval i = 1/`len' {
		if "`share'" == "" {
			if "`nolabel'" == "" {
				gen varstr`i' = var`i' + " (" + string(val`i' , "`format'") + ")"  if tag`i'==1 & tagid==1
			}
			else {
				gen varstr`i' = ""
			}
		}
		else {
			gen double share`i' = (val`i' / val0) * 100  if tag`i'==1 & tagid==1
			if "`nolabel'" == "" {
				gen varstr`i' = var`i' + " (" + string(share`i', "`format'") + "%)"  if tag`i'==1 & tagid==1
			}
			else {
				gen varstr`i' = ""
			}
			
		}
	}	
	
	//////////
	// draw //
	//////////
	
	if "`lcolor'" == "" local lcolor gs8
	
	// lines
	forval i = 2/`len' {
		if "`polar'" == "" {
			if "`noscale'"!= "" {
				local trees `trees' (line y`i'norm x`i'norm, cmissing(n) lw(0.2) lc(`lcolor'))
			}
			else {
				levelsof scale`i', local(scales)
				foreach j of local scales {
					summ scale`i' if scale`i'==`j', meanonly
					local width = r(mean) * `scalefactor'
					local trees `trees' (line y`i'norm x`i'norm if scale`i'==`j' , cmissing(n) lw(`width') lc(`lcolor'))					
				}
			}
		}
		else {
			if "`noscale'"!= "" {
				local trees `trees' (line py`i' px`i', cmissing(n) lw(0.2) lc(`lcolor'))		
			}
			else {
				levelsof scale`i', local(scales)
				foreach j of local scales {
					summ scale`i' if scale`i'==`j', meanonly
					local width = r(mean) * `scalefactor'
					local trees `trees' (line py`i' px`i' if scale`i'==`j' , cmissing(n) lw(`width') lc(`lcolor'))					
				}				
			}
		}
	}
	
	
	// dots and labels
	
	if "`labsize'" 	== "" local labsize 1.3
	if "`msize'"  	== "" local msize 	1
	if "`msymbol'"	== "" local msymbol O
	if "`mcolor'"	== "" local mcolor white
	if "`mlcolor'"	== "" local mlcolor gs3

	
	if "`polar'" == "" {	
		forval i = 1/`second' {
			local dots `dots' (scatter cuts`i' x`i' if tag`i' ==1 & tagid==1, msym(`msymbol') mc(`mcolor') mlc(`mlcolor') msize(`msize') mlwidth(`mlwidth') mlabsize(`labsize') mlab(varstr`i') mlabpos(1))
		}
	
		local dots `dots' (scatter cuts`len' x`len' if tag`len' ==1 & tagid==1, msym(`msymbol') mc(`mcolor') mlc(`mlcolor') msize(`msize') mlwidth(`mlwidth') mlab(varstr`len') mlabsize(`labsize') mlabpos(3))
	}
	else {
		forval i = 1/`second' {
			local dots `dots' (scatter cy`i' cx`i' if tag`i' ==1 & tagid==1, msym(`msymbol') mc(`mcolor') mlc(`mlcolor') msize(`msize') mlwidth(`mlwidth') mlabsize(`labsize') mlab(varstr`i') mlabpos(1))
		}
	
		local dots `dots' (scatter cy`len' cx`len' if tag`len' ==1 & tagid==1, msym(`msymbol') mc(`mcolor') mlwidth(`mlwidth') mlc(`mlcolor') msize(`msize'))		
		
		levelsof id if tag`len'==1 & tagid==1, local(lvls)

		// deal w the labels	
		
		if "`nolabel'" == "" {	
			foreach x of local lvls {
				summ ang`len' if id==`x' & tag`len'==1 & tagid==1, meanonly
				local labs `labs' (scatter laby`len' labx`len' if id==`x' & tag`len'==1 & tagid==1  , msym(none) mlabsize(`labsize') mlab(varstr`len') mlabangle(`r(mean)') mlabpos(0) ) // & inlist(quad`len',1,4)

			}
		}
		
		
		
	}
	
	
	// add the range variable on the x-axis	
	
	if "`polar'" == "" {
		summ x1, meanonly
		local xrmin = r(min)
		
		summ x`len', meanonly	
		local xrmax = r(max) 
		
		*local diff = (`xrmax' - `xrmin') + `offset'
		local xrmin = `xrmin' - 0.02
		local xrmax = `xrmax' + `offset'
		
		local yrmin = 0
		local yrmax = 1
		
	}
	else {
		summ labx`len', meanonly
		local xrmax = r(max) + `offset'
		local xrmin = -1 * `xrmax'
		
		local yrmax = `xrmax'
		local yrmin = `xrmin'
		
		if "`xsize'" == "" local xsize = 1
		if "`ysize'" == "" local ysize = 1
	}
	
	
	***** FINAL PLOT *****
	
	
	twoway ///
		`trees' ///
		`dots'	///
		`labs'  ///
		, ///
		legend(off) ///
		xtitle("") ytitle("") ///
		yscale(noline range(`yrmin' `yrmax')) ///
		xscale(noline range(`xrmin' `xrmax'))   ///
		ylabel(`yrmin' `yrmax', nolabels noticks nogrid) ///
		xlabel(`xrmin' `xrmax', nolabels noticks nogrid) ///
		`title' `subtitle' `note' `scheme' xsize(`xsize') ysize(`ysize') `aspect' `name'

restore	
}


end

*********************************
******** END OF PROGRAM *********
*********************************


