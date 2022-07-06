
function read_trace(path)
  local f = assert(io.open(path, "r"))
  local content = f:read("*all")
  f:close()
  results = {}
  for s in content:gmatch("[^%#][^\n]+\n") do
    local addr, size, read, written, read_outside, written_outside = string.match(s, "(%w+) (%d+) (%d+) (%d+) (%d+) (%d+)")
    -- Ignore first header line with # at the beginning
    if addr ~= nil then
      results[tonumber(addr, 16)] = {tonumber(size), tonumber(read), tonumber(written), tonumber(read_outside), tonumber(written_outside)}
    end
  end
  return results
end

return {
  read_trace = read_trace
}

