--[[
	代码速查手册（L区）
	技能索引：
		狼顾、乐学、雷击、雷击、离魂、离间、离间、离迁、礼让、疠火、连环、连理、连破、连营、烈弓、烈弓、烈刃、裂围、流离、龙胆、龙魂、龙魂、龙吟、笼络、乱击、乱武、裸衣、裸衣、洛神、落雁、落英
]]--
--[[
	技能名：狼顾
	相关武将：贴纸·司马昭
	描述：每当你受到1点伤害后，你可以进行一次判定，然后你可以打出一张手牌代替此判定牌：若如此做，你观看伤害来源的所有手牌，并弃置其中任意数量的与判定牌花色相同的牌。
	引用：LuaXLanggu
	状态：1217验证通过
]]--
LuaXLanggu = sgs.CreateTriggerSkill{
	name = "LuaXLanggu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged, sgs.AskForRetrial},
	on_trigger = function(self, event, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if not damage.from or damage.from:isKongcheng() then
				return
			end
			local target = damage.from
			local num = damage.damage
			local n = 0
			while n < num do
				if player:askForSkillInvoke(self:objectName(), data) then
					local room = player:getRoom()
					local judge = sgs.JudgeStruct()
					judge.reason = self:objectName()
					judge.pattern = "."
					judge.who = player
					room:judge(judge)
					local ids = target:handCards()
					room:fillAG(ids, player)
					local mark = judge.card:getSuitString()
					room:setPlayerFlag(player, mark)
					while not target:isKongcheng() do
						local card_id = room:askForAG(player, ids, true, "LuaXLanggu")
						if card_id == -1 then
							room:clearAG(player)
							break
						end
						local card = sgs.Sanguosha:getCard(card_id)
						if judge.card:getSuit() == card:getSuit() then
							room:throwCard(card_id, target)
						end
					end
					room:setPlayerFlag(player, "-" .. mark)
				else
					break
				end
				n = n + 1
			end
			return
		elseif event == sgs.AskForRetrial then
			local room = player:getRoom()
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				if judge.who:objectName() == player:objectName() then
					local card = room:askForCard(player, ".", "@LuaXLanggu", data, sgs.AskForRetrial)
					if card then
						room:retrial(card, player, judge, self:objectName(), false)
					end
				end
			end
			return false
		end
	end,
}
--[[
	技能名：乐学
	相关武将：倚天·姜伯约
	描述：出牌阶段，可令一名有手牌的其他角色展示一张手牌，若为基本牌或非延时锦囊，则你可将与该牌同花色的牌当作该牌使用或打出直到回合结束；若为其他牌，则立刻被你获得。每阶段限一次
	引用：LuaXLexue
	状态：1217验证通过
]]--
LuaXLexueCard = sgs.CreateSkillCard{
	name = "LuaXLexueCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				return not to_select:isKongcheng()
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = target:getRoom()
		local card = room:askForCardShow(target, source, "LuaXLexue")
		local card_id = card:getEffectiveId()
		room:showCard(target, card_id)
		local type_id = card:getTypeId()
		if type_id == sgs.Card_Basic or card:isNDTrick() then
			room:setPlayerMark(source, "lexue", card_id)
			room:setPlayerFlag(source, "lexue")
		else
			source:obtainCard(card)
			room:setPlayerFlag(source, "-lexue")
		end
	end
}
LuaXLexue = sgs.CreateViewAsSkill{
	name = "LuaXLexue",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Self:hasUsed("#LuaXLexueCard") then
			if #selected == 0 then
				if sgs.Self:hasFlag("lexue") then
					local card_id = sgs.Self:getMark("lexue")
					local card = sgs.Sanguosha:getCard(card_id)
					return to_select:getSuit() == card:getSuit()
				end
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if sgs.Self:hasUsed("#LuaXLexueCard") then
			if sgs.Self:hasFlag("lexue") then
				if #cards == 1 then
					local card_id = sgs.Self:getMark("lexue")
					local card = sgs.Sanguosha:getCard(card_id)
					local first = cards[1]
					local name = card:objectName()
					local suit = first:getSuit()
					local point = first:getNumber()
					local new_card = sgs.Sanguosha:cloneCard(name, suit, point)
					new_card:addSubcard(first)
					new_card:setSkillName(self:objectName())
					return new_card
				end
			end
		else
			return LuaXLexueCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		if player:hasUsed("#LuaXLexueCard") then
			if player:hasFlag("lexue") then
				local card_id = player:getMark("lexue")
				local card = sgs.Sanguosha:getCard(card_id)
				return card:isAvailable(player)
			end
			return false
		end
		return true
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getPhase() ~= sgs.Player_NotActive then
			if player:hasFlag("lexue") then
				if player:hasUsed("#LuaXLexueCard") then
					local card_id = player:getMark("lexue")
					local card = sgs.Sanguosha:getCard(card_id)
					return string.find(pattern, card:objectName())
				end
			end
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		if player:hasFlag("lexue") then
			local card_id = player:getMark("lexue")
			local card = sgs.Sanguosha:getCard(card_id)
			if card:objectName() == "nullification" then
				local cards = player:getHandcards()
				for _,c in sgs.qlist(cards) do
					if c:objectName() == "nullification" or c:getSuit() == card:getSuit() then
						return true
					end
				end
				cards = player:getEquips()
				for _,c in sgs.qlist(cards) do
					if c:objectName() == "nullification" or c:getSuit() == card:getSuit() then
						return true
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：雷击
	相关武将：风·张角
	描述：每当你使用【闪】选择目标后或打出【闪】，你可以令一名角色进行一次判定：若判定结果为黑色，你对该角色造成1点雷电伤害，然后你回复1点体力。 
	引用：LuaLeiji
	状态：1217验证通过
]]--
LuaLeiji = sgs.CreateTriggerSkill{
	name = "LuaLeiji",
	events = {sgs.CardResponded},

	on_trigger = function(self, event, player, data)
		local card_star = data:toCardResponse().m_card
		local room = player:getRoom()
		if card_star:isKindOf("Jink") then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "LuaLeiji-invoke", true, true)
			if not target then return false end
			local judge = sgs.JudgeStruct()
				judge.pattern = ".|black"
				judge.good = false
				judge.negative = true
				judge.reason = self:objectName()
				judge.who = target
				room:judge(judge)
			if judge:isBad() then
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Thunder))
			if player:isAlive() then
				local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				end
			end
		end
	end
}
--[[
	技能名：雷击
	相关武将：怀旧·张角
	描述：当你使用或打出一张【闪】（若为使用则在选择目标后），你可以令一名角色进行一次判定，若判定结果为黑桃，你对该角色造成2点雷电伤害。
	引用：LuaLeiji
	状态：1217验证通过
]]--
LuaLeiji = sgs.CreateTriggerSkill{
	name = "LuaLeiji" ,
	events = {sgs.CardResponded} ,
	on_trigger = function(self, event, player, data)
		local card_star = data:toCardResponse().m_card
		local room = player:getRoom()
		if card_star:isKindOf("Jink") then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "LuaLeiji-invoke", true, true)
			if target then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|spade"
				judge.good = false
				judge.negative = true
				judge.reason = self:objectName()
				judge.who = target
				room:judge(judge)
				if judge:isBad() then
					room:damage(sgs.DamageStruct(self:objectName(), player, target, 2, sgs.DamageStruct_Thunder))
				end
			end
		end
		return false
	end
}
--[[
	技能名：离魂
	相关武将：☆SP·貂蝉
	描述：出牌阶段限一次，你可以弃置一张牌将武将牌翻面，然后获得一名男性角色的所有手牌，且出牌阶段结束时，你交给该角色X张牌。（X为该角色的体力值）
	引用：LuaLihun
	状态：1217验证通过
]]--
LuaLihunCard = sgs.CreateSkillCard{
	name = "LuaLihunCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:isMale() and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		effect.from:turnOver()
		local dummy_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, cd in sgs.qlist(effect.to:getHandcards()) do
			dummy_card:addSubcard(cd)
		end
		if not effect.to:isKongcheng() then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, effect.from:objectName(),effect.to:objectName(), "LuaLihun", nil)
			room:moveCardTo(dummy_card, effect.to, effect.from, sgs.Player_PlaceHand, reason, false)
		end
		effect.to:setFlags("LuaLihunTarget")
	end
}
LuaLihunVS = sgs.CreateViewAsSkill{
	name = "LuaLihun" ,
	n = 1,
	view_filter = function(self, cards, to_select)
		if #cards == 0 then
			return not sgs.Self:isJilei(to_select)
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = LuaLihunCard:clone()
		card:addSubcard(cards[1])
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and (not player:hasUsed("#LuaLihunCard"))
	end
}
LuaLihun = sgs.CreateTriggerSkill{
	name = "LuaLihun" ,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd} ,
	view_as_skill = LuaLihunVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseEnd) and (player:getPhase() == sgs.Player_Play) then
			local target
			for _, other in sgs.qlist(room:getOtherPlayers(player)) do
				if other:hasFlag("LuaLihunTarget") then
					other:setFlags("-LuaLihunTarget")
					target = other
					break
				end
			end
			if (not target) or (target:getHp() < 1) or player:isNude() then return false end
			local to_back = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if player:getCardCount(true) <= target:getHp() then
				if not player:isKongcheng() then to_goback = player:wholeHandCards() end
				for i = 0, 3, 1 do
					if player:getEquip(i) then to_goback:addSubcard(player:getEquip(i):getEffectiveId()) end
				end
			else
				to_goback = room:askForExchange(player, self:objectName(), target:getHp(), true, "LuaLihunGoBack")
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), nil)
			room:moveCardTo(to_goback, player, target, sgs.Player_PlaceHand, reason)
		elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_NotActive) then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("LuaLihunTarget") then
					p:setFlags("-LuaLihunTarget")
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return target and target:hasUsed("#LuaLihunCard")
	end
}

