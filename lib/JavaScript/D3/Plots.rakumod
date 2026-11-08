unit module JavaScript::D3::Plots;

use Hash::Merge;
use JSON::Fast;
use JavaScript::D3::Predicates;
use JavaScript::D3::CodeSnippets;
use JavaScript::D3::Utilities;

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
                          Str :$background = 'White',
                          Str :color(:$stroke-color) = 'SteelBlue',
                          :$fill-color is copy = Whatever,
                          Str :color-palette(:$color-scheme) = 'Set2',
                          :$width = 600,
                          :$height = 400,
                          Str :plot-label(:$title) = '',
                          UInt :plot-label-font-size(:$title-font-size) = 16,
                          Str :plot-label-color(:$title-color) = 'Black',
                          Str :x-label(:$x-axis-label) = '',
                          :x-label-color(:$x-axis-label-color) is copy = Whatever,
                          :x-label-font-size(:$x-axis-label-font-size) is copy = Whatever,
                          :$x-axis-scale = Whatever,
                          Str :y-label(:$y-axis-label) = '',
                          :y-label-color(:$y-axis-label-color) is copy = Whatever,
                          :y-label-font-size(:$y-axis-label-font-size) is copy = Whatever,
                          :$y-axis-scale = Whatever,
                          :$tooltip = Whatever,
                          Str :$tooltip-background-color = 'Black',
                          Str :$tooltip-color = 'White',
                          :$grid-lines is copy = False,
                          :$margins is copy = Whatever,
                          :$legends = Whatever,
                          Bool :$axes = True,
                          Bool :$filled = False,
                          Numeric :$point-size = 6,
                          Numeric :$stroke-width = 1.5,
                          Str :$format = 'jupyter',
                          :$div-id = Whatever,
                          Str :$singleDatasetCode!,
                          Str :$multiDatasetCode!,
                          Str :$dataScalesAndAxesCode!,
                          Str :$dataAndScalesCode!
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

    # Process margins
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    # Grid lines
    $grid-lines = JavaScript::D3::Utilities::ProcessGridLines($grid-lines);

    # Groups
    my Bool $hasGroups = [&&] @data.map({ so $_<group> });

    # Tooltips
    my Bool $hasTooltips = [||] @data.map({ so $_<tooltip> });

    if $tooltip ~~ Bool:D && $tooltip && !$hasTooltips {
        @data = @data.map({ $_<tooltip> = "({$_<x>}, {$_<y>})"; $_ });
        $hasTooltips = True;
    }

    # Fill color
    if $fill-color.isa(Whatever) { $fill-color = $stroke-color; }
    die 'The value of $fill-color is expected to be a string or Whatever.'
    unless $fill-color ~~ Str:D;

    # Process data
    my $jsData = to-json(@data, :!pretty);

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
                         $hasTooltips ?? JavaScript::D3::CodeSnippets::GetTooltipPart() !! '',
                         $axes ??
                         JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(|$grid-lines, $dataScalesAndAxesCode, :$x-axis-scale, :$y-axis-scale)
                         !! $dataAndScalesCode,
                         $jsPlotMiddle]
            .join("\n");

    # Concrete parameters
    my $res = $jsScatterPlot
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$POINT_COLOR', '"' ~ $stroke-color ~ '"')
            .subst(:g, '$LINE_COLOR', '"' ~ $stroke-color ~ '"')
            .subst(:g, '$FILL_COLOR', '"' ~ $fill-color ~ '"')
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
            .subst(:g, '$TOOLTIP_COLOR', '"' ~ $tooltip-color ~ '"')
            .subst(:g, '$TOOLTIP_BACKGROUND_COLOR', '"' ~ $tooltip-background-color ~ '"')
            .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty)
            .subst(:g, '$LEGEND_X_POS', 'width + 3*12')
            .subst(:g, '$LEGEND_Y_POS', '0')
            .subst(:g, '$LEGEND_Y_GAP', '25');

    if $hasTooltips {
        my $marker = '// Trigger the tooltip functions';
        $res .= subst($marker, $marker ~ "\n" ~ JavaScript::D3::CodeSnippets::GetTooltipMousePart);
    }

    # Somewhat of a hack. That is why the of additional $hasGroups check.
    if $hasGroups && ($color-scheme.starts-with('#') || JavaScript::D3::Utilities::get-named-colors(){$color-scheme.lc} // False) {
        $res .= subst('.attr("stroke", function(d){ return myColor(d[0]) })', '.attr("stroke", "' ~ $color-scheme.lc ~ '")');
        $res .= subst(".range(d3.scheme$color-scheme", '.range(d3.schemeSet1')
    }

    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}

