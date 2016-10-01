module ParallelDataTransfer

  function sendtosimple(p::Int, nm, val)
      ref = @spawnat(p, eval(Main, Expr(:(=), nm, val)))
  end

  macro sendto(p, nm, val)
      return :( sendtosimple($p, $nm, $val) )
  end

  function sendto(p::Int; args...)
      for (nm, val) in args
          @spawnat(p, eval(Main, Expr(:(=), nm, val)))
      end
  end

  macro getfrom(p, obj,mod=Main)
    fetch(@spawnat(p,eval(Main,obj)))
  end

  function passobj(src::Int, target::Vector{Int}, nm::Symbol;
                   from_mod=Main, to_mod=Main)
      r = RemoteChannel(src)
      @spawnat(src, put!(r, getfield(from_mod, nm)))
      @sync for to in target
          @spawnat(to, eval(to_mod, Expr(:(=), nm, fetch(r))))
      end
      nothing
  end

  macro passobj(src, target, val, tomod=:Main)
    quote
      r = Future($(esc(src)))
      remotecall_wait($(esc(src)), r) do r_i
          put!(r_i, $(esc(val)))
      end
      futures = map($(esc(target))) do to
          remotecall(to, r) do r_i
              isready(r_i)
              eval($(esc(tomod)), Expr(:(=), $(QuoteNode(val)), fetch(r_i)))
          end
      end
      map(wait, futures) #Wait till all are done
    end
  end


  function passobj(src::Int, target::Int, nm::Symbol; from_mod=Main, to_mod=Main)
      passobj(src, [target], nm; from_mod=from_mod, to_mod=to_mod)
  end


  function passobj(src::Int, target, nms::Vector{Symbol};
                   from_mod=Main, to_mod=Main)
      for nm in nms
          passobj(src, target, nm; from_mod=from_mod, to_mod=to_mod)
      end
  end

  function sendto(ps::Vector{Int}; args...)
      for p in ps
          sendto(p; args...)
      end
  end

  macro broadcast(nm, val)
      quote
      @sync for p in workers()
          @async sendtosimple(p, $nm, $val)
      end
      end
  end

  export sendtosimple, @sendto, sendto, getfrom, passobj, @broadcast, @getfrom, @passobj
end # module
