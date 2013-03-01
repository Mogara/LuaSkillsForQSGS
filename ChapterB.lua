--[[
	代码速查手册（B区）
	技能索引：
		八阵、霸刀、霸王、拜印、豹变、暴虐、悲歌、北伐、崩坏、笔伐、闭月、补益、不屈
]]--
--[[
	技能名：八阵（锁定技）
	相关武将：火·诸葛亮
	描述：若你的装备区没有防具牌，视为你装备着【八卦阵】。
	状态：验证通过
]]--
LuaBazhen = sgs.CreateTriggerSkill{
	name = "LuaBazhen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardAsked},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toString()
		if pattern == "jink" then
			if player:askForSkillInvoke(self:objectName()) then
				local judge = sgs.JudgeStruct()
				judge.pattern = sgs.QRegExp("(.*):(heart|diamond):(.*)")
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				judge.play_animation = true
				room:setEmotion(player, "armor/eight_diagram");
				room:judge(judge)
				if judge:isGood() then
					local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
					jink:setSkillName(self:objectName())
					room:provide(jink)
					return true
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if not target:getArmor() then
					if not target:hasFlag("wuqian") then
						return target:getMark("qinggang") == 0
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：霸刀
	相关武将：智·华雄
	描述：当你成为黑色的【杀】目标时，你可以对你攻击范围内的一名其他角色使用一张【杀】 
	状态：验证通过
]]--
LuaXBadao = sgs.CreateTriggerSkill{
	name = "LuaXBadao",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardEffected},  
	on_trigger = function(self, event, player, data) 
		local effect = data:toCardEffect()
		local slash = effect.card
		if slash:isKindOf("Slash") and slash:isBlack() then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:askForUseCard(player, "slash", "@askforslash")
			end
		end
		return false
	end
}
--[[
	技能名：霸王
	相关武将：智·孙策
	描述：当你使用的【杀】被【闪】响应时，你可以和对方拼点：若你赢，可以选择最多两个目标角色，视为对其分别使用了一张【杀】
	状态：验证通过
]]--
LuaXBawangCard = sgs.CreateSkillCard{
	name = "LuaXBawangCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets < 2 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				if not (to_select:isKongcheng() and to_select:hasSkill("kongcheng")) then
					return true
				end
			end
		end
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local effect2 = sgs.CardEffectStruct()
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("LuaXBawang")
		effect2.card = slash
		effect2.from = source
		effect2.to = target
		room:cardEffect(effect2)
		room:setEmotion(target, "bad")
		room:setEmotion(source, "good")
	end
}
LuaXBawangVS = sgs.CreateViewAsSkill{
	name = "LuaXBawangVS", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXBawangCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXBawang"
	end
}
LuaXBawang = sgs.CreateTriggerSkill{
	name = "LuaXBawang",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.SlashMissed},  
	view_as_skill = LuaXBawangVS, 
	on_trigger = function(self, event, player, data) 
		local effect = data:toSlashEffect()
		local target = effect.to
		if not target:isNude() then
			if not player:isKongcheng() then
				if not target:isKongcheng() then
					local room = player:getRoom()
					if room:askForSkillInvoke(player, self:objectName(), data) then
						local success = player:pindian(target, self:objectName(), nil)
						if success then
							if player:hasFlag("drank") then
								room:setPlayerFlag(player, "-drank")
							end
							room:askForUseCard(player, "@@LuaXBawang", "@LuaXBawang")
						end
					end
				end
			end
		end
		return false
	end, 
	priority = 2
}
--[[
	技能名：拜印（觉醒技）
	相关武将：神·司马懿
	描述：回合开始阶段开始时，若你拥有4枚或更多的“忍”标记，你须减1点体力上限，并获得技能“极略”。
	状态：验证通过
]]--
LuaBaiyin = sgs.CreateTriggerSkill{
	name = "LuaBaiyin",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "baiyin", 1)
		player:gainMark("@waked")
		room:loseMaxHp(player)
		room:acquireSkill(player, "jilve")
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start then
					if target:getMark("baiyin") == 0 then
						return target:getMark("@bear") >= 4
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：豹变（锁定技）
	相关武将：SP·夏侯霸
	描述：若你的体力值为3或更少，你视为拥有技能“挑衅”;若你的体力值为2或更少;你视为拥有技能“咆哮”;若你的体力值为1，你视为拥有技能“神速”。 
	状态：尚未完成
]]--
--[[
	技能名：暴虐（主公技）
	相关武将：林·董卓
	描述：每当其他群雄角色造成一次伤害后，该角色可以进行一次判定，若判定结果为黑桃，你回复1点体力。
	状态：验证通过
]]--
LuaBaonue = sgs.CreateTriggerSkill{
	name = "LuaBaonue$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage, sgs.PreHpReduced},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if event == sgs.Damage then
			local tag = room:getTag("InvokeBaonue")
			local can_invoke = tag:toBool()
			if can_invoke then
				room:removeTag("InvokeBaonue")
				local list = room:getOtherPlayers(player)	
				for _,lord in sgs.qlist(list) do
					if lord:hasLordSkill(self:objectName()) then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							local judge = sgs.JudgeStruct()
							judge.pattern = sgs.QRegExp("(.*):(spade):(.*)")
							judge.good = true
							judge.reason = self:objectName()
							judge.who = player
							room:judge(judge)				
							if judge:isGood() then
								local recover = sgs.RecoverStruct()
								recover.who = player
								room:recover(lord, recover)
							end
						end
					end
				end
			end
		elseif event == sgs.PreHpReduced then
			local source = damage.from
			if source then
				local kingdom = source:getKingdom()
				if kingdom == "qun" then
					room:setTag("InvokeBaonue", sgs.QVariant(true))			
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--[[
	技能名：悲歌
	相关武将：山·蔡文姬、SP·蔡文姬
	描述：每当一名角色受到【杀】造成的一次伤害后，你可以弃置一张牌，令其进行一次判定，判定结果为：红桃 该角色回复1点体力；方块 该角色摸两张牌；梅花 伤害来源弃置两张牌；黑桃 伤害来源将其武将牌翻面。
	状态：验证通过
]]--
LuaBeige = sgs.CreateTriggerSkill{
	name = "LuaBeige",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local card = damage.card
		if card and card:isKindOf("Slash") then
			local victim = damage.to
			if not victim:isDead() then
				local room = player:getRoom()
				local list = room:getAlivePlayers()
				for _,p in sgs.qlist(list) do
					if not p:isNude() then
						if p:askForSkillInvoke(self:objectName(), data) then
							room:askForDiscard(p, self:objectName(), 1, 1, false, true)
							local judge = sgs.JudgeStruct()
							judge.pattern = sgs.QRegExp("(.*):(.*):(.*)")
							judge.good = true
							judge.who = victim
							judge.reason = self:objectName()
							room:judge(judge)
							local suit = judge.card:getSuit()
							local source = damage.from
							if suit == sgs.Card_Spade then
								if source and source:isAlive() then
									source:turnOver()
								end
							elseif suit == sgs.Card_Heart then
								local recover = sgs.RecoverStruct()
								recover.who = p
								room:recover(victim, recover)
							elseif suit == sgs.Card_Club then
								if source and source:isAlive() then
									local count = source:getCardCount(true)
									if count > 2 then
										count = 2
									end
									if count > 0 then
										room:askForDiscard(source, self:objectName(), count, count, false, true)
									end
								end
							elseif suit == sgs.Card_Diamond then
								victim:drawCards(2)
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--[[
	技能名：北伐（锁定技）
	相关武将：智·姜维
	描述：当你失去最后一张手牌时，视为对攻击范围内的一名角色使用了一张【杀】
	状态：验证通过
]]--
LuaXBeifa = sgs.CreateTriggerSkill{
	name = "LuaXBeifa",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardsMoveOneTime},  
	on_trigger = function(self, event, player, data) 
		if player:isKongcheng() then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() then
				if move.from_places:contains(sgs.Player_PlaceHand) then
					local room = player:getRoom()
					local players = sgs.SPlayerList()
					local others = room:getOtherPlayers(player)
					for _,p in sgs.qlist(others) do
						if not (p:hasSkill("kongcheng") and p:isKongcheng()) then
							if player:inMyAttackRange(p) then
								players:append(p)
							end
						end
					end
					local target = player
					if not players:isEmpty() then
						target = room:askForPlayerChosen(player, players, self:objectName())
					end
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName(self:objectName())
					local use = sgs.CardUseStruct()
					use.card = slash
					use.from = player
					use.to:append(target)
					room:useCard(use)
				end
			end
		end
		return false
	end
}
--[[
	技能名：崩坏（锁定技）
	相关武将：林·董卓
	描述：回合结束阶段开始时，若你不是当前的体力值最少的角色之一，你须失去1点体力或减1点体力上限。 
	状态：验证通过
]]--
LuaBenghuai = sgs.CreateTriggerSkill{
	name = "LuaBenghuai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			local list = room:getOtherPlayers(player)
			local cantrigger = false
			for _,p in sgs.qlist(list) do
				if p:getHp() < player:getHp() then
					cantrigger = true
					break
				end
			end
			if cantrigger then
				local result = room:askForChoice(player, self:objectName(), "hp+maxhp")
				if result == "hp" then
					room:loseHp(player)
				else
					room:loseMaxHp(player)
				end
			end
			return false
		end
	end
}
--[[
	技能名：笔伐
	相关武将：SP·陈琳
	描述：回合结束阶段开始时，你可以将一张手牌背面朝下移出游戏并选择一名其他角色。该角色的回合开始时，其观看此牌并选择一项：1、交给你一张与此牌同类别的手牌，然后获得此牌。2、将此牌置入弃牌堆，然后失去1点体力。
	状态：验证通过
]]--
LuaBifaCard = sgs.CreateSkillCard{
	name = "LuaBifa", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			local bifalist = to_select:getPile("bifa")
			if bifalist:isEmpty() then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		local keystr = string.format("BifaSource%d", self:getEffectiveId())
		local tag = sgs.QVariant()
		tag:setValue(source)
		room:setTag(keystr, tag)
		local cards = self:getSubcards()
		for _,id in sgs.qlist(cards) do
			target:addToPile("bifa", id, false)
		end
	end
}
LuaBifaVS = sgs.CreateViewAsSkill{
	name = "LuaBifaVS", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaBifaCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaBifa"
	end
}
LuaBifa = sgs.CreateTriggerSkill{
	name = "LuaBifa",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = LuaBifaVS, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Finish then
				if not player:isKongcheng() then 
					room:askForUseCard(player, "@@LuaBifa", "@bifa-remove")
					return false
				end
			end
		end
		if player:getPhase() == sgs.Player_RoundStart then
			local bifa_list = player:getPile("bifa")
			if bifa_list:length() > 0 then
				while (not bifa_list:isEmpty()) do
					local card_id = bifa_list:first()
					local keystr = string.format("BifaSource%d", card_id)
					local tag = room:getTag(keystr)
					local chenlin = tag:toPlayer()
					local ids = sgs.IntList()
					ids:append(card_id)
					room:fillAG(ids, player)
					local cd = sgs.Sanguosha:getCard(card_id)
					local pattern
					if cd:isKindOf("BasicCard") then
						pattern = "BasicCard"
					elseif cd:isKindOf("TrickCard") then
						pattern = "TrickCard"
					elseif cd:isKindOf("EquipCard") then
						pattern = "EquipCard"
					end
					local data_for_ai = sgs.QVariant(pattern)
					pattern = string.format("%s|.|.|hand", pattern)
					local to_give = nil
					if not player:isKongcheng() and chenlin and chenlin:isAlive() then
						to_give = room:askForCard(player, pattern, "@bifa-give", data_for_ai, sgs.NonTrigger, chenlin)
					end
					if to_give then
						room:throwCard(cd, player)
						room:obtainCard(chenlin, to_give, false)
						room:obtainCard(player, cd, false)
					else
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
						room:throwCard(cd, reason, nil)
						room:loseHp(player)
					end
					bifa_list:removeOne(card_id)
					player:invoke("clearAG")
					room:removeTag(keystr)
				end
			end
		end
		return false;
	end, 
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：闭月
	相关武将：标准·貂蝉、SP貂蝉、☆SP貂蝉
	描述：回合结束阶段开始时，你可以摸一张牌。
	状态：验证通过
]]--
LuaBiyue = sgs.CreateTriggerSkill{
	name = "LuaBiyue",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				player:drawCards(1)
			end
		end
	end
}
--[[
	技能名：补益
	相关武将：一将成名·吴国太
	描述：当一名角色进入濒死状态时，你可以展示该角色的一张手牌，若此牌不为基本牌，该角色弃置之，然后回复1点体力。
	状态：验证通过
]]--
LuaBuyi = sgs.CreateTriggerSkill{
	name = "LuaBuyi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local list = room:getAlivePlayers()
		for _,doctor in sgs.qlist(list) do
			if doctor:hasSkill(self:objectName()) then
				if room:askForSkillInvoke(doctor, self:objectName(), data) then
					local card
					if player:objectName() == doctor:objectName() then
						card = room:askForCardShow(player, doctor, self:objectName())
					else
						id = room:askForCardChosen(doctor, player, "h", self:objectName())
						card = sgs.Sanguosha:getCard(id)
					end
					room:showCard(player, card:getEffectiveId())
					local cardtype = card:getTypeId()
					if cardtype ~= sgs.Card_Basic then
						room:throwCard(card, player)
						local recover = sgs.RecoverStruct()
						recover.who = doctor
						room:recover(player, recover)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return not target:isKongcheng()
		end
		return false
	end
}
--[[
	技能名：不屈
	相关武将：风·周泰
	描述：每当你扣减1点体力后，若你当前的体力值为0：你可以从牌堆顶亮出一张牌置于你的武将牌上，若此牌的点数与你武将牌上已有的任何一张牌都不同，你不会死亡；若出现相同点数的牌，你进入濒死状态。
	状态：验证通过
]]--
LuaBuqu = sgs.CreateTriggerSkill{
	name = "LuaBuqu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Dying, sgs.HpRecover, sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Dying then
			local buqu = player:getPile("buqu")
			local need = 1 - player:getHp()
			local n = need - buqu:length()
			if n <= 0 then
				return false
			end
			if not room:askForSkillInvoke(player, self:objectName(), data) then
				return false
			end
			local ids = room:getNCards(n)
			for _,id in sgs.qlist(ids) do
				player:addToPile("buqu", id)
			end
			buqu = player:getPile("buqu")
			local numlist = {0,0,0,0,0,0,0,0,0,0,0,0,0}
			for _,id in sgs.qlist(buqu) do
				local card = sgs.Sanguosha:getCard(id)
				local num = card:getNumber()
				if numlist[num] then
					return false
				else
					numlist[num] = 1
				end
			end
			return true	
		elseif event == sgs.HpRecover then
			local recover = data:toRecover()
			local buqu = player:getPile("buqu")
			local count = buqu:length()
			if count > 0 then
				room:fillAG(buqu, player)
				for var=1,recover.recover,1 do
					local id_t = room:askForAG(player, buqu, false, self:objectName())
					room:throwCard(id_t, player)
				end
				player:invoke("clearAG")
			end
		elseif event == sgs.AskForPeachesDone then
			local buqu = player:getPile("buqu")
			local numlist = {0,0,0,0,0,0,0,0,0,0,0,0,0}
			local b = false
			for _,id_t in sgs.qlist(buqu) do
				local card = sgs.Sanguosha:getCard(id_t)
				local num = card:getNumber()
				if numlist[num] then
					return false
				else
					numlist[num] = 1
				end
			end
			return true
		end
	end
}