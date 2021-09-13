module bmitestbmi
  
#ifdef NGEN_ACTIVE
  use bmif_2_0_iso
#else
  use bmif_2_0
#endif

  use test_model
  use, intrinsic :: iso_c_binding, only: c_ptr, c_loc, c_f_pointer
  implicit none
  integer :: DEFAULT_TIME_STEP_SIZE = 3600
  integer :: DEFAULT_TIME_STEP_COUNT = 24

  type, extends (bmi) :: bmi_test_bmi
     private
     type (test_bmi_model) :: model
   contains
     procedure :: get_component_name => test_component_name
     procedure :: get_input_item_count => test_input_item_count
     procedure :: get_output_item_count => test_output_item_count
      procedure :: get_input_var_names => test_input_var_names
     procedure :: get_output_var_names => test_output_var_names
     procedure :: initialize => test_initialize
     procedure :: finalize => test_finalize
     procedure :: get_start_time => test_start_time
     procedure :: get_end_time => test_end_time
     procedure :: get_current_time => test_current_time
     procedure :: get_time_step => test_time_step
     procedure :: get_time_units => test_time_units
     procedure :: update => test_update
     procedure :: update_until => test_update_until
     procedure :: get_var_grid => test_var_grid
!      procedure :: get_grid_type => test_grid_type
!      procedure :: get_grid_rank => test_grid_rank
!      procedure :: get_grid_shape => test_grid_shape
     procedure :: get_grid_size => test_grid_size
!      procedure :: get_grid_spacing => test_grid_spacing
!      procedure :: get_grid_origin => test_grid_origin
!      procedure :: get_grid_x => test_grid_x
!      procedure :: get_grid_y => test_grid_y
!      procedure :: get_grid_z => test_grid_z
!      procedure :: get_grid_node_count => test_grid_node_count
!      procedure :: get_grid_edge_count => test_grid_edge_count
!      procedure :: get_grid_face_count => test_grid_face_count
!      procedure :: get_grid_edge_nodes => test_grid_edge_nodes
!      procedure :: get_grid_face_edges => test_grid_face_edges
!      procedure :: get_grid_face_nodes => test_grid_face_nodes
!      procedure :: get_grid_nodes_per_face => test_grid_nodes_per_face
     procedure :: get_var_type => test_var_type
!      procedure :: get_var_units => test_var_units
     procedure :: get_var_itemsize => test_var_itemsize
     procedure :: get_var_nbytes => test_var_nbytes
!      procedure :: get_var_location => test_var_location
     procedure :: get_value_int => test_get_int
     procedure :: get_value_float => test_get_float
     procedure :: get_value_double => test_get_double
!      generic :: get_value => &
!           get_value_int, &
!           get_value_float, &
!           get_value_double
! !      procedure :: get_value_ptr_int => test_get_ptr_int
! !      procedure :: get_value_ptr_float => test_get_ptr_float
! !      procedure :: get_value_ptr_double => test_get_ptr_double
! !      generic :: get_value_ptr => &
! !           get_value_ptr_int, &
! !           get_value_ptr_float, &
! !           get_value_ptr_double
! !      procedure :: get_value_at_indices_int => test_get_at_indices_int
! !      procedure :: get_value_at_indices_float => test_get_at_indices_float
! !      procedure :: get_value_at_indices_double => test_get_at_indices_double
! !      generic :: get_value_at_indices => &
! !           get_value_at_indices_int, &
! !           get_value_at_indices_float, &
! !           get_value_at_indices_double
     procedure :: set_value_int => test_set_int
     procedure :: set_value_float => test_set_float
     procedure :: set_value_double => test_set_double
