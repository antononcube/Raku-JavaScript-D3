#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Summarizers;

spurt $*CWD ~ '/clock-gauge.html',
        js-d3-clock-gauge(
                hour => Whatever, minute => Whatever, second => Whatever,
                background => 'none',
                height => 200,
                width => 200,
                tick-labels-font-size => 16,
                title => 'Clock gauge',
                title-color => 'Ivory',
                margins => 5,
                format => 'html');