subroutine head_homogeneous(ds,s,y,X0,v0,nSteps,d)
	use Lorenz63
	implicit none
	integer :: d 
	double precision, dimension(d) :: X
	double precision, dimension(d) :: Xnp1_res
	double precision  :: s
	double precision, dimension(d) :: X0, v0
	double precision, dimension(d) :: y
	integer :: t,t1
	integer :: nSteps
	double precision :: ds



!$openad INDEPENDENT(ds)
	do t = 1, d, 1 
		X(t) = X0(t) + v0(t)*ds
	end do
	do t = 1, nSteps, 1
		call Xnp1(X,Xnp1_res,s,d)
		do t1 = 1, d, 1
			X(t1) = Xnp1_res(t1)
		end do
	end do
	do t = 1, 3, 1
		y(t) = X(t)
	end do
!$openad DEPENDENT(y)

end subroutine


