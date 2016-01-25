--[[
	代码速查手册（G区）
	技能索引：
		甘露、感染、刚烈、刚烈、刚烈、刚烈、功獒、弓骑、弓骑、攻心、共谋、蛊惑、蛊惑、固守、固政、观星、归命、归汉、归心、归心、闺秀、鬼才、鬼道、国色
]]--
--[[
	技能名：甘露
	相关武将：一将成名·吴国太
	描述：出牌阶段限一次，你可以令装备区的装备牌数量差不超过你已损失体力值的两名角色交换他们装备区的装备牌。。
	引用：LuaGanlu
	状态：1217验证通过
]]--
swapEquip = function(first, second)
	local room = first:getRoom()
	local equips1, equips2 = sgs.IntList(), sgs.IntList()
	for _, equip in sgs.qlist(first:getEquips()) do
		equips1:append(equip:getId())
	end
	for _, equip in sgs.qlist(second:getEquips()) do
		equips2:append(equip:getId())
	end
	local exchangeMove = sgs.CardsMoveList()
	local move1 = sgs.CardsMoveStruct(equips1, second, sgs.Player_PlaceEquip, 
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, first:objectName(), second:objectName(), "LuaGanlu", ""))
	local move2 = sgs.CardsMoveStruct(equips2, first, sgs.Player_PlaceEquip,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, first:objectName(), second:objectName(), "LuaGanlu", ""))
	exchangeMove:append(move2)
	exchangeMove:append(move1)
	room:moveCards(exchangeMove, false)
end
LuaGanluCard = sgs.CreateSkillCard{
	name = "LuaGanluCard" ,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			local n1 = targets[1]:getEquips():length()
			local n2 = to_select:getEquips():length()
			return math.abs(n1 - n2) <= sgs.Self:getLostHp()
		else
			return false
		end
	end ,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		swapEquip(targets[1], targets[2])
	end
}
LuaGanlu = sgs.CreateViewAsSkill{
	name = "LuaGanlu" ,
	n = 0 ,
	view_as = function()
		return LuaGanluCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaGanluCard")
	end
}
--[[
	技能名：感染（锁定技）
	相关武将：僵尸·僵尸
	描述：你的装备牌都视为铁锁连环。
	引用：LuaXGanran
	状态：0405验证通过
]]--
LuaGanran = sgs.CreateFilterSkill{
	name = "LuaGanran",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return place == sgs.Player_PlaceHand and to_select:getTypeId() == sgs.Card_TypeEquip
	end,
	view_as = function(self, card)
		local ironchain = sgs.Sanguosha:cloneCard("iron_chain", card:getSuit(), card:getNumber())
		ironchain:setSkillName(self:objectName())
		local vs_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		vs_card:takeOver(ironchain)
		return vs_card
	end,
}
--[[
	技能名：刚烈
	相关武将：界限突破·夏侯惇
	描述：每当你受到1点伤害后，你可以进行判定：若结果为红色，你对伤害来源造成1点伤害；黑色，你弃置伤害来源一张牌。 
	引用：LuaGanglie
	状态：0405验证通过
]]--
LuaGanglie = sgs.CreateTriggerSkill{
	name = "LuaGanglie",
	events = {sgs.Damaged, sgs.FinishJudge},
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			local from = damage.from
			for i = 0, damage.damage - 1, 1 do
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.play_animation = false
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if (not from) or from:isDead() then return end
					if judge.card:isRed() then
						room:damage(sgs.DamageStruct(self:objectName(), player, from))
					elseif judge.card:isBlack() then
						if player:canDiscard(from, "he") then
							local id = room:askForCardChosen(player, from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
							room:throwCard(id, from, player)
						end
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = sgs.JudgeStruct()
			if judge.reason ~= self:objectName() then return false end
			judge.pattern = tostring(judge.card:getSuit())
		end
		return false
	end
}
--[[
	技能名：刚烈
	相关武将：标准·夏侯惇
	描述：每当你受到伤害后，你可以进行判定：若结果不为♥，则伤害来源选择一项：弃置两张手牌，或受到1点伤害。 
	引用：LuaNosGanglie
	状态：0405验证通过
]]--
LuaNosGanglie = sgs.CreateMasochismSkill{
	name = "LuaNosGanglie" ,
	on_damaged = function(self, player, damage)
		local from = damage.from
		local room = player:getRoom()
		local data = sgs.QVariant()
		data:setValue(damage)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if (not from) or from:isDead() then return end
			if judge:isGood() then
				if from:getHandcardNum() < 2 or not room:askForDiscard(from, self:objectName(), 2, 2, true) then
					room:damage(sgs.DamageStruct(self:objectName(), player, from))
				end
			end
		end
	end
}
--[[
	技能名：刚烈
	相关武将：2013-3v3·夏侯惇
	描述： 每当你受到伤害后，你可以选择一名对方角色并进行一次判定，若判定结果不为♥，则该角色选择一项：弃置两张手牌，或受到你造成的1点伤害。
	引用：LuaVsGanglie
	状态：1217验证通过
]]--
LuaVsGanglie = sgs.CreateMasochismSkill{
	name = "LuaVsGanglie",
	on_damaged = function(self,player)
		local room = player:getRoom()
		local mode = room:getMode()
		local function isFriend (a,b)
			return string.sub(a:getRole(),1,1) == string.sub(b:getRole(),1,1)
		end
		if mode:startsWith("06_") then
			local enemies = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers())do
				if not isFriend(player,p) then
					enemies:append(p)
				end
			end
			local from = room:askForPlayerChosen(player,enemies,self:objectName(),"vsganglie-invoke", true, true)
			if from then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if judge:isGood() then
					if from:getHandcardNum() < 2 then
						room:damage(sgs.DamageStruct(self:objectName(), player, from))
					else
						if not room:askForDiscard(from, self:objectName(), 2, 2, true) then
							room:damage(sgs.DamageStruct(self:objectName(), player, from))
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：刚烈
	相关武将：翼·夏侯惇
	描述：每当你受到一次伤害后，你可以进行一次判定，若判定结果不为红桃，你选择一项：令伤害来源弃置两张手牌，或受到你对其造成的1点伤害。
	引用：LuaXNeoGanglie
	状态：1217验证通过
]]--
LuaXNeoGanglie = sgs.CreateTriggerSkill{
	name = "LuaXNeoGanglie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local from = damage.from
		local ai_data = sgs.QVariant()
		ai_data:setValue(from)
		if from and from:isAlive() then
			if room:askForSkillInvoke(player, self:objectName(), ai_data) then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if judge:isGood() then
					local choicelist = "damage"
					local flag = false
					if from:getHandcardNum() > 1 then
						choicelist = "damage+throw"
						flag = true
					end
					local choice
					if flag then
						choice = room:askForChoice(player, self:objectName(), choicelist)
					else
						choice = choicelist
					end
					if choice == "damage" then
						local damage = sgs.DamageStruct()
						damage.from = player
						damage.to = from
						room:setEmotion(player, "good")
						room:damage(damage)
					else
						room:askForDiscard(from, self:objectName(), 2, 2)
					end
				else
					room:setEmotion(player, "bad")
				end
			end
		end
	end
}
--[[
	技能名：功獒（锁定技）
	相关武将：SP·诸葛诞
	描述：每当一名其他角色死亡时，你增加1点体力上限，回复1点体力。 
	引用：LuaGongao
	状态：0405验证通过
]]--
LuaGongao = sgs.CreateTriggerSkill{
	name = "LuaGongao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:sendCompulsoryTriggerLog(player, self:objectName())
		local log = sgs.LogMessage()
		log.type = "#GainMaxHp"
		log.from = player
		log.arg = "1"
		room:sendLog(log)
		room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
		if player:isWounded() then
			room:recover(player, sgs.RecoverStruct(player))
		end
		return false
	end
}
--[[
	技能名：弓骑
	相关武将：一将成名2012·韩当
	描述：出牌阶段限一次，你可以弃置一张牌，令你于此回合内攻击范围无限，若你以此法弃置的牌为装备牌，你可以弃置一名其他角色的一张牌。 
	引用：LuaGongqi
	状态：1217验证通过
]]--
LuaGongqiCard = sgs.CreateSkillCard{
	name = "LuaGongqiCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(source,"InfinityAttackRange")
		local cd = sgs.Sanguosha:getCard(self:getSubcards():first())
		if cd:isKindOf("EquipCard") then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if source:canDiscard(p, "he") then _targets:append(p) end
			end
			if not _targets:isEmpty() then
				local to_discard = room:askForPlayerChosen(source, _targets, "LuaGongqi", "@gongqi-discard", true)
				if to_discard then
					room:throwCard(room:askForCardChosen(source, to_discard, "he", "LuaGongqi", false, sgs.Card_MethodDiscard), to_discard, source)
				end
			end
		end
	end
}
LuaGongqi = sgs.CreateViewAsSkill{
	name = "LuaGongqi" ,
	n = 1 ,
	view_filter = function(self, cards, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = LuaGongqiCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaGongqiCard")
	end
}
--[[
	技能名：弓骑
	相关武将：怀旧·韩当
	描述：你可以将一张装备牌当【杀】使用或打出。你以此法使用的【杀】无距离限制。
	引用：LuaNosGongqi、LuaNosGongqiTargetMod
	状态：1217验证通过
]]--
LuaNosGongqi = sgs.CreateViewAsSkill{
	name = "LuaNosGongqi" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if to_select:getTypeId() ~= sgs.Card_TypeEquip then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(to_select:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end ,
	view_as = function(self, cards)
		if #cards == 1 then
		local slash = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber())
		slash:addSubcard(cards[1])
		slash:setSkillName(self:objectName())
		return slash
		end
	end ,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
LuaNosGongqiTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaNosGongqi-target" ,

	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "LuaNosGongqi" then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：攻心
	相关武将：神·吕蒙，界·吕蒙
	描述：出牌阶段限一次，你可以观看一名其他角色的手牌，然后选择其中一张♥牌并选择一项：弃置之，或将之置于牌堆顶。
	引用：LuaGongxin
	状态：0405验证通过
]]--

