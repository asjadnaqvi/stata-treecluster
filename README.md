
![StataMin](https://img.shields.io/badge/stata-2015-blue) ![issues](https://img.shields.io/github/issues/asjadnaqvi/stata-treecluster) ![license](https://img.shields.io/github/license/asjadnaqvi/stata-treecluster) ![Stars](https://img.shields.io/github/stars/asjadnaqvi/stata-treecluster) ![version](https://img.shields.io/github/v/release/asjadnaqvi/stata-treecluster) ![release](https://img.shields.io/github/release-date/asjadnaqvi/stata-treecluster)

# treecluster v1.0 (beta)


## Installation

The package can be installed via SSC or GitHub. The GitHub version, *might* be more recent due to bug fixes, feature updates etc, and *may* contain syntax improvements and changes in *default* values. See version numbers below. Eventually the GitHub version is published on SSC.

SSC (****):

```
coming soon!
```

GitHub (**v1.0**):

```
net install treecluster, from("https://raw.githubusercontent.com/asjadnaqvi/stata-treecluster/main/installation/") replace
```



If you want to make a clean figure, then it is advisable to load a clean scheme. These are several available and I personally use the following:

```
ssc install schemepack, replace
set scheme white_tableau  
```

I also prefer narrow fonts in figures with long labels. You can change this as follows:

```
graph set window fontface "Arial Narrow"
```


## Syntax

The syntax for **v1.0** is as follows:

```
treecluster value [if] [in], by(variables) 
                [ smooth(num) radius(num) gap(num) polar cuts(num) scalefactor(num)
                  noscale share offset(num) laboffset(num) lcolor(str) lwidth(str)    
                  title(str) subtitle(str) note(str) scheme(str) name(str)
                  xsize(num) ysize(num) aspect(num) ]

```

See the help file `help treecluster` for details.

The most basic use is as follows:

```
treecluster value, by(variables)
```



## Examples

Load the Stata dataset

```
use "https://github.com/asjadnaqvi/stata-treecluster/blob/main/data/sunburst.dta?raw=true", clear
```

Let's test the `treecluster` command:


```
treecluster value, by(continent region country)
```

<img src="/figures/treecluster1.png" height="400">

```
treecluster value, by(continent region country) threshold(2000)
```

<img src="/figures/treecluster1_1.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000)
```

<img src="/figures/treecluster2.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000) noscale
```
<img src="/figures/treecluster3.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000) scalefac(0.1)
```
<img src="/figures/treecluster3_1.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000) gap(5) scalefac(0.1)
```

<img src="/figures/treecluster4.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000) gap(5) scalefac(0.1) smooth(8) 
```

<img src="/figures/treecluster5.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000) gap(5) scalefac(0.1) smooth(8) offset(0.7)
```

<img src="/figures/treecluster6.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000) gap(5) scalefac(0.1) smooth(8) radius(1 2 4 8) lc(eltblue)  offset(0.7)
```

<img src="/figures/treecluster7.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000) gap(5) scalefac(0.1) smooth(8) radius(1 2 4 8) lc(eltblue)  offset(1) xsize(4) ysize(5)
```

<img src="/figures/treecluster7_1.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000) gap(5) scalefac(0.1) smooth(8) radius(1 2 4 8) lc(eltblue)  offset(1) share xsize(4) ysize(5)
```

<img src="/figures/treecluster7_2.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000) gap(5) scalefac(0.1) smooth(8) radius(1 2 4 8) lc(eltblue) offset(0.7) share
```

<img src="/figures/treecluster8.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000) gap(2) scalefac(0.1) radius(1 2 4 6) lc(blue)share polar 
```

<img src="/figures/treecluster9.png" height="400">

```
treecluster value, by(world continent region country) threshold(2000) gap(5) scalefac(0.1)  radius(1 2 4 8) lc(blue%70) offset(0.3) laboffset(1.8) polar 
```

<img src="/figures/treecluster10.png" height="400">

Image for the banner

```
treecluster value, by(world continent region country) thresh(100) gap(2) scalefac(0.08) lc(maroon%90) offset(0) laboff(0) polar nolab mlcolor(maroon)
```

<img src="/figures/treecluster_banner.png" height="400">


## Feedback

Please open an [issue](https://github.com/asjadnaqvi/stata-treecluster/issues) to report errors, feature enhancements, and/or other requests.


## Versions

**v1.0 (30 Dec 2022)**
- Public release.







