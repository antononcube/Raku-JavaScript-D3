# JavaScript::D3 Raku package

This repository has the a Raku package for generation of JavaScript's D3 code for making plots and charts.

If the commands of this package are executed in 
[Jupyter notebook with Raku kernel](https://raku.land/cpan:BDUGGAN/Jupyter::Kernel)
properly 
[hacked to redirect Raku code to JavaScript backend](https://github.com/bduggan/p6-jupyter-kernel/issues/100)
then the generate JavaScript code would produce 
nice 
[D3.js](https://d3js.org)
plots or charts.  

See the Jupyter notebook 
["Tests-for-JavaScript-D3"](./resources/Tests-for-JavaScript-D3.ipynb)
for illustrative examples.

--------

## Mission statement

Make first class (beautiful, tunable, and useful) plots and charts in Raku using 
concise specifications.

--------

## Design and philosophy

*TBD...*

--------

## Alternatives

### Raku packages

The Raku packages "Text::Plot", [AAp1], and "SVG::Plot", [MLp1],
provide similar functionalities and both can be used in Jupyter notebooks. 
(Well, "Text::Plot" can be used anywhere.)

### Different backend

Instead of using [D3.js](https://d3js.org) as a "backend" it is possible -- and instructive --
to implement Raku plotting functions that generate JavaScript code for the library 
[Chart.js](https://www.chartjs.org).

D3.js is lower level than Chart.js, hence in principle Chart.js is closer to the mission of this Raku package.
I.e. at first I considered having Raku plotting implementations with Chart.js
(in a package called "JavaScript::Chart".)
But I had hard time making Chart.js plots work consistently within Jupyter.

--------

## TODO

In the lists below the highest priority items are placed first.

### Plots

#### Single dataset

1. [X] DONE List plot
3. [X] DONE List line plot
5. [ ] TODO Date list plot
7. [ ] TODO Box plot

#### Multiple dataset

1. [ ] TODO List plot
2. [X] TODO List line plot
3. [ ] TODO Date list plot 
4. [ ] TODO Box plot 

### Charts

#### Single dataset

1. [X] DONE Bar chart
2. [X] DONE Histogram 
3. [X] DONE Bubble chart
4. [ ] TODO Density 2D chart -- rectangular bins
5. [ ] TODO Radar chart 
6. [ ] TODO Density 2D chart -- hexagonal bins
7. [ ] TODO Pie chart

#### Multiple dataset

1. [ ] TODO Bar chart
2. [ ] TODO Histogram
3. [X] DONE Bubble chart
4. [X] DONE Bubble chart with tooltips
5. [ ] TODO Pie chart 
7. [ ] TODO Radar chart

### Decorations

User specified or automatic:

1. [X] DONE Plot label / title
2. [X] DONE Axes labels
3. [X] DONE Plot margins
4. [X] DONE Plot legends (automatic for multi-datasets plots and chart)
5. [ ] TODO Title style (font size, color, face)
6. [ ] TODO Axes labels style (font size, color, face)

### Infrastructural

1. [ ] TODO Support for different JavaScript wrapper styles
  
   - Jupyter cell execution ready
   
   - Standard HTML
   
   - Result output within a JSON format

2. [ ] JavaScript code snippets management

   - If they become too many

--------

## References

### Articles

[OV1] Olivia Vane, 
["D3 JavaScript visualisation in a Python Jupyter notebook"](https://livingwithmachines.ac.uk/d3-javascript-visualisation-in-a-python-jupyter-notebook), 
(2020), 
[livingwithmachines.ac.uk](https://livingwithmachines.ac.uk).

[SF1] Stefaan Lippens, 
[Custom D3.js Visualization in a Jupyter Notebook](https://www.stefaanlippens.net/jupyter-custom-d3-visualization.html), 
(2018), 
[stefaanlippens.net](https://www.stefaanlippens.net).

### Packages

[AAp1] Anton Antonov,
[Text::Plot Raku package](https://raku.land/zef:antononcube/Text::Plot),
(2022),
[GitHub/antononcube](https://github.com/antononcube/Raku-Text-Plot).

[MLp1] Moritz Lenz,
[SVG::Plot Raku package](https://github.com/moritz/svg-plot)
(2009-2018),
[GitHub/moritz](https://github.com/moritz/svg-plot).
