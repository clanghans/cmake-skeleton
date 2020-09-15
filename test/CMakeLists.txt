
enable_testing()

include(coverage)

unit_test(NAME squareRootTest
    SRC squareRootTest.cpp
    INCLUDE ../src
    COVERAGE
    )

unit_test(NAME calcTest
    SRC calcTest.cpp
    INCLUDE ../src
    COVERAGE
    )

coverage(EXCLUDE "/usr/include/c++/7/**" "/usr/include/gtest/**/" "test/*")
