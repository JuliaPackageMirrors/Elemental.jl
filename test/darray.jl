using Base.Test
using Elemental
using DistributedArrays

# dense
A = drandn(50,50)
Al = convert(Array, A)
B = drandn(50,10)
Bl = convert(Array, B)

@test inv(Al) ≈ inv(A)
@test Al\Bl ≈ A\B
@test logdet(Al'Al) ≈ logdet(A'A)
@test svdvals(Al) ≈ Elemental.svdvals(A)

# sparse
A = sprandn(5, 5, 0.5)
AD = distribute(A)
## change to work directly on the DArray when more functionality has been implemented
AE = Elemental.toback(AD)
@test fetch([remotecall((t1, t2, t3) -> ((fetch(t1)*t2)'*t3)[1], AE[i,j].where, AE[i,j], [1.0;0;0;0;0], [1.0;0;0;0;0]) for i = 1:size(AE, 1), j = 1:size(AE, 2)][1]) ≈ A[1,1]
@test fetch([remotecall((t1, t2, t3) -> ((fetch(t1)*t2)'*t3)[1], AE[i,j].where, AE[i,j], [0.0;0;0;0;1], [1.0;0;0;0;0]) for i = 1:size(AE, 1), j = 1:size(AE, 2)][1]) ≈ A[1,5]
@test fetch([remotecall((t1, t2, t3) -> ((fetch(t1)*t2)'*t3)[1], AE[i,j].where, AE[i,j], [1.0;0;0;0;0], [0.0;0;0;0;1]) for i = 1:size(AE, 1), j = 1:size(AE, 2)][1]) ≈ A[5,1]
@test fetch([remotecall((t1, t2, t3) -> ((fetch(t1)*t2)'*t3)[1], AE[i,j].where, AE[i,j], [0.0;0;0;0;1], [0.0;0;0;0;1]) for i = 1:size(AE, 1), j = 1:size(AE, 2)][1]) ≈ A[5,5]
