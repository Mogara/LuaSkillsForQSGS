--[[
	代码速查手册（J区）
	代码索引：
		鸡肋、激昂、激将、极略、急救、急速、急袭、集智、集智、嫉恶、奸雄、奸雄、坚守、将驰、节命、结姻、竭缘、解烦、解烦、解惑、解围、尽瘁、禁酒、精策、精锐、酒池、酒诗、救援、救主、举荐、举荐、巨象、倨傲、据守、据守、据守、聚武、绝策、绝汲、绝境、绝境、绝情、军威、峻刑
]]--
--[[
	技能名：鸡肋
	相关武将：SP·杨修
	描述：每当你受到伤害后，你可以选择一种牌的类别，伤害来源不能使用、打出或弃置其该类别的手牌，直到回合结束。 
	引用：LuaJilei、LuaJileiClear
	状态：0405验证通过
]]--
LuaJilei = sgs.CreateTriggerSkill{
	name = "LuaJilei",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local current  = room:getCurrent()
		if not current or current:getPhase()==sgs.Player_NotActive or current:isDead() or not damage.from then
			return false
		end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local choice = room:askForChoice(player, self:objectName(), "BasicCard+EquipCard+TrickCard")
			local jileis = damage.from:getTag(self:objectName()):toString():split("+")
			if table.contains(jileis, choice) then return false end
			table.insert(jileis,choice)
			damage.from:setTag(self:objectName(), sgs.QVariant(table.concat(jileis, "+")))
			local _type = choice.."|.|.|hand" --只是手牌
			room:setPlayerCardLimitation(damage.from, "use,response,discard", _type, true)
			local typename = string.lower(string.gsub(choice,"Card",""))
			if damage.from:getMark("@jilei_"..typename) == 0 then
				room:addPlayerMark(damage.from, "@jilei_"..typename)
			end
		end
	end
}
LuaJileiClear = sgs.CreateTriggerSkill{
	name = "#LuaJilei-clear",
	events = {sgs.EventPhaseChanging,sgs.Death},
	priority = 5,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then 
				return false 
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() or player:objectName() ~= room:getCurrent():objectName() then
				return false
			end
		end
		local players = room:getAllPlayers()
		for _,p in sgs.qlist(players) do
			local jilei_list = p:getTag("LuaJilei"):toString():split("+")
			if #jilei_list > 0 then
				for _,jileity in ipairs(jilei_list) do
					room:removePlayerCardLimitation(p, "use,response,discard", jileity.."|.|.|hand$1")
					local typename = string.lower(string.gsub(jileity,"Card",""))
					room:setPlayerMark(p, "@jilei_"..typename, 0)
				end
				p:removeTag("LuaJilei")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：激昂
	相关武将：山·孙策，☆SP·吕蒙
	描述：每当你指定或成为红色【杀】或【决斗】的目标后，你可以摸一张牌。 
	引用：LuaJiang
	状态：0405验证通过
]]--
luaJiang = sgs.CreateTriggerSkill{
	name = "LuaJiang" ,
	events = {sgs.TargetConfirmed, sgs.TargetSpecified},
	frequency = sgs.Skill_Frequent, 
	on_trigger = function(self, event, sunce, data)
		local use = data:toCardUse()
		if event == sgs.TargetSpecified or (event == sgs.TargetConfirmed and use.to:contains(sunce)) then
			if use.card:isKindOf("Duel") or (use.card:isKindOf("Slash") and use.card:isRed()) then
				if sunce:askForSkillInvoke(self:objectName(), data) then
					sunce:drawCards(1, self:objectName())
				end
			end
		end
		return false
	end
}
--[[
	技能名：激将（主公技）
	相关武将：标准·刘备、山·刘禅、怀旧-标准·刘备-旧
	描述：当你需要使用或打出一张【杀】时，你可以令其他蜀势力角色打出一张【杀】（视为由你使用或打出）。
	引用：LuaJijiang
	状态：1217验证通过
]]--

LuaJijiangCard = sgs.CreateSkillCard{
	name = "LuaJijiangCard" ,
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local plist = sgs.PlayerList()
		for i = 1, #targets, 1 do
			plist:append(targets[i])
		end
		return slash:targetFilter(plist, to_select, sgs.Self)
	end ,
	on_validate = function(self, cardUse) --这是0610新加的哦~~~~
		cardUse.m_isOwnerUse = false
		local liubei = cardUse.from
		local targets = cardUse.to
		room = liubei:getRoom()
		local slash = nil
		local lieges = room:getLieges("shu", liubei)
		for _, target in sgs.qlist(targets) do
			target:setFlags("LuaJijiangTarget")
		end
		for _, liege in sgs.qlist(lieges) do
			slash = room:askForCard(liege, "slash", "@jijiang-slash:" .. liubei:objectName(), sgs.QVariant(), sgs.Card_MethodResponse, liubei) --未处理胆守
			if slash then
				for _, target in sgs.qlist(targets) do
					target:setFlags("-LuaJijiangTarget")
				end
				return slash
			end
		end
		for _, target in sgs.qlist(targets) do
			target:setFlags("-LuaJijiangTarget")
		end
		room:setPlayerFlag(liubei, "Global_LuaJijiangFailed")
		return nil
	end
}
hasShuGenerals = function(player)
	for _, p in sgs.qlist(player:getSiblings()) do
		if p:isAlive() and (p:getKingdom() == "shu") then
			return true
		end
	end
	return false
