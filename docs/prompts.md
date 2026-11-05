
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