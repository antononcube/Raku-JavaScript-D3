unit module JavaScript::D3::Chess;

use JavaScript::D3::CodeSnippets;
use JavaScript::D3::Predicates;
use JavaScript::D3::Plots;
use Hash::Merge;
use JSON::Fast;

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

my %chess-pieces = :p('♟'), :P('♙'), :r('♜'), :R('♖'), :n('♞'), :N('♘'), :b('♝'), :B('♗'), :q('♛'), :Q('♕'), :k('♚'), :K('♔');


#===========================================================

sub chess-color(Str $x, Str $y) {
    my %char-to-num = 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5, 'f' => 6, 'g' => 7, 'h' => 8;
    return ($y.Int + %char-to-num{$x}) % 2 == 0 ?? 0 !! 0.5;
}

#============================================================
# Chessboard
#============================================================

#| Makes a bubble chart for list of triplets..
our proto Chessboard($data, |) is export {*}

our multi Chessboard($data where $data ~~ Seq, *%args) {
    return Chessboard($data.List, |%args);
}

our multi Chessboard(*%args) {
    return Chessboard([], |%args);
}

our multi Chessboard($data where is-positional-of-lists($data, 3), *%args) {
    my @data2 = $data.map({ %( <x y z>.Array Z=> $_.Array) });
    return Chessboard(@data2, |%args);
}

our multi Chessboard(@data is copy where @data.all ~~ Map,
                     Str :$background= 'white',
                     Numeric :$opacity = 0.7,
                     :$width = 600,
                     :$height = 650,
                     Str :plot-label(:$title) = '',
                     :$margins is copy = Whatever,
                     Str :$format = 'jupyter',
                     :$div-id = Whatever
                     ) {

    my @dsField = 'a' .. 'h' X (1 .. 8)>>.Str;
    @dsField .= sort;
    @dsField = @dsField.map({ <x y z> Z=> [|$_, chess-color(|$_)] })>>.Hash;

    note @dsField.raku;

    my $res =
            JavaScript::D3::Plots::HeatmapPlot(@dsField,
                                               :$width,
                                               :$height,
                                               color-palette => 'Greys',
                                               low-value => 0,
                                               high-value => 1,
                                               x-axis-label => 'x coordinates',
                                               y-axis-label => 'y coordinates',
                                               plot-label => 'Chessboard',
                                               :$background,
                                               :$opacity,
                                               :$margins,
                                               format => 'asis');

    #-------------------------------------------------------
    # Fill in chess arguments
    #-------------------------------------------------------
    if @data {
        my @chessData = @data.clone.map({ merge-hash( $_, %( z => %chess-to-html{ %chess-pieces{$_<z>} // $_<z> } )) });

        my $jsData = to-json(@chessData, :!pretty);

        $res = $res ~ "\n" ~ JavaScript::D3::CodeSnippets::GetChessboardPart();

        $res = $res
                .subst('$CHESS_DATA', $jsData);
    }
    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}
