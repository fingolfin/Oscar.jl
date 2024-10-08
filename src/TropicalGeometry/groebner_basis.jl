################################################################################
#
#  Tropical Groebner bases
#  =======================
#
#  For a definition of tropical Groebner basis see Section 2.4 in:
#    D. Maclagan, B. Sturmfels: Introduction to tropical geometry
#  To see how they can be computed using standard bases see:
#    T. Markwig, Y. Ren: Computing tropical varieties over fields with valuation
#
################################################################################



################################################################################
#
#  Simulating and desimulating valuations
#
################################################################################
@doc raw"""
    simulate_valuation(I::MPolyIdeal, nu::TropicalSemiringMap)

Given an ideal `I` in variables x1, ..., xn over a field with a tropical semiring map `nu`, return an ideal `sI` in variables tsim, x1, ..., xn such that tropical Groebner bases of `I` with respect to a weight vectors `w` correspond to standard bases of `sI` with respect to `(-1,-w)` (min-convention) or `(-1,w)` (max-convention).

# Example ($p$-adic)
```jldoctest
julia> nu_2 = tropical_semiring_map(QQ,2);

julia> Kx,(x1,x2,x3) = polynomial_ring(QQ,3);

julia> I = ideal([x1+2*x2,x2+2*x3]);

julia> simulate_valuation(I,nu_2)
Ideal generated by
  -tsim + 2
  tsim*x2 + x1
  tsim*x3 + x2

```

# Example ($t$-adic)
```jldoctest
julia> K,s = rational_function_field(GF(2),"s");

julia> nu_s = tropical_semiring_map(K,s);

julia> s = Oscar.valued_ring(nu_s)(s);

julia> Kx,(x1,x2,x3) = polynomial_ring(K,3);

julia> I = ideal([x1+s*x2,x2+s*x3]);

julia> simulate_valuation(I,nu_s)
Ideal generated by
  tsim + s
  tsim*x2 + x1
  tsim*x3 + x2

```
"""
function simulate_valuation(I::MPolyIdeal, nu::TropicalSemiringMap)
    @req !isempty(gens(I)) "input ideal empty"

    R = valued_ring(nu)
    Rtx,tx = polynomial_ring(R,vcat([:tsim],symbols(base_ring(I))))

    sG = [R(uniformizer(nu))-tx[1]]
    for f in clear_coefficient_denominators.(gens(I))
        fRtx = MPolyBuildCtx(Rtx)
        for (cK,expvKx) = zip(coefficients(f),exponents(f))
            cR = numerator(cK)          # coefficient in R
            expvRtx = vcat([0],expvKx)  # exponent vector in R[t,x1,...,xn]
            push_term!(fRtx,cR,expvRtx)
        end
        push!(sG,tighten_simulation(finish(fRtx),nu))
    end

    return ideal(Rtx,sG)
end
function clear_coefficient_denominators(f::MPolyRingElem)
    return lcm(denominator.(coefficients(f)))*f
end
# if valuation trivial, do nothing
function simulate_valuation(I::MPolyIdeal, ::TropicalSemiringMap{K,Nothing,<:Union{typeof(min),typeof(max)}}) where {K}
    return I
end



