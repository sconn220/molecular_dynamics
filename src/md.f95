program md

  use global

  implicit none

  !Program Settings
  nxcells = 2   !Number of cells in the X direction
  nycells = 2   !Number of cells in the Y direction
  nzcells = 2   !Number of cells in the Z direction
  
  xcellscl = 1.125/0.5  !Width of cell in X direction
  ycellscl = 1.125/0.5  !Width of cell in y direction
  zcellscl = 1.125/0.5  !Width of cell in z direction
  
  scalefactor = 1  

  ncells = nxcells*nycells*nzcells !Number of Total Boxes
  ppc = 4                          !Particle per Cell
  
  !Set up boundry conditions
  xbound = nxcells*xcellscl*scalefactor 
  ybound = nycells*ycellscl*scalefactor
  zbound = nzcells*zcellscl*scalefactor
  
  nprtl = ncells*ppc !number of particles
  !nprtl = 4

  dt = 0.004
  
  !FCC Cordinates
  fcc(1,:) = (/0.0,0.0,0.0/)
  fcc(2,:) = (/0.0,0.5,0.5/)
  fcc(3,:) = (/0.5,0.5,0.0/)
  fcc(4,:) = (/0.5,0.0,0.5/)
 
  NT = 1000  !Number of timesteps

  allocate(pos(nprtl,3,NT))   !allocate position
  allocate(vel(nprtl,3,NT))   !allocate velocity
  allocate(accel(nprtl,3,NT)) !allocate acceration
  allocate(energy(NT))
  allocate(energy_k(NT))
  allocate(energy_p(NT))

  pos   = 0
  vel   = 0 
  accel = 0 
  
  !open(unit = 6, file = 'energy.out', status = 'unknown')

  !-----------Main Program-----------!
  call bld_lattice
  call verlet_integration
  call writepos
  call writevel 
  call writeenergy
  !call bld_lattice  !Create inital position of gas particles
  !call force_lj(fcc(2,:),fcc(1,:),force_test)
  !print*,'force_test:',force_test
  !call accel_calc(1)



end program

