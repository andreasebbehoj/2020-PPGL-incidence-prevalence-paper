***** Pheo-inci_FigTabLayout.do *****

***** Graphs
** General
set scheme s2color
grstyle init graphlayout, replace
grstyle set plain // No plot region color, white background + other tweaks

* Size 
grstyle set graphsize 560pt 1200pt // in pixels, default is 5.5 inches *72 pt/inch = 396pt
grstyle set symbolsize small
grstyle set size 25pt: axis_title // X and Y axis text size

* Axis
grstyle anglestyle vertical_tick horizontal // Horizontal "tick"text on y-axis
grstyle color major_grid gs11 // colour of horizontal lines

* Legend
grstyle set legend ///
	10, /// clock position of legend (1-12).
	nobox /// no legend background
	inside // inside plotregion

* Colors
global colour1 = "navy" 
global colour2 = "gs9" 
global colour3 = "gs12" 

* Export
graph set eps logo off
global exportformat = ".png" 
global exportoptions = ", replace width(1200)"


***** Tables
global tableoverall =  `"border(all, nil) halign(center)"'
global tablefirstrow = `"border(bottom, single) bold shading(191 191 191)"' // First row bold, underlined and dark gray
global tablerows = `"shading(217 217 217)"' // Remaining rows light grey
global tablefirstcol = `"halign(left)"'