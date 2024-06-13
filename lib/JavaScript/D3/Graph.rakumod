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
                    Str:D :$background = 'white',
                    Str:D :$vertex-color = 'SteelBlue',
                    Numeric:D :$vertex-size = 2,
                    Str:D :$edge-color = 'SteelBlue',
                    :$edge-thickness is copy = 1,
                    :$margins is copy = Whatever,
                    Str :$format = 'jupyter',
                    :$div-id = Whatever
                    ) {

    #------------------------------------------------------
    # Process edge thickness
    #------------------------------------------------------
    die 'The value of $edge-thickness is expected to be a non-negative numbeer or Whatever'
    unless $edge-thickness ~~ Numeric:D && $edge-thickness ≥ 0 || $edge-thickness.isa(Whatever);

    $edge-thickness = $edge-thickness.isa(Whatever) ?? 'd => Math.sqrt(d.weight)' !! $edge-thickness.Str;

    #------------------------------------------------------
    # Plot creation
    #------------------------------------------------------
    # Convert to JSON data
    my $jsData = to-json(@data, :!pretty);

    # Stencil code
    my $jsChart = [JavaScript::D3::CodeSnippets::GetPlotMarginsAndTitle($format),
                   JavaScript::D3::CodeSnippets::GetGraphPart()].join("\n");

    # Concrete values
    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst(:g, '$NODE_STROKE_COLOR', '"' ~ $vertex-color ~ '"')
            .subst(:g, '$NODE_FILL_COLOR', '"' ~ $vertex-color ~ '"')
            .subst(:g, '$NODE_SIZE', $vertex-size.Str)
            .subst(:g, '$NODE_LABEL_STROKE_COLOR', '"' ~ $title-color ~ '"')
            .subst(:g, '$LINK_STROKE_COLOR', '"' ~ $edge-color ~ '"')
            .subst(:g, '$LINK_LABEL_STROKE_COLOR', '"' ~ $title-color ~ '"')
            .subst(:g, '$LINK_STROKE_WIDTH', $edge-thickness)
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE_FONT_SIZE', $title-font-size)
            .subst(:g, '$TITLE_FILL', '"' ~ $title-color ~ '"')
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty);

    # Result
    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}