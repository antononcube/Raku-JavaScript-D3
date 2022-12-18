use v6.d;

use Hash::Merge;

unit module JavaScript::D3::CodeSnippets;

#============================================================
# Process margins
#============================================================

our sub ProcessMargins($margins is copy) {
    my %defaultMargins = %( top => 40, bottom => 40, left => 40, right => 40);
    if $margins.isa(Whatever) {
        $margins = %defaultMargins;
    }
    die "The argument margins is expected to be a Map or Whatever." unless $margins ~~ Map;
    $margins = merge-hash(%defaultMargins, $margins);
    return $margins;
}

#============================================================
# Process grid lines
#============================================================

our sub ProcessGridLines($gridLines is copy) {
    my @defaultGridLines = (5, 5);
    $gridLines = do given $gridLines {
        when $_ ~~ Bool && !$_ { (0, 0) }
        when $_ ~~ Bool && $_ { @defaultGridLines }
        when $_.isa(Whatever) { @defaultGridLines; }
        when $_ ~~ List && $_.elems == 1 { ($_[0], @defaultGridLines[1]) }
        when $_ ~~ List && $_.elems == 2 { $_ }
        when $_ ~~ Numeric && $_.round ≥ 0 { ($_.round, $_.round) }
    }

    $gridLines = $gridLines.map({ $_.isa(Whatever) ?? 0 !! $_ }).List;

    die "The argument grid-lines is expected to be a non-negative integer, Whatever, or a two element list of those type of values."
    unless $gridLines ~~ List && $gridLines.elems == 2 && $gridLines.all ~~ UInt;

    return $gridLines;
}

#============================================================
# JavaScript plot and chart template parts
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
// Obtain data
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
# JavaScript plot and chart snippets accessors
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

our sub GetPlotDataAndScalesCode(UInt $nXTicks = 0, UInt $nYTicks = 0, Str $codeFragment = $jsPlotDataAndScales) {
    my $res = $codeFragment;
    if $nXTicks > 0 {
        $res = $res.subst('.call(d3.axisBottom(x))', ".call(d3.axisBottom(x).ticks($nXTicks).tickSizeInner(-height))");
    }
    if $nYTicks > 0 {
        $res = $res.subst('.call(d3.axisLeft(y))', ".call(d3.axisLeft(y).ticks($nYTicks).tickSizeInner(-width))");
    }
    return $res;
}

our sub GetPlotPreparationCode(Str $format = 'jupyter', UInt $nXTicks = 0, UInt $nYTicks = 0) {
    return GetPlotStartingCode($format) ~ "\n" ~ GetPlotMarginsAndLabelsCode($format) ~ "\n" ~ GetPlotDataAndScalesCode($nXTicks, $nYTicks);
}

our sub GetLegendCode() {
    return $jsGroupsLegend;
}


#============================================================
# ListPlot code snippets
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

my $jsMultiScatterPlotPart = q:to/END/;
// Add a scale for dot color
var myColor = d3.scaleOrdinal()
    .domain(data.map(function(o) { return o.group; }))
    .range(d3.schemeSet2);

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
    .attr("fill", function (d) { return myColor(d.group) } )
END

#============================================================
# ListPlot code snippets accessors
#============================================================
our sub GetScatterPlotPart() {
    return $jsScatterPlotPart;
}

our sub GetMultiScatterPlotPart() {
    return $jsMultiScatterPlotPart;
}

#============================================================
# ListLinePlot code snippets
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

#============================================================
# ListLinePlot code snippets accessors
#============================================================

our sub GetPathPlotPart() {
    return $jsPathPlotPart;
}

our sub GetMultiPathPlotPart() {
    return $jsMultiPathPlotPart;
}

#============================================================
# DateListPlot code snippets
#============================================================

# See https://d3-graph-gallery.com/graph/line_basic.html
my $jsPlotDateDataAndScales = q:to/END/;
// Obtain data
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

#============================================================
# DateListPlot code snippets accessors
#============================================================

our sub GetPlotDateDataAndScales() {
    return $jsPlotDateDataAndScales;
}