!      generic :: set_value => &
!           set_value_int, &
!           set_value_float, &
!           set_value_double
! !      procedure :: set_value_at_indices_int => test_set_at_indices_int
! !      procedure :: set_value_at_indices_float => test_set_at_indices_float
! !      procedure :: set_value_at_indices_double => test_set_at_indices_double
! !      generic :: set_value_at_indices => &
! !           set_value_at_indices_int, &
! !           set_value_at_indices_float, &
! !           set_value_at_indices_double
! !      procedure :: print_model_info
  end type bmi_test_bmi

  private
  public :: bmi_test_bmi

  character (len=BMI_MAX_COMPONENT_NAME), target :: &
       component_name = "Testing BMI Fortran Model"

  ! Exchange items

  character (len=BMI_MAX_VAR_NAME), target :: &
    output_items(3) = ['OUTPUT_VAR_1', 'OUTPUT_VAR_2', 'OUTPUT_VAR_3']

  character (len=BMI_MAX_VAR_NAME), target :: &
    input_items(3) = ['INPUT_VAR_1', 'INPUT_VAR_2', 'INPUT_VAR_3']

  character (len=BMI_MAX_TYPE_NAME) :: &
    output_type(3) = [character(BMI_MAX_TYPE_NAME):: 'double precision', 'real', 'integer']

  character (len=BMI_MAX_TYPE_NAME) :: &
    input_type(3) = [character(BMI_MAX_TYPE_NAME):: 'double precision', 'real', 'integer']

  integer :: output_grid(3) = [0, 0, 0]
  integer :: input_grid(3) = [0, 0, 0]

contains

subroutine assert(condition, msg)
  ! If condition == .false., it aborts the program.
  !
  ! Arguments
  ! ---------
  !
  logical, intent(in) :: condition
  character(len=*), intent(in), optional :: msg
  !
  ! Example
  ! -------
  !
  ! call assert(a == 5)
  
  if (.not. condition) then
    print *, "Assertion Failed.", msg
    stop 1
  end if
  end subroutine

function read_init_config(model, config_file) result(bmi_status)
  use, intrinsic :: iso_fortran_env, only: stderr => error_unit
  implicit none
  class(test_bmi_model), intent(out) :: model
  character (len=*), intent(in) :: config_file
  integer :: bmi_status
  !namelist inputs
  integer(kind=4) :: epoch_start_time
  integer :: num_time_steps, time_step_size
  double precision :: model_end_time
  !locals
  integer :: rc, fu
  !namelists
  namelist /test/ epoch_start_time, num_time_steps, time_step_size, model_end_time

  !init values
  epoch_start_time = -1
  num_time_steps = 0
  time_step_size = DEFAULT_TIME_STEP_SIZE
  model_end_time = 0

  ! Check whether file exists.
  inquire (file=config_file, iostat=rc)

  if (rc /= 0) then
      write (stderr, '(3a)') 'Error: input file "', trim(config_file), '" does not exist.'
      bmi_status = BMI_FAILURE
      return
  end if

  ! Open and read Namelist file.
  open (action='read', file=config_file, iostat=rc, newunit=fu)
  read (nml=test, iostat=rc, unit=fu)

  if (rc /= 0) then
      write (stderr, '(a)') 'Error: invalid Namelist format.'
      bmi_status = BMI_FAILURE
  else
    if (epoch_start_time == -1 ) then
      !epoch_start_time wasn't found in the name list, log the error and return
      write (stderr, *) "Config param 'epoch_start_time' not found in config file"
      bmi_status = BMI_FAILURE
      return
    end if
    !Update the model with all values found in the namelist
    model%epoch_start_time = epoch_start_time
    model%num_time_steps = num_time_steps
    model%time_step_size = time_step_size
    model%model_end_time = model_end_time
    bmi_status = BMI_SUCCESS
  end if

  close (fu)

end function read_init_config

! BMI initializer.
function test_initialize(this, config_file) result (bmi_status)
  class (bmi_test_bmi), intent(out) :: this
  character (len=*), intent(in) :: config_file
  integer :: bmi_status

  if (len(config_file) > 0) then
     bmi_status = read_init_config(this%model, config_file)
     this%model%current_model_time = 0.0
     if ( this%model%num_time_steps == 0 .and. this%model%model_end_time == 0) then
        this%model%num_time_steps = DEFAULT_TIME_STEP_COUNT
     end if
     
     call assert ( this%model%model_end_time /= 0 .or. this%model%num_time_steps /= 0, &
                   "Both model_end_time and num_time_steps are 0" )

     if ( this%model%model_end_time == 0) then
        call assert( this%model%num_time_steps /= 0 )
        this%model%model_end_time = this%model%current_model_time + (this%model%num_time_steps * this%model%time_step_size)
     end if

     call assert( this%model%model_end_time /= 0, &
                  "model_end_time 0 after attempting to compute from num_time_steps" )
  
     if ( this%model%model_end_time /= 0 ) then
        this%model%num_time_steps = (this%model%model_end_time - this%model%current_model_time) / this%model%time_step_size
     end if

     bmi_status = BMI_SUCCESS
  else
     bmi_status = BMI_FAILURE
  end if

