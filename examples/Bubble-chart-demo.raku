#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Summarizers;
use Data::Generators;

my @data = random-tabular-dataset(20, <x y z tooltip>, generators => [ {&random-real(20, $_)}, {&random-real(1, $_)}, {&random-real(100, $_)}, {&random-pet-name($_)}]);

@data = @data.sort(*<value>).reverse.map({ $_<label> = $_<value>; $_ });

say @data.elems;

records-summary(@data);

spurt $*CWD ~ '/bubble-chart.html',
        js-d3-bubble-chart(@data,
                z-range-min => 2,
                z-range-max => 12,
                color => 'steelblue',
                background => 'ivory',
                height => 400,
                width => 600,
                title => 'Number of cities per state',
                title-color => 'Blue',
                :tooltip,
                tooltip-color => 'Salmon',
                tooltip-background-color => 'ivory',
                margins => %(left => 120, bottom => 40),
                :grid-lines,
                format => 'html');