end
LuaJijiangVS = sgs.CreateViewAsSkill{
	name = "LuaJijiang$" ,
	n = 0 ,
	view_as = function()
		return LuaJijiangCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return hasShuGenerals(player)
		   and player:hasLordSkill("LuaJijiang")
		   and (not player:hasFlag("Global_LuaJijiangFailed"))
		   and sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return hasShuGenerals(player)
		   and player:hasLordSkill("LuaJijiang")
		   and ((pattern == "slash") or (pattern == "@jijiang"))
		   and (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
		   and (not player:hasFlag("Global_LuaJijiangFailed"))
	end
}
LuaJijiang = sgs.CreateTriggerSkill{
	name = "LuaJijiang$" ,
	events = {sgs.CardAsked} ,
	view_as_skill = LuaJijiangVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toStringList()[1]
		local prompt = data:toStringList()[2]
		if (pattern ~= "slash") or string.find(prompt, "@jijiang-slash") then return false end
		local lieges = room:getLieges("shu", player)
		if lieges:isEmpty() then return false end
		if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
		for _, liege in sgs.qlist(lieges) do
			local slash = room:askForCard(liege, "slash", "@jijiang-slash:" .. player:objectName(), sgs.QVariant(), sgs.Card_MethodResponse, player)
			if slash then
				room:provide(slash)
				return true
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasLordSkill("LuaJijiang")
	end
}
--[[
	技能名：极略
	相关武将：神·司马懿
	描述：你可以弃一枚“忍”并发动以下技能之一：“鬼才”、“放逐”、“集智”、“制衡”、“完杀”。   
	引用：LuaJilve、LuaJilveClear
	状态：0405验证通过
]]--
LuaJilveCard = sgs.CreateSkillCard{
	name = "LuaJilveCard",
	target_fixed = true,
	about_to_use = function(self, room, use)
		local shensimayi = use.from
		local choices = {}
		if not shensimayi:hasFlag("LuaJilveZhiheng") and shensimayi:canDiscard(shensimayi, "he") then
			table.insert(choices,"zhiheng")
		end
		if not shensimayi:hasFlag("LuaJilveWansha") then
			table.insert(choices,"wansha")
		end
		table.insert(choices,"cancel")
		if #choices == 1 then return end
		local choice = room:askForChoice(shensimayi, "LuaJilve", table.concat(choices,"+"))
		if choice == "cancel" then
			room:addPlayerHistory(shensimayi, "#LuaJilveCard", -1)
			return
		end
		shensimayi:loseMark("@bear")
		room:notifySkillInvoked(shensimayi, "LuaJilve")
		if choice == "wansha" then
			room:setPlayerFlag(shensimayi, "LuaJilveWansha")
			room:acquireSkill(shensimayi, "wansha")
		else
			room:setPlayerFlag(shensimayi, "LuaJilveZhiheng")
			room:askForUseCard(shensimayi, "@zhiheng", "@jilve-zhiheng", -1, sgs.Card_MethodDiscard)
		end
	end
}
LuaJilveVS = sgs.CreateZeroCardViewAsSkill{--完杀和制衡
	name = "LuaJilve",
	enabled_at_play = function(self,player)
		return player:usedTimes("#LuaJilveCard") < 2 and player:getMark("@bear") > 0
	end,
	view_as = function()
		return LuaJilveCard:clone()
	end
}
LuaJilve = sgs.CreateTriggerSkill{
	name = "LuaJilve",
	events = {sgs.CardUsed, sgs.AskForRetrial, sgs.Damaged},--分别为集智、鬼才、放逐
	view_as_skill = LuaJilveVS,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getMark("@bear") > 0
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:setMark("JilveEvent",tonumber(event))
		if event == sgs.CardUsed then
			local jizhi = sgs.Sanguosha:getTriggerSkill("jizhi")
			local use = data:toCardUse()
			if jizhi and use.card and use.card:getTypeId() == sgs.Card_TypeTrick and player:askForSkillInvoke(self:objectName(), data) then
				room:notifySkillInvoked(player, self:objectName())
				player:loseMark("@bear")
				jizhi:trigger(event, room, player, data)
			end
		elseif event == sgs.AskForRetrial then
			local guicai = sgs.Sanguosha:getTriggerSkill("guicai")
			if guicai and not player:isKongcheng() and player:askForSkillInvoke(self:objectName(), data) then
				room:notifySkillInvoked(player, self:objectName())
				player:loseMark("@bear")
				guicai:trigger(event, room, player, data)
			end
		elseif event == sgs.Damaged then
			local fangzhu = sgs.Sanguosha:getTriggerSkill("fangzhu")
			if fangzhu and player:askForSkillInvoke(self:objectName(), data) then
				room:notifySkillInvoked(player, self:objectName())
				player:loseMark("@bear")
				fangzhu:trigger(event, room, player, data)
			end
		end
		player:setMark("JilveEvent", 0)
		return false
	end
}
LuaJilveClear = sgs.CreateTriggerSkill{
	name = "#LuaJilve-clear",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		room:detachSkillFromPlayer(player, "wansha", false, true)
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("LuaJilveWansha")
	end
}
--[[
	技能名：急救
	相关武将：标准·华佗
	描述：你的回合外，你可以将一张红色牌当【桃】使用。
	引用：LuaJijiu
	状态：1217验证通过
]]--
LuaJijiu = sgs.CreateViewAsSkill{
	name = "LuaJijiu",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isRed()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local peach = sgs.Sanguosha:cloneCard("peach", suit, point)
			peach:setSkillName(self:objectName())
			peach:addSubcard(id)
			return peach
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		local phase = player:getPhase()
		if phase == sgs.Player_NotActive then
			return string.find(pattern, "peach")
		end
		return false
	end
}
--[[
	技能名：急速
	相关武将：奥运·叶诗文
	描述：你可以跳过你此回合的判定阶段和摸牌阶段。若如此做，视为对一名其他角色使用一张【杀】。
	引用：LuaXJisu
	状态：1217验证通过
]]--
LuaXJisuCard = sgs.CreateSkillCard{
	name = "LuaXJisuCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return sgs.Self:canSlash(to_select, nil, false)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		local use = sgs.CardUseStruct()
		use.card = slash
		use.from = source
		for _,p in pairs(targets) do
			use.to:append(p)
		end
		room:useCard(use)
	end
}
LuaXJisuVS = sgs.CreateViewAsSkill{
	name = "LuaXJisu",
	n = 0,
	view_as = function(self, cards)
		return LuaXJisuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXJisu"
	end
}
LuaXJisu = sgs.CreateTriggerSkill{
	name = "LuaXJisu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	view_as_skill = LuaXJisuVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		local nextphase = change.to
		if nextphase == sgs.Player_Judge then
			if not player:isSkipped(sgs.Player_Judge) then
				if not player:isSkipped(sgs.Player_Draw) then
					if room:askForUseCard(player, "@@LuaXJisu", "@LuaXJisu") then
						player:skip(sgs.Player_Judge)
						player:skip(sgs.Player_Draw)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：急袭
	相关武将：山·邓艾
	描述：你可以将一张“田”当【顺手牵羊】使用。
	引用：LuaJixi
	状态：0405验证通过(需与技能“屯田”配合使用)
]]--
LuaJixi = sgs.CreateOneCardViewAsSkill{
	name = "LuaJixi", 
	filter_pattern = ".|.|.|field",
	expand_pile = "field",
	view_as = function(self, originalCard) 
		local snatch = sgs.Sanguosha:cloneCard("snatch", originalCard:getSuit(), originalCard:getNumber())
		snatch:addSubcard(originalCard:getId())
		snatch:setSkillName(self:objectName())
		return snatch
	end, 
	enabled_at_play = function(self, player)
		return not player:getPile("field"):isEmpty()
	end
}
--[[
	技能名：集智
	相关武将：标准·黄月英
	描述：每当你使用锦囊牌选择目标后，你可以展示牌堆顶的一张牌。若此牌为基本牌，你选择一项：1.将之置入弃牌堆；2.用一张手牌替换之。若此牌不为基本牌，你获得之。
	引用：LuaJizhi
	状态：1217验证通过
]]--
LuaJizhi = sgs.CreateTriggerSkill{
	name = "LuaJizhi" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if (use.card:getTypeId() == sgs.Card_TypeTrick) then
			if not (player:getMark("JilveEvent") > 0) then
				if not room:askForSkillInvoke(player, self:objectName()) then return false end
			end
			local ids = room:getNCards(1, false)
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = player
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
			room:moveCardsAtomic(move, true)
			local id = ids:first()
			local card = sgs.Sanguosha:getCard(id)
			if not card:isKindOf("BasicCard") then
				player:obtainCard(card)
			else
				local card_ex
				if not player:isKongcheng() then
					local card_data = sgs.QVariant()
					card_data:setValue(card)
					card_ex = room:askForCard(player, ".", "@jizhi-exchange:::" .. card:objectName(), card_data, sgs.Card_MethodNone)
				end
				if card_ex then
					local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), nil)
					local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE, player:objectName(), self:objectName(), nil)
					local move1 = sgs.CardsMoveStruct()
					move1.card_ids:append(card_ex:getEffectiveId())
					move1.from = player
					move1.to = nil
					move1.to_place = sgs.Player_DrawPile
					move1.reason = reason1
					local move2 = sgs.CardsMoveStruct()
					move2.card_ids = ids
					move2.from = player
					move2.to = player
					move2.to_place = sgs.Player_PlaceHand
					move2.reason = reason2
					local moves = sgs.CardsMoveList()
					moves:append(move1)
					moves:append(move2)
					room:moveCardsAtomic(moves, false)
				else
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
					room:throwCard(card, reason, nil)
				end
			end
		end
		return false
	end
}
--[[
	技能名：集智
	相关武将：怀旧-标准·黄月英-旧、1v1·黄月英1v1、SP·台版黄月英
	描述：每当你使用非延时类锦囊牌选择目标后，你可以摸一张牌。
	引用：LuaNosJizhi
	状态：0405验证通过
]]--
LuaNosJizhi = sgs.CreateTriggerSkill{
	name = "LuaNosJizhi" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isNDTrick() and room:askForSkillInvoke(player, self:objectName()) then
			player:drawCards(1, self:objectName())
		end
		return false
	end
}
--[[
	技能名：嫉恶（锁定技）
	相关武将：☆SP·张飞
	描述：你使用的红色【杀】造成的伤害+1。
	引用：LuaJie
	状态：1217验证通过
]]--
LuaJie = sgs.CreateTriggerSkill{
	name = "LuaJie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if card:isKindOf("Slash") and card:isRed() then
				local hurt = damage.damage
				damage.damage = hurt + 1
				data:setValue(damage)
			end
		end
		return false
	end
}
--[[
	技能名：奸雄
	相关武将：界限突破·曹操
	描述：每当你受到伤害后，你可以选择一项：获得对你造成伤害的牌，或摸一张牌。 
	引用：LuaJianxiong
	状态：0405验证通过
]]--
LuaJianxiong = sgs.CreateMasochismSkill{
	name = "LuaJianxiong" ,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local data = sgs.QVariant()
		data:setValue(damage)
		local choices = {"draw+cancel"}
		local card = damage.card
		if card then
			local ids = sgs.IntList()
			if card:isVirtualCard() then
				ids = card:getSubcards()
			else
				ids:append(card:getEffectiveId())
			end
			if ids:length() > 0 then
				local all_place_table = true
				for _, id in sgs.qlist(ids) do
					if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
						all_place_table = false
						break
					end
				end
				if all_place_table then
					table.insert(choices, "obtain")
				end
			end
		end
		local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)
		if choice ~= "cancel" then
			room:notifySkillInvoked(player, self:objectName())
			if choice == "obtain" then
				player:obtainCard(card)
			else
				player:drawCards(1, self:objectName())
			end
		end
	end
}
--[[
	技能名：奸雄
	相关武将：标准·曹操、铜雀台·曹操
	描述：每当你受到伤害后，你可以获得对你造成伤害的牌。 
	引用：LuaNosJianxiong
	状态：0405验证通过
]]--
LuaNosJianxiong = sgs.CreateMasochismSkill{
	name = "LuaNosJianxiong" ,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local card = damage.card
		if not card then return end
		local ids = sgs.IntList()
		if card:isVirtualCard() then
			ids = card:getSubcards()
		else
			ids:append(card:getEffectiveId())
		end
		if ids:isEmpty() then return end
		for _, id in sgs.qlist(ids) do
			if room:getCardPlace(id) ~= sgs.Player_PlaceTable then return end
		end
		local data = sgs.QVariant()
		data:setValue(damage)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			player:obtainCard(card)
		end
	end
}
--[[
	技能名：坚守
	相关武将：测试·蹲坑曹仁
	描述：回合结束阶段开始时，你可以摸五张牌，然后将你的武将牌翻面
	引用：LuaXJianshou
	状态：1217验证通过
]]--
LuaXJianshou = sgs.CreateTriggerSkill{
	name = "LuaXJianshou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			if player:askForSkillInvoke(self:objectName(), data) then
				player:drawCards(5, true, self:objectName())
				player:turnOver()
			end
		end
	end
}
--[[
	技能名：将驰
	相关武将：二将成名·曹彰
	描述：摸牌阶段，你可以选择一项：1、额外摸一张牌，若如此做，你不能使用或打出【杀】，直到回合结束。2、少摸一张牌，若如此做，出牌阶段你使用【杀】时无距离限制且你可以额外使用一张【杀】，直到回合结束。
	引用：LuaJiangchi、LuaJiangchiTargetMod
	状态：1217验证通过
]]--
LuaJiangchi = sgs.CreateTriggerSkill{
	name = "LuaJiangchi" ,
	events = {sgs.DrawNCards} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local choice = room:askForChoice(player, self:objectName(), "jiang+chi+cancel")
		if choice == "cancel" then return false end
		if choice == "jiang" then
			room:setPlayerCardLimitation(player, "use,response", "Slash", true)
			data:setValue(data:toInt() + 1)
			return false
		else
			room:setPlayerFlag(player, "LuaJiangchiInvoke")
			data:setValue(data:toInt() - 1)
			return false
		end
	end
}
LuaJiangchiTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaJiangchi-target" ,
	residue_func = function(self, from)
		if from:hasSkill("LuaJiangchi") and from:hasFlag("LuaJiangchiInvoke") then
			return 1
		else
			return 0
		end
	end ,
	distance_limit_func = function(self, from)
		if from:hasSkill("LuaJiangchi") and from:hasFlag("LuaJiangchiInvoke") then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：节命
	相关武将：火·荀彧
	描述：每当你受到1点伤害后，你可以令一名角色将手牌补至X张（X为该角色的体力上限且至多为5）。
	引用：LuaJieming
	状态：1217验证通过
]]--
LuaJieming = sgs.CreateTriggerSkill{
	name = "LuaJieming" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		for i = 0, damage.damage - 1, 1 do
			local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "jieming-invoke", true, true)
			if not to then break end
			local upper = math.min(5, to:getMaxHp())
			local x = upper - to:getHandcardNum()
			if x <= 0 then
			else
				to:drawCards(x)
			end
		end
	end
}
--[[
	技能名：结姻
	相关武将：界限突破·孙尚香、标准·孙尚香、SP·孙尚香
	描述：出牌阶段限一次，你可以弃置两张手牌并选择一名已受伤的男性角色，你和该角色各回复1点体力。
	引用：LuaJieyin
	状态：0405验证通过
]]--
LuaJieyinCard = sgs.CreateSkillCard{
	name = "LuaJieyinCard" ,
	filter = function(self, targets, to_select)
		if #targets ~= 0 then return false end
		return to_select:isMale() and to_select:isWounded() and to_select:objectName() ~= sgs.Self:objectName()
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = effect.from
		room:recover(effect.from, recover, true)
		room:recover(effect.to, recover, true)
	end
}
LuaJieyin = sgs.CreateViewAsSkill{
	name = "LuaJieyin" ,
	n = 2 ,
	view_filter = function(self, selected, to_select)
		if #selected > 1 or sgs.Self:isJilei(to_select) then return false end
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local jieyin_card = LuaJieyinCard:clone()
		for _,card in pairs(cards) do
			jieyin_card:addSubcard(card)
		end
		return jieyin_card
	end ,
	enabled_at_play = function(self, target)
		return target:getHandcardNum() >= 2 and not target:hasUsed("#LuaJieyinCard")
	end
}
--[[
	技能名：竭缘
	相关武将：铜雀台·灵雎、SP·灵雎
	描述：每当你对一名其他角色造成伤害时，若其体力值大于或等于你的体力值，你可以弃置一张黑色手牌：若如此做，此伤害+1。每当你受到一名其他角色造成的伤害时，若其体力值大于或等于你的体力值，你可以弃置一张红色手牌：若如此做，此伤害-1。 
	引用：LuaJieyuan
	状态：0405验证通过
]]--
LuaJieyuan = sgs.CreateTriggerSkill{
	name = "LuaJieyuan" ,
	events = {sgs.DamageCaused, sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			if damage.to and damage.to:isAlive() and damage.to:getHp() >= player:getHp() and damage.to:objectName() ~= player:objectName() and player:canDiscard(player, "h") and room:askForCard(player, ".black", "@jieyuan-increase:" .. damage.to:objectName(), data, self:objectName()) then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.DamageInflicted then
			if damage.from and damage.from:isAlive() and damage.from:getHp() >= player:getHp() and damage.from:objectName() ~= player:objectName() and player:canDiscard(player, "h") and room:askForCard(player, ".red", "@jieyuan-decrease:" .. damage.from:objectName(), data, self:objectName()) then
				damage.damage = damage.damage - 1
				data:setValue(damage)
				if damage.damage < 1 then return true end
			end
		end
		return false
	end
}
--[[
	技能名：解烦（限定技）
	相关武将：二将成名·韩当
	描述：出牌阶段，你可以指定一名角色，攻击范围内含有该角色的所有角色须依次选择一项：弃置一张武器牌；或令该角色摸一张牌。
	引用：LuaJiefan
	状态：1217验证通过
]]--
LuaJiefanCard = sgs.CreateSkillCard{
	name = "LuaJiefanCard" ,
	filter = function(self, targets, to_select)
		return #targets == 0
	end  ,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@rescue")
		local target = targets[1]
		local _targetdata = sgs.QVariant()
		_targetdata:setValue(target)
		source:setTag("LuaJiefanTarget", _targetdata)
		for _, player in sgs.qlist(room:getAllPlayers()) do
			if player:isAlive() and player:inMyAttackRange(target) then
				room:cardEffect(self, source, player)
			end
		end
		source:removeTag("LuaJiefanTarget")
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local target = effect.from:getTag("LuaJiefanTarget"):toPlayer()
		local data = effect.from:getTag("LuaJiefanTarget")
		if target then
			if not room:askForCard(effect.to, ".Weapon", "@jiefan-discard::" .. target:objectName(), data) then
				target:drawCards(1)
			end
		end
	end
}
LuaJiefanVS = sgs.CreateViewAsSkill{
	name = "LuaJiefan" ,
	n = 0,
	view_as = function()
		return LuaJiefanCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@rescue") >= 1
	end
}
LuaJiefan = sgs.CreateTriggerSkill{
	name = "LuaJiefan" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@rescue",
	events = {},
	view_as_skill = LuaJiefanVS ,

	on_trigger = function()
		return false
	end
}
--[[
	技能名：解烦
	相关武将：怀旧·韩当
	描述：你的回合外，当一名角色处于濒死状态时，你可以对当前正进行回合的角色使用一张【杀】（无距离限制），此【杀】造成伤害时，你防止此伤害，视为对该濒死角色使用一张【桃】。
	引用：LuaNosJiefan
	状态：1217验证通过
]]--
LuaNosJiefanCard = sgs.CreateSkillCard{
	name = "LuaNosJiefanCard",
	target_fixed = true,
	mute = true,
	on_use = function(self,room,handang,targets)
		local current = room:getCurrent()
		if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then return end
		local who = room:getCurrentDyingPlayer()
		if not who then return end
		handang:setFlags("NosJiefanUsed")
		local data = sgs.QVariant()
		data:setValue(who)
		room:setTag("NosJiefanTarget",data)
		local use_slash = room:askForUseSlashTo(handang,current,"nosjiefan-slash:"..current:objectName(),false)
		if not use_slash then
			handang:setFlags("-NosJiefanUsed")
			room:removeTag("NosJiefanTarget")
			room:setPlayerFlag(handang,"Global_NosJiefanFailed")
		end
	end
}
LuaNosJiefanvs = sgs.CreateViewAsSkill{
	name = "LuaNosJiefan",
	n = 0,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		if not string.find(pattern,"peach") then return false end
		if player:hasFlag("Global_NosJiefanFailed") then return false end
		for _,p in sgs.qlist(player:getAliveSiblings()) do
			if p:getPhase() ~=sgs.Player_NotActive then
				return true
			end
		end
		return false
	end,
	view_as = function(self,cards)
		return LuaNosJiefanCard:clone()
	end
}
LuaNosJiefan = sgs.CreateTriggerSkill{
	name = "LuaNosJiefan",
	events = {sgs.DamageCaused,sgs.CardFinished,sgs.PreCardUsed},
	view_as_skill = LuaNosJiefanvs,
	on_trigger = function(self,event,handang,data)
		local room = handang:getRoom()
		if event == sgs.PreCardUsed then
			if not handang:hasFlag("NosJiefanUsed") then return false end
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				handang:setFlags("-NosJiefanUsed")
				room:setCardFlag(use.card,"nosjiefan-slash")
			end
		elseif event == sgs.DamageCaused then
			local current = room:getCurrent()
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("nosjiefan-slash") then
				local log2 = sgs.LogMessage()
				log2.type = "#NosJiefanPrevent"
				log2.from = handang
				log2.to:append(damage.to)
				room:sendLog(log2)
				local target = room:getTag("NosJiefanTarget"):toPlayer()
				if target and target:getHp() > 0 then
					local log = sgs.LogMessage()
					log.type = "#NosJiefanNull1"
					log.from = target
					room:sendLog(log)
				elseif target and target:isDead() then
					local log = sgs.LogMessage()
					log.type = "#NosJiefanNull2"
					log.from = target					
					room:sendLog(log)
				elseif handang:hasFlag("Global_PreventPeach") then
					local log = sgs.LogMessage()
					log.type = "#NosJiefanNull3"
					log.from = current
					log.to:append(handang)
					room:sendLog(log)
				else
					local peach = sgs.Sanguosha:cloneCard("peach",sgs.Card_NoSuit,0)
					peach:setSkillName(self:objectName())
					room:setCardFlag(damage.card,"nosjiefan_success")
					room:useCard(sgs.CardUseStruct(peach,handang,target))
				end
				return true
			end
			return false
		elseif event == sgs.CardFinished and room:getTag("NosJiefanTarget"):toPlayer() then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:hasFlag("nosjiefan-slash") then
				if not use.card:hasFlag("nosjiefan_success") then
					room:setPlayerFlag(handang,"Global_NosJiefanFailed")
				end
				room:removeTag("NosJiefanTarget")
			end
		end
		return false
	end
}
--[[
	技能名：解惑（觉醒技）
	相关武将：智·司马徽
	描述：当你发动“授业”目标累计超过6个时，须减去一点体力上限，将技能“授业”改为每阶段限一次，并获得技能“师恩”
	引用：LuaJiehuo
	状态：1217验证通过

	注：智水镜的三个技能均有联系，为了方便起见统一使用本LUA版本的技能，并非原版
]]--
LuaJiehuo = sgs.CreateTriggerSkill{
	name = "LuaJiehuo" ,
	events = {sgs.CardFinished} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "LuaJiehuo", 1)
		player:loseAllMarks("@shouye")
		if room:changeMaxHpForAwakenSkill(player) then
			room:acquireSkill(player, "LuaShien")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getMark("LuaJiehuo") == 0) and (target:getMark("@shouye") >= 7)
	end
}
--[[
	技能名：解围
	相关武将：风·曹仁
	描述：每当你的武将牌翻面后，你可以摸一张牌，然后你可以使用一张锦囊牌或装备牌：若如此做，该牌结算后，你可以弃置场上一张同类型的牌。
	状态：1217验证通过
]]--
LuaJiewei = sgs.CreateTriggerSkill{
	name = "LuaJiewei",
	events = {sgs.TurnedOver} ,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not room:askForSkillInvoke(player, self:objectName()) then return false end
		player:drawCards(1)
		local card = room:askForUseCard(player, "TrickCard+^Nullification,EquipCard|.|.|hand", "@Luajiewei")
		if not card then return false end
		local targets = sgs.SPlayerList()
		if card:getTypeId() == sgs.Card_TypeTrick then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				local can_discard = false
				for _, judge in sgs.qlist(p:getJudgingArea()) do
					if (judge:getTypeId() == sgs.Card_TypeTrick) and (player:canDiscard(p, judge:getEffectiveId())) then
						can_discard = true
						break
					elseif judge:getTypeId() == sgs.Card_TypeSkill then
						local real_card = Sanguosha:getEngineCard(judge:getEffectiveId())
						if (real_card:getTypeId() == sgs.Card_TypeTrick) and (player:canDiscard(p, real_card:getEffectiveId())) then
							can_discard = true
							break
						end
					end
				end
				if can_discard then targets:append(p) end
			end
		elseif (card:getTypeId() == sgs.Card_TypeEquip) then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
						if (not p:getEquips():isEmpty()) and (player:canDiscard(p, "e")) then
							targets:append(p)
				else
					for _, judge in sgs.qlist(p:getJudgingArea()) do
									if judge:getTypeId() == sgs.Card_TypeSkill then
						local real_card = Sanguosha:getEngineCard(judge:getEffectiveId())
						 				if (real_card:getTypeId() == sgs.Card_TypeEquip) and (player:canDiscard(p, real_card:getEffectiveId())) then
												targets:append(p)
							   					break
							end
						end
					end
				end
			end
		end
		if targets:isEmpty() then return false end
		local to_discard = room:askForPlayerChosen(player, targets, self:objectName(), "@Luajiewei-discard", true)
		if to_discard then
			local disabled_ids = sgs.IntList()
			for _, c in sgs.qlist(to_discard:getCards("ej")) do
				local pcard = c 
				if (pcard:getTypeId() == sgs.Card_TypeSkill) then
					pcard = sgs.Sanguosha:getEngineCard(c:getEffectiveId())
				end
				if (pcard:getTypeId()~= card:getTypeId()) then
					disabled_ids:append(pcard:getEffectiveId())
				end
			end
			local id = room:askForCardChosen(player, to_discard, "ej", self:objectName(), false, sgs.Card_MethodDiscard, disabled_ids)
			room:throwCard(id, to_discard, player)
		end
		return false
	end	
}
--[[
	技能名：尽瘁
	相关武将：智·张昭
	描述：当你死亡时，可令一名角色摸取或者弃置三张牌
	引用：LuaXJincui
	状态：1217验证通过
]]--
LuaXJincui = sgs.CreateTriggerSkill{
	name = "LuaXJincui",
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local alives = room:getAlivePlayers()
		if player:objectName() == death.who:objectName() then
			if not alives:isEmpty() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local target = room:askForPlayerChosen(player, alives, self:objectName())
					local ai_data = sgs.QVariant()
					ai_data:setValue(target)
					local choice = room:askForChoice(player, self:objectName(), "draw+throw", ai_data)
					if choice == "draw" then
						target:drawCards(3)
					else
						local count = math.min(3, target:getCardCount(true))
						room:askForDiscard(target, self:objectName(), count, count, false, true)
					end
				end
			end
		end
		return
	end,
	can_trigger = function(self, target)
		 return target and target:hasSkill(self:objectName())
	end
}
--[[
	技能名：禁酒（锁定技）
	相关武将：一将成名·高顺
	描述：你的【酒】均视为【杀】。
	引用：LuaJinjiu
	状态：1217验证通过
]]--
LuaJinjiu = sgs.CreateFilterSkill{
	name = "LuaJinjiu" ,
	view_filter = function(self, card)
		return card:objectName() == "analeptic"
	end ,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(slash)
		return wrap
	end
}
--[[
	技能名：精策
	相关武将：一将成名2013·郭淮
	描述：出牌阶段结束时，若你本回合已使用的牌数大于或等于你当前的体力值，你可以摸两张牌。
	引用：LuaJingce
	状态：1217验证通过
]]--
LuaJingce = sgs.CreateTriggerSkill{
	name = "LuaJingce" ,
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseStart, sgs.EventPhaseEnd} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.PreCardUsed) or (event == sgs.CardResponded)) and (player:getPhase() <= sgs.Player_Play) then
			local card = nil
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and (card:getHandlingMethod() == sgs.Card_MethodUse) then
				player:addMark(self:objectName())
			end
		elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_RoundStart) then
			player:setMark(self:objectName(), 0)
		elseif event == sgs.EventPhaseEnd then
			if (player:getPhase() == sgs.Player_Play) and (player:getMark(self:objectName()) >= player:getHp()) then
				if room:askForSkillInvoke(player, self:objectName()) then
					player:drawCards(2)
				end
			end
		end
		return false
	end
}