@doc raw"""
    tighten_simulation(f::MPolyRingElem, nu::TropicalSemiringMap)

Given a polynomial `f` in the simulation ring, "replace" the uniformizer with the first variable `tsim`, and divide by the gcd of all coefficients and the highest possible power of `tsim`.  The result is a polynomial whose coefficient valuations have been encoded in the exponents of `tsim`.

# Example ($p$-adic)
```jldoctest
julia> nu_2 = tropical_semiring_map(QQ,2)
Map into Min tropical semiring encoding the 2-adic valuation on Rational field

julia> Rtx,(p,x1,x2,x3) = Oscar.valued_ring(nu_2)["p","x1","x2","x3"]
(Multivariate polynomial ring in 4 variables over ZZ, ZZMPolyRingElem[p, x1, x2, x3])

julia> f = x1+p*x1+p^2*x1+2^2*x2+p*x2+p^2*x2+x3
p^2*x1 + p^2*x2 + p*x1 + p*x2 + x1 + 4*x2 + x3

julia> Oscar.tighten_simulation(f,nu_2)
5*p*x2 + 7*x1 + x3

julia> Oscar.tighten_simulation(2^3*f,nu_2)
5*p*x2 + 7*x1 + x3

julia> Oscar.tighten_simulation(p^3*f,nu_2)
5*p*x2 + 7*x1 + x3

```

# Example ($t$-adic)
```jldoctest
julia> K,s = rational_function_field(GF(2),"s");

julia> nu_s = tropical_semiring_map(K,s);

julia> s = Oscar.valued_ring(nu_s)(s);

julia> Rtx,(t,x1,x2,x3) = Oscar.valued_ring(nu_s)["t","x1","x2","x3"];

julia> f = x1+t*x1+t^2*x1+s^2*x2+t*x2+t^2*x2+x3
t^2*x1 + t^2*x2 + t*x1 + t*x2 + x1 + s^2*x2 + x3

julia> Oscar.tighten_simulation(f,nu_s)
t*x2 + (s^2 + s + 1)*x1 + x3

julia> Oscar.tighten_simulation(s^3*f,nu_s)
t*x2 + (s^2 + s + 1)*x1 + x3

julia> Oscar.tighten_simulation(t^3*f,nu_s)
t*x2 + (s^2 + s + 1)*x1 + x3

```
"""
function tighten_simulation(f::MPolyRingElem, nu::TropicalSemiringMap)
    # substitute first variable tsim by uniformizer_ring
    # so that all monomials have distinct x-monomials
    f = evaluate(f,[1],[uniformizer(nu)])

    # divide f by the gcd of its coefficients
    f /= gcd(collect(coefficients(f)))

    # undo previous substitution by replace uniformizer with first variable
    sf = MPolyBuildCtx(parent(f))
    for (c,alpha) in zip(coefficients(f),exponents(f))
        d = Int(nu(c); preserve_ordering=true)
        c /= uniformizer(nu)^d  # divide uniformizer out of coefficient
        alpha[1] += d           # increase exponent in tsim instead
        push_term!(sf,c,alpha)
    end
    return finish(sf)
end
# if valuation trivial, do nothing
function tighten_simulation(f::MPolyRingElem, ::TropicalSemiringMap{K,Nothing,minOrMax}) where {K, minOrMax<:Union{typeof(min),typeof(max)}}
    return f
end



@doc raw"""
    simulate_valuation(w::AbstractVector{<:Union{QQFieldElem,ZZRingElem,Rational,Integer}}, nu::TropicalSemiringMap{K,p,<:Union{typeof(min),typeof(max)}; perturbation::Union{Nothing,AbstractVector}=nothing) where {K,p}

Return an integer vector `wSim` so that the (tropical) Groebner basis of an ideal `I` with respect to `w` corresponds to the standard basis of its simulation with respect to `wSim`.  If `pertubation!=nothing`, also returns a corresponding `perturbationSim`.

# Example
```jldoctest
julia> nuMin = tropical_semiring_map(QQ,2);

julia> nuMax = tropical_semiring_map(QQ,2,max);

julia> w = QQ.([1,1]);

julia> u = QQ.([1,0]);

julia> simulate_valuation(w,nuMin;perturbation=u)
(QQFieldElem[-1, -1, -1], QQFieldElem[0, -1, 0])

julia> simulate_valuation(w,nuMax;perturbation=u)
(QQFieldElem[-1, 1, 1], [0, 1, 0])

```
"""
function simulate_valuation(w::AbstractVector{QQFieldElem}, ::TropicalSemiringMap{K,p,typeof(min)}; perturbation::Union{Nothing,AbstractVector}=nothing) where {K,p}
    w = vcat([one(QQ)],w)        # prepend +1 to the vector
    w .*= -lcm(denominator.(w))  # scale vector to make entries integral
                                 # negate vector to convert to max convention for Singular
    if !isnothing(perturbation)
        perturbation = vcat([0],perturbation)
        perturbation .*= -lcm(denominator.(perturbation))
        return w, perturbation
    end
    return w
end
function simulate_valuation(w::AbstractVector{QQFieldElem}, ::TropicalSemiringMap{K,p,typeof(max)}; perturbation::Union{Nothing,AbstractVector}=nothing) where {K,p}
    w = vcat([-one(QQ)],w)      # prepend -1 to the vector
    w .*= lcm(denominator.(w))  # scale vector to make entries integral
    if !isnothing(perturbation)
        perturbation = vcat([0],perturbation)
        perturbation .*= lcm(denominator.(perturbation))
        perturbation = Int.(perturbation)
        return w, perturbation
    end
    return w
