use v6.d;

use JSON::Fast;
use Hash::Merge;

unit module JavaScript::D3::Plots;

#============================================================
# JavaScript plot template parts
#============================================================
my $jsPlotStartingHTML = q:to/END/;
<!DOCTYPE html>
<head>
    <script src="https://d3js.org/d3.v7.js"></script>
</head>
<body>

<div id="my_dataviz"></div>

<script>
END

my $jsPlotStarting = q:to/END/;
(function(element) { require(['d3'], function(d3) {
END

my $jsPlotMarginsAndLabels = q:to/END/;
// set the dimensions and margins of the graph
var margin = $MARGINS,
    width = $WIDTH - margin.left - margin.right,
    height = $HEIGHT - margin.top - margin.bottom;

// append the svg object to the body of the page
var svg = d3
   .select(element.get(0))
  .append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .style("background", $BACKGROUND_COLOR)
  .append("g")
    .attr("transform",
          "translate(" + margin.left + "," + margin.top + ")")

// Obtain title
var title = $TITLE

if ( title.length > 0 ) {
    svg.append("text")
        .attr("x", (width / 2))
        .attr("y", 0 - (margin.top / 2))
        .attr("text-anchor", "middle")
        .style("font-size", "16px")
        //.style("text-decoration", "underline")
        .text(title);
}

// Obtain x-axis label
var xAxisLabel = $X_AXIS_LABEL
var xAxisLabelFontSize = 12

if ( xAxisLabel.length > 0 ) {
    svg.append("text")
        .attr("x", (width / 2))
        .attr("y", height + margin.bottom - xAxisLabelFontSize/2)
        .attr("text-anchor", "middle")
        .style("font-size", xAxisLabelFontSize.toString() + "px")
        .text(xAxisLabel);
}

// Obtain y-axis label
var yAxisLabel = $Y_AXIS_LABEL
var yAxisLabelFontSize = 12

if ( yAxisLabel.length > 0 ) {
    svg.append("text")
        .attr("transform", "rotate(-90)")
        .attr("x", - (height / 2))
        .attr("y", 0 - margin.left + yAxisLabelFontSize)
        .attr("text-anchor", "middle")
        .style("font-size", yAxisLabelFontSize.toString() + "px")
        .text(yAxisLabel);
}
END

my $jsPlotDataAndScales = q:to/END/;
// Optain data
var data = $DATA

var xMin = Math.min.apply(Math, data.map(function(o) { return o.x; }))
var xMax = Math.max.apply(Math, data.map(function(o) { return o.x; }))

var yMin = Math.min.apply(Math, data.map(function(o) { return o.y; }))
var yMax = Math.max.apply(Math, data.map(function(o) { return o.y; }))

// X scale and Axis
var x = d3.scaleLinear()
    .domain([xMin, xMax])         // This is the min and the max of the data: 0 to 100 if percentages
    .range([0, width]);           // This is the corresponding value I want in Pixel

svg
  .append('g')
  .attr("transform", "translate(0," + height + ")")
  .call(d3.axisBottom(x))

// X scale and Axis
var y = d3.scaleLinear()
    .domain([yMin, yMax])         // This is the min and the max of the data: 0 to 100 if percentages
    .range([height, 0]);          // This is the corresponding value I want in Pixel

svg
  .append('g')
  .call(d3.axisLeft(y));
END

my $jsPlotPreparation = $jsPlotStarting ~ "\n" ~ $jsPlotMarginsAndLabels ~ "\n" ~ $jsPlotDataAndScales;

# See https://d3-graph-gallery.com/graph/custom_legend.html
my $jsGroupsLegend = q:to/END/;
// create a list of keys
var keys = data.map(function(o) { return o.group; })
keys = [...new Set(keys)];

// Add one dot in the legend for each name.
svg.selectAll("mydots")
  .data(keys)
  .enter()
  .append("circle")
    .attr("cx", $LEGEND_X_POS)
    .attr("cy", function(d,i){ return $LEGEND_Y_POS + i*$LEGEND_Y_GAP}) // 100 is where the first dot appears. 25 is the distance between dots
    .attr("r", 6)
    .style("fill", function(d){ return myColor(d)})

// Add one dot in the legend for each name.
svg.selectAll("mylabels")
  .data(keys)
  .enter()
  .append("text")
    .attr("x", $LEGEND_X_POS + 12)
    .attr("y", function(d,i){ return $LEGEND_Y_POS + i*$LEGEND_Y_GAP}) // 100 is where the first dot appears. 25 is the distance between dots
    .style("fill", function(d){ return myColor(d)})
    .text(function(d){ return d})
    .attr("text-anchor", "left")
    .style("alignment-baseline", "middle")
    .style("font-size", "12px")
    .attr("font-family", "Courier")
END

my $jsPlotEndingHTML = q:to/END/;
</script>
</body>
</html>
END

my $jsPlotEnding = q:to/END/;
}) })(element);
END

