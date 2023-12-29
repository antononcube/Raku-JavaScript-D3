#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Generators;
use Data::Summarizers;
use Data::Reshapers;

# Generate random data
my @ds3D = random-tabular-dataset(120, <group x y z label>,
        generators => [random-word(3), <a1 b2 c3 d4 e5 f6>, random-pet-name(5), { random-real((2, 12), $_) }, random-pet-name(30)]);

# Remove duplication
@ds3D = group-by(@ds3D, <group x y>).values.map(*.head).&flatten;

# Show that there are no duplicates
sink records-summary(group-by(@ds3D, <group x y>).map({$_.value.elems}).cache);

# Summary
sink records-summary(@ds3D);

# Plot
spurt $*CWD ~ '/heatmaps.html',
        js-d3-heatmap-plot(@ds3D,
                width => 600,
                height => 500,
                color-palette => 'Reds',
                plot-label-color => 'White',
                plot-label-font-size => 12,
                tick-label-color => 'steelblue',
                low-value => 0,
                high-value => 14,
                format => 'html');

