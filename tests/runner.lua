

local input = io.read("*all")
variables = {}
print(input)

for s in input:gmatch("variable:[^\n]+") do
  -- Look for the following lines: variable: {name} {addr}
  local _, name, value = string.match(s, "(%w+): ([%w_]+): (%w+)")

  if name ~= nil and value ~= nil then
    value = tonumber(value)
    variables[name] = value
  end
end

local test_module = os.getenv("TEST_MODULE")
local test_name = os.getenv("TEST_NAME")
local tests_location = os.getenv("TESTS_LOCATION")
package.path = package.path .. ";" .. tests_location .. "/?.lua" .. ";" .. test_module .. "/?.lua"
local test_suite = require(test_name)

test_suite.test_suite(variables)

