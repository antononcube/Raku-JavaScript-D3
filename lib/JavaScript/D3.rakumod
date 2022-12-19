use v6.d;

use JavaScript::D3::Charts;
use JavaScript::D3::Plots;
use JavaScript::D3::RandomMandala;
use Hash::Merge;

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

multi js-d3-config(:$v = 7, Bool :$direct = True) is export {
    if $direct {
        return $jsD3ConfigCode.subst('$VER', $v);
    } else {
        return (JavaScript::D3::Plots::GetPlotStartingCode(),
                $jsD3ConfigCode.subst('$VER', $v),
                JavaScript::D3::Plots::GetPlotEndingCode(),
        ).join("\n");
    }
}

#============================================================
#| Makes a list plot (scatter plot) for a list of numbers or a list of x-y coordinates.
proto js-d3-list-plot($data, |) is export {*}

multi js-d3-list-plot($data,
                      Str :$background= 'white',
                      Str :$color= 'steelblue',
                      :$width = 600, :$height = 400,
                      Str :plot-label(:$title) = '',
                      Str :x-label(:$x-axis-label) = '',
                      Str :y-label(:$y-axis-label) = '',
                      :$grid-lines = False,
                      :$margins = Whatever,
                      :$legends = Whatever,
                      Bool :$axes = True,
                      Str :$format = 'jupyter') {
    return JavaScript::D3::Plots::ListPlot($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$grid-lines,
            :$margins,
            :$legends,
            :$axes,
            :$format);
}

#============================================================
#| Makes a list line plot for a list of numbers or a list of x-y coordinates.
proto js-d3-list-line-plot($data, |) is export {*}

multi js-d3-list-line-plot($data,
                           Str :$background= 'white',
                           Str :$color= 'steelblue',
                           :$width = 600, :$height = 400,
                           Str :plot-label(:$title) = '',
                           Str :x-label(:$x-axis-label) = '',
                           Str :y-label(:$y-axis-label) = '',
                           :$grid-lines = False,
                           :$margins = Whatever,
                           :$legends = Whatever,
                           Bool :$axes = True,
                           Str :$format = 'jupyter') {
    return JavaScript::D3::Plots::ListLinePlot($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$grid-lines,
            :$margins,
            :$legends,
            :$axes,
            :$format);
}

#============================================================
#| Makes a list line plot for a list of numbers or a list of x-y coordinates.
proto js-d3-date-list-plot($data, |) is export {*}

multi js-d3-date-list-plot($data,
                           Str :$background= 'white',
                           Str :$color= 'steelblue',
                           :$width = 600, :$height = 400,
                           Str :plot-label(:$title) = '',
                           Str :date-axis-label(:$x-axis-label) = '',
                           Str :value-axis-label(:$y-axis-label) = '',
                           Str :$time-parse-spec = "%Y-%m-%d",
                           :$grid-lines = False,
                           :$margins = Whatever,
                           :$legends = Whatever,
                           Bool :$axes = True,
                           Str :$format = 'jupyter') {
    return JavaScript::D3::Plots::DateListPlot($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$time-parse-spec,
            :$grid-lines,
            :$margins,
            :$legends,
            :$axes,
            :$format);
}

#============================================================
#| Makes a bar chart for a list of numbers, hash with numeric values, or a dataset with columns C<<Label Value>>.
proto js-d3-bar-chart($data, |) is export {*}

multi js-d3-bar-chart($data,
                      Str :$background= 'white',
                      Str :$color= 'steelblue',
                      :$width = 600, :$height = 400,
                      Str :plot-label(:$title) = '',
                      Str :x-label(:$x-axis-label) = '',
                      Str :y-label(:$y-axis-label) = '',
                      :$grid-lines = False,
                      :$margins = Whatever,
                      :$legends = Whatever,
                      Str :$format = 'jupyter') {
    return JavaScript::D3::Charts::BarChart($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$grid-lines,
            :$margins,
            :$legends,
            :$format);
}

#============================================================
#| Makes a histogram for a list of numbers.
proto js-d3-histogram($data, |) is export {*}

multi js-d3-histogram($data,
                      Str :$background= 'white',
                      Str :$color= 'steelblue',
                      :$width = 600, :$height = 400,
                      Str :plot-label(:$title) = '',
                      Str :x-label(:$x-axis-label) = '',
                      Str :y-label(:$y-axis-label) = '',
                      :$grid-lines = False,
                      :$margins = Whatever,
                      Str :$format = 'jupyter') {
    return JavaScript::D3::Charts::Histogram($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$grid-lines,
            :$margins,
            :$format);
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
                         Str :x-label(:$x-axis-label) = '',
                         Str :y-label(:$y-axis-label) = '',
                         :$grid-lines = False,
                         :$margins = Whatever,
                         :$tooltip = Whatever,
                         :$legends = Whatever,
                         Str :$format = 'jupyter') {
    return JavaScript::D3::Charts::BubbleChart($data,
            :$background,
            :$color,
            :$opacity,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$grid-lines,
            :$margins,
            :$tooltip,
            :$legends,
            :$format);
}

