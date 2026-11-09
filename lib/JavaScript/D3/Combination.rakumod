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
            .subst(:g, 'LAYER_FONT_SIZE', $layer.font-size)}
// END layer: {$layer.kind}-$index
END
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

#| Compose 2D line, point, and label layers in one SVG with shared linear axes.
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
    my @data = @layers.map(*.data).flat.Array;
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

    my $scales = ($axes
            ?? JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(|$processed-grid-lines, :$x-axis-scale, :$y-axis-scale)
            !! JavaScript::D3::CodeSnippets::GetPlotDataAndScalesCode(:$x-axis-scale, :$y-axis-scale))
            .subst('$DATA', to-json(@data, :!pretty));

    my $layers = @layers.kv.map(-> $index, $layer { layer-code($layer, $index + 1) }).join("\n");
    my $legend = $legends ?? legend-code(@layers) !! '';
    my $code = ["// BEGIN plot-frame\n$frame\n// END plot-frame",
                "// BEGIN shared-scales-and-axes\n$scales\n// END shared-scales-and-axes",
                $layers, $legend].grep(*.chars).join("\n\n");
    JavaScript::D3::CodeSnippets::WrapIt($code, :$format, :$div-id);
}
