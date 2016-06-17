# ParallelDataTransfer.jl

[![Build Status](https://travis-ci.org/ChrisRackauckas/ParallelDataTransfer.jl.svg?branch=master)](https://travis-ci.org/ChrisRackauckas/ParallelDataTransfer.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/c8tqjhxx9679gl6u?svg=true)](https://ci.appveyor.com/project/ChrisRackauckas/paralleldatatransfer-jl)

A bunch of helper functions for transferring data between worker processes.
Credit goes to [the StackExchange users who developed the solution.](http://stackoverflow.com/questions/27677399/julia-how-to-copy-data-to-another-processor-in-julia)

This package adds some tests to ensure that these functions continue to work properly.

## Installation

```
Pkg.clone("https://github.com/ChrisRackauckas/ParallelDataTransfer.jl")
```

## Usage

For examples of usage, please see the tests.

```julia
# creates an integer x and Matrix y on processes 1 and 2
sendto([1, 2], x=100, y=rand(2, 3))

# create a variable here, then send it everywhere else
z = randn(10, 10); sendto(workers(), z=z)

# get an object from named x from Main module on process 2. Name it x
x = getfrom(2, :x)

# pass variable named x from process 2 to all other processes
passobj(2, filter(x->x!=2, procs()), :x)

# pass variables t, u, v from process 3 to process 1
passobj(3, 1, [:t, :u, :v])

# Pass a variable from the `Foo` module on process 1 to Main on workers
passobj(1, workers(), [:foo]; from_mod=Foo)
```
