unit module JavaScript::D3::Combination;

use JSON::Fast;
use JavaScript::D3::CodeSnippets;
use JavaScript::D3::Utilities;

# A layer is deliberately a Raku value, rather than completed JavaScript.  The
# composer can consequently create one frame and one pair of scales for all
# layers before it asks any layer to render itself.
class Layer is export {
    has Str $.kind is required;
    has Array $.data is required;
    has Str $.color = 'steelblue';
    has Numeric $.stroke-width = 1.5;
    has Numeric $.point-size = 6;
    has Numeric $.font-size = 12;
    has Numeric $.opacity = 0.55;
    has UInt $.number-of-bins = 20;
    has Numeric $.box-x = 1;
    has Numeric $.box-width = 20;
    has Bool $.horizontal = False;
    has Str $.legend = '';
}

sub normalized-data($data, Str:D $kind --> Array:D) {
    my @source = $data ~~ Seq ?? $data.List !! $data.List;
    # Raku's ordinary array literal slips a hash into its constituent pairs.
    # Reconstitute consecutive x/y[/label] pairs so that both
    # C<[{:x(1), :y(2)}]> and itemized maps are convenient layer inputs.
    if @source.elems && @source.all ~~ Pair {
        my @records;
        my %record;
        for @source -> $pair {
            if $pair.key.Str eq 'x' && (%record<x>:exists) {
                @records.push(%record);
                %record = ();
            }
            %record{$pair.key} = $pair.value;
        }
        @records.push(%record) if %record.elems;
        @source = @records;
    }
    die "A $kind layer needs at least one datum." unless @source.elems;

    my @result;
    for @source.kv -> $index, $item {
        my %point;
        if $item ~~ Associative {
            die "A $kind layer datum needs numeric x and y fields."
            unless ($item<x>:exists) && ($item<y>:exists)
                    && $item<x> ~~ Numeric && $item<y> ~~ Numeric;
            %point = %(x => $item<x>, y => $item<y>);
            %point<label> = $item<label> if $item<label>:exists;
        } elsif $item ~~ Positional {
            die "A $kind layer datum needs numeric x and y values."
            unless $item.elems >= 2 && $item[0] ~~ Numeric && $item[1] ~~ Numeric;
            %point = %(x => $item[0], y => $item[1]);
            %point<label> = $item[2] if $item.elems >= 3;
        } elsif $item ~~ Numeric {
            %point = %(x => $index + 1, y => $item);
        } else {
            die "A $kind layer datum is expected to be numeric, positional, or a map.";
        }

        if $kind eq 'labels' {
            die 'A label layer datum needs a label field or a third positional value.'
            unless %point<label>:exists;
        }
        @result.push(%point);
    }
    @result.Array;
}

our sub LayerLine($data, Str :$color = 'steelblue', Numeric :$stroke-width = 1.5,
                  Str :$legend = '' --> Layer:D) is export {
    Layer.new(kind => 'line', data => normalized-data($data, 'line'),
            :$color, :$stroke-width, :$legend);
}

our sub LayerPoints($data, Str :$color = 'steelblue', Numeric :$point-size = 6,
                    Str :$legend = '' --> Layer:D) is export {
    Layer.new(kind => 'points', data => normalized-data($data, 'points'),
            :$color, :$point-size, :$legend);
}

our sub LayerLabels($data, Str :$color = 'black', Numeric :$font-size = 12,
                    Str :$legend = '' --> Layer:D) is export {
    Layer.new(kind => 'labels', data => normalized-data($data, 'labels'),
            :$color, :$font-size, :$legend);
}

sub numeric-values($data, Str:D $kind --> Array:D) {
    my @values = $data ~~ Seq ?? $data.List !! $data.List;
    die "A $kind layer needs at least one numeric value."
        unless @values.elems && @values.all ~~ Numeric;
    @values.Array;
}

#| Creates a histogram layer. All histogram layers in one composition use the
#| same bin boundaries; set C<number-of-bins> identically on each layer.
our sub LayerHistogram($data, Str :$color = 'steelblue', Numeric :$opacity = 0.55,
                       UInt :bins(:$number-of-bins) = 20, Str :$legend = '' --> Layer:D) is export {
    Layer.new(kind => 'histogram', data => numeric-values($data, 'histogram'),
              :$color, :$opacity, :$number-of-bins, :$legend);
}

