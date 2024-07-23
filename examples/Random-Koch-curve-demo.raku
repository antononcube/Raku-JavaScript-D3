#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Generators;

spurt $*CWD ~ '/random-koch-curve-1.html',
        js-d3-random-koch-curve(Whatever,
                p => 1/4, w => 0.2, h => 0.3, n => 6,
                color => 'steelblue',
                width => 800,
                format => 'html');

spurt $*CWD ~ '/random-koch-curve-2.html',
        js-d3-random-koch-curve(Whatever,
                p => UniformDistribution.new(min => 0.3, max => 0.37),
                w => random-real([0.01, 0.05]),
                h => UniformDistribution.new(min => 0.2, max => 0.45),
                n => [5..7].pick,
                width => 1200,
                stroke-color => <GreenYellow PaleGreen ForestGreen Green YellowGreen OliveDrab Olive Teal>.pick,
                fill-color => <BlanchedAlmond Wheat Tan SandyBrown Peru SaddleBrown Sienna Brown Maroon>.pick,
                background => 'none',
                stroke-width => [1, 2].pick,
                :!axes,
                :filled,
                format => 'html');