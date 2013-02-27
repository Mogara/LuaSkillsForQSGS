--[[
	代码速查手册（Y区）
	技能索引：
		言笑、严整、业炎、庸肆、遗计、倚天、异才、义从、义从、义舍、义释、毅重、银铃、英魂、英姿、狱刎、援护
]]--
--[[
	技能名：言笑
	相关武将：☆SP·大乔
	描述：出牌阶段，你可以将一张方块牌置于一名角色的判定区内，判定区内有“言笑”牌的角色下个判定阶段开始时，获得其判定区里的所有牌。
]]--
--[[
	技能名：严整
	相关武将：☆SP·曹仁
	描述：若你的手牌数大于你的体力值，你可以将你装备区内的牌当【无懈可击】使用。
	状态：验证通过
]]--
LuaYanzheng = sgs.CreateViewAsSkill{
	name = "LuaYanzheng", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then 
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local ncard = sgs.Sanguosha:cloneCard("nullification", suit, point)
			ncard:addSubcard(card)
			ncard:setSkillName(self:objectName())
			return ncard
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		if player:getHandcardNum() > player:getHp() then
			return pattern == "nullification"
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		local cards = player:getHandcards()
		for _,card in sgs.qlist(cards) do
			if card:objectName() == "nullification" then
				return true
			end
		end
		if player:getHandcardNum() > player:getHp() then
			local equips = player:getEquips()
			return not equips:isEmpty()
		end
		return false
	end
}
--[[
	技能名：业炎（限定技）
	相关武将：神·周瑜
	描述：出牌阶段，你可以选择一至三名角色，你分别对他们造成最多共3点火焰伤害（你可以任意分配），若你将对一名角色分配2点或更多的火焰伤害，你须先弃置四张不同花色的手牌并失去3点体力。
]]--
--[[
	技能名：庸肆（锁定技）
	相关武将：SP·袁术
	描述：摸牌阶段，你额外摸等同于现存势力数的牌；弃牌阶段开始时，你须弃置等同于现存势力数的牌。
	状态：验证通过
]]--
YongsiGetKingdoms = function(targets)
	local kingdoms = {}
	for _,target in sgs.qlist(targets) do
		local flag = true
		local kingdom = target:getKingdom()
		for _,k in pairs(kingdoms) do
			if k == kingdom then
				flag = false
				break
			end
		end
		if flag then
			table.insert(kingdoms, kingdom)
		end
	end
	return kingdoms