end function test_initialize

! BMI finalizer.
function test_finalize(this) result (bmi_status)
  class (bmi_test_bmi), intent(inout) :: this
  integer :: bmi_status

  bmi_status = BMI_SUCCESS
end function test_finalize

  ! Get the name of the model.
  function test_component_name(this, name) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    character (len=*), pointer, intent(out) :: name
    integer :: bmi_status

    name => component_name
    bmi_status = BMI_SUCCESS
  end function test_component_name

    ! Model time units.
  function test_time_units(this, units) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    character (len=*), intent(out) :: units
    integer :: bmi_status

    units = "s"
    bmi_status = BMI_SUCCESS
  end function test_time_units

  ! Count the output variables.
  function test_output_item_count(this, count) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    integer, intent(out) :: count
    integer :: bmi_status

    count = size(output_items)
    bmi_status = BMI_SUCCESS
  end function test_output_item_count

! List output variables.
  function test_output_var_names(this, names) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    character (*), pointer, intent(out) :: names(:)
    integer :: bmi_status

    names => output_items
    bmi_status = BMI_SUCCESS
  end function test_output_var_names

  ! Count the input variables.
  function test_input_item_count(this, count) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    integer, intent(out) :: count
    integer :: bmi_status

    count = size(input_items)
    bmi_status = BMI_SUCCESS
  end function test_input_item_count

  ! List input variables.
  function test_input_var_names(this, names) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    character (*), pointer, intent(out) :: names(:)
    integer :: bmi_status

    names => input_items
    bmi_status = BMI_SUCCESS
  end function test_input_var_names

  ! The data type of the variable, as a string.
  function test_var_type(this, name, type) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    character (len=*), intent(in) :: name
    character (len=*), intent(out) :: type
    integer :: bmi_status, i

    !checkout output vars
    do  i = 1, size(output_items)
      if(output_items(i) .eq. trim(name) ) then
        type = output_type(i)
        bmi_status = BMI_SUCCESS
        return
      endif
    end do

    !checkout input vars
    do  i = 1, size(input_items)
      if(input_items(i) .eq. trim(name) ) then
        type = input_type(i)
        bmi_status = BMI_SUCCESS
        return
      endif
    end do
  
    !check any other vars???

    !no matches
    type = "-"
    bmi_status = BMI_FAILURE
  end function test_var_type

  ! Get the grid id for a particular variable.
  function test_var_grid(this, name, grid) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    character (len=*), intent(in) :: name
    integer, intent(out) :: grid
    integer :: bmi_status, i

    !checkout output vars
    do  i = 1, size(output_items)
      if(output_items(i) .eq. trim(name) ) then
        grid = output_grid(i)
        bmi_status = BMI_SUCCESS
        return
      endif
    end do

    !checkout input vars
    do  i = 1, size(input_items)
      if(input_items(i) .eq. trim(name) ) then
        grid = input_grid(i)
        bmi_status = BMI_SUCCESS
        return
      endif
    end do
  
    !check any other vars???

    !no matches
    grid = -1
    bmi_status = BMI_FAILURE
  end function test_var_grid

  ! The total number of elements in a grid.
  function test_grid_size(this, grid, size) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    integer, intent(in) :: grid
    integer, intent(out) :: size
    integer :: bmi_status

    select case(grid)
    case(0)
       size = 1
       bmi_status = BMI_SUCCESS
!     case(1)
!        size = this%model%n_y * this%model%n_x
!        bmi_status = BMI_SUCCESS
    case default
       size = -1
       bmi_status = BMI_FAILURE
    end select
  end function test_grid_size

