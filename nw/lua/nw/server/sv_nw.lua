local nw3_antipvs = {}
local nw3_updating = {}
local meta = FindMetaTable("Entity")

local ipairs = ipairs
local IsValid = IsValid
local GetPos = meta.GetPos
local insert = table.insert
local TestPVS = meta.TestPVS
local DebugPrints = NW3_DebugPrints
local StartsWith = string.StartsWith
local AddOriginToPVS = AddOriginToPVS
--[[
	Workaround for the PVS.
]]
hook.Add("SetupPlayerVisibility", "NW3_AntiPVS", function(ply)
	local tbl = nw3_updating[ply] or {}
	if #tbl == 0 then return end

	if DebugPrints then
		print("Updating player: " .. ply:Nick())
	end

	for k, v in ipairs(tbl) do
		local pos = IsValid(v) and GetPos(v) or nil

		--[[
			We're using TestPVS because else we would create engine crashes.
			When you use AddOriginToPVS at an already loaded PVS, it will result in a crash.
			GMOD Issue: https://github.com/Facepunch/garrysmod-issues/issues/3744 
		]]
		if !pos or TestPVS(v, pos) then continue end
		AddOriginToPVS(pos)
	end

	nw3_updating[ply] = {}
end)

local player_GetAll = player.GetAll
hook.Add("EntityNetworkedVarChanged", "NW3_AntiPVS", function(ent, name)
	if !nw3_antipvs[name] then return end

	if DebugPrints then
		print("Updating entity " .. ent:GetClass() .. " " .. (ent:IsPlayer() and ent:Nick() or ""))
	end

	for _, ply in ipairs(player_GetAll()) do
		if !nw3_updating[ply] then
			nw3_updating[ply] = {}
		end

		insert(nw3_updating[ply], ent)
	end
end)

--[[
	Creates all SetNW functions.
]]
local Replace = string.Replace
for k, v in pairs(meta) do
	if !StartsWith(k, "SetNW2") then continue end
	meta["SetNW3"..Replace(k, "SetNW2", "")] = function(self, name, value, pvs)
		pvs = pvs or false
		if !pvs then
			nw3_antipvs[name] = true
		elseif nw3_antipvs[name] then
			nw3_antipvs[name] = nil
		end

		v(self, name, value)
	end
end

--[[
	Fixing 32 bit limit of SetNW2Int
]]
local Round = math.Round
local tostring = tostring
local SetNW2Int = meta.SetNWInt
local SetNW2String = meta.SetNW2String
function meta:SetNW3Int(name, value, pvs)
	pvs = pvs or false
	if !pvs then
		nw3_antipvs[name] = true
	elseif nw3_antipvs[name] then
		nw3_antipvs[name] = nil
	end

	value = Round(value)
	if value > 0x7FFFFFFF or value < 0x80000000 then -- 32 bit Int limits
		SetNW2String(self, name, tostring(value))
		return
	end

	SetNW2Int(self, name, value)
end

local len = string.len
local assert = assert
local istable = istable
local TableToJSON = util.TableToJSON
local table_identifyer = string.char(10) .. string.char(10)
local SetNW3String = meta.SetNW3String
function meta:SetNW3Table(name, tbl, pvs)
	pvs = pvs or false
	if !pvs then
		nw3_antipvs[name] = true
	elseif nw3_antipvs[name] then
		nw3_antipvs[name] = nil
	end

	assert(istable(tbl), "[NW3] You're using SetNW3Table without passing a proper table!")

	local json = TableToJSON(tbl)
	assert(len(json) < 509, "[NW3] trying to network a table that is longer than 509 characters.")

	SetNW3String(self, name, table_identifyer .. json)
end

local istable = istable
local isnumber = isnumber
local SetNW2Var = meta.SetNW2Var
local SetNW3Int = meta.SetNW3Int
local SetNW3Table = meta.SetNW3Table
function meta:SetNW3Var(name, value, pvs)
	pvs = pvs or false
	if !pvs then
		nw3_antipvs[name] = true
	elseif nw3_antipvs[name] then
		nw3_antipvs[name] = nil
	end

	if istable(value) then
		SetNW3Table(self, name, value, pvs)
		return
	end

	if isnumber(value) then
		SetNW3Int(self, name, value, pvs)
		return
	end

	SetNW2Var(self, name, value)
end