typealias SimpleGraphEdge SimpleEdge

"""A type representing an undirected graph."""
type SimpleGraph{T<:Integer} <: AbstractSimpleGraph
    vertices::UnitRange{T}
    ne::Int
    fadjlist::Vector{Vector{T}} # [src]: (dst, dst, dst)
end

eltype{T<:Integer}(x::SimpleGraph{T}) = T

# Graph{UInt8}(6), Graph{Int16}(7)
function (::Type{SimpleGraph{T}}){T<:Integer}(n::Integer = 0)
    fadjlist = Vector{Vector{T}}()
    sizehint!(fadjlist, n)
    for _ = one(T):n
        push!(fadjlist, Vector{T}())
    end
    vertices = one(T):T(n)
    return SimpleGraph{T}(vertices, 0, fadjlist)
end

# Graph()
SimpleGraph() = SimpleGraph{Int}()

# Graph(6), Graph(0x5)
SimpleGraph{T<:Integer}(n::T) = SimpleGraph{T}(n)

# SimpleGraph(UInt8)
SimpleGraph{T<:Integer}(::Type{T}) = SimpleGraph{T}(zero(T))

# Graph{UInt8}(adjmx)
function (::Type{SimpleGraph{T}}){T<:Integer}(adjmx::AbstractMatrix)
    dima,dimb = size(adjmx)
    isequal(dima,dimb) || error("Adjacency / distance matrices must be square")
    issymmetric(adjmx) || error("Adjacency / distance matrices must be symmetric")

    g = SimpleGraph(T(dima))
    for i in find(triu(adjmx))
        ind = ind2sub((dima,dimb),i)
        add_edge!(g,ind...)
    end
    return g
end

# converts Graph{Int} to Graph{Int32}
function (::Type{SimpleGraph{T}}){T<:Integer}(g::SimpleGraph)
  h_vertices = one(T):T(nv(g))
  h_fadj = [Vector{T}(x) for x in fadj(g)]
  return SimpleGraph(h_vertices, ne(g), h_fadj)
end


# Graph(adjmx)
SimpleGraph(adjmx::AbstractMatrix) = SimpleGraph{Int}(adjmx)

# Graph(digraph)
function SimpleGraph(g::SimpleDiGraph)
    gnv = nv(g)
    edgect = 0
    newfadj = deepcopy(g.fadjlist)
    for i in vertices(g)
        for j in badj(g,i)
            if (_insert_and_dedup!(newfadj[i], j))
                edgect += 2     # this is a new edge only in badjlist
            else
                edgect += 1     # this is an existing edge - we already have it
                if i == j
                    edgect += 1 # need to count self loops
                end
            end
        end
    end
    iseven(edgect) || throw(AssertionError("invalid edgect in graph creation - please file bug report"))
    return SimpleGraph(vertices(g), edgect ÷ 2, newfadj)
end

edgetype{T<:Integer}(::SimpleGraph{T}) = SimpleGraphEdge{T}

"""Returns the backwards adjacency list of a graph.
For each vertex the Array of `dst` for each edge eminating from that vertex.

NOTE: returns a reference, not a copy. Do not modify result.
"""
badj(g::SimpleGraph) = fadj(g)
badj(g::SimpleGraph, v::Integer) = fadj(g, v)


"""Returns the adjacency list of a graph.
For each vertex the Array of `dst` for each edge eminating from that vertex.

NOTE: returns a reference, not a copy. Do not modify result.
"""
adj(g::SimpleGraph) = fadj(g)
adj(g::SimpleGraph, v::Integer) = fadj(g, v)

copy(g::SimpleGraph) =  SimpleGraph(g.vertices, g.ne, deepcopy(g.fadjlist))

==(g::SimpleGraph, h::SimpleGraph) =
    vertices(g) == vertices(h) &&
    ne(g) == ne(h) &&
    fadj(g) == fadj(h)


"""Return `true` if `g` is a directed graph."""
is_directed(::Type{SimpleGraph}) = false
is_directed{T}(::Type{SimpleGraph{T}}) = false
is_directed(g::SimpleGraph) = false

function has_edge(g::SimpleGraph, e::SimpleGraphEdge)
    u, v = Tuple(e)
    u > nv(g) || v > nv(g) && return false
    if degree(g,u) > degree(g,v)
        u, v = v, u
    end
    return length(searchsorted(fadj(g,u), v)) > 0
end

function add_edge!(g::SimpleGraph, e::SimpleGraphEdge)

    s, d = Tuple(e)
    (s in vertices(g) && d in vertices(g)) || return false
    inserted = _insert_and_dedup!(g.fadjlist[s], d)
    if inserted
        g.ne += 1
    end
    if s != d
        inserted = _insert_and_dedup!(g.fadjlist[d], s)
    end
    return inserted
end

function rem_edge!(g::SimpleGraph, e::SimpleGraphEdge)
    i = searchsorted(g.fadjlist[src(e)], dst(e))
    length(i) > 0 || return false   # edge not in graph
    i = i[1]
    deleteat!(g.fadjlist[src(e)], i)
    if src(e) != dst(e)     # not a self loop
        i = searchsorted(g.fadjlist[dst(e)], src(e))[1]
        deleteat!(g.fadjlist[dst(e)], i)
    end
    g.ne -= 1
    return true # edge successfully removed
end


"""Add a new vertex to the graph `g`."""
function add_vertex!{T<:Integer}(g::SimpleGraph{T})
    g.vertices = one(T):nv(g)+one(T)
    push!(g.fadjlist, Vector{T}())

    return true
end

empty{T<:Integer}(g::SimpleGraph{T}) = SimpleGraph{T}()
