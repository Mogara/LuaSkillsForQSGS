--[[
	代码速查手册（G区）
	技能索引：
		甘露、感染、刚戾、刚烈、刚烈、弓骑、弓骑、攻心、共谋、蛊惑、固守、固政、观星、归汉、归心、归心、鬼才、鬼道、国色
]]--
--[[
	技能名：甘露
	相关武将：一将成名·吴国太
	描述：出牌阶段，你可以交换两名角色装备区里的牌，以此法交换的装备数差不能超过X（X为你已损失体力值）。每阶段限一次。
	状态：验证通过
]]--
LuaGanluCard = sgs.CreateSkillCard{
	name = "LuaGanluCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			local n1 = targets[1]:getEquips():length()
			local n2 = to_select:getEquips():length()
			local diff = math.abs(n1 - n2)
			local lost = sgs.Self:getLostHp()
			return diff <= lost
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local first = targets[1]
		local second = targets[2]
		local idlistA = sgs.IntList()
		local idlistB = sgs.IntList()
		local equipsA = first:getEquips()
		local equipsB = second:getEquips()
		for _,equip in sgs.qlist(equipsA) do
			idlistA:append(equip:getId())
		end
		for _,equip in sgs.qlist(equipsB) do
			idlistB:append(equip:getId())
		end
		local move = sgs.CardsMoveStruct()
		move.card_ids = idlistA
		move.to = second
		move.to_place = sgs.Player_PlaceSpecial
		room:moveCards(move, false)
		move.card_ids = idlistB
		move.to = first
		move.to_place = sgs.Player_PlaceEquip
		room:moveCards(move, false)
		move.card_ids = idlistA
		move.to = second
		move.to_place = sgs.Player_PlaceEquip
		room:moveCards(move, false)
	end
}
LuaGanlu = sgs.CreateViewAsSkill{
	name = "LuaGanlu",
	n = 0,
	view_as = function(self, cards)
		return LuaGanluCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaGanluCard")
	end
}
--[[
	技能名：感染（锁定技）
	相关武将：僵尸·僵尸
	描述：你的装备牌都视为铁锁连环。 
]]--
--[[
	技能名：刚戾
	相关武将：3D织梦·程昱
	描述：每当你受到其他角色造成的1点伤害后，你可以：选择除伤害来源外的另一名角色，视为伤害来源对该角色使用一张【杀】（此【杀】无距离限制且不计入出牌阶段使用次数限制）。 
]]--
--[[
	技能名：刚烈
	相关武将：标准·夏侯惇
	描述：每当你受到一次伤害后，你可以进行一次判定，若判定结果不为红桃，则伤害来源选择一项：弃置两张手牌，或受到你对其造成的1点伤害。
	状态：验证通过
]]--
LuaGanglie = sgs.CreateTriggerSkill{
	name = "LuaGanglie", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		local source_data = sgs.QVariant()
		source_data:setValue(source)
		if room:askForSkillInvoke(player, self:objectName(), source_data) then
			local judge = sgs.JudgeStruct()
			judge.pattern = sgs.QRegExp("(.*):(heart):(.*)")
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isGood() then
				if not room:askForDiscard(source, self:objectName(), 2, 2, true) then
					local damage = sgs.DamageStruct()
					damage.from = player;
					damage.to = source;
					room:damage(damage);
				end
			end
		end
	end
}
--[[
	技能名：刚烈
	相关武将：翼·夏侯惇
	描述：每当你受到一次伤害后，你可以进行一次判定，若判定结果不为红桃，你选择一项：令伤害来源弃置两张手牌，或受到你对其造成的1点伤害。 
	状态：验证通过
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
				judge.pattern = sgs.QRegExp("(.*):(heart):(.*)")
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
	技能名：弓骑
	相关武将：二将成名·韩当
	描述：出牌阶段，你可以弃置一张牌，令你的攻击范围无限直到回合结束；若你以此法弃置的牌为装备牌，你可以弃置一名其他角色的一张牌，每阶段限一次。 
]]--
--[[
	技能名：弓骑
	相关武将：怀旧·韩当
	描述：你可以将一张装备牌当【杀】使用或打出；你以此法使用【杀】时无距离限制。
	状态：0224验证通过
]]--
LuaGongqi = sgs.CreateViewAsSkill{
	name = "LuaGongqi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		local weapon = sgs.Self:getWeapon()
		if weapon then
			if to_select:objectName() == weapon:objectName() then
				if to_select:objectName() == "Crossbow" then
					return sgs.Self:canSlashWithoutCrossbow()
				end
			end
		end
		return to_select:getTypeId() == sgs.Card_Equip
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
			slash:addSubcard(id)
			slash:setSkillName(self:objectName())
			return slash
		end
	end, 
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
LuaGongqiTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaGongqiTargetMod",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("LuaGongqi") then
			if card:getSkillName() == "LuaGongqi" then
				return 1000
			end
		end
		return 0
	end
}
--[[
	技能名：攻心
	相关武将：神·吕蒙
	描述：出牌阶段，你可以观看任意一名角色的手牌，并可以展示其中一张红桃牌，然后将其弃置或置于牌堆顶。每阶段限一次。 
	状态：验证通过
]]--
LuaGongxinCard = sgs.CreateSkillCard{
	name = "LuaGongxinCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if not target:isKongcheng() then
			room:doGongxin(source, target)
		end
	end
}
LuaGongxin = sgs.CreateViewAsSkill{
	name = "LuaGongxin",
	n = 0,
	view_as = function(self, cards)
		local card = LuaGongxinCard:clone()
		card:setSkillName(self:objectName())
		return card 
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaGongxinCard")
	end
}
--[[
	技能名：共谋
	相关武将：倚天·钟士季
	描述：回合结束阶段开始时，可指定一名其他角色：其在摸牌阶段摸牌后，须给你X张手牌（X为你手牌数与对方手牌数的较小值），然后你须选择X张手牌交给对方 
	状态：验证通过
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
	描述：你可以说出一张基本牌或非延时类锦囊牌的名称，并背面朝上使用或打出一张手牌。若无其他角色质疑，则亮出此牌并按你所述之牌结算。若有其他角色质疑则亮出验明：若为真，质疑者各失去1点体力；若为假，质疑者各摸一张牌。除非被质疑的牌为红桃且为真，此牌仍然进行结算，否则无论真假，将此牌置入弃牌堆。
	状态：尚未完成
]]--
--[[
	技能名：固守
	相关武将：智·田丰
	描述：回合外，当你使用或打出一张基本牌时，可以摸一张牌 
	状态：验证通过
]]--
LuaXGushou = sgs.CreateTriggerSkill{
	name = "LuaXGushou",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardUsed, sgs.CardResponsed},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local current = room:getCurrent()
		if current and current:objectName() ~= player:objectName() then
			local card = nil
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
			elseif event == sgs.CardResponsed then
				card = data:toResponsed().m_card
			end
			if card:isKindOf("BasicCard") then
				if not card:isVirtualCard() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						player:drawCards(1)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：固政
	相关武将：山·张昭张纮
	描述：其他角色的弃牌阶段结束时，你可以将该角色于此阶段中弃置的一张牌从弃牌堆返回其手牌，若如此做，你可以获得弃牌堆里其余于此阶段中弃置的牌。
	状态：0224验证通过
	附注：以字符串形式保存卡牌id
]]--
require("bit") --位运算所需
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
							local flag = bit:_and(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
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
	相关武将：标准·诸葛亮、山·姜维
	描述：回合开始阶段开始时，你可以观看牌堆顶的X张牌（X为存活角色数且至多为5），将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。
	状态：验证通过
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
				local cards = room:getNCards(count, false)
				room:askForGuanxing(player, cards, false)
			end
		end
	end
}
--[[
	技能名：归汉
	相关武将：倚天·蔡昭姬
	描述：出牌阶段，你可以主动弃置两张相同花色的红色手牌，和你指定的一名其他存活角色互换位置。每阶段限一次 
	状态：验证通过
]]--
LuaXGuihanCard = sgs.CreateSkillCard{
	name = "LuaXGuihanCard", 
	target_fixed = false, 
	will_throw = true, 
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:swapSeat(source, target)
	end
}
LuaXGuihan = sgs.CreateViewAsSkill{
	name = "LuaXGuihan", 
	n = 2, 
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			if #selected == 0 then
				return to_select:isRed()
			elseif #selected == 1 then
				local suit = selected[1]:getSuit()
				return to_select:getSuit() == suit
			end
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 2 then
			local card = LuaXGuihanCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaXGuihanCard")
	end
}
--[[
	技能名：归心
	相关武将：神·曹操
	描述：每当你受到1点伤害后，你可以分别从每名其他角色的区域获得一张牌，然后将你的武将牌翻面。
	状态：验证通过
]]--
LuaGuixin = sgs.CreateTriggerSkill{
	name = "LuaGuixin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local count = damage.damage
		local can_invoke = false
		local targets = room:getOtherPlayers(player)
		for i=0, count, 1 do
			for _,p in sgs.qlist(targets) do
				if not p:isAllNude() then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				if player:askForSkillInvoke(self:objectName()) then
					local targets = room:getOtherPlayers(player)
					for _,p in sgs.qlist(targets) do
						if not p:isAllNude() then
							local card_id = room:askForCardChosen(player, p, "hej", self:objectName())
							room:obtainCard(player, card_id, true)
						end
					end
					can_invoke = false
					player:turnOver()
				end
			else
				break
			end
		end
	end
}
--[[
	技能名：归心
	相关武将：倚天·魏武帝
	描述：回合结束阶段，你可以做以下二选一：
		1. 永久改变一名其他角色的势力
		2. 永久获得一项未上场或已死亡角色的主公技。(获得后即使你不是主公仍然有效) 
	状态：验证通过
]]--
LuaGuixin = sgs.CreateTriggerSkill{
	name = "LuaGuixin",
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
	技能名：鬼才
	相关武将：标准·司马懿
	描述：在一名角色的判定牌生效前，你可以打出一张手牌代替之。
	状态：验证通过
]]--
GuicaiCard = sgs.CreateSkillCard{
	name = "GuicaiCard",
	target_fixed = true,
	will_throw = false,
}
LuaGuicaiVS = sgs.CreateViewAsSkill{
	name = "LuaGuicai",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = GuicaiCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@LuaGuicai"
	end
}
LuaGuicai = sgs.CreateTriggerSkill{
	name = "LuaGuicai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.AskForRetrial},
	view_as_skill = LuaGuicaiVS,
	on_trigger = function(self, event, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			local judge = data:toJudge()
			local room = player:getRoom()
			local card = room:askForCard(player, "@LuaGuicai", nil, data, sgs.AskForRetrial)
			room:retrial(card, player, judge, self:objectName())
			return false
		end
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				return not target:isKongcheng()
			end
		end
		return false
	end
}
--[[
	技能名：鬼道
	相关武将：风·张角
	描述：在一名角色的判定牌生效前，你可以打出一张黑色牌替换之。
	状态：验证通过
]]--
GuidaoCard = sgs.CreateSkillCard{
	name = "GuidaoCard",
	target_fixed = true,
	will_throw = false
}
LuaGuidaoVS = sgs.CreateViewAsSkill{
	name = "LuaGuidao",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isBlack()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = GuidaoCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@LuaGuidao"
	end
}
LuaGuidao = sgs.CreateTriggerSkill{
	name = "LuaGuidao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.AskForRetrial},
	view_as_skill = LuaGuidaoVS,
	on_trigger = function(self, event, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			local judge = data:toJudge()
			local room = player:getRoom()
			local card = room:askForCard(player, "@LuaGuidao", nil, data, sgs.AskForRetrial)
			room:retrial(card, player, judge, self:objectName(), true)
			return false
		end
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:isKongcheng() then
					for i=1, 4, 1 do
						local equip = target:getEquip(i)
						if equip:isBlack() then
							return true
						end
					end
					return false
				else
					return true
				end
			end
		end
		return false
	end
}
--[[
	技能名：国色
	相关武将：标准·大乔
	描述：你可以将一张方块牌当【乐不思蜀】使用。
	状态：验证通过
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