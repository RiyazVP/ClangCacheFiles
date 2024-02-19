# This is typically invoked as:
# 
# cmake \
#   -G Ninja \
#   -B <build-dir> \
#   -DCMAKE_C_COMPILER=clang \
#   -DCMAKE_CXX_COMPILER=clang++ \
#   -DCMAKE_INSTALL_PREFIX=<install-dir> \
#   -DMY_BUILD_STAGE=<stage-num> \
#   -DMY_TARGET_MACHINE=$(uname -m) \
#   -DMY_TOOLCHAIN_HAS_LLD=ON \
#   -C Bootstrap.cmake \
#   <llvm-project-dir>/llvm
#
if (${MY_BUILD_STAGE} LESS 2)
  set(MY_BUILD_LAST_STAGE OFF CACHE BOOL "")
else()
  set(MY_BUILD_LAST_STAGE ON CACHE BOOL "")
endif()

set(CMAKE_BUILD_TYPE "Release" CACHE STRING "")

# Use lld if available
set(LLVM_ENABLE_LLD ${MY_TOOLCHAIN_HAS_LLD} CACHE BOOL "")

if (MY_BUILD_LAST_STAGE)
  set(LLVM_ENABLE_PROJECTS "clang;lld;clang-tools-extra" CACHE STRING "")
else()
  set(LLVM_ENABLE_PROJECTS "clang;lld" CACHE STRING "")
endif()

