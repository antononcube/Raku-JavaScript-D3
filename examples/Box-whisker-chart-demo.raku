#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;

my @data = [
    {:value(1), :variable("District Of Columbia")}, {:value(52), :variable("Rhode Island")}, {:value(73), :variable("Nevada")}, {:value(75), :variable("Delaware")},
    {:value(132), :variable("Hawaii")}, {:value(198), :variable("Wyoming")}, {:value(205), :variable("Idaho")}, {:value(236), :variable("New Mexico")},
    {:value(246), :variable("Connecticut")}, {:value(252), :variable("Arizona")}, {:value(263), :variable("New Hampshire")}, {:value(275), :variable("Montana")},
    {:value(280), :variable("Vermont")}, {:value(284), :variable("West Virginia")}, {:value(289), :variable("Utah")}, {:value(310), :variable("Oregon")},
    {:value(329), :variable("Mississippi")}, {:value(349), :variable("Alaska")}, {:value(355), :variable("Colorado")}, {:value(369), :variable("Maryland")},
    {:value(369), :variable("South Carolina")}, {:value(378), :variable("Virginia")}, {:value(383), :variable("Tennessee")}, {:value(399), :variable("Louisiana")},
    {:value(417), :variable("South Dakota")}, {:value(437), :variable("Massachusetts")}, {:value(440), :variable("North Dakota")}, {:value(467), :variable("Kentucky")},
    {:value(494), :variable("Alabama")}, {:value(519), :variable("Arkansas")}, {:value(524), :variable("Washington")}, {:value(537), :variable("Nebraska")},
    {:value(547), :variable("Maine")}, {:value(571), :variable("New Jersey")}, {:value(597), :variable("Georgia")}, {:value(602), :variable("Indiana")},
    {:value(631), :variable("Kansas")}, {:value(644), :variable("Michigan")}, {:value(657), :variable("North Carolina")}, {:value(691), :variable("Oklahoma")},
    {:value(889), :variable("Florida")}, {:value(931), :variable("Minnesota")}, {:value(954), :variable("Iowa")}, {:value(972), :variable("Missouri")},
    {:value(1059), :variable("Ohio")}, {:value(1096), :variable("California")}, {:value(1314), :variable("Illinois")}, {:value(1431), :variable("Pennsylvania")},
    {:value(1512), :variable("Texas")}, {:value(1640), :variable("Wisconsin")}, {:value(1710), :variable("New York")}];

@data = @data.sort(*<value>).reverse.map({ $_<label> = $_<value>; $_ });

#my @data2 = @data.map({ $_<group> = $_<value> ≤ 300 ?? 'smaller' !! 'larger'; $_ });
my @data2 = @data.map({ $_<group> = (^5).pick; $_ });

say @data.elems;
#
spurt $*CWD ~ '/box-whisker-chart.html',
        js-d3-box-whisker-chart(@data.map(*<value>),
                title => 'State sizes',
                format => 'html');

#spurt $*CWD ~ '/box-whisker-chart.html',
#        js-d3-box-whisker-chart(@data2, format => 'html');
