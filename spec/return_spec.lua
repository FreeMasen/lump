local Lump = require "lump"
local P = {}
P.__index = P
P.__tostring = function(self)
  return string.format("P(%s)", self)
end
describe("unuse #t", function()
  it("will return a table", function()
    local key = "some-key"
    local l = Lump.new(2, function() return {} end)
    local one = l:get(key)
    local segment = l.segments[key]
    assert.are.equal(0, #segment.unused)
    l:unuse(key, one)
    assert.are.equal(1, #segment.unused)
    local two = l:get(key)
    assert.are.equal(one, two)
  end)
end)
