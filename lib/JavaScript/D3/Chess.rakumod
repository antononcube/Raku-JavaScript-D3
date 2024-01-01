unit module JavaScript::D3::Chess;

use JavaScript::D3::CodeSnippets;
use JavaScript::D3::Predicates;
use JavaScript::D3::Plots;
use Hash::Merge;
use JSON::Fast;

use FEN::Grammar;
use FEN::Actions;

#===========================================================

my %chess-to-html =
        '♔' => '&#9812;',
        '♕' => '&#9813;',
        '♖' => '&#9814;',
        '♗' => '&#9815;',
        '♘' => '&#9816;',
        '♙' => '&#9817;',
        '♚' => '&#9818;',
        '♛' => '&#9819;',
        '♜' => '&#9820;',
        '♝' => '&#9821;',
        '♞' => '&#9822;',
        '♟' => '&#9823;';

my %chess-pieces =
        :p('♟'), :P('♙'), :r('♜'), :R('♖'),
        :n('♞'), :N('♘'), :b('♝'), :B('♗'),
        :q('♛'), :Q('♕'), :k('♚'), :K('♔');

my %white-to-black = :P('p'), :R('r'), :N('n'), :B('b'), :Q('q'), :K('k');
%white-to-black = %white-to-black , ('♙♖♘♗♕♔'.comb Z=> '♟♜♞♝♛♚'.comb).Hash;

#===========================================================

sub chess-color(Str $x, Str $y) {
    my %char-to-num = 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5, 'f' => 6, 'g' => 7, 'h' => 8;
    return ($y.Int + %char-to-num{$x}) % 2 == 0 ?? 'black' !! 'white';
}

#===========================================================

sub starting-chess-position() {
    [
        { :x("a"), :y("8"), :z("r") }, { :x("b"), :y("8"), :z("n") }, { :x("c"), :y("8"), :z("b") }, { :x("d"), :y("8"), :z("q") }, { :x("e"), :y("8"), :z("k") }, { :x("f"), :y("8"), :z("b") }, { :x("g"), :y("8"), :z("n") }, { :x("h"), :y("8"), :z("r") },
        { :x("a"), :y("7"), :z("p") }, { :x("b"), :y("7"), :z("p") }, { :x("c"), :y("7"), :z("p") }, { :x("d"), :y("7"), :z("p") }, { :x("e"), :y("7"), :z("p") }, { :x("f"), :y("7"), :z("p") }, { :x("g"), :y("7"), :z("p") }, { :x("h"), :y("7"), :z("p") },
        { :x("a"), :y("2"), :z("P") }, { :x("b"), :y("2"), :z("P") }, { :x("c"), :y("2"), :z("P") }, { :x("d"), :y("2"), :z("P") }, { :x("e"), :y("2"), :z("P") }, { :x("f"), :y("2"), :z("P") }, { :x("g"), :y("2"), :z("P") }, { :x("h"), :y("2"), :z("P") },
        { :x("a"), :y("1"), :z("R") }, { :x("b"), :y("1"), :z("N") }, { :x("c"), :y("1"), :z("B") }, { :x("d"), :y("1"), :z("Q") }, { :x("e"), :y("1"), :z("K") }, { :x("f"), :y("1"), :z("B") }, { :x("g"), :y("1"), :z("N") }, { :x("h"), :y("1"), :z("R") }
    ]
}

#============================================================
# Chessboard
#============================================================

#| Makes a bubble chart for list of triplets..
our proto Chessboard(|) is export {*}

our multi Chessboard($data where $data ~~ Seq, *%args) {
    return Chessboard($data.List, |%args);
}

our multi Chessboard(*%args) {
    return Chessboard(starting-chess-position, |%args);
}

our multi Chessboard(Str $data, *%args) {
    return Chessboard([$data,], |%args);
}

our multi Chessboard(@data where @data.all ~~ Str, *%args) {

    # Interpret into rows
    my @fenData;
    for @data.kv -> $k, $d {
        my $match = FEN::Grammar.parse($d, actions => FEN::Actions.new);
        my $resObj = $match.made;

        my @ranks = |$resObj.position-set().grep({ so $_.value }).map({ [|$_.key.split(/\h/), $_.value] })>>.Array.Array;

        @fenData.append( @ranks.map({ (<x y z group> Z=> [|$_.Array, $k].Array).Hash.deepmap(*.Str) }) );
    }

    # Delegate
    return Chessboard(@fenData, |%args);
}

