using Pkg
pkg"activate .;precompile"
using Flux, StatsBase, LearnBase, Test, Zygote, ChainRulesCore, Combinatorics, StableRNGs, FiniteDifferences, BenchmarkTools
using HierarchicalUtils: encode, stringify
using LearnBase: ObsDim

const VecOrRange{T} = Union{UnitRange{T}, AbstractVector{T}}
const VecOrTupOrNTup{T} = Union{Vector{<:T}, Tuple{Vararg{T}}, NamedTuple{K, <:Tuple{Vararg{T}}} where K}
using Base: AbstractVecOrMat, AbstractVecOrTuple
const Maybe{T} = Union{T, Missing}
const Optional{T} = Union{T, Nothing}
import Base: *, ==, reduce

rng = StableRNG(25)

# datanodes/datanode.jl
abstract type AbstractNode end
abstract type AbstractProductNode <: AbstractNode end
abstract type AbstractBagNode <: AbstractNode end

# datanodes/arraynode.jl
struct ArrayNode{A <: AbstractArray, C} <: AbstractNode
    data::A
    metadata::C
end

ArrayNode(d::AbstractArray) = ArrayNode(d, nothing)

Flux.@functor ArrayNode

mapdata(f, x::ArrayNode) = ArrayNode(mapdata(f, x.data), x.metadata)

Base.ndims(x::ArrayNode) = Colon()
StatsBase.nobs(a::ArrayNode) = size(a.data, 2)
StatsBase.nobs(a::ArrayNode, ::Type{ObsDim.Last}) = nobs(a)

# datanodes/productnode.jl
struct ProductNode{T, C} <: AbstractProductNode
    data::T
    metadata::C

    function ProductNode{T, C}(data::T, metadata::C) where {T, C}
        @assert(length(data) >= 1 && all(x -> nobs(x) == nobs(data[1]), data),
                "All subtrees must have an equal amount of instances!")
        new{T, C}(data, metadata)
    end
end

ProductNode(ds::T) where {T} = ProductNode{T, Nothing}(ds, nothing)
ProductNode(ds::T, m::C) where {T, C} = ProductNode{T, C}(ds, m)

Flux.@functor ProductNode

mapdata(f, x::ProductNode) = ProductNode(map(i -> mapdata(f, i), x.data), x.metadata)

Base.getindex(x::ProductNode, i::Symbol) = x.data[i]

Base.getindex(x::ProductNode, i::VecOrRange{<:Int}) = ProductNode(subset(x.data, i), subset(x.metadata, i))

include("bags.jl")
# datanodes/bagnode.jl
struct BagNode{T <: Maybe{AbstractNode}, B <: AbstractBags, C} <: AbstractBagNode
    data::T
    bags::B
    metadata::C

    function BagNode(d::T, b::B, m::C=nothing) where {T <: Maybe{AbstractNode}, B <: AbstractBags, C}
        ismissing(d) && any(length.(b) .> 0) && error("BagNode with `missing` in data cannot have a non-empty bag")
        new{T, B, C}(d, b, m)
    end
end

BagNode(d::Maybe{AbstractNode}, b::AbstractVector, m=nothing) = BagNode(d, bags(b), m)
Flux.@functor BagNode
mapdata(f, x::BagNode) = BagNode(mapdata(f, x.data), x.bags, x.metadata)

function Base.getindex(x::BagNode, i::VecOrRange{<:Int})
    nb, ii = remapbags(x.bags, i)
    emptyismissing() && isempty(ii) && return(BagNode(missing, nb, nothing))
    BagNode(subset(x.data,ii), nb, subset(x.metadata, i))
end

# datanodes/datanode.jl
data(n::AbstractNode) = n.data
metadata(x::AbstractNode) = x.metadata

StatsBase.nobs(a::AbstractBagNode) = length(a.bags)
StatsBase.nobs(a::AbstractBagNode, ::Type{ObsDim.Last}) = nobs(a)
Base.ndims(x::AbstractBagNode) = Colon()

Base.ndims(x::AbstractProductNode) = Colon()
StatsBase.nobs(a::AbstractProductNode) = nobs(a.data[1], ObsDim.Last)
StatsBase.nobs(a::AbstractProductNode, ::Type{ObsDim.Last}) = nobs(a)

