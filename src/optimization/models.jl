for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))

    for (matA, matb, sym) in ((:Matrix, :Matrix, "_"),
                              (:DistMatrix, :DistMatrix, "Dist_"),
                              (:SparseMatrix, :Matrix, "Sparse_"),
                              (:DistSparseMatrix, :DistMultiVec, "DistSparse_"))
        @eval begin
            function lav!(A::$matA{$elty}, b::$matb{$elty}, x::$matb{$elty})
                err = ccall(($(string("ElLAV", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, Ptr{Void}),
                    A.obj, b.obj, x.obj)
                err == 0 || throw(ElError(err))
                return x
            end

            function lav!(A::$matA{$elty}, b::$matb{$elty}, x::$matb{$elty}, ctrl::LPAffineCtrl{$elty})
                err = ccall(($(string("ElLAVX", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, Ptr{Void}, LPAffineCtrl{$elty}),
                    A.obj, b.obj, x.obj, ctrl)
                err == 0 || throw(ElError(err))
                return x
            end
        end
    end
    @eval begin
        function lav(A::Matrix{$elty}, b::Matrix{$elty})
            x = Matrix($elty)
            return lav!(A, b, x)
        end
        function lav(A::DistMatrix{$elty}, b::DistMatrix{$elty})
            x = DistMatrix($elty, MC, MR, Grid(A))
            return lav!(A, b, x)
        end
        function lav(A::DistSparseMatrix{$elty}, b::DistMultiVec{$elty})
            x = DistMultiVec($elty, comm(A))
            return lav!(A, b, x)
        end

        function lav(A::DistSparseMatrix{$elty}, b::DistMultiVec{$elty}, ctrl::LPAffineCtrl{$elty})
            x = DistMultiVec($elty, comm(A))
            return lav!(A, b, x, ctrl)
        end
    end
end

for (elty, rty, ext) in ((:Float32,    :Float32, :s),
                         (:Float64,    :Float64, :d),
                         (:Complex64,  :Float32, :c),
                         (:Complex128, :Float64, :z))
    @eval begin
        function spinvcov(A::DistMatrix{$elty}, lambda::Number)
            lam = convert($rty, lambda)
            Z = DistMatrix($elty)
            niter = Ref(zero(ElInt))
            err = ccall(($(string("ElSparseInvCov",ext)), libEl), Cuint,
                (Ptr{Void},$rty,Ptr{Void},Ref{ElInt}),
                A.obj, lam, Z.obj, niter)
            err == 0 || throw(ElError(err))
            return (Z, Int(niter[]))
        end
    end
end
