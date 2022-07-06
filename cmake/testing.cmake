
enable_testing()

find_package(LuaExec REQUIRED)

set(tests serial_single_function)
set(serial_single_function tests/serial/single_function.cpp 1 64)

foreach(list_name IN LISTS tests)

  list(GET ${list_name} 0 test_location)
  list(SUBLIST ${list_name} 1 -1 cache_sizes)

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
      "TEST_MODULE=${CMAKE_CURRENT_SOURCE_DIR}/tests/serial;TEST_NAME=${filename};CACHELINE_SIZE=${cachesize};TRACER_OUTPUT=${CMAKE_CURRENT_BINARY_DIR}/tests/${testname}_${cachesize}.out"
    )

  endforeach()
endforeach()