# aggregations/aggregation.jl
abstract type AggregationOperator{T <: Number} end

struct Aggregation{T, U <: Tuple{Vararg{AggregationOperator{T}}}}
    fs::U
    Aggregation(fs::Union{Aggregation, AggregationOperator}...) = Aggregation(fs)
    function Aggregation(fs::Tuple{Vararg{Union{Aggregation{T}, AggregationOperator{T}}}}) where {T}
        ffs = _flatten_agg(fs)
        new{T, typeof(ffs)}(ffs)
    end
end

_flatten_agg(t) = tuple(vcat(map(_flatten_agg, t)...)...)
_flatten_agg(a::Aggregation) = vcat(map(_flatten_agg, a.fs)...)
_flatten_agg(a::AggregationOperator) = [a]

Flux.@functor Aggregation


const _bagcount = Ref(true)

bagcount() = _bagcount[]

function (a::Aggregation{T})(x::Union{AbstractArray, Missing}, bags::AbstractBags, args...) where T
    o = reduce(vcat, (f(x, bags, args...) for f in a.fs))
    bagcount() ? vcat(o, Zygote.@ignore permutedims(log.(one(T) .+ length.(bags)))) : o
end
(a::Union{AggregationOperator, Aggregation})(x::ArrayNode, args...) = ArrayNode(a(x.data, args...))
Flux.@forward Aggregation.fs Base.getindex, Base.firstindex, Base.lastindex, Base.first, Base.last, Base.iterate, Base.eltype

Base.length(a::Aggregation) = sum(length.(a.fs))
Base.size(a::Aggregation) = tuple(sum(only, size.(a.fs)))
Base.vcat(as::Aggregation...) = reduce(vcat, as |> collect)
function Base.reduce(::typeof(vcat), as::Vector{<:Aggregation})
    Aggregation(tuple(vcat((collect(a.fs) for a in as)...)...))
end

# more stable definitions for r_map and p_map
ChainRulesCore.rrule(::typeof(softplus), x) = softplus.(x), Δ -> (NO_FIELDS, Δ .* σ.(x))

# our definition of type min for Maybe{...} types
_typemin(t::Type) = typemin(t)
_typemin(::Type{Maybe{T}}) where T = typemin(T)

include("segmented_mean.jl")
include("segmented_max.jl")

const names = ["Sum", "Mean", "Max", "PNorm", "LSE"]
for p in filter(!isempty, collect(powerset(collect(1:length(names)))))
    s = Symbol(lowercase.(names[p])..., "_aggregation")
    @eval begin
        """
            $($(s))([t::Type, ]d::Int)

        Construct [`Aggregation`](@ref) consisting of $($(
            join("[`Segmented" .* names[p] .* "`](@ref)", ", ", " and ")
       )) operator$($(length(p) > 1 ? "s" : "")).

        $($(
            all(in(["Sum", "Mean", "Max"]), names[p]) ? """
            # Examples
            ```jldoctest
            julia> $(s)(4)
            Aggregation{Float32}:
            $(join(" Segmented" .* names[p] .* "(ψ = Float32[0.0, 0.0, 0.0, 0.0])", "\n"))

            julia> $(s)(Int64, 2)
            Aggregation{Int64}:
            $(join(" Segmented" .* names[p] .* "(ψ = [0, 0])", "\n"))
            ```
            """ : ""
        ))

        See also: [`Aggregation`](@ref), [`AggregationOperator`](@ref), [`SegmentedSum`](@ref),
            [`SegmentedMax`](@ref), [`SegmentedMean`](@ref), [`SegmentedPNorm`](@ref), [`SegmentedLSE`](@ref).
        """
        function $s(d::Int)
            Aggregation($((Expr(:call, Symbol("Segmented", n), :d) for n in names[p])...))
        end
    end
    @eval function $s(::Type{T}, d::Int) where T
        Aggregation($((Expr(:call, Expr(:curly, Symbol("Segmented", n), :T), :d) for n in names[p])...))
    end
    # if length(p) > 1
    #     @eval function $s(D::Vararg{Int, $(length(p))})
    #         Aggregation($((Expr(:call, Symbol("_Segmented", n), :(D[$i]))
    #                        for (i,n) in enumerate(names[p]))...))
    #     end
    # end
    @eval export $s
