unit module JavaScript::D3;

use JavaScript::D3::Charts;
use JavaScript::D3::Plots;
use JavaScript::D3::Random;
use JavaScript::D3::Images;
use JavaScript::D3::Chess;
use JavaScript::D3::Gauge;
use JavaScript::D3::Graph;
use Hash::Merge;
use JSON::Fast;

#============================================================
#| Resources access
our sub resources {
    %?RESOURCES
}

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

#| Configuration JavaScript code to be executed in %%javascript magic cell in a Jupyter notebook.
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
# Get/ingest named colors
#============================================================

# From https://htmlcolorcodes.com/color-names/ :
#   Modern browsers support 140 named colors, which are listed below.
#   Use them in your HTML and CSS by name, Hex color code or RGB value.

my %namedColors;
sub get-named-colors() {
    if %namedColors.elems == 0 {
        %namedColors = from-json(slurp(%?RESOURCES<named-colors.json>.IO))
    }
    return %namedColors.clone;
}

#============================================================
#| Named HTML and CSS colors, names to hex-codes.
proto sub js-d3-named-colors(|) is export {*}

multi sub js-d3-named-colors() {
    return get-named-colors();
}

multi sub js-d3-named-colors(*@names, Bool:D :p(:$pairs) = False) {
    return $pairs ?? (@names Z=> get-named-colors(){@names}).List !! get-named-colors(){@names};
}

#============================================================
#| Makes a list plot (scatter plot) for a list of numbers or a list of x-y coordinates.
proto js-d3-list-plot($data, |) is export {*}

multi js-d3-list-plot($data, *%args) {
    return JavaScript::D3::Plots::ListPlot($data, |%args);
}

#============================================================
#| Makes a list line plot for a list of numbers or a list of x-y coordinates.
proto js-d3-list-line-plot($data, |) is export {*}

multi js-d3-list-line-plot($data, *%args) {
    return JavaScript::D3::Plots::ListLinePlot($data, |%args);
}

#============================================================
#| Makes a list line plot for a list of numbers or a list of x-y coordinates.
proto js-d3-date-list-plot($data, |) is export {*}

multi js-d3-date-list-plot($data, *%args) {
    return JavaScript::D3::Plots::DateListPlot($data, |%args);
}

#============================================================
#| Makes a bar chart for a list of numbers, hash with numeric values, or a dataset with columns C<<Label Value>>.
proto js-d3-bar-chart($data, |) is export {*}

multi js-d3-bar-chart($data, *%args) {
    return JavaScript::D3::Charts::BarChart($data, |%args);
}

#============================================================
#| Makes a histogram for a list of numbers.
proto js-d3-histogram($data, |) is export {*}

multi js-d3-histogram($data, UInt $number-of-bins, *%args) {
    return JavaScript::D3::Charts::Histogram($data, :$number-of-bins, |%args);
}

multi js-d3-histogram($data, *%args) {
    return JavaScript::D3::Charts::Histogram($data, |%args);
}

#============================================================
#| Makes a box-whisker chart for a list of numbers or data with group and value fields.
proto js-d3-box-whisker-chart($data, |) is export {*}

multi js-d3-box-whisker-chart($data, *%args) {
    return JavaScript::D3::Charts::BoxWhiskerChart($data, |%args);
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
        Bool:D :$symmetric-seed = True,
        :color(:$stroke) is copy = Whatever,
        :$stroke-width is copy = Whatever,
        :$fill is copy = Whatever,
        Str:D :$color-scheme = 'schemeSet2',
        :$background is copy = Whatever,
        UInt:D :$width= 300,
        UInt:D :$height= 300,
        Str:D :plot-label(:$title) = '',
        Str:D :x-label(:$x-axis-label) = '',
        Str:D :y-label(:$y-axis-label) = '',
        :$grid-lines = False,
        :$margins = %(:top(10), :bottom(10), :left(10), :right(10)),
        Bool:D :$axes = False,
        UInt:D :$count = 1,
        Str:D :$format= "jupyter",
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
            .subst(:g, 'd3.schemeSet2', "d3.$color-scheme")
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
#| Makes a random Koch curve.
proto sub js-d3-random-koch-curve(|) is export {*}

multi sub js-d3-random-koch-curve($points, $possdist, $widthdist, $heightdist, Int $n, *%args) {
    my @snowflake = JavaScript::D3::Random::KochCurve($points, $possdist, $widthdist, $heightdist, $n);
    my $width = %args<width> // 600;
    my $height = %args<height> // ($width * max(@snowflake.map(*.tail))),
    my %args2 = %args.grep({ $_.key ∉ <width height axes flip> });
    my $res = js-d3-list-line-plot(
            @snowflake,
            :$width,
            :$height,
            axes => %args<axes> // False,
            |%args2);
    if %args<flip> // False {
        # Hack, but it is simple to implement and works fine
        $res .= subst('.range([height, 0]);', '.range([0, height]);')
    }
    return $res;
}

