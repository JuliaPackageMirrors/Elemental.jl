for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:DistMultiVec, "DistMultiVec_"))
        @eval begin
            function nrm2(x::$mat{$elty})
                nm = Ref{$relty}(0)
                err = ccall(($(string("ElNrm2", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ref{$relty}),
                    x.obj, nm)
                err == 0 || throw(ElError(err))
                return nm[]
            end

            function copy!(src::$mat{$elty}, dest::$mat{$elty})
                err = ccall(($(string("ElCopy", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}),
                    src.obj, dest.obj)
                err == 0 || throw(ELError(err))
                dest
            end
        end
    end
end
copy(A::ElementalMatrix) = copy!(A, similar(A))


for (mat, sym) in ((:DistMatrix, "Dist_"),)

    for (elty, ext) in ((:Complex64, :c),
                        (:Complex128, :z))
        @eval begin
            function makeSymmetric!(uplo::ElUpperOrLower, A::$mat{$elty}, conj=false)
                conj && return MakeHermitian!(uplo, A)
                err = ccall(($(string("ElMakeSymmetric", sym, ext)), libEl), Cuint,
                    (Cuint, Ptr{Void}),
                    uplo, A.obj)
                err == 0 || throw(ElError(err))
                return A
            end

            function makeHermitian!(uplo::ElUpperOrLower, A::$mat{$elty})
                err = ccall(($(string("ElMakeHermitian", sym, ext)), libEl), Cuint,
                    (Cuint, Ptr{Void}),
                    uplo, A.obj)
                err == 0 || throw(ElError(err))
                return A
            end
        end
    end

    for (elty, ext) in ((:Float32, :s),
                        (:Float64, :d))
        @eval begin
            function makeSymmetric!(uplo::ElUpperOrLower, A::$mat{$elty}, conj=false)
                err = ccall(($(string("ElMakeSymmetric", sym, ext)), libEl), Cuint,
                    (Cuint, Ptr{Void}),
                    uplo, A.obj)
                err == 0 || throw(ElError(err))
                return A
            end
            makeHermitian!(uplo::ElUpperOrLower, A::$mat{$elty}) =
                makeSymmetric!(uplo, A)
        end
    end
end
