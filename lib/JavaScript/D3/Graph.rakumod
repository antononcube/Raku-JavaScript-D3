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
# Highlight spec processing
#============================================================
# Default highlight colors
my @defaultHighlightColors =
        <#faba8c #a71c00 #f29838 #feffdb #5f885e #ddede3 #7db79f #7da9ac #9fcede #cc6f84>;

sub is-positional-of-strings-or-pairs($list) {
    return False unless $list ~~ Positional:D;
    for |$list -> $item {
        return False unless $item ~~ Str:D or $item ~~ Pair:D;
    }
    return True;
}

sub ProcessHighlightSpec($highlight, Bool :$directed-edges = False) {
    if ! $highlight {
        return Empty
    }
    my %spec = do given $highlight {
        when is-positional-of-strings-or-pairs($_) {
            %('Orange' => $_ )
        }

        when ($_ ~~ Positional:D || $_ ~~ Seq:D) && ([&&] |$_.map(*.&is-positional-of-strings-or-pairs)) {
            if $_.elems ≤ @defaultHighlightColors.elems {
                (@defaultHighlightColors[0..$_.elems].Array Z=> $_.Array).Hash
            } else {
                die "Please provide a map of color-to-highlight-group pairs.";
            }
        }

        when $_ ~~ Hash:D && ([&&] |$_.values.map(*.&is-positional-of-strings-or-pairs)) {
            $_
        }

        default {
            die "The highlight spec is expected to be a list of vertexes or edges, " ~
                    "or a list of such lists, or a Map of colors to such lists."
        }
    };

    %spec = do if $directed-edges {
        %spec.map({ $_.key => [|$_.value.grep({ $_ ~~ Str:D }), |$_.value.grep({ $_ ~~ Pair:D }).map({ $_.kv })] });
    } else {
        %spec.map({ $_.key => [|$_.value.grep({ $_ ~~ Str:D }), |$_.value.grep({ $_ ~~ Pair:D }).map({ $_.kv }), |$_.value.grep({ $_ ~~ Pair:D }).map({ $_.kv.reverse })] });
    }

    return %spec;
}

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
                    :%vertex-coordinates = %(),
                    :$width is copy = 400,
                    :$height is copy = Whatever,
                    Str :plot-label(:$title) = '',
                    UInt :plot-label-font-size(:$title-font-size) = 16,
                    Str :plot-label-color(:$title-color) = 'Black',
                    :$vertex-label-color is copy = Whatever,
                    :$vertex-label-font-size is copy = Whatever,
                    :$vertex-label-font-family is copy = 'Courier New',
                    :$edge-label-color is copy = Whatever,
                    :$edge-label-font-size is copy = Whatever,
                    :$edge-label-font-family is copy = 'Courier New',
                    Str:D :$background = 'White',
                    :vertex-color(:$vertex-fill-color) is copy = Whatever,
                    :$vertex-stroke-color is copy = Whatever,
                    Numeric:D :$vertex-size = 2,
                    :$edge-color is copy = 'SteelBlue',
                    :%force is copy = %(),
                    :$edge-thickness is copy = 1,
                    :$arrowhead-size is copy = Whatever,
                    :$arrowhead-offset is copy = Whatever,
                    :$highlight is copy = Empty,
                    :$margins is copy = Whatever,
                    Str :$format = 'jupyter',
                    :$div-id = Whatever
                    ) {

    #======================================================
    # Arguments
    #======================================================
    # Process edge thickness
    die 'The value of $edge-thickness is expected to be a non-negative numbeer or Whatever.'
    unless $edge-thickness ~~ Numeric:D && $edge-thickness ≥ 0 || $edge-thickness.isa(Whatever);

    $edge-thickness = $edge-thickness.isa(Whatever) ?? 'd => Math.sqrt(d.weight)' !! $edge-thickness.Str;

    #------------------------------------------------------
    # Vertex label color
    if $vertex-label-color.isa(Whatever) { $vertex-label-color = $title-color; }
    die 'The value of $vertex-label-color is expected to be a string or Whatever.'
    unless $vertex-label-color ~~ Str:D;

    # Vertex label font size
    if $vertex-label-font-size.isa(Whatever) { $vertex-label-font-size = round($title-font-size * 0.8); }
    die 'The value of $vertex-label-font-size is expected to be a number or Whatever.'
    unless $vertex-label-font-size ~~ Numeric:D;

    # Vertex label font family
    if $vertex-label-font-family.isa(Whatever) { $vertex-label-font-family = 'Courier New'; }
    die 'The value of $vertex-label-font-family is expected to be a string or Whatever.'
    unless $vertex-label-font-family ~~ Str:D;

    # Edge label color
    if $edge-label-color.isa(Whatever) { $edge-label-color = $vertex-label-color; }
    die 'The value of $edge-label-color is expected to be a string or Whatever.'
    unless $edge-label-color ~~ Str:D;

    # Edge label font size
    if $edge-label-font-size.isa(Whatever) { $edge-label-font-size = $vertex-label-font-size; }
    die 'The value of $edge-label-font-size is expected to be a number or Whatever.'
    unless $edge-label-font-size ~~ Numeric:D;

    # Edge label font family
    if $edge-label-font-family.isa(Whatever) { $edge-label-font-family = 'Courier New'; }
    die 'The value of $edge-label-font-family is expected to be a string or Whatever.'
    unless $edge-label-font-family ~~ Str:D;

    #------------------------------------------------------
    # Vertex and edge colors processing
    given ($vertex-fill-color, $edge-color) {
        when (Whatever, Whatever) {
            $vertex-fill-color = 'SteelBlue'; $edge-color = 'SteelBlue';
        }
        when $_.head.isa(Whatever) && ($_.tail ~~ Str:D) {
            $vertex-fill-color = $_.tail;
        }
        when ($_.head ~~ Str:D) && $_.tail.isa(Whatever) {
            $edge-color = $_.head;
        }
        when !( ($_.head ~~ Str:D) && ($_.tail ~~ Str:D) ) {
            die 'The arguments vertex-color and edge-color are expected to be strings or Whatever.';
        }
    }

    if $vertex-stroke-color.isa(Whatever) { $vertex-stroke-color = $vertex-fill-color }
    die 'The value of $vertex-stroke-color is expected to be a string or Whatever.'
    unless $vertex-stroke-color ~~ Str:D;

    #------------------------------------------------------
    # Arrowhead size and offset
    if $arrowhead-size.isa(Whatever) { $arrowhead-size = $edge-thickness + 2; }
    die 'The value of $arrowhead-size is expected to be a number or Whatever.'
    unless $arrowhead-size ~~ Numeric:D;

    if $arrowhead-offset.isa(Whatever) { $arrowhead-offset = 2 * $arrowhead-size + $vertex-size; }
    die 'The value of $arrowhead-offset is expected to be a number or Whatever.'
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

    my $jsVertexCoords = [];
    if %vertex-coordinates {
        $jsVertexCoords = do if %vertex-coordinates.values.all ~~ Map:D {
            to-json(%vertex-coordinates, :!pretty);
        } elsif %vertex-coordinates.values.all ~~ Positional:D {
            to-json(%vertex-coordinates.map({ $_.key => %( x => $_.value.head, y => $_.value.tail) }).Hash, :!pretty);
        } else {
            die 'The value of vertex-coordinates is expected to be a Map of Maps with keys <x y>, or a Map of Positionals of length two.'
        }
    }

    #------------------------------------------------------
    # Stencil code
    my $jsChart = [
        JavaScript::D3::CodeSnippets::GetPlotMarginsAndTitle($format),
        %vertex-coordinates ??  JavaScript::D3::CodeSnippets::GetGraphWithCoordsPart() !! JavaScript::D3::CodeSnippets::GetGraphPart()
    ].join("\n");

    #------------------------------------------------------
    # Concrete values
    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$VERTEX_COORDINATES', $jsVertexCoords)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst(:g, '$NODE_STROKE_COLOR', '"' ~ $vertex-stroke-color ~ '"')
            .subst(:g, '$NODE_FILL_COLOR', '"' ~ $vertex-fill-color ~ '"')
            .subst(:g, '$NODE_SIZE', $vertex-size.Str)
            .subst(:g, '$NODE_LABEL_STROKE_COLOR', '"' ~ $vertex-label-color ~ '"')
            .subst(:g, '$NODE_LABEL_FONT_SIZE', $vertex-label-font-size)
            .subst(:g, '$NODE_LABEL_FONT_FAMILY', '"' ~ $vertex-label-font-family ~ '"')
            .subst(:g, '$LINK_STROKE_COLOR', '"' ~ $edge-color ~ '"')
            .subst(:g, '$LINK_LABEL_FONT_SIZE', $edge-label-font-size)
            .subst(:g, '$LINK_LABEL_STROKE_COLOR', '"' ~ $edge-label-color ~ '"')
            .subst(:g, '$LINK_LABEL_FONT_FAMILY', '"' ~ $edge-label-font-family ~ '"')
            .subst(:g, '$LINK_STROKE_WIDTH', $edge-thickness)
            .subst(:g, '$ARROWHEAD_SIZE', $arrowhead-size)
            .subst(:g, '$ARROWHEAD_OFFSET', $arrowhead-offset)
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE_FONT_SIZE', $title-font-size)
            .subst(:g, '$TITLE_FILL', '"' ~ $title-color ~ '"')
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty);

    # Force components
    if !%force<link><distance>.isa(Whatever) {
        my $ds = %force<link><distance>.Str.lc ∈ <edgeweight weight> ?? 'd => d.weight' !!  %force<link><distance>;
        $res .= subst('$FORCE_LINK_DISTANCE', $ds)
    }
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
    $highlight = ProcessHighlightSpec($highlight);
    if $highlight ~~ Map:D {
        $res .= subst('$HIGHLIGHT_SPEC', to-json($highlight, :!pretty))
    } else {
        $res .= subst('$HIGHLIGHT_SPEC', '{}')
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
            .subst('$HIGHLIGHT_SPEC', '');

    #------------------------------------------------------
    # Result
    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}
