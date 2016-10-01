# ParallelDataTransfer.jl

[![Travis](https://travis-ci.org/ChrisRackauckas/ParallelDataTransfer.jl.svg?branch=master)](https://travis-ci.org/ChrisRackauckas/ParallelDataTransfer.jl)
[![AppVeyor](https://ci.appveyor.com/api/projects/status/c8tqjhxx9679gl6u?svg=true)](https://ci.appveyor.com/project/ChrisRackauckas/paralleldatatransfer-jl)
[![codecov](https://codecov.io/gh/ChrisRackauckas/ParallelDataTransfer.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ChrisRackauckas/ParallelDataTransfer.jl)
[![coveralls](https://coveralls.io/repos/github/ChrisRackauckas/ParallelDataTransfer.jl/badge.svg)](https://coveralls.io/github/ChrisRackauckas/ParallelDataTransfer.jl)

A bunch of helper functions for transferring data between worker processes.

## Installation

To install the package, simply use:

```julia
Pkg.add("ParallelDataTransfer")
using ParallelDataTransfer
```

For the most up to date version, checkout master by using:

```julia
Pkg.checkout("ParallelDataTransfer")
```

## Usage

For examples of usage, please see the tests.

```julia
# Creates an integer x and Matrix y on processes 1 and 2
sendto([1, 2], x=100, y=rand(2, 3))

# Create a variable here, then send it everywhere else
z = randn(10, 10); sendto(workers(), z=z)

# Create the variable x with a value 3 directly on process 4
@defineat 4 x 3

# Broadcast a value 3 to x on all workers
@broadcast x 3

# Get an object from named x from Main module on process 2. Name it y
y = @getfrom 2 x
# Or
y = getfrom(2,:x)

# Get an object from named x from Foo module on process 2. Name it y
y = @getfrom 2 x Foo
# Or
y = getfrom(2,:x,Foo)

# Get an object from named foo.x from Foo module on process 2. Name it y
y = @getfrom 2 foo.x Foo
# Using the function will not work!

# pass variable named x from process 2 to all other processes
@passobj 2  filter(x->x!=2, procs())  x
# Or
passobj(2, filter(x->x!=2, procs()), :x)

# pass variables t, u, v from process 3 to process 1
passobj(3, 1, [:t, :u, :v])

# Pass a variable from the `Foo` module on process 1 to Main on workers
@passobj 1 workers() Foo.foo
#Or
passobj(1, workers(), [:foo]; from_mod=Foo)
```

## Credit

Lots of credit goes to [the StackExchange users who developed some of the original solutions.](http://stackoverflow.com/questions/27677399/julia-how-to-copy-data-to-another-processor-in-julia).
This package adds some tests to ensure that these functions continue to work properly,
updated them to v0.5, and adds some macros to unify the API (also avoids issues
that came up with original functions and generalizes them a bit).
Special thanks to @TotalVerb and @oxinabox for help via Gitter.
