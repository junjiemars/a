#!/bin/sh

_ROOT_DIR_="`cd -- $(dirname -- $0) && pwd`"
_TEST_="${_TEST_:-basic}"
_CFG_OPT_="${_CFG_OPT_}"
_OS_NAME_="`uname -s 2>/dev/null`"
_WIN_ENV_=
_WIN_ENV_MSVC_=
_CC_DIR_="cc"
_OUT_DIR_="out"

case "$_OS_NAME_" in
  MSYS_NT-*|MINGW??_NT-*) _OS_NAME_="WinNT" ;;
esac

CC="${CC}"
if [ -z "$CC" ]; then
  case "$_OS_NAME_" in
    Darwin)  CC="clang" ;;
    Linux)   CC="gcc"   ;;
    WinNT)   CC="cl"    ;;
  esac
fi

make_test_env() {
  mkdir -p "${_ROOT_DIR_}/${_OUT_DIR_}"
}

make_test_cc_env() {
  local b="https://raw.githubusercontent.com/junjiemars/nore/master/bootstrap.sh"
  local d="${_ROOT_DIR_}/${_CC_DIR_}"
  mkdir -p "$d"
  pushd "${d}"

  curl $b -sSfL | sh -s -- --branch=edge && ./configure where

  popd
}

print_test_env() {
  echo "_ROOT_DIR_=${_ROOT_DIR_}"
  echo "_TEST_=${_TEST_}"
  echo "_CFG_OPT_=${_CFG_OPT_}"
  echo "_OS_NAME_=${_OS_NAME_}"
  echo "CC=${CC}"
}

test_linux_do() {
  local rc=0
  local cfg="$_CFG_OPT_ $*"
  echo "------------"
  echo "# $*"

  return $rc
}

test_darwin_do() {
  local rc=0
  local cfg="$_CFG_OPT_ $*"
  echo "------------"
  echo "# $*"

  return $rc
}

test_winnt_do() {
  local rc=0
  local cfg="$_CFG_OPT_ $*"
  local out="${_ROOT_DIR_}/${_OUT_DIR_}"
  echo "------------"
  echo "# $*"

  make_test_cc_env
  pushd "${out}"

  cat <<END > c.c
#include <stdio.h>
int main(void)
{
  printf("yoo\n");
}
END

  ls -lh "${out}/Makefile"

  cat <<END > Makefile
include ${out}/Makefile

c_root := ./
c_binout := \$(bin_path)/c\$(bin_ext)

c: \$(c_binout)
c_test: c
	\$(c_binout)

\$(c_binout): \$(c_root)/c.c
	\$(CC) \$(CFLAGS) \$(INC) \$^ \$(bin_out)\$@

END

  ./configure --out-dir="${out}"
  make clean c_test

  popd

  return $rc
}

# basic test
if [ "basic" = "$_TEST_" ]; then

  make_test_env
  print_test_env

  case "$_OS_NAME_" in
    Darwin)
      test_darwin_do
      ;;
    Linux)
      test_linux_do
      ;;
    WinNT)
      test_winnt_do
      ;;
  esac
fi


echo "!completed"

# eof
