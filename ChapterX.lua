--[[
	代码速查手册（X区）
	技能索引：
		惜粮、吓尿、先登、陷嗣、陷阵、享乐、枭姬、枭姬、骁果、骁果、骁袭、孝德、挟缠、心战、新生、星舞、行殇、雄异、修罗、旋风、旋风、眩惑、眩惑、雪恨、血祭、血裔、恂恂、循规、迅猛、殉志
]]--
--[[
	技能名：惜粮
	相关武将：倚天·张公祺
	描述：你可将其他角色弃牌阶段弃置的红牌收为“米”或加入手牌
	引用：LuaXXiliang
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
	技能名：吓尿（锁定技）
	相关武将：胆创·夏侯杰
	描述：当其他角色造成一次伤害时，若你在其攻击范围内，你须弃置所有手牌，然后摸等同于该角色体力值张数的牌。
]]--
--[[
	技能名：先登
	相关武将：3D织梦·乐进
	描述：摸牌阶段，你可少摸一张牌，然后你无视一名其他角色的距离直到回合结束。
]]--
--[[
	技能名：陷嗣
	相关武将：一将成名2013·刘封
	描述：准备阶段开始时，你可以将一至两名角色的各一张牌置于你的武将牌上，称为“逆”。其他角色可以将两张“逆”置入弃牌堆，视为对你使用一张【杀】。
]]--
--[[
	技能名：陷阵
	相关武将：一将成名·高顺
	描述：出牌阶段限一次，你可以与一名其他角色拼点：若你赢，你获得以下技能：本回合，该角色的防具无效，你无视与该角色的距离，你对该角色使用【杀】无数量限制；若你没赢，你不能使用【杀】，直到回合结束。
	引用：LuaXianzhen、LuaXianzhenClear
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
	技能名：享乐（锁定技）
	相关武将：山·刘禅
	描述：当其他角色使用【杀】指定你为目标时，需弃置一张基本牌，否则此【杀】对你无效。
	引用：LuaXiangle
	状态：1227验证通过
]]--
LuaXiangle = sgs.CreateTriggerSkill{
	name = "LuaXiangle" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.SlashEffected, sgs.TargetConfirming} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				player:setMark("LuaXiangle", 0)
				local dataforai = sgs.QVariant()
				dataforai:setValue(player)
				if not player:getRoom():askForCard(use.from,".Basic","@xiangle-discard",dataforai) then
					player:addMark("LuaXiangle")
				end
			end
		else
			local effect= data:toSlashEffect()
			if player:getMark("LuaXiangle") > 0 then
				player:removeMark("LuaXiangle")
				return true
			end
		end
	end
}
--[[
	技能名：枭姬
	相关武将：标准·孙尚香、SP·孙尚香
	描述：当你失去装备区里的一张牌时，你可以摸两张牌。
	引用：LuaXiaoji
	状态：0610验证通过
]]--
LuaXiaoji = sgs.CreateTriggerSkill{
	name = "LuaXiaoji" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and (move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceEquip) then
			for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				if move.from_places:at(i) == sgs.Player_PlaceEquip then
					if room:askForSkillInvoke(player, self:objectName()) then
						player:drawCards(2)
					else
						break
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：枭姬
	相关武将：1v1·孙尚香1v1
	描述：每当你失去一张装备区的装备牌后，你可以选择一项：摸两张牌，或回复1点体力。
]]--
--[[
	技能名：骁果
	相关武将：SP·乐进
	描述： 其他角色的结束阶段开始时，你可以弃置一张基本牌，令该角色选择一项：弃置一张装备牌并令你摸一张牌，或受到你对其造成的1点伤害。
]]--
--[[
	技能名：骁果
	相关武将：3D织梦·乐进
	描述：出牌阶段，每当你使用非红桃【杀】被目标角色的【闪】抵消时，你可令该【闪】返回该角色手牌中，然后将此【杀】当一张延时类锦囊对该角色使用（黑色当【兵粮寸断】，方块当【乐不思蜀】）。
]]--
--[[
	技能名：骁袭
	相关武将：1v1·马超1v1
	描述：你登场时，你可以视为使用一张【杀】。
]]--
--[[
	技能名：孝德
	相关武将：SP·夏侯氏
	描述：每当一名其他角色死亡结算后，你可以拥有该角色武将牌上的一项技能（除主公技与觉醒技），且“孝德”无效，直到你的回合结束时。每当你失去“孝德”后，你失去以此法获得的技能。 
]]--
--[[
	技能名：挟缠（限定技）
	相关武将：1v1·许褚1v1
	描述：出牌阶段，你可以与对手拼点：若你赢，视为你对对手使用一张【决斗】；若你没赢，视为对手对你使用一张【决斗】。
]]--
--[[
	技能名：心战
	相关武将：一将成名·马谡
	描述：出牌阶段限一次，若你的手牌数大于你的体力上限，你可以观看牌堆顶的三张牌，展示并获得其中任意数量的♥牌，然后将其余的牌以任意顺序置于牌堆顶。
	引用：LuaXinzhan
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
	技能名：新生
	相关武将：山·左慈
	描述：每当你受到1点伤害后，你可以获得一张“化身牌”。
	引用：LuaXinSheng
	状态：验证通过
	备注：需调用ChapterH 的acquireGenerals 函数
]]--
LuaXinSheng = sgs.CreateTriggerSkill{
	name = "LuaXinSheng",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			acquireGenerals(player, data:toDamage().damage) --需調用ChapterH 的acquieGenerals 函数
		end
	end
}
--[[
	技能名：星舞
	相关武将：SP·大乔&小乔
	描述：弃牌阶段开始时，你可以将一张与你本回合使用的牌颜色均不同的手牌置于武将牌上。若你有三张“星舞牌”，你将其置入弃牌堆，然后选择一名男性角色，你对其造成2点伤害并弃置其装备区的所有牌。
]]--
--[[
	技能名：行殇
	相关武将：林·曹丕、铜雀台·曹丕
	描述：其他角色死亡时，你可以获得其所有牌。
	引用：LuaXingshang
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
	技能：雄异（限定技）
	相关武将：国战·马腾
	描述：出牌阶段，你可以令你与任意数量的角色摸三张牌：若以此法摸牌的角色数不大于全场角色数的一半，你回复1点体力。
	状态：尚未验证
]]--
--[[
	技能名：修罗
	相关武将：SP·暴怒战神
	描述：准备阶段开始时，你可以弃置一张与判定区内延时类锦囊牌花色相同的手牌，然后弃置该延时类锦囊牌。
	引用：LuaXiuluo
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
			local pattern = string.format(".|%s|.|.|.",suit_str)
			if room:askForCard(player, pattern, "@LuaXiuluoprompt", data, sgs.CardDiscarded) then
				room:throwCard(card, nil, player)
				once_success = true
			end
		until (not (player:getCards("j"):length() ~= 0 and once_success) )
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
	引用：LuaXuanfeng
	状态：0610验证通过
]]--