--[[
	技能名：酒池
	相关武将：林·董卓
	描述：你可以将一张黑桃手牌当【酒】使用。
	引用：LuaJiuchi
	状态：1217验证通过
]]--
LuaJiuchi = sgs.CreateViewAsSkill{
	name = "LuaJiuchi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Spade)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local analeptic = sgs.Sanguosha:cloneCard("analeptic", cards[1]:getSuit(), cards[1]:getNumber())
			analeptic:setSkillName(self:objectName())
			analeptic:addSubcard(cards[1])
			return analeptic
		end
	end,
	enabled_at_play = function(self, player)
		local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then return false end
		return player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player , newanal)
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic")
	end
}
--[[
	技能名：酒诗
	相关武将：一将成名·曹植
	描述：若你的武将牌正面朝上，你可以将你的武将牌翻面，视为使用一张【酒】；若你的武将牌背面朝上时你受到伤害，你可以在伤害结算后将你的武将牌翻转至正面朝上。
	引用：LuaJiushi
	状态：1217验证通过
]]--
LuaJiushivs = sgs.CreateViewAsSkill{
	name = "LuaJiushi",
	n = 0,
	view_as = function(self, cards)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		analeptic:setSkillName(self:objectName())
		return analeptic
	end,
	enabled_at_play = function(self, player)
		return sgs.Analeptic_IsAvailable(player) and player:faceUp()
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic") and player:faceUp()
	end
}
LuaJiushi = sgs.CreateTriggerSkill{
	name = "LuaJiushi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PreCardUsed, sgs.PreDamageDone, sgs.DamageComplete},
	view_as_skill = LuaJiushivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card:getSkillName() == "LuaJiushi" then
				player:turnOver()
			end
		elseif event == sgs.PreDamageDone then
			room:setTag("PredamagedFace", sgs.QVariant(player:faceUp()))
		elseif event == sgs.DamageComplete then
			local faceup = room:getTag("PredamagedFace"):toBool()
			room:removeTag("PredamagedFace")
			if not (faceup or player:faceUp()) then
				if player:askForSkillInvoke("LuaJiushi", data) then
					player:turnOver()
				end
			end
		end
	end
}

