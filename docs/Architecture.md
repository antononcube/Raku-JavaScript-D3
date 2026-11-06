# Architecture

`JavaScript::D3` retains the established `js-d3-*` public API. Existing
feature modules remain the owners of their visualization families; this avoids
adding namespace layers that merely forward one routine to another.

```text
JavaScript::D3                         public, compatibility-preserving API
├── Config                             D3 frontend loader configuration
├── Render                             output wrapper and rendering boundary
├── Charts                            charts and their data normalization
├── Plots / Plots3D                   2D and 3D plotting
├── Graph / Chess / Images / Gauge    specialized visualizations
├── Random                            geometry/data generators
└── CodeSnippets / CodeSnippets3D     current shared JavaScript catalog
```

Do not create a module merely to rename a routine. Extract a module only when
it owns implementation, state, or a reusable rendering contract. The current
feature modules are the appropriate boundaries until a cohesive portion of
their implementation is physically moved.

Rendering has already crossed the new boundary: `RenderSpec` captures a
visualization body and output settings, and `Render` owns Jupyter, complete
HTML, HTML fragment, and raw-JavaScript wrappers. `CodeSnippets::WrapIt`
delegates to it for backward compatibility.

When adding a visualization, place input normalization and option validation
in its feature module and call `Render::render` once at the output edge.
