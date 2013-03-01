--[[
	代码速查手册（M区）
	技能索引：
		马术、漫卷、猛进、秘计、密信、密诏、明策、明哲、谋断、谋溃
]]--
--[[
	技能名：马术（锁定技）
	相关武将：标准·马超、火·庞德、SP·庞德、SP·关羽、SP·最强神话、SP·暴怒战神、SP·马超、二将成名·马岱
	描述：你计算的与其他角色的距离-1。
	状态：验证通过
]]--
LuaMashu = sgs.CreateDistanceSkill{
	name = "LuaMashu",
	correct_func = function(self, from, to)
		if from:hasSkill("LuaMashu") then
			return -1
		end
	end,
}
--[[
	技能名：漫卷
	相关武将：☆SP·庞统
	描述：每当你将获得任何一张手牌，将之置于弃牌堆。若此情况处于你的回合中，你可依次将与该牌点数相同的一张牌从弃牌堆置于你的手上。
	状态：验证通过
]]--
DoManjuan = function(player, id, skillname)
	local room = player:getRoom()
	player:setFlags("ManjuanInvoke")
	local DiscardPile = room:getDiscardPile()
	local toGainList = sgs.IntList()
	local card = sgs.Sanguosha:getCard(id)
	for _,cid in sgs.qlist(DiscardPile) do
		local cd = sgs.Sanguosha:getCard(cid)
		if cd:getNumber() == card:getNumber() then
			toGainList:append(cid)
		end
	end
	room:fillAG(toGainList, player)
	local card_id = room:askForAG(player, toGainList, false, skillname)
	if card_id ~= -1 then
		local gain_card = sgs.Sanguosha:getCard(card_id)
		room:moveCardTo(gain_card, player, sgs.Player_PlaceHand, true)
	end
	player:invoke("clearAG")
