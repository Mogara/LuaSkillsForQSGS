--[[
	代码速查手册（X区）
	技能索引：
		惜粮、陷嗣、陷阵、享乐、枭姬、枭姬、骁果、骁袭、孝德、挟缠、心战、新生、星舞、行殇、雄异、修罗、旋风、旋风、眩惑、眩惑、雪恨、血祭、血裔、恂恂、迅猛、殉志
]]--
--[[
	技能名：惜粮
	相关武将：倚天·张公祺
	描述：你可将其他角色弃牌阶段弃置的红牌收为“米”或加入手牌
	引用：LuaXiliang
	状态：1217验证通过
]]--
LuaXiliang = sgs.CreateTriggerSkill{
	name = "LuaXiliang" ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Discard then return false end
		local zhanglu = room:findPlayerBySkillName(self:objectName())
		if not zhanglu then return false end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName()
				and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
			for _, id in sgs.qlist(move.card_ids) do
				local c = sgs.Sanguosha:getCard(id)
				if (room:getCardPlace(id) == sgs.Player_DiscardPile) and c:isRed() then dummy:addSubcard(id) end
			end
		end
		if dummy:subcardsLength() == 0 then return false end
		if not zhanglu:askForSkillInvoke(self:objectName(), data) then return false end
		local canput = (5 - zhanglu:getPile("rice"):length() >= dummy:subcardsLength())
		if canput then
			if room:askForChoice(zhanglu, self:objectName(), "put+obtain") == "put" then
				zhanglu:addToPile("rice", dummy)
			else
				zhanglu:obtainCard(dummy)
			end
		else
			zhanglu:obtainCard(dummy)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (not target:hasSkill(self:objectName()))
	end
}
--[[
	技能名：陷嗣
	相关武将：一将成名2013·刘封
	描述：准备阶段开始时，你可以将一至两名角色的各一张牌置于你的武将牌上，称为“逆”。其他角色可以将两张“逆”置入弃牌堆，视为对你使用一张【杀】。
	引用：LuaXiansi LuaXiansiAttach LuaXiansiSlash（技能暗将）
	状态：1217验证通过
]]--
LuaXiansiCard = sgs.CreateSkillCard{
	name = "LuaXiansiCard", 
	target_fixed = false,
	filter = function(self, targets, to_select) 
		return #targets < 2 and not to_select:isNude()
	end,
	on_effect = function(self, effect) 
		if effect.to:isNude() then return end
		local id = effect.from:getRoom():askForCardChosen(effect.from, effect.to, "he", "LuaXiansi")
		effect.from:addToPile("counter", id)
	end,
}

LuaXiansiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaXiansi",
	response_pattern = "@@LuaXiansi",
	view_as = function(self) 
		return LuaXiansiCard:clone()
	end, 
}

LuaXiansi = sgs.CreateTriggerSkill{
	name = "LuaXiansi", 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = LuaXiansiVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			player:getRoom():askForUseCard(player, "@@LuaXiansi", "@xiansi-card")
		end
	end,
}

