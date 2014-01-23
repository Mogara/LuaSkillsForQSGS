--[[
	代码速查手册（Q区）
	技能索引：
		七星、戚乱、奇才、奇才、奇策、奇袭、千幻、谦逊、潜袭、潜袭、枪舞、强袭、巧变、巧说、琴音、青釭、青囊、倾城、倾国、倾国1V1、求援、驱虎、权计、权计、劝谏
]]--
--[[
	技能名：七星
	相关武将：神·诸葛亮
	描述：分发起始手牌时，共发你十一张牌，你选四张作为手牌，其余的面朝下置于一旁，称为“星”；摸牌阶段结束时，你可以用任意数量的手牌等量替换这些“星”。
	引用：LuaQixing、LuaQixingStart、LuaQixingAsk、LuaQixingClear
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
	技能名：戚乱
	相关武将：阵·何太后
	描述：每当一名角色的回合结束后，若你于本回合杀死至少一名角色，你可以摸三张牌。 
]]--
--[[
	技能名：奇才（锁定技）
	相关武将：标准·黄月英
	描述：你使用锦囊牌无距离限制。你装备区里除坐骑牌外的牌不能被其他角色弃置。
]]--
--[[
	技能名：奇才（锁定技）
	相关武将：怀旧-标准·黄月英-旧、SP·台版黄月英
	描述：你使用锦囊牌时无距离限制。
	引用：LuaNosQicai
	状态：1217验证通过
]]--
LuaNosQicai = sgs.CreateTargetModSkill{
	name = "LuaNosQicai" ,
	pattern = "TrickCard" ,
	distance_limit_func = function(self, from, card)
		if from:hasSkill(self:objectName()) then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：奇策
	相关武将：二将成名·荀攸
	描述：出牌阶段限一次，你可以将你的所有手牌（至少一张）当任意一张非延时锦囊牌使用。
]]--
--[[
	技能名：千幻
	相关武将：阵·于吉
	描述：每当一名角色受到伤害后，该角色可以将牌堆顶的一张牌置于你的武将牌上。每当一名角色被指定为基本牌或锦囊牌的唯一目标时，若该角色同意，你可以将一张“千幻牌”置入弃牌堆：若如此做，取消该目标。
]]--
--[[
	技能名：奇袭
	相关武将：标准·甘宁、SP·台版甘宁
	描述：你可以将一张黑色牌当【过河拆桥】使用。
	引用：LuaQixi
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
	相关武将：标准·陆逊、国战·陆逊
	描述：你不能被选择为【顺手牵羊】和【乐不思蜀】的目标。
	引用：LuaQianxun
	状态：1217验证通过
]]--
LuaQianxun = sgs.CreateProhibitSkill{
	name = "LuaQianxun",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Snatch") or card:isKindOf("Indulgence"))
	end
}
--[[
	技能名：潜袭
	相关武将：一将成名2012·马岱
	描述：准备阶段开始时，你可以进行一次判定，然后令一名距离为1的角色不能使用或打出与判定结果颜色相同的手牌，直到回合结束。
	引用：LuaQianxi、LuaQianxiClear
	状态：1217验证通过
]]--
LuaQianxi = sgs.CreateTriggerSkill{
	name = "LuaQianxi" ,
	events = {sgs.EventPhaseStart,sgs.FinishJudge} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player and player:isAlive() and player:hasSkill(self:objectName())) and (player:getPhase() == sgs.Player_Start) then
			if room:askForSkillInvoke(player, self:objectName()) then
			local judge = sgs.JudgeStruct()
				judge.reason = self:objectName()
				judge.play_animation = false
				judge.who = player
				room:judge(judge)
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if (judge.reason ~= self:objectName()) or (not player:isAlive()) then return false end
			local color
			if judge.card:isRed() then
				color = "red"
			else
				color = "black"
			end
			player:setTag(self:objectName(), sgs.QVariant(color))
			local to_choose = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:distanceTo(p)  == 1 then
					to_choose:append(p)
				end
			end
			if to_choose:isEmpty() then return false end
			local victim = room:askForPlayerChosen(player, to_choose, self:objectName())
			local pattern = ".|" .. color .. "|.hand$0"
			room:setPlayerFlag(victim, "LuaQianxiTarget")
			room:addPlayerMark(victim, "@qianxi_" .. color)
			room:setPlayerCardLimitation(victim, "use,response", pattern, false)
		end
		return false
	end ,
	can_trigger = function(self,target)
		return target
	end
}
LuaQianxiClear = sgs.CreateTriggerSkill{
	name = "#LuaQianxi-clear" ,
	events = {sgs.EventPhaseChanging, sgs.Death} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
		end
		local color = player:getTag("LuaQianxi"):toString()
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("LuaQianxiTarget") then
				room:removePlayerCardLimitation(p, "use,response", ".|" .. color .. ".|hand$0")
				room:setPlayerMark(p, "@qianxi_" .. color, 0)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return not (target:getTag("LuaQianxi"):toString() == "")
	end
}
--[[
	技能名：潜袭
	相关武将：怀旧-一将2·马岱-旧
	描述：每当你使用【杀】对距离为1的目标角色造成伤害时，你可以进行一次判定，若判定结果不为红桃，你防止此伤害，改为令其减1点体力上限。
	引用：LuaNosQianxi
	状态：1217验证通过
]]--
LuaNosQianxi = sgs.CreateTriggerSkill{
	name = "LuaNosQianxi" ,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if (player:distanceTo(damage.to) == 1) and damage.card and damage.card:isKindOf("Slash")
				and damage.by_user and (not damage.chain) and (not damage.transfer) then
			if player:askForSkillInvoke(self:objectName(), data) then
				local room = player:getRoom()
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = false
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				if judge:isGood() then
					room:loseMaxHp(damage.to)
					return true
				end
			end
		end
		return false
	end
}
--[[
	技能名：强袭
	相关武将：火·典韦
	描述：出牌阶段限一次，你可以失去1点体力或弃置一张武器牌，并选择你攻击范围内的一名角色，对其造成1点伤害。
	引用：LuaQiangxi
	状态：0610验证通过
]]--
LuaQiangxiCard = sgs.CreateSkillCard{
	name = "LuaQiangxiCard", 
	target_fixed = false, 
	will_throw = true,
	filter = function(self, targets, to_select) 
		if #targets ~= 0 then return false end
		local rangefix = 0
		if (not self:getSubcards():isEmpty()) and sgs.Self:getWeapon() and (sgs.Self:getWeapon():getId() == self:getSubcards():first()) then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - 1
		end
		return sgs.Self:distanceTo(to_select, rangefix) <= sgs.Self:getAttackRange()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if self:getSubcards():isEmpty() then room:loseHp(effect.from) end
		room:damage(sgs.DamageStruct("LuaQiangxi", effect.from, effect.to))
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
	技能名：枪舞
	相关武将：SP·星彩
	描述：出牌阶段限一次，你可以进行判定，直到回合结束，你使用点数比结果小的【杀】无距离限制，且你使用的点数比结果大的【杀】不计入限制的使用次数。
	引用：LuaQiangwu、LuaQiangwutarmod
	状态：1217验证通过
]]--
LuaQiangwucard = sgs.CreateSkillCard{
	name = "LuaQiangwu" ,
	target_fixed = true ,
	on_use = function(self, room, source)
		if source:getMark("LuaQiangwu") > 0 then
			room:askForUseCard(source, "Slash|.|"..(source:getMark("LuaQiangwu")+1).."~", "@LuaQiangwu", -1, sgs.Card_MethodUse, false)
		else
			local judge = sgs.JudgeStruct()
			judge.who = source
			judge.reason = "LuaQiangwu"
			judge.play_animation = false
			room:judge(judge)
		end
	end
}
LuaQiangwuvs = sgs.CreateZeroCardViewAsSkill{
	name = "LuaQiangwu" ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaQiangwu") or player:getMark("LuaQiangwu") > 0
	end ,
	view_as = function()
		return LuaQiangwucard:clone()
	end
}
LuaQiangwu = sgs.CreateTriggerSkill{
	name = "LuaQiangwu" ,
	view_as_skill = LuaQiangwuvs ,
	events = {sgs.FinishJudge, sgs.EventPhaseStart, sgs.PreCardUsed},
	can_trigger = function(self, player)
		return player
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == "LuaQiangwu" then
				room:setPlayerMark(player, "LuaQiangwu", judge.card:getNumber())
			end
		elseif event == sgs.EventPhaseStart then
			if (player:getPhase() == sgs.Player_NotActive) and (player:getMark("LuaQiangwu") > 0) then
				room:setPlayerMark(player, "LuaQiangwu", 0)
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and (player:getMark("LuaQiangwu") > 0) 
					and (use.card:getNumber() > player:getMark("LuaQiangwu")) then
				if (use.m_addHistory) then
					room:addPlayerHistory(player, use.card:getClassName(), -1)
					use.m_addHistory = false
					data:setValue(use)
				end
			end
		end
		return false
	end ,
}
LuaQiangwutarmod = sgs.CreateTargetModSkill{
	name = "#LuaQiangwu-tarmod" ,
	distance_limit_func = function(self, player, card)
		local n = player:getMark("LuaQiangwu")
		if (n > 0) and (n > card:getNumber()) and (card:getNumber() ~= 0) then
			return 998
		end
		return 0
	end
}
--[[
	技能名：巧变
	相关武将：山·张郃
	描述：你可以弃置一张手牌，跳过你的一个阶段（回合开始和回合结束阶段除外），若以此法跳过摸牌阶段，你获得其他至多两名角色各一张手牌；若以此法跳过出牌阶段，你可以将一名角色装备区或判定区里的一张牌移动到另一名角色区域里的相应位置。
	引用：LuaQiaobian
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
	name = "LuaQiaobian",
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
	技能名：巧说
	相关武将：一将成名2013·简雍
	描述：出牌阶段开始时，你可以与一名角色拼点：若你赢，本回合你使用的下一张基本牌或非延时类锦囊牌可以增加一个额外目标（无距离限制）或减少一个目标（若原有多余一个目标）；若你没赢，你不能使用锦囊牌，直到回合结束。
	引用：LuaQiaoshui、LuaQiaoshuiTargetMod、LuaQiaoshuiUse
	状态：1217验证通过
]]--
---------------------Ex借刀杀人技能卡---------------------
function targetsTable2QList(thetable)
	local theqlist = sgs.PlayerList()
	for _, p in ipairs(thetable) do
		theqlist:append(p)
	end
	return theqlist