end
# if valuation is trivial, just flip sign depending on convention
function simulate_valuation(w::AbstractVector{QQFieldElem}, ::TropicalSemiringMap{K,Nothing,typeof(min)}; perturbation::Union{Nothing,AbstractVector}=nothing) where {K}
    isnothing(perturbation) ? (return -w) : (return -w, -perturbation)
end
function simulate_valuation(w::AbstractVector{QQFieldElem}, ::TropicalSemiringMap{K,Nothing,typeof(max)}; perturbation::Union{Nothing,AbstractVector}=nothing) where {K}
    isnothing(perturbation) ? (return w) : (return w,perturbation)
end



@doc raw"""
    desimulate_valuation(sG::AbstractVector{<:MPolyRingElem}, nu::TropicalSemiringMap)

Given a generating set of the simulation ideal, reconstruct a generating set of the original ideal.  In pparticular, given a standard basis of the simulation ideal with respect to `wSim`, return the (tropical) Groebner basis of the original ideal with respect to `w`.

# Example ($p$-adic)
```jldoctest
julia> nu_2 = tropical_semiring_map(QQ,2);

julia> Kx,(x1,x2,x3) = polynomial_ring(QQ,3);

julia> I = ideal(Kx,[x1+2*x2,x2+2*x3])
Ideal generated by
  x1 + 2*x2
  x2 + 2*x3

julia> sG = gens(simulate_valuation(I,nu_2))
3-element Vector{ZZMPolyRingElem}:
 -tsim + 2
 tsim*x2 + x1
 tsim*x3 + x2

julia> desimulate_valuation(sG,nu_2)
2-element Vector{QQMPolyRingElem}:
 x1 + 2*x2
 x2 + 2*x3

```
"""
function desimulate_valuation(sG::AbstractVector{<:MPolyRingElem}, nu::TropicalSemiringMap)
    # construct original polynomial ring over valued field
    Rtx = parent(first(sG))
    xSymbols = copy(symbols(Rtx))[2:end]
    K = valued_field(nu)
    Kx,x = polynomial_ring(K,xSymbols)

    # map everything from simulation ring to original polynomial ring
    # whilst substituting first variable tsim by uniformizer
    desimulation_map = hom(Rtx,Kx,c->K(c),vcat(Kx(uniformizer(nu)),x))
    G = desimulation_map.(sG)
    return G[findall(!iszero,G)] # return only non-zero elements
end
# if valuation trivial, do nothing
function desimulate_valuation(sG::AbstractVector{<:MPolyRingElem}, ::TropicalSemiringMap{K,Nothing,minOrMax}) where {K,minOrMax<:Union{typeof(min),typeof(max)}}
    return sG
end



@doc raw"""
    desimulate_valuation(w::AbstractVector, nu::TropicalSemiringMap{K,p,typeof(min)}; perturbation::Union{Nothing,AbstractVector}=nothing) where {K,p}

Given a weight vector `wSim` on the simulation ring, return weight vector `w` on the original polynomial ring so that a standard basis with respect to `wSim` corresponds to a (tropical) Groebner basis with respect to `w`.

# Example
```jldoctest
julia> nuMin = tropical_semiring_map(QQ,2);

julia> nuMax = tropical_semiring_map(QQ,2,max);

julia> w = QQ.([1,1]);

julia> u = QQ.([1,0]);

julia> wSim, uSim = simulate_valuation(w,nuMin;perturbation=u)
(QQFieldElem[-1, -1, -1], QQFieldElem[0, -1, 0])

julia> desimulate_valuation(wSim, nuMin; perturbation=uSim)
(QQFieldElem[1, 1], QQFieldElem[1, 0])

julia> wSim, uSim = simulate_valuation(w,nuMax;perturbation=u)
(QQFieldElem[-1, 1, 1], [0, 1, 0])

julia> desimulate_valuation(wSim, nuMax; perturbation=uSim)
(QQFieldElem[1, 1], [1, 0])

```
"""
function desimulate_valuation(w::AbstractVector{QQFieldElem}, ::TropicalSemiringMap{K,p,typeof(min)}; perturbation::Union{Nothing,AbstractVector}=nothing) where {K,p}
    @req w[1]<0 "invalid weight vector"
    # scale the vector so that first entry is 1, then remove first entry
    w = w[2:end] ./ w[1]
    if !isnothing(perturbation)
        # negate vector, then remove first entry
        perturbation = perturbation[2:end] * -1
        return w,perturbation
    end
    return w
