use v6.d;

unit module JavaScript::D3::Random;

our sub Mandala(
        UInt :$rotational-symmetry-order = 6,
        UInt :$number-of-seed-elements = 10,
        Bool :$symmetric-seed = True) {

    #--------------------------------------------------------
    # Make the random mandala
    #--------------------------------------------------------
    my @randomMandala;

    my $ang = 2 * π / $rotational-symmetry-order;
    my $ang2 = $symmetric-seed ?? $ang / 2 !! $ang ;

    # Make seed segment
    my $radius = 1;
    my $range = (0, 1 / $number-of-seed-elements ... 1).List;
    my @poly0 = $range.map({ ($radius * $_) X* (cos($ang2), sin($ang2)) }).Array;
    @poly0 = [|@poly0, |$range.map({ ($radius * $_, 0) })].pick(*);

    if $symmetric-seed {

        # Reflection
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
        @randomMandala = [|@randomMandala, |@d]
    }

    return @randomMandala;
}