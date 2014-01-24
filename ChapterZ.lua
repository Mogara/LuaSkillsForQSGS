--[[
	代码速查手册（Z区）
	技能索引：
		灾变、再起、凿险、早夭、战神、仗八、昭烈、昭心、昭心、贞烈、贞烈、鸩毒、镇威、镇卫、争锋、争功、争功、整军、直谏、直言、志继、制霸、制霸、制衡、智迟、智愚、忠义、咒缚、筑楼、追忆、惴恐、资粮、自立、自守、宗室、纵火、纵适、纵玄、醉乡
]]--
--[[
	技能名：灾变（锁定技）
	相关武将：僵尸·僵尸
	描述：你的出牌阶段开始时，若人类玩家数-僵尸玩家数+1大于0，你多摸该数目的牌。
]]--

--[[
	技能名：再起
	相关武将：林·孟获
	描述：摸牌阶段开始时，若你已受伤，你可以放弃摸牌，改为从牌堆顶亮出X张牌（X为你已损失的体力值），你回复等同于其中红桃牌数量的体力，然后将这些红桃牌置入弃牌堆，并获得其余的牌。
	引用：LuaZaiqi
	状态：0610验证通过
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
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_throw) do
							dummy:addSubcard(id)
						end
						local recover = sgs.RecoverStruct()
						recover.card = nil
						recover.who = player
						recover.recover = #card_to_throw
						room:recover(player, recover)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
						room:throwCard(dummy, reason, nil)
						has_heart = true
					end
					if #card_to_gotback > 0 then
						local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_gotback) do
							dummy2:addSubcard(id)
						end
						room:obtainCard(player, dummy2)
					end
					return true
				end
			end
		end
		return false
	end
}
--[[
	技能名：凿险（觉醒技）
	相关武将：山·邓艾
	描述：回合开始阶段开始时，若“田”的数量达到3或更多，你须减1点体力上限，并获得技能“急袭”。
	引用：LuaZaoxian
	状态：1217验证通过
]]--
LuaZaoxian = sgs.CreateTriggerSkill{
	name = "LuaZaoxian" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "LuaZaoxian")
		if room:changeMaxHpForAwakenSkill(player) then
			room:acquireSkill(player, "jixi")
		end
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
			and (target:getPhase() == sgs.Player_Start)
			and (target:getMark("LuaZaoxian") == 0)
			and (target:getPile("field"):length() >= 3)
	end
}
--[[
	技能名：早夭（锁定技）
	相关武将：倚天·曹冲
	描述：回合结束阶段开始时，若你的手牌大于13张，则你必须弃置所有手牌并流失1点体力
	引用：LuaZaoyao
	状态：1217验证通过
]]--
LuaZaoyao = sgs.CreateTriggerSkill{
	name = "LuaZaoyao" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if (player:getPhase() == sgs.Player_Finish) and (player:getHandcardNum() > 13) then
			player:throwAllHandCards()
			player:getRoom():loseHp(player)
		end
		return false
	end
}
--[[
	技能名：战神（觉醒技）
	相关武将：2013-3v3·吕布
	描述：准备阶段开始时，若你已受伤且有己方角色已死亡，你减1点体力上限，弃置装备区的武器牌，然后获得技能“马术”和“神戟”。
]]--
--[[
	技能名：仗八（锁定技）
	相关武将：长坂坡·神张飞
	描述：当你没有装备武器时，你的攻击范围始终为3。
]]--
--[[
	技能名：昭烈
	相关武将：☆SP·刘备
	描述：摸牌阶段摸牌时，你可以少摸一张牌，指定你攻击范围内的一名其他角色亮出牌堆顶上3张牌，将其中全部的非基本牌和【桃】置于弃牌堆，该角色进行二选一：你对其造成X点伤害，然后他获得这些基本牌；或他依次弃置X张牌，然后你获得这些基本牌。（X为其中非基本牌的数量）。
	引用：LuaZhaolie、LuaZhaolieAct
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
	技能名：昭心
	相关武将：贴纸·司马昭
	描述：摸牌阶段结束时，你可以展示所有手牌，若如此做，视为你使用一张【杀】，每阶段限一次。
	引用：LuaZhaoxin
	状态：1217验证通过
]]--
LuaZhaoxinCard = sgs.CreateSkillCard{
	name = "LuaZhaoxinCard" ,
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local tarlist = sgs.PlayerList()
		for i = 1, #targets, 1 do
			tarlist:append(targets[i])
		end
		return slash:targetFilter(tarlist, to_select, sgs.Self)
	end ,
	on_use = function(self, room, source, targets)
		room:showAllCards(source)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("_LuaZhaoxin")
		local tarlist = sgs.SPlayerList()
		for i = 1, #targets, 1 do
			tarlist:append(targets[i])
		end
		room:useCard(sgs.CardUseStruct(slash, source, tarlist))
	end
}
LuaZhaoxinVS = sgs.CreateViewAsSkill{
	name = "LuaZhaoxin" ,
	n = 0 ,
	view_as = function()
		return LuaZhaoxinCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "@@LuaZhaoxin") and sgs.Slash_IsAvailable(player)
	end ,
}
LuaZhaoxin = sgs.CreateTriggerSkill{
	name = "LuaZhaoxin" ,
	events = {sgs.EventPhaseEnd} ,
	view_as_skill = LuaZhaoxinVS ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Draw then return false end
		if player:isKongcheng() or (not sgs.Slash_IsAvailable(player)) then return false end
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(player:getRoom():getAllPlayers()) do
			if player:canSlash(p) then
				targets:append(p)
			end
		end
		if targets:isEmpty() then return false end
		player:getRoom():askForUseCard(player, "@@LuaZhaoxin", "@zhaoxin")
		return false
	end
}
--[[
	技能名：昭心
	相关武将：3D织梦·司马昭
	描述：出牌阶段，若你的手牌数不小于你的体力值，你可以展示你全部手牌。若其均为不同花色，你令一名角色失去1点体力。若其均为同一种花色，你获得一名其他角色一张牌。每阶段限一次。
]]--
--[[
	技能名：贞烈
	相关武将：一将成名2012·王异
	描述： 每当你成为一名其他角色使用的【杀】或非延时类锦囊牌的目标后，你可以失去1点体力，令此牌对你无效，然后你弃置其一张牌。
	引用：LuaZhenlie
	状态：1217验证通过
]]--
LuaZhenlie = sgs.CreateTriggerSkill{
	name = "LuaZhenlie" ,
	events = {sgs.TargetConfirmed, sgs.CardEffected, sgs.SlashEffected} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				local use = data:toCardUse()
				if use.to:contains(player) and (use.from:objectName() ~= player:objectName()) then
					if use.card:isKindOf("Slash") or use.card:isNDTrick() then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:setCardFlag(use.card, "LuaZhenlieNullify")
							player:setFlags("LuaZhenlieTarget")
							room:loseHp(player)
							if player:isAlive() and player:hasFlag("LuaZhenlieTarget") and player:canDiscard(use.from, "he") then
								local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
								room:throwCard(id, use.from, player)
							end
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if (not effect.card:isKindOf("Slash")) and effect.card:hasFlag("LuaZhenlieNullify") and player:hasFlag("LuaZhenlieTarget") then
				player:setFlags("-LuaZhenlieTarget")
				return true
			end
		elseif event == sgs.SlashEffected then
			local effect = data:toSlashEffect()
			if effect.slash:hasFlag("LuaZhenlieNullify") and player:hasFlag("LuaZhenlieTarget") then
				player:setFlags("-LuaZhenlieTarget")
				return true
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：贞烈·旧
	相关武将：怀旧-一将2·王异-旧
	描述：在你的判定牌生效前，你可以从牌堆顶亮出一张牌代替之。
	引用：LuaNosZhenlie
	状态：1217验证通过
]]--
LuaNosZhenlie = sgs.CreateTriggerSkill{
	name = "LuaNosZhenlie" ,
	events = {sgs.AskForRetrial} ,
	on_trigger = function(self, event, player, data)
		local judge = data:toJudge()
		if judge.who:objectName() ~= player:objectName() then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
			local room = player:getRoom()
			local card_id = room:drawCard()
			room:getThread():delay()
			local card = sgs.Sanguosha:getCard(card_id)
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end
}
--[[
	技能名：鸩毒
	相关武将：阵·何太后
	描述：每当一名其他角色的出牌阶段开始时，你可以弃置一张手牌：若如此做，视为该角色使用一张【酒】（计入限制），然后你对该角色造成1点伤害。 
]]--
--[[
	技能名：镇威
	相关武将：倚天·倚天剑
	描述：你的【杀】被手牌中的【闪】抵消时，可立即获得该【闪】。
	引用：LuaYTZhenwei
	状态：1217验证通过
]]--
LuaYTZhenwei = sgs.CreateTriggerSkill{
	name = "LuaYTZhenwei" ,
	events = {sgs.SlashMissed} ,
	on_trigger = function(self, event, player, data)
		local effect = data:toSlashEffect()
		if effect.jink and (player:getRoom():getCardPlace(effect.jink:getEffectiveId()) == sgs.Player_DiscardPile) then
			if player:askForSkillInvoke(self:objectName(), data) then
				player:obtainCard(effect.jink)
			end
		end
		return false
	end
}
--[[
	技能名：镇卫（锁定技）
	相关武将：2013-3v3·文聘
	描述：对方角色与其他己方角色的距离+1。
]]--
--[[
	技能名：争锋（锁定技）
	相关武将：倚天·倚天剑
	描述：当你的装备区没有武器时，你的攻击范围为X，X为你当前体力值。
]]--
--[[
	技能名：争功
	相关武将：倚天·邓士载
	描述：其他角色的回合开始前，若你的武将牌正面向上，你可以将你的武将牌翻面并立即进入你的回合，你的回合结束后，进入该角色的回合
	引用：LuaXZhenggong
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
	技能名：争功(0610版)
	相关武将：倚天·邓士载
	描述：其他角色的回合开始前，若你的武将牌正面朝上，你可以进行一个额外的回合，然后将武将牌翻面。
	引用：LuaZhenggong610
	状态：1217验证通过
]]--
LuaZhenggong610 = sgs.CreateTriggerSkill{
	name = "LuaZhenggong610" ,
	events = {sgs.TurnStart} ,
	on_trigger = function(self, event, player, data)
		if not player then return false end
		local room = player:getRoom()
		local dengshizai = room:findPlayerBySkillName(self:objectName())
		if dengshizai and dengshizai:faceUp() then
			if dengshizai:askForSkillInvoke(self:objectName()) then
				dengshizai:gainAnExtraTurn()
				dengshizai:turnOver()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and not target:hasSkill(self:objectName())
	end
}
--[[
	技能名：争功
	相关武将：胆创·钟会
	描述：你每受到一次伤害，可以获得伤害来源装备区中的一张牌并立即放入你的装备区。
]]--
--[[
	技能名：整军（锁定技）
	相关武将：长坂坡·神张飞
	描述：回合开始阶段，你弃X张牌（不足则全弃），回合结束阶段，你须将你的武将牌翻面并摸X+1张牌。X为你的攻击范围。
]]--
--[[
	技能名：直谏
	相关武将：山·张昭张纮
	描述：出牌阶段，你可以将手牌中的一张装备牌置于一名其他角色的装备区里（不能替换原装备），然后摸一张牌。
	引用：LuaZhijian
	状态：1217验证通过
]]--
LuaZhijianCard = sgs.CreateSkillCard{
	name = "LuaZhijianCard" ,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,

	filter = function(self, targets, to_select)
		if not #targets == 0 or to_select:objectName() == sgs.Self:objectName() then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end,
	
	on_effect = function(self, effect)
		local erzhang = effect.from
		erzhang:getRoom():moveCardTo(self, erzhang, effect.to, sgs.Player_PlaceEquip,
									sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,
													   erzhang:objectName(), self:objectName(), nil))
		erzhang:drawCards(1)
	end
}
LuaZhijian = sgs.CreateViewAsSkill{
	name = "LuaZhijian" ,
	n = 1 ,
	view_filter = function(self, cards, to_select)
		return (not to_select:isEquipped()) and (to_select:getTypeId() == sgs.Card_TypeEquip)
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local zhijian_card = LuaZhijianCard:clone()
		zhijian_card:addSubcard(cards[1])
		return zhijian_card
	end
}
--[[
	技能名：直言
	相关武将：一将成名2013·虞翻
	描述：结束阶段开始时，你可以令一名角色摸一张牌并展示之。若此牌为装备牌，该角色回复1点体力，然后使用之。
	引用：LuaZhiyan
	状态：1217验证通过
]]--
LuaZhiyan = sgs.CreateTriggerSkill{
	name = "LuaZhiyan" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Finish then return false end
		local room = player:getRoom()
		local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "LuaZhiyan-invoke", true, true)
		if to then
			local ids = room:getNCards(1, false)
			local card = sgs.Sanguosha:getCard(ids:first())
			room:obtainCard(to, card, false)
			if not to:isAlive() then return false end
			room:showCard(to, ids:first())
			if card:isKindOf("EquipCard") then
				if (to:isWounded()) then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(to, recover)
				end
				if to:isAlive() and (not to:isCardLimited(card, sgs.Card_MethodUse)) then
					room:useCard(sgs.CardUseStruct(card, to, to))
				end
			end
		end
		return false
	end
}
--[[
	技能名：志继（觉醒技）
	相关武将：山·姜维
	描述：回合开始阶段开始时，若你没有手牌，你须选择一项：回复1点体力，或摸两张牌。然后你减1点体力上限，并获得技能“观星”。
	引用：LuaZhiji
	状态：1217验证通过
]]--
LuaZhiji = sgs.CreateTriggerSkill{
	name = "LuaZhiji" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isWounded() then
			if room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			else
				room:drawCards(player, 2)
			end
		else
			room:drawCards(player, 2)
		end
		room:addPlayerMark(player, "LuaZhiji")
		if room:changeMaxHpForAwakenSkill(player) then
			room:acquireSkill(player, "guanxing")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("LuaZhiji") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and target:isKongcheng()
	end
}
--[[
	技能名：制霸（主公技）
	相关武将：山·孙策
	描述：出牌阶段限一次，其他吴势力角色的出牌阶段可以与你拼点（“魂姿”发动后，你可以拒绝此拼点）。若其没赢，你可以获得两张拼点的牌。
	引用：LuaSunceZhiba；LuaZhibaPindian（技能暗将）
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
	引用：LuaXZhiBa
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
	技能名：制衡
	相关武将：标准·孙权
	描述：出牌阶段限一次，你可以弃置任意数量的牌，然后摸等量的牌。
	引用：LuaZhiheng
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
	技能名：智迟（锁定技）
	相关武将：一将成名·陈宫
	描述：你的回合外，每当你受到一次伤害后，【杀】或非延时类锦囊牌对你无效，直到回合结束。
	引用：LuaZhichi、LuaZhichiProtect、LuaZhichiClear
	状态：0610验证通过
]]--
LuaZhichi = sgs.CreateTriggerSkill{
	name = "LuaZhichi" ,
	events = {sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		local current = room:getCurrent()
		if current and current:isAlive() and (current:getPhase() ~= sgs.Player_NotActive) then
			if player:getMark("@late") == 0 then
				room:addPlayerMark(player, "@late")
			end
		end
	end
}
LuaZhichiProtect = sgs.CreateTriggerSkill{
	name = "#LuaZhichi-protect" ,
	events = {sgs.CardEffected} ,
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if (effect.card:isKindOf("Slash") or effect.card:isNDTrick()) and (effect.to:getMark("@late") > 0) then
			return true
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
LuaZhichiClear = sgs.CreateTriggerSkill{
	name = "#LuaZhichi-clear" ,
	events = {sgs.EventPhaseChanging, sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		else
			local death = data:toDeath()
			if (death.who:objectName() ~= player:objectName()) or (player:objectName() ~= room:getCurrent():objectName()) then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("@late") > 0 then
				room:setPlayerMark(p, "@late", 0)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：智愚
	相关武将：二将成名·荀攸
	描述：每当你受到一次伤害后，你可以摸一张牌，然后展示所有手牌，若颜色均相同，伤害来源弃置一张手牌。
	引用：LuaZhiyu
	状态：1217验证通过
]]--
LuaZhiyu = sgs.CreateTriggerSkill{
	name = "LuaZhiyu" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			player:drawCards(1)
			local room = player:getRoom()
			if player:isKongcheng() then return false end
			room:showAllCards(player)
			local cards = player:getHandcards()
			local isred = cards:first():isRed()
			local same_color = true
			for _, card in sgs.qlist(cards) do
				if card:isRed() ~= isred then
					same_color = false
					break
				end
			end
			local damage = data:toDamage()
			if same_color and damage.from and damage.from:canDiscard(damage.from, "h") then
				room:askForDiscard(damage.from, self:objectName(), 1, 1)
			end
		end
	end
}
--[[
	技能名：忠义（限定技）
	相关武将：2013-3v3·关羽
	描述：出牌阶段，你可以将一张红色手牌置于武将牌上。若你有“忠义”牌，己方角色使用的【杀】对目标角色造成伤害时，此伤害+1。身份牌重置后，你将“忠义”牌置入弃牌堆。
]]--
--[[
	技能名：咒缚
	相关武将：SP·张宝
	描述：阶段技。你可以将一张手牌移出游戏并选择一名无“咒缚牌”的其他角色：若如此做，该角色进行判定时，以“咒缚牌”作为判定牌。一名角色的回合结束后，若该角色有“咒缚牌”，你获得该牌。 
]]--
--[[
	技能名：筑楼
	相关武将：翼·公孙瓒
	描述：回合结束阶段开始时，你可以摸两张牌，然后失去1点体力或弃置一张武器牌。
	引用：LuaXZhulou
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
	引用：LuaZhuiyi
	状态：1217验证通过
]]--
LuaZhuiyi = sgs.CreateTriggerSkill{
	name = "LuaZhuiyi" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local targets
		if death.damage and death.damage.from then
			targets = room:getOtherPlayers(death.damage.from)
		else
			targets = room:getAlivePlayers()
		end
		if targets:isEmpty() then return false end
		local prompt = "zhuiyi-invoke"
		if death.damage and death.damage.from and (death.damage.from:objectName() ~= player:objectName()) then
			prompt = "zhuiyi-invokex:" .. death.damage.from:objectName()
		end
		local target = room:askForPlayerChosen(player,targets,self:objectName(), prompt, true, true)
		if not target then return false end
		target:drawCards(3)
		local recover = sgs.RecoverStruct()
		recover.who = player
		recover.recover = 1
		room:recover(target, recover, true)
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
--[[
	技能名：惴恐
	相关武将：一将成名2013·伏皇后
	描述： 一名其他角色的回合开始时，若你已受伤，你可以与其拼点：若你赢，该角色跳过出牌阶段；若你没赢，该角色与你距离为1，直到回合结束。
]]--
--[[
	技能名：资粮
	相关武将：阵·邓艾
	描述：每当一名角色受到伤害后，你可以将一张“田”交给该角色。 
]]--
--[[
	技能名：自立（觉醒技）
	相关武将：一将成名·钟会
	描述：准备阶段开始时，若“权”大于或等于三张，你减1点体力上限，摸两张牌或回复1点体力，然后获得技能“排异”。
	引用：LuaZili
	状态：0610验证通过
	备注：觉醒获得的排异为自带技能
]]
LuaZili = sgs.CreateTriggerSkill{
	name = "LuaZili" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "LuaZili")
		if room:changeMaxHpForAwakenSkill(player) then
			if player:isWounded() then
				if room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				else
					room:drawCards(player, 2)
				end
			else
				room:drawCards(player, 2)
			end
			room:acquireSkill(player, "paiyi")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
		   and (target:getPhase() == sgs.Player_Start)
		   and (target:getMark("LuaZili") == 0)
		   and (target:getPile("power"):length() >= 3)
	end
}
--[[
	技能名：自立（觉醒技）
	相关武将：胆创·钟会
	描述：回合开始阶段开始时，若你的“权”为四张或更多时，你必须减1点体力上限，并永久获得技能“排异”。
]]--
--[[
	技能名：自守
	相关武将：二将成名·刘表
	描述：摸牌阶段，若你已受伤，你可以额外摸X张牌（X为你已损失的体力值），然后跳过你的出牌阶段。
	引用：LuaZishou
	状态：1217验证通过
]]--
LuaZishou = sgs.CreateTriggerSkill{
	name = "LuaZishou" ,
	events = {sgs.DrawNCards} ,
	on_trigger = function(self, event, player, data)
		local n = data:toInt()
		local room = player:getRoom()
		if player:isWounded() then
			if room:askForSkillInvoke(player, self:objectName()) then
				local losthp = player:getLostHp()
				player:clearHistory()
				player:skip(sgs.Player_Play)
				data:setValue(n + losthp)
			else
				data:setValue(n)
			end
		else
			data:setValue(n)
		end
	end
}
--[[
	技能名：宗室（锁定技）
	相关武将：二将成名·刘表
	描述：你的手牌上限+X（X为现存势力数）。
	引用：LuaZongshi
	状态：1217验证通过
]]--
LuaZongshi = sgs.CreateMaxCardsSkill{
	name = "LuaZongshi" ,
	extra_func = function(self, target)
		local extra = 0
		local kingdom_set = {}
		table.insert(kingdom_set, target:getKingdom())
		for _, p in sgs.qlist(target:getSiblings()) do
			local flag = true
			for _, k in ipairs(kingdom_set) do
				if p:getKingdom() == k then
					flag = false
					break
				end
			end
			if flag then table.insert(kingdom_set, p:getKingdom()) end
		end
		extra = #kingdom_set
		if target:hasSkill(self:objectName()) then
			return extra
		else
			return 0
		end
	end
}
--[[
	技能名：纵火（锁定技）
	相关武将：倚天·陆伯言
	描述：你的杀始终带有火焰属性
	引用：LuaZonghuo
	状态：1217验证通过
]]--
LuaZonghuo = sgs.CreateTriggerSkill{
	name = "LuaZonghuo" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, room, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (not use.card:isKindOf("FireSlash")) then
			local fire_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
			if not use.card:isVirtualCard() then
				fire_slash:addSubcard(use.card)
			elseif use.card:subcardsLength() > 0 then
				for _, id in sgs.qlist(use.card:getSubcards()) do
					fire_slash:addSubcard(id)
				end
			end
			fire_slash:setSkillName(self:objectName())
			use.card = fire_slash
			data:setValue(use)
		end
		return false
	end
}
--[[
	技能名：纵适
	相关武将：一将成名2013·简雍
	描述：每当你拼点赢，你可以获得对方的拼点牌。每当你拼点没赢，你可以获得你的拼点牌。
	引用：LuaZongshih
	状态：1217验证通过
]]--
LuaZongshih = sgs.CreateTriggerSkill{
	name = "LuaZongshih" ,
	events = {sgs.Pindian} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pindian = data:toPindian()
		local to_obtain = nil
		local jianyong = nil
		if (pindian.from and pindian.from:isAlive() and pindian.from:hasSkill(self:objectName())) then
			jianyong = pindian.from
			if pindian.from_number > pindian.to_number then
				to_obtain = pindian.to_card
			else
				to_obtain = pindian.from_card
			end
		elseif (pindian.to and pindian.to:isAlive() and pindian.to:hasSkill(self:objectName())) then
			jianyong = pindian.to
			if pindian.from_number < pindian.to_number then
				to_obtain = pindian.from_card
			else
				to_obtain = pindian.to_card
			end
		end
		if jianyong and to_obtain and (room:getCardPlace(to_obtain:getEffectiveId()) == sgs.Player_PlaceTable) then
			if room:askForSkillInvoke(jianyong, self:objectName(), data) then
				jianyong:obtainCard(to_obtain)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：纵玄
	相关武将：一将成名2013·虞翻
	描述：当你的牌因弃置而置入弃牌堆前，你可以将其中任意数量的牌以任意顺序依次置于牌堆顶。
	状态：0610验证通过（单机通过）
]]--
LuaZongxuanCard = sgs.CreateSkillCard{
	name = "LuaZongxuanCard",
	target_fixed = true,
	will_throw = false,
	handling_method =sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local sbs = source:getTag("LuaZongxuan"):toString():split("+")
		for _,cdid in sgs.qlist(self:getSubcards()) do table.insert(sbs, cdid)  end
		source:setTag("LuaZongxuan", sgs.QVariant(table.concat(sbs, "+")))
	end
}
LuaZongxuanVS = sgs.CreateViewAsSkill{
	name = "LuaZongxuan",
	n = 998,
	view_filter = function(self, selected, to_select)
		local str = sgs.Self:property("LuaZongxuan"):toString()
		return string.find(str, tostring(to_select:getEffectiveId())) end,
	view_as = function(self, cards)
		if #cards ~= 0 then
			local card = LuaZongxuanCard:clone()
			for var=1,#cards do card:addSubcard(cards[var]) end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern == "@@LuaZongxuan"
	end,
}
function listIndexOf(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
LuaZongxuan = sgs.CreateTriggerSkill{
	name = "LuaZongxuan",
	view_as_skill = LuaZongxuanVS,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		local move = data:toMoveOneTime()
		local source = move.from
		if source:objectName() ~= player:objectName() then return end
		local reason = move.reason.m_reason
		if move.to_place == sgs.Player_DiscardPile then
			if bit32.band(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				local zongxuan_card = sgs.IntList()
				for i=0, (move.card_ids:length()-1), 1 do
					local card_id = move.card_ids:at(i)
					if room:getCardOwner(card_id):getSeat() == source:getSeat()
						and (move.from_places:at(i) == sgs.Player_PlaceHand
						or move.from_places:at(i) == sgs.Player_PlaceEquip) then
						zongxuan_card:prepend(card_id)
					end
				end
				if zongxuan_card:isEmpty() then
					return
				end
				local zongxuantable = sgs.QList2Table(zongxuan_card)
				room:setPlayerProperty(player, "LuaZongxuan", sgs.QVariant(table.concat(zongxuantable, "+")))
				while not zongxuan_card:isEmpty() do
				if not room:askForUseCard(player, "@@LuaZongxuan", "@LuaZongxuanput") then break end
				local subcards = sgs.IntList()
				local subcards_variant = player:getTag("LuaZongxuan"):toString():split("+")
				if #subcards_variant>0 then
					for _,ids in ipairs(subcards_variant) do subcards:append(ids) end
					local zongxuan = player:property("LuaZongxuan"):toString():split("+")
					for _, id in sgs.qlist(subcards) do
						zongxuan_card:removeOne(id)
						table.removeOne(zongxuan,tonumber(id))
						if move.card_ids:contains(id) then
							move.from_places:removeAt(listIndexOf(move.card_ids, id))
							move.card_ids:removeOne(id)
							data:setValue(move)
						end
						room:setPlayerProperty(player, "zongxuan_move", sgs.QVariant(tonumber(id)))
						room:moveCardTo(sgs.Sanguosha:getCard(id), player, nil ,sgs.Player_DrawPile, move.reason, true)
						if not player:isAlive() then break end
					end
				end
				player:removeTag("LuaZongxuan")
				end
			end
		end
		return
	end,
}
--[[
	技能名：醉乡（限定技）
	相关武将：☆SP·庞统
	描述：准备阶段开始时，你可以将牌堆顶的三张牌置于你的武将牌上。此后每个准备阶段开始时，你重复此流程，直到你的武将牌上出现同点数的“醉乡牌”，然后你获得所有“醉乡牌”（不能发动“漫卷”）。你不能使用或打出“醉乡牌”中存在的类别的牌，且这些类别的牌对你无效。
]]--
