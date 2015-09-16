##############################################################################
##
## Solve A'Ax = A'b by cgls with jacobi preconditioner
## x is the initial guess for x. It is modified in place
## r equals b - Ax0 where x0 is the initial guess for x. It is not modified in place
## s, p, z, ptmp, are used for storage. They have dimension size(A, 2). 
## q is used for storage. It has dimension size(A, 1). 
##
## Stopping rule : Least-squares problems, normal equations, and stopping criteria for the conjugate gradient method Mario Arioli and Serge Gratton (also used in Stata reghdfe)
##
## TODO : switch to lmqr augmented for residual
##############################################################################

# TODO. Follow LMQR for better stopping rule
function cgls!(x, r, A, q, invdiag, s, p, z, ptmp; 
               tol::Real=1e-8, maxiter::Int=100)

    # Initialization.
    converged = false
    iterations = maxiter 

    Ac_mul_B!(s, A, r)
    broadcast!(*, z, s, invdiag)
    copy!(p, z)
    ssr0 = dot(s, z)
    ssrold = ssr0  
    ν = sumabs2(r)
    ψ = Float64[]
    iter = 0
    while iter < maxiter
        iter += 1
        A_mul_B!(q, A, p) 
        Ac_mul_B!(ptmp, A, q)
        α = ssrold / dot(ptmp, p)
        push!(ψ, α * ssrold)
        ν -= α * ssrold
        x == nothing || axpy!(α, p, x) 
        axpy!(-α, q, r)
        axpy!(-α, ptmp, s)
        broadcast!(*, z, s, invdiag)
        ssr = dot(s, z)
        if (iter == 1 && ψ[end] <= tol^2 * ν) || ssr <= eps() || ψ[end] <= eps() || (iter >= 3 && sum(sub(ψ, (iter-2):iter)) <= tol^2 * ν)
            iterations = iter
            converged = true
            break
        end
        β = ssr / ssrold
        # p = s + β p
        scale!(p, β)
        axpy!(1.0, z, p) 
        ssrold = ssr
    end
    return iterations, converged
end

