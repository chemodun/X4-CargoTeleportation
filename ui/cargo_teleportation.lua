-- Cargo Teleportation - sets the engine's salvage flag on a trade deal, which lets two
-- objects in the same zone trade without docking, parking or drones.
--
-- No API sets the flag on a normal ware, so the deal is reached through the engine's own
-- trade id lookup and the flag word written in memory. Both are found once per game build
-- in CreateTradeOrder, from the code that sets the flag. Design and evidence:
-- claude/mod-cargo_teleportation.md.

---@diagnostic disable-next-line: unresolved-require
local ffi = require("ffi")
local bit = require("bit")
local C = ffi.C

local P = ffi.typeof("uint8_t*")

local cargoTeleportation = {
  configBlackboard = "$CargoTeleportationConfig",
  answerBlackboard = "$CargoTeleportationFlagged",
  engineBlackboard = "$CargoTeleportationEngine",
  debugLevel = "none",
  engine = nil,
  reason = "not searched",
}

-- bumped when the record's meaning changes: older records are searched again
local RECORD_VERSION = 1
local ANCHOR = "CreateTradeOrder(): Trade ID 0x%llx does not exist"
-- a flag word at or above this bit belongs to a deal the engine has already started
local STARTED_BITS = 0x200000

local function write(message, ...)
  if select("#", ...) > 0 then
    message = string.format(message, ...)
  end
  DebugError("CargoTeleportation: " .. message)
end

function cargoTeleportation.Error(message, ...) write(message, ...) end
function cargoTeleportation.Debug(message, ...) if cargoTeleportation.debugLevel ~= "none" then write(message, ...) end end
function cargoTeleportation.Trace(message, ...) if cargoTeleportation.debugLevel == "trace" then write(message, ...) end end

local function playerId() return ConvertStringTo64Bit(tostring(C.GetPlayerID())) end

function cargoTeleportation.ReadConfig()
  if playerId() == 0 then return end
  local config = GetNPCBlackboard(playerId(), cargoTeleportation.configBlackboard)
  if type(config) == "table" and config.debugLevel then
    cargoTeleportation.debugLevel = tostring(config.debugLevel)
  end
end

local function u16(p) return ffi.cast("uint16_t*", p)[0] end
local function u32(p) return ffi.cast("uint32_t*", p)[0] end
local function i32(p) return ffi.cast("int32_t*", p)[0] end
local function hex(n) return string.format("0x%x", tonumber(n)) end

-- false in bytes matches any byte
local function match(p, bytes)
  for k = 1, #bytes do
    if bytes[k] and p[k - 1] ~= bytes[k] then return false end
  end
  return true
end