LuaXuanfengCard = sgs.CreateSkillCard{
	name = "LuaXuanfengCard" ,
	filter = function(self, targets, to_select)
		if #targets >= 2 then return false end
		if to_select:objectName() == sgs.Self:objectName() then return false end
		return sgs.Self:canDiscard(to_select, "he")
	end ,
	on_use = function(self, room, source, targets)
		local map = {}
		local totaltarget = 0
		for _, sp in ipairs(targets) do
			map[sp] = 1
		end
		totaltarget = #targets
		if totaltarget == 1 then
			for _, sp in ipairs(targets) do
				map[sp] = map[sp] + 1
			end
		end
		for _, sp in ipairs(targets) do
			while map[sp] > 0 do
				if source:isAlive() and sp:isAlive() and source:canDiscard(sp, "he") then
					local card_id = room:askForCardChosen(source, sp, "he", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(card_id, sp, source)
				end
				map[sp] = map[sp] - 1
			end
		end
	end
}
LuaXuanfengVS = sgs.CreateViewAsSkill{
	name = "LuaXuanfeng" ,
	n = 0 ,
	view_as = function()
		return LuaXuanfengCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, target, pattern)
		return pattern == "@@LuaXuanfeng"
	end
}
LuaXuanfeng = sgs.CreateTriggerSkill{
	name = "LuaXuanfeng" ,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart} ,
	view_as_skill = LuaXuanfengVS ,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			player:setMark("LuaXuanfeng", 0)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (not move.from) or (move.from:objectName() ~= player:objectName()) then return false end
			if (move.to_place == sgs.Player_DiscardPile) and (player:getPhase() == sgs.Player_Discard)
					and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				player:setMark("LuaXuanfeng", player:getMark("LuaXuanfeng") + move.card_ids:length())
			end
			if ((player:getMark("LuaXuanfeng") >= 2) and (not player:hasFlag("LuaXuanfengUsed")))
					or move.from_places:contains(sgs.Player_PlaceEquip) then
				local room = player:getRoom()
				local targets = sgs.SPlayerList()
				for _, target in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canDiscard(target, "he") then
						targets:append(target)
					end
				end
				if targets:isEmpty() then return false end
				local choice = room:askForChoice(player, self:objectName(), "throw+nothing") --这个地方令我非常无语…………用askForSkillInvoke不好么…………
				if choice == "throw" then
					--player:setFlags("LuaXuanfengUsed") --这是源码Bug的地方
					if player:getPhase() == sgs.Player_Discard then player:setFlags("LuaXuanfengUsed") end --修复源码Bug
					room:askForUseCard(player, "@@LuaXuanfeng", "@xuanfeng-card")
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
	引用：LuaNosXuanfeng
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
	引用：LuaXuanhuo、LuaXuanhuoFakeMove
	状态：0610验证通过
]]--

