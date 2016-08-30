--[[
	代码速查手册（Q区）
	技能索引：
		七星、戚乱、奇才、奇才、奇策、奇袭、千幻、谦逊、潜袭、潜袭、枪舞、强袭、巧变、巧说、琴音、青囊、倾城、倾国、倾国1V1、清俭、求援、驱虎、权计、
]]--
--[[
	技能名：七星
	相关武将：神·诸葛亮
	描述：分发起始手牌时，共发你十一张牌，你选四张作为手牌，其余的面朝下置于一旁，称为“星”；摸牌阶段结束时，你可以用任意数量的手牌等量替换这些“星”。
	引用：LuaQixing、LuaQixingStart、LuaQixingAsk、LuaQingxingClear
	状态：0405验证通过
	备注：水饺wch哥：医神要把0405耦合的“狂风”和“大雾”解耦吗？
]]--
LuaQixingCard = sgs.CreateSkillCard{
	name = "LuaQixingCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local pile = source:getPile("stars")
		local subCards = self:getSubcards()
		local to_handcard = sgs.IntList()
		local to_pile = sgs.IntList()
		local set = source:getPile("stars")
		for _,id in sgs.qlist(subCards) do
			set:append(id)
		end
		for _,id in sgs.qlist(set) do
			if not subCards:contains(id) then
				to_handcard:append(id)
			elseif not pile:contains(id) then
				to_pile:append(id)
			end
		end
		assert(to_handcard:length() == to_pile:length())
		if to_pile:length() == 0 or to_handcard:length() ~= to_pile:length() then return end
		room:notifySkillInvoked(source, "LuaQixing")
		source:addToPile("stars", to_pile, false)
		local to_handcard_x = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _,id in sgs.qlist(to_handcard) do
			to_handcard_x:addSubcard(id)
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, source:objectName())
		room:obtainCard(source, to_handcard_x, reason, false)
	end,
}
LuaQixingVS = sgs.CreateViewAsSkill{
	name = "LuaQixing", 
	n = 998,
	response_pattern = "@@LuaQixing",
	expand_pile = "stars",
	view_filter = function(self, selected, to_select)
		if #selected < sgs.Self:getPile("stars"):length() then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == sgs.Self:getPile("stars"):length() then
			local c = LuaQixingCard:clone()
			for _,card in ipairs(cards) do
				c:addSubcard(card)
			end
			return c
		end
		return nil
	end,
}
LuaQixing = sgs.CreateTriggerSkill{
	name = "LuaQixing",
	events = {sgs.EventPhaseEnd},
	view_as_skill = LuaQixingVS,
	can_trigger = function(self, player)
		return player:isAlive() and player:hasSkill(self:objectName()) and player:getPile("stars"):length() > 0
			and player:getPhase() == sgs.Player_Draw
	end,
	on_trigger = function(self, event, player, data)
		player:getRoom():askForUseCard(player, "@@LuaQixing", "@qixing-exchange", -1, sgs.Card_MethodNone)
		return false
	end,
}
LuaQixingStart = sgs.CreateTriggerSkill{
	name = "#LuaQixingStart",
	events = {sgs.DrawInitialCards,sgs.AfterDrawInitialCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawInitialCards then
			room:sendCompulsoryTriggerLog(player, "LuaQixing")
			data:setValue(data:toInt() + 7)
		elseif event == sgs.AfterDrawInitialCards then
			local exchange_card = room:askForExchange(player, "LuaQixing", 7, 7)
			player:addToPile("stars", exchange_card:getSubcards(), false)
			exchange_card:deleteLater()
		end
		return false
	end,
}
LuaQixingAsk = sgs.CreateTriggerSkill{
	name = "#LuaQixingAsk",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if player:getPile("stars"):length() > 0 and player:hasSkill("LuaKuangfeng") then
				room:askForUseCard(player, "@@LuaKuangfeng", "@kuangfeng-card", -1, sgs.Card_MethodNone)
			end
			if player:getPile("stars"):length() > 0 and player:hasSkill("LuaDawu") then
				room:askForUseCard(player, "@@LuaDawu", "@dawu-card", -1, sgs.Card_MethodNone)
			end
		end
		return false
	end,
}
LuaQixingClear = sgs.CreateTriggerSkill{
	name = "#LuaQixingClear",
	events = {sgs.EventPhaseStart, sgs.Death, sgs.EventLoseSkill},
	can_trigger = function(self, player)
		return player ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if sgs.event == EventPhaseStart or event == sgs.Death then
			if event == sgs.Death then
				local death = data:toDeath()
				if death.who:objectName() ~= player:objectName() then
					return false
				end
			end
			if not player:getTag("LuaQixing_user"):toBool() then
				return false
			end
			local invoke = false
			if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart) or event == sgs.Death then
				invoke = true
			end
			if not invoke then
				return false
			end
			local players = room:getAllPlayers()
			for _,p in sgs.qlist(players) do
				p:loseAllMarks("@gale")
				p:loseAllMarks("@fog")
			end
			player:removeTag("LuaQixing_user")
		elseif event == sgs.EventLoseSkill and data:toString() == "LuaQixing" then
			player:clearOnePrivatePile("stars")
		end
		return false
	end,
}
--[[
	技能名：戚乱
	相关武将：阵·何太后
	描述：每当一名角色的回合结束后，若你于本回合杀死至少一名角色，你可以摸三张牌。
	引用：LuaQiluan 
	状态：1217验证通过
]]--
LuaQiluan = sgs.CreateTriggerSkill{
	name = "LuaQiluan", 
	frequency = sgs.Skill_Frequent, --, NotFrequent, Compulsory, Limited, Wake 
	events = {sgs.Death,sgs.EventPhaseStart}, 
	on_trigger = function(self, triggerEvent, player, data)
		local room = player:getRoom()
		if (triggerEvent == sgs.Death) then
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName() then return false end
            local killer = death.damage.from
            local current = room:getCurrent();
            if killer and current and (current:isAlive() or death.who == current)
                and current:getPhase() ~= sgs.Player_NotActive then
                killer:addMark(self:objectName())
			end
        else 
            if player:getPhase() == sgs.Player_NotActive then
                local hetaihous = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getAllPlayers()) do
                    if p:getMark(self:objectName()) > 0 and player:hasSkill(self:objectName()) then
                        hetaihous:append(p)
					end
                    p:setMark(self:objectName(), 0);
                end

                for _,p in sgs.qlist(hetaihous)do
                    if room:askForSkillInvoke(p, self:objectName()) then
                        p:drawCards(3)
					end
                end
            end
        end
        return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--[[
	技能名：奇才（锁定技）
	相关武将：标准·黄月英、JSP·黄月英
	描述：你使用锦囊牌无距离限制。你装备区里除坐骑牌外的牌不能被其他角色弃置。
	状态：尚未完成
	备注：前半部分与奇才一样，后半部分被写入源码，详见Player::canDiscard
]]--
--[[
	技能名：奇才（锁定技）
	相关武将：怀旧-标准·黄月英-旧、SP·台版黄月英
	描述：你使用锦囊牌时无距离限制。
	引用：LuaNosQicai
	状态：0405验证通过
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
	引用：LuaQice
	状态：0405验证通过
]]--
LuaQiceCard = sgs.CreateSkillCard{
	name = "LuaQiceCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local card = sgs.Self:getTag("LuaQice"):toCard()
		card:addSubcards(sgs.Self:getHandcards())
		card:setSkillName(self:objectName())
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) 
			and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local card = sgs.Self:getTag("LuaQice"):toCard()
		card:addSubcards(sgs.Self:getHandcards())
		card:setSkillName(self:objectName())
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,	
	on_validate = function(self, card_use)
		local xunyou = card_use.from
		local room = xunyou:getRoom()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString())
		use_card:addSubcards(xunyou:getHandcards())
		use_card:setSkillName(self:objectName())
		local available = true
		for _,p in sgs.qlist(card_use.to) do
			if xunyou:isProhibited(p,use_card)	then
				available = false
				break
			end
		end
		available = available and use_card:isAvailable(xunyou)
		if not available then return nil end
		return use_card		
	end,
}
LuaQice = sgs.CreateViewAsSkill{
	name = "LuaQice",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		local c = sgs.Self:getTag("LuaQice"):toCard()
		if c then
			local card = LuaQiceCard:clone()
			card:setUserString(c:objectName())	
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#LuaQice")) and (not player:isKongcheng())
	end,
}
LuaQice:setGuhuoDialog("r")
--[[
	技能名：千幻
	相关武将：阵·于吉
	描述：每当一名角色受到伤害后，该角色可以将牌堆顶的一张牌置于你的武将牌上。每当一名角色被指定为基本牌或锦囊牌的唯一目标时，若该角色同意，你可以将一张“千幻牌”置入弃牌堆：若如此做，取消该目标。
	引用：LuaQianhuan
	状态：1217验证通过
]]--
LuaQianhuan = sgs.CreateTriggerSkill{
	name = "LuaQianhuan", 
	events = {sgs.Damaged,sgs.TargetConfirming}, 
	on_trigger = function(self, triggerEvent, player, data)
		local room = player:getRoom()
		if triggerEvent == sgs.Damaged and player:isAlive() then
            local yuji = room:findPlayerBySkillName(self:objectName())
            if yuji and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("choice:" .. yuji:objectName()))then
                if (yuji:objectName() ~= player:objectName()) then
                    room:notifySkillInvoked(yuji, self:objectName());
                end
                local id = room:drawCard()
                local suit = sgs.Sanguosha:getCard(id):getSuit()
                local duplicate = false;
                for _,card_id in sgs.qlist(yuji:getPile("sorcery")) do
                    if (sgs.Sanguosha:getCard(card_id):getSuit() == suit) then
                        duplicate = true
                        break
                    end
                end
                yuji:addToPile("sorcery", id)
                if (duplicate) then
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,"", self:objectName(), "")
                    room:throwCard(sgs.Sanguosha:getCard(id), reason, nil)
                end
            end
        elseif triggerEvent == sgs.TargetConfirming then
            local use = data:toCardUse()
            if (not use.card) or use.card:getTypeId() == sgs.Card_TypeEquip or use.card:getTypeId() == sgs.Card_TypeSkill then return false end
            if use.to:length() ~= 1 then return false end
            local yuji = room:findPlayerBySkillName(self:objectName());
            if yuji == nil or yuji:getPile("sorcery"):isEmpty() then return false end
            if room:askForSkillInvoke(yuji, self:objectName(), data) then
                if (yuji:objectName() == player:objectName() or room:askForChoice(player, self:objectName(), "accept+reject", data) == "accept") then
                    local ids = yuji:getPile("sorcery")
                    local id = -1
                    if (ids:length() > 1) then
                        room:fillAG(ids, yuji)
                        id = room:askForAG(yuji, ids, false, self:objectName())
                        room:clearAG(yuji)
                    else
                        id = ids:first()
                    end
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(),"")
                    room:throwCard(sgs.Sanguosha:getCard(id), reason,nil);
                    use.to = sgs.SPlayerList()
                    data:setValue(use)
                end
            end
        end
        return false;
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--[[
	技能名：奇袭
	相关武将：标准·甘宁、SP·台版甘宁
	描述：你可以将一张黑色牌当【过河拆桥】使用。
	引用：LuaQixi
	状态：1217验证通过
]]--
LuaQixi = sgs.CreateOneCardViewAsSkill{
	name = "LuaQixi", 
	filter_pattern = ".|black",
	view_as = function(self, card) 
		local acard = sgs.Sanguosha:cloneCard("dismantlement", card:getSuit(), card:getNumber())
		acard:addSubcard(card:getId())
		acard:setSkillName(self:objectName())
		return acard
	end, 
}
--[[
	技能名：谦逊（锁定技）
	相关武将：标准·陆逊、国战·陆逊
	描述：你不能被选择为【顺手牵羊】和【乐不思蜀】的目标。
	引用：LuaNosQianxun
	状态：0405验证通过
]]--
LuaNosQianxun = sgs.CreateProhibitSkill{
	name = "LuaNosQianxun",
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
	描述：出牌阶段限一次，你可以失去1点体力或弃置一张武器牌，并选择攻击范围内的一名角色：若如此做，你对该角色造成1点伤害。  
	引用：LuaQiangxi
	状态：0405验证通过
]]--

