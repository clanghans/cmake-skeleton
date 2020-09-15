cmake_minimum_required (VERSION 3.10)
project (HELLO)

# ccache - find and activate ccache if available
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
endif()

include(CTest)

set(CMAKE_VERBOSE_MAKEFILE TRUE)
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

set(CMAKE_BUILD_TYPE Debug)
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/test")

# add code coverage INTERFACE target and set compiler options
add_library(test-profiling INTERFACE)
target_compile_options(test-profiling INTERFACE "--coverage" "-O0")
target_link_libraries(test-profiling INTERFACE "gcov")

# Recurse into the "Hello" and "Demo" subdirectories. This does not actually
# cause another cmake executable to run. The same process will walk through
# the project's entire directory structure.
add_subdirectory (src)
add_subdirectory (test)
