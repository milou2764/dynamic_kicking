local schedule = {}

if (SERVER) then

	util.AddNetworkString("sched_player_act")

	local meta = FindMetaTable("Player")
	function meta:ScheduleActivity(act, time)
		local sched = {}
		if (schedule[time] ~= nil) then
			sched = schedule[time]
		end
		sched[self:EntIndex()] = act
		time = time or CurTime()
		schedule[time] = sched
		net.Start("sched_player_act")
		net.WriteEntity(self)
		net.WriteFloat(time)
		net.WriteInt(act, 12)
		net.Broadcast()
	end
	
elseif (CLIENT) then
	
	net.Receive("sched_player_act", function()
		local player = net.ReadEntity()
		local time = net.ReadFloat()
		local act = net.ReadInt(12)
		local sched = {}
		if (schedule[time] ~= nil) then
			sched = schedule[time]
		end
		sched[player:EntIndex()] = act
		schedule[time] = sched
	end )

end

hook.Add("CalcMainActivity", "sched_player_act", function(ply, vel)
	local ind = ply:EntIndex()
	for t,v in pairs(schedule) do
		if (t < CurTime()) then
            local act = v[ind]
			if (act ~= nil) then
				table.remove(v, ind)
				if (table.IsEmpty(v)) then
					table.remove(schedule, t)
				else
					schedule[t] = v
				end
				local to = ply:SequenceDuration( ply:SelectWeightedSequence(act) )
				return act
			end
		end
	end
end )

hook.Add("Tick", "manage_player_act_schedule_expiry", function()
	for t,v in pairs(schedule) do
		if (t < (CurTime()-3)) then
			table.remove(schedule, t)
		end
	end
end )
