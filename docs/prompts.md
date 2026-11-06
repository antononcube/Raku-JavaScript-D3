
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
