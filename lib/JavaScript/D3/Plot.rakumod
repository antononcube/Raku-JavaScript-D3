use v6.d;

use JSON::Fast;

unit module JavaScript::D3::Plot;

#============================================================
# JavaScript plot template parts
#============================================================

my $jsPlotPreparation = q:to/END/;
(function(element) { require(['d3'], function(d3) {

// set the dimensions and margins of the graph
var margin = {top: 10, right: 40, bottom: 30, left: 30},
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

my $jsPlotEnding = q:to/END/;
}) })(element);
END

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
    my @dataPairs = |$data.map({ <x y> Z=> ($k++, $_ ) })>>.Hash;
    return ListPlot(@dataPairs, |%args);
}

our multi ListPlot(@data where @data.all ~~ Map,
                   Str :$background='white',
                   Str :$color='steelblue',
                   :$width = 600,
                   :$height = 400) {
    my $jsData = to-json(@data,:!pretty);

    my $jsScatterPlot = [$jsPlotPreparation, $jsScatterPlotPart, $jsPlotEnding].join("\n");

    return  $jsScatterPlot
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$POINT_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
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


our proto ListLinePlot($data, |) is export {*}

our multi ListLinePlot($data where $data ~~ Positional && $data.all ~~ Numeric, *%args) {
    my $k = 1;
    my @dataPairs = |$data.map({ <x y> Z=> ($k++, $_ ) })>>.Hash;
    return ListLinePlot(@dataPairs, |%args);
}

our multi ListLinePlot(@data where @data.all ~~ Map,
                   Str :$background='white',
                   Str :$color='steelblue',
                   :$width = 600,
                   :$height = 400) {
    my $jsData = to-json(@data,:!pretty);

    my $jsScatterPlot = [$jsPlotPreparation, $jsPathPlotPart, $jsPlotEnding].join("\n");

    return  $jsScatterPlot
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$LINE_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
}