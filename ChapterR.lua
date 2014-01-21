--[[
	代码速查手册（R区）
	技能索引：
		仁德、仁德、仁德、仁望、仁心、忍戒、肉林、若愚
]]--
--[[
	技能名：仁德
	相关武将：标准·刘备
	描述：出牌阶段限一次，你可以将任意数量的手牌以任意分配方式交给任意数量的其他角色，然后当你于以此法交给其他角色的手牌首次达到两张或更多时，你回复1点体力。
]]--
--[[
	技能名：仁德
	相关武将：怀旧-标准·刘备-旧
	描述：出牌阶段，你可以将任意数量的手牌交给一名其他角色，然后当你于此阶段内以此法交给其他角色的手牌首次达到两张或更多时，你回复1点体力。
	引用：LuaNosRende
	状态：1217验证通过
]]--
LuaNosRendeCard = sgs.CreateSkillCard{
	name = "LuaNosRendeCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:obtainCard(target, self, false)
		local old_value = source:getMark("LuaNosRende")
		local new_value = old_value + self:getSubcards():length()
		room:setPlayerMark(source, "LuaNosRende", new_value)
		if (old_value < 2) and (new_value >= 2) then
			local recover = sgs.RecoverStruct()
			recover.card = self
			recover.who = source
			room:recover(source, recover)
		end
	end
}
LuaNosRendeVS = sgs.CreateViewAsSkill{
	name = "LuaNosRende" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local rende_card = LuaNosRendeCard:clone()
		for _, c in ipairs(cards) do
			rende_card:addSubcard(c)
		end
		return rende_card
	end ,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end
}
LuaNosRende = sgs.CreateTriggerSkill{
	name = "LuaNosRende" ,
	events = {sgs.EventPhaseChanging} ,
	view_as_skill = LuaNosRendeVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		room:setPlayerMark(player,"LuaNosRende", 0)
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getMark("LuaNosRende") > 0)
	end
}
--[[
	技能名：仁德
	相关武将：虎牢关·刘备
	描述：出牌阶段，你可以将最多两张手牌交给其他角色，若此阶段你给出的牌张数达到两张时，你回复1点体力。
	引用：LuaRende
	状态：验证通过
]]--
LuaRendeCard = sgs.CreateSkillCard{
	name = "LuaRendeCard",
	target_fixed = false,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local target
		if #targets == 0 then
			local list = room:getAlivePlayers()
			for _,player in sgs.qlist(list) do
				if player:objectName() ~= source:objectName() then
					target = player
					break
				end
			end
		else
			target = targets[1]
		end
		room:obtainCard(target, self, false)
		local subcards = self:getSubcards()
		local old_value = source:getMark("rende")
		local new_value = old_value + subcards:length()
		room:setPlayerMark(source, "rende", new_value)
		if old_value < 2 then
			if new_value >= 2 then
				local recover = sgs.RecoverStruct()
				recover.card = self
				recover.who = source
				room:recover(source, recover)
			end
		end
	end
}
LuaRendeVS = sgs.CreateViewAsSkill{
	name = "LuaRende",
	n = 2,
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			local markCount = sgs.Self:getMark("rende")
			return #selected + markCount < 2
		end
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local rende_card = LuaRendeCard:clone()
			for i=1, #cards, 1 do
				local id = cards[i]:getId()
				rende_card:addSubcard(id)
			end
			return rende_card
		end
	end
}
LuaRende = sgs.CreateTriggerSkill{
	name = "LuaRende",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaRendeVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "rende", 0)
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() then
				if target:hasSkill(self:objectName()) then
					if target:getPhase() == sgs.Player_NotActive then
						return target:hasUsed("#LuaRendeCard")
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：仁望
	相关武将：1v1·刘备
	描述：对手于其出牌阶段内对包括你的角色使用第二张及以上【杀】或非延时锦囊牌时，你可以弃置其一张牌。 
]]--
--[[
	技能名：仁心
	相关武将：一将成名2013·曹冲
	描述：一名其他角色处于濒死状态时，你可以将武将牌翻面并将所有手牌交给该角色，令该角色回复1点体力。
]]--
LuaRenxinCard = sgs.CreateSkillCard{
	name = "LuaRenxinCard",
	target_fixed = true,

	on_use = function(self, room, source, targets)
		local who = room:getCurrentDyingPlayer()
		if who then
			source:turnOver()
			room:obtainCard(who,source:wholeHandCards(),false)
		local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(who,recover)
	end
end
}
LuaRenxin = sgs.CreateViewAsSkill{
	name = "LuaRenxin",
	n = 0,

	view_as = function(self, cards)
		return LuaRenxinCard:clone()
end,
	enabled_at_play = function(self, player)
		return false
end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "peach" and not player:isKongcheng()
end
}
--[[
	技能名：忍戒（锁定技）
	相关武将：神·司马懿
	描述：每当你受到一次伤害后或于弃牌阶段弃置手牌后，你获得等同于受到伤害或弃置手牌数量的“忍”标记。
	引用：LuaRenjie、LuaRenjieClear
	状态：1217验证通过
]]--
LuaRenjie = sgs.CreateTriggerSkill{
	name = "LuaRenjie" ,
	events = {sgs.Damaged, sgs.CardsMoveOneTime} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		if event == sgs.CardsMoveOneTime then
			if player:getPhase() == sgs.Player_Discard then
				local move = data:toMoveOneTime()
				if (move.from:objectName() == player:objectName())
						and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
					local n = move.card_ids:length()
					if n > 0 then
						player:gainMark("@bear", n)
					end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			player:gainMark("@bear",damage.damage)
		end
		return false
	end
}
LuaRenjieClear = sgs.CreateTriggerSkill{
	name = "#LuaRenjie-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaRenjie" then
			player:loseAllMarks("@bear")
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：肉林（锁定技）
	相关武将：林·董卓
	当你使用【杀】指定一名女性角色为目标后，该角色需连续使用两张【闪】才能抵消；当你成为女性角色使用【杀】的目标后，你需连续使用两张【闪】才能抵消。
	引用：LuaRoulin
	状态：验证通过
]]--
LuaRoulinDummyCard = sgs.CreateSkillCard{
	name = "LuaRoulinDummyCard",
}
askForDoubleJink = function(player, slasher, reason)
	local room = player:getRoom()
	local first_jink = nil
	local second_jink = nil
	local prompt = string.format("@%s-jink-1", reason)
	first_jink = room:askForCard(player, "jink", prompt, sgs.QVariant(), sgs.CardUsed, slasher)
	if first_jink then
		prompt = string.format("@%s-jink-2", reason)
		second_jink = room:askForCard(player, "jink", prompt, sgs.QVariant(), sgs.CardUsed, slasher)
		local jink = nil
		if first_jink and second_jink then
			jink = LuaRoulinDummyCard:clone()
			jink:addSubcard(first_jink)
			jink:addSubcard(second_jink)
		end
		return jink
	end