--[[
	技能名：救援（主公技、锁定技）
	相关武将：标准·孙权、测试·制霸孙权
	描述：其他吴势力角色使用的【桃】指定你为目标后，回复的体力+1。
	引用：LuaJiuyuan
	状态：1217验证通过
]]--
LuaJiuyuan = sgs.CreateTriggerSkill{
	name = "LuaJiuyuan$",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.PreHpRecover},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Peach") and use.from and (use.from:getKingdom() == "wu")
					and (player:objectName() ~= use.from:objectName()) and player:hasFlag("Global_Dying") then
				room:setCardFlag(use.card, "LuaJiuyuan")
			end
		elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and rec.card:hasFlag("LuaJiuyuan") then
				rec.recover = rec.recover + 1
				data:setValue(rec)
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return target:hasLordSkill(self:objectName())
		end
		return false
	end
}
--[[
	技能名：救主
	相关武将：2013-3v3·赵云
	描述：每当一名其他己方角色处于濒死状态时，若你的体力值大于1，你可以失去1点体力并弃置一张牌，令该角色回复1点体力。
	引用：LuaJiuzhu
	状态：1217验证通过(2013-3v3模式)
]]--
LuaJiuzhuCard = sgs.CreateSkillCard{
	name = "LuaJiuzhuCard",
	target_fixed = true,
	on_use = function(self,room,player,targets)
		local who = room:getCurrentDyingPlayer()
		if not who then return end
		room:loseHp(player)
		local recover = sgs.RecoverStruct()
		recover.who = player
		room:recover(who,recover)
	end
}
LuaJiuzhuvs = sgs.CreateViewAsSkill{
	name = "LuaJiuzhu",
	n = 1,
	view_filter = function(self,selected,to_select)
		return #selected == 0 
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		if pattern ~= "peach" or not player:canDiscard(player,"he") or player:getHp() <= 1 then return false end
		local dyingobj = player:property("currentdying"):toString()
		local who = nil
		for _,p in sgs.qlist(player:getAliveSiblings()) do 
			if p:objectName() == dyingobj then
				who = p
				break
			end
		end
		if not who then return false end
		if player:getMark("_3v3mode") > 0 then
			return string.sub(player:getRole(),1,1) == string.sub(who:getRole(),1,1)
		else
			return true
		end
	end,
	view_as = function(self,cards)
		if #cards ~= 1 then return nil end
		local card = LuaJiuzhuCard:clone()
		card:addSubcard(cards[1])
		return card
	end
}
LuaJiuzhu = sgs.CreateTriggerSkill{
	name = "LuaJiuzhu",
	events = {sgs.GameStart},
	view_as_skill = LuaJiuzhuvs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getGameMode():startsWith("06_") then
			room:setPlayerMark(player,"_3v3mode",1)
		end
		return false
	end
}
--[[
	技能名：举荐
	相关武将：一将成名·徐庶
	描述：回合结束阶段开始时，你可以弃置一张非基本牌，令一名其他角色选择一项：摸两张牌，或回复1点体力，或将其武将牌翻至正面朝上并重置之。
	引用：LuaJujian
	状态：1217验证通过
]]--

