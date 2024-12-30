#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Summarizers;

spurt $*CWD ~ '/clock-gauge.html',
        js-d3-clock-gauge(
                hour => Whatever, minute => Whatever, second => Whatever,
                background => 'none',
                height => 300,
                width => 300,
                tick-labels-font-size => 16,
                title => 'Clock gauge',
                title-color => 'Blue',
                margins => 25,
                format => 'html');