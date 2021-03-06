# Automated CTest Builds -- Workhorse File
#
# Do not define any new CTEST_* variables, prefix them with SEQAN!
#
# Variable ${CTEST_MODEL} comes from command line, this saves 1/2
# of CMake files.
#
# Environment Variables set from outside:
#
# BUILDNAME  - A descriptive name of the triggered build.
# PLATFORM   - A string of value unix/windows
# GIT_BRANCH - The target branch name that is tested.
# BITS       - The target architecture to build for.
# MODEL      - The deployment model: continues, nightly, experimental
# WORKSPACE  - The workspace with the checkout-$ENV{GIT_BRANCH} and build-$ENV{GIT_BRANCH} directories
# HOSTBITS   - [optional] The bits of the host platform: defaults to 64.
# THREADS    - [optional] The number of processor to use for build: defaults to 4
#
# Windows specific variables
# WIN_CTEST_GENERATOR          - One of Visual Studio 14 2015, ...
# WIN_CTEST_GENERATOR_TOOLSET  - [optional] One of: none, clang, intel, defaults to none


CMAKE_MINIMUM_REQUIRED (VERSION 2.6)
cmake_policy (SET CMP0011 NEW)  # Suppress warning about PUSH/POP policy change.

# ---------------------------------------------------------------------------
# MANDATORY EXTERNAL VARIABLES
# ---------------------------------------------------------------------------

if (NOT DEFINED ENV{BUILDNAME})
    message (FATAL_ERROR "No BUILDNAME defined (can be arbitary STRING).")
endif (NOT DEFINED ENV{BUILDNAME})

if (NOT DEFINED ENV{PLATFORM})
    message (FATAL_ERROR "No Platform defined (should be unix or windows).")
endif (NOT DEFINED ENV{PLATFORM})

if (NOT DEFINED ENV{GIT_BRANCH})
    message (FATAL_ERROR "No GIT_BRANCH defined (can be master or develop).")
endif (NOT DEFINED ENV{GIT_BRANCH})

if (NOT DEFINED ENV{BITS})
    message (FATAL_ERROR "No BITS defined (target bit size, should be 32 or 64)")
endif (NOT DEFINED ENV{BITS})

#TODO: We always assume 64 bit host system
if (NOT DEFINED ENV{HOSTBITS})
    set (ENV{HOSTBITS} 64)  # Default to 64 bits.
endif (NOT DEFINED ENV{HOSTBITS})

if (NOT DEFINED ENV{MODEL})
    set (ENV{MODEL} "Experimental")
endif (NOT DEFINED ENV{MODEL})

if (NOT "$ENV{BITS}" STREQUAL "$ENV{HOSTBITS}")
    # setting CMAKE_CXX_FLAGS here doesnt work because they are overwritten later
    if ($ENV{PLATFORM} MATCHES "unix")
        set(ENV{CXXFLAGS} "$ENV{CXXFLAGS} -m$ENV{BITS}")
    endif ()
endif (NOT "$ENV{BITS}" STREQUAL "$ENV{HOSTBITS}")

# ---------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ---------------------------------------------------------------------------
if (NOT DEFINED ENV{THREADS})
    set(ENV{THREADS} 4)
endif ()

if ($ENV{PLATFORM} MATCHES "unix")
    set (CTEST_BUILD_FLAGS "${CTEST_BUILD_FLAGS} -j $ENV{THREADS}")
else()
    set (CTEST_BUILD_FLAGS "${CTEST_BUILD_FLAGS} -m:$ENV{THREADS}")
endif()

# ------------------------------------------------------------
# Prepare windows environment
# ------------------------------------------------------------

