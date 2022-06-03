
project(memreuse-analyzer)
cmake_minimum_required(VERSION 3.11)

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(Pintool)

if(NOT Pintool_FOUND)
	message(FATAL_ERROR "Pintool has not been found but it's required. Please provide PIN_ROOT with correct location.")
endif()

add_subdirectory(pintool)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/bin/memtracer.in ${CMAKE_CURRENT_BINARY_DIR}/bin/memtracer @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/bin/memtracer_ompi.in ${CMAKE_CURRENT_BINARY_DIR}/bin/memtracer_ompi @ONLY)

