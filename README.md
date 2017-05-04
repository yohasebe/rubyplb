# RubyPLB

RubyPLB generates pattern lattice graphics from lists of patterns.

## Features

* Accept a text file with any number of patterns and generate a Graphviz DOT file, or a PNG/JPG/EPS image file.
* Calculate z-scores of pattern nodes and create lattice graphs with temperature colorng applied. 

## Installation

Install the gem:

  $sudo gem install rubyplb

## How to Use

    Usage:
           rubyplb [options] <source file> <output file>
  
    where:
    <source file>
           ".plb", ".txt"
    <output file>
           ."dot", ".png", ".jpg", or ".eps"
    [options]:
        --simple, -s:   Use simple labels for pattern nodes
          --full, -f:   Generate a full pattern lattice without contracting nodes
      --vertical, -v:   Draw the graph from top to bottom instead of left to right)
      --coloring, -c:   Color pattern nodes
      --straight, -t:   Straighten edges (available when output format is either png, jpg, or eps)
          --help, -h:   Show this message

## Example

Source file (`sample.plb`)

    A B C A [navy] (42)
    C D E [#FF9900] (23)
    A D E (8)

Each line represents a pattern, or an instance of a pattern to be more precise. A color code can be specified in square brackets and pattern weight can be specified by an integer in parentheses after the pattern representation.

    rubyplb -s -c 1 -t -v sample.plb sapmple.png

Resulting image

![sample.png](https://github.com/yohasebe/rubyplb/blob/master/sample.png)

## Copyright

Copyright (c) 2009-2017 Kow Kuroda and Yoichiro Hasebe. See LICENSE for details.
