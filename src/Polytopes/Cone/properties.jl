###############################################################################
###############################################################################
### Iterators
###############################################################################
###############################################################################

struct ConeRayIterator
    cone::Cone
end

function Base.iterate(iter::ConeRayIterator, index = 1)
    rays = pm_cone(iter.cone).RAYS
    if size(rays, 1) < index
        return nothing
    end

    return (rays[index, :], index + 1)
end
Base.eltype(::Type{ConeRayIterator}) = Polymake.Vector{Polymake.Rational}
Base.length(iter::ConeRayIterator) = nrays(iter.cone)

"""
    rays(C)

Return the rays of a cone.

# Arguments
- `C::Cone`: A cone.

# Examples
Here a cone is constructed from three rays. Calling `rays` reveals that one of these was redundant:
```julia-repl
julia> R = [1 0; 0 1; 0 2];

julia> PO = positive_hull(R);

julia> collect(rays(PO))
2-element Vector{Polymake.Vector{Polymake.Rational}}:
 pm::Vector<pm::Rational>
1 0
 pm::Vector<pm::Rational>
0 1
```
"""
rays(C::Cone) = ConeRayIterator(C)

###############################################################################
###############################################################################
### Access properties
###############################################################################
###############################################################################

###############################################################################
## Scalar properties
###############################################################################

"""
    nrays(C)

Return the number of rays of the cone `C`.

# Arguments
- `C::Cone`: A cone.

# Examples
Here a cone is constructed from three rays. Calling `nrays` reveals that one of these was redundant:
```julia-repl
julia> R = [1 0; 0 1; 0 2];

julia> PO = positive_hull(R);

julia> nrays(PO)
2
```
"""
nrays(C::Cone) = pm_cone(C).N_RAYS

"""
    dim(C)

Return the dimension of a cone.

# Arguments
- `C::Cone`: A cone.

# Examples
The cone `C` in this example is 2-dimensional within a 3-dimensional ambient space.
```julia-repl
julia> C = Cone([1 0 0; 1 1 0; 0 1 0]);

julia> dim(C)
2
```
"""
dim(C::Cone) = pm_cone(C).CONE_DIM

"""
    ambient_dim(C)

Return the ambient dimension of a cone.

# Arguments
- `C::Cone`: A cone.

# Examples
The cone `C` in this example is 2-dimensional within a 3-dimensional ambient space.
```julia-repl
julia> C = Cone([1 0 0; 1 1 0; 0 1 0]);

julia> ambient_dim(C)
3
```
"""
ambient_dim(C::Cone) = pm_cone(C).CONE_AMBIENT_DIM

"""
    codim(C)

Returns the codimension of a cone.

# Arguments
- `C::Cone`: A cone.

# Examples
The cone `C` in this example is 2-dimensional within a 3-dimensional ambient space.
```julia-repl
julia> C = Cone([1 0 0; 1 1 0; 0 1 0]);

julia> codim(C)
1
```
"""
codim(C::Cone) = ambient_dim(C)-dim(C)

###############################################################################
## Boolean properties
###############################################################################
"""
    ispointed(C)

Determine whether the cone is pointed, i.e. whether 0 is a face of the cone.

# Arguments
- `C::Cone`: A cone.

# Examples
A cone with lineality is not pointed, but a cone only consisting of a single ray is.
```julia-repl
julia> C = Cone([1 0], [0 1]);

julia> ispointed(C)
false

julia> C = Cone([1 0]);

julia> ispointed(C)
true
```
"""
ispointed(C::Cone) = pm_cone(C).POINTED

"""
    isfulldimensional(C)

Determine whether the cone is full dimensional

# Arguments
- `C::Cone`: A cone.

# Examples
The cone `C` in this example is 2-dimensional within a 3-dimensional ambient space.
```julia-repl
julia> C = Cone([1 0 0; 1 1 0; 0 1 0]);

julia> isfulldimensional(C)
false
```
"""
isfulldimensional(C::Cone) = pm_cone(C).FULL_DIM

###############################################################################
## Points properties
###############################################################################

"""
    rays_as_point_matrix(C)

Return the rays of a cone as rows in a matrix.

# Arguments
- `C::Cone`: A cone.

# Examples
Here a cone is constructed from three rays. Calling `rays_as_point_matrix` reveals that one of these was redundant:
```julia-repl
julia> R = [1 0; 0 1; 0 2];

julia> PO = positive_hull(R);

julia> rays_as_point_matrix(PO)
pm::Matrix<pm::Rational>
1 0
0 1
```
"""
function rays_as_point_matrix(C::Cone)
    pm_cone(C).RAYS
end


"""
    facets_as_point_matrix(C)

Return the facets of a cone as rows of a matrix.

# Arguments
- `C::Cone`: A cone.

# Examples
From this little example it is easy to see that the facets are displayed as their inside-pointing (w.r.t. the cone) normals.
```julia-repl
julia> R = [1 0; 1 1];

julia> C = positive_hull(R);

julia> facets_as_point_matrix(C)
pm::Matrix<pm::Rational>
0 1
1 -1
```
"""
facets_as_point_matrix(C::Cone) = pm_cone(C).FACETS


"""
    lineality_space(C)

Return a basis of the lineality space of a cone.

# Arguments
- `C::Cone`: A cone.

# Examples
Three rays are used here to construct the upper half-plane. Actually, two of these rays point in opposite directions.
This gives us a 1-dimensional lineality.
```julia-repl
julia> UH = Cone([1 0; 0 1; -1 0]);

julia> lineality_space(UH)
pm::Matrix<pm::Rational>
1 0
```
"""
lineality_space(C::Cone) = pm_cone(C).LINEALITY_SPACE

"""
    hilbert_basis(C)

Return the Hilbert basis of a pointed cone as the rows of a matrix.

# Arguments
- `C::Cone`: A cone.

# Examples
This (non-smooth) cone in the plane has a hilbert basis with three elements.
```julia-repl
julia> C = Cone([1 0; 1 2])
A polyhedral cone in ambient dimension 2

julia> hilbert_basis(C)
pm::Matrix<pm::Integer>
1 0
1 1
1 2
```
"""
function hilbert_basis(C::Cone)
   if ispointed(C)
      return pm_cone(C).HILBERT_BASIS_GENERATORS[1]
   else
      throw(ArgumentError("Cone not pointed."))
   end
end
