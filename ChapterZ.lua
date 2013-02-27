--[[
	代码速查手册（Z区）
	技能索引：
		凿险、早夭、再起、昭心、昭烈、贞烈、镇威、争锋、争功、直谏、制霸、制霸、智迟、制衡、志继、智愚、筑楼、追忆、自立、自守、宗室、纵火、醉乡
]]--
--[[
	技能名：凿险（觉醒技）
	相关武将：山·邓艾
	描述：回合开始阶段开始时，若“田”的数量达到3或更多，你须减1点体力上限，并获得技能“急袭”。
	状态：验证通过
]]--
LuaZaoxian = sgs.CreateTriggerSkill{
	name = "LuaZaoxian", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "zaoxian", 1)
		player:gainMark("@waked")
		room:loseMaxHp(player)
		room:acquireSkill(player, "jixi")
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start then
					if target:getMark("zaoxian") == 0 then
						local fields = target:getPile("field")
						return fields:length() >= 3
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：早夭（锁定技）
	相关武将：倚天·曹冲
	描述：回合结束阶段开始时，若你的手牌大于13张，则你必须弃置所有手牌并流失1点体力 
	状态：验证通过
]]--
LuaXZaoyao = sgs.CreateTriggerSkill{
	name = "LuaXZaoyao",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Finish then
			if player:getHandcardNum() > 13 then
				local room = player:getRoom()
				player:throwAllHandCards()
				room:loseHp(player)
			end
		end
		return false
	end
}
--[[
	技能名：再起
	相关武将：林·孟获
	描述：摸牌阶段开始时，若你已受伤，你可以放弃摸牌，改为从牌堆顶亮出X张牌（X为你已损失的体力值），你回复等同于其中红桃牌数量的体力，然后将这些红桃牌置入弃牌堆，并获得其余的牌。
	状态：验证通过
]]--
LuaZaiqi = sgs.CreateTriggerSkill{
	name = "LuaZaiqi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			if player:isWounded() then
				local room = player:getRoom()
				if room:askForSkillInvoke(player, self:objectName()) then
					local x = player:getLostHp()
					local has_heart = false
					local ids = room:getNCards(x, false)
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = player
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					room:getThread():delay(1000)
					local card_to_throw = {}
					local card_to_gotback = {}
					for i=0, x-1, 1 do
						local id = ids:at(i)
						local card = sgs.Sanguosha:getCard(id)
						local suit = card:getSuit()
						if suit == sgs.Card_Heart then
							table.insert(card_to_throw, id)
						else
							table.insert(card_to_gotback, id)
						end
					end
					if #card_to_throw > 0 then
						local recover = sgs.RecoverStruct()
						recover.card = nil
						recover.who = player
						recover.recover = #card_to_throw
						room:recover(player, recover)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
						for _,card in pairs(card_to_throw) do
							room:throwCard(card, nil, nil)
						end
						has_heart = true
					end
					if #card_to_gotback > 0 then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, player:objectName())
						for _,card in pairs(card_to_gotback) do
							room:obtainCard(player, card, true)
						end
					end
					return true
				end
			end
		end
		return false
	end
}
--[[
	技能名：昭心
	相关武将：贴纸·司马昭
	描述：摸牌阶段结束时，你可以展示所有手牌，若如此做，视为你使用一张【杀】，每阶段限一次。 
	状态：验证通过
]]--
LuaZhaoXin = sgs.CreateTriggerSkill{
	name = "LuaZhaoXin",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			local splist = sgs.SPlayerList()
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canSlash(p, slash) then
					splist:append(p)
				end
			end
			if splist:isEmpty() then return false end
			if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant()) then
				local target = room:askForPlayerChosen(player, splist, self:objectName())
				room:showAllCards(player)
				local use = sgs.CardUseStruct()
				use.from = player
				use.to:append(target)
				use.card = slash
				room:useCard(use, false)
			end
		end
	end
}
--[[
	技能名：昭烈
	相关武将：☆SP·刘备
	描述：摸牌阶段摸牌时，你可以少摸一张牌，指定你攻击范围内的一名其他角色亮出牌堆顶上3张牌，将其中全部的非基本牌和【桃】置于弃牌堆，该角色进行二选一：你对其造成X点伤害，然后他获得这些基本牌；或他依次弃置X张牌，然后你获得这些基本牌。（X为其中非基本牌的数量）。
	状态：验证通过
]]--
LuaZhaolie = sgs.CreateTriggerSkill{
	name = "LuaZhaolie",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DrawNCards},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local targets = room:getOtherPlayers(player)
		local victims = sgs.SPlayerList()
		for _,p in sgs.qlist(targets) do
			if player:inMyAttackRange(p) then
				victims:append(p)
			end
		end
		if victims:length() > 0 then
			if room:askForSkillInvoke(player, self:objectName()) then
				room:setPlayerFlag(player, "Invoked")
				local count = data:toInt() - 1
				data:setValue(count)
			end
		end
	end
}
LuaZhaolieAct = sgs.CreateTriggerSkill{
	name = "#LuaZhaolie",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardDrawnDone},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local no_basic = 0
		local cards = {}
		local targets = room:getOtherPlayers(player)
		local victims = sgs.SPlayerList()
		for _,p in sgs.qlist(targets) do
			if player:inMyAttackRange(p) then
				victims:append(p)
			end
		end
		if player:getPhase() == sgs.Player_Draw then
			if player:hasFlag("Invoked") then
				room:setPlayerFlag(player, "-Invoked")
				local victim = room:askForPlayerChosen(player, victims, "LuaZhaolie")
				local cardIds = sgs.IntList()
				for i=1, 3, 1 do
					local id = room:drawCard()
					cardIds:append(id)
				end
				assert(cardIds:length() == 3)
				local move = sgs.CardsMoveStruct()
				move.card_ids = cardIds
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), "", "LuaZhaolie", "")
				room:moveCards(move, true)
				room:getThread():delay()
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, "", "LuaZhaolie", "")
				for i=0, 2, 1 do
					local card_id = cardIds:at(i)
					local card = sgs.Sanguosha:getCard(card_id)
					if not card:isKindOf("BasicCard") or card:isKindOf("Peach") then
						if not card:isKindOf("BasicCard") then
							no_basic = no_basic + 1
						end
						room:throwCard(card, reason, nil)
					else
						table.insert(cards, card)
					end
				end
				local choicelist = "damage"
				local flag = false
				local victim_cards = victim:getCards("he")
				if victim_cards:length() >= no_basic then
					choicelist = "damage+throw"
					flag = true
				end
				local choice
				if flag then
					local data = sgs.QVariant(no_basic)
					choice = room:askForChoice(victim, "LuaZhaolie", choicelist, data)
				else
					choice = "damage"
				end
				if choice == "damage" then
					if no_basic > 0 then
						local damage = sgs.DamageStruct()
						damage.card = nil
						damage.from = player
						damage.to = victim
						damage.damage = no_basic
						room:damage(damage)
					end
					if #cards > 0 then
						local reasonA = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, victim:objectName())
						local reasonB = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, victim:objectName(), "LuaZhaolie", "")
						for _,c in pairs(cards) do
							if victim:isAlive() then
								room:obtainCard(victim, c, true)
							else
								room:throwCard(c, reasonB, nil)
							end
						end
					end
				else
					if no_basic > 0 then
						while no_basic > 0 do
							room:askForDiscard(victim, "LuaZhaolie", 1, 1, false, true)
							no_basic = no_basic - 1
						end
					end
					if #cards > 0 then
						reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, player:objectName())
						for _,c in pairs(cards) do
							room:obtainCard(player, c)
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：贞烈
	相关武将：二将成名·王异
	描述：在你的判定牌生效前，你可以从牌堆顶亮出一张牌代替之。
	状态：验证通过
]]--
LuaZhenlie = sgs.CreateTriggerSkill{
	name = "LuaZhenlie", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.AskForRetrial}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local judge = data:toJudge()
		if judge.who:objectName() == player:objectName() then
			if player:askForSkillInvoke(self:objectName(), data) then
				local card_id = room:drawCard()
				room:getThread():delay()
				local card = sgs.Sanguosha:getCard(card_id)
				room:retrial(card, player, judge, self:objectName())
			end
		end
		return false
	end
}
--[[
	技能名：镇威
	相关武将：倚天·倚天剑
	描述：你的【杀】被手牌中的【闪】抵消时，可立即获得该【闪】。 
	状态：验证通过
]]--
LuaXZhenwei = sgs.CreateTriggerSkill{
	name = "LuaXZhenwei",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.SlashMissed},  
	on_trigger = function(self, event, player, data) 
		local effect = data:toSlashEffect()
		local room = player:getRoom()
		local jink = effect.jink
		local id = jink:getEffectiveId()
		local place = room:getCardPlace(id)
		if place == sgs.Player_DiscardPile then
			if player:askForSkillInvoke(self:objectName(), data) then
				player:obtainCard(jink)
			end
		end
		return false
	end
}
--[[
	技能名：争锋（锁定技）
	相关武将：倚天·倚天剑
	描述：当你的装备区没有武器时，你的攻击范围为X，X为你当前体力值。 
]]--
--[[
	技能名：争功
	相关武将：倚天·邓士载
	描述：其他角色的回合开始前，若你的武将牌正面向上，你可以将你的武将牌翻面并立即进入你的回合，你的回合结束后，进入该角色的回合 
	状态：验证通过
]]--
LuaXZhenggong = sgs.CreateTriggerSkill{
	name = "LuaXZhenggong",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TurnStart},  
	on_trigger = function(self, event, player, data) 
		if player then
			local room = player:getRoom()
			local dengshizai = room:findPlayerBySkillName(self:objectName())
			if dengshizai and dengshizai:faceUp() then
				if dengshizai:askForSkillInvoke(self:objectName()) then
					dengshizai:turnOver()
					local tag = room:getTag("Zhenggong")
					if tag then
						local zhenggong = tag:toPlayer()
						if not zhenggong then
							tag:setValue(player)
							room:setTag("Zhenggong", tag)
							player:gainMark("@zhenggong")
						end
					end
					room:setCurrent(dengshizai)
					dengshizai:play()
					return true
				end
			end
			local tag = room:getTag("Zhenggong")
			if tag then
				local p = tag:toPlayer()
				if p and not player:hasFlag("isExtraTurn") then
					p:loseMark("@zhenggong")
					room:setCurrent(p)
					room:setTag("Zhenggong", sgs.QVariant())
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return not target:hasSkill(self:objectName())
		end
		return false
	end
}
--[[
	技能名：直谏
	相关武将：山·张昭张纮
	描述：出牌阶段，你可以将手牌中的一张装备牌置于一名其他角色的装备区里（不能替换原装备），然后摸一张牌。
	状态：验证通过
]]--
LuaZhijianCard = sgs.CreateSkillCard{
	name = "LuaZhijianCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				local subs = self:getSubcards()
				local id = subs:first()
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("Weapon") then
					return not to_select:getWeapon()
				elseif card:isKindOf("Armor") then
					return not to_select:getArmor()
				elseif card:isKindOf("DefensiveHorse") then
					return not to_select:getDefensiveHorse()
				elseif card:isKindOf("OffensiveHorse") then
					return not to_select:getOffensiveHorse()
				end
			end
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local room = source:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "LuaZhijian", "")
		room:moveCardTo(self, source, effect.to, sgs.Player_PlaceEquip, reason)
		source:drawCards(1)
	end
}
LuaZhijian = sgs.CreateViewAsSkill{
	name = "LuaZhijian", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return to_select:getTypeId() == sgs.Card_Equip
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local zhijian_card = LuaZhijianCard:clone()
			zhijian_card:addSubcard(cards[1])
			return zhijian_card
		end
	end
}
--[[
	技能名：制霸（主公技）
	相关武将：山·孙策
	描述：其他吴势力角色可以在他们各自的出牌阶段与你拼点（“魂姿”发动后，你可以拒绝此拼点），若该角色没赢，你可以获得双方拼点的牌。每阶段限一次。
	状态：验证通过
]]--
LuaZhibaCard = sgs.CreateSkillCard{
	name = "LuaZhibaCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			if to_select:hasLordSkill("LuaSunceZhiba") then
				if to_select:objectName() ~= sgs.Self:objectName() then
					if not to_select:isKongcheng() then
						return not to_select:hasFlag("ZhibaInvoked")
					end
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		room:setPlayerFlag(target, "ZhibaInvoked")
		if target:getMark("hunzi") > 0 then
			local choice = room:askForChoice(target, "LuaZhibaPindian", "accept+reject")
			if choice == "reject" then
				return
			end
		end
		source:pindian(target, "LuaZhibaPindian", self)
		local sunces = sgs.SPlayerList()
		local players = room:getOtherPlayers(source)
		for _,p in sgs.qlist(players) do
			if p:hasLordSkill("sunce_zhiba") then
				if not p:hasFlag("ZhibaInvoked") then
					sunces:append(p)
				end
			end
		end
		if sunces:length() == 0 then
			room:setPlayerFlag(source, "ForbidZhiba")
		end
	end
}
LuaZhibaPindian = sgs.CreateViewAsSkill{
	name = "LuaZhibaPindian", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaZhibaCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		if player:getKingdom() == "wu" then
			if not player:isKongcheng() then
				return not player:hasFlag("ForbidZhiba")
			end
		end
		return false
	end
}
LuaSunceZhiba = sgs.CreateTriggerSkill{
	name = "LuaSunceZhiba$",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.GameStart, sgs.Pindian, sgs.EventPhaseChanging},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:hasLordSkill(self:objectName()) then
				local others = room:getOtherPlayers(player)
				for _,p in sgs.qlist(others) do
					if not p:hasSkill("LuaZhibaPindian") then
						room:attachSkillToPlayer(p, "LuaZhibaPindian")
					end
				end
			end
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "LuaZhibaPindian" then
				local target = pindian.to
				if target:hasLordSkill(self:objectName()) then
					if pindian.from_card:getNumber() <= pindian.to_card:getNumber() then
						local choice = room:askForChoice(target, "LuaSunceZhiba", "yes+no")
						if choice == "yes" then
							target:obtainCard(pindian.from_card)
							target:obtainCard(pindian.to_card)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from == sgs.Player_Play then
				if player:hasFlag("ForbidZhiba") then
					room:setPlayerFlag(player, "-ForbidZhiba")
				end
				local players = room:getOtherPlayers(player)
				for _,p in sgs.qlist(players) do
					if p:hasFlag("ZhibaInvoked") then
						room:setPlayerFlag(p, "-ZhibaInvoked")
					end
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
	技能名：制霸
	相关武将：测试·制霸孙权
	描述：出牌阶段，你可以弃置任意数量的牌，然后摸取等量的牌。每阶段可用X+1次，X为你已损失的体力值 
	状态：验证通过
]]--
LuaZhihengCard = sgs.CreateSkillCard{
	name = "LuaZhihengCard", 
	target_fixed = true, 
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			room:drawCards(source, count)
		end
	end
}
LuaXZhiBa = sgs.CreateViewAsSkill{
	name = "LuaXZhiba", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		return true
	end, 
	view_as = function(self, cards) 
		if #cards > 0 then
			local zhiheng_card = LuaZhihengCard:clone()
			for _,card in pairs(cards) do
				zhiheng_card:addSubcard(card)
			end
			zhiheng_card:setSkillName(self:objectName())
			return zhiheng_card
		end
	end, 
	enabled_at_play = function(self, player)
		local lost = player:getLostHp()
		local used = player:usedTimes("#LuaZhihengCard")
		return used < (lost + 1)
	end
}
--[[
	技能名：智迟（锁定技）
	相关武将：一将成名·陈宫
	描述：你的回合外，每当你受到一次伤害后，【杀】或非延时类锦囊牌对你无效，直到回合结束。
	状态：验证通过
]]--
LuaZhichiClear = sgs.CreateTriggerSkill{
	name = "#LuaZhichiClear",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			local room = player:getRoom()
			room:removeTag("Zhichi")
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
LuaZhichi = sgs.CreateTriggerSkill{
	name = "LuaZhichi",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged, sgs.CardEffected}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player then
			if player:getPhase() == sgs.Player_NotActive then
				if event == sgs.Damaged then
					if room:getCurrent():isAlive() then
						local value = sgs.QVariant(player:objectName())
						room:setTag("Zhichi", value)
					end
				elseif event == sgs.CardEffected then
					local tag = room:getTag("Zhichi")
					if tag:toString() == player:objectName() then
						local effect = data:toCardEffect()
						local card = effect.card
						if card:isKindOf("Slash") or card:getTypeId() == sgs.Card_Trick then
							return true
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：制衡
	相关武将：标准·孙权
	描述：出牌阶段，你可以弃置任意数量的牌，然后摸等量的牌。每阶段限一次。
	状态：验证通过
]]--
LuaZhihengCard = sgs.CreateSkillCard{
	name = "LuaZhihengCard", 
	target_fixed = true, 
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			room:drawCards(source, count)
		end
	end
}
LuaZhiheng = sgs.CreateViewAsSkill{
	name = "LuaZhiheng", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		return true
	end, 
	view_as = function(self, cards) 
		if #cards > 0 then
			local zhiheng_card = LuaZhihengCard:clone()
			for _,card in pairs(cards) do
				zhiheng_card:addSubcard(card)
			end
			zhiheng_card:setSkillName(self:objectName())
			return zhiheng_card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaZhihengCard")
	end
}
--[[
	技能名：志继（觉醒技）
	相关武将：山·姜维
	描述：回合开始阶段开始时，若你没有手牌，你须选择一项：回复1点体力，或摸两张牌。然后你减1点体力上限，并获得技能“观星”。
	状态：验证通过
]]--
LuaZhiji = sgs.CreateTriggerSkill{
	name = "LuaZhiji", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data) --必须
		local room = player:getRoom()
		local draw
		if player:getLostHp() > 0 then
			choice = room:askForChoice(player, self:objectName(), "draw+recover")
		else
			choice = "draw"
		end
		if choice == "recover" then
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
		else
			room:drawCards(player, 2)
		end
		room:setPlayerMark(player, "zhiji", 1)
		player:gainMark("@waked")
		room:acquireSkill(player, "guanxing")
		room:loseMaxHp(player)
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getMark("zhiji") == 0 then
					if target:getPhase() == sgs.Player_Start then
						return target:isKongcheng()
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：智愚
	相关武将：二将成名·荀攸
	描述：每当你受到一次伤害后，你可以摸一张牌，然后展示所有手牌，若颜色均相同，伤害来源弃置一张手牌。
	状态：验证通过
]]--
LuaZhiyu = sgs.CreateTriggerSkill{
	name = "LuaZhiyu", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local source = damage.from
		if source then
			if source:isAlive() then
				if player:askForSkillInvoke(self:objectName(), data) then
					player:drawCards(1)
					if not player:isKongcheng() then
						local room = player:getRoom()
						room:showAllCards(player)
						local cards = player:getHandcards()
						local color = cards:first():isBlack()
						local same_color = true
						for _,card in sgs.qlist(cards) do
							if card:isBlack() ~= color then
								same_color = false
								break
							end
						end
						if same_color then
							if not source:isKongcheng() then
								room:askForDiscard(source, self:objectName(), 1, 1)
							end
						end
					end
				end
			end
		end
	end
}
--[[
	技能名：筑楼
	相关武将：翼·公孙瓒
	描述：回合结束阶段开始时，你可以摸两张牌，然后失去1点体力或弃置一张武器牌。 
	状态：验证通过
]]--
LuaXZhulou = sgs.CreateTriggerSkill{
	name = "LuaXZhulou",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom();
		if player:getPhase() == sgs.Player_Finish then
			if player:askForSkillInvoke(self:objectName()) then
				player:drawCards(2)
				if not room:askForCard(player, ".Weapon", "@zhulou-discard", sgs.QVariant(), sgs.CardDiscarded) then
					room:loseHp(player)
				end
			end
		end
		return false
	end
}
--[[
	技能名：追忆
	相关武将：二将成名·步练师
	描述：你死亡时，可以令一名其他角色（杀死你的角色除外）摸三张牌并回复1点体力。
	状态：验证通过
]]--
LuaZhuiyi = sgs.CreateTriggerSkill{
	name = "LuaZhuiyi", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local targets = nil
		local killer = nil
		if damage then
			killer = damage.from
			if killer then
				targets = room:getOtherPlayers(killer)
			end
		end
		if not killer then
			targets = room:getAlivePlayers()
		end
		if targets:length() > 0 then
			if player:askForSkillInvoke(self:objectName(), data) then
				local target = room:askForPlayerChosen(player, targets, self:objectName())
				target:drawCards(3)
				local recover = sgs.RecoverStruct()
				recover.who = target
				recover.recover = 1
				room:recover(target, recover, true)
				return false
			end
		end
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasSkill(self:objectName())
		end
		return false
	end
}
--[[
	技能名：自立（觉醒技）
	相关武将：一将成名·钟会
	描述：回合开始阶段开始时，若“权”的数量达到3或更多，你须减1点体力上限，然后回复1点体力或摸两张牌，并获得技能“排异”。
	状态：验证通过
]]--
LuaZili = sgs.CreateTriggerSkill{
	name = "LuaZili", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		room:setPlayerMark(player, "zili", 1)
		player:gainMark("@waked")
		room:loseMaxHp(player)
		local choice
		if player:getLostHp() > 0 then
			choice = room:askForChoice(player, self:objectName(), "recover+draw")
		else
			choice = "draw"
		end
		if choice == "recover" then
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
		else
			room:drawCards(player, 2)
		end
		room:acquireSkill(player, "paiyi")
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start then
					if target:getMark("zili") == 0 then
						local powers = target:getPile("power")
						return powers:length() >= 3
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：自守
	相关武将：二将成名·刘表
	描述：摸牌阶段，若你已受伤，你可以额外摸X张牌（X为你已损失的体力值），然后跳过你的出牌阶段。
	状态：验证通过
]]--
LuaZishou = sgs.CreateTriggerSkill{
	name = "LuaZishou",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DrawNCards}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:isWounded() then
			if room:askForSkillInvoke(player, self:objectName()) then
				local losthp = player:getLostHp()
				local count = data:toInt() + losthp
				player:clearHistory()
				player:skip(sgs.Player_Play)
				data:setValue(count)
			end
		end
	end
}
--[[
	技能名：宗室（锁定技）
	相关武将：二将成名·刘表
	描述：你的手牌上限+X（X为现存势力数）。
	状态：验证通过
]]--
ZongshiGetKingdoms = function(targets, source)
	local kingdoms = {}
	table.insert(kingdoms, source:getKingdom())
	for _,target in sgs.qlist(targets) do
		local flag = true
		local kingdom = target:getKingdom()
		for _,k in pairs(kingdoms) do
			if k == kingdom then
				flag = false
				break
			end
		end
		if flag then
			table.insert(kingdoms, kingdom)
		end
	end
	return kingdoms
