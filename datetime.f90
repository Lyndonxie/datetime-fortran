!
! datetime-fortran - A Fortran library for time and date manipulation
! Copyright (C) 2013  Milan Curcic
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
!
MODULE datetime_module
!======================================================================>
!
! MODULE: datetime
!
! VERSION: 1.0.0
!
! AUTHOR: Milan Curcic
!         University of Miami
!         e-mail: milan@orca.rsmas.miami.edu
!
! DESCRIPTION: A Fortran module that provides time and date manipulation 
!              facilities. It tries to emulate Python's datetime module 
!              API, but differs from it where convenient or necessary. 
!              Conforms to standard Fortran 2003 and later, so a fairly 
!              recent Fortran compiler is necessary.
!
! CONTAINS:
!
!     TYPES: 
!
!         datetime  - Main datetime object
!         timedelta - Time difference object
!         tm_struct - For compatibility with C/C++ procedures 
!
!     DATETIME METHODS:
!
!         PROCEDURE :: addMilliseconds
!         PROCEDURE :: addSeconds
!         PROCEDURE :: addMinutes
!         PROCEDURE :: addHours
!         PROCEDURE :: addDays
!         PROCEDURE :: isocalendar
!         PROCEDURE :: isoformat
!         PROCEDURE :: isValid
!         PROCEDURE :: now
!         PROCEDURE :: secondsSinceEpoch
!         PROCEDURE :: tm
!         PROCEDURE :: weekday
!         PROCEDURE :: weekdayShort
!         PROCEDURE :: weekdayLong
!         PROCEDURE :: yearday
!
!     TIMEDELTA METHODS:
!
!         PROCEDURE :: total_seconds
!
!     PUBLIC PROCEDURES:
!
!         FUNCTION date2num
!         FUNCTION daysInMonth
!         FUNCTION daysInYear
!         FUNCTION isLeapYear
!         FUNCTION num2date
!         FUNCTION strftime
!         FUNCTION strptime
!
! LAST UPDATE: 2013-05-12
!
!======================================================================>
USE,INTRINSIC :: iso_c_binding

IMPLICIT NONE

PRIVATE

! Derived types:
PUBLIC :: datetime
PUBLIC :: timedelta
PUBLIC :: tm_struct

! Operators:
PUBLIC :: OPERATOR(+)
PUBLIC :: OPERATOR(-)
PUBLIC :: OPERATOR(>)
PUBLIC :: OPERATOR(<)
PUBLIC :: OPERATOR(>=)
PUBLIC :: OPERATOR(<=)
PUBLIC :: OPERATOR(==)

! Procedures:
PUBLIC :: date2num
PUBLIC :: daysInMonth
PUBLIC :: daysInYear
PUBLIC :: isLeapYear
PUBLIC :: num2date
PUBLIC :: strftime
PUBLIC :: strptime

! Constants:
INTEGER,PARAMETER :: real_sp = KIND(1e0)
INTEGER,PARAMETER :: real_dp = KIND(1d0)

REAL(KIND=real_dp),PARAMETER :: d2h = 24d0     ! day    -> hour
REAL(KIND=real_dp),PARAMETER :: h2d = 1d0/d2h  ! hour   -> day
REAL(KIND=real_dp),PARAMETER :: d2m = d2h*60d0 ! day    -> minute
REAL(KIND=real_dp),PARAMETER :: m2d = 1d0/d2m  ! minute -> day
REAL(KIND=real_dp),PARAMETER :: s2d = m2d/60d0 ! second -> day
REAL(KIND=real_dp),PARAMETER :: d2s = 86400d0  ! day    -> second
REAL(KIND=real_dp),PARAMETER :: h2s = 3600d0   ! hour   -> second
REAL(KIND=real_dp),PARAMETER :: s2h = 1d0/h2s  ! second -> hour
REAL(KIND=real_dp),PARAMETER :: m2s = 60d0     ! minute -> second
REAL(KIND=real_dp),PARAMETER :: s2m = 1d0/m2s  ! second -> minute

! Derived types:

