unit module JavaScript::D3::Plots3D;

use Hash::Merge;
use JSON::Fast;
use JavaScript::D3::Predicates;
use JavaScript::D3::CodeSnippets;
use JavaScript::D3::CodeSnippets3D;
use JavaScript::D3::Utilities;

#============================================================
# ListPlotGeneric
#============================================================

our proto ListLinePlot3D($data, |) is export {*}

our multi ListLinePlot3D($data where $data ~~ Seq, *%args) {
    return ListLinePlot3D($data.List, |%args);
}

our multi ListLinePlot3D($data where is-positional-of-lists($data, 4), *%args) {
    my @dataPairs = |$data.map({ <x y z group> Z=> $_.List })>>.Hash;
    return ListLinePlot3D(@dataPairs, |%args);
}

our multi ListLinePlot3D($data where is-positional-of-lists($data, 3), *%args) {
    my @dataPairs = |$data.map({ <x y z> Z=> $_.List })>>.Hash;
    return ListLinePlot3D(@dataPairs, |%args);
}

our multi ListLinePlot3D(@data where @data.all ~~ Map,
                         Str :$background = 'White',
                         Str :color(:$stroke-color) = 'SteelBlue',
                         Str :color-palette(:$color-scheme) = 'Set2',
                         :$width = 600,
                         :$height = 400,
                         Str :plot-label(:$title) = '',
                         UInt :plot-label-font-size(:$title-font-size) = 16,
                         Str :plot-label-color(:$title-color) = 'Black',
                         Str:D :x-label(:$x-axis-label) = '',
                         :x-label-color(:$x-axis-label-color) is copy = Whatever,
                         :x-label-font-size(:$x-axis-label-font-size) is copy = Whatever,
                         :$x-axis-scale = Whatever,
                         Str:D :y-label(:$y-axis-label) = '',
                         :y-label-color(:$y-axis-label-color) is copy = Whatever,
                         :y-label-font-size(:$y-axis-label-font-size) is copy = Whatever,
                         :$y-axis-scale = Whatever,
                         Str:D :z-label(:$z-axis-label) = '',
                         :z-label-color(:$z-axis-label-color) is copy = Whatever,
                         :z-label-font-size(:$z-axis-label-font-size) is copy = Whatever,
                         :$z-axis-scale = Whatever,
                         :$tooltip = Whatever,
                         Str :$tooltip-background-color = 'Black',
                         Str :$tooltip-color = 'White',
                         :$box-ratios is copy = Whatever, #= The value [x, y, z] gives the side-length ratios of the corresponding axes.
                         :$view-point is copy = Whatever, #= The value [x,y,z] gives the position of the view point relative to the center of the three-dimensional box that contains the objects.
                         :$view-vertical is copy = Whatever, #= Specifies what direction in scaled coordinates should be vertical in the final image.
                         :$margins is copy = Whatever,
                         :$legends = Whatever,
                         Bool:D :$axes = True,
                         Numeric :$point-size = 6,
                         Numeric :$stroke-width = 1.5,
                         Str:D :$default-type = 'line',
                         Str :$format = 'jupyter',
                         :$div-id = Whatever,
                          ) {
    # Process labels colors and font sizes
    ($x-axis-label-color, $x-axis-label-font-size, $y-axis-label-color, $y-axis-label-font-size) =
            JavaScript::D3::Utilities::ProcessLabelsColorsAndFontSizes(
            :$title-color,
            :$title-font-size,
            :$x-axis-label-color,
            :$x-axis-label-font-size,
            :$y-axis-label-color,
            :$y-axis-label-font-size
            );

    ($x-axis-label-color, $x-axis-label-font-size, $z-axis-label-color, $z-axis-label-font-size) =
            JavaScript::D3::Utilities::ProcessLabelsColorsAndFontSizes(
            :$title-color,
            :$title-font-size,
            :$x-axis-label-color,
            :$x-axis-label-font-size,
            y-axis-label-color => $z-axis-label-color,
            y-axis-label-font-size => $z-axis-label-font-size
            );

    # Process margins
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    # Process box ratios
    if $box-ratios.isa(Whatever) {
        $box-ratios = [1, 1, 0.4]
    }
    die 'The value of $box-ratios is expected a list of three numbers or Whatever.'
    unless $box-ratios ~~ Positional:D && $box-ratios.elems == 3 && $box-ratios.all ~~ Numeric:D;

    # Process view point
    if $view-point.isa(Whatever) {
        $view-point = [1.3, -2.4, 2.0]
    }
    die 'The value of $view-point is expected a list of three numbers or Whatever.'
    unless $view-point ~~ Positional:D && $view-point.elems == 3 && $view-point.all ~~ Numeric:D;

    # Process view vertical
    # The setting is view-vertical => [0,0,1] specifies that the z axis in your original coordinate system should end up vertical in the final image.
    if $view-vertical.isa(Whatever) {
        $view-vertical = [0, 0, 1]
    }
    die 'The value of $view-vertical is expected a list of three numbers or Whatever.'
    unless $view-vertical ~~ Positional:D && $view-vertical.elems == 3 && $view-vertical.all ~~ Numeric:D;

    # Face grids
    # TBD...

    # Clone the data
    my @dataLocal = @data».clone.Array;

    # Groups
    my Bool:D $hasGroups = [&&] @dataLocal.map({ so $_<group> });

    if !$hasGroups {
        @dataLocal = @dataLocal.map({ merge-hash($_, {group => ''}) })
    }

    # Types
    my Bool:D $hasTypes = [&&] @dataLocal.map({ so $_<type> });

    if !$hasTypes {
        @dataLocal = @dataLocal.map({ merge-hash($_, {type => $default-type}) })
    }

    # Tooltips
#    my Bool $hasTooltips = [||] @dataLocal.map({ so $_<tooltip> });

#    if $tooltip ~~ Bool:D && $tooltip && !$hasTooltips {
#        @dataLocal = @dataLocal.map({ $_<tooltip> = "({$_<x>}, {$_<y>})"; $_ });
#        $hasTooltips = True;
#    }

    # Process data
    my $jsData = to-json(@dataLocal, :!pretty);

    # Select code fragment to splice in
    my $jsPlotMiddle = JavaScript::D3::CodeSnippets3D::GetMultiTrajectoryPlotPart();

    # Chose to add legend code fragment or not
    my $maxGroupChars = $hasGroups ?? @dataLocal.map(*<group>).unique>>.chars.max !! 'all'.chars;
    given $legends {
        when $_ ~~ Bool && $_ || $_.isa(Whatever) && $hasGroups {
            $margins<right> = max($margins<right>, ($maxGroupChars + 4) * 12);
            $jsPlotMiddle ~=  "\n" ~ JavaScript::D3::CodeSnippets::GetLegendCode();
        }
    }

    # Stencil
    my $jsScatterPlot = [JavaScript::D3::CodeSnippets::GetPlotMarginsTitleAndLabelsCode($format),
                         $jsPlotMiddle]
            .join("\n");

    # Concrete parameters
    my $res = $jsScatterPlot
            .subst(:g, '$DATA', $jsData)
            .subst(:g, '$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst(:g, '$POINT_COLOR', '"' ~ $stroke-color ~ '"')
            .subst(:g, '$LINE_COLOR', '"' ~ $stroke-color ~ '"')
            .subst(:g, '$COLOR_SCHEME', $color-scheme.starts-with('scheme') ?? $color-scheme !! 'scheme' ~ $color-scheme.tc )
            .subst(:g, '$POINT_RADIUS', round($point-size / 2))
            .subst(:g, '$STROKE_WIDTH', $stroke-width)
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE_FONT_SIZE', $title-font-size)
            .subst(:g, '$TITLE_FILL', '"' ~ $title-color ~ '"')
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$X_AXIS_LABEL_FONT_SIZE', $x-axis-label-font-size)
            .subst(:g, '$X_AXIS_LABEL_FILL', '"' ~ $x-axis-label-color ~ '"')
            .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
            .subst(:g, '$Y_AXIS_LABEL_FONT_SIZE', $y-axis-label-font-size)
            .subst(:g, '$Y_AXIS_LABEL_FILL', '"' ~ $y-axis-label-color ~ '"')
            .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
            .subst(:g, '$Z_AXIS_LABEL_FONT_SIZE', $z-axis-label-font-size)
            .subst(:g, '$Z_AXIS_LABEL_FILL', '"' ~ $z-axis-label-color ~ '"')
            .subst(:g, '$Z_AXIS_LABEL', '"' ~ $z-axis-label ~ '"')
            .subst(:g, '$TOOLTIP_COLOR', '"' ~ $tooltip-color ~ '"')
            .subst(:g, '$TOOLTIP_BACKGROUND_COLOR', '"' ~ $tooltip-background-color ~ '"')
            .subst(:g, '$BOX_RATIOS', to-json($box-ratios):!pretty)
            .subst(:g, '$VIEW_POINT', to-json($view-point):!pretty)
            .subst(:g, '$VIEW_VERTICAL', to-json($view-vertical):!pretty)
            .subst(:g, '$MARGINS', to-json($margins):!pretty)
            .subst(:g, '$LEGEND_X_POS', 'width + 3*12')
            .subst(:g, '$LEGEND_Y_POS', '0')
            .subst(:g, '$LEGEND_Y_GAP', '25')
            ;
#
#    if $hasTooltips {
#        my $marker = '// Trigger the tooltip functions';
#        $res .= subst($marker, $marker ~ "\n" ~ JavaScript::D3::CodeSnippets::GetTooltipMousePart);
#    }

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id, :with-d33d);
}
