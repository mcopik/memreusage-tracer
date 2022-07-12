
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

  -- Now performing checks on the host side
  -- counter variables should be there - we read their pointers for printing.

  trace = utils.read_trace(tracer_output .. ".host.0")

  -- We write first array address and read last address
  existing_accesses = {}
  not_existing_accesses = {}

  local array_addr = utils.get_var_address(variables, 'array')
  local addr = utils.align_addr(array_addr, cacheline_size)
  utils.add_accesses(existing_accesses, addr, 0, 1)
  local addr = utils.align_addr(array_addr + (array_size - 1) * 4, cacheline_size)
  utils.add_accesses(existing_accesses, addr, 1, 0)

  -- Remove existing accesses - first and last
  generate_accesses_array(not_existing_accesses, variables, cacheline_size, array_size)
  for addr, data in pairs(existing_accesses) do
    not_existing_accesses[addr] = nil
  end

  utils.check_accesses(existing_accesses, trace)
  utils.check_accesses_not_exist(not_existing_accesses, trace)

  -- Second check on the host side
  trace = utils.read_trace(tracer_output .. ".host.1")

  -- We write first array address and read last address
  existing_accesses = {}
  not_existing_accesses = {}

  local array_addr = utils.get_var_address(variables, 'array')
  local addr = utils.align_addr(array_addr, cacheline_size)
  utils.add_accesses(existing_accesses, addr, 1, 0)
  local addr = utils.align_addr(array_addr + (array_size - 1) * 4, cacheline_size)
  utils.add_accesses(accesses, addr, 0, 1)

  -- Remove existing accesses - first and last
  generate_accesses_array(not_existing_accesses, variables, cacheline_size, array_size)
  for addr, data in pairs(existing_accesses) do
    not_existing_accesses[addr] = nil
  end

  utils.check_accesses(existing_accesses, trace)
  utils.check_accesses_not_exist(not_existing_accesses, trace)

  -- Loop variables - we check only for cacheline size 1
  -- Otherwise, other stack variables can get mixed in.
  if cacheline_size == 1 then

    accesses = {}
    generate_accesses_variables(accesses, variables, cacheline_size, array_size)
    utils.check_accesses_not_exist(accesses, trace)

  end

  -- Check the JSON output
  json_cfg = utils.read_trace_json_configuration(tracer_output .. ".host_events")

  if #json_cfg ~= 2 then 
    error("Expected two elements in JSON configuration, got " .. #json_cfg)
  end

  first_event = json_cfg[1]["after"]
  if first_event == nil then
    error("'After' key not found in the configuration")
  end

  second_event = json_cfg[2]["before"]
  if second_event == nil then
    error("'Before' key not found in the configuration")
  end

  events = {first_event, second_event}
  for k, event in pairs(events) do

    region = event["region"]
    if region == nil or region ~= "foo" then
      error("Event " .. k .. ", expected region name 'foo ', got " .. before_region)
    end

    counter = event["counter"]
    if counter == nil or counter ~= 0 then
      error("Event " .. k .. ", expected counter 0, got " .. before_counter)
    end

  end

  return reserved
end

return {
  test_suite = test_suite
}