!======================================================================>
!
! TYPE: datetime
!
! DESCRIPTION: A main datetime class for date and time representation.
! It is modeled after Python's datetime.datetime class, and has similar
! components and methods (but not all).
!
!======================================================================>
TYPE :: datetime

  ! COMPONENTS:
  INTEGER :: year        = 1 ! Year                   [1-HUGE(year)]
  INTEGER :: month       = 1 ! Month in year          [1-12]
  INTEGER :: day         = 1 ! Day in month           [1-31]
  INTEGER :: hour        = 0 ! Hour in day            [0-23]
  INTEGER :: minute      = 0 ! Minute in hour         [0-59]
  INTEGER :: second      = 0 ! Second in minute       [0-59]
  INTEGER :: millisecond = 0 ! Milliseconds in second [0-999]

  CONTAINS

  ! METHODS:
  PROCEDURE :: addMilliseconds
  PROCEDURE :: addSeconds
  PROCEDURE :: addMinutes
  PROCEDURE :: addHours
  PROCEDURE :: addDays
  PROCEDURE :: isocalendar
  PROCEDURE :: isoformat
  PROCEDURE :: isValid
  PROCEDURE :: now
  PROCEDURE :: secondsSinceEpoch
  PROCEDURE :: tm
  PROCEDURE :: weekday
  PROCEDURE :: weekdayLong
  PROCEDURE :: weekdayShort
  PROCEDURE :: yearday

ENDTYPE datetime
!======================================================================>



!======================================================================>
!
! TYPE: timedelta
!
! DESCRIPTION: Class of objects that define difference between two
! datetime instances. Modeled after Python's datetime.timedelta class.
! Currently, timedelta components are implemented as integers (Python's
! timedelta allows floats),
!
!======================================================================>
TYPE :: timedelta

  ! COMPONENTS:
  INTEGER :: days         = 0
  INTEGER :: hours        = 0
  INTEGER :: minutes      = 0
  INTEGER :: seconds      = 0
  INTEGER :: milliseconds = 0

  CONTAINS

  ! METHODS:
  PROCEDURE :: total_seconds

ENDTYPE timedelta
!======================================================================>



!======================================================================>
!
! TYPE: tm_struct
!
! DESCRIPTION: A derived type provided for compatibility with C/C++ 
! time struct. Allows for calling strftime and strptime procedures 
! through the iso_c_binding.
!
!======================================================================>
TYPE,BIND(c) :: tm_struct

  ! COMPONENTS:
  INTEGER(KIND=c_int) :: tm_sec   ! Seconds      [0-60] (1 leap second)
  INTEGER(KIND=c_int) :: tm_min   ! Minutes      [0-59]
  INTEGER(KIND=c_int) :: tm_hour  ! Hours        [0-23]
  INTEGER(KIND=c_int) :: tm_mday  ! Day          [1-31]
  INTEGER(KIND=c_int) :: tm_mon   ! Month        [0-11]
  INTEGER(KIND=c_int) :: tm_year  ! Year - 1900
  INTEGER(KIND=c_int) :: tm_wday  ! Day of week  [0-6]
  INTEGER(KIND=c_int) :: tm_yday  ! Days in year [0-365]
  INTEGER(KIND=c_int) :: tm_isdst ! DST          [-1/0/1]

  ! METHODS: None.

ENDTYPE tm_struct
!======================================================================>



!======================================================================>
! Operator procedure interfaces:

INTERFACE OPERATOR(+)
  MODULE PROCEDURE datetime_plus_timedelta
ENDINTERFACE

INTERFACE OPERATOR(-)
  MODULE PROCEDURE datetime_minus_datetime
  MODULE PROCEDURE datetime_minus_timedelta
  MODULE PROCEDURE unary_minus_timedelta
ENDINTERFACE

INTERFACE OPERATOR(==)
  MODULE PROCEDURE eq
ENDINTERFACE

INTERFACE OPERATOR(>)
  MODULE PROCEDURE gt
ENDINTERFACE

INTERFACE OPERATOR(<)
  MODULE PROCEDURE lt
ENDINTERFACE

INTERFACE OPERATOR(>=)
  MODULE PROCEDURE ge
ENDINTERFACE

INTERFACE OPERATOR(<=)
  MODULE PROCEDURE le
ENDINTERFACE

!======================================================================>



