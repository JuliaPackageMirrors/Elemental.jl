type DistMatrix{T} <: ElementalMatrix{T}
	obj::Ptr{Void}

    function DistMatrix(ptr::Ptr{Void})
        assert(ptr != C_NULL)
        D = new(ptr)
        finalizer(D, destroy)
        return D
    end
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistMatrix(::Type{$elty},
                            coldist::ElDist=MC,
                            rowdist::ElDist=MR,
                            grid=Grid())
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistMatrixCreateSpecific_", ext)), libEl), Cuint,
                (Cint, Cint, Ptr{Void}, Ref{Ptr{Void}}),
                coldist, rowdist, grid.obj, obj)
            err == 0 || throw(ElError(err))
            return DistMatrix{$elty}(obj[])
        end

        function destroy(A::DistMatrix{$elty})
            err = ccall(($(string("ElDistMatrixDestroy_", ext)), libEl), Cuint,
                (Ptr{Void},), A.obj)
            err == 0 || throw(ElError(err))
            return
        end

        function _getindex(A::DistMatrix{$elty}, i::Integer, j::Integer)
            1 <= i <= size(A, 1) || throw(BoundsError())
            1 <= j <= size(A, 2) || throw(BoundsError())
            v = Ref(zero($elty))
            err = ccall(($(string("ElDistMatrixGet_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, Ref{$elty}),
                A.obj, i-1 , j-1, v)
            err == 0 || throw(ElError(err))
            return v[]
        end

        function _setindex!(A::DistMatrix{$elty}, v, i::Integer, j::Integer)
            1 <= i <= size(A, 1) || throw(BoundsError())
            1 <= j <= size(A, 2) || throw(BoundsError())
            err = ccall(($(string("ElDistMatrixSet_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty),
                A.obj, i-1, j-1, v)
            err == 0 || throw(ElError(err))
            return A
        end

        function globalrow(A::DistMatrix{$elty}, i::Integer)
            1 <= i <= size(A, 1) || throw(BoundsError())
            r = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixGlobalRow_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, Ref{ElInt}),
                A.obj, i-1, r)
            err == 0 || throw(ElError(err))
            return Int(r[] + 1)
        end

        function globalcol(A::DistMatrix{$elty}, j::Integer)
            1 <= j <= size(A, 2) || throw(BoundsError())
            c = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixGlobalCol_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, Ref{ElInt}),
                A.obj, j-1, c)
            err == 0 || throw(ElError(err))
            return Int(c[] + 1)
        end

        function localwidth(A::DistMatrix{$elty})
            w = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixLocalWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, w)
            err == 0 || throw(ElError(err))
            return Int(w[])
        end

        function width(A::DistMatrix{$elty})
            w = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, w)
            err == 0 || throw(ElError(err))
            return Int(w[])
        end

        function localheight(A::DistMatrix{$elty})
            h = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixLocalHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, h)
            err == 0 || throw(ElError(err))
            return Int(h[])
        end

        function height(A::DistMatrix{$elty})
            h = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, h)
            err == 0 || throw(ElError(err))
            return Int(h[])
        end

        function localsetindex!(A::DistMatrix{$elty}, v::Number, i::Integer, j::Integer)
            1 <= i <= size(A, 1) || throw(BoundsError())
            1 <= j <= size(A, 2) || throw(BoundsError())
            err = ccall(($(string("ElDistMatrixSetLocal_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty),
                A.obj, i-1, j-1, v)
            err == 0 || throw(ElError(err))
            return A
        end
    end
end
DistMatrix() = DistMatrix(Float64)

# This might be wrong. Should consider how to extract distributions properties of A
similar{T}(A::DistMatrix{T}) = DistMatrix(T)

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function Grid(A::DistMatrix{$elty})
            g = Grid()
            err = ccall(($(string("ElDistMatrixGrid_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{Ptr{Void}}),
                A.obj, Ref{Ptr{Void}}(g.obj))
            err == 0 || throw(ElError(err))
            return g
        end
    end
end

Base.getindex(A::DistMatrix, i::Integer) = getindex(A, ind2sub(size(A), i)...)
Base.getindex(A::DistMatrix, i::Integer, j::Integer) = _getindex(A, i, j)

Base.setindex!(A::DistMatrix, v, i::Integer) = setindex!(A, v, ind2sub(size(A), i)...)
Base.setindex!(A::DistMatrix, v, i::Integer, j::Integer) = _setindex!(A, v, i, j)

localsize(A::DistMatrix) = (localheight(A), localwidth(A))
function localsize(A::DistMatrix, d::Integer)
    if d < 1 || d > 2
        throw(ArgumentError("dimension must be 1 or 2, got $d"))
    elseif d == 1
        return localheight(A)
    elseif d == 2
        return localwidth(A)
    end
end

localsetindex!(A::DistMatrix, v::Number, i::Integer) = localsetindex!(A, v, ind2sub(A, i)...)

Base.size(A::DistMatrix) = (height(A), width(A))
function Base.size(A::DistMatrix, d::Integer)
    if d < 1
        throw(ArgumentError("dimension must be ≥ 1, got $d"))
    elseif d == 1
        return height(A)
    elseif d == 2
        return width(A)
    else
        return 1
    end
end
