
local utils = require "../utils"

function test_suite(variables)
 
  local tracer_output = os.getenv("TRACER_OUTPUT")
  local cacheline_size = tonumber(os.getenv("CACHELINE_SIZE"))

  local size = 5

  for iteration=0,size-1 do

    print('Processing trace: ' .. tracer_output .. ".foo." .. iteration)
    trace = utils.read_trace(tracer_output .. ".foo." .. iteration)

    local array_size = iteration

    accesses = {}

    -- Generate array accesses
    local array_addr = utils.get_var_address(variables, 'array')
    for i=0,array_size-1 do
      local addr = utils.align_addr(array_addr + 4*i, cacheline_size)

      utils.add_accesses(accesses, addr, 1, 1)
    end

    -- Loop variables

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

    utils.check_accesses(accesses, trace)

  end

  return reserved
end

return {
  test_suite = test_suite
}