!======================================================================>
!
! INTERFACE: To C procedures strftime and strptime through 
! iso_c_binding.
!
!======================================================================>
INTERFACE



  !====================================================================>
  !
  ! FUNCTION: strftime
  ! 
  ! DESCRIPTION: Returns a formatted time string, given input time
  ! struct and format. Refer to C standard library documentation for
  ! more information. 
  ! 
  !====================================================================>
  FUNCTION strftime(str,slen,format,tm)BIND(c,name='strftime')RESULT(rc)
    USE,INTRINSIC :: iso_c_binding
    TYPE,BIND(c) :: tm_struct
      INTEGER(KIND=c_int) :: tm_sec
      INTEGER(KIND=c_int) :: tm_min
      INTEGER(KIND=c_int) :: tm_hour
      INTEGER(KIND=c_int) :: tm_mday
      INTEGER(KIND=c_int) :: tm_mon
      INTEGER(KIND=c_int) :: tm_year
      INTEGER(KIND=c_int) :: tm_wday
      INTEGER(KIND=c_int) :: tm_yday
      INTEGER(KIND=c_int) :: tm_isdst
    ENDTYPE tm_struct
    CHARACTER(KIND=c_char),DIMENSION(*),INTENT(OUT) :: str
    INTEGER(KIND=c_int),VALUE,          INTENT(IN)  :: slen
    CHARACTER(KIND=c_char),DIMENSION(*),INTENT(IN)  :: format
    TYPE(tm_struct),                    INTENT(IN)  :: tm
    INTEGER(KIND=c_int)                             :: rc
  ENDFUNCTION strftime
  !====================================================================>



  !====================================================================>
  !
  ! FUNCTION: strptime
  ! 
  ! DESCRIPTION: Returns a time struct object based on the input time 
  ! string str, formatted using format. Refer to C standard library
  ! documentation for more information.
  ! 
  !====================================================================>
  FUNCTION strptime(str,format,tm)BIND(c,name='strptime')RESULT(rc)
    USE,INTRINSIC :: iso_c_binding
    TYPE,BIND(c) :: tm_struct
      INTEGER(KIND=c_int) :: tm_sec
      INTEGER(KIND=c_int) :: tm_min
      INTEGER(KIND=c_int) :: tm_hour
      INTEGER(KIND=c_int) :: tm_mday
      INTEGER(KIND=c_int) :: tm_mon
      INTEGER(KIND=c_int) :: tm_year
      INTEGER(KIND=c_int) :: tm_wday
      INTEGER(KIND=c_int) :: tm_yday
      INTEGER(KIND=c_int) :: tm_isdst
    ENDTYPE tm_struct
    CHARACTER(KIND=c_char),DIMENSION(*),INTENT(IN)  :: str
    CHARACTER(KIND=c_char),DIMENSION(*),INTENT(IN)  :: format
    TYPE(tm_struct),                    INTENT(OUT) :: tm
    INTEGER(KIND=c_int)                             :: rc
  ENDFUNCTION strptime
  !====================================================================>


ENDINTERFACE
!======================================================================>
CONTAINS



!======================================================================>
!
! SUBROUTINE: addMilliseconds
!
! DESCRIPTION: datetime-bound procedure. It adds an integer number of 
! milliseconds to self. Called by datetime addition (+) and subtraction
! (-) operators.
!
!======================================================================>
PURE ELEMENTAL SUBROUTINE addMilliseconds(self,ms)

  CLASS(datetime),INTENT(INOUT) :: self
  INTEGER,        INTENT(IN)    :: ms

  self%millisecond = self%millisecond+ms

  IF(self%millisecond >= 1000)THEN
    CALL self%addSeconds(self%millisecond/1000)
    self%millisecond = MOD(self%millisecond,1000)
  ELSEIF(self%millisecond < 0)THEN
    CALL self%addSeconds(self%millisecond/1000-1)
    self%millisecond = MOD(self%millisecond,1000)+1000
  ENDIF

ENDSUBROUTINE addMilliseconds
!======================================================================>



!======================================================================>
!
! SUBROUTINE: addSeconds
!
! DESCRIPTION: datetime-bound procedure. It adds an integer number of 
! seconds to self. Called by datetime addition (+) and subtraction (-) 
! operators.
!
!======================================================================>
PURE ELEMENTAL SUBROUTINE addSeconds(self,s)

  CLASS(datetime),INTENT(INOUT) :: self
  INTEGER,        INTENT(IN)    :: s

  self%second = self%second+s
  IF(self%second >= 60)THEN
    CALL self%addMinutes(self%second/60)
    self%second = MOD(self%second,60)
  ELSEIF(self%second < 0)THEN
    CALL self%addMinutes(self%second/60-1)
    self%second = MOD(self%second,60)+60
  ENDIF

ENDSUBROUTINE addSeconds
!======================================================================>



!======================================================================>
!
! SUBROUTINE: addMinutes
!
! DESCRIPTION: datetime-bound procedure. It adds an integer number of 
! minutes to self. Called by datetime addition (+) and subtraction (-) 
! operators.
!
!======================================================================>
PURE ELEMENTAL SUBROUTINE addMinutes(self,m)

  CLASS(datetime),INTENT(INOUT) :: self
  INTEGER,        INTENT(IN)    :: m

  self%minute = self%minute+m
  IF(self%minute >= 60)THEN
    CALL self%addHours(self%minute/60)
    self%minute = MOD(self%minute,60)
  ELSEIF(self%minute < 0)THEN
    CALL self%addHours(self%minute/60-1)
    self%minute = MOD(self%minute,60)+60
  ENDIF

ENDSUBROUTINE addMinutes
!======================================================================>