#============================================================
#| Makes a density-2D chart for a list of numeric pairs or list of Maps with key C<<x y>>.
proto js-d3-density2d-chart($data, |) is export {*}

multi js-d3-density2d-chart($data,
                            Str :$background= 'white',
                            Str :$color= 'steelblue',
                            :$width = 600, :$height = 400,
                            Str :plot-label(:$title) = '',
                            Str :x-label(:$x-axis-label) = '',
                            Str :y-label(:$y-axis-label) = '',
                            :$grid-lines = False,
                            :$margins = Whatever,
                            :$method = Whatever,
                            Str :$format = 'jupyter') {
    return JavaScript::D3::Charts::Bin2DChart($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$grid-lines,
            :$margins,
            :$method,
            :$format);
}

#============================================================
#| Makes a random mandala.
proto js-d3-random-mandala(|) is export {*}

multi js-d3-random-mandala($data, *%args) {
    my $rso = do given $data {
        when Positional { $data[0] }
        when UInt { $data[0] }
        default { 6 }
    };

    return js-d3-random-mandala(|merge-hash(%(rotational-symmetry-order => $rso), %args));
}

multi js-d3-random-mandala(
        Int :$rotational-symmetry-order = 6,
        :$number-of-seed-elements is copy = Whatever,
        :$connecting-function is copy = 'curveBasisClosed',
        Bool :$symmetric-seed = True,
        :color(:$stroke) is copy = Whatever,
        :$stroke-width is copy = Whatever,
        :$fill is copy = Whatever,
        :$background is copy = Whatever,
        UInt :$width= 300,
        UInt :$height= 300,
        Str :plot-label(:$title) = '',
        Str :x-label(:$x-axis-label) = '',
        Str :y-label(:$y-axis-label) = '',
        :$grid-lines = False,
        :$margins = %(:top(0), :bottom(0), :left(0), :right(0)),
        Bool :$axes = False,
        Str :$format= "jupyter") {

    #--------------------------------------------------------
    # Process options
    #--------------------------------------------------------
    # Number of seed elements
    if $number-of-seed-elements.isa(Whatever) {
        $number-of-seed-elements = 10;
    }
    die 'The parameter number-of-seed-elements is expected to be a non-negative integer or Whatever.'
    unless $number-of-seed-elements ~~ UInt;

    # Connecting function
    my $d3Curves = <curveLinear curveStep curveStepAfter curveStepBefore curveBasis curveBasisClosed curveCardinal curveCatmullRom curveMonotoneX curveMonotoneY curveBundle>;
    if $connecting-function.isa(Whatever) {
        $connecting-function = $d3Curves.pick;
    }
    die 'Them parameter connecting-function is expected to be a string or Whatever.'
    unless $connecting-function ~~ Str;

    # Stroke
    if $stroke.isa(Whatever) {
        $stroke = 'gray';
    }
    die 'Them parameter stroke is expected to be a string or Whatever.'
    unless $stroke ~~ Str;

    # Stroke width
    if $stroke-width.isa(Whatever) {
        $stroke-width = 1.5;
    }
    die 'Them parameter stroke-width is expected to be a positive number or Whatever.'
    unless $stroke-width ~~ Numeric && $stroke-width > 0;

    # Fill
    if $fill.isa(Whatever) {
        $fill = 'rgb(100,100,100)';
    }
    die 'Them parameter fill is expected to be a string or Whatever.'
    unless $fill ~~ Str;

    # Background
    if $background.isa(Whatever) {
        $background = 'none';
    }
    die 'Them parameter background is expected to be a string or Whatever.'
    unless $background ~~ Str;

    #--------------------------------------------------------
    # Random mandala points
    #--------------------------------------------------------

    my @randomMandala =
            JavaScript::D3::RandomMandala::RandomMandala(
            :$rotational-symmetry-order
            :$number-of-seed-elements,
            :$symmetric-seed
            );

    #--------------------------------------------------------
    # Finishing
    #--------------------------------------------------------

    my $jsCode = js-d3-list-line-plot(
            @randomMandala,
            :$width, :$height,
            :$title,
            :$x-axis-label,
            :$y-axis-label,
            :$background,
            :$margins,
            :$grid-lines,
            :!legends,
            :$axes,
            :$format);

    return $jsCode
            .subst('.attr("stroke-width", 1.5)',
                    '.attr("stroke-width", ' ~ $stroke-width.Str ~ ').attr("fill", "' ~ $fill ~ '")')
            .subst('.attr("stroke", function(d){ return myColor(d[0]) })', '.attr("stroke", "' ~ $stroke ~ '")')
            .subst('.y(function(d) { return y(+d.y); })',
                    '.y(function(d) { return y(+d.y); }).curve(d3.' ~ $connecting-function ~ ')');
}