end

@inline _bagnorm(w::Nothing, b) = length(b)
@inline _bagnorm(w::AbstractVector, b) = @views sum(w[b])
@inline _bagnorm(w::AbstractMatrix, b) = @views vec(sum(w[:, b], dims=2))

@inline _weight(w::Nothing, _, _, ::Type{T}) where T = one(T)
@inline _weight(w::AbstractVector, _, j, _) = w[j]
@inline _weight(w::AbstractMatrix, i, j, _) = w[i, j]

@inline _weightsum(ws::Real, _) = ws
@inline _weightsum(ws::AbstractVector, i) = ws[i]

# modelnodes/modelnode.jl
abstract type AbstractMillModel end

const MillFunction = Union{Dense, Chain, Function}

_make_array_model(m::Union{MillFunction, Function}) = ArrayModel(m)
_make_array_model(m) = m

function reflectinmodel(x, fm=d -> Dense(d, 10), fa=d -> meanmax_aggregation(d); fsm=Dict(), fsa=Dict(),
               single_key_identity=true, single_scalar_identity=true)
    _reflectinmodel(x, fm, fa, fsm, fsa, "", single_key_identity, single_scalar_identity)[1]
end

function _reflectinmodel(x::AbstractBagNode, fm, fa, fsm, fsa, s, ski, ssi)
    c = stringify(s)
    im, d = _reflectinmodel(x.data, fm, fa, fsm, fsa, s * encode(1, 1), ski, ssi)
    agg = haskey(fsa, c) ? fsa[c](d) : fa(d)
    d = size(BagModel(im, agg)(x).data, 1)
    bm = haskey(fsm, c) ? fsm[c](d) : fm(d)
    m = BagModel(im, agg, bm)
    m, size(m(x).data, 1)
end

_cat_meta(f, m::Vector{Nothing}) = nothing
_cat_meta(f, m) = reduce(f, m)

Base.vcat(as::ArrayNode...) = reduce(vcat, collect(as))
function Base.reduce(::typeof(vcat), as::Vector{<:ArrayNode})
    ArrayNode(reduce(vcat, data.(as)), _cat_meta(vcat, metadata.(as)))
end

Base.hcat(as::ArrayNode...) = reduce(hcat, collect(as))
function Base.reduce(::typeof(hcat), as::Vector{<:ArrayNode})
    ArrayNode(reduce(hcat, data.(as)), _cat_meta(hcat, metadata.(as)))
end

Base.getindex(x::ArrayNode, i::VecOrRange{<:Int}) = ArrayNode(subset(x.data, i), subset(x.metadata, i))

Base.hash(e::ArrayNode, h::UInt) = hash((e.data, e.metadata), h)
(e1::ArrayNode == e2::ArrayNode) = isequal(e1.data == e2.data, true) && e1.metadata == e2.metadata
Base.isequal(e1::ArrayNode, e2::ArrayNode) = isequal(e1.data, e2.data) && isequal(e1.metadata, e2.metadata)


_remap(data::NamedTuple, ms) = (; zip(keys(data), ms)...)
_remap(::Tuple, ms) = tuple(ms...)

function _reflectinmodel(x::AbstractProductNode, fm, fa, fsm, fsa, s, ski, ssi)
    c = stringify(s)
    n = length(x.data)
    ks = keys(x.data)
    ms, ds = zip([_reflectinmodel(x.data[k], fm, fa, fsm, fsa, s * encode(i, n), ski, ssi)
                  for (i, k) in enumerate(ks)]...) |> collect
    ms = _remap(x.data, ms)
    m = if haskey(fsm, c)
        ArrayModel(fsm[c](sum(ds)))
    elseif ski && n == 1
        identity_model()
    else
        _reflectinmodel(ProductModel(ms)(x), fm, fa, fsm, fsa, s, ski, ssi)[1]
    end
    m = ProductModel(ms, m)
    m, size(m(x).data, 1)
end

function _reflectinmodel(x::ArrayNode, fm, fa, fsm, fsa, s, ski, ssi)
    c = stringify(s)
    r = size(x.data, 1)
    t = if haskey(fsm, c)
        fsm[c](r)
    elseif ssi && r == 1
        identity
    else
        fm(r)
    end |> ArrayModel
    t, size(t(x).data, 1)
