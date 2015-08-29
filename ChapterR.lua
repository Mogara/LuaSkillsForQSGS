--[[
	代码速查手册（R区）
	技能索引：
		仁德、仁德、仁德、仁望、仁心、忍戒、肉林、若愚
]]--
--[[
	技能名：仁德
	相关武将：标准·刘备
	描述：出牌阶段限一次，你可以将至少一张手牌交给其他角色，若你以此法交给其他角色的手牌数量不少于2，你回复1点体力。
	状态：1217验证通过
	引用：LuaRende
	注备：为什么table.contains不好使……
]]--
LuaRendeCard = sgs.CreateSkillCard{
	name = "LuaRendeCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_use = function(self, room, source, targets)
		local target = targets[1];
		source:speak("a")
		local old_value = source:getMark("LuaRende");
		local rende_list = {}
		if old_value > 0 then
			rende_list = source:property("LuaRende"):toString():split("+")
		else
			rende_list = sgs.QList2Table(source:handCards())
		end
		for _,id in sgs.qlist(self:getSubcards())do
			table.removeOne(rende_list,id)
		end
		room:setPlayerProperty(source, "LuaRende", sgs.QVariant(table.concat(rende_list,"+")));
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "LuaRende","")
		room:moveCardTo(self,target,sgs.Player_PlaceHand,reason)
		local new_value = old_value + self:getSubcards():length()
		room:setPlayerMark(source, "LuaRende", new_value);
		if (old_value < 2 and new_value >= 2) then
			local recover = sgs.RecoverStruct()
			recover.card = self
			recover.who = source;
			room:recover(source, recover);
		end
		if room:getMode() == "04_1v3" and source:getMark("LuaRende") >= 2 then return end
		if source:isKongcheng() or source:isDead() or #rende_list == 0 then return end
		room:addPlayerHistory(source, "#LuaRendeCard", -1);
		if not room:askForUseCard(source, "@@LuaRende", "@rende-give", -1, sgs.Card_MethodNone) then
			room:addPlayerHistory(source,"#LuaRendeCard")
		end
	end,
}
LuaRendeVs = sgs.CreateViewAsSkill{
	name = "LuaRende", 
	n = 10086, 
	response_pattern = "@@LuaRende",
	view_filter = function(self, selected, to_select)
		if sgs.Self:property("GameMode"):toString() == "04_1v3" and #selected + sgs.Self:getMark("LuaRende") >= 2 then
		   return false
		else
			if to_select:isEquipped() then return false end
			if sgs.Sanguosha:getCurrentCardUsePattern() == "@@LuaRende" then
				local rende_list = sgs.Self:property("LuaRende"):toString():split("+")
				return function()
					for _,id in pairs(rende_list)do
						if id == to_select:getEffectiveId() then
							return true
						end
					end
					return false
				end
			else
				return true
			end
			return true
		end
	end, 
	view_as = function(self, cards) 
		if #cards > 0 then
			local rende =  LuaRendeCard:clone()
			for _,c in ipairs(cards)do
				rende:addSubcard(c)
			end
			return rende
		end
	end, 
	enabled_at_play = function(self, player)
		if player:property("GameMode"):toString() == "04_1v3" and player:getMark("LuaRende") >= 2 then
		   return false
		end
		return (not player:hasUsed("#LuaRendeCard")) and not player:isKongcheng()
	end, 
}
LuaRende = sgs.CreateTriggerSkill{
	name = "LuaRende" ,
	events = {sgs.EventPhaseChanging,sgs.TurnStart} ,
	view_as_skill = LuaRendeVs ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging and player:getMark("LuaRende") > 0 then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
				room:setPlayerMark(player,"LuaRende", 0)
			return false
		elseif event == sgs.TurnStart and player:property("GameMode"):toString() == "" then
			room:setPlayerProperty(player,"GameMode",sgs.QVariant(room:getMode()))
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：仁德
	相关武将：怀旧-标准·刘备-旧
	描述：出牌阶段，你可以将至少一张手牌任意分配给其他角色。你于本阶段内以此法给出的手牌首次达到两张或更多后，你回复1点体力。  
	引用：LuaNosRende
	状态：0405验证通过
	备注：虎牢关部分没有lua
]]--
LuaNosRendeCard = sgs.CreateSkillCard{
	name = "LuaNosRendeCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "LuaNosRende", "")
		room:obtainCard(targets[1], self, reason, false)
		local old_value = source:getMark("LuaNosRende")
		local new_value = old_value + self:getSubcards():length()
		room:setPlayerMark(source, "LuaNosRende", new_value)
		if old_value < 2 and new_value >= 2 then
			room:recover(source, sgs.RecoverStruct(source))
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
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		player:getRoom():setPlayerMark(player, self:objectName(), 0)
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:getMark(self:objectName()) > 0
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
	引用：LuaRenwang
	状态：1217验证通过
]]--
LuaRenwang = sgs.CreateTriggerSkill{
	name = "LuaRenwang" ,
	events = {sgs.CardUsed, sgs.EventPhaseChanging} ,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed and player:getPhase() == sgs.Player_Play then
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") and not use.card:isNDTrick() then return false end
			local first = sgs.SPlayerList()
			for _,to in sgs.qlist(use.to) do
				if to:objectName() ~= player:objectName() and not to:hasFlag("LuaRenwangEffect") then
					first:append(to)
					to:setFlags("LuaRenwangEffect")
				end
			end
			for _,p in sgs.qlist(room:getOtherPlayers(use.from)) do
				if use.to:contains(p) and not first:contains(p) and p:canDiscard(use.from, "he") and  p:hasFlag("LuaRenwangEffect") and p:isAlive() and p:hasSkill(self:objectName()) then
					if not room:askForSkillInvoke(p, self:objectName(), data) then return false end
					room:throwCard(room:askForCardChosen(p, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard), use.from, p);
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,to in sgs.qlist(room:getAlivePlayers()) do
					if to:hasFlag("LuaRenwangEffect") then
						to:setFlags("-LuaRenwangEffect")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--[[
	技能名：仁心
	相关武将：一将成名2013·曹冲
	描述：一名其他角色处于濒死状态时，你可以将武将牌翻面并将所有手牌交给该角色，令该角色回复1点体力。
	引用：LuaRenxin
	状态：1217验证通过
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
LuaRenxin = sgs.CreateZeroCardViewAsSkill{
	name = "LuaRenxin",

	view_as = function(self) 
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
	描述：每当你受到1点伤害后或于弃牌阶段因你的弃置而失去一张牌后，你获得一枚“忍”。 
	引用：LuaRenjie
	状态：0405验证通过
]]--
LuaRenjie = sgs.CreateTriggerSkill{
	name = "LuaRenjie" ,
	events = {sgs.Damaged, sgs.CardsMoveOneTime} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			if player:getPhase() == sgs.Player_Discard then
				local move = data:toMoveOneTime()
				if move.from:objectName() == player:objectName() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
					local n = move.card_ids:length()
					if n > 0 then
						room:notifySkillInvoked(player, self:objectName())
						player:gainMark("@bear", n)
					end
				end
			end
		elseif event == sgs.Damaged then
			room:notifySkillInvoked(player, self:objectName())
			local damage = data:toDamage()
			player:gainMark("@bear",damage.damage)
		end
		return false
	end
}
--[[
	技能名：肉林（锁定技）
	相关武将：林·董卓
	当你使用【杀】指定一名女性角色为目标后，该角色需连续使用两张【闪】才能抵消；当你成为女性角色使用【杀】的目标后，你需连续使用两张【闪】才能抵消。
	引用：LuaRoulin
	状态：1217验证通过
]]--
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
LuaRoulin = sgs.CreateTriggerSkill{
	name = "LuaRoulin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and player:objectName() == use.from:objectName() then
			local jink_table = sgs.QList2Table(use.from:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			local play_effect = false
			if use.from and use.from:isAlive() and use.from:hasSkill(self:objectName()) then
				for _,p in sgs.qlist(use.to) do
					if p:isFemale() then
						play_effect = true
						if jink_table[index] == 1 then
							jink_table[index] = 2
						end
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				use.from:setTag("Jink_" .. use.card:toString(), jink_data)
				if play_effect then
					room:notifySkillInvoked(use.from, self:objectName())
				end
			elseif use.from:isFemale() then
				for _,p in sgs.qlist(use.to) do
					if p:hasSkill(self:objectName()) then
						play_effect = true
						if jink_table[index] == 1 then
							jink_table[index] = 2
						end
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				use.from:setTag("Jink_" .. use.card:toString(), jink_data)
				if play_effect then
					for _,p in sgs.qlist(use.to) do
						if p:hasSkill(self:objectName()) then
							room:notifySkillInvoked(p, self:objectName())
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil and (target:hasSkill(self:objectName()) or target:isFemale())
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
