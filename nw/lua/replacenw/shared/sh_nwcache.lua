local nw_registry = {}
local types = NW3.Types
local float_str = NW3.Float_Str
local TypeID = TypeID
local sub = string.sub
local isstring = isstring
local isnumber = isnumber
local tonumber = tonumber
local format = string.format
local timer_Simple = timer.Simple
local DebugPrints = NW3.DebugPrints
local meta = FindMetaTable("Entity")
local ent_isvalid = meta.IsValid
local JSONToTable = util.JSONToTable
local StartsWith = string.StartsWith
local GetNW2Entity = meta.GetNW2Entity
local table_identifyer = NW3.Table_Identifyer -- Used when networking tables as strings.
--[[
	This is the NW cache.
	We cache all NW Vars here, so we can access then faster.
	It also allows us to convert some values to the right type right here, instead of doing it in the GetNW3* functions.
]]
hook.Add("EntityNetworkedVarChanged", "NW_Cache", function(ent, name, old, value)
	if !StartsWith(name, "NW_") then return end -- We want to separate the NW3 Vars from the NW vars.
	name = sub(name, 4) -- remove NW_
	local start = DebugPrints and SysTime()
	local vars = nw_registry[ent]
	if !vars then
		vars = {}
	end

	local name_isnumber = tonumber(name)
	if name_isnumber then
		name = name_isnumber
	end

	local var = vars[name]
	if !var then
		var = {
			["type"] = types[TypeID(value)] or ""
		}
	end
	var.type = types[TypeID(value)] or var.type

	--[[
		NW2 can Network nil values so we should make sure that we remove the value if it's set to nil.
		If we wouldn't do this we would create a bug. (https://github.com/Facepunch/garrysmod-issues/issues/3397)
	]]
	if value == nil then
		vars[name] = nil
		nw_registry[ent] = vars
		return
	end

	--[[
		Fixes NW2 returning floats like 3.2999999523163 when the value was 3.3
	]]
	if isnumber(value) then
		value = tonumber(format(float_str, value))
	end

	--[[
		Fixed Entitys being a [NULL Entity] Clientside.
	]]
	local entity = false
	if type == "Entity" and !ent_isvalid(value) then
		entity = true
		timer_Simple(0, function()
			var.value = GetNW2Entity(ent, "NW_" .. name)
			nw_registry[ent] = var
			hook.Run("EntityNWVarChanged", ent, name, old, value)
		end)
	end

	--[[
		Caching networked tables, so we don't need to use JSONToTable on every GetNW3Table call.
	]]
	if isstring(value) then
		local isnwtable = sub(value, 1, 2) == table_identifyer -- Checks if the given string was networked using SetNW3Table
		if isnwtable then
			var.type = "Table"

			local json = sub(value, 3)
			local tbl = JSONToTable(json)
			if tbl then -- util.JSONToTable will return nil if the JSON string is invalid.
				value = tbl
			else
				print("[NW Cache] Failed to read Table!. Entity: " .. (ent:IsPlayer() and ent:Name() or ent:GetClass()) .. " Var: " .. name)
			end
		end
	end

	--[[
		Fixes NW2 32Bit int limit by networking values over the limit as a String.
	]]
	local number = tonumber(value)
	if number then
		var.type = "Int"
		value = number
	end

	var.value = value
	vars[name] = var

	nw_registry[ent] = vars
	if !entity then -- Entitys will be nil until the next tick.
		hook.Run("EntityNWVarChanged", ent, name, old, value)
	end

	if DebugPrints then
		print("[NW Cache] Updating " .. name .. " on " .. (ent:IsPlayer() and ent:Name() or ent:GetClass()), value, SysTime() - start + 1)
	end
end)

