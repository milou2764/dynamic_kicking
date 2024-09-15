if (not ConVarExists("sv_vmanip_kick_damage")) then
	CreateConVar("sv_vmanip_kick_damage", 5, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "The damage points dealt with each kick")
	CreateConVar("sv_vmanip_kick_radius", 36, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "The degree radius of influence in a kick")
	CreateConVar("sv_vmanip_kick_range", 150, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "The maximum distance of a kick in hammer units")
	CreateConVar("sv_vmanip_kick_doors", "true", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Whether or not doors should be able to be bust open by a kick")
end

util.AddNetworkString("request_sv_vmanip_kick_convars")
util.AddNetworkString("send_sv_vmanip_kick_convars")
util.AddNetworkString("update_sv_vmanip_kick_convars")

net.Receive("request_sv_vmanip_kick_convars", function(len, ply)
	if (not ply:IsAdmin()) then return end
	net.Start("send_sv_vmanip_kick_convars")
	net.WriteFloat(GetConVar("sv_vmanip_kick_damage"):GetFloat())
	net.WriteFloat(GetConVar("sv_vmanip_kick_radius"):GetFloat())
	net.WriteFloat(GetConVar("sv_vmanip_kick_range"):GetFloat())
	net.WriteBool(GetConVar("sv_vmanip_kick_doors"):GetBool())
	net.Send(ply)
end )

local varFuncs = {
	["sv_vmanip_kick_damage"] = tonumber,
	["sv_vmanip_kick_radius"] = tonumber,
	["sv_vmanip_kick_range"] = tonumber,
	["sv_vmanip_kick_doors"] = tobool
}
net.Receive("update_sv_vmanip_kick_convars", function(len, ply)
	if (not ply:IsAdmin()) then return end
	local cv = net.ReadString()
	local val = net.ReadString()
	if (varFuncs[cv] ~= nil) then
		local validator = varFuncs[cv]
		local nv = validator(val)
		if (nv ~= nil) then
			if (isnumber(nv)) then
				GetConVar(cv):SetFloat(nv)
			elseif (isbool(nv) and (string.lower(tostring(nv)) == string.lower(val))) then
				GetConVar(cv):SetBool(nv)
			end
		end
	end
end )