end
LuaExtraCollateralCard = sgs.CreateSkillCard{
	name = "LuaExtraCollateralCard" ,
	filter = function(self, targets, to_select)
		local coll = sgs.Card_Parse(sgs.Self:property("extra_collateral"):toString())
		if (not coll) then return false end
		local tos = sgs.Self:property("extra_collateral_current_targets"):toString():split("+")
		if (#targets == 0) then
			return (not table.contains(tos, to_select:objectName())) 
					and (not sgs.Self:isProhibited(to_select, coll)) and coll:targetFilter(targetsTable2QList(targets), to_select, sgs.Self)
		else
			return coll:targetFilter(targetsTable2QList(targets), to_select, sgs.Self)
		end
	end ,
	about_to_use = function(self, room, cardUse)
		local killer = cardUse.to:first()
		local victim = cardUse.to:last()
		killer:setFlags("ExtraCollateralTarget")
		local _data = sgs.QVariant()
		_data:setValue(victim)
		killer:setTag("collateralVictim", _data)
	end
}
----------------------------------------------------------
LuaQiaoshuiCard = sgs.CreateSkillCard{
	name = "LuaQiaoshuiCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "LuaQiaoshui", nil)
		if (success) then
			source:setFlags("LuaQiaoshuiSuccess")
		else
			room:setPlayerCardLimitation(source, "use", "TrickCard", true)
		end
	end
}
LuaQiaoshuiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaQiaoshui" ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@LuaQiaoshui")
	end ,
	view_as = function()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if string.find(pattern, "!") then
			return LuaExtraCollateralCard:clone()
		else
			return LuaQiaoshuiCard:clone()
		end
	end
}
LuaQiaoshui = sgs.CreatePhaseChangeSkill{
	name = "LuaQiaoshui" ,
	view_as_skill = LuaQiaoshuiVS ,
	on_phasechange = function(self, jianyong)
		if (jianyong:getPhase() == sgs.Player_Play) and (not jianyong:isKongcheng()) then
			local room = jianyong:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(jianyong)
			for _, player in sgs.qlist(other_players) do
				if not player:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if (can_invoke) then
				room:askForUseCard(jianyong, "@@LuaQiaoshui", "@qiaoshui-card", 1)
			end
		end
		return false
	end ,
}
LuaQiaoshuiUse = sgs.CreateTriggerSkill{
	name = "#LuaQiaoshui-use" ,
	events = {sgs.PreCardUsed} ,
	on_trigger = function(self, event, jianyong, data)
		if not jianyong:hasFlag("LuaQiaoshuiSuccess") then return false end
		local use = data:toCardUse()
		if (use.card:isNDTrick() or use.card:isKindOf("BasicCard")) then
			local room = jianyong:getRoom()
			jianyong:setFlags("-LuaQiaoshuiSuccess")
			if (sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY) then return false end
			local available_targets = sgs.SPlayerList()
			if (not use.card:isKindOf("AOE")) and (not use.card:isKindOf("GlobalEffect")) then
				room:setPlayerFlag(jianyong, "LuaQiaoshuiExtraTarget")
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (use.to:contains(p) or room:isProhibited(jianyong, p, use.card)) then continue end
					if (use.card:targetFixed()) then
						if (not use.card:isKindOf("Peach")) or (p:isWounded()) then
							available_targets:append(p)
						end
					else
						if (use.card:targetFilter(sgs.PlayerList(), p, jianyong)) then
							available_targets:append(p)
						end
					end
				end
				room:setPlayerFlag(jianyong, "-LuaQiaoshuiExtraTarget")
			end
			local choices = {}
			table.insert(choices, "cancel")
			if (use.to:length() > 1) then table.insert(choices, 1, "remove") end
			if (not available_targets:isEmpty()) then table.insert(choices, 1, "add") end
			if #choices == 1 then return false end
			local choice = room:askForChoice(jianyong, "LuaQiaoshui", table.concat(choices, "+"), data)
			if (choice == "cancel") then
				return false
			elseif choice == "add" then
				local extra = nil
				if not use.card:isKindOf("Collateral") then
					extra = room:askForPlayerChosen(jianyong, available_targets, "LuaQiaoshui", "@qiaoshui-add:::" .. use.card:objectName())
				else
					local tos = {}
					for _, t in sgs.qlist(use.to) do
						table.insert(tos, t:objectName())
					end
					room:setPlayerProperty(jianyong, "extra_collateral", sgs.QVariant(use.card:toString()))
					room:setPlayerProperty(jianyong, "extra_collateral_current_targets", sgs.QVariant(table.concat(tos, "+")))
					room:askForUseCard(jianyong, "@@LuaQiaoshui!", "@qiaoshui-add:::collateral")
					room:setPlayerProperty(jianyong, "extra_collateral", sgs.QVariant(""))
					room:setPlayerProperty(jianyong, "extra_collateral_current_targets", sgs.QVariant("+"))
					for _, p in sgs.qlist(room:getOtherPlayers(jianyong)) do
						if p:hasFlag("ExtraCollateralTarget") then
							p:setFlags("-ExtraColllateralTarget")
							extra = p
							break
						end
					end
					if (extra == nil) then
						extra = available_targets:at(math.random(available_targets:length()) - 1)
						local victims = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(extra)) do
							if (extra:canSlash(p) and not (p:objectName() == jianyong:objectName() and p:hasSkill("kongcheng") and p:isLastHandCard(use.card, true))) then
								victims:append(p)
							end
						end
						assert(not victims:isEmpty())
						local _data = sgs.QVariant()
						_data:setValue(victims:at(math.random(victims:length()) - 1))
						extra:setTag("collateralVictim", _data)
					end
				end
				use.to:append(extra)
				room:sortByActionOrder(use.to)
			else
				local removed = room:askForPlayerChosen(jianyong, use.to, "LuaQiaoshui", "@qiaoshui-remove:::" .. use.card:objectName())
				use.to:removeOne(removed)
			end
		end
		data:setValue(use)
		return false
	end ,
}
LuaQiaoshuiTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaQiaoshui-target" ,
	pattern = "Slash,TrickCard+^DelayedTrick" ,
	distance_limit_func = function(self, from)
		if (from:hasFlag("LuaQiaoshuiExtraTarget")) then
			return 1000
		end
		return 0
	end
}

