
set(LUA_ROOT "" CACHE STRING "Provide location of the Lua installation.")

find_program(LUA_EXECUTABLE lua HINTS ${LUA_ROOT})

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(LuaExec DEFAULT_MSG LUA_EXECUTABLE)

