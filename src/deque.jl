@inline push(vec::StaticVector, x) = _push(Size(vec), vec, x)
@generated function _push(::Size{s}, vec::StaticVector, x) where {s}
    newlen = s[1] + 1
    exprs = vcat([:(vec[$i]) for i = 1:s[1]], :x)
    return quote
        @_inline_meta
        @inbounds return similar_type(vec, Size($newlen))(tuple($(exprs...)))
    end
end

@inline unshift(vec::StaticVector, x) = _unshift(Size(vec), vec, x)
@generated function _unshift(::Size{s}, vec::StaticVector, x) where {s}
    newlen = s[1] + 1
    exprs = vcat(:x, [:(vec[$i]) for i = 1:s[1]])
    return quote
        @_inline_meta
        @inbounds return similar_type(vec, Size($newlen))(tuple($(exprs...)))
    end
end

@propagate_inbounds insert(vec::StaticVector, index, x) = _insert(Size(vec), vec, index, x)
@generated function _insert(::Size{s}, vec::StaticVector, index, x) where {s}
    newlen = s[1] + 1
    exprs = [(i == 1 ? :(ifelse($i < index, vec[$i], x)) :
              i == newlen ? :(ifelse($i == index, x, vec[$i-1])) :
              :(ifelse($i < index, vec[$i], ifelse($i == index, x, vec[$i-1])))) for i = 1:newlen]
    return quote
        @_inline_meta
        @boundscheck if (index < 1 || index > $newlen)
            throw(BoundsError(vec, index))
        end
        @inbounds return similar_type(vec, Size($newlen))(tuple($(exprs...)))
    end
end

@inline pop(vec::StaticVector) = _pop(Size(vec), vec)
@generated function _pop(::Size{s}, vec::StaticVector) where {s}
    newlen = s[1] - 1
    exprs = [:(vec[$i]) for i = 1:s[1]-1]
    return quote
        @_inline_meta
        @inbounds return similar_type(vec, Size($newlen))(tuple($(exprs...)))
    end
end

@inline shift(vec::StaticVector) = _shift(Size(vec), vec)
@generated function _shift(::Size{s}, vec::StaticVector) where {s}
    newlen = s[1] - 1
    exprs = [:(vec[$i]) for i = 2:s[1]]
    return quote
        @_inline_meta
        @inbounds return similar_type(vec, Size($newlen))(tuple($(exprs...)))
    end
end

@propagate_inbounds deleteat(vec::StaticVector, index) = _deleteat(Size(vec), vec, index)
@generated function _deleteat(::Size{s}, vec::StaticVector, index) where {s}
    newlen = s[1] - 1
    exprs = [:(ifelse($i < index, vec[$i], vec[$i+1])) for i = 1:newlen]
    return quote
        @_inline_meta
        @boundscheck if (index < 1 || index > $(s[1]))
            throw(BoundsError(vec, index))
        end
        @inbounds return similar_type(vec, Size($newlen))(tuple($(exprs...)))
    end
end

# TODO consider prepend, append (can use vcat, but eltype might change), and
# maybe splice (a bit hard to get statically sized without a "static" range)


# Immutable version of setindex!(). Seems similar in nature to the above, but
# could also be justified to live in src/indexing.jl
import Base: setindex
@inline setindex(a::StaticArray, x, index::Int) = _setindex(Size(a), a, convert(eltype(typeof(a)), x), index)
@generated function _setindex(::Size{s}, a::StaticArray{<:Any,T}, x::T, index::Int) where {s, T}
    exprs = [:(ifelse($i == index, x, a[$i])) for i = 1:s[1]]
    return quote
        @_inline_meta
        @boundscheck if (index < 1 || index > $(s[1]))
            throw(BoundsError(a, index))
        end
        @inbounds return typeof(a)(tuple($(exprs...)))
    end
end

# TODO proper multidimension boundscheck
if VERSION < v"0.7-"
    @propagate_inbounds setindex(a::StaticArray, x, inds::Int...) = setindex(a, x, sub2ind(size(typeof(a)), inds...))
else
    @propagate_inbounds setindex(a::StaticArray, x, inds::Int...) = setindex(a, x, LinearIndices(a)[inds...])
end