LuaXiansiAttach = sgs.CreateTriggerSkill{
	name = "#LuaXiansiAttach", 
	events = {sgs.TurnStart,sgs.EventAcquireSkill,sgs.EventLoseSkill}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local source = room:findPlayerBySkillName("LuaXiansi")
		if event == sgs.TurnStart then
			if (event == sgs.TurnStart and source and source:isAlive()) or (event == sgs.EventAcquireSkill and data:toString() == "LuaXiansi") then
				for _,p in sgs.qlist(room:getOtherPlayers(source))do
					if not p:hasSkill("LuaXiansiSlash") then
						room:attachSkillToPlayer(p,"LuaXiansiSlash")
					end
				end
			end
		elseif event == sgs.EventLoseSkill and data:toString() == "LuaXiansi"then
			for _,p in sgs.qlist(room:getOtherPlayers(player))do
				if p:hasSkill("LuaXiansiSlash") then
					room:detachSkillFromPlayer(p, "LuaXiansiSlash", true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

LuaXiansiSlashCard = sgs.CreateSkillCard{
	name = "LuaXiansiSlashCard", 
	target_fixed = false,
	filter = function(self, targets, to_select) 
		return to_select:hasSkill("LuaXiansi") and to_select:getPile("counter"):length() >1 and sgs.Self:canSlash(to_select,nil)
	end,
	on_validate = function(self,carduse)
		local source = carduse.from
		local target = carduse.to:first()
		local room = source:getRoom()
		local dummy = sgs.Sanguosha:cloneCard("jink")
		if target:getPile("counter"):length() == 2 then
			dummy:addSubcard(target:getPile("counter"):first())
			dummy:addSubcard(target:getPile("counter"):last())
		else
			local ids = target:getPile("counter")
			for i = 0,1,1 do
				room:fillAG(ids, source);
				local id = room:askForAG(source, ids, false, "LuaXiansi");
				dummy:addSubcard(id);
				ids:removeOne(id);
				room:clearAG(source)
			end
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "LuaXiansi", "");
		room:throwCard(dummy, reason, nil);
		if source:canSlash(target, nil, false) then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName("_LuaXiansi")
			return slash
		end
	end,
}
function canSlashLiufeng (player)
	local liufeng = nil;
	for _,p in sgs.qlist(player:getAliveSiblings()) do
		if (p:hasSkill("LuaXiansi") and p:getPile("counter"):length() > 1) then
			liufeng = p;
			break;
		end
	end
	if liufeng == nil then return false end
	local slash = sgs.Sanguosha:cloneCard("slash")
	return slash:targetFilter(sgs.PlayerList(), liufeng, player);
end

LuaXiansiSlash = sgs.CreateZeroCardViewAsSkill{
	name = "LuaXiansiSlash",
	view_as = function(self) 
		return LuaXiansiSlashCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and canSlashLiufeng(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return  pattern == "slash"and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			   and canSlashLiufeng(player)
	end,
}
--[[
	技能名：陷阵
	相关武将：一将成名·高顺
	描述：出牌阶段限一次，你可以与一名其他角色拼点：若你赢，你获得以下技能：本回合，该角色的防具无效，你无视与该角色的距离，你对该角色使用【杀】无数量限制；若你没赢，你不能使用【杀】，直到回合结束。
	引用：LuaXianzhen
	状态：1217验证通过
]]--
LuaXianzhenCard = sgs.CreateSkillCard{
	name = "LuaXianzhenCard", 
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng();
	end,
	on_effect = function(self, effect) 
		local room = effect.from:getRoom();
		if effect.from:pindian(effect.to, "LuaXianzhen",nil) then
			local target = effect.to
			local data = sgs.QVariant()
			data:setValue(target)
			effect.from:setTag("XianzhenTarget",data) 
			room:setPlayerFlag(effect.from, "XianzhenSuccess");
			local assignee_list = effect.from:property("extra_slash_specific_assignee"):toString():split("+")
			table.insert(assignee_list,target:objectName())
			room:setPlayerProperty(effect.from, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
			room:setFixedDistance(effect.from, effect.to, 1);
			room:addPlayerMark(effect.to, "Armor_Nullified");
		else
			room:setPlayerCardLimitation(effect.from, "use", "Slash", true);
		end
	end,
}

LuaXianzhenVs = sgs.CreateZeroCardViewAsSkill{
	name = "LuaXianzhen",
	view_as = function(self) 
		return LuaXianzhenCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#LuaXianzhenCard")) and (not player:isKongcheng())
	end, 
}

LuaXianzhen = sgs.CreateTriggerSkill{
	name = "LuaXianzhen",  
	events = {sgs.EventPhaseChanging,sgs.Death}, 
	view_as_skill = LuaXianzhenVs,
	on_trigger = function(self, event, gaoshun, data)
		if (triggerEvent == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		end
		local room = gaoshun:getRoom()
		local target = gaoshun:getTag("XianzhenTarget"):toPlayer()
		if (triggerEvent == sgs.Death) then
			local death = data:toDeath()
			if death.who:objectName() ~= gaoshun:objectName() then
				if death.who:objectName() == target:objectName() then
					room:setFixedDistance(gaoshun, target, -1);
					gaoshun:removeTag("XianzhenTarget");
					room:setPlayerFlag(gaoshun, "-XianzhenSuccess");
				end
				return false;
			end
		end
		if target then
			local assignee_list = gaoshun:property("extra_slash_specific_assignee"):toString():split("+")
			table.removeOne(assignee_list,target:objectName())
			room:setPlayerProperty(gaoshun, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")));
			room:setFixedDistance(gaoshun, target, -1);
			gaoshun:removeTag("XianzhenTarget");
			room:removePlayerMark(target, "Armor_Nullified");
		end
		return false;
	end,
	can_trigger = function(self, target)
		return target and target:getTag("XianzhenTarget"):toPlayer()
	end,
}
--[[
	技能名：享乐（锁定技）
	相关武将：山·刘禅
	描述：当其他角色使用【杀】指定你为目标时，需弃置一张基本牌，否则此【杀】对你无效。
	引用：LuaXiangle
	状态：1217验证通过
]]--
LuaXiangle = sgs.CreateTriggerSkill{
	name = "LuaXiangle" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.SlashEffected, sgs.TargetConfirming} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				player:setMark("LuaXiangle", 0)
				local dataforai = sgs.QVariant()
				dataforai:setValue(player)
				if not player:getRoom():askForCard(use.from,".Basic","@xiangle-discard",dataforai) then
					player:addMark("LuaXiangle")
				end
			end
		else
			local effect= data:toSlashEffect()
			if player:getMark("LuaXiangle") > 0 then
				player:removeMark("LuaXiangle")
				return true
			end
		end
	end
}
--[[
	技能名：枭姬
	相关武将：标准·孙尚香、SP·孙尚香、JSP·孙尚香
	描述：每当你失去一张装备区的装备牌后，你可以摸两张牌。 

	引用：LuaXiaoji
	状态：0405证通过
]]--

LuaXiaoji = sgs.CreateTriggerSkill{
	name = "LuaXiaoji" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
			for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				if move.from_places:at(i) == sgs.Player_PlaceEquip then
					if room:askForSkillInvoke(player, self:objectName()) then
						player:drawCards(2)
					else
						break
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：枭姬
	相关武将：1v1·孙尚香1v1
	描述：每当你失去一张装备区的装备牌后，你可以选择一项：摸两张牌，或回复1点体力。
	引用：Lua1V1Xiaoji
	状态：1217验证通过
]]--
Lua1V1Xiaoji = sgs.CreateTriggerSkill{
	name = "Lua1V1Xiaoji" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and (move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceEquip) then
			for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				if move.from_places:at(i) == sgs.Player_PlaceEquip then
					local choices = {}
					table.insert(choices, "draw")
					table.insert(choices, "cancel") 
					if player:isWounded() then
						table.insert(choices, "recover") 
					end
					local choice
					if #choices == 1 then
						choice = choices[1]
					else
						choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
					end
					if choice == "recover" then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
					elseif choice == "draw" then
						player:drawCards(2)
					else
						break
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：骁果
	相关武将：国战·乐进、SP乐进
	描述：其他角色的结束阶段开始时，你可以弃置一张基本牌：若如此做，该角色选择一项：1.弃置一张装备牌，然后令你摸一张牌；2.受到1点伤害。 
	引用：LuaXiaoguo
	状态：0405验证通过
]]--
LuaXiaoguo = sgs.CreateTriggerSkill{
	name = "LuaXiaoguo" ,
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Finish then return false end
		local yuejin = room:findPlayerBySkillName(self:objectName())
		if not yuejin or yuejin:objectName() == player:objectName() then return false end
		if yuejin:canDiscard(yuejin, "h") and room:askForCard(yuejin, ".Basic", "@xiaoguo", sgs.QVariant(), self:objectName()) then
			if not room:askForCard(player, ".Equip", "@xiaoguo-discard", sgs.QVariant()) then
				room:damage(sgs.DamageStruct(self:objectName(), yuejin, player))
			else--如果是写国战·骁果的话这一行和下一行删除
				yuejin:drawCards(1, self:objectName())
			end
		end
		return false
	end
}
--[[
	技能名：骁袭
	相关武将：1v1·马超1v1
	描述：你登场时，你可以视为使用一张【杀】。
	引用：LuaXiaoxi
	状态：1217验证通过
]]--
LuaXiaoxi = sgs.CreateTriggerSkill{
	name = "LuaXiaoxi",
	events = {sgs.Debut},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local opponent = player:getNext()
		if not opponent:isAlive() then
			return false
		end
		local aSlash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		aSlash:setSkillName(self:objectName())
		if not aSlash:isAvailable(player) or not player:canSlash(opponent, nil) then
			aSlash = nil
			return false
		end
		if player:askForSkillInvoke(self:objectName()) then
			room:useCard(sgs.CardUseStruct(aSlash, player, opponent), false)
			return false
		end
	end
}
--[[
	技能名：孝德
	相关武将：SP·夏侯氏
	描述：每当一名其他角色死亡结算后，你可以拥有该角色武将牌上的一项技能（除主公技与觉醒技），且“孝德”无效，直到你的回合结束时。每当你失去“孝德”后，你失去以此法获得的技能。 
	引用：LuaXiaode, LuaXiaoEx
	状态：1217验证通过
]]--
function addSkillList(general)
	if not general then return nil end
	local skill_list = {}
	for _, skill in sgs.qlist(general:getSkillList()) do
		if skill:isVisible() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake then
			table.insert(skill_list, skill:objectName())
		end
	end
	return table.concat(skill_list, "+")
end
LuaXiaode = sgs.CreateTriggerSkill{
	name = "LuaXiaode" ,
	events = {sgs.BuryVictim} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local xiahoushi = room:findPlayerBySkillName(self:objectName())
		if not xiahoushi or xiahoushi:getTag("LuaXiaodeSkill"):toString() ~= "" then return false end
		local skill_list = xiahoushi:getTag("LuaXiaodeVictimSkills"):toString():split("+")
		if #skill_list == 0 then return false end
		if not room:askForSkillInvoke(xiahoushi, self:objectName()) then return false end
		local skill_name = room:askForChoice(xiahoushi, self:objectName(), table.concat(skill_list, "+"))
		xiahoushi:setTag("LuaXiaodeSkill", sgs.QVariant(skill_name))
		room:acquireSkill(xiahoushi, skill_name)
			return false
	end ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	priority = -2
}
LuaXiaodeEx = sgs.CreateTriggerSkill{
	name = "#LuaXiaode" ,
	events = {sgs.EventPhaseChanging, sgs.EventLoseSkill, sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local skill_name = player:getTag("LuaXiaodeSkill"):toString()
				if skill_name ~= "" then
					room:detachSkillFromPlayer(player, skill_name, false, true)
							player:setTag("LuaXiaodeSkill", sgs.QVariant())
				end
			end
		elseif event == sgs.EventLoseSkill and data:toString() == sef:objectName() then
			local skill_name = player:getTag("LuaXiaodeSkill"):toString()
			if skill_name ~= "" then
				room:detachSkillFromPlayer(player, skill_name, false, true)
						player:setTag("LuaXiaodeSkill", sgs.QVariant())
			end
		elseif event == sgs.Death and self:triggerable(player) then
			local death = data:toDeath()
			local skill_list = {}
			table.insert(skill_list, addSkillList(death.who:getGeneral()))
			table.insert(skill_list, addSkillList(death.who:getGeneral2()))
			player:setTag("LuaXiaodeVictimSkills", sgs.QVariant(table.concat(skill_list, "+")))
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--[[
	技能名：挟缠（限定技）
	相关武将：1v1·许褚1v1
	描述：出牌阶段，你可以与对手拼点：若你赢，视为你对对手使用一张【决斗】；若你没赢，视为对手对你使用一张【决斗】。
	引用：LuaXiechan
	状态：1217验证通过
]]--
LuaXiechanCard = sgs.CreateSkillCard{
	name = "LuaXiechanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() 
	end,
	on_use = function(self, room, xuchu, targets)
		room:removePlayerMark(xuchu,"@twine")
		local succes = xuchu:pindian(targets[1], "LuaXiechan")
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName("LuaXiechan")
		local from, to = nil, nil
		if succes then
			from = xuchu
			to = targets[1]
		else
			from = targets[1]
			to = xuchu
		end
		if not from:isLocked(duel) and not from:isProhibited(to, duel) then
			room:useCard(sgs.CardUseStruct(duel,from, to))
		end
	end
}
LuaXiechanVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaXiechan",
	view_as = function(self, cards)
		return LuaXiechanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@twine") >= 1 and not player:isKongcheng()
	end
}
LuaXiechan = sgs.CreateTriggerSkill{
	name = "LuaXiechan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@twine",
	events = {sgs.GameStart},
	view_as_skill = LuaXiechanVS,
	on_trigger = function()
		return false
	end
}
--[[
	技能名：心战
	相关武将：一将成名·马谡
	描述：出牌阶段，若你的手牌数大于你的体力上限，你可以：观看牌堆顶的三张牌，然后亮出其中任意数量的红桃牌并获得之，其余以任意顺序置于牌堆顶。每阶段限一次。
	引用：LuaXinzhan
	状态：1217验证通过
]]--
LuaXinzhanCard = sgs.CreateSkillCard{
	name = "LuaXinzhanCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		local cards = room:getNCards(3)
		local left = cards
		local hearts = sgs.IntList()
		local non_hearts = sgs.IntList()
		for _, card_id in sgs.qlist(cards) do
			local card = sgs.Sanguosha:getCard(card_id)
			if card:getSuit() == sgs.Card_Heart then
				hearts:append(card_id)
			else
				non_hearts:append(card_id)
			end
		end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if not hearts:isEmpty() then
			repeat
				room:fillAG(left, source, non_hearts)
				local card_id = room:askForAG(source, hearts, true, "LuaXinzhan")
				if (card_id == -1) then
					room:clearAG(source)
					break
				end
				hearts:removeOne(card_id)
				left:removeOne(card_id)
				dummy:addSubcard(card_id)
				room:clearAG(source)
			until hearts:isEmpty()
			if dummy:subcardsLength() > 0 then
				room:doBroadcastNotify(56, tostring(room:getDrawPile():length() + dummy:subcardsLength()))
				source:obtainCard(dummy)
				for _, id in sgs.qlist(dummy:getSubcards()) do
					room:showCard(source, id)
				end
			end
		end
		if not left:isEmpty() then
			room:askForGuanxing(source, left, sgs.Room_GuanxingUpOnly)
		end
	end ,
}
LuaXinzhan = sgs.CreateViewAsSkill{
	name = "LuaXinzhan" ,
	n = 0,
	view_as = function()
		return LuaXinzhanCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#LuaXinzhanCard")) and (player:getHandcardNum() > player:getMaxHp())
	end
}
--[[
	技能名：新生
	相关武将：山·左慈
	描述：每当你受到1点伤害后，你可以获得一张“化身牌”。
	引用：LuaXinSheng
	状态：1217验证通过
	备注：需调用ChapterH 的acquireGenerals 函数
]]--
LuaXinSheng = sgs.CreateTriggerSkill{
	name = "LuaXinSheng",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			AcquireGenerals(player, data:toDamage().damage) --需调用ChapterH 的acquieGenerals 函数
		end
	end
}
--[[
	技能名：星舞
	相关武将：SP·大乔&小乔
	描述：弃牌阶段开始时，你可以将一张与你本回合使用的牌颜色均不同的手牌置于武将牌上。
		若你有三张“星舞牌”，你将其置入弃牌堆，然后选择一名男性角色，你对其造成2点伤害并弃置其装备区的所有牌。
	引用：LuaXingwu
	状态：1217验证通过
]]--
LuaXingwu = sgs.CreateTriggerSkill{
	name = "LuaXingwu" ,
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseStart, sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.PreCardUsed) or (event == sgs.CardResponded) then
			local card = nil
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and (card:getTypeId() ~= sgs.Card_TypeSkill) and (card:getHandlingMethod() == sgs.Card_MethodUse) then
				local n = player:getMark(self:objectName())
				if card:isBlack() then
					n = bit32.bor(n, 1)
				elseif card:isRed() then
					n = bit32.bor(n, 2)
				end
				player:setMark(self:objectName(), n)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				local n = player:getMark(self:objectName())
				local red_avail = (bit32.band(n, 2) == 0)
				local black_avail = (bit32.band(n, 1) == 0)
				if player:isKongcheng() or ((not red_avail) and (not black_avail)) then return false end
				local pattern = ".|.|.|hand"
				if red_avail ~= black_avail then
					if red_avail then
						pattern = ".|red|.|hand"
					else
						pattern = ".|black|.|hand"
					end
				end
				local card = room:askForCard(player, pattern, "@xingwu", sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					player:addToPile(self:objectName(), card)
				end
			elseif player:getPhase() == sgs.Player_RoundStart then
				player:setMark(self:objectName(), 0)
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.to and move.to:objectName() == player:objectName()) and (move.to_place == sgs.Player_PlaceSpecial) and (player:getPile(self:objectName()):length() >= 3) then
				player:clearOnePrivatePile(self:objectName())
				local males = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isMale() then
						males:append(p)
					end
				end
				if males:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, males, self:objectName(), "@xingwu-choose")
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 2))
				if not player:isAlive() then return false end
				local equips = target:getEquips()
				if not equips:isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, equip in sgs.qlist(equips) do
						if player:canDiscard(target, equip:getEffectiveId()) then
							dummy:addSubcard(equip)
						end
					end
					if dummy:subcardsLength() > 0 then
						room:throwCard(dummy, target, player)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：行殇
	相关武将：林·曹丕、铜雀台·曹丕
	描述：每当一名其他角色死亡时，你可以获得该角色的牌。    
	引用：LuaXingshang
	状态：0405验证通过
]]--
LuaXingshang = sgs.CreateTriggerSkill{
	name = "LuaXingshang",
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local splayer = death.who
		if splayer:objectName() == player:objectName() or player:isNude() then return false end
		if player:isAlive() and room:askForSkillInvoke(player, self:objectName(), data) then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local cards = splayer:getCards("he")
			for _,card in sgs.qlist(cards) do
				dummy:addSubcard(card)
			end
			if cards:length() > 0 then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
				room:obtainCard(player, dummy, reason, false)
			end
			dummy:deleteLater()
		end
		return false
	end
}
--[[
	技能：雄异（限定技）
	相关武将：国战·马腾
	描述：出牌阶段，你可以令你与任意数量的角色摸三张牌：若以此法摸牌的角色数不大于全场角色数的一半，你回复1点体力。
	引用：LuaXiongyi
	状态：1217验证通过
]]--
LuaXiongyiCard = sgs.CreateSkillCard{
	name = "LuaXiongyiCard",
	mute = true,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return true
	end,
	feasible = function(self, targets)
		return true
	end,
	about_to_use = function(self, room, cardUse)
		local use = cardUse
		if not use.to:contains(use.from) then
			use.to:append(use.from)
		end
		room:removePlayerMark(use.from, "@arise")
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		for _,p in ipairs(targets) do
			p:drawCards(3)
		end
		if #targets <= room:getAlivePlayers():length() / 2 and source:isWounded() then
			local rec = sgs.RecoverStruct()
			rec.who = source
			room:recover(source, rec)
		end
	end
}
LuaXiongyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaXiongyi",
	view_as = function(self, cards)
		return LuaXiongyiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@arise") >= 1
	end
}
LuaXiongyi = sgs.CreateTriggerSkill{
	name = "LuaXiongyi",
	frequency = sgs.Skill_Limited,
	events = {sgs.GameStart},
	limit_mark = "@arise",
	view_as_skill = LuaXiongyiVS,
	on_trigger = function()
	end
}

