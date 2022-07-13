
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

  local size = 5

  -- Correct access on the remote side.

  for iteration=0,size-1 do

    print('Processing trace: ' .. tracer_output .. ".foo." .. iteration)
    trace = utils.read_trace(tracer_output .. ".foo." .. iteration)
    
    accesses = generate_accesses(variables, cacheline_size, iteration)

    utils.check_accesses(accesses, trace)

  end

  -- Now performing checks on the host side
  -- All iterations, except the last one, read the first position.
  -- All iterations, except the first one, read the second position.

  for iteration=0,size-1 do

    print('Processing host trace: ' .. tracer_output .. ".host." .. iteration)
    trace = utils.read_trace(tracer_output .. ".host." .. iteration)

    -- We write first array address and read last address
    existing_accesses = {}
    not_existing_accesses = {}

    local array_addr = utils.get_var_address(variables, 'array')

    if iteration < size - 1 then
      local addr = utils.align_addr(array_addr, cacheline_size)
      utils.add_accesses(existing_accesses, addr, 0, 1)
    end

    if iteration > 0 then
      local addr = utils.align_addr(array_addr + 4, cacheline_size)
      utils.add_accesses(existing_accesses, addr, 1, 0)
    end

    -- Remove existing accesses - first and last
    generate_accesses_array(not_existing_accesses, variables, cacheline_size, array_size)
    for addr, data in pairs(existing_accesses) do
      not_existing_accesses[addr] = nil
    end

    utils.check_accesses(existing_accesses, trace)
    utils.check_accesses_not_exist(not_existing_accesses, trace)

  end

  -- Check the JSON output - 6 host events
  json_cfg = utils.read_trace_json_configuration(tracer_output .. ".host_events")

  if #json_cfg ~= 6 then 
    error("Expected six elements in JSON configuration, got " .. #json_cfg)
  end

  for iteration=1,6 do

    if iteration < 6 then

      event = json_cfg[iteration]["after"]
      if event == nil then
        error("'After' key not found at postion " .. iteration .. " in the configuration.")
      end

      region = event["region"]
      if region == nil or region ~= "foo" then
        error("Event " .. iteration .. ", expected region name 'for', got " .. region)
      end

      expected_counter = iteration - 1
      counter = event["counter"]
      if counter == nil or counter ~= expected_counter then
        error("Event " .. iteration .. ", expected counter " .. expected_counter .. ", got " .. counter)
      end

    end

    if iteration > 1 then

      event = json_cfg[iteration]["before"]
      if event == nil then
        error("'Before' key not found at postion " .. iteration .. " in the configuration.")
      end

      region = event["region"]
      if region == nil or region ~= "foo" then
        error("Event " .. iteration .. ", expected region name 'for', got " .. region)
      end

      expected_counter = iteration - 2
      counter = event["counter"]
      if counter == nil or counter ~= expected_counter then
        error("Event " .. iteration .. ", expected counter " .. expected_counter .. ", got " .. counter)
      end

    end

  end

  return reserved
end

return {
  test_suite = test_suite
}