LuaQiangxiCard = sgs.CreateSkillCard{
	name = "LuaQiangxiCard", 
	filter = function(self, targets, to_select) 
		if #targets ~= 0 or to_select:objectName() == sgs.Self:objectName() then return false end--根据描述应该可以选择自己才对
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		return sgs.Self:inMyAttackRange(to_select, rangefix);
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if self:getSubcards():isEmpty() then 
			room:loseHp(effect.from)
		end
		room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
	end
}
LuaQiangxi = sgs.CreateViewAsSkill{
	name = "LuaQiangxi", 
	n = 1, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaQiangxiCard")
	end,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("Weapon") and not sgs.Self:isJilei(to_select)
	end, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return LuaQiangxiCard:clone()
		elseif #cards == 1 then
			local card = LuaQiangxiCard:clone()
			card:addSubcard(cards[1])
			return card
		else 
			return nil
		end
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
	描述：除准备阶段和结束阶段的阶段开始前，你可以弃置一张手牌：若如此做，你跳过该阶段。若以此法跳过摸牌阶段，你可以依次获得一至两名其他角色的各一张手牌；若以此法跳过出牌阶段，你可以将场上的一张牌置于另一名角色相应的区域内。 
	引用：LuaQiaobian
	状态：0405验证通过
]]--
LuaQiaobianCard = sgs.CreateSkillCard{
	name = "LuaQiaobianCard",
	feasible = function(self, targets)
		local phase = sgs.Self:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			return #targets <= 2 and #targets > 0
		elseif phase == sgs.Player_Play then
			return #targets == 1
		end
		return false
	end,
	filter = function(self, targets, to_select)
		local phase = sgs.Self:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			return #targets < 2 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
		elseif phase == sgs.Player_Play then
			return #targets == 0 and (to_select:getJudgingArea():length() > 0 or to_select:getEquips():length() > 0)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local phase = source:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			if #targets == 0 then return end
			for _, target in pairs(targets)do
				if source:isAlive() and target:isAlive() then
					room:cardEffect(self, source, target)
				end
			end
		elseif phase == sgs.Player_Play then
			if #targets == 0 then return end
			local from = targets[1]
			if not from:hasEquip() and from:getJudgingArea():length() == 0 then return end
			local card_id = room:askForCardChosen(source, from, "ej", self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			local place = room:getCardPlace(card_id)
			local equip_index = -1
			if place == sgs.Player_PlaceEquip then
				local equip = card:getRealCard():toEquipCard()
				equip_index = equip:location()
			end
			local tos = sgs.SPlayerList()
			local list = room:getAlivePlayers()
			for _, p in sgs.qlist(list) do
				if equip_index ~= -1 then
					if not p:getEquip(equip_index) then
						tos:append(p)
					end
				else
					if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
						tos:append(p)
					end
				end
			end
			local tag = sgs.QVariant()
			tag:setValue(from)
			room:setTag("QiaobianTarget", tag)
			local to = room:askForPlayerChosen(source, tos, self:objectName(), "@qiaobian-to" .. card:objectName())
			if to then
				room:moveCardTo(card, from, to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("QiaobianTarget")
		end
	end,
	on_effect = function(self, effect) 
		local room = effect.from:getRoom()
		if not effect.to:isKongcheng() then
			local card_id = room:askForCardChosen(effect.from, effect.to, "h", "LuaQiaobian")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName())
			room:obtainCard(effect.from, sgs.Sanguosha:getCard(card_id), reason, false)
		end
	end,
}
LuaQiaobianVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaQiaobian",
	response_pattern = "@@LuaQiaobian",
	view_as = function(self, cards)
		return LuaQiaobianCard:clone()
	end
}
LuaQiaobian = sgs.CreateTriggerSkill{
	name = "LuaQiaobian",
	events = {sgs.EventPhaseChanging},
	view_as_skill = LuaQiaobianVS,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName()) and target:isAlive() and target:canDiscard(target, "h")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		room:setPlayerMark(player, "qiaobianPhase", change.to)
		local index = 0
		if change.to == sgs.Player_Judge then
			index = 1
		elseif change.to == sgs.Player_Draw then
			index = 2
		elseif change.to == sgs.Player_Play then
			index = 3
		elseif change.to == sgs.Player_Discard then
			index = 4
		end
		local discard_prompt = string.format("#qiaobian-%d", index)
		local use_prompt = string.format("@qiaobian-%d", index)
		if index > 0 and room:askForDiscard(player, self:objectName(), 1, 1, true, false, discard_prompt) then
			if not player:isAlive() then return false end
			if not player:isSkipped(change.to) and (index == 2 or index == 3) then
				room:askForUseCard(player, "@@LuaQiaobian", use_prompt, index)
			end
			player:skip(change.to)
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
							p:setFlags("-ExtraCollateralTarget")
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
	描述：弃牌阶段结束时，若你于本阶段内弃置了至少两张你的牌，你可以选择一项：令所有角色各回复1点体力，或令所有角色各失去1点体力。
	引用：LuaQinyin
	状态：0405验证通过
]]--	
LuaQinyin = sgs.CreateTriggerSkill{
	name = "LuaQinyin" ,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.EventPhaseChanging} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, shenzhouyu, data)
		local room = shenzhouyu:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if shenzhouyu:getPhase() == sgs.Player_Discard and move.from and move.from:objectName() == shenzhouyu:objectName() and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				shenzhouyu:addMark("qinyin", move.card_ids:length())
			end
		elseif event == sgs.EventPhaseEnd and shenzhouyu:getPhase() == sgs.Player_Discard and shenzhouyu:getMark("qinyin") >= 2 then
			local choices = {"down+cancel"}
			local all_players = room:getAllPlayers()
			for _, player in sgs.qlist(all_players) do
				if player:isWounded() then
					table.insert(choices, "up")
					break
				end
			end
			local result = room:askForChoice(shenzhouyu, self:objectName(), table.concat(choices, "+"))
			if result == "cancel" then
				return
			else
				room:notifySkillInvoked(shenzhouyu, "qinyin")
				if result == "up" then
					for _, player in sgs.qlist(all_players) do
						room:recover(player, sgs.RecoverStruct(shenzhouyu))
					end
				elseif result == "down" then
					for _, player in sgs.qlist(all_players) do
						room:loseHp(player)
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			shenzhouyu:setMark("qinyin", 0)
		end
		return false
	end
}
--[[
	技能名：青囊
	相关武将：标准·华佗
	描述： 出牌阶段限一次，你可以弃置一张手牌并选择一名已受伤的角色，令该角色回复1点体力。
	引用：LuaQingnang
	状态：1217验证通过
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
		return #targets == 0 and sgs.Self:isWounded()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1] or source
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
LuaQingnang = sgs.CreateOneCardViewAsSkill{
	name = "LuaQingnang", 
	filter_pattern = ".|.|.|hand!",
	view_as = function(self, card) 
		local qnc = LuaQingnangCard:clone()
		qnc:addSubcard(card)
		qnc:setSkillName(self:objectName())
		return qnc
	end, 
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "h") and not player:hasUsed("#LuaQingnangCard")
	end, 
}

--[[
	技能名：倾城
	相关武将：国战·邹氏
	描述：出牌阶段，你可以弃置一张装备牌，令一名其他角色的一项武将技能无效，直到其下回合开始。
	引用：LuaQingcheng
	状态：1217验证通过
]]--
local json = require ("json")
LuaQingchengCard = sgs.CreateSkillCard{
	name = "LuaQingchengCard", 
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	about_to_use = function(self,room,card_use)
		local player,to = card_use.from,card_use.to:first()
		local log = sgs.LogMessage()
		log.from = player
		log.to = card_use.to
		log.type = "#UseCard"
		log.card_str = card_use.card:toString()
		room:sendLog(log)
		local skill_list = {}
		local Qingchenglist = to:getTag("Qingcheng"):toString():split("+") or {}
		for _,skill in sgs.qlist(to:getVisibleSkillList()) do
			if (not table.contains(skill_list,skill:objectName())) and not skill:isAttachedLordSkill() then
				table.insert(skill_list,skill:objectName())
			end
		end
		table.removeTable(skill_list,Qingchenglist)
		local skill_qc = ""
		if (#skill_list > 0) then
			skill_qc = room:askForChoice(player, "LuaQingcheng", table.concat(skill_list,"+"))
		end
		if (skill_qc ~= "") then
			table.insert(Qingchenglist,skill_qc)
			to:setTag("Qingcheng",sgs.QVariant(table.concat(Qingchenglist,"+")))
			room:addPlayerMark(to, "Qingcheng" .. skill_qc)
			for _,p in sgs.qlist(room:getAllPlayers())do
				room:filterCards(p, p:getCards("he"), true)
			end
			local jsonValue = {
				8
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		end
		local data = sgs.QVariant()
		data:setValue(card_use)
		local thread = room:getThread()
		thread:trigger(sgs.PreCardUsed, room, player, data)
		card_use = data:toCardUse()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), "", card_use.card:getSkillName(), "")
		room:moveCardTo(self, player, nil, sgs.Player_DiscardPile, reason, true)
		thread:trigger(sgs.CardUsed, room, player, data)
		thread:trigger(sgs.CardFinished, room, player, data)
	end,
}
LuaQingchengVs = sgs.CreateOneCardViewAsSkill{
	name = "LuaQingcheng", 
	filter_pattern = "EquipCard",
	view_as = function(self, card) 
		local qcc = LuaQingchengCard:clone()
		qcc:addSubcard(card)
		qcc:setSkillName(self:objectName())
		return qcc
	end, 
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he")
	end, 
}
LuaQingcheng = sgs.CreateTriggerSkill{
	name = "LuaQingcheng", 
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaQingchengVs,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_RoundStart then
			local room = player:getRoom()
            local Qingchenglist = player:getTag("Qingcheng"):toString():split("+")
            if #Qingchenglist == 0 then return false end
            for _,skill_name in pairs(Qingchenglist)do
                room:setPlayerMark(player, "Qingcheng" .. skill_name, 0);
            end
            player:removeTag("Qingcheng")
            for _,p in sgs.qlist(room:getAllPlayers())do
                room:filterCards(p, p:getCards("he"), true)
			end
            local jsonValue = {
				8
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
        end
        return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 6
}
--[[
	技能名：倾国
	相关武将：标准·甄姬、SP·甄姬、SP·台版甄姬
	描述：你可以将一张黑色手牌当【闪】使用或打出。  
	引用：LuaQingguo
	状态：0405证通过
]]--
LuaQingguo = sgs.CreateOneCardViewAsSkill{
	name = "LuaQingguo", 
	response_pattern = "jink",
	filter_pattern = ".|black|.|hand",
	response_or_use = true,
	view_as = function(self, card) 
		local jink = sgs.Sanguosha:cloneCard("jink",card:getSuit(),card:getNumber())
		jink:setSkillName(self:objectName())
		jink:addSubcard(card:getId())
		return jink
	end
}
--[[
	技能名：倾国1V1
	相关武将：1v1·甄姬1v1
	描述：你可以将一张装备区的牌当【闪】使用或打出。   
	引用：LuaKOFQingguo
	状态：0405验证通过
]]--
LuaKOFQingguo = sgs.CreateOneCardViewAsSkill{
	name = "LuaKOFQingguo", 
	filter_pattern = ".|.|.|equipped",
	view_as = function(self, card) 
		local jink = sgs.Sanguosha:cloneCard("jink",card:getSuit(),card:getNumber())
		jink:setSkillName(self:objectName());
		jink:addSubcard(card:getId());
		return jink
	end,
	enabled_at_play = function(self, target)
		return false
	end,
	enabled_at_response = function(self, target, pattern)
		return pattern == "jink" and target:getEquips():length() > 0
	end
}
--[[
	技能名：清俭
	相关武将：界限突破·夏侯惇
	描述：每当你于摸牌阶段外获得手牌后，你可以将其中至少一张牌任意分配给其他角色。    
	引用：LuaQingjian
	状态：0405验证通过
]]--
LuaQingjian = sgs.CreateTriggerSkill{
	name = "LuaQingjian",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		local room = player:getRoom()
		if not room:getTag("FirstRound"):toBool() and player:getPhase() ~= sgs.Player_Draw and move.to and move.to:objectName() == player:objectName() then
			local ids = sgs.IntList()
			for _,id in sgs.qlist(move.card_ids) do
				if room:getCardOwner(id) == player and room:getCardPlace(id) == sgs.Player_PlaceHand then
					ids:append(id)
				end
			end
			if ids:isEmpty() then return false end
			player:setTag("QingjianCurrentMoveSkill", sgs.QVariant(move.reason.m_skillName))
			while room:askForYiji(player, ids, self:objectName(), false, false, true, -1, sgs.SPlayerList(), sgs.CardMoveReason(), "@LuaQingjian-distribute", true) do
				if player:isDead() then return false end
			end
		end
		return false
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
	状态：1217验证通过
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
LuaQuhu = sgs.CreateZeroCardViewAsSkill{
	name = "LuaQuhu",
	view_as = function(self, cards) 
		return LuaQuhuCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#LuaQuhuCard")) and not player:isKongcheng()
	end, 
}

--[[
	技能名：权计
	相关武将：一将成名·钟会
	描述：每当你受到1点伤害后，你可以摸一张牌，然后将一张手牌置于武将牌上，称为“权”。每有一张“权”，你的手牌上限+1。 
	引用：LuaQuanji、LuaQuanjiKeep
	状态：0405证通过
]]--
LuaQuanji = sgs.CreateMasochismSkill{
	name = "LuaQuanji",
	frequency = sgs.Skill_Frequent,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local x = damage.damage
		for i = 0, x - 1, 1 do
			if player:askForSkillInvoke(self:objectName()) then
				room:drawCards(player, 1, self:objectName())
				if not player:isKongcheng() then
					local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					if player:getHandcardNum() == 1 then
						card_id = player:handCards():first()
						room:getThread():delay()
					else
						card_id = room:askForExchange(player, self:objectName(), 1, 1, false, "QuanjiPush"):getSubcards():first()
					end
					player:addToPile("power", card_id)
				end
			end
		end
	end
}
LuaQuanjiKeep = sgs.CreateMaxCardsSkill{
	name = "#LuaQuanji-keep",
	frequency = sgs.Skill_Frequent,
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getPile("power"):length()
		else
			return 0
		end
	end
}
