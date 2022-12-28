{smcl}
{* 30December2022}{...}
{hi:help treecluster}{...}
{right:{browse "https://github.com/asjadnaqvi/stata-treecluster":treecluster v1.0 (GitHub)}}

{hline}

{title:treecluster}: A Stata package for plotting clustered trees.

{p 4 4 2}
The command plots heirarchical data in a tree cluster layout. The last layer determines the placement of higher tier "parent" layers.
The tree layout can be switched between horizontal Cartesian and circular Polar coodinates. 

{p 4 4 2}
The command is still {it:beta} and is subject to change and improvements. Please regularly check the {browse "https://github.com/asjadnaqvi/stata-treecluster":GitHub} page for version changes and updates.


{marker syntax}{title:Syntax}
{p 8 15 2}

{cmd:treecluster} {it:value} {ifin}, {cmd:by}({it:variables}) 
                {cmd:[} {cmd:smooth({it:num})} {cmdab:rad:ius}({it:num}) {cmd:gap({it:num})} {cmd:polar} {cmd:cuts({it:num})} {cmdab:scalefac:tor}({it:num})
                  {cmdab:nosc:ale} {cmd:share} {cmdab:off:set}({it:num}) {cmdab:laboff:set}({it:num}) {cmdab:lc:olor}({it:str}) {cmdab:lw:idth}({it:str})    
                  {cmd:title}({it:str}) {cmd:subtitle}({it:str}) {cmd:note}({it:str}) {cmd:scheme}({it:str}) {cmd:name}({it:str}) {cmdab:nolab:el}
                  {cmd:xsize({it:num})} {cmd:ysize({it:num})} {cmd:aspect}({it:num}) {cmd:]}

{p 4 4 2}


{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}

{p2coldent : {opt treecluster value, by(vars)}}The command requires a numerical {it:value} variable, plotted over a sequence of heirarchical variables defined by {opt by()}.
The option {opt by()} should be specified from higher grouping category to finer categories. If there are imperfect overlaps across {opt by()} layers, then lower tier layers
will be split based on higher tier layers. Currently, there is no limit to the number of layers that can be specified. More complex layer combinations will result in longer processing times.{p_end}

{p2coldent : {opt smooth(1-8)}}The smooth option determines the shape of the line links. A value of 1 is a straight light, while 8 is a stepwise line.
Middle values of 3-5 represent S-shaped logistic curves.{p_end}

{p2coldent : {opt rad:ius(numlist)}}The gaps on the x-axis or radii can be manually specified here for fine tuning. Note that the number of radii should be exactly equal to the
the number of {opt by()} variables. If no option is specified, then the command will automatically use radius increments of 1.{p_end}

{p2coldent : {opt gap(num)}}The gap option defines the gaps between the layer groups. The number is a percentage of the y-axis length. The default value is {opt gap(2)} for 2%.{p_end}

{p2coldent : {opt polar}}This option converts the graph into a circular polar plot laid out in a circle.{p_end}

{p2coldent : {opt cuts(num)}}lines are split into equally-spaced intervals based on the highest value. The cuts are used as weights for line widths.
Higher value categories are drawn thicker than lower value categories. The default value is {opt cuts(50)}.{p_end}

{p2coldent : {opt scalefac:tor(num)}}This option can be used to scale the line widths. A lower value implies thinner lines. The default option is {opt scalefac(0.15)}.{p_end}

{p2coldent : {opt nosc:ale}}This option simply draws unweighted lines and is definitely much faster than generating scaled connections.{p_end}

{p2coldent : {opt share}}Show shares (0-100) rather than values in layer labels. Shares add up to 100 for each {opt by()} layer.{p_end}

{p2coldent : {opt thresh:old(value)}}The cut-off value below which the values are collapsed into one group, and labeled as "Rest of ...". This option is highly useful if
there are a lot of very small barely-discernible categories. Default is {opt thresh(0)}.{p_end}

