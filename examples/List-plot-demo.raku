#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Summarizers;
use Data::Generators;

my @data1 = random-tabular-dataset(20, <x y>, generators => [ {&random-real(20, $_)}, {&random-real(1, $_)}]);
my @data2 = random-tabular-dataset(20, <x y tooltip>, generators => [ {&random-real(20, $_)}, {&random-real(1, $_)}, {&random-pet-name($_)}]);
my @data3 = random-tabular-dataset(60, <weight name>, generators => [ {&random-variate( NormalDistribution.new(25, 12), $_)}, {&random-pet-name($_)}]);

@data3 = @data3.grep(*<weight> > 0);
say @data3.elems;
records-summary(@data3);

#my $paretoStats = pareto-principle-statistic(@data3.map(*<weight>));
my @paretoStats = pareto-principle-statistic(@data3.map({ $_<name> => $_<weight> }).Hash);

#say $paretoStats;
say @paretoStats;

my $k = 0;

spurt $*CWD ~ '/list-plot.html',
        js-d3-list-plot(@paretoStats.map({ %( x => $k++, y => $_.value, tooltip => $_.key ) }),
                point-size => 12,
                color => 'steelblue',
                background => 'ivory',
                height => 600,
                width => 800,
                title-color => 'Blue',
                margins => %(left => 120, bottom => 40),
                title => 'Random pets',
                :!tooltip,
                tooltip-color => 'red',
                tooltip-background-color => 'white',
                format => 'html');