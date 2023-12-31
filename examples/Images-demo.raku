#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Generators;
use Data::Reshapers;
use Data::Summarizers;

my ($m, $n) = (100, 200);
my @dsSin = ((-$m ... $m) X (-$n ... $n)).map({ sin(([+] $_ <<*>> $_) / (4*$n)) }).rotor(2*$n+1);

say dimensions(@dsSin);

#records-summary(@dsSin);

spurt $*CWD ~ '/images.html',
        js-d3-image(@dsSin,
                color-palette => 'Greys',
                width => @dsSin[0].elems,
                height => @dsSin.elems,
                format => 'html');