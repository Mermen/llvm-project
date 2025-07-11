! RUN: %python %S/test_errors.py %s %flang_fc1 -pedantic
! Tests for the ASSOCIATED() and NULL() intrinsics
subroutine assoc()

  abstract interface
    subroutine subrInt(i)
      integer :: i
    end subroutine subrInt

    integer function abstractIntFunc(x)
      integer, intent(in) :: x
    end function
  end interface

  type :: t1
    integer :: n
  end type t1
  type :: t2
    type(t1) :: t1arr(2)
    type(t1), pointer :: t1ptr(:)
  end type t2

 contains
  integer function intFunc(x)
    integer, intent(in) :: x
    intFunc = x
  end function

  real function realFunc(x)
    real, intent(in) :: x
    realFunc = x
  end function

  pure integer function pureFunc()
    pureFunc = 343
  end function pureFunc

  elemental integer function elementalFunc(n)
    integer, value :: n
    elementalFunc = n
  end function elementalFunc

  subroutine subr(i)
    integer :: i
  end subroutine subr

  subroutine subrCannotBeCalledfromImplicit(i)
    integer :: i(:)
  end subroutine subrCannotBeCalledfromImplicit

  function objPtrFunc(x)
    integer, target :: x
    integer, pointer :: objPtrFunc
    objPtrFunc => x
  end

  !PORTABILITY: nonstandard usage: FUNCTION statement without dummy argument list
  function procPtrFunc
    procedure(intFunc), pointer :: procPtrFunc
    procPtrFunc => intFunc
  end

  subroutine test(assumedRank)
    real, pointer, intent(in out) :: assumedRank(..)
    integer :: intVar
    integer, target :: targetIntVar1
    integer(kind=2), target :: targetIntVar2
    real, target :: targetRealVar, targetRealMat(2,2)
    real, pointer :: realScalarPtr, realVecPtr(:), realMatPtr(:,:)
    integer, pointer :: intPointerVar1
    integer, pointer :: intPointerVar2
    integer, allocatable :: intAllocVar
    procedure(intFunc) :: intProc
    procedure(intFunc), pointer :: intprocPointer1
    procedure(intFunc), pointer :: intprocPointer2
    procedure(realFunc) :: realProc
    procedure(realFunc), pointer :: realprocPointer1
    procedure(pureFunc), pointer :: pureFuncPointer
    procedure(elementalFunc) :: elementalProc
    external :: externalProc
    procedure(subrInt) :: subProc
    procedure(subrInt), pointer :: subProcPointer
    procedure(), pointer :: implicitProcPointer
    procedure(subrCannotBeCalledfromImplicit), pointer :: cannotBeCalledfromImplicitPointer
    !ERROR: 'neverdeclared' must be an abstract interface or a procedure with an explicit interface
    procedure(neverDeclared), pointer :: badPointer
    logical :: lVar
    type(t1) :: t1x
    type(t1), target :: t1xtarget
    type(t2) :: t2x
    type(t2), target :: t2xtarget
    integer, target :: targetIntArr(2)
    integer, target, save :: targetIntCoarray[*]
    integer, pointer :: intPointerArr(:)
    procedure(objPtrFunc), pointer :: objPtrFuncPointer

    lvar = associated(assumedRank, assumedRank) ! ok
    !ERROR: TARGET= argument 'realscalarptr' may not be assumed-rank when POINTER= argument is not
    lvar = associated(realScalarPtr, assumedRank)
    !ERROR: TARGET= argument 'realvecptr' may not be assumed-rank when POINTER= argument is not
    lvar = associated(realVecPtr, assumedRank)
    lvar = associated(assumedRank, targetRealVar) ! ok
    lvar = associated(assumedRank, targetRealMat) ! ok
    lvar = associated(realScalarPtr, targetRealVar) ! ok
    !ERROR: POINTER= argument and TARGET= argument have incompatible ranks 1 and 0
    lvar = associated(realVecPtr, targetRealVar)
    !ERROR: POINTER= argument and TARGET= argument have incompatible ranks 2 and 0
    lvar = associated(realMatPtr, targetRealVar)
    !ERROR: POINTER= argument and TARGET= argument have incompatible ranks 0 and 2
    lvar = associated(realScalarPtr, targetRealMat)
    !ERROR: POINTER= argument and TARGET= argument have incompatible ranks 1 and 2
    lvar = associated(realVecPtr, targetRealMat)
    lvar = associated(realMatPtr, targetRealMat) ! ok
    !ERROR: missing mandatory 'pointer=' argument
    lVar = associated()
    !ERROR: POINTER= argument 'intprocpointer1' is a procedure pointer but the TARGET= argument '(targetintvar1)' is not a procedure or procedure pointer
    lvar = associated(intprocPointer1, (targetIntVar1))
    !ERROR: POINTER= argument 'intpointervar1' is an object pointer but the TARGET= argument '(targetintvar1)' is not a variable
    lvar = associated(intPointerVar1, (targetIntVar1))
    !ERROR: MOLD= argument to NULL() must be a pointer or allocatable
    lVar = associated(null(intVar))
    !ERROR: A NULL() allocatable is not allowed for 'pointer=' intrinsic argument
    lVar = associated(null(intAllocVar))
    lVar = associated(null()) !OK
    lVar = associated(null(intPointerVar1)) !OK
    !PORTABILITY: POINTER= argument of ASSOCIATED() is required by some other compilers to be a valid left-hand side of a pointer assignment statement [-Wportability]
    !BECAUSE: 'NULL()' is a null pointer
    lVar = associated(null(), null()) !OK
    lVar = associated(intPointerVar1, null(intPointerVar2)) !OK
    lVar = associated(intPointerVar1, null()) !OK
    !PORTABILITY: POINTER= argument of ASSOCIATED() is required by some other compilers to be a valid left-hand side of a pointer assignment statement [-Wportability]
    !BECAUSE: 'NULL()' is a null pointer
    lVar = associated(null(), null(intPointerVar1)) !OK
    !PORTABILITY: POINTER= argument of ASSOCIATED() is required by some other compilers to be a pointer [-Wportability]
    lVar = associated(null(intPointerVar1), null()) !OK
    !ERROR: POINTER= argument of ASSOCIATED() must be a pointer
    lVar = associated(intVar)
    !ERROR: POINTER= argument of ASSOCIATED() must be a pointer
    lVar = associated(intVar, intVar)
    !ERROR: POINTER= argument of ASSOCIATED() must be a pointer
    lVar = associated(intAllocVar)
    !ERROR: Arguments of ASSOCIATED() must be a pointer and an optional valid target
    lVar = associated(intPointerVar1, targetRealVar)
    lVar = associated(intPointerVar1, targetIntVar1) !OK
    !ERROR: Arguments of ASSOCIATED() must be a pointer and an optional valid target
    lVar = associated(intPointerVar1, targetIntVar2)
    lVar = associated(intPointerVar1) !OK
    lVar = associated(intPointerVar1, intPointerVar2) !OK
    !ERROR: In assignment to object pointer 'intpointervar1', the target 'intvar' is not an object with POINTER or TARGET attributes
    intPointerVar1 => intVar
    !ERROR: TARGET= argument 'intvar' must have either the POINTER or the TARGET attribute
    lVar = associated(intPointerVar1, intVar)

    !ERROR: TARGET= argument 't1x%n' must have either the POINTER or the TARGET attribute
    lVar = associated(intPointerVar1, t1x%n)
    lVar = associated(intPointerVar1, t1xtarget%n) ! ok
    !ERROR: TARGET= argument 't2x%t1arr(1_8)%n' must have either the POINTER or the TARGET attribute
    lVar = associated(intPointerVar1, t2x%t1arr(1)%n)
    lVar = associated(intPointerVar1, t2x%t1ptr(1)%n) ! ok
    lVar = associated(intPointerVar1, t2xtarget%t1arr(1)%n) ! ok
    lVar = associated(intPointerVar1, t2xtarget%t1ptr(1)%n) ! ok

    ! Procedure pointer tests
    intprocPointer1 => intProc !OK
    lVar = associated(intprocPointer1, intProc) !OK
    intprocPointer1 => intProcPointer2 !OK
    lVar = associated(intprocPointer1, intProcPointer2) !OK
    intProcPointer1  => null(intProcPointer2) ! ok
    lvar = associated(intProcPointer1, null(intProcPointer2)) ! ok
    intProcPointer1 => null() ! ok
    lvar = associated(intProcPointer1, null()) ! ok
    intProcPointer1 => intProcPointer2 ! ok
    lvar = associated(intProcPointer1, intProcPointer2) ! ok
    intProcPointer1 => null(intProcPointer2) ! ok
    lvar = associated(intProcPointer1, null(intProcPointer2)) ! ok
    intProcPointer1 =>null() ! ok
    lvar = associated(intProcPointer1, null())
    intPointerVar1 => null(intPointerVar1) ! ok
    lvar = associated (intPointerVar1, null(intPointerVar1)) ! ok

    ! Functions (other than NULL) returning pointers
    lVar = associated(objPtrFunc(targetIntVar1)) ! ok
    !PORTABILITY: POINTER= argument of ASSOCIATED() is required by some other compilers to be a pointer [-Wportability]
    lVar = associated(objPtrFunc(targetIntVar1), targetIntVar1) ! ok
    !PORTABILITY: POINTER= argument of ASSOCIATED() is required by some other compilers to be a pointer [-Wportability]
    lVar = associated(objPtrFunc(targetIntVar1), objPtrFunc(targetIntVar1)) ! ok
    lVar = associated(procPtrFunc()) ! ok
    lVar = associated(procPtrFunc(), intFunc) ! ok
    lVar = associated(procPtrFunc(), procPtrFunc()) ! ok
    !ERROR: POINTER= argument 'objptrfunc(targetintvar1)' is an object pointer but the TARGET= argument 'intfunc' is not a variable
    !PORTABILITY: POINTER= argument of ASSOCIATED() is required by some other compilers to be a pointer [-Wportability]
    lVar = associated(objPtrFunc(targetIntVar1), intFunc)
    !ERROR: POINTER= argument 'objptrfunc(targetintvar1)' is an object pointer but the TARGET= argument 'procptrfunc()' is not a variable
    !PORTABILITY: POINTER= argument of ASSOCIATED() is required by some other compilers to be a pointer [-Wportability]
    lVar = associated(objPtrFunc(targetIntVar1), procPtrFunc())
    !ERROR: POINTER= argument 'procptrfunc()' is a procedure pointer but the TARGET= argument 'objptrfunc(targetintvar1)' is not a procedure or procedure pointer
    lVar = associated(procPtrFunc(), objPtrFunc(targetIntVar1))
    !ERROR: POINTER= argument 'procptrfunc()' is a procedure pointer but the TARGET= argument 'targetintvar1' is not a procedure or procedure pointer
    lVar = associated(procPtrFunc(), targetIntVar1)

    !ERROR: In assignment to procedure pointer 'intprocpointer1', the target is not a procedure or procedure pointer
    intprocPointer1 => intVar
    !ERROR: POINTER= argument 'intprocpointer1' is a procedure pointer but the TARGET= argument 'intvar' is not a procedure or procedure pointer
    lVar = associated(intprocPointer1, intVar)
    !ERROR: Procedure pointer 'intprocpointer1' associated with incompatible procedure designator 'elementalproc': incompatible procedure attributes: Elemental
    intProcPointer1 => elementalProc
    !WARNING: Procedure pointer 'intprocpointer1' associated with incompatible procedure designator 'elementalproc': incompatible procedure attributes: Elemental
    !ERROR: Non-intrinsic ELEMENTAL procedure 'elementalproc' may not be passed as an actual argument
    lvar = associated(intProcPointer1, elementalProc)
    !ERROR: POINTER= argument 'intpointervar1' is an object pointer but the TARGET= argument 'intfunc' is not a variable
    lvar = associated (intPointerVar1, intFunc)
    !ERROR: POINTER= argument 'intpointervar1' is an object pointer but the TARGET= argument 'objptrfuncpointer' is not a variable
    lvar = associated (intPointerVar1, objPtrFuncPointer)
    !ERROR: In assignment to object pointer 'intpointervar1', the target 'intfunc' is a procedure designator
    intPointerVar1 => intFunc
    !ERROR: In assignment to procedure pointer 'intprocpointer1', the target is not a procedure or procedure pointer
    intProcPointer1 => targetIntVar1
    !ERROR: POINTER= argument 'intprocpointer1' is a procedure pointer but the TARGET= argument 'targetintvar1' is not a procedure or procedure pointer
    lvar = associated (intProcPointer1, targetIntVar1)
    !ERROR: Procedure pointer 'intprocpointer1' associated with result of reference to function 'null' that is an incompatible procedure pointer: function results have distinct types: INTEGER(4) vs REAL(4)
    intProcPointer1 => null(mold=realProcPointer1)
    !WARNING: Procedure pointer 'intprocpointer1' associated with result of reference to function 'null(mold=realprocpointer1)' that is an incompatible procedure pointer: function results have distinct types: INTEGER(4) vs REAL(4)
    lvar = associated(intProcPointer1, null(mold=realProcPointer1))
    !ERROR: PURE procedure pointer 'purefuncpointer' may not be associated with non-PURE procedure designator 'intproc'
    pureFuncPointer => intProc
    !WARNING: PURE procedure pointer 'purefuncpointer' may not be associated with non-PURE procedure designator 'intproc'
    lvar = associated(pureFuncPointer, intProc)
    !ERROR: Function pointer 'realprocpointer1' associated with incompatible function designator 'intproc': function results have distinct types: REAL(4) vs INTEGER(4)
    realProcPointer1 => intProc
    !WARNING: Function pointer 'realprocpointer1' associated with incompatible function designator 'intproc': function results have distinct types: REAL(4) vs INTEGER(4)
    lvar = associated(realProcPointer1, intProc)
    subProcPointer => externalProc ! OK to associate a procedure pointer  with an explicit interface to a procedure with an implicit interface
    lvar = associated(subProcPointer, externalProc) ! OK to associate a procedure pointer with an explicit interface to a procedure with an implicit interface
    !ERROR: Subroutine pointer 'subprocpointer' may not be associated with function designator 'intproc'
    subProcPointer => intProc
    !WARNING: Subroutine pointer 'subprocpointer' may not be associated with function designator 'intproc'
    lvar = associated(subProcPointer, intProc)
    !ERROR: Function pointer 'intprocpointer1' may not be associated with subroutine designator 'subproc'
    intProcPointer1 => subProc
    !WARNING: Function pointer 'intprocpointer1' may not be associated with subroutine designator 'subproc'
    lvar = associated(intProcPointer1, subProc)
    implicitProcPointer => subr ! OK for an implicit point to point to an explicit proc
    lvar = associated(implicitProcPointer, subr) ! OK
    !WARNING: Procedure pointer 'implicitprocpointer' with implicit interface may not be associated with procedure designator 'subrcannotbecalledfromimplicit' with explicit interface that cannot be called via an implicit interface
    lvar = associated(implicitProcPointer, subrCannotBeCalledFromImplicit)
    !ERROR: Procedure pointer 'cannotbecalledfromimplicitpointer' with explicit interface that cannot be called via an implicit interface cannot be associated with procedure designator with an implicit interface
    cannotBeCalledfromImplicitPointer => externalProc
    !WARNING: Procedure pointer 'cannotbecalledfromimplicitpointer' with explicit interface that cannot be called via an implicit interface cannot be associated with procedure designator with an implicit interface
    lvar = associated(cannotBeCalledfromImplicitPointer, externalProc)
    !ERROR: TARGET= argument 'targetintarr([INTEGER(8)::2_8,1_8])' may not have a vector subscript or coindexing
    lvar = associated(intPointerArr, targetIntArr([2,1]))
    !ERROR: TARGET= argument 'targetintcoarray[1_8]' may not have a vector subscript or coindexing
    lvar = associated(intPointerVar1, targetIntCoarray[1])
    !ERROR: 'neverdeclared' is not a procedure
    !ERROR: Could not characterize intrinsic function actual argument 'badpointer'
    !ERROR: 'neverdeclared' is not a procedure
    !ERROR: Could not characterize intrinsic function actual argument 'badpointer'
    lvar = associated(badPointer)
  end subroutine test
end subroutine assoc
