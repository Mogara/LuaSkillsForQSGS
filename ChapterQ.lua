--[[
	代码速查手册（Q区）
	技能索引：
		七星、奇才、奇策、奇袭、谦逊、潜袭、强袭、巧变、琴音、倾国、青囊、驱虎、权计
]]--
--[[
	技能名：七星
	相关武将：神·诸葛亮
	描述：分发起始手牌时，共发你十一张牌，你选四张作为手牌，其余的面朝下置于一旁，称为“星”；摸牌阶段结束时，你可以用任意数量的手牌等量替换这些“星”。
	状态：验证通过
]]--
Exchange = function(shenzhuge)
	local stars = shenzhuge:getPile("stars")
	if stars:length() > 0 then
		local room = shenzhuge:getRoom()
		local n = 0
		while stars:length() > 0 do
			room:fillAG(stars, shenzhuge)
			local card_id = room:askForAG(shenzhuge, stars, true, "LuaQixing")
			shenzhuge:invoke("clearAG")
			if card_id == -1 then
				break
			end
			stars:removeOne(card_id)
			n = n + 1
			local card = sgs.Sanguosha:getCard(card_id)
			room:obtainCard(shenzhuge, card, false)
		end
		if n > 0 then
			local exchange_card = room:askForExchange(shenzhuge, "LuaQixing", n)
			local subcards = exchange_card:getSubcards()
			for _,id in sgs.qlist(subcards) do
				shenzhuge:addToPile("stars", id, false)
			end
		end
	end
end
DiscardStar = function(shenzhuge, n, skillName)
	local room = shenzhuge:getRoom();
	local stars = shenzhuge:getPile("stars")
	for i = 1, n, 1 do
		room:fillAG(stars, shenzhuge)
		local card_id = room:askForAG(shenzhuge, stars, false, "qixing-discard")
		shenzhuge:invoke("clearAG")
		stars:removeOne(card_id)
		local card = sgs.Sanguosha:getCard(card_id)
		room:throwCard(card, nil, nil)
	end
