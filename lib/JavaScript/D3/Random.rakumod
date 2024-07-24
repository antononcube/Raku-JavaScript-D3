unit module JavaScript::D3::Random;

use Data::Generators;

#============================================================
# Random mandala
#============================================================

our sub Mandala(
        Numeric :$radius = 1,
        Numeric :$rotational-symmetry-order = 6,
        UInt :$number-of-seed-elements = 10,
        Bool :$symmetric-seed = True) {

    my @randomMandala;

    my $ang = 2 * π / $rotational-symmetry-order;
    my $ang2 = $symmetric-seed ?? $ang / 2 !! $ang;

    # Make seed segment
    my $range = (0, 1 / $number-of-seed-elements ... 1).List;
    my @poly0 = $range.map({ ($radius * $_) X* (cos($ang2), sin($ang2)) }).Array;
    @poly0 = [|@poly0, |$range.map({ ($radius * $_, 0) })].pick(*);

    # Reflection
    if $symmetric-seed {
        my @polyRefl = @poly0.map({ ($_[0], -$_[1]) });
        @poly0 = [|@poly0, |@polyRefl];
    }

    # Rotation matrix;
    my @rotMat = [[cos($ang), -sin($ang)], [sin($ang), cos($ang)]];

    # First segment
    my @polyRot = @poly0;
    @randomMandala = @polyRot.map({ %( group => 0.Str, x => $_[0], y => $_[1]) }).List;

    # Rotation of the seed
    for $ang, 2 * $ang ... (2 * π) -> $a {
        @polyRot = @polyRot.map({ ((sum $_.List Z* @rotMat[0].List), (sum $_.List Z* @rotMat[1].List)) });
        my @d = @polyRot.map({ %( group => $a.Str, x => $_[0], y => $_[1]) }).List;
        @randomMandala = [|@randomMandala, |@d.reverse]
    }

    return @randomMandala;
}

#===========================================================
# Rescale
#===========================================================
proto rescale($x, |) {*};

multi rescale($x where $x ~~ Numeric,
              Numeric $min,
              Numeric $max,
              Numeric $vmin,
              Numeric $vmax) {
    return rescale([$x,], $min, $max, $vmin, $vmax)[0];
}

multi rescale(@x) {
    return rescale(@x, (min(@x), max(@x)), (0, 1));
}
multi rescale(@x, @vrng where @vrng.elems == 2) {
    return rescale(@x, @vrng, (0, 1));
}

multi rescale(@x,
              @rng where @rng.elems == 2,
              @vrng where @vrng.elems == 2) {
    rescale(@x, @rng[0], @rng[1], @vrng[0], @vrng[1])
}

multi rescale(@x,
              Numeric $min,
              Numeric $max,
              Numeric $vmin,
              Numeric $vmax) {

    if $max != $min {
        my @res = (@x X- $min) X/ ($max - $min);
        return (@res X* ($vmax - $vmin)) X+ $vmin;
    }

    return @x X- $min;
}

#============================================================
# Random scribble
#============================================================

sub rfunc($x) {
    my $a = rescale(rand, 0, 1, 0.8, 1.2);
    my $f = rescale(rand, 0, 1, -0.2, 0.2);;
    return cos($a * $x * π / 2 + $f);
}

our sub Scribble(
        UInt :$number-of-strokes = 120,
        Bool :$ordered-stroke-points = True,
        :$rotation-angle = Whatever,
        :$envelope-functions = Whatever) {

    my @xs = rescale(rand xx ($number-of-strokes + 1), 0, 1, -1, 1);
    my @ys = rescale(rand xx ($number-of-strokes + 1), 0, 1, -1, 1);
    my @r = @xs Z @ys;

    # Envelope functions
    if $envelope-functions.isa(Whatever) || $envelope-functions.isa(WhateverCode) {
        @r = @r.map({ ($_[0], rescale($_[1], -1, 1, -rfunc($_[0]), rfunc($_[0])) )});
    }

    # Ordered stroke points
    if $ordered-stroke-points { @r = @r.sort({ $_[0] }); }

    # Rotation angle
    if $rotation-angle ~~ Numeric {
        my @rotMat = [[cos($rotation-angle), -sin($rotation-angle)], [sin($rotation-angle), cos($rotation-angle)]];
        @r = @r.map({ ((sum $_.List Z* @rotMat[0].List), (sum $_.List Z* @rotMat[1].List)) });
    }

    return @r;
}