--[[
	技能名：琴音
	相关武将：神·周瑜
	描述：当你于弃牌阶段内弃置了两张或更多的手牌后，你可以令所有角色各回复1点体力或各失去1点体力。每阶段限一次。
	引用：LuaQinyin
	状态：1217验证通过
]]--	
LuaQinyin = sgs.CreateTriggerSkill{
	name = "LuaQinyin" ,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Discard then return false end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from:objectName() == player:objectName()) and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				player:setMark("LuaQinyin", player:getMark("LuaQinyin") + move.card_ids:length())
				if (not player:hasFlag("LuaQinyinUsed")) and (player:getMark("LuaQinyin") >= 2) then
					if player:askForSkillInvoke(self:objectName()) then
						player:setFlags("LuaQinyinUsed")
		local result = room:askForChoice(player, "LuaQinyin", "up+down")
		local all_players = room:getAllPlayers()
		if result == "up" then
			for _, player in sgs.qlist(all_players) do
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
		end
		elseif result == "down" then
			for _, player in sgs.qlist(all_players) do
				room:loseHp(player)
				end
			end
		end
	end
end
		elseif event == sgs.EventPhaseStart then
			player:setMark("qinyin", 0)
			player:setFlags("-QinyinUsed")
		end
	end
}
--[[
	技能名：青釭
	相关武将：长坂坡·神赵云
	描述：你每造成1点伤害，你可以让目标选择弃掉一张手牌或者让你从其装备区获得一张牌。
]]--
--[[
	技能名：青囊
	相关武将：标准·华佗
	描述： 出牌阶段限一次，你可以弃置一张手牌并选择一名已受伤的角色，令该角色回复1点体力。
	引用：LuaQingnang
	状态：0610验证通过
]]--
LuaQingnangCard = sgs.CreateSkillCard{
	name = "LuaQingnangCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:isWounded())
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
		return player:canDiscard(player, "h") and (not player:hasUsed("#LuaQingnangCard"))
	end
}

