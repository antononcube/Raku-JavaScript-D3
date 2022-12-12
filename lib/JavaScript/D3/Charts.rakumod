use v6.d;

use JSON::Fast;

unit module JavaScript::D3::Charts;

#============================================================
# JavaScript chart template parts
#============================================================
my $jsChartPreparation = q:to/END/;
(function(element) { require(['d3'], function(d3) {

// set the dimensions and margins of the graph
var margin = {top: 30, right: 30, bottom: 30, left: 30},
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

// Optain data
var data = $DATA

END

my $jsChartEnding = q:to/END/;
}) })(element);
END

#============================================================
# BarChart
#============================================================
# See https://d3-graph-gallery.com/graph/barplot_basic.html

my $jsBarChartPart = q:to/END/;

var valueMin = Math.min.apply(Math, data.map(function(o) { return o.Value; }))
var valueMax = Math.max.apply(Math, data.map(function(o) { return o.Value; }))

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
                   :$height = 400,
                   Str :$title = '') {
    my $jsData = to-json(@data,:!pretty);

    my &jsChart = [$jsChartPreparation, $jsBarChartPart, $jsChartEnding].join("\n");

    return  &jsChart
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
}

#============================================================
# Histogram
#============================================================
# See https://d3-graph-gallery.com/graph/histogram_basic.html
my $jsHistogramPart = q:to/END/;
 var valueMin = Math.min.apply(Math, data.map(function(o) { return o; }))
 var valueMax = Math.max.apply(Math, data.map(function(o) { return o; }))

 // X axis: scale and draw:
  var x = d3.scaleLinear()
      .domain([valueMin, valueMax])     // can use this instead of 1000 to have the max of data: d3.max(data, function(d) { return +d.Value })
      .range([0, width]);
  svg.append("g")
      .attr("transform", "translate(0," + height + ")")
      .call(d3.axisBottom(x));

  // set the parameters for the histogram
  var histogram = d3.histogram()
      .value(function(d) { return d; })   // I need to give the vector of value
      .domain(x.domain())  // then the domain of the graphic
      .thresholds(x.ticks(70)); // then the numbers of bins

  // And apply this function to data to get the bins
  var bins = histogram(data);

  // Y axis: scale and draw:
  var y = d3.scaleLinear()
      .range([height, 0]);
      y.domain([0, d3.max(bins, function(d) { return d.length; })]);   // d3.hist has to be called before the Y axis obviously
  svg.append("g")
      .call(d3.axisLeft(y));

  // append the bar rectangles to the svg element
  svg.selectAll("rect")
      .data(bins)
      .enter()
      .append("rect")
        .attr("x", 1)
        .attr("transform", function(d) { return "translate(" + x(d.x0) + "," + y(d.length) + ")"; })
        .attr("width", function(d) { return x(d.x1) - x(d.x0) -1 ; })
        .attr("height", function(d) { return height - y(d.length); })
        .style("fill", $FILL_COLOR)
END

#| Makes a histogram for a list of numbers.
our proto Histogram($data, |) is export {*}

our multi Histogram(@data where @data.all ~~ Numeric,
                   Str :$background='white',
                   Str :$color='steelblue',
                   :$width = 600,
                   :$height = 400,
                    Str :$title = '') {
    my $jsData = to-json(@data,:!pretty);

    my $jsChart = [$jsChartPreparation, $jsHistogramPart, $jsChartEnding].join("\n");

    return  $jsChart
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$WIDTH', $width.Str)
            .subst(:g, '$HEIGHT', $height.Str)
            .subst(:g, '$TITLE', '"' ~ $title ~ '"')
}