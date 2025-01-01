#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Summarizers;

spurt $*CWD ~ '/clock-gauge.html', js-d3-clock-gauge(
        hour => Whatever, minute => Whatever, second => Whatever,
        background => 'none',
        height => 300,
        width => 300,
        tick-labels-font-size => 16,
        title => 'Clock gauge',
        title-color => 'Blue',
        scale-ranges => [[0, 30], [30, 45], [[45, 55], [0, 0.15]], [[55, 60], [0.1, 0.2]]],
        color-scheme => 'Reds',
        color-scheme-interpolation-range => [0.1, 0.5],
        gauge-labels => Whatever,
        margins => 25,
        format => 'html');