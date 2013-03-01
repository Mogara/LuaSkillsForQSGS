--[[
	代码速查手册（V区）
	技能索引：（本区用于收录尚未实现或有争议的技能）
	☆源代码转化失败，改写后通过：
		不屈、称象、龙胆、龙魂、龙魂
	☆验证失败：
		洞察、弓骑、固政、虎啸、护驾、激将、极略、军威、疠火、连理、秘计、神速、探虎、伪帝、武神、修罗、狱刎、援护
	☆尚未完成：
		豹变、归心、缓释、缓释、落英
	☆尚未验证：
		弘援、弘援、明哲
]]--
--[[
	技能名：豹变（锁定技）
	相关武将：SP·夏侯霸
	描述：若你的体力值为3或更少，你视为拥有技能“挑衅”;若你的体力值为2或更少;你视为拥有技能“咆哮”;若你的体力值为1，你视为拥有技能“神速”。 
	状态：验证通过
]]--
BaobianChange = function(room, player, hp, skill_name)
	local room = player:getRoom()
	local baobian_skills = player:getTag("BaobianSkills"):toString():split("+")
	if player:getHp() <= hp then
		if not table.contains(baobian_skills, skill_name) then
			room:acquireSkill(player, skill_name)
			table.insert(baobian_skills, skill_name)
		end
	else
		room:detachSkillFromPlayer(player, skill_name)
		for i=1, #baobian_skills, 1 do
			if baobian_skills[i]==skill_name  then
				table.remove(baobian_skills, i)
			end
		end
	end
	player:setTag("BaobianSkills", sgs.QVariant(table.concat(baobian_skills, "+")))
end
LuaBaobian = sgs.CreateTriggerSkill{
	name = "LuaBaobian",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.GameStart, sgs.HpChanged, sgs.MaxHpChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill},  
	on_trigger = function(self, event, player, data) 
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local baobian_skills = player:getTag("BaobianSkills"):toString():split("+")
				for _,skname in ipairs(baobian_skills) do
					room:detachSkillFromPlayer(player, skill_name)
				end
				player:setTag("BaobianSkills", sgs.QVariant())
			end
			return false
		end
		if player:isAlive() and player:hasSkill(self:objectName()) then
			BaobianChange(room, player, 1, "shensu")
			BaobianChange(room, player, 2, "paoxiao")
			BaobianChange(room, player, 3, "tiaoxin")
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end, 
}
--[[
	技能：不屈
	相关武将：风·周泰
	描述：每当你扣减1点体力后，若你当前的体力值为0：你可以从牌堆顶亮出一张牌置于你的武将牌上，若此牌的点数与你武将牌上已有的任何一张牌都不同，你不会死亡；若出现相同点数的牌，你进入濒死状态。
	状态：验证失败（第一次回复体力时不能移除不屈牌）
]]--
Remove = function(player)
	local room = player:getRoom()
	local buqu = player:getPile("buqu")
	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "buqu", "")
	local need = 1 - player:getHp()
	if need <= 0 then
		for _,id in sgs.qlist(buqu) do
			local card = sgs.Sanguosha:getCard(id)
			room:throwCard(card, reason, nil)
		end
	else
		local to_remove = buqu:length() - need
		for i=1, to_remove, 1 do
			room:fillAG(buqu)
			local card_id = room:askForAG(player, buqu, false, "LuaBuqu")
			buqu:removeOne(card_id)
			local card = sgs.Sanguosha:getCard(card_id)
			room:throwCard(card, reason, nil)
			room:broadcastInvoke("clearAG")
		end
	end
