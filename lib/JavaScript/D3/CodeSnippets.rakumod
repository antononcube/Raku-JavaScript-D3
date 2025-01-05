unit module JavaScript::D3::CodeSnippets;

use JavaScript::D3::Utilities;

#============================================================
# Wrapping
#============================================================
# The core JavaScript code is wrapped with HTML or Jupyter cell pre- and post code.

our sub WrapIt(Str $code, Str :$format='jupyter', :$div-id is copy = Whatever) {

    if $div-id !~~ Str {
        warn 'The argument div-id is expected to be a string or Whatever' unless $div-id.isa(Whatever);
        $div-id = 'my-dataviz'
    }

    if $format eq 'asis' {
        return $code
    }

    my $res =
            [JavaScript::D3::CodeSnippets::GetPlotStartingCode($format),
             $code,
             JavaScript::D3::CodeSnippets::GetPlotEndingCode($format)].join("\n");


    $res = do given $format.lc {

        when $_ eq 'html' {
            $res
                    .subst(:g, '.select(element.get(0))', '.select("#' ~ $div-id ~ '")')
                    .subst(:g, / 'element.get(0)' | '"my_dataviz"' /, '"' ~ $div-id ~ '"')
                    .subst(:g, '"#my_dataviz"', '"#' ~ $div-id ~ '"');
        }

        when $_ ∈ <html-md html-markdown html-embedded html-fragment> {
            $res
                    .subst(:g, / 'element.get(0)' | '"my_dataviz"' /, '"' ~ $div-id ~ '"')
                    .subst(:g, '"#my_dataviz"', '"#' ~ $div-id ~ '"')
                    .subst(:g, '<body>')
                    .subst(:g, '</body>')
                    .subst(:g, '<!DOCTYPE html>')
                    .subst(:g, '</html>');
        }

        default { $res }
    }

    return $res;
}

#============================================================
# D3.js color palettes
#============================================================

# See : https://d3js.org/d3-scale-chromatic/sequential
my @knownSequentialSchemes =
        <Blues BuGn BuPu Cividis Cool CubehelixDefault GnBu Greens Greys Inferno Magma
Oranges OrRd Plasma PuBu PuBuGn PuRd Purples RdPu Reds Turbo Viridis Warm
YlGn YlGnBu YlOrBr YlOrRd>;

our sub known-sequential-schemes() { return @knownSequentialSchemes; }

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

my $jsPlotMarginsAndTitle = q:to/END/;
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
var titleFontSize = $TITLE_FONT_SIZE

if ( title.length > 0 ) {
    svg.append("text")
        .attr("x", (width / 2))
        .attr("y", 0 - (margin.top / 2))
        .attr("text-anchor", "middle")
        .style("font-size", titleFontSize.toString() + "px")
        .style("fill", $TITLE_FILL)
        .text(title);
}
END

my $jsPlotAxesLabels = q:to/END/;
// Obtain x-axis label
var xAxisLabel = $X_AXIS_LABEL
var xAxisLabelFontSize = $X_AXIS_LABEL_FONT_SIZE

if ( xAxisLabel.length > 0 ) {
    svg.append("text")
        .attr("x", (width / 2))
        .attr("y", height + margin.bottom - xAxisLabelFontSize/2)
        .attr("text-anchor", "middle")
        .style("font-size", xAxisLabelFontSize.toString() + "px")
        .style("fill", $X_AXIS_LABEL_FILL)
        .text(xAxisLabel);
}

// Obtain y-axis label
var yAxisLabel = $Y_AXIS_LABEL
var yAxisLabelFontSize = $Y_AXIS_LABEL_FONT_SIZE

if ( yAxisLabel.length > 0 ) {
    svg.append("text")
        .attr("transform", "rotate(-90)")
        .attr("x", - (height / 2))
        .attr("y", 0 - margin.left + yAxisLabelFontSize)
        .attr("text-anchor", "middle")
        .style("font-size", yAxisLabelFontSize.toString() + "px")
        .style("fill", $Y_AXIS_LABEL_FILL)
        .text(yAxisLabel);
}
END

my $jsPlotMarginsTitleAndLabels = $jsPlotMarginsAndTitle ~ "\n" ~ $jsPlotAxesLabels;

my $jsPlotDataAndScales = q:to/END/;
// Obtain data
var data = $DATA

var xMin = Math.min.apply(Math, data.map(function(o) { return o.x; }))
var xMax = Math.max.apply(Math, data.map(function(o) { return o.x; }))

var yMin = Math.min.apply(Math, data.map(function(o) { return o.y; }))
var yMax = Math.max.apply(Math, data.map(function(o) { return o.y; }))

// X scale and Axis
var x = d3.$X_AXIS_SCALE
    .domain([xMin, xMax])
    .range([0, width]);

// Y scale and Axis
var y = d3.$Y_AXIS_SCALE
    .domain([yMin, yMax])
    .range([height, 0]);
END

my $jsPlotDataAxes = q:to/END/;
svg
  .append('g')
  .attr("transform", "translate(0," + height + ")")
  .call(d3.axisBottom(x))

svg
  .append('g')
  .call(d3.axisLeft(y));
END

my $jsPlotDataScalesAndAxes = $jsPlotDataAndScales ~ "\n" ~ $jsPlotDataAxes;

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
    return $format.lc ∈ <jupyter asis> ?? $jsPlotStarting !! $jsPlotStartingHTML;
}

our sub GetPlotEndingCode(Str $format = 'jupyter') {
    return $format.lc ∈ <jupyter asis> ?? $jsPlotEnding !! $jsPlotEndingHTML;
}

our sub GetPlotMarginsAndTitle(Str $format = 'jupyter') {
    return
            $format.lc ∈ <jupyter asis> ??
            $jsPlotMarginsAndTitle !! $jsPlotMarginsAndTitle.subst(:g, 'element.get(0)', '"#my_dataviz"');
}

our sub GetPlotMarginsTitleAndLabelsCode(Str $format = 'jupyter') {
    return
            $format.lc ∈ <jupyter asis> ??
            $jsPlotMarginsTitleAndLabels !! $jsPlotMarginsTitleAndLabels.subst(:g, 'element.get(0)', '"#my_dataviz"');
}

our sub ProcessAxisScale($scale = Whatever) {
    return do given $scale {
        when Whatever { 'scaleLinear()' }
        when WhateverCode { 'scaleLinear()' }
        when $_ ~~ Str:D && $_.lc ∈ <line linear> { 'scaleLinear()' }
        when $_ ~~ Str:D && $_.lc ∈ <log logarith logarithmic> { 'scaleLog()' }
        default { $_ }
    }
}
our sub GetPlotDataAndScalesCode(
        :$x-axis-scale = Whatever,
        :$y-axis-scale = Whatever) {
    return
            $jsPlotDataAndScales
            .subst('$X_AXIS_SCALE', ProcessAxisScale($x-axis-scale))
            .subst('$Y_AXIS_SCALE', ProcessAxisScale($y-axis-scale));
}

our sub GetPlotDataScalesAndAxesCode(
        UInt $nXTicks = 0,
        UInt $nYTicks = 0,
        Str $codeFragment = $jsPlotDataScalesAndAxes,
        :$x-axis-scale = Whatever,
        :$y-axis-scale = Whatever) {
    my $res = $codeFragment;
    if $nXTicks > 0 {
        $res = $res.subst('.call(d3.axisBottom(x))', ".call(d3.axisBottom(x).ticks($nXTicks).tickSizeInner(-height))");
    }
    if $nYTicks > 0 {
        $res = $res.subst('.call(d3.axisLeft(y))', ".call(d3.axisLeft(y).ticks($nYTicks).tickSizeInner(-width))");
    }
    $res = $res
            .subst('$X_AXIS_SCALE', ProcessAxisScale($x-axis-scale))
            .subst('$Y_AXIS_SCALE', ProcessAxisScale($y-axis-scale));
    return $res;
}

