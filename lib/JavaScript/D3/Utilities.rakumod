unit module JavaScript::D3::Utilities;

use Data::TypeSystem;
use Data::TypeSystem::Predicates;
use Hash::Merge;
use JSON::Fast;

#============================================================
# Really flat
#============================================================
# This is obsolete with the new .flat functionalities.
our sub reallyflat (+@list) {
    gather @list.deepmap: *.take
}

#============================================================
# Get/ingest named colors
#============================================================

# From https://htmlcolorcodes.com/color-names/ :
#   Modern browsers support 140 named colors, which are listed below.
#   Use them in your HTML and CSS by name, Hex color code or RGB value.

my %namedColors;
our sub get-named-colors() {
    if %namedColors.elems == 0 {
        %namedColors = from-json(slurp(%?RESOURCES<named-colors.json>.IO))
    }
    return %namedColors.clone;
}

#============================================================
# Process margins
#============================================================

our sub ProcessMargins($margins is copy) {
    my %defaultMargins = %( top => 40, bottom => 40, left => 40, right => 40);
    $margins = do given $margins {
        when $_.isa(Whatever) { %defaultMargins; }
        when $_ ~~ Int { (<top bottom left right>.List X=> $_).Hash; }
        default { $margins }
    }
    die "The argument margins is expected to be a Map or Whatever." unless $margins ~~ Map;
    $margins = merge-hash(%defaultMargins, $margins);
    return $margins;
}

#============================================================
# Process grid lines
#============================================================

our sub ProcessGridLines($gridLines is copy) {
    my @defaultGridLines = (5, 5);
    $gridLines = do given $gridLines {
        when $_ ~~ Bool && !$_ { (0, 0) }
        when $_ ~~ Bool && $_ { @defaultGridLines }
        when $_.isa(Whatever) { @defaultGridLines; }
        when $_ ~~ List && $_.elems == 1 { ($_[0], @defaultGridLines[1]) }
        when $_ ~~ List && $_.elems == 2 { $_ }
        when $_ ~~ Numeric && $_.round ≥ 0 { ($_.round, $_.round) }
    }

    $gridLines = $gridLines.map({ $_.isa(Whatever) ?? 0 !! $_ }).List;

    die "The argument grid-lines is expected to be a non-negative integer, Whatever, or a two element list of those type of values."
    unless $gridLines ~~ List && $gridLines.elems == 2 && $gridLines.all ~~ UInt;

    return $gridLines;
}

#============================================================
# Find record columns
#============================================================

our proto RecordColumns($data) {*}

multi sub RecordColumns(@data where @data.all ~~ Positional) {
    return Empty;
}

multi sub RecordColumns(@data where @data.all ~~ Map) {

    my $tt = deduce-type(@data);

    if $tt ~~ Data::TypeSystem::Vector {
        if $tt.type ~~ Data::TypeSystem::Struct {
            return $tt.type.keys;
        }
    }

    return Empty;
}

#============================================================
# Labels colors and font sizes
#============================================================

our sub ProcessLabelsColorsAndFontSizes(
        UInt :$title-font-size!,
        Str :$title-color!,
        :$x-axis-label-color is copy = Whatever,
        :$x-axis-label-font-size is copy = Whatever,
        :$y-axis-label-color is copy = Whatever,
        :$y-axis-label-font-size is copy = Whatever) {

    # Labels color
    given ($x-axis-label-color, $y-axis-label-color) {
        when (Whatever, Whatever) {
            $x-axis-label-color = $title-color;
            $y-axis-label-color = $title-color
        }
        when $_.head.isa(Whatever) && $_.tail ~~ Str:D {
            $x-axis-label-color =  $y-axis-label-color;
        }
        when $_.head ~~ Str:D && $_.tail.isa(Whatever) {
            $y-axis-label-color =  $x-axis-label-color;
        }
        default {
            $x-axis-label-color = 'Black';
            $y-axis-label-color = 'Black';
        }
    }

    # Labels font size
    given ($x-axis-label-font-size, $y-axis-label-font-size) {
        when (Whatever, Whatever) {
            $x-axis-label-font-size = max(4, round($title-font-size * 3 /4));
            $y-axis-label-font-size = max(4, round($title-font-size * 3 /4));
        }
        when $_.head.isa(Whatever) && $_.tail ~~ Str:D {
            $x-axis-label-font-size =  $y-axis-label-font-size;
        }
        when $_.head ~~ Str:D && $_.tail.isa(Whatever) {
            $y-axis-label-font-size =  $x-axis-label-font-size;
        }
        default {
            $x-axis-label-font-size = 12;
            $y-axis-label-font-size = 12;
        }
    }


    # Return
    return [$x-axis-label-color, $x-axis-label-font-size, $y-axis-label-color, $y-axis-label-font-size];
}

#============================================================
# Width and height
#============================================================

our sub ProcessWidthAndHeight(:$width! is copy,
                              :$height! is copy,
                              Numeric:D :$aspect-ratio = 2 / 3,
                              UInt:D :$default = 600) {

    given ($width, $height) {
        when $_.head.isa(Whatever) && $_.tail ~~ UInt:D {
           $width = $height * 1 / $aspect-ratio;
        }
        when $_.head ~~ UInt:D && $_.tail.isa(Whatever) {
           $height = $width * $aspect-ratio;
        }
        when $_.head ~~ UInt:D && $_.tail ~~ UInt:D {
            # do nothing
        }
        default {
            $width = $default;
            $height = $width * $aspect-ratio;
        }
    }

    return ($width.round, $height.round);
}