LuaJujianCard = sgs.CreateSkillCard{
	name = "LuaJujianCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()

		local choiceList = {"draw"}
		if effect.to:isWounded() then
			table.insert(choiceList, "recover")
		end
		if (not effect.to:faceUp()) or effect.to:isChained() then
			table.insert(choiceList, "reset")
		end
		local choice = room:askForChoice(effect.to, "LuaJujian", table.concat(choiceList, "+"))
		if choice == "draw" then
			effect.to:drawCards(2)
		elseif choice == "recover" then
			local recover = sgs.RecoverStruct()
			recover.who = effect.from
			room:recover(effect.to, recover)
		elseif choice == "reset" then
			if effect.to:isChained() then
				room:setPlayerProperty(effect.to, "chained", sgs.QVariant(false))
			end
			if not effect.to:faceUp() then
				effect.to:turnOver()
			end
		end
	end
}
LuaJujianVS = sgs.CreateViewAsSkill{
	name = "LuaJujian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return (not to_select:isKindOf("BasicCard")) and (not sgs.Self:isJilei(to_select))
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local jujiancard = LuaJujianCard:clone()
			jujiancard:addSubcard(cards[1])
			return jujiancard
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaJujian"
	end
}
LuaJujian = sgs.CreateTriggerSkill{
	name = "LuaJujian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaJujianVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getPhase() == sgs.Player_Finish) and player:canDiscard(player, "he") then
			room:askForUseCard(player, "@@LuaJujian", "@jujian-card", -1, sgs.Card_MethodNone)
		end
		return false
	end
}
--[[
	技能名：举荐
	相关武将：怀旧·徐庶
	描述：出牌阶段，你可以弃置至多三张牌，然后令一名其他角色摸等量的牌。若你以此法弃置三张同一类别的牌，你回复1点体力。每阶段限一次。
	引用：LuaNosJujian
	状态：1217验证通过
]]--
LuaNosJujianCard = sgs.CreateSkillCard{
	name = "LuaNosJujianCard" ,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local n = self:subcardsLength()
		effect.to:drawCards(n)
		local room = effect.from:getRoom()
		if n == 3 then
			local thetype = nil
			for _, card_id in sgs.qlist(effect.card:getSubcards()) do
				if thetype == nil then
					thetype = sgs.Sanguosha:getCard(card_id):getTypeId()
				elseif sgs.Sanguosha:getCard(card_id):getTypeId() ~= thetype then
					return false
				end
			end
			local recover = sgs.RecoverStruct()
			recover.card = self
			recover.who = effect.from
			room:recover(effect.from, recover)
		end
	end
}
LuaNosJujian = sgs.CreateViewAsSkill{
	name = "LuaNosJujian" ,
	n = 3 ,
	view_filter = function(self, selected, to_select)
		return (#selected < 3) and (not sgs.Self:isJilei(to_select))
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = LuaNosJujianCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and (not player:hasUsed("#LuaNosJujianCard"))
	end
}
--[[
	技能名：巨象（锁定技）
	相关武将：林·祝融
	描述：【南蛮入侵】对你无效；当其他角色使用的【南蛮入侵】在结算后置入弃牌堆时，你获得之。
	引用：LuaSavageAssaultAvoid（与祸首一致，注意重复技能）、LuaJuxiang
	状态：1217验证通过
]]--
LuaSavageAssaultAvoid = sgs.CreateTriggerSkill{
	name = "#LuaSavageAssaultAvoid",
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			return true
		else
			return false
		end
	end
}
LuaJuxiang = sgs.CreateTriggerSkill{
	name = "LuaJuxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BeforeCardsMove,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				if use.card:isVirtualCard() and (use.card:subcardsLength() ~= 1) then return false end
				if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId())
						and sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):isKindOf("SavageAssault") then
					room:setCardFlag(use.card:getEffectiveId(), "real_SA")
				end
			end
		elseif player and player:isAlive() and player:hasSkill(self:objectName()) then
			local move = data:toMoveOneTime()
			if (move.card_ids:length() == 1) and move.from_places:contains(sgs.Player_PlaceTable) and (move.to_place == sgs.Player_DiscardPile)
					and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE) then
				local card = sgs.Sanguosha:getCard(move.card_ids:first())
				if card:hasFlag("real_SA") and (player:objectName() ~= move.from:objectName()) then
					player:obtainCard(card)
					move.card_ids = sgs.IntList()
					data:setValue(move)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：倨傲
	相关武将：智·许攸
	描述：出牌阶段，你可以选择两张手牌背面向上移出游戏，指定一名角色，被指定的角色到下个回合开始阶段时，跳过摸牌阶段，得到你所移出游戏的两张牌。每阶段限一次
	引用：LuaJuao
	状态：1217验证通过
]]--
LuaJuaoCard = sgs.CreateSkillCard{
	name = "LuaJuaoCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:getMark("LuaJuao") == 0)
	end ,
	on_effect = function(self, effect)
		effect.to:addToPile("hautain", self, false)
		effect.to:addMark("LuaJuao")
	end
}
LuaJuaoVS = sgs.CreateViewAsSkill{
	name = "LuaJuao" ,
	n = 2 ,
	view_filter = function(self, selected, to_select)
		if (#selected >= 2) then return false end
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local card = LuaJuaoCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaJuaoCard")
	end
}
LuaJuao = sgs.CreateTriggerSkill{
	name = "LuaJuao" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = LuaJuaoVS ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			player:setMark("LuaJuao", 0)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, card_id in sgs.qlist(player:getPile("hautain")) do
				dummy:addSubcard(card_id)
			end
			player:obtainCard(dummy, false)
			player:skip(sgs.Player_Draw)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getMark("LuaJuao") > 0)
	end
}
--[[
	技能名：据守
	相关武将：风·曹仁
	描述：结束阶段开始时，你可以摸一张牌，然后将你的武将牌翻面。
	引用：LuaJushou
	状态：1217验证通过
]]--
LuaJushou = sgs.CreatePhaseChangeSkill{
	name = "LuaJushou",

	on_phasechange = function(self,target)
		local room = target:getRoom()
		if target:getPhase() == sgs.Player_Finish then
		if room:askForSkillInvoke(target,self:objectName()) then
			target:drawCards(1)
			target:turnOver()
			end
		end
	end 
}
--[[
	技能名：据守·旧
	相关武将：怀旧·曹仁
	描述：结束阶段开始时，你可以摸三张牌，然后将你的武将牌翻面。
	引用：LuaJushou
	状态：1217验证通过
]]--
LuaNosJushou = sgs.CreatePhaseChangeSkill{
	name = "LuaNosJushou",

	on_phasechange = function(self,target)
		local room = target:getRoom()
		if target:getPhase() == sgs.Player_Finish then
		if room:askForSkillInvoke(target,self:objectName()) then
			target:drawCards(3)
			target:turnOver()
			end
		end
	end 
}
--[[
	技能名：据守
	相关武将：翼·曹仁
	描述：回合结束阶段开始时，你可以摸2+X张牌（X为你已损失的体力值），然后将你的武将牌翻面。
	引用：LuaXNeoJushou
	状态：1217验证通过
]]--
LuaXNeoJushou = sgs.CreateTriggerSkill{
	name = "LuaXNeoJushou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				local lost = player:getLostHp()
				player:drawCards(2 + lost)
				player:turnOver()
			end
		end
		return false
	end
}

