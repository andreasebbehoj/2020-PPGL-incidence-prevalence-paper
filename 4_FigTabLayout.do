***** 4_FigTabLayout.do *****

***** Graphs
** General
set scheme s2color
grstyle init graphlayout, replace
grstyle set plain // No plot region color, white background + other tweaks

** Size
grstyle set graphsize 560pt 1200pt // in pixels, default is 5.5 inches *72 pt/inch = 396pt
grstyle set symbolsize small
grstyle set size 25pt: axis_title // X and Y axis text size

** Axis
grstyle anglestyle vertical_tick horizontal // Horizontal "tick"text on y-axis
grstyle color major_grid gs11 // colour of horizontal lines

** Legend
grstyle set legend ///
	10, /// clock position of legend (1-12).
	nobox /// no legend background
	inside // inside plotregion

** Colors
* Graphs with 1 color
global color1 = "black"

* Graphs with 2 colors
global color2_1 = "navy"
global color2_2 = "green"

* Graphs with 4 colors
global color4_1 = "navy"
global color4_2 = "green"
global color4_3 = "orange"
global color4_4 = "gs9"

* Graphs with 5 colors
global color5_1 = "navy"
global color5_2 = "green"
global color5_3 = "orange"
global color5_4 = "sienna"
global color5_5 = "gs9"

* Graphs with 8 colors
global color8_1 = "navy"
global color8_2 = "green"
global color8_3 = "orange"
global color8_4 = "sienna"
global color8_5 = "olive_teal"
global color8_6 = "lavender"
global color8_7 = "sandb"
global color8_8 = "gs9"


** Export
graph set eps logo off
global exportformat = ".png"
global exportoptions = ", replace width(1200)"


***** Tables
global tablecells =  `"border(all, nil) halign(center)"'
global tablefirstrow = `"border(bottom, single) bold shading(191 191 191)"' // First row bold, underlined and dark gray
global tablerows = `"shading(217 217 217)"' // Remaining subheaders light grey
global tablefirstcol = `"halign(left)"'
