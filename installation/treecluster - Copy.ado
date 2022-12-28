*! treecluster v1.0 30 Dec 2022. Beta release.
*! Asjad Naqvi 


cap program drop treecluster

program treecluster, // sortpreserve

version 15
 
	syntax varlist(numeric max=1) [if] [in], by(varlist) ///
		[ smooth(numlist >=1 <=8) gap(real 2) offset(real 0.20) polar ] ///
		[ RADius(numlist) palette(string) colorby(string) THRESHold(numlist max=1 >=0) share format(str) LABCONDition(string) ]   ///
		[ LWidth(numlist) LColor(string) LABSize(numlist)  ]   ///
		[ legend(passthru) title(passthru) subtitle(passthru) note(passthru) scheme(passthru) name(passthru) text(passthru) xsize(passthru) ysize(passthru) ] 
		
	
		
	// check dependencies
	cap findfile colorpalette.ado
	if _rc != 0 {
		display as error "The palettes package is missing. Install the {stata ssc install palettes, replace:palettes} and {stata ssc install colrspace, replace:colrspace} packages."
		exit
	}
	
	marksample touse, strok
	
	

*qui {
*preserve		
	keep if `touse'
	keep `varlist' `by'
	drop if `varlist'==. |  `varlist'==0
	
	
	//////////////////////
	// prepare the data //
	//////////////////////
	
	local len : word count `by'   				// number of variables
	
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
		forval i = 0/`len' {
			local autorad = 1 + `i'  		// define an autogap of 1
			local radius `radius' `autorad'  
		}
	}
	
	local radlen : word count `radius'   // number of variables
	local target = `len' + 1
	
	// radius error checks
	if "`radius'"!="" {
		if `radlen' < `target' {
			di as error "For `len' variables, `target' radii need to be defined."
			exit
		}
		
		local raderror = 0	
		forval i = 2/`target' {
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
	forval i = 0/`len' {
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
		
		gen x`i' = `i' - `switch' // x axis
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
	local newobs = 60		
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
			
			gen px`i' = x`i'norm * cos(angle`i')
			gen py`i' = x`i'norm * sin(angle`i')
		}
		
		// scatters
		forval i = 1/`len' {
			gen cang`i' = cuts`i'	* 2 * _pi	if tag`i' ==1 & tagid==1
			
			gen cx`i' = x`i' * cos(cang`i')
			gen cy`i' = x`i' * sin(cang`i') 
		
		
		gen quad`i' = .  // quadrants
			replace quad`i' = 1 if cx`i' >= 0 & cy`i' >= 0 & tag`i'==1 & tagid==1
			replace quad`i' = 2 if cx`i' <  0 & cy`i' >= 0 & tag`i'==1 & tagid==1
			replace quad`i' = 3 if cx`i' <  0 & cy`i' <  0 & tag`i'==1 & tagid==1
			replace quad`i' = 4 if cx`i' >= 0 & cy`i' <  0 & tag`i'==1 & tagid==1			

	
		gen ang`i' = .
			replace ang`i' = (cang`i' * (180 / _pi)) - 180 if quad`i' ==1
			replace ang`i' = (cang`i' * (180 / _pi))       if quad`i' ==2
			replace ang`i' = (cang`i' * (180 / _pi))       if quad`i' ==3
			replace ang`i' = (cang`i' * (180 / _pi)) - 180 if quad`i' ==4

		}
		
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
			gen varstr`i' = var`i' + " (" + string(val`i' , "`format'") + ")"  if tag`i'==1 & tagid==1
		}
		else {
			gen share`i' = (val`i' / val0) * 100  if tag`i'==1 & tagid==1
			gen varstr`i' = var`i' + " (" + string(share`i', "`format'") + "%)"  if tag`i'==1 & tagid==1
		}
	}	
	
	//////////
	// draw //
	//////////
	
	
	// lines
	forval i = 2/`len' {
		if "`polar'" == "" {
			local trees `trees' (line y`i'norm x`i'norm, cmissing(n) lw(0.2) lc(gs8))
		}
		else {
			local trees `trees' (line py`i' px`i', cmissing(n) lw(0.2) lc(gs8))			
		}
	}
	
	
	// dots
	if "`polar'" == "" {	
		forval i = 1/`second' {
			local dots `dots' (scatter cuts`i' x`i' if tag`i' ==1 & tagid==1, msym(O) mc(white) mlc(gs3) msize(1) mlabsize(1.3) mlab(varstr`i') mlabpos(1))
		}
	
		local dots `dots' (scatter cuts`len' x`len' if tag`len' ==1 & tagid==1, msym(O) mc(white) mlc(gs3) msize(1) mlab(varstr`len') mlabsize(1.3) mlabpos(3))
	}
	else {
		forval i = 1/`second' {
			local dots `dots' (scatter cy`i' cx`i' if tag`i' ==1 & tagid==1, msym(O) mc(white) mlc(gs3) msize(1) mlabsize(1.3) mlab(varstr`i') mlabpos(1))
		}
	
		local dots `dots' (scatter cy`len' cx`len' if tag`len' ==1 & tagid==1, msym(O) mc(white) mlc(gs3) msize(1) mlab(varstr`len') mlabsize(1.3) mlabpos(3))		
	}
	
	
	// add the range variable on the x-axis	
	
	if "`polar'" == "" {
		summ x1, meanonly
		local xrmin = r(min)
		
		summ x`len', meanonly	
		local xrmax = r(max) 
		
		local diff = (`xrmax' - 0) * `offset'
		local xrmin = `xrmin' - 0.05
		local xrmax = `xrmax' + `diff'
		
		local yrmin = 0
		local yrmax = 1
		
	}
	else {
		summ cx`len', meanonly
		local xrmax = r(max) * (1 + `offset' / 100)
		local xrmin = -1 * `xrmax'
		
		local yrmax = `xrmax'
		local yrmin = `xrmin'
		
	}
	
	
	***** FINAL PLOT *****
	
	
	twoway ///
		`trees' ///
		`dots'	///
		, ///
		legend(off) ///
		xtitle("") ytitle("") ///
		yscale(noline range(`yrmin' `yrmax')) ///
		xscale(noline range(`xrmin' `xrmax'))   ///
		ylabel(, nolabels noticks nogrid) ///
		xlabel(, nolabels noticks nogrid) ///
		`title' `subtitle' `note' `scheme' `xsize' `ysize' `name'
*/
*restore	
*}

end

*********************************
******** END OF PROGRAM *********
*********************************


