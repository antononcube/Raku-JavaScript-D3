unit module JavaScript::D3::Visualizations::Images;
need JavaScript::D3::Images;
our sub Image(|c) is export { JavaScript::D3::Images::Image(|c) }
our sub ImageDisplay(|c) is export { JavaScript::D3::Images::ImageDisplay(|c) }
