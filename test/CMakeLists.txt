# Locate GTest
find_package(GTest REQUIRED)



enable_testing()

set(UT squareRootTest)

add_executable(${UT}
    ${UT}.cpp)

gtest_discover_tests(${UT})
add_test(${UT} ${UT})

target_include_directories(${UT}
    PUBLIC
    ../src
    ${GTEST_INCLUDE_DIRS}
    )

target_link_libraries(${UT}
    test-profiling
    ${GTEST_LIBRARIES}
    pthread
    )

include(CodeCoverage)
setup_target_for_coverage_lcov(NAME ${UT}_coverage ${UT})
