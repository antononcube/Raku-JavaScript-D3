unit module JavaScript::D3;

use JavaScript::D3::Charts;
use JavaScript::D3::Plots;
use JavaScript::D3::Random;
use JavaScript::D3::Images;
use JavaScript::D3::Chess;
use Hash::Merge;


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
                      Str :$format = 'jupyter',
                      :$div-id = Whatever) {
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
            :$format, :$div-id);
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
                           Str :$format = 'jupyter',
                           :$div-id = Whatever) {
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
            :$format, :$div-id);
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
                           Str :$format = 'jupyter',
                           :$div-id = Whatever) {
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
            :$format, :$div-id);
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
                      Str :$plot-labels-color = 'black',
                      Str :$plot-labels-font-family = 'Courier',
                      :$plot-labels-font-size is copy = Whatever,
                      :$grid-lines = False,
                      :$margins = Whatever,
                      :$legends = Whatever,
                      Bool :$horizontal = False,
                      Str :$format = 'jupyter',
                      :$div-id = Whatever) {
    return JavaScript::D3::Charts::BarChart($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$plot-labels-color, :$plot-labels-font-family, :$plot-labels-font-size,
            :$grid-lines,
            :$margins,
            :$legends,
            :$horizontal,
            :$format, :$div-id);
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
                      Str :$format = 'jupyter',
                      :$div-id = Whatever) {
    return JavaScript::D3::Charts::Histogram($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$grid-lines,
            :$margins,
            :$format, :$div-id);
}

#============================================================
#| Makes a bubble chart for a list of numeric triplets or list of Maps with key C<<x y z>>.
proto js-d3-bubble-chart($data, |) is export {*}

multi js-d3-bubble-chart($data, *%args) {
    return JavaScript::D3::Charts::BubbleChart($data, |%args);
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
                            Str :$format = 'jupyter',
                            :$div-id = Whatever) {
    return JavaScript::D3::Charts::Bin2DChart($data,
            :$background,
            :$color,
            :$width, :$height,
            :$title,
            :$x-axis-label, :$y-axis-label,
            :$grid-lines,
            :$margins,
            :$method,
            :$format, :$div-id);
}

#============================================================
#| Replicate parameter
sub replicate-to-list(Str $param, $element-type, @whatever-to-roll, $count, $value) {

    my $res = do given $value {
        when Whatever { @whatever-to-roll.roll($count).Array }
        when Numeric { ($_ xx $count).Array }
        when List { ($_ xx $count).flat[^$count].Array }
        when Range { ($_.List xx $count).flat[^$count].Array }
        default { $_ }
    }

    if ! $res ~~ Positional && $res.all ~~ $element-type {
        die "The parameter $param is expected to be {$element-type.raku}, a list of {$element-type.raku}, or Whatever."
    }

    return [|$res];
}

#============================================================
#| Makes a random mandala.
#| C<$data> Positional argument to pass to C<:count>.
#| C<:$radius> Radius of the mandala.
#| C<:$rotational-symmetry-order> Rotational symmetry order.
#| C<:$number-of-seed-element> Number of seed elements.
#| C<:$connecting-function> Connecting function.
#| C<:$symmetric-seed> Should the seed be symmetric or not?
#| C<:color(:$stroke)> Color of the stroke.
#| C<:$stroke-width> Width of the stroke.
#| C<:$fill> Filling color.
#| C<:$background> Background color.
#| C<:$width> Width of a single mandala plot.
#| C<:$height> Height of a single mandala plot.
#| C<:plot-label(:$title)> Plot title.
#| C<:x-label(:$x-axis-label)> X-axis label.
#| C<:y-label(:$y-axis-label)> Y-axis label.
#| C<:$grid-lines> Should grid lines be placed or not?
#| C<:$margins> A hash with the keys top, bottom, left right, for the margins of a single plot.
#| C<:$axes> Should axes be placed or not?
#| C<:$count> Number of mandalas.
#| C<:$format> Format of the generated code, one of "asis", "html", "html-md", or "jupyter".
#| C<:$div-id> Div identifier tag.
proto js-d3-random-mandala(|) is export {*}

multi js-d3-random-mandala($data, *%args) {
    my $count = do given $data {
        when Positional { $data[0] }
        when UInt { $data }
        default { 1 }
    };

    return js-d3-random-mandala(|merge-hash(%(:$count), %args));
}

