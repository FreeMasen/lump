local Lump = require "lump"

describe("GC Guard #g", function()
  it("works", function()
    local key = "some-key"
    local l = Lump.new(1, function() return {} end)
    local function test()
      local entry = l:get(key)
      return string.format("%s", entry)
    end
    local one = test()
    collectgarbage("collect")
    assert.are.equal(1, #l.segments[key].unused)
    local two = test()
    assert.are.equal(one, two)
  end)
end)