--[[
	Creating all GetNW3 functions.
	We create them here because the nw2 cache is here.
]]
local Replace = string.Replace
local StartsWith = string.StartsWith
for k, v in pairs(meta) do
	if !StartsWith(k, "GetNW2") or k == "GetNW2VarProxy" or k == "GetNW2VarTable" then continue end

	local type = Replace(k, "GetNW2", "")
	meta["GetNW" .. type] = function(self, name, fallback)
		local reg = nw_registry[self]
		if !reg then return fallback end

		local var = reg[name]
		if !var or var.type != type then return fallback end

		return var.value
	end
end

--[[
	Default fallback should be [NULL Entity]
]]
local fallback_entity = Entity(-1)
local entity = "Entity"
function meta:GetNWEntity(name, fallback)
	fallback = fallback or fallback_entity
	local reg = nw_registry[self]
	if !reg then return fallback end

	local var = reg[name]
	if !var or var.type != entity then return fallback end

	return var.value
end

--[[
	Default fallback should be ""
]]
local fallback_string = ""
local string_ = "String"
function meta:GetNWString(name, fallback)
	fallback = fallback or fallback_string
	local reg = nw_registry[self]
	if !reg then return fallback end

	local var = reg[name]
	if !var or var.type != string_ then return fallback end

	return var.value
end

--[[
	Default fallback should be Angle(0, 0, 0)
]]
local fallback_angle = Angle(0, 0, 0)
local angle = "Angle"
function meta:GetNWAngle(name, fallback)
	fallback = fallback or fallback_angle
	local reg = nw_registry[self]
	if !reg then return fallback end

	local var = reg[name]
	if !var or var.type != angle then return fallback end

	return var.value
end

--[[
	Default fallback should be Vector(0, 0, 0)
]]
local fallback_vector = Vector(0, 0, 0)
local vector = "Vector"
function meta:GetNWVector(name, fallback)
	fallback = fallback or fallback_vector
	local reg = nw_registry[self]
	if !reg then return fallback end

	local var = reg[name]
	if !var or var.type != vector then return fallback end

	return var.value
end

--[[
	Default fallback should be 0
]]
local int = "Int"
function meta:GetNWInt(name, fallback)
	fallback = fallback or 0
	local reg = nw_registry[self]
	if !reg then return fallback end

	local var = reg[name]
	if !var or var.type != int then return fallback end

	return var.value
end

--[[
	GetNW3Float should be able to return Ints so we need to whitelist them.
]]
local whiteslist_float = {
	["Float"] = true,
	["Int"] = true
}
local float = "Float"
function meta:GetNWFloat(name, fallback)
	fallback = fallback or 0
	local reg = nw_registry[self]
	if !reg then return fallback end

	local var = reg[name]
	if !var or (var.type != float and !whiteslist_float[var.type]) then return fallback end

	return var.value
end

local tbl = "Table"
function meta:GetNWTable(name, fallback)
	local reg = nw_registry[self]
	if !reg then return fallback end

	local var = reg[name]
	if !var or var.type != tbl then return fallback end

	return var.value
end

--[[
	GetNW3Var will be the same in code, only without the type check.
]]
function meta:GetNWVar(name, fallback)
	local reg = nw_registry[self]
	if !reg then return fallback end

	local var = reg[name]
	if !var then return fallback end

	return var.value
end

function meta:GetNWVar(name, fallback)
	local reg = nw_registry[self]
	if !reg then return fallback end

	local var = reg[name]
	if !var then return fallback end

	return var.value
end

--[[
	We use our own table where we store all NW Vars.
	Also fixed https://github.com/Facepunch/garrysmod-issues/issues/5396.
]]
function meta:GetNWVarTable()
	return nw_registry[self] or {}
end

