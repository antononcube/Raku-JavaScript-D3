#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Generators;
use Data::Summarizers;
use Data::Reshapers;

my @ds3D = random-tabular-dataset(120, <group x y z>,
        generators => [random-word(3), <a1 b2 c3 d4 e5 f6>, random-pet-name(5), { random-real((0, 12), $_) }]);

sink records-summary(@ds3D);

spurt $*CWD ~ '/heatmaps.html',
        js-d3-heatmap-plot(@ds3D,
                width => 300,
                height => 500,
                color-palette => 'Blues',
                tick-label-color => 'blue',
                format => 'html');

