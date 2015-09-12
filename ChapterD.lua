--[[
	代码速查手册（D区）
	技能索引：
		大喝、大雾、单骑、胆守、啖酪、当先、缔盟、定品、洞察、毒士、毒医、黩武、短兵、断肠、断粮、断指、度势、夺刀
]]--
--[[
	技能名：大喝
	相关武将：☆SP·张飞
	描述：出牌阶段限一次，你可以与一名角色拼点：若你赢，你可以将该角色的拼点牌交给一名体力值不多于你的角色，本回合该角色使用的非♥【闪】无效；若你没赢，你展示所有手牌，然后弃置一张手牌。
	引用：LuaDahe、LuaDahePindian
	状态：0504验证通过
]]--
LuaDaheCard = sgs.CreateSkillCard{
	name = "LuaDaheCard",
	mute = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		source:pindian(targets[1], "LuaDahe", nil)
	end
}
LuaDaheVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaDahe",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaDaheCard") and not player:isKongcheng()
	end,
	view_as = function(self)
		return LuaDaheCard:clone()
	end,
}
LuaDahe = sgs.CreateTriggerSkill{
	name = "LuaDahe",
	events = {sgs.JinkEffect, sgs.EventPhaseChanging, sgs.Death},
	view_as_skill = LuaDaheVS,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.JinkEffect then
			local jink = data:toCard()
			local bgm_zhangfei = room:findPlayerBySkillName(self:objectName())
			if bgm_zhangfei and bgm_zhangfei:isAlive() and player:hasFlag(self:objectName()) and jink:getSuit() ~= sgs.Card_Heart then
				local log = sgs.LogMessage()
				log.from = bgm_zhangfei
				log.to:append(player)
				log.type = "#DaheEffect"
				log.arg = jink:getSuitString()
				log.arg2 = "LuaDahe"
				room:sendLog(log)
				
				return true
			end
			return false
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who ~= player then return false end
		end
		for _,other in sgs.qlist(room:getOtherPlayers(player)) do
			if other:hasFlag(self:objectName()) then
				room:setPlayerFlag(other, "-"..self:objectName())
			end
		end
		return false
	end
}
LuaDahePindian = sgs.CreateTriggerSkill{
	name = "#LuaDahe",
	events = {sgs.Pindian},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pindian = data:toPindian()
		if pindian.reason ~= "LuaDahe" or not pindian.from:hasSkill("LuaDahe") or room:getCardPlace(pindian.to_card:getEffectiveId()) ~= sgs.Player_PlaceTable then return false end
		if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
			room:setPlayerFlag(pindian.to, "LuaDahe")
			local to_givelist = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() <= pindian.from:getHp() then
					to_givelist:append(p)
				end
			end
			if not to_givelist:isEmpty() then
				local to_give = room:askForPlayerChosen(pindian.from, to_givelist, "LuaDahe", "@LuaDahe-give", true)
				if not to_give then return false end
				to_give:obtainCard(pindian.to_card)
			end
		else
			if not pindian.from:isKongcheng() then
				room:showAllCards(pindian.from)
				room:askForDiscard(pindian.from, "LuaDahe", 1, 1, false, false)
			end
		end
		return false
	end
}
--[[
	技能名：大雾
	相关武将：神·诸葛亮
	描述：结束阶段开始时，你可以将X张“星”置入弃牌堆并选择X名角色，若如此做，你的下回合开始前，每当这些角色受到的非雷电伤害结算开始时，防止此伤害。
	引用：LuaDawu
	状态：0405验证通过(需与本手册的“七星”配合使用)
	备注：医治永恒&水饺wch哥：源码狂风和大雾的技能询问与标记的清除分别位于七星的QixingAsk和QixingClear中，此技能独立出来了。
]]--
LuaDawuCard = sgs.CreateSkillCard{
	name = "LuaDawuCard",
	handling_method = sgs.Card_MethodNone,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < self:subcardsLength()
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "LuaDawu", "")
		room:throwCard(self, reason, nil)
		source:setTag("LuaQixing_user", sgs.QVariant(true))
		for _,p in ipairs(targets) do
			p:gainMark("@fog")
		end
	end,
}
LuaDawuVS = sgs.CreateViewAsSkill{
	name = "LuaDawu", 
	n = 998,
	response_pattern = "@@LuaDawu",
	expand_pile = "stars",
	view_filter = function(self, selected, to_select)
		return sgs.Self:getPile("stars"):contains(to_select:getId())
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local dw = LuaDawuCard:clone()
			for _,card in pairs(cards) do
				dw:addSubcard(card)
			end
			return dw
		end
		return nil
	end,
}
LuaDawu = sgs.CreateTriggerSkill{
	name = "LuaDawu",
	events = {sgs.DamageForseen},
	view_as_skill = LuaDawuVS,
	can_trigger = function(self, player)
		return player ~= nil and player:getMark("@fog") > 0
	end,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Thunder then
			return true
		else
			return false
		end
	end,
}
--[[
	技能名：单骑（觉醒技）
	相关武将：SP·关羽
	描述：准备阶段开始时，若你的手牌数大于体力值，且本局游戏主公为曹操，你减1点体力上限，然后获得技能“马术”。
	引用：LuaDanji
	状态：0405验证通过
]]--
LuaDanji = sgs.CreateTriggerSkill{
	name = "LuaDanji",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, target)
		return target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
			and target:getMark("danji") == 0 and target:getHandcardNum() > target:getHp()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local lord = room:getLord()
		if lord and (string.find(lord:getGeneralName(), "caocao") or string.find(lord:getGeneral2Name(), "caocao")) then
			room:setPlayerMark(player, "danji", 1)
			if room:changeMaxHpForAwakenSkill(player) and player:getMark("danji") == 1 then
				room:acquireSkill(player, "mashu")
			end
		end
	end,
}
--[[
	技能名：胆守
	相关武将：一将成名2013·朱然
	描述： 每当你造成伤害后，你可以摸一张牌，然后结束当前回合并结束一切结算。
	状态：Lua无法实现
]]--
luaNosDanshou = sgs.CreateTriggerSkill{
	name = "luaNosDanshou" ,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			player:drawCards(1, self:objectName())
			room:throwEvent(sgs.TurnBroken)
		end
		return false
	end
}
--[[
	技能名：啖酪
	相关武将：SP·杨修
	描述：每当至少两名角色成为锦囊牌的目标后，若你为目标角色，你可以摸一张牌，然后该锦囊牌对你无效。   
	引用：LuaDanlao
	状态：0405验证通过
]]--
LuaDanalao = sgs.CreateTriggerSkill{
	name = "LuaDanlao" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.to:length() <= 1 or not use.to:contains(player) or not use.card:isKindOf("TrickCard") 
			or not room:askForSkillInvoke(player, self:objectName(), data) then
			return false
		end
		player:setFlags("-LuaDanlaoTarget")
		player:setFlags("LuaDanlaoTarget")
		player:drawCards(1, self:objectName())
		if player:isAlive() and player:hasFlag("LuaDanlaoTarget") then
			player:setFlags("-LuaDanlaoTarget")
			local nullified_list = use.nullified_list
			table.insert(nullified_list, player:objectName())
			use.nullified_list = nullified_list
			data:setValue(use)
		end
		return false
	end
}
--[[
	技能名：当先（锁定技）
	相关武将：二将成名·廖化
	描述：回合开始时，你执行一个额外的出牌阶段。
	引用：LuaDangxian
	状态：0405验证通过
]]--
LuaDangxian = sgs.CreateTriggerSkill{
	name = "LuaDangxian" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_RoundStart then
			local room = player:getRoom()
			player:setPhase(sgs.Player_Play)
			room:broadcastProperty(player, "phase")
			local thread = room:getThread()
			if not thread:trigger(sgs.EventPhaseStart, room, player) then
				thread:trigger(sgs.EventPhaseProceeding, room, player)
			end
			thread:trigger(sgs.EventPhaseEnd, room, player)
			player:setPhase(sgs.Player_RoundStart)
			room:broadcastProperty(player, "phase")
		end
		return false
	end
}
--[[
	技能名：缔盟
	相关武将：林·鲁肃
	描述：出牌阶段限一次，你可以弃置任意数量的牌并选择两名手牌数差等于该数量的其他角色：若如此做，这两名角色交换他们的手牌。 
	引用：LuaDimeng
	状态：0405验证通过
]]--
local json = require ("json")
LuaDimengCard = sgs.CreateSkillCard{
	name = "LuaDimengCard",
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if #targets == 0 then return true end
		if #targets == 1 then
			return math.abs(to_select:getHandcardNum() - targets[1]:getHandcardNum()) == self:subcardsLength()
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local a = targets[1]
		local b = targets[2]
		a:setFlags("DimengTarget")
		b:setFlags("DimengTarget")
		local n1 = a:getHandcardNum()
		local n2 = b:getHandcardNum()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:objectName() ~= a:objectName() and p:objectName() ~= b:objectName() then
				room:doNotify(p, sgs.CommandType.S_COMMAND_EXCHANGE_KNOWN_CARDS, json.encode({a:objectName(), b:objectName()}))
			end
		end
		local exchangeMove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(a:handCards(), b, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, a:objectName(), b:objectName(), "dimeng", ""))
		local move2 = sgs.CardsMoveStruct(b:handCards(), a, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, b:objectName(), a:objectName(), "dimeng", ""))
		exchangeMove:append(move1)
		exchangeMove:append(move2)
        	room:moveCardsAtomic(exchangeMove, false);
	   	a:setFlags("-DimengTarget")
	   	b:setFlags("-DimengTarget")
	end
}
LuaDimeng = sgs.CreateViewAsSkill{
	name = "LuaDimeng",
	n = 999 ,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		local card = LuaDimengCard:clone()
		for _, c in ipairs(cards) do
	   		card:addSubcard(c)
		end
	   	return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaDimengCard")
	end
}
--[[
	技能名：定品
	相关武将：四将·陈群
	描述：出牌阶段，你可以弃置一张与你本回合已使用或弃置的牌类别均不同的手牌，然后令一名已受伤的角色进行判定：若结果为黑色，该角色摸X张牌，且你本阶段不能对该角色发动“定品”；红色，你将武将牌翻面。（X为该角色已损失的体力值）
	引用：LuaDingpin
	状态：0428验证通过
]]--
LuaDingpinCard = sgs.CreateSkillCard{
    name = "LuaDingpinCard" ,
    filter = function(self, targets, to_select, Self)
        return #targets == 0 and to_select:isWounded() and (not to_select:hasFlag("LuaDingpin"))
    end ,
    on_effect = function(self, effect) 
        local room = effect.from:getRoom()
        
        local judge = sgs.JudgeStruct()
        judge.who = effect.to
        judge.good = true
        judge.pattern = ".|black"
        judge.reason = "LuaDingpin"
        
        room:judge(judge)
        
        if (judge:isGood()) then
            room:setPlayerFlag(effect.to, "LuaDingpin")
            effect.to:drawCards(effect.to:getLostHp(), "LuaDingpin")
        else
            effect.from:turnOver()
        end
    end ,
}

