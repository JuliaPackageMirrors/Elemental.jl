# Hermitian and tridiagonal eigensolvers

immutable HermitianEigSubset{T<:ElFloatType}
    indexSubset::ElBool
    lowerIndex::ElInt
    upperIndex::ElInt
    rangeSubset::ElBool
    lowerBound::T
    upperBound::T
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function hermitianEig(uplo::ElUpperOrLower,
                              A::DistMatrix{$elty})
            sort::ElSortType=ASCENDING
            w = DistMatrix($elty, STAR, STAR, Grid(A))
            X = DistMatrix($elty, MC, MR, Grid(A))
            err = ccall(($(string("ElHermitianEigPairDist", ext)), libEl),
                    (Cuint, Ptr{Void}, Ptr{Void}, Ptr{Void}, Cuint),
                    uplo, A.obj, w.obj, X.obj, sort)
            err == 0 || throw(ElError(err))
            return w
        end
    end
end