LuaXuanhuo = sgs.CreateTriggerSkill{
	name = "LuaXuanhuo" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "xuanhuo-invoke", true, true)
			if to then
				room:drawCards(to, 2)
				if (not player:isAlive()) or (not to:isAlive()) then return true end
				local targets = sgs.SPlayerList()
				for _, vic in sgs.qlist(room:getOtherPlayers(to)) do
					if to:canSlash(vic) then
						targets:append(vic)
					end
				end
				local victim
				if not targets:isEmpty() then
					victim = room:askForPlayerChosen(player, targets, "xuanhuo_slash", "@dummy-slash2:" .. to:objectName())
				end
				if victim then --不得已写了两遍movecard…………
					if not room:askForUseSlashTo(to, victim, "xuanhuo-slash:" .. player:objectName() .. ":" .. victim:objectName()) then
						if to:isNude() then return true end
						room:setPlayerFlag(to, "LuaXuanhuo_InTempMoving")
						local first_id = room:askForCardChosen(player, to, "he", self:objectName())
						local original_place = room:getCardPlace(first_id)
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:addSubcard(first_id)
						to:addToPile("#xuanhuo", dummy, false)
						if not to:isNude() then
							local second_id = room:askForCardChosen(player, to, "he", self:objectName())
							dummy:addSubcard(second_id)
						end
						room:moveCardTo(sgs.Sanguosha:getCard(first_id), to, original_place, false)
						room:setPlayerFlag(to, "-LuaXuanhuo_InTempMoving")
						room:moveCardTo(dummy, player, sgs.Player_PlaceHand, false)
						--delete dummy
					end
				else
					if to:isNude() then return true end
					room:setPlayerFlag(to, "LuaXuanhuo_InTempMoving")
					local first_id = room:askForCardChosen(player, to, "he", self:objectName())
					local original_place = room:getCardPlace(first_id)
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					dummy:addSubcard(first_id)
					to:addToPile("#xuanhuo", dummy, false)
					if not to:isNude() then
						local second_id = room:askForCardChosen(player, to, "he", self:objectName())
						dummy:addSubcard(second_id)
					end
					room:moveCardTo(sgs.Sanguosha:getCard(first_id), to, original_place, false)
					room:setPlayerFlag(to, "-LuaXuanhuo_InTempMoving")
					room:moveCardTo(dummy, player, sgs.Player_PlaceHand, false)
					--delete dummy
				end
				return true
			end
		end
		return false
	end
}
LuaXuanhuoFakeMove = sgs.CreateTriggerSkill{
	name = "#LuaXuanhuo-fake-move" ,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime} ,
	priority = 10 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("LuaXuanhuo_InTempMoving") then return true end
		end
		return false
	end
}
--[[
	技能名：眩惑
	相关武将：怀旧·法正
	描述：出牌阶段，你可以将一张红桃手牌交给一名其他角色，然后你获得该角色的一张牌并交给除该角色外的其他角色。每阶段限一次。
	引用：LuaNosXuanhuo
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
	技能名：雪恨（锁定技）
	相关武将：☆SP·夏侯惇
	描述：一名角色的结束阶段开始时，若你的体力牌处于竖置状态，你横置之，然后选择一项：1.弃置当前回合角色X张牌。 2.视为你使用一张无距离限制的【杀】。（X为你已损失的体力值）
	引用：LuaXuehen、LuaXuehenAvoidTriggeringCardsMove
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
	描述：出牌阶段限一次，你可以弃置一张红色牌并选择你攻击范围内的至多X名其他角色，对这些角色各造成1点伤害（X为你已损失的体力值），然后这些角色各摸一张牌。
	引用：LuaXueji
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
	引用：LuaXueyi
	状态：验证通过
]]--
LuaXueyi = sgs.CreateMaxCardsSkill{
	name = "LuaXueyi$",
	extra_func = function(self, target)
		local extra = 0
		local players = target:getSiblings()
		for _,player in sgs.qlist(players) do
			if player:isAlive() then
				if player:getKingdom() == "qun" then
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
	技能名：恂恂
	相关武将：势·李典
	描述：摸牌阶段开始时，你可以放弃摸牌并观看牌堆顶的四张牌，你获得其中的两张牌，然后将其余的牌以任意顺序置于牌堆底。
]]--
--[[
	技能名：循规
	相关武将：3D织梦·蒋琬
	描述：出牌阶段，你可以将一张非延时类锦囊置于你的武将牌上，称为“规”。若存在“规”，则弃掉代替之，且你回复1点体力。每阶段限用一次。
]]--
--[[
	技能名：迅猛（锁定技）
	相关武将：僵尸·僵尸
	描述：你的杀造成的伤害+1。你的杀造成伤害时若你体力大于1，你流失1点体力。
	引用：LuaXunmeng
	状态：验证通过
]]--
LuaXunmeng = sgs.CreateTriggerSkill{
	name = "LuaXunmeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			damage.damage = damage.damage + 1
			data:setValue(damage)
		if player:getHp() > 1 then
			room:loseHp(player)
		end
	end
end
}
--[[
	技能名：殉志
	相关武将：倚天·姜伯约
	描述：出牌阶段，你可以摸三张牌并变身为其他未上场或已阵亡的蜀势力角色，回合结束后你立即死亡
	引用：LuaXXunzhi
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
			if general:getKingdom() == "shu" then
				if not table.contains(general_names, name) then
					table.insert(shu_generals, name)
				end
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