# LLVM "runtimes" to build.
set(LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")

set(LLVM_ENABLE_ZLIB "FORCE_ON" CACHE STRING "")

set(LLVM_TARGETS_TO_BUILD "host" CACHE STRING "")

if (MY_BUILD_LAST_STAGE)
  # Make a static build in Stage 2
  set(CMAKE_EXE_LINKER_FLAGS "-static-libstdc++ -static-libgcc -l:libc++abi.a" CACHE STRING "")
  set(CMAKE_SHARED_LINKER_FLAGS "-lc++abi" CACHE STRING "")

  # Use libc++ from stage1.
  set(LLVM_ENABLE_LIBCXX ON CACHE BOOL "")

  # This is necessary to statically link libc++ into clang.
  set(LLVM_STATIC_LINK_CXX_STDLIB "1" CACHE STRING "")
endif()

if (MY_TARGET_MACHINE AND MY_TARGET_MACHINE STREQUAL "x86_64")
  set(LLVM_BUILTIN_TARGETS "x86_64-unknown-linux-gnu;i386-unknown-linux-gnu" CACHE STRING "")
  set(LLVM_RUNTIME_TARGETS "x86_64-unknown-linux-gnu;i386-unknown-linux-gnu" CACHE STRING "")
elseif (MY_TARGET_MACHINE AND MY_TARGET_MACHINE STREQUAL "aarch64")
  set(LLVM_BUILTIN_TARGETS "aarch64-unknown-linux-gnu" CACHE STRING "")
  set(LLVM_RUNTIME_TARGETS "aarch64-unknown-linux-gnu" CACHE STRING "")
else()
  message(FATAL_ERROR "Undefined or unknown MY_TARGET_MACHINE")
endif()

# Disable arc migrate.
set(CLANG_ENABLE_ARCMT OFF CACHE BOOL "")

# Set clang's default --stdlib= to libc++.
set(CLANG_DEFAULT_CXX_STDLIB "libc++" CACHE STRING "")

# Set clang's default -fuse-ld= to lld.
set(CLANG_DEFAULT_LINKER "lld" CACHE STRING "")

if (MY_BUILD_LAST_STAGE)
  # Have clang default to llvm-objcopy.
  set(CLANG_DEFAULT_OBJCOPY "llvm-objcopy" CACHE STRING "")
endif()

# Set clang's default --rtlib= to compiler-rt.
set(CLANG_DEFAULT_RTLIB "compiler-rt" CACHE STRING "")

# Set clang's default --unwindlib= to libunwind.
set(CLANG_DEFAULT_UNWINDLIB "libunwind" CACHE STRING "")

# Disable static analyzer unless this is the last build stage
set(CLANG_ENABLE_STATIC_ANALYZER ${MY_BUILD_LAST_STAGE} CACHE BOOL "")

# Disable plugin support unless this is the last build stage
set(CLANG_PLUGIN_SUPPORT ${MY_BUILD_LAST_STAGE} CACHE BOOL "")

# The compiler builtins are necessary
set(COMPILER_RT_BUILD_BUILTINS ON CACHE BOOL "")

macro(SetBoolForeachTarget Var Value)
  set(${Var} ${Value} CACHE BOOL "")
  foreach(T ${LLVM_RUNTIME_TARGETS})
    set(RUNTIMES_${T}_${Var} ${Value} CACHE BOOL "")
  endforeach()
endmacro()

macro(SetStringForeachTarget Var Value)
  set(${Var} ${Value} CACHE STRING "")
  foreach(T ${LLVM_RUNTIME_TARGETS})
    set(RUNTIMES_${T}_${Var} ${Value} CACHE STRING "")
  endforeach()
endmacro()

SetBoolForeachTarget(COMPILER_RT_BUILD_XRAY ${MY_BUILD_LAST_STAGE})

# Compiler-rt is a replacement to libgcc.
SetBoolForeachTarget(COMPILER_RT_HAS_GCC_S_LIB OFF)

SetBoolForeachTarget(COMPILER_RT_USE_BUILTINS_LIBRARY ON)

SetBoolForeachTarget(LIBUNWIND_INCLUDE_DOCS ${MY_BUILD_LAST_STAGE})

SetBoolForeachTarget(LIBUNWIND_INCLUDE_TESTS ${MY_BUILD_LAST_STAGE})

# Need the headers to be available when we install-libunwind.
SetBoolForeachTarget(LIBUNWIND_INSTALL_HEADERS ON)

# Libunwind should use compiler-rt rather than libgcc.
SetBoolForeachTarget(LIBUNWIND_USE_COMPILER_RT ON)

# Needed to break the cycle between libc, libc++, and libunwind.
SetBoolForeachTarget(LIBCXXABI_ENABLE_STATIC_UNWINDER ON)

SetBoolForeachTarget(LIBCXXABI_INCLUDE_TESTS ${MY_BUILD_LAST_STAGE})

# libc++abi should use compiler-rt.
SetBoolForeachTarget(LIBCXXABI_USE_COMPILER_RT ON)

# libc++abi should use LLVM's libunwind.
SetBoolForeachTarget(LIBCXXABI_USE_LLVM_UNWINDER ON)

# libc++ should use libc++abi.
SetBoolForeachTarget(LIBCXX_CXX_ABI libcxxabi)

SetBoolForeachTarget(LIBCXX_ENABLE_EXPERIMENTAL_LIBRARY ${MY_BUILD_LAST_STAGE})

SetBoolForeachTarget(LIBCXX_HAS_ATOMIC_LIB OFF)

SetBoolForeachTarget(LIBCXX_HAS_GCC_LIB OFF)

SetBoolForeachTarget(LIBCXX_HAS_GCC_S_LIB OFF)

SetBoolForeachTarget(LIBCXX_INCLUDE_BENCHMARKS ${MY_BUILD_LAST_STAGE})

SetBoolForeachTarget(LIBCXX_INCLUDE_DOCS ${MY_BUILD_LAST_STAGE})

SetBoolForeachTarget(LIBCXX_INCLUDE_TESTS ${MY_BUILD_LAST_STAGE})

# libc++ should use compiler-rt.
SetBoolForeachTarget(LIBCXX_USE_COMPILER_RT ON)

SetStringForeachTarget(SANITIZER_CXX_ABI "libc++")

SetBoolForeachTarget(SANITIZER_CXX_ABI_INTREE ON)

SetStringForeachTarget(SANITIZER_TEST_CXX "libc++")

SetBoolForeachTarget(SANITIZER_TEST_CXX_INTREE ON)
