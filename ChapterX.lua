--[[
	代码速查手册（X区）
	技能索引：
		惜粮、享乐、枭姬、陷阵、新生、心战、行殇、修罗、旋风、旋风、眩惑、眩惑、雪恨、血祭、血裔、殉志
]]--
--[[
	技能名：惜粮
	相关武将：倚天·张公祺
	描述：你可将其他角色弃牌阶段弃置的红牌收为“米”或加入手牌 
	状态：验证通过
]]--
LuaXXiliang = sgs.CreateTriggerSkill{
	name = "LuaXXiliang",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardDiscarded},  
	on_trigger = function(self, event, player, data) 
		if player then
			if player:getPhase() == sgs.Player_Discard then
				local room = player:getRoom()
				local zhanglu = room:findPlayerBySkillName(self:objectName())
				if zhanglu then
					local card = data:toCard()
					local red_cards = {}
					local subs = card:getSubcards()
					for _,card_id in sgs.qlist(subs) do
						local c = sgs.Sanguosha:getCard(card_id)
						if c:isRed() then
							table.insert(red_cards, c)
						end
					end
					local count = #red_cards
					if count > 0 then
						if zhanglu:askForSkillInvoke(self:objectName(), data) then
							local rices = zhanglu:getPile("rice")
							local space = 5 - rices:length()
							local can_put = (space >= count)
							local choice = ""
							if can_put then
								choice = room:askForChoice(zhanglu, self:objectName(), "put+obtain")
							else
								choice = "obtain"
							end
							if choice == "put" then
								for _,cd in pairs(red_cards) do
									local id = cd:getEffectiveId()
									zhanglu:addToPile("rice", id)
								end
							else
								for _,cd in pairs(red_cards) do
									zhanglu:obtainCard(cd)
								end
							end
						end
					end
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
	技能名：享乐（锁定技）
	相关武将：山·刘禅
	描述：当其他角色使用【杀】指定你为目标时，需弃置一张基本牌，否则此【杀】对你无效。
	状态：验证通过
]]--
LuaXiangle = sgs.CreateTriggerSkill{
	name = "LuaXiangle", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.SlashEffected, sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			local slash = use.card
			if slash and slash:isKindOf("Slash") then
				local ai_data = sgs.QVariant()
				ai_data:setValue(player)
				if not room:askForCard(use.from, ".Basic", "@xiangle-discard", ai_data, sgs.CardDiscarded) then
					player:addMark("xiangle")
				end
			end
		else
			local count = player:getMark("xiangle")
			if count > 0 then
				player:setMark("xiangle", count - 1)
				return true
			end
		end
		return false
	end
}
--[[
	技能名：枭姬
	相关武将：标准·孙尚香、SP·孙尚香
	描述：当你失去装备区里的一张牌时，你可以摸两张牌。
	状态：验证通过
]]--
LuaXiaoji = sgs.CreateTriggerSkill{
	name = "LuaXiaoji", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardsMoveOneTime}, 
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		local places = move.from_places
		local source = move.from
		if source and source:objectName() == player:objectName() then
			if places:contains(sgs.Player_PlaceEquip) then
				local n = 0
				for _,place in sgs.qlist(places) do
					if place == sgs.Player_PlaceEquip then
						n = n + 1
					end
				end
				local room = player:getRoom()
				for i = 1, n, 1 do
					if room:askForSkillInvoke(player, self:objectName()) then
						player:drawCards(2)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：陷阵
	相关武将：一将成名·高顺
	描述：出牌阶段，你可以与一名其他角色拼点。若你赢，你获得以下技能直到回合结束：你无视与该角色的距离及其防具；你对该角色使用【杀】时无次数限制。若你没赢，你不能使用【杀】，直到回合结束。每阶段限一次。
	状态：验证通过
]]--
LuaXianzhenCard = sgs.CreateSkillCard{
	name = "LuaXianzhenCard", 
	target_fixed = false, 
	will_throw = false, 
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
		local dest = effect.to
		local room = source:getRoom()
		local card_ids = self:getSubcards()
		local card = sgs.Sanguosha:getCard(card_ids:first())
		if source:pindian(dest, self:objectName(), card) then
			local target = dest
			local tag = sgs.QVariant()
			tag:setValue(target)
			room:setTag("XianzhenTarget", tag)
			room:setPlayerFlag(source, "xianzhen_success")
			room:setFixedDistance(source, dest, 1)
			room:setPlayerFlag(dest, "wuqian")
		else
			room:setPlayerFlag(source, "xianzhen_failed")
		end
	end
}
LuaXianzhenSlashCard = sgs.CreateSkillCard{
	name = "LuaXianzhenSlashCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets)
		local tag = room:getTag("XianzhenTarget")
		local target = tag:toPlayer()
		if target and not target:isDead() then
			if source:canSlash(target, nil, false) then
				room:askForUseSlashTo(source, target, "@xianzhen-slash")
			end
		end
	end
}
LuaXianzhen = sgs.CreateViewAsSkill{
	name = "LuaXianzhen", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			if not sgs.Self:hasUsed("#LuaXianzhenCard") then
				return not to_select:isEquipped()
			end
		end
		return false
	end, 
	view_as = function(self, cards)
		if not sgs.Self:hasUsed("#LuaXianzhenCard") then
			if #cards == 1 then
				local card = LuaXianzhenCard:clone()
				card:addSubcard(cards[1])
				return card
			end
		elseif sgs.Self:hasFlag("xianzhen_success") then
			if #cards == 0 then
				return LuaXianzhenSlashCard:clone()
			end
		end
	end, 
	enabled_at_play = function(self, player)
		if not player:hasUsed("#LuaXianzhenCard") then
			return true
		elseif player:hasFlag("xianzhen_success") then
			return true
		end
		return false
	end
}
LuaXianzhenClear = sgs.CreateTriggerSkill{
	name = "#LuaXianzhenClear",
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart, sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local tag = room:getTag("XianzhenTarget")
		local target = tag:toPlayer()
		if event == sgs.Death or event == sgs.EventPhaseStart then
			if event == sgs.Death or player:getPhase() == sgs.Player_Finish then
				if target then
					local room = player:getRoom()
					room:setFixedDistance(player, target, -1)
					room:removeTag("XianzhenTarget")
					room:setPlayerFlag(target, "-wuqian")
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasSkill("LuaXianzhen")
		end
		return false
	end
}
--[[
	技能名：新生
	相关武将：山·左慈
	描述：每当你受到1点伤害后，你可以获得一张“化身牌”。
]]--
--[[
	技能名：心战
	相关武将：一将成名·马谡
	描述：出牌阶段，若你的手牌数大于你的体力上限，你可以：观看牌堆顶的三张牌，然后亮出其中任意数量的红桃牌并获得之，其余以任意顺序置于牌堆顶。每阶段限一次。
	状态：验证通过
]]--
LuaXinzhanCard = sgs.CreateSkillCard{
	name = "LuaXinzhanCard", 
	target_fixed = true,
	will_throw = true, 
	on_use = function(self, room, source, targets)
		local cards = room:getNCards(3)
		local left = cards
		local hearts = sgs.IntList()
		for _,card_id in sgs.qlist(cards) do
			local card = sgs.Sanguosha:getCard(card_id)
			if card:getSuit() == sgs.Card_Heart then
				hearts:append(card_id)
			end
		end
		if hearts:length() > 0 then
			room:fillAG(cards, source)
			while hearts:length() > 0 do
				local card_id = room:askForAG(source, hearts, true, self:objectName())
				if card_id == -1 then
					break
				end
				if hearts:contains(card_id) then
					hearts:removeOne(card_id)
					left:removeOne(card_id)
					local card = sgs.Sanguosha:getCard(card_id)
					source:obtainCard(card)
				end
			end
			source:invoke("clearAG")
		end
		if left:length() > 0 then
			room:askForGuanxing(source, left, true)
		end
	end
}
LuaXinzhan = sgs.CreateViewAsSkill{
	name = "LuaXinzhan", 
	n = 0, 
	view_as = function(self, cards)
		return LuaXinzhanCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if not player:hasUsed("#LuaXinzhanCard") then
			return player:getHandcardNum() > player:getMaxHp()
		end
		return false
	end
}
--[[
	技能名：行殇
	相关武将：林·曹丕、铜雀台·曹丕
	描述：其他角色死亡时，你可以获得其所有牌。
	状态：验证通过
]]--
LuaXingshangDummyCard = sgs.CreateSkillCard{
	name = "LuaXingshangDummyCard"
}
LuaXingshang = sgs.CreateTriggerSkill{
	name = "LuaXingshang",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Death}, 
	on_trigger = function(self, event, player, data)
		if not player:isNude() then
			local room = player:getRoom()
			local alives = room:getAlivePlayers()
			for _,caopi in sgs.qlist(alives) do
				if caopi:isAlive() and caopi:hasSkill(self:objectName()) then
					if room:askForSkillInvoke(caopi, self:objectName(), data) then
						local cards = player:getCards("he")
						if cards:length() > 0 then
							local allcard = LuaXingshangDummyCard:clone()
							for _,card in sgs.qlist(cards) do
								allcard:addSubcard(card)
							end
							room:obtainCard(caopi, allcard)
						end
						break
					end
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
	技能名：修罗
	相关武将：SP·暴怒战神
	描述：回合开始阶段开始时，你可以弃置一张手牌，若如此做，你弃置你判定区里的一张与你弃置手牌同花色的延时类锦囊牌。
	状态：1111验证通过，和cpp版效果一致
]]--
LuaXiuluo = sgs.CreateTriggerSkill{
	name = "LuaXiuluo",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local once_success = false
		repeat
			once_success = false
			if not player:askForSkillInvoke(self:objectName()) then return false end
			local card_id = room:askForCardChosen(player, player, "j", self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			local suit_str = card:getSuitString()
			local pattern=string.format(".|%s|.|.|.",suit_str)
			if room:askForCard(player, pattern, "@LuaXiuluoprompt", data, sgs.CardDiscarded) then
				room:throwCard(card,nil,player)
				once_success = true
			end
		until(not(player:getCards("j"):length() ~= 0 and once_success))
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start then
					if not target:isKongcheng() then
						local ja = target:getJudgingArea()
						return ja:length() > 0
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：旋风
	相关武将：一将成名·凌统
	描述：当你失去装备区里的牌时，或于弃牌阶段内弃置了两张或更多的手牌后，你可以依次弃置一至两名其他角色的共计两张牌。
	状态：验证通过
]]--
LuaXuanfengCard = sgs.CreateSkillCard{
	name = "LuaXuanfengCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets < 2 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				return not to_select:isNude()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local map = {}
		local totaltarget = 0
		for _,sp in pairs(targets) do
			map[sp:objectName()] = 1
		end
		totaltarget = #targets
		if totaltarget == 1 then
			for _,sp in pairs(targets) do
				map[sp:objectName()] = map[sp:objectName()] + 1
			end
		end
		for _,sp in pairs(targets) do
			while (map[sp:objectName()] > 0) do
				if not sp:isNude() then
					local card_id = room:askForCardChosen(source, sp, "he", "LuaXuanfeng")
					room:throwCard(card_id, sp, source)
				end
				map[sp:objectName()] = map[sp:objectName()] - 1
			end
		end
	end
}
LuaXuanfengVS = sgs.CreateViewAsSkill{
	name = "LuaXuanfengVS", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXuanfengCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXuanfeng"
	end
}
LuaXuanfeng = sgs.CreateTriggerSkill{
	name = "LuaXuanfeng",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart}, 
	view_as_skill = LuaXuanfengVS, 
	on_trigger = function(self, event, player, data) 
		if event == sgs.EventPhaseStart then
			player:setMark("xuanfeng", 0)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				local room = player:getRoom()
				local markcount = player:getMark("xuanfeng")
				if move.to_place == sgs.Player_DiscardPile then
					if player:getPhase() == sgs.Player_Discard then
						room:setPlayerMark(player, "xuanfeng", markcount + move.card_ids:length())
					end
				end
				markcount = player:getMark("xuanfeng")
				local flag = false
				if markcount >= 2 then
					flag = not player:hasFlag("xuanfeng_used")
				end
				if move.from_places:contains(sgs.Player_PlaceEquip) then
					flag = true
				end
				if flag then
					if markcount >= 2 then
						room:setPlayerFlag(player, "xuanfeng_used")
					end
					local can_invoke = false
					local other_players = room:getOtherPlayers(player)
					for _,p in sgs.qlist(other_players) do
						if not p:isNude() then
							can_invoke = true
							break
						end
					end
					if can_invoke then
						local choice = room:askForChoice(player, self:objectName(), "throw+nothing")
						if choice == "throw" then
							room:askForUseCard(player, "@@LuaXuanfeng", "@xuanfeng-card")
						end
					end
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
	状态：验证通过
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
	状态：验证通过
]]--
LuaXuanhuoDummyCard = sgs.CreateSkillCard{
	name = "LuaXuanhuoDummyCard",
}
LuaXuanhuoCard = sgs.CreateSkillCard{
	name = "LuaXuanhuoCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local dest = effect.to
		local room = source:getRoom()
		room:drawCards(dest, 2)
		if source:isAlive() and dest:isAlive() then
			local can_use = false
			local list = room:getOtherPlayers(dest)
			for _,p in sgs.qlist(list) do
				if dest:canSlash(p) then
					can_use = true
					break
				end
			end
			local victim = nil
			if can_use then
				local targets = sgs.SPlayerList()
				for _,v in sgs.qlist(list) do
					if dest:canSlash(v) then
						targets:append(v)
					end
				end
				victim = room:askForPlayerChosen(source, targets, self:objectName())
				local prompt = string.format("xuanhuo-slash:%s:%s", source:objectName(), victim:objectName())
				if not room:askForUseSlashTo(dest, victim, prompt) then
					if not dest:isNude() then
						local first_id = room:askForCardChosen(source, dest, "he", self:objectName())
						local dummy = LuaXuanhuoDummyCard:clone()
						dummy:addSubcard(first_id)
						dest:addToPile("#xuanhuo", dummy, false)
						if not dest:isNude() then
							local second_id = room:askForCardChosen(source, dest, "he", self:objectName())
							dummy:addSubcard(second_id)
						end
						room:moveCardTo(dummy, source, sgs.Player_PlaceHand, false)
					end
				end
			else
				if not dest:isNude() then
					local first_id = room:askForCardChosen(source, dest, "he", self:objectName())
					local dummy = LuaXuanhuoDummyCard:clone()
					dummy:addSubcard(first_id)
					dest:addToPile("#xuanhuo", dummy, false)
					if not dest:isNude() then
						local second_id = room:askForCardChosen(source, dest, "he", self:objectName())
						dummy:addSubcard(second_id)
					end
					room:moveCardTo(dummy, source, sgs.Player_PlaceHand, false)
				end
			end
		end
	end
}
LuaXuanhuoVS = sgs.CreateViewAsSkill{
	name = "LuaXuanhuoVS", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXuanhuoCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXuanhuo"
	end
}
LuaXuanhuo = sgs.CreateTriggerSkill{
	name = "LuaXuanhuo", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = LuaXuanhuoVS, 
	on_trigger = function(self, event, player, data) --必须
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if room:askForUseCard(player, "@@LuaXuanhuo", "@xuanhuo-card") then
				return true
			end
		end
		return false
	end
}
--[[
	技能名：眩惑
	相关武将：怀旧·法正
	描述：出牌阶段，你可以将一张红桃手牌交给一名其他角色，然后你获得该角色的一张牌并交给除该角色外的其他角色。每阶段限一次。
	状态：验证通过
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
	技能名：雪恨
	相关武将：☆SP·夏侯惇
	描述：每个角色的回合结束阶段开始时，若你的体力牌为竖置状态，你须横置之，然后选择一项：1.弃置当前回合角色X张牌（X为你已损失的体力值）；2.视为对一名任意角色使用一张【杀】。
	状态：验证通过
]]--
LuaXuehenDummyCard = sgs.CreateSkillCard{
	name = "LuaXuehenDummyCard"
}
LuaXuehen = sgs.CreateTriggerSkill{
	name = "LuaXuehen", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local xiahou = room:findPlayerBySkillName(self:objectName())
		if xiahou then
			if player:getPhase() == sgs.Player_Finish then
				if xiahou:getMark("@fenyong") > 0 then
					xiahou:loseMark("@fenyong")
					local targets = sgs.SPlayerList()
					local list = room:getOtherPlayers(xiahou)
					for _,p in sgs.qlist(list) do
						if xiahou:canSlash(p, nil, false) then
							targets:append(p)
						end
					end
					targets:append(xiahou)
					local choice
					if targets:length() == 0 then
						choice = "discard"
					else
						choice = room:askForChoice(xiahou, self:objectName(), "discard+slash")
					end
					if choice == "slash" then
						local victim = room:askForPlayerChosen(xiahou, targets, self:objectName())
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName(self:objectName())
						local card_use = sgs.CardUseStruct()
						card_use.from = xiahou
						card_use.to:append(victim)
						card_use.card = slash
						room:useCard(card_use, false)
					else
						room:setPlayerFlag(player, "XuehenTarget_InTempMoving")
						local dummy = LuaXuehenDummyCard:clone()
						local card_ids = {}
						local original_places = {}
						local losthp = xiahou:getLostHp()
						local count = 0
						for i=1, losthp, 1 do
							if not player:isNude() then
								local id = room:askForCardChosen(xiahou, player, "he", self:objectName())
								table.insert(card_ids, id)
								local place = room:getCardPlace(id)
								table.insert(original_places, place)
								dummy:addSubcard(id)
								player:addToPile("#xuehen", id, false)
								count = count + 1
							end
						end
						for i=1, count, 1 do
							local card = sgs.Sanguosha:getCard(card_ids[i])
							room:moveCardTo(card, player, original_places[i], false)
						end
						room:setPlayerFlag(player, "-XuehenTarget_InTempMoving")
						if count > 0 then
							room:throwCard(dummy, player, xiahou)
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
LuaXuehenAvoidTriggeringCardsMove = sgs.CreateTriggerSkill{
	name = "#LuaXuehenAvoidTriggeringCardsMove", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local targets = room:getAllPlayers()
		for _,p in sgs.qlist(targets) do
			if p:hasFlag("XuehenTarget_InTempMoving") then
				return true
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end, 
	priority = 10
}
--[[
	技能名：血祭
	相关武将：SP·关银屏
	描述：出牌阶段，你可以弃置一张红色牌，对你攻击范围内的至多X名其他角色各造成1点伤害，然后这些角色各摸一张牌。X为你损失的体力值。每阶段限一次。 
	状态：验证通过
]]--
LuaXuejiCard = sgs.CreateSkillCard{
	name = "LuaXuejiCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets < sgs.Self:getLostHp() then
			if to_select:objectName() ~= sgs.Self:objectName() then
				local weapon = sgs.Self:getWeapon()
				if weapon and weapon:getEffectiveId() == self:getEffectiveId() then
					return sgs.Self:distanceTo(to_select) == 1
				else
					local horse = sgs.Self:getOffensiveHorse()
					if horse and horse:getEffectiveId() == self:getEffectiveId() then
						return sgs.Self:distanceTo(to_select, 1) <= sgs.Self:getAttackRange()
					else
						return sgs.Self:distanceTo(to_select) <= sgs.Self:getAttackRange()
					end
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local damage = sgs.DamageStruct()
		damage.from = source
		for _,p in pairs(targets) do
			damage.to = p
			room:damage(damage)
		end
		for _,p in pairs(targets) do
			if p:isAlive() then
				p:drawCards(1)
			end
		end
	end
}
LuaXueji = sgs.CreateViewAsSkill{
	name = "LuaXueji", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:isRed()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local first = LuaXuejiCard:clone()
			first:addSubcard(cards[1]:getId())
			first:setSkillName(self:objectName())
			return first
		end
	end, 
	enabled_at_play = function(self, player)
		if player:getLostHp() > 0 then
			return not player:hasUsed("#LuaXuejiCard")
		end
		return false
	end
}
--[[
	技能名：血裔（主公技、锁定技）
	相关武将：火·袁绍
	描述：每有一名其他群雄角色存活，你的手牌上限便+2。
	状态：验证通过
]]--
LuaXueyi = sgs.CreateMaxCardsSkill{
	name = "LuaXueyi$",
	extra_func = function(self, target)
		local extra = 0
		local players = target:getSiblings()
		for _,player in sgs.qlist(players) do
			if player:isAlive() then
				if player:getKingdom() == "qun" th
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
	技能名：殉志
	相关武将：倚天·姜伯约
	描述：出牌阶段，你可以摸三张牌并变身为其他未上场或已阵亡的蜀势力角色，回合结束后你立即死亡 
	状态：0224验证通过
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
			if general:getKingdom() == "shu" and not table.contains(general_names, name) then
				table.insert(shu_generals, name)
			end
		end
		local general = room:askForGeneral(source, table.concat(shu_generals, "+"))
		source:setTag("newgeneral", sgs.QVariant(general))
		local isSecondaryHero = source:getGeneralName() ~= "jiangboyue"
		room:changeHero(source, general, false, false, isSecondaryHero, true)
		
		room:setPlayerFlag(source, "LuaXXunzhi")
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
				room:changeHero(player, "jiangboyue", false, false, isSecondaryHero, true)
				room:killPlayer(player)
			end
		end
		return false
	end
}