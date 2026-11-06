unit module JavaScript::D3::Charts::Bar;
need JavaScript::D3::Charts;
our sub BarChart($data, *%args) is export { JavaScript::D3::Charts::BarChart($data, |%args) }