if ($ENV{PLATFORM} MATCHES "win")
    if (NOT DEFINED ENV{WIN_CTEST_GENERATOR})
       message (FATAL_ERROR "No ctest generator specified: e.g.: Visual Studio 14 2015")
    endif ()

    if (DEFINED ENV{WIN_CTEST_GENERATOR_TOOLSET})
        set (SEQAN_CTEST_GENERATOR_TOOLSET "$ENV{WIN_CTEST_GENERATOR_TOOLSET}")
    else ()
        set (SEQAN_CTEST_GENERATOR_TOOLSET "none")
    endif ()

    set (SEQAN_CTEST_GENERATOR $ENV{WIN_CTEST_GENERATOR})

    # ---------------------------------------------------------------------------
    # Set SEQAN_CTEST_GENERATOR_SHORT and CTEST_BUILD_NAME from the
    # ${SEQAN_CTEST_*} variables.  On Unix, we use CTEST_GENERATOR_SHORT to
    # store the compiler and version.
    # ---------------------------------------------------------------------------

    if (SEQAN_CTEST_GENERATOR MATCHES "Visual Studio")
      # Set target bit width into generator if 64 bit.
        if ("$ENV{BITS}" EQUAL "64")
            if (NOT SEQAN_CTEST_GENERATOR MATCHES "16")
                set (SEQAN_CTEST_GENERATOR "${SEQAN_CTEST_GENERATOR} Win64")
            endif ()
        endif ()
        # Determine short generator name.
        if (SEQAN_CTEST_GENERATOR MATCHES "Visual Studio.*")
            # SEQAN_CTEST_GENERATOR has the name schema Visual Studio 14 2015,
            # Visual Studio 12 2013, or Visual Studio 11 2012
            # Thus match the first digits, e.g. 14, 12, or 11
            STRING (REGEX REPLACE "Visual Studio ([0-9]+).*" "VS\\1" SEQAN_CTEST_GENERATOR_SHORT "${SEQAN_CTEST_GENERATOR}")
        else ()
            message (FATAL_ERROR "Unknown generator ${SEQAN_CTEST_GENERATOR}")
        endif ()
    endif ()

    # if a toolset was set, like v140_clang_3_7, Intel C++ Compiler 16.0 or
    # LLVM-vs2014 append the correct version and compiler to
    # SEQAN_CTEST_GENERATOR_SHORT.
    #
    # For example:
    # * v140_clang_3_7 (clang/c2) appends "-clang++/c2-3.7"
    # * Intel C++ Compiler 16.0 (icpc) appends "-icpc-16.0"
    set(SEQAN_COMPILER_VERSION "${SEQAN_CTEST_GENERATOR_SHORT}")
    set(SEQAN_COMPILER "msvc-${SEQAN_COMPILER_VERSION}")
    if (NOT SEQAN_CTEST_GENERATOR_TOOLSET MATCHES "none")
        if (SEQAN_CTEST_GENERATOR_TOOLSET MATCHES "clang")
            STRING (REGEX REPLACE ".+clang_([0-9_]+).*" "\\1" SEQAN_COMPILER_VERSION "${SEQAN_CTEST_GENERATOR_TOOLSET}")
            STRING (REGEX REPLACE "_" "." SEQAN_COMPILER_VERSION "${SEQAN_COMPILER_VERSION}")
            set(SEQAN_CTEST_GENERATOR_SHORT "${SEQAN_CTEST_GENERATOR_SHORT}-clang++/c2-${SEQAN_COMPILER_VERSION}")
            set(SEQAN_COMPILER "c2-${SEQAN_COMPILER_VERSION}")
        elseif (SEQAN_CTEST_GENERATOR_TOOLSET MATCHES "Intel")
            STRING (REGEX REPLACE ".*Intel.*Compiler ([0-9.]+).*" "\\1" SEQAN_COMPILER_VERSION "${SEQAN_CTEST_GENERATOR_TOOLSET}")
            set(SEQAN_CTEST_GENERATOR_SHORT "${SEQAN_CTEST_GENERATOR_SHORT}-icpc-${SEQAN_COMPILER_VERSION}")
            set(SEQAN_COMPILER "icc-${SEQAN_COMPILER_VERSION}")
        else ()
            message (FATAL_ERROR "Unknown toolset ${SEQAN_CTEST_GENERATOR_TOOLSET}")
        endif()
        set (CTEST_CMAKE_GENERATOR_TOOLSET ${SEQAN_CTEST_GENERATOR_TOOLSET})
    endif()

    message (STATUS "SEQAN_CTEST_GENERATOR is ${SEQAN_CTEST_GENERATOR}")
    message (STATUS "SEQAN_CTEST_GENERATOR_SHORT is ${SEQAN_CTEST_GENERATOR_SHORT}")
    set (CTEST_CMAKE_GENERATOR ${SEQAN_CTEST_GENERATOR})
else ($ENV{PLATFORM} MATCHES "win")
    set (CTEST_CMAKE_GENERATOR "Unix Makefiles")
endif ($ENV{PLATFORM} MATCHES "win")

# ------------------------------------------------------------
# Set CTest variables describing the build.
# ------------------------------------------------------------

# determine full host name
find_program(HOSTNAME_CMD NAMES uname)
EXECUTE_PROCESS(COMMAND ${HOSTNAME_CMD} -n OUTPUT_VARIABLE FULL_HOSTNAME OUTPUT_STRIP_TRAILING_WHITESPACE)

# This project name is used for the CDash submission.
SET (CTEST_PROJECT_NAME "SeqAn")
set (CTEST_BUILD_NAME "$ENV{BUILDNAME}")
set (CTEST_SITE "${FULL_HOSTNAME}")

