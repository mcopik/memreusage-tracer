

local input = io.read("*all")
variables = {}
print(input)

for s in input:gmatch("variable:[^\n]+") do
  local _, name, value = string.match(s, "(%w+): (%w+): (%w+)")
  value = tonumber(value)
  variables[name] = value
end

local test_module = os.getenv("TEST_MODULE")
local test_name = os.getenv("TEST_NAME")
package.path = package.path .. ";" .. "/home/mcopik/projects/ETH/serverless/2022/performance_modeling/pintool_tests/pintool-memory-analyzer/tests/?.lua" .. ";" .. test_module .. "/?.lua"
local test_suite = require(test_name)

test_suite.test_suite(variables)

