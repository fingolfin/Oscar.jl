@doc Markdown.doc"""
    toric_ideal_binomial_generators(pts::Matrix{Int})

Get the exponent vectors corresponding to the generators of the toric ideal
coming from the affine relations between the rows of `pts`.

# Examples
```jldoctest
julia> C = positive_hull([-2 5; 1 0]);

julia> H = hilbert_basis(C).m
pm::Matrix<pm::Integer>
1 0
0 1
-2 5
-1 3


julia> toric_ideal_binomial_generators(H)
[2   -5   1   0]
[1   -3   0   1]
```
"""
function toric_ideal_binomial_generators(pts::AbstractMatrix)
    result = kernel(matrix(ZZ, pts), side=:left)
    return result[2]
end



@doc Markdown.doc"""
    toric_ideal_binomial_generators(antv::AffineNormalToricVariety)

Get the exponent vectors corresponding to the generators of the toric ideal
associated to the affine normal toric variety `antv`.

# Examples
Take the cyclic quotient singularity corresponding to the pair of integers
`(2,5)`.
```jldoctest
julia> C = positive_hull([-2 5; 1 0])
A polyhedral cone in ambient dimension 2

julia> antv = AffineNormalToricVariety(C)
A normal toric variety corresponding to a polyhedral fan in ambient dimension 2

julia> toric_ideal_binomial_generators(antv)
[-2   -1    5   0]
[ 1    0   -3   1]
```
"""
function toric_ideal_binomial_generators(antv::AffineNormalToricVariety)
    cone = Cone(pm_ntv(antv).WEIGHT_CONE)
    return toric_ideal_binomial_generators(hilbert_basis(cone).m)
end
export toric_ideal_binomial_generators
toric_ideal_binomial_generators(ntv::NormalToricVariety) = toric_ideal_binomial_generators(AffineNormalToricVariety(ntv))


@doc Markdown.doc"""
    binomial_exponents_to_ideal(binoms::Union{AbstractMatrix, fmpz_mat})

This function converts the rows of a matrix to binomials. Each row $r$ is
written as $r=u-v$ with $u,v\ge 0$ by splitting into positive and negative
entries. Then the row $r$ corresponds to $x^u-x^v$.  The resulting ideal is
returned.

# Examples
```jldoctest
julia> C = positive_hull([-2 5; 1 0]);

julia> H = hilbert_basis(C).m;

julia> B = toric_ideal_binomial_generators(H)
[2   -5   1   0]
[1   -3   0   1]

julia> I = binomial_exponents_to_ideal(B)
ideal(x[1]^2*x[3] - x[2]^5, x[1]*x[4] - x[2]^3)
```
"""
function binomial_exponents_to_ideal(binoms::Union{AbstractMatrix, fmpz_mat})
    nvars = ncols(binoms)
    R, x = PolynomialRing(QQ, "x" => 1:nvars)
    terms = Vector{fmpq_mpoly}(undef, nrows(binoms))
    for i in 1:nrows(binoms)
        binom = binoms[i, :]
        xpos = one(R)
        xneg = one(R)
        for j in 1:nvars
            if binom[j] < 0
                xneg = xneg * x[j]^(-binom[j])
            elseif binom[j] > 0
                xpos = xpos * x[j]^(binom[j])
            end
        end
        terms[i] = xpos-xneg
    end
    return ideal(terms)
end
export binomial_exponents_to_ideal


@doc Markdown.doc"""
    toric_ideal(pts::AbstractMatrix)

Return the toric ideal generated from the affine relations between the points
`pts`.

# Examples
```jldoctest
julia> C = positive_hull([-2 5; 1 0]);

julia> H = hilbert_basis(C).m;

julia> toric_ideal(H)
ideal(x[1]^2*x[3] - x[2]^5, x[1]*x[4] - x[2]^3)
```
"""
function toric_ideal(pts::AbstractMatrix)
    binoms = toric_ideal_binomial_generators(pts)
    return binomial_exponents_to_ideal(binoms)
end


@doc Markdown.doc"""
    toric_ideal(antv::AffineNormalToricVariety)

Return the toric ideal defining the affine normal toric variety.

# Examples
Take the cone over the square at height one. The resulting toric variety has
one defining equation. In projective space this corresponds to
$\mathbb{P}^1\times\mathbb{P}^1$. Note that this cone is self-dual, the toric
ideal comes from the dual cone.
```jldoctest
julia> C = positive_hull([1 0 0; 1 1 0; 1 0 1; 1 1 1])
A polyhedral cone in ambient dimension 3

julia> antv = AffineNormalToricVariety(C)
A normal toric variety corresponding to a polyhedral fan in ambient dimension 3

julia> toric_ideal(antv)
ideal(-x[1]*x[2] + x[3]*x[4])
```
"""
function toric_ideal(antv::AffineNormalToricVariety)
    binoms = toric_ideal_binomial_generators(antv)
    return binomial_exponents_to_ideal(binoms)
end
export toric_ideal
toric_ideal(ntv::NormalToricVariety) = toric_ideal(AffineNormalToricVariety(ntv))




