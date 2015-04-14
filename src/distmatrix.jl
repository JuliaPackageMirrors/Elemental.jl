type DistMatrix{T} <: ElementalMatrix{T}
	obj::Ptr{Void}
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistMatrix(::Type{$elty}, coldist=EL_MC, rowdist=EL_MR, grid=Grid())
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistMatrixCreateSpecific_", ext)), libEl), Cuint,
                (Cint, Cint, Ptr{Void}, Ref{Ptr{Void}}),
                coldist, rowdist, grid.obj, obj)
            err == 0 || throw(ElError(err))
            return DistMatrix{$elty}(obj[])
        end

        function width(A::DistMatrix{$elty})
            w = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, w)
            err == 0 || throw(ElError(err))
            return Int(w[])
        end

        function height(A::DistMatrix{$elty})
            h = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, h)
            err == 0 || throw(ElError(err))
            return Int(h[])
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

Base.size(A::DistMatrix) = (Int(height(A)), Int(width(A)))
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
