local Lump = require "lump"

describe("unuse", function()
  it("will return a table", function()
    local l = Lump.new(2, function() return {} end)
    local one = l:get("some-key")
    assert.are.equal(1, l.segments["some-key"]._in_use_ct)
    assert.are.equal(0, l.segments["some-key"]._unused_ct)
    l:unuse(one)
    assert.are.equal(1, l.segments["some-key"]._unused_ct)
    assert.are.equal(0, l.segments["some-key"]._in_use_ct)
    local two = l:get("some-key")
    assert.are.equal(one, two)
  end)
end)