end
LuaBuquRemove = sgs.CreateTriggerSkill{
	name = "#LuaBuquRemove",
	frequency = sgs.Skill_Frequent,
	events = {sgs.HpRecover, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		if event == sgs.HpRecover then
			if player:isAlive() and player:hasSkill("LuaBuqu") then
				if player:getPile("buqu"):length() > 0 then
					Remove(player)
				end
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() == "buqu" then
				player:removePileByName("buqu")
				if player:getHp() <= 0 then
					local room = player:getRoom()
					room:enterDying(player, nil)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
LuaBuqu = sgs.CreateTriggerSkill{
	name = "LuaBuqu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PostHpReduced, sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PostHpReduced then
			if player:getHp() < 1 then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:setTag("Buqu", sgs.QVariant(player:objectName()))
					local buqu = player:getPile("buqu")
					local need = 1 - player:getHp()
					local n = need - buqu:length()
					if n > 0 then
						local card_ids = room:getNCards(n, false)
						for _,id in sgs.qlist(card_ids) do
							player:addToPile("buqu", id)
						end
					end
					local buqunew = player:getPile("buqu")
					local duplicate_numbers = sgs.IntList()
					local numbers = {}
					for _,card_id in sgs.qlist(buqunew) do
						local card = sgs.Sanguosha:getCard(card_id)
						local number = card:getNumber()
						if numbers[number] then
							duplicate_numbers:append(number)
						else
							numbers[number] = number
						end
					end
					if duplicate_numbers:isEmpty() then
						room:setTag("Buqu", sgs.QVariant())
						return true
					end
				end
			end
		elseif event == sgs.AskForPeachesDone then
			local buqu = player:getPile("buqu")
			if player:getHp() <= 0 then
				if room:getTag("Buqu"):toString() == player:objectName() then
					room:setTag("Buqu", sgs.QVariant())
					local duplicate_numbers = sgs.IntList()
					local numbers = {}
					for _,card_id in sgs.qlist(buqu) do
						local card = sgs.Sanguosha:getCard(card_id)
						local number = card:getNumber()
						if numbers[number] then
							if not duplicate_numbers:contains(number) then
								duplicate_numbers:append(number)
							else
								numbers[number] = number
							end
						else
							numbers[number] = number
						end
					end
					if duplicate_numbers:isEmpty() then
						room:setPlayerFlag(player, "-dying")
						return true
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：称象
	相关武将：倚天·曹冲
	描述：每当你受到1次伤害，你可打出X张牌（X小于等于3），它们的点数之和与造成伤害的牌的点数相等，你可令X名角色各恢复1点体力（若其满体力则摸2张牌）
	状态：验证通过
]]--
LuaXChengxiangCard = sgs.CreateSkillCard{
	name = "LuaXChengxiangCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		local count = self:subcardsLength()
		if #targets < count then
			return to_select:isWounded()
		end
		return false
	end,
	feasible = function(self, targets)
		local count = self:subcardsLength()
		return #targets <= count
	end,
	on_use = function(self, room, source, targets) 
		local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
		if #targets == 0 then
			effect.to = source
			self:onEffect(effect)
		else
			for _,tg in ipairs(targets) do
				effect.to = tg
				self:onEffect(effect)
			end
		end
	end,
	on_effect = function(self, effect) 
		local target = effect.to
		local room = target:getRoom()
		if target:isWounded() then
			local recover = sgs.RecoverStruct()
			recover.card = self
			recover.who = effect.from
			room:recover(target, recover)
		else
			target:drawCards(2)
		end
	end
}
LuaXChengxiangVS = sgs.CreateViewAsSkill{
	name = "LuaXChengxiangVS", 
	n = 3, 
	view_filter = function(self, selected, to_select)
		if #selected < 3 then
			local sum = 0
			for _,card in pairs(selected) do
				sum = sum + card:getNumber()
			end
			sum = sum + to_select:getNumber()
			local target = sgs.Self:getMark("LuaXChengxiang")
			return sum <= target
		end
		return false
	end, 
	view_as = function(self, cards) 
		local sum = 0
		for _,card in pairs(cards) do
			sum = sum + card:getNumber()
		end
		local target = sgs.Self:getMark("LuaXChengxiang")
		if sum == target then
			local vs_card = LuaXChengxiangCard:clone()
			for _,card in pairs(cards) do
				vs_card:addSubcard(card)
			end
			return vs_card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXChengxiang"
	end
}
LuaXChengxiang = sgs.CreateTriggerSkill{
	name = "LuaXChengxiang",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged},  
	view_as_skill = LuaXChengxiangVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card then
			local point = card:getNumber()
			if point > 0 then
				if not player:isNude() then
					room:setPlayerMark(player, self:objectName(), point)
					local prompt = string.format("@chengxiang-card:::%d", point)
					room:askForUseCard(player, "@@LuaXChengxiang", prompt)
				end
			end
		end
	end
}
--[[
	技能名：洞察
	相关武将：倚天·贾文和
	描述：回合开始阶段开始时，你可以指定一名其他角色：该角色的所有手牌对你处于可见状态，直到你的本回合结束。其他角色都不知道你对谁发动了洞察技能，包括被洞察的角色本身 
	状态：验证失败（被洞察的角色的手牌不能处于可见状态）
]]--
LuaXDongcha = sgs.CreateTriggerSkill{
	name = "LuaXDongcha",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		local phase = player:getPhase()
		local room = player:getRoom()
		if phase == sgs.Player_Start then
			if player:askForSkillInvoke(self:objectName()) then
				local players = room:getOtherPlayers(player)
				local dongchaee = room:askForPlayerChosen(player, players, self:objectName())
				room:setPlayerFlag(dongchaee, "dongchaee")
				local tag = sgs.QVariant()
				tag:setValue(dongchaee:objectName())
				room:setTag("Dongchaee", tag)
				tag:setValue(player:objectName())
				room:setTag("Dongchaer", tag)
				room:showAllCards(dongchaee, player)
			end
		elseif phase == sgs.Player_Finish then
			local tag = room:getTag("Dongchaee")
			if tag then
				local dongchaee_name = tag:toString()
				if not dongchaee_name:isEmpty() then
					local list = room:getOtherPlayers(player)
					local dongchaee = nil
					for _,p in sgs.qlist(list) do
						if p:objectName() == dongchaee_name then
							dongchaee = p
							break
						end
					end
					if dongchaee then
						room:setPlayerFlag(dongchaee, "-dongchaee")
					end
					room:setTag("Dongchaee", sgs.QVariant())
					room:setTag("Dongchaer", sgs.QVariant())
				end
			end
		end
		return false
	end
}
--[[
	技能名：弓骑
	相关武将：怀旧·韩当
	描述：你可以将一张装备牌当【杀】使用或打出；你以此法使用【杀】时无距离限制。
	状态：验证失败（cloneCard的结果是nil，怀疑武神杀是否由此法产生）
]]--
LuaGongqi = sgs.CreateViewAsSkill{
	name = "LuaGongqi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:getTypeId() == sgs.Card_Equip
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local slash = sgs.Sanguosha:cloneCard("wushen_slash", suit, point)
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
--[[
	技能名：固政
	相关武将：山·张昭张纮
	描述：其他角色的弃牌阶段结束时，你可以将该角色于此阶段中弃置的一张牌从弃牌堆返回其手牌，若如此做，你可以获得弃牌堆里其余于此阶段中弃置的牌。
	状态：验证失败（QVariant无法转化成QList<int>）
]]--
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
		if source and erzhang then
			if player:objectName() == source:objectName() then
				if erzhang:objectName() ~= current:objectName() then
					if current:getPhase() == sgs.Player_Discard then
						local tag = room:getTag("GuzhengToGet")
						local guzhengToGet = tag:toIntList()
						tag = room:getTag("GuzhengToOther")
						local guzhengOther = tag:toIntList()
						for _,card_id in sgs.qlist(move.card_ids) do
							local flag = bit.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
							if flag == sgs.CardMoveReason_S_REASON_DISCARD then
								if source:objectName() == current:objectName() then
									guzhengToGet:append(card_id)
								elseif not guzhengToGet:contains(card_id) then
									guzhengOther:append(card_id)
								end
							end
						end
						tag:setValue(guzhengToGet)
						room:setTag("GuzhengToGet", tag)
						tag:setValue(guzhengOther)
						room:setTag("GuzhengOther", tag)
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
			local player = room:findPlayerBySkillName(self:objectName())
			if player then
				local tag = room:getTag("GuzhengToGet")
				local guzheng_cardsToGet = tag:toIntList()
				tag = room:getTag("GuzhengOther")
				local guzheng_cardsOther = tag:toIntList()
				room:removeTag("GuzhengToGet")
				room:removeTag("GuzhengOther")

				local cardsToGet = sgs.IntList()
				local cards = sgs.IntList()
				for _,card_data in sgs.qlist(guzheng_cardsToGet) do
					local card_id = card_data:toInt()
					if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
						cardsToGet:append(card_id)
						cards:append(card_id)
					end
				end
				for _,card_data in sgs.qlist(guzheng_cardsOther) do
					local card_id = card_data:toInt()
					if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
						cards:append(card_id)
					end
				end
				if cardsToGet:length() > 0 then
					local ai_data = sgs.QVariant()
					ai_data:setValue(cards:length())
					if player:askForSkillInvoke(self:objectName(), ai_data) then
						room:fillAG(cards, player)
						local to_back = room:askForAG(player, cardsToGet, false, self:objectName())
						local backcard = sgs.Sanguosha:getCard(to_back)
						player:obtainCard(backcard)
						cards:removeOne(to_back)
						player:invoke("clearAG")
						local move = sgs.CardsMoveStruct()
						move.card_ids = cards
						move.to = player
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
	技能名：归心
	相关武将：倚天·魏武帝
	描述：回合结束阶段，你可以做以下二选一：
		1. 永久改变一名其他角色的势力
		2. 永久获得一项未上场或已死亡角色的主公技。(获得后即使你不是主公仍然有效) 
	状态：尚未完成（含有findChildren<Skill*>和qobject_cast<GameStartSkill*>等内容无法转换）
]]--
LuaXWeiwudiGuixin = sgs.CreateTriggerSkill{
	name = "LuaXWeiwudiGuixin",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				local choice = room:askForChoice(player, self:objectName(), "modify+obtain")
				if choice == "modify" then
					local others = room:getOtherPlayers(player)
					local to_modify = room:askForPlayerChosen(player, others, self:objectName())
					local tag = sgs.QVariant()
					tag:setValue(to_modify)
					room:setTag("Guixin2Modify", tag)
					local kingdom = room:askForChoice(player, self:objectName(), "wei+shu+wu+qun")
					room:removeTag("Guixin2Modify")
					room:setPlayerProperty(to_modify, "kingdom", sgs.QVariant(kingdom))
				elseif choice == "obtain" then
					local lords = sgs.Sanguosha:getLords()
					local players = room:getOtherPlayers(player)
					for _,p in sgs.qlist(players) do
						local name = p:getGeneralName()
						lords:removeOne(name)
					end
					local lord_skills
					--[[以下内容含有findChildren<Skill*>和qobject_cast<GameStartSkill*>等无法转换
					for _,lord in sgs.qlist(lords) do
						local general = sgs.Sanguosha:getGeneral(lord)
						QList<const Skill *> skills = general->findChildren<const Skill *>();
						for _,skill in sgs.qlist(skills) do
							if skill:isLordSkill() then
								local skillname = skill:objectName()
								if not player:hasSkill(skillname) then
									lord_skills:append(skillname)
								end
							end
						end
					end
					if not lord_skills:isEmpty() then
						local skill_name = room:askForChoice(player, self:objectName(), lord_skills.join("+"))
						local skill = sgs.Sanguosha:getSkill(skill_name)
						room:acquireSkill(player, skill)
						if skill:inherits("GameStartSkill") then
							const GameStartSkill *game_start_skill = qobject_cast<const GameStartSkill *>(skill)
							game_start_skill->onGameStart(player)
						end
					end
					]]--
				end
			end
		end
		return false
	end
}
--[[
	技能名：弘援
	相关武将：新3V3·诸葛瑾
	描述：摸牌阶段，你可以少摸一张牌，令其他己方角色各摸一张牌。
	状态：尚未验证
]]--
LuaXHongyuan = sgs.CreateTriggerSkill{
	name = "LuaXHongyuan",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DrawNCards},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
        if room:askForSkillInvoke(player, self:objectName()) then
            room:setPlayerFlag(player, self:objectName())
            local count = data:toInt() - 1
			data:setValue(count)
        end
	end
}
LuaXHongyuanAct = sgs.CreateTriggerSkill{
	name = "#LuaXHongyuanAct",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.AfterDrawNCards},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Draw then
			if player:hasFlag("LuaXHongyuan") then
				room:setPlayerFlag(player, "-Invoked")
                for _,other in sgs.qlist(room:getOtherPlayers(player)) do
                    if sgs.AI_GetRelation3v3(player, other) == sgs.AI_Friend then
                        other:drawCards(1)
					end
                end
			end
		end
        return false
	end
}
--[[
	技能名：弘援
	相关武将：新3V3·诸葛瑾（身份局）
	描述：摸牌阶段，你可以少摸一张牌，令一至两名其他角色各摸一张牌。
	状态：尚未验证
]]--
LuaXHongyuanCard = sgs.CreateSkillCard{
	name = "LuaXHongyuanCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if to_select:objectName() ~= sgs.Self:objectName() then
			return #targets < 2
		end
		return false
	end,
	on_effect = function(self, effect) 
		effect.to:drawCards(1)
	end
}
LuaXHongyuanVS = sgs.CreateViewAsSkill{
	name = "LuaXHongyuan", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXHongyuanCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXHongyuan"
	end
}
LuaXHongyuan = sgs.CreateTriggerSkill{
	name = "LuaXHongyuan",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DrawNCards},  
	view_as_skill = LuaXHongyuanVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
        if room:askForSkillInvoke(player, self:objectName()) then
            room:setPlayerFlag(player, self:objectName())
            local count = data:toInt() - 1
			data:setValue(count)
        end
	end
}
LuaXHongyuanAct = sgs.CreateTriggerSkill{
	name = "#LuaXHongyuanAct",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.AfterDrawNCards},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Draw then
			if player:hasFlag("LuaXHongyuan") then
				room:setPlayerFlag(player, "-Invoked")
				if not room:askForUseCard(player, "@@LuaXHongyuan", "@hongyuan") then
					player:drawCards(1)
				end
			end
		end
        return false
	end
}
--[[
	技能名：虎啸
	相关武将：SP·关银屏
	描述：你于出牌阶段每使用一张【杀】被【闪】抵消，此阶段你可以额外使用一张【杀】。 
	状态：验证失败（不能额外使用杀）
]]--
LuaHuxiao = sgs.CreateTriggerSkill{
	name = "LuaHuxiao", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.SlashMissed, sgs.EventPhaseChanging},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.SlashMissed then
			if player:getPhase() == sgs.Player_Play then
				local count = player:getMark(self:objectName())
				room:setPlayerMark(player, "huxiao", count + 1)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				if player:getMark(self:objectName()) > 0 then
					room:setPlayerMark(player, "huxiao", 0)
				end
			end
		end
		return false
	end
}
LuaHuxiaoRemove = sgs.CreateTriggerSkill{
	name = "#LuaHuxiao", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventLoseSkill},   
	on_trigger = function(self, event, player, data) 
		if data:toString() == "LuaHuxiao" then
			room:setPlayerMark(player, "huxiao", 0)
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：护驾（主公技）
	相关武将：标准·曹操、铜雀台·曹操
	描述：当你需要使用或打出一张【闪】时，你可以令其他魏势力角色打出一张【闪】（视为由你使用或打出）。 
	状态：验证失败（可以实现技能效果，但服务器有指向askForCard函数的AI错误信息）
]]--
LuaHujia = sgs.CreateTriggerSkill{
	name = "LuaHujia$",
	frequency = sgs.NotFrequent,
	events = {sgs.CardAsked},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toString()
		if pattern == "jink" then
			local lieges = room:getLieges("wei", player)
			if not lieges:isEmpty() then
				if room:askForSkillInvoke(player, self:objectName()) then
					local tohelp = sgs.QVariant()
					tohelp:setValue(player)
					for _,p in sgs.qlist(lieges) do
						local prompt = string.format("@hujia-jink:%s", player:objectName())
						local jink = room:askForCard(p, "jink", prompt, tohelp, sgs.CardResponsed, player)
						if jink then
							room:provide(jink)
							return true
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, player)
		if player then
			return player:hasLordSkill(self:objectName())
		end
		return false
	end
}
--[[
	技能名：缓释
	相关武将：新3V3·诸葛瑾
	描述：在一名己方角色的判定牌生效前，你可以打出一张牌代替之。
	状态：尚未完成（含有tag无法转化）
]]--
LuaXHuanshiCard = sgs.CreateSkillCard{
	name = "LuaXHuanshiCard", 
	target_fixed = true, 
	will_throw = false, 
	handling_method = sgs.Card_MethodResponse
}
LuaXHuanshiVS = sgs.CreateViewAsSkill{
	name = "LuaXHuanshi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isCardLimited(to_select, sgs.Card_MethodResponse)
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaXHuanshiCard:clone()
			card:setSuit(cards[1]:getSuit())
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@LuaXHuanshi"
	end
}
getTeammates = function(zhugejin)
	local room = zhugejin:getRoom()
	local teammates = sgs.SPlayerList()
	teammates:append(zhugejin)
	local others = room:getOtherPlayers(zhugejin)
	for _,other in sgs.qlist(others) do
		if sgs.AI_GetRelation3v3(zhugejin, other) == sgs.AI_Friend then
			teammates:append(other)
		end
	end
	return teammates
