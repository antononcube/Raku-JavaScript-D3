#!/usr/bin/env raku
use v6.d;

use lib <. lib>;
use JavaScript::D3;
use Data::Importers;

my $url = "https://pldb.io/posts/age.tsv";
my @dsDataLines = data-import($url).lines.map({ $_.split("\t") })>>.Array;

my @field-names = @dsDataLines.head.Array;
my @dsData = @dsDataLines.tail(*-2).map({ @field-names.Array Z=> $_.Array })>>.Hash;

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

spurt $*CWD ~ '/box-whisker-chart.html',
        js-d3-box-whisker-chart(@dsData.map(*<numberOfUsersEstimate>).map({ log($_ + 1, 10)}),
                :horizontal,
                :outliers,
                width => 600,
                title => 'lg(Number of users estimate)',
                format => 'html');
