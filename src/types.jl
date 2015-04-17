# Detect Elemental integer size
function ElIntType()
    using64 = Ref(zero(Cint))
    err = ccall((:ElUsing64BitInt, libEl), Cuint, (Ref{Cint},), using64)
    err == 0 || throw(ElError(err))
    return using64[] == 1 ? Int64 : Int32
end
const ElInt = ElIntType()

# Detect Elemental Bool type
function ElBoolType()
    boolsize = Ref(zero(Cuint))
    err = ccall((:ElSizeOfBool, libEl), Cint, (Ref{Cuint},), boolsize)
    err == 0 || throw(ElError(err))
    return boolsize[] == 1 ? Uint8 : Uint32
end
const ElBool = ElBoolType()

typealias ElFieldType Union(Float32,Float64,Complex64,Complex128)

typealias ElComplexType Union(Complex64,Complex128)

typealias ElFloatType Union(Float32,Float64)

abstract ElementalMatrix{T} <: AbstractMatrix{T}

immutable ElEntry{T<:ElFieldType}
    i::ElInt
    j::ElInt
    value::T
end
Base.zero{T<:ElFieldType}(::Type{ElEntry{T}}) =
    ElEntry{T}(zero(ElInt), zero(ElInt), zero(T))

@enum(ElDist,
      MC = Cint(0),
      MD = Cint(1),
      MR = Cint(2),
      VC = Cint(3),
      VR = Cint(4),
      STAR = Cint(5),
      CIRC = Cint(6))

@enum(ElOrientation,
      NORMAL    = Cint(0),
      TRANSPOSE = Cint(1),
      ADJOINT   = Cint(2))

@enum(ElSortType,
      UNSORTED   = Cint(0),
      DESCENDING = Cint(1),
      ASCENDING  = Cint(2))

@enum(ElUpperOrLower,
      LOWER = Cint(0),
      UPPER = Cint(1))
