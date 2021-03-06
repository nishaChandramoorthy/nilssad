!Simple model of combustion in gas turbines

module combustion_juniper
	implicit none

	REAL, PARAMETER :: Pi = 3.1415927
	double precision, parameter :: dt = 0.001d0
	integer, parameter :: d = 20, N = 10
	integer, parameter :: N_p = 5	
	double precision, parameter :: sigma = 10., b = 8./3., rho = 28.
	double precision :: alpha = 0.01, tauL = 10.d0

contains

subroutine Xnp1(X,Xnp1_res,Xtmtau,param_active,params_passive)

	implicit none
	double precision :: c2, beta, xf
	double precision, dimension(d):: X, Xnp1_res
    double precision, dimension(d):: k1, k2, k3, k4
	double precision, dimension(d):: ddt
	integer :: i, imax
	double precision, dimension(N) :: Xtmtau 
	double precision, dimension(N_p-1) :: params_passive
	double precision :: param_active 
	

	c2 = params_passive(1)
	beta = params_passive(2)
	xf = params_passive(3)
		
    call dXdt(X,ddt,Xtmtau,param_active,c2,beta,xf)
    do i = 1, d, 1
		k1(i) = dt*ddt(i)
	   	Xnp1_res(i) = X(i) + 0.5d0*k1(i) 
	end do
	call dXdt(Xnp1_res,ddt,Xtmtau,param_active,c2,beta,xf)
    do i = 1, d, 1
		k2(i) = dt*ddt(i)
		Xnp1_res(i) = X(i) + 0.5d0*k2(i) 
	end do
	call dXdt(Xnp1_res,ddt,Xtmtau,param_active,c2,beta,xf)
    do i = 1, d, 1
		k3(i) = dt*ddt(i)
		Xnp1_res(i) = X(i) + k3(i) 
	end do
	call dXdt(Xnp1_res,ddt,Xtmtau,param_active,c2,beta,xf)
 	do i = 1, d, 1
		k4(i) = dt*ddt(i) 
	end do
  
	do i = 1, d, 1
    	Xnp1_res(i) = X(i) + 1.d0/6.d0*k1(i) + &
               1.d0/3.d0*k2(i) + 1.d0/3.d0*k3(i) + &
                1.d0/6.d0*k4(i)   

	end do

end subroutine Xnp1
double precision function uf(X,xf)
	
	implicit none
	double precision, dimension(N) :: X
	double precision :: uf0, xf
	integer :: i

	uf0 = 0.d0
	do i = 1, N, 1
	
		uf0 = uf0 + X(i)*cos(i*pi*xf)	

	end do 			
	uf = uf0
end function uf 
double precision function zeta(i,c1,c2)
	
	implicit none
	integer :: i
	double precision :: c1, c2
	zeta = c1*(i**2.0) + c2*(i**0.5d0)

end function zeta
double precision function qdot(delayed_velocity)
	implicit none
	double precision :: delayed_velocity
	double precision, dimension(5) :: coeffs
	integer :: i 
	coeffs(1) = 0.5d0
	coeffs(2) = -0.108d0
	coeffs(3) = -0.044d0
	coeffs(4) = 0.059d0
	coeffs(5) = -0.012d0
	qdot = 0.d0
	do i = 1, 5, 1
			qdot = qdot + coeffs*(delayed_velocity**i)
	end do
end function qdot
subroutine dXdt(X,dXdt_res,c1,c2,beta,xf,alpha)
	implicit none
	double precision :: c1, c2, beta
	double precision :: xf, velocity_fluctuation
	double precision :: velocity_flame
	double precision, dimension(d) :: X
	double precision :: heat_release
	double precision, intent(out), dimension(d) :: dXdt_res
	integer :: i,j

	dXdt_res(d-2) = 1.d0/tauL*(sigma*(X(d-1)-X(d-2)))
	dXdt_res(d-1) = 1.d0/tauL*(X(d-2)*(rho-X(d)) - X(d-1))
	dXdt_res(d) = 1.d0/tauL*(X(d-2)*X(d-1) - b*X(d))
	velocity_fluctuation = alpha*X(d-2)/(rho - 1.d0)
	velocity_flame = uf(X,xf) + velocity_fluctuation
	heat_release = beta*qdot(X(2*N+Ncheb))		

	do i = 1, N, 1
		dXdt_res(i) = i*pi*X(N+i)
		dXdt_res(N+i) = -1.d0*i*pi*X(i) - zeta(i,c1,c2)*X(N+i) &
						- 2.d0*heat_release*sin(i*pi*xf)
		dXdt_res(2*N+i) = -2.d0/tau*D(i+1,0)*velocity_flame 
		do j = 1, N, 1 
			dXdt_res(2*N+i) = dXdt_res(2*N+i) + &
							X(2*N +j)*D(i+1,j)
		end do 	
	end do
 