#| Creates one vertical box-whisker layer at a numeric x position. C<box-width>
#| is measured in screen pixels, so boxes remain legible under scale changes.
our sub LayerBoxWhisker($data, Numeric :x(:$box-x) = 1,
                        Numeric :$box-width = 20, Str :$color = 'steelblue',
                        Numeric :$opacity = 0.45, Bool :$horizontal = False,
                        Str :$legend = '' --> Layer:D) is export {
    die 'The argument box-width is expected to be positive.' unless $box-width > 0;
    Layer.new(kind => 'box-whisker', data => numeric-values($data, 'box-whisker'),
              :$box-x, :$box-width, :$color, :$opacity, :$horizontal, :$legend);
}

sub layer-code(Layer:D $layer, Int:D $index --> Str:D) {
    my $data = to-json($layer.data, :!pretty);
    my $color = to-json($layer.color);
    my $class = "plot-layer layer-{$layer.kind}";
    my $name = "layerData$index";

    my $geometry = do given $layer.kind {
        when 'line' {
            q:to/END/;
group.append('path')
  .datum(LAYER_DATA)
  .attr('d', d3.line().x(function(d) { return x(d.x); }).y(function(d) { return y(d.y); }))
  .attr('fill', 'none')
  .attr('stroke', LAYER_COLOR)
  .attr('stroke-width', LAYER_STROKE_WIDTH);
END
        }
        when 'points' {
            q:to/END/;
group.selectAll('circle')
  .data(LAYER_DATA)
  .join('circle')
    .attr('cx', function(d) { return x(d.x); })
    .attr('cy', function(d) { return y(d.y); })
    .attr('r', LAYER_POINT_RADIUS)
    .attr('fill', LAYER_COLOR);
END
        }
        when 'labels' {
            q:to/END/;
group.selectAll('text')
  .data(LAYER_DATA)
  .join('text')
    .attr('x', function(d) { return x(d.x); })
    .attr('y', function(d) { return y(d.y); })
    .attr('dx', 4)
    .attr('dy', -4)
    .attr('fill', LAYER_COLOR)
    .style('font-size', LAYER_FONT_SIZE + 'px')
    .text(function(d) { return d.label; });
END
        }
        when 'histogram' {
            q:to/END/;
group.selectAll('rect')
  .data(HISTOGRAM_BINS)
  .join('rect')
    .attr('x', function(d) { return x(d.x0) + 1; })
    .attr('y', function(d) { return y(d.length); })
    .attr('width', function(d) { return Math.max(0, x(d.x1) - x(d.x0) - 1); })
    .attr('height', function(d) { return y(0) - y(d.length); })
    .attr('fill', LAYER_COLOR)
    .attr('fill-opacity', LAYER_OPACITY);
END
        }
        when 'box-whisker' {
            q:to/END/;
var sortedValues = LAYER_DATA.slice().sort(function(a, b) { return a - b; });
var q1 = d3.quantileSorted(sortedValues, 0.25);
var median = d3.quantileSorted(sortedValues, 0.5);
var q3 = d3.quantileSorted(sortedValues, 0.75);
var iqr = q3 - q1;
var lowerWhisker = d3.min(sortedValues.filter(function(v) { return v >= q1 - 1.5 * iqr; }));
var upperWhisker = d3.max(sortedValues.filter(function(v) { return v <= q3 + 1.5 * iqr; }));
var boxCenter = x(BOX_X);
var outliers = sortedValues.filter(function(v) { return v < lowerWhisker || v > upperWhisker; });

if (BOX_HORIZONTAL) {
  boxCenter = y(BOX_X);
  group.append('line')
    .attr('x1', x(lowerWhisker)).attr('x2', x(upperWhisker))
    .attr('y1', boxCenter).attr('y2', boxCenter).attr('stroke', LAYER_COLOR);
  group.append('rect')
    .attr('x', x(q1)).attr('width', Math.max(0, x(q3) - x(q1)))
    .attr('y', boxCenter - BOX_WIDTH / 2).attr('height', BOX_WIDTH)
    .attr('fill', LAYER_COLOR).attr('fill-opacity', LAYER_OPACITY).attr('stroke', LAYER_COLOR);
  group.append('line')
    .attr('x1', x(median)).attr('x2', x(median))
    .attr('y1', boxCenter - BOX_WIDTH / 2).attr('y2', boxCenter + BOX_WIDTH / 2)
    .attr('stroke', LAYER_COLOR);
  group.selectAll('circle.box-outlier').data(outliers).join('circle')
    .attr('class', 'box-outlier').attr('cx', function(v) { return x(v); })
    .attr('cy', boxCenter).attr('r', 3).attr('fill', LAYER_COLOR);
} else {
  group.append('line')
    .attr('x1', boxCenter).attr('x2', boxCenter)
    .attr('y1', y(lowerWhisker)).attr('y2', y(upperWhisker)).attr('stroke', LAYER_COLOR);
  group.append('rect')
    .attr('x', boxCenter - BOX_WIDTH / 2).attr('width', BOX_WIDTH)
    .attr('y', y(q3)).attr('height', Math.max(0, y(q1) - y(q3)))
    .attr('fill', LAYER_COLOR).attr('fill-opacity', LAYER_OPACITY).attr('stroke', LAYER_COLOR);
  group.append('line')
    .attr('x1', boxCenter - BOX_WIDTH / 2).attr('x2', boxCenter + BOX_WIDTH / 2)
    .attr('y1', y(median)).attr('y2', y(median)).attr('stroke', LAYER_COLOR);
  group.selectAll('circle.box-outlier').data(outliers).join('circle')
    .attr('class', 'box-outlier').attr('cx', boxCenter)
    .attr('cy', function(v) { return y(v); }).attr('r', 3).attr('fill', LAYER_COLOR);
}
END
        }
        default { die "Unsupported combination layer kind '{$layer.kind}'."; }
    };

    qq:to/END/;
// BEGIN layer: {$layer.kind}-$index
var $name = $data;
var group = svg.append('g').attr('class', '$class');
{$geometry.subst(:g, 'LAYER_DATA', $name)
            .subst(:g, 'LAYER_COLOR', $color)
            .subst(:g, 'LAYER_STROKE_WIDTH', $layer.stroke-width)
            .subst(:g, 'LAYER_POINT_RADIUS', $layer.point-size / 2)
            .subst(:g, 'LAYER_FONT_SIZE', $layer.font-size)
            .subst(:g, 'LAYER_OPACITY', $layer.opacity)
            .subst(:g, 'HISTOGRAM_BINS', "histogramBins$index")
            .subst(:g, 'BOX_X', $layer.box-x)
            .subst(:g, 'BOX_WIDTH', $layer.box-width)
            .subst(:g, 'BOX_HORIZONTAL', $layer.horizontal ?? 'true' !! 'false')}
// END layer: {$layer.kind}-$index
END
}

