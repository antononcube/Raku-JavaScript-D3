unit module JavaScript::D3::Utilities;

use Data::TypeSystem;
use Data::TypeSystem::Predicates;
use Hash::Merge;

our sub reallyflat (+@list) {
    gather @list.deepmap: *.take
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


