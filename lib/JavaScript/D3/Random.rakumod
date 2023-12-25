unit module JavaScript::D3::Random;

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