
# avoid going over all Pin targets
add_custom_target(
  pintool_tracer
  ALL
  COMMAND make -f Makefile.pin obj-intel64 obj-intel64/memtracer.so
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Makefile.in ${CMAKE_CURRENT_BINARY_DIR}/Makefile.pin @ONLY)

install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/obj-intel64/memtracer.so DESTINATION lib/memtracer-pintool.so)

