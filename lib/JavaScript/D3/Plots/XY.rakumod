unit module JavaScript::D3::Plots::XY;
need JavaScript::D3::Plots;
our sub ListPlot($data, *%args) is export { JavaScript::D3::Plots::ListPlot($data, |%args) }
our sub ListLinePlot($data, *%args) is export { JavaScript::D3::Plots::ListLinePlot($data, |%args) }
