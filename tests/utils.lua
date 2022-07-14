
local json = require "rxi-json-lua"

function read_trace_json_configuration(path)

  local f = assert(io.open(path, "r"))
  local content = f:read("*all")
  f:close()

  if content == nil then
    error('Couldnt read JSON trace configuration from: ' .. path)
  end

  return json.decode(content)

end

function read_trace(path)
  local f = assert(io.open(path, "r"))
  local content = f:read("*all")
  f:close()

  if content == nil then
    error('Couldnt read trace from: ' .. path)
  end

  results = {}
  for s in content:gmatch("[^%#][^\n]+\n") do
    local addr, read, written = string.match(s, "(%w+) (%d+) (%d+)")
    -- Ignore first header line with # at the beginning
    if addr ~= nil then
      results[tonumber(addr, 16)] = {tonumber(read), tonumber(written)}
    end
  end
  return results
end

function print_trace(trace)

  for addr, data in pairs(trace) do
    print(addr, ' ', data[1], ' ' , data[2])
  end

end

function print_accesses(accesses)

  for addr, data in pairs(accesses) do
    print(addr, ' ', data[1], ' ' , data[2])
  end

end

function table_len(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function add_accesses(collection, addr, reads, writes)

  local access_data = collection[addr]
  if access_data == nil then
    access_data = {reads, writes}
    collection[addr] = access_data
  else
    access_data[1] = access_data[1] + reads
    access_data[2] = access_data[2] + writes
  end

end

function get_var_address(variables, varname)

  local addr = variables[varname]
  if addr == nil then
      print('Available variables:')
      for index, data in pairs(variables) do
        print(index, data)
      end
      error('Address not found for variable ' .. varname .. '!')
  end
  return addr

end

function align_addr(addr, cacheline_size)
  return addr - (addr % cacheline_size)
end

function check_accesses(accesses, trace)

  local test_debug_output = os.getenv("TEST_DEBUG_OUTPUT")
  if test_debug_output ~= nil and string.upper(test_debug_output) == "TRUE" then
    print('----Trace----')
    print_trace(trace)
    print('----Accesses----')
    print_accesses(accesses)
  end

  for addr, data in pairs(accesses) do
    reads = data[1]
    writes = data[2]

    -- For simplicity, we allow tests to generate empty accesses.
    -- This simplifies writing tests for many iterations when sometimes we might have 'zero'
    -- accesses instead of adding more if conditions.
    if reads == 0 and writes == 0 then
      goto continue
    end

    local addr_data = trace[addr]
    if addr_data == nil then
      error('Address ' .. string.format("%x", addr) .. ' missing in the trace output!')
    end

    if addr_data[1] < reads then
      error('Incorrect number of reads ' .. addr_data[1] .. ' at address ' .. string.format("%x", addr) .. ', expected ' .. reads)
    else
      addr_data[1] = addr_data[1] - reads
    end

    if addr_data[2] < writes then
      error('Incorrect number of writes ' .. addr_data[2] .. ' at address ' .. string.format("%x", addr) .. ', expected ' .. writes)
    else
      addr_data[2] = addr_data[2] - writes
    end

    ::continue::
  end

end

function check_accesses_not_exist(accesses, trace)

  local test_debug_output = os.getenv("TEST_DEBUG_OUTPUT")
  if test_debug_output ~= nil and string.upper(test_debug_output) == "TRUE" then
    print('----Trace----')
    print_trace(trace)
    print('----Accesses----')
    print_accesses(accesses)
  end

  for addr, data in pairs(accesses) do
    reads = data[1]
    writes = data[2]

    -- For simplicity, we allow tests to generate empty accesses.
    -- This simplifies writing tests for many iterations when sometimes we might have 'zero'
    -- accesses instead of adding more if conditions.
    if reads == 0 and writes == 0 then
      goto continue
    end

    local addr_data = trace[addr]
    if addr_data ~= nil then
      error('Address ' .. string.format("%x", addr) .. ' exists in the trace but it should not!')
    end

    ::continue::
  end

end

return {
  read_trace = read_trace,
  read_trace_json_configuration = read_trace_json_configuration,
  print_trace = print_trace,
  print_accesses = print_accesses,
  check_accesses = check_accesses,
  check_accesses_not_exist = check_accesses_not_exist,
  get_var_address = get_var_address,
  align_addr = align_addr,
  add_accesses = add_accesses,
  table_len = table_len
}

