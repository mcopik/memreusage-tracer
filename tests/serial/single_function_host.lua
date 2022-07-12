
local utils = require "../utils"

function generate_accesses_array(accesses, variables, cacheline_size, array_size)

  -- Generate array accesses
  local array_addr = utils.get_var_address(variables, 'array')
  for i=0,array_size-1 do
    local addr = utils.align_addr(array_addr + 4*i, cacheline_size)

    utils.add_accesses(accesses, addr, 1, 1)
  end

end

function generate_accesses_variables(accesses, variables, cacheline_size, array_size)

  -- Offset is read once in each iteration
  local offset_addr = utils.align_addr(utils.get_var_address(variables, 'offset'), cacheline_size)
  utils.add_accesses(accesses, offset_addr, array_size, 0)

  -- Size is read once in each iteration + once after last
  local size_addr = utils.align_addr(utils.get_var_address(variables, 'size'), cacheline_size)
  utils.add_accesses(accesses, size_addr, array_size + 1, 0)

  -- Array pointer is read twice in each iteration
  -- The access is counted twice because it's 8 bytes
  local ptr_addr = utils.align_addr(utils.get_var_address(variables, 'ptr'), cacheline_size)
  utils.add_accesses(accesses, ptr_addr, array_size * 2, 0)
  local ptr_addr = utils.align_addr(ptr_addr + 4, cacheline_size)
  utils.add_accesses(accesses, ptr_addr, array_size * 2, 0)

  -- Counter pointer is read four times in each iteration (check, access array twice, update)
  -- It is also written once in each iteration
  -- It is checked once after the computation is finished
  local counter_addr = utils.align_addr(utils.get_var_address(variables, 'counter'), cacheline_size)
  utils.add_accesses(accesses, counter_addr, array_size * 4 + 1, array_size)

end

function generate_accesses(variables, cacheline_size, array_size)

  accesses = {}

  -- Array access
  generate_accesses_array(accesses, variables, cacheline_size, array_size)

  -- Loop variables
  generate_accesses_variables(accesses, variables, cacheline_size, array_size)

  return accesses
end

function test_suite(variables)
 
  local tracer_output = os.getenv("TRACER_OUTPUT")
  local cacheline_size = tonumber(os.getenv("CACHELINE_SIZE"))
  local array_size = 100

  -- First test - correct access on the remote side.
  trace = utils.read_trace(tracer_output .. ".foo.0")
  
  accesses = generate_accesses(variables, cacheline_size, array_size)

  utils.check_accesses(accesses, trace)

  -- Now performing checks on the host side - no loop accesses should exist.
  -- counter variables should be there - we read their pointers for printing.

  trace = utils.read_trace(tracer_output .. ".host.0")

  -- We do not access the array
  accesses = {}
  generate_accesses_array(accesses, variables, cacheline_size, array_size)
  utils.check_accesses_not_exist(accesses, trace)

  -- We access loop variables, but only once writing the first value 
  -- We do not access the loop counter - it's unitialized before the loop.
  accesses = {}

  vars = {'offset', 'size', 'ptr'}
  for k,v in pairs(vars) do

    local variable = utils.align_addr(utils.get_var_address(variables, v), cacheline_size)
    utils.add_accesses(accesses, variable, 0, 1)

  end

  utils.check_accesses(accesses, trace)

  -- After the remote function ends, there should be no accesses anymore.

  trace = utils.read_trace(tracer_output .. ".host.1")

  -- Array access variables
  accesses = {}
  generate_accesses_array(accesses, variables, cacheline_size, array_size)
  utils.check_accesses_not_exist(accesses, trace)

  -- Loop variables - we check only for cacheline size 1
  -- Otherwise, other variables can get mixed in.
  if cacheline_size == 1 then

    accesses = {}
    generate_accesses_variables(accesses, variables, cacheline_size, array_size)
    utils.check_accesses_not_exist(accesses, trace)

  end

  -- Check
  json_cfg = utils.read_trace_json_configuration(tracer_output .. ".host_events")

  if #json_cfg ~= 1 then 
    error("Expected one element in JSON configuration, got " .. #json_cfg)
  end

  event = json_cfg[1]["before"]
  if event == nil then
    error("'Before' key not found in the configuration")
  end

  before_region = event["region"]
  if before_region == nil or before_region ~= "foo" then
    error("Expected 'before' region name 'foo ', got " .. before_region)
  end

  before_counter = event["counter"]
  if before_counter == nil or before_counter ~= 0 then
    error("Expected 'before' counter 0, got " .. before_counter)
  end

  return reserved
end

return {
  test_suite = test_suite
}