our sub GetPlotPreparationCode(
        Str $format = 'jupyter',
        UInt $nXTicks = 0,
        UInt $nYTicks = 0,
        Bool :$axes = True,
        :$x-axis-scale = Whatever,
        :$y-axis-scale = Whatever) {
    return [GetPlotMarginsTitleAndLabelsCode($format),
            $axes
            ?? GetPlotDataScalesAndAxesCode($nXTicks, $nYTicks, :$x-axis-scale, :$y-axis-scale)
            !! GetPlotDataAndScalesCode(:$x-axis-scale, :$y-axis-scale)].join("\n");
}

our sub GetLegendCode() {
    return $jsGroupsLegend;
}


#============================================================
# Tooltip code snippets
#============================================================

my $jsTooltipPart = q:to/END/;
// -1- Create a tooltip div that is hidden by default:
const tooltip = d3.select(element.get(0))
    .append("div")
      .style("opacity", 0)
      .attr("class", "tooltip")
      .style("background-color", $TOOLTIP_BACKGROUND_COLOR)
      .style("border-radius", "5px")
      .style("padding", "10px")
      .style("color", $TOOLTIP_COLOR)

// -2- Create 3 functions to show / update (when mouse move but stay on same circle) / hide the tooltip
const showTooltip = function(event, d) {
    tooltip
      .transition()
      .duration($TOOLTIP_DURATION);

    var tooltipContent
    if (d.tooltip) {
        tooltipContent = d.tooltip;
    } else if (d.label) {
        tooltipContent = "Label: " + d.label;
    } else if (d.group && d.x && d.y && d.z) {
        tooltipContent = "Group: " + d.group + '<br/>z: ' + d.z.toString() + '<br/>x: ' + d.x.toString() + '<br/>y: ' + d.y.toString();
    } else if (d.group && d.x && d.y) {
        tooltipContent = "Group: " + d.group + '<br/>x: ' + d.x.toString() + '<br/>y: ' + d.y.toString();
    }

    tooltip
      .style("opacity", 1)
      .html(tooltipContent)
      .style("left", (event.x)/2 + "px")
      .style("top", (event.y)/2 + 10 + "px");
};

const moveTooltip = function(event, d) {
tooltip
  .style("left", (event.x)/2 + "px")
  .style("top", (event.y)/2+10 + "px")
};

const hideTooltip = function(event, d) {
tooltip
  .transition()
  .duration($TOOLTIP_DURATION)
  .style("opacity", 0)
};
END

my $jsTooltipMousePart = q:to/END/;
    .on("mouseover", showTooltip )
    .on("mousemove", moveTooltip )
    .on("mouseleave", hideTooltip )
END

#============================================================
# Tooltip code snippets
#============================================================

our sub GetTooltipPart(UInt :duration(:$tooltip-duration) = 200) {
    my $res = $jsTooltipPart
        .subst('$TOOLTIP_DURATION', $tooltip-duration):g;

    return $res;
}

our sub GetTooltipMousePart() {
    return $jsTooltipMousePart;
}

#============================================================
# ListPlot code snippets
#============================================================

my $jsScatterPlotPart = q:to/END/;
// Add dots
svg
  .selectAll("dot")
  .data(data)
  .enter()
  .append("circle")
    .attr("cx", function(d){ return x(d.x) })
    .attr("cy", function(d){ return y(d.y) })
    .attr("r", $POINT_RADIUS)
    .attr("color", "blue")
    .attr("fill", $POINT_COLOR)
  // Trigger the tooltip functions
END

my $jsMultiScatterPlotPart = q:to/END/;
// Add a scale for dot color
var myColor = d3.scaleOrdinal()
    .domain(data.map(function(o) { return o.group; }))
    .range(d3.$COLOR_SCHEME);

// Add dots
svg
  .selectAll("whatever")
  .data(data)
  .enter()
  .append("circle")
    .attr("cx", function(d){ return x(d.x) })
    .attr("cy", function(d){ return y(d.y) })
    .attr("r", $POINT_RADIUS)
    .attr("color", "blue")
    .attr("fill", function (d) { return myColor(d.group) } )
  // Trigger the tooltip functions
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
  .attr("stroke-width", $STROKE_WIDTH)
  .attr('stroke', $LINE_COLOR)
  .attr('fill', 'none');
END

my $jsFilledPathPlotPart = q:to/END/;
// prepare a helper function
var areaFunc = d3.area()
  .x(function(d) { return x(d.x) })
  .y0(function(d) { return y(0) })
  .y1(function(d) { return y(d.y) })

// Add the path using this helper function
svg.append('path')
  .attr('d', areaFunc(data))
  .attr("stroke-width", $STROKE_WIDTH)
  .attr('stroke', $LINE_COLOR)
  .attr('fill', $FILL_COLOR);
END

# See https://d3-graph-gallery.com/graph/line_several_group.html
my $jsMultiPathPlotPart = q:to/END/;
// group the data: I want to draw one line per group
var sumstat = d3.group(data, d => d.group);

// Add a scale for line color
var myColor = d3.scaleOrdinal()
    .domain(data.map(function(o) { return o.group; }))
    .range(d3.$COLOR_SCHEME);

// Draw the line
svg.selectAll(".line")
      .data(sumstat)
      .join("path")
        .attr("fill", "none")
        .attr("stroke", function(d){ return myColor(d[0]) })
        .attr("stroke-width", $STROKE_WIDTH)
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