end
LuaXHuanshi = sgs.CreateTriggerSkill{
	name = "LuaXHuanshi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.AskForRetrial},  
	view_as_skill = LuaXHuanshiVS, 
	on_trigger = function(self, event, player, data) 
		local judge = data:toJudge()
		local can_invoke = false
		local mates = getTeammates(player)
		for _,teammate in sgs.qlist(mates) do
			if teammate:objectName() == judge.who:objectName() then
				can_invoke = true
				break
			end
		end
		if not can_invoke then
			return false
		end
		local prompt_list = {"@huanshi-card", judge.who:objectName(), self:objectName(), judge.reason, judge.card:getEffectIdString()}
		local prompt = table.concat(prompt_list, ":")
		--[[以下内容含有tag无法转化
		player->tag["Judge"] = data
		]]--
		local pattern = "@LuaXHuanshi"
		local card = room:askForCard(player, pattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				return not target:isNude()
			end
		end
		return false
	end
}
--[[
	技能名：缓释
	相关武将：新3V3·诸葛瑾（身份局）
	描述：在一名角色的判定牌生效前，你可以令其选择是否由你打出一张牌代替之。
	状态：尚未完成（含有tag无法转化）
]]--
LuaXHuanshiCard = sgs.CreateSkillCard{
	name = "LuaXHuanshiCard", 
	target_fixed = true, 
	will_throw = false, 
	handling_method = sgs.Card_MethodResponse
}
LuaXHuanshiVS = sgs.CreateViewAsSkill{
	name = "LuaXHuanshi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isCardLimited(to_select, sgs.Card_MethodResponse)
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaXHuanshiCard:clone()
			card:setSuit(cards[1]:getSuit())
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@LuaXHuanshi"
	end
}
LuaXHuanshi = sgs.CreateTriggerSkill{
	name = "LuaXHuanshi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.AskForRetrial},  
	view_as_skill = LuaXHuanshiVS, 
	on_trigger = function(self, event, player, data) 
		local judge = data:toJudge()
		local can_invoke = false
		local room = player:getRoom()
		if judge.who:objectName() ~= player:objectName() then
			if room:askForSkillInvoke(player, self:objectName()) then
				if room:askForChoice(judge.who, self:objectName(), "yes+no") == "yes" then
					can_invoke = true;
				end
			end
		else 
			can_invoke = true
		end
		if not can_invoke then
			return false
		end
		local prompt_list = {"@huanshi-card", judge.who:objectName(), self:objectName(), judge.reason, judge.card:getEffectIdString()}
		local prompt = table.concat(prompt_list, ":")
		--[[以下内容含有tag无法转化
		player->tag["Judge"] = data
		]]--
		local pattern = "@LuaXHuanshi"
		local card = room:askForCard(player, pattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				return not target:isNude()
			end
		end
		return false
	end
}
--[[
	技能名：激将（主公技）
	相关武将：标准·刘备、山·刘禅
	描述：当你需要使用或打出一张【杀】时，你可以令其他蜀势力角色打出一张【杀】（视为由你使用或打出）。
	状态：验证失败（sgs.ClientInstance为空导致在打出杀时发动技能时出错）
]]--
LuaJijiangCard = sgs.CreateSkillCard{
	name = "LuaJijiangCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local players = sgs.PlayerList()
		if #targets > 0 then
			for _,p in pairs(targets) do
				players:append(p)
			end
		end
		return slash:targetFilter(players, to_select, sgs.Self)
	end,
	on_use = function(self, room, source, targets) 
		local lieges = room:getLieges("shu", source)
		local slash = NULL
		local tohelp = sgs.QVariant()
		tohelp:setValue(source)
		local prompt = string.format("@jijiang-slash:%s", source:objectName())
		for _,liege in sgs.qlist(lieges) do
			slash = room:askForCard(liege, "slash", prompt, tohelp, sgs.CardResponsed, source)
			if slash then
				local card_use = sgs.CardUseStruct()
				card_use.card = slash
				card_use.from = source
				card_use.to:append(targets[1])
				room:useCard(card_use)
				return;
			end
		end
		room:setPlayerFlag(source, "jijiang_failed")
	end
}
LuaJijiangVS = sgs.CreateViewAsSkill{
	name = "LuaJijiang$", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaJijiangCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:hasLordSkill("LuaJijiang") then
			return sgs.Slash_IsAvailable(player)
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		if pattern == "slash" then
			if not sgs.ClientInstance:hasNoTargetResponsing() then
				return not player:hasFlag("jijiang_failed")
			end
		end
		return false
	end
}
LuaJijiang = sgs.CreateTriggerSkill{
	name = "LuaJijiang$",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardAsked}, 
	view_as_skill = LuaJijiangVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local pattern = data:toString()
		if pattern == "slash" then 
			local lieges = room:getLieges("shu", player)
			if not lieges:isEmpty() then
				if room:askForSkillInvoke(player, self:objectName()) then
					local tohelp = sgs.QVariant()
					tohelp:setValue(player)
					local prompt = string.format("@jijiang-slash:%s", player:objectName())
					for _,liege in sgs.qlist(lieges) do
						local slash = room:askForCard(liege, "slash", prompt, tohelp, sgs.CardResponsed, player)
						if slash then
							room:provide(slash)
							return true;
						end
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasLordSkill("LuaJijiang")
		end
		return false
	end
}
--[[
	技能名：极略
	相关武将：神·司马懿
	描述：弃一枚“忍”标记发动下列一项技能——“鬼才”、“放逐”、“完杀”、“制衡”、“集智”。
	状态：验证失败（无法发动鬼才，制衡和完杀选择效果有误）
]]--
LuaJilveCard = sgs.CreateSkillCard{
	name = "LuaJilveCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		local choices = ""
		local count = 0
		if not source:hasUsed("ZhihengCard") then
			if not source:hasSkill("zhiheng") then
				choices = "zhiheng"
				count = count + 1
			end
		end
		local tag = room:getTag("JilveWansha")
		if not tag or not tag:toBool() then
			if not source:hasSkill("wansha") then
				if count == 0 then
					choices = "wansha"
				elseif count == 1 then
					choices = "zhiheng+wansha"
				end
			end
		end
		if choices ~= "" then
			local choice
			if count == 1 then
				choice = choices
			else
				choice = room:askForChoice(source, "LuaJilve", "zhiheng+wansha")
			end
			source:loseMark("@bear")
			if choice == "wansha" then
				room:acquireSkill(source, "wansha")
				room:setTag("JilveWansha", sgs.QVariant(true))
			else
				room:askForUseCard(source, "@zhiheng", "@jilve-zhiheng")
			end
		end
	end
}
LuaJilveVS = sgs.CreateViewAsSkill{
	name = "LuaJilveVS", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaJilveCard:clone()
	end, 
	enabled_at_play = function(self, player)
		local extra = 0
		if player:hasSkill("zhiheng") then
			extra = extra + 1
		elseif player:hasInnateSkill("wansha") then
			extra = extra + 1
		end
		local times = player:usedTimes("#LuaJilveCard")
		if times + extra < 2 then
			return player:getMark("@bear") > 0
		end
		return false
	end
}
LuaJilve = sgs.CreateTriggerSkill{
	name = "LuaJilve",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardUsed, sgs.CardResponsed, sgs.AskForRetrial, sgs.Damaged},  
	view_as_skill = LuaJilveVS, 
	on_trigger = function(self, event, player, data) 
		player:setMark("JilveEvent", event)
		if event == sgs.CardUsed or event == sgs.CardResponsed then
			local card = nil
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toResponsed().m_card
			end
			if card:isNDTrick() then
				if not player:hasSkill("jizhi") then
					if player:askForSkillInvoke("LuaJilve", data) then
						player:loseMark("@bear")
						player:drawCards(1)
					end
				end
			end
		elseif event == sgs.AskForRetrial then
			local guicai = sgs.Sanguosha:getTriggerSkill("guicai")
			if guicai and not player:isKongcheng() then
				if not player:hasSkill("guicai") then
					if player:askForSkillInvoke("LuaJilve", data) then
						player:loseMark("@bear")
						guicai:trigger(event, room, player, data)
					end
				end
			end
		elseif event == sgs.Damaged then
			local fangzhu = sgs.Sanguosha:getTriggerSkill("fangzhu")
			if fangzhu and not player:hasSkill("fangzhu") then
				if player:askForSkillInvoke("LuaJilve", data) then
					player:loseMark("@bear")
					fangzhu:trigger(event, room, player, data)
				end
			end
		end
		player:setMark("JilveEvent", 0)
		return false
	end, 
	can_trigger = function(self, target)
		if target then 
			if target:isAlive() and target:hasSkill(self:objectName()) then
				return target:getMark("@bear") > 0
			end
		end
		return false
	end
}
LuaJilveClear = sgs.CreateTriggerSkill{
	name = "#LuaJilveClear",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "wansha")
		room:removeTag("JilveWansha")
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) and target:isAlive() then
				if target:getPhase() == sgs.Player_NotActive then
					local room = sgs.Sanguosha:currentRoom()
					local tag = room:getTag("JilveWansha")
					if tag then
						return tag:toBool()
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：军威
	相关武将：☆SP·甘宁
	描述：回合结束阶段开始时，你可以将三张“锦”置入弃牌堆。若如此做，你须指定一名角色并令其选择一项：1.亮出一张【闪】，然后由你交给任意一名角色。2.该角色失去1点体力，然后由你选择将其装备区的一张牌移出游戏。在该角色的回合结束后，将以此法移出游戏的装备牌移回原处。
	状态：未经验证 (原有bug:（若原位置有其他装备牌，把移出游戏的装备牌移回原处时出错。）)
]]--
LuaJunwei = sgs.CreateTriggerSkill{
	name = "LuaJunwei", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if player:getPile("brocade"):length() >= 3 then
				if player:askForSkillInvoke(self:objectName()) then
					local brocade = player:getPile("brocade")
					for i = 0, 2, 1 do
						local card_id = 0
						room:fillAG(brocade, player)
						if brocade:length() == 3 - i then
							card_id = brocade:at(0)
						else
							card_id = room:askForAG(player, brocade, false, self:objectName())
						end
						player:invoke("clearAG")
						brocade:removeOne(card_id)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
						local card = sgs.Sanguosha:getCard(card_id)
						room:throwCard(card, reason, nil)
					end
					local list = room:getAllPlayers()
					local target = room:askForPlayerChosen(player, list, self:objectName())
					local ai_data = sgs.QVariant()
					ai_data:setValue(player)
					local card = room:askForCard(target, ".junwei", "@junwei-show", ai_data, sgs.NonTrigger)
					if card then
						local show_id = card:getEffectiveId()
						room:showCard(target, show_id)
						local receiver = room:askForPlayerChosen(player, list, "junweigive")
						if receiver:objectName() ~= target:objectName() then
							receiver:obtainCard(card)
						end
					else
						room:loseHp(target, 1)
						if target:isAlive() then
							if target:hasEquip() then
								local card_id = room:askForCardChosen(player, target, "e", self:objectName())
								target:addToPile("junwei_equip", card_id)
							end
						end
					end
				end
			end
		end
		return false
	end
}
LuaJunweiGot = sgs.CreateTriggerSkill{
	name = "#LuaJunweiGot", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			local jw_equip = player:getPile("junwei_equip")
			if jw_equip:length() > 0 then
				local room = player:getRoom()
				for _,card_id in sgs.qlist(jw_equip) do
					local card = sgs.Sanguosha:getCard(card_id)
					local equip_index = -1
					local equip = card:getRealCard()
					if equip:isKindOf("Weapon") then
						equip_index = 0
					elseif equip:isKindOf("Armor") then
						equip_index = 1
					elseif equip:isKindOf("DefensiveHorse") then
						equip_index = 2
					elseif equip:isKindOf("OffensiveHorse") then
						equip_index = 3
					end
					local move1 = sgs.CardsMoveStruct()
					move1.card_ids:append(card_id)
					move1.to = player
					move1.to_place = sgs.Player_PlaceEquip
					move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName())
					local eqp = player:getEquip(equip_index)
					if eqp then
						local move2 = sgs.CardsMoveStruct()
						move2.card_ids:append(eqp:getId())
						move2.to = nil
						move2.to_place = sgs.Player_DiscardPile
						move2.reason = CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, player:objectName())
						room:moveCardsAtomic(move2, true)
					end
					room:moveCardsAtomic(move1, true)
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
	技能名：龙胆
	相关武将：标准·赵云、☆SP·赵云、翼·赵云
	描述：你可以将一张【杀】当【闪】，一张【闪】当【杀】使用或打出。
	状态：验证失败（currentRoomState错误，认为sgs.Sanguosha是nil）
]]--
LuaLongdan = sgs.CreateViewAsSkill{
	name = "LuaLongdan",
	n = 1,
	view_filter = function(self, selected, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local state = room:getRoomState()
		local reason = state:getCurrentCardUseReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return to_select:isKindOf("Jink")
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			local pattern = state:getCurrentCardUsePattern()
			if pattern == "slash" then
				return to_select:isKindOf("Jink")
			elseif pattern == "jink" then
				return to_select:isKindOf("Slash")
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			if card:isKindOf("Slash") then
				local jink = sgs.Sanguosha:cloneCard("jink", suit, point)
				jink:addSubcard(card)
				jink:setSkillName(self:objectName())
				return jink
			elseif card:isKindOf("Jink") then
				local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
				slash:addSubcard(card)
				slash:setSkillName(self:objectName())
				return slash
			end
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "jink") or (pattern == "slash")
	end
}
--[[
	技能名：龙魂
	相关武将：神·赵云
	描述：你可以将同花色的X张牌按下列规则使用或打出：红桃当【桃】，方块当具火焰伤害的【杀】，梅花当【闪】，黑桃当【无懈可击】（X为你当前的体力值且至少为1）。
	状态：验证失败（currentRoomState()结果为空值）
]]--
LuaLonghun = sgs.CreateViewAsSkill{
	name = "LuaLonghun", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		local hp = sgs.Self:getHp()
		local n = math.max(1, hp)
		if #selected < n then
			if n > 1 then
				if #selected > 0 then
					local suit = selected[1]:getSuit()
					return to_select:getSuit() == suit
				end
			end
			local state = sgs.Sanguosha:currentRoomState()
			local reason = state:getCurrentCardUseReason()
			if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
				if sgs.Self:isWounded() then
					return card:getSuit() == sgs.Card_Heart
				elseif sgs.Slash_IsAvailable(sgs.Self) then
					return card:getSuit() == sgs.Card_Diamond
				else
					return false
				end
			elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
				local pattern = state:getCurrentCardUsePattern()
				if pattern == "jink" then
					return card:getSuit() == sgs.Card_Club
				elseif pattern == "nullification" then
					return card:getSuit() == sgs.Card_Spade
				elseif pattern == "peach" or pattern == "peach+analeptic" then
					return card:getSuit() == sgs.Card_Heart
				elseif pattern == "slash" then
					return card:getSuit() == sgs.Card_Diamond
				end
			end
		end
		return false
	end, 
	view_as = function(self, cards)
		local hp = sgs.Self:getHp()
		local n = math.max(1, hp)
		if #cards == n then
			local card = cards[1]
			local new_card = nil
			local suit = card:getSuit()
			local number = 0
			if #cards == 1 then
				number = card:getNumber()
			end
			if suit == sgs.Card_Spade then
				new_card = sgs.Sanguosha:cloneCard("nullification", suit, number)
			elseif suit == sgs.Card_Heart then
				new_card = sgs.Sanguosha:cloneCard("each", suit, number)
			elseif suit == sgs.Card_Club then
				new_card = sgs.Sanguosha:cloneCard("jink", suit, number)
			elseif suit == sgs.Card_Diamond then
				new_card = sgs.Sanguosha:cloneCard("fire_slash", suit, number)
			end
			if new_card then
				new_card:setSkillName(self:objectName())
				for _,cd in pairs(cards) do
					new_card:addSubcard(cd)
				end
			end
			return new_card
		end
	end, 
	enabled_at_play = function(self, player)
		if player:isWounded() then
			return true
		elseif sgs.Slash_IsAvailable(player) then
			return true
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		if pattern == "slash" then
			return true
		elseif pattern == "jink" then
			return true
		elseif pattern:contains("peach") then
			return true
		elseif pattern == "nullification" then
			return true
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		local hp = player:getHp()
		local n = math.max(1, hp)
		local count = 0
		local cards = player:getHandcards()
		for _,card in sgs.qlist(cards) do
			if card:objectName() == "nullification" then
				return true
			end
			if card:getSuit() == sgs.Card_Spade then
				count = count + 1
			end
		end
		cards = player:getEquips()
		for _,card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Spade then
				count = count + 1
			end
		end
		return count >= n
	end
}
--[[
	技能名：龙魂
	相关武将：测试·高达一号
	描述：你可以将一张牌按以下规则使用或打出：♥当【桃】；♦当火【杀】；♠当【无懈可击】；♣当【闪】。回合开始阶段开始时，若其他角色的装备区内有【青釭剑】，你可以获得之。 
	状态：尚未验证
]]--
LuaXNosLonghun = sgs.CreateViewAsSkill{
	name = "LuaXNosLonghun", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if #selected < 1 then
			local state = sgs.Sanguosha:currentRoomState()
			local reason = state:getCurrentCardUseReason()
			local suit = to_select:getSuit()
			if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
				if sgs.Self:isWounded() then
					if suit == sgs.Card_Heart then
						return true
					end
				end
				if sgs.Slash_IsAvailable(sgs.Self) then
					if suit == sgs.Card_Diamond then
						local weapon = sgs.Self:getWeapon()
						if weapon and to_select:getEffectiveId() == weapon:getId() then
							if to_select:objectName() == "crossbow" then
								return sgs.Self:canSlashWithoutCrossbow()
							else
								return true
							end
						end
					else
						return false
					end
				end
			elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
				local pattern = state:getCurrentCardUsePattern()
				if pattern == "jink" then
					return suit == sgs.Card_Club
				elseif pattern == "nullification" then
					return suit == sgs.Card_Spade
				elseif pattern == "peach" or pattern == "peach+analeptic" then
					return suit == sgs.Card_Heart
				elseif pattern == "slash" then
					return suit == sgs.Card_Diamond
				end
			end
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local new_card = nil
			local suit = card:getSuit()
			local number = card:getNumber()
			if suit == sgs.Card_Spade then
				new_card = sgs.Sanguosha:cloneCard("nullification", suit, number)
			elseif suit == sgs.Card_Heart then
				new_card = sgs.Sanguosha:cloneCard("peach", suit, number)
			elseif suit == sgs.Card_Club then
				new_card = sgs.Sanguosha:cloneCard("jink", suit, number)
			elseif suit == sgs.Card_Diamond then
				new_card = sgs.Sanguosha:cloneCard("fire_slash", suit, number)
			end
			if new_card then
				new_card:setSkillName(self:objectName())
				new_card:addSubcard(card)
			end
			return new_card
		end
	end, 
	enabled_at_nullification = function(self, player)
		local cards = player:getHandcards()
		for _,card in sgs.qlist(cards) do
			if card:objectName() == "nullification" then
				return true
			end
			if card:getSuit() == sgs.Card_Spade then
				return true
			end
		end
		cards = player:getEquips()
		for _,card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Spade then
				return true
			end
		end
		return false
	end
}
LuaXDuojian = sgs.CreateTriggerSkill{
	name = "#LuaXDuojian",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local others = room:getOtherPlayers(player)
			for _,p in sgs.qlist(others) do
				local weapon = p:getWeapon()
				if weapon and weapon:objectName() == "QinggangSword" then
					if room:askForSkillInvoke(player, self:objectName()) then
						player:obtainCard(weapon)
					end
				end
			end
		end			
		return false	 
	end
}
--[[
	技能名：疠火
	相关武将：二将成名·程普
	描述：你可以将一张普通【杀】当火【杀】使用，若以此法使用的【杀】造成了伤害，在此【杀】结算后你失去1点体力；你使用火【杀】时，可以额外选择一个目标。
	状态：验证失败（不能选择额外的目标，不能流失体力）
]]--
LuaLihuoVS = sgs.CreateViewAsSkill{
	name = "LuaLihuoVS", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:objectName() == "slash"
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local number = card:getNumber()
			local id = card:getId()
			local acard = sgs.Sanguosha:cloneCard("fire_slash", suit, number)
			acard:addSubcard(id)
			acard:setSkillName(self:objectName())
			return acard
		end
	end, 
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
LuaLihuo = sgs.CreateTriggerSkill{
	name = "LuaLihuo",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageDone, sgs.CardFinished}, 
	view_as_skill = LuaLihuoVS, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageDone then
			local damage = data:toDamage()
			local card = damage.card
			if card then
				if card:isKindOf("Slash") then
					if card:getSkillName() == self:objectName() then
						room:setTag("Invokelihuo", sgs.QVariant(true))
					end
				end
			end
		elseif event == sgs.CardFinished then
			if player:hasSkill(self:objectName()) then
				local tag = room:getTag("Invokelihuo")
				if tag:toBool() then
					room:setTag("Invokelihuo", sgs.QVariant(false))
					room:loseHp(player, 1)
				end
			end
		end
		return false;
	end, 
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--[[
	技能名：落英
	相关武将：一将成名·曹植
	描述：当其他角色的梅花牌因弃置或判定而置入弃牌堆时，你可以获得之。
	状态：尚未验证（因为按位与操作无法验证）
]]--
require("bit")--按位操作所需库文件
LuaLuoying = sgs.CreateTriggerSkill{
	name = "LuaLuoying", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data) 
		local move = data:toMoveOneTime()
		local source = move.from
		if source then
			if source:objectName() ~= player:objectName() then
				if move.to_place == sgs.Player_DiscardPile then
					local reason = move.reason.m_reason
					local flag = false
					if bit.band(reason, sgs.CardMoveReason_S_MARK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
						flag = true
					end
					if reason == sgs.CardMoveReason_S_REASON_JUDGEDONE then
						flag = true
					end
					if flag then
						local luoyingMove = sgs.CardsMoveStruct()
						luoyingMove.to = player
						luoyingMove.to_place = sgs.Player_PlaceHand
						local ids = move.card_ids
						local places = move.from_places
						for i=0, ids:length()-1, 1 do
							local id = ids[i]
							local place = places[i]
							local suit = sgs.Sanguosha:getCard(id):getSuit()
							if suit == sgs.Card_Club then
								if place ~= sgs.Player_PlaceDelayedTrick then
									if place ~= sgs.Player_PlaceSpecial then
										if room:getCardPlace(id) == sgs.Player_DiscardPile then
											luoyingMove.card_ids:append(id)
										end
									end
								end
							end
						end
						if not luoyingMove.card_ids:empty() then
							if player:askForSkillInvoke(self:objectName(), data) then
								if luoyingMove.card_ids:length() > 1 then
									while (not luoyingMove.card_ids:isEmpty()) do
										room:fillAG(luoyingMove.card_ids, player)
										local card_id = room:askForAG(player, luoyingMove.card_ids, true, self:objectName())
										player:invoke("clearAG")
										if card_id == -1 then
											break
										end
										luoyingMove.card_ids:removeOne(card_id)
									end
									if luoyingMove.card_ids:empty() then
										return false
									end
								end
								room:moveCardsAtomic(luoyingMove, true)
							end
						end
					end
				end
			end
		end
		return false
	end, 
	priority = 4
}
--[[
	技能名：连理
	相关武将：倚天·夏侯涓
	描述：回合开始阶段开始时，你可以选择一名男性角色，你和其进入连理状态直到你的下回合开始：该角色可以帮你出闪，你可以帮其出杀 
	状态：验证失败
]]--
LuaXLianliCard = sgs.CreateSkillCard{
	name = "LuaXLianliCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return to_select:isMale()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		if source:getMark("@tied") == 0 then
			source:gainMark("@tied")
		end
		if target:getMark("@tied") == 0 then
			local players = room:getOtherPlayers(source)
			for _,player in sgs.qlist(players) do
				if player:getMark("@tied") > 0 then
					player:loseMark("@tied")
					break
				end
			end
			target:gainMark("@tied")
		end
	end
}
LuaXLianliStart = sgs.CreateTriggerSkill{
	name = "#LuaXLianliStart",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.GameStart},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local players = room:getOtherPlayers(player)
		for _,p in sgs.qlist(players) do
			if p:isMale() then
				room:attachSkillToPlayer(p, "LuaXLianliSlash")
			end
		end
	end
}
LuaXLianliSlashCard = sgs.CreateSkillCard{
	name = "LuaXLianliSlashCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return sgs.Self:canSlash(to_select)
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local room = source:getRoom()
		local dest = room:findPlayerBySkillName("LuaXLianli")
		if dest then
			local slash = room:askForCard(dest, "slash", "@lianli-slash")
			if slash then
				source:invoke("addHistory", "Slash")
				room:cardEffect(slash, source, effect.to)
				return
			end
		end
	end
}
LuaXLianliSlashVS = sgs.CreateViewAsSkill{
	name = "LuaXLianliSlash", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXLianliSlashCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:getMark("@tied") > 0 then
			return sgs.Slash_IsAvailable(player)
		end
		return false
	end
}
LuaXLianliSlash = sgs.CreateTriggerSkill{
	name = "#LuaXLianliSlash",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardAsked},  
	on_trigger = function(self, event, player, data) 
		local pattern = data:toString()
		if pattern == "slash" then
			if player:askForSkillInvoke("LuaLianliSlash", data) then
				local xiahoujuan = room:findPlayerBySkillName("LuaXLianli")
				if xiahoujuan then
					local slash = room:askForCard(xiahoujuan, "slash", "@lianli-slash")
					if slash then
						room:provide(slash)
						return true
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:getMark("@tied") > 0 then
				return not target:hasSkill("LuaXLianli")
			end
		end
		return false
	end
}
LuaXLianliJink = sgs.CreateTriggerSkill{
	name = "LuaXLianliJink",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardAsked},  
	on_trigger = function(self, event, player, data) 
		local pattern = data:toString()
		if pattern == "jink" then
			if player:askForSkillInvoke("LuaXLianliJink", data) then
				local players = room:getOtherPlayers(player)
				for _,p in sgs.qlist(players) do
					if p:getMark("@tied") > 0 then
						local jink = room:askForCard(p, "jink", "@lianli-jink")
						if jink then
							room:provide(jink)
							return true
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
			if target:hasSkill(self:objectName()) and target:isAlive() then
				return target:getMark("@tied") > 0
			end
		end
		return false
	end
}
LuaXLianliVS = sgs.CreateViewAsSkill{
	name = "LuaXLianliVS", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXLianliCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXLianli"
	end
}
LuaXLianli = sgs.CreateTriggerSkill{
	name = "LuaXLianli",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	view_as_skill = LuaXLianliVS, 
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local used = room:askForUseCard(player, "@@LuaXLianli", "@lianli-card")
			if used then
				local spouse = nil
				local alives = room:getAlivePlayers()
				for _,p in sgs.qlist(alives) do
					if p:getMark("@tied") > 0 then
						if p:objectName() ~= player:objectName() then
							spouse = p
							break
						end
					end
				end
				if spouse then
					local kingdom = spouse:getKingdom()
					if player:getKingdom() ~= kingdom then
						--离迁：当你处于连理状态时，势力与连理对象的势力相同
						room:setPlayerProperty(player, "kingdom", sgs.QVariant(kingdom)) 
					end
				end
			else
				if player:getKingdom() ~= "wei" then
					--离迁：当你处于未连理状态时，势力为魏 
					room:setPlayerProperty(player, "kingdom", sgs.QVariant("wei")) 
				end
				local players = room:getAllPlayers()
				for _,p in sgs.qlist(players) do
					if p:getMark("@tied") > 0 then
						p:loseMark("@tied")
					end
				end
			end
		end
		return false
	end
}
--离迁：清除效果
LuaXLiqianClear = sgs.CreateTriggerSkill{
	name = "#LuaXLiqianClear",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data) 
		if player then
			local players = room:getAllPlayers()
			for _,p in sgs.qlist(players) do
				if p:getMark("@tied") > 0 then
					p:loseMark("@tied")
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then 
			return target:hasSkill(self:objectName())
		end
		return false
	end
}
--[[
	技能名：秘计
	相关武将：二将成名·王异
	描述：回合开始/结束阶段开始时，若你已受伤，你可以进行一次判定，若判定结果为黑色，你观看牌堆顶的X张牌（X为你已损失的体力值），然后将这些牌交给一名角色。
	状态：验证失败（mid出错无法给牌）
]]--
LuaMiji = sgs.CreateTriggerSkill{
	name = "LuaMiji",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:isWounded() then
			local phase = player:getPhase()
			if phase == sgs.Player_Start or phase == sgs.Player_Finish then
				if player:askForSkillInvoke(self:objectName()) then
					local room = player:getRoom()
					local judge = sgs.JudgeStruct()
					judge.pattern = sgs.QRegExp("(.*):(club|spade):(.*)")
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then
						local x = player:getLostHp()
						player:drawCards(x)
						local playerlist = room:getAllPlayers()
						local target = room:askForPlayerChosen(player, playerlist, self:objectName())
						local count = player:getHandcardNum() - x
						local handcards = player:getHandcards()
						local miji_cards = handcards:mid(count)
						for _,card in sgs.qlist(miji_cards) do
							room:obtainCard(target, card, nil, false)
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：明哲
	相关武将：新3V3·诸葛瑾
	描述：你的回合外，当你因使用、打出或弃置而失去一张红色牌时，你可以摸一张牌。 
	状态：尚未验证
]]--
require "bit"
LuaXMingzhe = sgs.CreateTriggerSkill{
	name = "LuaXMingzhe",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() ~= sgs.Player_NotActive then
            return false
		end
        local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() then
			if event == sgs.BeforeCardsMove then
				local reason = move.reason
				local basic = bit.band(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
				local flag = (basic == sgs.CardMoveReason_S_REASON_USE)
				flag = flag or (basic == sgs.CardMoveReason_S_REASON_DISCARD)
				flag = flag or (basic == sgs.CardMoveReason_S_REASON_RESPONSE)
				if flag then
					local card
					local i = 0
					for _,card_id in sgs.qlist(move.card_ids) do
						card = sgs.Sanguosha:getCard(card_id)
						if card:isRed() then
							local places = move.from_places[i]
							if places == sgs.Player_PlaceHand or places == sgs.Player_PlaceEquip then
								player:addMark(self:objectName())
							end
						end
						i = i + 1
					end
				end
			else
				local count = player:getMark(self:objectName())
				for i=0, count, 1 do
					if player:askForSkillInvoke(self:objectName(), data) then
						player:drawCards(1)
					else
						break
					end
				end
				player:setMark(self:objectName(), 0)
			end
		end
        return false
	end
}
--[[
	技能名：神速
	相关武将：风·夏侯渊
	描述：你可以选择一至两项：1.跳过你的判定阶段和摸牌阶段。2.跳过你的出牌阶段并弃置一张装备牌。你每选择一项，视为对一名其他角色使用一张【杀】（无距离限制）。
	状态：验证失败（点击按钮发动技能时currentRoomState()为空，不点击按钮直接发动则能正常发动）
]]--
LuaShensuCard = sgs.CreateSkillCard{
	name = "LuaShensuCard", 
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
		use.to = targets
		room:useCard(use)
	end
}
LuaShensuVS = sgs.CreateViewAsSkill{
	name = "LuaShensuVS", 
	n = 1,
	view_filter = function(self, selected, to_select)
		local state = sgs.Sanguosha:currentRoomState()
		local pattern = state:getCurrentCardUsePattern()
		if not string.find(pattern, "1", string.len(pattern)) then
			if #selected == 0 then
				return to_select:isKindOf("EquipCard")
			end
		end
		return false
	end, 
	view_as = function(self, cards) 
		local state = sgs.Sanguosha:currentRoomState()
		local pattern = state:getCurrentCardUsePattern()
		if string.find(pattern, "1", string.len(pattern)) then
			if #cards == 0 then
				return LuaShensuCard:clone()
			end
		else
			if #cards == 1 then
				local card = LuaShensuCard:clone()
				card:addSubcard(cards[1])
				return card
			end
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@shensu") == 1
	end
}
LuaShensu = sgs.CreateTriggerSkill{
	name = "LuaShensu",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseChanging},  
	view_as_skill = LuaShensuVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local change = data:toPhaseChange()
		local nextphase = change.to
		if nextphase == sgs.Player_Judge then
			if not player:isSkipped(sgs.Player_Judge) then
				if not player:isSkipped(sgs.Player_Draw) then
					if room:askForUseCard(player, "@@shensu1", "@shensu1", 1) then
						player:skip(sgs.Player_Judge)
						player:skip(sgs.Player_Draw)
					end
				end
			end
		elseif nextphase == sgs.Player_Play then
			if not player:isSkipped(sgs.Player_Play) then
				if room:askForUseCard(player, "@@shensu2", "@shensu2", 2) then
					player:skip(sgs.Player_Play)
				end
			end
		end
		return false
	end
}
--[[
	技能名：探虎
	相关武将：☆SP·吕蒙
	描述：出牌阶段，你可以与一名其他角色拼点。若你赢，你获得以下技能直到回合结束：你与该角色的距离为1.你对该角色使用的非延时类锦囊不能被【无懈可击】抵消，每阶段限一次。
	状态：验证失败（可以拼点与锁定距离，但不能禁止无懈可击）
]]--
LuaTanhuCard = sgs.CreateSkillCard{
	name = "LuaTanhuCard", 
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
		local dest = targets[1]
		local success = source:pindian(dest, "tanhu", self)
		if success then
			room:setPlayerFlag(dest, "TanhuTarget")
			room:setFixedDistance(source, dest, 1)
		end
	end
}
LuaTanhu = sgs.CreateViewAsSkill{
	name = "LuaTanhu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if #cards == 1 then
			local newCard = LuaTanhuCard:clone()
			newCard:addSubcard(cards[1])
			return newCard
		end
	end, 
	enabled_at_play = function(self, player)
		if not player:hasUsed("#LuaTanhuCard") then
			return not player:isKongcheng()
		end
		return false
	end
}
LuaTanhuClear = sgs.CreateTriggerSkill{
	name = "#LuaTanhu", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			local players = room:getAlivePlayers()
			for _,p in sgs.qlist(players) do
				if p:hasFlag("TanhuTarget") then	
					room:setPlayerFlag(p, "-TanhuTarget")
					room:setFixedDistance(player, p, -1)
				end
			end
		end
		return false
	end
}
--[[
	技能名：伪帝（锁定技）
	相关武将：SP·袁术
	描述：你拥有当前主公的主公技。
	状态：验证失败（不能拥有主公技）
]]--
LuaWeidiCard = sgs.CreateSkillCard{
	name = "LuaWeidiCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		local lord = room:getLord()
		local choices = sgs.StringList()
		if source:hasLordSkill("jijiang") then
			if lord:hasLordSkill("jijiang") then
				if sgs.Slash_IsAvailable(source) then
					choices:append("jijiang")
				end
			end
		end
		if source:hasLordSkill("weidai") then
			if lord:hasLordSkill("weidai") then
				if sgs.Analeptic_IsAvailable(source) then
					choices:append("weidai")
				end
			end
		end
		if choices:length() > 0 then
			local choice = ""
			if choices:length() == 1 then
				choice = choices:first()
			else
				choice = room:askForChoice(source, "LuaWeidi", "jijiang+weidai")
			end
			if choice == "jijiang" then
				local targetlist = sgs.SPlayerList()
				local others = room:getOtherPlayers(source)
				for _,target in sgs.qlist(others) do
					if source:canSlash(target) then
						targetlist:append(target)
					end
				end
				local target = room:askForPlayerChosen(source, targetlist, "jijiang")
				if target then
					local jijiang = JijiangCard:clone()
					jijiang:setSkillName("LuaWeidi")
					local use = sgs.CardUseStruct()
					use.card = jijiang
					use.from = source
					use.to:append(target)
					room:useCard(use)
				end
			elseif choice == "weidai" then
				local weidai = WeidaiCard:clone()
				weidai:setSkillName("LuaWeidi")
				local use = sgs.CardUseStruct()
				use.card = weidai
				use.from = source
				room:useCard(use)
			end
		end
	end
}
LuaWeidiVS = sgs.CreateViewAsSkill{
	name = "LuaWeidiVS", 
	n = 0,
	view_as = function(self, cards) 
		return LuaWeidiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:hasLordSkill("jijiang") then
			if sgs.Slash_IsAvailable(player) then
				return true
			end
		end
		if player:hasLordSkill("weidai") then
			if sgs.Analeptic_IsAvailable(player) then
				return true
			end
		end
		return false
	end
}
LuaWeidi = sgs.CreateTriggerSkill{
	name = "LuaWeidi", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.GameStart}, 
	view_as_skill = LuaWeidiVS, 
	on_trigger = function(self, event, player, data) 
		-- do nothing --
		return false
	end
}
--[[
	技能名：武神（锁定技）
	相关武将：神·关羽
	描述：你的红桃手牌均视为【杀】；你使用红桃【杀】时无距离限制。
	状态：验证失败（slash为nil，无法视为武神杀）
]]--
LuaWushen = sgs.CreateFilterSkill{
	name = "LuaWushen",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local id = to_select:getEffectiveId()
		local place = room:getCardPlace(id)
		if to_select:getSuit() == sgs.Card_Heart then
			return place == sgs.Player_PlaceHand
		end
		return false
	end, 
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local slash = sgs.Sanguosha:cloneCard("wushen_slash", suit, point)
		slash:setSkillName(self:objectName())
		local id = card:getId()
		local vs_card = sgs.Sanguosha:getWrappedCard(id)
		vs_card:takeOver(slash)
		return vs_card
	end
}
--[[
	技能名：修罗
	相关武将：SP·暴怒战神
	描述：回合开始阶段开始时，你可以弃置一张手牌，若如此做，你弃置你判定区里的一张与你弃置手牌同花色的延时类锦囊牌。
	状态：验证失败（pattern构造出错）
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
			if player:askForSkillInvoke(self:objectName()) then
				local card_id = room:askForCardChosen(player, player, "j", self:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				local suit_str = card:getSuitString()
				local prompt = string.format("@xiuluo:::%s", suit_str)
				string.upper(suit_str)
				local suit = string.sub(suit_str, 1, 1)
				local pattern = string.format(".%s", suit)
				if room:askForCard(player, pattern, prompt, sgs.QVariant(), sgs.CardDiscarded) then
					room:throwCard(card, nil)
					once_success = true
				end
			end
		until ((player:getCards("j"):length() == 0) or once_success)
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
	技能名：狱刎（锁定技）
	相关武将：智·田丰
	描述：当你死亡时，凶手视为自己 
	状态：验证失败（有时不能视为自己）
]]--
LuaXYuwen = sgs.CreateTriggerSkill{
	name = "LuaXYuwen",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.GameOverJudge},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamageStar()
		if damage then
			if damage.from then
				if damage.from:objectName() == player:objectName() then
					return false
				end
			end
		else
			damage = sgs.DamageStruct()
			damage.to = player
			data:setValue(damage)
		end
		damage.from = player
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasSkill(self:objectName())
		end
		return false
	end, 
	priority = 3
}
--[[
	技能名：援护
	相关武将：SP·曹洪
	描述：回合结束阶段开始时，你可以将一张装备牌置于一名角色的装备区里，然后根据此装备牌的种类执行以下效果。
		武器牌：弃置与该角色距离为1的一名角色区域中的一张牌；
		防具牌：该角色摸一张牌；
		坐骑牌：该角色回复一点体力。
	状态：验证失败（各装备类型效果可实现，但技能卡的filter部分有问题导致装备区有同类装备时仍可发动技能）
]]--
LuaYuanhuCard = sgs.CreateSkillCard{
	name = "LuaYuanhuCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			local id = self:getSubcards():first()
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("Weapon") then
				return not to_select:getEquip(0)
			elseif card:isKindOf("Armor") then
				return not to_select:getEquip(1)
			elseif card:isKindOf("DefensiveHorse") then
				return not to_select:getEquip(2)
			elseif card:isKindOf("OffensiveHorse") then
				return not to_select:getEquip(3)
			end
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "LuaYuanhu", "")
		room:moveCardTo(self, source, target, sgs.Player_PlaceEquip, reason)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if card:isKindOf("Weapon") then
			local targets = sgs.SPlayerList()
			local allplayers = room:getAllPlayers()
			for _,p in sgs.qlist(allplayers) do
				if target:distanceTo(p) == 1 then
					if not p:isAllNude() then
						targets:append(p)
					end
				end
			end
			if not targets:isEmpty() then
				local to_dismantle = room:askForPlayerChosen(source, targets, "LuaYuanhu")
				local card_id = room:askForCardChosen(source, to_dismantle, "hej", "LuaYuanhu")
				local to_throw = sgs.Sanguosha:getCard(card_id)
				room:throwCard(to_throw, to_dismantle, source)
			end
		elseif card:isKindOf("Armor") then
			target:drawCards(1)
		elseif card:isKindOf("Horse") then
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(target, recover)
		end
	end
}
LuaYuanhuVS = sgs.CreateViewAsSkill{
	name = "LuaYuanhuVS", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local first = LuaYuanhuCard:clone()
			first:addSubcard(cards[1]:getId())
			first:setSkillName(self:objectName())
			return first
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaYuanhu"
	end
}
LuaYuanhu = sgs.CreateTriggerSkill{
	name = "LuaYuanhu", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = LuaYuanhuVS, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if not player:isNude() then
				room:askForUseCard(player, "@@LuaYuanhu", "@yuanhu-equip")
			end
		end
		return false
	end
}
