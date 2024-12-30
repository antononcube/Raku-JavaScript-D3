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
                Str:D :$hour-hand-color = 'Black',
                Str:D :$minute-hand-color = 'Black',
                Str:D :$second-hand-color = 'Red',
                :$tick-labels-color is copy = Whatever,
                Numeric:D :$tick-labels-font-size  = 20,
                Str:D :$tick-labels-font-family is copy = 'Ariel',
                Numeric:D :$update-interval = 1000,
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
