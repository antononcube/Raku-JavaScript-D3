#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Summarizers;
use Data::Reshapers;
use Data::Generators;

my $n = 5;
my $scale = 1;
my @data;
@data.append: random-real([80,120] <<*>> $scale, $n).kv.map( -> $k, $v { %(y => $v.round(0.01), x => $k, group => 'a') });
@data.append: random-real([50, 60] <<*>> $scale, $n).kv.map( -> $k, $v { %(y => $v.round(0.01), x => $k, group => 'b') });
@data.append: random-real([10, 70] <<*>> $scale, $n).kv.map( -> $k, $v { %(y => $v.round(0.01), x => $k, group => 'c') });

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
                x-label => 'Indexes',
                margins => %(left => 120, bottom => 40),
                title => 'Random numbers',
                format => 'html');