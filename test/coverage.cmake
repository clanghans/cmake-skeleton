# Locate GTest
find_package(GTest REQUIRED)
if (NOT GTEST_FOUND)
    message(FATAL_ERROR "gtest not found! Aborting...")
endif()

# Check prereqs
find_program( GCOV_PATH gcov )
find_program( LCOV_PATH  NAMES lcov lcov.bat lcov.exe lcov.perl)
find_program( GENHTML_PATH NAMES genhtml genhtml.perl genhtml.bat )
find_program( CPPFILT_PATH NAMES c++filt )

if(NOT GCOV_PATH)
    message(FATAL_ERROR "gcov not found! Aborting...")
endif()

if(NOT LCOV_PATH)
    message(FATAL_ERROR "lcov not found! Aborting...")
endif()

if(NOT GENHTML_PATH)
    message(FATAL_ERROR "genhtml not found! Aborting...")
endif()

# non-Debug builds make no sense
if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(FATAL_ERROR "Coverage results with a non-Debug build makes no sense")
endif()

set(COVERAGE_COMPILER_FLAGS "-g -fprofile-arcs -ftest-coverage"
    CACHE INTERNAL "")

#
# testing interface library
add_library(testing INTERFACE)
target_compile_options(testing INTERFACE "-fprofile-arcs" "-ftest-coverage" "-g" "--coverage")
target_link_libraries(testing INTERFACE "gcov" "GTest::GTest" "GTest::Main")
# target_include_directories(testing INTERFACE "")

# coverage helper
add_library(coverage-collection INTERFACE)

# setup target for coverage
function(unit_test_coverage)
    # parameter parsing
    set(options COVERAGE)
    set(oneValueArgs NAME)
    set(multiValueArgs SRC INCLUDE LINKING)
    cmake_parse_arguments(coverage "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    get_target_property(bindir ${coverage_NAME} BINARY_DIR)
    ## DEBUG
    message(STATUS "BINDIR: ${bindir}")

    set_property(TARGET coverage-collection
        APPEND
        PROPERTY INTERFACE_SOURCES ${coverage_NAME}_coverage
        )

    add_custom_target(${coverage_NAME}_coverage
        COMMAND ${bindir}/${coverage_NAME}
        DEPENDS coverage-baseline ${coverage_NAME}
        )

endfunction()

# PARAMETER:
# NAME target name
# SRC list of compilation units
# INLCUDE list of included files and folders
# LINKING additional linking
# COVERAGE enable coverage
function(unit_test)

    # parameter parsing
    set(options COVERAGE)
    set(oneValueArgs NAME)
    set(multiValueArgs SRC INCLUDE LINKING)
    cmake_parse_arguments(test "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    ## DEBUG
    message(STATUS "NAME: ${test_NAME}")
    message(STATUS "SRC: ${test_SRC}")
    message(STATUS "INCLUDE: ${test_INCLUDE}")
    message(STATUS "LINKING: ${test_LINKING}")

    add_executable(${test_NAME}
        ${test_SRC}
        )

    gtest_discover_tests(${test_NAME})
    add_test(NAME ${test_NAME} COMMAND ${test_NAME})

    target_include_directories(${test_NAME}
        PUBLIC
        ${test_INCLUDE}
        )

    target_link_libraries(${test_NAME}
        testing
        ${test_LINKING}
        )

    if(test_COVERAGE)
        unit_test_coverage(NAME ${test_NAME})
    endif()

endfunction()

### TODO
# I type: 'make coverage'
# run all tests and generate coverage
function(coverage)
    # parameter parsing
    set(options)
    set(oneValueArgs)
    set(multiValueArgs EXCLUDE)
    cmake_parse_arguments(test "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    get_target_property(TARGETS coverage-collection INTERFACE_SOURCES)

    set(BASEDIR ${PROJECT_SOURCE_DIR})

    set(LCOV_EXCLUDES "")
    foreach(EXCLUDE ${test_EXCLUDE} ${COVERAGE_EXCLUDES} ${COVERAGE_LCOV_EXCLUDES})
        if(CMAKE_VERSION VERSION_GREATER 3.4)
            get_filename_component(EXCLUDE ${EXCLUDE} ABSOLUTE BASE_DIR ${BASEDIR})
        endif()
        list(APPEND LCOV_EXCLUDES "${EXCLUDE}")
    endforeach()
    list(REMOVE_DUPLICATES LCOV_EXCLUDES)

    message(STATUS "Excludes: ${LCOV_EXCLUDES}")

    add_custom_target(coverage-baseline
        # Cleanup lcov
        COMMAND ${LCOV_PATH} --gcov-tool ${GCOV_PATH} -directory . -b ${BASEDIR} --zerocounters
        # Create baseline to make sure untouched files show up in the report
        COMMAND ${LCOV_PATH} --gcov-tool ${GCOV_PATH} -c -i -d . -b ${BASEDIR} -o coverage.base
        )

    add_custom_target(coverage
        # Capturing lcov counters and generating report
        COMMAND ${LCOV_PATH} --gcov-tool ${GCOV_PATH} --directory . -b ${BASEDIR} --capture --output-file coverage.capture
        # add baseline counters
        COMMAND ${LCOV_PATH} --gcov-tool ${GCOV_PATH} -a coverage.base -a coverage.capture --output-file coverage.total
        # filter collected data to final coverage report
        COMMAND ${LCOV_PATH} --gcov-tool ${GCOV_PATH} --remove coverage.total ${LCOV_EXCLUDES} --output-file coverage.info

        # Generate HTML output
        COMMAND ${GENHTML_PATH} ${GENHTML_EXTRA_ARGS} -o coverage coverage.info

        # Set output files as GENERATED (will be removed on 'make clean')
        BYPRODUCTS
        coverage.base
        coverage.capture
        coverage.total
        coverage.info
        coverage  # report directory

        DEPENDS ${TARGETS}
        VERBATIM # qutoe protect commandline parameters
        )
endfunction()
