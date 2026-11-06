unit module JavaScript::D3::Components::Axes;
use JavaScript::D3::CodeSnippets;
our sub scales(Str:D :$x-axis-scale = 'linear', Str:D :$y-axis-scale = 'linear') is export {
    JavaScript::D3::CodeSnippets::GetPlotDataAndScalesCode(:$x-axis-scale, :$y-axis-scale)
}
our sub scales-and-axes(|c) is export { JavaScript::D3::CodeSnippets::GetPlotDataScalesAndAxesCode(|c) }
