--[[
	代码速查手册（D区）
	技能索引：
		大喝、大雾、单骑、胆守、啖酪、当先、蹈矩、缔盟、洞察、毒计、毒士、毒医、黩武、短兵、断肠、断粮、断指、度势、夺刀
]]--
--[[
	技能名：大喝
	相关武将：☆SP·张飞
	描述：出牌阶段限一次，你可以与一名角色拼点：若你赢，你可以将该角色的拼点牌交给一名体力值不多于你的角色，本回合该角色使用的非♥【闪】无效；若你没赢，你展示所有手牌，然后弃置一张手牌。
	引用：LuaDahe、LuaDahePindian
	状态：验证通过
]]--
LuaDaheCard = sgs.CreateSkillCard{
	name = "LuaDaheCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		source:pindian(targets[1], "LuaDahe", self)
	end
}
LuaDaheVS = sgs.CreateViewAsSkill{
	name = "LuaDahe",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local daheCard = LuaDaheCard:clone()
			daheCard:addSubcard(cards[1])
			return daheCard
		end
	end,
	enabled_at_play = function(self, player)
		if not player:hasUsed("#LuaDaheCard") then
			return not player:isKongcheng()
		end
		return false
	end
}
LuaDahe = sgs.CreateTriggerSkill{
	name = "LuaDahe",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.SlashProceed, sgs.EventPhaseStart},
	view_as_skill = LuaDaheVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local source = room:findPlayerBySkillName(self:objectName())
		if source then
			if event == sgs.SlashProceed then
				local effect = data:toSlashEffect()
				local target = effect.to
				if target:hasFlag(self:objectName()) then
					local prompt = string.format("@dahe-jink:%s:%s:%s", effect.from:objectName(), source:objectName(), self:objectName())
					local jink = room:askForCard(target, "jink", prompt, data, sgs.CardUsed, source)
					if jink and jink:getSuit() ~= sgs.Card_Heart then
						room:slashResult(effect, nil)
					else
						room:slashResult(effect, jink)
					end
					return true
				end
			elseif event == sgs.EventPhaseStart then
				if source:getPhase() == sgs.Player_NotActive then
					local list = room:getOtherPlayers(player)
					for _,other in sgs.qlist(list) do
						if other:hasFlag(self:objectName()) then
							local flag = string.format("-%s", self:objectName())
							room:setPlayerFlag(other, flag)
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
LuaDahePindian = sgs.CreateTriggerSkill{
	name = "#LuaDahe",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Pindian},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pindian = data:toPindian()
		local source = pindian.from
		if pindian.reason == "LuaDahe" and source:hasSkill("LuaDahe") then
			if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
				room:setPlayerFlag(pindian.to, "LuaDahe")
				local to_givelist = room:getAlivePlayers()
				for _,p in sgs.qlist(to_givelist) do
					if p:getHp() > source:getHp() then
						to_givelist:removeOne(p)
					end
				end
				choice = room:askForChoice(source, "LuaDahe", "yes+no")
				if to_givelist:length() > 0 and choice == "yes" then
					local to_give = room:askForPlayerChosen(source, to_givelist, "LuaDahe")
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName())
					reason.m_playerId = to_give:objectName()
					to_give:obtainCard(pindian.to_card)
				end
			else
				if not source:isKongcheng() then
					room:showAllCards(source)
					room:askForDiscard(source, "LuaDahe", 1, 1, false, false)
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
	技能名：大雾
	相关武将：神·诸葛亮
	描述：结束阶段开始时，你可以将X张“星”置入弃牌堆并选择X名角色，若如此做，你的下回合开始前，每当这些角色受到的非雷电伤害结算开始时，防止此伤害。
	引用：LuaDawu
	状态：验证通过
]]--
LuaDawuCard = sgs.CreateSkillCard{
	name = "LuaDawuCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		local stars = sgs.Self:getPile("stars")
		local count = stars:length()
		return #targets < count
	end,
	on_use = function(self, room, source, targets)
		local count = #targets
		local stars = source:getPile("stars")
		for i = 0, count, 1 do
			room:fillAG(stars, source);
			local card_id = room:askForAG(source, stars, false, "qixing-discard")
			source:invoke("clearAG")
			stars:removeOne(card_id)
			local star = sgs.Sanguosha:getCard(card_id)
			room:throwCard(star, nil, nil)
		end
		for _,target in ipairs(targets) do
			target:gainMark("@fog")
		end
	end
}
LuaDawuVS = sgs.CreateViewAsSkill{
	name = "LuaDawu",
	n = 0,
	view_as = function(self, cards)
		return LuaDawuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@dawu"
	end
}
LuaDawu = sgs.CreateTriggerSkill{
	name = "LuaDawu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageForseen},
	view_as_skill = LuaDawuVS,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		return damage.nature ~= sgs.DamageStruct_Thunder
	end,
	can_trigger = function(self, target)
		if target then
			return target:getMark("@fog") > 0
		end
		return false
	end
}
--[[
	技能名：单骑（觉醒技）
	相关武将：SP·关羽
	描述：准备阶段开始时，若你的手牌数大于体力值，且本局游戏主公为曹操，你减1点体力上限，然后获得技能“马术”。
	引用：LuaDanji
	状态：验证通过
]]--
LuaDanji = sgs.CreateTriggerSkill{
	name = "LuaDanji",
	frequency = sgs.Skill_Wake,
	events = {sgs.TurnStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local lord = room:getLord()
		if lord then
			if lord:isCaoCao() then
				player:setMark("danji", 1)
				player:gainMark("@waked")
				room:loseMaxHp(player, 1)
				room:acquireSkill(player, "mashu")
			end
		end
	end,
	can_trigger = function(self, target)
		if target:getMark("danji") == 0 then
			if target:hasSkill(self:objectName()) then
				return target:getHandcardNum() > target:getHp()
			end
		end
		return false
	end
}
--[[
	技能名：胆守
	相关武将：一将成名2013·朱然
	描述： 每当你造成伤害后，你可以摸一张牌，然后结束当前回合并结束一切结算。
]]--
--[[
	技能名：啖酪
	相关武将：SP·杨修
	描述：当一张锦囊牌指定包括你在内的多名目标后，你可以摸一张牌，若如此做，此锦囊牌对你无效。
	引用：LuaDanlao
	状态：1217验证通过
]]--
LuaDanalao = sgs.CreateTriggerSkill{
	name = "LuaDanlao" ,
	events = {sgs.TargetConfirmed, sgs.CardEffected} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (use.to:length() <= 1) or (not use.to:contains(player)) or (not use.card:isKindOf("TrickCard")) then
				return false
			end
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			player:setTag("LuaDanlao", sgs.QVariant(use.card:toString()))
			player:drawCards(1)
		else
			if (not player:isAlive()) or (not player:hasSkill(self:objectName())) then return false end
			local effect = data:toCardEffect()
			if player:getTag("LuaDanlao") == nil or (player:getTag("LuaDanlao"):toString() ~= effect.card:toString()) then return false end
			player:setTag("LuaDanlao", sgs.QVariant(""))
			return true
		end
		return false
	end
}
--[[
	技能名：当先（锁定技）
	相关武将：二将成名·廖化
	描述：回合开始时，你执行一个额外的出牌阶段。
	引用：LuaDangxian
	状态：1217验证通过
]]--
LuaDangxian = sgs.CreateTriggerSkill{
	name = "LuaDangxian" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_RoundStart then
			local room = player:getRoom()
			local thread = room:getThread()
			player:setPhase(sgs.Player_Play)
			room:broadcastProperty(player, "phase")
			if not thread:trigger(sgs.EventPhaseStart, room, player) then
				thread:trigger(sgs.EventPhaseProceeding, room, player)
			end
			thread:trigger(sgs.EventPhaseEnd, room, player)
			player:setPhase(sgs.Player_RoundStart)
			room:broadcastProperty(player, "phase")
		end
	end
}
--[[
	技能名：蹈矩
	相关武将：3D织梦·蒋琬
	描述：出牌阶段，你可以将两张相同颜色手牌当“规”所示锦囊使用。每阶段限用一次。
]]--
--[[
	技能名：缔盟
	相关武将：林·鲁肃
	描述：出牌阶段限一次，你可以选择两名其他角色并弃置X张牌（X为两名目标角色手牌数的差），令这些角色交换手牌。
	引用：LuaDimeng
	状态：验证通过
]]--
LuaDimengCard = sgs.CreateSkillCard{
	name = "LuaDimengCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then
			return false
		elseif #targets == 0 then
			return true
		elseif #targets == 1 then
			local max_diff = sgs.Self:getCardCount(true)
			sc = to_select:getHandcardNum()
			tc = targets[1]:getHandcardNum()
			local diff = math.abs(sc - tc)
			return max_diff >= diff
		end
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local playerA = targets[1]
		local playerB = targets[2]
		local countA = playerA:getHandcardNum()
		local countB = playerB:getHandcardNum()
		local diff = math.abs(countA - countB)
		if diff > 0 then
			room:askForDiscard(source, self:objectName(), diff, diff, false, true)
		end
		local moveA = sgs.CardsMoveStruct()
		moveA.card_ids = playerA:handCards()
		moveA.to = playerB
		moveA.to_place = sgs.Player_PlaceHand
		local moveB = sgs.CardsMoveStruct()
		moveB.card_ids = playerB:handCards()
		moveB.to = playerA
		moveB.to_place = sgs.Player_PlaceHand
		room:moveCards(moveA, false)
		room:moveCards(moveB, false)
	end
}
LuaDimeng = sgs.CreateViewAsSkill{
	name = "LuaDimeng",
	n = 0,
	view_as = function(self, cards)
		local card = LuaDimengCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaDimengCard")
	end
}
--[[
	技能名：洞察
	相关武将：倚天·贾文和
	描述：回合开始阶段开始时，你可以指定一名其他角色：该角色的所有手牌对你处于可见状态，直到你的本回合结束。其他角色都不知道你对谁发动了洞察技能，包括被洞察的角色本身
	状态：验证失败
]]--
--[[
	技能名：毒计
	相关武将：3D织梦·李儒
	描述： 出牌阶段，若你的武将牌上没有牌，你可以将一张黑桃牌置于你的武将牌上。当一名其他角色在其出牌阶段使用一张【杀】指定目标后，你可将此牌置于其手上，并令此【杀】当有【酒】效果的【杀】结算，然后该角色须执行下列一项：将武将牌翻面或失去1点体力。
	引用：LuaDuji
	状态：验证通过
]]--
LuaXDujiCard = sgs.CreateSkillCard{
	name = "LuaXDujiCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:addToPile("du", self)
	end
}
LuaXDujiVS = sgs.CreateViewAsSkill{
	name = "LuaXDuji",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Spade
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local vs_card = LuaDujiCard:clone()
			vs_card:setSkillName(self:objectName())
			vs_card:addSubcard(card)
			return vs_card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getPile("du"):isEmpty()
	end
}
LuaXDuji = sgs.CreateTriggerSkill{
	name = "LuaXDuji",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	view_as_skill = LuaDujiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local pile = player:getPile("du")
		if use.from and use.from:objectName() ~= player:objectName() then
			if use.from:getPhase() == sgs.Player_Play then
				if not pile:isEmpty() then
					if use.card and use.card:isKindOf("Slash") then
						if not use.from:hasFlag("drank") then
							if player:askForSkillInvoke(self:objectName()) then
								local cardid = pile:first()
								room:obtainCard(use.from, cardid)
								room:setPlayerFlag(use.from, "drank")
								local choice = room:askForChoice(use.from, self:objectName(), "turn+lp")
								if  choice == "turn"  then
									use.from:turnOver()
								else
									room:loseHp(use.from)
								end
							end
						end
					end
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
	状态：1217验证通过
]]--
LuaDushi = sgs.CreateTriggerSkill{
	name = "LuaDushi" ,
	events = {sgs.Death} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local killer = nil
		if death.damage then killer = death.damage.from end
		if (death.who:objectName() == player:objectName()) and killer then
			local room = killer:getRoom()
			if (killer:objectName() ~= player:objectName()) and (not killer:hasSkill("benghuai")) then
				killer:gainMark("@collapse")
				room:acquireSkill(killer, "benghuai")
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
--[[
	技能名：毒医
	相关武将：铜雀台·吉本
	描述：出牌阶段限一次，你可以亮出牌堆顶的一张牌并交给一名角色，若此牌为黑色，该角色不能使用或打出其手牌，直到回合结束。
	引用：LuaDuyi
	状态：1217验证通过
]]--
LuaDuyiCard = sgs.CreateSkillCard{
	name = "LuaDuyiCard" ,
	target_fixed = true ,
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
LuaDuyiVS = sgs.CreateViewAsSkill{
	name = "LuaDuyi" ,
	n = 0,
	view_as = function()
		return LuaDuyiCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaDuyiCard")
	end
}
LuaDuyi = sgs.CreateTriggerSkill{
	name = "LuaDuyi" ,
	events = {sgs.EventPhaseChanging, sgs.Death} ,
	view_as_skill = LuaDuyiVS ,
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
	can_trigger = function(self, target)
		return target and target:hasInnateSkill(self:objectName())
	end
}
--[[
	技能名：黩武
	相关武将：SP·诸葛恪
	描述：出牌阶段，你可以选择攻击范围内的一名其他角色并弃置X张牌：若如此做，你对该角色造成1点伤害。
		若你以此法令该角色进入濒死状态，濒死结算后你失去1点体力，且本阶段你不能再次发动“黩武”。（X为该角色当前的体力值）
	状态：1217验证通过
]]--
LuaDuwuCard = sgs.CreateSkillCard{
	name = "LuaDuwuCard" ,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) or (math.max(0, to_select:getHp()) ~= self:subcardsLength()) then return false end
		if (not sgs.Self:inMyAttackRange(to_select)) or (sgs.Self:objectName() == to_select:objectName()) then return false end
		if sgs.Self:getWeapon() and self:getSubcards():contains(sgs.Self:getWeapon():getId()) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			local distance_fix = weapon:getRange() - 1
			if sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
				distance_fix = distance_fix + 1
			end
			return sgs.Self:distanceTo(to_select, distance_fix) <= sgs.Self:getAttackRange()
		elseif sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
			return sgs.Self:distanceTo(to_select, 1) <= sgs.Self:getAttackRange()
		else
			return true
		end
	end ,
	on_effect = function(self, effect)
		effect.from:getRoom():damage(sgs.DamageStruct("LuaDuwu", effect.from, effect.to))
	end
}
LuaDuwuVS = sgs.CreateViewAsSkill{
	name = "LuaDuwu" ,
	n = 999 ,
	view_filter = function()
		return true
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
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and (not player:hasFlag("LuaDuwuEnterDying"))
	end
}
LuaDuwu = sgs.CreateTriggerSkill{
	name = "LuaDuwu" ,
	events = sgs.AskForPeachesDone,--DB:Lua没有QuitDying时机，在这里处理方式略有不同
	view_as_skill = LuaDuwuVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.damage and (dying.damage:getReason() == "LuaDuwu") then
			local from = dying.damage.from
			if from and from:isAlive() then
				room:setPlayerFlag(from, "LuaDuwuEnterDying")
				room:loseHp(from,1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：短兵
	相关武将：国战·丁奉
	描述：你使用【杀】可以额外选择一名距离1的目标。
	引用：LuaXDuanbing
	状态：验证通过
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
						if not sgs.Sanguosha:isProhibited(player, p, slash) then
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
	描述：你死亡时，杀死你的角色失去其所有武将技能。
	引用：LuaDuanchang
	状态：验证通过
]]--
LuaDuanchang = sgs.CreateTriggerSkill{
	name = "LuaDuanchang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			local damage = death.damage
			if damage then
				local murderer = damage.from
				if murderer then
					local room = player:getRoom()
					local skill_list = murderer:getVisibleSkillList()
					for _,skill in sgs.qlist(skill_list) do
						if skill:getLocation() == sgs.Skill_Right then
							room:detachSkillFromPlayer(murderer, skill:objectName())
						end
					end
				end
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
	技能名：断粮
	相关武将：林·徐晃
	描述：你可以将一张黑色牌当【兵粮寸断】使用，此牌必须为基本牌或装备牌；你可以对距离2以内的一名其他角色使用【兵粮寸断】。
	引用：LuaDuanliangTargetMod，LuaDuanliang
	状态：0610验证通过
]]--