sub shared-scales-code(@layers, Bool:D $axes, $grid-lines,
                       :$x-axis-scale = Whatever, :$y-axis-scale = Whatever --> Str:D) {
    my @points = @layers.grep({ .kind ne 'histogram' && .kind ne 'box-whisker' }).map(*.data).flat.Array;
    my %histogram-data;
    my @box-data;
    my @histogram-bins;
    for @layers.kv -> $index, $layer {
        if $layer.kind eq 'histogram' {
            %histogram-data{$index + 1} = $layer.data;
            @histogram-bins.push($layer.number-of-bins);
        }
        if $layer.kind eq 'box-whisker' {
            @box-data.push(%(x => $layer.box-x, values => $layer.data, horizontal => $layer.horizontal));
        }
    }
    die 'Histogram layers in one composition must use the same number-of-bins.'
        if @histogram-bins.unique.elems > 1;

    my $histogram-data = to-json(%histogram-data, :!pretty);
    my $box-data = to-json(@box-data, :!pretty);
    my $point-data = to-json(@points, :!pretty);
    my $bin-count = @histogram-bins.elems ?? @histogram-bins[0] !! 0;
    my $x-axis = JavaScript::D3::CodeSnippets::ProcessAxisScale($x-axis-scale);
    my $y-axis = JavaScript::D3::CodeSnippets::ProcessAxisScale($y-axis-scale);
    my $x-grid = $axes && $grid-lines[0] > 0 ?? ".ticks($grid-lines[0]).tickSizeInner(-height)" !! '';
    my $y-grid = $axes && $grid-lines[1] > 0 ?? ".ticks($grid-lines[1]).tickSizeInner(-width)" !! '';
    my $axes-code = '';
    if $axes {
        $axes-code = q:to/END/;
svg.append('g')
  .attr('transform', 'translate(0,' + height + ')')
  .call(d3.axisBottom(x)AXIS_X_GRID);
svg.append('g')
  .call(d3.axisLeft(y)AXIS_Y_GRID);
END
    }
    # AXES_CODE is inserted after the main template substitutions, so resolve
    # its local placeholders before embedding it.
    $axes-code = $axes-code
        .subst('AXIS_X_GRID', $x-grid, :g)
        .subst('AXIS_Y_GRID', $y-grid, :g);

    my $code = q:to/END/;
// Obtain point-like data and raw histogram values separately.
var combinationPoints = POINT_DATA;
var histogramLayerData = HISTOGRAM_DATA;
var histogramValues = Object.values(histogramLayerData).flat();
var boxLayerData = BOX_DATA;
var verticalBoxes = boxLayerData.filter(function(d) { return !d.horizontal; });
var horizontalBoxes = boxLayerData.filter(function(d) { return d.horizontal; });
var verticalBoxXValues = verticalBoxes.map(function(d) { return d.x; });
var verticalBoxYValues = verticalBoxes.flatMap(function(d) { return d.values; });
var horizontalBoxXValues = horizontalBoxes.flatMap(function(d) { return d.values; });
var horizontalBoxYValues = horizontalBoxes.map(function(d) { return d.x; });
var xValues = combinationPoints.map(function(d) { return d.x; })
  .concat(histogramValues, verticalBoxXValues, horizontalBoxXValues);
var yValues = combinationPoints.map(function(d) { return d.y; })
  .concat(verticalBoxYValues, horizontalBoxYValues);
var xMin = d3.min(xValues);
var xMax = d3.max(xValues);

// Histogram layers intentionally share one bin generator and therefore one
// set of bin boundaries.
var histogramBinGenerator = d3.bin()
  .domain([xMin, xMax])
  .thresholds(NUMBER_OF_BINS);
HISTOGRAM_BIN_SETS

var histogramCounts = HISTOGRAM_COUNTS;
var yMin = yValues.length ? d3.min(yValues) : 0;
var yMax = yValues.length ? d3.max(yValues) : 0;
if (histogramCounts.length) {
  yMin = Math.min(0, yMin);
  yMax = Math.max(yMax, d3.max(histogramCounts));
}

var x = d3.X_AXIS_SCALE
  .domain([xMin, xMax])
  .range([0, width]);
var y = d3.Y_AXIS_SCALE
  .domain([yMin, yMax])
  .range([height, 0]);
AXES_CODE
END
    my @bin-sets = %histogram-data.keys.sort.map({ "var histogramBins$_ = histogramBinGenerator(histogramLayerData[\"$_\"]);" });
    my $counts = '[' ~ %histogram-data.keys.sort.map({ 'histogramBins' ~ $_ ~ '.map(function(bin) { return bin.length; })' }).join(', ') ~ '].flat()';
    $code.subst('POINT_DATA', $point-data)
        .subst('HISTOGRAM_DATA', $histogram-data)
        .subst('BOX_DATA', $box-data)
        .subst('NUMBER_OF_BINS', $bin-count)
        .subst('HISTOGRAM_BIN_SETS', @bin-sets.join("\n"))
        .subst('HISTOGRAM_COUNTS', $counts)
        .subst('X_AXIS_SCALE', $x-axis, :g)
        .subst('Y_AXIS_SCALE', $y-axis, :g)
        .subst('AXES_CODE', $axes-code, :g);
}