LuaGongxinCard = sgs.CreateSkillCard{
	name = "LuaGongxinCard" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() --and not to_select:isKongcheng() 如果不想选择没有手牌的角色就加上这一句，源码是没有这句的
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if not effect.to:isKongcheng() then--如果加上了上面的那句，这句和对应的end可以删除
			local ids = sgs.IntList()
			for _, card in sgs.qlist(effect.to:getHandcards()) do
				if card:getSuit() == sgs.Card_Heart then
					ids:append(card:getEffectiveId())
				end
			end
			local card_id = room:doGongxin(effect.from, effect.to, ids)
			if (card_id == -1) then return end
			local result = room:askForChoice(effect.from, "LuaGongxin", "discard+put")
			effect.from:removeTag("LuaGongxin")
			if result == "discard" then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, effect.from:objectName(), nil, "LuaGongxin", nil)
				room:throwCard(sgs.Sanguosha:getCard(card_id), reason, effect.to, effect.from)
			else
				effect.from:setFlags("Global_GongxinOperator")
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(), nil, "LuaGongxin", nil)
				room:moveCardTo(sgs.Sanguosha:getCard(card_id), effect.to, nil, sgs.Player_DrawPile, reason, true)
				effect.from:setFlags("-Global_GongxinOperator")
			end
		end
	end
}	
LuaGongxin = sgs.CreateZeroCardViewAsSkill{
	name = "LuaGongxin" ,
	view_as = function()
		return LuaGongxinCard:clone()
	end ,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#LuaGongxinCard")
	end
}
--[[
	技能名：共谋
	相关武将：倚天·钟士季
	描述：回合结束阶段开始时，你可指定一名其他角色：其在摸牌阶段摸牌后，须给你X张手牌（X为你手牌数与对方手牌数的较小值），然后你须选择X张手牌交给对方
	引用：LuaXGongmou、LuaXGongmouExchange
	状态：1217验证通过
]]--
LuaXGongmou = sgs.CreateTriggerSkill{
	name = "LuaXGongmou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			if player:askForSkillInvoke(self:objectName()) then
				local players = room:getOtherPlayers(player)
				local target = room:askForPlayerChosen(player, players, self:objectName())
				target:gainMark("@conspiracy")
			end
		elseif phase == sgs.Player_Start then
			local players = room:getOtherPlayers(player)
			for _,p in sgs.qlist(players) do
				if p:getMark("@conspiracy") > 0 then
					p:loseMark("@conspiracy")
				end
			end
		end
		return false
	end
}
LuaXGongmouExchange = sgs.CreateTriggerSkill{
	name = "#LuaXGongmouExchange",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			player:loseMark("@conspiracy")
			local room = player:getRoom()
			local source = room:findPlayerBySkillName("LuaXGongmou")
			if source then
				local thisCount = player:getHandcardNum()
				local thatCount = source:getHandcardNum()
				local x = math.min(thatCount, thisCount)
				if x > 0 then
					local to_exchange = nil
					if thisCount == x then
						to_exchange = player:wholeHandCards()
					else
						to_exchange = room:askForExchange(player, "LuaXGongmou", x)
					end
					room:moveCardTo(to_exchange, source, sgs.Player_PlaceHand, false)
					to_exchange = room:askForExchange(source, "LuaXGongmou", x)
					room:moveCardTo(to_exchange, player, sgs.Player_PlaceHand, false)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:getMark("@conspiracy") > 0
		end
		return false
	end,
	priority = -2
}
--[[
	技能名：蛊惑
	相关武将：风·于吉
	描述：你可以扣置一张手牌当做一张基本牌或非延时锦囊牌使用或打出，其他角色选择是否质疑：若无角色质疑，你展示该牌，取消不合法的目标并按你所述类型结算；若有角色质疑，中止质疑询问并展示该牌：若该牌为真，该角色获得“缠怨”（锁定技。你不能质疑“蛊惑”。若你的体力值为1，你的其他武将技能无效。），取消不合法的目标并按你所述类型结算；若该牌为假，你将其置入弃牌堆。每名角色的回合限一次。 
	引用：guhuo_new
	状态：0405验证通过(需配合本手册的缠怨一起使用)不知是否还有隐藏的问题
]]--
function guhuo(self, yuji)
	local room = yuji:getRoom()
	local players = room:getOtherPlayers(yuji)
	local used_cards = sgs.IntList()
	local moves = sgs.CardsMoveList()
	for _, card_id in sgs.qlist(self:getSubcards()) do
		used_cards:append(card_id)
	end
	--room:setTag("GuhuoType", self:getUserString())
	local questioned = nil
	for _, player in sgs.qlist(players) do
		if player:hasSkill("LuaChanyuan") then
			room:notifySkillInvoked(player, "LuaChanyuan")
			room:setEmotion(player, "no-question")
			continue
		end
		local choice = room:askForChoice(player, "LuaGuhuo", "noquestion+question")
		if choice == "question" then
			room:setEmotion(player, "question")
		else
			room:setEmotion(player, "no-question")
		end
		if choice == "question" then
			questioned = player
			break
		end
	end
	local success = false
	if not questioned then
		success = true
		for _, player in sgs.qlist(players) do
			room:setEmotion(player, ".")
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, yuji:objectName(), "", "LuaGuhuo")
		local move = sgs.CardsMoveStruct(used_cards, yuji, nil, sgs.Player_PlaceUnknown, sgs.Player_PlaceTable, reason)
		moves:append(move)
		room:moveCardsAtomic(moves, true)
	else
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if self:getUserString() and self:getUserString() == "peach+analeptic" then
			success = card:objectName() == yuji:getTag("GuhuoSaveSelf"):toString()
		elseif self:getUserString() and self:getUserString() == "slash" then
			success = string.find(card:objectName(),"slash")
		elseif self:getUserString() and self:getUserString() == "normal_slash" then
			success = card:objectName() == "slash"
		else
			success = card:match(self:getUserString())
		end
		if success then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, yuji:objectName(), "", "LuaGuhuo")
			local move = sgs.CardsMoveStruct(used_cards, yuji, nil, sgs.Player_PlaceUnknown, sgs.Player_PlaceTable, reason)
			moves:append(move)
			room:moveCardsAtomic(moves, true)
		else
			room:moveCardTo(self, yuji, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, yuji:objectName(), "", "LuaGuhuo"), true)
		end
		for _, player in sgs.qlist(players) do
			room:setEmotion(player, ".")
			if success and questioned:objectName() == player:objectName() then
				room:acquireSkill(questioned, "LuaChanyuan")
			end
		end
	end
	yuji:removeTag("GuhuoSaveSelf")
	yuji:removeTag("GuhuoSlash")
	room:setPlayerFlag(yuji, "GuhuoUsed")
	return success
