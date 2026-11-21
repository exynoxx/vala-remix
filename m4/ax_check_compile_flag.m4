# Minimal AX_CHECK_COMPILE_FLAG(FLAG, [ACTION-SUCCESS], [ACTION-FAILURE], [EXTRA-FLAGS], [INPUT])
# ponytail: local stand-in for autoconf-archive's macro; drop when autoconf-archive is installed.
AC_DEFUN([AX_CHECK_COMPILE_FLAG],
[AS_VAR_PUSHDEF([CACHEVAR],[ax_cv_check_cflags_$4_$1])dnl
AC_CACHE_CHECK([whether _AC_LANG compiler accepts $1], CACHEVAR, [
  ax_check_save_flags=$CFLAGS
  CFLAGS="$CFLAGS $4 $1"
  AC_COMPILE_IFELSE([m4_default([$5],[AC_LANG_PROGRAM()])],
    [AS_VAR_SET(CACHEVAR,[yes])],
    [AS_VAR_SET(CACHEVAR,[no])])
  CFLAGS=$ax_check_save_flags])
AS_VAR_IF(CACHEVAR,yes,[m4_default([$2], :)],[m4_default([$3], :)])dnl
AS_VAR_POPDEF([CACHEVAR])dnl
])
