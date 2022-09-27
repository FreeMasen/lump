local Lump = require "lump"

describe("LumpSegment regains space on remove", function()
    it("Lump:get new table after remove", function()
        local key = "some-key"
        local l = Lump.new(1, function() return {} end)
        local ent1 = assert(l:get(key))
        l:remove(key, ent1)
        assert.are.equal(nil, ent1.___lump_guard)
        local ent2 = assert(l:get(key))
        assert.is_not.equal(ent1, ent2)
    end)
end)