--[[
	The function becomes slower if we create a function that internally calls a function and returns a result.
]]
hook.Add("NWLoaded", "NW_Cache", function()
	local ent = nil
	local await_tbl = {}
	hook.Add("InitPostEntity", "NW_EntFix", function()
		ent = Entity(0)

		for k, v in ipairs(await_tbl) do
			v.Func(ent, v.Name, v.Value)
		end
		await_tbl = nil
	end)

	--[[
		Creates all SetGlobal3 functions.
		Doesn't really need to be optimized because it is not intended to be called every tick.
	]]
	local Entity = Entity
	for k, v in pairs(meta) do
		if !StartsWith(k, "SetNW3") then continue end
		local nwfunc = meta["SetNW"..Replace(k, "SetNW3", "")]
		_G["SetGlobal"..Replace(k, "SetNW3", "")] = function(name, value)
			if !ent then
				table.insert(await_tbl, {
					["Name"] = name,
					["Value"] = value,
					["Func"] =  nwfunc
				})
				return
			end

			nwfunc(ent, name, value)
		end
	end

	--[[
		Creates all GetGlobal3 functions.
	]]
	for k, v in pairs(meta) do
		if !StartsWith(k, "GetNW3") then continue end
		local type = Replace(k, "GetNW3", "")
		_G["GetGlobal"..Replace(k, "GetNW3", "")] = function(name, fallback)
			local reg = nw_registry[ent]
			if !reg then return fallback end

			local var = reg[name]
			if !var or var.type != type then return fallback end

			return var.value
		end
	end

	--[[
		Default fallback should be ""
	]]
	local fallback_string = ""
	local string_ = "String"
	function GetGlobalString(name, fallback)
		fallback = fallback or fallback_string
		local reg = nw_registry[ent]
		if !reg then return fallback end

		local var = reg[name]
		if !var or var.type != string_ then return fallback end

		return var.value
	end

	--[[
		Default fallback should be [NULL Entity]
	]]
	local fallback_entity = Entity(-1)
	local entity = "Entity"
	function GetGlobalEntity(name, fallback)
		fallback = fallback or fallback_entity
		local reg = nw_registry[ent]
		if !reg then return fallback end

		local var = reg[name]
		if !var or var.type != entity then return fallback end

		return var.value
	end

	--[[
		Default fallback should be Angle(0, 0, 0)
	]]
	local fallback_angle = Angle(0, 0, 0)
	local angle = "Angle"
	function GetGlobalAngle(name, fallback)
		fallback = fallback or fallback_angle
		local reg = nw_registry[ent]
		if !reg then return fallback end

		local var = reg[name]
		if !var or var.type != angle then return fallback end

		return var.value
	end

	--[[
		Default fallback should be Vector(0, 0, 0)
	]]
	local fallback_vector = Vector(0, 0, 0)
	local vector = "Vector"
	function GetGlobalVector(name, fallback)
		fallback = fallback or fallback_vector
		local reg = nw_registry[ent]
		if !reg then return fallback end

		local var = reg[name]
		if !var or var.type != vector then return fallback end

		return var.value
	end

	--[[
		Default fallback should be 0
	]]
	local int = "Int"
	function GetGlobalInt(name, fallback)
		fallback = fallback or 0
		local reg = nw_registry[ent]
		if !reg then return fallback end

		local var = reg[name]
		if !var or var.type != int then return fallback end

		return var.value
	end

	--[[
		GetNW3Float should be able to return Ints so we need to whitelist them.
	]]
	local whiteslist_float = {
		["Float"] = true,
		["Int"] = true
	}
	local float = "Float"
	function GetGlobalFloat(name, fallback)
		fallback = fallback or 0
		local reg = nw_registry[ent]
		if !reg then return fallback end

		local var = reg[name]
		if !var or (var.type != float and !whiteslist_float[var.type]) then return fallback end

		return var.value
	end

	local tbl = "Table"
	function GetGlobalTable(name, fallback)
		local reg = nw_registry[ent]
		if !reg then return fallback end

		local var = reg[name]
		if !var or var.type != tbl then return fallback end

		return var.value
	end

	--[[
		GetNW3Var will be the same in code, only without the type check.
	]]
	function GetGlobalVar(name, fallback)
		local reg = nw_registry[ent]
		if !reg then return fallback end

		local var = reg[name]
		if !var then return fallback end

		return var.value
	end
end)