end
LuaYongsiDummyCard = sgs.CreateSkillCard{
	name = "LuaYongsiDummyCard",
}
LuaYongsi = sgs.CreateTriggerSkill{
	name = "LuaYongsi", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DrawNCards, sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local players = room:getAlivePlayers()
		if event == sgs.DrawNCards then
			local kingdoms = YongsiGetKingdoms(players)
			local count = data:toInt() + #kingdoms
			data:setValue(count)
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then
			local kingdoms = YongsiGetKingdoms(players)
			local x = #kingdoms
			local total = 0
			local jilei_cards = {}
			local handcards = player:getHandcards()
			for _,card in sgs.qlist(handcards) do
				if player:isJilei(card) then
					table.insert(jilei_cards, card)
				end
			end
			total = handcards:length() - #jilei_cards + player:getEquips():length()
			if x >= total then
				if player:hasFlag("jilei") then
					local dummy_card = LuaYongsiDummyCard:clone()
					for _,card in pairs(jilei_cards) do
						if handcards:contains(card) then
							handcards:removeOne(card)
						end
					end
					local count = 0
					for _,card in sgs.qlist(handcards) do
						dummy_card:addSubcard(card)
						count = count + 1
					end
					local equips = player:getEquips()
					for _,equip in sgs.qlist(equips) do
						dummy_card:addSubcard(equip)
						count = count + 1
					end
					if count > 0 then
						room:throwCard(dummy_card, player)
					end
					room:showAllCards(player)
				else
					player:throwAllHandCardsAndEquips()
				end
			else
				room:askForDiscard(player, "yongsi", x, x, false, true)
			end
		end
		return false
	end
}
--[[
	技能名：遗计
	相关武将：标准·郭嘉
	描述：每当你受到1点伤害后，你可以观看牌堆顶的两张牌，将其中一张交给一名角色，然后将另一张交给一名角色。
	状态：验证通过
]]--
LuaYiji = sgs.CreateTriggerSkill{
	name = "LuaYiji", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Damaged},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			local damage = data:toDamage()
			local x = damage.damage
			for i = 0, x-1, 1 do
				local move = sgs.CardsMoveStruct()
				local cardA = room:drawCard()
				move.card_ids:append(cardA)
				local cardB = room:drawCard()
				move.card_ids:append(cardB)
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, player:objectName(), self:objectName(), nil)
				room:moveCards(move, false)
				if not move.card_ids:isEmpty() then
					local flag = true
					while flag do
						flag = room:askForYiji(player, move.card_ids)
					end
				end
			end
		end
	end
}
--[[
	技能名：倚天（联动技）
	相关武将：倚天·倚天剑
	描述：当你对曹操造成伤害时，可令该伤害-1 
	状态：验证通过
]]--
LuaXYitian = sgs.CreateTriggerSkill{
	name = "LuaXYitian",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageCaused},   
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		if damage.to:isCaoCao() then
			if player:askForSkillInvoke(self:objectName(), data) then
				damage.damage = damage.damage - 1
				data:setValue(damage)
			end
		end
		return false
	end
}
--[[
	技能名：异才
	相关武将：智·姜维
	描述：每当你使用一张非延时类锦囊时(在它结算之前)，可立即对攻击范围内的角色使用一张【杀】 
	状态：验证通过
]]--
LuaXYicai = sgs.CreateTriggerSkill{
	name = "LuaXYicai",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardUsed, sgs.CardResponsed},  
	on_trigger = function(self, event, player, data) 
		local card = nil
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponsed then
			card = data:toResponsed().m_card
		end
		if card:isNDTrick() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:throwCard(card, nil)
				room:askForUseCard(player, "slash", "@askforslash")
			end
		end
		return false
	end
}
--[[
	技能名：义从（锁定技）
	相关武将：SP·公孙瓒、翼·公孙瓒、翼·赵云
	描述：若你当前的体力值大于2，你计算的与其他角色的距离-1；若你当前的体力值小于或等于2，其他角色计算的与你的距离+1。
	状态：验证通过
]]--
LuaYicong = sgs.CreateDistanceSkill{
	name = "LuaYicong", 
	correct_func = function(self, from, to) 
		if from:hasSkill(self:objectName()) then
			if from:getHp() > 2 then
				return -1
			end
		end
		if to:hasSkill(self:objectName()) then
			if to:getHp() <= 2 then
				return 1
			end
		end
		return 0
	end
}
--[[
	技能名：义从
	相关武将：贴纸·公孙瓒
	描述：弃牌阶段结束时，你可以将任意数量的牌置于武将牌上，称为“扈”。每有一张“扈”，其他角色计算与你的距离+1。 
]]--
--[[
	技能名：义舍
	相关武将：倚天·张公祺
	描述：出牌阶段，你可将任意数量手牌正面朝上移出游戏称为“米”（至多存在五张）或收回；其他角色在其出牌阶段可选择一张“米”询问你，若你同意，该角色获得这张牌，每阶段限两次 
	状态：验证通过
]]--
LuaXYisheCard = sgs.CreateSkillCard{
	name = "LuaXYisheCard", 
	target_fixed = true, 
	will_throw = false, 
	on_use = function(self, room, source, targets) 
		local rice = source:getPile("rice")
		local subs = self:getSubcards()
		if subs:isEmpty() then
			for _,card_id in sgs.qlist(rice) do
				room:obtainCard(source, card_id)
			end
		else
			for _,card_id in sgs.qlist(subs) do
				source:addToPile("rice", card_id)
			end
		end
	end
}
LuaXYisheVS = sgs.CreateViewAsSkill{
	name = "LuaXYisheVS", 
	n = 5, 
	view_filter = function(self, selected, to_select)
		local n = sgs.Self:getPile("rice"):length()
		if #selected + n < 5 then
			return not to_select:isEquipped()
		end
		return false
	end, 
	view_as = function(self, cards) 
		if not sgs.Self:getPile("rice"):isEmpty() then
			if #cards > 0 then
				local card = LuaXYisheCard:clone()
				for _,cd in pairs(cards) do
					card:addSubcard(cd)
				end
				return card
			end
		end
	end, 
	enabled_at_play = function(self, player)
		if player:getPile("rice"):isEmpty() then
			return not player:isKongcheng()
		end
		return true
	end
}
LuaXYisheAskCard = sgs.CreateSkillCard{
	name = "LuaXYisheAskCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		local boss = room:findPlayerBySkillName("LuaXYishe")
		if boss then
			local yishe = boss:getPile("rice")
			if not yishe:isEmpty() then
				local card_id
				if yishe:length() == 1 then
					card_id = yishe:first()
				else
					room:fillAG(yishe, source)
					card_id = room:askForAG(source, yishe, false, "LuaXYisheAsk")
					source:invoke("clearAG")
				end
				local card = sgs.Sanguosha:getCard(card_id)
				source:obtainCard(card)
				room:showCard(source, card_id)
				local choice = room:askForChoice(boss, "LuaXYisheAsk", "allow+disallow")
				if choice == "disallow" then
					boss:addToPile("rice", card_id)
				end
			end
		end
	end
}
LuaXYisheAsk = sgs.CreateViewAsSkill{
	name = "LuaXYisheAsk", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXYisheAskCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if not player:hasSkill("LuaXYishe") then
			if player:usedTimes("#LuaXYisheAskCard") < 2 then
				local boss = nil
				local players = player:getSiblings()
				for _,p in sgs.qlist(players) do
					if p:isAlive() then
						if p:hasSkill("LuaXYishe") then
							boss = p
							break
						end
					end
				end
				if boss then
					return not boss:getPile("rice"):isEmpty()
				end
			end
		end
		return false
	end
}
LuaXYishe = sgs.CreateTriggerSkill{
	name = "LuaXYishe",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.GameStart},  
	view_as_skill = LuaXYisheVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local others = room:getOtherPlayers(player)
		for _,p in sgs.qlist(others) do
			room:attachSkillToPlayer(p, "LuaXYisheAsk")
		end
	end
}
--[[
	技能名：义释
	相关武将：翼·关羽
	描述：每当你使用红桃【杀】对目标角色造成伤害时，你可以防止此伤害，改为获得其区域里的一张牌。
	状态：验证通过
]]--
LuaXYishi = sgs.CreateTriggerSkill{
	name = "LuaXYishi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageCaused},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local slash = damage.card
		if slash and slash:isKindOf("Slash") then
			if slash:getSuit() == sgs.Card_Heart then
				if not damage.chain and not damage.transfer then
					if player:askForSkillInvoke(self:objectName(), data) then
						local target = damage.to
						if not target:isAllNude() then
							local room = player:getRoom()
							local card_id = room:askForCardChosen(player, target, "hej", self:objectName())
							local name = player:objectName()
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, name)
							local card = sgs.Sanguosha:getCard(card_id)
							local place = room:getCardPlace(card_id)
							room:obtainCard(player, card, place ~= sgs.Player_PlaceHand)
						end
						return true
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：毅重（锁定技）
	相关武将：一将成名·于禁
	描述：若你的装备区没有防具牌，黑色的【杀】对你无效。
	状态：验证通过
]]--
LuaYizhong = sgs.CreateTriggerSkill{
	name = "LuaYizhong", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.SlashEffected}, 
	on_trigger = function(self, event, player, data)
		local effect = data:toSlashEffect()
		if effect.slash:isBlack() then
			return true
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				local armor = target:getArmor()
				return (armor == nil)
			end
		end
		return false
	end
}
--[[
	技能名：银铃
	相关武将：☆SP·甘宁
	描述：出牌阶段，你可以弃置一张黑色牌并指定一名其他角色。若如此做，你获得其一张牌并置于你的武将牌上，称为“锦”。（数量最多为四）
	状态：验证通过
]]--
LuaYinlingCard = sgs.CreateSkillCard{
	name = "LuaYinlingCard", 
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local target = effect.to
		local source = effect.from
		local room = target:getRoom()
		if not target:isNude() then
			local brocades = source:getPile("brocade")
			if brocades:length() < 4 then
				local id = room:askForCardChosen(source, target, "he", self:objectName())
				source:addToPile("brocade", id)
			end
		end
	end
}
LuaYinling = sgs.CreateViewAsSkill{
	name = "LuaYinling", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaYinlingCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return player:getPile("brocade"):length() < 4
	end
}
LuaYinlingClear = sgs.CreateTriggerSkill{
	name = "#LuaYinlingClear", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventLoseSkill},  
	on_trigger = function(self, event, player, data) 
		if data:toString() == "LuaYinling" then
			player:removePileByName("brocade")
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：英魂
	相关武将：林·孙坚、山·孙策
	描述：回合开始阶段开始时，若你已受伤，你可以选择一项：令一名其他角色摸X张牌，然后弃置一张牌；或令一名其他角色摸一张牌，然后弃置X张牌（X为你已损失的体力值）。 
	状态：验证通过
]]--
LuaYinghunCard = sgs.CreateSkillCard{
	name = "LuaYinghunCard",
	target_fixed = false, 
	will_throw = true, 
	on_effect = function(self, effect) 
		local source = effect.from
		local dest = effect.to
		local x = source:getLostHp()
		local room = source:getRoom()
		local good = false
		if x == 1 then
			dest:drawCards(1)
			room:askForDiscard(dest, self:objectName(), 1, 1, false, true);
			good = true
		else
			local choice = room:askForChoice(source, self:objectName(), "d1tx+dxt1")
			if choice == "d1tx" then
				dest:drawCards(1)
				x = math.min(x, dest:getCardCount(true))
				room:askForDiscard(dest, self:objectName(), x, x, false, true)
				good = false
			else
				dest:drawCards(x)
				room:askForDiscard(dest, self:objectName(), 1, 1, false, true)
				good = true
			end
		end
		if good then
			room:setEmotion(dest, "good")
		else
			room:setEmotion(dest, "bad")
		end
	end
}
LuaYinghunVS = sgs.CreateViewAsSkill{
	name = "LuaYinghunVS", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaYinghunCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaYinghun"
	end
}
LuaYinghun = sgs.CreateTriggerSkill{
	name = "LuaYinghun", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = LuaYinghunVS, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:askForUseCard(player, "@@LuaYinghun", "@yinghun")
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start then
					return target:isWounded()
				end
			end
		end
		return false
	end
}
--[[
	技能名：英姿
	相关武将：标准·周瑜、山·孙策、翼·周瑜
	描述：摸牌阶段，你可以额外摸一张牌。
	状态：验证通过
]]--
LuaYingzi = sgs.CreateTriggerSkill{
	name = "LuaYingzi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, "LuaYingZi", data) then
			local count = data:toInt() + 1
			data:setValue(count)
		end
	end
}
--[[
	技能名：狱刎（锁定技）
	相关武将：智·田丰
	描述：当你死亡时，凶手视为自己 
	状态：验证失败
]]--
--[[
	技能名：援护
	相关武将：SP·曹洪
	描述：回合结束阶段开始时，你可以将一张装备牌置于一名角色的装备区里，然后根据此装备牌的种类执行以下效果。
		武器牌：弃置与该角色距离为1的一名角色区域中的一张牌；
		防具牌：该角色摸一张牌；
		坐骑牌：该角色回复一点体力。
	状态：验证失败
]]--