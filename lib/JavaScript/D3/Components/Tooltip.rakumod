unit module JavaScript::D3::Components::Tooltip;
use JavaScript::D3::CodeSnippets;
our sub definition(|c) is export { JavaScript::D3::CodeSnippets::GetTooltipPart(|c) }
our sub mouse-handlers() is export { JavaScript::D3::CodeSnippets::GetTooltipMousePart() }