LuaDingpinVS = sgs.CreateOneCardViewAsSkill{
    name = "LuaDingpin" ,
    enabled_at_play = function(self, player)
        if (not player:canDiscard(player, "h")) or (player:getMark("LuaDingpin") == 14) then return false end
        if (not player:hasFlag("LuaDingpin")) and player:isWounded() then return true end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if (not p:hasFlag("LuaDingpin")) and p:isWounded() then return true end
        end
        
        return false
    end ,
    view_filter = function(self, card)
        return (not card:isEquipped()) and (bit32.band(sgs.Self:getMark("LuaDingpin"), bit32.lshift(1, card:getTypeId())) == 0)
    end ,
    view_as = function(self, card)
        local dp = LuaDingpinCard:clone()
        dp:addSubcard(card)
        return dp
    end ,
}

function recordLuaDingpinCardType(room, player, card)
    if player:getMark("LuaDingpin") == 14 then return end
    local typeid = bit32.lshift(1, card:getTypeId())
    local mark = player:getMark("LuaDingpin")
    if (bit32.band(mark, typeid) == 0) then
        room:setPlayerMark(player, "LuaDingpin", bit32.bor(mark, typeid))
    end
end

LuaDingpin = sgs.CreateTriggerSkill{
    name = "LuaDingpin" ,
    events = {sgs.EventPhaseChanging, sgs.PreCardUsed, sgs.CardResponded, sgs.BeforeCardsMove} ,
    view_as_skill = LuaDingpinVS ,
    global = true ,
    on_trigger = function(self, event, player, data) 
        local room = player:getRoom()
        if (event == sgs.EventPhaseChanging) then
            local change = data:toPhaseChange()
            if (change.to == sgs.Player_NotActive) then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:hasFlag("LuaDingpin") then
                        room:setPlayerFlag(p, "-LuaDingpin")
                    end
                end
                if (player:getMark("LuaDingpin") > 0) then
                    room:setPlayerMark(player, "LuaDingpin", 0)
                end
            end
        else
            if (not player:isAlive()) or (player:getPhase() == sgs.Player_NotActive) then return false end
            if (event == sgs.PreCardUsed) or (event == sgs.CardResponded) then
                local card = nil
                if (event == sgs.PreCardUsed) then
                    card = data:toCardUse().card
                else
                    local resp = data:toCardResponse()
                    if (resp.m_isUse) then
                        card = resp.m_card
                    end
                end
                if (not card) or (card:getTypeId() == sgs.Card_TypeSkill) then return false end
                recordLuaDingpinCardType(room, player, card)
            elseif event == sgs.BeforeCardsMove then
                local move = data:toMoveOneTime()
                if (not move.from) or (player:objectName() ~= move.from:objectName()) or (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_DISCARD) then
                    return false
                end
                for _, id in sgs.qlist(move.card_ids) do
                    local c = sgs.Sanguosha:getCard(id)
                    recordLuaDingpinCardType(room, player, c)
                end
            end
        end
        return false
    end ,
}