--[[
	技能名：修罗
	相关武将：SP·暴怒战神
	描述：准备阶段开始时，你可以弃置一张与判定区内延时锦囊牌花色相同的手牌：若如此做，你弃置该延时锦囊牌。 
	引用：LuaXiuluo
	状态：0405验证通过
]]--
hasDelayedTrickXiuluo = function(target)
	for _, card in sgs.qlist(target:getJudgingArea()) do
		if not card:isKindOf("SkillCard") then return true end
	end
	return false
end
containsTable = function(t, tar)
	for _, i in ipairs(t) do
		if i == tar then return true end
	end
	return false
end
LuaXiuluo = sgs.CreatePhaseChangeSkill{
	name = "LuaXiuluo" ,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		while hasDelayedTrickXiuluo(player) and player:canDiscard(player, "h") do
			local suits = {}
			for _, jcard in sgs.qlist(player:getJudgingArea()) do
				if not containsTable(suits, jcard:getSuitString()) then
					table.insert(suits, jcard:getSuitString())
				end
			end
			local card = room:askForCard(player, ".|" .. table.concat(suits, ",") .. "|.|hand", "@xiuluo", sgs.QVariant(), self:objectName())
			if not card or not hasDelayedTrickXiuluo(player) then break end
			local avail_list = sgs.IntList()
			local other_list = sgs.IntList()
			local all_list = sgs.IntList()
			for _, jcard in sgs.qlist(player:getJudgingArea()) do
				if jcard:isKindOf("SkillCard") then continue end
				if jcard:getSuit() == card:getSuit() then
					avail_list:append(jcard:getEffectiveId())
				else
					other_list:append(jcard:getEffectiveId())
				end
			end
			for _, l in sgs.qlist(avail_list) do
				all_list:append(l)
			end
			for _, l in sgs.qlist(other_list) do
				all_list:append(l)
			end
			room:fillAG(all_list, nil, other_list)
			local id = room:askForAG(player, avail_list, false, self:objectName())
			room:clearAG()
			room:throwCard(id, nil)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName())and target:getPhase() == sgs.Player_Start
		and target:canDiscard(target, "h") and hasDelayedTrickXiuluo(target)
	end
}
--[[
	技能名：旋风
	相关武将：一将成名·凌统
	描述：当你失去装备区里的牌时，或于弃牌阶段内弃置了两张或更多的手牌后，你可以依次弃置一至两名其他角色的共计两张牌。
	引用：LuaXuanfeng
	状态：1217验证通过
]]--
LuaXuanfengCard = sgs.CreateSkillCard{
	name = "LuaXuanfengCard" ,
	filter = function(self, targets, to_select)
		if #targets >= 2 then return false end
		if to_select:objectName() == sgs.Self:objectName() then return false end
		return sgs.Self:canDiscard(to_select, "he")
	end ,
	on_use = function(self, room, source, targets)
		local map = {}
		local totaltarget = 0
		for _, sp in ipairs(targets) do
			map[sp] = 1
		end
		totaltarget = #targets
		if totaltarget == 1 then
			for _, sp in ipairs(targets) do
				map[sp] = map[sp] + 1
			end
		end
		for _, sp in ipairs(targets) do
			while map[sp] > 0 do
				if source:isAlive() and sp:isAlive() and source:canDiscard(sp, "he") then
					local card_id = room:askForCardChosen(source, sp, "he", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(card_id, sp, source)
				end
				map[sp] = map[sp] - 1
			end
		end
	end
}
LuaXuanfengVS = sgs.CreateViewAsSkill{
	name = "LuaXuanfeng" ,
	n = 0 ,
	view_as = function()
		return LuaXuanfengCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, target, pattern)
		return pattern == "@@LuaXuanfeng"
	end
}
LuaXuanfeng = sgs.CreateTriggerSkill{
	name = "LuaXuanfeng" ,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart} ,
	view_as_skill = LuaXuanfengVS ,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			player:setMark("LuaXuanfeng", 0)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (not move.from) or (move.from:objectName() ~= player:objectName()) then return false end
			if (move.to_place == sgs.Player_DiscardPile) and (player:getPhase() == sgs.Player_Discard)
					and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				player:setMark("LuaXuanfeng", player:getMark("LuaXuanfeng") + move.card_ids:length())
			end
			if ((player:getMark("LuaXuanfeng") >= 2) and (not player:hasFlag("LuaXuanfengUsed")))
					or move.from_places:contains(sgs.Player_PlaceEquip) then
				local room = player:getRoom()
				local targets = sgs.SPlayerList()
				for _, target in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canDiscard(target, "he") then
						targets:append(target)
					end
				end
				if targets:isEmpty() then return false end
				local choice = room:askForChoice(player, self:objectName(), "throw+nothing") --这个地方令我非常无语…………用askForSkillInvoke不好么…………
				if choice == "throw" then
					--player:setFlags("LuaXuanfengUsed") --这是源码Bug的地方
					if player:getPhase() == sgs.Player_Discard then player:setFlags("LuaXuanfengUsed") end --修复源码Bug
					room:askForUseCard(player, "@@LuaXuanfeng", "@xuanfeng-card")
				end
			end
		end
		return false
	end
}
--[[
	技能名：旋风
	相关武将：怀旧·凌统
	描述：当你失去一次装备区里的牌时，你可以选择一项：1. 视为对一名其他角色使用一张【杀】；你以此法使用【杀】时无距离限制且不计入出牌阶段内的使用次数限制。2. 对距离为1的一名角色造成1点伤害。
	引用：LuaNosXuanfeng
	状态：1217验证通过
]]--
LuaNosXuanfeng = sgs.CreateTriggerSkill{
	name = "LuaNosXuanfeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() then
				if move.from_places:contains(sgs.Player_PlaceEquip) then
					local room = player:getRoom()
					local choicecount = 1
					local choicelist = "nothing"
					local targets1 = sgs.SPlayerList()
					local list = room:getAlivePlayers()
					for _,target in sgs.qlist(list) do
						if player:canSlash(target, nil, false) then
							targets1:append(target)
						end
					end
					if targets1:length() > 0 then
						choicelist = string.format("%s+%s", choicelist, "slash")
						choicecount = choicecount + 1
					end
					local targets2 = sgs.SPlayerList()
					others = room:getOtherPlayers(player)
					for _,p in sgs.qlist(others) do
						if player:distanceTo(p) <= 1 then
							targets2:append(p)
						end
					end
					if targets2:length() > 0 then
						choicelist = string.format("%s+%s", choicelist, "damage")
						choicecount = choicecount + 1
					end
					if choicecount > 1 then
						local choice = room:askForChoice(player, self:objectName(), choicelist)
						if choice == "slash" then
							local target = room:askForPlayerChosen(player, targets1, "xuanfeng-slash")
							local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							slash:setSkillName(self:objectName())
							local card_use = sgs.CardUseStruct()
							card_use.card = slash
							card_use.from = player
							card_use.to:append(target)
							room:useCard(card_use, false)
						elseif choice == "damage" then
							local target = room:askForPlayerChosen(player, targets2, "xuanfeng-damage")
							local damage = sgs.DamageStruct()
							damage.from = player
							damage.to = target
							room:damage(damage)
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：眩惑
	相关武将：一将成名·法正
	描述：摸牌阶段开始时，你可以放弃摸牌，改为令一名其他角色摸两张牌，然后令其对其攻击范围内你选择的另一名角色使用一张【杀】，若该角色未如此做或其攻击范围内没有其他角色，你获得其两张牌。
	引用：LuaXuanhuo、LuaXuanhuoFakeMove
	状态：1217验证通过
]]--