end
LuaGuhuoCard = sgs.CreateSkillCard {
	name = "LuaGuhuoCard",
    will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local players = sgs.PlayerList()
		for i = 1 , #targets do
			players:append(targets[i])
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card = nil
			if self:getUserString() and self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				return card and card:targetFilter(players, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, players)
			end
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local _card = sgs.Self:getTag("LuaGuhuo"):toCard()
		if _card == nil then
			return false
		end
		local card = sgs.Sanguosha:cloneCard(_card)
		card:setCanRecast(false)
		card:deleteLater()
		return card and card:targetFilter(players, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, players)
	end ,
	feasible = function(self, targets)
		local players = sgs.PlayerList()
		for i = 1 , #targets do
			players:append(targets[i])
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card = nil
			if self:getUserString() and self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				return card and card:targetsFeasible(players, sgs.Self)
			end
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local _card = sgs.Self:getTag("LuaGuhuo"):toCard()
		if _card == nil then
			return false
		end
		local card = sgs.Sanguosha:cloneCard(_card)
		card:setCanRecast(false)
		card:deleteLater()
		return card and card:targetsFeasible(players, sgs.Self)
	end ,
	on_validate = function(self, card_use)
		local yuji = card_use.from
		local room = yuji:getRoom()
		local to_guhuo = self:getUserString()
		if to_guhuo == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			local sts = sgs.GetConfig("BanPackages", "")
			if not string.find(sts, "maneuvering") then
				table.insert(guhuo_list, "normal_slash")
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			to_guhuo = room:askForChoice(yuji, "guhuo_slash", table.concat(guhuo_list, "+"))
			yuji:setTag("GuhuoSlash", sgs.QVariant(to_guhuo))
		end
		if guhuo(self, yuji) then
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			local user_str = ""
			if to_guhuo == "slash"  then
				if card:isKindOf("Slash") then
					user_str = card:objectName()
				else
					user_str = "slash"
				end
			elseif to_guhuo == "normal_slash" then
				user_str = "slash"
			else
				user_str = to_guhuo
			end
			--yuji:setTag("GuhuoSlash", sgs.QVariant(user_str))
			local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
			use_card:setSkillName("LuaGuhuo")
			use_card:addSubcard(self:getSubcards():first())
			use_card:deleteLater()
			local tos = card_use.to
			for _, to in sgs.qlist(tos) do
				local skill = room:isProhibited(yuji, to, use_card)
				if skill then
					card_use.to:removeOne(to)
				end
			end
			return use_card
		else
			return nil
		end
	end ,
	on_validate_in_response = function(self, yuji)
		local room = yuji:getRoom()
		local to_guhuo = ""
		if self:getUserString() == "peach+analeptic" then
			local guhuo_list = {}
			table.insert(guhuo_list, "peach")
			local sts = sgs.GetConfig("BanPackages", "")
			if not string.find(sts, "maneuvering") then
				table.insert(guhuo_list, "analeptic")
			end
			to_guhuo = room:askForChoice(yuji, "guhuo_saveself", table.concat(guhuo_list, "+"))
			yuji:setTag("GuhuoSaveSelf", sgs.QVariant(to_guhuo))
		elseif self:getUserString() == "slash" then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			local sts = sgs.GetConfig("BanPackages", "")
			if not string.find(sts, "maneuvering") then
				table.insert(guhuo_list, "normal_slash")
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			to_guhuo = room:askForChoice(yuji, "guhuo_slash", table.concat(guhuo_list, "+"))
			yuji:setTag("GuhuoSlash", sgs.QVariant(to_guhuo))
		else
			to_guhuo = self:getUserString()
		end
		if guhuo(self, yuji) then
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			local user_str = ""
			if to_guhuo == "slash" then
				if card:isKindOf("Slash") then
					user_str = card:objectName()
				else
					user_str = "slash"
				end
			elseif to_guhuo == "normal_slash" then
				user_str = "slash"
			else
				user_str = to_guhuo
			end
			local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
			use_card:setSkillName("LuaGuhuo")
			use_card:addSubcard(self)
			use_card:deleteLater()
			return use_card
		else
			return nil
		end
	end
}
LuaGuhuo = sgs.CreateOneCardViewAsSkill{
	name = "LuaGuhuo",
	filter_pattern = ".|.|.|hand",
	response_or_use = true,
	enabled_at_response = function(self, player, pattern)
		local current = false
		local players = player:getAliveSiblings()
		players:append(player)
		for _, p in sgs.qlist(players) do
			if p:getPhase() ~= sgs.Player_NotActive then
				current = true
				break
			end
		end
		if not current then return false end
		if player:isKongcheng() or player:hasFlag("GuhuoUsed") or string.sub(pattern, 1, 1) == "." or string.sub(pattern, 1, 1) == "@" then
            return false
		end
        if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then return false end
        if string.find(pattern, "[%u%d]") then return false end--这是个极其肮脏的黑客！！ 因此我们需要去阻止基本牌模式
		return true
	end,
	enabled_at_play = function(self, player)
		local current = false
		local players = player:getAliveSiblings()
		players:append(player)
		for _, p in sgs.qlist(players) do
			if p:getPhase() ~= sgs.Player_NotActive then
				current = true
				break
			end
		end
		if not current then return false end
		return not player:isKongcheng() and not player:hasFlag("GuhuoUsed")
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card = LuaGuhuoCard:clone()
			card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
			card:addSubcard(cards)
			return card
		end
		local c = sgs.Self:getTag("LuaGuhuo"):toCard()
        if c then
            local card = LuaGuhuoCard:clone()
            if not string.find(c:objectName(), "slash") then
                card:setUserString(c:objectName())
            else
				card:setUserString(sgs.Self:getTag("GuhuoSlash"):toString())
				card:setTargetFixed(c:targetFixed() or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
			end
			card:addSubcard(cards)
			return card
        else
			return nil
		end
	end,
	enabled_at_nullification = function(self, player)
		local current = player:getRoom():getCurrent()
		if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then return false end
		return not player:isKongcheng() and not player:hasFlag("GuhuoUsed")
	end
}
LuaGuhuo:setGuhuoDialog("lr")
LuaGuhuoClear = sgs.CreateTriggerSkill{
	name = "#LuaGuhuo-clear" ,
	events = {sgs.EventPhaseChanging} ,
	can_trigger = function(self, target)
		return target
	end ,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local room = player:getRoom()
        if change.to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag("GuhuoUsed") then
                    room:setPlayerFlag(p, "-GuhuoUsed")
				end
            end
        end
		return false
	end
}
--[[
	技能名：蛊惑
	相关武将：怀旧·于吉
	描述：你可以说出一张基本牌或非延时类锦囊牌的名称，并背面朝上使用或打出一张手牌。若无其他角色质疑，则亮出此牌并按你所述之牌结算。若有其他角色质疑则亮出验明：若为真，质疑者各失去1点体力；若为假，质疑者各摸一张牌。除非被质疑的牌为红桃且为真，此牌仍然进行结算，否则无论真假，将此牌置入弃牌堆。
	引用：LuaNosguhuo
	状态：1217验证通过	
]]--
function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end
local patterns = {"slash", "jink", "peach", "analeptic", "nullification", "snatch", "dismantlement", "collateral", "ex_nihilo", "duel", "fire_attack", "amazing_grace", "savage_assault", "archery_attack", "god_salvation", "iron_chain"}
if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
	table.insert(patterns, 2, "thunder_slash")
	table.insert(patterns, 2, "fire_slash")
	table.insert(patterns, 2, "normal_slash")
end
local slash_patterns = {"slash", "normal_slash", "thunder_slash", "fire_slash"}
function getPos(table, value)
	for i, v in ipairs(table) do
		if v == value then
			return i
		end
	end
	return 0
end
local pos = 0
guhuo_select = sgs.CreateSkillCard {
	name = "guhuo_select",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		local type = {}
		local basic = {}
		local sttrick = {}
		local mttrick = {}
		for _, cd in ipairs(patterns) do
			local card = sgs.Sanguosha:cloneCard(cd, sgs.Card_NoSuit, 0)
			if card then
				card:deleteLater()
				if card:isAvailable(source) then
					if card:getTypeId() == sgs.Card_TypeBasic then
						table.insert(basic, cd)
					elseif card:isKindOf("SingleTargetTrick") then
						table.insert(sttrick, cd)
					else
						table.insert(mttrick, cd)
					end
					if cd == "slash" then
						table.insert(basic, "normal_slash")
					end
				end
			end
		end
		if #basic ~= 0 then table.insert(type, "basic") end
		if #sttrick ~= 0 then table.insert(type, "single_target_trick") end
		if #mttrick ~= 0 then table.insert(type, "multiple_target_trick") end
		local typechoice = ""
		if #type > 0 then
			typechoice = room:askForChoice(source, "LuaNosguhuo", table.concat(type, "+"))
		end
		local choices = {}
		if typechoice == "basic" then
			choices = table.copyFrom(basic)
		elseif typechoice == "single_target_trick" then
			choices = table.copyFrom(sttrick)
		elseif typechoice == "multiple_target_trick" then
			choices = table.copyFrom(mttrick)
		end
		local pattern = room:askForChoice(source, "guhuo-new", table.concat(choices, "+"))
		if pattern then
			if string.sub(pattern, -5, -1) == "slash" then
				pos = getPos(slash_patterns, pattern)
				room:setPlayerMark(source, "GuhuoSlashPos", pos)
			end
			pos = getPos(patterns, pattern)
			room:setPlayerMark(source, "GuhuoPos", pos)
			room:askForUseCard(source, "@LuaNosguhuo", "@@LuaNosguhuo")			
		end
	end,
}
function questionOrNot(player)
	local room = player:getRoom()
	local yuji = room:findPlayerBySkillName("LuaNosguhuo")
	local guhuoname = room:getTag("GuhuoType"):toString()
	if guhuoname == "peach+analeptic" then guhuoname = "peach" end
	if guhuoname == "normal_slash" then guhuoname = "slash" end
	local guhuocard = sgs.Sanguosha:cloneCard(guhuoname, sgs.Card_NoSuit, 0)
	local guhuotype = guhuocard:getClassName()
	if guhuotype and guhuotype == "AmazingGrace" then return "noquestion" end
	if guhuotype:match("Slash") then
		if yuji:getState() ~= "robot" and math.random(1, 4) == 1 and not sgs.questioner then return "question" end
	end
	if math.random(1, 6) == 1 and player:getHp() >= 3 and player:getHp() > player:getLostHp() then return "question" end
	local players = room:getOtherPlayers(player)
	players = sgs.QList2Table(players)
	local x = math.random(1, 5)
	if sgs.questioner then return "noquestion" end
	local questioner = room:getOtherPlayers(player):at(0)
	return player:objectName() == questioner:objectName() and x ~= 1 and "question" or "noquestion"
end
function guhuo(self, yuji)
		local room = yuji:getRoom()
		local players = room:getOtherPlayers(yuji)
	
		local used_cards = sgs.IntList()
		local moves = sgs.CardsMoveList()
		for _, card_id in sgs.qlist(self:getSubcards()) do
			used_cards:append(card_id)
		end		
		local questioned = sgs.SPlayerList()
		for _, p  in sgs.qlist(players) do
			if p:hasSkill("LuaChanyuan") then
				local log = sgs.LogMessage()
				log.type = "#LuaChanyuan"
				log.from = yuji
				log.to:append(p)
				log.arg = "LuaChanyuan"
				room:sendLog(log)				
				room:notifySkillInvoked(p, "LuaChanyuan")
				room:setEmotion(p, "no-question")
			else
				local choice = "noquestion"
				if p:getState() == "online" then
					choice = room:askForChoice(p, "guhuo", "noquestion+question")
				else
					room:getThread():delay(sgs.GetConfig("OriginAIDelay", ""))
					choice = questionOrNot(p)
				end
				if choice == "question" then
					sgs.questioner = p
					room:setEmotion(p, "question")
					questioned:append(p)					
				else
					room:setEmotion(p, "no-question")					
				end			
				local log = sgs.LogMessage()
				log.type = "#GuhuoQuery"
				log.from = p
				log.arg = choice
				room:sendLog(log)				
			end
		end
		room:removeTag("GuhuoType")
		local log = sgs.LogMessage()
		log.type = "$GuhuoResult"
		log.from = yuji
		local subcards = self:getSubcards()
		log.card_str = tostring(subcards:first())
		room:sendLog(log)
		local success = false
		local canuse = false
		if questioned:isEmpty() then
			canuse = true
			for _, p in sgs.qlist(players) do
				room:setEmotion(p, ".")
			end			
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, yuji:objectName(), "", "guhuo")
			local move = sgs.CardsMoveStruct()
			move.card_ids = used_cards
			move.from = yuji
			move.to = nil
			move.to_place = sgs.Player_PlaceTable
			move.reason = reason
			moves:append(move)
			room:moveCardsAtomic(moves, true)
		else
			local card = sgs.Sanguosha:getCard(subcards:first())
			local user_string = self:getUserString()						
			if user_string == "peach+analeptic" then
				success = card:objectName() == yuji:getTag("GuhuoSaveSelf"):toString()
			elseif user_string == "slash" then
				success = string.sub(card:objectName(), -5, -1) == "slash"
			elseif user_string == "normal_slash" then
				success = card:objectName() == "slash"
			else
				success = card:match(user_string)
			end
			if success then
				for _, p in sgs.qlist(questioned) do
					room:loseHp(p)
				end
			else
				for _, p in sgs.qlist(questioned) do
					if p:isAlive() then
						p:drawCards(1)
					end
				end
			end
			if success and card:getSuit() == sgs.Card_Heart	then canuse = true end	
			if canuse then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, yuji:objectName(), "", "guhuo")
				local move = sgs.CardsMoveStruct()
				move.card_ids = used_cards
				move.from = yuji
				move.to = nil
				move.to_place = sgs.Player_PlaceTable
				move.reason = reason
				moves:append(move)
				room:moveCardsAtomic(moves, true)
			else
				room:moveCardTo(self, yuji, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, yuji:objectName(), "", "guhuo"), true)
			end
			for _, p in sgs.qlist(players) do
				room:setEmotion(p, ".")
			end			
		end
		yuji:removeTag("GuhuoSaveSelf")		
		return canuse
	end
