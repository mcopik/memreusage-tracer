
project(memreuse-analyzer)
cmake_minimum_required(VERSION 3.11)

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(Pintool)

if(NOT Pintool_FOUND)
	message(FATAL_ERROR "Pintool has not been found but it's required. Please provide PIN_ROOT with correct location.")
endif()

add_subdirectory(pintool)

