
local utils = require "../utils"

function test_suite(variables)
 
  local tracer_output = os.getenv("TRACER_OUTPUT")
  local cacheline_size = tonumber(os.getenv("CACHELINE_SIZE"))

  -- Verify trace of function foo.

  trace = utils.read_trace(tracer_output .. ".foo.0")

  accesses = {}
  local array_size = 100

  -- Generate array accesses
  local array_addr = utils.get_var_address(variables, 'array')
  for i=0,array_size-1 do

    local addr = utils.align_addr(array_addr + 4*i, cacheline_size)
    utils.add_accesses(accesses, addr, 1, 2)

  end

  -- Loop variables

  -- Offset is read once in first loop iteration
  local offset_addr = utils.align_addr(utils.get_var_address(variables, 'foo_offset'), cacheline_size)
  utils.add_accesses(accesses, offset_addr, array_size, 0)

  -- Size is read once in each iteration + once after last
  local size_addr = utils.align_addr(utils.get_var_address(variables, 'foo_size'), cacheline_size)
  utils.add_accesses(accesses, size_addr, 2*(array_size + 1), 0)

  -- Array pointer is read twice in each iteration of first loop.
  -- Then, it is read twice in each iteration of the second loop.
  -- The access is counted twice because it's 8 bytes
  local ptr_addr = utils.align_addr(utils.get_var_address(variables, 'foo_ptr'), cacheline_size)
  utils.add_accesses(accesses, ptr_addr, array_size * 3, 0)
  local ptr_addr = utils.align_addr(ptr_addr + 4, cacheline_size)
  utils.add_accesses(accesses, ptr_addr, array_size * 3, 0)

  -- In first loop, counter is read four times in each iteration (check, access array twice, update)
  -- In second loop, counter is read three times in each iteration (check, access array once, update)
  -- It is also written once in each iteration
  -- It is checked once after the computation is finished
  local counter_addr = utils.align_addr(utils.get_var_address(variables, 'foo_counter'), cacheline_size)
  utils.add_accesses(accesses, counter_addr, array_size * 4 + 1 + array_size * 3 + 1, array_size)

  utils.check_accesses(accesses, trace)

  -- Verify trace of function bar.

  trace = utils.read_trace(tracer_output .. ".bar.0")

  accesses = {}
  local array_size = 50

  -- Generate array accesses
  local array_addr = utils.get_var_address(variables, 'array')
  for i=0,array_size-1 do

    local addr = utils.align_addr(array_addr + 4*i, cacheline_size)
    utils.add_accesses(accesses, addr, 1, 1)

  end

  -- Loop variables

  -- Offset is read once in loop iteration
  local offset_addr = utils.align_addr(utils.get_var_address(variables, 'bar_offset'), cacheline_size)
  utils.add_accesses(accesses, offset_addr, array_size, 0)

  -- Size is read once in each iteration + once after last
  local size_addr = utils.align_addr(utils.get_var_address(variables, 'bar_size'), cacheline_size)
  utils.add_accesses(accesses, size_addr, array_size + 1, 0)

  -- Array pointer is read twice in each iteration of loop.
  -- The access is counted twice because it's 8 bytes
  local ptr_addr = utils.align_addr(utils.get_var_address(variables, 'bar_ptr'), cacheline_size)
  utils.add_accesses(accesses, ptr_addr, array_size * 2, 0)
  local ptr_addr = utils.align_addr(ptr_addr + 4, cacheline_size)
  utils.add_accesses(accesses, ptr_addr, array_size * 2, 0)

  -- Counter is read four times in each iteration (check, access array twice, update)
  -- It is also written once in each iteration
  -- It is checked once after the computation is finished
  local counter_addr = utils.align_addr(utils.get_var_address(variables, 'bar_counter'), cacheline_size)
  utils.add_accesses(accesses, counter_addr, array_size * 4 + 1, array_size)

  utils.check_accesses(accesses, trace)

end

return {
  test_suite = test_suite
}