--[[
	技能名：洞察
	相关武将：倚天·贾文和
	描述：回合开始阶段开始时，你可以指定一名其他角色：该角色的所有手牌对你处于可见状态，直到你的本回合结束。其他角色都不知道你对谁发动了洞察技能，包括被洞察的角色本身
	引用：LuaDongcha
	状态：1217验证通过
]]--
function findServerPlayer(room,name)
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		if p:objectName() == name then
			return p
		end
	end
	return nil
end
LuaDongcha = sgs.CreateTriggerSkill{
	name = "LuaDongcha",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local phase = player:getPhase()
		local room = player:getRoom()
		if phase == sgs.Player_Start then
			local shou = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@LuaDongcha",true,false)
			if shou then
				room:setPlayerFlag(shou,"dongchaee")
				room:setTag("Dongchaee",sgs.QVariant(shou:objectName()))
				room:setTag("Dongchaer",sgs.QVariant(player:objectName()))
				room:showAllCards(shou,player)
			end
		elseif phase == sgs.Player_Finish then
			local shou_name = room:getTag("Dongchaee"):toString()
			if shou_name ~= "" then
				local shou = findServerPlayer(room,shou_name)
				if shou then
					room:setPlayerFlag(shou,"-dongchaee")
					room:setTag("Dongchaee",sgs.QVariant())
					room:setTag("Dongchaer",sgs.QVariant())
				end
			end
		end
		return false
	end
}
--[[
	技能名：毒士（锁定技）
	相关武将：倚天·贾文和
	描述：杀死你的角色获得崩坏技能直到游戏结束
	引用：LuaDushi
	状态：0405验证通过
]]--
LuaDushi = sgs.CreateTriggerSkill{
	name = "LuaDushi",
	events = {sgs.Death},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local killer = nil
		if death.damage then killer = death.damage.from end
		if death.who:objectName() == player:objectName() and killer then
			if killer:objectName() ~= player:objectName() then
				killer:gainMark("@collapse")
				room:acquireSkill(killer, "benghuai")
			end
		end
		return false
	end,
}
--[[
	技能名：毒医
	相关武将：铜雀台·吉本
	描述：出牌阶段限一次，你可以亮出牌堆顶的一张牌并交给一名角色，若此牌为黑色，该角色不能使用或打出其手牌，直到回合结束。
	引用：LuaDuyi
	状态：0504验证通过
]]--
LuaDuyiCard = sgs.CreateSkillCard{
	name = "LuaDuyiCard" ,
	target_fixed = true ,
	mute = true ,
	on_use = function(self, room, source, targets)
		local card_ids = room:getNCards(1)
		local id = card_ids:first()
		room:fillAG(card_ids, nil)
		local target = room:askForPlayerChosen(source, room:getAlivePlayers(), "LuaDuyi")
		local card = sgs.Sanguosha:getCard(id)
		target:obtainCard(card)
		if card:isBlack() then
			room:setPlayerCardLimitation(target, "use,response", ".|.|.|hand", false)
			room:setPlayerMark(target, "LuaDuyi_target", 1)
		end
		room:clearAG()
	end
}
LuaDuyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaDuyi" ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaDuyiCard")
	end ,
	view_as = function()
		return LuaDuyiCard:clone()
	end ,
}
LuaDuyi = sgs.CreateTriggerSkill{
	name = "LuaDuyi" ,
	events = {sgs.EventPhaseChanging, sgs.Death} ,
	view_as_skill = LuaDuyiVS ,
	can_trigger = function(self, target)
		return target and target:hasInnateSkill(self:objectName())
	end ,
	on_trigger = function(self, event, player, data)
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
		else
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
		end
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("LuaDuyi_target") > 0 then
				room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand$0")
				room:setPlayerMark(p, "LuaDuyi_target", 0)
			end
		end
		return false
	end ,
}
--[[
	技能名：黩武
	相关武将：SP·诸葛恪
	描述：出牌阶段，你可以选择攻击范围内的一名其他角色并弃置X张牌：若如此做，你对该角色造成1点伤害。
		若你以此法令该角色进入濒死状态，濒死结算后你失去1点体力，且本阶段你不能再次发动“黩武”。（X为该角色当前的体力值）
	状态：0504验证通过
]]--
LuaDuwuCard = sgs.CreateSkillCard{
	name = "LuaDuwuCard" ,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) or (math.max(0, to_select:getHp()) ~= self:subcardsLength()) then return false end
		if sgs.Self:getWeapon() and self:getSubcards():contains(sgs.Self:getWeapon():getId()) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			local distance_fix = weapon:getRange() - sgs.Self:getAttackRange(false)
			if sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
				distance_fix = distance_fix + 1
			end
			return sgs.Self:inMyAttackRange(to_select, distance_fix)
		elseif sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
			return sgs.Self:inMyAttackRange(to_select, 1)
		else
			return sgs.Self:inMyAttackRange(to_select)
		end
	end ,
	on_effect = function(self, effect)
		effect.from:getRoom():damage(sgs.DamageStruct("LuaDuwu", effect.from, effect.to))
	end
}
LuaDuwuVS = sgs.CreateViewAsSkill{
	name = "LuaDuwu" ,
	n = 999 ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and (not player:hasFlag("LuaDuwuEnterDying"))
	end ,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		local duwu = LuaDuwuCard:clone()
		if #cards ~= 0 then
			for _, c in ipairs(cards) do
				duwu:addSubcard(c)
			end
		end
		return duwu
	end ,
}
LuaDuwu = sgs.CreateTriggerSkill{
	name = "LuaDuwu" ,
	events = {sgs.QuitDying} ,
	view_as_skill = LuaDuwuVS ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.damage and dying.damage:getReason() == "LuaDuwu" and not dying.damage.chain and not dying.damage.transfer then
			local from = dying.damage.from
			if from and from:isAlive() then
				room:setPlayerFlag(from, "LuaDuwuEnterDying")
				room:loseHp(from,1)
			end
		end
		return false
	end,
}
--[[
	技能名：短兵
	相关武将：国战·丁奉
	描述：你使用【杀】可以额外选择一名距离1的目标。
	引用：LuaXDuanbing
	状态：0504验证通过
	附注：原技能涉及修改源码。Lua的版本以此法可实现，但体验感略微欠佳。
]]--
LuaXDuanbing = sgs.CreateTriggerSkill{
	name = "LuaXDuanbing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			local room = player:getRoom()
			local targets = sgs.SPlayerList()
			local others = room:getOtherPlayers(player)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _,p in sgs.qlist(others) do
				if player:distanceTo(p) == 1 then
					if not use.to:contains(p) then
						if player:canSlash(p, use.card) then
							room:setPlayerFlag(p, "duanbingslash")
							targets:append(p)
						end
					end
				end
			end
			if not targets:isEmpty() then
				if player:askForSkillInvoke(self:objectName()) then
					local target = room:askForPlayerChosen(player, targets, self:objectName())
					for _,p in sgs.qlist(others) do
						if p:hasFlag("duanbingslash") then
							room:setPlayerFlag(p, "-duanbingslash")
						end
					end
					use.to:append(target)
					data:setValue(use)
				end
			end
		end
	end,
}
--[[
	技能名：断肠（锁定技）
	相关武将：山·蔡文姬、SP·蔡文姬
	描述：杀死你的角色失去所有武将技能。 
	引用：LuaDuanchang
	状态：0405验证通过
]]--
LuaDuanchang = sgs.CreateTriggerSkill{
	name = "LuaDuanchang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = player:getRoom()
		if death.who:objectName() ~= player:objectName() then
			return false
		end
		if death.damage and death.damage.from then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local skills = death.damage.from:getVisibleSkillList()
			local detachList = {}
			for _,skill in sgs.qlist(skills) do
				if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() then
					table.insert(detachList,"-"..skill:objectName())
				end
			end
			room:handleAcquireDetachSkills(death.damage.from, table.concat(detachList,"|"))
			if death.damage.from:isAlive() then
				death.damage.from:gainMark("@duanchang")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
--[[
	技能名：断粮
	相关武将：林·徐晃
	描述：你可以将一张黑色的基本牌或黑色的装备牌当【兵粮寸断】使用。你使用【兵粮寸断】的距离限制为2。 
	引用：LuaDuanliangTargetMod，LuaDuanliang
	状态：0405验证通过
]]--
LuaDuanliang = sgs.CreateOneCardViewAsSkill{
	name = "LuaDuanliang",
	filter_pattern = "BasicCard,EquipCard|black",
	response_or_use = true,
	view_as = function(self, card)
		local shortage = sgs.Sanguosha:cloneCard("supply_shortage",card:getSuit(),card:getNumber())
		shortage:setSkillName(self:objectName())
		shortage:addSubcard(card)
		return shortage
	end
}
LuaDuanliangTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaDuanliang-target",
	pattern = "SupplyShortage",
	distance_limit_func = function(self, from)
		if from:hasSkill("LuaDuanliang") then
			return 1
		else
			return 0
		end
	end
}
--[[
	技能名：断指
	相关武将：铜雀台·吉本
	描述：当你成为其他角色使用的牌的目标后，你可以弃置其至多两张牌（也可以不弃置），然后失去1点体力。
	引用：LuaXDuanzhi、LuaXDuanzhiFakeMove
	状态：1217验证通过	
]]--
LuaXDuanzhi = sgs.CreateTriggerSkill{
	name = "LuaXDuanzhi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getTypeId() == sgs.Card_TypeSkill or use.from:objectName() == player:objectName() or (not use.to:contains(player)) then
			return false
		end
		if player:askForSkillInvoke(self:objectName(), data) then
			room:setPlayerFlag(player, "LuaXDuanzhi_InTempMoving");
			local target = use.from
			local dummy = sgs.Sanguosha:cloneCard("slash") --没办法了，暂时用你代替DummyCard吧……
			local card_ids = sgs.IntList()
			local original_places = sgs.PlaceList()
			for i = 1,2,1 do
				if not player:canDiscard(target, "he") then break end
				if room:askForChoice(player, self:objectName(), "discard+cancel") == "cancel" then break end
				card_ids:append(room:askForCardChosen(player, target, "he", self:objectName()))
				original_places:append(room:getCardPlace(card_ids:at(i-1)))
				dummy:addSubcard(card_ids:at(i-1))
				target:addToPile("#duanzhi", card_ids:at(i-1), false)
			end
			if dummy:subcardsLength() > 0 then
				for i = 1,dummy:subcardsLength(),1 do
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i-1)), target, original_places:at(i-1), false)
				end
			end
			room:setPlayerFlag(player, "-LuaXDuanzhi_InTempMoving")
			if dummy:subcardsLength() > 0 then
				room:throwCard(dummy, target, player)
			end
			room:loseHp(player);
		end
		return false
	end,
}
LuaXDuanzhiFakeMove = sgs.CreateTriggerSkill{
	name = "#LuaXDuanzhi-fake-move",
	events = {sgs.BeforeCardsMove,sgs.CardsMoveOneTime},
	priority = 10,
	on_trigger = function(self, event, player, data)
		if player:hasFlag("LuaXDuanzhi_InTempMoving") then
			return true
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--[[
	技能名：夺刀
	相关武将：一将成名2013·潘璋&马忠
	描述：每当你受到一次【杀】造成的伤害后，你可以弃置一张牌，获得伤害来源装备区的武器牌。
	引用：LuaDuodao
	状态：0405验证通过
]]--
LuaDuodao = sgs.CreateTriggerSkill{
	name = "LuaDuodao" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if not damage.card or not damage.card:isKindOf("Slash") or not player:canDiscard(player, "he") then
			return
		end
		local _data = sgs.QVariant()
		_data:setValue(damage)
		local room = player:getRoom()
		if room:askForCard(player, "..", "@duodao-get", _data, self:objectName()) then
			if damage.from and damage.from:getWeapon() then
				player:obtainCard(damage.from:getWeapon())
			end
		end
	end
}
--[[
	技能名：度势
	相关武将：国战·陆逊
	描述：出牌阶段限四次，你可以弃置一张红色手牌并选择任意数量的其他角色，你与这些角色先各摸两张牌，然后各弃置两张牌。
	引用：LuaXDuoshi
	状态：1217验证通过	
]]--
LuaXDuoshiCard = sgs.CreateSkillCard{
	name = "LuaXDuoshiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets)
		source:drawCards(2)
		for i=1, #targets, 1 do
			targets[i]:drawCards(2)
		end
		room:askForDiscard(source, "LuaXDuoshi", 2, 2, false, true, "#LuaXDuoshi-discard")
		for i=1, #targets, 1 do
			room:askForDiscard(targets[i], "LuaXDuoshi", 2, 2, false, true, "#LuaXDuoshi-discard")
		end
	end,
}
LuaXDuoshi = sgs.CreateViewAsSkill{
	name = "LuaXDuoshi",
	n = 1,
	view_filter = function(self, selected, to_select)
		if to_select:isRed() then
			if not to_select:isEquipped() then
				return not sgs.Self:isJilei(to_select)
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local await = LuaXDuoshiCard:clone()
			await:addSubcard(cards[1])
			await:setSkillName(self:objectName())
			return await
		end
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#LuaXDuoshiCard") < 4
	end
}
