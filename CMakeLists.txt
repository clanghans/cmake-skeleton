cmake_minimum_required (VERSION 3.10)
project (HELLO)

include(CTest)

set(CMAKE_VERBOSE_MAKEFILE TRUE)
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

# add code coverage INTERFACE target and set compiler options
add_library(test-profiling INTERFACE)
target_compile_options(test-profiling INTERFACE "--coverage")
target_link_libraries(test-profiling INTERFACE "gcov")

# Recurse into the "Hello" and "Demo" subdirectories. This does not actually
# cause another cmake executable to run. The same process will walk through
# the project's entire directory structure.
add_subdirectory (src)
add_subdirectory (test)
