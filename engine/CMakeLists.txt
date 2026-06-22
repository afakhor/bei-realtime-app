cmake_minimum_required(VERSION 3.18)
project(bei_engine)

set(CMAKE_CXX_STANDARD 17)

add_library(bei_engine SHARED src/bridge.cpp)

# log-lib cuma ada di Android
if(ANDROID)
    find_library(log-lib log)
    target_link_libraries(bei_engine ${log-lib})
endif()