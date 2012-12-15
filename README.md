# RubyPLB

RubyPLB generates pattern lattice graphics from lists of patterns.

## Features

* Accept a text file with any number of patterns and generate a Graphviz DOT file, or a PNG/JPG/EPS image file.
* Calculate z-scores of pattern nodes and create lattice graphs with temperature colorng applied. 

## Installation

Install the gem:

  $sudo gem install rubyplb --source http://gemcutter.org

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

## ToDo

* Multiple input formats
* Database connection capability

## Links

under construction

## Copyright

Copyright (c) 2009-2012 Kow Kuroda and Yoichiro Hasebe. See LICENSE for details.