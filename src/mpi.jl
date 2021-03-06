module MPI

using Compat
import Compat.String

using Elemental: ElComm, ElElementType, ElInt, CommWorld, libEl

function __init__()
    # FixMe! The symbol could probably also be missing for other implementations
    #
    # NOTE! I'm using RTLD_GLOBAL here to avoid the OPEN-MPI error described in
    # https://www.open-mpi.org/faq/?category=troubleshooting#missing-symbols
    if Libdl.dlsym_e(Libdl.dlopen(libEl, Libdl.RTLD_GLOBAL), :MPI_Get_library_version) == C_NULL
        const global MPIImpl = :MPICH2
    else
        versionBuffer = Array(UInt8, 2800)
        len = Cint[0]
        err = ccall((:MPI_Get_library_version, libEl), Cint, (Ptr{UInt8}, Ptr{Cint}), versionBuffer, len)
        versionString = String(versionBuffer[1:len[1]-1])
        if ismatch(r"Open MPI", versionString)
            const global MPIImpl = :OpenMPI
        elseif ismatch(r"MPICH", versionString)
            const global MPIImpl = :MPICH3
        else
            error("don't know which MPI implemetation you are using here")
        end
    end
end

function MPIType(t::DataType)
    if MPIImpl == :OpenMPI
        if t == Float64
            return Libdl.dlsym_e(Libdl.dlopen(libEl), :ompi_mpi_double)
        elseif t == Cint
            return Libdl.dlsym_e(Libdl.dlopen(libEl), :ompi_mpi_int)
        elseif t == Clong
            return Libdl.dlsym_e(Libdl.dlopen(libEl), :ompi_mpi_long_int)
        else
            error("data type not defined yet")
        end
    elseif MPIImpl == :MPICH2 || MPIImpl == :MPICH3
        if t == Float64
            return Cint(0x4c00080b)
        elseif t == Cint
            return Cint(0x4c000405)
        elseif t == Clong
            return Cint(0x4c000807)
        else
            error("data type not defined yet")
        end
    else
        error("MPI implementation not covered yet")
    end
end

function MPIOp(f::Function)
    if MPIImpl == :OpenMPI
        if f == (+)
            return Libdl.dlsym_e(Libdl.dlopen(libEl), :ompi_mpi_op_sum)
        else
            error("operation not defined yet")
        end
    elseif MPIImpl == :MPICH2 || MPIImpl == :MPICH3
        if f == (+)
            return Cint(0x58000003)
        else
            error("operation not defined yet")
        end
    else
        error("MPI implementaion no covered yet")
    end
end

function commRank(comm::ElComm)
    n = Ref{Cint}()
    err = ccall((:MPI_Comm_rank, libEl), Cint, (ElComm, Ref{Cint}), comm, n)
    if err != 0
        error("error value was $err")
    end
    return n[]
end

# FixMe! Should be restricted to support element types
function allreduce{T}(sendbuf::Ref{T}, recvbuf::Ref{T}, count::Integer, op::Function, comm::ElComm = CommWorld)
    err = ccall((:MPI_Allreduce, libEl), Cint,
        (Ref{T}, Ref{T}, Cint, ElComm, ElComm, ElComm),
        sendbuf, recvbuf, count, MPIType(T), MPIOp(op), comm)
    if err != 0
        error("error value was $err")
    end
    return recvbuf
end

allreduce{T}(value::T, op::Function, comm::ElComm = CommWorld) = ElInt(allreduce(Ref(value), Ref{T}(), 1, op, comm)[])

end # module
