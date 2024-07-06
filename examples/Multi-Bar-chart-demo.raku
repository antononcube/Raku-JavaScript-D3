#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Summarizers;
use Data::Reshapers;
use Data::Generators;

my $k = 0;
my @data = random-real([80,120],5).map({ %(y => $_, x => $k++, group => 'a') });
$k = 0;
@data.append: random-real([50,60],5).map({ %(y => $_, x => $k++, group => 'b') });

say dimensions(@data);

records-summary(@data);

spurt $*CWD ~ '/multi-bar-chart.html',
        js-d3-bar-chart(@data,
                color => 'steelblue',
                background => 'ivory',
                color-scheme => 'schemeObservable10',
                height => 500,
                width => 600,
                :grid-lines,
                title-color => 'Blue',
                margins => %(left => 120, bottom => 40),
                title => 'Random numbers',
                format => 'html');