-- The exe image and its sections as RVA ranges: to = the file-backed part (searched),
-- vto = the whole section (zeroed tail included, where globals live).
local function mapImage()
  -- the walk below the image would read unmapped memory in the native Linux build
  if ffi.os ~= "Windows" then return nil, "not the Windows build" end
  local a = ffi.cast("uintptr_t", C.GetPlayerID)
  a = a - a % 0x10000
  local base
  for _ = 1, 4096 do
    local p = ffi.cast(P, a)
    if p[0] == 0x4d and p[1] == 0x5a and u32(p + i32(p + 0x3c)) == 0x4550 then
      base = p
      break
    end
    a = a - 0x10000
  end
  if not base then return nil, "image base not found" end
  local pe = base + i32(base + 0x3c)
  local opt = pe + 24
  local img = { base = base, sec = {} }
  -- timestamp, checksum, image size: what a cached result is tied to
  img.id = string.format("%x-%x-%x", u32(pe + 8), u32(opt + 64), u32(opt + 56))
  -- exception directory: every function's start and end, sorted
  img.pdata, img.pdataCount = u32(opt + 112 + 3 * 8), math.floor(u32(opt + 112 + 3 * 8 + 4) / 12)
  local s = opt + u16(pe + 20)
  for i = 0, u16(pe + 6) - 1 do
    local h = s + i * 40
    local n = {}
    for k = 0, 7 do
      if h[k] ~= 0 then n[#n + 1] = string.char(h[k]) end
    end
    local from, vsize, raw = u32(h + 12), u32(h + 8), u32(h + 16)
    img.sec[table.concat(n)] = { from = from, to = from + math.min(vsize, raw), vto = from + vsize }
  end
  if not (img.sec[".text"] and img.sec[".rdata"] and img.sec[".data"]) then
    return nil, "image sections missing"
  end
  if img.pdataCount == 0 then return nil, "no exception directory" end
  return img
end

local function inSection(sec, rva, len)
  return rva >= sec.from and rva + (len or 8) <= sec.to
end

local function cStringAt(img, sec, rva, s)
  if not inSection(sec, rva, #s + 1) then return false end
  for k = 1, #s do
    if img.base[rva + k - 1] ~= string.byte(s, k) then return false end
  end
  return img.base[rva + #s] == 0
end

-- The function containing rva, from .pdata: begin, end or nil.
local function functionOf(img, rva)
  local lo, hi = 0, img.pdataCount - 1
  while lo <= hi do
    local mid = math.floor((lo + hi) / 2)
    local entry = img.base + img.pdata + mid * 12
    local from, to = u32(entry), u32(entry + 4)
    if rva < from then
      hi = mid - 1
    elseif rva >= to then
      lo = mid + 1
    else
      return from, to
    end
  end
end

-- bts eax,0x11; mov [rdi|rsi+disp8],eax: the salvage parameter written into the new deal
local SETTER = { 0x0f, 0xba, 0xe8, false, 0x89, false, false }

local function setterAt(img, o)
  local b = img.base
  if not inSection(img.sec[".text"], o, #SETTER) or not match(b + o, SETTER) then return nil end
  if b[o + 5] ~= 0x46 and b[o + 5] ~= 0x47 then return nil end
  return b[o + 3], b[o + 6]
end

-- test rdx,rdx; je fail; mov r8d,2; mov rcx,[rip+registry]; call lookup; mov r15,rax
local LOOKUP = { 0x48, 0x85, 0xd2, 0x0f, 0x84, false, false, false, false, 0x41, 0xb8, 0x02, 0, 0, 0,
  0x48, 0x8b, 0x0d, false, false, false, false, 0xe8, false, false, false, false, 0x4c, 0x8b, 0xf8 }

-- registry and lookup RVAs when o is the lookup site of CreateTradeOrder
local function lookupAt(img, o)
  local b = img.base
  if not inSection(img.sec[".text"], o, #LOOKUP) or not match(b + o, LOOKUP) then return nil end
  local fail = o + 9 + i32(b + o + 5)
  if not (inSection(img.sec[".text"], fail, 7) and match(b + fail, { 0x48, 0x8d, 0x0d })) then return nil end
  if not cStringAt(img, img.sec[".rdata"], fail + 7 + i32(b + fail + 3), ANCHOR) then return nil end
  local registry = o + 22 + i32(b + o + 18)
  local data = img.sec[".data"]
  if registry < data.from or registry + 8 > data.vto then return nil end
  local lookup = o + 27 + i32(b + o + 23)
  if functionOf(img, lookup) ~= lookup then return nil end
  return registry, lookup
end

-- A setter hit inside CreateTradeOrder: the record, or nil.
local function candidate(img, h, build)
  local bitIndex, offset = setterAt(img, h)
  if not bitIndex then return nil end
  local from, to = functionOf(img, h)
  if not from then return nil end
  local loaded = false
  for k = math.max(from, h - 0x60), h - 4 do
    if match(img.base + k, { 0x41, 0x8b, 0x47, offset }) then loaded = true break end
  end
  if not loaded then return nil end
  for o = from, to - #LOOKUP do
    if img.base[o] == 0x48 and img.base[o + 1] == 0x85 then
      local registry, lookup = lookupAt(img, o)
      if registry then
        return { build = build, found = true, setter = h, site = o, registry = registry, lookup = lookup, offset = offset, bit = bitIndex }
      end
    end
  end
end

-- ffi.string with a length is meant to copy NULs too; checked on the DOS header, which holds them.
local function copiesWholeBlocks(img)
  local ok, s = pcall(ffi.string, img.base, 0x40)
  return ok and #s == 0x40
end

-- Setter hits in .text: at C speed through string.find when blocks copy whole, else byte by byte.
local function setterHits(img)
  local tx, b = img.sec[".text"], img.base
  local hits = {}
  if copiesWholeBlocks(img) then
    local chunk, overlap = 0x100000, 8
    local from = tx.from
    while from < tx.to do
      local len = math.min(chunk + overlap, tx.to - from)
      local s = ffi.string(b + from, len)
      local at = 1
      while true do
        local i = string.find(s, "\15\186\232\17\137[FG]T", at)
        if not i then break end
        local o = from + i - 1
        if i <= chunk and setterAt(img, o) then hits[#hits + 1] = o end
        at = i + 1
      end
      from = from + chunk
    end
    return hits, "block"
  end
  for o = tx.from, tx.to - #SETTER do
    if b[o] == 0x0f and b[o + 1] == 0xba and b[o + 2] == 0xe8 and b[o + 3] == 0x11 and setterAt(img, o) then
      hits[#hits + 1] = o
      -- unique in every known build; stop at the first so the byte walk ends early
      return hits, "bytes"
    end
  end
  return hits, "bytes"
end

local function search(img, build)
  local hits, mode = setterHits(img)
  cargoTeleportation.Debug("search (%s): %d salvage setter candidates", mode, #hits)
  local record
  for _, h in ipairs(hits) do
    local c = candidate(img, h, build)
    if c then
      if record then return { build = build, found = false, reason = "more than one CreateTradeOrder candidate" } end
      record = c
    end
  end
  return record or { build = build, found = false, reason = "CreateTradeOrder not found" }
end

local function verifyCached(img, c)
  local bitIndex, offset = setterAt(img, c.setter)
  if bitIndex ~= c.bit or offset ~= c.offset then return false end
  local registry, lookup = lookupAt(img, c.site)
  return registry == c.registry and lookup == c.lookup
end

local function store(record)
  if record then record.v = RECORD_VERSION end
  ---@diagnostic disable-next-line: global-in-non-module
  __CARGO_TELEPORTATION_ENGINE = record
  local saved, err = pcall(function() C.SaveUIUserData() end)
  if not saved then cargoTeleportation.Error("SaveUIUserData failed: %s", tostring(err)) end
end

local function use(img, c)
  cargoTeleportation.engine = {
    registry = ffi.cast("void**", img.base + c.registry),
    lookup = ffi.cast("void* (*)(void*, uint64_t, int)", img.base + c.lookup),
    offset = c.offset,
    mask = bit.lshift(1, c.bit),
  }
end

-- At Lua init. A build with a cached record costs a few reads; a new build is searched once.
function cargoTeleportation.Detect()
  cargoTeleportation.engine = nil
  local build
  local ok, result = pcall(function()
    local img, why = mapImage()
    if not img then return why end
    build = GetVersionString() .. " " .. img.id
    local c = __CARGO_TELEPORTATION_ENGINE
    if type(c) ~= "table" or c.build ~= build or c.v ~= RECORD_VERSION then c = nil end
    if c and not c.found then return "cached: " .. tostring(c.reason) end
    -- a crash while reading leaves this record behind, so the build is not read again
    store({ build = build, found = false, reason = "the game stopped while the engine was searched" })
    if not (c and verifyCached(img, c)) then
      c = search(img, build)
    end
    store(c)
    if not c.found then return "searched: " .. tostring(c.reason) end
    use(img, c)
    return string.format("%s: CreateTradeOrder lookup at %s, flag word +%s bit %d", build, hex(c.site), hex(c.offset), c.bit)
  end)
  cargoTeleportation.reason = ok and tostring(result) or ("error: " .. tostring(result))
  if not ok and build then
    store({ build = build, found = false, reason = cargoTeleportation.reason })
  end
  if not cargoTeleportation.engine then
    cargoTeleportation.Error("cargo teleportation unavailable: %s", cargoTeleportation.reason)
  end
end

local TRADE_ORDERS = { TradePerform = true, TradeExchange = true, CargoTeleportationReach = true }

-- The deal of the ship's running trade order, as the 64-bit trade id, or nil and a reason.
local function runningDeal(ship)
  local order = ffi.new("Order[1]")
  if C.GetOrders(order, 1, ship) < 1 then return nil, "no order" end
  local def = ffi.string(order[0].orderdef)
  if not TRADE_ORDERS[def] then return nil, "running order is " .. def end
  local params = GetOrderParams(ship, 1)
  local deal = type(params) == "table" and params[1] and params[1].value
  if not deal or not IsValidTrade(deal) then return nil, "no valid trade in " .. def end
  return ConvertStringTo64Bit(tostring(deal)), def
end

-- Returns nil on success, else the reason.
local function flag(ship)
  local engine = cargoTeleportation.engine
  if not engine then return "engine not located: " .. cargoTeleportation.reason end
  if GetComponentData(ship, "owner") ~= "player" then return "not a player ship" end
  local deal, def = runningDeal(ship)
  if not deal then return def end
  local registry = engine.registry[0]
  if registry == nil then return "trade registry empty" end
  local p = engine.lookup(registry, deal, 2)
  if p == nil then return "deal " .. hex(deal) .. " not found" end
  local word = ffi.cast("uint32_t*", ffi.cast(P, p) + engine.offset)
  local before = word[0]
  if before >= STARTED_BITS then return string.format("deal %s already started, flags %s", hex(deal), hex(before)) end
  word[0] = bit.bor(before, engine.mask)
  cargoTeleportation.Trace("%s deal %s flags %s -> %s", def, hex(deal), hex(before), hex(word[0]))
  return nil
end

-- Raised by the patched order scripts with the ship; the answer goes to the pilot's
-- blackboard: 1 = flagged, -1 = refused (a false value would read back as 0).
function cargoTeleportation.OnFlag(_, param)
  local ship = ConvertStringTo64Bit(tostring(param))
  local reason
  local ok, raised = pcall(function() reason = flag(ship) end)
  if not ok then reason = "error: " .. tostring(raised) end
  local pilot = GetComponentData(ship, "assignedpilot")
  if pilot then
    SetNPCBlackboard(ConvertStringTo64Bit(tostring(pilot)), cargoTeleportation.answerBlackboard, reason and -1 or 1)
  end
  if reason then
    cargoTeleportation.Debug("%s not flagged: %s", tostring(GetComponentData(ship, "name")), reason)
  else
    cargoTeleportation.Debug("%s deal flagged", tostring(GetComponentData(ship, "name")))
  end
end

-- Production seconds of the items: each ware's production time per unit, summed.
local function restockSeconds(items)
  local total = 0
  for _, item in ipairs(items) do
    local macro, amount = tostring(item[1]), tonumber(item[2]) or 0
    local ware = GetMacroData(macro, "ware")
    if not ware or ware == "" then return nil, "no ware for " .. macro end
    local time, perRun = GetWareData(ware, "productiontime", "productionamount")
    if not time or not perRun or perRun <= 0 then return nil, "no production data for " .. ware end
    total = total + time / perRun * amount
  end
  return total
end

-- Raised by the Restock order with the ship; the pilot's blackboard holds the query
-- [supplier, [[macro, amount, isunit], ...]] and gets the answer in seconds, -1 when unknown.
function cargoTeleportation.OnRestockTime(_, param)
  local ship = ConvertStringTo64Bit(tostring(param))
  local pilot = GetComponentData(ship, "assignedpilot")
  if not pilot then return end
  pilot = ConvertStringTo64Bit(tostring(pilot))
  local seconds, reason
  local ok, raised = pcall(function()
    local query = GetNPCBlackboard(pilot, "$CargoTeleportationRestockQuery")
    if type(query) ~= "table" or type(query[2]) ~= "table" then
      reason = "no query"
      return
    end
    seconds, reason = restockSeconds(query[2])
  end)
  if not ok then reason = "error: " .. tostring(raised) end
  SetNPCBlackboard(pilot, "$CargoTeleportationRestockTime", seconds or -1)
  if seconds then
    cargoTeleportation.Trace("%s restock build time %.0f s", tostring(GetComponentData(ship, "name")), seconds)
  else
    cargoTeleportation.Debug("%s restock build time unknown: %s", tostring(GetComponentData(ship, "name")), tostring(reason))
  end
end

local function init()
  RegisterEvent("CargoTeleportation.Flag", cargoTeleportation.OnFlag)
  RegisterEvent("CargoTeleportation.RestockTime", cargoTeleportation.OnRestockTime)
  RegisterEvent("CargoTeleportation.ConfigChanged", cargoTeleportation.ReadConfig)
  cargoTeleportation.ReadConfig()
  cargoTeleportation.Detect()
  -- the order scripts commit a ship-to-ship exchange only when this is 1; saved with the player
  SetNPCBlackboard(playerId(), cargoTeleportation.engineBlackboard, cargoTeleportation.engine and 1 or 0)
  cargoTeleportation.Debug("engine flag %d: %s", cargoTeleportation.engine and 1 or 0, cargoTeleportation.reason)
end

-- runs on game start, load and /reloadui, once the player exists
Register_OnLoad_Init(init)