LuaNosguhuoCard = sgs.CreateSkillCard {
	name = "LuaNosguhuo",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	player = nil,
	on_use = function(self, room, source)
		player = source
	end,
	filter = function(self, targets, to_select, player)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@LuaNosguhuo" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("guhuo")
			end
			if card and card:targetFixed() then
				return false
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end		
		local pattern = patterns[player:getMark("GuhuoPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("guhuo")
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,	
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@LuaNosguhuo" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end		
		local pattern = patterns[player:getMark("GuhuoPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		return card and card:targetFixed()
	end,	
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@LuaNosguhuo" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("guhuo")
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetsFeasible(qtargets, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end		
		local pattern = patterns[sgs.Self:getMark("GuhuoPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("guhuo")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,	
	on_validate = function(self, card_use)
		local yuji = card_use.from
		local room = yuji:getRoom()		
		local to_guhuo = self:getUserString()		
		if to_guhuo == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@LuaNosguhuo" then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "normal_slash")
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			to_guhuo = room:askForChoice(yuji, "guhuo_slash", table.concat(guhuo_list, "+"))
			pos = getPos(slash_patterns, to_guhuo)
			room:setPlayerMark(yuji, "GuhuoSlashPos", pos)
		end
		room:broadcastSkillInvoke("guhuo")		
		local log = sgs.LogMessage()
		if card_use.to:isEmpty() then
			log.type = "#GuhuoNoTarget"
		else
			log.type = "#Guhuo"
		end
		log.from = yuji
		log.to = card_use.to
		log.arg = to_guhuo
		log.arg2 = "guhuo"		
		room:sendLog(log)		
		room:setTag("GuhuoType", sgs.QVariant(self:getUserString()))		
		if guhuo(self, yuji) then
			local subcards = self:getSubcards()
			local card = sgs.Sanguosha:getCard(subcards:first())
			local user_str
			if to_guhuo == "slash"  then
				if card:isKindOf("Slash") then
					user_str = card:objectName()
				else
					user_str = "slash"
				end
			elseif to_guhuo == "normal_slash" then
				user_str = "slash"
			else
				user_str = to_guhuo
			end
			local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
			use_card:setSkillName("guhuo")
			use_card:addSubcard(card)
			use_card:deleteLater()			
			return use_card
		else
			return nil
		end
	end,
	on_validate_in_response = function(self, yuji)
		local room = yuji:getRoom()
		room:broadcastSkillInvoke("guhuo")		
		local to_guhuo
		if self:getUserString() == "peach+analeptic" then
			local guhuo_list = {}
			table.insert(guhuo_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "analeptic")
			end
			to_guhuo = room:askForChoice(yuji, "guhuo_saveself", table.concat(guhuo_list, "+"))
			yuji:setTag("GuhuoSaveSelf", sgs.QVariant(to_guhuo))
		elseif self:getUserString() == "slash" then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "normal_slash")
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			to_guhuo = room:askForChoice(yuji, "guhuo_slash", table.concat(guhuo_list, "+"))
			pos = getPos(slash_patterns, to_guhuo)
			room:setPlayerMark(yuji, "GuhuoSlashPos", pos)
		else
			to_guhuo = self:getUserString()
		end		
		local log = sgs.LogMessage()
		log.type = "#GuhuoNoTarget"
		log.from = yuji
		log.arg = to_guhuo
		log.arg2 = "guhuo"
		room:sendLog(log)		
		room:setTag("GuhuoType", sgs.QVariant(self:getUserString()))		
		if guhuo(self, yuji) then
			local subcards = self:getSubcards()
			local card = sgs.Sanguosha:getCard(subcards:first())
			local user_str
			if to_guhuo == "slash" then
				if card:isKindOf("Slash") then
					user_str = card:objectName()
				else
					user_str = "slash"
				end
			elseif to_guhuo == "normal_slash" then
				user_str = "slash"
			else
				user_str = to_guhuo
			end
			local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
			use_card:setSkillName("guhuo")
			use_card:addSubcard(subcards:first())
			use_card:deleteLater()
			return use_card
		else
			return nil
		end
	end
}
LuaNosguhuo = sgs.CreateViewAsSkill {
	name = "LuaNosguhuo",	
	n = 1,	
	enabled_at_response = function(self, player, pattern)
		if pattern == "@LuaNosguhuo" then
			return not player:isKongcheng() 
		end		
		if player:isKongcheng() or string.sub(pattern, 1, 1) == "." or string.sub(pattern, 1, 1) == "@" then
			return false
		end
		if pattern == "peach" and player:hasFlag("Global_PreventPeach") then return false end
		return true
	end,	
	enabled_at_play = function(self, player)				
		return not player:isKongcheng()
	end,	
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if sgs.Sanguosha:getCurrentCardUsePattern() == "@LuaNosguhuo" then
				local pattern = patterns[sgs.Self:getMark("GuhuoPos")]
				if pattern == "normal_slash" then pattern = "slash" end
				local c = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
				if c and #cards == 1 then
					c:deleteLater()
					local card = LuaNosguhuoCard:clone()
					if not string.find(c:objectName(), "slash") then
						card:setUserString(c:objectName())
					else
						card:setUserString(slash_patterns[sgs.Self:getMark("GuhuoSlashPos")])
					end
					card:addSubcard(cards[1])
					return card
				else
					return nil
				end
			elseif #cards == 1 then
				local card = LuaNosguhuoCard:clone()
				card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
				card:addSubcard(cards[1])
				return card
			else
				return nil
			end
		elseif #cards == 0 then
			local cd = guhuo_select:clone()
			return cd
		end
	end,	
	enabled_at_nullification = function(self, player)				
		return not player:isKongcheng() 
	end
}
--[[
	技能名：固守
	相关武将：智·田丰
	描述：回合外，当你使用或打出一张基本牌时，可以摸一张牌
	引用：LuaXGushou
	状态：1217验证通过
]]--
LuaGushou = sgs.CreateTriggerSkill{
	name = "LuaGushou" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardUsed, sgs.CardResponded} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getCurrent():objectName() == player:objectName() then return false end
		local card = nil
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		else
			card = data:toCardResponse().m_card
		end
		if card and card:isKindOf("BasicCard") then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				player:drawCards(1)
			end
		end
		return false
	end
}
--[[
	技能名：固政
	相关武将：山·张昭张纮
	描述：其他角色的弃牌阶段结束时，你可以将该角色于此阶段内弃置的一张牌从弃牌堆返回其手牌，若如此做，你可以获得弃牌堆里其余于此阶段内弃置的牌。
	引用：LuaGuzheng、LuaGuzhengGet
	状态：1217验证通过
	附注：以字符串形式保存卡牌id
]]--
function strcontain(a, b)
	if a == "" then return false end
	local c = a:split("+")
	local k = false
	for i=1, #c, 1 do
		if a[i] == b then
			k = true
			break
		end
	end
	return k
end
LuaGuzheng = sgs.CreateTriggerSkill{
	name = "LuaGuzheng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local erzhang = room:findPlayerBySkillName(self:objectName())
		local current = room:getCurrent()
		local move = data:toMoveOneTime()
		local source = move.from
		if source then
			if player:objectName() == source:objectName() then
				if erzhang and erzhang:objectName() ~= current:objectName() then
					if current:getPhase() == sgs.Player_Discard then
						local tag = room:getTag("GuzhengToGet")
						local guzhengToGet= tag:toString()
						tag = room:getTag("GuzhengOther")
						local guzhengOther = tag:toString()
						if guzhengToGet == nil then
							guzhengToGet = ""
						end
						if guzhengOther == nil then
							guzhengOther = ""
						end
						for _,card_id in sgs.qlist(move.card_ids) do
							local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
							if flag == sgs.CardMoveReason_S_REASON_DISCARD then
								if source:objectName() == current:objectName() then
									if guzhengToGet == "" then
										guzhengToGet = tostring(card_id)
									else
										guzhengToGet = guzhengToGet.."+"..tostring(card_id)
									end
								elseif not strcontain(guzhengToGet, tostring(card_id)) then
									if guzhengOther == "" then
										guzhengOther = tostring(card_id)
									else
										guzhengOther = guzhengOther.."+"..tostring(card_id)
									end
								end
							end
						end
						if guzhengToGet then
							room:setTag("GuzhengToGet", sgs.QVariant(guzhengToGet))
						end
						if guzhengOther then
							room:setTag("GuzhengOther", sgs.QVariant(guzhengOther))
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
LuaGuzhengGet = sgs.CreateTriggerSkill{
	name = "#LuaGuzhengGet",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		if not player:isDead() then
			local room = player:getRoom()
			local erzhang = room:findPlayerBySkillName(self:objectName())
			if erzhang then
				local tag = room:getTag("GuzhengToGet")
				local guzheng_cardsToGet
				local guzheng_cardsOther
				if tag then
					guzheng_cardsToGet = tag:toString():split("+")
				else
					return false
				end
				tag = room:getTag("GuzhengOther")
				if tag then
					guzheng_cardsOther = tag:toString():split("+")
				end
				room:removeTag("GuzhengToGet")
				room:removeTag("GuzhengOther")
				local cardsToGet = sgs.IntList()
				local cards = sgs.IntList()
				for i=1,#guzheng_cardsToGet, 1 do
					local card_data = guzheng_cardsToGet[i]
					if card_data == nil then return false end
					if card_data ~= "" then --弃牌阶段没弃牌则字符串为""
						local card_id = tonumber(card_data)
						if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
							cardsToGet:append(card_id)
							cards:append(card_id)
						end
					end
				end
				if guzheng_cardsOther then
					for i=1, #guzheng_cardsOther, 1 do
						local card_data = guzheng_cardsOther[i]
						if card_data == nil then return false end
						if card_data ~= "" then
							local card_id = tonumber(card_data)
							if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
								cardsToGet:append(card_id)
								cards:append(card_id)
							end
						end
					end
				end
				if cardsToGet:length() > 0 then
					local ai_data = sgs.QVariant()
					ai_data:setValue(cards:length())
					if erzhang:askForSkillInvoke(self:objectName(), ai_data) then
						room:fillAG(cards, erzhang)
						local to_back = room:askForAG(erzhang, cardsToGet, false, self:objectName())
						local backcard = sgs.Sanguosha:getCard(to_back)
						player:obtainCard(backcard)
						cards:removeOne(to_back)
						erzhang:invoke("clearAG")
						local move = sgs.CardsMoveStruct()
						move.card_ids = cards
						move.to = erzhang
						move.to_place = sgs.Player_PlaceHand
						room:moveCardsAtomic(move, true)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:getPhase() == sgs.Player_Discard
		end
		return false
	end
}
--[[
	技能名：观星
	相关武将：标准·诸葛亮、山·姜维、SP·台版诸葛亮
	描述：准备阶段开始时，你可以观看牌堆顶的X张牌，然后将任意数量的牌以任意顺序置于牌堆顶，将其余的牌以任意顺序置于牌堆底。（X为存活角色数且至多为5）。
	引用：LuaGuanxing
	状态：1217验证通过（仅在原来基础修改askForGuanxing）
]]--
LuaGuanxing = sgs.CreateTriggerSkill{
	name = "LuaGuanxing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local count = room:alivePlayerCount()
				if count > 5 then
					count = 5
				end
				local cards = room:getNCards(count)
				room:askForGuanxing(player,cards)
			end
		end
	end
}
--[[
	技能名：归命（主公技、锁定技）
	相关武将：SP·孙皓
	描述：其他吴势力角色于你的回合内视为已受伤的角色。 
	引用：LuaGuiming
	状态：Lua无法实现，可以考虑写在残蚀里
]]--
--[[
	技能名：归汉
	相关武将：倚天·蔡昭姬
	描述：出牌阶段，你可以主动弃置两张相同花色的红色手牌，和你指定的一名其他存活角色互换位置。每阶段限一次
	引用：LuaGuihan
	状态：1217验证通过
]]--
LuaGuihanCard = sgs.CreateSkillCard{
	name = "LuaGuihan" ,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		effect.from:getRoom():swapSeat(effect.from, effect.to)
	end
}
LuaGuihan = sgs.CreateViewAsSkill{
	name = "LuaGuihan" ,
	n = 2 ,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		if #selected == 0 then
			return to_select:isRed()
		elseif (#selected == 1) then
			local suit = selected[1]:getSuit()
			return to_select:getSuit() == suit
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local card = LuaGuihanCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaGuihanCard")
	end
}
--[[
	技能名：归心
	相关武将：神·曹操
	描述：每当你受到1点伤害后，你可以依次获得所有其他角色区域内的一张牌，然后将武将牌翻面。 
	引用：LuaGuixin
	状态：0405验证通过
]]--
LuaGuixin = sgs.CreateMasochismSkill{
	name = "LuaGuixin" ,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local n = player:getMark("LuaGuixinTimes")--这个标记为了ai
		player:setMark("LuaGuixinTimes", 0)
		local data = sgs.QVariant()
		data:setValue(damage)
		local players = room:getOtherPlayers(player)
		for i = 0, damage.damage - 1, 1 do
			player:addMark("LuaGuixinTimes")
			if player:askForSkillInvoke(self:objectName(), data) then
				player:setFlags("LuaGuixinUsing")
				for _, p in sgs.qlist(players) do
					if p:isAlive() and (not p:isAllNude()) then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						local card_id = room:askForCardChosen(player, p, "hej", self:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					end
				end
				player:turnOver()
				player:setFlags("-LuaGuixinUsing")
			else
				break
			end
		end
		player:setMark("LuaGuixinTimes", n)
	end
}
--[[
	技能名：归心
	相关武将：倚天·魏武帝
	描述：回合结束阶段，你可以做以下二选一：\
	  1. 永久改变一名其他角色的势力\
	  2. 永久获得一项未上场或已死亡角色的主公技。(获得后即使你不是主公仍然有效)"
	引用：LuaXWeiwudiGuixin
	状态：1217验证通过
]]--
LuaXWeiwudiGuixin = sgs.CreateTriggerSkill{
	name = "LuaXWeiwudiGuixin",
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if room:askForSkillInvoke(player, self:objectName()) then
				local choice = room:askForChoice(player, self:objectName(), "modify+obtain")
				local others = room:getOtherPlayers(player)
				if choice == "modify" then
					local to_modify = room:askForPlayerChosen(player, others, self:objectName())
					local ai_data = sgs.QVariant()
					ai_data:setValue(to_modify)
					room:setTag("Guixin2Modify", ai_data)
					local kingdom = room:askForChoice(player, self:objectName(), "wei+shu+wu+qun")
					room:removeTag("Guixin2Modify")
					local old_kingdom = to_modify:getKingdom()
					room:setPlayerProperty(to_modify, "kingdom", sgs.QVariant(kingdom))
				elseif choice == "obtain" then
					local lords = sgs.Sanguosha:getLords()
					for _, p in sgs.qlist(others) do
						table.removeOne(lords, p:getGeneralName())
					end
					local lord_skills = {}
					for _, lord in ipairs(lords) do
						local general = sgs.Sanguosha:getGeneral(lord)
						local skills = general:getSkillList()
						for _, skill in sgs.qlist(skills) do
							if skill:isLordSkill() then
								if not player:hasSkill(skill:objectName()) then
									table.insert(lord_skills, skill:objectName())
								end
							end
						end
					end
					if #lord_skills > 0 then
						local choices = table.concat(lord_skills, "+")
						local skill_name = room:askForChoice(player, self:objectName(), choices)
						local skill = sgs.Sanguosha:getSkill(skill_name)
						room:acquireSkill(player, skill)
						local jiemingEX = sgs.Sanguosha:getTriggerSkill(skill:objectName())
						jiemingEX:trigger(sgs.GameStart, room, player, sgs.QVariant())
					end
				end
			end
		end
	end,
}
--[[
	技能名：闺秀
	相关武将：势·糜夫人
	描述：每当你失去“闺秀”后，你可以回复1点体力。限定技，准备阶段开始时或出牌阶段，你可以摸两张牌。 
	引用：LuaGuixiu、LuaGuixiuDetach
	状态：1217验证通过
]]--
LuaGuixiuCard = sgs.CreateSkillCard{
	name = "LuaGuixiuCard",
	target_fixed = true,

	on_use = function(self, room, source, targets)
		room:removePlayerMark(source,"Luaguixiu")
		source:drawCards(2,"LuaGuixiu")
	end
}
LuaGuixiuVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaGuixiu" ,

	view_as = function()
		return LuaGuixiuCard:clone()
	end,
	
	enabled_at_play = function(self, player)
		return player:getMark("Luaguixiu") >= 1
	end
}
LuaGuixiu = sgs.CreateTriggerSkill{
	name = "LuaGuixiu" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "Luaguixiu",
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaGuixiuVS ,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("Luaguixiu") >= 1 and player:getPhase() == sgs.Player_Start and room:askForSkillInvoke(player, self:objectName()) then
			room:removePlayerMark(player,"Luaguixiu")
			player:drawCards(2,self:objectName())
		end
	end
}
LuaGuixiuDetach = sgs.CreateTriggerSkill{
	name = "#LuaGuixiuDetach" ,
	events = {sgs.EventLoseSkill},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if data:toString() == "LuaGuixiu" then
		if player:isWounded() and room:askForSkillInvoke(player,"guixiu_rec",sgs.QVariant("recover")) then
			room:notifySkillInvoked(player,"LuaGuixiu")
		local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player,recover)
			end
		end
	end
}
--[[
	技能名：鬼才
	相关武将：界限突破·司马懿
	描述：每当一名角色的判定牌生效前，你可以打出一张牌代替之。 
	引用：LuaGuicai
	状态：0405验证通过
]]--
LuaGuicai = sgs.CreateTriggerSkill{
	name = "LuaGuicai" ,
	events = {sgs.AskForRetrial} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isKongcheng() then return false end
		local judge = data:toJudge()
		local prompt_list = {
			"@guicai-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			string.format("%d", judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local forced = false
		if player:getMark("JilveEvent") == sgs.AskForRetrial then forced = true end
		local askforcardpattern = "."
		if forced then askforcardpattern = ".!" end
		local card = room:askForCard(player, askforcardpattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if forced and (card == nil) then
			card = player:getRandomHandCard()
		end
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end
}
--[[
	技能名：鬼才
	相关武将：标准·司马懿
	描述：每当一名角色的判定牌生效前，你可以打出一张手牌代替之。
	引用：LuaNosGuicai
	状态：0405验证通过
]]--
LuaNosGuicai = sgs.CreateTriggerSkill{
	name = "LuaNosGuicai" ,
	events = {sgs.AskForRetrial} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isKongcheng() then return false end
		local judge = data:toJudge()
		local prompt_list = {
			"@nosguicai-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			tostring(judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
        local card = room:askForCard(player, ".", prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end
}
--[[
	技能名：鬼道
	相关武将：风·张角、旧风·张角
	描述：每当一名角色的判定牌生效前，你可以打出一张黑色牌替换之。
	引用：LuaGuidao
	状态：0405验证通过
]]--
LuaGuidao = sgs.CreateTriggerSkill{
	name = "LuaGuidao" ,
	events = {sgs.AskForRetrial} ,
	can_trigger = function(self, target)
		if not (target and target:isAlive() and target:hasSkill(self:objectName())) then return false end
		if target:isKongcheng() then
			local has_black = false
			for i = 0, 3, 1 do
				local equip = target:getEquip(i)
				if equip and equip:isBlack() then
					has_black = true
					break
				end
			end
			return has_black
		else
			return true
		end
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local prompt_list = {
			"@guidao-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			tostring(judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local card = room:askForCard(player, ".|black", prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName(), true)
		end
		return false
	end
}
--[[
	技能名：国色
	相关武将：标准·大乔、SP·台版大乔、SP·王战大乔
	描述：你可以将一张方块牌当【乐不思蜀】使用。
	引用：LuaGuose
	状态：1217验证通过
]]--
LuaGuose = sgs.CreateViewAsSkill{
	name = "LuaGuose",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Diamond
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		elseif #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local indulgence = sgs.Sanguosha:cloneCard("indulgence", suit, point)
			indulgence:addSubcard(id)
			indulgence:setSkillName(self:objectName())
			return indulgence
		end
	end
}
