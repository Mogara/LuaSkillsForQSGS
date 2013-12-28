--[[
	代码速查手册（T区）
	技能索引：
		抬榇、贪婪、探虎、探囊、躺枪、天妒、天命、天香、天义、挑衅、铁骑、同疾、同心、偷渡、突骑、突袭、突袭、屯田
]]--
--[[
	技能名：抬榇
	相关武将：倚天·庞令明
	描述：出牌阶段，你可以自减1点体力或弃置一张武器牌，弃置你攻击范围内的一名角色区域的两张牌。每回合中，你可以多次使用抬榇
	引用：LuaXTaichen
	状态：验证通过
]]--
LuaXTaichenCard = sgs.CreateSkillCard{
	name = "LuaXTaichenCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:isAllNude() then
				local cards = self:getSubcards()
				if not cards:isEmpty() then
					local weapon = sgs.Self:getWeapon()
					if weapon and cards:first() == weapon:getId() then
						if not sgs.Self:hasSkill("zhengfeng") then
							return sgs.Self:distanceTo(to_select) == 1
						end
					end
				end
				return sgs.Self:inMyAttackRange(to_select)
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local cards = self:getSubcards()
		if cards:isEmpty() then
			room:loseHp(source)
		else
			room:throwCard(self, source)
		end
		for i=1, 2, 1 do
			if not target:isAllNude() then
				local card = room:askForCardChosen(source, target, "hej", "LuaXTaichen")
				room:throwCard(card, target)
			end
		end
	end
}
LuaXTaichen = sgs.CreateViewAsSkill{
	name = "LuaXTaichen",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isKindOf("Weapon")
		end
		return false
	end,
	view_as = function(self, cards)
		local taichen_card = LuaXTaichenCard:clone()
		if #cards == 1 then
			taichen_card:addSubcard(cards[1])
		end
		return taichen_card
	end
}
--[[
	技能名：贪婪
	相关武将：智·许攸
	描述：每当你受到一次伤害，可与伤害来源进行拼点：若你赢，你获得两张拼点牌
	引用：LuaXTanlan
	状态：验证通过
]]--
LuaXTanlan = sgs.CreateTriggerSkill{
	name = "LuaXTanlan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Pindian, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local from = damage.from
			local room = player:getRoom()
			if from then
				if not from:isKongcheng() and not player:isKongcheng() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						player:pindian(from, "LuaXTanlan")
					end
				end
			end
			return false
		else
			local pindian = data:toPindian()
			if pindian.reason == "LuaXTanlan" then
				local cardA = pindian.to_card
				local cardB = pindian.from_card
				if cardA:getNumber() < cardB:getNumber() then
					player:obtainCard(cardA)
					player:obtainCard(cardB)
				end
			end
		end
		return false
	end,
	priority = -1
}
--[[
	技能名：探虎
	相关武将：☆SP·吕蒙
	描述：出牌阶段限一次，你可以与一名角色拼点：若你赢，你拥有以下锁定技：你无视与该角色的距离，你使用的非延时类锦囊牌对该角色结算时不能被【无懈可击】响应，直到回合结束。
	状态：验证失败
]]--
--[[
	技能名：探囊（锁定技）
	相关武将：翼·张飞
	描述：你计算的与其他角色的距离-X（X为你已损失的体力值）。
	引用：LuaXTannang
	状态：验证通过
]]--
LuaXTannang = sgs.CreateDistanceSkill{
	name = "LuaXTannang",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			local lost = from:getLostHp()
			return -lost
		end
	end
}
--[[
	技能名：躺枪（锁定技）
	相关武将：胆创·夏侯杰
	描述：杀死你的角色失去1点体力上限并获得技能“躺枪”。
]]--
--[[
	技能名：天妒
	相关武将：标准·郭嘉、SP·台版郭嘉
	描述：在你的判定牌生效后，你可以获得此牌。
	引用：LuaTiandu
	状态：0610验证通过
]]--
LuaTiandu = sgs.CreateTriggerSkill{
	name = "LuaTiandu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local judge = data:toJudge()
		local card = judge.card
		local card_data = sgs.QVariant()
		card_data:setValue(card)
		if player:askForSkillInvoke(self:objectName(), card_data) then
			player:obtainCard(card)
		end
	end
}
--[[
	技能名：天覆
	相关武将：阵·姜维
	描述：你或与你相邻的角色的回合开始时，该角色可以令你拥有“看破”，直到回合结束。 
]]--
--[[
	技能名：天命
	相关武将：铜雀台·汉献帝、SP·刘协
	描述：当你成为【杀】的目标时，你可以弃置两张牌（不足则全弃，无牌则不弃），然后摸两张牌；若此时全场体力值最多的角色仅有一名（且不是你），该角色也可如此做
	引用：LuaXTianming
	状态：验证通过
]]--
LuaXTianming = sgs.CreateTriggerSkill{
	name = "LuaXTianming",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local slash = use.card
		if slash and slash:isKindOf("Slash") then
			if player:askForSkillInvoke(self:objectName()) then
				local room = player:getRoom()
				if not player:isNude() then
					local total = 0
					local jilei_cards = {}
					local handcards = player:getHandcards()
					for _,card in sgs.qlist(handcards) do
						if player:isJilei(card) then
							table.insert(jilei_cards, card)
						end
					end
					total = handcards:length() - #jilei_cards + player:getEquips():length()
					if total <= 2 then
						player:throwAllHandCardsAndEquips()
					else
						room:askForDiscard(player, self:objectName(), 2, 2, false, true)
					end
				end
				player:drawCards(2)
				local maxHp = -1000
				local allplayers = room:getAllPlayers()
				for _,p in sgs.qlist(allplayers) do
					if p:getHp() > maxHp then
						maxHp = p:getHp()
					end
				end
				if player:getHp() ~= maxHp then
					local maxs = sgs.SPlayerList()
					for _,p in sgs.qlist(allplayers) do
						if p:getHp() == maxHp then
							maxs:append(p)
						end
						if maxs:length() > 1 then
							return false
						end
					end
					local mosthp = maxs:first()
					if room:askForSkillInvoke(mosthp, self:objectName()) then
						local jilei_cards = {}
						local handcards = mosthp:getHandcards()
						for _,card in sgs.qlist(handcards) do
							if mosthp:isJilei(card) then
								table.insert(jilei_cards, card)
							end
						end
						local total = handcards:length() - #jilei_cards + mosthp:getEquips():length()
						if total <= 2 then
							mosthp:throwAllHandCardsAndEquips()
						else
							room:askForDiscard(mosthp, self:objectName(), 2, 2, false, true)
						end
						mosthp:drawCards(2)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：天香
	相关武将：风·小乔、SP·王战小乔
	描述：每当你受到伤害时，你可以弃置一张红桃手牌，将此伤害转移给一名其他角色，然后该角色摸X张牌（X为该角色当前已损失的体力值）。
	引用：LuaTianxiang
	状态：验证失败
]]--