multi js-d3-random-mandala(
        :$radius is copy = 1,
        :$rotational-symmetry-order is copy = 6,
        :$number-of-seed-elements is copy = Whatever,
        :$connecting-function is copy = 'curveBasis',
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
        :$margins = %(:top(10), :bottom(10), :left(10), :right(10)),
        Bool :$axes = False,
        UInt :$count = 1,
        Str :$format= "jupyter",
        :$div-id = Whatever) {

    #--------------------------------------------------------
    # Process options
    #--------------------------------------------------------

    # Radius
    if $radius.isa(Whatever) {
        $radius = 1;
    }
    die 'The parameter radius is expected to be a positive number or Whatever.'
    unless $radius ~~ Numeric && $radius > 0;

    # Rotational symmetry order
    $rotational-symmetry-order = replicate-to-list('rotational-symmetry-order', Numeric, [4, 5, 6, 7, 9, 12], $count, $rotational-symmetry-order);

    die 'The parameter rotational-symmetry-order is expected to be a positive number, a list of positive numbers, or Whatever.'
    unless $rotational-symmetry-order.all > 0;

    # Number of seed elements
    $number-of-seed-elements = replicate-to-list('number-of-seed-elements', Int, (5 ... 10), $count, $number-of-seed-elements);

    die 'The parameter number-of-seed-elements is expected to be a positive integer, a list of positive integers, or Whatever.'
    unless $rotational-symmetry-order.all > 0;

    # Connecting function
    my $d3Curves = <curveLinear curveStep curveStepAfter curveStepBefore curveBasis curveBasisClosed curveCardinal curveCatmullRom curveMonotoneX curveMonotoneY curveBundle>;
    my $d3ShortCurves = $d3Curves.map({ $_.substr(5) }).List;
    if $connecting-function.isa(Whatever) {
        $connecting-function = $d3Curves.pick;
    }
    if $connecting-function ∈ $d3ShortCurves {
        $connecting-function = 'curve' ~ $connecting-function;
    }
    die 'Them parameter connecting-function is expected to be Whatever or a string, one of ' ~ $d3Curves.join(', ') ~ '.'
    unless $connecting-function ~~ Str && $connecting-function ∈ $d3Curves;

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
    # Random mandala
    #--------------------------------------------------------
    my $jsCode = '';
    for ^$count -> $i {

        # Random mandala points
        my @randomMandala =
                JavaScript::D3::Random::Mandala(
                :$radius,
                rotational-symmetry-order => $rotational-symmetry-order[$i],
                number-of-seed-elements => $number-of-seed-elements[$i],
                :$symmetric-seed
                );

        $jsCode ~= js-d3-list-line-plot(
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
                format => 'asis');
    }

    #--------------------------------------------------------
    # Finishing
    #--------------------------------------------------------

    $jsCode = $jsCode
            .subst(:g, '.attr("stroke-width", 1.5)',
                    '.attr("stroke-width", ' ~ $stroke-width.Str ~ ').attr("fill", "' ~ $fill ~ '")')
            .subst(:g, '.attr("stroke", function(d){ return myColor(d[0]) })', '.attr("stroke", "' ~ $stroke ~ '")')
            .subst(:g, '.y(function(d) { return y(+d.y); })',
                    '.y(function(d) { return y(+d.y); }).curve(d3.' ~ $connecting-function ~ ')');

    return JavaScript::D3::CodeSnippets::WrapIt($jsCode, :$format, :$div-id);
}


#============================================================
#| Makes a random scribble.
proto js-d3-random-scribble(|) is export {*}

multi js-d3-random-scribble($data, *%args) {
    my $count = do given $data {
        when Positional { $data[0] }
        when UInt { $data[0] }
        default { 1 }
    };

    return js-d3-random-scribble(|merge-hash(%(:$count), %args));
}

