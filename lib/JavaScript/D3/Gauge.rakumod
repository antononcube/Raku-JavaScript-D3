unit module JavaScript::D3::Gauge;

use JavaScript::D3::CodeSnippets;
use JavaScript::D3::Predicates;
use JavaScript::D3::Utilities;
use Hash::Merge;
use JSON::Fast;


#============================================================
# Clock
#============================================================

#| Makes a bubble chart for list of triplets..
our proto Clock(|) is export {*}

our multi Clock($hour = Whatever, $minute = Whatever, $second = Whatever, *%args) {
    return Clock(:$hour, :$minute, :$second, |%args);
}

our multi Clock(:$hour is copy = Whatever,
                :$minute is copy = Whatever,
                :$second is copy = Whatever,
                :$width = 200,
                :$height = 200,
                Str :plot-label(:$title) = '',
                UInt :plot-label-font-size(:$title-font-size) = 16,
                Str :plot-label-color(:$title-color) = 'Black',
                Str:D :$background = 'White',
                Str:D :color(:$stroke-color) = 'Black',
                :$hour-hand-color is copy = Whatever,
                :$minute-hand-color is copy = Whatever,
                :$second-hand-color = 'Gray',
                :$tick-labels-color is copy = Whatever,
                :$scale-ranges is copy = Whatever,
                :color-palette(:$color-scheme) is copy = Whatever,
                Numeric:D :$tick-labels-font-size  = 16,
                Str:D :$tick-labels-font-family is copy = 'Ariel',
                Numeric:D :$update-interval = 1000,
                :$color-scheme-interpolation-range = Whatever,
                :$margins is copy = 5,
                Str:D :$format = 'jupyter',
                :$div-id = Whatever,
                *%args
                ) {


    #------------------------------------------------------
    # Process margins
    $margins = JavaScript::D3::Utilities::ProcessMargins($margins);

    #------------------------------------------------------
    # Process ticks color
    if $tick-labels-color.isa(Whatever) { $tick-labels-color = $stroke-color; }
    die 'The value of $tick-labels-color is expected to be a string or Whatever.'
    unless $tick-labels-color ~~ Str:D;

    #------------------------------------------------------
    # Process hour-hand color
    if $hour-hand-color.isa(Whatever) { $hour-hand-color = $stroke-color; }
    die 'The value of $hour-hand-color is expected to be a string or Whatever.'
    unless $hour-hand-color ~~ Str:D;

    #------------------------------------------------------
    # Process minute-hand color
    if $minute-hand-color.isa(Whatever) { $minute-hand-color = $hour-hand-color; }
    die 'The value of $munute-hand-color is expected to be a string or Whatever.'
    unless $minute-hand-color ~~ Str:D;

    #------------------------------------------------------
    # Process second-hand color
    if $second-hand-color.isa(Whatever) { $second-hand-color = $stroke-color; }
    die 'The value of $second-hand-color is expected to be a string or Whatever.'
    unless $second-hand-color ~~ Str:D;

    #------------------------------------------------------
    # Process scale ranges
    if $scale-ranges.isa(Whatever) { $scale-ranges = []; }
    if $scale-ranges ~~ Seq:D { $scale-ranges = $scale-ranges.Array; }
    die 'The value of $scale-ranges is expected to be Whatever or a list of lists.'
    unless $scale-ranges ~~ (Array:D | List:D) && $scale-ranges.all ~~ (Array:D | List:D | Seq:D);

    my $err-message = 'If the value of $scale-ranges a list then each element is expected to be list of two numbers or a list of two lists each with tow numbers.';
    $scale-ranges = do for |$scale-ranges -> @r {
        do given @r {
           when $_.all ~~ Numeric:D { [$_, [0, 0.1]] }
           when $_.all ~~ (List:D | Array:D | Seq:D) && $_.elems ≥ 2 {
               if @r.head.all ~~ Numeric:D && @r.tail.all ~~ Numeric:D { @r }
               else { die $err-message }
           }
           default { die $err-message }
        }
    }

    #------------------------------------------------------
    # Process color-scheme
    if $color-scheme.isa(Whatever) { $color-scheme = 'Reds'; }
    die 'The value of $color-scheme is expected to be a string or Whatever.'
    unless $color-scheme ~~ Str:D;

    #------------------------------------------------------
    # Process color-scheme
    if $color-scheme-interpolation-range.isa(Whatever) { $color-scheme-interpolation-range = [0.2, 0.8]; }
    die 'The value of $color-scheme-interpolation-range is expected to be Whatever or a list of two numbers.'
    unless $color-scheme-interpolation-range ~~ (Array:D | List:D | Seq:D)
            && $color-scheme-interpolation-range.elems ≥ 2
            && $color-scheme-interpolation-range.head(2).all ~~ Numeric:D;

    #======================================================
    # Plot creation
    #======================================================

    #------------------------------------------------------
    # Stencil code
    my $jsChart = [
        JavaScript::D3::CodeSnippets::GetPlotMarginsAndTitle($format),
        JavaScript::D3::CodeSnippets::GetClockGauge()
    ].join("\n");

    #------------------------------------------------------
    # Concrete values
    my $res = $jsChart
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst(:g, '$STROKE_COLOR', '"' ~ $stroke-color ~ '"')
            .subst(:g, '$TICK_LABELS_FONT_SIZE', '"' ~ $tick-labels-font-size ~ 'px"')
            .subst(:g, '$TICK_LABELS_COLOR', '"' ~ $tick-labels-color ~ '"')
            .subst(:g, '$TICK_LABELS_FONT_FAMILY', '"' ~ $tick-labels-font-family ~ '"')
            .subst(:g, '$HOUR_HAND_COLOR', '"' ~ $hour-hand-color ~ '"')
            .subst(:g, '$MINUTE_HAND_COLOR', '"' ~ $minute-hand-color ~ '"')
            .subst(:g, '$SECOND_HAND_COLOR', '"' ~ $second-hand-color ~ '"')
            .subst(:g, '$UPDATE_INTERVAL', $update-interval)
            .subst(:g, '$COLOR_SCHEME_INTERPOLATION_START', $color-scheme-interpolation-range[0])
            .subst(:g, '$COLOR_SCHEME_INTERPOLATION_END', $color-scheme-interpolation-range[1])
            .subst(:g, '$SCALE_RANGES', to-json($scale-ranges, :!pretty))
            .subst(:g, '$COLOR_SCHEME', '"' ~ $color-scheme ~ '"')
            .subst(:g, '$HOUR', $hour ~~ UInt:D ?? $hour !! 'new Date().getHours()')
            .subst(:g, '$MINUTE', $minute ~~ UInt:D ?? $minute !! 'new Date().getMinutes()')
            .subst(:g, '$SECOND', $second ~~ UInt:D ?? $second !! 'new Date().getSeconds()')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE_FONT_SIZE', $title-font-size)
            .subst(:g, '$TITLE_FILL', '"' ~ $title-color ~ '"')
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty);

    #------------------------------------------------------
    # Result
    return JavaScript::D3::CodeSnippets::WrapIt($res, :$format, :$div-id);
}
