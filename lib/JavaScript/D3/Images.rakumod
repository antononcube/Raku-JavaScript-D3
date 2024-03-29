unit module JavaScript::D3::Images;

use Data::TypeSystem::Predicates;
use JavaScript::D3::CodeSnippets;
use JavaScript::D3::Utilities;
use JSON::Fast;

#============================================================
# ImageDisplay
#============================================================

our proto ImageDisplay($data, |) is export {*}

our multi ImageDisplay($spec,
                       :$width is copy = Whatever,
                       :$height is copy = Whatever,
                       Str :$format = 'jupyter',
                       :$div-id = Whatever ) {

    #-------------------------------------------------------
    # Verify $spec
    #-------------------------------------------------------
    # TBD...

    #-------------------------------------------------------
    # Stencil
    #-------------------------------------------------------
    my $jsImage = JavaScript::D3::CodeSnippets::GetImageDisplayPart();

    #-------------------------------------------------------
    # Concrete parameters
    #-------------------------------------------------------
    my $res = $jsImage.subst(:g, '$IMAGE_PATH', $spec);

    if $width ~~ Int:D {
        $res .= subst(:g, '$WIDTH', $width)
    } else {
        $res .= subst('.attr("width", "$WIDTH")')
    }

    if $height ~~ Int:D {
        $res .= subst(:g, '$HEIGHT', $height)
    } else {
        $res .= subst('.attr("height", "$HEIGHT")')
    }

    #-------------------------------------------------------
    # Wrap-up and return
    #-------------------------------------------------------
    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}


#============================================================
# Image
#============================================================

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

    #-------------------------------------------------------
    # Dimensions of from data
    #-------------------------------------------------------
    my $nRows = @data.elems;
    my $nCols = @data.head.elems;

    #-------------------------------------------------------
    # Process $color-palette
    #-------------------------------------------------------
    die "The argument \$color-palette is expected to be one of '{JavaScript::D3::CodeSnippets::known-sequential-schemes.join("', '")}'."
    unless $color-palette ∈ JavaScript::D3::CodeSnippets::known-sequential-schemes;

    #-------------------------------------------------------
    # Process $low-value
    #-------------------------------------------------------
    if $low-value.isa(Whatever) {
        $low-value = min(JavaScript::D3::Utilities::reallyflat(@data))
    }
    die "The argument \$low-value is expected Whatever or Numeric:D."
    unless $low-value ~~ Numeric:D;

    #-------------------------------------------------------
    # Process $high-value
    #-------------------------------------------------------
    if $high-value.isa(Whatever) {
        $high-value = max(JavaScript::D3::Utilities::reallyflat(@data))
    }
    die "The argument \$max-value is expected Whatever or Numeric:D."
    unless $low-value ~~ Numeric:D;

    #-------------------------------------------------------
    # Process width
    #-------------------------------------------------------
    if $width.isa(Whatever) { $width = $nCols; }
    die "The argument \$width is expected Whatever or a positive integer."
    unless $width ~~ Int:D && $width > 0;

    #-------------------------------------------------------
    # Process height
    #-------------------------------------------------------
    if $height.isa(Whatever) { $height = $nRows; }
    die "The argument \$height is expected Whatever or a positive integer."
    unless $height ~~ Int:D && $height > 0;

    #-------------------------------------------------------
    # Make data to hand over to D3.js
    #-------------------------------------------------------
    my @values = |JavaScript::D3::Utilities::reallyflat(@data);
    my $jsData = to-json({ width => $nCols, height => $nRows, :@values }, :!pretty);

    #-------------------------------------------------------
    # Stencil
    #-------------------------------------------------------
    my $jsImage = JavaScript::D3::CodeSnippets::GetImagePart();

    #-------------------------------------------------------
    # Concrete parameters
    #-------------------------------------------------------
    my $res = $jsImage
            .subst('$DATA', $jsData)
            .subst('$COLOR_PALETTE', $color-palette)
            .subst(:g, '$LOW_VALUE', $low-value)
            .subst(:g, '$HIGH_VALUE', $high-value)
            .subst(:g, '$WIDTH', $width)
            .subst(:g, '$HEIGHT', $height);

    #-------------------------------------------------------
    # Wrap-up and return
    #-------------------------------------------------------
    $res = JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);

    return $res.subst(/ '<head>' \h* \v+ /,
            "<head>\n\t<canvas style=\"width:{ $width }px; height:{ $height }px;\"></canvas>\n");
}
