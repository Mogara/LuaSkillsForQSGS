--[[
	代码速查手册（F区）
	技能索引：
		反间、反间、反馈、反馈、逢亮、放权、放逐、飞影、焚城、焚心、奋激、奋迅、愤勇、奉印、伏枥、扶乱、辅佐、父魂、父魂
]]--
--[[
	技能名：反间
	相关武将：标准·周瑜
	描述：出牌阶段，你可以令一名其他角色说出一种花色，然后获得你的一张手牌并展示之，若此牌不为其所述之花色，你对该角色造成1点伤害。每阶段限一次。
	引用：LuaFanjian
	状态：1217验证通过
]]--
LuaFanjianCard = sgs.CreateSkillCard{
	name = "LuaFanjianCard",

	on_effect = function(self, effect)
		local zhouyu = effect.from
		local target = effect.to
		local room = zhouyu:getRoom()
		local card_id = zhouyu:getRandomHandCardId()
		local card = sgs.Sanguosha:getCard(card_id)
		local suit = room:askForSuit(target, "LuaFanjian")
		room:getThread():delay()
		target:obtainCard(card)
		room:showCard(target, card_id)
		if card:getSuit() ~= suit then
			room:damage(sgs.DamageStruct("LuaFanjian", zhouyu, target))
		end
	end
}
LuaFanjian = sgs.CreateZeroCardViewAsSkill{
	name = "LuaFanjian",
	
	view_as = function()
		return LuaFanjianCard:clone()
	end,

	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and (not player:hasUsed("#LuaFanjianCard"))
	end
}
--[[
	技能名：反间
	相关武将：翼·周瑜
	描述：出牌阶段，你可以选择一张手牌，令一名其他角色说出一种花色后展示并获得之，若猜错则其受到你对其造成的1点伤害。每阶段限一次。
	引用：LuaXNeoFanjian
	状态：1217验证通过
]]--
LuaXNeoFanjianCard = sgs.CreateSkillCard{
	name = "LuaXNeoFanjianCard",
	target_fixed = false,
	will_throw = false,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local subid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(subid)
		local card_id = card:getEffectiveId()
		local suit = room:askForSuit(target, "LuaXNeoFanjian")
		room:getThread():delay()
		target:obtainCard(self)
		room:showCard(target, card_id)
		if card:getSuit() ~= suit then
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.from = source
			damage.to = target
			room:damage(damage)
		end
	end
}
LuaXNeoFanjian = sgs.CreateViewAsSkill{
	name = "LuaXNeoFanjian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = LuaXNeoFanjianCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#LuaXNeoFanjianCard")
		end
		return false
	end
}
--[[
	技能名：反馈
	相关武将：界限突破·司马懿
	描述：每当你受到1点伤害后，你可以获得伤害来源的一张牌。 
	引用：LuaFankui
	状态：0405验证通过
]]--
LuaFankui = sgs.CreateMasochismSkill{
	name = "LuaFankui",
	on_damaged = function(self, player, damage)
		local from = damage.from
		local room = player:getRoom()
		for i = 0, damage.damage - 1, 1 do
			local data = sgs.QVariant()
			data:setValue(from)
			if from and not from:isNude() and room:askForSkillInvoke(player, self:objectName(), data) then
				local card_id = room:askForCardChosen(player, from, "he", self:objectName())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
				room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
			else
				break
			end
		end
	end
}
--[[
	技能名：反馈
	相关武将：标准·司马懿
	描述：每当你受到伤害后，你可以获得伤害来源的一张牌。   
	引用：LuaNosFankui
	状态：0405验证通过
]]--
LuaNosFankui = sgs.CreateMasochismSkill{
	name = "LuaNosFankui",
	on_damaged = function(self, player, damage)
		local from = damage.from
		local room = player:getRoom()
		local data = sgs.QVariant()
		data:setValue(from)
		if from and not from:isNude() and room:askForSkillInvoke(player, self:objectName(), data) then
			local card_id = room:askForCardChosen(player, from, "he", self:objectName())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
			room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
		end
	end
}
--[[
	技能名：逢亮
	相关武将：界限突破SP·姜维
	描述：觉醒技，当你进入濒死状态时，你减1点体力上限并将体力值恢复至2点，然后获得技能“挑衅”，将技能“困奋”改为非锁定技。   
	引用：LuaFengliang
	状态：0504验证通过
	备注：zy：要和手册里的困奋配合使用、或者将获得的标记改为“fengliang”并将“LuaKunfen”改为“kunfen”
]]--
LuaFengliang = sgs.CreateTriggerSkill{
	name = "LuaFengliang" ,
	events = {sgs.EnterDying} ,
	frequency = sgs.Skill_Wake ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName()) and target:isAlive() and target:getMark(self:objectName()) == 0
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        room:addPlayerMark(player, self:objectName(), 1)
        if room:changeMaxHpForAwakenSkill(player) and player:getMark(self:objectName()) > 0 then
            local recover = 2 - player:getHp()
            room:recover(player, sgs.RecoverStruct(nil, nil, recover))
            room:handleAcquireDetachSkills(player, "tiaoxin")
            if player:hasSkill("LuaKunfen", true) then
				room:doNotify(player, 86, sgs.QVariant("LuaKunfen"))
			end
        end
		return false
	end
}
--[[
	技能名：放权
	相关武将：山·刘禅
	描述：你可以跳过你的出牌阶段，若如此做，你在回合结束时可以弃置一张手牌令一名其他角色进行一个额外的回合。
	引用：LuaFangquan、LuaFangquanGive
	状态：1217验证通过
]]--
LuaFangquan = sgs.CreateTriggerSkill{
	name = "LuaFangquan" ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play then
			local invoked = false
			if player:isSkipped(sgs.Player_Play) then return false end
			invoked = player:askForSkillInvoke(self:objectName())
			if invoked then
				player:setFlags("LuaFangquan")
				player:skip(sgs.Player_Play)
			end
		elseif change.to == sgs.Player_NotActive then
			if player:hasFlag("LuaFangquan") then
				if not player:canDiscard(player, "h") then return false end
				if not room:askForDiscard(player, "LuaFangquan", 1, 1, true) then return false end
				local _player = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				local p = _player
				local playerdata = sgs.QVariant()
				playerdata:setValue(p)
				room:setTag("LuaFangquanTarget", playerdata)
			end
		end
		return false
	end
}
LuaFangquanGive = sgs.CreateTriggerSkill{
	name = "#LuaFangquan-give" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("LuaFangquanTarget") then
			local target = room:getTag("LuaFangquanTarget"):toPlayer()
			room:removeTag("LuaFangquanTarget")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end ,
	priority = 1
}
--[[
	技能名：放逐
	相关武将：林·曹丕、铜雀台·曹丕、神·司马懿
	描述：每当你受到伤害后，你可以令一名其他角色摸X张牌，然后将其武将牌翻面。（X为你已损失的体力值）   
	引用：LuaFangzhu
	状态：0405验证通过
]]--
LuaFangzhu = sgs.CreateMasochismSkill{
	name = "LuaFangzhu",
	on_damaged = function(self, player)
		local room = player:getRoom()
		local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "fangzhu-invoke", player:getMark("JilveEvent") ~= 35, true)
		if to then
			to:drawCards(player:getLostHp(), self:objectName())
			to:turnOver()
		end
	end
}
--[[
	技能名：飞影（锁定技）
	相关武将：神·曹操、倚天·魏武帝
	描述：其他角色与你的距离+1 
	引用：LuaFeiying
	状态：0405验证通过
]]--
LuaFeiying = sgs.CreateDistanceSkill{
	name = "LuaFeiying",
	correct_func = function(self, from, to)
		if to:hasSkill("LuaFeiying") then
			return 1
		else
			return 0
		end
	end
}
--[[
	技能名：焚城（限定技）
	相关武将：一将成名2013·李儒
	描述：出牌阶段，你可以令所有其他角色选择一项：弃置X张牌，或受到你对其造成的1点火焰伤害。（X为该角色装备区牌的数量且至少为1）
	引用：LuaFencheng
	状态：1217验证通过
]]--
LuaFenchengCard = sgs.CreateSkillCard{
	name = "LuaFenchengCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@burn")
		local players = room:getOtherPlayers(source)
		source:setFlags("LuaFenchengUsing")
		for _, player in sgs.qlist(players) do
			if player:isAlive() then
				room:cardEffect(self, source, player)
			end
		end
		source:setFlags("-LuaFenchengUsing")
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local length = math.max(1, effect.to:getEquips():length())
		if not effect.to:canDiscard(effect.to, "he") then
			room:damage(sgs.DamageStruct("LuaFencheng", effect.from, effect.to, 1, sgs.DamageStruct_Fire))
		elseif not room:askForDiscard(effect.to, "LuaFencheng", length, length, true, true) then
			room:damage(sgs.DamageStruct("LuaFencheng", effect.from, effect.to, 1, sgs.DamageStruct_Fire))
		end
	end
}
LuaFenchengVS = sgs.CreateViewAsSkill{
	name = "LuaFencheng" ,
	n = 0,
	view_as = function()
		return LuaFenchengCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@burn") >= 1
	end
}
LuaFencheng = sgs.CreateTriggerSkill{
	name = "LuaFencheng" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@burn",
	events = {},
	view_as_skill = LuaFenchengVS,
	
	on_trigger = function()
	end
}
--[[
	技能名：焚心（限定技）
	相关武将：铜雀台·灵雎、SP·灵雎
	描述：当你杀死一名非主公角色时，在其翻开身份牌之前，你可以与该角色交换身份牌。（你的身份为主公时不能发动此技能。）
	引用：LuaXFenxin
	状态：1217验证通过
]]--
LuaXFenxin = sgs.CreateTriggerSkill{
	name = "LuaXFenxin",
	frequency = sgs.Skill_Limited,
	events = {sgs.AskForPeachesDone},
	limit_mark = "@burnheart",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local mode = room:getMode()
		if string.sub(mode, -1) == "p" or string.sub(mode, -2) == "pd" or string.sub(mode, -2) == "pz" then
			local dying = data:toDying()
			if dying.damage then
				local killer = dying.damage.from
				if killer and not killer:isLord() then
					if not player:isLord() and player:getHp() <= 0 then
						if killer:hasSkill(self:objectName()) then
							if killer:getMark("@burnheart") > 0 then
								room:setPlayerFlag(player, "FenxinTarget")
								local ai_data = sgs.QVariant()
								ai_data:setValue(player)
								if room:askForSkillInvoke(killer, self:objectName(), ai_data) then
									killer:loseMark("@burnheart")
									local role1 = killer:getRole()
									local role2 = player:getRole()
									killer:setRole(role2)
									room:setPlayerProperty(killer, "role", sgs.QVariant(role2))
									player:setRole(role1)
									room:setPlayerProperty(player, "role", sgs.QVariant(role1))
								end
								room:setPlayerFlag(player, "-FenxinTarget")
								return false
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：奋激
	相关武将：风·周泰
	描述：每当一名角色的手牌因另一名角色的弃置或获得为手牌而失去后，你可以失去1点体力：若如此做，该角色摸两张牌。 
	引用：LuaFenji
	状态：0405验证通过
]]--
LuaFenji = sgs.CreateTriggerSkill{
	name = "LuaFenji",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if player:getHp() > 0 and move.from and move.from:isAlive() and move.from_places:contains(sgs.Player_PlaceHand)
			and ((move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE
			and move.reason.m_playerId ~= move.reason.m_targetId)
			or (move.to and move.to:objectName() ~= move.from:objectName() and move.to_place == sgs.Player_PlaceHand
				and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_GIVE
				and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_SWAP)) then
			move.from:setFlags("LuaFenjiMoveFrom") --For AI
			local invoke = room:askForSkillInvoke(player, self:objectName(), data)
			move.from:setFlags("-LuaFenjiMoveFrom")
			if invoke then
				room:loseHp(player)
				if move.from:isAlive() then
					for _,p in sgs.qlist(room:getAllPlayers()) do
						if p:objectName() == move.from:objectName() then
							room:drawCards(p, 2, "LuaFenji")
							break
						end
					end
				end
			end
		end
	end
}
--[[
	技能名：奋迅
	相关武将：国战·丁奉
	描述：出牌阶段限一次，你可以弃置一张牌并选择一名其他角色，你获得以下锁定技：本回合你无视与该角色的距离。
	引用：LuaFenxun
	状态：1217验证通过
]]--
LuaFenxunCard = sgs.CreateSkillCard{
	name = "LuaFenxunCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local _data = sgs.QVariant()
		_data:setValue(effect.to)
		effect.from:setTag("LuaFenxunTarget", _data)
		room:setFixedDistance(effect.from, effect.to, 1)
	end
}
LuaFenxunVS = sgs.CreateViewAsSkill{
	name = "LuaFenxun" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return (#selected == 0) and (not sgs.Self:isJilei(to_select))
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local first = LuaFenxunCard:clone()
		first:addSubcard(cards[1])
		first:setSkillName(self:objectName())
		return first
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and (not player:hasUsed("#LuaFenxunCard"))
	end
}
LuaFenxun = sgs.CreateTriggerSkill{
	name = "LuaFenxun" ,
	events = {sgs.EventPhaseChanging, sgs.Death, sgs.EventLoseSkill} ,
	view_as_skill = LuaFenxunVS ,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
		elseif event == sgs.EventLoseSkill then
			if data:toString() ~= self:objectName() then return false end
		end
		local target = player:getTag("LuaFenxunTarget"):toPlayer()
		if target then
			player:getRoom():setFixedDistance(player, target, -1)
			player:removeTag("LuaFenxunTarget")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:getTag("LuaFenxunTarget"):toPlayer()
	end
}
--[[
	技能名：愤勇
	相关武将：☆SP·夏侯惇
	描述：每当你受到一次伤害后，你可以竖置你的体力牌；当你的体力牌为竖置状态时，防止你受到的所有伤害。
	引用：LuaFenyong、LuaFenyongClear
	状态：1217验证通过
]]--
LuaFenyong = sgs.CreateTriggerSkill{
	name = "LuaFenyong" ,
	events = {sgs.Damaged, sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			if player:getMark("@fenyong") == 0 then
				if player:askForSkillInvoke(self:objectName()) then
					player:gainMark("@fenyong")
				end
			end
		elseif event == sgs.DamageInflicted then
			if player:getMark("@fenyong") > 0 then
				return true
			end
		end
		return false
	end
}
LuaFenyongClear = sgs.CreateTriggerSkill{
	name = "#LuaFenyong-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaFenyong" then
			player:loseAllMarks("@fenyong")
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：奉印
	相关武将：铜雀台·伏完
	描述：其他角色的回合开始时，若其当前的体力值不比你少，你可以交给其一张【杀】，令其跳过其出牌阶段和弃牌阶段。
	引用：LuaFengyin
	状态：1217验证通过
]]--
LuaFengyinCard = sgs.CreateSkillCard{
	name = "LuaFengyinCard" ,
	target_fixed = true ,
	will_throw = false,
	handling_method = sgs.Card_MethodNone ,
	on_use = function(self, room, source, targets)
		local target = room:getCurrent()
		target:obtainCard(self)
		room:setPlayerFlag(target, "LuaFengyin_target")
	end
}
LuaFengyinVS = sgs.CreateViewAsSkill{
	name = "LuaFengyin" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return (#selected == 0) and to_select:isKindOf("Slash")
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = LuaFengyinCard:clone()
		card:addSubcard(cards[1])
		return card
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaFengyin"
	end
}
LuaFengyin = sgs.CreateTriggerSkill{
	name = "LuaFengyin" ,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseStart} ,
	view_as_skill = LuaFengyinVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if not splayer or splayer:objectName() == player:objectName() then return false end
		if (event == sgs.EventPhaseChanging) and (data:toPhaseChange().to == sgs.Player_Start) then
			if player:getHp() >= splayer:getHp() then
				room:askForUseCard(splayer, "@@LuaFengyin", "@fengyin", -1, sgs.Card_MethodNone)
			end
		end
		if (event == sgs.EventPhaseStart) and player:hasFlag("LuaFengyin_target") then
			player:skip(sgs.Player_Play)
			player:skip(sgs.Player_Discard)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end ,
}
--[[
	技能名：伏枥（限定技）
	相关武将：二将成名·廖化
	描述：当你处于濒死状态时，你可以将体力回复至X点（X为现存势力数），然后将你的武将牌翻面。
	引用：LuaFuli、LuaLaoji1
	状态：1217验证通过
]]--
getKingdomsFuli = function(yuanshu)
	local kingdoms = {}
	local room = yuanshu:getRoom()
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		local flag = true
		for _, k in ipairs(kingdoms) do
			if p:getKingdom() == k then
				flag = false
				break
			end
		end
		if flag then table.insert(kingdoms, p:getKingdom()) end
	end
	return #kingdoms
end
LuaFuli = sgs.CreateTriggerSkill{
	name = "LuaFuli" ,
	frequency = sgs.Skill_Limited ,
	events = {sgs.AskForPeaches} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		if dying_data.who:objectName() ~= player:objectName() then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
			room:removePlayerMark(player, "@laoji")
			local recover = sgs.RecoverStruct()
			recover.recover = math.min(getKingdomsFuli(player), player:getMaxHp()) - player:getHp()
			room:recover(player, recover)
			player:turnOver()
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName())) and (target:getMark("@laoji") > 0)
	end
}
LuaLaoji1 = sgs.CreateTriggerSkill{
	name = "#@laoji-Lua-1" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		player:gainMark("@laoji", 1)
	end
}
--[[
	技能名：扶乱
	相关武将：贴纸·王元姬
	描述：出牌阶段限一次，若你未于本阶段使用过【杀】，你可以弃置三张相同花色的牌，令你攻击范围内的一名其他角色将武将牌翻面，然后你不能使用【杀】直到回合结束。
	引用：LuaFuluan、LuaFuluanForbid
	状态：1217验证通过
]]--
LuaFuluanCard = sgs.CreateSkillCard{
	name = "LuaFuluanCard" ,
	filter = function(self, targets, to_select)
		if #targets ~= 0 then return false end
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
		local room = effect.to:getRoom()
		effect.to:turnOver()
		room:setPlayerCardLimitation(effect.from, "use", "Slash", true)
	end ,
}
LuaFuluan = sgs.CreateViewAsSkill{
	name = "LuaFuluan" ,
	n = 3 ,
	view_filter = function(self, selected, to_select)
		if #selected >= 3 then return false end
		if sgs.Self:isJilei(to_select) then return false end
		if #selected ~= 0 then
			local suit = selected[1]:getSuit()
			return to_select:getSuit() == suit
		end
		return true
	end ,
	view_as = function(self, cards)
		if #cards ~= 3 then return nil end
		local card = LuaFuluanCard:clone()
		card:addSubcard(cards[1])
		card:addSubcard(cards[2])
		card:addSubcard(cards[3])
		return card
	end ,
	enabled_at_play = function(self, player)
		return (player:getCardCount(true) >= 3) and (not player:hasUsed("#LuaFuluanCard")) and (not player:hasFlag("ForbidLuaFuluan"))
	end
}
LuaFuluanForbid = sgs.CreateTriggerSkill{
	name = "#LuaFuluan-forbid" ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (player:getPhase() == sgs.Player_Play) and (not player:hasFlag("ForbidLuaFuluan")) then
			player:getRoom():setPlayerFlag(player, "ForbidLuaFuluan")
		end
		return false
	end
}
--[[
	技能名：辅佐
	相关武将：智·张昭
	描述：当有角色拼点时，你可以打出一张点数小于8的手牌，让其中一名角色的拼点牌加上这张牌点数的二分之一（向下取整）
	引用：LuaFuzuo
	状态：1217验证通过
]]--
LuaFuzuoCard = sgs.CreateSkillCard{
	name = "LuaFuzuoCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:hasFlag("LuaFuzuo_target")
	end ,
	on_effect = function(self, effect)
		effect.to:getRoom():setPlayerMark(effect.to, "LuaFuzuo", self:getNumber())
	end
}
LuaFuzuoVS = sgs.CreateViewAsSkill{
	name = "LuaFuzuo" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return (#selected == 0) and (not to_select:isEquipped()) and (to_select:getNumber() < 8)
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = LuaFuzuoCard:clone()
		card:addSubcard(cards[1])
		return card
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaFuzuo"
	end
}
LuaFuzuo = sgs.CreateTriggerSkill{
	name = "LuaFuzuo" ,
	events = {sgs.PindianVerifying} ,
	view_as_skill = LuaFuzuoVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local zhangzhao = room:findPlayerBySkillName(self:objectName())
		if not zhangzhao then return false end
		local pindian = data:toPindian()
		room:setPlayerFlag(pindian.from, "LuaFuzuo_target")
		room:setPlayerFlag(pindian.to, "LuaFuzuo_target")
		room:setTag("LuaFuzuoPindianData", data)
		if room:askForUseCard(zhangzhao, "@@LuaFuzuo", "@fuzuo-pindian", -1, sgs.Card_MethodDiscard) then
			local isFrom = (pindian.from:getMark(self:objectName()) > 0)
			if isFrom then
				local to_add = pindian.from:getMark(self:objectName()) / 2
				room:setPlayerMark(pindian.from, self:objectName(), 0)
				pindian.from_number = pindian.from_number + to_add
			else
				local to_add = pindian.to:getMark(self:objectName()) / 2
				room:setPlayerMark(pindian.to, self:objectName(), 0)
				pindian.to_number = pindian.to_number + to_add
			end
			data:setValue(pindian)
		end
		room:setPlayerFlag(pindian.from, "-LuaFuzuo_target")
		room:setPlayerFlag(pindian.to, "-LuaFuzuo_target")
		room:removeTag("LuaFuzuoPindianData")
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：父魂
	相关武将：一将成名2012·关兴&张苞
	描述：你可以将两张手牌当普通【杀】使用或打出。每当你于出牌阶段内以此法使用【杀】造成伤害后，你获得技能“武圣”、“咆哮”，直到回合结束。
	引用：LuaFuhun
	状态：1217验证通过
]]--
LuaFuhunVS = sgs.CreateViewAsSkill{
	name = "LuaFuhun" ,
	n = 2,
	view_filter = function(self, selected, to_select)
		return (#selected < 2) and (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_SuitToBeDecided, 0)
		slash:setSkillName(self:objectName())
		slash:addSubcard(cards[1])
		slash:addSubcard(cards[2])
		return slash
	end ,
	enabled_at_play = function(self, player)
		return (player:getHandcardNum() >= 2) and sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return (player:getHandcardNum() >= 2) and (pattern == "slash")
	end
}
LuaFuhun = sgs.CreateTriggerSkill{
	name = "LuaFuhun" ,
	events = {sgs.Damage, sgs.EventPhaseChanging} ,
	view_as_skill = LuaFuhunVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) and (player and player:isAlive() and player:hasSkill(self:objectName())) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and (damage.card:getSkillName() == self:objectName())
					and (player:getPhase() == sgs.Player_Play) then
				room:handleAcquireDetachSkills(player, "wusheng|paoxiao")
				player:setFlags(self:objectName())
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) and player:hasFlag(self:objectName()) then
				room:handleAcquireDetachSkills(player, "-wusheng|-paoxiao")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：父魂
	相关武将：怀旧-一将2·关&张-旧
	描述：摸牌阶段开始时，你可以放弃摸牌，改为从牌堆顶亮出两张牌并获得之，若亮出的牌颜色不同，你获得技能“武圣”、“咆哮”，直到回合结束。
	引用：LuaNosFuhun
	状态：1217验证通过
]]--
LuaNosFuhun = sgs.CreateTriggerSkill{
	name = "LuaNosFuhun",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if event == sgs.EventPhaseStart and phase == sgs.Player_Draw then
			if player:askForSkillInvoke(self:objectName()) then
				local id1 = room:drawCard()
				local id2 = room:drawCard()
				local card1 = sgs.Sanguosha:getCard(id1)
				local card2 = sgs.Sanguosha:getCard(id2)
				local diff = card1:isBlack() ~= card2:isBlack()
				local move = sgs.CardsMoveStruct()
				local move2 = sgs.CardsMoveStruct()
				move.card_ids:append(id1)
				move.card_ids:append(id2)
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),self:objectName(), "")
				move.to_place = sgs.Player_PlaceTable
				room:moveCardsAtomic(move, true)
				room:getThread():delay()
				move2 = move
				move2.to_place = sgs.Player_PlaceHand
				move2.to = player
				room:moveCardsAtomic(move2, true)
				if diff then
					room:setEmotion(player, "good")
					room:acquireSkill(player, "wusheng")
					room:acquireSkill(player, "paoxiao")
					player:setFlags(self:objectName())
				else
					room:setEmotion(player, "bad")
				end
				return true
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasFlag(self:objectName()) then
				room:detachSkillFromPlayer(player, "wusheng")
				room:detachSkillFromPlayer(player, "paoxiao")
			end
		end
	end
}