{p2coldent : {opt format(str)}}Format the displayed values. Default for standard values is {opt format(%9.0fc)} and for shares it is {opt format(%5.2f)}.{p_end}

{p2coldent : {opt offset(num)}}This option is the value by which the x-axis should be extended. 
This option is used to accmmodate the labels of the last category. The default value is {opt offset(0.3)}.{p_end}

{p2coldent : {opt laboffset(num)}}This option is a the percentage share of the x-axis width of the last category width by which the labels should be extended. 
The default value is {opt laboffset(2)} for 2%.{p_end}

{p2coldent : {opt lc:olor(str)}}This line colors. The default value is {opt lc(gs13)}.{p_end}

{p2coldent : {opt labs:ize(str)}}This size of the value labels. The default value is {opt labs(1.3)}.{p_end}

{p2coldent : {opt msym:bol(str)}}The marker symbol. The default value is {opt msym(O)} for a circle.{p_end}

{p2coldent : {opt msize(str)}}The marker size. The default value is {opt msize(1)}.{p_end}

{p2coldent : {opt mc:olor(str)}}The marker color. The default value is {opt mc(white)}.{p_end}

{p2coldent : {opt mlc:olor(str)}}The marker outline color. The default value is {opt mc(gs3)}.{p_end}

{p2coldent : {opt mlw:idth(str)}}The marker outline width.{p_end}

{p2coldent : {opt nolab:el}}Turn off all labels. Mostly to create aesthetically-pleasing minimal layouts.{p_end}

{p2coldent : {opt p:oints(num)}}Number of points for evaluating the line curves. This option usually does not need to be touched unless a very high resolution image needs to be drawn.
In this case, the number of evaluation points should be increased. 
The default value is {opt p(80)}.{p_end}

{p2coldent : {opt xsize()}, {opt ysize()}, {opt aspect()}}These options can be used to finetune graphs. For polar, the options are set equal to 1 each.{p_end}

{p2coldent : {opt title()}, {opt subtitle()}, {opt note()}, {opt name()}}These are standard twoway graph options.{p_end}

{synoptline}
{p2colreset}{...}


{title:Dependencies}

The {browse "http://repec.sowi.unibe.ch/stata/palettes/index.html":palette} package (Jann 2018) is required for {cmd:sunburst}:

{stata ssc install palettes, replace}
{stata ssc install colrspace, replace}

Even if you have these installed, it is highly recommended to update the dependencies:
{stata ado update, update}

{title:Examples}

See {browse "https://github.com/asjadnaqvi/stata-sunburst":GitHub} for examples.



{hline}

{title:Version history}

- {bf:1.0} : First version.


{title:Package details}

Version      : {bf:treecluster} v1.0
This release : 30 Dec 2022
First release: 30 Dec 2022
Repository   : {browse "https://github.com/asjadnaqvi/stata-treecluster":GitHub}
Keywords     : Stata, graph, clustered trees
License      : {browse "https://opensource.org/licenses/MIT":MIT}

Author       : {browse "https://github.com/asjadnaqvi":Asjad Naqvi}
E-mail       : asjadnaqvi@gmail.com
Twitter      : {browse "https://twitter.com/AsjadNaqvi":@AsjadNaqvi}


{title:Acknowledgements}



{title:Feedback}

Please submit bugs, errors, feature requests on {browse "https://github.com/asjadnaqvi/stata-treecluster/issues":GitHub} by opening a new issue.

{title:References}


{title:Other visualization packages}

{psee}
    {helpb sunburst}, {helpb sankey}, {helpb alluvial}, {helpb circlebar}, {helpb spider}, {helpb treemap}, {helpb circlepack}, {helpb arcplot},
	{helpb marimekko}, {helpb bimap}, {helpb joyplot}, {helpb streamplot}, {helpb delaunay}, {helpb clipgeo},  {helpb schemepack}

