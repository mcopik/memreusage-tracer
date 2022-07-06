
local read_trace = require "../read_trace"

function test_suite(variables)
 
  local tracer_output = os.getenv("TRACER_OUTPUT")
  local cacheline_size = tonumber(os.getenv("CACHELINE_SIZE"))
  --print(tracer_output, cacheline_size)

  trace = read_trace.read_trace(tracer_output)

  -- Generate array accesses
  local array_size = 100
  local addr = variables['array']
  if addr == nil then
      print('Available variables:')
      for index, data in pairs(variables) do
        print(index, data)
      end
      error('Array address not found!')
  end
  for i=0,array_size-1,cacheline_size do
    local addr_data = trace[addr]
    if addr_data == nil then
      error('Array address ' .. addr .. ' missing in the trace output!')
    end
    -- We read one element from each array.
    -- Thus, we read $cacheline elements from each cache line.
    --print(addr_data[2])
    --print(addr+i)
    if addr_data[2] ~= cacheline_size then
      error('Incorrect number of reads ' .. addr_data[2] .. ' at address ' .. addr)
    end
  end

  return reserved
end

return {
  test_suite = test_suite
}
