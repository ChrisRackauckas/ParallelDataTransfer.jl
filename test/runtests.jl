addprocs(4)
@everywhere using ParallelDataTransfer
using Base.Test

@everywhere srand(100)
# creates an integer x and Matrix y on processes 1 and 2
sendto([1, 2], x=100, y=rand(2, 3))
abs(remotecall_fetch(getindex,2,y,1,1) - .260) < 1e-2
# create a variable here, then send it everywhere else
z = randn(10, 10); sendto(workers(), z=z)
@everywhere println(z)

# get an object from named x from Main module on process 2. Name it x
x = @getfrom(2, z)
@test x==z

# pass variable named x from process 2 to all other processes
@spawnat 2 eval(:(x=1))
passobj(2, filter(x->x!=2, procs()), :x)
sleep(1)
@test x==1
# pass variables t, u, v from process 3 to process 1
@spawnat 3 eval(:(t=1))
@spawnat 3 eval(:(u=2))
@spawnat 3 eval(:(v=3))

passobj(3, 1, [:t, :u, :v])
sleep(1)
@test [t;u;v] == [1;2;3]


@everywhere module Foo
  foo = 1
end
passobj(3, 1, :foo, from_mod=Foo)
sleep(1)
@test foo == 1
# Pass a variable from the `Foo` module on process 1 to Main on workers
passobj(1, workers(), :foo, from_mod=Foo)



#### @getfrom test ####

@everywhere type Bar
    a
    b
    c
end
srand(3)
bar_vec = [Bar(rand(3),rand(3),rand(3)) for n in 1:3]
sendto(workers(),bar_vec=bar_vec)
@test @getfrom(2,bar_vec[3].c) == bar_vec[3].c

remotecall(2, ()->Main.bar_vec[3].c=ones(3))
mybar_3c1 = remotecall_fetch(2, ()->Main.bar_vec[3].c)
@test mybar_3c1 == ones(3)
mybar_3c2 = @getfrom(2,bar_vec[3].c)
@test mybar_3c2 == ones(3)

true