!======================================================================>
!
! SUBROUTINE: addHours
!
! DESCRIPTION: datetime-bound procedure. It adds an integer number of 
! hours to self. Called by datetime addition (+) and subtraction (-) 
! operators.
!
!======================================================================>
PURE ELEMENTAL SUBROUTINE addHours(self,h)
  
  CLASS(datetime),INTENT(INOUT) :: self
  INTEGER,        INTENT(IN)    :: h

  self%hour = self%hour+h
  IF(self%hour >= 24)THEN
    CALL self%addDays(self%hour/24)
    self%hour = MOD(self%hour,24)
  ELSEIF(self%hour < 0)THEN
    CALL self%addDays(self%hour/24-1)
    self%hour = MOD(self%hour,24)+24
  ENDIF

ENDSUBROUTINE addHours
!======================================================================>



!======================================================================>
!
! SUBROUTINE: addDays
!
! DESCRIPTION: datetime-bound procedure. It adds an integer number of 
! days to self. Called by datetime addition (+) and subtraction (-) 
! operators.
!
!======================================================================>
PURE ELEMENTAL SUBROUTINE addDays(self,d)

  CLASS(datetime),INTENT(INOUT) :: self
  INTEGER,        INTENT(IN)    :: d

  INTEGER :: daysInCurrentMonth

  self%day = self%day+d
  DO
    daysInCurrentMonth = daysInMonth(self%month,self%year)
    IF(self%day > daysInCurrentMonth)THEN
      self%day = self%day-daysInCurrentMonth
      self%month = self%month+1
      IF(self%month > 12)THEN
        self%year = self%year+self%month/12
        self%month = MOD(self%month,12)
      ENDIF
    ELSEIF(self%day < 1)THEN
      self%day = self%day+daysInCurrentMonth
      self%month = self%month-1
      IF(self%month < 1)THEN
        self%year = self%year+self%month/12-1
        self%month = 12+MOD(self%month,12)
      ENDIF
    ELSE
      EXIT
    ENDIF 
  ENDDO

ENDSUBROUTINE addDays
!======================================================================>



!======================================================================>
!
! FUNCTION: isoformat
!
! DESCRIPTION:
!
!======================================================================>
PURE ELEMENTAL CHARACTER(LEN=23) FUNCTION isoformat(self,sep)

  CLASS(datetime),INTENT(IN)           :: self
  CHARACTER(LEN=1),INTENT(IN),OPTIONAL :: sep
  CHARACTER(LEN=1)                     :: separator

  IF(PRESENT(sep))THEN
    separator = sep
  ELSE
    separator = 'T'
  ENDIF

  isoformat = int2str(self%year,       4)//'-'//      &
              int2str(self%month,      2)//'-'//      &
              int2str(self%day,        2)//separator//&
              int2str(self%hour,       2)//':'//      &
              int2str(self%minute,     2)//':'//      &
              int2str(self%second,     2)//'.'//      &
              int2str(self%millisecond,3)

ENDFUNCTION isoformat
!======================================================================>



!======================================================================>
!
! FUNCTION: isValid
!
! DESCRIPTION: datetime-bound method that checks whether the datetime
! instance has valid component values. Returns .TRUE. if the datetime
! instance is valid, and .FALSE. otherwise.
!
!======================================================================>
PURE ELEMENTAL LOGICAL FUNCTION isValid(self)

  CLASS(datetime),INTENT(IN) :: self

  isValid = .TRUE.

  IF(self%year < 1)THEN
    isValid = .FALSE.
    RETURN
  ENDIF

  IF(self%month < 1 .OR. self%month > 12)THEN
    isValid = .FALSE.
    RETURN
  ENDIF

  IF(self%day < 1 .OR. &
     self%day > daysInMonth(self%month,self%year))THEN
    isValid = .FALSE.
    RETURN
  ENDIF
 
  IF(self%hour < 0 .OR. self%hour > 23)THEN    
    isValid = .FALSE.
    RETURN
  ENDIF

  IF(self%minute < 0 .OR. self%minute > 59)THEN    
    isValid = .FALSE.
    RETURN
  ENDIF

  IF(self%second < 0 .OR. self%second > 59)THEN    
    isValid = .FALSE.
    RETURN
  ENDIF

  IF(self%millisecond < 0 .OR. self%millisecond > 999)THEN    
    isValid = .FALSE.
    RETURN
  ENDIF

ENDFUNCTION isValid
!======================================================================>



!======================================================================>
!
! FUNCTION: now
!
! DESCRIPTION: datetime-bound procedure. Returns current time.
!
!======================================================================>
TYPE(datetime) FUNCTION now(self)

  CLASS(datetime),INTENT(IN) :: self

  INTEGER,DIMENSION(8)       :: values

  CALL date_and_time(values=values)
  now = datetime(year        = values(1),&
                 month       = values(2),&
                 day         = values(3),&
                 hour        = values(5),&
                 minute      = values(6),&
                 second      = values(7),&
                 millisecond = values(8))

