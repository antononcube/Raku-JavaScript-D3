use v6.d;

unit module JavaScript::D3::CodeSnippets3D;

use JavaScript::D3::Utilities;

#============================================================
# ListPlot3D code snippets
#============================================================
my $jsMultiTrajectoryPlotPart = q:to/END/;
function render3DTrajectory(d33dModule, width, height) {
  var d33d = d33dModule || window.d33d || {};
  var lineStrips3D = d33d.lineStrips3D;
  var points3D = d33d.points3D;
  var lines3D = d33d.lines3D;

  if (!lineStrips3D || !points3D || !lines3D) {
    d3.select(element.get(0))
      .append("div")
      .style("color", "#b00020")
      .style("font-family", "sans-serif")
      .style("padding", "8px")
      .text("d3-3d is not loaded. Prime notebook first with require.config for d3_3d.");
    return;
  }

  var host = d3.select(element.get(0));
  host.html("");

  function asNumberTriplet(value, fallback) {
    if (!Array.isArray(value) || value.length !== 3) {
      return fallback.slice();
    }
    var out = [];
    for (var i = 0; i < 3; i++) {
      var n = Number(value[i]);
      out.push(isFinite(n) ? n : fallback[i]);
    }
    return out;
  }

  var boxRatios = asNumberTriplet($BOX_RATIOS, [1, 1, 0.4]).map(function(v) {
    return Math.max(1e-9, Math.abs(v));
  });

  var origin = { x: width / 2, y: height / 2 };
  var showAxes = $AXES;
  var showBoxed = $BOXED;
  var showTicks = $TICKS;
  var minScale = 1;
  var maxScale = 1;
  var scale = 1;
  var angleX = 1.35;
  var angleY = 0.15;
  var angleZ = 0;

  // Toggle point projection mode:
  // true  -> manual projection (rotates points correctly)
  // false -> library points3D() projection
  var USE_MANUAL_POINT_PROJECTION = true;

  host
    .append("div")
    .style("font-family", "Arial, sans-serif")
    .style("font-size", "$TITLE_FONT_SIZEpx")
    .style("line-height", "1.35")
    .style("margin-bottom", "8px")
    .html($TITLE);

  var svg = host
    .append("svg")
    .attr("width", width)
    .attr("height", height)
    .style("display", "block")
    .style("background", $BACKGROUND_COLOR)
    .style("cursor", "grab");

  // Replace this with your own input array of dicts.
  // Assume all dictionaries within a group share the same `type`.
  var data = $DATA;

  var xMin = Math.min.apply(Math, data.map(function(o) { return o.x; }))
  var xMax = Math.max.apply(Math, data.map(function(o) { return o.x; }))
  var yMin = Math.min.apply(Math, data.map(function(o) { return o.y; }))
  var yMax = Math.max.apply(Math, data.map(function(o) { return o.y; }))
  var zMin = Math.min.apply(Math, data.map(function(o) { return o.z; }))
  var zMax = Math.max.apply(Math, data.map(function(o) { return o.z; }))

  var xMid = 0.5 * (xMin + xMax);
  var yMid = 0.5 * (yMin + yMax);
  var zMid = 0.5 * (zMin + zMax);
  var xHalfSpan = Math.max(1e-9, 0.5 * (xMax - xMin));
  var yHalfSpan = Math.max(1e-9, 0.5 * (yMax - yMin));
  var zHalfSpan = Math.max(1e-9, 0.5 * (zMax - zMin));

  function applyBoxRatios(o) {
    return {
      x: ((o.x - xMid) / xHalfSpan) * 10 * boxRatios[0],
      y: ((o.y - yMid) / yHalfSpan) * 10 * boxRatios[1],
      z: ((o.z - zMid) / zHalfSpan) * 10 * boxRatios[2]
    };
  }

  function mapXValueToScene(v) {
    return ((v - xMid) / xHalfSpan) * 10 * boxRatios[0];
  }

  function mapYValueToScene(v) {
    return ((v - yMid) / yHalfSpan) * 10 * boxRatios[1];
  }

  function mapZValueToScene(v) {
    return ((v - zMid) / zHalfSpan) * 10 * boxRatios[2];
  }

  function makeAxes(ratios) {
    return [
      [{ x: -10 * ratios[0], y: 0, z: 0 }, { x: 10 * ratios[0], y: 0, z: 0 }],
      [{ x: 0, y: -10 * ratios[1], z: 0 }, { x: 0, y: 10 * ratios[1], z: 0 }],
      [{ x: 0, y: 0, z: -10 * ratios[2] }, { x: 0, y: 0, z: 10 * ratios[2] }]
    ];
  }

  function makeBoundingBoxEdges(ratios) {
    var rx = 10 * ratios[0];
    var ry = 10 * ratios[1];
    var rz = 10 * ratios[2];
    var corners = [
      { x: -rx, y: -ry, z: -rz }, // 0
      { x:  rx, y: -ry, z: -rz }, // 1
      { x:  rx, y:  ry, z: -rz }, // 2
      { x: -rx, y:  ry, z: -rz }, // 3
      { x: -rx, y: -ry, z:  rz }, // 4
      { x:  rx, y: -ry, z:  rz }, // 5
      { x:  rx, y:  ry, z:  rz }, // 6
      { x: -rx, y:  ry, z:  rz }  // 7
    ];
    var edgePairs = [
      [0, 1], [1, 2], [2, 3], [3, 0],
      [4, 5], [5, 6], [6, 7], [7, 4],
      [0, 4], [1, 5], [2, 6], [3, 7]
    ];
    return edgePairs.map(function(e) {
      return { a: corners[e[0]], b: corners[e[1]] };
    });
  }

  function makeAxisTicks(ratios) {
    var xValues = d3.ticks(xMin, xMax, 4);
    var yValues = d3.ticks(yMin, yMax, 4);
    var zValues = d3.ticks(zMin, zMax, 4);
    if (!xValues.length) { xValues = [xMin]; }
    if (!yValues.length) { yValues = [yMin]; }
    if (!zValues.length) { zValues = [zMin]; }

    var tickSize = 0.35;
    var labelOffset = 1.1;
    var tickFormat = d3.format(".4~g");
    var segments = [];
    var labels = [];

    for (var i = 0; i < xValues.length; i++) {
      var xValue = xValues[i];
      var x = mapXValueToScene(xValue);
      segments.push({
        a: { x: x, y: -tickSize, z: 0 },
        b: { x: x, y: tickSize, z: 0 }
      });
      labels.push({
        p: { x: x, y: -labelOffset, z: 0 },
        text: tickFormat(xValue)
      });
    }

    for (var j = 0; j < yValues.length; j++) {
      var yValue = yValues[j];
      var y = mapYValueToScene(yValue);
      segments.push({
        a: { x: -tickSize, y: y, z: 0 },
        b: { x: tickSize, y: y, z: 0 }
      });
      labels.push({
        p: { x: labelOffset, y: y, z: 0 },
        text: tickFormat(yValue)
      });
    }

    for (var k = 0; k < zValues.length; k++) {
      var zValue = zValues[k];
      var z = mapZValueToScene(zValue);
      segments.push({
        a: { x: -tickSize, y: 0, z: z },
        b: { x: tickSize, y: 0, z: z }
      });
      labels.push({
        p: { x: labelOffset, y: 0, z: z },
        text: tickFormat(zValue)
      });
    }

    return { segments: segments, labels: labels };
  }

  function makeBoxTicks(ratios) {
    var rx = 10 * ratios[0];
    var ry = 10 * ratios[1];
    var rz = 10 * ratios[2];
    var xValues = d3.ticks(xMin, xMax, 4);
    var yValues = d3.ticks(yMin, yMax, 4);
    var zValues = d3.ticks(zMin, zMax, 4);
    if (!xValues.length) { xValues = [xMin]; }
    if (!yValues.length) { yValues = [yMin]; }
    if (!zValues.length) { zValues = [zMin]; }

    var tickSize = 0.35;
    var labelOffset = 1.1;
    var tickFormat = d3.format(".4~g");
    var segments = [];
    var labels = [];

    // x-axis ticks on bottom-front box edge (y=-ry, z=-rz)
    for (var i = 0; i < xValues.length; i++) {
      var xValue = xValues[i];
      var x = mapXValueToScene(xValue);
      segments.push({
        a: { x: x, y: -ry, z: -rz },
        b: { x: x, y: -ry, z: -rz + tickSize }
      });
      labels.push({
        p: { x: x, y: -ry, z: -rz - labelOffset },
        text: tickFormat(xValue)
      });
    }

    // y-axis ticks on right-front box edge (x=rx, z=-rz)
    for (var j = 0; j < yValues.length; j++) {
      var yValue = yValues[j];
      var y = mapYValueToScene(yValue);
      segments.push({
        a: { x: rx, y: y, z: -rz },
        b: { x: rx, y: y, z: -rz + tickSize }
      });
      labels.push({
        p: { x: rx + labelOffset, y: y, z: -rz },
        text: tickFormat(yValue)
      });
    }

    // z-axis ticks on right-bottom box edge (x=rx, y=-ry)
    for (var k = 0; k < zValues.length; k++) {
      var zValue = zValues[k];
      var z = mapZValueToScene(zValue);
      segments.push({
        a: { x: rx, y: -ry, z: z },
        b: { x: rx, y: -ry + tickSize, z: z }
      });
      labels.push({
        p: { x: rx + labelOffset, y: -ry, z: z },
        text: tickFormat(zValue)
      });
    }

    return { segments: segments, labels: labels };
  }

  var axes = makeAxes(boxRatios);
  var axisTicks = makeAxisTicks(boxRatios);
  var boxTicks = makeBoxTicks(boxRatios);
  var boxEdges = makeBoundingBoxEdges(boxRatios);
  var sceneRadiusSq = 0;

  function includeRadiusPoint(p) {
    var r2 = p.x * p.x + p.y * p.y + p.z * p.z;
    if (r2 > sceneRadiusSq) {
      sceneRadiusSq = r2;
    }
  }

  for (var a = 0; a < axes.length; a++) {
    includeRadiusPoint(axes[a][0]);
    includeRadiusPoint(axes[a][1]);
  }
  for (var be = 0; be < boxEdges.length; be++) {
    includeRadiusPoint(boxEdges[be].a);
    includeRadiusPoint(boxEdges[be].b);
  }

  // Compatibility grouping (avoids d3.group/Array.prototype.flatMap requirements)
  var groupsByName = {};
  var groupOrder = [];
  for (var p = 0; p < data.length; p++) {
    var item = data[p];
    var gname = item.group;
    if (!groupsByName[gname]) {
      groupsByName[gname] = { group: gname, values: [], type: String(item.type || "line").toLowerCase() };
      groupOrder.push(gname);
    }
    var scenePoint = applyBoxRatios(item);
    includeRadiusPoint(scenePoint);
    groupsByName[gname].values.push(scenePoint);
  }

  var sceneRadius = Math.max(1e-9, Math.sqrt(sceneRadiusSq));
  var paddingPx = 24;
  var availableRadiusPx = Math.max(8, 0.5 * Math.min(width, height) - paddingPx);
  var fitScale = availableRadiusPx / sceneRadius;

  // Rotation-safe fit: at this scale (or smaller), all points remain in view.
  maxScale = fitScale;
  minScale = fitScale * 0.2;
  scale = fitScale;

  var grouped = [];
  for (var gi = 0; gi < groupOrder.length; gi++) {
    grouped.push(groupsByName[groupOrder[gi]]);
  }

  var palette = (d3.schemeTableau10 || d3.schemeSet2 || d3.schemeCategory10 || [
    "#4e79a7", "#f28e2b", "#e15759", "#76b7b2", "#59a14f",
    "#edc948", "#b07aa1", "#ff9da7", "#9c755f", "#bab0ab"
  ]);
  var color = d3.scaleOrdinal().domain(groupOrder).range(palette);

  var lineGroups = [];
  var pointGroups = [];
  for (var g = 0; g < grouped.length; g++) {
    if (grouped[g].type === "point") {
      pointGroups.push(grouped[g]);
    } else {
      lineGroups.push(grouped[g]);
    }
  }

  var pointData = [];
  for (var pg = 0; pg < pointGroups.length; pg++) {
    for (var pv = 0; pv < pointGroups[pg].values.length; pv++) {
      var pointItem = pointGroups[pg].values[pv];
      pointData.push({
        x: pointItem.x,
        y: pointItem.y,
        z: pointItem.z,
        group: pointGroups[pg].group,
        type: pointGroups[pg].type
      });
    }
  }

  var strip3d = lineStrips3D()
    .x(function(d) { return d.x; })
    .y(function(d) { return d.y; })
    .z(function(d) { return d.z; })
    .origin(origin)
    .scale(scale)
    .rotateX(angleX)
    .rotateY(angleY);

  var pts3d = points3D()
    .x(function(d) { return d.x; })
    .y(function(d) { return d.y; })
    .z(function(d) { return d.z; })
    .origin(origin)
    .scale(scale)
    .rotateX(angleX)
    .rotateY(angleY);

  var ax3d = lines3D()
    .x(function(d) { return d.x; })
    .y(function(d) { return d.y; })
    .z(function(d) { return d.z; })
    .origin(origin)
    .scale(scale)
    .rotateX(angleX)
    .rotateY(angleY);

  function syncProjectors() {
    strip3d.origin(origin).scale(scale).rotateX(angleX).rotateY(angleY);
    pts3d.origin(origin).scale(scale).rotateX(angleX).rotateY(angleY);
    ax3d.origin(origin).scale(scale).rotateX(angleX).rotateY(angleY);
  }

  function rotateX3d(p, a) {
    var s = Math.sin(a);
    var c = Math.cos(a);
    return { x: p.x, y: p.y * c - p.z * s, z: p.y * s + p.z * c };
  }

  function rotateY3d(p, a) {
    var s = Math.sin(a);
    var c = Math.cos(a);
    return { x: p.z * s + p.x * c, y: p.y, z: p.z * c - p.x * s };
  }

  function rotateZ3d(p, a) {
    var s = Math.sin(a);
    var c = Math.cos(a);
    return { x: p.x * c - p.y * s, y: p.x * s + p.y * c, z: p.z };
  }

  function manualProjectPoint(d) {
    var afterZ = rotateZ3d({ x: d.x, y: d.y, z: d.z }, angleZ);
    var afterY = rotateY3d(afterZ, angleY);
    var rotated = rotateX3d(afterY, angleX);

    return {
      x: d.x,
      y: d.y,
      z: d.z,
      group: d.group,
      type: d.type,
      rotated: rotated,
      projected: {
        x: origin.x + scale * rotated.x,
        y: origin.y + scale * rotated.y
      }
    };
  }

  function draw() {
    syncProjectors();

    if (showAxes) {
      var transformedAxes = ax3d.data(axes);

      svg.selectAll("line.axis")
        .data(transformedAxes)
        .join("line")
        .attr("class", "axis")
        .attr("stroke-width", 2)
        .attr("fill", "none")
        .attr("stroke", "#888")
        .attr("x1", function(d) { return d[0].projected.x; })
        .attr("y1", function(d) { return d[0].projected.y; })
        .attr("x2", function(d) { return d[1].projected.x; })
        .attr("y2", function(d) { return d[1].projected.y; });

      if (showTicks) {
        var axisLabels = [
          { text: "X", x: transformedAxes[0][1].projected.x, y: transformedAxes[0][1].projected.y },
          { text: "Y", x: transformedAxes[1][1].projected.x, y: transformedAxes[1][1].projected.y },
          { text: "Z", x: transformedAxes[2][1].projected.x, y: transformedAxes[2][1].projected.y }
        ];

        svg.selectAll("text.axis-label")
          .data(axisLabels)
          .join("text")
          .attr("class", "axis-label")
          .attr("font-size", 14)
          .attr("font-weight", "bold")
          .attr("fill", "#666")
          .attr("x", function(d) { return d.x + 8; })
          .attr("y", function(d) { return d.y - 8; })
          .text(function(d) { return d.text; });

        var projectedTickSegments = axisTicks.segments.map(function(s) {
          return {
            a: manualProjectPoint(s.a).projected,
            b: manualProjectPoint(s.b).projected
          };
        });

        svg.selectAll("line.axis-tick")
          .data(projectedTickSegments)
          .join("line")
          .attr("class", "axis-tick")
          .attr("stroke-width", 1)
          .attr("stroke", "#777")
          .attr("x1", function(d) { return d.a.x; })
          .attr("y1", function(d) { return d.a.y; })
          .attr("x2", function(d) { return d.b.x; })
          .attr("y2", function(d) { return d.b.y; });

        var projectedTickLabels = axisTicks.labels.map(function(l) {
          return {
            text: l.text,
            projected: manualProjectPoint(l.p).projected
          };
        });

        svg.selectAll("text.axis-tick-label")
          .data(projectedTickLabels)
          .join("text")
          .attr("class", "axis-tick-label")
          .attr("font-size", 10)
          .attr("fill", "#777")
          .attr("x", function(d) { return d.projected.x; })
          .attr("y", function(d) { return d.projected.y; })
          .attr("text-anchor", "middle")
          .text(function(d) { return d.text; });
      } else {
        svg.selectAll("text.axis-label").remove();
        svg.selectAll("line.axis-tick").remove();
        svg.selectAll("text.axis-tick-label").remove();
      }
    } else {
      svg.selectAll("line.axis").remove();
      svg.selectAll("text.axis-label").remove();
      svg.selectAll("line.axis-tick").remove();
      svg.selectAll("text.axis-tick-label").remove();
    }

    if (showBoxed) {
      var projectedBoxEdges = boxEdges.map(function(e) {
        return {
          a: manualProjectPoint(e.a).projected,
          b: manualProjectPoint(e.b).projected
        };
      });

      svg.selectAll("line.bounding-box")
        .data(projectedBoxEdges)
        .join("line")
        .attr("class", "bounding-box")
        .attr("stroke-width", 1)
        .attr("stroke", "#999")
        .attr("fill", "none")
        .attr("x1", function(d) { return d.a.x; })
        .attr("y1", function(d) { return d.a.y; })
        .attr("x2", function(d) { return d.b.x; })
        .attr("y2", function(d) { return d.b.y; });

      if (showTicks) {
        var projectedBoxTickSegments = boxTicks.segments.map(function(s) {
          return {
            a: manualProjectPoint(s.a).projected,
            b: manualProjectPoint(s.b).projected
          };
        });

        svg.selectAll("line.box-tick")
          .data(projectedBoxTickSegments)
          .join("line")
          .attr("class", "box-tick")
          .attr("stroke-width", 1)
          .attr("stroke", "#777")
          .attr("x1", function(d) { return d.a.x; })
          .attr("y1", function(d) { return d.a.y; })
          .attr("x2", function(d) { return d.b.x; })
          .attr("y2", function(d) { return d.b.y; });

        var projectedBoxTickLabels = boxTicks.labels.map(function(l) {
          return {
            text: l.text,
            projected: manualProjectPoint(l.p).projected
          };
        });

        svg.selectAll("text.box-tick-label")
          .data(projectedBoxTickLabels)
          .join("text")
          .attr("class", "box-tick-label")
          .attr("font-size", 10)
          .attr("fill", "#777")
          .attr("x", function(d) { return d.projected.x; })
          .attr("y", function(d) { return d.projected.y; })
          .attr("text-anchor", "middle")
          .text(function(d) { return d.text; });
      } else {
        svg.selectAll("line.box-tick").remove();
        svg.selectAll("text.box-tick-label").remove();
      }
    } else {
      svg.selectAll("line.bounding-box").remove();
      svg.selectAll("line.box-tick").remove();
      svg.selectAll("text.box-tick-label").remove();
    }

    var lineInput = [];
    for (var li = 0; li < lineGroups.length; li++) {
      lineInput.push(lineGroups[li].values);
    }
    var transformedLineStrips = strip3d.data(lineInput);

    var lineRenderData = [];
    for (var lr = 0; lr < transformedLineStrips.length; lr++) {
      lineRenderData.push({ strip: transformedLineStrips[lr], group: lineGroups[lr].group });
    }

    svg.selectAll("path.trajectory")
      .data(lineRenderData)
      .join("path")
      .attr("class", "trajectory")
      .attr("fill", "none")
      .attr("stroke", function(d) { return color(d.group); })
      .attr("stroke-width", 3)
      .attr("stroke-linejoin", "round")
      .attr("stroke-linecap", "round")
      .attr("d", function(d) { return strip3d.draw(d.strip); });

    var transformedPoints = USE_MANUAL_POINT_PROJECTION
      ? pointData.map(function(d) { return manualProjectPoint(d); })
      : pts3d.data(pointData);

    svg.selectAll("circle.point")
      .data(transformedPoints)
      .join("circle")
      .attr("class", "point")
      .attr("fill", function(d) { return color(d.group); })
      .attr("stroke", "black")
      .attr("stroke-width", 0.4)
      .attr("cx", function(d) { return d.projected.x; })
      .attr("cy", function(d) { return d.projected.y; })
      .attr("r", function(d) { return Math.max(1.8, 3.4 + 0.02 * d.rotated.z); });

    svg.selectAll("text.legend")
      .data(grouped)
      .join("text")
      .attr("class", "legend")
      .attr("x", 12)
      .attr("y", function(d, i) { return 20 + i * 18; })
      .attr("font-size", 12)
      .attr("fill", function(d) { return color(d.group); })
      .text(function(d) { return d.group + " (" + d.type + ")"; });
  }

  draw();

  var startX = 0;
  var startY = 0;
  var startAngleX = angleX;
  var startAngleY = angleY;

  svg.call(
    d3.drag()
      .on("start", function(event) {
        svg.style("cursor", "grabbing");
        startX = event.x;
        startY = event.y;
        startAngleX = angleX;
        startAngleY = angleY;
      })
      .on("drag", function(event) {
        var dx = event.x - startX;
        var dy = event.y - startY;
        angleY = startAngleY + dx * 0.01;
        angleX = startAngleX - dy * 0.01;
        draw();
      })
      .on("end", function() {
        svg.style("cursor", "grab");
      })
  );

  svg.on("wheel", function(event) {
    event.preventDefault();
    var factor = event.deltaY > 0 ? 0.92 : 1.08;
    scale = Math.max(minScale, Math.min(maxScale, scale * factor));
    draw();
  });
}

if (window.d33d && window.d33d.lineStrips3D) {
  render3DTrajectory(window.d33d, $WIDTH, $HEIGHT);
  return;
}
END

#============================================================
# ListPlot3D code snippets accessors
#============================================================

our sub GetMultiTrajectoryPlotPart() {
    return $jsMultiTrajectoryPlotPart;
}