#============================================================
# JavaScript code accessors
#============================================================

our sub GetPlotStartingCode(Str $format = 'jupyter') {
    return $format.lc eq 'jupyter' ?? $jsPlotStarting !! $jsPlotStartingHTML;
}

our sub GetPlotEndingCode(Str $format = 'jupyter') {
    return $format.lc eq 'jupyter' ?? $jsPlotEnding !! $jsPlotEndingHTML;
}

our sub GetPlotMarginsAndLabelsCode(Str $format = 'jupyter') {
    return
            $format.lc eq 'jupyter' ??
            $jsPlotMarginsAndLabels !! $jsPlotMarginsAndLabels.subst(:g, 'element.get(0)', '"#my_dataviz"');
}

our sub GetPlotPreparationCode(Str $format = 'jupyter') {
    return GetPlotStartingCode($format) ~ "\n" ~ GetPlotMarginsAndLabelsCode($format) ~ "\n" ~ $jsPlotDataAndScales;
}

our sub GetLegendCode() {
    return $jsGroupsLegend;
}


#============================================================
# Process margins
#============================================================

our sub ProcessMargins($margins is copy) {
    my %defaultMargins = %( top => 40, bottom => 40, left => 40, right => 40);
    if $margins.isa(Whatever) {
        $margins = %defaultMargins
    }
    die "The argument margins is expected to be a Map or Whatever." unless $margins ~~ Map;
    $margins = merge-hash(%defaultMargins, $margins);
    return $margins;
}

#============================================================
# ListPlot
#============================================================

my $jsScatterPlotPart = q:to/END/;
// Add dots
svg
  .selectAll("whatever")
  .data(data)
  .enter()
  .append("circle")
    .attr("cx", function(d){ return x(d.x) })
    .attr("cy", function(d){ return y(d.y) })
    .attr("r", 3)
    .attr("color", "blue")
    .attr("fill", $POINT_COLOR)
END

our proto ListPlot($data, |) is export {*}

our multi ListPlot($data where $data ~~ Positional && $data.all ~~ Numeric, *%args) {
    my $k = 1;
    my @dataPairs = |$data.map({ <x y> Z=> ($k++, $_) })>>.Hash;
    return ListPlot(@dataPairs, |%args);
}

our multi ListPlot(@data where @data.all ~~ Map,
                   Str :$background= 'white',
                   Str :$color= 'steelblue',
                   :$width = 600,
                   :$height = 400,
                   Str :plot-label(:$title) = '',
                   Str :$x-axis-label = '',
                   Str :$y-axis-label = '',
                   :$margins is copy = Whatever,
                   Str :$format = 'jupyter'
                   ) {
    my $jsData = to-json(@data, :!pretty);

    my $jsScatterPlot = [GetPlotPreparationCode($format), $jsScatterPlotPart, GetPlotEndingCode($format)].join("\n");

    $margins = ProcessMargins($margins);

    my $res =
            $jsScatterPlot
                    .subst('$DATA', $jsData)
                    .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
                    .subst('$POINT_COLOR', '"' ~ $color ~ '"')
                    .subst(:g, '$WIDTH', $width.Str)
                    .subst(:g, '$HEIGHT', $height.Str)
                    .subst(:g, '$TITLE', '"' ~ $title ~ '"')
                    .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
                    .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty);

    if $format.lc eq 'html' {
        $res = $res.subst('element.get(0)', '"#my_dataviz"'):g;
    }

    return $res;
}