--[[
	技能名：离间
	相关武将：标准·貂蝉
	描述：出牌阶段限一次，你可以弃置一张牌并选择两名男性角色：若如此做，视为其中一名角色对另一名角色使用一张【决斗】。 
	引用：LuaLijian
	状态：0405验证通过
]]--
LuaLijianCard = sgs.CreateSkillCard{
	name = "LuaLijianCard" ,
	filter = function(self, targets, to_select)
		if not to_select:isMale() then
			return false
		end
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		if #targets == 0 and to_select:isProhibited(to_select, duel) then
			return false
		elseif #targets == 1 and to_select:isCardLimited(duel, sgs.Card_MethodUse) then 
			return false 
		end
		return #targets < 2 and to_select:objectName() ~= sgs.Self:objectName()
	end ,
	feasible = function(self, targets)
		return #targets == 2
	end ,
	about_to_use = function(self, room, card_use)
		local use = card_use
		local data = sgs.QVariant()
		data:setValue(card_use)
		local thread = room:getThread()
		thread:trigger(sgs.PreCardUsed, room, card_use.from, data)
		use = data:toCardUse()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, card_use.from:objectName(), "", "LuaLijian", "")
		room:moveCardTo(self, card_use.from, nil, sgs.Player_DiscardPile, reason, true)
		thread:trigger(sgs.CardUsed, room, card_use.from, data)
		thread:trigger(sgs.CardFinished, room, card_use.from, data)
	end ,
	on_use = function(self, room, source, targets)
		local to = targets[1]
		local from = targets[2]
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:toTrick():setCancelable(true)-- 这里true改为false 就是旧版技能
		duel:setSkillName(self:objectName())
		if not from:isCardLimited(duel, sgs.Card_MethodUse) and not from:isProhibited(to, duel) then
			room:useCard(sgs.CardUseStruct(duel, from, to))
		else
			duel:deleteLater()
		end
	end
}
LuaLijian = sgs.CreateOneCardViewAsSkill{
	name = "LuaLijian" ,
	filter_pattern = ".!" ,
	view_as = function(self, card)
		local lijian_card = LuaLijianCard:clone()
		lijian_card:addSubcard(card:getId())
		return lijian_card
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and not player:hasUsed("#LuaLijianCard") and player:getAliveSiblings():length() > 1
	end
}
--[[
	技能名：离间
	相关武将：怀旧-标准·貂蝉-旧、SP·貂蝉、SP·台版貂蝉
	描述：出牌阶段限一次，你可以弃置一张牌并选择两名男性角色：若如此做，视为其中一名角色对另一名角色使用一张【决斗】，此【决斗】不能被【无懈可击】响应。 
	引用：LuaLijian
	状态：0405验证通过
	注：仅需将新版离间的 "duel:toTrick():setCancelable(true)" 那一行改掉即可
]]--
--[[
	技能名：离迁（锁定技）
	相关武将：倚天·夏侯涓
	描述：当你处于连理状态时，势力与连理对象的势力相同；当你处于未连理状态时，势力为魏
	引用:LuaLiqian
	状态：1217验证通过(技能的实现被耦合在本手册的技能“连理”中，这里只是空壳，做一个技能按钮而已)
]]--
LuaLiqian = sgs.CreateTriggerSkill{
	name = "LuaLiqian",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function()	end
}
--[[
	技能名：礼让
	相关武将：国战·孔融
	描述：当你的牌因弃置而置入弃牌堆时，你可以将其中任意数量的牌以任意分配方式交给任意数量的其他角色。
	引用：LuaXLirang
	状态：1217验证通过
]]--
LuaXLirang = sgs.CreateTriggerSkill{
	name = "LuaXLirang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		local source = move.from
		if source and source:objectName() == player:objectName() then
			if move.to_place == sgs.Player_DiscardPile then
				local reason = move.reason
				local basic = bit32.band(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
				if basic == sgs.CardMoveReason_S_REASON_DISCARD then
					local room = player:getRoom()
					local i = 0
					local lirang_card = sgs.IntList()
					for _,card_id in sgs.qlist(move.card_ids) do
						if room:getCardOwner(card_id):objectName() == move.from:objectName() then
							local place = move.from_places:at(i)
							if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
								lirang_card:append(card_id)
							end
						end
						i = i + 1
					end
					if not lirang_card:isEmpty() then
						if player:askForSkillInvoke(self:objectName(), data) then
							local original_lirang = lirang_card
							while room:askForYiji(player, lirang_card, self:objectName(), false, true, true, -1, sgs.SPlayerList(), move.reason, "@lirang-distribute", true) do
								if player:isDead() then return false end
							end
							local ids = move.card_ids
							i = 0
							for _,card_id in sgs.qlist(ids) do
								if (original_lirang:contains(card_id) and not lirang_card:contains(card_id)) then
									move.card_ids:removeOne(card_id)
									move.from_places:removeAt(i)
								end
								i = i+1
							end
							data:setValue(move)
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：疠火
	相关武将：二将成名·程普
	描述：你可以将一张普通【杀】当火【杀】使用，若以此法使用的【杀】造成了伤害，在此【杀】结算后你失去1点体力；你使用火【杀】时，可以额外选择一个目标。
	引用：LuaLihuo、LuaLihuoTarget
	状态：1217验证通过
]]--
LuaLihuoVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaLihuo" ,
	filter_pattern = "%slash" ,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and pattern == "slash"
	end ,
	view_as = function(self, card)
		local acard = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
	end ,
}
invokeLihuo = {}
LuaLihuo = sgs.CreateTriggerSkill{
	name = "LuaLihuo" ,
	events = {sgs.PreDamageDone, sgs.CardFinished} ,
	view_as_skill = LuaLihuoVS ,
	can_trigger = function(self, target)
		return target
	end ,
	on_trigger = function(self, event, player, data)
		if event == sgs.PreDamageDone then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and (damage.card:getSkillName() == self:objectName()) then
				table.insert(invokeLihuo, damage.card)
			end
		elseif (player and player:isAlive() and player:hasSkill(self:objectName())) and (not player:hasFlag("Global_ProcessBroken")) then
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			local can_invoke = false
			for _, c in ipairs(invokeLihuo) do
				if c:getEffectiveId() == use.card:getEffectiveId() then
					can_invoke = true
					table.removeOne(invokeLihuo,c)
					break
				end
			end
			if not can_invoke then return false end
			player:getRoom():loseHp(player)
		end
		return false
	end
}
LuaLihuoTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaLihuo-target" ,
	extra_target_func = function(self, from, card)
		if from:hasSkill("LuaLihuo") and card:isKindOf("FireSlash") then
			return 1
		end
		return 0
	end ,
}
--[[
	技能名：连环
	相关武将：火·庞统
	描述：你可以将一张梅花手牌当【铁索连环】使用或重铸。
	引用：LuaLianhuan
	状态：1217验证通过
]]--
LuaLianhuan = sgs.CreateViewAsSkill{
	name = "LuaLianhuan",
	n = 1,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Club)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local chain = sgs.Sanguosha:cloneCard("iron_chain", cards[1]:getSuit(), cards[1]:getNumber())
			chain:addSubcard(cards[1])
			chain:setSkillName(self:objectName())
			return chain
		end
	end
}
--[[
	技能名：连理
	相关武将：倚天·夏侯涓
	描述：回合开始阶段开始时，你可以选择一名男性角色，你和其进入连理状态直到你的下回合开始：该角色可以帮你出闪，你可以帮其出杀
	引用：LuaLianStart,LuaLianliSlash,LuaLianliJink,LuaLianliClear,LuaLianli,LuaLianlivs(技能暗将，或加入技能库)
	状态：1217验证通过
]]--
LuaLianliStart = sgs.CreateTriggerSkill{
	name = "#LuaLianliStart",
	events = {sgs.GameStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local players = room:getOtherPlayers(player)
		for _,p in sgs.qlist(players) do
			if p:isMale() then
				room:attachSkillToPlayer(p,"LuaLianliSlash")
			end 
		end
		return false
	end
}
LuaLianliSlashCard = sgs.CreateSkillCard{
	name = "LuaLianliSlashCard",
	filter = function(self,targets,to_select)
		local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
		slash:deleteLater()
		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets) do
			qtargets:append(p)
		end
		return slash:targetFilter(qtargets,to_select,sgs.Self)
	end,
	on_validate = function(self,carduse)
		carduse.m_isOwnerUse = false
		local zhangfei = carduse.from
		local room = zhangfei:getRoom()
		local xiahoujuan = room:findPlayerBySkillName("LuaLianli")
		if xiahoujuan then
			local slash = room:askForCard(xiahoujuan,"slash","@lianli-slash",sgs.QVariant(),sgs.Card_MethodResponse,nil,false,"",true)
			if slash then
				return slash
			end
		end
		room:setPlayerFlag(zhangfei,"Global_LianliFailed")
		return nil
	end
}
LuaLianliSlashvs = sgs.CreateViewAsSkill{
	name = "LuaLianliSlash",
	n = 0,
	attached_lord_skill = true,
	enabled_at_play = function(self,player)
		return player:getMark("@tied") > 0 and sgs.Slash_IsAvailable(player) and not player:hasFlag("Global_LianliFailed")
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE 
		and not player:hasFlag("Global_LianliFailed")
	end,
	view_as = function(self,cards)
		return LuaLianliSlashCard:clone()
	end
}
LuaLianliSlash = sgs.CreateTriggerSkill{
	name = "#LuaLianliSlash",
	events = {sgs.CardAsked},
	can_trigger = function(self,target)
		return target ~= nil and target:getMark("@tied") > 0 and not target:hasSkill("LuaLianli")
	end,
	on_trigger = function(self,event,player,data)
		local pattern = data:toStringList()[1]
		if pattern ~= "slash" then return false end
		if not player:askForSkillInvoke("LuaLianli",data) then return false end
		local room = player:getRoom()
		local xiahoujuan = room:findPlayerBySkillName("LuaLianli")
		if xiahoujuan then
			local slash = room:askForCard(xiahoujuan,"slash","@lianli-slash",data,sgs.Card_MethodResponse,nil,false,"",true)
			if slash then
				room:provide(slash)
				return true
			end
		end
		return false
	end
}
LuaLianliJink = sgs.CreateTriggerSkill{
	name = "#LuaLianliJink",
	events = {sgs.CardAsked},
	can_trigger = function(self,target)
		return target ~= nil and target:getMark("@tied") > 0 and target:isAlive() and target:hasSkill(self:objectName())
	end,
	on_trigger = function(self,event,xiahoujuan,data)
		local pattern = data:toStringList()[1]
		if pattern ~= "jink" then return false end
		if not xiahoujuan:askForSkillInvoke("LuaLianli",data) then return false end
		local room = xiahoujuan:getRoom()
		local players = room:getOtherPlayers(xiahoujuan)
		for _ ,player in sgs.qlist(players) do
			if player:getMark("@tied") > 0 then
				local zhangfei = player
				local jink = room:askForCard(zhangfei,"jink","@lianli-jink",data,sgs.Card_MethodResponse,nil,false,"",true)
				if jink then
					room:provide(jink)
					return true
				end
				break
			end
		end
		return false
	end
}
LuaLianli = sgs.CreateTriggerSkill{
	name = "LuaLianli",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,target,data)
		if target:getPhase() == sgs.Player_Start then
			local room = target:getRoom()
			local males = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:isMale() then
					males:append(p)
				end
			end
			local zhangfei = room:askForPlayerChosen(target,males,self:objectName(),"@lianli-card",true,true)
			if males:isEmpty() or zhangfei == nil then
				if target:hasSkill("LuaLiqian") and target:getKingdom() ~= "wei" then
					room:setPlayerProperty(target,"kingdom",sgs.QVariant("wei"))
				end
				local players = room:getAllPlayers()
				for _,p in sgs.qlist(players) do
					if p:getMark("@tied") > 0 then
						p:loseMark("@tied")
					end
				end
				return false
			end
			local log = sgs.LogMessage()
			log.type = "#LianliConnection"
			log.from = target
			log.to:append(zhangfei)
			room:sendLog(log)
			if target:getMark("@tied") == 0 then
				target:gainMark("@tied")
			end
			if zhangfei:getMark("@tied") == 0 then
				for _,p in sgs.qlist(room:getOtherPlayers(target)) do
					if p:getMark("@tied") > 0 then
						p:loseMark("@tied")
						break
					end
				end
				zhangfei:gainMark("@tied")
			end
			if target:hasSkill("LuaLiqian") and target:getKingdom() ~= zhangfei:getKingdom() then
				room:setPlayerProperty(target,"kingdom",sgs.QVariant(zhangfei:getKingdom()))
			end
		end
		return false
	end
}
LuaLianliClear = sgs.CreateTriggerSkill{
	name = "#LuaLianliClear",
	events = {sgs.Death},
	can_trigger = function(self,target)
		return target ~= nil and target:hasSkill(self:objectName())
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if player:getMark("@tied") > 0 then
				player:loseMark("@tied")
			end
		end
		return false
	end
}
--[[
	技能名：连破
	相关武将：神·司马懿
	描述：每当一名角色的回合结束后，若你于本回合杀死至少一名角色，你可以进行一个额外的回合。   
	引用：LuaLianpoCount、LuaLianpo
	状态：0405验证通过
]]--
LuaLianpoCount = sgs.CreateTriggerSkill{
	name = "#LuaLianpo-count" ,
	events = {sgs.Death, sgs.TurnStart} ,
	global = true ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
			local killer
			if death.damage then
				killer = death.damage.from
			else
				killer = nil
			end
			local current = room:getCurrent()
			if killer and current and (current:isAlive() or current:objectName() == death.who:objectName()) and current:getPhase() ~= sgs.Playr_NotActive then
				killer:addMark("LuaLianpo")
			end
		else
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				p:setMark("LuaLianpo", 0)
			end
		end
		return false
	end
}
LuaLianpo = sgs.CreatePhaseChangeSkill{
	name = "LuaLianpo" ,
	frequency = sgs.Skill_Frequent ,
	priority = 1 ,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_NotActive then
			local shensimayi = player:getRoom():findPlayerBySkillName(self:objectName())
			if not shensimayi or shensimayi:getMark("LuaLianpo") <= 0 or not shensimayi:askForSkillInvoke(self:objectName()) then return false end
			shensimayi:gainAnExtraTurn()
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：连营
	相关武将：界限突破·陆逊
	描述：每当你失去最后的手牌后，你可以令至多X名角色各摸一张牌。（X为你失去的手牌数） 
	引用：LuaLianying
	状态：0405验证通过
]]--

