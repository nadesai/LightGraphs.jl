"""
Computes the articulation points(https://en.wikipedia.org/wiki/Biconnected_component)
of a connected graph `g` and returns an array containing all cut vertices.
"""
function articulation(g::AbstractGraph) :: AbstractArray
    state = Articulations(g)
    for u in vertices(g)
        if state.depth[u] == 0
            visit!(state, g, u, u)
        end
    end
    return find(state.articulation_points)
end

"""
Articulations: a state type for the Depth first search that finds the articulation points in a graph.
"""
type Articulations{T<:Integer}
    low::Vector{T}
    depth::Vector{T}
    articulation_points::BitArray
    id::T
end

function Articulations(g::AbstractGraph)
    n = nv(g)
    T = typeof(n)
    return Articulations(zeros(T, n), zeros(T, n), falses(n), zero(T))
end

"""
Does a depth first search storing the depth (in `depth`) and low-points (in `low`) of each vertex.
Call this function repeatedly to complete the DFS see `articulation` for usage.
"""
function visit!{T<:Integer}(state::Articulations, g::AbstractGraph, u::T, v::T)
    children = 0
    state.id += 1
    state.depth[v] = state.id
    state.low[v] = state.depth[v]

    for w in out_neighbors(g, v)
        if state.depth[w] == 0
            children += 1
            visit!(state, g, v, w)

            state.low[v] = min(state.low[v], state.low[w])
            if state.low[w] >= state.depth[v] && u != v
                state.articulation_points[v] = true
            end

        elseif w != u
            state.low[v] = min(state.low[v], state.depth[w])
        end
	  end
    if u == v && children > 1
        state.articulation_points[v] = true
    end
end
