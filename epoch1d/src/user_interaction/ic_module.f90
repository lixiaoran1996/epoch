! Copyright (C) 2009-2019 University of Warwick
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

MODULE ic_module

  USE shared_data
  USE helper
  USE numerics

  IMPLICIT NONE

  PRIVATE

  PUBLIC :: manual_load

CONTAINS


  SUBROUTINE manual_load
    ! TYPE(particle), POINTER :: current
    ! INTEGER, PARAMETER :: np_local = 1000
    ! INTEGER :: ispecies, ip
    ! REAL(num) :: temperature, pte2, p_ref, min_p, max_p, dp_local, p_scale
    ! REAL(num), DIMENSION(np_local) :: p_axis, distfn_axis
    ! REAL(num), PARAMETER :: m = 3.0_num  ! 设置m为超高斯分布的指数
    
    ! DO ispecies = 1, n_species
    !   IF (species_list(ispecies)%name == 'electron') THEN
    !     print *,'found electron'
    !     temperature = 3000_num  ! 设置温度 eV
    !     pte2 = q0 * temperature * species_list(ispecies)%mass  ! 计算标准差的平方
    !     p_ref= SQRT(3.0*pte2*gamma_fn(3.0/m)/gamma_fn(5.0/m))

    !     max_p = 5.0_num*SQRT(pte2)  ! 速度最大值
    !     min_p = -max_p  ! 速度最小值
    !     dp_local = (max_p - min_p) / REAL(np_local-1, num)  ! 速度步长
    !     ! 生成超高斯分布
    !     DO ip = 1, np_local
    !         p_axis(ip) = min_p + (ip - 1) * dp_local  ! 计算每个速度点
    !         p_scale = ABS(p_axis(ip)/p_ref)
    !         distfn_axis(ip) = EXP(-p_scale ** m)
    !     ENDDO
        
    !     ! 分配粒子的速度
    !     current => species_list(ispecies)%attached_list%head
    !     DO WHILE (ASSOCIATED(current))
    !         current%part_p(1) = sample_dist_function(p_axis, distfn_axis)  ! 从分布中采样速度
    !         current => current%next
    !     ENDDO
    !   ENDIF
    ! ENDDO
  END SUBROUTINE manual_load
    

END MODULE ic_module
