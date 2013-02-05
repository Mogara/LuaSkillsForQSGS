--[[
	代码速查手册（E区）
	技能索引：
		恩怨、恩怨
]]--
--[[
	技能名：恩怨
	相关武将：一将成名·法正
	描述：你每次获得一名其他角色两张或更多的牌时，可以令其摸一张牌；每当你受到1点伤害后，你可以令伤害来源选择一项：交给你一张手牌，或失去1点体力。
	状态：验证通过
]]--
LuaEnyuan = sgs.CreateTriggerSkill{
	name = "LuaEnyuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local dest = move.to
			local source = move.from
			if dest then
				if dest:objectName() == player:objectName() then
					if source then
						local cards = move.card_ids
						local count = cards:length()
						if count > 1 then
							if room:askForSkillInvoke(player, self:objectName(), data) then
								local alives = room:getAlivePlayers()
								for _,p in sgs.qlist(alives) do
									if p:objectName() == source:objectName() then
										room:drawCards(p, 1, self:objectName())
										break
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			local source = damage.from
			if source then
				if source:objectName() ~= player:objectName() then
					local count = damage.damage
					for i=1, count, 1 do
						if room:askForSkillInvoke(player, self:objectName(), data) then
							local card = room:askForExchange(source, self:objectName(), 1, false, "EnyuanGive", true)
							if card then
								room:moveCardTo(card, player, sgs.Player_PlaceHand)
							else
								room:loseHp(source)
							end
						end
					end
				end
			end
		end
	end
}
--[[
	技能名：恩怨（锁定技）
	相关武将：怀旧·法正
	描述：其他角色每令你回复1点体力，该角色摸一张牌；其他角色每对你造成一次伤害后，需交给你一张红桃手牌，否则该角色失去1点体力。
	状态：验证通过
]]--
LuaNosEnyuan = sgs.CreateTriggerSkill{
	name = "LuaNosEnyuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpRecover, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpRecover then
			local recover = data:toRecover()
			local source = recover.who
			local count = recover.recover
			if source then
				if source:objectName() ~= player:objectName() then
					source:drawCards(count)
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			local source = damage.from
			if source then
				if source:objectName() ~= player:objectName() then
					local card = room:askForCard(source, ".enyuan", "@enyuanheart", sgs.QVariant(), sgs.NonTrigger)
					if card then
						player:obtainCard(card)
					else
						room:loseHp(source)
					end
				end
			end
		end
	end
}