end
LuaQixing = sgs.CreateTriggerSkill{
	name = "LuaQixing",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd, sgs.EventLoseSkill}, 
	on_trigger = function(self, event, player, data) 
		if event == sgs.EventPhaseEnd then
			if player:hasSkill(self:objectName()) then
				local stars = player:getPile("stars")
				if stars:length() > 0 then
					if player:getPhase() == sgs.Player_Draw then
						Exchange(player)
					end
				end
			end
		elseif event == EventLoseSkill then
			local name = data:toString()
			if name == self:objectName() then
				player:removePileByName("stars")
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return (target ~= nil)
	end
}
LuaQixingStart = sgs.CreateTriggerSkill{
	name = "#LuaQixingStart", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "qixingOwner", 1)
		for i = 1, 7, 1 do
			local id = room:drawCard()
			player:addToPile("stars", id, false)
		end
		Exchange(player)
	end,
	priority = -1
}
LuaQixingAsk = sgs.CreateTriggerSkill{
	name = "#LuaQixingAsk",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local stars = player:getPile("stars")
			if stars:length() > 0 then
				if player:hasSkill("kuangfeng") then
					room:askForUseCard(player, "@@kuangfeng", "@kuangfeng-card")
				end
			end
			stars = player:getPile("stars")
			if stars:length() > 0 then
				if player:hasSkill("dawu") then
					room:askForUseCard(player, "@@dawu", "@dawu-card")
				end
			end
		end
		return false
	end
}
LuaQixingClear = sgs.CreateTriggerSkill{
	name = "#LuaQixingClear", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Death, sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local players = room:getAllPlayers()
			for _,dest in sgs.qlist(players) do
				dest:loseAllMarks("@gale")
				dest:loseAllMarks("@fog")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				local players = room:getAllPlayers()
				for _,dest in sgs.qlist(players) do
					if dest:getMark("@gale") > 0 then
						dest:loseMark("@gale")
					end
					if dest:getMark("@fog") > 0 then
						dest:loseMark("@fog")
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:getMark("qixingOwner") > 0
		end
		return false
	end, 
	priority = 3
}
--[[
	技能名：奇才（锁定技）
	相关武将：标准·黄月英
	描述：你使用锦囊牌时无距离限制。
]]--
--[[
	技能名：奇策
	相关武将：二将成名·荀攸
	描述：出牌阶段，你可以将所有的手牌（至少一张）当任意一张非延时类锦囊牌使用。每阶段限一次。
]]--
--[[
	技能名：奇袭
	相关武将：标准·甘宁
	描述：你可以将一张黑色牌当【过河拆桥】使用。
	状态：验证通过
]]--
LuaQixi = sgs.CreateViewAsSkill{
	name = "LuaQixi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		if #cards == 1 then
			local card = cards[1]
			local acard = sgs.Sanguosha:cloneCard("dismantlement", card:getSuit(), card:getNumber())
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end
}
--[[
	技能名：谦逊（锁定技）
	相关武将：标准·陆逊
	描述：你不能被选择为【顺手牵羊】和【乐不思蜀】的目标。
	状态：验证通过
]]--
LuaQianxun = sgs.CreateProhibitSkill{
	name = "LuaQianxun", 
	is_prohibited = function(self, from, to, card)
		return card:isKindOf("Snatch") or card:isKindOf("Indulgence")
	end
}
--[[
	技能名：潜袭
	相关武将：二将成名·马岱
	描述：每当你使用【杀】对距离为1的目标角色造成伤害时，你可以进行一次判定，若判定结果不为红桃，你防止此伤害，改为令其减1点体力上限。
	状态：验证通过
]]--
LuaQianxi = sgs.CreateTriggerSkill{
	name = "LuaQianxi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local victim = damage.to
		local card = damage.card
		if card then
			if card:isKindOf("Slash") then
				if player:distanceTo(victim) <= 1 then
					if room:askForSkillInvoke(player, "LuaQianxi", data) then
						room:loseMaxHp(victim)
						return true
					end
				end
			end
		end
	end
}
--[[
	技能名：强袭
	相关武将：火·典韦
	描述：出牌阶段，你可以失去1点体力或弃置一张武器牌，对你攻击范围内的一名角色造成1点伤害。每阶段限一次。
	状态：验证通过
]]--
LuaQiangxiCard = sgs.CreateSkillCard{
	name = "LuaQiangxiCard", 
	target_fixed = false, 
	will_throw = true,
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			local subcards = self:getSubcards()
			if subcards:length() > 0 then
				local weapon = sgs.Self:getWeapon()
				if weapon then
					local card_id = subcards:first()
					if weapon:getId() == card_id then
						return sgs.Self:distanceTo(to_select) <= 1
					end
				end
			end
			return sgs.Self:inMyAttackRange(to_select)
		end
	end,
	on_use = function(self, room, source, targets)
		local dest = targets[1]
		local subcards = self:getSubcards()
		if subcards:length() == 0 then
			room:loseHp(source, 1)
		end
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.to = dest
		damage.damage = 1
		damage.card = nil
		room:damage(damage)
	end
}
LuaQiangxi = sgs.CreateViewAsSkill{
	name = "LuaQiangxi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isKindOf("Weapon")
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return LuaQiangxiCard:clone()
		elseif #cards == 1 then
			local card = LuaQiangxiCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaQiangxiCard")
	end
}
--[[
	技能名：巧变
	相关武将：山·张郃
	描述：你可以弃置一张手牌，跳过你的一个阶段（回合开始和回合结束阶段除外），若以此法跳过摸牌阶段，你获得其他至多两名角色各一张手牌；若以此法跳过出牌阶段，你可以将一名角色装备区或判定区里的一张牌移动到另一名角色区域里的相应位置。
	状态：验证通过
]]--
LuaQiaobianCard = sgs.CreateSkillCard{
	name = "LuaQiaobianCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select)
		local phase = sgs.Self:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			if to_select:objectName() ~= sgs.Self:objectName() then
				if not to_select:isKongcheng() then
					return #targets < 2
				end
			end
		elseif phase == sgs.Player_Play then
			if #targets == 0 then
				if to_select:getJudgingArea():length() >0 then
					return true
				end
				return to_select:getEquips():length() > 0
			end
		end
		return false
	end,
	feasible = function(self, targets)
		local phase = sgs.Self:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			if #targets > 0 then
				return #targets <= 2
			end
		elseif phase == sgs.Player_Play then
			return #targets == 1
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local phase = source:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			if #targets > 0 then
				local move1 = sgs.CardsMoveStruct()
				local id1 = room:askForCardChosen(source, targets[1], "h", self:objectName())
				move1.card_ids:append(id1)
				move1.to = source
				move1.to_place = sgs.Player_PlaceHand
				if #targets == 2 then
					local move2 = sgs.CardsMoveStruct()
					local id2 = room:askForCardChosen(source, targets[2], "h", self:objectName())
					move2.card_ids:append() 
					move2.to = source
					move2.to_place = Player_PlaceHand
					room:moveCardsAtomic(move2, false)
				end
				room:moveCardsAtomic(move1, false)
			end
		elseif phase == sgs.Player_Play then
			if #targets > 0 then
				local from = targets[1]
				if from:hasEquip() or from:getJudgingArea():length() > 0 then
					local card_id = room:askForCardChosen(source, from, "ej", self:objectName())
					local card = sgs.Sanguosha:getCard(card_id)
					local place = room:getCardPlace(card_id)
					local equip_index = -1
					if place == sgs.Player_PlaceEquip then
						local equip = card:getRealCard()
						equip_index = equip:location()
					end
					local tos = sgs.SPlayerList()
					local list = room:getAlivePlayers()
					for _,p in sgs.qlist(list) do
						if equip_index ~= -1 then
							if p:getEquip(equip_index) then
								tos:append(p)
							end
						else
							if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
								tos:append(p)
							end
						end
					end
					local tag = sgs.QVariant()
					tag.setValue(from)
					room:setTag("QiaobianTarget", tag)
					local to = room:askForPlayerChosen(source, tos, "qiaobian")
					if to then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), "")
						room:moveCardTo(card, from, to, place, reason)
					end
					room:removeTag("QiaobianTarget")
				end
			end
		end
	end
}
LuaQiaobianVS = sgs.CreateViewAsSkill{
	name = "LuaQiaobianVS", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaQiaobianCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@qiaobian"
	end
}
LuaQiaobian = sgs.CreateTriggerSkill{
	name = "LuaQiaobian", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseChanging}, 
	view_as_skill = LuaQiaobianVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local change = data:toPhaseChange()
		local nextphase = change.to
		room:setPlayerMark(player, "qiaobianPhase", nextphase)
		local index = 0
		if nextphase == sgs.Player_Judge then
			index = 1
		elseif nextphase == sgs.Player_Draw then
			index = 2
		elseif nextphase == sgs.Player_Play then
			index = 3
		elseif nextphase == sgs.Player_Discard then
			index = 4
		end
		local discard_prompt = string.format("#qiaobian-%d", index)
		local use_prompt = string.format("@qiaobian-%d", index)
		if index > 0 then
			if room:askForDiscard(player, self:objectName(), 1, 1, true, false, discard_prompt) then
				if not player:isSkipped(nextphase) then
					if index == 2 or index == 3 then
						room:askForUseCard(player, "@qiaobian", use_prompt, index)
					end
				end
				player:skip(nextphase)
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) and target:isAlive() then
				return not target:isKongcheng()
			end
		end
		return false
	end
}
--[[
	技能名：琴音
	相关武将：神·周瑜
	描述：当你于弃牌阶段内弃置了两张或更多的手牌后，你可以令所有角色各回复1点体力或各失去1点体力。每阶段限一次。
	状态：验证通过
]]--
perform = function(player, skill_name)
	local room = player:getRoom()
	local result = room:askForChoice(player, skill_name, "up+down")
	local all_players = room:getAllPlayers()
	if result == "up" then
		for _,p in sgs.qlist(all_players) do
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(p, recover)
		end
	elseif result == "down" then
		for _,p in sgs.qlist(all_players) do
			room:loseHp(p)
		end
	end