LuaLianyingCard = sgs.CreateSkillCard{
	name = "LuaLianyingCard",
	filter = function(self, targets, to_select, erzhang)
		return #targets < sgs.Self:getMark("lianying")
	end,
	on_effect = function(self, effect)
		effect.to:drawCards(1, "lianying")
	end
}
LuaLianyingVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaLianying",
	response_pattern = "@@LuaLianying",
	view_as = function()
		return LuaLianyingCard:clone()
	end
}
LuaLianying = sgs.CreateTriggerSkill{
	name = "LuaLianying",
	events = {sgs.CardsMoveOneTime},
	view_as_skill = LuaLianyingVS ,
	on_trigger = function(self, event, luxun, data)
		local room = luxun:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == luxun:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard  then
			luxun:setTag("LianyingMoveData", data)
			local count = 0
			for i = 0, move.from_places:length() - 1, 1 do
				if move.from_places:at(i) == sgs.Player_PlaceHand then
					count = count + 1
				end
			end
			room:setPlayerMark(luxun, "lianying", count)
			room:askForUseCard(luxun, "@@LuaLianying", "@lianying-card:::" .. tostring(count))
		end
		return false
	end
}
--[[
	技能名：连营
	相关武将：标准·陆逊、SP·台版陆逊、倚天·陆抗
	描述：每当你失去最后的手牌后，你可以摸一张牌。
	引用：LuaNosLianying
	状态：0405验证通过
]]--
LuaNosLianying = sgs.CreateTriggerSkill{
	name = "LuaNosLianying" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, luxun, data)
		local room = luxun:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == luxun:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
			if room:askForSkillInvoke(luxun, self:objectName(), data) then
				luxun:drawCards(1, self:objectName())
			end
		end
		return false
	end
}
--[[
	技能名：烈弓
	相关武将：风·黄忠
	描述：当你于出牌阶段内使用【杀】指定一个目标后，若其手牌数不小于你的体力值或不大于你的攻击范围，你可以令其不能使用【闪】响应此【杀】。
	引用：LuaLiegong
	状态：0405验证通过
]]--
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
LuaLiegong = sgs.CreateTriggerSkill{
	name = "LuaLiegong" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if player:getPhase() ~= sgs.Player_Play or not use.card:isKindOf("Slash") then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			if player:getHp() <= p:getHandcardNum() or player:getAttackRange() >= p:getHandcardNum() then
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player:askForSkillInvoke(self:objectName(), _data) then
					jink_table[index] = 0
				end
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
}
zy:addSkill(LuaLiegong)
--[[
	技能名：烈弓
	相关武将：1v1·黄忠1v1
	描述：当你于出牌阶段内使用【杀】指定一个目标后，若其手牌数不小于你的体力值，你可以令其不能使用【闪】响应此【杀】。
	引用：LuaKOFLiegong
	状态：0405验证通过
]]--

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
LuaKOFLiegong = sgs.CreateTriggerSkill{
	name = "LuaKOFLiegong" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if player:getPhase() ~= sgs.Player_Play or not use.card:isKindOf("Slash") then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			local _data = sgs.QVariant()
			_data:setValue(p)
			if player:getHp() <= p:getHandcardNum() and player:askForSkillInvoke(self:objectName(), _data) then
				jink_table[index] = 0
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
}
--[[
	技能名：烈刃
	相关武将：火·祝融、1v1·祝融1v1
	描述：每当你使用【杀】对目标角色造成伤害后，你可以与该角色拼点：若你赢，你获得其一张牌。 
	引用：LuaLieren
	状态：0405验证通过
]]--
LuaLieren = sgs.CreateTriggerSkill{
	name = "LuaLieren",
	events = {sgs.Damage},
	on_trigger = function(self, event, zhurong, data)
		local room = zhurong:getRoom()
		local damage = data:toDamage()
		local target = damage.to
		if damage.card and damage.card:isKindOf("Slash") and (not zhurong:isKongcheng()) and (not target:isKongcheng()) and (not target:hasFlag("Global_DebutFlag")) and (not damage.chain) and (not damage.transfer) then
			if room:askForSkillInvoke(zhurong, self:objectName(), data) then
				local success = zhurong:pindian(target, "LuaLieren", nil)
				if not success then return false end
				if not target:isNude() then
					local card_id = room:askForCardChosen(zhurong, target, "he", self:objectName())
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, zhurong:objectName())
					room:obtainCard(zhurong, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= Player_PlaceHand)
				end
			end
		end
		return false
	end
}
--[[
	技能名：裂围
	相关武将：1v1·牛金
	描述：每当你杀死对手后，你可以摸三张牌。 
	引用：LuaLiewei
	状态：1217验证通过
]]--
LuaLiewei = sgs.CreateTriggerSkill{
	name = "LuaLiewei",
	events = {sgs.BuryVictim},
	frequency = sgs.Skill_Frequent,
	priority = -2,
	can_trigger = function(target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = player:getRoom()
		if death.damage and death.damage.from and death.damage.from:hasSkill(self:objectName()) then
			if room:askForSkillInvoke(death.damage.from, self:objectName(), data) then
				death.damage.from:drawCards(3, self:objectName())
			end
		end
		return false
	end,
}
--[[
	技能名：流离
	相关武将：标准·大乔、SP·台版大乔、SP·王战大乔
	描述：当你成为【杀】的目标时，你可以弃置一张牌，将此【杀】转移给你攻击范围内的一名其他角色（此【杀】的使用者除外）。
	引用：LuaLiuli
	状态：1217验证通过	
]]--
LuaLiuliCard = sgs.CreateSkillCard{
	name = "LuaLiuliCard" ,
	filter = function(self, targets, to_select)
		if #targets > 0 then return false end
		if to_select:hasFlag("LuaLiuliSlashSource") or (to_select:objectName() == sgs.Self:objectName()) then return false end
		local from
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
			if p:hasFlag("LuaLiuliSlashSource") then
				from = p
				break
			end
		end
		local slash = sgs.Card_Parse(sgs.Self:property("lualiuli"):toString())
		if from and (not from:canSlash(to_select, slash, false)) then return false end
		local card_id = self:getSubcards():first()
		local range_fix = 0
		if sgs.Self:getWeapon() and (sgs.Self:getWeapon():getId() == card_id) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			range_fix = range_fix + weapon:getRange() - 1
		elseif sgs.Self:getOffensiveHorse() and (sgs.Self:getOffensiveHorse():getId() == card_id) then
			range_fix = range_fix + 1
		end
		return sgs.Self:distanceTo(to_select, range_fix) <= sgs.Self:getAttackRange()
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("LuaLiuliTarget")
	end
}
LuaLiuliVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaLiuli" ,
	response_pattern = "@@LuaLiuli",
	filter_pattern = ".!",
	view_as = function(self, card)
		local liuli_card = LuaLiuliCard:clone()
		liuli_card:addSubcard(card)
		return liuli_card
	end
}
LuaLiuli = sgs.CreateTriggerSkill{
	name = "LuaLiuli" ,
	events = {sgs.TargetConfirming} ,
	view_as_skill = LuaLiuliVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash")
				and use.to:contains(player) and player:canDiscard(player,"he") and (room:alivePlayerCount() > 2) then
			local players = room:getOtherPlayers(player)
			players:removeOne(use.from)
			local can_invoke = false
			for _, p in sgs.qlist(players) do
				if use.from:canSlash(p, use.card) and player:inMyAttackRange(p) then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				local prompt = "@liuli:" .. use.from:objectName()
				room:setPlayerFlag(use.from, "LuaLiuliSlashSource")
				room:setPlayerProperty(player, "lualiuli", sgs.QVariant(use.card:toString()))
				if room:askForUseCard(player, "@@LuaLiuli", prompt, -1, sgs.Card_MethodDiscard) then
					room:setPlayerProperty(player, "lualiuli", sgs.QVariant())
					room:setPlayerFlag(use.from, "-LuaLiuliSlashSource")
					for _, p in sgs.qlist(players) do
						if p:hasFlag("LuaLiuliTarget") then
							p:setFlags("-LuaLiuliTarget")
							use.to:removeOne(player)
							use.to:append(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)
							room:getThread():trigger(sgs.TargetConfirming, room, p, data)
							return false
						end
					end
				else
					room:setPlayerProperty(player, "lualiuli", sgs.QVariant())
					room:setPlayerFlag(use.from, "-LuaLiuliSlashSource")
				end
			end
		end
		return false
	end
}


