#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;
use Data::Importers;

my $url = "https://pldb.io/posts/age.tsv";
my @dsData = data-import($url, headers => 'auto');

@dsData = @dsData.map({
    $_<ageAtCreation> = $_<ageAtCreation>.UInt;
    $_<rank> = $_<rank>.Int;
    $_<pldbScore> = $_<pldbScore>.Int;
    $_<appeared> = $_<appeared>.Int;
    $_<numberOfUsersEstimate> = $_<numberOfUsersEstimate>.Int;
    $_<numberOfJobsEstimate> = $_<numberOfJobsEstimate>.Int;
    $_<foundationScore> = $_<foundationScore>.Int;
    $_
}).Array;

say @dsData.elems;
#
#spurt $*CWD ~ '/box-whisker-chart.html',
#        js-d3-box-whisker-chart(@dsData.map(*<numberOfUsersEstimate>).map({ log($_ + 1, 10)}),
#                :!horizontal,
#                :outliers,
#                width => 200,
#                title => 'lg(numberOfUsersEstimate)',
#                format => 'html');

spurt $*CWD ~ '/box-whisker-chart.html',
        js-d3-box-whisker-chart(@dsData.map(*<ageAtCreation>),
                :!horizontal,
                :outliers,
                width => 400,
                title => 'ageAtCreation',
                title-color => 'Salmon',
                stroke-color => 'DarkRed',
                fill-color => 'Pink',
                tooltip-color => 'DarkRed',
                tooltip-background-color => 'Ivory',
                format => 'html');
