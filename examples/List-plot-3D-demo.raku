#!/usr/bin/env raku
use v6.d;

use lib <. lib>;

use JavaScript::D3;
use Data::Summarizers;
use Data::Generators;

my @data1 = random-tabular-dataset(20, <x y z>, generators => [ {&random-real(20, $_)}, {&random-real(1, $_)}, {&random-real(4, $_)}]);

say @data1.elems;
records-summary(@data1);

my $k = 0;

spurt $*CWD ~ '/list-plot-3D.html',
        js-d3-list-line-plot3d(@data1,
                point-size => 12,
                color => 'steelblue',
                background => 'ivory',
                height => 600,
                width => 800,
                y-axis-scale => 'line', # 'log'
                title-color => 'Blue',
                margins => %(left => 120, bottom => 40),
                title => 'Random pets',
                :!tooltip,
                tooltip-color => 'red',
                tooltip-background-color => 'white',
                format => 'html');