--[[
	代码速查手册（V区）
	（本区用于收录尚未实现或有争议的技能）
]]--
--[[
	技能名：完杀（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。
	引用：LuaWansha
	状态：0405验证失败
]]--
LuaWansha=sgs.CreateTriggerSkill{
	name = "LuaWansha",
	events = {sgs.AskForPeaches, sgs.EventPhaseChanging, sgs.Death},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			local jiaxu = room:getCurrent()
			if jiaxu and jiaxu:isAlive() and jiaxu:hasSkill(self:objectName()) and jiaxu:getPhase() ~= sgs.Player_NotActive then
				if dying.who:objectName() ~= player:objectName() and jiaxu:objectName() ~= player:objectName() then
					room:setPlayerFlag(player, "Global_PreventPeach")
				end
			end
		else
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to ~= sgs.Player_NotActive then return false end
			elseif event == sgs.Death then
				local death = data:toDeath()
				if death.who:objectName() ~= player:objectName() or death.who:getPhase() == sgs.Player_NotActive then return false end
			end
			for _ , p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("Global_PreventPeach") then
							 room:setPlayerFlag(p, "-Global_PreventPeach")
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target
	end
}