--[[
	技能名：绝策
	相关武将：一将成名2013·李儒
	描述：你的回合内，一名体力值大于0的角色失去最后的手牌后，你可以对其造成1点伤害。
	引用：LuaJuece
	状态：1217验证通过
]]--
LuaJuece = sgs.CreateTriggerSkill{
	name = "LuaJuece" ,
	events = {sgs.CardsMoveOneTime},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if player:getPhase() ~= sgs.Player_NotActive and move.from and move.from_places:contains(sgs.Player_PlaceHand)and move.is_last_handcard then
		local from = room:findPlayer(move.from:getGeneralName())
		if from:getHp() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
			room:damage(sgs.DamageStruct(self:objectName(),player,from))
		end
	end
end
}
--[[
	技能名：绝汲
	相关武将：倚天·张儁乂
	描述：出牌阶段，你可以和一名角色拼点：若你赢，你获得对方的拼点牌，并可立即再次与其拼点，如此反复，直到你没赢或不愿意继续拼点为止。每阶段限一次。
	引用：LuaXJueji
	状态：1217验证通过
]]--
LuaXJuejiCard = sgs.CreateSkillCard{
	name = "LuaXJuejiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return not to_select:isKongcheng()
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local success = source:pindian(target, "LuaXJueji", self)
		local data = sgs.QVariant()
		data:setValue(target)
		while success do
			if target:isKongcheng() then
				break
			elseif source:isKongcheng() then
				break
			elseif source:askForSkillInvoke("LuaXJueji", data) then
				success = source:pindian(target, "LuaXJueji")
			else
				break
			end
		end
	end
}
LuaXJuejivs = sgs.CreateViewAsSkill{
	name = "LuaXJueji",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local juejiCard = LuaXJuejiCard:clone()
			juejiCard:addSubcard(cards[1])
			return juejiCard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaXJuejiCard")
	end
}
LuaXJueji = sgs.CreateTriggerSkill{
	name = "LuaXJueji",	
	events = {sgs.Pindian},
	view_as_skill = LuaXJuejivs,
	on_trigger = function(self, event, player, data)
		local pindian = data:toPindian()
		if pindian.reason == "LuaXJueji" then
			if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
				player:obtainCard(pindian.to_card)
			end
		end
		return false
	end,
	priority = -1
}
--[[
	技能名：绝境（锁定技）
	相关武将：神·赵云
	描述：摸牌阶段，你额外摸X张牌。你的手牌上限+2。（X为你已损失的体力值） 
	引用：LuaJuejing、LuaJuejingDraw
	状态：0405验证通过
]]--
LuaJuejing = sgs.CreateMaxCardsSkill{
	name = "LuaJuejing" ,
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return 2
		else
			return 0
		end
	end
}
LuaJuejingDraw = sgs.CreateDrawCardsSkill{
	name = "#LuaJuejing-draw" ,
	frequency = sgs.Skill_Compulsory ,
	draw_num_func = function(self, player, n)
		if player:isWounded() then
			player:getRoom():sendCompulsoryTriggerLog(player, "LuaJuejing")
		end
		return n + player:getLostHp()
	end
}
--[[
	技能名：绝境（锁定技）
	相关武将：测试·高达一号
	描述：摸牌阶段，你不摸牌。每当你的手牌数变化后，若你的手牌数不为4，你须将手牌补至或弃置至四张。
	引用：LuaXNosJuejing
	状态：1217验证通过
]]--
LuaXNosJuejing = sgs.CreateTriggerSkill{
	name = "LuaXNosJuejing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			local target = move.to
			if not source or source:objectName() ~= player:objectName() then
				if not target or target:objectName() ~= player:objectName() then
					return false
				end
			end
			if move.to_place ~= sgs.Player_PlaceHand then
				if not move.from_places:contains(sgs.Player_PlaceHand) then
					return false
				end
			end
			if player:getPhase() == sgs.Player_Discard then
				return false
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local nextphase = change.to
			if nextphase == sgs.Player_Draw then
				player:skip(nextphase)
				return false
			elseif nextphase ~= sgs.Player_Finish then
				return false
			end
		end
		local count = player:getHandcardNum()
		if count == 4 then
			return false
		elseif count < 4 then
			player:drawCards(4 - count)
		elseif count > 4 then
			local room = player:getRoom()
			room:askForDiscard(player, self:objectName(), count - 4, count - 4)
		end
		return false
	end
}
--[[
	技能名：绝情（锁定技）
	相关武将：一将成名·张春华、怀旧·张春华
	描述：你即将造成的伤害均视为失去体力。
	引用：LuaJueqing
	状态：1217验证通过
]]--
LuaJueqing = sgs.CreateTriggerSkill{
	name = "LuaJueqing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Predamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		room:loseHp(damage.to, damage.damage)
		return true
	end,
}
--[[
	技能名：军威
	相关武将：☆SP·甘宁
	描述：结束阶段开始时，你可以将三张“锦”置入弃牌堆并选择一名角色，令该角色选择一项：1.展示一张【闪】并将该【闪】交给由你选择的一名角色；2.失去1点体力，然后你将其装备区的一张牌移出游戏，该角色的下个回合结束后，将这张装备牌移回其装备区。
	引用：LuaJunwei,LuaJunweiGot
	状态：1217验证通过(需与技能“银铃”配合使用)
]]--
LuaJunwei = sgs.CreateTriggerSkill{
	name = "LuaJunwei",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, ganning, data)
		local room = ganning:getRoom()
		if ganning:getPhase() == sgs.Player_Finish and ganning:getPile("brocade"):length() >= 3 then
			local target = room:askForPlayerChosen(ganning,room:getAllPlayers(),self:objectName(),"junwei-invoke",true,true)
			if not target then return false end
			local brocade = ganning:getPile("brocade")
			local to_throw = sgs.IntList()
			for i = 0,2,1 do
				local card_id = 0
				room:fillAG(brocade,ganning)
				if brocade:length() == 3 - i then
					card_id = brocade:first()
				else
					card_id = room:askForAG(ganning,brocade,false,self:objectName())
				end
				room:clearAG(ganning)
				brocade:removeOne(card_id)
				to_throw:append(card_id)
			end
			local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			for _,id in sgs.qlist(to_throw) do
				slash:addSubcard(id)
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,"",self:objectName(),"")
			room:throwCard(slash,reason,nil)
			slash:deleteLater()
			local card = room:askForCard(target,"Jink","@junwei-show",data,sgs.Card_MethodNone)
			if card then
				room:showCard(target,card:getEffectiveId())
				local receiver = room:askForPlayerChosen(ganning,room:getAllPlayers(),"junweigive","@junwei-give")
				if receiver:objectName() ~= target:objectName() then
					receiver:obtainCard(card)
				end
			else
				room:loseHp(target,1)
				if not target:isAlive() then return false end
				if target:hasEquip() then
					local card_id = room:askForCardChosen(ganning,target,"e",self:objectName())
					target:addToPile("junwei_equip",card_id)
					if target:objectName() == ganning:objectName() then
						room:setPlayerMark(target,tostring(card_id),1)
					end
				end
			end
		end
		return false
	end
}
LuaJunweiGot = sgs.CreateTriggerSkill{
	name = "#LuaJunweiGot",
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target ~= nil
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive or player:getPile("junwei_equip"):length() == 0 then return false end
		for _,card_id in sgs.qlist(player:getPile("junwei_equip")) do
			if player:getMark(tostring(card_id)) > 0 then
				room:setPlayerMark(player,tostring(card_id),0)
				continue
			end
			local card = sgs.Sanguosha:getCard(card_id)
			local equip_index = -1
			local equip = card:getRealCard():toEquipCard()
			equip_index = equip:location()
			local exchangeMove = sgs.CardsMoveList()
			local move1 = sgs.CardsMoveStruct(card_id,player,sgs.Player_PlaceEquip,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,player:objectName()))
			exchangeMove:append(move1)
			if player:getEquip(equip_index) ~= nil then
				local move2 = sgs.CardsMoveStruct(player:getEquip(equip_index):getId(),nil,sgs.Player_DiscardPile,
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP,player:objectName()))
				exchangeMove:append(move2)
			end
			local log = sgs.LogMessage()
			log.type = "$JunweiGot"
			log.from = player
			log.card_str = tonumber(card_id)
			room:sendLog(log)
			room:moveCardsAtomic(exchangeMove,true)
		end
		return false
	end
}
--[[
	技能名：峻刑
	相关武将：一将成名2013·满宠
	描述：出牌阶段限一次，你可以弃置至少一张手牌并选择一名其他角色，该角色须弃置一张与你弃置的牌类型均不同的手牌，否则将其武将牌翻面并摸X张牌。（X为你弃置的牌的数量）
	引用：LuaJunxing
	状态：1217验证通过
]]--
LuaJunxingCard = sgs.CreateSkillCard{
	name = "LuaJunxing" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if not target:isAlive() then return end
		local type_name = {"BasicCard", "TrickCard", "EquipCard"}
		local types = {"BasicCard", "TrickCard", "EquipCard"}
		for _, id in sgs.qlist(self:getSubcards()) do
			local c = sgs.Sanguosha:getCard(id)
			table.removeOne(types,type_name[c:getTypeId()])
			if #types == 0 then break end
		end
		if (not target:canDiscard(target, "h")) or #types == 0 then
			target:turnOver()
			target:drawCards(self:getSubcards():length(), "LuaJunxing")
		elseif not room:askForCard(target, table.concat(types, ",") .. "|.|.|hand", "@junxing-discard") then
			target:turnOver()
			target:drawCards(self:getSubcards():length(), "LuaJunxing")
		end
	end
}
LuaJunxing = sgs.CreateViewAsSkill{
	name = "LuaJunxing" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = LuaJunxingCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "h") and (not player:hasUsed("#LuaJunxingCard"))
	end
}
