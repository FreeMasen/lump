local Lump = require "lump"

describe("GC Guard", function()
  it("works", function()
    local l = Lump.new(2, function() return {} end)
    local function test()
      local entry = l:get()
      return string.format("%s", entry)
    end
    local one = test()
    collectgarbage("collect")
    local two = test()
    assert.are.equal(one, two)
  end)
end)