! Memory use per array element.
  function test_var_itemsize(this, name, size) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    character (len=*), intent(in) :: name
    integer, intent(out) :: size
    integer :: bmi_status

    !TODO think of a better way to do this
    !Use 'sizeof' in gcc & ifort
    select case(name)
    case("INPUT_VAR_1")
       size = sizeof(this%model%input_var_1)
       bmi_status = BMI_SUCCESS
    case("INPUT_VAR_2")
       size = sizeof(this%model%input_var_2)
       bmi_status = BMI_SUCCESS
    case("INPUT_VAR_3")
       size = sizeof(this%model%input_var_3)
    case("OUTPUT_VAR_1")
       size = sizeof(this%model%output_var_1)
    case("OUTPUT_VAR_2")
       size = sizeof(this%model%output_var_2)
       bmi_status = BMI_SUCCESS
    case("OUTPUT_VAR_3")
       size = sizeof(this%model%output_var_3)
       bmi_status = BMI_SUCCESS
    case default
       size = -1
       bmi_status = BMI_FAILURE
    end select
  end function test_var_itemsize

  ! The size of the given variable.
  function test_var_nbytes(this, name, nbytes) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    character (len=*), intent(in) :: name
    integer, intent(out) :: nbytes
    integer :: bmi_status
    integer :: s1, s2, s3, grid, grid_size, item_size

    s1 = this%get_var_grid(name, grid)
    s2 = this%get_grid_size(grid, grid_size)
    s3 = this%get_var_itemsize(name, item_size)

    if ((s1 == BMI_SUCCESS).and.(s2 == BMI_SUCCESS).and.(s3 == BMI_SUCCESS)) then
       nbytes = item_size * grid_size
       bmi_status = BMI_SUCCESS
    else
       nbytes = -1
       bmi_status = BMI_FAILURE
    end if
  end function test_var_nbytes