sub legend-code(@layers --> Str:D) {
    my @entries = @layers.grep(*.legend.chars).map({ %(label => .legend, color => .color) });
    return '' unless @entries.elems;
    my $entries = to-json(@entries, :!pretty);
    my $code = q:to/END/;
// BEGIN decoration:legend
var legendEntries = LEGEND_ENTRIES;
var legend = svg.append('g').attr('class', 'plot-legend')
  .attr('transform', 'translate(' + (width + 12) + ',0)');
legend.selectAll('circle').data(legendEntries).join('circle')
  .attr('cx', 0).attr('cy', function(d, i) { return i * 24; })
  .attr('r', 5).attr('fill', function(d) { return d.color; });
legend.selectAll('text').data(legendEntries).join('text')
  .attr('x', 10).attr('y', function(d, i) { return i * 24; })
  .attr('dominant-baseline', 'middle').style('font-size', '12px')
  .text(function(d) { return d.label; });
// END decoration:legend
END
    $code.subst('LEGEND_ENTRIES', $entries);
}

#| Compose 2D histogram, box-whisker, line, point, and label layers in one SVG with shared axes.
our sub Combine(*@layers,
                Str :$background = 'White',
                :$width = 600, :$height = 400,
                :plot-label(:$title) = '',
                UInt :plot-label-font-size(:$title-font-size) = 16,
                Str :plot-label-color(:$title-color) = 'Black',
                :x-label(:$x-axis-label) = '',
                Str :x-label-color(:$x-axis-label-color) = 'Black',
                UInt :x-label-font-size(:$x-axis-label-font-size) = 12,
                :y-label(:$y-axis-label) = '',
                Str :y-label-color(:$y-axis-label-color) = 'Black',
                UInt :y-label-font-size(:$y-axis-label-font-size) = 12,
                :$x-axis-scale = Whatever,
                :$y-axis-scale = Whatever,
                :$grid-lines is copy = False,
                :$margins is copy = Whatever,
                Bool :$axes = True,
                Bool :$legends = True,
                Str :$format = 'jupyter',
                :$div-id = Whatever --> Str:D) is export {
    die 'js-d3-combine needs at least one layer.' unless @layers.elems;
    die 'js-d3-combine accepts only JavaScript::D3 combination layers.'
    unless [&&] @layers.map({ $_ ~~ Layer });

    my $title-text = $title ~~ Positional ?? $title.join(' ') !! $title.Str;
    my $x-label-text = $x-axis-label ~~ Positional ?? $x-axis-label.join(' ') !! $x-axis-label.Str;
    my $y-label-text = $y-axis-label ~~ Positional ?? $y-axis-label.join(' ') !! $y-axis-label.Str;
    my %margins = JavaScript::D3::Utilities::ProcessMargins($margins);
    my $processed-grid-lines = JavaScript::D3::Utilities::ProcessGridLines($grid-lines);
    if $legends && @layers.grep(*.legend.chars).elems {
        %margins<right> = max(%margins<right>, 120);
    }

    my $frame = JavaScript::D3::CodeSnippets::GetPlotMarginsTitleAndLabelsCode($format)
            .subst('$MARGINS', to-json(%margins, :!pretty))
            .subst('$WIDTH', $width.Str).subst('$HEIGHT', $height.Str)
            .subst('$BACKGROUND_COLOR', to-json($background))
            .subst('$TITLE_FONT_SIZE', $title-font-size).subst('$TITLE_FILL', to-json($title-color)).subst('$TITLE', to-json($title-text))
            .subst('$X_AXIS_LABEL_FONT_SIZE', $x-axis-label-font-size).subst('$X_AXIS_LABEL_FILL', to-json($x-axis-label-color)).subst('$X_AXIS_LABEL', to-json($x-label-text))
            .subst('$Y_AXIS_LABEL_FONT_SIZE', $y-axis-label-font-size).subst('$Y_AXIS_LABEL_FILL', to-json($y-axis-label-color)).subst('$Y_AXIS_LABEL', to-json($y-label-text));

    my $scales = shared-scales-code(@layers, $axes, $processed-grid-lines,
            :$x-axis-scale, :$y-axis-scale);

    my $layers = @layers.kv.map(-> $index, $layer { layer-code($layer, $index + 1) }).join("\n");
    my $legend = $legends ?? legend-code(@layers) !! '';
    my $code = ["// BEGIN plot-frame\n$frame\n// END plot-frame",
                "// BEGIN shared-scales-and-axes\n$scales\n// END shared-scales-and-axes",
                $layers, $legend].grep(*.chars).join("\n\n");
    JavaScript::D3::CodeSnippets::WrapIt($code, :$format, :$div-id);
}