ENDFUNCTION now
!======================================================================>



!======================================================================>
!
! FUNCTION: weekday
!
! DESCRIPTION: datetime-bound method to calculate day of the week using
! Zeller's congruence. Returns an integer scalar in the range of [0-6], 
! starting from Sunday.
!
!======================================================================>
PURE ELEMENTAL INTEGER FUNCTION weekday(self)

  CLASS(datetime),INTENT(IN) :: self

  INTEGER :: year,month
  INTEGER :: j,k

  year  = self%year
  month = self%month

  IF(month <= 2)THEN
    month = month+12
    year  = year-1
  ENDIF

  j = year/100
  k = MOD(year,100)

  weekday = MOD(self%day+((month+1)*26)/10+k+k/4+j/4+5*j,7)-1

  IF(weekday < 0)weekday = 6

ENDFUNCTION weekday
!======================================================================>



!======================================================================>
!
! FUNCTION: weekdayLong
!
! DESCRIPTION: datetime-bound procedure. Returns the name of the day
! of the week.
!
!======================================================================>
PURE ELEMENTAL CHARACTER(LEN=9) FUNCTION weekdayLong(self)

  CLASS(datetime),INTENT(IN) :: self

  CHARACTER(LEN=9),PARAMETER,DIMENSION(7) :: &
  days = ['Sunday   ','Monday   ','Tuesday  ','Wednesday',&
          'Thursday ','Friday   ','Saturday ']

  weekdayLong = days(self%weekday()+1)

ENDFUNCTION weekdayLong
!======================================================================>



!======================================================================>
!
! FUNCTION: weekDayShort
!
! DESCRIPTION: datetime-bound procedure. Returns a 3-character 
! representation of the name of the day of the week.
!
!======================================================================>
PURE ELEMENTAL CHARACTER(LEN=3) FUNCTION weekdayShort(self)

  CLASS(datetime),INTENT(IN) :: self

  CHARACTER(LEN=3),PARAMETER,DIMENSION(7) :: &
                   days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']

  weekdayShort = days(self%weekday()+1)

ENDFUNCTION weekdayShort
!======================================================================>



