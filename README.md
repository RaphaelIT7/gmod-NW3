# NW3 System
The NW3 System is a combination of the NW and NW2 System.  
It internally uses the NW2 system for networking, but it allows one to decide if you want to use the PVS or not.  
You should not use the NW3 System if you set NW3 vars every tick. It aims to improve the performance of all GetNW3 functions at the cost of the SetNW3 functions.

If you experience engine crashes related to https://github.com/Facepunch/garrysmod-issues/issues/3744 please open an issue [here](https://github.com/RaphaelIT7/gmod-NW3/issues). (should hopefully never happen)

## Performance

#### SetNW3* and SetGlobal3* Performance
They are going to be a bit slower than the equivalent NW2function.
The NW3 Cache uses Internally, the hook [EntityNetworkedVarChanged](https://wiki.facepunch.com/gmod/GM:EntityNetworkedVarChanged) is used to cache every NW3 Var.

#### GetNW3* and GetGlobal3* Performance
2.5-4x better Performance than GetNW2* functions. (Results from test below).
GetNW3Var will be the fastest function. It will return the current value from the nw2 registry(cache table.)

### Performance Test
```lua
if SERVER then
	local nw3 = 0 
	local nw2 = 0
	local nw = 0
	local ent = Entity(1)
	local SysTime = SysTime
	Entity(1):SetNWInt("Test", 10000000) 
	Entity(1):SetNW2Int("Test", 10000000)
	Entity(1):SetNW3Int("Test2", 10000000)  
	for k=1, 10000000 do
		local start = SysTime()
		ent:GetNW3Int("Test", 0)
		local finish = SysTime()  
		nw3 = nw3 + (finish - start)
	end 
 
	for k=1, 10000000 do
		local start = SysTime()
		ent:GetNW2Int("Test2", 0)
		local finish = SysTime()
		nw2 = nw2 + (finish - start)
	end

	for k=1, 10000000 do
		local start = SysTime()
		ent:GetNWInt("Test", 0)
		local finish = SysTime()
		nw = nw + (finish - start)
	end

	print("NW3", nw3)
	print("NW2", nw2)
	print("NW", nw)
end
```
Output (executed 5 times.):
```lua
NW3	0.46445980099816
NW2	1.1991258009039
NW	1.2526921993067

NW3	0.48828999972648
NW2	1.2319813006652
NW	1.2516106997355

NW3	0.44739039998603
NW2	1.2135862994273
NW	1.2454914982427

NW3	0.43265849884483
NW2	1.2111449998883
NW	1.2444628995872

NW3	0.43737039941334
NW2	1.2225386995815
NW	1.3808498018261
```

## Settings
[NW3_DebugPrints](https://github.com/RaphaelIT7/gmod-NW3/blob/ac74a724047d31fa4a8e8bc490b4e27e186bf026/nw/lua/autorun/_sh_nwloader.lua#L2) 
if set to true, it will enable all debug prints.  
[ReplaceNW](https://github.com/RaphaelIT7/gmod-NW3/blob/ac74a724047d31fa4a8e8bc490b4e27e186bf026/nw/lua/autorun/_sh_nwloader.lua#L20) 
if set to true, it will, replace the NW System with the NW3 System.

## Functions
It has all the NW2 functions.
serverside all functions have a third argument. PVS. The PVS is disabled by default.
#### Example
```lua
  Entity(1):SetNW3String("Hello", "World", true) -- uses the PVS.
```

### [Entity:SetNW3Table(key, table, pvs)](https://github.com/RaphaelIT7/gmod-NW3/blob/ac74a724047d31fa4a8e8bc490b4e27e186bf026/nw/lua/nw/server/sv_nw.lua#L104-L118)
### [Entity:GetNW3Table(key, fallback)](https://github.com/RaphaelIT7/gmod-NW3/blob/ac74a724047d31fa4a8e8bc490b4e27e186bf026/nw/lua/nw/shared/sh_nwcache.lua#L221-L229)

### [SetGlobal3Table(key, table)](https://github.com/RaphaelIT7/gmod-NW3/blob/ac74a724047d31fa4a8e8bc490b4e27e186bf026/nw/lua/nw/server/sv_nw.lua#L104-L118) (same as Entity(0):SetNW3Table)
### [GetGlobal3Table(key, fallback)](https://github.com/RaphaelIT7/gmod-NW3/blob/ac74a724047d31fa4a8e8bc490b4e27e186bf026/nw/lua/nw/shared/sh_nwcache.lua#L388-L396)