--[[
	技能名：倾城
	相关武将：国战·邹氏
	描述：出牌阶段，你可以弃置一张装备牌，令一名其他角色的一项武将技能无效，直到其下回合开始。
	状态：尚未完成
]]--
LuaXQingchengCard = sgs.CreateSkillCard{--倾城
	name = "LuaXQingchengCard",
	will_throw = false,
	handling_method = sgs.Card_MethodDiscard,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local skill_list = {}
		local skills = effect.to:getVisibleSkillList()
		for _,skill in sgs.qlist(skills) do
			if not table.contains(skill_list, skill:objectName()) then
				if not skill:inherits("SPConvertSkill") then
					if not skill:isAttachedLordSkill() then
						table.insert(skill_list, skill:objectName())
					end
				end
			end
		end
		local skill_qc
		if #skill_list > 0 then
			local ai_data = sgs.QVariant()
			ai_data:setValue(effect.to)
			local choices = table.concat(skill_list, "+")
			skill_qc = room:askForChoice(effect.from, "LuaXQingcheng", choices, ai_data)
		end
		room:throwCard(self, effect.from)
		if skill_qc ~= "" then
			local card_ids = {}--用了“Table”的办法，应该没什么Bug...
			table.insert(card_ids, skill_qc)
			local card_id = table.concat(card_ids, "+")
			effect.to:setTag("QingchengList", sgs.QVariant(card_id))
			local mark = "Qingcheng"..skill_qc
			room:setPlayerMark(effect.to, mark, 1)
			local cards = effect.to:getCards("he")
			room:filterCards(effect.to, cards, true)
		end
	end
}
LuaXQingchengVS = sgs.CreateViewAsSkill{
	name = "LuaXQingcheng",
	n = 1,
	view_filter = function(self, selected, to_select)
		if to_select:isKindOf("EquipCard") then
			return not sgs.Self:isJilei(to_select)
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local first = LuaXQingchengCard:clone()
			first:addSubcard(cards[1])
			first:setSkillName(self:objectName())
			return first
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isNude()
	end
}
LuaXQingcheng = sgs.CreateTriggerSkill{
	name = "LuaXQingcheng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaXQingchengVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_RoundStart then
			local guzhu_list = player:getTag("QingchengList"):toString()
			guzhu_list = guzhu_list:split("+")
			for _,id in ipairs(guzhu_list) do
				local mark = "Qingcheng"..id
				room:setPlayerMark(player, mark, 0)
			end
			player:setTag("QingchengList", sgs.QVariant())
			local cards = player:getCards("he")
			room:filterCards(player, cards, false)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 4
}
--[[
	技能名：倾国
	相关武将：标准·甄姬、SP·甄姬、SP·台版甄姬
	描述：你可以将一张黑色手牌当【闪】使用或打出。
	引用：LuaQingguo
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
	技能名：倾国1V1
	相关武将：1v1·甄姬1v1
	描述：你可以将一张装备区的装备牌当【闪】使用或打出。
	引用：Lua1V1Qingguo
	状态：验证通过
]]--
Lua1V1Qingguo = sgs.CreateViewAsSkill{
	name = "Lua1V1Qingguo",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local jink = sgs.Sanguosha:cloneCard("jink",cards[1]:getSuit(),cards[1]:getNumber())
			jink:setSkillName(self:objectName())
			jink:addSubcard(cards[1]:getId())
		return jink
end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "jink" and not player:getEquips():isEmpty()
	end
}
--[[
	技能名：求援
	相关武将：一将成名2013·伏皇后
	描述：每当你成为【杀】的目标时，你可以令一名除此【杀】使用者外的有手牌的其他角色正面朝上交给你一张手牌。若此牌不为【闪】，该角色也成为此【杀】的目标。
	引用：LuaQiuyuan
	状态：1217验证通过
]]--
LuaQiuyuan = sgs.CreateTriggerSkill{
	name = "LuaQiuyuan" ,
	events = {sgs.TargetConfirming} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			local room = player:getRoom()
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if (not p:isKongcheng()) and (p:objectName() ~= use.from:objectName()) then
					targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "qiuyuan-invoke", true, true)
			if target then
				local card = nil
				if target:getHandcardNum() > 1 then
					card = room:askForCard(target, ".!", "@qiuyuan-give:" .. player:objectName(), data, sgs.Card_MethodNone)
					if not card then
						card = target:getHandcards():at(math.random(0, target:getHandcardNum() - 1))
					end
				else
					card = target:getHandcards():first()
				end
				player:obtainCard(card)
				room:showCard(player, card:getEffectiveId())
				if not card:isKindOf("Jink") then
					if use.from:canSlash(target, use.card, false) then
						use.to:append(target)
						room:sortByActionOrder(use.to)
						data:setValue(use)
						room:getThread():trigger(sgs.TargetConfirming, room, target, data)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：驱虎
	相关武将：火·荀彧
	描述：出牌阶段限一次，你可以与一名当前的体力值大于你的角色拼点：若你赢，其对其攻击范围内你选择的另一名角色造成1点伤害。若你没赢，其对你造成1点伤害。
	引用：LuaQuhu
	状态：0610验证通过
]]--
LuaQuhuCard = sgs.CreateSkillCard{
	name = "LuaQuhuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:getHp() > sgs.Self:getHp()) and (not to_select:isKongcheng())
	end,
	on_use = function(self, room, source, targets)
		local tiger = targets[1]
		local success = source:pindian(tiger, self:objectName(), nil)
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
			local wolf = room:askForPlayerChosen(source, wolves, self:objectName(), "@quhu-damage:" .. tiger:objectName())
			room:damage(sgs.DamageStruct(self:objectName(), tiger, wolf))
		else
			room:damage(sgs.DamageStruct(self:objectName(), tiger, source))
		end
	end
}
LuaQuhu = sgs.CreateViewAsSkill{
	name = "LuaQuhu",
	n = 0,
	view_as = function()
		return LuaQuhuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#LuaQuhuCard")) and (not player:isKongcheng())
	end
}

