#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Summarizers;
use Data::Generators;

my @data1 = random-tabular-dataset(20, <x y z tooltip group>,
        generators => [{ &random-real(20, $_) }, { &random-real(1, $_) }, { &random-real(100, $_) }, { &random-pet-name($_) }, <A B>]);

my @data2 = @data1.map({
    my %h = $_.clone;
    %h<label> = $_<tooltip>;
    %h<tooltip>:delete;
    %h
});
my @data3 = @data1.map({
    my %h = $_.clone;
    %h<tooltip>:delete;
    %h
});

say @data1.elems;

records-summary(@data3);

my %opts =
        z-range-min => 2,
        z-range-max => 12,
        color => 'steelblue',
        background => 'ivory',
        height => 400,
        width => 600,
        title-color => 'Blue',
        :tooltip,
        tooltip-color => 'Salmon',
        tooltip-background-color => 'ivory',
        margins => %(left => 120, bottom => 40),
        :grid-lines,
        format => 'html';

my @res =
        [
            js-d3-bubble-chart(@data1, title => 'Random pet groups -- with tooltip per record', div-id => 'd1', |%opts),
            js-d3-bubble-chart(@data2, title => 'Random pet groups -- with label and no tooltip per record', div-id => 'd2', |%opts),
            js-d3-bubble-chart(@data3, title => 'Random pet groups -- no label nor tooltip per record', div-id => 'd3', |%opts)
        ];

spurt $*CWD ~ '/bubble-chart-1.html', @res[0];
spurt $*CWD ~ '/bubble-chart-2.html', @res[1];
spurt $*CWD ~ '/bubble-chart-3.html', @res[2];
