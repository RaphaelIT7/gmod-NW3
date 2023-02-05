string.StartsWith = string.StartsWith or string.StartWith -- 64x has not updated.
NW3 = {
	DebugPrints = true,
	ReplaceNW = true,
	Table_Identifyer = string.char(10) .. string.char(10), -- used when networking a table
	Float_Str = '%.3f', -- Used to fix the precision error when networking a float
	//Number_Identifyer = string.char(11) .. string.char(11) -- Used when networking a var which has a number as a key. Currently Unused.
	Types = { -- Used by the NW cache to try to find out the type of the new value
		[TYPE_BOOL] = "Bool",
		[TYPE_NUMBER] = "Int",
		[TYPE_STRING] = "String",
		[TYPE_ENTITY] = "Entity",
		[TYPE_VECTOR] = "Vector",
		[TYPE_ANGLE] = "Angle"
	}
}

if CLIENT then
	local function nw_include(nw_file)
		if !file.Exists(nw_file, "LUA") then return end
		include(nw_file)
	end

	nw_include("nw/shared/sh_nwcache.lua")
	nw_include("nw/client/cl_nw.lua")
	nw_include("nw/shared/sh_nw.lua")

	nw_include("replacenw/shared/sh_nwcache.lua")
	nw_include("replacenw/shared/sh_nw.lua")

	return
end

include("nw/shared/sh_nwcache.lua")
include("nw/server/sv_nw.lua")
include("nw/shared/sh_nw.lua")

AddCSLuaFile("nw/shared/sh_nwcache.lua")
AddCSLuaFile("nw/shared/sh_nw.lua")
AddCSLuaFile("nw/client/cl_nw.lua")

if NW3.ReplaceNW then
	include("replacenw/shared/sh_nwcache.lua")
	include("replacenw/shared/sh_nw.lua")

	AddCSLuaFile("replacenw/shared/sh_nwcache.lua")
	AddCSLuaFile("replacenw/shared/sh_nw.lua")
end