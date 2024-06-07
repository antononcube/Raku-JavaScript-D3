# Date list plot examples

## Introduction

-------
## CLI execution

To "run" this file using shell commands the following Raku packages have to be installed:  

- ["Text::CodeProcessing"](https://raku.land/zef:antononcube/Text::CodeProcessing)
    
  - Provides `file-code-chunks-eval` used below.

- ["Markdown::Grammar"](https://raku.land/zef:antononcube/Markdown::Grammar)

  - Provides `from-markdown` used below.


Here is the shell command executed in the director of this Markdown file:

```
file-code-chunks-eval ./Date-list-plot-examples.md && from-markdown ./Date-list-plot-examples_woven.md -o=./Date-list-plot-examples.html -t=html 
```

-------

## Load packages

```perl6
use Data::Generators;
use Data::Reshapers;
use Data::Summarizers;
use JavaScript::D3;
```

------

## Random data

Make random data time series data:

```perl6
my $k=0;
my @dsXY = (^1200)>>.rand>>.sqrt.map({ %(x=>$k++, y=>$_) });

my $refDate = DateTime.new('2000-01-01');
my @dsTS = @dsXY.map({ %( date => ($refDate + $_<x> * 10e4).DateTime, value => $_<y> ) });

my @dsTS2 = @dsTS.map({ %( date => $_<date>.Str.substr(0,10), value => $_<value>, group => <a b>.pick ) }).map({ if $_<group> eq 'a' { $_<value> *= -1 }; $_ });
say records-summary(@dsTS2);
say dimensions(@dsTS2);
```

Convert to format understood by `js-d3-date-list-plot`:

```perl6
my @dsTS2 = @dsTS.map({ %( date => $_<date>.Str.substr(0,10), value => $_<value>, group => <a b>.pick ) }).map({ if $_<group> eq 'a' { $_<value> *= -1 }; $_ });
say records-summary(@dsTS2);
say dimensions(@dsTS2);
```

```perl6, results=asis
js-d3-date-list-plot(@dsTS2, width=>1000, background => 'none', format=>'html');
```

------

## References

[AA1] Anton Antonov
["JavaScript::D3"](https://rakuforprediction.wordpress.com/2022/12/15/javascriptd3/),
(2022),
[RakuForPrediction](https://rakuforprediction.wordpress.com).

[AA2] Anton Antonov
["Further work on the Raku-D3.js translation"](https://rakuforprediction.wordpress.com/2022/12/22/further-work-on-the-raku-to-d3-js-translation/),
(2022),
[RakuForPrediction](https://rakuforprediction.wordpress.com).