--[[
	技能名：权计
	相关武将：一将成名·钟会
	描述：每当你受到1点伤害后，你可以摸一张牌，然后将一张手牌置于你的武将牌上，称为“权”；每有一张“权”，你的手牌上限便+1。
	引用：LuaQuanji、LuaQuanjiKeep、LuaQuanjiRemove
	状态：0610验证通过
]]--
LuaQuanji = sgs.CreateTriggerSkill{
	name = "LuaQuanji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		local x = damage.damage
		for i = 0, x - 1, 1 do
			if player:askForSkillInvoke(self:objectName()) then
				room:drawCards(player, 1)
				if not player:isKongcheng() then
					local card_id
					if player:getHandcardNum() == 1 then
						card_id = player:handCards():first()
					else
						card_id = room:askForExchange(player, self:objectName(), 1, false, "QuanjiPush"):getSubcards():first()
					end
					player:addToPile("power", card_id)
				end
			end
		end
	end
}
LuaQuanjiKeep = sgs.CreateMaxCardsSkill{
	name = "#LuaQuanji-keep",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getPile("power"):length()
		else
			return 0
		end
	end
}
LuaQuanjiRemove = sgs.CreateTriggerSkill{
	name = "#LuaQuanjiRemove",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaQuanji" then
			player:clearOnePrivatePile("power")
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：权计
	相关武将：胆创·钟会
	描述：其他角色的回合开始时，你可以与该角色进行一次拼点。若你赢，该角色跳过回合开始阶段及判定阶段。
]]--
--[[
	技能名：劝谏
	相关武将：3D织梦·沮授
	描述：出牌阶段，你可以交给一名其他角色一张【闪】，展示其一张手牌：若为【闪】，则你与该角色各摸一张牌。每阶段限一次。
]]--
