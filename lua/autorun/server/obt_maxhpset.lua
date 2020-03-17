--[[
	Set maximum health when spawned
]]
hook.Add("OnEntityCreated", "obt_npc_spawn_health", function(ent)
	if (IsValid(ent) and ent:IsNPC()) then
		timer.Simple(0.001, function()
			if (IsValid(ent)) then
				ent:SetNWInt("npc_maxhealth", ent:Health());
			end
		end);
	end
end);

--[[
	Set maximum health to already existing entities
]]
hook.Add("Initialize", "obt_npc_init_health", function()
	timer.Simple(1, function()
		for _, ent in pairs(ents.GetAll()) do
			if (IsValid(ent) and ent:IsNPC()) then
				ent:SetNWInt("npc_maxhealth", ent:Health());
			end
		end
	end);
end);
