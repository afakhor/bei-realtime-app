cmake_minimum_required(VERSION 3.18)
project(bei_engine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_library(bei_engine SHARED
    src/bridge.cpp
)

set_target_properties(bei_engine PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/../app/android/app/src/main/jniLibs/arm64-v8a
)
