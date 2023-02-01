string.StartsWith = string.StartsWith or string.StartWith -- 64x has not updated.
--NW3_DebugPrints = true

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

local ReplaceNW = false -- if set to true it will replace the NW System

include("nw/shared/sh_nwcache.lua")
include("nw/server/sv_nw.lua")
include("nw/shared/sh_nw.lua")

AddCSLuaFile("nw/shared/sh_nwcache.lua")
AddCSLuaFile("nw/shared/sh_nw.lua")
AddCSLuaFile("nw/client/cl_nw.lua")

if ReplaceNW then
	include("replacenw/shared/sh_nwcache.lua")
	include("replacenw/shared/sh_nw.lua")

	AddCSLuaFile("replacenw/shared/sh_nwcache.lua")
	AddCSLuaFile("replacenw/shared/sh_nw.lua")
end