#============================================================
# ListLinePlot
#============================================================
my $jsPathPlotPart = q:to/END/;
// prepare a helper function
var lineFunc = d3.line()
  .x(function(d) { return x(d.x) })
  .y(function(d) { return y(d.y) })

// Add the path using this helper function
svg.append('path')
  .attr('d', lineFunc(data))
  .attr('stroke', $LINE_COLOR)
  .attr('fill', 'none');
END

# See https://d3-graph-gallery.com/graph/line_several_group.html
my $jsMultiPathPlotPart = q:to/END/;
// group the data: I want to draw one line per group
const sumstat = d3.group(data, d => d.group); // nest function allows to group the calculation per level of a factor

// Add a scale for line color
var myColor = d3.scaleOrdinal()
    .domain(data.map(function(o) { return o.group; }))
    .range(d3.schemeSet2);

// Draw the line
svg.selectAll(".line")
      .data(sumstat)
      .join("path")
        .attr("fill", "none")
        .attr("stroke", function(d){ return myColor(d[0]) })
        .attr("stroke-width", 1.5)
        .attr("d", function(d){
          return d3.line()
            .x(function(d) { return x(d.x); })
            .y(function(d) { return y(+d.y); })
            (d[1])
        })

END

our proto ListLinePlot($data, |) is export {*}

our multi ListLinePlot($data where $data ~~ Positional && $data.all ~~ Numeric, *%args) {
    my $k = 1;
    my @dataPairs = |$data.map({ <x y> Z=> ($k++, $_) })>>.Hash;
    return ListLinePlot(@dataPairs, |%args);
}

our multi ListLinePlot(@data where @data.all ~~ Map,
                       Str :$background= 'white',
                       Str :$color= 'steelblue',
                       :$width = 600,
                       :$height = 400,
                       Str :plot-label(:$title) = '',
                       Str :$x-axis-label = '',
                       Str :$y-axis-label = '',
                       :$margins is copy = Whatever,
                       :$legends = Whatever,
                       Str :$format = 'jupyter'
                       ) {

    $margins = ProcessMargins($margins);

    # Groups
    my Bool $hasGroups = [&&] @data.map({ so $_<group> });

    # Select code fragment to splice in
    my $jsPlotMiddle = $hasGroups ?? $jsMultiPathPlotPart !! $jsPathPlotPart;

    # Chose to add legend code fragment or not
    my $maxGroupChars = $hasGroups ?? @data.map(*<group>).unique>>.chars.max !! 'all'.chars;
    given $legends {
        when $_ ~~ Bool && $_ || $_.isa(Whatever) && $hasGroups {
            $margins<right> = max($margins<right>, ($maxGroupChars + 4) * 12);
            $jsPlotMiddle ~=  "\n" ~ $jsGroupsLegend;
        }
    }

    my $jsData = to-json(@data, :!pretty);

    my $jsLinePlot = [GetPlotPreparationCode($format), $jsPlotMiddle, GetPlotEndingCode($format)].join("\n");

    my $res =
            $jsLinePlot
                    .subst('$DATA', $jsData)
                    .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
                    .subst('$LINE_COLOR', '"' ~ $color ~ '"')
                    .subst(:g, '$WIDTH', $width.Str)
                    .subst(:g, '$HEIGHT', $height.Str)
                    .subst(:g, '$TITLE', '"' ~ $title ~ '"')
                    .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
                    .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
                    .subst(:g, '$MARGINS', to-json($margins):!pretty)
                    .subst(:g, '$LEGEND_X_POS', 'width + 3*12')
                    .subst(:g, '$LEGEND_Y_POS', '0')
            .subst(:g, '$LEGEND_Y_GAP', '25');

    if $format.lc eq 'html' {
        $res = $res.subst('element.get(0)', '"#my_dataviz"');
    }

    return $res;
}


