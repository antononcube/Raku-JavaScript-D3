use v6.d;

use JSON::Fast;

unit module JavaScript::D3::Charts;

#============================================================
# JavaScript chart template parts
#============================================================

our $jsChartPreparation = q:to/END/;
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

var valueMin = Math.min.apply(Math, data.map(function(o) { return o.Value; }))
var valueMax = Math.max.apply(Math, data.map(function(o) { return o.Value; }))

END

my $jsChartEnding = q:to/END/;
}) })(element);
END

#============================================================
# BarChart
#============================================================
our $jsBarChartPart = q:to/END/;
// X axis
var x = d3.scaleBand()
  .range([ 0, width ])
  .domain(data.map(function(d) { return d.Label; }))
  .padding(0.2);
svg.append("g")
  .attr("transform", "translate(0," + height + ")")
  .call(d3.axisBottom(x))
  .selectAll("text")
    .attr("transform", "translate(-10,0)rotate(-45)")
    .style("text-anchor", "end");

// Add Y axis
var y = d3.scaleLinear()
  .domain([0, valueMax])
  .range([ height, 0]);
svg.append("g")
  .call(d3.axisLeft(y));

// Bars
svg.selectAll("mybar")
  .data(data)
  .enter()
  .append("rect")
    .attr("x", function(d) { return x(d.Label); })
    .attr("y", function(d) { return y(d.Value); })
    .attr("width", x.bandwidth())
    .attr("height", function(d) { return height - y(d.Value); })
    .attr("fill", $FILL_COLOR)
END

#| Makes a bar chart for a list of numbers or a hash with numeric values.
our proto BarChart($data, |) is export {*}

our multi BarChart($data where $data ~~ Positional && $data.all ~~ Numeric, *%args) {
    my $k = 1;
    my @dataPairs = |$data.map({ <Label Value> Z=> ($k++, $_ ) })>>.Hash;
    return BarChart(@dataPairs, |%args);
}

our multi BarChart(%data, *%args) {
    my @dataPairs = %data.map({ %(Label => $_.key, Value => $_.value ) }).Array;
    return BarChart(@dataPairs, |%args);
}

our multi BarChart(@data where @data.all ~~ Map,
                   Str :$background='white',
                   Str :$color='steelblue',
                   :$width = 600,
                   :$height = 400) {
    my $jsData = to-json(@data,:!pretty);

    my $jsScatterPlot = [$jsChartPreparation, $jsBarChartPart, $jsChartEnding].join("\n");

    return  $jsScatterPlot
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
}