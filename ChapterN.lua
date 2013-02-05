--[[
	代码速查手册（N区）
	技能索引：
		涅槃
]]--
--[[
	技能名：涅槃（限定技）
	相关武将：火·庞统
	描述：当你处于濒死状态时，你可以：弃置你区域里所有的牌，然后将你的武将牌翻至正面朝上并重置之，再摸三张牌且体力回复至3点。
	状态：验证通过
]]--
LuaNiepan = sgs.CreateTriggerSkill{
	name = "LuaNiepan",
	frequency = sgs.Skill_Limited, 
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:objectName() == player:objectName() then
			if player:askForSkillInvoke(self:objectName(), data) then
				player:loseMark("@nirvana")
				player:throwAllCards()
				local maxhp = player:getMaxHp()
				local hp = math.min(3, maxhp)
				room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
				player:drawCards(3)
				if player:isChained() then
					local damage = dying_data.damage
					if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
				end
				if not player:faceUp() then
					player:turnOver()
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return target:getMark("@nirvana") > 0
				end
			end
		end
		return false
	end
}
LuaNiepanStart = sgs.CreateTriggerSkill{
	name = "#LuaNiepanStart",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		player:gainMark("@nirvana")
	end
}