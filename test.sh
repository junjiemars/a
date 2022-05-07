#!/bin/sh

_ROOT_DIR_="`cd -- $(dirname -- $0) && pwd`"
_TEST_="${_TEST_:-basic}"
_CFG_OPT_="${_CFG_OPT_}"
_OS_NAME_="`uname -s 2>/dev/null`"
_WIN_ENV_=
_WIN_ENV_MSVC_=

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
  cd "${_ROOT_DIR_}"
  mkdir -p out
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
  
  $CC --version
  # ctags --version
  # readtags --version
  
  echo '' | $CC -v -E 2>&1 >/dev/null -
  
  # find                                                                                                                      \
  #       /usr/local/include                                                                                                  \
  #       /Applications/Xcode_13.2.1.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/13.0.0/include  \
  #       /Applications/Xcode_13.2.1.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include   \
  #       /Applications/Xcode_13.2.1.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include                   \
  # \( -type f -exec grep -q -e major \{\} \; \) -ls
  
  echo "--------------------"

  ctags -a --c-kinds=+p -oout/x.TAGS                                                                                        \
        /usr/local/include                                                                                                  \
        /Applications/Xcode_13.2.1.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/13.0.0/include  \
        /Applications/Xcode_13.2.1.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include   \
        /Applications/Xcode_13.2.1.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include

  
  return $rc
}

test_winnt_do() {
  local rc=0
  local cfg="$_CFG_OPT_ $*"
  echo "------------"
  echo "# $*"
  
  return $rc
}

# basic test
if [ "basic" = "$_TEST_" ]; then
  make_test_env
  
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
