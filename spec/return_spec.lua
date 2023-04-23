local Lump = require "lump"

describe("unuse #t", function()
  it("will return a table", function()
    local key = "some-key"
    local l = Lump.new(2, function() return {} end)
    local one = l:get(key)
    local segment = l.segments[key]
    assert.are.equal(0, #segment.unused)
    assert(l:unuse(one))
    assert.are.equal(1, #segment.unused)
    local two = l:get(key)
    assert.are.equal(one, two)
  end)
  it("will error for bad key", function()
    local key = "some-key"
    local l = Lump.new(1, function() return {} end)
    local one = l:get(key)
    local success, err = l:unuse(one, "other-key")
    assert.are.equal(nil, success)
    assert.are.equal("unknown key", err)
  end)
end)
