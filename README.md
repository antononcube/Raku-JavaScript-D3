# JavaScript::D3 Raku package

[![SparrowCI](https://ci.sparrowhub.io/project/gh-antononcube-Raku-JavaScript-D3/badge)](https://ci.sparrowhub.io)

This repository has the Raku package for generation of 
[JavaScript's D3](https://d3js.org/what-is-d3) 
code for making plots and charts.

This package is intended to be used in Jupyter notebooks with the
[Raku kernel implemented by Brian Duggan](https://github.com/bduggan/raku-jupyter-kernel), [BD1], or
["Jupyter::Chatbook"](https://github.com/antononcube/Raku-Jupyter-Chatbook), [AAp4].
The commands of the package generate JavaScript code that produces (nice) [D3.js](https://d3js.org/) plots or charts.
See the video [AAv1].

The package JavaScript graphs can be also included in HTML and Markdown documents.
See the videos [AAv2, AAv3].

For illustrative examples see the Jupyter notebook
["Tests-for-JavaScript-D3"](https://nbviewer.org/github/antononcube/Raku-JavaScript-D3/blob/main/resources/Tests-for-JavaScript-D3.ipynb).

The (original versions of the) JavaScript snippets used in this package are (mostly) taken from
["The D3.js Graph Gallery"](https://d3-graph-gallery.com/index.html).

Here is a corresponding video demo (≈7 min): ["The Raku-ju hijack hack of D3.js"](https://www.youtube.com/watch?v=YIhx3FBWayo) (≈ 7 min.)

And here is the demo notebook:
["The-Raku-ju-hijack-hack-for-D3.js-demo"](https://nbviewer.org/github/antononcube/Raku-JavaScript-D3/blob/main/resources/The-Raku-ju-hijack-hack-for-D3.js-demo.ipynb).

--------

## Mission statement

Make first class -- beautiful, tunable, and useful -- plots and charts with Raku using 
concise specifications.

--------

## Design and philosophy

Here is a list of guiding design principles:

- Concise plot and charts specifications.

- Using Mathematica's plot functions for commands signatures inspiration. 
  (Instead of, say, R's ["ggplot2"](https://ggplot2.tidyverse.org).)

  - For example, see [`ListPlot`](https://reference.wolfram.com/language/ref/ListPlot.html), 
    [`BubbleChart`](https://reference.wolfram.com/language/ref/BubbleChart.html).
  
- The primary target data structure to visualize is an array of hashes, 
   with all array elements having one of these sets of keys 
   - `<x y>` 
   - `<x y group>`
   - `<x y z>`
   - `<x y z group>` 
   
- Multiple-dataset plots are produced via dataset records that have the key "group".  

- Whenever possible deduce the keys from arrays of scalars.

- The data reshaping functions in "Data::Reshapers", [AAp1], should fit nicely into workflows with this package.

- The package functions are tested separately:

  - As Raku functions that produce output for given signatures
  - As JavaScript plots that correspond to the corresponding intents
  
--------

## How does it work?

Here is a diagram that summarizes the evaluation path from a Raku plot spec to a browser diagram:

```mermaid
graph TD
   Raku{{Raku}}
   IRaku{{"Raku<br>Jupyter kernel"}}
   Jupyter{{Jupyter}}
   JS{{JavaScript}}
   RakuInput[/Raku code input/]
   JSOutput[/JavaScript code output/]
   CellEval[Cell evaluation]
   JSResDisplay[JavaScript code result display]
   Jupyter -.-> |1|IRaku -.-> |2|Raku -.-> |3|JSOutput -.-> |4|Jupyter
   Jupyter -.-> |5|JS -.-> |6|JSResDisplay
   RakuInput ---> CellEval ---> Jupyter  ---> JSResDisplay
```

Here is the corresponding narration:

1. Enter Raku plot command in cell that starts with 
   [the magic spec `%% js`](https://github.com/bduggan/raku-jupyter-kernel/issues/100#issuecomment-1349494169).

   - Like `js-d3-list-plot((^12)>>.rand)`.
   
2. Jupyter via the Raku kernel evaluates the Raku plot command.

3. The Raku plot command produces JavaScript code.

4. The Jupyter "lets" the web browser to evaluate the obtained JavaScript code.

   - Instead of web browser, say, Visual Studio Code can be used.

   
The evaluation loop spelled out above is possible because of the magics implementation in the Raku package
[Jupyter::Kernel](https://github.com/bduggan/raku-jupyter-kernel#features), 
[BD1].
   
--------

## Alternatives

### Raku packages

The Raku packages "Text::Plot", [AAp2], and "SVG::Plot", [MLp1],
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

## Command Line Interface (CLI)

The package provides a CLI script that can be used to generate HTML files with plots or charts.

```shell
js-d3-graphics --help
```
```
# Usage:
#   js-d3-graphics <cmd> [<points> ...] [-w|--width[=UInt]] [-h|--height[=UInt]] [-t|--title=<Str>] [--x-label=<Str>] [--y-label=<Str>] [--background=<Str>] [--color=<Str>] [--grid-lines] [--margins[=UInt]] [--format=<Str>] -- Generates HTML document code with D3.js plots or charts.
#   js-d3-graphics <cmd> <words> [-w|--width[=UInt]] [-h|--height[=UInt]] [-t|--title=<Str>] [--x-label=<Str>] [--y-label=<Str>] [--background=<Str>] [--color=<Str>] [--grid-lines] [--format=<Str>] -- Generates HTML document code with D3.js plots or charts by splitting a string of data points.
#   js-d3-graphics <cmd> [-w|--width[=UInt]] [-h|--height[=UInt]] [-t|--title=<Str>] [--x-label=<Str>] [--y-label=<Str>] [--background=<Str>] [--color=<Str>] [--grid-lines] [--format=<Str>] -- Generates HTML document code with D3.js plots or charts from pipeline input.
#   
#     <cmd>                 Graphics command.
#     [<points> ...]        Data points.
#     -w|--width[=UInt]     Width of the plot. (0 for Whatever.) [default: 800]
#     -h|--height[=UInt]    Height of the plot. (0 for Whatever.) [default: 600]
#     -t|--title=<Str>      Title of the plot. [default: '']
#     --x-label=<Str>       Label of the X-axis. If Whatever, then no label is placed. [default: '']
#     --y-label=<Str>       Label of the Y-axis. If Whatever, then no label is placed. [default: '']
#     --background=<Str>    Image background color [default: 'white']
#     --color=<Str>         Color. [default: 'steelblue']
#     --grid-lines          Should grid lines be drawn or not? [default: False]
#     --margins[=UInt]      Size of the top, bottom, left, and right margins. [default: 40]
#     --format=<Str>        Output format, one of 'jupyter' or 'html'. [default: 'html']
#     <words>               String with data points.
```

Here is an usage example that produces a list line plot:

```shell
js-d3-graphics list-line-plot 1 2 2 12 33 41 15 5 -t="Nice plot" --x-label="My X" --y-label="My Y" > out.html && open out.html
```
```
# 
```

Here is an example that produces bubble chart:

```shell
js-d3-graphics bubble-chart "1,1,10 2,2,12 33,41,15 5,3,30" -t="Nice plot" --x-label="My X" --y-label="My Y" > out.html && open out.html
```
```
# 
```

Here is an example that produces a random mandala:

```shell
js-d3-graphics random-mandala 1 --margins=100 -h=1000 -w=1000 --color='rgb(120,120,120)' --background='white' -t="Random mandala" > out.html && open out.html
```
```
# 
```

Here is an example that produces three random scribbles:

```shell
js-d3-graphics random-scribble 3 --margins=10 -h=200 -w=200 --color='blue' --background='white' > out.html && open out.html
```
```
# 
```

--------

## TODO

In the lists below the highest priority items are placed first.

### Plots

#### Single dataset

1. [X] DONE List plot
2. [X] DONE List line plot
3. [X] DONE Date list plot
4. [X] DONE Box plot

#### Multiple datasets

1. [X] DONE List plot
2. [X] DONE List line plot
3. [X] DONE Date list plot 
4. [ ] TODO Box plot 

### Graph plots

1. [ ] TODO Graph plot using d3-force
    - [X] DONE Core graph plot
    - [X] DONE Directed graphs
    - [X] DONE Vertex label styling
    - [X] DONE Edge label styling
    - [X] DONE Highlight vertices and edges
      - Multiple groups can be specified.
    - [ ] TODO Vertex shape styling
    - [ ] TODO Edge shape styling
    - [ ] TODO Curved edges
2. [ ] TODO Graph plot using vertex coordinates
    - [X] DONE Core graph plot
    - [X] DONE Directed graphs
    - [X] DONE Vertex label styling
    - [X] DONE Edge label styling
    - [ ] TODO Vertex shape styling
    - [ ] TODO Edge shape styling
    - [ ] TODO Curved edges
   
### Charts

#### Single dataset

1. [X] DONE Bar chart
   - [X] DONE Vertical   
   - [X] DONE Horizontal   
   - [X] DONE Chart label per bar   
2. [X] DONE Histogram 
3. [X] DONE Bubble chart
4. [ ] TODO Density 2D chart -- rectangular bins
5. [ ] TODO Radar chart 
6. [ ] TODO Density 2D chart -- hexagonal bins
7. [ ] TODO Pie chart
8. [X] DONE Heatmap plot
9. [X] DONE Chessboard position

#### Multiple datasets

1. [X] TODO Bar chart
2. [ ] TODO Histogram
3. [X] DONE Bubble chart
4. [X] DONE Bubble chart with tooltips
5. [ ] TODO Pie chart 
6. [ ] TODO Radar chart

### Decorations

User specified or automatic:

1. [X] DONE Plot label / title
2. [X] DONE Axes labels
3. [X] DONE Plot margins
4. [X] DONE Plot legends (automatic for multi-datasets plots and chart)
5. [X] DONE Plot grid lines 
     - [X] DONE Automatic 
     - [X] DONE User specified number of ticks
6. [X] DONE Title style (font size, color, face)
7. [X] DONE Axes labels style (font size, color, face)
8. [ ] TODO Grid lines style

### Infrastructural

1. [X] DONE Support for different JavaScript wrapper styles
  
   - [X] DONE Jupyter cell execution ready
   
   - [X] DONE Standard HTML
   
   - Result output with JSON format?

2. [ ] TODO Better, comprehensive type checking
   
   - Using the type system of "Data::TypeSystem".
     
3. [X] DONE CLI script

4. [X] DONE JavaScript code snippets management

   - Initially the JavaScript snippets were kept with the Raku code,
     but it seems it is better to have them in a separate file.
     (With the corresponding accessors.)
   
## Second wave

1. [X] Random Mandala, single plot

2. [X] Random mandalas row

3. [ ] Random mandalas table/array
   
   - (I am not sure I will do this.)
   
4. [X] Random Scribble, single plot 

5. [X] Random Scribbles row 

--------

## Implementation details

### Splicing of JavaScript snippets

The package works by splicing of parametrized JavaScript code snippets and replacing the parameters
with concrete values.

In a sense, JavaScript macros are used to construct the final code through text manipulation.
(Probably, unsound software-engineering-wise, but it works.)

### History

Initially  the commands of this package were executed in
[Jupyter notebook with Raku kernel](https://raku.land/cpan:BDUGGAN/Jupyter::Kernel)
properly
[hacked to redirect Raku code to JavaScript backend](https://github.com/bduggan/p6-jupyter-kernel/issues/100)

Brian Duggan fairly quickly implemented the suggested Jupyter kernel magics, so, now no hacking is needed.

After I finished version 0.1.3 of this package I decided to write a Python version of it, see [AAp3].
Writing the Python version was a good brainstorming technique to produce reasonable refactoring (that is version 0.1.4).

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
[Data::Reshapers Raku package](https://github.com/antononcube/Raku-Data-Reshapers),
(2021-2024),
[GitHub/antononcube](https://github.com/antononcube).

[AAp2] Anton Antonov,
[Text::Plot Raku package](https://github.com/antononcube/Raku-Text-Plot),
(2022),
[GitHub/antononcube](https://github.com/antononcube).

[AAp3] Anton Antonov,
[Data::TypeSystem Raku package](https://github.com/antononcube/Raku-Data-TypeSystem),
(2023-2024),
[GitHub/antononcube](https://github.com/antononcube).

[AAp3] Anton Antonov,
[JavaScriptD3 Python package](https://github.com/antononcube/Python-packages/tree/main/JavaScriptD3),
(2022),
[Python-packages at GitHub/antononcube](https://github.com/antononcube/Python-packages).

[AAp4] Anton Antonov,
[Jupyter::Chatbook Raku package](https://github.com/antononcube/Raku-Jupyter-Chatbook),
(2023-2024),
[GitHub/antononcube](https://github.com/antononcube).

[BD1] Brian Duggan,
[Jupyter::Kernel Raku package](https://raku.land/cpan:BDUGGAN/Jupyter::Kernel),
(2017-2022),
[GitHub/bduggan](https://github.com/bduggan/raku-jupyter-kernel).

[MLp1] Moritz Lenz,
[SVG::Plot Raku package](https://github.com/moritz/svg-plot)
(2009-2018),
[GitHub/moritz](https://github.com/moritz/svg-plot).

### Videos

[AAv1] Anton Antonov,
["The Raku-ju hijack hack for D3.js"](https://www.youtube.com/watch?v=YIhx3FBWayo),
(2022),
[YouTube/@AAA4Prediction](https://www.youtube.com/@AAA4prediction).

[AAv2] Anton Antonov,
["Random mandalas generation (with D3.js via Raku)"](https://www.youtube.com/watch?v=THNnofZEAn4),
(2022),
[YouTube/@AAA4Prediction](https://www.youtube.com/@AAA4prediction).

[AAv3] Anton Antonov,
["Raku Literate Programming via command line pipelines"](https://www.youtube.com/watch?v=2UjAdQaKof8),
(2023),
[YouTube/@AAA4Prediction](https://www.youtube.com/@AAA4prediction).