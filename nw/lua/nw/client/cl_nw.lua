local StartsWith = string.StartsWith
local meta = FindMetaTable("Entity")
local Replace = string.Replace
local sub = string.sub
for k, v in pairs(meta) do
	if sub(k, 1, 6) != "SetNW2" then continue end
	meta["SetNW3"..Replace(k, "SetNW2", "")] = v
end

--[[
	Fixing the 32 bit limit of SetNW2Int.
]]
local Round = math.Round
local tostring = tostring
local SetNW2Int = meta.SetNW2Int
local SetNW2String = meta.SetNW2String
function meta:SetNW3Int(name, value)
	value = Round(value)
	if value > 0x7FFFFFFF or value < 0x80000000 then -- 32 bit Int limits
		SetNW2String(self, name, tostring(value))
		return
	end

	SetNW2Int(self, name, value)
end

local assert = assert
local len = string.len
local TableToJSON = util.TableToJSON
local SetNW3String = meta.SetNW3String
local table_identifyer = string.char(10) .. string.char(10)
function meta:SetNW3Table(name, tbl)
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
function meta:SetNW3Var(name, value)
	if istable(value) then
		SetNW3Table(self, name, value)
		return
	end

	if isnumber(value) then
		SetNW3Int(self, name, value)
		return
	end

	SetNW2Var(self, name, value)
end