--[[
	技能名：龙胆
	相关武将：标准·赵云、☆SP·赵云、翼·赵云、2013-3v3·赵云、SP·台版赵云、界限突破·赵云
	描述：你可以将一张【杀】当【闪】，一张【闪】当【杀】使用或打出。
	引用：LuaLongdan
	状态：0405验证通过
]]--
LuaLongdan = sgs.CreateOneCardViewAsSkill{
	name = "LuaLongdan" ,
	response_or_use = true,
	view_filter = function(self, card)
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return card:isKindOf("Jink")
		elseif usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			else
				return card:isKindOf("Slash")
			end
		else
			return false
		end
	end ,
	view_as = function(self, card)
		if card:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			jink:addSubcard(card)
			jink:setSkillName(self:objectName())
			return jink
		elseif card:isKindOf("Jink") then
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:addSubcard(card)
			slash:setSkillName(self:objectName())
			return slash
		else
			return nil
		end
	end ,
	enabled_at_play = function(self, target)
		return sgs.Slash_IsAvailable(target)
	end,
	enabled_at_response = function(self, target, pattern)
		return pattern == "slash" or pattern == "jink"
	end
}
--[[
	技能名：龙魂
	相关武将：神·赵云
	描述：你可以将X张同花色的牌按以下规则使用或打出：红桃当【桃】；方块当火【杀】；黑桃当【无懈可击】；梅花当【闪】。（X为你的体力值且至少为1） 
	引用：LuaLonghun
	状态：0405验证通过
]]--
LuaLonghun = sgs.CreateViewAsSkill{
	name = "LuaLonghun" ,
	response_or_use = true ,
	n = 999 ,
	view_filter = function(self, selected, card)
		local n = math.max(1, sgs.Self:getHp())
		if #selected >= n or card:hasFlag("using") then
			return false 
		end
		if n > 1 and not #selected == 0 then
			local suit = selected[1]:getSuit()
			return card:getSuit() == suit
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Self:isWounded() and card:getSuit() == sgs.Card_Heart then
				return true
			elseif card:getSuit() == sgs.Card_Diamond then
				local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
				slash:addSubcard(card:getEffectiveId())
				slash:deleteLater()
				return slash:isAvailable(sgs.Self)
			else
				return false
			end
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				return card:getSuit() == sgs.Card_Club
			elseif pattern == "nullification" then
				return card:getSuit() == sgs.Card_Spade
			elseif string.find(pattern, "peach") then
				return card:getSuit() == sgs.Card_Heart
			elseif pattern == "slash" then
				return card:getSuit() == sgs.Card_Diamond
			end
			return false
		end
		return false
	end ,
	view_as = function(self, cards)
		local n = math.max(1, sgs.Self:getHp())
		if #cards ~= n then 
			return nil 
		end
		local card = cards[1]
		local new_card = nil
		if card:getSuit() == sgs.Card_Spade then
			new_card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Heart then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Club then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Diamond then
			new_card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			new_card:setSkillName(self:objectName())
			for _, c in ipairs(cards) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end ,
	enabled_at_play = function(self, player)
		return player:isWounded() or sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" or pattern == "jink" or (string.find(pattern, "peach") and player:getMark("Global_PreventPeach") == 0) or (pattern == "nullification")
	end ,
	enabled_at_nullification = function(self, player)
		local n = math.max(1, player:getHp())
		local count = 0
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= n then return true end
		end
		for _, card in sgs.qlist(player:getEquips()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= n then return true end
		end
		return false
	end
}
--[[
	技能名：龙魂
	相关武将：测试·高达一号
	描述：你可以将一张牌按以下规则使用或打出：♥当【桃】；♦当火【杀】；♠当【无懈可击】；♣当【闪】。回合开始阶段开始时，若其他角色的装备区内有【青釭剑】，你可以获得之。
	引用：LuaXNosLonghun、LuaXDuojian
	状态：1217验证通过
]]--
LuaLonghun = sgs.CreateViewAsSkill{
	name = "LuaLonghun" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if (#selected >= 1) or to_select:hasFlag("using") then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Self:isWounded() and (to_select:getSuit() == sgs.Card_Heart) then
				return true
			elseif sgs.Slash_IsAvailable(sgs.Self) and (to_select:getSuit() == sgs.Card_Diamond) then
				if sgs.Self:getWeapon() and (to_select:getEffectiveId() == sgs.Self:getWeapon():getId())
						and to_select:isKindOf("Crossbow") then
					return sgs.Self:canSlashWithoutCrossbow()
				else
					return true
				end
			else
				return false
			end
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				return to_select:getSuit() == sgs.Card_Club
			elseif pattern == "nullification" then
				return to_select:getSuit() == sgs.Card_Spade
			elseif string.find(pattern, "peach") then
				return to_select:getSuit() == sgs.Card_Heart
			elseif pattern == "slash" then
				return to_select:getSuit() == sgs.Card_Diamond
			end
			return false
		end
		return false
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = cards[1]
		local new_card = nil
		if card:getSuit() == sgs.Card_Spade then
			new_card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Heart then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Club then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Diamond then
			new_card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			new_card:setSkillName(self:objectName())
			for _, c in ipairs(cards) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end ,
	enabled_at_play = function(self, player)
		return player:isWounded() or sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash")
				or (pattern == "jink")
				or (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")))
				or (pattern == "nullification")
	end ,
	enabled_at_nullification = function(self, player)
		local count = 0
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= 1 then return true end
		end
		for _, card in sgs.qlist(player:getEquips()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= 1 then return true end
		end
	end
}
LuaXDuojian = sgs.CreateTriggerSkill{
	name = "#LuaXDuojian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local others = room:getOtherPlayers(player)
			for _,p in sgs.qlist(others) do
				local weapon = p:getWeapon()
				if weapon and weapon:objectName() == "QinggangSword" then
					if room:askForSkillInvoke(player, self:objectName()) then
						player:obtainCard(weapon)
					end
				end
			end
		end
		return false
	end
}

--[[
	技能名：龙吟
	相关武将：一将成名2013·关平
	描述：每当一名角色于其出牌阶段内使用【杀】选择目标后，你可以弃置一张牌，令此【杀】不计入出牌阶段限制的使用次数，若此【杀】为红色，你摸一张牌。
	引用：LuaLongyin
	状态：1217验证通过
]]--
LuaLongyin = sgs.CreateTriggerSkill{
	name = "LuaLongyin",
	events = {sgs.CardUsed},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
		local me = room:findPlayerBySkillName(self:objectName())
		if me and me:canDiscard(me,"he") and room:askForCard(me, "..", "@LuaLongyin", data,self:objectName()) then
		if use.m_addHistory then
			room:addPlayerHistory(player, use.card:getClassName(),-1)
		if use.card:isRed() then
			me:drawCards(1)
				end
			end
		end
	end
end,
	can_trigger = function(self, target)
		return target:getPhase() == sgs.Player_Play
	end
}

--[[
	技能名：笼络
	相关武将：智·张昭
	描述：回合结束阶段开始时，你可以选择一名其他角色摸取与你弃牌阶段弃牌数量相同的牌
	引用：LuaLongluo
	状态：1217验证通过
]]--
LuaLongluo = sgs.CreateTriggerSkill{
	name = "LuaLongluo" ,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local drawnum = player:getMark(self:objectName())
				if drawnum > 0 then
					if player:askForSkillInvoke(self:objectName(), data) then
						local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
						target:drawCards(drawnum)
					end
				end
			elseif player:getPhase() == sgs.Player_NotActive then
				room:setPlayerMark(player, self:objectName(), 0)
			end
		elseif player:getPhase() == sgs.Player_Discard then
			local move = data:toMoveOneTime()
			if move.from:objectName() == player:objectName() and
					(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				room:setPlayerMark(player, self:objectName(), player:getMark(self:objectName()) + move.card_ids:length())
			end
		end
		return false
	end
}
--[[
	技能名：乱击
	相关武将：火·袁绍
	描述：你可以将两张花色相同的手牌当【万箭齐发】使用。
	引用：LuaLuanji
	状态：1217验证通过
]]--
LuaLuanji = sgs.CreateViewAsSkill{
	name = "LuaLuanji",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getSuit() == card:getSuit() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local cardA = cards[1]
			local cardB = cards[2]
			local suit = cardA:getSuit()
			local aa = sgs.Sanguosha:cloneCard("archery_attack", suit, 0);
			aa:addSubcard(cardA)
			aa:addSubcard(cardB)
			aa:setSkillName(self:objectName())
			return aa
		end
	end
}
--[[
	技能名：乱武（限定技）
	相关武将：林·贾诩、SP·贾诩
	描述：出牌阶段，你可以令所有其他角色对距离最近的另一名角色使用一张【杀】，否则该角色失去1点体力。 
	引用：LuaLuanwu
	状态：0405验证通过	
]]--
LuaLuanwuCard = sgs.CreateSkillCard{
	name = "LuaLuanwuCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@chaos")
		local players = room:getOtherPlayers(source)
		for _,p in sgs.qlist(players) do
			if p:isAlive() then
				room:cardEffect(self, source, p)
			end
			room:getThread():delay()
		end
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local players = room:getOtherPlayers(effect.to)
		local distance_list = sgs.IntList()
		local nearest = 1000
		for _,player in sgs.qlist(players) do
			local distance = effect.to:distanceTo(player)
			distance_list:append(distance)
			nearest = math.min(nearest, distance)
		end
		local luanwu_targets = sgs.SPlayerList()
		for i = 0, distance_list:length() - 1, 1 do
			if distance_list:at(i) == nearest and effect.to:canSlash(players:at(i), nil, false) then
				luanwu_targets:append(players:at(i))
			end
		end
		if luanwu_targets:length() == 0 or not room:askForUseSlashTo(effect.to, luanwu_targets, "@luanwu-slash") then
			room:loseHp(effect.to)
		end
	end
}
LuaLuanwuVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaLuanwu",
	view_as = function(self, cards)
		return LuaLuanwuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@chaos") >= 1
	end
}
LuaLuanwu = sgs.CreateTriggerSkill{
	name = "LuaLuanwu" ,
	frequency = sgs.Skill_Limited ,
	view_as_skill = LuaLuanwuVS ,
	limit_mark = "@chaos" ,
	on_trigger = function()
	end
}
--[[
	技能名：裸衣
	相关武将：标准·许褚
	描述：摸牌阶段，你可以少摸一张牌，若如此做，你使用的【杀】或【决斗】（你为伤害来源时）造成的伤害+1，直到回合结束。
	引用：LuaLuoyiBuff、LuaLuoyi
	状态：1217验证通过
]]--
LuaLuoyiBuff = sgs.CreateTriggerSkill{
	name = "#LuaLuoyiBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.chain or damage.transfer or (not damage.by_user) then return false end
		local reason = damage.card
		if reason and (reason:isKindOf("Slash") or reason:isKindOf("Duel")) then
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("LuaLuoyi") and target:isAlive()
	end
}
LuaLuoyi = sgs.CreateTriggerSkill{
	name = "LuaLuoyi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local count = data:toInt()
		if count > 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				count = count - 1
				room:setPlayerFlag(player, "LuaLuoyi")
				data:setValue(count)
			end
		end
	end
}
--[[
	技能名：裸衣
	相关武将：翼·许褚
	描述：出牌阶段，你可以弃置一张装备牌，若如此做，你使用的【杀】或【决斗】（你为伤害来源时）造成的伤害+1，直到回合结束。每阶段限一次。
	引用：LuaXNeoLuoyi、LuaXNeoLuoyiBuff
	状态：1217验证通过
]]--
LuaXNeoLuoyiCard = sgs.CreateSkillCard{
	name = "LuaXNeoLuoyiCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:setFlags("LuaXNeoLuoyi")
	end
}
LuaXNeoLuoyi = sgs.CreateViewAsSkill{
	name = "LuaXNeoLuoyi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = LuaXNeoLuoyiCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if not player:hasUsed("#LuaXNeoLuoyiCard") then
			return not player:isNude()
		end
		return false
	end
}
LuaXNeoLuoyiBuff = sgs.CreateTriggerSkill{
	name = "#LuaXNeoLuoyiBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local reason = damage.card
		if reason then
			if reason:isKindOf("Slash") or reason:isKindOf("Duel") then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasFlag("LuaXNeoLuoyi") then
				return target:isAlive()
			end
		end
		return false
	end
}
--[[
	技能名：洛神
	相关武将：标准·甄姬、1v1·甄姬1v1、SP·甄姬、SP·台版甄姬
	描述：准备阶段开始时，你可以进行一次判定，若判定结果为黑色，你获得生效后的判定牌且你可以重复此流程。
	引用：LuaLuoshen
	状态：1217验证通过
]]--
LuaLuoshen = sgs.CreateTriggerSkill{
	name = "LuaLuoshen",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				while player:askForSkillInvoke(self:objectName()) do
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					judge.time_consuming = true
					room:judge(judge)
					if judge:isBad() then
						break
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				if card:isBlack() then
					player:obtainCard(card)
					return true
				end
			end
		end
		return false
	end
}

--[[
	技能名：落雁（锁定技）
	相关武将：SP·大乔&小乔
	描述：若你的武将牌上有“星舞牌”，你视为拥有技能“天香”和“流离”。
	引用：LuaLuoyan
	状态：1217验证通过(需与技能“星舞”配合使用)
]]--
LuaLuoyan = sgs.CreateTriggerSkill{
	name = "LuaLuoyan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	can_trigger = function(self,player)
		return player ~= nil 
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventLoseSkill and data:toString() == self:objectName() then
			room:handleAcquireDetachSkills(player,"-tianxiang|-liuli",true)
		elseif event == sgs.EventAcquireSkill and data:toString() == self:objectName() then
			if not player:getPile("xingwu"):isEmpty() then
				room:notifySkillInvoked(player,self:objectName())
				room:handleAcquireDetachSkills(player,"tianxiang|liuli")
			end
		elseif event == sgs.CardsMoveOneTime and player:isAlive() and player:hasSkill(self:objectName(),true) then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceSpecial and move.to_pile_name == "xingwu" then
				if player:getPile("xingwu"):length() == 1 then
					room:notifySkillInvoked(player,self:objectName())
					room:handleAcquireDetachSkills(player,"tianxiang|liuli")
				end
			elseif move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceSpecial) and table.contains(move.from_pile_names,"xingwu") then
				if player:getPile("xingwu"):isEmpty() then
					room:handleAcquireDetachSkills(player,"-tianxiang|-liuli",true)
				end
			end
		end
		return false
	end
}
--[[
	技能名：落英
	相关武将：一将成名·曹植
	描述：其他角色的牌因判定或弃置而置入弃牌堆时，你可以获得其中至少一张梅花牌。 
	引用：LuaLuoying
	状态：0405验证通过
]]--
LuaLuoYing = sgs.CreateTriggerSkill{
	name = "LuaLuoYing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from == nil or move.from:objectName() == player:objectName() then return false end
		if move.to_place == sgs.Player_DiscardPile and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD or move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE) then
			local card_ids = sgs.IntList()
			local i = 0
			for _, card_id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Club and ((move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE and move.from_places:at(i) == sgs.Player_PlaceJudge and move.to_place == sgs.Player_DiscardPile) or (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_JUDGEDONE and room:getCardOwner(card_id):objectName() == move.from:objectName() and (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip))) then
					card_ids:append(card_id)
				end
				i = i + 1
			end
			if card_ids:isEmpty() then
				return false
			else
				if player:askForSkillInvoke(self:objectName(), data) then
					while not card_ids:isEmpty() do
						room:fillAG(card_ids, player)
						local id = room:askForAG(player, card_ids, true, self:objectName())
						if id == -1 then
							room:clearAG(player)
							break
						end
						card_ids:removeOne(id)
						room:clearAG(player)
					end
					if not card_ids:isEmpty() then
						move:removeCardIds(card_ids)
						data:setValue(move)
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:addSubcards(card_ids)
						room:moveCardTo(dummy, player, sgs.Player_PlaceHand, move.reason, true)
					end
				end
			end
		end
		return false
	end
}
