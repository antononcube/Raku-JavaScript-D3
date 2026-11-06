# Architecture

`JavaScript::D3` retains the established `js-d3-*` public API. The public
facade delegates to feature namespaces, so a visualization can now be found
by its subject rather than by searching one large module.

```text
JavaScript::D3                         public, compatibility-preserving API
├── Config                             D3 frontend loader configuration
├── Render                             output wrapper and rendering boundary
├── Plots/{XY,Date,Heatmap,Matrix,ThreeD}
├── Charts/{Bar,HistogramFeature,BoxWhisker,Bubble,Density2D}
├── Visualizations/{Graph,Chess,Images,Gauge}
├── Components/{Layout,Axes,Legend,Tooltip}
└── Templates/{XY,Heatmap}
```

The first migration keeps the established `Plots`, `Charts`, and
`CodeSnippets` modules as compatibility engines. New feature modules are the
stable ownership boundary; they delegate to those engines while their
implementations are incrementally separated into Components and Templates.
This deliberately avoids a public API break or a broad generated-JavaScript
diff.

Rendering has already crossed the new boundary: `RenderSpec` captures a
visualization body and output settings, and `Render` owns Jupyter, complete
HTML, HTML fragment, and raw-JavaScript wrappers. `CodeSnippets::WrapIt`
delegates to it for backward compatibility.

When adding a visualization, place input normalization and option validation
in its feature module, shared JavaScript fragments in `Components` or
`Templates`, and call `Render::render` once at the edge.
