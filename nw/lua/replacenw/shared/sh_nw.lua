--[[
	Replaces all SetNW functions.
]]
local meta = FindMetaTable("Entity")
local StartsWith = string.StartsWith
local Replace = string.Replace
local sub = string.sub
for k, v in pairs(meta) do
	if !StartsWith(k, "SetNW3") then continue end
	meta["SetNW"..Replace(k, "SetNW3", "")] = function(self, name, value)
		if sub(name, 1, 3) != "NW_" then
			name = "NW_" .. name
		end

		v(self, name, value)
	end
end

function meta:SetNetworkedVarProxy(name, func)
	if !self.NNWVarProxies then
		self.NNWVarProxies = {}
	end

	self.NNWVarProxies[name] = func
end

local isfunction = isfunction
function meta:GetNetworkedVarProxy(name)
	if self.NNWVarProxies then
		local func = self.NNWVarProxies[name]
		if isfunction(func) then
			return func
		end
	end

	return nil
end

meta.SetNWVarProxy = meta.SetNetworkedVarProxy
meta.GetNWVarProxy = meta.GetNetworkedVarProxy

hook.Add("EntityNWVarChanged", "NWVars", function(ent, name, oldValue, newValue)
	if ent.NNWVarProxies then
		local func = ent.NNWVarProxies[name]

		if isfunction(func) then
			func(ent, name, oldValue, newValue)
		end
	end
end)

hook.Run("NWLoaded")