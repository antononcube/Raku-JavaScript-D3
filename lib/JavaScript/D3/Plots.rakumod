unit module JavaScript::D3::Plots;

use Hash::Merge;
use JSON::Fast;
use JavaScript::D3::Predicates;
use JavaScript::D3::CodeSnippets;


#============================================================
# ListPlotGeneric
#============================================================

our proto ListPlotGeneric($data, |) is export {*}

our multi ListPlotGeneric($data where $data ~~ Seq, *%args) {
    return ListPlotGeneric($data.List, |%args);
}

our multi ListPlotGeneric($data where is-positional-of-lists($data, 3), *%args) {
    my @dataPairs = |$data.map({ <x y group> Z=> $_.List })>>.Hash;
    return ListPlotGeneric(@dataPairs, |%args);
}

our multi ListPlotGeneric($data where is-positional-of-lists($data, 2), *%args) {
    my @dataPairs = |$data.map({ <x y> Z=> $_.List })>>.Hash;
    return ListPlotGeneric(@dataPairs, |%args);
}

our multi ListPlotGeneric($data where $data ~~ Positional && $data.all ~~ Numeric, *%args) {
    my $k = 1;
    my @dataPairs = |$data.map({ <x y> Z=> ($k++, $_) })>>.Hash;
    return ListPlotGeneric(@dataPairs, |%args);
}