#============================================================
# Random Koch curve
#============================================================

sub cross(@v) {
    if (@v.all ~~ Numeric:D) && @v.elems == 2 {
        return [ -@v[1], @v[0] ];
    } elsif @v.elems == 2 && @v[0].elems == 3 && @v[1].elems == 3 {
        my ($a, $b) = @v;
        return [
            $a[1] * $b[2] - $a[2] * $b[1],
            $a[2] * $b[0] - $a[0] * $b[2],
            $a[0] * $b[1] - $a[1] * $b[0]
        ];
    } else {
        die "A 2D vector or two 3D vectors are expected as arguments.";
    }
}

#-----------------------------------------------------------
sub random-koch-curve-helper(@spec, @points) {
    my ($posspec, $widthspec, $heightspec) = @spec;
    my ($p1, $p5) = @points;
    my $alpha1 = $posspec - $widthspec / 2;
    my $alpha2 = $posspec + $widthspec / 2;
    my $p2 = (1 - $alpha1) <<*<< $p1 <<+>> $alpha1 <<*<< $p5;
    my $p4 = (1 - $alpha2) <<*<< $p1 <<+>> $alpha2 <<*<< $p5;
    my $p3 = (1 - $posspec) <<*<< $p1 <<+>> $posspec <<*<< $p5 <<+>> ($p5 <<->> $p1).&cross >>*>> $heightspec;
    return ($p1, $p2, $p3, $p4, $p5);
}

#-----------------------------------------------------------
our proto sub KochCurve($pts, $possdist, $widthdist, $heightdist, Int $n) is export {*}

multi sub KochCurve(Whatever, $possdist, $widthdist, $heightdist, Int $n) {
    return KochCurve([[0, 0], [1, 0]], $possdist, $widthdist, $heightdist, $n);
}

multi sub KochCurve(@pts, $possdist, $widthdist, $heightdist, Int $n) {
    my @out = @pts;
    for ^$n {
        @out = @out.rotor(2 => -1);

        my @ps = $possdist ~~ Numeric:D ?? $possdist xx @out.elems !! random-variate($possdist, @out.elems);
        my @ws = $widthdist ~~ Numeric:D ?? $widthdist xx @out.elems !! random-variate($widthdist, @out.elems);
        my @hs = $heightdist ~~ Numeric:D ?? $heightdist xx @out.elems !! random-variate($heightdist, @out.elems);

        @out = do for ^@out.elems -> $i {
            random-koch-curve-helper([ @ps[$i], @ws[$i], @hs[$i] ], @out[$i])
        }

        @out = [@out.head, |@out.tail(*-1).map({ $_.tail(*-1) })];
        @out .= map(*.Slip);
    }
    return @out;
}

#============================================================
# Random Mondrian
#============================================================
sub rectangle-splitting(%d where { %d<x1> < %d<x2> && %d<y1> < %d<y2> }) {
    my $t = random-variate(BetaDistribution.new(10, 10));
    my $r = rand;
    my $x1 = %d<x1>;
    my $y1 = %d<y1>;
    my $x2 = %d<x2>;
    my $y2 = %d<y2>;

    given $r {
        when $_ < 0.3 * ($x2 - $x1) / ($y2 - $y1) {
            return (
            { :$x1, :$y1, x2 => $x1 + ($x2 - $x1) * $t, :$y2},
            { x1 => $x1 + ($x2 - $x1) * $t, :$y1, :$x2, :$y2}
            );
        }
        when 1 - $_ < 0.5 * ($y2 - $y1) / ($x2 - $x1) {
            return (
            { :$x1, :$y1, :$x2, y2 => $y1 + ($y2 - $y1) * $t },
            { :$x1, y1 => $y1 + ($y2 - $y1) * $t, :$x2, :$y2}
            );
        }
        default {
            return (%d,);
        }
    }
}

our sub Mondrian(Numeric:D $width,
                 Numeric:D $height,
                 UInt:D $max-iterations = 6,
                 Numeric:D :$jitter = 0) {
    my @rects = [{x1 => 0, y1 => 0, x2 => $width, y2 => $height}, ];
    for ^$max-iterations {
        @rects .= map({ rectangle-splitting($_).Slip })
    }
    if $jitter {
        @rects = @rects.map({ <x1 y1 x2 y2> Z=> $_<x1 y1 x2 y2> <<+>> random-real([0, $jitter], 4) })».Hash.pick(*)
    }
    return @rects;
}
