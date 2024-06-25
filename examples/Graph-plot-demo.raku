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
my @data1 = random-tabular-dataset(12, <from to>,
        generators => [
            { @nodes.roll($_).List },
            { @nodes.roll($_).List },
        ]);

my @data2 = @data.map(*<from to>);

my @data3 = @data.map(*<from to weight>);

my @data4 =
        :Carson("Reno"), :Enterprise("Spring_Valley"), :Summerlin_South("Spring_Valley"), :North_Las_Vegas("Sunrise_Manor"), :Winchester("Paradise"),
        :Henderson("Whitney"), :Paradise("Winchester"), :Las_Vegas("Summerlin_South"), :Sunrise_Manor("Winchester"), :Spring_Valley("Summerlin_South"),
        :Whitney("Sunrise_Manor"), :Reno("Sparks"), :Pahrump("Summerlin_South"), :Sparks("Reno");

# Plot
spurt $*CWD ~ '/graph-plot.html',
        js-d3-graph-plot(@data4,
                width => 700,
                height => 500,
                title => 'Random pet graph',
                vertex-size => 4,
                title-color => 'DarkRed',
                vertex-label-color => 'Gray',
                edge-thickness => 3,
                #highlight => ['Carson', 'Pahrump', 'Summerlin_South'],
                #highlight => ['Reno' => 'Carson', 'Pahrump' => 'Summerlin_South'],
                #highlight => ['Carson', 'Pahrump', 'Summerlin_South', 'Reno' => 'Carson', 'Pahrump' => 'Summerlin_South'],
                #:!directed-edges,
                force => %(
                    charge => {strength => -40},
                    x => { strength => 0.01, x => 0.1},
                    y => { strength => 0.03 },
                    collision => { radius => 0.7, strength => 80},
                    link => { distance => 'd => d.weight*35'}
                ),
                format => 'html');

