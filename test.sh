#!/bin/sh

_ROOT_DIR_="`cd -- $(dirname -- $0) && pwd`"
_CI_DIR_="${_ROOT_DIR_%/}/ci"
_BRANCH_="${_BRANCH_:-edge}"
_OS_NAME_="`uname -s 2>/dev/null`"
_MSVC_ENV_=
_TRACE_="${_TRACE_}"

case "${_OS_NAME_}" in
  MSYS_NT-*|MINGW??_NT-*) _OS_NAME_="WinNT" ;;
esac

CC="${CC}"
if [ -z "$CC" ]; then
  case "$_OS_NAME_" in
    Darwin)                 CC="clang" ;;
    Linux)                  CC="gcc"   ;;
    WinNT)                  CC="cl"    ;;
  esac
fi


env_ci_build () {
  echo "------------"
  echo "CC=$CC"
  echo "_ROOT_DIR_=$_ROOT_DIR_"
  echo "_CI_DIR_=$_CI_DIR_"
  echo "------------"

  cd "${_CI_DIR_}"

  if [ "WinNT" = "${_OS_NAME_}" -a "cl" = "${CC}" ]; then
    if [ ! -f "${HOME}/.nore/cc-env.sh" ]; then
      echo "!panic: ${HOME}/.nore/cc-env.sh no found"
      exit 1
    fi
    ${HOME}/.nore/cc-env.sh 1

    if [ ! -f "${HOME}/.nore/cc-env.bat" ]; then
      echo "!panic: ${HOME}/.nore/cc-env.bat no found"
      exit 1
    fi
    _MSVC_ENV_="${HOME}/.nore/cc-env.bat"
  fi
}

test_what () {
  echo "------------"
  echo "# $@ ..."
  echo "------------"
}

test_configure () {
  local msvc_bat="msvc.bat"
  cd "$_CI_DIR_"
  if [ -z "${_MSVC_ENV_}" ]; then
    ./configure ${_TRACE_} $@
  else
    cat << END > "${msvc_bat}"
@if not "%VSCMD_DEBUG%" GEQ "3" echo off
REM generated by Nore (https://github.com/junjiemars/nore)
call "%1"
sh ./configure ${_TRACE_} $@
END
    if [ ! -f "${msvc_bat}" ]; then
      echo "!panic: generate msvc.bat failed"
      exit 1
    fi
    chmod u+x ${msvc_bat}
    ./${msvc_bat} "${_MSVC_ENV_}"
  fi
}

install_nore_from_github () {
  local b="https://raw.githubusercontent.com/junjiemars/nore/master/bootstrap.sh"
  test_what "install from github.com"
  if [ -d "$_CI_DIR_" ]; then
    rm -r "${_CI_DIR_}"
  fi
  mkdir -p "$_CI_DIR_" && cd "$_CI_DIR_"

  curl $b -sSfL | sh -s -- --branch=$_BRANCH_
}

test_make_print_database () {
  test_what "print the make's predefined database"
  make -C "$_CI_DIR_" -p 2>&1 || echo "------------"
}

test_make () {
  local msvc_bat="msvc.bat"
  cd "$_CI_DIR_"
  if [ -z "${_MSVC_ENV_}" ]; then
    make $@
  else
    cat << END > "${msvc_bat}"
@if not "%VSCMD_DEBUG%" GEQ "3" echo off
REM generated by Nore (https://github.com/junjiemars/nore)
call "%1"
"%2" "%3"
END
    if [ ! -f "${msvc_bat}" ]; then
      echo "!panic: generate msvc.bat failed"
      exit 1
    fi
    chmod u+x ${msvc_bat}
    ./${msvc_bat} "${_MSVC_ENV_}" "make $@"
  fi
}

test_nore_where_command () {
  test_what "./configure where"
  test_configure where
}

test_c_program () {
  local c="`basename $_CI_DIR_`.c"
  local m="Makefile"

  cat <<END > "$c"
#include <nore.h>
#include <stdio.h>

#if (MSVC)
#  if !(defined(unused) || defined(__attribute__))
#    define unused  warning(suppress:4100 4101 4189)
#    define __attribute__(unused)  __pragma unused
#  endif
#elif defined(__has_attribute) && __has_attribute(unused)
#elif !(defined(__attribute__) || defined(unused))
#  define unused
#  define __attribute__(_)
#endif


#if defined(__has_attribute) && __has_attribute(fallthrough)
#elif !(defined(__attribute__) || defined(fallthrough))
#  define fallthrough
#  define __attribute__(_)
#endif

static void fn(void);

int main(void) {
  __attribute__((unused)) int x = 0;
  __attribute__((unused)) int y = 0;
  printf("sizeof(fpos_t) = %zu\n", sizeof(fpos_t));
  __attribute__((fallthrough));
  return 0;
}

void
fn(void)
{
  printf("XXX\n");
}
END


  cat <<END > "$m"
include out/Makefile

ci_root := ./
ci_binout := \$(bin_path)/ci\$(bin_ext)
ci_cppout := \$(tmp_path)/ci\$(cpp_ext)

ci: \$(ci_binout)
ci_test: ci
	\$(ci_binout)
	cat \$(ci_cppout)

\$(ci_binout): \$(ci_cppout)
	\$(CC) \$(CFLAGS) \$^ \$(bin_out)\$@

\$(ci_cppout): \$(ci_root)/ci.c
	\$(CC) \$(CPPFLAGS) \$(INC) \$(nm_stage_pre) \$^ \$(cpp_out)\$@
END

  test_what "CC=$CC ./configure --with-optimize=yes"
  test_configure --with-optimize=yes
  test_make clean test
}

# clone nore
if [ -n "$_INSIDE_CI_" ]; then
  install_nore_from_github
fi

# env build
env_ci_build

# test_make_print_database
test_nore_where_command
test_c_program
# cat /etc/passwd


echo "#!completed"

# eof