end
LuaManjuan = sgs.CreateTriggerSkill{
	name = "LuaManjuan",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.CardDrawing},
	on_trigger = function(self, event, player, data)
		if player:hasFlag("ManjuanInvoke") then
			player:setFlags("-ManjuanInvoke")
			return false
		end
		local card_id = -1
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local dest = move.to
			local flag = true
			if dest then
				if dest:objectName() == player:objectName() then
					if move.to_place == sgs.Player_PlaceHand then
						if move.from and dest:objectName() ~= move.from:objectName() then
							for _,card_id in sgs.qlist(move.card_ids) do
								local card = sgs.Sanguosha:getCard(card_id)
								room:moveCardTo(card, nil, nil, sgs.Player_DiscardPile, reason)
								flag = false
							end
						end
					end
				end
			end
			if flag then
				return false
			end
		elseif event == sgs.CardDrawing then
			local tag = room:getTag("FirstRound")
			if tag:toBool() then
				return false
			else
				card_id = data:toInt()
				local card = sgs.Sanguosha:getCard(card_id)
				room:moveCardTo(card, nil, nil, sgs.Player_DiscardPile, reason)
			end
		end
		if player:getPhase() ~= sgs.Player_NotActive then
			if player:askForSkillInvoke(self:objectName(), data) then
				if event == sgs.CardsMoveOneTime then
					local move = data:toMoveOneTime()
					for _,card_id in sgs.qlist(move.card_ids) do
						DoManjuan(player, card_id, self:objectName())
					end
				else 
					DoManjuan(player, card_id, self:objectName())
				end
				return event ~= sgs.CardsMoveOneTime
			end
		end
		return event ~= sgs.CardsMoveOneTime
	end,
	priority = 2
}
--[[
	技能名：猛进
	相关武将：火·庞德、SP·庞德
	描述：当你使用的【杀】被目标角色的【闪】抵消时，你可以弃置其一张牌。 
	状态：验证通过
]]--
LuaMengjin = sgs.CreateTriggerSkill{
	name = "LuaMengjin",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.SlashMissed},  
	on_trigger = function(self, event, player, data) 
		local effect = data:toSlashEffect()
		local dest = effect.to
		if dest:isAlive() then
			if not dest:isNude() then
				if player:askForSkillInvoke(self:objectName(), data) then
					local room = player:getRoom()
					local to_throw = room:askForCardChosen(player, dest, "he", self:objectName())
					local card = sgs.Sanguosha:getCard(to_throw)
					room:throwCard(card, dest, player);
				end
			end
		end
		return false
	end, 
	priority = 2
}
--[[
	技能名：秘计
	相关武将：二将成名·王异
	描述：回合开始/结束阶段开始时，若你已受伤，你可以进行一次判定，若判定结果为黑色，你观看牌堆顶的X张牌（X为你已损失的体力值），然后将这些牌交给一名角色。
	状态：1111验证通过
]]--
LuaMiji = sgs.CreateTriggerSkill{
	name = "LuaMiji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:isWounded() then
			local phase = player:getPhase()
			if phase == sgs.Player_Start or phase == sgs.Player_Finish then
				if player:askForSkillInvoke(self:objectName()) then
					local room = player:getRoom()
					local judge = sgs.JudgeStruct()
					judge.pattern = sgs.QRegExp("(.*):(club|spade):(.*)")
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then
						local x = player:getLostHp()
						local miji_cards=sgs.CardList()
						miji_cards=room:getNCards(x,false)
						local miji_card = sgs.Sanguosha:cloneCard("Slash",sgs.Card_Spade,13)
						for _,card in sgs.qlist(miji_cards) do
							miji_card:addSubcard(card)
						end
						room:obtainCard(player,miji_card,false)
						local playerlist = room:getAllPlayers()
						local target = room:askForPlayerChosen(player, playerlist, self:objectName())
						room:obtainCard(target,miji_card,false)
					end
				end
			end
		end
		return false
	end,
}
--[[
	技能名：密信
	相关武将：铜雀台·伏皇后
	描述：出牌阶段，你可以将一张手牌交给一名其他角色，该角色须对你选择的另一名角色使用一张【杀】（无距离限制），否则你选择的角色观看其手牌并获得其中任意一张。每阶段限一次。 
	状态：验证通过
]]--
LuaXMixinCard = sgs.CreateSkillCard{
	name = "LuaXMixinCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		target:obtainCard(self, false)
		local others = sgs.SPlayerList()
		local list = room:getOtherPlayers(target)
		for _,p in sgs.qlist(list) do
			if target:canSlash(p, nil, false) then
				others:append(p)
			end
		end
		if not others:isEmpty() then
			local target2 = room:askForPlayerChosen(source, others, "LuaXMixin")
			room:setPlayerFlag(target, "jiefanUsed")
			if room:askForUseSlashTo(target, target2, "#mixin") then
				room:setPlayerFlag(target, "-jiefanUsed")
			else
				room:setPlayerFlag(target, "-jiefanUsed")
				local card_ids = target:handCards()
				room:fillAG(card_ids, target2)
				local cdid = room:askForAG(target2, card_ids, false, self:objectName())
				room:obtainCard(target2, cdid, false)
				target2:invoke("clearAG")
			end
			return
		end
	end
}
LuaXMixin = sgs.CreateViewAsSkill{
	name = "LuaXMixin", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaXMixinCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaXMixinCard")
	end
}
--[[
	技能名：密诏
	相关武将：铜雀台·汉献帝
	描述：出牌阶段，你可以将所有手牌（至少一张）交给一名其他角色。若如此做，你令该角色与你指定的另一名有手牌的角色拼点。视为拼点赢的角色对没赢的角色使用一张【杀】。每阶段限一次 
	状态：验证通过
]]--
LuaXMizhaoCard = sgs.CreateSkillCard{
	name = "LuaXMizhaoCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		target:obtainCard(effect.card, false)
		local room = source:getRoom()
		local targets = sgs.SPlayerList()
		local others = room:getOtherPlayers(target)
		for _,p in sgs.qlist(others) do
			if not p:isKongcheng() then
				targets:append(p)
			end
		end
		if not target:isKongcheng() then
			if not targets:isEmpty() then
				local dest = room:askForPlayerChosen(source, targets, "LuaXMizhao")
				target:pindian(dest, "LuaXMizhao", nil)
			end
		end
	end
}
LuaXMizhaoVS = sgs.CreateViewAsSkill{
	name = "LuaXMizhaoVS", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		local count = sgs.Self:getHandcardNum()
		if #cards == count then
			local card = LuaXMizhaoCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#LuaXMizhaoCard")
		end
		return false
	end
}
LuaXMizhao = sgs.CreateTriggerSkill{
	name = "LuaXMizhao",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Pindian},  
	view_as_skill = LuaXMizhaoVS, 
	on_trigger = function(self, event, player, data) 
		local pindian = data:toPindian()
		if pindian.reason == self:objectName() then
			local fromNumber = pindian.from_card:getNumber()
			local toNumber = pindian.to_card:getNumber()
			if fromNumber ~= toNumber then
				local winner
				local loser
				if fromNumber > toNumber then
					winner = pindian.from
					loser = pindian.to
				else
					winner = pindian.to
					loser = pindian.from
				end
				if winner:canSlash(loser, nil, false) then
					local room = player:getRoom()
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("LuaXMizhao")
					local card_use = sgs.CardUseStruct()
					card_use.from = winner
					card_use.to:append(loser)
					card_use.card = slash
					room:useCard(card_use, false)
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end, 
	priority = -1
}
--[[
	技能名：明策
	相关武将：一将成名·陈宫
	描述：出牌阶段，你可以交给一名其他角色一张装备牌或【杀】，该角色选择一项：1. 视为对其攻击范围内你选择的另一名角色使用一张【杀】。2. 摸一张牌。每回合限一次。
	状态：验证通过
]]--
LuaMingceCard = sgs.CreateSkillCard{
	name = "LuaMingceCard", 
	target_fixed = false, 
	will_throw = false, 
	on_effect = function(self, effect) 
		local dest = effect.to
		local source = effect.from
		local room = dest:getRoom()
		local can_use = false
		local targets = sgs.SPlayerList()
		local list = room:getOtherPlayers(dest)
		for _,p in sgs.qlist(list) do
			if dest:canSlash(p) then
				targets:append(p)
				can_use = true
			end
		end
		local target
		local choicelist = {}
		table.insert(choicelist, "draw")
		if can_use then
			table.insert(choicelist, "use")
		end
		dest:obtainCard(self)
		local choice
		if #choicelist > 1 then
			choice = room:askForChoice(dest, self:objectName(), "draw+use")
		else
			choice = choicelist[1]
		end
		if choice == "use" then
			if source:isAlive() then
				target = room:askForPlayerChosen(source, targets, self:objectName())
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName(self:objectName())
				local card_use = sgs.CardUseStruct()
				card_use.from = dest
				card_use.to:append(target)
				card_use.card = slash
				room:useCard(card_use, false)
			end
		elseif choice == "draw" then
			dest:drawCards(1)
		end
	end
}
LuaMingce = sgs.CreateViewAsSkill{
	name = "LuaMingce", 
	n = 1,
	view_filter = function(self, selected, to_select)
		local typeID = to_select:getTypeId()
		if typeID == sgs.Card_Equip then
			return true
		else
			return to_select:isKindOf("Slash")
		end
	end, 
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local mc_card = LuaMingceCard:clone()
			mc_card:addSubcard(card)
			return mc_card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaMingceCard")
	end
}
--[[
	技能名：明哲
	相关武将：新3V3·诸葛瑾
	描述：你的回合外，当你因使用、打出或弃置而失去一张红色牌时，你可以摸一张牌。 
	状态：尚未验证
]]--
--[[
	技能名：谋断（转化技）
	相关武将：☆SP·吕蒙
	描述：通常状态下，你拥有标记“武”并拥有技能“激昂”和“谦逊”。当你的手牌数为2张或以下时，你须将你的标记翻面为“文”，将该两项技能转化为“英姿”和“克己”。任一角色的回合开始前，你可弃一张牌将标记翻回。
	状态：验证通过
]]--
LuaMouduanStart = sgs.CreateTriggerSkill{
	name = "#LuaMouduanStart", 
	frequency = sgs.Skill_Frequency, 
	events = {sgs.GameStart}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:gainMark("@wu")
		room:acquireSkill(player, "jiang")
		room:acquireSkill(player, "qianxun")
	end,
	priority = -1
}
LuaMouduan = sgs.CreateTriggerSkill{
	name = "LuaMouduan", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TurnStart, sgs.CardsMoveOneTime}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local source = room:findPlayerBySkillName(self:objectName())
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from then
				if move.from:objectName() == player:objectName() then
					if player:getMark("@wu") > 0 then	
						local handcardnum = player:getHandcardNum()
						if handcardnum <= 2 then
							player:loseMark("@wu")
							player:gainMark("@wen")
							room:detachSkillFromPlayer(player, "jiang")
							room:detachSkillFromPlayer(player, "qianxun")
							room:acquireSkill(player, "yingzi")
							room:acquireSkill(player, "keji")
						end
					end
				end
			end
		elseif event == sgs.TurnStart then
			if source then
				if source:getMark("@wen") > 0 then
					if not source:isNude() then
						if source:askForSkillInvoke(self:objectName()) then
							room:askForDiscard(source, self:objectName(), 1, 1, false, true)
							local count = source:getHandcardNum()
							if count > 2 then
								source:loseMark("@wen")
								source:gainMark("@wu")
								room:detachSkillFromPlayer(source, "yingzi")
								room:detachSkillFromPlayer(source, "keji")
								room:acquireSkill(source, "jiang")
								room:acquireSkill(source, "qianxun")
							end
						end
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return (target ~= nil)
	end
}
LuaMouduanClear = sgs.CreateTriggerSkill{
	name = "#LuaMouduanClear",
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventLoseSkill}, 
	on_trigger = function(self, event, player, data) 
		local name = data:toString()
		if name == "LuaMouduan" then
			if player:getMark("@wu") > 0 then
				player:loseMark("@wu")
				room:detachSkillFromPlayer(player, "jiang")
				room:detachSkillFromPlayer(player, "qianxun")
			elseif player:getMark("@wen") > 0 then
				player:loseMark("@wen")
				room:detachSkillFromPlayer(player, "yingzi")
				room:detachSkillFromPlayer(player, "keji")
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return not target:hasSkill("LuaMouduan")
	end
}
--[[
	技能名：谋溃
	相关武将：铜雀台·穆顺
	描述：当你使用【杀】指定一名角色为目标后，你可以选择一项：摸一张牌，或弃置其一张牌。若如此做，此【杀】被【闪】抵消时，该角色弃置你的一张牌。 
	状态：验证通过
]]--
LuaXMoukui = sgs.CreateTriggerSkill{
	name = "LuaXMoukui",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TargetConfirmed, sgs.SlashMissed, sgs.CardFinished},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if player:objectName() == use.from:objectName() then
				if player:isAlive() and player:hasSkill(self:objectName()) then
					local slash = use.card
					if slash:isKindOf("Slash") then
						for _,p in sgs.qlist(use.to) do
							local ai_data = sgs.QVariant()
							ai_data:setValue(p)
							if player:askForSkillInvoke(self:objectName(), ai_data) then
								local choice
								if p:isNude() then
									choice = "draw"
								else
									choice = room:askForChoice(player, self:objectName(), "draw+discard")
								end
								if choice == "draw" then
									player:drawCards(1)
								else
									local disc = room:askForCardChosen(player, p, "he", self:objectName())
									room:throwCard(disc, p, player)
								end
								local mark = string.format("%s%s", self:objectName(), slash:getEffectIdString())
								local count = p:getMark(mark) + 1
								room:setPlayerMark(p, mark,	count)
							end
						end
					end
				end
			end
		elseif event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			local dest = effect.to
			local source = effect.from
			local slash = effect.slash
			local mark = string.format("%s%s", self:objectName(), slash:getEffectIdString())
			if dest:getMark(mark) > 0 then
				if source:isAlive() and dest:isAlive() and not source:isNude() then
					local disc = room:askForCardChosen(dest, source, "he", self:objectName())
					room:throwCard(disc, source, dest)
					local count = dest:getMark(mark) - 1
					room:setPlayerMark(dest, mark, count)
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				local players = room:getAllPlayers()
				for _,p in sgs.qlist(players) do
					local mark = string.format("%s%s", self:objectName(), use.card:getEffectIdString())
					room:setPlayerMark(p, mark, 0)
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