--[[
	技能名：天义
	相关武将：火·太史慈
	描述：出牌阶段限一次，你可以与一名角色拼点。若你赢，你获得以下锁定技，直到回合结束：你使用【杀】无距离限制；你于出牌阶段内能额外使用一张【杀】；你使用【杀】选择目标的个数上限+1。若你没赢，你不能使用【杀】，直到回合结束。
	引用：LuaTianyi、LuaTianyiTargetMod
	状态：验证通过
]]--
LuaTianyiCard = sgs.CreateSkillCard{
	name = "LuaTianyiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "tianyi", self)
		if success then
			room:setPlayerFlag(source, "tianyi_success")
		else
			room:setPlayerCardLimitation(source, "use", "Slash", true)
		end
	end,
}
LuaTianyiVS = sgs.CreateViewAsSkill{
	name = "LuaTianyi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = LuaTianyiCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#LuaTianyiCard")) and (not player:isKongcheng())
	end,
}
LuaTianyi = sgs.CreateTriggerSkill{
	name = "LuaTianyi",
	events = {sgs.EventLoseSkill},
	view_as_skill = LuaTianyiVS,
	on_trigger = function(self, event, player, data)
		if data:toString() == self:objectName() then
			room:setPlayerFlag(player, "-tianyi_success")
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("tianyi_success")
	end,
}
LuaTianyiTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaTianyiTargetMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("tianyi_success") then
			return 1
		else
			return 0
		end
	end,
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("tianyi_success") then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("tianyi_success") then
			return 1
		else
			return 0
		end
	end,
}
--[[
	技能名：挑衅
	相关武将：山·姜维，1V1姜维
	描述：出牌阶段，你可以令一名你在其攻击范围内的其他角色选择一项：对你使用一张【杀】，或令你弃置其一张牌。每阶段限一次。
	引用：LuaTiaoxin
	状态：1227验证通过
]]--
LuaTiaoxinCard = sgs.CreateSkillCard{
	name = "LuaTiaoxinCard" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:inMyAttackRange(sgs.Self) and to_select:objectName() ~= sgs.Self:objectName()
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local use_slash = false
		if effect.to:canSlash(effect.from, nil, false) then
			use_slash = room:askForUseSlashTo(effect.to,effect.from, "@tiaoxin-slash:" .. effect.from:objectName())
		end
		if (not use_slash) and effect.from:canDiscard(effect.to, "he") then
			room:throwCard(room:askForCardChosen(effect.from,effect.to, "he", "LuaTiaoxin", false, sgs.Card_MethodDiscard), effect.to, effect.from)
		end
	end
}
LuaTiaoxin = sgs.CreateViewAsSkill{
	name = "LuaTiaoxin",
	n = 0 ,
	view_as = function()
		return LuaTiaoxinCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaTiaoxinCard")
	end
}
--[[
	技能名：铁骑
	相关武将：标准·马超、SP·马超、1v1·马超1v1、SP·台版马超
	描述：当你使用【杀】指定一名角色为目标后，你可以进行一次判定，若判定结果为红色，该角色不可以使用【闪】对此【杀】进行响应。
	引用：LuaTieji
	状态：0901验证通过

	备注：和无双一样的问题，由于0610缺少QVariant::toIntList()和QVariant::setValue(QList <int>)而导致技能无法实现
	Fs吐槽下：上一个版本的技能谁写的？技能明明不是SlashProceed时机发动的！！
]]--
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
LuaTieji = sgs.CreateTriggerSkill{
	name = "LuaTieji" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			local _data = sgs.QVariant()
			_data:setValue(p)
			if player:askForSkillInvoke(self:objectName(), _data) then
				p:setFlags("LuaTiejiTarget")
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				player:getRoom():judge(judge)
				if judge:isGood() then
					jink_table[index] = 0
				end
				p:setFlags("-LuaTiejiTarget")
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
	技能名：同疾（锁定技）
	相关武将：标准·袁术
	描述：若你的手牌数大于你的体力值，且你在一名其他角色的攻击范围内，则其他角色不能被选择为该角色的【杀】的目标。
]]--
--[[
	技能名：同心
	相关武将：倚天·夏侯涓
	描述：处于连理状态的两名角色，每受到一点伤害，你可以令你们两人各摸一张牌
	引用：LuaXTongxin
	状态：验证通过
]]--
LuaXTongxin = sgs.CreateTriggerSkill{
	name = "LuaXTongxin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local source = room:findPlayerBySkillName(self:objectName())
		if source then
			if source:askForSkillInvoke(self:objectName(), data) then
				local target = nil
				if player:objectName() == source:objectName() then
					local players = room:getOtherPlayers(source)
					for _,p in sgs.qlist(players) do
						if p:getMark("@tied") > 0 then
							target = p
							break
						end
					end
				else
					target = player
				end
				local damage = data:toDamage()
				local count = damage.damage
				source:drawCards(count)
				if target then
					target:drawCards(count)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return target:getMark("@tied") > 0
		end
		return false
	end
}
--[[
	技能名：偷渡
	相关武将：倚天·邓士载
	描述：当你的武将牌背面向上时若受到伤害，你可以弃置一张手牌并将你的武将牌翻面，视为对一名其他角色使用了一张【杀】
	引用：LuaXToudu
	状态：验证通过
]]--
LuaXToudu = sgs.CreateTriggerSkill{
	name = "LuaXToudu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		if not player:faceUp() then
			if not player:isKongcheng() then
				if player:askForSkillInvoke("LuaXToudu") then
					local room = player:getRoom()
					if room:askForDiscard(player, "LuaXtoudu", 1, 1, false, false) then
						player:turnOver()
						local players = room:getOtherPlayers(player)
						local targets = sgs.SPlayerList()
						for _,p in sgs.qlist(players) do
							if player:canSlash(p, nil, false) then
								targets:append(p)
							end
						end
						if not targets:isEmpty() then
							local target = room:askForPlayerChosen(player, targets, "LuaXToudu")
							local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							slash:setSkillName("LuaXToudu")
							local use = sgs.CardUseStruct()
							use.card = slash
							use.from = player
							use.to:append(target)
							room:useCard(use)
						end
					end
				end
			end
		end
	end
}
--[[
	技能名：突骑（锁定技）
	相关武将：贴纸·公孙瓒
	描述：准备阶段开始时，若你的武将牌上有“扈”，你将所有“扈”置入弃牌堆：若X小于或等于2，你摸一张牌。本回合你与其他角色的距离-X。（X为准备阶段开始时置于弃牌堆的“扈”的数量）
	引用：LuaXTuqi、LuaXTuqiDist
	状态：验证通过
]]--
LuaXTuqi = sgs.CreateTriggerSkill{
	name = "LuaXTuqi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_NotActive then
			room:setPlayerMark(player, "yicong", 0)
		end
		if player:getPhase() ~= sgs.Player_Start then return end
		local n = player:getPile("retinue"):length()
		if n < 1 then return end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, "LuaXYicong", "")
		for _,card_id in sgs.qlist(player:getPile("retinue")) do
			room:moveCardTo(sgs.Sanguosha:getCard(card_id), nil, sgs.Player_DiscardPile, reason, true)
		end
		room:setPlayerMark(player, "yicong", n)
		if n <= 2 then
			player:drawCards(1)
		end
	end,
}
LuaXTuqiDist = sgs.CreateDistanceSkill{
	name = "#LuaXTuqi",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return -from:getMark("yicong")
		end
	end,
}
--[[
	技能名：突袭
	相关武将：标准·张辽、SP·台版张辽
	描述：摸牌阶段开始时，你可以放弃摸牌，改为获得一至两名其他角色的各一张手牌。
	引用：LuaTuxi
	状态：0610验证通过
]]--
LuaTuxiCard = sgs.CreateSkillCard{
	name = "LuaTuxiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if (#targets >= 2) or (to_select:objectName() == sgs.Self:objectName()) then
			return false
		end
		return not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		local moves = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct()
		move1.card_ids:append(room:askForCardChosen(source, targets[1], "h", self:objectName()))
		move1.to = source
		move1.to_place = sgs.Player_PlaceHand
		moves:append(move1)
		if #targets == 2 then
			local move2 = sgs.CardsMoveStruct()
			move2.card_ids:append(room:askForCardChosen(source, targets[2], "h", self:objectName()))
			move2.to = source
			move2.to_place = sgs.Player_PlaceHand
			moves:append(move2)
		end
		room:moveCards(moves, false)
	end
}
LuaTuxiVS = sgs.CreateViewAsSkill{
	name = "LuaTuxi",
	n = 0,
	view_as = function(self, cards)
		return LuaTuxiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaTuxi"
	end
}
LuaTuxi = sgs.CreateTriggerSkill{
	name = "LuaTuxi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaTuxiVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _,target in sgs.qlist(other_players) do
				if not target:isKongcheng() then
					can_invoke = true
					break;
				end
			end
			if can_invoke then
				if room:askForUseCard(player, "@@LuaTuxi", "@tuxi-card") then
					return true
				end
			end
		end
		return false
	end
}

