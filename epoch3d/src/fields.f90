MODULE fields

  USE boundary
  USE laser

  IMPLICIT NONE

  REAL(num), DIMENSION(6) :: const
  INTEGER :: large, small, order
  REAL(num) :: hdt, fac
  REAL(num) :: hdtx, hdty, hdtz
  REAL(num) :: cnx, cny, cnz

CONTAINS

  SUBROUTINE set_field_order(field_order)

    INTEGER, INTENT(IN) :: field_order

    order = field_order
    large = order / 2
    small = large - 1

    IF (field_order .EQ. 2) THEN
      const(1:2) = (/ -1.0_num, 1.0_num /)
      cfl = 1.0_num
    ELSE IF (field_order .EQ. 4) THEN
      const(1:4) = (/ 1.0_num/24.0_num, -9.0_num/8.0_num, &
          9.0_num/8.0_num, -1.0_num/24.0_num /)
      cfl = 6.0_num / 7.0_num
    ELSE
      const(1:6) = (/ -3.0_num/640.0_num, 25.0_num/384.0_num, &
          -75.0_num/64.0_num, 75.0_num/64.0_num, -25.0_num/384.0_num, &
          3.0_num/640.0_num /)
      cfl = 120.0_num / 149.0_num
    ENDIF

  END SUBROUTINE set_field_order



  SUBROUTINE update_e_field

    INTEGER :: ix, iy, iz

    DO iz = 1, nz
      DO iy = 1, ny
        DO ix = 1, nx
          ex(ix, iy, iz) = ex(ix, iy, iz) &
              + cny * SUM(const(1:order) * bz(ix, iy-large:iy+small, iz)) &
              - cnz * SUM(const(1:order) * by(ix, iy, iz-large:iz+small)) &
              - fac * jx(ix, iy, iz)
        ENDDO
      ENDDO
    ENDDO

    DO iz = 1, nz
      DO iy = 1, ny
        DO ix = 1, nx
          ey(ix, iy, iz) = ey(ix, iy, iz) &
              + cnz * SUM(const(1:order) * bx(ix, iy, iz-large:iz+small)) &
              - cnx * SUM(const(1:order) * bz(ix-large:ix+small, iy, iz)) &
              - fac * jy(ix, iy, iz)
        ENDDO
      ENDDO
    ENDDO

    DO iz = 1, nz
      DO iy = 1, ny
        DO ix = 1, nx
          ez(ix, iy, iz) = ez(ix, iy, iz) &
              + cnx * SUM(const(1:order) * by(ix-large:ix+small, iy, iz)) &
              - cny * SUM(const(1:order) * bx(ix, iy-large:iy+small, iz)) &
              - fac * jz(ix, iy, iz)
        ENDDO
      ENDDO
    ENDDO

  END SUBROUTINE update_e_field



  SUBROUTINE update_b_field

    INTEGER :: ix, iy, iz

    DO iz = 1, nz
      DO iy = 1, ny
        DO ix = 1, nx
          bx(ix, iy, iz) = bx(ix, iy, iz) &
              - hdty * SUM(const(1:order) * ez(ix, iy-small:iy+large, iz)) &
              + hdtz * SUM(const(1:order) * ey(ix, iy, iz-small:iz+large))
        ENDDO
      ENDDO
    ENDDO

    DO iz = 1, nz
      DO iy = 1, ny
        DO ix = 1, nx
          by(ix, iy, iz) = by(ix, iy, iz) &
              - hdtz * SUM(const(1:order) * ex(ix, iy, iz-small:iz+large)) &
              + hdtx * SUM(const(1:order) * ez(ix-small:ix+large, iy, iz))
        ENDDO
      ENDDO
    ENDDO

    DO iz = 1, nz
      DO iy = 1, ny
        DO ix = 1, nx
          bz(ix, iy, iz) = bz(ix, iy, iz) &
              - hdtx * SUM(const(1:order) * ey(ix-small:ix+large, iy, iz)) &
              + hdty * SUM(const(1:order) * ex(ix, iy-small:iy+large, iz))
        ENDDO
      ENDDO
    ENDDO

  END SUBROUTINE update_b_field



  SUBROUTINE update_eb_fields_half

    hdt  = 0.5_num * dt
    hdtx = hdt / dx
    hdty = hdt / dy
    hdtz = hdt / dz

    cnx = hdtx * c**2
    cny = hdty * c**2
    cnz = hdtz * c**2

    fac = hdt / epsilon0

    ! Update E field to t+dt/2
    CALL update_e_field

    ! Now have E(t+dt/2), do boundary conditions on E
    CALL efield_bcs

    ! Update B field to t+dt/2 using E(t+dt/2)
    CALL update_b_field

    ! Now have B field at t+dt/2. Do boundary conditions on B
    CALL bfield_bcs(.FALSE.)

    ! Now have E&B fields at t = t+dt/2
    ! Move to particle pusher

  END SUBROUTINE update_eb_fields_half



  SUBROUTINE update_eb_fields_final

    CALL update_b_field

    CALL bfield_bcs(.FALSE.)

    IF (x_min_boundary) THEN
      IF (bc_field(c_bd_x_min) .EQ. c_bc_simple_laser) THEN
        CALL laser_bcs_x_min
      ELSE IF (bc_field(c_bd_x_min) .EQ. c_bc_simple_outflow) THEN
        CALL outflow_bcs_x_min
      ENDIF
    ENDIF

    IF (x_max_boundary) THEN
      IF (bc_field(c_bd_x_max) .EQ. c_bc_simple_laser) THEN
        CALL laser_bcs_x_max
      ELSE IF (bc_field(c_bd_x_max) .EQ. c_bc_simple_outflow) THEN
        CALL outflow_bcs_x_max
      ENDIF
    ENDIF

    IF (y_min_boundary) THEN
      IF (bc_field(c_bd_y_min) .EQ. c_bc_simple_laser) THEN
        CALL laser_bcs_y_min
      ELSE IF (bc_field(c_bd_y_min) .EQ. c_bc_simple_outflow) THEN
        CALL outflow_bcs_y_min
      ENDIF
    ENDIF

    IF (y_max_boundary) THEN
      IF (bc_field(c_bd_y_max) .EQ. c_bc_simple_laser) THEN
        CALL laser_bcs_y_max
      ELSE IF (bc_field(c_bd_y_max) .EQ. c_bc_simple_outflow) THEN
        CALL outflow_bcs_y_max
      ENDIF
    ENDIF

    IF (z_min_boundary) THEN
      IF (bc_field(c_bd_z_min) .EQ. c_bc_simple_laser) THEN
        CALL laser_bcs_z_min
      ELSE IF (bc_field(c_bd_z_min) .EQ. c_bc_simple_outflow) THEN
        CALL outflow_bcs_z_min
      ENDIF
    ENDIF

    IF (z_max_boundary) THEN
      IF (bc_field(c_bd_z_max) .EQ. c_bc_simple_laser) THEN
        CALL laser_bcs_z_max
      ELSE IF (bc_field(c_bd_z_max) .EQ. c_bc_simple_outflow) THEN
        CALL outflow_bcs_z_max
      ENDIF
    ENDIF

    CALL bfield_bcs(.TRUE.)

    CALL update_e_field

    CALL efield_bcs

  END SUBROUTINE update_eb_fields_final

END MODULE fields
