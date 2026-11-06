unit module JavaScript::D3::Render;

# The rendering boundary is intentionally independent from visualization
# modules.  A visualization supplies its JavaScript body; this module owns
# output formats and the target element used by those formats.
class RenderSpec is export {
    has Str $.body is required;
    has Str $.format = 'jupyter';
    has $.div-id = Whatever;
    has Bool $.with-d33d = False;
}

my $jupyter_start = q:to/END/;
(function(element) { require(['d3'], function(d3) {
END

my $jupyter_end = q:to/END/;
}) })(element);
END

my $html_start = q:to/END/;
<!DOCTYPE html>
<head>
    <script src="https://d3js.org/d3.v7.js"></script>
</head>
<body>

<div id="my_dataviz"></div>

<script>
END

my $html_start_3d = q:to/END/;
<!DOCTYPE html>
<head>
    <script src="https://d3js.org/d3.v7.js"></script>
    <script src="https://unpkg.com/d3-3d@2.0.2/build/d3-3d"></script>
</head>
<body>

<div id="my_dataviz"></div>

<script>
END

my $html_end = q:to/END/;
</script>
</body>
</html>
END

our sub target-expression(Str:D :$format = 'jupyter', Str:D :$div-id = 'my-dataviz' --> Str:D) is export {
    $format.lc ∈ <jupyter asis>
        ?? 'element.get(0)'
        !! 'document.getElementById(' ~ $div-id.raku ~ ')';
}

our sub wrap(Str:D $code, Str:D :$format = 'jupyter', :$div-id is copy = Whatever,
             Bool:D :$with-d33d = False --> Str:D) is export {
    if $div-id !~~ Str {
        warn 'The argument div-id is expected to be a string or Whatever' unless $div-id.isa(Whatever);
        $div-id = 'my-dataviz';
    }

    return $code if $format.lc eq 'asis';

    my $start = $format.lc eq 'jupyter'
        ?? $jupyter_start
        !! ($with-d33d ?? $html_start_3d !! $html_start);
    my $end = $format.lc eq 'jupyter' ?? $jupyter_end !! $html_end;
    my $res = [$start, $code, $end].join("\n");

    given $format.lc {
        when 'html' {
            $res = $res
                .subst(:g, '.select(element.get(0))', '.select("#' ~ $div-id ~ '")')
                .subst(:g, / 'element.get(0)' | '"my_dataviz"' /, '"' ~ $div-id ~ '"')
                .subst(:g, '"#my_dataviz"', '"#' ~ $div-id ~ '"');
        }
        when $_ ∈ <html-md html-markdown html-embedded html-fragment> {
            $res = $res
                .subst(:g, / 'element.get(0)' | '"my_dataviz"' /, '"' ~ $div-id ~ '"')
                .subst(:g, '"#my_dataviz"', '"#' ~ $div-id ~ '"')
                .subst(:g, '<body>')
                .subst(:g, '</body>')
                .subst(:g, '<!DOCTYPE html>')
                .subst(:g, '</html>');
        }
    }

    $res;
}

our sub render(RenderSpec:D $spec --> Str:D) is export {
    my $body = $spec.body;
    my $format = $spec.format;
    my $div-id = $spec.div-id;
    my $with-d33d = $spec.with-d33d;
    wrap($body, :$format, :$div-id, :$with-d33d);
}