set (CTEST_NIGHTLY_START_TIME "00:00:00 UTC")
set (CTEST_DROP_METHOD "http")
set (CTEST_DROP_SITE "cdash.seqan.de")
set (CTEST_DROP_LOCATION "/submit.php?project=SeqAn")
set (CTEST_DROP_SITE_CDASH TRUE)

set (CTEST_TIMEOUT 600)
if (${CTEST_BUILD_NAME} MATCHES ".*memcheck.*")
    set (CTEST_TIMEOUT 7200)
endif (${CTEST_BUILD_NAME} MATCHES ".*memcheck.*")

# Increase reported warning and error count.
set (CTEST_CUSTOM_MAXIMUM_NUMBER_OF_ERRORS   1000)
set (CTEST_CUSTOM_MAXIMUM_NUMBER_OF_WARNINGS 1000)
# Make sure the compiler generates errors and warnings in English.
set ($ENV{LC_MESSAGES} "en_EN")

# ------------------------------------------------------------
# Set CTest variables for directories.
# ------------------------------------------------------------

# In theory one checkout for develop and master each would be enough
# but since multiple scripts might run in parallel they might conflict
# TODO(h4nn3s) move git clone and update into the sh script where locking
# can be used to prevent multiple checkout dirs
# WARNING then the changed files feature won't work, so maybe not.

# The Git checkout goes here.
set (CTEST_SOURCE_ROOT_DIRECTORY "$ENV{WORKSPACE}/checkout-$ENV{GIT_BRANCH}")
set (CTEST_SOURCE_DIRECTORY "${CTEST_SOURCE_ROOT_DIRECTORY}")

# Set build directory and directory to run tests in.
set (CTEST_BINARY_DIRECTORY "$ENV{WORKSPACE}/build-$ENV{GIT_BRANCH}")
set (CTEST_BINARY_TEST_DIRECTORY "${CTEST_BINARY_DIRECTORY}")

# ------------------------------------------------------------
# Set CTest variables for programs.
# ------------------------------------------------------------

# Give path to CMake.
set (CTEST_CMAKE_COMMAND cmake)

# ------------------------------------------------------------
# Find memcheck and coverage programs.
# ------------------------------------------------------------

# FIND_PROGRAM(CTEST_MEMORYCHECK_COMMAND NAMES valgrind)
# SET(CTEST_MEMORY_CHECK_COMMAND "/usr/bin/valgrind")
# SET(CTEST_MEMORYCHECK_COMMAND_OPTIONS "${CTEST_MEMORYCHECK_COMMAND_OPTIONS} --suppressions=${CTEST_SOURCE_ROOT_DIRECTORY}/util/valgrind/seqan.supp --suppressions=${CTEST_SOURCE_ROOT_DIRECTORY}/util/valgrind/python.supp --suppressions=/usr/lib/valgrind/python.supp")
# FIND_PROGRAM(CTEST_COVERAGE_COMMAND NAMES gcov)

# ------------------------------------------------------------
# Preparation of the binary directory.
# ------------------------------------------------------------

# Clear the binary directory to avoid problems.
CTEST_EMPTY_BINARY_DIRECTORY (${CTEST_BINARY_DIRECTORY})

# Write the initial cache to use for the binary tree.  Be careful to
# escape any quotes inside of this string if you use it.  This is the
# only way to communicate with the cmake process forked by ctest.
#
# Comments:
#
#   CMAKE_GENERATOR -- pass the generator
#      TODO(holtgrew): Neccesary?
#   CMAKE_BUILD_TYPE -- The build type.  We set this to Release since
#     the compiler tries its best to understand the code and unearths
#     some warning types only in this build type.

