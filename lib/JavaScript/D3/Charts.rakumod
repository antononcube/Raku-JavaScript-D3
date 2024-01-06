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

our multi BarChart(@data where @data.all ~~ Map,
                   Str :$background= 'white',
                   Str :$color= 'steelblue',
                   :$width = 600,
                   :$height = 400,
                   Str :plot-label(:$title) = '',
                   Str :$x-axis-label = '',
                   Str :$y-axis-label = '',
                   :$grid-lines is copy = False,
                   :$margins is copy = Whatever,
                   :$legends = Whatever,
                   Str :$format = 'jupyter',
                   :$div-id = Whatever
                   ) {
    # Convert to JSON data
    my $jsData = to-json(@data, :!pretty);

    # Grid lines
    $grid-lines = JavaScript::D3::Utilities::ProcessGridLines($grid-lines);

    # Margins
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    # Normalize data
    if [&&] @data.map({ so $_<group> }) {
        @data = JavaScript::D3::Utilities::NormalizeData(@data, columns-from => Whatever, columns-to => <variable value group>);
    } else {
        @data = JavaScript::D3::Utilities::NormalizeData(@data, columns-from => Whatever, columns-to => <variable value>);
    }

    # Groups
    my Bool $hasGroups = [&&] @data.map({ (<group variable value> (&) $_).elems == 3 });

    note "Multi-dataset bar plots require all records to have the keys <group variable value>."
    when !$hasGroups && ( [&&] @data.map({ so $_<group> }) );

    # Select code fragment to splice in
    my $jsPlotMiddle;
    if $hasGroups {
        $jsPlotMiddle = JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(|$grid-lines, JavaScript::D3::CodeSnippets::GetMultiBarChartPart()),
    } else {
        $jsPlotMiddle = JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(|$grid-lines, JavaScript::D3::CodeSnippets::GetBarChartPart()),
    }

    # Chose to add legend code fragment or not
    my $maxGroupChars = $hasGroups ?? @data.map(*<group>).unique>>.chars.max !! 'all'.chars;
    given $legends {
        when $_ ~~ Bool && $_ || $_.isa(Whatever) && $hasGroups {
            $margins<right> = max($margins<right>, ($maxGroupChars + 4) * 12);
            $jsPlotMiddle ~=  "\n" ~ JavaScript::D3::CodeSnippets::GetLegendCode().subst('return o.group;', "return o.variable;");
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
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
            .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty)
            .subst(:g, '$LEGEND_X_POS', 'width + 3*12')
            .subst(:g, '$LEGEND_Y_POS', '0')
            .subst(:g, '$LEGEND_Y_GAP', '25');

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id );
}

#============================================================
# Histogram
#============================================================

#| Makes a histogram for a list of numbers.
our proto Histogram($data, |) is export {*}

our multi Histogram($data where $data ~~ Seq, *%args) {
    return Histogram($data.List, |%args);
}

our multi Histogram(@data where @data.all ~~ Numeric,
                    Str :$background= 'white',
                    Str :$color= 'steelblue',
                    :$width = 600,
                    :$height = 400,
                    Str :plot-label(:$title) = '',
                    Str :$x-axis-label = '',
                    Str :$y-axis-label = '',
                    :$grid-lines is copy = False,
                    :$margins is copy = Whatever,
                    Str :$format = 'jupyter',
                    :$div-id = Whatever
                    ) {
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
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
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
                      Str :$background= 'white',
                      Str :$color= 'steelblue',
                      Numeric :$opacity = 0.7,
                      :$width = 600,
                      :$height = 600,
                      Str :plot-label(:$title) = '',
                      Str :$x-axis-label = '',
                      Str :$y-axis-label = '',
                      :$grid-lines is copy = False,
                      :$margins is copy = Whatever,
                      :$tooltip = Whatever,
                      :$legends = Whatever,
                      Str :$format = 'jupyter',
                      :$div-id = Whatever
                      ) {
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
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
            .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty)
            .subst(:g, '$LEGEND_X_POS', 'width + 3*12')
            .subst(:g, '$LEGEND_Y_POS', '0')
            .subst(:g, '$LEGEND_Y_GAP', '25');

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
                     Str :$y-axis-label = '',
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
            .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
            .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty);

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}