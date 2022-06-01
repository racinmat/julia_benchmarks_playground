using Pkg
pkg"activate ."
pkg"precompile"
using OrderedCollections: OrderedDict
using BenchmarkTools
abstract type NodeType end
struct LeafNode <: NodeType end
struct InnerNode <: NodeType end
NodeType(::Type{T}) where T = @error "Define NodeType(::Type{$T}) to be either LeafNode() or InnerNode()"
NodeType(x::T) where T = NodeType(T)
find_traversal(n, x) = pred_traversal(n, t -> x === t)
pred_traversal(n::T, p::Function, s::String="") where T = _pred_traversal(NodeType(T), n, p, s)
_pred_traversal(::LeafNode, n, p, s="") = p(n) ? [stringify(s)] : String[]
function _pred_traversal(::InnerNode, n, p, s="")
    d = _childsort(children(n))
    l = length(d)
    z = Vector{String}[pred_traversal(_ith_child(d, i), p, s * encode(i, l)) for i in 1:l]
    res = isempty(z) ? String[] : reduce(vcat, z)
    p(n) ? vcat(stringify(s), res) : res
end
_childsort(x::Union{Tuple, Vector, OrderedDict}) = x
function _childsort(x::NamedTuple{T}) where T
    ks = tuple(sort(collect(T))...)
    NamedTuple{ks}(x[k] for k in ks)
end
children(n) = children(NodeType(n), n)
children(::LeafNode, _) = ()
children(_, ::T) where T = @error "Define children(n::$T) to return a collection of children (one of allowed types)"
const ALPHABET = [Char(x) for x in vcat(collect.([42:43, 48:57, 65:90, 97:122])...)]
function stringify(c::AbstractString)
    if length(c) % 6 != 0
        c = c * '0' ^ mod(6-length(c), 6)
    end
    join(ALPHABET[parse(Int, x, base=2) + 1] for x in [c[i:i+5] for i in 1:6:(length(c)-1)])
end
function _ith_child(m::Union{Tuple, Vector, NamedTuple}, i::Integer)
    return m[i]
end
_ith_child(m::OrderedDict, i::Integer) = _ith_child(collect(m), i)
_segment_width(l::Integer) = ceil(Int, log2(l+1))
encode(i::Integer, l::Integer) = string(i, base=2, pad=_segment_width(l))
abstract type AbstractVertex end
mutable struct Leaf <: AbstractVertex
    n::Int64
end
NodeType(::Type{<:Vector}) = InnerNode()
children(v::Vector) = v
noderepr(v::Vector) = isempty(v) ? "[]" : "Vector of"
NodeType(::Type{Leaf}) = LeafNode()
const LINEAR_TREE_3 = [[[[[[[Leaf(1)]]]]]]]
t = LINEAR_TREE_3
@time find_traversal(t, [t, t])
@btime find_traversal(t, [t, t])
