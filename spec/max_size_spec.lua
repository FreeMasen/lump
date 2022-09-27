local Lump = require "lump"

describe("LumpSegment can't exceed max size", function()
    it("Lump:get returns `nil, \"full\"", function()
        local key = "some-key"
        local l = Lump.new(1, function() return {} end)
        local _ = assert(l:get(key))
        local ent, err = l:get(key)
        assert.are.equal(nil, ent)
        assert.are.equal("full", err)
    end)
end)