subroutine bld_lattice !{{{
  !Functionality: Creates the inital position of all the particles in the box.
  !
  !Input: pos - position array that hold the cartesian cordinates of the particles.
  !             Array on input should be zeros.
  !Output: pos -
  
  use global

  implicit none

  integer :: ii, jj, kk, ll

  do ii = 1,nzcells
    do jj = 1,nycells
      do kk = 1,nxcells
        do ll = 1,ppc
        prtlnum = (ii-1)*nycells*nxcells*ppc+(jj-1)*nxcells*ppc+(kk-1)*ppc + ll
        
        !Set inital position
        pos(prtlnum,1,1) = (fcc(ll,1) + (ii-1)*xcellscl)*scalefactor
        pos(prtlnum,2,1) = (fcc(ll,2) + (jj-1)*ycellscl)*scalefactor
        pos(prtlnum,3,1) = (fcc(ll,3) + (kk-1)*zcellscl)*scalefactor
  
        !Create and scale random velocities
        call random_number(rand_vel)
        call scalerand(rand_vel)

        !Assign random velocities
        vel(prtlnum,1:3,1) = rand_vel
        end do 
      end do 
    end do
  end do

end subroutine !}}}
!**************************************************************************
subroutine bld_lattice_two_prtl !{{{

  use global

  implicit none

  pos(1,:,1) = [0.d0,0.d0,0.d0]    
  pos(2,:,1) = [0.d0,0.d0,1.d0]

  vel(1,:,1) = [0.d0,0.d0,0.d0]
  vel(2,:,1) = [0.d0,0.d0,0.d0]
end subroutine !}}}
!**************************************************************************
subroutine writepos !{{{
  !Functionality - write position out to file

  use global
  
  implicit none

  integer :: ii,jj

  open (unit = 1, file = 'pos.out', status = 'unknown')
  do ii = 1,nprtl
      do jj = 1, NT
          write (1,*),jj,pos(ii,:,jj)
      end do
  end do
end subroutine !}}}
!**************************************************************************
subroutine writevel!{{{
  !Functionality - Write Velocity out to file
  
  use global
   
  implicit none

  integer :: ii,jj

  open (unit = 2, file = 'vel.out', status = 'unknown')
  do ii = 1,nprtl
      do jj = 1,NT
          write (2,*),jj,vel(ii,:,jj)
      end do
  end do

end subroutine !}}}
!**************************************************************************
subroutine writeaccel!{{{
  !Functionality - write acceration to file
  
  use global

  implicit none

  integer :: ii,jj

  open (unit = 3, file = 'accel.out', status = 'unknown') 
  do ii = 1,nprtl
      do jj = 1, NT
          write (3,*),jj,accel(ii,:,jj)
      end do
  end do
end subroutine!}}}
!**************************************************************************
subroutine writeenergy !{{{
  !function: write energy if system for each time step to file
  use global
  
  integer :: ii

  open (unit = 7, file = 'energy.out' , status = 'unknown')
  do ii = 1 , NT
      write (7,*),ii,energy(ii),energy_k(ii),energy_p(ii)
  end do 

end subroutine!}}}
!**************************************************************************
subroutine scalerand(randvel)  !{{{

  use global 

  implicit none

  real(8),dimension(3) :: randvel

  randvel = randvel
  
end subroutine  !}}}
!**************************************************************************
subroutine force_lj(pos1,pos2,force) !{{{
  
  !Calculates the force due to the Lenard Jones Potiential 
  !Input: pos1,pos2- position of the first and second particle
  
  use global

  implicit none
  
  !input variabels 
  real(8),dimension(3),intent(in) :: pos1,pos2  !position of particle 1 and 2
  real(8),dimension(3),intent(out) :: force      !force between particles
  
  !Internal Variable
  real(8),dimension(3) :: r  !Distance Between Radius
  real(8) :: force_mag       !Magnitude of the Force

  r = pos1 - pos2             !Finding the Distance Between the Points
  r(1) = r(1) - NINT(r(1)/xbound)*xbound
  r(2) = r(2) - NINT(r(2)/ybound)*ybound
  r(3) = r(3) - NINT(r(3)/zbound)*zbound
  
  !Lenard Jones force 
  force_mag = 24.d0*((2.d0/(dot_product(r,r))**7)+(-1.d0/(dot_product(r,r))**4))

  !Direction Force
  force = r * force_mag

end subroutine !}}}
!**************************************************************************
subroutine verlet_integration !{{{
  !------------------------------------------------------------------------
  !Function - Calculate the postion of all the particles after NT timesteps
  !
  !Input:  pos - position of every particle over NT timesteps
  !        vel - velocity of every particle over NT timesteps
  !        accel - acceration of every particle over NT timesteps
  !        NT - number of timesteps 
  !Output: pos
  !------------------------------------------------------------------------
  
  use global 

  implicit none

  integer :: ii

  call accel_calc(1)
  !first time step iteration
  do ii = 1 , NT-1 
      pos(:,:,ii+1) = pos(:,:,ii) + vel(:,:,ii) * dt + 0.5*accel(:,:,ii)*dt**2 
      pos(:,1,ii+1) = mod(pos(:,1,ii+1),xbound)
      pos(:,2,ii+1) = mod(pos(:,2,ii+1),ybound)
      pos(:,3,ii+1) = mod(pos(:,3,ii+1),zbound)

      call accel_calc(ii+1)
      vel(:,:,ii+1) = vel(:,:,ii) + 0.5*(accel(:,:,ii+1)+accel(:,:,ii))*dt

      call sys_energy(ii)

  end do 

end subroutine !}}}
!**************************************************************************
subroutine accel_calc(it) !{{{
  !Function: Calculates the acceleration of every particle from the iteration of every other particle
  !
  !input: it - current time step indexer
  !
  !Global Variables - 

  use global
 
  implicit none

  !internal variable
  real(8), dimension(3) :: prtl_force_lj !particle force from Lennard-Jones
  integer :: it                          !current iteration
  integer :: ii, jj


  do ii = 1, nprtl
      do jj = 1, nprtl 
          if (ii .ne. jj) then  
              call force_lj(pos(ii,:,it),pos(jj,:,it),prtl_force_lj) 
              accel(ii,:,it) = accel(ii,:,it) + prtl_force_lj
          end if 
      end do 
  end do 


end subroutine !}}}
!**************************************************************************
subroutine sys_energy(it) !{{{
  !Function: Calculates the system energy 
  !
  !input: it - current time step ind
  !
  !Global Variables - 

  use global
 
  implicit none

  !internal variable
  real(8) :: LJPEnergy = 0      !Potiential Energy
  real(8) :: KEnergy   = 0      !Kinetic Energy
  real(8) :: LJPE_tot  = 0      !Total pot E for the time step
  real(8) :: KE_tot    = 0      !Total Kinetic Energy for the time step
  integer :: it                 !Current Iteration
  integer :: ii, jj             !Indexers

  
  do ii = 1, nprtl
      do jj = 1, nprtl 
          if (ii .ne. jj) then  
              call Lennard_Jones_Potential(pos(ii,:,it),pos(jj,:,it),LJPEnergy) 
              LJPE_tot = LJPE_tot + LJPEnergy 
          end if 
      end do 
      call kinetic_energy(vel(ii,:,it),KEnergy)
      KE_tot = KE_tot + KEnergy
  end do
  energy(it)   = KE_tot + LJPE_tot
  energy_p(it) = LJPE_tot
  energy_k(it) = KE_tot
  KE_tot = 0 
  LJPE_tot = 0
end subroutine!}}}
!**************************************************************************
subroutine Lennard_Jones_Potential(pos1,pos2,p_energy)!{{{
  !{{{
  !Function: take the position of two particles and compute the lennard Jones between them
  !
  !Input:
  !   pos1 - Position of Particle one
  !   pos2 - Position of Particle Two
  !
  !Output: 
  !   p_energy - potential energy
  !   
  !Internal Variables:
  !   r - distance vector from one particle to another
  !
  !Global Variables:
  !   xbound -   
  !   ybound -
  !   zbound -
  !
  !}}}


  use global
  
  !Input Variables
  real(8), dimension(3),intent(in) :: pos1,pos2
  real(8) :: p_energy

  !Internal Variables
  real(8), dimension(3) :: r

  !Finding the distance between points and adding periodic boundry conditions
  r = pos1 - pos2
  !r(1) = r(1) - NINT(r(1)/xbound)*xbound
  !r(2) = r(2) - NINT(r(2)/ybound)*ybound
  !r(3) = r(3) - NINT(r(3)/zbound)*zbound

  !Lenard Jones Potiential 
  p_energy = 4.d0 * ((dot_product(r,r))**(-6) - (dot_product(r,r))**(-3))

end subroutine Lennard_Jones_Potential!}}}
!**************************************************************************
subroutine kinetic_energy(vel,k_energy)!{{{
  !{{{
  !Function: take the position of two particles and compute the lennard Jones between them
  !
  !Input:
  !   vel - Velocity of Particle
  !
  !Output: 
  !   k_energy - kinetic energy
  !}}}
  
  !Input Variables
  real(8), dimension(3) :: vel
  real(8) :: k_energy

  !Lenard Jones Potiential 
  k_energy = 0.5*dot_product(vel,vel)

end subroutine kinetic_energy !}}}
!**************************************************************************
subroutine plot_lj_force!{{{
  !Samples force_lj routine to be able to plot and verify lenard jones force

  use global 

  integer :: ii
  integer :: npoints = 200
  real(8) :: rtest
  real(8),dimension(3) :: ljforce
  
  open(unit = 4, file = 'ljforce.out', status = 'unknown')
  do ii = 1 , npoints
      rtest = .01*real(ii) + 0.2
      call force_lj([0.d0,0.d0,0.d0],[0.d0,0.d0,rtest],ljforce)
      write(4,*),rtest,ljforce   
  end do 
end subroutine!}}}
!**************************************************************************
subroutine plot_lj_pot!{{{
  !Samples force_lj routine to be able to plot and verify lenard jones potiential

  use global 

  integer :: ii
  integer :: npoints = 200
  real(8) :: rtest
  real(8) :: ljpot
  
  open(unit = 5, file = 'ljpot.out', status = 'unknown')
  do ii = 1 , npoints
      rtest = .01*real(ii) + 0.2
      call Lennard_Jones_Potential([0.d0,0.d0,0.d0],[0.d0,0.d0,rtest],ljpot)
      write(5,*),rtest,ljpot   
  end do 
end subroutine!}}}



