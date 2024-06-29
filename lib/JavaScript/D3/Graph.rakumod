unit module JavaScript::D3::Graph;

use JavaScript::D3::CodeSnippets;
use JavaScript::D3::Predicates;
use JavaScript::D3::Plots;
use JavaScript::D3::Utilities;
use Hash::Merge;
use JSON::Fast;


#============================================================
# Force spec
#============================================================

my %forceProperties =
    center => {
        x => 0.5,
        y => 0.5
    },
    charge => {
        :enabled,
        strength => -30,
        distanceMin => 1,
        distanceMax => 2000
    },
    collision => {
        :enabled,
        strength => 0.7,
        iterations => 1,
        radius => 5
    },
    x => {
        :!enabled,
        strength => 0.1,
        x => 0.5
    },
    y => {
        :!enabled,
        strength => 0.1,
        y => 0.5
    },
    link => {
        :enabled,
        distance => 30,
        iterations => 1
    };

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
                    Bool:D :d(:directed(:$directed-edges)) = False,
                    :$width is copy = 400,
                    :$height is copy = Whatever,
                    Str :plot-label(:$title) = '',
                    UInt :plot-label-font-size(:$title-font-size) = 16,
                    Str :plot-label-color(:$title-color) = 'Black',
                    :$vertex-label-color is copy = Whatever,
                    :$vertex-label-font-size is copy = Whatever,
                    :$edge-label-color is copy = Whatever,
                    :$edge-label-font-size is copy = Whatever,
                    Str:D :$background = 'White',
                    :$vertex-color is copy = Whatever,
                    Numeric:D :$vertex-size = 2,
                    :$edge-color is copy = 'SteelBlue',
                    :%force is copy = %(),
                    :$edge-thickness is copy = 1,
                    :$arrowhead-size is copy = Whatever,
                    :$arrowhead-offset is copy = Whatever,
                    :@highlight = Empty,
                    Str:D :$highlight-color = 'Orange',
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
    # Vertex and edge colors processing
    given ($vertex-color, $edge-color) {
        when (Whatever, Whatever) {
            $vertex-color = 'SteelBlue'; $edge-color = 'SteelBlue';
        }
        when $_.head.isa(Whatever) && ($_.tail ~~ Str:D) {
            $vertex-color = $_.tail;
        }
        when ($_.head ~~ Str:D) && $_.tail.isa(Whatever) {
            $edge-color = $_.head;
        }
        when !( ($_.head ~~ Str:D) && ($_.tail ~~ Str:D) ) {
            die 'The arguments vertex-color and edge-color are expected to be strings or Whatever.';
        }
    }

    #------------------------------------------------------
    # Arrowhead size and offset
    if $arrowhead-size.isa(Whatever) { $arrowhead-size = $edge-thickness + 2; }
    die 'The value of $arrowhead-size is expected to be a number or Whatever'
    unless $arrowhead-size ~~ Numeric:D;

    if $arrowhead-offset.isa(Whatever) { $arrowhead-offset = 2 * $arrowhead-size + $vertex-size; }
    die 'The value of $arrowhead-offset is expected to be a number or Whatever'
    unless $arrowhead-offset ~~ Numeric:D;

    #------------------------------------------------------
    # Process width and height
    ($width, $height) = JavaScript::D3::Utilities::ProcessWidthAndHeight(:$width, :$height, aspect-ratio => 1 / 1.618);

    #------------------------------------------------------
    # Process force
    my %forceDefault;
    %forceDefault<center> = %( x => 'width / 2', y => 'height / 2');
    %forceDefault<x> = %( strength => Whatever, :enabled );
    %forceDefault<y> = %( strength => Whatever, :enabled );
    %forceDefault<collision> = %( strength => Whatever, radius => Whatever );
    %forceDefault<charge> = %( strength => Whatever );
    %forceDefault<link> = %( distance => Whatever );

    %forceDefault = merge-hash(%forceProperties, %forceDefault, :deep);

    %force = merge-hash(%forceDefault, %force, :deep);

    if %force<link-distance> ~~ Str:D && %force<link-distance> eq 'weights' {
        %force<link-distance> = 'd => d.weight';
    }

    if %force<center>.isa(Whatever) {
        %force<center> = ('width / 2', 'height / 2');
    }

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
            .subst(:g, '$ARROWHEAD_SIZE', $arrowhead-size)
            .subst(:g, '$ARROWHEAD_OFFSET', $arrowhead-offset)
            .subst(:g, '$HIGHLIGHT_STROKE_COLOR', '"' ~ $highlight-color ~ '"')
            .subst(:g, '$HIGHLIGHT_FILL_COLOR', '"' ~ $highlight-color ~ '"')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE_FONT_SIZE', $title-font-size)
            .subst(:g, '$TITLE_FILL', '"' ~ $title-color ~ '"')
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty);

    # Force components
    if !%force<link><distance>.isa(Whatever) { $res .= subst('$FORCE_LINK_DISTANCE', %force<link><distance>) }
    if !%force<link><iterations>.isa(Whatever) { $res .= subst('$FORCE_LINK_ITER', %force<link><iterations>) }
    if !%force<charge><strength>.isa(Whatever) { $res .= subst('$FORCE_CHARGE_STRENGTH', %force<charge><strength>) }
    if !%force<charge><distanceMin>.isa(Whatever) { $res .= subst('$FORCE_CHARGE_DIST_MIN', %force<charge><distanceMin>) }
    if !%force<charge><distanceMax>.isa(Whatever) { $res .= subst('$FORCE_CHARGE_DIST_MAX', %force<charge><distanceMax>) }
    if !%force<x><strength>.isa(Whatever) { $res .= subst('$FORCE_X_STRENGTH', %force<x><strength>) }
    if !%force<y><strength>.isa(Whatever) { $res .= subst('$FORCE_Y_STRENGTH', %force<y><strength>) }
    if !%force<collision><radius>.isa(Whatever) { $res .= subst('$FORCE_COLLIDE_RADIUS', %force<collision><radius>) }
    if !%force<collision><strength>.isa(Whatever) { $res .= subst('$FORCE_COLLIDE_STRENGTH', %force<collision><strength>) }
    if !%force<center><x>.isa(Whatever) { $res .= subst('$FORCE_CENTER_X', %force<center><x>) }
    if !%force<center><y>.isa(Whatever) { $res .= subst('$FORCE_CENTER_Y', %force<center><y>) }

    # Process highlight spec
    if @highlight {
        my @links = @highlight.grep({ $_ ~~ Pair:D }).map({ $_.kv.join('-') });
        if ! $directed-edges {
           @links = [|@links, |@highlight.grep({ $_ ~~ Pair:D }).map({ $_.kv.reverse.join('-') })];
        }
        if @links {
            $res .= subst('$HIGHLIGHT_LINK_SET', "\"{ @links.join("\", \"") }\"")
        }

        my @nodes = @highlight.grep({ $_ ~~ Str:D });
        if @nodes {
            $res .= subst('$HIGHLIGHT_SET', "\"{ @nodes.join("\", \"") }\"")
        }
    }

    if !$directed-edges {
        $res .= subst(".attr('marker-end','url(#arrowhead)')");
    }

    $res = $res
            .subst('.distance($FORCE_LINK_DISTANCE)')
            .subst('.iterations($FORCE_LINK_ITER)')
            .subst('.strength($FORCE_CHARGE_STRENGTH)')
            .subst('.distanceMin($FORCE_CHARGE_DIST_MIN)')
            .subst('.distanceMax($FORCE_CHARGE_DIST_MAX)')
            .subst('.x($FORCE_X)')
            .subst('.strength($FORCE_X_STRENGTH)')
            .subst('.strength($FORCE_Y_STRENGTH)')
            .subst('.y($FORCE_Y)')
            .subst('.strength($FORCE_COLLIDE_STRENGTH)')
            .subst('.radius($FORCE_COLLIDE_RADIUS)')
            .subst('.iterations($FORCE_COLLIDE_ITER)')
            .subst('$HIGHLIGHT_LINK_SET', '')
            .subst('$HIGHLIGHT_SET', '');

    #------------------------------------------------------
    # Result
    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}
