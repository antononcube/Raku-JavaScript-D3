unit module JavaScript::D3::Templates::XY;
use JavaScript::D3::CodeSnippets;
our sub scatter() is export { JavaScript::D3::CodeSnippets::GetScatterPlotPart() }
our sub line(Bool:D :$filled = False) is export { JavaScript::D3::CodeSnippets::GetPathPlotPart(:$filled) }
