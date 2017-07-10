subroutine head_inhomogeneous(s,sprime,y,X0,v0,nSteps)
	use Lorenz63
	implicit none 
	double precision, dimension(3) :: X
	double precision, dimension(3) :: Xnp1_res
	double precision, intent(in) :: s
	double precision, dimension(3), intent(in) :: X0, v0
	double precision, dimension(3), intent(out) :: y
	integer :: t
	integer, intent(in) :: nSteps
	double precision :: sprime


!$openad INDEPENDENT(s) 
	X(1) = X0(1) + v0(1)*(s-sprime)
	X(2) = X0(2) + v0(2)*(s-sprime)
	X(3) = X0(3) + v0(3)*(s-sprime)
	do t = 1, nSteps, 1
		call Xnp1(X,Xnp1_res,s)
		X(1) = Xnp1_res(1)
		X(2) = Xnp1_res(2)
		X(3) = Xnp1_res(3)
	end do
	do t = 1, 3, 1
		y(t) = X(t)
	end do
	!y(1) = 1.d0
	!y(2) = s
	!y(3) = 1.d0
!$openad DEPENDENT(y)

end subroutine

