
set(PIN_ROOT "" CACHE STRING "Provide location of the pintool installation.")

if(NOT PIN_ROOT)
  set(PIN_ROOT "$ENV{PIN_ROOT}")
endif()

find_program(PINTOOL_PATH pin HINTS ${PIN_ROOT})

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(Pintool DEFAULT_MSG PINTOOL_PATH)