LuaDuanliang = sgs.CreateViewAsSkill{
	name = "LuaDuanliang",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack() and (to_select:isKindOf("BasicCard") or to_select:isKindOf("EquipCard"))
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local shortage = sgs.Sanguosha:cloneCard("supply_shortage",cards[1]:getSuit(),cards[1]:getNumber())
		shortage:setSkillName(self:objectName())
		shortage:addSubcard(cards[1])
		return shortage
	end
}
LuaDuanliangTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaDuanliang-target",
	pattern = "SupplyShortage",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
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
	引用：LuaXDuanzhi、LuaXDuanzhiAvoidTriggeringCardsMove
	状态：验证通过
	备注:原版遇到香香会有bug,新版选择手牌可能会有多次选择的情况()两次随机选卡为相同id,以后再修正
]]--
LuaXDuanzhi = sgs.CreateTriggerSkill{
	name = "LuaXDuanzhi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if splayer then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill then
				local source = use.from
				if source and source:objectName() ~= splayer:objectName() then
					local targets = use.to
					if targets and targets:contains(splayer) then
						if player:objectName() == splayer:objectName() then
							if player:askForSkillInvoke(self:objectName()) then
								local card_ids = sgs.IntList()
								local m
								if(source:getCards("he"):length() < 2)then
									m = 1
								else
									m = 2
								end
								while(card_ids:length() < m) do
									if source:isNude() then
										break
									end
									local choice = room:askForChoice(player, self:objectName(), "discard+cancel")
									if choice == "cancel" then
										break
									end
									local id = room:askForCardChosen(player, source, "he", self:objectName())
									while(card_ids:contains(id)) do
										id = room:askForCardChosen(player, source, "he", self:objectName())
									end
									card_ids:append(id)
								end
								if(card_ids:length() > 0) then
									local move1 = sgs.CardsMoveStruct()
									move1.card_ids = card_ids
									move1.from = source
									move1.to_place = sgs.Player_DiscardPile
									room:moveCardsAtomic(move1, false)
								end
								room:loseHp(player)
							end
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
--[[
	技能名：夺刀
	相关武将：一将成名2013·潘璋&马忠
	描述：每当你受到一次【杀】造成的伤害后，你可以弃置一张牌，获得伤害来源装备区的武器牌。
	引用：LuaDuodao
	状态：1217验证通过
]]--
LuaDuodao = sgs.CreateTriggerSkill{
	name = "LuaDuodao" ,
	events = {sgs.Damaged} ,

	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if not damage.card or not damage.card:isKindOf("Slash") or player:isNude() then return false end
		if player:getRoom():askForCard(player, "..", "@duodao-get",data, self:objectName()) then
		if damage.from and damage.from:getWeapon() then
			player:obtainCard(damage.from:getWeapon())
		end
	end
end
}
--[[
	技能名：度势
	相关武将：国战·陆逊
	描述：出牌阶段限四次，你可以弃置一张红色手牌并选择任意数量的其他角色，你与这些角色各摸两张牌并弃置两张牌。
	引用：LuaXDuoshi
	状态：0224验证通过（但无限四次）
	附注：按照dadao.net修改，依次摸牌，然后再依次弃牌，而不是某人摸2弃2，再结算下一个
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
	end
}
