
enable_testing()

find_package(LuaExec REQUIRED)
find_package(Python)

set(tests
  serial_single_function
  serial_two_functions
  serial_iterations
  serial_single_function_host
  serial_single_function_host_reuse
  serial_two_functions_host_reuse
  serial_iterations_host_reuse
  serial_iterations_host_reuse_long
)
set(serial_single_function tests/serial/single_function.cpp FALSE 1 64)
set(serial_two_functions tests/serial/two_functions.cpp FALSE 1 64)
set(serial_iterations tests/serial/iterations.cpp FALSE 1 64)
set(serial_single_function_host tests/serial/single_function_host.cpp FALSE 1 64)
set(serial_single_function_host_reuse tests/serial/single_function_host_reuse.cpp TRUE 1 64)
set(serial_two_functions_host_reuse tests/serial/two_functions_host_reuse.cpp FALSE 1 64)
set(serial_iterations_host_reuse tests/serial/iterations_host_reuse.cpp FALSE 1 64)
set(serial_iterations_host_reuse_long tests/serial/iterations_host_reuse_long.cpp FALSE 1 64)

find_package(Python COMPONENTS Interpreter)
if(NOT Python_FOUND)
  message(WARNING "Could not find Python, tool's tests are not enabled!")
  set(WITH_PYTHON FALSE)
else()
  message(STATUS "Found Python, enabling tool's test.")
  set(WITH_PYTHON TRUE)
endif()

foreach(list_name IN LISTS tests)

  list(GET ${list_name} 0 test_location)
  list(GET ${list_name} 1 has_python_test)
  list(SUBLIST ${list_name} 2 -1 cache_sizes)

  get_filename_component(filename ${test_location} NAME_WLE)
  get_filename_component(location ${test_location} DIRECTORY)
  string(REPLACE "/" "_" testname "${location}/${filename}")

  # Create test executable shared for all cache values.
  add_executable(${testname}_exe ${test_location})
  target_link_libraries(${testname}_exe PUBLIC memreuse)
  set_target_properties(${testname}_exe PROPERTIES RUNTIME_OUTPUT_DIRECTORY tests)
  set_target_properties(${testname}_exe PROPERTIES WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tests/)

  # Create a different test for each cache value
  # This syntax works for lists with semi-colons
  # For a list with spaces, we need the syntax above
  foreach(cachesize ${cache_sizes})

    add_test(
      NAME ${testname}_${cachesize}
      COMMAND bash -c "${CMAKE_CURRENT_BINARY_DIR}/bin/memtracer -c ${cachesize} -o ${testname}_${cachesize}.out $<TARGET_FILE:${testname}_exe> | ${LUA_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/tests/runner.lua" WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tests/
    )
    set_tests_properties(
      ${testname}_${cachesize}
      PROPERTIES ENVIRONMENT
      "TEST_MODULE=${CMAKE_CURRENT_SOURCE_DIR}/tests/serial;TEST_NAME=${filename};CACHELINE_SIZE=${cachesize};TESTS_LOCATION=${CMAKE_CURRENT_SOURCE_DIR}/tests;TRACER_OUTPUT=${CMAKE_CURRENT_BINARY_DIR}/tests/${testname}_${cachesize}.out"
    )

    if(${WITH_PYTHON} AND ${has_python_test})

      add_test(
        NAME ${testname}_${cachesize}_python
        COMMAND ${Python_EXECUTABLE} -m pytest ${CMAKE_CURRENT_SOURCE_DIR}/tests/serial/${filename}.py
      )
      set_tests_properties(
        ${testname}_${cachesize}_python
        PROPERTIES ENVIRONMENT
        "CACHELINE_SIZE=${cachesize};PYTHONPATH=${CMAKE_CURRENT_SOURCE_DIR};TRACER_OUTPUT=${CMAKE_CURRENT_BINARY_DIR}/tests/${testname}_${cachesize}.out"
      )
      # Wait until previous test generates input files
      set_tests_properties(${testname}_${cachesize}_python PROPERTIES DEPENDS ${testname}_${cachesize})

    endif()

  endforeach()
endforeach()

