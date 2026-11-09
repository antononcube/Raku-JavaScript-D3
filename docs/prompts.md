
---

## XKCD filter

The code of "./resources/XKCD-filter.js" was taken from https://www.reddit.com/r/wljs/comments/1xfcsvc/turn_your_plots_into_xkcdlike_handdrawn_figures/.

```text
Examine the code in "./resources/XKCD-filter.js". Make a new Jupyter notebook in "./docs" that draws a multi list-line-plot using the Raku package "JavaScript::D3" and then applies that XKCD filter. I assume you have to make a Raku function that modifies the output of list-line-plot.
```

````text
Can you make an universal function that I can modify any of the outputs of "JavaScript::D3"? For example:

```raku
js-d3-box-whisker-chart(random-variate(BetaDistribution.new(120,10), 500)) 
==> js-xkcd-modifier(roughness => 0.035)
```

````

## Fix of applying the XKCD filter only to the last cell

```text
I moved js-xkcd-modifier at the bottom of the file "./libs/JavaScript/D3.rakumod". It seems that in Jupyter notebooks the filter is applied to the last cell output with JavaScript code. I.e. if I evaluate a previous #%js cell with that has XKCD filter the filter is not applied. Can investigate -- see the last two cells in "./docs/XKCD-modifications.ipynb".
```

---

## Refactoring evaluation

```text
Examine the code of this package, "JavaScript::D3", and give suggestions for improvements from developer perspective: 
- Easier to find and modify code elements
- Composing JavaScript chunks is adequately modularized
```

Most of the refactoring done aftewards was discarded.

----

## Bin2DChart

```text
Make full, proper implementation of Bin2DChart using D3.js routines or primitives. 
Follow the style of the other functions.
```

----

## Histogram

````text
Extend the implementation of js-d3-histogram to handle lists of lists as first arguments. For example:

```
js-d3-histogram(
    [
        random-variate(NormalDistribution.new(120,10), 500), 
        random-variate(BetaDistribution.new(170,10), 500), 
    ])
```

The colors of each histogram are assigned by a specified color palette. (E.g. "Set2".)
```

````text
I want to also specify in the multiple distribution data in long form:

```
[{value => 2.3, group => 'normal'}, {value => 9.3, group => 'normal'}, {value => 3.23, group => 'beta'}, ...]
```

The option `:$legend` would show the groups colored according to the applied color scheme.
````

----

## Parallel axis plot

````text
Implement `js-d3-parallel-axis-plot` that plots lines between equally spaced parallel lines,
each corresponding to a data axis. For example:

```raku
js-d3-parallel-axis-plot((10.rand xx 40).rotor(5))
```

Implement the multiple datasets version too:

```raku
my @md-data = (10.rand xx 40).rotor(5), (10.rand xx 20).rotor(5), (10.rand xx 50).rotor(5);
js-d3-parallel-axis-plot(@md-data)
```

Should work with long form data too:

```
[
    {1 => 2.3, 2 => .23, 3 => 1.45, 4 => 3.2, group => 'first'}, 
    {1 => 7.3, 2 => .63, 3 => 3.5, 4 => 4.2, group => 'first'}, 
    {1 => 7.3, 2 => 2.38, 3 => 5.5, 4 => 5.2, group => 'second'}, 
    ...
]
```

The options for color palette, title and axes labels, should correspond to those of `js-d3-list-line-plot`.
````

```text
Make sure that datased like this is plotted:
```
{bumble => 2.378383132755555, cancel => 8.149281270421287, contributor => 3.26138081729468, nervy => 0.1261034166787256},
{bumble => 1.7675764038449282, cancel => 3.8843567988217886, contributor => 7.498732703954179, nervy => 8.582488572307456},
{bumble => 7.636664441265772, cancel => 8.046858250770148, contributor => 6.5016792242452155, nervy => 8.798841831117617},
```
````

----

## Radial axis plot

````text
Implement `js-d3-radial-axis-plot` that plots equally spaced radial axes,
each corresponding to a data element. For example:

```raku
js-d3-radial-axis-plot([y_1, y_2, ..., y_n])
```