#============================================================
# DateListPlot
#============================================================
# See https://d3-graph-gallery.com/graph/line_basic.html
my $jsPlotDateDataAndScales = q:to/END/;
// Optain data
var data = $DATA

data = data.map(function(d){
  var d2 = d;
  d2["x"] = d3.timeParse("%Y-%m-%d")(d.date);
  if ( "value" in d ) { d2["y"] = d.value; }
  return d2
})

var yMin = Math.min.apply(Math, data.map(function(o) { return o.y; }))
var yMax = Math.max.apply(Math, data.map(function(o) { return o.y; }))

// Add X axis --> it is a date format
var x = d3.scaleTime()
      .domain(d3.extent(data, function(d) { return d.x; }))
      .range([ 0, width ]);

svg
  .append('g')
  .attr("transform", "translate(0," + height + ")")
  .call(d3.axisBottom(x))

// Y scale and Axis
var y = d3.scaleLinear()
    .domain([yMin, yMax])
    .range([height, 0]);

svg
  .append('g')
  .call(d3.axisLeft(y));
END

END

our proto DateListPlot($data, |) is export {*}

our multi DateListPlot($data where $data ~~ Positional && $data.all ~~ Numeric, *%args) {
    my $k = 1;
    my @dataPairs = |$data.map({ <date value> Z=> (DateTime.new($k++), $_) })>>.Hash;
    return DateListPlot(@dataPairs, |%args);
}

our multi DateListPlot(@data where @data.all ~~ Map,
                       Str :$background= 'white',
                       Str :$color= 'steelblue',
                       :$width = 600,
                       :$height = 400,
                       Str :plot-label(:$title) = '',
                       Str :date-axis-label(:$x-axis-label) = '',
                       Str :value-axis-label(:$y-axis-label) = '',
                       Str :$time-parse-spec = '%Y-%m-%d',
                       :$margins is copy = Whatever,
                       :$legends = Whatever,
                       Str :$format = 'jupyter'
                       ) {

    $margins = ProcessMargins($margins);

    # Groups
    my Bool $hasGroups = [&&] @data.map({ so $_<group> });

    # Select code fragment to splice in
    my $jsPlotMiddle = $hasGroups ?? $jsMultiPathPlotPart !! $jsPathPlotPart;

    # Chose to add legend code fragment or not
    my $maxGroupChars = $hasGroups ?? @data.map(*<group>).unique>>.chars.max !! 'all'.chars;
    given $legends {
        when $_ ~~ Bool && $_ || $_.isa(Whatever) && $hasGroups {
            $margins<right> = max($margins<right>, ($maxGroupChars + 4) * 12);
            $jsPlotMiddle ~=  "\n" ~ $jsGroupsLegend;
        }
    }

    my $jsData = to-json(@data, :!pretty);

    my $jsLinePlot = [$jsPlotStarting, $jsPlotMarginsAndLabels, $jsPlotDateDataAndScales, $jsPlotMiddle, $jsPlotEnding]
            .join("\n");

    return  $jsLinePlot
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$LINE_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
            .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
            .subst(:g, '$TIME_PARSE_SPEC', '"' ~ $time-parse-spec ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty)
            .subst(:g, '$LEGEND_X_POS', 'width + 3*12')
            .subst(:g, '$LEGEND_Y_POS', '0')
            .subst(:g, '$LEGEND_Y_GAP', '25')
}