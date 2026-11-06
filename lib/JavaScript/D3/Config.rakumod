unit module JavaScript::D3::Config;

my $d3_config = q:to/END/;
require.config({
     paths: {
     d3: 'https://d3js.org/d3.v$VER.min'
}});

require(['d3'], function(d3) {
     console.log(d3);
});
END

my $d3_config_3d = q:to/END/;
require.config({
  paths: {
    d3: "https://d3js.org/d3.v7.min",
    d3_3d: "https://unpkg.com/d3-3d@2.0.2/build/d3-3d"
  }
});

require(["d3", "d3_3d"], function(d3, d3_3d) {
  window.d3 = d3;
  window.d33d = d3_3d || window.d33d || {};
  console.log("d3:", d3.version, "d3_3d:", Object.keys(window.d33d));
});
END

#| JavaScript to prime a Jupyter frontend with D3.
our sub config(:v(:$d3-version) = 7, :v3d(:$d33d-version) = '2.0.2',
               Bool:D :$direct = True, Bool:D :$with-d33d = True) is export {
    my $code = $with-d33d ?? $d3_config_3d !! $d3_config;
    return $code.subst('$VER', $d3-version).subst('$VER_D33D', $d33d-version) if $direct;

    # A non-direct configuration is itself a Jupyter JavaScript cell.
    '(function(element) { require([\'d3\'], function(d3) {' ~ "\n"
        ~ $d3_config.subst('$VER', $d3-version).subst('$VER3D', $d33d-version)
        ~ "\n}) })(element);";
}
