use v6.d;

# Comprehensive type checking is needed in order the JavaScript::D3 functions to work well.
# Using the type system of "Data::Reshapers",  would be ideal,
# but I do not want to introduce such a "heavy" dependency.
# Hence, I copied functions of Data::Reshapers::Predicates here.
# (And made relevant changes and additions.)

unit module JavaScript::D3::Predicates;

#------------------------------------------------------------
# From gfldex over Discord #raku channel.
#| Returns True if the argument is a list of hashes or lists that have the same number of elements.
multi has-homogeneous-shape($l) is export {
   so $l[*].&{ $_».elems.all == $_[0].elems }
}

multi has-homogeneous-shape(@l where $_.all ~~ Pair) is export {
   has-homogeneous-shape(@l.map({ .values }))
}

#------------------------------------------------------------
#| Returns True if the argument is a list of hashes and all hashes have the same keys.
sub has-homogeneous-keys(\l) is export {
   l[0].isa(Hash) and so l[*].&{ $_».keys».sort.all == $_[0].keys.sort }
}

#------------------------------------------------------------
#| Returns True if the argument is a positional of Hashes and the value types of all hashes are the same.
sub has-homogeneous-hash-types(\l) is export {
   l[0].isa(Hash) and so l[*].&{ $_.map({ $_.values.map({ $_.^name }) }).all == $_[0].values.map({ $_.^name }) }
}

#------------------------------------------------------------
#| Returns True if the argument is a list of lists and the element types of all lists are the same.
sub has-homogeneous-array-types(\l) is export {
   (l[0].isa(Positional) or l[0].isa(Array)) and so l[*].&{ $_.map({ $_.map({ $_.^name }) }).all == $_[0].map({ $_.^name }) }
}

#------------------------------------------------------------
sub is-array-of-key-array-pairs(@arr) is export {
   ( [and] @arr.map({ is-key-array-pair($_) }) ) and has-homogeneous-shape(@arr)
}

sub is-key-array-pair( $p ) { $p ~~ Pair and $p.key ~~ Str and $p.value ~~ Positional }

#------------------------------------------------------------
sub is-array-of-key-hash-pairs(@arr) is export {
   ( [and] @arr.map({ is-key-hash-pair($_) }) ) and has-homogeneous-shape(@arr)
}

sub is-key-hash-pair( $p ) { $p ~~ Pair and $p.key ~~ Str and $p.value ~~ Map }

#------------------------------------------------------------
sub is-array-of-hashes($arr) is export {
   $arr ~~ Positional and ( [and] $arr.map({ $_ ~~ Map }) )
}

#------------------------------------------------------------
sub is-map-of-maps($obj) is export {
   $obj ~~ Map && ( [and] $obj.values.map({ $_ ~~ Map }) )
}

#------------------------------------------------------------
sub is-positional-of-pairs($obj) is export {
   $obj ~~ Positional && ( [and] $obj.map({ $_ ~~ Pair }) )
}

#------------------------------------------------------------
sub is-positional-of-date-time-value-pairs($obj) is export {
    is-positional-of-pairs($obj) && $obj>>.key.all ~~ DateTime && $obj>>.value.all ~ Numeric
}

#------------------------------------------------------------
sub is-positional-of-date-time-value-lists($obj) is export {
    $obj ~~ Positional && ( [and] $obj.map({ $_ ~~ List && $_.elems == 2 && $_[0] ~~ DateTime && $_[1] ~~ Numeric}) )
}

#------------------------------------------------------------
# Same as above except checking for the date field to be a string.
sub is-positional-of-str-date-time-value-lists($obj) is export {
    $obj ~~ Positional && ( [and] $obj.map({ $_ ~~ List && $_.elems == 2 && $_[0] ~~ Str && $_[1] ~~ Numeric}) )
}

#------------------------------------------------------------
sub is-time-series-record($obj, $dateType) {
    ($obj.keys.sort eq <date value> || $obj.keys.sort eq <date group value>) && $obj<date> ~~ $dateType && $obj<value> ~~ Numeric
}

#------------------------------------------------------------
sub is-time-series($obj) is export {
    $obj ~~ Positional && ( [and] $obj.map({ $_ ~~ Map && is-time-series-record($_, DateTime) }) )
}

#------------------------------------------------------------
# Same as above except checking for the date field to be a string.
sub is-str-time-series($obj) is export {
    $obj ~~ Positional && ( [and] $obj.map({ $_ ~~ Map && is-time-series-record($_, Str) }) )
}

