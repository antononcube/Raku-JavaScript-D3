unit module JavaScript::D3::Graph;

use JavaScript::D3::CodeSnippets;
use JavaScript::D3::Predicates;
use JavaScript::D3::Plots;
use JavaScript::D3::Utilities;
use Hash::Merge;
use JSON::Fast;


#============================================================
# Graph
#============================================================

#| Makes a bubble chart for list of triplets..
our proto GraphPlot(|) is export {*}

our multi GraphPlot($data where $data ~~ Seq, *%args) {
    return GraphPlot($data.List, |%args);
}

our multi GraphPlot(@data where @data.all ~~ Pair:D, *%args) {

    return GraphPlot(@data>>.kv>>.List.List, |%args);
}

our multi GraphPlot($data where is-positional-of-lists($data, 2), *%args) {
    my @data2 = $data.map({ %( <from to weight label>.Array Z=> [|$_.Array, 1, '']) });
    return GraphPlot(@data2, |%args);
}

our multi GraphPlot($data where is-positional-of-lists($data, 3), *%args) {
    my @data2 = $data.map({ %( <from to weight label>.Array Z=> [|$_.Array, '']) });
    return GraphPlot(@data2, |%args);
}

our multi GraphPlot($data where is-positional-of-lists($data, 4), *%args) {
    my @data2 = $data.map({ %( <from to weight label>.Array Z=> $_.Array) });
    return GraphPlot(@data2, |%args);
}

our multi GraphPlot(@data is copy where @data.all ~~ Map,
                    :$width = 400,
                    :$height = Whatever,
                    Str :plot-label(:$title) = '',
                    UInt :plot-label-font-size(:$title-font-size) = 16,
                    Str :plot-label-color(:$title-color) = 'Black',
                    :$vertex-label-color is copy = Whatever,
                    :$vertex-label-font-size is copy = Whatever,
                    :$edge-label-color is copy = Whatever,
                    :$edge-label-font-size is copy = Whatever,
                    Str:D :$background = 'white',
                    Str:D :$vertex-color = 'SteelBlue',
                    Numeric:D :$vertex-size = 2,
                    Str:D :$edge-color = 'SteelBlue',
                    :$edge-thickness is copy = 1,
                    :$margins is copy = Whatever,
                    Str :$format = 'jupyter',
                    :$div-id = Whatever
                    ) {

    #======================================================
    # Arguments
    #======================================================
    # Process edge thickness
    die 'The value of $edge-thickness is expected to be a non-negative numbeer or Whatever'
    unless $edge-thickness ~~ Numeric:D && $edge-thickness ≥ 0 || $edge-thickness.isa(Whatever);

    $edge-thickness = $edge-thickness.isa(Whatever) ?? 'd => Math.sqrt(d.weight)' !! $edge-thickness.Str;

    #------------------------------------------------------
    # Vertex label color
    if $vertex-label-color.isa(Whatever) { $vertex-label-color = $title-color; }
    die 'The value of $vertex-label-color is expected to be a string or Whatever'
    unless $vertex-label-color ~~ Str:D;

    # Vertex label font size
    if $vertex-label-font-size.isa(Whatever) { $vertex-label-font-size = round($title-font-size * 0.8); }
    die 'The value of $vertex-label-font-size is expected to be a number or Whatever'
    unless $vertex-label-font-size ~~ Numeric:D;

    # Edge label color
    if $edge-label-color.isa(Whatever) { $edge-label-color = $vertex-label-color; }
    die 'The value of $edge-label-color is expected to be a string or Whatever'
    unless $edge-label-color ~~ Str:D;

    # Edge label font size
    if $edge-label-font-size.isa(Whatever) { $edge-label-font-size = $vertex-label-font-size; }
    die 'The value of $edge-label-font-size is expected to be a number or Whatever'
    unless $edge-label-font-size ~~ Numeric:D;

    #------------------------------------------------------
    # Process width and height
    ($width, $height) = JavaScript::D3::Utilities::ProcessWidthAndHeight(:$width, :$height, aspect-ratio => $horizontal ?? 1/2 !! 2);

    #------------------------------------------------------
    # Process margins
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    #======================================================
    # Plot creation
    #======================================================
    # Convert to JSON data
    my $jsData = to-json(@data.map({ merge-hash( %(weight => 1, label => ''), $_ ) }).Array, :!pretty);

    #------------------------------------------------------
    # Stencil code
    my $jsChart = [JavaScript::D3::CodeSnippets::GetPlotMarginsAndTitle($format),
                   JavaScript::D3::CodeSnippets::GetGraphPart()].join("\n");

    #------------------------------------------------------
    # Concrete values
    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst(:g, '$NODE_STROKE_COLOR', '"' ~ $vertex-color ~ '"')
            .subst(:g, '$NODE_FILL_COLOR', '"' ~ $vertex-color ~ '"')
            .subst(:g, '$NODE_SIZE', $vertex-size.Str)
            .subst(:g, '$NODE_LABEL_STROKE_COLOR', '"' ~ $vertex-label-color ~ '"')
            .subst(:g, '$NODE_LABEL_FONT_SIZE', $vertex-label-font-size)
            .subst(:g, '$LINK_STROKE_COLOR', '"' ~ $edge-color ~ '"')
            .subst(:g, '$LINK_LABEL_FONT_SIZE', $edge-label-font-size)
            .subst(:g, '$LINK_LABEL_STROKE_COLOR', '"' ~ $edge-label-color ~ '"')
            .subst(:g, '$LINK_STROKE_WIDTH', $edge-thickness)
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE_FONT_SIZE', $title-font-size)
            .subst(:g, '$TITLE_FILL', '"' ~ $title-color ~ '"')
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty);

    #------------------------------------------------------
    # Result
    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}