! Set new integer values.
  function test_set_int(this, name, src) result (bmi_status)
    class (bmi_test_bmi), intent(inout) :: this
    character (len=*), intent(in) :: name
    integer, intent(in) :: src(:)
    integer :: bmi_status
  
    select case(name)
    case("INPUT_VAR_3")
       this%model%input_var_3 = src(1)
       bmi_status = BMI_SUCCESS
    case default
       bmi_status = BMI_FAILURE
    end select
    ! NOTE, if vars are gridded, then use:
    ! this%model%var= reshape(src, [this%model%n_y, this%model%n_x])
  end function test_set_int

  ! Set new real values.
  function test_set_float(this, name, src) result (bmi_status)
    class (bmi_test_bmi), intent(inout) :: this
    character (len=*), intent(in) :: name
    real, intent(in) :: src(:)
    integer :: bmi_status

    select case(name)
    case("INPUT_VAR_2")
       this%model%input_var_2 = src(1)
       bmi_status = BMI_SUCCESS
    case default
       bmi_status = BMI_FAILURE
    end select
    ! NOTE, if vars are gridded, then use:
    ! this%model%temperature = reshape(src, [this%model%n_y, this%model%n_x])
  end function test_set_float

  ! Set new double values.
  function test_set_double(this, name, src) result (bmi_status)
    class (bmi_test_bmi), intent(inout) :: this
    character (len=*), intent(in) :: name
    double precision, intent(in) :: src(:)
    integer :: bmi_status

    select case(name)
    case("INPUT_VAR_1")
      this%model%input_var_1 = src(1)
      bmi_status=BMI_SUCCESS
    case default
       bmi_status = BMI_FAILURE
    end select
    ! NOTE, if vars are gridded, then use:
    ! this%model%var = reshape(src, [this%model%n_y, this%model%n_x])
  end function test_set_double

  ! Get a copy of a integer variable's values, flattened.
  function test_get_int(this, name, dest) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    character (len=*), intent(in) :: name
    integer, intent(inout) :: dest(:)
    integer :: bmi_status

    select case(name)
    case("INPUT_VAR_3")
       dest = [this%model%input_var_3]
       bmi_status = BMI_SUCCESS
    case("OUTPUT_VAR_3")
      dest = [this%model%output_var_3]
      bmi_status = BMI_SUCCESS
    case default
       dest(:) = -1
       bmi_status = BMI_FAILURE
    end select
    ! NOTE, if vars are gridded, then use:
    ! dest = reshape(this%model%var, [this%model%n_x*this%model%n_y])
  end function test_get_int

  ! Get a copy of a real variable's values, flattened.
  function test_get_float(this, name, dest) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    character (len=*), intent(in) :: name
    real, intent(inout) :: dest(:)
    integer :: bmi_status

    select case(name)
    case("INPUT_VAR_2")
       dest = [this%model%input_var_2]
       bmi_status = BMI_SUCCESS
    case("OUTPUT_VAR_2")
      dest = [this%model%output_var_2]
      bmi_status = BMI_SUCCESS
    case default
       dest(:) = -1.0
       bmi_status = BMI_FAILURE
    end select
    ! NOTE, if vars are gridded, then use:
    ! dest = reshape(this%model%temperature, [this%model%n_x*this%model%n_y]) 
  end function test_get_float

  ! Get a copy of a double variable's values, flattened.
  function test_get_double(this, name, dest) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    character (len=*), intent(in) :: name
    double precision, intent(inout) :: dest(:)
    integer :: bmi_status

    !==================== UPDATE IMPLEMENTATION IF NECESSARY FOR DOUBLE VARS =================

    select case(name)
    case("INPUT_VAR_1")
      dest = [this%model%input_var_1]
      bmi_status = BMI_SUCCESS
    case("OUTPUT_VAR_1")
      dest = [this%model%output_var_1]
      bmi_status = BMI_SUCCESS
    case default
       dest(:) = -1.d0
       bmi_status = BMI_FAILURE
    end select
    ! NOTE, if vars are gridded, then use:
    ! dest = reshape(this%model%var, [this%model%n_x*this%model%n_y])
  end function test_get_double

    ! Model start time.
  function test_start_time(this, time) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    double precision, intent(out) :: time
    integer :: bmi_status

    time = 0.0
    bmi_status = BMI_SUCCESS
  end function test_start_time
  
  ! Model end time.
  function test_end_time(this, time) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    double precision, intent(out) :: time
    integer :: bmi_status

    time = this%model%num_time_steps * this%model%time_step_size
    bmi_status = BMI_SUCCESS
  end function test_end_time

  ! Model current time.
  function test_current_time(this, time) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    double precision, intent(out) :: time
    integer :: bmi_status

    time = this%model%current_model_time
    bmi_status = BMI_SUCCESS
  end function test_current_time

  ! Model current time.
  function test_time_step(this, time_step) result (bmi_status)
    class (bmi_test_bmi), intent(in) :: this
    double precision, intent(out) :: time_step
    integer :: bmi_status

    time_step = this%model%time_step_size
    bmi_status = BMI_SUCCESS
  end function test_time_step

  ! Advance the model until the given time.
  function test_update_until(this, time) result (bmi_status)
    use test_model, only: run
    class (bmi_test_bmi), intent(inout) :: this
    double precision, intent(in) :: time
    integer :: bmi_status, run_status

    call run(this%model, time - this%model%current_model_time )
    !really this if isn't required...
    if(this%model%current_model_time /= time ) then
      this%model%current_model_time = time
    endif

    bmi_status = BMI_SUCCESS
  end function test_update_until
  
  ! Advance model by one time step.
  function test_update(this) result (bmi_status)
    class (bmi_test_bmi), intent(inout) :: this
    integer :: bmi_status

    bmi_status = this%update_until(this%model%current_model_time + this%model%time_step_size)
  end function test_update

#ifdef NGEN_ACTIVE
  function register_bmi(this) result(bmi_status) bind(C, name="register_bmi")
   use, intrinsic:: iso_c_binding, only: c_ptr, c_loc, c_int
   use iso_c_bmif_2_0
   implicit none
   type(c_ptr) :: this ! If not value, then from the C perspective `this` is a void**
   integer(kind=c_int) :: bmi_status
   !Create the momdel instance to use
   !Definitely need to carefully undertand and document the semantics of the save attribute here
   type(bmi_test_bmi), target, save :: bmi_model !need to ensure scope/lifetime, use save attribute
   !Create a simple pointer wrapper
   type(box), pointer :: bmi_box

   !allocate the pointer box
   allocate(bmi_box)
   !allocate(bmi_box%ptr, source=bmi_model)
   !associate the wrapper pointer the created model instance
   bmi_box%ptr => bmi_model
   !Return the pointer to box
   this = c_loc(bmi_box)
   bmi_status = BMI_SUCCESS
 end function register_bmi
#endif
end module bmitestbmi