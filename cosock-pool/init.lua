
--- @class Protected
--- A table protected from garbage collection by the Pool
local Protected = {}
Protected.__index = function(self, k)
    return self._inner[k]
end
Protected.__newindex = function(self, k, v)
    self._inner[k] = v
end
Protected.__gc = function(self)
    if type(self._on_gc) == "function" then
        self:_on_gc()
    end
end

--- Protect the provided table by calling the `on_gc` function argument before
--- exiting the __gc metamethod
--- @param inner table The table to protect from GC
--- @param on_gc fun(table) The function that protects this table
function Protected.new(inner, on_gc)
    return setmetatable({
        _inner = inner,
        _on_gc = on_gc,
    }, Protected)
end

--- A pool of tables that will be protected from garbage collection
--- when not in use elsewhere
local Pool = {}
Pool.__index = Pool

local PoolSegmet = {}
PoolSegmet.__index = PoolSegmet

--- Create a new pool
--- @param size_unused_per_key integer The maximum size for each key's segment of the pool
--- @param idle_timeout integer The maximum number of seconds a table can be unused
--- @param ctor fun():any A constructor for creating a new entry into a pool segment
--- @return Pool
function Pool.new(size_unused_per_key, idle_timeout, ctor)
    return setmetatable({
        size_unused_per_key = size_unused_per_key,
        ctor = ctor,
        segments = {},
        idle_timeout = idle_timeout,
    }, Pool)
end

--- Get a new or unused entry from the segment matching the provided key
--- 
--- Note: If the key is not found a new segment will be created.
--- @param key string The key for this pool segment
--- @return any|nil @The protected table from a segment
--- @return "full"|nil @If the segment has reached its `size_per_key` then the error "full" is returned
function Pool:get(key)
    local existing = self.segments[key]
    if not existing then
        existing = PoolSegmet.new(self.size_unused_per_key, {}, self.ctor)
        self.segments[key] = existing
    end
    return existing:get_unused()
end

--- Create a new pool segment
--- @param max integer The max size for this segment
function PoolSegmet.new(max, unused, ctor)
    unused = unused or {}
    return setmetatable({
        max = max,
        unused = unused,
        ctor = ctor,
        in_use = setmetatable({}, {__mode = "k"})
    }, PoolSegmet)
end

function PoolSegmet:get_unused()
    if #self.unused == 0 and self:len_in_use() >= self.max then
        return nil, "full"
    end
    local ret
    if #self.unused == 0 then
        ret = Protected.new(self.ctor(),function(gc_able)
            self.in_use[gc_able] = nil
            table.insert(self.unused, gc_able)
        end)
    else
        ret = table.remove(self.unused, 1)
    end
    self.in_use[ret] = true
    return ret
end

function PoolSegmet:len_in_use()
    local ret = 0
    for _,_ in pairs(self.in_use) do
        ret = ret + 1
    end
    return ret
end
local ct = 0
local pool = Pool.new(5, 5, function()
    local id = ct
    ct = ct + 1
    return setmetatable({}, {
        __tostring = function()
            return string.format("thing {%s}", id)
        end
    })
end)
local function do_and_drop()
    for i=1,6 do
        local thing, err = pool:get("some-key")
        print(thing, err)
    end
end
do_and_drop()
collectgarbage("collect")
do_and_drop()
