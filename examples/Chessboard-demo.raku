#!/usr/bin/env raku
use v6.d;

use JavaScript::D3;

#===========================================================
# Initial position

#spurt $*CWD ~ '/chessboard.html', js-d3-chessboard(width => 600, height => 650, format => 'html');

#===========================================================
# Given position in long form

my @chessPos = [
    {:x("a"), :y("8"), :z("r")}, {:x("c"), :y("8"), :z("b")}, {:x("d"), :y("8"), :z("k")}, {:x("h"), :y("8"), :z("r")},
    {:x("a"), :y("7"), :z("p")}, {:x("d"), :y("7"), :z("p")}, {:x("e"), :y("7"), :z("B")}, {:x("f"), :y("7"), :z("p")}, {:x("g"), :y("7"), :z("N")}, {:x("h"), :y("7"), :z("p")},
    {:x("a"), :y("6"), :z("n")}, {:x("f"), :y("6"), :z("n")}, {:x("b"), :y("5"), :z("p")},
    {:x("d"), :y("5"), :z("N")}, {:x("e"), :y("5"), :z("P")}, {:x("h"), :y("5"), :z("P")},
    {:x("g"), :y("4"), :z("P")}, {:x("d"), :y("3"), :z("P")},
    {:x("a"), :y("2"), :z("P")}, {:x("c"), :y("2"), :z("P")}, {:x("e"), :y("2"), :z("K")},
    {:x("a"), :y("1"), :z("q")}, {:x("g"), :y("1"), :z("b")}
];

#spurt $*CWD ~ '/chessboard.html', js-d3-chessboard(@chessPos, width => 600, height => 650, format => 'html');


#===========================================================
# Given position as a FEN string

my @fens = [
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR',
    'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR',
    'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R'
];

spurt $*CWD ~ '/chessboard.html',
        js-d3-chessboard(@fens,
                background => '#EEEEEE',
                color-palette=>'Greens',
                black-square-value => 0.1,
                white-square-value => 0.75,
                tick-label-color=>'red',
                width=>450,
                format => 'html');

