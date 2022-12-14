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
    return
            (JavaScript::D3::Plots::GetPlotStartingCode(),
             $jsD3ConfigCode.subst('$VER', $v),
             JavaScript::D3::Plots::GetPlotEndingCode(),
            ).join("\n");
}

#============================================================
#| Makes a list plot (scatter plot) for a list of numbers or a list of x-y coordinates.
proto js-d3-list-plot($data, |) is export {*}

multi js-d3-list-plot($data,
                      Str :$background= 'white',
                      Str :$color= 'steelblue',
                      :$width = 600, :$height = 400,
                      Str :plot-label(:$title) = '',
                      Str :$x-axis-label = '', Str :$y-axis-label = '',
                      :$margins = Whatever) {
    return JavaScript::D3::Plots::ListPlot($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$margins);
}

#============================================================
#| Makes a list line plot for a list of numbers or a list of x-y coordinates.
proto js-d3-list-line-plot($data, |) is export {*}

multi js-d3-list-line-plot($data,
                           Str :$background= 'white',
                           Str :$color= 'steelblue',
                           :$width = 600, :$height = 400,
                           Str :plot-label(:$title) = '',
                           Str :$x-axis-label = '', Str :$y-axis-label = '',
                           :$margins = Whatever,
                           :$legends = Whatever) {
    return JavaScript::D3::Plots::ListLinePlot($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$margins,
            :$legends);
}

#============================================================
#| Makes a bar chart for a list of numbers, hash with numeric values, or a dataset with columns C<<Label Value>>.
proto js-d3-bar-chart($data, |) is export {*}

multi js-d3-bar-chart($data,
                      Str :$background= 'white',
                      Str :$color= 'steelblue',
                      :$width = 600, :$height = 400,
                      Str :plot-label(:$title) = '',
                      Str :$x-axis-label = '', Str :$y-axis-label = '',
                      :$margins = Whatever) {
    return JavaScript::D3::Charts::BarChart($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$margins);
}

#============================================================
#| Makes a histogram for a list of numbers.
proto js-d3-histogram($data, |) is export {*}

multi js-d3-histogram($data,
                      Str :$background= 'white',
                      Str :$color= 'steelblue',
                      :$width = 600, :$height = 400,
                      Str :plot-label(:$title) = '',
                      Str :$x-axis-label = '', Str :$y-axis-label = '',
                      :$margins = Whatever) {
    return JavaScript::D3::Charts::Histogram($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$margins);
}

#============================================================
#| Makes a bubble chart for a list of numeric triplets or list of Maps with key C<<x y z>>.
proto js-d3-bubble-chart($data, |) is export {*}

multi js-d3-bubble-chart($data,
                         Str :$background= 'white',
                         Str :$color= 'steelblue',
                         Numeric :$opacity = 0.7,
                         :$width = 600, :$height = 400,
                         Str :plot-label(:$title) = '',
                         Str :$x-axis-label = '', Str :$y-axis-label = '',
                         :$margins = Whatever,
                         :$tooltip = Whatever,
                         :$legends = Whatever) {
    return JavaScript::D3::Charts::BubbleChart($data,
            :$background,
            :$color,
            :$opacity,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$margins,
            :$tooltip,
            :$legends);
}

#============================================================
#| Makes a density-2D chart for a list of numeric pairs or list of Maps with key C<<x y>>.
proto js-d3-density2d-chart($data, |) is export {*}

multi js-d3-density2d-chart($data,
                            Str :$background= 'white',
                            Str :$color= 'steelblue',
                            :$width = 600, :$height = 400,
                            Str :plot-label(:$title) = '',
                            Str :$x-axis-label = '', Str :$y-axis-label = '',
                            :$margins = Whatever,
                            :$method = Whatever) {
    return JavaScript::D3::Charts::Bin2DChart($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$margins,
            :$method);
}