end
LuaQinyin = sgs.CreateTriggerSkill{
	name = "LuaQinyin", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Discard then
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				local source = move.from
				if source:objectName() == player:objectName() then
					if move.to_place == sgs.Player_DiscardPile then
						local count = player:getMark("qinyin")
						count = count + move.card_ids:length()
						player:setMark("qinyin", count)
					end
					if not player:hasFlag("qinyin_used") then
						if player:getMark("qinyin") >= 2 then
							if player:askForSkillInvoke(self:objectName()) then
								local room = player:getRoom()
								room:setPlayerFlag(player, "qinyin_used")
								perform(player, self:objectName())
							end
						end
					end
				end
			elseif event == sgs.EventPhaseStart then
				player:setMark("qinyin", 0)
			end
		end
		return false
	end
}
--[[
	技能名：倾国
	相关武将：标准·甄姬、SP·甄姬
	描述：你可以将一张黑色手牌当【闪】使用或打出。
	状态：验证通过
]]--
LuaQingguo = sgs.CreateViewAsSkill{
	name = "LuaQingguo", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if to_select:isBlack() then
			return not to_select:isEquipped()
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local jink = sgs.Sanguosha:cloneCard("jink", suit, point)
			jink:setSkillName(self:objectName())
			jink:addSubcard(id)
			return jink
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "jink"
	end
}
--[[
	技能名：青囊
	相关武将：标准·华佗
	描述：出牌阶段，你可以弃置一张手牌，令一名已受伤的角色回复1点体力。每阶段限一次。
	状态：验证通过
]]--
LuaQingnangCard = sgs.CreateSkillCard{
	name = "LuaQingnangCard",
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return to_select:isWounded()
		end
		return false
	end,
	feasible = function(self, targets)
		if #targets == 1 then
			return targets[1]:isWounded()
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		local effect = sgs.CardEffectStruct()
		effect.card = self
		effect.from = source
		effect.to = target
		room:cardEffect(effect)
	end,
	on_effect = function(self, effect) 
		local dest = effect.to
		local room = dest:getRoom()
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = effect.from
		room:recover(dest, recover)
	end
}
LuaQingnang = sgs.CreateViewAsSkill{
	name = "LuaQingnang", 
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if #cards ==1 then
			local card = cards[1]
			local qn_card = LuaQingnangCard:clone()
			qn_card:addSubcard(card)
			return qn_card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaQingnangCard")
	end
}
--[[
	技能名：驱虎
	相关武将：火·荀彧
	描述：出牌阶段，你可以与一名体力比你多的角色拼点。若你赢，则该角色对其攻击范围内你选择的另一名角色造成1点伤害。若你没赢，则其对你造成1点伤害。每阶段限一次。
	状态：验证通过
]]--
LuaQuhuCard = sgs.CreateSkillCard{
	name = "LuaQuhuCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			local player = sgs.Self
			if to_select:getHp() > player:getHp() then
				return not to_select:isKongcheng()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local tiger = targets[1]
		local success = source:pindian(tiger, self:objectName(), self)
		if success then
			local players = room:getOtherPlayers(tiger)
			local wolves = sgs.SPlayerList()
			for _,player in sgs.qlist(players) do
				if tiger:inMyAttackRange(player) then
					wolves:append(player)
				end
			end
			if wolves:isEmpty() then
				return
			end
			local wolf = room:askForPlayerChosen(source, wolves, self:objectName())
			local damage = sgs.DamageStruct()
			damage.from = tiger
			damage.to = wolf
			room:damage(damage)
		else
			local damage = sgs.DamageStruct()
			damage.from = tiger
			damage.to = source
			room:damage(damage)
		end
	end
}
LuaQuhu = sgs.CreateViewAsSkill{
	name = "LuaQuhu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = LuaQuhuCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end 
	end,
	enabled_at_play = function(self, player)
		if not player:hasUsed("#LuaQuhuCard") then
			return not player:isKongcheng()
		end
		return false
	end
}
--[[
	技能名：权计
	相关武将：一将成名·钟会
	描述：每当你受到1点伤害后，你可以摸一张牌，然后将一张手牌置于你的武将牌上，称为“权”；每有一张“权”，你的手牌上限便+1。
	状态：验证通过
]]--
LuaQuanji = sgs.CreateTriggerSkill{
	name = "LuaQuanji", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Damaged}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local damage = data:toDamage()
			local x = damage.damage
			for i=1, x, 1 do
				room:drawCards(player, 1)
				if not player:isKongcheng() then
					local card_id = -1
					local handcards = player:handCards()
					if handcards:length() == 1 then
						room:getThread():delay(500)
						card_id = handcards:first()
					else
						local cards = room:askForExchange(player, self:objectName(), 1, false, "QuanjiPush")
						card_id = cards:getSubcards():first()
					end
					player:addToPile("power", card_id)
				end
			end
		end
	end
}
LuaQuanjiKeep = sgs.CreateMaxCardsSkill{
	name = "#LuaQuanjiKeep", 
	extra_func = function(self, target) 
		if target:hasSkill(self:objectName()) then
			local powers = target:getPile("power")
			return powers:length()
		end
	end
}
LuaQuanjiRemove = sgs.CreateTriggerSkill{
	name = "#LuaQuanjiRemove", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventLoseSkill}, 
	on_trigger = function(self, event, player, data)
		local name = data:toString()
		if name == "LuaQuanji" then
			player:removePileByName("power")
		end
		return false
	end, 
	can_trigger = function(self, target)
		return (target ~= nil)
	end
}