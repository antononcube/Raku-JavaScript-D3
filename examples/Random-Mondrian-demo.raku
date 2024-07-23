#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;

my @color-shemes = <schemeCategory10 schemeAccent schemeDark2 schemeObservable10 schemePaired schemePastel1 schemePastel2 schemeSet1 schemeSet2 schemeSet3 schemeTableau10>;
@color-shemes = @color-shemes.append('None' xx 6);

spurt $*CWD ~ '/random-mondrian.html',
        js-d3-random-mondrian(
                width => 900,
                stroke-color => <Black Black Black Gray Blue Orange Teal>.pick,
                color-scheme => @color-shemes.pick,
                stroke-width => [1, 2].pick,
                format => 'html'
        );