--[[
	技能名：突袭
	相关武将：1v1·张辽1v1
	描述：摸牌阶段，若你的手牌数小于对手的手牌数，你可以少摸一张牌并你获得对手的一张手牌。
]]--
--[[
	技能名：屯田
	相关武将：山·邓艾
	描述：你的回合外，当你失去牌时，你可以进行一次判定，将非红桃结果的判定牌置于你的武将牌上，称为“田”；每有一张“田”，你计算的与其他角色的距离便-1。
	引用：LuaTuntian、LuaTuntianGet
	状态：验证通过
]]--
LuaTuntian = sgs.CreateDistanceSkill{
	name = "#LuaTuntian",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			local fields = from:getPile("field")
			local count = fields:length()
			return -count
		end
	end
}
LuaTuntianGet = sgs.CreateTriggerSkill{
	name = "LuaTuntianGet",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime, sgs.FinishJudge, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		if player:isAlive() then
			if player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_NotActive then
					if event == sgs.CardsMoveOneTime then
						local move = data:toMoveOneTime()
						local source = move.from
						if source and source:objectName() == player:objectName() then
							local places = move.from_places
							local room = player:getRoom()
							if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
								if player:askForSkillInvoke(self:objectName(), data) then
									local judge = sgs.JudgeStruct()
									judge.pattern = sgs.QRegExp("(.*):(heart):(.*)")
									judge.good = false
									judge.reason = self:objectName()
									judge.who = player
									judge.play_animation = true
									room:judge(judge)
								end
							end
						end
					elseif event == sgs.FinishJudge then
						local judge = data:toJudge()
						if judge.reason == self:objectName() then
							if judge:isGood() then
								local id = judge.card:getEffectiveId()
								player:addToPile("field", id)
								return true
							end
						end
					end
				end
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				player:removePileByName("field")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
