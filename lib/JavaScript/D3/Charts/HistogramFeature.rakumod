unit module JavaScript::D3::Charts::HistogramFeature;
need JavaScript::D3::Charts;
our proto sub Histogram(|) is export {*}
multi sub Histogram($data, *%args) { JavaScript::D3::Charts::Histogram($data, |%args) }
multi sub Histogram($data, $number-of-bins, *%args) {
    JavaScript::D3::Charts::Histogram($data, $number-of-bins, |%args)
}