end
LuaZongshi = sgs.CreateMaxCardsSkill{
	name = "LuaZongshi", 
	extra_func = function(self, target) 
		if target:hasSkill(self:objectName()) then
			local targets = target:getSiblings()
			local kingdoms = ZongshiGetKingdoms(targets, target)
			return #kingdoms
		end
	end
}
--[[
	技能名：纵火（锁定技）
	相关武将：倚天·陆伯言
	描述：你的杀始终带有火焰属性 
	状态：验证通过
]]--
LuaXZonghuo = sgs.CreateTriggerSkill{
	name = "LuaXZonghuo",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.SlashEffect},  
	on_trigger = function(self, event, player, data) 
		local effect = data:toSlashEffect()
		if effect.nature ~= sgs.DamageStruct_Fire then
			effect.nature = sgs.DamageStruct_Fire
			data:setValue(effect)
		end
		return false
	end
}
--[[
	技能名：醉乡（限定技）
	相关武将：☆SP·庞统
	描述：回合开始阶段开始时，你可以展示牌堆顶的3张牌并置于你的武将牌上，你不可使用或打出与该些牌同类的牌，所有同类牌对你无效。之后每个你的回合开始阶段，你须重复展示一次，直至该些牌中任意两张点数相同时，将你武将牌上的全部牌置于你的手上。
]]--
