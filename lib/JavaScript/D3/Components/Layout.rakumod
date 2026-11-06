unit module JavaScript::D3::Components::Layout;
use JavaScript::D3::CodeSnippets;
our sub margins-and-title(Str:D $format = 'jupyter') is export {
    JavaScript::D3::CodeSnippets::GetPlotMarginsAndTitle($format)
}
our sub margins-title-and-labels(Str:D $format = 'jupyter') is export {
    JavaScript::D3::CodeSnippets::GetPlotMarginsTitleAndLabelsCode($format)
}
