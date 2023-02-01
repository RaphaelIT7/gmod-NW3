local meta = FindMetaTable("Entity")

function meta:SetNetworked3VarProxy(name, func)
	if !self.NW3VarProxies then
		self.NW3VarProxies = {}
	end

	self.NW3VarProxies[name] = func
end

local isfunction = isfunction
function meta:GetNetworked3VarProxy(name)
	if self.NW3VarProxies then
		local func = self.NW3VarProxies[name]
		if isfunction(func) then
			return func
		end
	end

	return nil
end

meta.SetNW3VarProxy = meta.SetNetworked3VarProxy
meta.GetNW3VarProxy = meta.GetNetworked3VarProxy

hook.Add("EntityNW3VarChanged", "NW3Vars", function(ent, name, oldValue, newValue)
	if ent.NW3VarProxies then
		local func = ent.NW3VarProxies[name]

		if isfunction(func) then
			func(ent, name, oldValue, newValue)
		end
	end
end)

hook.Run("NW3_Loaded")