our sub GetPathPlotPart(Bool :$filled = False) {
    return $filled ?? $jsFilledPathPlotPart !! $jsPathPlotPart;
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

// Y scale and Axis
var y = d3.$Y_AXIS_SCALE
    .domain([yMin, yMax])
    .range([height, 0]);
END

my $jsPlotDateAxes = q:to/END/;
svg
  .append('g')
  .attr("transform", "translate(0," + height + ")")
  .call(d3.axisBottom(x))

svg
  .append('g')
  .call(d3.axisLeft(y));
END

#============================================================
# DateListPlot code snippets accessors
#============================================================

our sub GetPlotDateDataAndScales(:$y-axis-scale = Whatever) {
    return $jsPlotDateDataAndScales.subst('$Y_AXIS_SCALE', ProcessAxisScale($y-axis-scale));
}

our sub GetPlotDateDataScalesAndAxes(:$y-axis-scale = Whatever) {
    return GetPlotDateDataAndScales(:$y-axis-scale) ~ "\n" ~ $jsPlotDateAxes;
}

#============================================================
# Box-Whisker code snippets
#============================================================

my $jsBoxWhiskerPlotBoxData = q:to/END/;
// Obtain data
var data = $DATA

// Compute summary statistics used for the box:
var data_sorted = data.sort(d3.ascending)
var q1 = d3.quantile(data_sorted, .25)
var median = d3.quantile(data_sorted, .5)
var q3 = d3.quantile(data_sorted, .75)
var interQuantileRange = q3 - q1
var min = q1 - 1.5 * interQuantileRange
var max = q1 + 1.5 * interQuantileRange

var outliers = data.filter(d => d < min || max < d);

var valueMin = Math.min.apply(Math, data.map(function(o) { return o; }))
var valueMax = Math.max.apply(Math, data.map(function(o) { return o; }))

const tooltipContent = `
  <table>
    <tr><td><b>max</b></td><td>${valueMax}</td></tr>
    <tr><td><b>75%</b></td><td>${q3}</td></tr>
    <tr><td><b>median</b></td><td>${median}</td></tr>
    <tr><td><b>25%</b></td><td>${q1}</td></tr>
    <tr><td><b>min</b></td><td>${valueMin}</td></tr>
  </table>
`;

const findClosestLarger = (data, min) => {
  return data.filter(d => d > min).reduce((prev, curr) =>
    (Math.abs(curr - min) < Math.abs(prev - min) ? curr : prev), Infinity);
};

const findClosestSmaller = (data, max) => {
  return data.filter(d => d < max).reduce((prev, curr) =>
    (Math.abs(curr - max) < Math.abs(prev - max) ? curr : prev), Infinity);
};

const minWhisker = findClosestLarger(data, min);
const maxWhisker = findClosestSmaller(data, max);

var boxData = [{"q1" : q1, "q3" : q3, "minWhisker" : minWhisker, "maxWhisker" : maxWhisker, "median" : median, "tooltip" : tooltipContent }];
END

my $jsVerticalBoxWhiskerPlot = q:to/END/;
// Show the Y scale
var y = d3.scaleLinear()
  .domain([valueMin,valueMax])
  .range([height, 0]);
svg.call(d3.axisLeft(y))

// a few features for the box
var center = width / 2
var boxWidth = $BOX_WIDTH

// Show the main vertical line
svg
.append("line")
  .attr("x1", center)
  .attr("x2", center)
  .attr("y1", y(minWhisker) )
  .attr("y2", y(maxWhisker) )
  .attr("stroke", $STROKE_COLOR)

svg.append('g')
    .selectAll('rect')
    .data(boxData)
    .join("rect")
        .attr("x", center - boxWidth/2)
        .attr("y", d => y(d.q3) )
        .attr("height", d => (y(d.q1)-y(d.q3)) )
        .attr("width", boxWidth )
        .attr("stroke", $STROKE_COLOR)
        .style("fill", $FILL_COLOR)
    // Trigger the tooltip functions

if ($OUTLIERS) {
    svg
      .selectAll("whatever")
      .data(outliers)
      .enter()
      .append("circle")
        .attr("cy", function(d){ return y(d) })
        .attr("cx", center)
        .attr("r", 2)
        .attr("color", $STROKE_COLOR)
        .attr("fill", $STROKE_COLOR)
}

// show median, min and max horizontal lines
svg
.selectAll("toto")
.data([minWhisker, median, maxWhisker])
.enter()
.append("line")
  .attr("x1", center-boxWidth/2)
  .attr("x2", center+boxWidth/2)
  .attr("y1", function(d){ return(y(d))} )
  .attr("y2", function(d){ return(y(d))} )
  .attr("stroke", $STROKE_COLOR)
END

my $jsHorizonalBoxWhiskerPlot = q:to/END/;
// Show the X scale
var x = d3.scaleLinear()
  .domain([valueMin,valueMax])
  .range([0, width]);

svg.call(d3.axisBottom(x))

// a few features for the box
var center = height / 2
var boxWidth = $BOX_WIDTH

// Show the main vertical line
svg
.append("line")
  .attr("y1", center)
  .attr("y2", center)
  .attr("x1", x(minWhisker) )
  .attr("x2", x(maxWhisker) )
  .attr("stroke", $STROKE_COLOR)

svg.append('g')
    .selectAll('rect')
    .data(boxData)
    .join("rect")
        .attr("x", d => x(d.q1) )
        .attr("y", center - boxWidth/2)
        .attr("width", d => (x(d.q3)-x(d.q1)) )
        .attr("height", boxWidth )
        .attr("stroke", $STROKE_COLOR)
        .style("fill", $FILL_COLOR)
    // Trigger the tooltip functions

if ($OUTLIERS) {
    svg
      .selectAll("whatever")
      .data(outliers)
      .enter()
      .append("circle")
        .attr("cx", function(d){ return x(d) })
        .attr("cy", center)
        .attr("r", 2)
        .attr("color", $STROKE_COLOR)
        .attr("fill", $STROKE_COLOR)
}

// show median, min and max horizontal lines
svg
.selectAll("toto")
.data([minWhisker, median, maxWhisker])
.enter()
.append("line")
  .attr("y1", center-boxWidth/2)
  .attr("y2", center+boxWidth/2)
  .attr("x1", function(d){ return(x(d))} )
  .attr("x2", function(d){ return(x(d))} )
  .attr("stroke", $STROKE_COLOR)
END

my $jsMultiBoxWhiskerPlot = q:to/END/;
// Obtain data
var data = $DATA

var groupColumn = $GROUP_COLUMN;
var valueColumn = $VALUE_COLUMN;

var valueMin = Math.min.apply(Math, data.map(function(o) { return o[valueColumn]; }))
var valueMax = Math.max.apply(Math, data.map(function(o) { return o[valueColumn]; }))

var uniqueValues = [...new Set(data.map(d => d[groupColumn]))];

// Compute quartiles, median, inter quantile range min and max --> these info are then used to draw the box.
var sumstat = d3.nest() // nest function allows to group the calculation per level of a factor
.key(function(d) { return d[groupColumn];})
.rollup(function(d) {
  q1 = d3.quantile(d.map(function(g) { return g[valueColumn];}).sort(d3.ascending),.25)
  median = d3.quantile(d.map(function(g) { return g[valueColumn];}).sort(d3.ascending),.5)
  q3 = d3.quantile(d.map(function(g) { return g[valueColumn];}).sort(d3.ascending),.75)
  interQuantileRange = q3 - q1
  min = q1 - 1.5 * interQuantileRange
  max = q3 + 1.5 * interQuantileRange
  return({q1: q1, median: median, q3: q3, interQuantileRange: interQuantileRange, min: min, max: max})
})
.entries(data)

// Show the X scale
var x = d3.scaleBand()
.range([ 0, width ])
.domain(uniqueValues)
.paddingInner(1)
.paddingOuter(.5)
svg.append("g")
.attr("transform", "translate(0," + height + ")")
.call(d3.axisBottom(x))

// Show the Y scale
var y = d3.scaleLinear()
.domain([valueMin * 0.95, valueMax * 1.05])
.range([height, 0])
svg.append("g").call(d3.axisLeft(y))

// Show the main vertical line
svg
.selectAll("vertLines")
.data(sumstat)
.enter()
.append("line")
  .attr("x1", function(d){return(x(d.key))})
  .attr("x2", function(d){return(x(d.key))})
  .attr("y1", function(d){return(y(d.value.min))})
  .attr("y2", function(d){return(y(d.value.max))})
  .attr("stroke", "black")
  .style("width", 40)

// rectangle for the main box
var boxWidth = $BOX_WIDTH
svg
.selectAll("boxes")
.data(sumstat)
.enter()
.append("rect")
    .attr("x", function(d){return(x(d.key)-boxWidth/2)})
    .attr("y", function(d){return(y(d.value.q3))})
    .attr("height", function(d){return(y(d.value.q1)-y(d.value.q3))})
    .attr("width", boxWidth )
    .attr("stroke", "black")
    .style("fill", "#69b3a2")

// Show the median
svg
.selectAll("medianLines")
.data(sumstat)
.enter()
.append("line")
  .attr("x1", function(d){return(x(d.key)-boxWidth/2) })
  .attr("x2", function(d){return(x(d.key)+boxWidth/2) })
  .attr("y1", function(d){return(y(d.value.median))})
  .attr("y2", function(d){return(y(d.value.median))})
  .attr("stroke", "white")
  .style("width", 80)
END

#============================================================
# Box-Whisker code accessors
#============================================================

our sub GetBoxWhiskerChartPart(Bool :$horizontal=False) {
    my $res = [
        GetTooltipPart(),
        $jsBoxWhiskerPlotBoxData,
        $horizontal ?? $jsHorizonalBoxWhiskerPlot !! $jsVerticalBoxWhiskerPlot
    ].join("\n\n");

    my $marker = '// Trigger the tooltip functions';
    $res .= subst($marker, $marker ~ "\n" ~ GetTooltipMousePart());

    return $res;
}

our sub GetMultiBoxWhiskerChartPart() {
    return $jsMultiBoxWhiskerPlot;
}

#============================================================
# Linear Gradient code snippets
#============================================================

my $jsLinearGradient = q:to/END/;
// Set the gradient
svg.append("linearGradient")
  .attr("id", "line-gradient")
  .attr("gradientUnits", "userSpaceOnUse")
  .attr("x1", $LINEAR_GRADIENT_MIN_X)
  .attr("y1", $LINEAR_GRADIENT_MIN_Y)
  .attr("x2", $LINEAR_GRADIENT_MAX_X)
  .attr("y2", $LINEAR_GRADIENT_MAX_Y)
  .selectAll("stop")
    .data([
      {offset: "0%", color: "$LINEAR_GRADIENT_COLOR_0"},
      {offset: "100%", color: "$LINEAR_GRADIENT_COLOR_100"}
    ])
  .enter().append("stop")
    .attr("offset", function(d) { return d.offset; })
    .attr("stop-color", function(d) { return d.color; });
END

#============================================================
# Linear Gradient accessors
#============================================================
our sub GetLinearGradientCode(:$minX='x(xMin)', :$maxX='x(xMax)',
                              :$minY='y(yMin)', :$maxY='y(yMax)',
                              :$color0 = 'blue', :$color100 = 'red') {
    return
            $jsLinearGradient
            .subst('$LINEAR_GRADIENT_MIN_X', $minX)
            .subst('$LINEAR_GRADIENT_MAX_X', $maxX)
            .subst('$LINEAR_GRADIENT_MIN_Y', $minY)
            .subst('$LINEAR_GRADIENT_MAX_Y', $maxY)
            .subst('$LINEAR_GRADIENT_COLOR_0', $color0)
            .subst('$LINEAR_GRADIENT_COLOR_100', $color100);
}

#============================================================
# BarChart code snippets
#============================================================
# See https://d3-graph-gallery.com/graph/barplot_basic.html

my $jsBarChartPart = q:to/END/;
// Obtain data
var data = $DATA

var valueMin = Math.min.apply(Math, data.map(function(o) { return o.y; }))
var valueMax = Math.max.apply(Math, data.map(function(o) { return o.y; }))

// X axis
var x = d3.scaleBand()
  .range([ 0, width ])
  .domain(data.map(function(d) { return d.x; }))
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
    .attr("x", function(d) { return x(d.x); })
    .attr("y", function(d) { return y(d.y); })
    .attr("width", x.bandwidth())
    .attr("height", function(d) { return height - y(d.y); })
    .attr("fill", $FILL_COLOR)
END

my $jsBarChartHorizontalPart = q:to/END/;
// Obtain data
var data = $DATA

var valueMin = Math.min.apply(Math, data.map(function(o) { return o.y; }))
var valueMax = Math.max.apply(Math, data.map(function(o) { return o.y; }))

// Y axis
var y = d3.scaleBand()
  .range([0, height])
  .domain(data.map(function(d) { return d.x; }))
  .padding(0.2);

svg.append("g")
  .call(d3.axisLeft(y))
  .selectAll("text")
    .attr("transform", "translate(-10,0)")
    .style("text-anchor", "end");

// Add X axis
var x = d3.scaleLinear()
  .domain([0, valueMax])
  .range([0, width]);

svg.append("g")
  .attr("transform", "translate(0," + height + ")")
  .call(d3.axisBottom(x));

// Bars
svg.selectAll("mybar")
  .data(data)
  .enter()
  .append("rect")
    .attr("x", function(d) { return 0; })
    .attr("y", function(d) { return y(d.x); })
    .attr("height", y.bandwidth())
    .attr("width", function(d) { return x(d.y); })
    .attr("fill", $FILL_COLOR)
END

my $jsMultiBarChartPart = q:to/END/;
// Obtain data
var data = $DATA

var valueMin = Math.min.apply(Math, data.map(function(o) { return o.y; }))
var valueMax = Math.max.apply(Math, data.map(function(o) { return o.y; }))
var absMax = Math.max.apply(Math, data.map(function(o) { return Math.abs(o.y); }))

var zeroLocation = height
zeroLocation = height * Math.abs(valueMax / (valueMax - valueMin))

// List of subgroups
var subgroups = d3.map(data, function(d){return(d.x)}).values()
subgroups = [...new Set(subgroups)];

// List of groups
var groups = d3.map(data, function(d){return(d.group)}).values()

// Add X axis
var x = d3.scaleBand()
  .domain(groups)
  .range([0, width])
  .padding([0.2]);

svg.append("g")
.attr("transform", "translate(0," + zeroLocation + ")")
.call(d3.axisBottom(x).tickSize(0));

// Add Y axis
//    .domain([-absMax, absMax]).nice()
var y = d3.scaleLinear()
    .domain([valueMin, valueMax])
    .range([ height, 0 ]);

svg.append("g")
    .call(d3.axisLeft(y));

// Another scale for subgroup position?
var xSubgroup = d3.scaleBand()
    .domain(subgroups)
    .range([0, x.bandwidth()])
    .padding([0.05])

// Color palette = one color per subgroup
var myColor = d3.scaleOrdinal()
    .domain(subgroups)
    .range(d3.$COLOR_SCHEME);

// Show the bars positive values
svg.append("g")
    .selectAll("g")
    // Enter in data = loop group per group
    .data(data.map(d => d.y > 0 ? d : {y: 0}))
    .join("g")
      .attr("transform", d => `translate(${x(d.group)}, 0)`)
    .selectAll("rect")
    .data(function(d) { return data.filter(function(x){ return x.group == d.group }) })
    .join("rect")
      .attr("x", d => xSubgroup(d.x))
      .attr("y", d => y(d.y))
      .attr("width", xSubgroup.bandwidth())
      .attr("height", d => y(0) - y(d.y))
      .attr("fill", d => myColor(d.x));

// Show the bars negative values
svg.append("g")
    .selectAll("g")
    // Enter in data = loop group per group
    .data(data.map(d => d.y < 0 ? d : {y: 0}))
    .join("g")
      .attr("transform", d => `translate(${x(d.group)}, 0)`)
    .selectAll("rect")
    .data(function(d) { return data.filter(function(x){ return x.group == d.group }) })
    .join("rect")
      .attr("x", d => xSubgroup(d.x))
      .attr("y", d => y(0))
      .attr("width", xSubgroup.bandwidth())
      .attr("height", d => y(0) - y(-d.y))
      .attr("fill", d => myColor(d.x));
END

my $jsBarChartLabelsPart = q:to/BARCHART-PLOT-LABELS/;
svg.selectAll("mybar")
  .data(data)
  .enter()
  .append("text")
    .text(function(d) {return d.label})
    .attr("x", function(d){return x(d.x) + x.bandwidth()/2 })
    .attr("y", function(d){return y(d.y) - $PLOT_LABELS_Y_OFFSET})
    .style("fill", $PLOT_LABELS_COLOR)
    .style("stroke-width", "1px")
    .style("font-size", $PLOT_LABELS_FONT_SIZE)
    .attr("font-family", "$PLOT_LABELS_FONT_FAMILY")
    .attr("text-anchor", "middle")
BARCHART-PLOT-LABELS

my $jsBarChartHorizontalLabelsPart = q:to/BARCHARTHOR-PLOT-LABELS/;
var hy = y.bandwidth() * 0.65;

svg.selectAll("mybar")
  .data(data)
  .enter()
  .append("text")
    .text(function(d) {return d.label})
    .attr("x", function(d){return x(d.y) + $PLOT_LABELS_Y_OFFSET })
    .attr("y", function(d){return y(d.x) + hy})
    .style("fill", $PLOT_LABELS_COLOR)
    .style("stroke-width", "1px")
    .style("font-size", $PLOT_LABELS_FONT_SIZE)
    .attr("font-family", "$PLOT_LABELS_FONT_FAMILY")
    .attr("text-anchor", "left")
BARCHARTHOR-PLOT-LABELS

#============================================================
# BarChart code snippets accessors
#============================================================

our sub GetBarChartPart(Bool :$horizontal = False) {
    return $horizontal ?? $jsBarChartHorizontalPart !! $jsBarChartPart;
}

our sub GetMultiBarChartPart() {
    return $jsMultiBarChartPart;
}

our sub GetBarChartLabelsPart(Bool :$horizontal = False) {
    return $horizontal ?? $jsBarChartHorizontalLabelsPart !! $jsBarChartLabelsPart;
}

#============================================================
# Histogram code snippets
#============================================================
# See https://d3-graph-gallery.com/graph/histogram_basic.html
my $jsHistogramPart = q:to/END/;
// Obtain data
var data = $DATA

var valueMin = Math.min.apply(Math, data)
var valueMax = Math.max.apply(Math, data)

// X axis: scale and draw:
var x = d3.scaleLinear()
      .domain([valueMin, valueMax])
      .range([0, width]);
svg.append("g")
      .attr("transform", "translate(0," + height + ")")
      .call(d3.axisBottom(x));

// set the parameters for the histogram
var histogram = d3.histogram()
      .value(function(d) { return d; })  // I need to give the vector of value
      .domain(x.domain())  // then the domain of the graphic
      .thresholds(x.ticks($NUMBER_OF_BINS)); // then the numbers of bins

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
    .range([$Z_RANGE_MIN, $Z_RANGE_MAX]);

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
    .range([$Z_RANGE_MIN, $Z_RANGE_MAX]);

// Add a scale for bubble color
var myColor = d3.scaleOrdinal()
    .domain(data.map(function(o) { return o.group; }))
    .range(d3.$COLOR_SCHEME);

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
      .attr("stroke", $STROKE_COLOR)
    // Trigger the tooltip functions
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
    #return $jsTooltipMultiBubbleChartPart;
    my $res =  GetTooltipPart() ~ "\n\n" ~ GetMultiBubbleChartPart();
    my $marker = '// Trigger the tooltip functions';
    $res .= subst($marker, $marker ~ "\n" ~ GetTooltipMousePart());
    return $res;
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

#============================================================
# Image display code snippets
#============================================================

my $jsImageDisplayPart = q:to/END/;
const imagePath = '$IMAGE_PATH'
d3.select(element.get(0)).append('img').attr("src", imagePath).attr("width", "$WIDTH").attr("height", "$HEIGHT")
END

#============================================================
# Image display code snippets accessors
#============================================================

our sub GetImageDisplayPart() {
    return $jsImageDisplayPart;
}

#============================================================
# Image code snippets
#============================================================

my $jsImagePart = q:to/END/;
const color = d3.scaleSequential([$LOW_VALUE, $HIGH_VALUE], d3.interpolate$COLOR_PALETTE)

// Obtain data
var data = $DATA

var n = data.width,
  m = data.height;

var canvas = d3.select("canvas")
  .attr("width", n)
  .attr("height", m);

var context = canvas.node().getContext("2d"),
  image = context.createImageData(n, m);

for (var j = 0, k = 0, l = 0; j < m; ++j) {
    for (var i = 0; i < n; ++i, ++k, l += 4) {
      var c = d3.rgb(color(data.values[k]));
      image.data[l + 0] = c.r;
      image.data[l + 1] = c.g;
      image.data[l + 2] = c.b;
      image.data[l + 3] = 255;
    }
}

context.putImageData(image, 0, 0);
END

#============================================================
# Image code snippets accessors
#============================================================

our sub GetImagePart() {
    return $jsImagePart;
}

#============================================================
# Heatmap code snippets
#============================================================

my $jsTooltipHeatmapPart = q:to/HEATMAP-PART-END/;
// Obtain data
var data = $DATA;

var myGroups = $X_TICK_LABELS;
var myVars = $Y_TICK_LABELS;

if (myGroups.length === 0) {
    myGroups = Array.from(new Set(data.map(d => d.x)));
}
if (myVars.length === 0) {
    myVars = Array.from(new Set(data.map(d => d.y)));
}

if ($SORT_TICK_LABELS) {
    myGroups = myGroups.sort(d3.ascending);
    myVars = myVars.sort(d3.ascending);
}

// Build X scales and axis:
var x = d3.scaleBand()
    .range([0, width])
    .domain(myGroups)
    .padding(0.05);

svg.append("g")
    .style("font-size", $TICK_LABELS_FONT_SIZE)
    .style("stroke", $TICK_LABELS_COLOR)
    .style("stroke-width", "1px")
    .attr("font-family", $TICK_LABELS_FONT_FAMILY)
    .attr("transform", `translate(0, ${height})`)
    .call(d3.axisBottom(x).tickSize(0))
    .select(".domain").remove();

// Build Y scales and axis:
var y = d3.scaleBand()
    .range([height, 0])
    .domain(myVars)
    .padding(0.05);

svg.append("g")
    .style("font-size", $TICK_LABELS_FONT_SIZE)
    .style("stroke", $TICK_LABELS_COLOR)
    .style("stroke-width", "1px")
    .attr("font-family", $TICK_LABELS_FONT_FAMILY)
    .call(d3.axisLeft(y).tickSize(0))
    .select(".domain").remove();

// Build color scale
var myColor = d3.scaleSequential()
    .interpolator(d3.interpolate$COLOR_PALETTE)
    .domain([$LOW_VALUE, $HIGH_VALUE]);

// tooltip-code-begin
// create a tooltip
var tooltip = d3.select(element.get(0))
    .append("div")
    .style("opacity", 0)
    .attr("class", "tooltip")
    .style("background-color", $TOOLTIP_BACKGROUND_COLOR)
    .style("border", "solid")
    .style("border-width", "2px")
    .style("border-radius", "5px")
    .style("padding", "5px")
    .style("color", $TOOLTIP_COLOR);

// Three functions that change the tooltip when user hover / move / leave a cell
var mouseover = function(event, d) {
    tooltip
        .style("opacity", 1);
    d3.select(this)
        .style("stroke", "black")
        .style("opacity", 1);
};

var mousemove = function(event, d) {
    tooltip
        .html((d.tooltip ? String(d.tooltip) : String(d.z)))
        .style("left", (event.pageX) + "px")
        .style("top", (event.pageY) + "px");
};

var mouseleave = function(event, d) {
    tooltip
        .style("opacity", 0);
    d3.select(this)
        .style("stroke", "none")
        .style("opacity", 0.8);
};
// tooltip-code-end

// add the squares
svg.selectAll()
    .data(data, d => d.x + ':' + d.y)
    .join("rect")
    .attr("x", d => x(d.x))
    .attr("y", d => y(d.y))
    .attr("rx", 4)
    .attr("ry", 4)
    .attr("width", x.bandwidth())
    .attr("height", y.bandwidth())
    .style("fill", d => myColor(d.z))
    .style("stroke-width", 4)
    .style("stroke", "none")
    .style("opacity", $OPACITY)
    .on("mouseover", mouseover)
    .on("mousemove", mousemove)
    .on("mouseleave", mouseleave);

// add the grid
if ( $GRID_LINES) {
    svg.selectAll()
        .data(data, d => d.x + ':' + d.y)
        .join("rect")
        .attr("x", d => x(d.x))
        .attr("y", d => y(d.y))
        .attr("rx", 0)
        .attr("ry", 0)
        .attr("width", x.bandwidth())
        .attr("height", y.bandwidth())
        .style("fill", "none")
        .style("stroke-width", $GRID_LINES_WIDTH)
        .style("stroke", $GRID_LINES_COLOR)
        .style("opacity", 1)
}
HEATMAP-PART-END

#============================================================
# Heatmap code snippets accessors
#============================================================

our sub GetTooltipHeatmapPart() {
    return $jsTooltipHeatmapPart;
}

#============================================================
# Chessboard code snippets
#============================================================

my $jsTooltipHeatmapPlotLabelsPart = q:to/HEATMAP-PLOT-LABELS/;
var plotLabelData = $PLOT_LABELS_DATA

var hx = x.bandwidth()
var hy = y.bandwidth()

svg.selectAll()
.data(plotLabelData, function(d) {return d.x+':'+d.y;})
.join("text")
  .attr("x", function(d) { return x(d.x) + hx/2 })
  .attr("y", function(d) { return y(d.y) + hy/2 + $PLOT_LABELS_Y_OFFSET })
  .attr("text-anchor", "middle")
  .style("alignment-baseline", "middle")
  .style("fill", $PLOT_LABELS_COLOR)
  .style("stroke", $PLOT_LABELS_COLOR)
  .style("stroke-width", "1px")
  .style("font-size", $PLOT_LABELS_FONT_SIZE)
  .attr("font-family", "$PLOT_LABELS_FONT_FAMILY")
  .attr("font-weight", 100)
  .html(function(d){ return d.z });
HEATMAP-PLOT-LABELS

#============================================================
# Chessboard code snippets accessors
#============================================================

our sub GetTooltipHeatmapPlotLabelsPart() {
    return $jsTooltipHeatmapPlotLabelsPart;
}

#============================================================
# Graph-force code snippets
#============================================================
# For the force settings see GitHub gist:
# https://gist.github.com/steveharoz/8c3e2524079a8c440df60c1ab72b5d03

my $jsGraphPart = q:to/GRAPH-END/;
const edges = $DATA;

const nodes = Array.from(new Set(edges.flatMap(e => [e.from, e.to])), id => ({id}));

const highlightSpecs = $HIGHLIGHT_SPEC;

const links = edges.map(e => ({
  source: e.from,
  target: e.to,
  weight: e.weight,
  label: e.label,
}));

//.force("link", d3.forceLink(links).id(d => d.id).distance(d => Math.max(d.weight * 20, $NODE_SIZE * 4)))
const simulation = d3.forceSimulation(nodes)
    .force("link", d3.forceLink(links).id(d => d.id).distance($FORCE_LINK_DISTANCE).iterations($FORCE_LINK_ITER))
    .force("charge", d3.forceManyBody().strength($FORCE_CHARGE_STRENGTH).distanceMin($FORCE_CHARGE_DIST_MIN).distanceMax($FORCE_CHARGE_DIST_MAX))
    .force("x", d3.forceX().strength($FORCE_X_STRENGTH).x($FORCE_X))
    .force("y", d3.forceY().strength($FORCE_Y_STRENGTH).y($FORCE_Y))
    .force("collision", d3.forceCollide().strength($FORCE_COLLIDE_STRENGTH).radius($FORCE_COLLIDE_RADIUS).iterations($FORCE_COLLIDE_ITER))
    .force("center", d3.forceCenter($FORCE_CENTER_X, $FORCE_CENTER_Y));

svg.append('defs').append('marker')
    .attr("id",'arrowhead')
    .attr('viewBox','-0 -5 10 10') //the bound of the SVG viewport for the current SVG fragment. defines a coordinate system 10 wide and 10 high starting on (0,-5)
     .attr('refX', $ARROWHEAD_OFFSET) // x coordinate for the reference point of the marker. If circle is bigger, this need to be bigger.
     .attr('refY',0)
     .attr('orient','auto')
        .attr('markerWidth', $ARROWHEAD_SIZE)
        .attr('markerHeight', $ARROWHEAD_SIZE)
        .attr('xoverflow','visible')
    .append('svg:path')
    .attr('d', 'M 0,-5 L 10 ,0 L 0,5')
    .attr('fill', $LINK_STROKE_COLOR)
    .style('stroke','none');

const link = svg.append("g")
    .attr("class", "links")
  .selectAll("line")
  .data(links)
  .enter().append("line")
    .attr("class", "link")
    .attr("stroke", d => {
        for (const [color, items] of Object.entries(highlightSpecs)) {
            if (items.some(item => Array.isArray(item) && item[0] === d.source.id && item[1] === d.target.id)) {
                return color;
            }
        }
        return $LINK_STROKE_COLOR;
    })
    .attr("stroke-width", $LINK_STROKE_WIDTH)
    .attr('marker-end','url(#arrowhead)')

const node = svg.append("g")
    .attr("class", "nodes")
  .selectAll("circle")
  .data(nodes)
  .enter().append("circle")
    .attr("class", "node")
    .attr("r", $NODE_SIZE)
    .attr("stroke", d => {
       for (const [color, items] of Object.entries(highlightSpecs)) {
         if (items.includes(d.id)) {
            return color;
         }
       }
       return $NODE_STROKE_COLOR;
    })
    .attr("fill", d => {
       for (const [color, items] of Object.entries(highlightSpecs)) {
         if (items.includes(d.id)) {
            return color;
         }
       }
       return $NODE_FILL_COLOR;
    })
    .call(drag(simulation));

node.append("title")
    .text(d => d.id);

const nodeLabel = svg.append("g")
    .attr("class", "node-labels")
  .selectAll("text")
  .data(nodes)
  .enter().append("text")
    .attr("class", "node-label")
    .style("font-size", $NODE_LABEL_FONT_SIZE)
    .attr("font-family", $NODE_LABEL_FONT_FAMILY)
    .attr("font-weight", 100)
    .attr("dy", -10)
    .attr('fill', $NODE_LABEL_STROKE_COLOR)
    .attr('stroke', $NODE_LABEL_STROKE_COLOR)
    .text(d => d.id);

const linkLabel = svg.append("g")
    .attr("class", "link-labels")
  .selectAll("text")
  .data(links)
  .enter().append("text")
    .filter(d => d.label !== "")
    .attr("class", "link-label")
    .style("font-size", $LINK_LABEL_FONT_SIZE)
    .attr("font-family", "Courier")
    .attr('fill', $LINK_LABEL_STROKE_COLOR)
    .attr('stroke', $LINK_LABEL_STROKE_COLOR)
    .text(d => d.label);

simulation.on("tick", () => {
  link
      .attr("x1", d => d.source.x)
      .attr("y1", d => d.source.y)
      .attr("x2", d => d.target.x)
      .attr("y2", d => d.target.y);

  node
      .attr("cx", d => d.x)
      .attr("cy", d => d.y);

  nodeLabel
      .attr("x", d => d.x)
      .attr("y", d => d.y);

  linkLabel
      .attr("x", d => (d.source.x + d.target.x) / 2)
      .attr("y", d => (d.source.y + d.target.y) / 2);
});

function drag(simulation) {
  function dragstarted(event, d) {
    if (!event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
  }

  function dragged(event, d) {
    d.fx = event.x;
    d.fy = event.y;
  }

  function dragended(event, d) {
    if (!event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
  }

  return d3.drag()
      .on("start", dragstarted)
      .on("drag", dragged)
      .on("end", dragended);
}
GRAPH-END


#============================================================
# Graph code snippets accessors
#============================================================

our sub GetGraphPart() {
    return $jsGraphPart;
}


#============================================================
# Graph-with-coordinates code snippets
#============================================================

my $jsGraphWithCoordsPart = q:to/GRAPH-COORDS-END/;
const edges = $DATA;

const isDirected = $IS_DIRECTED;

const vertexCoordinates = $VERTEX_COORDINATES;

const highlightSpecs = $HIGHLIGHT_SPEC;

const links = edges.map(e => ({
  source: e.from,
  target: e.to,
  weight: e.weight,
  label: e.label
}));

const nodes = Object.keys(vertexCoordinates).map(key => ({
  id: key,
  x: vertexCoordinates[key].x,
  y: vertexCoordinates[key].y
}));

var xMin = Math.min.apply(Math, nodes.map(function(o) { return o.x; }))
var xMax = Math.max.apply(Math, nodes.map(function(o) { return o.x; }))

var yMin = Math.min.apply(Math, nodes.map(function(o) { return o.y; }))
var yMax = Math.max.apply(Math, nodes.map(function(o) { return o.y; }))

// X scale and Axis
var xScale = d3.scaleLinear()
    .domain([xMin, xMax])
    .range([0, width]);

// Y scale and Axis
var yScale = d3.scaleLinear()
    .domain([yMin, yMax])
    .range([height, 0]);

nodes.forEach(node => {
  node.x = xScale(node.x);
  node.y = yScale(node.y);
});

const link = svg.append("g")
    .attr("class", "links")
  .selectAll("line")
  .data(links)
  .enter().append("line")
    .attr("class", "link")
    .attr("stroke", d => {
        for (const [color, items] of Object.entries(highlightSpecs)) {
            if (items.some(item => Array.isArray(item) && item[0] === d.source && item[1] === d.target)) {
                return color;
            }
        }
        return $LINK_STROKE_COLOR;
    })
    .attr("stroke-width", $LINK_STROKE_WIDTH)
    .attr("x1", d => nodes.find(n => n.id === d.source).x)
    .attr("y1", d => nodes.find(n => n.id === d.source).y)
    .attr("x2", d => nodes.find(n => n.id === d.target).x)
    .attr("y2", d => nodes.find(n => n.id === d.target).y);

if (isDirected) {
  link.attr("marker-end", "url(#arrow)");
  svg.append("defs").append("marker")
    .attr("id", "arrow")
    .attr("viewBox", "0 -5 10 10")
    .attr("refX", $ARROWHEAD_OFFSET)
    .attr("refY", 0)
    .attr("markerWidth", $ARROWHEAD_SIZE)
    .attr("markerHeight", $ARROWHEAD_SIZE)
    .attr("orient", "auto")
    .append("path")
    .attr("d", "M0,-5L10,0L0,5")
    .attr("fill", $LINK_STROKE_COLOR);
}

const node = svg.append("g")
    .attr("class", "nodes")
  .selectAll("circle")
  .data(nodes)
  .enter().append("circle")
    .attr("class", "node")
    .attr("r", $NODE_SIZE)
    .attr("cx", d => d.x)
    .attr("cy", d => d.y)
    .attr("stroke", d => {
       for (const [color, items] of Object.entries(highlightSpecs)) {
         if (items.includes(d.id)) {
            return color;
         }
       }
       return $NODE_STROKE_COLOR;
    })
    .attr("fill", d => {
       for (const [color, items] of Object.entries(highlightSpecs)) {
         if (items.includes(d.id)) {
            return color;
         }
       }
       return $NODE_FILL_COLOR;
    })
    .call(d3.drag()
      .on("start", dragstarted)
      .on("drag", dragged)
      .on("end", dragended));

node.append("title")
    .text(d => d.id);

const nodeLabel = svg.append("g")
    .attr("class", "node-labels")
  .selectAll("text")
  .data(nodes)
  .enter().append("text")
    .attr("class", "node-label")
    .style("font-size", $NODE_LABEL_FONT_SIZE)
    .attr("font-family", $NODE_LABEL_FONT_FAMILY)
    .attr("font-weight", 100)
    .attr("dy", -10)
    .attr("x", d => d.x)
    .attr("y", d => d.y)
    .attr('fill', $NODE_LABEL_STROKE_COLOR)
    .attr('stroke', $NODE_LABEL_STROKE_COLOR)
    .text(d => d.id);

const linkLabel = svg.append("g")
    .attr("class", "link-labels")
  .selectAll("text")
  .data(links)
  .enter().append("text")
    .filter(d => d.label !== "")
    .attr("class", "link-label")
    .style("font-size", $LINK_LABEL_FONT_SIZE)
    .attr("font-family", $LINK_LABEL_FONT_FAMILY)
    .attr('fill', $LINK_LABEL_STROKE_COLOR)
    .attr('stroke', $LINK_LABEL_STROKE_COLOR)
    .attr("font-weight", 100)
    .attr("dy", -10)
    .attr("x", d => xScale((vertexCoordinates[d.source].x + vertexCoordinates[d.target].x) / 2))
    .attr("y", d => yScale((vertexCoordinates[d.source].y + vertexCoordinates[d.target].y) / 2))
    .text(d => d.label);

function dragstarted(event, d) {
  d3.select(this).raise().attr("stroke", $NODE_STROKE_COLOR);
}

function dragged(event, d) {
  d.x = event.x;
  d.y = event.y;
  d3.select(this).attr("cx", d.x).attr("cy", d.y);
  link
    .attr("x1", l => nodes.find(n => n.id === l.source).x)
    .attr("y1", l => nodes.find(n => n.id === l.source).y)
    .attr("x2", l => nodes.find(n => n.id === l.target).x)
    .attr("y2", l => nodes.find(n => n.id === l.target).y);
}

function dragended(event, d) {
  d3.select(this).attr("stroke", null);
}
GRAPH-COORDS-END

#============================================================
# Graph code snippets accessors
#============================================================

our sub GetGraphWithCoordsPart() {
    return $jsGraphWithCoordsPart;
}

#============================================================
# Mondrian code snippet
#============================================================
my $jsMondrianPart = q:to/MONDRIAN-END/;
const data = $DATA;

const colorScheme = $COLOR_SCHEME;

var color;
if (colorScheme.toLowerCase()  === 'none') {
    color = d3.scaleOrdinal(d3.schemeAccent)
} else {
    color = d3.scaleOrdinal(d3[colorScheme])
};

const weightedColors = $COLOR_PALETTE;

function getRandomWeightedColor() {
    const colors = [];
    for (const [color, weight] of Object.entries(weightedColors)) {
        for (let i = 0; i < weight; i++) {
            colors.push(color);
        }
    }
    return colors[Math.floor(Math.random() * colors.length)];
}

var xMin = Math.min.apply(Math, data.map(function(o) { return Math.min(o.x1, o.x2); }))
var xMax = Math.max.apply(Math, data.map(function(o) { return Math.max(o.x1, o.x2); }))

var yMin = Math.min.apply(Math, data.map(function(o) { return Math.min(o.y1, o.y2); }))
var yMax = Math.max.apply(Math, data.map(function(o) { return Math.max(o.y1, o.y2); }))

// X scale and Axis
var xScale = d3.scaleLinear()
    .domain([xMin, xMax])
    .range([0, width]);

// Y scale and Axis
var yScale = d3.scaleLinear()
    .domain([yMin, yMax])
    .range([0, height]);

svg.selectAll("rect")
    .data(data)
    .enter()
    .append("rect")
    .attr("x", d => xScale(d.x1))
    .attr("y", d => yScale(d.y1))
    .attr("width", d => xScale(d.x2) - xScale(d.x1))
    .attr("height", d => yScale(d.y2) - yScale(d.y1))
    .attr("fill", (d, i) => {
        if (colorScheme.toLowerCase() === 'none') {
            return getRandomWeightedColor();
        } else {
            return color(Math.random());
        }
    })
    .attr("stroke-width", $STROKE_WIDTH)
    .attr("stroke", $STROKE_COLOR);
MONDRIAN-END

#============================================================
# Mondrian code snippet accessor
#============================================================

our sub GetMondrianPart() {
    return $jsMondrianPart;
}

#============================================================
# Clock Gauge snippet
#============================================================

my $jsClockGauge = q:to/GAUGE-CLOCK/;
const radius = Math.min(width, height) / 2;

// Rescaling
svg = svg
    .attr("viewBox", `0 0 ${width} ${height}`)
    .append("g")
    .attr("transform", `translate(${width / 2}, ${height / 2})`);

const hour   = $HOUR;   //new Date().getHours();
const minute = $MINUTE; //new Date().getMinutes();
const second = $SECOND; //new Date().getSeconds();
const updateInterval = $UPDATE_INTERVAL; // Update, say, every second

//const scaleRanges = [[[20, 30], [0, 0.05]], [[30, 45], [0, 0.25]], [[45, 55], [0, 0.25]], [[55, 60], [0, 0.05]]];
const scaleRanges = $SCALE_RANGES;

const colorScheme = $COLOR_SCHEME; //"Tableau10";
const colorScale = createColorScale(colorScheme, scaleRanges.length);

function isSequentialScheme(schemeName) {
    const sequentialSchemes = [
        "Blues", "Greens", "Greys", "Oranges", "Purples", "Reds",
        "BuGn", "BuPu", "GnBu", "OrRd", "PuBuGn", "PuBu", "PuRd", "RdPu", "YlGnBu", "YlGn", "YlOrBr", "YlOrRd",
        "BrBG", "PRGn", "PiYG", "PuOr", "RdBu", "RdGy", "RdYlBu", "RdYlGn", "Spectral",
        "Cividis", "Viridis", "Inferno", "Magma", "Plasma", "Warm", "Cool", "CubehelixDefault", "Turbo",
        "Rainbow", "Sinebow"
    ];
    return sequentialSchemes.includes(schemeName);
}

function isCategoricalScheme(schemeName) {
    const categoricalSchemes = [
        "Observable10", "Category10", "Accent", "Dark2", "Paired", "Pastel1", "Pastel2", "Set1", "Set2", "Set3", "Tableau10"
    ];
    return categoricalSchemes.includes(schemeName);
}

function createColorScale(scheme, numCategories, start = $COLOR_SCHEME_INTERPOLATION_START, end = $COLOR_SCHEME_INTERPOLATION_END) {
    if (isSequentialScheme(scheme)) {
        //return d3.scaleSequential(d3[`interpolate${scheme}`]).domain([0, numCategories - 1]);
        const scale = d3.scaleSequential(d3[`interpolate${scheme}`]).domain([0, 1]);
        return function(i) { return scale(start + (end - start) * i / (numCategories - 1)) };
    } else if (isCategoricalScheme(scheme)) {
        return d3.scaleOrdinal(d3[`scheme${scheme}`]);
    } else {
        throw new Error("Unknown color scheme.");
    }
}

function isString(obj) {
  return typeof obj === 'string' || obj instanceof String;
}

function isListOfTwoStrings(obj) {
  return Array.isArray(obj) &&
         obj.length === 2 &&
         obj.every(item => isString(item));
}

var gaugeLabels = $GAUGE_LABELS;

function drawClock(hour, minute, second, gaugeLabels) {
    svg.selectAll("*").remove();

    svg.append("circle")
        .attr("r", radius)
        .attr("fill", $FILL_COLOR)
        .attr("stroke", $STROKE_COLOR)
        .attr("stroke-width", $STROKE_WIDTH);

    if (scaleRanges.length) {
        const arc = d3.arc()
            .innerRadius(d => radius - radius * Math.min(...d[1]))
            .outerRadius(d => radius - radius * Math.max(...d[1]))
            .startAngle(d => (d[0][0] * 2 * Math.PI) / 60)
            .endAngle(d => (d[0][1] * 2 * Math.PI) / 60);

        svg.selectAll("path")
            .data(scaleRanges)
            .enter()
            .append("path")
            .attr("d", arc)
            .each(function(d, i) {
                // Create a radial gradient for each arc
                var gradient = svg.append("defs")
                    .append("radialGradient")
                    .attr("id", "gradient" + i)
                    .attr("gradientUnits", "userSpaceOnUse")
                    .attr("cx", 0)
                    .attr("cy", 0)
                    .attr("r", radius);

                // Define the gradient stops along the radius
                if (isString(d[2]) && (isSequentialScheme(d[2]) || isCategoricalScheme(d[2])) ) {
                    var cf = createColorScale(d[2], 100);
                    const minRad = Math.min(...d[1]);
                    const maxRad = Math.max(...d[1]);
                    for (var j = 0; j <= 100; j++) {
                        const j2 = Math.round((minRad + j / 100 * (maxRad - minRad)) * 100);
                        if (d[1][0] < d[1][1]) {
                            gradient.append("stop")
                                .attr("offset", j + "%")
                                .attr("stop-color", cf(j2))
                                .attr("stop-opacity", 1);
                        } else {
                            gradient.append("stop")
                                .attr("offset", j + "%")
                                .attr("stop-color", cf(100-j2))
                                .attr("stop-opacity", 1);
                        }
                    }

                    // Apply the gradient to the current arc
                    d3.select(this)
                        .style("fill", "url(#gradient" + i + ")");

                } else if (isListOfTwoStrings(d[2])) {
                    gradient.append("stop")
                        .attr("offset",  Math.round((1-d[1][1]) * 100) + "%")
                        .attr("stop-color", d[2][1])
                        .attr("stop-opacity", 1);

                    gradient.append("stop")
                        .attr("offset", Math.round((1-d[1][0]) * 100) + "%")
                        .attr("stop-color", d[2][0])
                        .attr("stop-opacity", 1);

                    // Apply the gradient to the current arc
                    d3.select(this)
                        .style("fill", "url(#gradient" + i + ")");
                } else if (isString(d[2])) {
                    d3.select(this).attr("fill", d[2]);
                } else {
                    d3.select(this).attr("fill", colorScale(i));
                }
            });
    }

    // Draw ticks
    const ticks = svg.append("g").selectAll("line")
        .data(d3.range(0, 60)).enter()
        .append("line")
        .attr("x1", 0)
        .attr("y1", d => d % 5 === 0 ? -radius + 15 : -radius + 10)
        .attr("x2", 0)
        .attr("y2", -radius + 5)
        .attr("stroke", $STROKE_COLOR)
        .attr("stroke-width", d => d % 5 === 0 ? 2 : 1)
        .attr("transform", d => `rotate(${d * 6})`);

    // Draw numbers
    const numbers = svg.append("g").selectAll("text")
        .data(d3.range(1, 13)).enter()
        .append("text")
        .attr("x", d => Math.sin(d * Math.PI / 6) * (radius - 30))
        .attr("y", d => -Math.cos(d * Math.PI / 6) * (radius - 30) + 5)
        .attr("text-anchor", "middle")
        .attr("font-size", $TICK_LABELS_FONT_SIZE)
        .attr("fill", $TICK_LABELS_COLOR)
        .attr("font-family", $TICK_LABELS_FONT_FAMILY)
        .text(d => d);

    // Draw gauge labels (before the clock hands)
    const labelElements = svg.append("g").selectAll("text")
        .data(Object.entries(gaugeLabels)).enter()
        .append("text")
        .attr("x", d => typeof d[1] === 'object' ? d[1][0] * 2 * radius - radius : Math.sin(d[1] * Math.PI / 6) * (radius - 40))
        .attr("y", d => typeof d[1] === 'object' ? - d[1][1] * 2 * radius + radius : -Math.cos(d[1] * Math.PI / 6) * (radius - 40))
        .attr("text-anchor", "middle")
        .attr("font-size", $GAUGE_LABELS_FONT_SIZE)
        .attr("fill", $GAUGE_LABELS_COLOR)
        .attr("font-family", $GAUGE_LABELS_FONT_FAMILY)
        .text(d => d[0] === 'Value' ? `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}:${second.toString().padStart(2, '0')}` : d[0]);

    // Draw hour hand
    svg.append("line")
        .attr("x1", 0)
        .attr("y1", 0)
        .attr("x2", 0)
        .attr("y2", -radius + 8 / 15 * radius)
        .attr("stroke", $HOUR_HAND_COLOR)
        .attr("stroke-width", 4)
        .attr("transform", `rotate(${(hour % 12) * 30 + minute / 2})`);

    // Draw minute hand
    svg.append("line")
        .attr("x1", 0)
        .attr("y1", 0)
        .attr("x2", 0)
        .attr("y2", -radius + 4 / 15 * radius)
        .attr("stroke", $MINUTE_HAND_COLOR)
        .attr("stroke-width", 2)
        .attr("transform", `rotate(${minute * 6 + second / 10})`);

    // Draw second hand
    svg.append("line")
        .attr("x1", 0)
        .attr("y1", 0)
        .attr("x2", 0)
        .attr("y2", -radius + 2 / 15 * radius)
        .attr("stroke", $SECOND_HAND_COLOR)
        .attr("stroke-width", 1)
        .attr("transform", `rotate(${second * 6})`);
}

function updateClock() {
    //const now = new Date();
    //drawClock(now.getHours(), now.getMinutes(), now.getSeconds());
    drawClock($HOUR, $MINUTE, $SECOND, gaugeLabels);
}

drawClock(hour, minute, second, gaugeLabels);
setInterval(updateClock, updateInterval);
GAUGE-CLOCK

#============================================================
# Clock Gauge code snippet accessor
#============================================================

our sub GetClockGauge() {
    return $jsClockGauge;
}