!======================================================================>
!
! FUNCTION: isocalendar
!
! DESCRIPTION: datetime-bound procedure. Returns an array of 3 integers,
! year, week number, and week day, as defined by ISO 8601 week date.
! Essentially a wrapper around C strftime() function.
!
!======================================================================>
FUNCTION isocalendar(self)

  CLASS(datetime),INTENT(IN) :: self

  INTEGER,DIMENSION(3) :: isocalendar
  INTEGER              :: year,week,wday
  INTEGER              :: rc
  CHARACTER(LEN=20)    :: string

  rc = strftime(string,LEN(string),'%G %V %u'//CHAR(0),self%tm())  

  READ(UNIT=string(1:4),FMT='(I4)')year
  READ(UNIT=string(6:7),FMT='(I2)')week
  READ(UNIT=string(9:9),FMT='(I1)')wday

  isocalendar = [year,week,wday]

ENDFUNCTION isocalendar
!======================================================================>



!======================================================================>
!
! FUNCTION: secondsSinceEpoch
!
! DESCRIPTION: datetime-bound procedure. Returns an integer number of 
! seconds since the UNIX Epoch, 1970-01-01 00:00:00 +0000 (UTC).
!
!======================================================================>
INTEGER FUNCTION secondsSinceEpoch(self)

  CLASS(datetime),INTENT(IN) :: self

  INTEGER           :: rc
  CHARACTER(LEN=11) :: string

  rc = strftime(string,LEN(string),'%s'//CHAR(0),self%tm())  

  READ(UNIT=string,FMT='(I10)')secondsSinceEpoch

ENDFUNCTION secondsSinceEpoch
!======================================================================>



!======================================================================>
!
! FUNCTION: tm
!
! DESCRIPTION: datetime-bound procedure. Returns a respective tm_struct 
! instance.
!
!======================================================================>
PURE ELEMENTAL TYPE(tm_struct) FUNCTION tm(self)

  CLASS(datetime),INTENT(IN) :: self

  tm%tm_sec   = self%second
  tm%tm_min   = self%minute
  tm%tm_hour  = self%hour
  tm%tm_mday  = self%day
  tm%tm_mon   = self%month-1
  tm%tm_year  = self%year-1900
  tm%tm_wday  = self%weekday()
  tm%tm_yday  = self%yearday()-1
  tm%tm_isdst = 0

ENDFUNCTION tm
!======================================================================>



!======================================================================>
!
! FUNCTION: yearday
!
! DESCRIPTION: datetime-bound procedure. Returns integer day of the
! year (ordinal date).
!
!======================================================================>
PURE ELEMENTAL INTEGER FUNCTION yearday(self)

  CLASS(datetime),INTENT(IN) :: self

  INTEGER :: month

  yearday = 0
  DO month=1,self%month-1
    yearday = yearday+daysInMonth(month,self%year)
  ENDDO
  yearday = yearday+self%day

ENDFUNCTION yearday
!======================================================================>



!======================================================================>
!
! FUNCTION: datetime_plus_timedelta
!
! DESCRIPTION: Adds a timedelta instance to a datetime instance.
! Returns a new datetime instance. Overloads the operator +.
!
!======================================================================>
PURE ELEMENTAL FUNCTION datetime_plus_timedelta(d0,t) RESULT(d)

  TYPE(datetime), INTENT(IN) :: d0
  TYPE(timedelta),INTENT(IN) :: t
  TYPE(datetime)             :: d

  ! Initialize:
  d = d0 

  IF(t%milliseconds /= 0)CALL d%addMilliseconds(t%milliseconds)
  IF(t%seconds      /= 0)CALL d%addSeconds(t%seconds)
  IF(t%minutes      /= 0)CALL d%addMinutes(t%minutes)
  IF(t%hours        /= 0)CALL d%addHours(t%hours)
  IF(t%days         /= 0)CALL d%addDays(t%days)

ENDFUNCTION datetime_plus_timedelta
!======================================================================>



!======================================================================>
!
! FUNCTION: datetime_minus_timedelta
!
! DESCRIPTION: Subtracts a timedelta instance from a datetime instance.
! Returns a new datetime instance. Overloads the operator -.
!
!======================================================================>
PURE ELEMENTAL FUNCTION datetime_minus_timedelta(d0,t) RESULT(d)

  TYPE(datetime), INTENT(IN) :: d0
  TYPE(timedelta),INTENT(IN) :: t
  TYPE(datetime)             :: d

  ! Initialize:
  d = d0

  IF(t%milliseconds /= 0)CALL d%addMilliseconds(-t%milliseconds)
  IF(t%seconds      /= 0)CALL d%addSeconds(-t%seconds)
  IF(t%minutes      /= 0)CALL d%addMinutes(-t%minutes)
  IF(t%hours        /= 0)CALL d%addHours(-t%hours)
  IF(t%days         /= 0)CALL d%addDays(-t%days)

ENDFUNCTION datetime_minus_timedelta
!======================================================================>



!======================================================================>
!
! FUNCTION: datetime_minus_datetime
!
! DESCRIPTION: Subtracts a datetime instance from another datetime 
! instance. Returns a timedelta instance. Overloads the operator -.
!
!======================================================================>
PURE ELEMENTAL FUNCTION datetime_minus_datetime(d0,d1) RESULT(t)

  TYPE(datetime),INTENT(IN) :: d0,d1
  TYPE(timedelta)           :: t

  REAL(KIND=real_dp) :: daysDiff
  INTEGER            :: days,hours,minutes,seconds,milliseconds
  INTEGER            :: sign_

  daysDiff = date2num(d0)-date2num(d1)

  IF(daysDiff < 0)THEN
    sign_ = -1
    daysDiff = ABS(daysDiff)
  ELSE
    sign_ = 1
  ENDIF

  days         = INT(daysDiff)
  hours        = INT((daysDiff-days)*d2h)
  minutes      = INT((daysDiff-days-hours*h2d)*d2m)
  seconds      = INT((daysDiff-days-hours*h2d-minutes*m2d)*d2s)
  milliseconds = NINT((daysDiff-days-hours*h2d-minutes*m2d&
                               -seconds*s2d)*d2s*1d3)

  t = timedelta(sign_*days,sign_*hours,sign_*minutes,sign_*seconds,&
                sign_*milliseconds)

ENDFUNCTION datetime_minus_datetime
!======================================================================>



!======================================================================>
!
! FUNCTION: gt
!
! DESCRIPTION: datetime object comparison operator. Returns .TRUE. if
! d0 is greater than d1, and .FALSE. otherwise. Overloads the 
! operator >.
!
!======================================================================>
PURE ELEMENTAL LOGICAL FUNCTION gt(d0,d1)

  TYPE(datetime),INTENT(IN) :: d0,d1

  ! Year comparison block
  IF(d0%year > d1%year)THEN
    gt = .TRUE.
  ELSEIF(d0%year < d1%year)THEN
    gt = .FALSE.
  ELSE

    ! Month comparison block
    IF(d0%month > d1%month)THEN
      gt = .TRUE.
    ELSEIF(d0%month < d1%month)THEN
      gt = .FALSE.
    ELSE

      ! Day comparison block
      IF(d0%day > d1%day)THEN
        gt = .TRUE.
      ELSEIF(d0%day < d1%day)THEN
        gt = .FALSE.
      ELSE

        ! Hour comparison block
        IF(d0%hour > d1%hour)THEN
          gt = .TRUE.
        ELSEIF(d0%hour < d1%hour)THEN
          gt = .FALSE.
        ELSE

          ! Minute comparison block
          IF(d0%minute > d1%minute)THEN
            gt = .TRUE.
          ELSEIF(d0%minute < d1%minute)THEN
            gt = .FALSE.
          ELSE

            ! Second comparison block
            IF(d0%second > d1%second)THEN
              gt = .TRUE.
            ELSEIF(d0%second < d1%second)THEN
              gt = .FALSE.
            ELSE

              ! Millisecond comparison block
              IF(d0%millisecond > d1%millisecond)THEN
                gt = .TRUE.
              ELSE
                gt = .FALSE.
              ENDIF

            ENDIF
          ENDIF
        ENDIF
      ENDIF
    ENDIF
  ENDIF

ENDFUNCTION gt
!======================================================================>



!======================================================================>
!
! FUNCTION: lt
!
! DESCRIPTION: datetime object comparison operator. Returns .TRUE. if
! d0 is less than d1, and .FALSE. otherwise. Overloads the operator <.
!
!======================================================================>
PURE ELEMENTAL LOGICAL FUNCTION lt(d0,d1)

  TYPE(datetime),INTENT(IN) :: d0,d1

  lt = d1 > d0

ENDFUNCTION lt
!======================================================================>



!======================================================================>
!
! FUNCTION: eq
!
! DESCRIPTION: datetime object comparison operator. Returns .TRUE. if
! d0 is equal to d1, and .FALSE. otherwise. Overloads the operator ==.
!
!======================================================================>
PURE ELEMENTAL LOGICAL FUNCTION eq(d0,d1)

  TYPE(datetime),INTENT(IN) :: d0,d1

  eq = d0%year        == d1%year   .AND. &
       d0%month       == d1%month  .AND. &
       d0%day         == d1%day    .AND. &
       d0%hour        == d1%hour   .AND. &
       d0%minute      == d1%minute .AND. &
       d0%second      == d1%second .AND. &
       d0%millisecond == d1%millisecond

ENDFUNCTION eq
!======================================================================>



!======================================================================>
!
! FUNCTION: ge
!
! DESCRIPTION: datetime object comparison operator. Returns .TRUE. if
! d0 is greater or equal than d1, and .FALSE. otherwise. Overloads the 
! operator >=.
!
!======================================================================>
PURE ELEMENTAL LOGICAL FUNCTION ge(d0,d1)

  TYPE(datetime),INTENT(IN) :: d0,d1

  ge = d0 > d1 .OR. d0 == d1

ENDFUNCTION ge
!======================================================================>



!======================================================================>
!
! FUNCTION: le
!
! DESCRIPTION: datetime object comparison operator. Returns .TRUE. if
! d0 is less or equal than d1, and .FALSE. otherwise. Overloads the 
! operator <=.
!
!======================================================================>
PURE ELEMENTAL LOGICAL FUNCTION le(d0,d1)

  TYPE(datetime),INTENT(IN) :: d0,d1

  le = d1 > d0 .OR. d0 == d1

ENDFUNCTION le
!======================================================================>



!======================================================================>
!
! FUNCTION: total_seconds
!
! DESCRIPTION: timedelta-bound procedure. Returns a total number of 
! seconds contained in a timedelta instance.
!
!======================================================================>
PURE ELEMENTAL REAL FUNCTION total_seconds(self)

  CLASS(timedelta),INTENT(IN) :: self

  total_seconds = self%days*86400 &
                 +self%hours*3600 &
                 +self%minutes*60 &
                 +self%seconds    &
                 +self%milliseconds*1E-3

ENDFUNCTION total_seconds
!======================================================================>



!======================================================================>
!
! FUNCTION: unary_minus_timedelta
!
! DESCRIPTION: Takes a negative of a timedelta instance. Overloads the 
! operator -.
!
!======================================================================>
PURE ELEMENTAL FUNCTION unary_minus_timedelta(t0) RESULT(t)

  TYPE(timedelta),INTENT(IN) :: t0
  TYPE(timedelta)            :: t

  t%days         = -t0%days
  t%hours        = -t0%hours
  t%minutes      = -t0%minutes
  t%seconds      = -t0%seconds
  t%milliseconds = -t0%milliseconds

ENDFUNCTION unary_minus_timedelta
!======================================================================>
  


!======================================================================>
!
! FUNCTION: isLeapYear
!
! DESCRIPTION: Given an integer year, returns .TRUE. if year is leap
! year, and .FALSE. otherwise.
!
!======================================================================>
PURE ELEMENTAL LOGICAL FUNCTION isLeapYear(year)

  INTEGER,INTENT(IN) :: year

  isLeapYear = (MOD(year,4)==0.AND..NOT.MOD(year,100)==0)&
           .OR.(MOD(year,400)==0)

ENDFUNCTION isLeapYear
!======================================================================>



!======================================================================>
!
! FUNCTION: daysInMonth
!
! DESCRIPTION: Given integer month and year, returns an integer number
! of days in that particular month.
!
!======================================================================>
PURE ELEMENTAL INTEGER FUNCTION daysInMonth(month,year)

  INTEGER,INTENT(IN) :: month,year

  INTEGER,PARAMETER,DIMENSION(12) :: &
          days = [31,28,31,30,31,30,31,31,30,31,30,31]

  IF(month<1.OR.month>12)THEN
    daysInMonth = 0
    RETURN 
  ENDIF

  IF(month==2.AND.isLeapYear(year))THEN
    daysInMonth = 29
  ELSE
    daysInMonth = days(month)
  ENDIF

ENDFUNCTION daysInMonth
!======================================================================>



!======================================================================>
!
! FUNCTION: daysInYear
!
! DESCRIPTION: Given an integer year, returns an integer number of days
! in that year.
!
!======================================================================>
PURE ELEMENTAL INTEGER FUNCTION daysInYear(year)

  INTEGER,INTENT(IN) :: year

  IF(isLeapYear(year))THEN
    daysInYear = 366
  ELSE
    daysInYear = 365
  ENDIF

ENDFUNCTION daysInYear
!======================================================================>



!======================================================================>
!
! FUNCTION: date2num
! 
! DESCRIPTION: Given a datetime instance d, returns number of days
! since 0001-01-01 00:00:00.
!
!======================================================================>
PURE ELEMENTAL REAL(KIND=real_dp) FUNCTION date2num(d)

  TYPE(datetime),INTENT(IN) :: d

  INTEGER :: year

  date2num = 0
  DO year = 1,d%year-1
    date2num = date2num+daysInYear(year)
  ENDDO

  date2num = date2num+d%yearday()+d%hour*h2d+d%minute*m2d&
            +(d%second+1d-3*d%millisecond)*s2d
 
ENDFUNCTION date2num
!======================================================================>



!======================================================================>
!
! FUNCTION: num2date
! 
! DESCRIPTION: Given number of days since 0001-01-01 00:00:00, returns a 
! correspoding datetime instance.
!
!======================================================================>
PURE ELEMENTAL TYPE(datetime) FUNCTION num2date(num)

  REAL(KIND=real_dp),INTENT(IN) :: num
  REAL(KIND=real_dp)            :: days,totseconds

  INTEGER :: year,month,day,hour,minute,second,millisecond

  days = num

  year = 1
  DO
    IF(days < daysInYear(year))EXIT
    days = days-daysInYear(year)
    year = year+1
  ENDDO

  month = 1
  DO
    IF(days < daysInMonth(month,year))EXIT
    days = days-daysInMonth(month,year)
    month = month+1
  ENDDO

  day         = INT(days)
  totseconds  = (days-day)*d2s
  hour        = INT(totseconds*s2h)
  minute      = INT((totseconds-hour*h2s)*s2m)
  second      = INT(totseconds-hour*h2s-minute*m2s)
  millisecond = NINT((totseconds-INT(totseconds))*1d3)

  num2date = datetime(year,month,day,hour,minute,second,millisecond)

  ! Handle a special case caused by floating-point arithmethic:
  IF(num2date%millisecond == 1000)THEN
    num2date%millisecond = 0
    CALL num2date%addSeconds(1)
  ENDIF

ENDFUNCTION num2date
!======================================================================>



!======================================================================>
!
! FUNCTION: int2str
!
! DESCRIPTION: Converts an integer i into a character string of 
! requested length, by pre-pending zeros if necessary.
!
!======================================================================>
PURE FUNCTION int2str(i,length)

  INTEGER,INTENT(IN)    :: i,length
  CHARACTER(LEN=length) :: int2str

  WRITE(UNIT=int2str,FMT='(I0)')i

  DO WHILE(LEN_TRIM(ADJUSTL(int2str)) < length)
    int2str = '0'//TRIM(ADJUSTL(int2str))
  ENDDO

ENDFUNCTION int2str
!======================================================================>
ENDMODULE datetime_module