end

identity_dense(x) = Dense(Matrix{Float32}(I, size(x, 1), size(x, 1)), zeros(Float32, size(x, 1)))

# modelnodes/arraymodel.jl
struct ArrayModel{T <: MillFunction} <: AbstractMillModel
    m::T
end

Flux.@functor ArrayModel

(m::ArrayModel)(x::ArrayNode) = ArrayNode(m.m(x.data))

identity_model() = ArrayModel(identity)

const IdentityModel = ArrayModel{typeof(identity)}

Flux.activations(::typeof(identity), x::Matrix) = (x,)

# modelsnodes/bagmodel.jl
struct BagModel{T <: AbstractMillModel, A <: Aggregation, U <: ArrayModel} <: AbstractMillModel
    im::T
    a::A
    bm::U
end

Flux.@functor BagModel

function BagModel(im::Union{MillFunction, AbstractMillModel}, a::Aggregation,
        bm::Union{MillFunction, ArrayModel}=identity_model())
    BagModel(_make_array_model(im), a, _make_array_model(bm))
end

(m::BagModel)(x::BagNode{<:AbstractNode}) = m.bm(m.a(m.im(x.data), x.bags))

# modelnodes/productnode.jl
struct ProductModel{T <: VecOrTupOrNTup{AbstractMillModel}, U <: ArrayModel} <: AbstractMillModel
    ms::T
    m::U
end

Flux.@functor ProductModel

function ProductModel(ms::VecOrTupOrNTup{Union{MillFunction, AbstractMillModel}},
                                m::Union{MillFunction, ArrayModel}=identity_model())
    ProductModel(map(_make_array_model, ms), _make_array_model(m))
end
ProductModel(ms::Union{MillFunction, AbstractMillModel},
             m::Union{MillFunction, ArrayModel}=identity_model()) = ProductModel((ms,), m)

Base.getindex(m::ProductModel, i::Symbol) = m.ms[i]
Base.keys(m::ProductModel) = keys(m.ms)

function (m::ProductModel{<:Tuple})(x::ProductNode{<:Tuple})
    xx = ArrayNode(vcat([m.ms[i](x.data[i]) |> data for i in 1:length(m.ms)]...))
    m.m(xx)
end

function (m::ProductModel{<:NamedTuple})(x::ProductNode{<:NamedTuple})
    xx = ArrayNode(vcat([m.ms[k](x.data[k]) |> data for k in keys(m.ms)]...))
    m.m(xx)
end

include("gradients.jl")

x = ProductNode((a=ArrayNode(randn(Float32, 3, 4)), b=ArrayNode(randn(Float32, 4, 4))))
m = reflectinmodel(x, k->Flux.Dense(k, 2, NNlib.relu))
@test eltype(m(x).data) == Float32
@test size(m(x).data) == (2, 4)
@test m isa ProductModel
@test m.ms[:a] isa ArrayModel
@test m.ms[:b] isa ArrayModel

x = ProductNode((BagNode(ArrayNode(randn(Float32, 3, 4)), [1:2, 3:4]),
                 BagNode(ArrayNode(randn(Float32, 4, 4)), [1:1, 2:4])))
m = reflectinmodel(x, k->Flux.Dense(k, 2, NNlib.relu))
@test size(m(x).data) == (2, 2)
@test m isa ProductModel
@test m.ms[1] isa BagModel
@test m.ms[1].im isa ArrayModel
@test m.ms[1].bm isa ArrayModel
@test m.ms[2] isa BagModel
@test m.ms[2].im isa ArrayModel
@test m.ms[2].bm isa ArrayModel

@time layerbuilder(k) = Dense(k, 2, softplus) |> f64
@time abuilder(d) = all_aggregations(Float64, d)
x = randn(rng, 4, 4)
y = randn(rng, 3, 4)
z = randn(rng, 2, 8)

ds = x -> ArrayNode(x)
@time m = reflectinmodel(ds(x), layerbuilder, abuilder)
@time @test gradtest(x -> m(ds(x)).data, x)
@btime gradtest(x -> m(ds(x)).data, x)
@btime m(ds(x))
f2 = gradf(x -> m(ds(x)).data, x)
@btime ag = Flux.gradient(f2, x)