# Always write out the generator and some other settings.
file (WRITE "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt" "
      CMAKE_GENERATOR:INTERNAL=${CTEST_CMAKE_GENERATOR}
      #MEMORYCHECK_COMMAND:FILEPATH=${CTEST_MEMORYCHECK_COMMAND}
      #MEMORYCHECK_COMMAND_OPTIONS:STRING=--supressions=${CTEST_SOURCE_ROOT_DIRECTORY}/util/valgrind/seqan.supp
      #COVERAGE_COMMAND:FILEPATH=${CTEST_COVERAGE_COMMAND}
      MODEL:STRING=$ENV{MODEL}
      CTEST_TEST_TIMEOUT:STRING=${CTEST_TEST_TIMEOUT}
      SEQAN_ENABLE_CUDA:BOOL=OFF
      SEQAN_DEFINITIONS:INTERNAL=-DSEQAN_IGNORE_MISSING_OPENMP=1;
      ")

if (($ENV{PLATFORM} MATCHES "win") AND (NOT SEQAN_CTEST_GENERATOR_TOOLSET MATCHES "none"))
    file (APPEND "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt" "
          CMAKE_GENERATOR_TOOLSET:INTERNAL=${CTEST_CMAKE_GENERATOR_TOOLSET}
          ")
endif ()

# Give CMAKE_FIND_ROOT_PATH to cmake process.
if (DEFINED ENV{SEQAN_CMAKE_FIND_ROOT_PATH})
  file (APPEND "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt" "CMAKE_FIND_ROOT_PATH:INTERNAL=$ENV{SEQAN_CMAKE_FIND_ROOT_PATH}
")
endif (DEFINED ENV{SEQAN_CMAKE_FIND_ROOT_PATH})

# When running memory checks then generate debug symbols, otherwise compile
# in Release mode.
if (${CTEST_BUILD_NAME} MATCHES ".*memcheck.*")
  file (APPEND "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt" "
CMAKE_BUILD_TYPE:STRING=RelWithDebInfo")
else (${CTEST_BUILD_NAME} MATCHES ".*memcheck.*")
  file (APPEND "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt" "
CMAKE_BUILD_TYPE:STRING=Release")
endif (${CTEST_BUILD_NAME} MATCHES ".*memcheck.*")

# Allow disabling of library search in 64 bit dirs.
if (SEQAN_FIND_LIBRARY_USE_LIB64_PATHS_OFF)
    file (APPEND "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt" "
SEQAN_FIND_LIBRARY_USE_LIB64_PATHS_OFF:BOOL=ON")
endif (SEQAN_FIND_LIBRARY_USE_LIB64_PATHS_OFF)

# ------------------------------------------------------------
# Suppress certain warnings.
# ------------------------------------------------------------

# Of course, the following list should be kept as short as possible and should
# be limited to very small lists of system/compiler pairs.  However, some
# warnings cannot be suppressed from the source.  Also, the warnings
# suppressed here should be specific to certain system/compiler versions.
#
# If you add anything then document what it does.

set (CTEST_CUSTOM_WARNING_EXCEPTION
    # Suppress warnings about slow 64 bit atomic intrinsics.
    "compatibility.h.*: note:.*pragma message: slow.*64")

# ------------------------------------------------------------
# Perform the actual tests.
# ------------------------------------------------------------

## -- Start
message(" -- Start dashboard $ENV{MODEL} - ${CTEST_BUILD_NAME} --")

# if (${CTEST_BUILD_NAME} MATCHES ".*memcheck.*")
#     append sth to TRAK?
# endif (${CTEST_BUILD_NAME} MATCHES ".*memcheck.*")

CTEST_START ($ENV{MODEL} TRACK "$ENV{MODEL}-$ENV{GIT_BRANCH}")

# Update from repository, configure, build, test, submit.  These commands will
# get all necessary information from the CTEST_* variables set above.
message(" -- Update $ENV{MODEL} - ${CTEST_BUILD_NAME} --")
# CTEST_UPDATE    (RETURN_VALUE VAL)

CTEST_CONFIGURE (RETURN_VALUE _CONFIG_RES)

CTEST_BUILD     (CONFIGURATION Release
                 NUMBER_ERRORS _BUILD_ERRORS
                 NUMBER_WARNINGS _BUILD_WARNINGS)

CTEST_TEST      (PARALLEL_LEVEL $ENV{THREADS} RETURN_VALUE _TEST_RES)

# Run memory checks if configured to do so.
if (${CTEST_BUILD_NAME} MATCHES ".*memcheck.*")
  CTEST_MEMCHECK (BUILD "${CTEST_BINARY_TEST_DIRECTORY}")
endif (${CTEST_BUILD_NAME} MATCHES ".*memcheck.*")

# Run coverage checks if configured to do so.
if (${CTEST_BUILD_NAME} MATCHES ".*coverage.*")
  CTEST_COVERAGE(BUILD "${CTEST_BINARY_TEST_DIRECTORY}")
endif (${CTEST_BUILD_NAME} MATCHES ".*coverage.*")

CTEST_SUBMIT()

# indicate errors
if (${_BUILD_ERRORS} GREATER 0 OR ${_BUILD_WARNINGS} GREATER 0 OR NOT ${_CONFIG_RES} EQUAL 0 OR NOT ${_TEST_RES} EQUAL 0)
  message(STATUS "build errors: ${_BUILD_ERRORS}; build warnings: ${_BUILD_WARNINGS}; config errors: ${_CONFIG_RES}; test failure: ${_TEST_RES}")
  message(FATAL_ERROR "Finished with errors")
endif ()
