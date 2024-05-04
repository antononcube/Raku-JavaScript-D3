#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Generators;
use Data::Summarizers;
use Data::Reshapers;

# Generate random data
my @ds3D = random-tabular-dataset(30, <group x y z label>,
        generators => [random-word(3),
                       <a1 b2 c3 d4 e5 f6>,
                       random-pet-name(5),
                       { random-real((2, 12), $_) },
                       random-pet-name(30).grep({ $_.chars ≤ 6}).map({"<tspan>{$_}</tspan><tspan dx='-{$_.chars/2}em', dy='1em'>{<cat dog>.pick}</tspan>"}).cache ]);

# Remove duplication
@ds3D = group-by(@ds3D, <group x y>).values.map(*.head).&flatten;

# Show that there are no duplicates
sink records-summary(group-by(@ds3D, <group x y>).map({$_.value.elems}).cache);

# Summary
sink records-summary(@ds3D);

my @xLabels = <a1 b2 c3 d4 e5 f6>;
my @yLabels = @ds3D.map(*<y>).unique;

# Plot
spurt $*CWD ~ '/heatmaps.html',
        js-d3-heatmap-plot(@ds3D,
                width => 700,
                height => 500,
                x-tick-labels => @xLabels,
                y-tick-labels => @yLabels,
                color-palette => 'Reds',
                plot-labels-color => 'White',
                plot-labels-font-size => 18,
                plot-labels-font-family => 'Courier',
                tick-labels-color => 'steelblue',
                tick-labels-font-size => 12,
                low-value => 0,
                high-value => 14,
                margins => {left => 100, right => 0},
                mesh => 0.01,
                format => 'html');

