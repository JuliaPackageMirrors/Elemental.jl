for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:SparseMatrix, "Sparse_"),
                       (:DistSparseMatrix, "DistSparse_"),
                       (:DistMultiVec, "DistMultiVec_"))
        @eval begin
            function maxNorm(A::$mat{$elty})
                v = Ref{$relty}(0)
                err = ccall(($(string("ElMaxNorm", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ref{$relty}),
                    A.obj, v)
                err == 0 || throw(ElError(err))
                return v[]
            end

            function entrywiseNorm(A::$mat{$elty}, p::Real)
                v = Ref{$relty}(0)
                err = ccall(($(string("ElEntrywiseNorm", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, $relty, Ref{$relty}),
                    A.obj, p, v)
                err == 0 || throw(ElError(err))
                return v[]
            end

            function frobeniusNorm(A::$mat{$elty})
                v = Ref{$relty}(0)
                err = ccall(($(string("ElFrobeniusNorm", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ref{$relty}),
                    A.obj, v)
                err == 0 || throw(ElError(err))
                return v[]
            end
        end
    end
end

Base.vecnorm(A::ElementalMatrix) = frobeniusNorm(A)
