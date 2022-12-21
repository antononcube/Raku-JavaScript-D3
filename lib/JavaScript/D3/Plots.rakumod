use v6.d;

use Hash::Merge;
use JSON::Fast;
use JavaScript::D3::Predicates;
use JavaScript::D3::CodeSnippets;

unit module JavaScript::D3::Plots;

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
    my $jsScatterPlot = [JavaScript::D3::CodeSnippets::GetPlotMarginsAndLabelsCode($format),
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

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format);
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
                       Str :$format = 'jupyter'
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
                    singleDatasetCode => JavaScript::D3::CodeSnippets::GetPathPlotPart(),
                    multiDatasetCode => JavaScript::D3::CodeSnippets::GetMultiPathPlotPart(),
                    dataScalesAndAxesCode => JavaScript::D3::CodeSnippets::GetPlotDateDataScalesAndAxes(),
                    dataAndScalesCode => JavaScript::D3::CodeSnippets::GetPlotDateDataAndScales());

    $res = $res.subst(:g, '$TIME_PARSE_SPEC', '"' ~ $time-parse-spec ~ '"');

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format);
}