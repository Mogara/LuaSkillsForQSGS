--[[
	代码速查手册（T区）
	技能索引：
		抬榇、贪婪、探虎、探囊、天妒、天命、天香、天义、挑衅、铁骑、同心、偷渡、突骑、突袭、屯田
]]--
--[[
	技能名：抬榇
	相关武将：倚天·庞令明
	描述：出牌阶段，你可以自减1点体力或弃置一张武器牌，弃置你攻击范围内的一名角色区域的两张牌。每回合中，你可以多次使用抬榇 
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
	描述：出牌阶段，你可以与一名其他角色拼点。若你赢，你获得以下技能直到回合结束：你与该角色的距离为1.你对该角色使用的非延时类锦囊不能被【无懈可击】抵消，每阶段限一次。
	状态：验证失败
]]--
--[[
	技能名：探囊（锁定技）
	相关武将：翼·张飞
	描述：你计算的与其他角色的距离-X（X为你已损失的体力值）。
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
	技能名：天妒
	相关武将：标准·郭嘉
	描述：在你的判定牌生效后，你可以获得此牌。
	状态：验证通过
]]--
LuaTiandu = sgs.CreateTriggerSkill{
	name = "LuaTiandu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
		local card_data = sgs.QVariant()
		card_data:setValue(card)
		if room:askForSkillInvoke(player, self:objectName(), card_data) then
			player:obtainCard(card)
		end
	end
}
--[[
	技能名：天命
	相关武将：铜雀台·汉献帝
	描述：当你成为【杀】的目标时，你可以弃置两张牌（不足则全弃，无牌则不弃），然后摸两张牌；若此时全场体力值最多的角色仅有一名（且不是你），该角色也可如此做 
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
	相关武将：风·小乔
	描述：每当你受到伤害时，你可以弃置一张红桃手牌，将此伤害转移给一名其他角色，然后该角色摸X张牌（X为该角色当前已损失的体力值）。
	状态：验证通过
]]--
LuaTianxiangCard = sgs.CreateSkillCard{
	name = "LuaTianxiangCard", 
	target_fixed = false, 
	will_throw = true, 
	on_effect = function(self, effect) 
		local target = effect.to
		local room = target:getRoom()
		room:setPlayerFlag(target, "TianxiangTarget")
		local tag = room:getTag("TianxiangDamage")
		local damage = tag:toDamage()
		damage.to = target
		damage.transfer = true
		room:damage(damage)
	end
}
LuaTianxiangVS = sgs.CreateViewAsSkill{
	name = "LuaTianxiangVS", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return to_select:getSuit() == sgs.Card_Heart
		end
		return false
	end, 
	view_as = function(self, cards)
		local tianxiangCard = LuaTianxiangCard:clone()
		tianxiangCard:addSubcard(cards[1])
		return tianxiangCard
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@tianxiang"
	end
}
LuaTianxiang = sgs.CreateTriggerSkill{
	name = "LuaTianxiang", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageInflicted, sgs.DamageComplete}, 
	view_as_skill = LuaTianxiangVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			if player:isAlive() then
				if player:hasSkill(self:objectName()) then
					if not player:isKongcheng() then
						local damage = data:toDamage()
						local value = sgs.QVariant()
						value:setValue(damage)
						room:setTag("TianxiangDamage", value)
						if room:askForUseCard(player, "@@tianxiang", "@tianxiang-card") then
							return true
						end
					end
				end
			end
		elseif event == sgs.DamageComplete then
			if player:hasFlag("TianxiangTarget") then
				if player:isAlive() then
					room:setPlayerFlag(player, "-TianxiangTarget")
					local count = player:getLostHp()
					player:drawCards(count, false)
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end, 
	priority = 2
}
--[[
	技能名：天义
	相关武将：火·太史慈
	描述：出牌阶段，你可以与一名其他角色拼点。若你赢，你获得以下技能直到回合结束：你使用【杀】时无距离限制；可以额外使用一张【杀】；使用【杀】时可以额外选择一个目标。若你没赢，你不能使用【杀】，直到回合结束。每阶段限一次。
	状态：验证通过
]]--
LuaTianyiCard = sgs.CreateSkillCard{
	name = "LuaTianyiCard", 
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
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "tianyi", self)
		if success then
			room:setPlayerFlag(source, "tianyi_success")
		else
			room:setPlayerFlag(source, "tianyi_failed")
		end
	end
}
LuaTianyi = sgs.CreateViewAsSkill{
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
		if not player:hasUsed("#LuaTianyiCard") then
			return not player:isKongcheng()
		end
		return false
	end
}
LuaTianyiClear = sgs.CreateTriggerSkill{
	name = "#LuaTianyiClear", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventLoseSkill}, 
	on_trigger = function(self, event, player, data)
		if data:toString() == self:objectName() then
			room:setPlayerFlag(player, "-tianyi_success")
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasFlag("tianyi_success")
		end
		return false
	end
}
--[[
	技能名：挑衅
	相关武将：山·姜维
	描述：出牌阶段，你可以令一名你在其攻击范围内的其他角色选择一项：对你使用一张【杀】，或令你弃置其一张牌。每阶段限一次。
	状态：验证通过
]]--
LuaTiaoxinCard = sgs.CreateSkillCard{
	name = "LuaTiaoxinCard", 
	target_fixed = false,
	will_throw = true, 
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:inMyAttackRange(sgs.Self) then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local dest = effect.to
		local room = source:getRoom()
		local prompt = string.format("@tiaoxin-slash:%s", source:objectName())
		if not room:askForUseSlashTo(dest, source, prompt) then
			if not dest:isNude() then
				local chosen = room:askForCardChosen(source, dest, "he", self:objectName())
				room:throwCard(chosen, dest, source)
			end
		end
	end
}
LuaTiaoxin = sgs.CreateViewAsSkill{
	name = "LuaTiaoxin",
	n = 0, 
	view_as = function(self, cards) 
		return LuaTiaoxinCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaTiaoxinCard")
	end
}
--[[
	技能名：铁骑
	相关武将：标准·马超、SP·马超
	描述：当你使用【杀】指定一名角色为目标后，你可以进行一次判定，若判定结果为红色，该角色不可以使用【闪】对此【杀】进行响应。
	状态：验证通过
]]--
LuaTieji = sgs.CreateTriggerSkill{
	name = "LuaTieji",
	frequency = sgs.Skill_NotFrequency,
	events = {sgs.SlashProceed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not room:askForSkillInvoke(player, self:objectName()) then
			return false
		end
		local judge = sgs.JudgeStruct()
		judge.pattern = sgs.QRegExp("(.*):(heart|diamond):(.*)")
		judge.good = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if judge:isGood() then
			local effect = data:toSlashEffect()
			room:slashResult(effect, nil)	  
			return true
		end
	end
}
--[[
	技能名：同心
	相关武将：倚天·夏侯涓
	描述：处于连理状态的两名角色，每受到一点伤害，你可以令你们两人各摸一张牌 
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
	描述：回合开始阶段开始时，若你的武将牌上有“扈”：你计算与其他角色的距离-X，直到回合结束，若X不大于2，你摸一张牌（X为你武将牌上“扈”的数量），然后你将所有“扈”置入弃牌堆。 
]]--
--[[
	技能名：突袭
	相关武将：标准·张辽
	描述：摸牌阶段开始时，你可以放弃摸牌，改为获得一至两名其他角色的各一张手牌。
	状态：验证通过
]]--
LuaTuxiCard = sgs.CreateSkillCard{
	name = "LuaTuxiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select) 
		if #targets < 2 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				return not to_select:isKongcheng()
			end
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local moves = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct()
		local id1 = room:askForCardChosen(source, targets[1], "h", self:objectName())
		move1.card_ids:append(id1)
		move1.to = source
		move1.to_place = sgs.Player_PlaceHand
		moves:append(move1)
		if #targets == 2 then
			local move2 = sgs.CardsMoveStruct()
			local id2 = room:askForCardChosen(source, targets[2], "h", self:objectName())
			move2.card_ids:append(id2)
			move2.to = source
			move2.to_place = sgs.Player_PlaceHand
			moves:append(move2)
		end
		room:moveCards(moves, false)
	end
}
LuaTuxiVS = sgs.CreateViewAsSkill{
	name = "LuaTuxiVS", 
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
	技能名：屯田
	相关武将：山·邓艾
	描述：你的回合外，当你失去牌时，你可以进行一次判定，将非红桃结果的判定牌置于你的武将牌上，称为“田”；每有一张“田”，你计算的与其他角色的距离便-1。
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