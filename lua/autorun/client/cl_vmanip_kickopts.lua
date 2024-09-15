if (not ConVarExists("vmanip_kick_bind")) then
	CreateClientConVar("vmanip_kick_bind", "k", true, false, "What keycode to bind VManip Kick to")
	CreateClientConVar("vmanip_kick_power", 1, true, false, "What power to give your VManip Kick", 0, 1)
	CreateClientConVar("vmanip_kick_admin", "false", true, false, "Whether or not to supercharge your kick. Ignored if you are not an admin")
end

hook.Add( "AddToolMenuCategories", "VManipSettingsCategory", function()
	spawnmenu.AddToolCategory( "Options", "VManip", "#VManip" )
end )

hook.Add( "PopulateToolMenu", "VManipSettings_Kick", function()
	spawnmenu.AddToolMenuOption( "Options", "VManip", "Kicking", "#Kicking", "", "", function(panel) 
		panel:ClearControls()
		local entry,_ = panel:TextEntry("Key", "vmanip_kick_bind")
		local slider,_ = panel:NumSlider("Power", "vmanip_kick_power", 0, 1, 2)
		if (LocalPlayer():IsAdmin()) then
			panel:Help("Admin Only Section")
			panel:CheckBox("Admin Mode", "vmanip_kick_admin")
			panel:ControlHelp("Supercharges your kick power by 100x. Available to admins only.")
			panel:Help("The following settings will change how kicking works for everyone in the server!")
			local damageWang = panel:NumberWang("Kick Damage", "", 0, 1000)
			panel:ControlHelp("Global kick damage. 5 by default.")
			local radiusWang = panel:NumberWang("Kick Radius", "", 0.1, 180)
			panel:ControlHelp("Global kick radius in degrees. 36 by default.")
			local rangeWang = panel:NumberWang("Kick Range", "", 0.1, 1000)
			panel:ControlHelp("Global kick range in units. 150 by default.")
			local doorsBox = panel:CheckBox("Door Kicking", "")
			panel:ControlHelp("Globally controls the ability to door kick. Enabled by default.")
			local updateButton = panel:Button("Update")
			panel:ControlHelp("Fetches the latest values from the server. Saves on resources.")
			net.Receive("send_sv_vmanip_kick_convars", function()
				damageWang:SetValue(net.ReadFloat())
				radiusWang:SetValue(net.ReadFloat())
				rangeWang:SetValue(net.ReadFloat())
				doorsBox:SetValue(net.ReadBool())
			end )
			local modifyCooldown = 0
			local function update()
				modifyCooldown = CurTime() + 0.2
				net.Start("request_sv_vmanip_kick_convars")
				net.SendToServer()
			end
			update()
			function updateButton:DoClick() update() end
			local function modify(cvName, reqValue)
				if (CurTime() < modifyCooldown) then return end
				net.Start("update_sv_vmanip_kick_convars")
				net.WriteString(cvName)
				net.WriteString(tostring(reqValue))
				net.SendToServer()
			end
			function damageWang:OnValueChanged(v) modify("sv_vmanip_kick_damage", v) end
			function radiusWang:OnValueChanged(v) modify("sv_vmanip_kick_radius", v) end
			function rangeWang:OnValueChanged(v) modify("sv_vmanip_kick_range", v) end
			function doorsBox:OnChange(v) modify("sv_vmanip_kick_doors", v) end
		end
	end )
end )