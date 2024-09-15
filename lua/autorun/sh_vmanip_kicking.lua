local kickCooldown = 0.7

if (SERVER) then

	util.AddNetworkString("vmanip_kick_sendkey")
	util.AddNetworkString("vmanip_kick_request")
	
	local globalInflictor = NULL
	local function DoKick(ply, power)
		if (not globalInflictor:IsValid()) then
			globalInflictor = ents.Create("simple_physics_brush")
			globalInflictor:SetPos(Vector())
			globalInflictor:Spawn()
		end
		local punchPower = math.min(power, 2)
		ply:ViewPunch(AngleRand()*punchPower*0.01)
		ply:EmitSound("Weapon_Crowbar.Single")
		ply:ScheduleActivity(ACT_CROUCH)
		ply:ScheduleActivity(ACT_FLINCH_LEFTLEG, CurTime() + 0.13)
		timer.Simple(0.13, function()
			if (not ply:IsValid()) then return end
			local origin = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_R_Foot"))
			local bulletInfo = {
				Attacker = ply,
				Callback = function(atk, tr, dmg)
					local punch = AngleRand()*punchPower*0.1
					punch.y = punch.y*0.1
					punch.r = punch.r*0.1
					ply:ViewPunch(punch)
				end,
				Damage = 0.1,
				Force = 1,
				Distance = GetConVar("sv_vmanip_kick_range"):GetFloat(),
				Num = 1,
				Tracer = -1,
				Dir = ((ply:GetForward()*0.8) + (ply:GetUp()*0.2)):GetNormalized(),
				Src = origin,
				IgnoreEntity = ply
			}
			ply:FireBullets(bulletInfo)
			local nts = ents.FindInCone(origin - (ply:GetForward()*50), ply:GetForward(), GetConVar("sv_vmanip_kick_range"):GetFloat(), math.cos(GetConVar("sv_vmanip_kick_radius"):GetFloat() * (math.pi/180)))
			local anyHit = false
			local propDoors = {}
			local funcDoors = {}
			for _,v in ipairs(nts) do
				if (v == ply) then continue end
				if (not IsEntity(v)) then continue end
				if (not v:IsValid()) then continue end
				if (v:IsWorld()) then continue end
				if (not GAMEMODE:ShouldCollide(ply, v)) then continue end
				local vec = (v:GetPos()-origin):GetNormalized()*(power*16000)
				local d = DamageInfo()
				d:SetDamage(power*(GetConVar("sv_vmanip_kick_damage"):GetFloat()))
				d:SetAttacker(ply)
				d:SetInflictor(globalInflictor)
				d:SetDamageType(DMG_CLUB)
				d:SetReportedPosition(origin)
				v:TakeDamageInfo(d)
				anyHit = true
				local class = v:GetClass()
				if (class == "prop_door_rotating") then
					table.insert(propDoors, v)
					continue
				elseif (class == "func_door_rotating") then
					table.insert(funcDoors, v)
					continue
				end
				local p = v:GetPhysicsObject()
				if (p:IsValid()) then
					p:ApplyForceOffset(vec, origin)
				else
					v:SetVelocity(v:GetVelocity() + vec)
				end
			end
			if (anyHit) then
				ply:EmitSound("physics/body/body_medium_impact_soft1.wav")
			end
			if (GetConVar("sv_vmanip_kick_doors"):GetBool()) then
				local hasPropDoor = not table.IsEmpty(propDoors)
				local hasFuncDoor = not table.IsEmpty(funcDoors)
				if (hasPropDoor or hasFuncDoor) then
					local doors = propDoors
					local isPropDoor = true
					if (not hasPropDoor) then
						doors = funcDoors
						isPropDoor = false
					end
					local closestDist = doors[1]:GetPos():DistToSqr(origin)
					local closest = doors[1]
					local len = #doors
					if (len > 1) then
						for i=2, len do
							local pd = doors[i]
							local pddist = pd:GetPos():DistToSqr(origin)
							if (pddist < closestDist) then
								closestDist = pddist
								closest = pd
							end
						end
					end
					//
					local kvs = closest:GetKeyValues()
					local speed = kvs['speed']
					closest:Fire('SetSpeed', speed + (speed*6*power), 0)
					if (isPropDoor) then
						closest:Fire('OpenAwayFrom', ply:GetName(), 0, ply)
					else
						local dir = 1
						local pAngles = ply:GetAngles()
						local dAngles = closest:GetAngles()
						if (pAngles.y > (dAngles.y-90) and pAngles.y < (dAngles.y+90)) then
							dir = -1
						end
						local old = kvs['distance']
						closest:SetKeyValue('distance', old*dir)
						closest:Fire('Open', nil, 0, ply)
						closest:SetKeyValue('distance', old)
					end
					closest:Fire('SetSpeed', speed, 0.1)
				end
			end
		end )
	end
	
	local nextKicks = {}
	net.Receive("vmanip_kick_request", function(_,ply)
		if (nextKicks[ply:EntIndex()] ~= nil) then
			if (CurTime() < nextKicks[ply:EntIndex()]) then return end
		end
		nextKicks[ply:EntIndex()] = CurTime() + kickCooldown
		local max = 1
		if (ply:IsAdmin()) then max = 100 end
		local power = math.Clamp(net.ReadFloat() or 1, 0, max)
		DoKick(ply, power)
	end )


elseif (CLIENT) then

	killicon.Add("simple_physics_brush", "HUD/killicons/vmanip_kick", Color( 255, 255, 255 ))

	local function PlayKickAnim(ply)
		if CLIENT and VMLegs then
			VMLegs:PlayAnim("standkick")
		end
	end

	local nextKick = 0
	function RequestKick(key, predicted)
		if (CurTime() < nextKick) then return end

		local bind = -1
		local keyCV = GetConVar("vmanip_kick_bind")
		bind = input.GetKeyCode(keyCV:GetString()) or bind

		local power = 1
		local powerCV = GetConVar("vmanip_kick_power")
		power = powerCV:GetFloat() or power

		if (key == bind) then
			nextKick = CurTime() + kickCooldown
			PlayKickAnim()
			if (not predicted) then
				net.Start("vmanip_kick_request")
				local mult = 1
				if (LocalPlayer():IsAdmin()) then
					if (GetConVar("vmanip_kick_admin"):GetBool()) then
						mult = 100
					end
				end
				net.WriteFloat(math.Clamp(power, 0, 1)*mult)
				net.SendToServer()
			end
		end
	end

	net.Receive("vmanip_kick_sendkey", function()
		RequestKick(net.ReadInt(9), false)
	end )

end

hook.Add("PlayerButtonDown", "CheckKickEvent", function(ply, button)
	if (game.SinglePlayer() and SERVER) then
		net.Start("vmanip_kick_sendkey")
		net.WriteInt(button, 9)
		net.Send(ply)
	elseif (CLIENT and ply == LocalPlayer()) then
		RequestKick(button, not IsFirstTimePredicted())
	end
end )