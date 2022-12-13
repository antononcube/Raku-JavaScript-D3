use v6.d;

use JSON::Fast;
use Hash::Merge;

unit module JavaScript::D3::Plots;

#============================================================
# JavaScript plot template parts
#============================================================
my $jsPlotPreparation = q:to/END/;
(function(element) { require(['d3'], function(d3) {

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
    .attr("r", 7)
    .style("fill", function(d){ return myColor(d)})

// Add one dot in the legend for each name.
svg.selectAll("mylabels")
  .data(keys)
  .enter()
  .append("text")
    .attr("x", $LEGEND_X_POS + 20)
    .attr("y", function(d,i){ return $LEGEND_Y_POS + i*$LEGEND_Y_GAP}) // 100 is where the first dot appears. 25 is the distance between dots
    .style("fill", function(d){ return myColor(d)})
    .text(function(d){ return d})
    .attr("text-anchor", "left")
    .style("alignment-baseline", "middle")
END

my $jsPlotEnding = q:to/END/;
}) })(element);
END

our sub GetPlotPreparationCode() {
    return $jsPlotPreparation;
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
                   :$margins is copy = Whatever
                   ) {
    my $jsData = to-json(@data, :!pretty);

    my $jsScatterPlot = [$jsPlotPreparation, $jsScatterPlotPart, $jsPlotEnding].join("\n");

    $margins = ProcessMargins($margins);

    return  $jsScatterPlot
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$POINT_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
            .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty)
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
                       :$margins is copy = Whatever
                       ) {

    $margins = ProcessMargins($margins);

    # Groups
    my Bool $hasGroups = [&&] @data.map({ so $_<group> });

    # Select code fragment to splice in
    my $jsPlotMiddle = $jsPathPlotPart;
    if $hasGroups {
        $jsPlotMiddle = $jsMultiPathPlotPart ~ "\n" ~ $jsGroupsLegend;
        $margins<right> = $margins<right> + 100;
    }

    my $jsData = to-json(@data, :!pretty);

    my $jsLinePlot = [$jsPlotPreparation, $jsPlotMiddle, $jsPlotEnding].join("\n");

    return  $jsLinePlot
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$LINE_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
            .subst(:g, '$X_AXIS_LABEL', '"' ~ $x-axis-label ~ '"')
            .subst(:g, '$Y_AXIS_LABEL', '"' ~ $y-axis-label ~ '"')
            .subst(:g, '$MARGINS', to-json($margins):!pretty)
            .subst(:g, '$LEGEND_X_POS', ($width - $margins<right>).Str)
            .subst(:g, '$LEGEND_Y_POS', '0')
            .subst(:g, '$LEGEND_Y_GAP', '25')
}