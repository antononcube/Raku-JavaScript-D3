unit module JavaScript::D3::Charts;

use JSON::Fast;
use JavaScript::D3::CodeSnippets;
use JavaScript::D3::Predicates;
use JavaScript::D3::Utilities;


#============================================================
# BarChart
#============================================================

#| Makes a bar chart for a list of numbers or a hash with numeric values.
our proto BarChart($data, |) is export {*}

our multi BarChart($data where $data ~~ Seq, *%args) {
    return BarChart($data.List, |%args);
}

our multi BarChart($data where $data ~~ Positional && $data.all ~~ Numeric, *%args) {
    my $k = 1;
    my @dataPairs = |$data.map({ <variable value> Z=> ($k++, $_) })>>.Hash;
    return BarChart(@dataPairs, |%args);
}

our multi BarChart(%data, *%args) {
    my @dataPairs = %data.map({ %(variable => $_.key, value => $_.value) }).Array;
    return BarChart(@dataPairs, |%args);
}

our multi BarChart(@data is copy where @data.all ~~ Map,
                   Str :$background= 'white',
                   Str :$color= 'steelblue',
                   :$width = 600,
                   :$height = 400,
                   Str :plot-label(:$title) = '',
                   UInt :plot-label-font-size(:$title-font-size) = 16,
                   Str :plot-label-color(:$title-color) = 'Black',
                   Str :x-label(:$x-axis-label) = '',
                   :x-label-color(:$x-axis-label-color) is copy = Whatever,
                   :x-label-font-size(:$x-axis-label-font-size) is copy = Whatever,
                   Str :y-label(:$y-axis-label) = '',
                   :y-label-color(:$y-axis-label-color) is copy = Whatever,
                   :y-label-font-size(:$y-axis-label-font-size) is copy = Whatever,
                   :$plot-labels-color is copy = Whatever,
                   Str :$plot-labels-font-family = 'Courier',
                   :$plot-labels-font-size is copy = Whatever,
                   :$grid-lines is copy = False,
                   :$margins is copy = Whatever,
                   :$legends = Whatever,
                   Bool :$horizontal = False,
                   Str :$format = 'jupyter',
                   :$div-id = Whatever
                   ) {

    #-------------------------------------------------------
    # Process labels colors and font sizes
    #-------------------------------------------------------
    ($x-axis-label-color, $x-axis-label-font-size, $y-axis-label-color, $y-axis-label-font-size) =
            JavaScript::D3::Utilities::ProcessLabelsColorsAndFontSizes(
            :$title-color,
            :$title-font-size,
            :$x-axis-label-color,
            :$x-axis-label-font-size,
            :$y-axis-label-color,
            :$y-axis-label-font-size
            );

    #-------------------------------------------------------
    # Process $plot-labels-font-size
    #-------------------------------------------------------
    $plot-labels-font-size = do given $plot-labels-font-size {
        when Whatever { 'function(d) { return Math.max(width / 200, 4) + "px" }' }
        when $_ ~~ Int:D && $_ ≥ 0 { "\"{$_.Str}px\"" }
        when Str:D {}
        default {
            die 'The argument $plot-labels-font-size is expected to be a string, a non-negative integer, or Whatever.';
        }
    }

    #-------------------------------------------------------
    # Process $plot-labels-color
    #-------------------------------------------------------
    if $plot-labels-color.isa(Whatever) {
        $plot-labels-color = $x-axis-label-color;
    }

    die 'The argument $plot-labels-color is expected to be a string or Whatever.'
    unless $plot-labels-color ~~ Str:D;

    #-------------------------------------------------------
    # Normalize data
    #-------------------------------------------------------
    if [&&] @data.map({ so $_<group> }) {
        @data = JavaScript::D3::Utilities::NormalizeData(@data, columns-from => Whatever, columns-to => Whatever);
    } else {
        @data = JavaScript::D3::Utilities::NormalizeData(@data, columns-from => Whatever, columns-to => Whatever);
    }

    #-------------------------------------------------------
    # Chart creation
    #-------------------------------------------------------
    # Convert to JSON data
    my $jsData = to-json(@data, :!pretty);

    # Grid lines
    $grid-lines = JavaScript::D3::Utilities::ProcessGridLines($grid-lines);

    # Margins
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    # Groups
    my Bool $hasGroups = [&&] @data.map({ (<group x y> (&) $_).elems == 3 });

    note "Multi-dataset bar plots require all records to have the keys <group x y>."
    when !$hasGroups && ( [&&] @data.map({ so $_<group> }) );

    # Select code fragment to splice in
    my $jsPlotMiddle;
    if $hasGroups {
        if $horizontal {
            die 'The option horizontal is implemented only for data without groups.';
        }
        $jsPlotMiddle = JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(|$grid-lines, JavaScript::D3::CodeSnippets::GetMultiBarChartPart()),
    } else {
        $jsPlotMiddle = JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(|$grid-lines, JavaScript::D3::CodeSnippets::GetBarChartPart(:$horizontal)),
    }

    # Chose to add legend code fragment or not
    my $maxGroupChars = $hasGroups ?? @data.map(*<group>).unique>>.chars.max !! 'all'.chars;
    given $legends {
        when $_ ~~ Bool && $_ || $_.isa(Whatever) && $hasGroups {
            $margins<right> = max($margins<right>, ($maxGroupChars + 4) * 12);
            $jsPlotMiddle ~=  "\n" ~ JavaScript::D3::CodeSnippets::GetLegendCode().subst('return o.group;', "return o.x;");
        }
    }

    # Stencil code
    my $jsChart = [JavaScript::D3::CodeSnippets::GetPlotMarginsTitleAndLabelsCode($format),
                   $jsPlotMiddle].join("\n");

    # Concrete values
    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
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
            .subst(:g, '$MARGINS', to-json($margins):!pretty)
            .subst(:g, '$LEGEND_X_POS', 'width + 3*12')
            .subst(:g, '$LEGEND_Y_POS', '0')
            .subst(:g, '$LEGEND_Y_GAP', '25');

    # Fill in plot label data
    if !$hasGroups && ([&&] @data.map({ $_<label> // False })) {

        $res = $res ~ "\n" ~ JavaScript::D3::CodeSnippets::GetBarChartLabelsPart(:$horizontal);

        $res = $res
                .subst('$PLOT_LABELS_DATA', $jsData)
                .subst('$PLOT_LABELS_COLOR', '"' ~ $plot-labels-color ~ '"')
                .subst(:g, '$PLOT_LABELS_FONT_SIZE', $plot-labels-font-size)
                .subst(:g, '$PLOT_LABELS_FONT_FAMILY', $plot-labels-font-family)
                .subst('$PLOT_LABELS_Y_OFFSET', '5');
    }

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id );
}

#============================================================
# Histogram
#============================================================

#| Makes a histogram for a list of numbers.
our proto Histogram($data, |) is export {*}

our multi Histogram($data, UInt $number-of-bins, *%args) {
    return Histogram($data, :$number-of-bins, |%args);
}

our multi Histogram($data where $data ~~ Seq, *%args) {
    return Histogram($data.List, |%args);
}

our multi Histogram(@data where @data.all ~~ Numeric,
                    UInt :bins(:$number-of-bins) = 20,
                    Str :$background= 'white',
                    Str :$color= 'steelblue',
                    :$width = 600,
                    :$height = 400,
                    Str :plot-label(:$title) = '',
                    UInt :plot-label-font-size(:$title-font-size) = 16,
                    Str :plot-label-color(:$title-color) = 'Black',
                    Str :x-label(:$x-axis-label) = '',
                    :x-label-color(:$x-axis-label-color) is copy = Whatever,
                    :x-label-font-size(:$x-axis-label-font-size) is copy = Whatever,
                    Str :y-label(:$y-axis-label) = '',
                    :y-label-color(:$y-axis-label-color) is copy = Whatever,
                    :y-label-font-size(:$y-axis-label-font-size) is copy = Whatever,
                    :$grid-lines is copy = False,
                    :$margins is copy = Whatever,
                    Str :$format = 'jupyter',
                    :$div-id = Whatever
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

    # Process data
    my $jsData = to-json(@data, :!pretty);

    # Grid lines
    $grid-lines = JavaScript::D3::Utilities::ProcessGridLines($grid-lines);

    # Margins
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    # Stencil code
    my $jsChart = [JavaScript::D3::CodeSnippets::GetPlotMarginsTitleAndLabelsCode($format),
                   JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(|$grid-lines, JavaScript::D3::CodeSnippets::GetHistogramPart())].join("\n");

    # Concrete values
    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$NUMBER_OF_BINS', $number-of-bins)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
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
            .subst(:g, '$MARGINS', to-json($margins):!pretty);

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}


#============================================================
# Box-Whisker chart
#============================================================

#| Makes a histogram for a list of numbers.
our proto BoxWhiskerChart($data, |) is export {*}

our multi BoxWhiskerChart($data where $data ~~ Seq, *%args) {
    return BoxWhiskerChart($data.List, |%args);
}

our multi BoxWhiskerChart(@data where @data.all ~~ Numeric,
                          Bool :$outliers = True,
                          Bool :$horizontal = False,
                          UInt :$box-width = 50,
                          Str :$background = 'white',
                          Str :color(:$fill-color) = 'steelblue',
                          Str :$stroke-color = 'black',
                          :$width is copy = Whatever,
                          :$height is copy = Whatever,
                          Str :plot-label(:$title) = '',
                          UInt :plot-label-font-size(:$title-font-size) = 16,
                          Str :plot-label-color(:$title-color) = 'Black',
                          Str :x-label(:$x-axis-label) = '',
                          :x-label-color(:$x-axis-label-color) is copy = Whatever,
                          :x-label-font-size(:$x-axis-label-font-size) is copy = Whatever,
                          Str :y-label(:$y-axis-label) = '',
                          :y-label-color(:$y-axis-label-color) is copy = Whatever,
                          :y-label-font-size(:$y-axis-label-font-size) is copy = Whatever,
                          :$grid-lines is copy = False,
                          :$margins is copy = Whatever,
                          Str :$format = 'jupyter',
                          :$div-id = Whatever
                          ) {

    # Process width and height
    ($width, $height) = JavaScript::D3::Utilities::ProcessWidthAndHeight(:$width, :$height, aspect-ratio => $horizontal ?? 1/2 !! 2);

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

    # Process data
    my $jsData = to-json(@data, :!pretty);

    # Grid lines
    $grid-lines = JavaScript::D3::Utilities::ProcessGridLines($grid-lines);

    # Margins
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    # Stencil code
    my $jsChart = [JavaScript::D3::CodeSnippets::GetPlotMarginsAndTitle($format),
                   JavaScript::D3::CodeSnippets::GetBoxWhiskerChartPart(:$horizontal)].join("\n");

    # Concrete values
    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$BOX_WIDTH', $box-width)
            .subst(:g, '$OUTLIERS', $outliers ?? 'true' !! 'false')
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst(:g, '$FILL_COLOR', '"' ~ $fill-color ~ '"')
            .subst(:g, '$STROKE_COLOR', '"' ~ $stroke-color ~ '"')
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
            .subst(:g, '$MARGINS', to-json($margins):!pretty);

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}

our multi BoxWhiskerChart(@data where @data.all ~~ Map:D,
                          Bool :$outliers = True,
                          Bool :$horizontal = False,
                          Str :group(:$group-column-name) = 'group',
                          Str :value(:$value-column-name) = 'value',
                          UInt :$box-width = 50,
                          Str :$background = 'white',
                          Str :$color = 'steelblue',
                          :$width = 600,
                          :$height = 400,
                          Str :plot-label(:$title) = '',
                          UInt :plot-label-font-size(:$title-font-size) = 16,
                          Str :plot-label-color(:$title-color) = 'Black',
                          Str :x-label(:$x-axis-label) = '',
                          :x-label-color(:$x-axis-label-color) is copy = Whatever,
                          :x-label-font-size(:$x-axis-label-font-size) is copy = Whatever,
                          Str :y-label(:$y-axis-label) = '',
                          :y-label-color(:$y-axis-label-color) is copy = Whatever,
                          :y-label-font-size(:$y-axis-label-font-size) is copy = Whatever,
                          :$grid-lines is copy = False,
                          :$margins is copy = Whatever,
                          Str :$format = 'jupyter',
                          :$div-id = Whatever
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

    # Process data
    my $jsData = to-json(@data.map({
        my %h = $_.clone;
        %h<group> = %h{$group-column-name};
        %h<value> = %h{$value-column-name};
        %h
    }), :!pretty);

    # Grid lines
    $grid-lines = JavaScript::D3::Utilities::ProcessGridLines($grid-lines);

    # Margins
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    # Stencil code
    my $jsChart = [JavaScript::D3::CodeSnippets::GetPlotMarginsAndTitle($format),
                   JavaScript::D3::CodeSnippets::GetBoxWhiskerChartPart].join("\n");

    # Concrete values
    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$GROUP_COLUMN', '"' ~ $group-column-name ~ '"')
            .subst('$VALUE_COLUMN', '"' ~ $value-column-name ~ '"')
            .subst('$BOX_WIDTH', $box-width)
            .subst(:g, '$OUTLIERS', $outliers ?? 'TRUE' !! 'FALSE')
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
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
            .subst(:g, '$MARGINS', to-json($margins):!pretty);

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}

#============================================================
# BubbleChart
#============================================================

#| Makes a bubble chart for list of triplets..
our proto BubbleChart($data, |) is export {*}

our multi BubbleChart($data where $data ~~ Seq, *%args) {
    return BubbleChart($data.List, |%args);
}

our multi BubbleChart($data where is-positional-of-lists($data, 4), *%args) {
    my @data2 = $data.map({ %( <x y z group>.Array Z=> $_.Array) });
    return BubbleChart(@data2, |%args);
}

our multi BubbleChart($data where is-positional-of-lists($data, 3), *%args) {
    my @data2 = $data.map({ %( <x y z>.Array Z=> $_.Array) });
    return BubbleChart(@data2, |%args);
}

our multi BubbleChart($data where is-positional-of-lists($data, 2), *%args) {
    return BubbleChart($data.map({ [|$_, 1] }), |%args);
}

our multi BubbleChart(@data is copy where @data.all ~~ Map,
                      Numeric :$z-range-min = 1,
                      Numeric :$z-range-max = 40,
                      Str :$background= 'white',
                      Str :$color= 'steelblue',
                      Numeric :$opacity = 0.7,
                      :$width = 600,
                      :$height = 600,
                      Str :plot-label(:$title) = '',
                      UInt :plot-label-font-size(:$title-font-size) = 16,
                      Str :plot-label-color(:$title-color) = 'Black',
                      Str :x-label(:$x-axis-label) = '',
                      :x-label-color(:$x-axis-label-color) is copy = Whatever,
                      :x-label-font-size(:$x-axis-label-font-size) is copy = Whatever,
                      Str :y-label(:$y-axis-label) = '',
                      :y-label-color(:$y-axis-label-color) is copy = Whatever,
                      :y-label-font-size(:$y-axis-label-font-size) is copy = Whatever,
                      :$grid-lines is copy = False,
                      :$margins is copy = Whatever,
                      :$tooltip = Whatever,
                      Str :$tooltip-background-color = 'black',
                      Str :$tooltip-color = 'white',
                      :$legends = Whatever,
                      Str :$format = 'jupyter',
                      :$div-id = Whatever
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

    # Grid lines
    $grid-lines = JavaScript::D3::Utilities::ProcessGridLines($grid-lines);

    # Margins
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    # Groups
    my Bool $hasGroups = [&&] @data.map({ so $_<group> });

    # Select code fragment to splice in
    my $jsChartMiddle = do given $tooltip {
        when ($_.isa(Whatever) || $_ ~~ Bool && $_) && $hasGroups {
            JavaScript::D3::CodeSnippets::GetTooltipMultiBubbleChartPart()
        }
        when $_ ~~ Bool && !$_ && $hasGroups {
            JavaScript::D3::CodeSnippets::MultiBubbleChartPart()
        }
        when $_ ~~ Bool && $_ && !$hasGroups {
            @data = @data.map({ $_.push(group => 'All') });
            JavaScript::D3::CodeSnippets::GetTooltipMultiBubbleChartPart()
        }
        default { JavaScript::D3::CodeSnippets::GetBubbleChartPart() }
    }

    # Chose to add legend code fragment or not
    my $maxGroupChars = $hasGroups ?? @data.map(*<group>).unique>>.chars.max !! 'all'.chars;
    given $legends {
        when $_ ~~ Bool && $_ || $_.isa(Whatever) && $hasGroups {
            $margins<right> = max($margins<right>, ($maxGroupChars + 4) * 12);
            $jsChartMiddle ~=  "\n" ~ JavaScript::D3::CodeSnippets::GetLegendCode
        }
    }

    my $jsChart = [JavaScript::D3::CodeSnippets::GetPlotPreparationCode($format, |$grid-lines),
                   $jsChartMiddle].join("\n");

    my $jsData = to-json(@data, :!pretty);

    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$OPACITY', '"' ~ $opacity ~ '"')
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
            .subst(:g, '$MARGINS', to-json($margins):!pretty)
            .subst(:g, '$LEGEND_X_POS', 'width + 3*12')
            .subst(:g, '$LEGEND_Y_POS', '0')
            .subst(:g, '$LEGEND_Y_GAP', '25')
            .subst(:g, '$Z_RANGE_MIN', $z-range-min)
            .subst(:g, '$Z_RANGE_MAX', $z-range-max)
            .subst(:g, '$TOOLTIP_COLOR', '"' ~ $tooltip-color ~ '"')
            .subst(:g, '$TOOLTIP_BACKGROUND_COLOR', '"' ~ $tooltip-background-color ~ '"');

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}

#============================================================
# Bind2D
#============================================================

#| Makes a bin 2D chart.
our proto Bin2DChart($data, |) is export {*}

our multi Bin2DChart($data where $data ~~ Seq, *%args) {
    return Bin2DChart($data.List, |%args);
}

our multi Bin2DChart(@data where @data.all ~~ List, *%args) {
    my @data2 = @data.map({ %( <x y>.Array Z=> $_.Array) });
    return Bin2DChart(@data2, |%args);
}

our multi Bin2DChart(@data where @data.all ~~ Map,
                     Str :$background= 'white',
                     Str :$color= 'steelblue',
                     :$width = 600,
                     :$height = 600,
                     Str :plot-label(:$title) = '',
                     Str :$x-axis-label = '',
                     UInt :$x-axis-label-font-size = 12;
                     Str :$x-axis-label-color = 'Black';
                     Str :$y-axis-label = '',
                     UInt :$y-axis-label-font-size = 12;
                     Str :$y-axis-label-color = 'Black';
                     :$grid-lines is copy = False,
                     :$margins is copy = Whatever,
                     :$method is copy = Whatever,
                     Str :$format = 'jupyter',
                     :$div-id = Whatever
                     ) {
    my $jsData = to-json(@data, :!pretty);

    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    if $method.isa(Whatever) {
        $method = 'rectbin';
    }
    die 'The argument method is expected to be one of \'rectbin\', \'hexbin\', or Whatever'
    unless $method ~~ Str && $method ∈ <rect rectangle rectbin hex hexagon hexbin>;

    my $jsChart = [JavaScript::D3::CodeSnippets::GetPlotPreparationCode($format),
                   $method eq 'rectbin' ?? JavaScript::D3::CodeSnippets::GetRectbinChartPart() !! JavaScript::D3::CodeSnippets::GetHexbinChartPart()].join("\n");

    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$X_AXIS_LABEL_FONT_SIZE', $x-axis-label-font-size)
            .subst(:g, '$X_AXIS_LABEL_FILL', '"' ~ $x-axis-label-color ~ '"')
            .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
            .subst(:g, '$Y_AXIS_LABEL_FONT_SIZE', $y-axis-label-font-size)
            .subst(:g, '$Y_AXIS_LABEL_FILL', '"' ~ $y-axis-label-color ~ '"')
            .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty);

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}