multi js-d3-random-scribble(
        :$number-of-strokes is copy = 120,
        Bool :$ordered-stroke-points = True,
        :$rotation-angle is copy = Whatever,
        :$envelope-functions = Whatever,
        :$connecting-function is copy = 'curveBasis',
        :color(:$stroke) is copy = Whatever,
        :$stroke-width is copy = Whatever,
        :$fill is copy = Whatever,
        :$background is copy = Whatever,
        :$gradient-colors is copy = False,
        UInt :$width= 300,
        UInt :$height= 300,
        Str :plot-label(:$title) = '',
        Str :x-label(:$x-axis-label) = '',
        Str :y-label(:$y-axis-label) = '',
        :$grid-lines = False,
        :$margins = %(:top(10), :bottom(10), :left(10), :right(10)),
        Bool :$axes = False,
        UInt :$count = 1,
        Str :$format= "jupyter",
        :$div-id = Whatever) {

    #--------------------------------------------------------
    # Process options
    #--------------------------------------------------------
    # Number of seed elements
    $number-of-strokes = replicate-to-list('number-of-strokes', UInt, [120, 80], $count, $number-of-strokes);

    # Rotation angle
    $rotation-angle = replicate-to-list('rotation-angle', Numeric, [0, π/3, π/4, π/6],  $count, $rotation-angle);

    # Connecting function
    my $d3Curves = <curveLinear curveStep curveStepAfter curveStepBefore curveBasis curveBasisClosed curveCardinal curveCatmullRom curveMonotoneX curveMonotoneY curveBundle>;
    my $d3ShortCurves = $d3Curves.map({ $_.substr(5) }).List;
    if $connecting-function.isa(Whatever) {
        $connecting-function = $d3Curves.pick;
    }
    if $connecting-function ∈ $d3ShortCurves {
        $connecting-function = 'curve' ~ $connecting-function;
    }
    die 'Them parameter connecting-function is expected to be Whatever or a string, one of ' ~ $d3Curves.join(', ') ~ '.'
    unless $connecting-function ~~ Str && $connecting-function ∈ $d3Curves;

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
    # Random Scribble
    #--------------------------------------------------------

    my $jsCode = '';
    for ^$number-of-strokes -> $i {

        my @randomScribble =
                JavaScript::D3::Random::Scribble(
                number-of-strokes => $number-of-strokes[$i],
                rotation-angle => $rotation-angle[$i],
                :$ordered-stroke-points,
                :$envelope-functions
                );

        $jsCode ~= js-d3-list-line-plot(
                @randomScribble,
                :$width, :$height,
                :$title,
                :$x-axis-label,
                :$y-axis-label,
                :$background,
                :$margins,
                :$grid-lines,
                :!legends,
                :$axes,
                format => 'asis');
    }

    #--------------------------------------------------------
    # Finishing
    #--------------------------------------------------------

    $jsCode = $jsCode
            .subst(:g, '.attr("stroke-width", 1.5)',
                    '.attr("stroke-width", ' ~ $stroke-width.Str ~ ').attr("fill", "' ~ $fill ~ '")')
            .subst(:g, '.attr("stroke", function(d){ return myColor(d[0]) })', '.attr("stroke", "' ~ $stroke ~ '")')
            .subst(:g, '.y(function(d) { return y(+d.y); })',
                    '.y(function(d) { return y(+d.y); }).curve(d3.' ~ $connecting-function ~ ')');

    $gradient-colors = do given $gradient-colors {
        when Str { [$gradient-colors, 'gray'] }
        when $_ ~~ List && $_.elems == 1 { [$gradient-colors[0], 'gray'] }
        when $_ ~~ List && $_.elems == 2 { $gradient-colors }
        when Whatever { <blue red> }
        when $_ ~~ Bool && $_ { <blue red> }
        when $_ ~~ Bool && !$_ { Empty }
        default {
            note 'Do not know how to process the given gradient-colors.';
            <blue red>
        }
    }

    if $gradient-colors ~~ List && $gradient-colors.elems == 2 {
        $jsCode = $jsCode
                .subst(:g,
                        "// Add the path using this helper function",
                        JavaScript::D3::CodeSnippets::GetLinearGradientCode(color0 => $gradient-colors[0], color100 => $gradient-colors[1])
                                ~ "\n" ~ '// Add the path using this helper function')
                .subst(:g, / '.attr(\'stroke\'' .*?  \n /, '.attr("stroke", "url(#line-gradient)" )')
    }

    return JavaScript::D3::CodeSnippets::WrapIt($jsCode, :$format, :$div-id);
}

#============================================================
#| Displays the image using a given URL or file name.
proto js-d3-image-display(|) is export {*}

multi sub js-d3-image-display(
        Str $spec,
        :$width = Whatever,
        :$height = Whatever,
        :$format = 'jupyter',
        :$div-id = Whatever) {

    return JavaScript::D3::Images::ImageDisplay($spec, :$width, :$height, :$format, :$div-id);
}

#============================================================
#| Makes an image from a numerical matrix.
proto js-d3-image(|) is export {*}

multi sub js-d3-image(
        $data,
        Str :$color-palette = "Greys",
        :$width = Whatever,
        :$height = Whatever,
        :$low-value is copy = Whatever,
        :$high-value is copy = Whatever,
        Str :$format = 'jupyter',
        :$div-id = Whatever) {

    return JavaScript::D3::Images::Image($data, :$color-palette, :$width, :$height, :$low-value, :$high-value, :$format, :$div-id);
}

#============================================================
#| Makes an image from a numerical matrix.
proto js-d3-heatmap-plot(|) is export {*}

multi sub js-d3-heatmap-plot($data, *%args) {
    return JavaScript::D3::Plots::HeatmapPlot($data, |%args);
}

#============================================================
#| Makes a chessboard position plot.
proto js-d3-chessboard(|) is export {*}

multi sub js-d3-chessboard(*%args) {
    return JavaScript::D3::Chess::Chessboard(|%args);
}
multi sub js-d3-chessboard($data, *%args) {
    return JavaScript::D3::Chess::Chessboard($data, |%args);
}