our multi Chessboard($data where is-positional-of-lists($data, 3), *%args) {
    my @data2 = $data.map({ %( <x y z>.Array Z=> $_.Array) });
    return Chessboard(@data2, |%args);
}

our multi Chessboard(@data is copy where @data.all ~~ Map,
                     :$width = 400,
                     :$height = Whatever,
                     Str :$background = 'white',
                     Str :$color-palette = 'Greys',
                     Numeric :$black-square-value = 0.5,
                     Numeric :$white-square-value = 0.15,
                     Str :$tick-label-color = 'black',
                     Numeric :$opacity = 1.0,
                     Str :plot-label(:$title) = '',
                     :$margins is copy = Whatever,
                     Str :$format = 'jupyter',
                     :$div-id = Whatever
                     ) {

    #-------------------------------------------------------
    # Groups
    #-------------------------------------------------------
    my Bool $hasGroups = [&&] @data.map({ so $_<group> });

    if $hasGroups {

        my $resTotal;
        for @data.classify(*<group>).pairs.sort(*.key) -> $p {
            $resTotal ~= "\n\n" ~
                    Chessboard($p.value.map({ $_.grep({ $_.key ne 'group' }).Hash }).Array,
                            :$width, :$height,
                            :$background,
                            :$color-palette, :$black-square-value, :$white-square-value,
                            :$tick-label-color, :$opacity, :$title, :$margins, :$div-id, format => 'asis');
        }

        return JavaScript::D3::CodeSnippets::WrapIt($resTotal, :$format, :$div-id);
    }

    my %chess-values = white => $white-square-value, black => $black-square-value;
    my @dsField = 'a' .. 'h' X (1 .. 8)>>.Str;
    @dsField .= sort;
    @dsField = @dsField.map({ <x y z> Z=> [|$_, %chess-values{chess-color(|$_)}] })>>.Hash;

    my $res =
            JavaScript::D3::Plots::HeatmapPlot(@dsField,
                                               :$width,
                                               :$height,
                                               low-value => 0,
                                               high-value => 1,
                                               :$title,
                                               :$color-palette,
                                               :$background,
                                               :$tick-label-color,
                                               :$opacity,
                                               :$margins,
                                               format => 'asis');

    $res =
            $res
            .subst('.on("mouseover", mouseover)')
            .subst('.on("mousemove", mousemove)')
            .subst('.on("mouseleave", mouseleave)')
            .subst('.attr("rx", 4)')
            .subst('.attr("ry", 4)');

    #-------------------------------------------------------
    # Fill in chess arguments
    #-------------------------------------------------------
    if @data {
        my @white-data = @data.grep({ $_<z> ∈ %white-to-black });

        # Print white piece only
        if @white-data {
            my @chessData = @white-data.clone.map({ merge-hash($_, %( z => %chess-to-html{%chess-pieces{%white-to-black{$_<z>}} // $_<z>})) });

            my $jsData = to-json(@chessData, :!pretty);

            $res = $res ~ "\n" ~ JavaScript::D3::CodeSnippets::GetTooltipHeatmapPlotLabelsPart();

            $res = $res
                    .subst('$PLOT_LABELS_DATA', $jsData)
                    .subst(:g, '$PLOT_LABELS_COLOR', '"white"')
                    .subst('$PLOT_LABELS_FONT_SIZE', 'function(d) { return (height / 8) + "px" }')
                    .subst('$PLOT_LABELS_Y_OFFSET', 'hy*0.1');
        }

        # Print all pieces
        my @chessData = @data.clone.map({ merge-hash($_, %( z => %chess-to-html{%chess-pieces{$_<z>} // $_<z>})) });

        my $jsData = to-json(@chessData, :!pretty);

        $res = $res ~ "\n" ~ JavaScript::D3::CodeSnippets::GetTooltipHeatmapPlotLabelsPart();

        $res = $res
                .subst('$PLOT_LABELS_DATA', $jsData)
                .subst(:g, '$PLOT_LABELS_COLOR', '"black"')
                .subst('$PLOT_LABELS_FONT_SIZE', 'function(d) { return (height / 8) + "px" }')
                .subst('$PLOT_LABELS_Y_OFFSET', 'hy*0.1');
    }

    # Result
    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}
