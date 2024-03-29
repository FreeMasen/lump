local log = require "log"

--- @class Guard
--- A guard to protect a parent table from garbage collection
--- @field parent table The table to protect from GC
--- @field on_gc fun(table) The function that protects parent from GC
--- @field setment_key string The identifer of the LumpSegment this Guard belongs to
local Guard = {}
Guard.__index = Guard
Guard.__gc = function(self)
  log.trace("Guard.__gc")
  if type(self._on_gc) == "function" then
    self:_on_gc()
  end
end
Guard._mode = "v"

--- @param parent table The table to protect from GC
--- @param on_gc fun(table) The function that protects this table
--- @param segment_key string The identifier of the segment this table is tied to
function Guard.new(parent, on_gc, segment_key)
  log.trace("Guard.new", parent, on_gc)
  local guard = setmetatable({_on_gc = on_gc, parent = parent, segment_key = segment_key}, Guard)
  parent.___lump_guard = guard
end

function Guard:__tostring()
  local suffix = string.format("[%s]", self.segment_key)
  return string.format("Guard(%s)%s", self.parent, suffix)
end

--- @class Lump
--- @field segments {string: LumpSegment} A map of key to segments
--- @field ctor fun():any A constructor for new entries
--- @field size_unused_per_key integer The max entries per segment
--- A lump of entries that will be protected from garbage collection
--- when not in use elsewhere
local Lump = {}
Lump.__index = Lump

--- @class LumpSegment
--- @field max integer Max size of this segment
--- @field unused table The list of unused entries
--- @field ctor fun():any The constructor for each entry
--- @field private _ct integer Current size of in use and unused
local LumpSegment = {}
LumpSegment.__index = LumpSegment

--- Create a new Lump
--- @param size_unused_per_key integer The maximum size for each key's segment
--- @param idle_timeout integer The maximum number of seconds a table can be unused
--- @param ctor fun():any A constructor for creating a new entry into a segment
--- @return Lump
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
--- @param key string The key for this segment
--- @return any|nil @The protected table from a segment
--- @return "full"|nil @If the segment has reached its `size_per_key` then the error "full" is returned
function Lump:get(key)
  log.trace("Lump:get", key)
  key = key or ""
  local existing = self.segments[key]
  if not existing then
    existing = LumpSegment.new(self.size_unused_per_key, self.ctor, key)
    self.segments[key] = existing
  end
  return existing:get_unused()
end

--- Return the table to be unused. This will happen automatically on garbage collection but that
--- isn't very predictable.
--- 
--- note: Use of this method cannot garuntee a reference to t is not
--- in use some where so take care with its use
--- @param key string The key for this segment
--- @param t any The value to return to its segment
function Lump:unuse(t, key)
  key = key or t.___lump_guard.segment_key
  log.trace("unuse", key, t)
  --- @type LumpSegment
  local existing = self.segments[key]
  if not existing  then
    return nil, "unknown key"
  end
  return existing:_demote(t.___lump_guard)
end

--- Remove the table from management by this Lump. This will remove any guards on `t`, prevent
--- `t` from being placed back into `unused`, and make space for new tables to be created
---
--- @param key string The key for this segment
--- @param t any The value to remove from this Lump
function Lump:remove(t, key)
  key = key or t.___lump_guard.segment_key
  log.trace("unuse", key, t)
  t.___lump_guard = nil
  local existing = self.segments[key]
  if not existing then
    log.warn(string.format("segment with key %q not found", key))
    return nil, "unknown key"
  end
  existing._ct = math.max(0, existing._ct - 1)
  return 1
end

--- Create a new segment
--- @param max integer The max size for this segment
--- @param ctor fun():any The constructor to use for new entries
--- @param key string The name of this segment
--- @return LumpSegment
function LumpSegment.new(max, ctor, key)
  return setmetatable({
    max = max,
    unused = {},
    ctor = ctor,
    _ct = 0,
    key = key,
  }, LumpSegment)
end

--- Attempt to get an unused entry from this LumpSegment, returning `nil, "full"` if that cannot
--- be performed
---
--- @return table|nil
--- @return nil|string
function LumpSegment:get_unused()
  log.trace("LumpSegment:get_unused")
  if self._ct >= self.max and #self.unused == 0 then
    log.debug("lump segment is full")
    return nil, "full"
  end
  return self:_promote()
end

function LumpSegment:_promote()
  log.trace("LumpSegment:_promote")
  local ret = table.remove(self.unused, 1)
  if not ret then
    log.trace("unused is empty, creating new")
    ret = self.ctor()
    self._ct = self._ct + 1
  end
  local gc = function(gc_able)
    self:_demote(gc_able)
  end
  local _guard = Guard.new(ret, gc, self.key)
  return ret
end

function LumpSegment:_demote(t)
  log.trace("LumpSegment:_demote", t, t.parent and "with parent" or "no-parent")
  if not t.parent then
    -- If cleanup has already been performed, we want to return early with a success
    -- This may happen when we set `t.parent.___lump_guard = nil` below. 
    return 1
  end
  t.parent.___lump_guard = nil
  table.insert(self.unused, t.parent)
  return 1
end

return Lump