end
function desimulate_valuation(w::AbstractVector{QQFieldElem}, ::TropicalSemiringMap{K,p,typeof(max)}; perturbation::Union{Nothing,AbstractVector}=nothing) where {K,p}
    @req w[1]<0 "invalid weight vector"
    # scale the vector so that first entry is -1, then remove first entry
    w = w[2:end] ./ -w[1]
    if !isnothing(perturbation)
        # remove first entry
        perturbation = perturbation[2:end]
        return w,perturbation
    end
    return w
end
# if trivial valuation, just flip sign depending on convention
function desimulate_valuation(w::AbstractVector{QQFieldElem}, ::TropicalSemiringMap{K,Nothing,typeof(min)}; perturbation::Union{Nothing,AbstractVector}=nothing) where {K}
    isnothing(perturbation) ? (return -w) : (return -w,-perturbation)
end
function desimulate_valuation(w::AbstractVector{QQFieldElem}, ::TropicalSemiringMap{K,Nothing,typeof(max)}; perturbation::Union{Nothing,AbstractVector}=nothing) where {K}
    isnothing(perturbation) ? (return w) : (return w,perturbation)
end



################################################################################
#
#  (Tropical) Groebner bases
#
################################################################################
@doc raw"""
    groebner_basis(I::MPolyIdeal, nu::TropicalSemiringMap, w::AbstractVector{<:Union{QQFieldElem,ZZRingElem,Rational,Integer}})

Return a (tropical) Groebner basis of `I` with respect to the tropical semiring map `nu` and weight vector `w`.

!!! warning
    No general algorithm for (tropical) computing Groebner bases exist and `groebner_basis` will return an error if it does not know how to compute one for the input.
    For a list of cases in which Groebner bases can be computed, see Section "Groebner Theory" in the documentation.

# Examples
```jldoctest
julia> R,(x,y) = QQ["x","y"];

julia> I = ideal([x^3-5*x^2*y,3*y^3-2*x^2*y]);

julia> nu = tropical_semiring_map(QQ,2);

julia> w = [0,0];

julia> groebner_basis(I,nu,w)
2-element Vector{QQMPolyRingElem}:
 x^3 - 5*x^2*y
 -2*x^2*y + 3*y^3

```
"""
function groebner_basis(I::MPolyIdeal, nu::TropicalSemiringMap, w::AbstractVector{<:Union{QQFieldElem,ZZRingElem,Rational,Integer}})

    G = gens(I)

    ###
    # Principal ideal, return G
    ###
    if isone(length(G))
        return gens(I)
    end

    ###
    # Binomial ideal, return G if w is in the tropicalization, continue with general algorithm if it is not
    ###
    if all(isequal(2),length.(G)) && all(isequal(2),length.(initial.(G,Ref(nu),Ref(w))))
        return G
    end

    ###
    # Linear ideal, do a reduced row echelon form of the Macaulay matrix sorted by w
    ###
    if all(isequal(1),total_degree.(G)) && is_trivial(nu)
        R = base_ring(I)
        K = coefficient_ring(R)
        xand1 = vcat(gens(R),[one(R)])
        wand0 = tropical_semiring(nu).(vcat(w,[0]))
        xand1Sorted = xand1[sortperm(wand0)]
        macaulayMatrixSorted = matrix(K,[[coeff(g,xj) for xj in xand1Sorted] for g in G])
        return rref(macaulayMatrixSorted)[2]*xand1Sorted
    end

    ###
    # Trivial valuation, return classical Groebner basis of `I` is weight vector can be made into a global ordering
    ###
    if is_trivial(nu) && convention(nu)==max && all(is_positive.(w))
        return groebner_basis(I,ordering=weight_ordering(Int.(w),default_ordering(base_ring(I))))
    end
    if is_trivial(nu) && convention(nu)==min && all(is_negative.(w))
        return groebner_basis(I,ordering=weight_ordering(Int.(-w),default_ordering(base_ring(I))))
    end

    @req (is_trivial(nu)&&all(is_positive.(w))) || all(Oscar._is_homogeneous,G) "if semiring map non-trivial or weight vector not positive, input ideal needs homogeneous generators"
    Isim = simulate_valuation(I,nu)
    wSim = simulate_valuation(QQ.(w),nu)
    # TODO: experiment with different tiebreaker orderings
    oSim = weight_ordering(Int.(wSim),default_ordering(base_ring(Isim)))
    Gsim = standard_basis(Isim; ordering = oSim)
    G = desimulate_valuation(gens(Gsim),nu)
    return G
end
