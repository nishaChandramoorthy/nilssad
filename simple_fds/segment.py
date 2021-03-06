import os
import numpy as np
def trapez_mean(J, dim):
    J = np.rollaxis(J, dim)
    J_m1 = 2 * J[0] - J[1]
    return (J.sum(0) + J[:-1].sum(0) + J_m1) / (2 * J.shape[0])

def run_segment(run, u0, V, v, parameter, i_segment, steps,
                epsilon):
	'''
	Run Time Segement i_segment, starting from
	u0: nonlinear solution
	V:  homogeneous tangents
	v:  inhomogeneous tangent
	for steps time steps, and returns afterwards
	u0: nonlinear solution
	V:  homogeneous tangents
	v:  inhomogeneous tangent
	J0: history of quantities of interest for the nonlinear solution
	G:  sensitivities of the homogeneous tangents
	g:  sensitivity of the inhomogeneous tangent
	'''
	# run homogeneous tangents
	res_h = []
	subspace_dimension = len(V)

	u1i = u0 + v * epsilon
	u1h = []
	for j in range(subspace_dimension):
		u1h.append(u0 + V[j] * epsilon)

	res_0 = run(u0, parameter, steps)
		
	for j in range(subspace_dimension):
		res_h.append(run(u1h[j], parameter, steps))
    
	# run inhomogeneous tangent
	res_i = run(u1i, parameter + epsilon, steps)
	J0 = res_0[1]
	u0p = res_0[0]
    
	# get homogeneous tangents
	G = []
	V = np.random.rand(subspace_dimension,len(u0))
	for j in range(subspace_dimension):
		J1 = res_h[j][1]
		u1p = res_h[j][0]
		V[j] = (u1p - u0p) / epsilon
		G.append(trapez_mean((J1 - J0) / epsilon, 0))
	# get inhomogeneous tangent
	J1 = res_i[1]
	u1p = res_i[0]
	v, g = (u1p - u0p) / epsilon, trapez_mean((J1 - J0) / epsilon,0)
	return u0p, V, v, J0, G, g