our multi ListPlotGeneric(@data where @data.all ~~ Map,
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
                          Bool :$axes = True,
                          Str :$format = 'jupyter',
                          :$div-id = Whatever,
                          Str :$singleDatasetCode!,
                          Str :$multiDatasetCode!,
                          Str :$dataScalesAndAxesCode!,
                          Str :$dataAndScalesCode!
                          ) {
    my $jsData = to-json(@data, :!pretty);

    # Process margins
    $margins = JavaScript::D3::CodeSnippets::ProcessMargins($margins);

    # Grid lines
    $grid-lines = JavaScript::D3::CodeSnippets::ProcessGridLines($grid-lines);

    # Groups
    my Bool $hasGroups = [&&] @data.map({ so $_<group> });

    # Select code fragment to splice in
    my $jsPlotMiddle = $hasGroups ?? $multiDatasetCode !! $singleDatasetCode;

    # Chose to add legend code fragment or not
    my $maxGroupChars = $hasGroups ?? @data.map(*<group>).unique>>.chars.max !! 'all'.chars;
    given $legends {
        when $_ ~~ Bool && $_ || $_.isa(Whatever) && $hasGroups {
            $margins<right> = max($margins<right>, ($maxGroupChars + 4) * 12);
            $jsPlotMiddle ~=  "\n" ~ JavaScript::D3::CodeSnippets::GetLegendCode();
        }
    }

    # Stencil
    my $jsScatterPlot = [JavaScript::D3::CodeSnippets::GetPlotMarginsTitleAndLabelsCode($format),
                      $axes ?? JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(|$grid-lines, $dataScalesAndAxesCode) !! $dataAndScalesCode,
                      $jsPlotMiddle]
            .join("\n");

    # Concrete parameters
    my $res = $jsScatterPlot
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$POINT_COLOR', '"' ~ $color ~ '"')
            .subst('$LINE_COLOR', '"' ~ $color ~ '"')
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
# ListPlot
#============================================================

our proto ListPlot($data, |) is export {*}

our multi ListPlot($data, *%args) {
    return ListPlotGeneric(
            $data,
            |%args,
            singleDatasetCode => JavaScript::D3::CodeSnippets::GetScatterPlotPart(),
            multiDatasetCode => JavaScript::D3::CodeSnippets::GetMultiScatterPlotPart(),
            dataScalesAndAxesCode => JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(),
            dataAndScalesCode => JavaScript::D3::CodeSnippets::GetPlotDataAndScalesCode());
}

#============================================================
# ListLinePlot
#============================================================

our proto ListLinePlot($data, |) is export {*}

our multi ListLinePlot($data, *%args) {
    return ListPlotGeneric(
            $data,
            |%args,
            singleDatasetCode => JavaScript::D3::CodeSnippets::GetPathPlotPart(),
            multiDatasetCode => JavaScript::D3::CodeSnippets::GetMultiPathPlotPart(),
            dataScalesAndAxesCode => JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(),
            dataAndScalesCode => JavaScript::D3::CodeSnippets::GetPlotDataAndScalesCode());
}

#============================================================
# DateListPlot
#============================================================

our proto DateListPlot($data, |) is export {*}

our multi DateListPlot($data where $data ~~ Seq, *%args) {
    return DateListPlot($data.List, |%args);
}

our multi DateListPlot($data where $data ~~ Positional && $data.all ~~ Numeric, *%args) {
    my $k = 1;
    my @dataPairs = $data.map({ <date value> Z=> (DateTime.new($k++), $_) })>>.Hash;
    return DateListPlot(@dataPairs, |%args);
}

our multi DateListPlot($data where is-positional-of-str-date-time-value-lists($data), *%args) {
    my @dataPairs = $data.map({ <date value> Z=> $_.List })>>.Hash;
    return DateListPlot(@dataPairs, |%args);
}

our multi DateListPlot($data where is-str-time-series($data),
                       Str :$background= 'white',
                       Str :$color= 'steelblue',
                       :$width = 600,
                       :$height = 400,
                       Str :plot-label(:$title) = '',
                       Str :date-axis-label(:$x-axis-label) = '',
                       Str :value-axis-label(:$y-axis-label) = '',
                       Str :$time-parse-spec = '%Y-%m-%d',
                       :$grid-lines is copy = False,
                       :$margins is copy = Whatever,
                       :$legends = Whatever,
                       Bool :$axes = True,
                       Str :$format = 'jupyter',
                       :$div-id = Whatever
                       ) {
    my $res =
            ListPlotGeneric($data,
                    :$background,
                    :$color,
                    :$width,
                    :$height,
                    :$title,
                    :$x-axis-label,
                    :$y-axis-label,
                    :$grid-lines,
                    :$margins,
                    :$legends,
                    :$axes,
                    format => 'asis',
                    :$div-id,
                    singleDatasetCode => JavaScript::D3::CodeSnippets::GetPathPlotPart(),
                    multiDatasetCode => JavaScript::D3::CodeSnippets::GetMultiPathPlotPart(),
                    dataScalesAndAxesCode => JavaScript::D3::CodeSnippets::GetPlotDateDataScalesAndAxes(),
                    dataAndScalesCode => JavaScript::D3::CodeSnippets::GetPlotDateDataAndScales());

    $res = $res.subst(:g, '$TIME_PARSE_SPEC', '"' ~ $time-parse-spec ~ '"');

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}


#============================================================
# HeatmapPlot
#============================================================

#| Makes a bubble chart for list of triplets..
our proto HeatmapPlot($data, |) is export {*}

our multi HeatmapPlot($data where $data ~~ Seq, *%args) {
    return HeatmapPlot($data.List, |%args);
}

our multi HeatmapPlot($data where is-positional-of-lists($data, 3), *%args) {
    my @data2 = $data.map({ %( <x y z>.Array Z=> $_.Array) });
    return HeatmapPlot(@data2, |%args);
}

our multi HeatmapPlot($data where is-positional-of-lists($data, 2), *%args) {
    return HeatmapPlot($data.map({ [|$_, 1] }), |%args);
}

our multi HeatmapPlot(@data is copy where @data.all ~~ Map,
                      :$width is copy = 600,
                      :$height is copy = 600,
                      Str :$color-palette = 'Inferno',
                      Str :$background = 'white',
                      Str :$tick-label-color = 'black',
                      :$tick-label-font-size is copy = Whatever,
                      Numeric :$opacity = 0.7,
                      Str :$plot-label-color = 'black',
                      :$plot-label-font-size is copy = Whatever,
                      Str :plot-label(:$title) = '',
                      :$x-tick-labels is copy = Whatever,
                      :$y-tick-labels is copy = Whatever,
                      Bool :$sort-tick-labels = True,
                      Bool :$show-groups = True,
                      :$low-value is copy = Whatever,
                      :$high-value is copy = Whatever,
                      :$margins is copy = Whatever,
                      :$tooltip = Whatever,
                      Str :$format = 'jupyter',
                      :$div-id = Whatever
                      ) {

    given ($width, $height) {
        when (Whatever, Whatever) {
            $width = 600; $height = 600;
        }
        when (Int:D, Whatever) {
            $height = $width;
        }
        when (Whatever, Int:D) {
            $width = $height;
        }
        when (Int:D, Int:D) { }
        default {
            die 'The arguments $width and $height are expected to positive integers or Whatever.';
        }
    }

    # Get values
    my @values = @data.map(*<z>).Array;

    #-------------------------------------------------------
    # Process $low-value
    #-------------------------------------------------------
    if $low-value.isa(Whatever) {
        $low-value = min(JavaScript::D3::CodeSnippets::reallyflat(@values))
    }
    die "The argument \$low-value is expected Whatever or Numeric:D."
    unless $low-value ~~ Numeric:D;

    #-------------------------------------------------------
    # Process $high-value
    #-------------------------------------------------------
    if $high-value.isa(Whatever) {
        $high-value = max(JavaScript::D3::CodeSnippets::reallyflat(@values))
    }
    die "The argument \$max-value is expected Whatever or Numeric:D."
    unless $low-value ~~ Numeric:D;

    #-------------------------------------------------------
    # Process $color-palette
    #-------------------------------------------------------
    die "The argument \$color-palette is expected to be one of '{JavaScript::D3::CodeSnippets::known-sequential-schemes.join("', '")}'."
    unless $color-palette ∈ JavaScript::D3::CodeSnippets::known-sequential-schemes;

    #-------------------------------------------------------
    # Process $plot-label-font-size
    #-------------------------------------------------------
    $plot-label-font-size = do given $plot-label-font-size {
        when Whatever { 'function(d) { return (width / 30) + "px" }' }
        when $_ ~~ Int:D && $_ ≥ 0 { "\"{$_.Str}px\"" }
        when Str:D {}
        default {
            die 'The argument $plot-label-font-size is expected to be a string, a non-negative integer, or Whatever.';
        }
    }

    #-------------------------------------------------------
    # Process $tick-label-font-size
    #-------------------------------------------------------
    $tick-label-font-size = do given $tick-label-font-size {
        when Whatever { max(10, round(max($width, $height) / 60 * 2 )) }
        when $_ ~~ Int:D && $_ ≥ 0 { "\"{$_.Str}px\"" }
        when Str:D {}
        default {
            die 'The argument $plot-label-font-size is expected to be a string, a non-negative integer, or Whatever.';
        }
    }

    #-------------------------------------------------------
    # Process $x-tick-labels
    #-------------------------------------------------------
    if $x-tick-labels.isa(Whatever) {
        $x-tick-labels = []
    }
    die "The argument \$x-tick-labels is expected Whatever or a Iterable."
    unless $x-tick-labels ~~ Iterable;

    if $x-tick-labels && ! ($x-tick-labels (&) @data.map(*<x>)) {
        note "None of the given x tick labels are found in the data.";
    }

    #-------------------------------------------------------
    # Process $y-tick-labels
    #-------------------------------------------------------
    if $y-tick-labels.isa(Whatever) {
        $y-tick-labels = []
    }
    die "The argument \$y-tick-labels is expected Whatever or a Iterable."
    unless $y-tick-labels ~~ Iterable;

    if $y-tick-labels && ! ($y-tick-labels (&) @data.map(*<y>)) {
        note "None of the given y tick labels are found in the data.";
    }

    #-------------------------------------------------------
    # Margins
    #-------------------------------------------------------
    $margins = JavaScript::D3::CodeSnippets::ProcessMargins($margins);

    #-------------------------------------------------------
    # Groups
    #-------------------------------------------------------
    my Bool $hasGroups = [&&] @data.map({ so $_<group> });

    my %groups;
    if $hasGroups {
        %groups = @data.classify(*<group>);
    } else {
        %groups = %($title => @data);
    }

    my $resTotal = '';
    for %groups.kv -> $g, @d {

        #-------------------------------------------------------
        # Select code fragment to splice in
        #-------------------------------------------------------
        my $jsHeatmapMiddle = JavaScript::D3::CodeSnippets::GetTooltipHeatmapPart();

        my $jsHeatmap = [JavaScript::D3::CodeSnippets::GetPlotMarginsAndTitle($format),
                         $jsHeatmapMiddle].join("\n");

        #-------------------------------------------------------
        # Fill in arguments
        #-------------------------------------------------------
        my $jsData = to-json(@d, :!pretty);

        my $res = $jsHeatmap
                .subst('$DATA', $jsData)
                .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
                .subst('$COLOR_PALETTE', $color-palette)
                .subst(:g, '$SORT_TICK_LABELS', $sort-tick-labels ?? 'true' !! 'false')
                .subst(:g, '$TICK_LABEL_COLOR', "\"$tick-label-color\"")
                .subst(:g, '$TICK_LABEL_FONT_SIZE', $tick-label-font-size)
                .subst(:g, '$WIDTH', $width.Str)
                .subst(:g, '$HEIGHT', $height.Str)
                .subst(:g, '$TITLE', '"' ~ ($show-groups ?? $g !! '') ~ '"')
                .subst(:g, '$X_TICK_LABELS', $x-tick-labels ?? to-json($x-tick-labels.Array, :!pretty) !! '[]')
                .subst(:g, '$Y_TICK_LABELS', $y-tick-labels ?? to-json($y-tick-labels.Array, :!pretty) !! '[]')
                .subst(:g, '$MARGINS', to-json($margins):!pretty)
                .subst(:g, '$LOW_VALUE', $low-value)
                .subst(:g, '$HIGH_VALUE', $high-value);

        #-------------------------------------------------------
        # Fill in plot label data
        #-------------------------------------------------------
        if [||] @d.map({ $_<label> // False }) {
            my @plotLabelData = @d.clone.map({ merge-hash($_, %( z => $_<label>)) });

            my $jsData = to-json(@plotLabelData, :!pretty);

            $res = $res ~ "\n" ~ JavaScript::D3::CodeSnippets::GetTooltipHeatmapPlotLabelsPart();

            $res = $res
                    .subst('$PLOT_LABELS_DATA', $jsData)
                    .subst('$PLOT_LABEL_COLOR', '"' ~ $plot-label-color ~ '"')
                    .subst(:g, '$PLOT_LABEL_FONT_SIZE', $plot-label-font-size)
                    .subst('$PLOT_LABEL_Y_OFFSET', '0');
        }

        $resTotal ~= $res;
    }

    return JavaScript::D3::CodeSnippets::WrapIt($resTotal, :$format, :$div-id);
}