#============================================================
# BarChart code snippets
#============================================================
# See https://d3-graph-gallery.com/graph/barplot_basic.html

my $jsBarChartPart = q:to/END/;
// Obtain data
var data = $DATA

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

#============================================================
# BarChart code snippets accessors
#============================================================

our sub GetBarChartPart() {
    return $jsBarChartPart;
}

#============================================================
# Histogram code snippets
#============================================================
# See https://d3-graph-gallery.com/graph/histogram_basic.html
my $jsHistogramPart = q:to/END/;
// Obtain data
var data = $DATA

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

#============================================================
# Histogram code snippets accessors
#============================================================

our sub GetHistogramPart() {
    return $jsHistogramPart;
}

#============================================================
# BubbleChart code snippets
#============================================================

# See https://d3-graph-gallery.com/graph/bubble_basic.html
my $jsBubbleChartPart = q:to/END/;
var zMin = Math.min.apply(Math, data.map(function(o) { return o.z; }))
var zMax = Math.max.apply(Math, data.map(function(o) { return o.z; }))

// Add a scale for bubble size
const z = d3.scaleLinear()
    .domain([zMin, zMax])
    .range([1, 40]);

// Add dots
svg.append('g')
    .selectAll("dot")
    .data(data)
    .join("circle")
      .attr("cx", d => x(d.x))
      .attr("cy", d => y(d.y))
      .attr("r",  d => z(d.z))
      .style("fill", $FILL_COLOR)
      .style("opacity", "0.7")
      .attr("stroke", "black")
END

# See https://d3-graph-gallery.com/graph/bubble_color.html
my $jsMultiBubbleChartPart = q:to/END/;
var zMin = Math.min.apply(Math, data.map(function(o) { return o.z; }))
var zMax = Math.max.apply(Math, data.map(function(o) { return o.z; }))

// Add a scale for bubble size
const z = d3.scaleLinear()
    .domain([zMin, zMax])
    .range([1, 40]);

// Add a scale for bubble color
var myColor = d3.scaleOrdinal()
    .domain(data.map(function(o) { return o.group; }))
    .range(d3.schemeSet2);

// Add dots
svg.append('g')
    .selectAll("dot")
    .data(data)
    .join("circle")
      .attr("cx", d => x(d.x))
      .attr("cy", d => y(d.y))
      .attr("r",  d => z(d.z))
      .style("fill", function (d) { return myColor(d.group); } )
      .style("opacity", $OPACITY)
      .attr("stroke", "black")
END

# See https://d3-graph-gallery.com/graph/bubble_tooltip.html
my $jsTooltipMultiBubbleChartPart = q:to/END/;
var zMin = Math.min.apply(Math, data.map(function(o) { return o.z; }))
var zMax = Math.max.apply(Math, data.map(function(o) { return o.z; }))

// Add a scale for bubble size
const z = d3.scaleLinear()
    .domain([zMin, zMax])
    .range([1, 40]);

// Add a scale for bubble color
var myColor = d3.scaleOrdinal()
    .domain(data.map(function(o) { return o.group; }))
    .range(d3.schemeSet2);

// -1- Create a tooltip div that is hidden by default:
const tooltip = d3.select(element.get(0))
    .append("div")
      .style("opacity", 0)
      .attr("class", "tooltip")
      .style("background-color", "black")
      .style("border-radius", "5px")
      .style("padding", "10px")
      .style("color", "white")

// -2- Create 3 functions to show / update (when mouse move but stay on same circle) / hide the tooltip
const showTooltip = function(event, d) {
    tooltip
      .transition()
      .duration(200)
    tooltip
      .style("opacity", 1)
      .html("Group: " + d.group + '<br/>value: ' + d.z.toString() + '<br/>x: ' + d.x.toString() + '<br/>y: ' + d.y.toString())
      .style("left", (event.x)/2 + "px")
      .style("top", (event.y)/2+10 + "px")
  }
  const moveTooltip = function(event, d) {
    tooltip
      .style("left", (event.x)/2 + "px")
      .style("top", (event.y)/2+10 + "px")
  }
  const hideTooltip = function(event, d) {
    tooltip
      .transition()
      .duration(200)
      .style("opacity", 0)
  }