multi sub js-d3-random-koch-curve(:p(:$position-spec)!, :w(:$width-spec)!, :h(:$height-spec)!, Int :$n!, *%args) {
    return js-d3-random-koch-curve(Whatever, $position-spec, $width-spec, $height-spec, $n, |%args);
}

multi sub js-d3-random-koch-curve($points, :p(:$position-spec)!, :w(:$width-spec)!, :h(:$height-spec)!, Int :$n!, *%args) {
    return js-d3-random-koch-curve($points, $position-spec, $width-spec, $height-spec, $n, |%args);
}

multi sub js-d3-random-koch-curve(UInt:D $n = 4, *%args) {
    return js-d3-random-koch-curve(Whatever, 1/2, 1/3, sqrt(3)/6, $n, |%args);
}

#============================================================
#| Makes a random Mondrian.
proto sub js-d3-random-mondrian(|) is export {*}

multi sub js-d3-random-mondrian(:$width is copy = 800,
                                :$height is copy = Whatever,
                                UInt:D :n(:$max-iterations) = 7,
                                Numeric:D :$jitter = 0,
                                :d(:dist(:$distribution)) = Whatever,
                                :$color-scheme is copy = Whatever,
                                Str:D :stroke(:$stroke-color) = 'Black',
                                Numeric:D :$stroke-width = 4,
                                :fill-color(:$color-palette) is copy = Whatever,
                                Str:D :$background = 'White',
                                :$margins is copy = Whatever,
                                Str:D :$format= "jupyter",
                                :$div-id = Whatever,
                                *%args
                                ) {

    # Process width and height
    ($width, $height) = JavaScript::D3::Utilities::ProcessWidthAndHeight(:$width, :$height);

    # Make rectangles
    my @rects = JavaScript::D3::Random::Mondrian($width, $height, $max-iterations, :$jitter, :$distribution);

    # Get core code
    my $jsCode = [JavaScript::D3::CodeSnippets::GetPlotMarginsAndTitle($format),
                  JavaScript::D3::CodeSnippets::GetMondrianPart()].join("\n");

    #-------------------------------------------------------
    # Process $color-scheme
    #-------------------------------------------------------
    if $color-scheme.isa(Whatever) { $color-scheme = 'None'}
    die 'The argument $color-scheme is expected to be a string or Whatever.'
    unless $color-scheme ~~ Str:D;

    #-------------------------------------------------------
    # Process $color-palette
    #-------------------------------------------------------
    if $color-palette.isa(Whatever) {
        $color-palette = {'#000000' => 1, '#878787' => 1, '#194F9A' => 4, '#BC0118' => 4, '#FACA02' => 4, '#FDFDFD' => 16};
    }
    die 'The argument $color-palette is expected to be a Map or Whatever.'
    unless $color-palette ~~ Map:D;

    #-------------------------------------------------------
    # Margins
    #-------------------------------------------------------
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    #--------------------------------------------------------
    # Finishing
    #--------------------------------------------------------
    $jsCode = $jsCode
            .subst('$DATA', to-json(@rects, :!pretty))
            .subst(:g, '$WIDTH', $width)
            .subst(:g, '$HEIGHT', $height)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty)
            .subst(:g, '$TITLE_FONT_SIZE', %args<title-font-size> // 12)
            .subst(:g, '$TITLE_FILL', '"' ~ (%args<title-color> // '') ~ '"')
            .subst(:g, '$TITLE', '"' ~ (%args<title> // '') ~ '"')
            .subst(:g, '$COLOR_SCHEME', '"' ~ $color-scheme ~ '"')
            .subst(:g, '$COLOR_PALETTE', to-json($color-palette))
            .subst(:g, '$STROKE_COLOR', '"' ~ $stroke-color ~ '"')
            .subst(:g, '$STROKE_WIDTH', $stroke-width);

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
#| Makes a heatmap plot from a coordinates-and-value triplets.
proto js-d3-heatmap-plot(|) is export {*}

multi sub js-d3-heatmap-plot($data, *%args) {
    return JavaScript::D3::Plots::HeatmapPlot($data, |%args);
}

#============================================================
#| Makes an image from a numerical matrix.
proto js-d3-matrix-plot(|) is export {*}

multi sub js-d3-matrix-plot($data, *%args) {
    return JavaScript::D3::Plots::MatrixPlot($data, |%args);
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

#============================================================
#| Makes a graph plot.
proto js-d3-graph-plot(|) is export {*}

multi sub js-d3-graph-plot($data, *%args) {
    return JavaScript::D3::Graph::GraphPlot($data, |%args);
}


#============================================================
#| Makes a clock gauge for given C<:$hour>, C<:$minute>, C<:$second>.
proto js-d3-clock-gauge(|) is export {*}

multi sub js-d3-clock-gauge(*@rgs, *%args) {
    return JavaScript::D3::Gauge::Clock(|@rgs, |%args);
}

#============================================================
# Spirograph
#============================================================

sub SpirographZ($t, $k, $l --> Numeric:D) {
    (1 - $k) * exp(1i * $t) + $k * $l * exp(- 1i * $t * (1 - $k) / $k)
}

#| Spirograph plot.
#| C<:$k> - How big the inner circle Ci is compared to the outer circle Co, r/R.
#| C<:$l> - How far is the plot point from the center Ci.
#| C<:n(:$number-of-cycles)> - Number of cycles to produce the spirograph curve.
#| C<:$number-of-segments> - Number of segments of the spirograph curve.
multi sub js-d3-spirograph(|) is export {*}

multi sub js-d3-spirograph($k, $l, *%args) {
    #die 'The first and second parameters are expected to be numbers between 0 an 1.'
    #unless 0 ≤ $k ≤ 1 && 0 ≤ $l ≤ 1;

    return js-d3-spirograph(:$k, :$l, |%args);
}

multi sub js-d3-spirograph(Numeric:D :$k = 2/5,
                           Numeric:D :$l = 4/11,
                           Numeric:D :r(:$scale) = 1,
                           UInt:D :n(:$number-of-cycles) = 20,
                           UInt:D :$number-of-segments = 2000,
                           UInt:D :$width = 400,
                           :$height is copy = Whatever,
                           Bool:D :$axes = False,
                           *%args ) {
    # Process $k and $l arguments
    # Wrong parameters are fine
    #die 'The parameters $k and $l is are expected to be numbers between 0 an 1.'
    #unless 0 ≤ $k ≤ 1 && 0 ≤ $l ≤ 1;

    # Process height
    if $height.isa(Whatever) || ($height ~~ Int:D) && $height == 0 { $height = $width }
    die 'The agument $height is expected to be a positive integer or Whatever.'
    unless ($height ~~ Int:D) && $height > 0;

    # The points
    my $max-t = 2 * π * $number-of-cycles;
    my $step = $max-t / $number-of-segments;
    my @points = (0, $step ... $max-t).map({ $scale * SpirographZ($_, $k, $l) }).map({ %( x => $_.re, y => $_.im) });

    # Graph
    return js-d3-list-line-plot(@points, :$width, :$height, :$axes, |%args);
}

#============================================================
# Optimization
#============================================================
BEGIN { get-named-colors() }