end
LuaRoulin = sgs.CreateTriggerSkill{
	name = "LuaRoulin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.SlashProceed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
		local source = effect.from
		local target = effect.to
		if source:hasSkill(self:objectName()) and target:isFemale() then
			local female = target
			local jink = askForDoubleJink(female, source, "roulin1")
			room:slashResult(effect, jink)
			return true
		elseif source:isFemale() and target:hasSkill(self:objectName()) then
			local dongzhuo = target
			local jink = askForDoubleJink(dongzhuo, source, "roulin2")
			room:slashResult(effect, jink)
			return true
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				return true
			end
			return target:isFemale()
		end
		return false
	end
}
--[[
	技能名：若愚（主公技、觉醒技）
	相关武将：山·刘禅
	描述：回合开始阶段开始时，若你的体力是全场最少的（或之一），你须加1点体力上限，回复1点体力，并获得技能“激将”。
	引用：LuaRuoyu
	状态：1217验证通过
]]--
LuaRuoyu = sgs.CreateTriggerSkill{
	name = "LuaRuoyu$",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_invoke = true
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if player:getHp() > p:getHp() then
				can_invoke = false
				break
			end
		end
		if can_invoke then
			room:addPlayerMark(player, "LuaRuoyu")
			if room:changeMaxHpForAwakenSkill(player, 1) then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
				if player:isLord() then
					room:acquireSkill(player, "jijiang")
				end
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasLordSkill("LuaRuoyu")
				and target:isAlive()
				and (target:getMark("LuaRuoyu") == 0)
	end
}