Using an array of pairs as argument is equivalent to use using the values of those pairs:

```raku
js-d3-radial-axis-plot( %( k_1 => y_1, k_2 => y_2, ..., k_n => y_n) )
```

Same for a hashmap argument -- its values are used for the plot.

- Values y_i that are not numeric are taken to be missing and are not shown.
- The axes are arranged clockwise starting from the positive y axis.
- By default, all the axes have the same plot range.
- With the default setting `plot-ange => Whatever`, all the axes use the same plot range.
- With `axes => Whatever`, only the first axis will be shown if all of the axes have the same scale and plot range. If there are any differences, all the axes will be shown.

The options for title, axes, legend, etc. are the same as those of `js-d3-parallel-axis-plot`.
````

````text
Implement option `filling => True` that can take values `True`, `False`. If `True` the area inside the radial plot curve is filled with the same color as the curve but: 0.8 lighter and 0.7 more transparent.

Also, make the `js-d3-radial-axis-plot` work with multiple vectors (or a list of hashmaps). 
For each vector have different color. The color of each plot curve is selected according to specified color palette.
````

````text
This just plots one axis and a legend, nothing else:

```raku
js-d3-radial-axis-plot([[3,9,9,7,2],[8,10,0,6,7],[7,10,2,4,3]])
```
````

```text
Make the grid-lines option take not just Boolean but also string shape values "polygon", "circle".
Add `:$grid-lines-color` option that takes color values.
```

---

## 3D surfaces

```text
Does 3D plotting of D3.js support plotting of surfaces?
If, yes, outline an implementation plan for this package, "JavaScript::D3".
```

````text
Ok. Change the implementation to use explicit 3D points. I expect to see a triangle with this spec:

```raku
js-list-plot3D([[0, 0, 1], [1, 0, 0], [0, 1, 0]])
```

Should be equivalent to:

```raku
js-list-plot3D([{x => 0, y => 0, z => 1}, {x => 1, y => 0, z => 0}, {x => 0, y => 1, z => 0}])
```
````

```text
Your previous implementation assumed regular data -- a matrix of Z-values. 
Let us have both:
- Irregular data treatment is used for a list of triplets.
- Regular data treatment is used if the argument is a dense matrix with columns more than 3.
- Irregular data is by default -- matrices with exactly three columns are treated as irregular data. 
```

----

## Plot combinations

```text
I am interested in combining two or more JavaScript plots generated by this package, "JavaScript::D3", into one.
Outline a good strategy. I think it is good idea the JavaScript code snippets to have comments separting their specific parts from the decoration parts, like title, axes, etc. and then splice those specific parts into one, and use the decorations of the first plot
to be the decorations of the plots combination.
```

```text
Ok. Outline how the layers combinations is done.
```

```text
Are you going to use or reuse the JavaScript snippets for the combinations? In what way? Are you going to refactor the existing JavaScript code snippets?
```

````text
Ok. I want see the implementation of:

```raku
js-d3-combine(
    js-d3-layer-line(@series-a, :color<steelblue>),
    js-d3-layer-points(@series-b, :color<tomato>),
    js-d3-layer-labels(@annotations),
    :title<Combined view>,
    :x-axis-label<Time>,
    :y-axis-label<Value>,
)
```

Make it in separate "Combination.rakumod" file in the "Plots" directory.
````

```text
What if I want to combine two charts, or a chart and plot? Say, two histograms. 
You have to implement a histogram layer?
```

```text
Ok. Make the changes for using histogram layers. Make sure I can combine histograms, lines, and points.
```

````text
Ok. I can combine one chart with multiple plots but I cannot combine two or more charts. Please:
- Make a box-whisker plot layer
- Make sure I can combine two more charts
This should work / render:

```raku
js-d3-combine(
    js-d3-layer-histogram([1, 2, 2, 3, 5, 8], :color<steelblue>, :legend('Sample A'), :number-of-bins(4)),
    js-d3-layer-histogram([2, 3, 3, 4, 6, 8], :color<tomato>, :legend('Sample B'), :number-of-bins(4)),
)
```
````

```text
The box-whisker layer should take the boolean option :horizontal.
```