end subroutine dXdt
subroutine Objective(X,J,param_active,params_passive)
	implicit none
	double precision, intent(in), dimension(d) :: X
	double precision, intent(out) :: J
	double precision :: xf
	double precision, dimension(N_p-1):: params_passive
	double precision :: param_active
	integer :: t

	J = 0.d0
	xf = params_passive(N_p-2)
	do t = 1, N, 1
		J = J - X(N+t)*sin(t*pi*xf)
	end do

end subroutine Objective
subroutine FlameOutput(X,Xtmtau,pf,ufvar,heat,param_active,params_passive)
	implicit none
	double precision, intent(in), dimension(d) :: X, Xtmtau
	double precision, intent(out) :: pf,ufvar,heat
	double precision :: xf
	double precision, dimension(N_p-1):: params_passive
	double precision :: param_active
	integer :: t

	pf = 0.d0
    ufvar = 0.d0
    heat = 0.d0
	xf = params_passive(N_p-2)
	do t = 1, N, 1
		pf = pf - X(N+t)*sin(t*pi*xf)
        ufvar = ufvar + X(t)*cos(t*pi*xf)
        heat = heat + Xtmtau(t)*cos(t*pi*xf)
    end do
    heat = ((1.d0/3.d0 + heat)**2.d0 + 0.001d0)**0.25d0 - (1.d0/3.d0)**0.5d0
end subroutine FlameOutput

subroutine dfdX(X,dfdX_res)

	implicit none
	double precision, dimension(d) :: X
	double precision, intent(out), dimension(d,d) :: dfdX_res 	
	integer :: i,j
	double precision:: r

	dfdX_res = 0.d0
	r = 28.d0
 
	dfdX_res(1,1) = -1.d0*sigma
	dfdX_res(1,2) =	sigma 
	
	dfdX_res(2,1) = r - X(3)
	dfdX_res(2,2) = -1.d0
	dfdX_res(2,3) = -1.d0*X(1)	
	
	dfdX_res(3,1) = X(2)
	dfdX_res(3,2) = X(1)
	dfdX_res(3,3) = -1.d0*b
    
end subroutine dfdX  

subroutine dvdt(X,v1,dvdt_res)

		implicit none
		double precision, dimension(d) :: X
		double precision, intent(out), dimension(d,1) :: dvdt_res
		double precision, dimension(d,d) :: dfdX_res
		double precision, dimension(d,1) :: v1
		double precision, dimension(d,1):: dfdX_times_v
		integer :: i		
	
		call dfdX(X,dfdX_res)
		!Manual matrix-vector product
		do i = 1,d,1
			dvdt_res(i,1) = dfdX_res(i,1)*v1(1,1) + dfdX_res(i,2)*v1(2,1) + dfdX_res(i,3)*v1(3,1)
		end do
		dvdt_res(1,1) = dvdt_res(1,1) + 0.d0
		dvdt_res(2,1) = dvdt_res(2,1) + X(1)
		dvdt_res(3,1) = dvdt_res(3,1) + 0.d0	

end subroutine dvdt
subroutine rk45_full(X,v,vnp1)
!Assumes full perturbation vector.
	implicit none
	double precision , dimension(d) :: X
	double precision , intent(out), dimension(d,1) :: vnp1
	double precision , dimension(d,1) :: v
	double precision , dimension(d,1) :: v1,k1,k2,k3,k4
	double precision , dimension(d,1):: dvdt_res

	v1 = v
	call dvdt(X,v1,dvdt_res)	
	k1 = dt*dvdt_res
	call dvdt(X,v1 + 0.5d0*k1,dvdt_res)
	k2 = dt*dvdt_res
	call dvdt(X,v1 + 0.5d0*k2,dvdt_res)
	k3 = dt*dvdt_res
	call dvdt(X,v1 + k3,dvdt_res)
	k4 = dt*dvdt_res
	vnp1 = v1 + 1.d0/6.d0*k1 + &
		 1.d0/3.d0*k2 + 1.d0/3.d0*k3 + &
		1.d0/6.d0*k4
    

end subroutine rk45_full 

end module combustion_juniper
