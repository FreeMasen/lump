local Lump = require "lump"

describe("Lump:remove", function()
    it("Lump:get returns new table after remove", function()
        local key = "some-key"
        local l = Lump.new(1, function() return {} end)
        local ent1 = assert(l:get(key))
        assert(l:remove(ent1))
        assert.are.equal(nil, ent1.___lump_guard)
        local ent2 = assert(l:get(key))
        assert.is_not.equal(ent1, ent2)
    end)
    it("errors with bad key", function()
        local key = "some-key"
        local l = Lump.new(1, function() return {} end)
        local ent1 = assert(l:get(key))
        local success, err = l:remove(ent1, "other-key")
        assert.are.equal(nil, success)
        assert.are.equal("unknown key", err)
    end)
end)
