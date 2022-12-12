use v6.d;

use JavaScript::D3::Charts;
use JavaScript::D3::Plots;

unit module JavaScript::D3;


#============================================================
my $jsD3ConfigCode = q:to/END/;
require.config({
     paths: {
     d3: 'https://d3js.org/d3.v$VER.min'
}});

require(['d3'], function(d3) {
     console.log(d3);
});
END

multi js-d3-config(:$v = 7) is export {
    return $jsD3ConfigCode.subst('$VER', $v);
}

#============================================================
#| Make a list plot (scatter plot) for a list of numbers or a list of x-y coordinates.
proto js-d3-list-plot($data, |) is export {*}

multi js-d3-list-plot($data, Str :$background= 'white', Str :$color= 'steelblue', :$width = 600, :$height = 400, Str :$title = '') {
    return JavaScript::D3::Plots::ListPlot($data,
            :$background,
            :$color,
            :$width,
            :$height,
            :$title);
}

#============================================================
#| Make a list line plot for a list of numbers or a list of x-y coordinates.
proto js-d3-list-line-plot($data, |) is export {*}

multi js-d3-list-line-plot($data, Str :$background= 'white', Str :$color= 'steelblue', :$width = 600, :$height = 400, Str :$title = '') {
    return JavaScript::D3::Plots::ListLinePlot($data,
            :$background,
            :$color,
            :$width,
            :$height,
            :$title);
}

#============================================================
#| Make a bar chart for a list of numbers, hash with numeric values, or a dataset with columns C<<Label Value>>.
proto js-d3-bar-chart($data, |) is export {*}

multi js-d3-bar-chart($data, Str :$background= 'white', Str :$color= 'steelblue', :$width = 600, :$height = 400, Str :$title = '') {
    return JavaScript::D3::Charts::BarChart($data,
            :$background,
            :$color,
            :$width,
            :$height,
            :$title);
}

#============================================================
#| Make a histogram for a list of numbers.
proto js-d3-histogram($data, |) is export {*}

multi js-d3-histogram($data, Str :$background= 'white', Str :$color= 'steelblue', :$width = 600, :$height = 400, Str :$title = '') {
    return JavaScript::D3::Charts::Histogram($data,
            :$background,
            :$color,
            :$width,
            :$height,
            :$title);
}