#============================================================
# ListPlot
#============================================================

our proto ListPlot($data, |) is export {*}

our multi ListPlot(@data where @data.all ~~ Pair:D, *%args) {
    my $k = 0;
    my @data2 = @data.map({ %( x => $k++, y => $_.value, tooltip => $_.key ) });
    return ListPlot(@data2, |%args);
}

our multi ListPlot($data, *%args) {
    my $x-axis-scale = %args<x-axis-scale> // Whatever;
    my $y-axis-scale = %args<y-axis-scale> // Whatever;
    return ListPlotGeneric(
            $data,
            |%args,
            singleDatasetCode => JavaScript::D3::CodeSnippets::GetScatterPlotPart(),
            multiDatasetCode => JavaScript::D3::CodeSnippets::GetMultiScatterPlotPart(),
            dataScalesAndAxesCode => JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(:$x-axis-scale, :$y-axis-scale),
            dataAndScalesCode => JavaScript::D3::CodeSnippets::GetPlotDataAndScalesCode(:$x-axis-scale, :$y-axis-scale));
}

#============================================================
# ListLinePlot
#============================================================

our proto ListLinePlot($data, |) is export {*}

our multi ListLinePlot($data, *%args) {
    my $x-axis-scale = %args<x-axis-scale> // Whatever;
    my $y-axis-scale = %args<y-axis-scale> // Whatever;
    return ListPlotGeneric(
            $data,
            |%args,
            singleDatasetCode => JavaScript::D3::CodeSnippets::GetPathPlotPart(filled => %args<filled> // False),
            multiDatasetCode => JavaScript::D3::CodeSnippets::GetMultiPathPlotPart(),
            dataScalesAndAxesCode => JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(:$x-axis-scale, :$y-axis-scale),
            dataAndScalesCode => JavaScript::D3::CodeSnippets::GetPlotDataAndScalesCode(:$x-axis-scale, :$y-axis-scale));
}

#============================================================
# ParallelAxisPlot
#============================================================

#| Makes a parallel-axis plot from rows of numeric values, multiple row datasets, or long-form records.
our proto ParallelAxisPlot($data, |) is export {*}

our multi ParallelAxisPlot($data where $data ~~ Seq, *%options) {
    ParallelAxisPlot($data.List, |%options);
}

our multi ParallelAxisPlot(@data where (@data.elems > 0 && [&&] @data.map({
        $_ ~~ (Positional | Seq) && $_.elems >= 2 && $_.all ~~ Numeric
    })), *%options) {
    my @rows = @data.map(*.List);
    my @dimensions = (1 .. @rows[0].elems).map(*.Str);
    die 'Each parallel-axis row is expected to have the same number of numeric values.'
    unless [&&] @rows.map(*.elems == @dimensions.elems);

    my @records = @rows.map({
        %(values => (@dimensions Z=> $_.List).Hash)
    }).Array;
    parallel-axis-render(@records, @dimensions, |%options);
}

our multi ParallelAxisPlot(@datasets where (@datasets.elems > 0 && [&&] @datasets.map({
        $_ ~~ (Positional | Seq) && $_.elems > 0 && [&&] $_.map({
            $_ ~~ (Positional | Seq) && $_.elems >= 2 && $_.all ~~ Numeric
        })
    })), *%options) {
    my @datasets2 = @datasets.map(*.List);
    my @dimensions = (1 .. @datasets2[0][0].elems).map(*.Str);
    die 'Each parallel-axis row is expected to have the same number of numeric values.'
    unless [&&] @datasets2.map({ [&&] $_.map(*.elems == @dimensions.elems) });

    my @records;
    for @datasets2.kv -> $i, $dataset {
        @records.append: $dataset.map({
            %(group => "Series {$i + 1}", values => (@dimensions Z=> $_.List).Hash)
        });
    }
    parallel-axis-render(@records, @dimensions, :has-groups, |%options);
}

sub parallel-axis-dimensions(%row --> Array:D) {
    my @keys = %row.keys.grep(* ne 'group').map(*.Str);
    return ([&&] @keys.map({ so $_ ~~ /^ \d+ $/ }))
        ?? @keys.sort({ $^a.Numeric <=> $^b.Numeric }).Array
        !! @keys.sort.Array;
}

our multi ParallelAxisPlot(@data where (@data.elems > 0 && @data.all ~~ Map), *%options) {
    my @dimensions = parallel-axis-dimensions(@data[0]);
    die 'Long-form parallel-axis data is expected to have at least two dimension keys.'
    unless @dimensions.elems >= 2;
    die 'Long-form parallel-axis records are expected to have the same dimension keys and numeric values.'
    unless [&&] @data.map(-> %row {
        my @keys = parallel-axis-dimensions(%row);
        @keys eqv @dimensions && [&&] @dimensions.map(-> $dimension { %row{$dimension} ~~ Numeric })
    });

    my Bool $has-groups = [&&] @data.map({ $_<group> ~~ Str:D });
    die 'Long-form parallel-axis data either has a string group in every record or none.'
    unless $has-groups || [&&] @data.map({ !($_<group>:exists) });

    my @records = @data.map(-> %row {
        %(|(%row<group>:exists ?? %(group => %row<group>) !! Empty),
          values => (@dimensions Z=> @dimensions.map(-> $dimension { %row{$dimension} })).Hash)
    }).Array;
    parallel-axis-render(@records, @dimensions, :$has-groups, |%options);
}

our multi ParallelAxisPlot($data, *%options) {
    die 'Parallel-axis data is expected to be numeric rows, multiple numeric-row datasets, or long-form records.';
}

sub parallel-axis-render(@data, @dimensions,
                         Bool :$has-groups = False,
                         Str :$background = 'White',
                         Str :color(:$stroke-color) = 'SteelBlue',
                         Str :color-palette(:$color-scheme) = 'Set2',
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
                         :$legends = Whatever,
                         Bool :$legend = False,
                         Numeric :$stroke-width = 1.5,
                         Str :$format = 'jupyter',
                         :$div-id = Whatever) {
    ($x-axis-label-color, $x-axis-label-font-size, $y-axis-label-color, $y-axis-label-font-size) =
        JavaScript::D3::Utilities::ProcessLabelsColorsAndFontSizes(
            :$title-color, :$title-font-size,
            :$x-axis-label-color, :$x-axis-label-font-size,
            :$y-axis-label-color, :$y-axis-label-font-size);
    $grid-lines = JavaScript::D3::Utilities::ProcessGridLines($grid-lines);
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    my Bool $show-legend = $has-groups && ($legend || $legends ~~ Bool:D && $legends || $legends ~~ Whatever);
    if $show-legend {
        my $max-group-chars = @data.map(*<group>.chars).max;
        $margins<right> = max($margins<right>, ($max-group-chars + 4) * 12);
    }
    my $y-axis-grid = $grid-lines[1] > 0 ?? ".ticks($grid-lines[1]).tickSize(-width)" !! '';
    my $jsChart = [JavaScript::D3::CodeSnippets::GetPlotMarginsTitleAndLabelsCode($format),
                   JavaScript::D3::CodeSnippets::GetParallelAxisPlotPart(),
                   $show-legend ?? JavaScript::D3::CodeSnippets::GetLegendCode() !! ''].join("\n");
    my $res = $jsChart
        .subst('$DATA', to-json(@data, :!pretty))
        .subst('$DIMENSIONS', to-json(@dimensions, :!pretty))
        .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
        .subst('$COLOR_SCHEME', $color-scheme.starts-with('scheme') ?? $color-scheme !! 'scheme' ~ $color-scheme.tc)
        .subst('$HAS_GROUPS', $has-groups ?? 'true' !! 'false')
        .subst('$LINE_COLOR', '"' ~ $stroke-color ~ '"')
        .subst('$STROKE_WIDTH', $stroke-width)
        .subst('$Y_AXIS_GRID', $y-axis-grid)
        .subst(:g, '$AXIS_LABEL_COLOR', '"' ~ $y-axis-label-color ~ '"')
        .subst('$WIDTH', $width.Str).subst('$HEIGHT', $height.Str)
        .subst('$TITLE_FONT_SIZE', $title-font-size).subst('$TITLE_FILL', '"' ~ $title-color ~ '"').subst('$TITLE', '"' ~ $title ~ '"')
        .subst('$X_AXIS_LABEL_FONT_SIZE', $x-axis-label-font-size).subst('$X_AXIS_LABEL_FILL', '"' ~ $x-axis-label-color ~ '"').subst('$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
        .subst('$Y_AXIS_LABEL_FONT_SIZE', $y-axis-label-font-size).subst('$Y_AXIS_LABEL_FILL', '"' ~ $y-axis-label-color ~ '"').subst('$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
        .subst('$MARGINS', to-json($margins, :!pretty))
        .subst(:g, '$LEGEND_X_POS', 'width + 12').subst(:g, '$LEGEND_Y_POS', '0').subst(:g, '$LEGEND_Y_GAP', '22');
    JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}

#============================================================
# RadialAxisPlot
#============================================================

#| Makes a radial-axis plot from values, pairs, a map, or multiple maps.
our proto RadialAxisPlot($data, |) is export {*}

our multi RadialAxisPlot($data where $data ~~ Seq, *%options) {
    RadialAxisPlot($data.List, |%options);
}

our multi RadialAxisPlot(@data where (@data.elems > 0 && @data.all ~~ Pair:D), *%options) {
    my @dimensions = @data.map(*.key.Str);
    radial-axis-render([%(values => (@dimensions Z=> @data.map(*.value)).Hash)], @dimensions, |%options);
}

our multi RadialAxisPlot(@datasets where (@datasets.elems > 0 && [&&] @datasets.map({ $_ ~~ (Positional | Seq) })), *%options) {
    my @datasets2 = @datasets.map(*.List);
    my @dimensions = (1 .. @datasets2[0].elems).map(*.Str);
    die 'Each radial-axis vector is expected to have the same number of values.'
    unless [&&] @datasets2.map(*.elems == @dimensions.elems);
    my @records = @datasets2.kv.map(-> $i, $values {
        %(group => "Series {$i + 1}", values => (@dimensions Z=> $values).Hash)
    }).Array;
    radial-axis-render(@records, @dimensions, :has-groups, |%options);
}

our multi RadialAxisPlot(@data where (@data.elems > 0 && !(@data.all ~~ Map) && !([&&] @data.map({ $_ ~~ (Positional | Seq) }))), *%options) {
    my @dimensions = (1 .. @data.elems).map(*.Str);
    radial-axis-render([%(values => (@dimensions Z=> @data).Hash)], @dimensions, |%options);
}

our multi RadialAxisPlot(%data where %data.elems > 0, *%options) {
    my @dimensions = parallel-axis-dimensions(%data);
    radial-axis-render([%(values => (@dimensions Z=> @dimensions.map({ %data{$_} })).Hash)], @dimensions, |%options);
}

our multi RadialAxisPlot(@data where (@data.elems > 0 && @data.all ~~ Map), *%options) {
    my @dimensions = parallel-axis-dimensions(@data[0]);
    die 'Each radial-axis dataset is expected to have the same keys.'
    unless [&&] @data.map({ parallel-axis-dimensions($_) eqv @dimensions });
    my @records = @data.kv.map(-> $i, %row {
        %(group => "Series {$i + 1}", values => (@dimensions Z=> @dimensions.map({ %row{$_} })).Hash)
    }).Array;
    radial-axis-render(@records, @dimensions, :has-groups, |%options);
}

sub radial-axis-range(@data, @dimensions, $plot-range --> Array:D) {
    my @numeric = @data.map(*<values>.values).flat.grep(* ~~ Numeric);
    my @shared = @numeric.elems ?? (@numeric.min, @numeric.max) !! (0, 1);
    @shared = (0, @shared[1] == 0 ?? 1 !! @shared[1]) if @shared[0] == @shared[1];
    given $plot-range {
        when Whatever { return @dimensions.map({ @shared.Array }).Array; }
        when Positional && .elems == 2 && .all ~~ Numeric { return @dimensions.map({ $_.List }).Array; }
        when Map {
            die 'Each plot-range map value is expected to be a two-number range.'
            unless [&&] @dimensions.map(-> $dimension {
                my $range = $plot-range{$dimension};
                $range ~~ Positional && $range.elems == 2 && $range.all ~~ Numeric
            });
            return @dimensions.map({ $plot-range{$_}.List }).Array;
        }
        default { die 'The argument plot-range is expected to be a two-number range, a map of ranges, or Whatever.'; }
    }
}

sub radial-axis-render(@data, @dimensions,
                       Bool :$has-groups = False,
                       Str :$background = 'White',
                       Str :color(:$stroke-color) = 'SteelBlue',
                       Str :color-palette(:$color-scheme) = 'Set2',
                       :$width = 600, :$height = 400,
                       Str :plot-label(:$title) = '',
                       UInt :plot-label-font-size(:$title-font-size) = 16,
                       Str :plot-label-color(:$title-color) = 'Black',
                       Str :x-label(:$x-axis-label) = '',
                       :x-label-color(:$x-axis-label-color) is copy = Whatever,
                       :x-label-font-size(:$x-axis-label-font-size) is copy = Whatever,
                       Str :y-label(:$y-axis-label) = '',
                       :y-label-color(:$y-axis-label-color) is copy = Whatever,
                       :y-label-font-size(:$y-axis-label-font-size) is copy = Whatever,
                       :$plot-range = Whatever,
                       :$axes = Whatever,
                       :$grid-lines is copy = False,
                       :$margins is copy = Whatever,
                       :$legends = Whatever,
                       Bool :$legend = False,
                       Bool :$filling = True,
                       Numeric :$stroke-width = 1.5,
                       Str :$format = 'jupyter', :$div-id = Whatever) {
    ($x-axis-label-color, $x-axis-label-font-size, $y-axis-label-color, $y-axis-label-font-size) =
        JavaScript::D3::Utilities::ProcessLabelsColorsAndFontSizes(
            :$title-color, :$title-font-size, :$x-axis-label-color, :$x-axis-label-font-size,
            :$y-axis-label-color, :$y-axis-label-font-size);
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);
    $grid-lines = JavaScript::D3::Utilities::ProcessGridLines($grid-lines);
    my @normalized = @data.map(-> %row {
        %(|(%row<group>:exists ?? %(group => %row<group>) !! Empty),
          values => (@dimensions Z=> @dimensions.map(-> $d { %row<values>{$d} ~~ Numeric ?? %row<values>{$d} !! Any })).Hash)
    }).Array;
    my @domains = radial-axis-range(@normalized, @dimensions, $plot-range);
    my Bool $same-ranges = [&&] @domains.map({ $_ eqv @domains[0] });
    my @axis-dimensions = do given $axes {
        when Bool:D { $_ ?? @dimensions !! () }
        when Whatever { $same-ranges ?? @dimensions.head !! @dimensions }
        default { die 'The argument axes is expected to be a Boolean or Whatever.'; }
    };
    my Bool $show-legend = $has-groups && ($legend || $legends ~~ Bool:D && $legends || $legends ~~ Whatever);
    if $show-legend {
        my $max-group-chars = @normalized.map(*<group>.chars).max;
        $margins<right> = max($margins<right>, ($max-group-chars + 4) * 12);
    }
    my $jsChart = [JavaScript::D3::CodeSnippets::GetPlotMarginsTitleAndLabelsCode($format),
                   JavaScript::D3::CodeSnippets::GetRadialAxisPlotPart(),
                   $show-legend ?? JavaScript::D3::CodeSnippets::GetLegendCode() !! ''].join("\n");
    my $res = $jsChart
        .subst('$DATA', to-json(@normalized, :!pretty)).subst('$DIMENSIONS', to-json(@dimensions, :!pretty))
        .subst('$DOMAINS', to-json(@domains, :!pretty)).subst('$AXIS_DIMENSIONS', to-json(@axis-dimensions, :!pretty))
        .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"').subst('$COLOR_SCHEME', $color-scheme.starts-with('scheme') ?? $color-scheme !! 'scheme' ~ $color-scheme.tc)
        .subst(:g, '$HAS_GROUPS', $has-groups ?? 'true' !! 'false').subst(:g, '$LINE_COLOR', '"' ~ $stroke-color ~ '"').subst('$STROKE_WIDTH', $stroke-width)
        .subst(:g, '$FILLING', $filling ?? 'true' !! 'false')
        .subst(:g, '$GRID_LINES', $grid-lines.max)
        .subst(:g, '$AXIS_LABEL_COLOR', '"' ~ $y-axis-label-color ~ '"').subst('$WIDTH', $width.Str).subst('$HEIGHT', $height.Str)
        .subst('$TITLE_FONT_SIZE', $title-font-size).subst('$TITLE_FILL', '"' ~ $title-color ~ '"').subst('$TITLE', '"' ~ $title ~ '"')
        .subst('$X_AXIS_LABEL_FONT_SIZE', $x-axis-label-font-size).subst('$X_AXIS_LABEL_FILL', '"' ~ $x-axis-label-color ~ '"').subst('$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
        .subst('$Y_AXIS_LABEL_FONT_SIZE', $y-axis-label-font-size).subst('$Y_AXIS_LABEL_FILL', '"' ~ $y-axis-label-color ~ '"').subst('$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
        .subst('$MARGINS', to-json($margins, :!pretty)).subst(:g, '$LEGEND_X_POS', 'width + 12').subst(:g, '$LEGEND_Y_POS', '0').subst(:g, '$LEGEND_Y_GAP', '22');
    JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
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
                       Str :color(:$stroke-color) = 'steelblue',
                       :$fill-color is copy = Whatever,
                       Str :$color-scheme = 'schemeSet2',
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
                       Bool :$filled = False,
                       Str :$format = 'jupyter',
                       :$div-id = Whatever,
                       *%args
                       ) {
    my $y-axis-scale = %args<y-axis-scale> // Whatever;
    my $res =
            ListPlotGeneric($data,
                    :$background,
                    :$stroke-color,
                    :$fill-color,
                    :$color-scheme,
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
                    singleDatasetCode => JavaScript::D3::CodeSnippets::GetPathPlotPart(:$filled),
                    multiDatasetCode => JavaScript::D3::CodeSnippets::GetMultiPathPlotPart(),
                    dataScalesAndAxesCode => JavaScript::D3::CodeSnippets::GetPlotDateDataScalesAndAxes(:$y-axis-scale),
                    dataAndScalesCode => JavaScript::D3::CodeSnippets::GetPlotDateDataAndScales(:$y-axis-scale),
                    |%args
            );

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
                      Str :plot-label(:$title) = '',
                      UInt :plot-label-font-size(:$title-font-size) = 16,
                      Str :plot-label-color(:$title-color) = 'Black',
                      Str :x-label(:$x-axis-label) = '',
                      :x-label-color(:$x-axis-label-color) is copy = Whatever,
                      :x-label-font-size(:$x-axis-label-font-size) is copy = Whatever,
                      Str :y-label(:$y-axis-label) = '',
                      :y-label-color(:$y-axis-label-color) is copy = Whatever,
                      :y-label-font-size(:$y-axis-label-font-size) is copy = Whatever,
                      :$color = Whatever,
                      Str :$color-palette = 'Inferno',
                      Str :$background = 'White',
                      Str :$tick-labels-color = 'Black',
                      :$tick-labels-font-size is copy = Whatever,
                      Str:D :$tick-labels-font-family = 'Helvetica',
                      Numeric :$opacity = 0.7,
                      Str :$plot-labels-color = 'Black',
                      :$plot-labels-font-size is copy = Whatever,
                      Str :$plot-labels-font-family = 'Courier',
                      :$x-tick-labels is copy = Whatever,
                      :$y-tick-labels is copy = Whatever,
                      Bool :$sort-tick-labels = True,
                      Bool :$show-groups = True,
                      :$low-value is copy = Whatever,
                      :$high-value is copy = Whatever,
                      :$margins is copy = Whatever,
                      Bool :$tooltip = True,
                      :$tooltip-background-color is copy = Whatever,
                      :$tooltip-color is copy = Whatever,
                      :$mesh = True,
                      :$grid-lines is copy = Whatever,
                      :$round-corners is copy = Whatever,
                      Str :$format = 'jupyter',
                      :$div-id = Whatever
                      ) {

    #-------------------------------------------------------
    # Process width & height
    #-------------------------------------------------------
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

    # Get values
    my @values = @data.map(*<z>).Array;

    die 'All z-values of the dataset are expected to be Numeric:D.'
    unless @values.all ~~ Numeric:D;

    #-------------------------------------------------------
    # Process $tooltip-(background-)color
    #-------------------------------------------------------
    if $tooltip-background-color.isa(Whatever) { $$tooltip-background-color = $background }
    die 'The value of $tooltip-background-color is expected to be a string or Whatever.'
    unless $tooltip-background-color ~~ Str:D;

    if $tooltip-color.isa(Whatever) { $$tooltip-color = $plot-labels-color }
    die 'The value of $tooltip-color is expected to be a string or Whatever.'
    unless $tooltip-color ~~ Str:D;

    #-------------------------------------------------------
    # Process $grid-lines
    #-------------------------------------------------------
    if $grid-lines.isa(Whatever) { $grid-lines = False }
    my $grid-lines-color = $grid-lines ~~ Map:D ?? $grid-lines<color> // 'Gray' !! 'Gray';
    my $grid-lines-width = $grid-lines ~~ Map:D ?? $grid-lines<width> // 1 !! 1;

    #-------------------------------------------------------
    # Process $round-corners
    #-------------------------------------------------------
    if $round-corners.isa(Whatever) { $round-corners = True }

    #-------------------------------------------------------
    # Process $low-value
    #-------------------------------------------------------
    if $low-value.isa(Whatever) {
        $low-value = min(JavaScript::D3::Utilities::reallyflat(@values))
    }
    die "The argument \$low-value is expected Whatever or Numeric:D."
    unless $low-value ~~ Numeric:D;

    #-------------------------------------------------------
    # Process $high-value
    #-------------------------------------------------------
    if $high-value.isa(Whatever) {
        $high-value = max(JavaScript::D3::Utilities::reallyflat(@values))
    }
    die "The argument \$max-value is expected Whatever or Numeric:D."
    unless $low-value ~~ Numeric:D;

    #-------------------------------------------------------
    # Process $color-palette
    #-------------------------------------------------------
    die "The argument \$color-palette is expected to be one of '{JavaScript::D3::CodeSnippets::known-sequential-schemes.join("', '")}'."
    unless $color-palette ∈ JavaScript::D3::CodeSnippets::known-sequential-schemes;

    #-------------------------------------------------------
    # Process $plot-labels-font-size
    #-------------------------------------------------------
    $plot-labels-font-size = do given $plot-labels-font-size {
        when Whatever { 'function(d) { return (width / 30) + "px" }' }
        when $_ ~~ Int:D && $_ ≥ 0 { "\"{$_.Str}px\"" }
        when Str:D {}
        default {
            die 'The argument $plot-labels-font-size is expected to be a string, a non-negative integer, or Whatever.';
        }
    }

    #-------------------------------------------------------
    # Process $tick-labels-font-size
    #-------------------------------------------------------
    $tick-labels-font-size = do given $tick-labels-font-size {
        when Whatever { '"' ~ max(10, round(min($width, $height) / 60 * 2 )).Str ~ 'px"' }
        when $_ ~~ Int:D && $_ ≥ 0 { "\"{$_.Str}px\"" }
        when Str:D { $tick-labels-font-size }
        default {
            die 'The argument $tick-labels-font-size is expected to be a string, a non-negative integer, or Whatever.';
        }
    }

    #-------------------------------------------------------
    # Process $x-tick-labels
    #-------------------------------------------------------
    if $x-tick-labels.isa(Whatever) {
        $x-tick-labels = []
    }
    die 'The argument $x-tick-labels is expected to be a list or Whatever.'
    unless $x-tick-labels ~~ (List:D | Array:D | Seq:D);

    if $x-tick-labels && ! ($x-tick-labels (&) @data.map(*<x>)) {
        note "None of the given x-tick labels is found in the data.";
    }

    #-------------------------------------------------------
    # Process $y-tick-labels
    #-------------------------------------------------------
    if $y-tick-labels.isa(Whatever) {
        $y-tick-labels = []
    }
    die 'The argument $y-tick-labels is expected to be a list or Whatever.'
    unless $y-tick-labels ~~ (List:D | Array:D | Seq:D);

    if $y-tick-labels && ! ($y-tick-labels (&) @data.map(*<y>)) {
        note "None of the given y-tick labels is found in the data.";
    }

    #-------------------------------------------------------
    # Margins
    #-------------------------------------------------------
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

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
                .subst(:g, '$OPACITY', $opacity)
                .subst(:g, '$SORT_TICK_LABELS', $sort-tick-labels ?? 'true' !! 'false')
                .subst(:g, '$TICK_LABELS_COLOR', "\"$tick-labels-color\"")
                .subst(:g, '$TICK_LABELS_FONT_SIZE', $tick-labels-font-size)
                .subst(:g, '$TICK_LABELS_FONT_FAMILY', "\"$tick-labels-font-family\"")
                .subst(:g, '$TOOLTIP_BACKGROUND_COLOR', "\"$tooltip-background-color\"")
                .subst(:g, '$TOOLTIP_COLOR', "\"$tooltip-color\"")
                .subst(:g, '$WIDTH', $width.Str)
                .subst(:g, '$HEIGHT', $height.Str)
                .subst(:g, '$X_TICK_LABELS', $x-tick-labels.elems ?? to-json($x-tick-labels.Array, :!pretty) !! '[]')
                .subst(:g, '$Y_TICK_LABELS', $y-tick-labels.elems ?? to-json($y-tick-labels.Array, :!pretty) !! '[]')
                .subst(:g, '$TITLE_FONT_SIZE', $title-font-size)
                .subst(:g, '$TITLE_FILL', '"' ~ $title-color ~ '"')
                .subst(:g, '$TITLE', '"' ~ ($show-groups ?? $g !! '') ~ '"')
                .subst(:g, '$X_AXIS_LABEL_FONT_SIZE', $x-axis-label-font-size)
                .subst(:g, '$X_AXIS_LABEL_FILL', '"' ~ $x-axis-label-color ~ '"')
                .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
                .subst(:g, '$Y_AXIS_LABEL_FONT_SIZE', $y-axis-label-font-size)
                .subst(:g, '$Y_AXIS_LABEL_FILL', '"' ~ $y-axis-label-color ~ '"')
                .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
                .subst(:g, '$GRID_LINES_COLOR', '"' ~ $grid-lines-color ~ '"')
                .subst(:g, '$GRID_LINES_WIDTH', $grid-lines-width)
                .subst(:g, '$GRID_LINES', $grid-lines ?? 'true' !! 'false')
                .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
                .subst(:g, '$MARGINS', to-json($margins):!pretty)
                .subst(:g, '$LOW_VALUE', $low-value)
                .subst(:g, '$HIGH_VALUE', $high-value);

        unless $round-corners {
            $res = $res
                    .subst('.attr("rx", 4)')
                    .subst('.attr("ry", 4)');
        }

        #-------------------------------------------------------
        # Fill in plot label data
        #-------------------------------------------------------
        if [||] @d.map({ $_<label> // False }) {
            my @plotLabelData = @d.clone.map({ merge-hash($_, %( z => $_<label>)) });

            my $jsData = to-json(@plotLabelData, :!pretty);

            $res = $res ~ "\n" ~ JavaScript::D3::CodeSnippets::GetTooltipHeatmapPlotLabelsPart();

            $res = $res
                    .subst('$PLOT_LABELS_DATA', $jsData)
                    .subst('$PLOT_LABELS_COLOR', '"' ~ $plot-labels-color ~ '"')
                    .subst(:g, '$PLOT_LABELS_FONT_SIZE', $plot-labels-font-size)
                    .subst(:g, '$PLOT_LABELS_FONT_FAMILY', $plot-labels-font-family)
                    .subst('$PLOT_LABELS_Y_OFFSET', '0');
        }

        $resTotal ~= $res;
    }

    # Here we assume that the heatmap plot code snipped is using '.padding(0.05)'
    # and that is only for the "squares" of the heatmap.
    given $mesh {
        when $_ ~~ Bool:D {
            # As explained by Nemokosch:
            #  when uses smart-matching under the hood but somebody thought it should also try to mimic the behavior of if as much as possible
            #  so smartmatching was deliberately ruined to support this use case
            if !$_ {
                $resTotal = $resTotal.subst(:g, '.padding(0.05)');
            }
        }
        when $_ ~~ Numeric:D && $_ ≥ 0 {
            $resTotal = $resTotal.subst(:g, '.padding(0.05)', ".padding($mesh)");
        }
        when !$_.isa(Whatever) {
            note 'The argument $mesh is expected to be a Boolean or non-negative number.';
        }
    }

    if !$tooltip {
        $resTotal = $resTotal
                .subst('.on("mouseover", mouseover)')
                .subst('.on("mousemove", mousemove)')
                .subst('.on("mouseleave", mouseleave)')
                .subst(/'// tooltip-code-begin' (.*?) '// tooltip-code-end'/)
    }

    return JavaScript::D3::CodeSnippets::WrapIt($resTotal, :$format, :$div-id);
}

#============================================================
# MatrixPlot
#============================================================
sub dense-to-triplets(@A) {
    my @triplets;
    for ^@A.elems -> $i {
        for ^@A.head.elems -> $j {
            if @A[$i][$j] ~~ Numeric:D {
                @triplets.push: { x => $j, y => $i, z => @A[$i][$j] };
            }
        }
    }
    return @triplets.Array;
}

#| Makes a matrix plot for a dense matrix or a dataset with columns "x", "y", "z".
our proto MatrixPlot($data, |) is export {*}

multi sub MatrixPlot(@data,
                     :$width is copy = Whatever,
                     :$height is copy = Whatever,
                     :$margins = 2,
                     :$background = 'none',
                     :$grid-lines is copy = Whatever,
                     :$round-corners is copy = Whatever,
                     *%args) {
    if @data.all ~~ Seq:D {
        return MatrixPlot(@data».Array.Array, :$width, :$height, :$margins, :$background, :$grid-lines, :$round-corners, |%args);
    } elsif (@data.all ~~ List:D | Array:D) && (@data».elems.all == @data.head.elems) {
        my @res = dense-to-triplets(@data);
        ($width, $height) = JavaScript::D3::Utilities::ProcessWidthAndHeight(:$width, :$height, aspect-ratio => @data.elems / @data.head.elems);
        if $grid-lines.isa(Whatever) { $grid-lines = True }
        if $round-corners.isa(Whatever) { $round-corners = False }
        return MatrixPlot(@res, :$width, :$height, :$margins, :$background, :$grid-lines, :$round-corners, |%args);
    } elsif @data.all ~~ Map:D {
        my $ncol = @data.map({ $_<x> }).unique.elems;
        my $nrow = @data.map({ $_<y> }).unique.elems;
        ($width, $height) = JavaScript::D3::Utilities::ProcessWidthAndHeight(:$width, :$height, aspect-ratio => $ncol / $nrow);
        my $res = HeatmapPlot(@data, :$width, :$height, :$margins, :$background, :$grid-lines, :$round-corners, |%args);
        if 'y-tick-labels' ∉ %args {
            $res .= subst('.range([height, 0])', '.range([0, height])', :g);
        }
        return $res;
    } else {
        die 'The first argument is expected to be a dense matrix or heatmap plot spec.';
    }
}