#============================================================
# Normalize records
#============================================================

our proto NormalizeData($data,
                        :$columns-from = Whatever,
                        :$columns-to = Whatever) {*}

multi sub NormalizeData(%data,
                        :$columns-from is copy = Whatever,
                        :$columns-to is copy = Whatever) {

    if %data.values.all ~~ Numeric:D {
       return %data.map({ %(x => $_.key, y => $_.value ) }).Array;
    }

    return NormalizeData(%data.values, :$columns-to, :$columns-from);
}

multi sub NormalizeData(@data where @data.all ~~ Positional,
                        :$columns-from is copy = Whatever,
                        :$columns-to is copy = Whatever) {

    if [&&] @data.map({ $_.all ~~ Pair }) {
        return NormalizeData(@data>>.Hash.Array, :$columns-from, :$columns-to);
    }

    if $columns-from.isa(Whatever) && $columns-to.all ~~ Str && has-homogeneous-shape(@data) && $columns-to.elems ≤ @data[0].elems {
        return NormalizeData(@data.map({ $columns-to.Array Z=> $_[^$columns-to.elems].Array }));
    }

    return @data;
}

multi sub NormalizeData(@data where @data.all ~~ Map,
                        :$columns-from is copy = Whatever,
                        :$columns-to is copy = Whatever) {

    if $columns-from.isa(Whatever) {
        $columns-from = RecordColumns(@data);
    }

    if !$columns-from {
        return @data;
    }

    if $columns-to.isa(Whatever) {
        given $columns-from {
            when $_.elems == 2 && $_.sort({.lc})>>.lc eq <value variable> {
                $columns-from = $_.sort({.lc}).cache;
                $columns-to = <y x>;
            }
            when $_.elems == 2 {
                $columns-to = <x y>
            }
            when $_.elems == 3 && $_.sort({.lc})>>.lc eqv <group value variable> {
                $columns-from = $_.sort({.lc}).cache;
                $columns-to = <group y x>;
            }
            when $_.elems == 4 && $_.sort({.lc})>>.lc eqv <group label value variable> {
                $columns-from = $_.sort({.lc}).cache;
                $columns-to = <group label y x>;
            }
            when $_.elems == 3 && $_.sort({.lc})>>.lc eqv <label value variable> {
                $columns-from = $_.sort({.lc}).cache;
                $columns-to = <label y x>;
            }
            when $_.elems == 3 && 'group' ∈ $_>>.lc {
                my $k = 0;
                $columns-to = $_.map({ $_.lc eq 'group' ?? 'group' !! <x y>[$k++] }).List;
            }
            when (<group x y> (&) $_>>.lc).elems == 3 {
                $columns-from = <group x y>;
                $columns-to = <group x y>;
            }
            when $_.elems == 3 {
                $columns-to = <x y z>;
            }
        }
    }

    if !($columns-from ~~ Iterable && $columns-to ~~ Iterable && $columns-from.elems == $columns-to.elems) {
        die 'The arguments $columns-from and $columns-to are expected to be Iterables and of same length.';
    }

    if $columns-from.sort eqv $columns-to.sort {
        return @data;
    }

    return @data.map({ ($columns-to.Array Z=> $_{|$columns-from}.Array).Hash }).Array;
}

#============================================================
# AnglePath
#============================================================

#| Gives the list of 2D coordinates corresponding to a path that starts at [0,0],
#| then takes a series of steps of unit length at successive relative angles.
proto sub angle-path($angles, |) is export {*}
multi sub angle-path(@angles) {
    my $x = 0;
    my $y = 0;
    my $angle = 0;
    my @path = [$x, $y], ;
    for @angles -> $th {
        $angle += $th;
        $x += cos($angle);
        $y += sin($angle);
        @path.push([$x, $y]);
    }
    return @path;
}

multi sub angle-path(@steps where all(@steps) ~~ Positional) {
    my $x = 0;
    my $y = 0;
    my $angle = 0;
    my @path = [$x, $y], ;
    for @steps -> ($r, $th) {
        $angle += $th;
        $x += $r * cos($angle);
        $y += $r * sin($angle);
        @path.push([$x, $y]);
    }
    return @path;
}

multi sub angle-path(Numeric:D $th0, @steps) {
    my $x = 0;
    my $y = 0;
    my $angle = $th0;
    my @path = [$x, $y], ;
    for @steps -> $th {
        $angle += $th;
        $x += cos($angle);
        $y += sin($angle);
        @path.push([$x, $y]);
    }
    return @path;
}

multi sub angle-path(($x0, $y0), @steps) {
    my $x = $x0;
    my $y = $y0;
    my $angle = 0;
    my @path = [$x, $y], ;
    for @steps -> $th {
        $angle += $th;
        $x += cos($angle);
        $y += sin($angle);
        @path.push([$x, $y]);
    }
    return @path;
}

#============================================================
# Optimization
#============================================================
BEGIN { get-named-colors() }