LuaXuanhuo = sgs.CreateTriggerSkill{
	name = "LuaXuanhuo" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "xuanhuo-invoke", true, true)
			if to then
				room:drawCards(to, 2)
				if (not player:isAlive()) or (not to:isAlive()) then return true end
				local targets = sgs.SPlayerList()
				for _, vic in sgs.qlist(room:getOtherPlayers(to)) do
					if to:canSlash(vic) then
						targets:append(vic)
					end
				end
				local victim
				if not targets:isEmpty() then
					victim = room:askForPlayerChosen(player, targets, "xuanhuo_slash", "@dummy-slash2:" .. to:objectName())
				end
				if victim then --不得已写了两遍movecard…………
					if not room:askForUseSlashTo(to, victim, "xuanhuo-slash:" .. player:objectName() .. ":" .. victim:objectName()) then
						if to:isNude() then return true end
						room:setPlayerFlag(to, "LuaXuanhuo_InTempMoving")
						local first_id = room:askForCardChosen(player, to, "he", self:objectName())
						local original_place = room:getCardPlace(first_id)
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:addSubcard(first_id)
						to:addToPile("#xuanhuo", dummy, false)
						if not to:isNude() then
							local second_id = room:askForCardChosen(player, to, "he", self:objectName())
							dummy:addSubcard(second_id)
						end
						room:moveCardTo(sgs.Sanguosha:getCard(first_id), to, original_place, false)
						room:setPlayerFlag(to, "-LuaXuanhuo_InTempMoving")
						room:moveCardTo(dummy, player, sgs.Player_PlaceHand, false)
						--delete dummy
					end
				else
					if to:isNude() then return true end
					room:setPlayerFlag(to, "LuaXuanhuo_InTempMoving")
					local first_id = room:askForCardChosen(player, to, "he", self:objectName())
					local original_place = room:getCardPlace(first_id)
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					dummy:addSubcard(first_id)
					to:addToPile("#xuanhuo", dummy, false)
					if not to:isNude() then
						local second_id = room:askForCardChosen(player, to, "he", self:objectName())
						dummy:addSubcard(second_id)
					end
					room:moveCardTo(sgs.Sanguosha:getCard(first_id), to, original_place, false)
					room:setPlayerFlag(to, "-LuaXuanhuo_InTempMoving")
					room:moveCardTo(dummy, player, sgs.Player_PlaceHand, false)
					--delete dummy
				end
				return true
			end
		end
		return false
	end
}
LuaXuanhuoFakeMove = sgs.CreateTriggerSkill{
	name = "#LuaXuanhuo-fake-move" ,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime} ,
	priority = 10 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("LuaXuanhuo_InTempMoving") then return true end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--[[
	技能名：眩惑
	相关武将：怀旧·法正
	描述：出牌阶段，你可以将一张红桃手牌交给一名其他角色，然后你获得该角色的一张牌并交给除该角色外的其他角色。每阶段限一次。
	引用：LuaNosXuanhuo
	状态：1217验证通过
]]--
LuaNosXuanhuoCard = sgs.CreateSkillCard{
	name = "LuaNosXuanhuoCard",
	target_fixed = false,
	will_throw = true,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		dest:obtainCard(self)
		local room = source:getRoom()
		local card_id = room:askForCardChosen(source, dest, "he", self:objectName())
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
		local card = sgs.Sanguosha:getCard(card_id)
		local place = room:getCardPlace(card_id)
		local unhide = (place ~= sgs.Player_PlaceHand)
		room:obtainCard(source, card, unhide)
		local targets = room:getOtherPlayers(dest)
		local target = room:askForPlayerChosen(source, targets, self:objectName())
		if target:objectName() ~= source:objectName() then
			reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName())
			reason.m_playerId = target:objectName()
			room:obtainCard(target, card, false)
		end
	end
}
LuaNosXuanhuo = sgs.CreateViewAsSkill{
	name = "LuaNosXuanhuo",
	n = 1,
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return to_select:getSuit() == sgs.Card_Heart
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local xuanhuoCard = LuaNosXuanhuoCard:clone()
			xuanhuoCard:addSubcard(cards[1])
			return xuanhuoCard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaNosXuanhuoCard")
	end
}
--[[
	技能名：雪恨（锁定技）
	相关武将：☆SP·夏侯惇
	描述：一名角色的结束阶段开始时，若你的体力牌处于竖置状态，你横置之，然后选择一项：1.弃置当前回合角色X张牌。 2.视为你使用一张无距离限制的【杀】。（X为你已损失的体力值）
	引用：LuaXuehen、LuaXuehenNDL、LuaXuehenFakeMove
	状态：1217验证通过
]]--
LuaXuehen = sgs.CreateTriggerSkill{
	name = "LuaXuehen" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local xiahou = room:findPlayerBySkillName(self:objectName())
		if not xiahou then return false end
		if (player:getPhase() == sgs.Player_Finish) and (xiahou:getMark("@fenyong") > 0) then
			xiahou:loseMark("@fenyong")
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(xiahou)) do
				if xiahou:canSlash(p, nil, false) then
					targets:append(p)
				end
			end
			local choice
			if (not sgs.Slash_IsAvailable(xiahou)) or targets:isEmpty() then
				choice = "discard"
			else
				choice = room:askForChoice(xiahou, self:objectName(), "discard+slash")
			end
			if choice == "slash" then
				local victim = room:askForPlayerChosen(xiahou, targets, self:objectName(), "@dummy-slash")
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName(self:objectName())
				room:useCard(sgs.CardUseStruct(slash, xiahou, victim), false)
			else
				room:setPlayerFlag(player, "LuaXuehen_InTempMoving")
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local card_ids = sgs.IntList()
				local original_places = sgs.IntList()
				for i = 0, xiahou:getLostHp() - 1, 1 do
					if not xiahou:canDiscard(player, "he") then break end
					card_ids:append(room:askForCardChosen(xiahou, player, "he", self:objectName(), false, sgs.Card_MethodDiscard))
					original_places:append(room:getCardPlace(card_ids:at(i)))
					dummy:addSubcard(card_ids:at(i))
					player:addToPile("#xuehen", card_ids:at(i), false)
				end
				for i = 0, dummy:subcardsLength() - 1, 1 do
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), player, original_places:at(i), false)
				end
				room:setPlayerFlag(player, "-LuaXuehen_InTempMoving")
				if dummy:subcardsLength() > 0 then
					room:throwCard(dummy, player, xiahou)
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end ,
}
LuaXuehenNDL = sgs.CreateTargetModSkill{
	name = "#LuaXuehen-slash-ndl" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("LuaXuehen") and (card:getSkillName() == "LuaXuehen") then
			return 1000
		else
			return 0
		end
	end
}
LuaXuehenFakeMove = sgs.CreateTriggerSkill{
	name = "#LuaXuehen-fake-move" ,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime} ,
	priority = 10 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("LuaXuehen_InTempMoving") then return true end
		end
		return false
	end
}
--[[
	技能名：血祭
	相关武将：SP·关银屏
	描述：出牌阶段限一次，你可以弃置一张红色牌并选择你攻击范围内的至多X名角色：若如此做，你对这些角色各造成1点伤害，然后这些角色各摸一张牌。（X为你已损失的体力值） 
	引用：LuaXueji
	状态：0405验证通过
]]--
LuaXuejiCard = sgs.CreateSkillCard{
	name = "LuaXuejiCard" ,
	filter = function(self, targets, to_select)
		if #targets >= sgs.Self:getLostHp() then return false end
		if to_select:objectName() == sgs.Self:objectName() then return false end
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		return sgs.Self:inMyAttackRange(to_select, rangefix)
	end ,
	on_use = function(self, room, source, targets)
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.reason = "LuaXueji"
		for _, p in ipairs(targets) do
			damage.to = p
			room:damage(damage)
		end
		for _, p in ipairs(targets) do
			if p:isAlive() then
				p:drawCards(1, "LuaXueji")
			end
		end
	end
}
LuaXueji = sgs.CreateOneCardViewAsSkill{
	name = "LuaXueji" ,
	filter_pattern = ".|red!" ,
	view_as = function(self, card)
		local first = LuaXuejiCard:clone()
		first:addSubcard(card:getId())
		first:setSkillName(self:objectName())
		return first
	end ,
	enabled_at_play = function(self, player)
		return player:getLostHp() > 0 and player:canDiscard(player, "he") and not player:hasUsed("#LuaXuejiCard")
	end
}
--[[
	技能名：血裔（主公技、锁定技）
	相关武将：火·袁绍
	描述：每有一名其他群雄角色存活，你的手牌上限便+2。
	引用：LuaXueyi
	状态：1217验证通过
]]--
LuaXueyi = sgs.CreateMaxCardsSkill{
	name = "LuaXueyi$",
	extra_func = function(self, target)
		local extra = 0
		local players = target:getSiblings()
		for _,player in sgs.qlist(players) do
			if player:isAlive() then
				if player:getKingdom() == "qun" then
					extra = extra + 2
				end
			end
		end
		if target:hasLordSkill(self:objectName()) then
			return extra
		end
	end
}
--[[
	技能名：恂恂
	相关武将：势·李典
	描述：摸牌阶段开始时，你可以放弃摸牌并观看牌堆顶的四张牌，你获得其中的两张牌，然后将其余的牌以任意顺序置于牌堆底。
	引用：LuaXunxun
	状态：1217验证通过
]]--
LuaXunxun = sgs.CreatePhaseChangeSkill{
	name = "LuaXunxun",
	frequency = sgs.Skill_Frequent,

	on_phasechange = function(self,player)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			if room:askForSkillInvoke(player,self:objectName()) then
			local card_ids = room:getNCards(4)
			local obtained = sgs.IntList()
				room:fillAG(card_ids,player)
			local id1 = room:askForAG(player,card_ids,false,self:objectName())
				card_ids:removeOne(id1)
				obtained:append(id1)
				room:takeAG(player,id1,false)
			local id2 = room:askForAG(player,card_ids,false,self:objectName())
				card_ids:removeOne(id2)
				obtained:append(id2)
				room:clearAG(player)
				room:askForGuanxing(player,card_ids,sgs.Room_GuanxingDownOnly)
			local dummy = sgs.Sanguosha:cloneCard("jink",sgs.Card_NoSuit,0)
			for _,id in sgs.qlist(obtained) do
				dummy:addSubcard(id)
			end
				player:obtainCard(dummy,false)
			return true
			end
		end
	end 
}
--[[
	技能名：迅猛（锁定技）
	相关武将：僵尸·僵尸
	描述：你的杀造成的伤害+1。你的杀造成伤害时若你体力大于1，你流失1点体力。
	引用：LuaXunmeng
	状态：1217验证通过
]]--
LuaXunmeng = sgs.CreateTriggerSkill{
	name = "LuaXunmeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			damage.damage = damage.damage + 1
			data:setValue(damage)
			if player:getHp() > 1 then
				room:loseHp(player)
			end
		end
	end
}
--[[
	技能名：殉志
	相关武将：倚天·姜伯约
	描述：出牌阶段，你可以摸三张牌并变身为其他未上场或已阵亡的蜀势力角色，回合结束后你立即死亡
	引用：LuaXXunzhi
	状态：1217验证通过
]]--
LuaXXunzhiCard = sgs.CreateSkillCard{
	name = "LuaXXunzhiCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:drawCards(3)
		local players = room:getAlivePlayers()
		local general_names = {}
		for _,player in sgs.qlist(players) do
			table.insert(general_names, player:getGeneralName())
		end
		local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
		local shu_generals = {}
		for _,name in ipairs(all_generals) do
			local general = sgs.Sanguosha:getGeneral(name)
			if general:getKingdom() == "shu" then
				if not table.contains(general_names, name) then
					table.insert(shu_generals, name)
				end
			end
		end
		local general = room:askForGeneral(source, table.concat(shu_generals, "+"))
		source:setTag("newgeneral", sgs.QVariant(general))
		local isSecondaryHero = not (sgs.Sanguosha:getGeneral(source:getGeneralName()):hasSkill("LuaXXunzhi"))
		if isSecondaryHero then
			source:setTag("originalGeneral",sgs.QVariant(source:getGeneral2Name()))
		else
			source:setTag("originalGeneral",sgs.QVariant(source:getGeneralName()))
		end
		room:changeHero(source, general, false, false, isSecondaryHero)
		room:setPlayerFlag(source, "LuaXXunzhi")
		room:acquireSkill(source, "LuaXXunzhi", false)
	end
}
LuaXXunzhiVS = sgs.CreateViewAsSkill{
	name = "LuaXXunzhi",
	n = 0,
	view_as = function(self, cards)
		return LuaXXunzhiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("LuaXXunzhi")
	end
}
LuaXXunzhi = sgs.CreateTriggerSkill{
	name = "LuaXXunzhi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	view_as_skill = LuaXXunzhiVS,
	on_trigger = function(self, event, player, data)
		if data:toPhaseChange().to == sgs.Player_NotActive then
			if player:hasFlag("LuaXXunzhi") then
				local room = player:getRoom()
				local isSecondaryHero = player:getGeneralName() ~= player:getTag("newgeneral"):toString()
				room:changeHero(player, player:getTag("originalGeneral"):toString(), false, false, isSecondaryHero)
				room:killPlayer(player)
			end
		end
		return false
	end,
}
