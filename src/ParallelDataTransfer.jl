module ParallelDataTransfer
  using Distributed

  function sendtosimple(p::Int, nm, val)
      ref = @spawnat(p, Core.eval(Main, Expr(:(=), nm, val)))
  end

  function sendto(p::Int; args...)
      for (nm, val) in args
          @spawnat(p, Core.eval(Main, Expr(:(=), nm, val)))
      end
  end

  macro getfrom(p, obj,mod=:Main)
    quote
      remotecall_fetch($(esc(p)),$(esc(mod)),$(QuoteNode(obj))) do m,o
        Core.eval(m,o)
      end
    end
  end


  getfrom(p::Int, nm::Symbol, mod::Module=Main) = fetch(@spawnat(p, getfield(mod, nm)))

  macro defineat(p,ex,mod=Main)
    quote
      remotecall_wait($(esc(p)),$(esc(mod)),$(QuoteNode(ex))) do mod,ex
        Core.eval(mod,ex)
      end
    end
  end

  function passobj(src::Int, target::AbstractVector{Int}, nm::Symbol;
                   from_mod=Main, to_mod=Main)
      r = RemoteChannel(src)
      @spawnat(src, put!(r, getfield(from_mod, nm)))
      @sync for to in target
          @spawnat(to, Core.eval(to_mod, Expr(:(=), nm, fetch(r))))
      end
      nothing
  end

  macro passobj(src::Int, target, val, from_mod=:Main, tomod=:Main)
    quote
      passobj($(esc(src)), $(esc(target)), $(QuoteNode(val)); from_mod=$from_mod, to_mod=$tomod)
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

  function sendto(ps::AbstractVector{Int}; args...)
      for p in ps
          sendto(p; args...)
      end
  end

  macro broadcast(ex)
     quote
         for p in workers()
             @defineat p $(ex)
         end
     end
  end

  export sendtosimple, @sendto, sendto, getfrom, passobj,
         @broadcast, @getfrom, @passobj, @defineat
end # module
