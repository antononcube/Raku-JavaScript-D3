use v6.d;

use JSON::Fast;
use JavaScript::D3::Plots;
use JavaScript::D3::Predicates;

unit module JavaScript::D3::Charts;

#============================================================
# JavaScript chart template parts
#============================================================
my $jsChartPreparation = q:to/END/;
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

END

my $jsChartEnding = q:to/END/;
}) })(element);
END

#============================================================
# BarChart
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

#| Makes a bar chart for a list of numbers or a hash with numeric values.
our proto BarChart($data, |) is export {*}

our multi BarChart($data where $data ~~ Seq, *%args) {
    return BarChart($data.List, |%args);
}

our multi BarChart($data where $data ~~ Positional && $data.all ~~ Numeric, *%args) {
    my $k = 1;
    my @dataPairs = |$data.map({ <Label Value> Z=> ($k++, $_) })>>.Hash;
    return BarChart(@dataPairs, |%args);
}

our multi BarChart(%data, *%args) {
    my @dataPairs = %data.map({ %(Label => $_.key, Value => $_.value) }).Array;
    return BarChart(@dataPairs, |%args);
}

our multi BarChart(@data where @data.all ~~ Map,
                   Str :$background= 'white',
                   Str :$color= 'steelblue',
                   :$width = 600,
                   :$height = 400,
                   Str :plot-label(:$title) = '',
                   Str :$x-axis-label = '',
                   Str :$y-axis-label = '',
                   :$grid-lines is copy = False,
                   :$margins is copy = Whatever,
                   Str :$format = 'jupyter'
                   ) {
    my $jsData = to-json(@data, :!pretty);

    # Grid lines
    $grid-lines = JavaScript::D3::Plots::ProcessGridLines($grid-lines);

    # Margins
    $margins = JavaScript::D3::Plots::ProcessMargins($margins);

    # Stencil code
    my $jsChart = [JavaScript::D3::Plots::GetPlotStartingCode($format),
                   JavaScript::D3::Plots::GetPlotMarginsAndLabelsCode($format),
                   JavaScript::D3::Plots::GetPlotDataAndScalesCode(|$grid-lines, $jsBarChartPart),
                   JavaScript::D3::Plots::GetPlotEndingCode($format)].join("\n");

    # Concrete values
    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
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
# Histogram
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

#| Makes a histogram for a list of numbers.
our proto Histogram($data, |) is export {*}

our multi Histogram($data where $data ~~ Seq, *%args) {
    return Histogram($data.List, |%args);
}

our multi Histogram(@data where @data.all ~~ Numeric,
                    Str :$background= 'white',
                    Str :$color= 'steelblue',
                    :$width = 600,
                    :$height = 400,
                    Str :plot-label(:$title) = '',
                    Str :$x-axis-label = '',
                    Str :$y-axis-label = '',
                    :$grid-lines is copy = False,
                    :$margins is copy = Whatever,
                    Str :$format = 'jupyter'
                    ) {
    my $jsData = to-json(@data, :!pretty);

    # Grid lines
    $grid-lines = JavaScript::D3::Plots::ProcessGridLines($grid-lines);

    # Margins
    $margins = JavaScript::D3::Plots::ProcessMargins($margins);

    # Stencil code
    my $jsChart = [JavaScript::D3::Plots::GetPlotStartingCode($format),
                   JavaScript::D3::Plots::GetPlotMarginsAndLabelsCode($format),
                   JavaScript::D3::Plots::GetPlotDataAndScalesCode(|$grid-lines, $jsHistogramPart),
                   JavaScript::D3::Plots::GetPlotEndingCode($format)].join("\n");

    # Concrete values
    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
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
# BubbleChart
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

#| Makes a bubble chart for list of triplets..
our proto BubbleChart($data, |) is export {*}

our multi BubbleChart($data where $data ~~ Seq, *%args) {
    return BubbleChart($data.List, |%args);
}

our multi BubbleChart($data where is-positional-of-lists($data, 3), *%args) {
    my @data2 = $data.map({ %( <x y z>.Array Z=> $_.Array) });
    return BubbleChart(@data2, |%args);
}

our multi BubbleChart($data where is-positional-of-lists($data, 2), *%args) {
    return BubbleChart($data.map({ [|$_, 1] }), |%args);
}

our multi BubbleChart(@data is copy where @data.all ~~ Map,
                      Str :$background= 'white',
                      Str :$color= 'steelblue',
                      Numeric :$opacity = 0.7,
                      :$width = 600,
                      :$height = 600,
                      Str :plot-label(:$title) = '',
                      Str :$x-axis-label = '',
                      Str :$y-axis-label = '',
                      :$grid-lines is copy = False,
                      :$margins is copy = Whatever,
                      :$tooltip = Whatever,
                      :$legends = Whatever,
                      Str :$format = 'jupyter'
                      ) {
    # Grid lines
    $grid-lines = JavaScript::D3::Plots::ProcessGridLines($grid-lines);

    # Margins
    $margins = JavaScript::D3::Plots::ProcessMargins($margins);

    # Groups
    my Bool $hasGroups = [&&] @data.map({ so $_<group> });

    # Select code fragment to splice in
    my $jsChartMiddle = do given $tooltip {
        when ($_.isa(Whatever) || $_ ~~ Bool && $_) && $hasGroups {
            $jsTooltipMultiBubbleChartPart
        }
        when $_ ~~ Bool && !$_ && $hasGroups {
            $jsMultiBubbleChartPart
        }
        when $_ ~~ Bool && $_ && !$hasGroups {
            @data = @data.map({ $_.push(group=>'All') });
            $jsTooltipMultiBubbleChartPart
        }
        default { $jsBubbleChartPart }
    }

    # Chose to add legend code fragment or not
    my $maxGroupChars = $hasGroups ?? @data.map(*<group>).unique>>.chars.max !! 'all'.chars;
    given $legends {
        when $_ ~~ Bool && $_ || $_.isa(Whatever) && $hasGroups {
            $margins<right> = max($margins<right>, ($maxGroupChars + 4) * 12);
            $jsChartMiddle ~=  "\n" ~ JavaScript::D3::Plots::GetLegendCode
        }
    }

    my $jsChart = [JavaScript::D3::Plots::GetPlotPreparationCode($format, |$grid-lines),
                   $jsChartMiddle,
                   JavaScript::D3::Plots::GetPlotEndingCode($format)].join("\n");

    my $jsData = to-json(@data, :!pretty);

    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
            .subst(:g, '$OPACITY', '"' ~ $opacity ~ '"')
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
        $res = $res.subst('element.get(0)', '"#my_dataviz"'):g;
    }

    return $res;
}

#============================================================
# HexbinChart
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

#| Makes a bin 2D chart.
our proto Bin2DChart($data, |) is export {*}

our multi Bin2DChart($data where $data ~~ Seq, *%args) {
    return Bin2DChart($data.List, |%args);
}

our multi Bin2DChart(@data where @data.all ~~ List, *%args) {
    my @data2 = @data.map({ %( <x y>.Array Z=> $_.Array) });
    return Bin2DChart(@data2, |%args);
}

our multi Bin2DChart(@data where @data.all ~~ Map,
                     Str :$background= 'white',
                     Str :$color= 'steelblue',
                     :$width = 600,
                     :$height = 600,
                     Str :plot-label(:$title) = '',
                     Str :$x-axis-label = '',
                     Str :$y-axis-label = '',
                     :$grid-lines is copy = False,
                     :$margins is copy = Whatever,
                     :$method is copy = Whatever,
                     Str :$format = 'jupyter'
                     ) {
    my $jsData = to-json(@data, :!pretty);

    $margins = JavaScript::D3::Plots::ProcessMargins($margins);

    if $method.isa(Whatever) {
        $method = 'rectbin';
    }
    die 'The argument method is expected to be one of \'rectbin\', \'hexbin\', or Whatever'
    unless $method ~~ Str && $method ∈ <rect rectangle rectbin hex hexagon hexbin>;

    my $jsChart = [JavaScript::D3::Plots::GetPlotPreparationCode($format),
                   $method eq 'rectbin' ?? $jsRectbinChartPart !! $jsHexbinChartPart,
                   JavaScript::D3::Plots::GetPlotEndingCode($format)].join("\n");

    my $res = $jsChart
            .subst('$DATA', $jsData)
            .subst('$BACKGROUND_COLOR', '"' ~ $background ~ '"')
            .subst('$FILL_COLOR', '"' ~ $color ~ '"')
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