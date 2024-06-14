#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Generators;
use Data::Summarizers;
use Data::Reshapers;

my @nodes = random-pet-name(7);
my @data = random-tabular-dataset(12, <from to weight label>,
        generators => [
            { @nodes.roll($_).List },
            { @nodes.roll($_).List },
            { (10..20).roll($_).List },
            { random-word($_) }
        ]);

.say for @data;

# These kind of specs also work
my @data2 = @data.map(*<from to>);
my @data3 = @data.map(*<from to weight>);

# Plot
spurt $*CWD ~ '/graph-plot.html',
        js-d3-graph-plot(@data,
                width => 700,
                height => 500,
                title => 'Random pet graph',
                vertex-size => 10,
                title-color => 'DarkRed',
                vertex-label-color => 'Gray',
                format => 'html');

