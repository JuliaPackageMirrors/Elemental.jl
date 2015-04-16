for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d))
    for (matA, matB, sym) in ((:Matrix, :Matrix, "_"),
                              (:DistMatrix, :DistMatrix, "Dist_"),
                              (:SparseMatrix, :Matrix, "Sparse_"),
                              (:DistSparseMatrix, :DistMultiVec, "DistSparse_"))
        @eval begin
            function leastSquares!(A::$matA{$elty},
                                   B::$matB{$elty},
                                   X::$matB{$elty};
                                   orientation::ElOrientation=NORMAL)
                err = ccall(($(string("ElLeastSquares", sym, ext)), libEl), Cuint,
                    (Cint, Ptr{Void}, Ptr{Void}, Ptr{Void}),
                    orientation, A.obj, B.obj, X.obj)
                err == 0 || throw(ElError(err))
                return X
            end
        end
    end
end

function leastSquares{T<:ElFloatType}(A::DistMatrix{T},
                                      B::DistMatrix{T};
                                      orientation::ElOrientation=NORMAL)
    X = DistMatrix(T, EL_MC, EL_MR, Grid(A))
    return leastSquares!(A, B, X, orientation=orientation)
end

function leastSquares{T<:ElFloatType}(A::DistSparseMatrix{T},
                                      B::DistMultiVec{T};
                                      orientation::ElOrientation=NORMAL)
    X = DistMultiVec(T, comm(A))
    return leastSquares!(A, B, X, orientation=orientation)
end
