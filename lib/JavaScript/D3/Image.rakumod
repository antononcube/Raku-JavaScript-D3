unit module JavaScript::D3::Image;

use Data::TypeSystem::Predicates;
use JavaScript::D3::CodeSnippets;
use JSON::Fast;

#============================================================
# Image
#============================================================

my @knownSequentialSchemes =
        <Blues BuGn BuPu Cividis Cool CubehelixDefault GnBu Greens Greys Inferno Magma
Oranges OrRd Plasma PuBu PuBuGn PuRd Purples RdPu Reds Turbo Viridis Warm
lGn YlGnBu YlOrBr YlOrRd>;

our proto Image($data, |) is export {*}

our multi Image($data where $data ~~ Seq, *%args) {
    return Image($data.List, |%args);
}

our multi Image(@data where is-matrix(@data, Numeric:D),
                Str :$color-palette= "Greys",
                :$width is copy = Whatever,
                :$height is copy = Whatever,
                :$low-value is copy = Whatever,
                :$high-value is copy = Whatever,
                Str :$format = 'jupyter',
                :$div-id = Whatever
                ) {

    my $nRows = @data.elems;
    my $nCols = @data.head.elems;

    # Process $low-value
    if $low-value.isa(Whatever) {
        $low-value = min(JavaScript::D3::CodeSnippets::reallyflat(@data))
    }
    die "The argument \$low-value is expected Whatever or Numeric:D."
    unless $low-value ~~ Numeric:D;

    # Process $high-value
    if $high-value.isa(Whatever) {
        $high-value = max(JavaScript::D3::CodeSnippets::reallyflat(@data))
    }
    die "The argument \$max-value is expected Whatever or Numeric:D."
    unless $low-value ~~ Numeric:D;

    # Process width
    if $width.isa(Whatever) { $width = $nCols; }
    die "The argument \$width is expected Whatever or a positive integer."
    unless $width ~~ Int:D && $width > 0;

    # Process width
    if $height.isa(Whatever) { $height = $nRows; }
    die "The argument \$height is expected Whatever or a positive integer."
    unless $height ~~ Int:D && $height > 0;


    # Make data to hand over to D3.js
    my @values = |JavaScript::D3::CodeSnippets::reallyflat(@data);
    my $jsData = to-json({ :$width, :$height, :@values }, :!pretty);

    # Stencil
    my $jsImage = [
        JavaScript::D3::CodeSnippets::GetImagePart()
    ].join("\n");

    # Concrete parameters
    my $res = $jsImage
            .subst('$DATA', $jsData)
            .subst('$COLOR_PALETTE', $color-palette)
            .subst(:g, '$LOW_VALUE', $low-value)
            .subst(:g, '$HIGH_VALUE', $high-value)
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str);

    $res = JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
    return $res.subst(/ '<head>' \h* \v+ /,
            "<head>\n\t<canvas style=\"width:{ $width }px; height:{ $height }px;\"></canvas>\n");
}