// Add dots
  svg.append('g')
    .selectAll("dot")
    .data(data)
    .join("circle")
      .attr("class", "bubbles")
      .attr("cx", d => x(d.x))
      .attr("cy", d => y(d.y))
      .attr("r",  d => z(d.z))
      .style("fill", d => myColor(d.group))
      .style("opacity", $OPACITY)
    // -3- Trigger the functions
    .on("mouseover", showTooltip )
    .on("mousemove", moveTooltip )
    .on("mouseleave", hideTooltip )
END

#============================================================
# BubbleChart code snippets accessors
#============================================================

our sub GetBubbleChartPart() {
    return $jsBubbleChartPart;
}

our sub GetMultiBubbleChartPart() {
    return $jsMultiBubbleChartPart;
}

our sub GetTooltipMultiBubbleChartPart() {
    return $jsTooltipMultiBubbleChartPart;
}

#============================================================
# Bind2D code snippets
#============================================================

# See https://d3-graph-gallery.com/graph/density2d_hexbin.html
my $jsHexbinChartPart = q:to/END/;
  // Reformat the data: d3.hexbin() needs a specific format
  const inputForHexbinFun = []
  data.forEach(function(d) {
    inputForHexbinFun.push( [x(d.x), y(d.y)] )  // Note that we had the transform value of X and Y !
  })

  // Prepare a color palette
  const color = d3.scaleLinear()
      .domain([0, 500]) // Number of points in the bin?
      .range(["transparent",  "#69b3a2"])

  // Compute the hexbin data
  const hexbin = d3.hexbin()
    .radius(9) // size of the bin in px
    .extent([ [0, 0], [width, height] ])

  // Plot the hexbins
  svg.append("clipPath")
      .attr("id", "clip")
    .append("rect")
      .attr("width", width)
      .attr("height", height)

  svg.append("g")
    .attr("clip-path", "url(#clip)")
    .selectAll("path")
    .data( hexbin(inputForHexbinFun) )
    .join("path")
      .attr("d", hexbin.hexagon())
      .attr("transform", function(d) { return `translate(${d.x}, ${d.y})`})
      .attr("fill", function(d) { return color(d.length); })
      .attr("stroke", "black")
      .attr("stroke-width", "0.1")

END

my $jsRectbinChartPart = q:to/END/;
  // Reformat the data: d3.rectbin() needs a specific format
  var inputForRectBinning = []
  data.forEach(function(d) {
    inputForRectBinning.push( [+d.x, +d.y] )  // Note that we had the transform value of X and Y !
  })

  // Compute the rectbin
  var size = 0.5
  var rectbinData = d3.rectbin()
    .dx(size)
    .dy(size)
    (inputForRectBinning)

  // Prepare a color palette
  var color = d3.scaleLinear()
      .domain([0, 350]) // Number of points in the bin?
      .range(["transparent",  "#69a3b2"])

  // What is the height of a square in px?
  heightInPx = y( yLim[1]-size )

  // What is the width of a square in px?
  var widthInPx = x(xLim[0]+size)

  // Now we can add the squares
  svg.append("clipPath")
      .attr("id", "clip")
    .append("rect")
      .attr("width", width)
      .attr("height", height)
  svg.append("g")
      .attr("clip-path", "url(#clip)")
    .selectAll("myRect")
    .data(rectbinData)
    .enter().append("rect")
      .attr("x", function(d) { return x(d.x) })
      .attr("y", function(d) { return y(d.y) - heightInPx })
      .attr("width", widthInPx )
      .attr("height", heightInPx )
      .attr("fill", function(d) { return color(d.length); })
      .attr("stroke", "black")
      .attr("stroke-width", "0.4")
END

#============================================================
# Bind2D code snippets accessors
#============================================================

our sub GetHexbinChartPart() {
    return $jsHexbinChartPart;
}

our sub GetRectbinChartPart() {
    return $jsRectbinChartPart;
}
