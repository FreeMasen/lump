
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
local Lump = {}
Lump.__index = Lump

local LumpSegment = {}
LumpSegment.__index = LumpSegment

--- Create a new pool
--- @param size_unused_per_key integer The maximum size for each key's segment of the pool
--- @param idle_timeout integer The maximum number of seconds a table can be unused
--- @param ctor fun():any A constructor for creating a new entry into a pool segment
--- @return Pool
function Lump.new(size_unused_per_key, ctor)
  return setmetatable({
    size_unused_per_key = size_unused_per_key,
    ctor = ctor,
    segments = {},
  }, Lump)
end

--- Get a new or unused entry from the segment matching the provided key
--- 
--- Note: If the key is not found a new segment will be created.
--- @param key string The key for this pool segment
--- @return any|nil @The protected table from a segment
--- @return "full"|nil @If the segment has reached its `size_per_key` then the error "full" is returned
function Lump:get(key)
  key = key or ""
  local existing = self.segments[key]
  if not existing then
    existing = LumpSegment.new(self.size_unused_per_key, self.ctor)
    self.segments[key] = existing
  end
  return existing:get_unused()
end

--- Return the table to be unused. This will happen automatically on garbage collection but that isn't very predictable.
--- 
--- note: Use of this method cannot garuntee a reference to t is not
--- in use some where so take care with its use
--- @param key string The key for this pool segment
--- @param t any The value to return to its segment
function Lump:unuse(key, t)
  local existing = self.segments[key]
  if not exiting then
    return nil, "unknown key"
  end
  existing:_demote(t)
end

--- Create a new segment
--- @param max integer The max size for this segment
function LumpSegment.new(max, ctor)
  return setmetatable({
    max = max,
    unused = {},
    ctor = ctor,
    in_use = setmetatable({}, {__mode = "k"}),
    _in_use_ct = 0,
    _unused_ct = 0,
  }, LumpSegment)
end

function LumpSegment:get_unused()
  if self._unused_ct == 0 and self._in_use_ct >= self.max then
    return nil, "full"
  end
  return self:_promote()
end

function LumpSegment:_promote()
  local ret
  if self._unused_ct == 0 then
    local prot = self.ctor()
    local gc = function(gc_able)
      self:_demote(gc_able)
    end
    self._in_use_ct = self._in_use_ct + 1
    ret = Protected.new(prot, gc)
  else
    ret = next(self.unused)
    self._in_use_ct = self._in_use_ct + 1
    self._unused_ct = self._unused_ct - 1
  end
  self.in_use[ret] = true
  self.unused[ret] = nil
  return ret
end

function LumpSegment:_demote(t)
  print("_demote", self._in_use_ct, self._unused_ct)
  if self.in_use[t] then
    print("was in use")
    self.in_use[t] = nil
    self._in_use_ct = self._in_use_ct - 1
  end
  if not self.unused[t] then
    print("was not unused")
    self.unused[t] = true
    self._unused_ct = math.max(0, self._unused_ct + 1)
  end
  print("_demote", self._in_use_ct, self._unused_ct)
end

return Lump

