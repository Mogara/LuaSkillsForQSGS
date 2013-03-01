--[[
	代码速查手册（C区）
	技能索引：
		藏匿、超级观星、称象、冲阵、筹粮、持重、醇醪、聪慧
]]--
--[[
	技能名：藏匿
	相关武将：铜雀台·伏皇后
	描述：弃牌阶段开始时，你可以回复1点体力或摸两张牌，然后将你的武将牌翻面；其他角色的回合内，当你获得（每回合限一次）/失去一次牌时，若你的武将牌背面朝上，你可以令该角色摸/弃置一张牌。 
	状态：验证通过
]]--
LuaXCangni = sgs.CreateTriggerSkill{
	name = "LuaXCangni",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				if player:askForSkillInvoke(self:objectName()) then
					local choices = "draw"
					local size = 1
					if player:isWounded() then
						choices = "draw+recover"
						size = 2
					end
					local choice
					if size == 1 then
						choice = choices
					else
						choice = room:askForChoice(player, self:objectName(), choices)
					end
					if choice == "recover" then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
					else
						player:drawCards(2)
					end
					player:turnOver()
					return false
				end
			end
		end
		if event == sgs.CardsMoveOneTime then
			if not player:faceUp() then
				if player:getPhase() == sgs.Player_NotActive then
					local move = data:toMoveOneTime()
					local target = room:getCurrent()
					if not target:isDead() then
						local source = move.from
						local dest = move.to
						if source and source:objectName() == player:objectName() then
							if not dest or dest:objectName() ~= player:objectName() then
								local invoke = false
								local size = move.card_ids:length()
								for i=0, size-1, 1 do
									if move.from_places:at(i) == sgs.Player_PlaceHand then
										invoke = true
										break
									end
									if move.from_places:at(i) == sgs.Player_PlaceEquip then
										invoke = true
										break
									end
								end
								room:setPlayerFlag(player, "cangnilose")
								if invoke and not target:isNude() then
									if player:askForSkillInvoke(self:objectName()) then
										room:askForDiscard(target, self:objectName(), 1, 1, false, true)
									end
								end
								room:setPlayerFlag(player, "-cangnilose")
								return false
							end
						end
						if dest and dest:objectName() == player:objectName() then
							if not source or source:objectName() ~= player:objectName() then
								if move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip then
									room:setPlayerFlag(player, "cangniget")
									if not target:hasFlag("cangni_used") then
										if player:askForSkillInvoke(self:objectName()) then
											room:setPlayerFlag(target, "cangni_used")
											target:drawCards(1)
										end
									end
									room:setPlayerFlag(player, "-cangniget")
								end
							end
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：超级观星
	相关武将：测试·五星诸葛
	描述：回合开始阶段，你可以观看牌堆顶的5张牌，将其中任意数量的牌以任意顺序置于牌堆顶，其余则以任意顺序置于牌堆底 
	状态：验证通过
]]--
LuaXSuperGuanxing = sgs.CreateTriggerSkill{
	name = "LuaXSuperGuanxing",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Start then
			if player:askForSkillInvoke(self:objectName()) then
				local room = player:getRoom()
				local stars = room:getNCards(5, false)
				room:askForGuanxing(player, stars, false)
			end
		end
		return false
	end
}
--[[
	技能名：冲阵
	相关武将：☆SP·赵云
	描述：每当你发动“龙胆”使用或打出一张手牌时，你可以立即获得对方的一张手牌。
	状态：验证通过
]]--
LuaChongzhen = sgs.CreateTriggerSkill{
	name = "LuaChongzhen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardResponsed, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponsed then
			local resp = data:toResponsed()
			local dest = resp.m_who
			local card = resp.m_card
			if card:getSkillName() == "longdan" then
				if dest and not dest:isKongcheng() then
					local ai_data = sgs.QVariant()
					ai_data:setValue(dest)
					if player:askForSkillInvoke(self:objectName(), ai_data) then
						card_id = room:askForCardChosen(player, dest, "h", self:objectName())
						local destcard = sgs.Sanguosha:getCard(card_id)
						room:obtainCard(player, destcard)
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from:objectName() == player:objectName() then
				if use.card:getSkillName() == "longdan" then
					local targets = use.to
					for _,dest in sgs.qlist(targets) do
						if not dest:isKongcheng() then
							local ai_data = sgs.QVariant()
							ai_data:setValue(dest)
							if player:askForSkillInvoke(self:objectName(), ai_data) then
								local card_id = room:askForCardChosen(player, dest, "h", self:objectName())
								local destcard = sgs.Sanguosha:getCard(card_id)
								room:obtainCard(player, destcard)
							end
						end
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
	技能名：醇醪
	相关武将：二将成名·程普
	描述：回合结束阶段开始时，若你的武将牌上没有牌，你可以将任意数量的【杀】置于你的武将牌上，称为“醇”；当一名角色处于濒死状态时，你可以将一张“醇”置入弃牌堆，视为该角色使用一张【酒】。
	状态：验证通过
]]--
LuaChunlaoCard = sgs.CreateSkillCard{
	name = "LuaChunlaoCard", 
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local ids = self.subcards
		for _,id in sgs.qlist(ids) do
			source:addToPile("wine", id, true)
		end
	end
}
LuaChunlaoVS = sgs.CreateViewAsSkill{
	name = "LuaChunlaoVS", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash")
	end, 
	view_as = function(self, cards)
		if #cards > 0 then
			local acard = LuaChunlaoCard:clone()
			for _,card in pairs(cards) do
				acard:addSubcard(card)
			end
			acard:setSkillName(self:objectName())
			return acard
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@chunlao"
	end
}
LuaChunlao = sgs.CreateTriggerSkill{
	name = "LuaChunlao", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart, sgs.AskForPeaches},
	view_as_skill = LuaChunlaoVS, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if not player:isKongcheng() then
					if player:getPile("wine"):length() == 0 then
						room:askForUseCard(player, "@@chunlao", "@chunlao")
					end
				end
			end
		elseif event == sgs.AskForPeaches then
			local wines = player:getPile("wine")
			if wines:length() > 0 then
				local dying = data:toDying()
				local dest = dying.who
				while (dest:getHp() < 1) do
					if player:askForSkillInvoke(self:objectName(), data) then
						room:fillAG(wines, player)
						local card_id = room:askForAG(player, wines, true, self:objectName())
						room:broadcastInvoke("clearAG")
						if card_id ~= -1 then
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
							local card = sgs.Sanguosha:getCard(card_id)
							room:throwCard(card, reason, nil)
							local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
							analeptic:setSkillName(self:objectName())
							local use = sgs.CardUseStruct()
							use.card = analeptic
							use.from = dest
							use.to:append(dest)
							room:useCard(use)
						end
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
	技能名：筹粮
	相关武将：智·蒋琬
	描述：回合结束阶段开始时，若你手牌少于三张，你可以从牌堆顶亮出X张牌（X为4减当前手牌数），拿走其中的基本牌，把其余的牌置入弃牌堆 
	状态：验证通过
]]--
LuaXChouliang = sgs.CreateTriggerSkill{
	name = "LuaXChouliang",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},   
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local handcardnum = player:getHandcardNum()
		if player:getPhase() == sgs.Player_Finish then
			if handcardnum < 3 then
				if room:askForSkillInvoke(player, self:objectName()) then
					for i=1, 4-handcardnum, 1 do
						local card_id = room:drawCard()
						local card = sgs.Sanguosha:getCard(card_id)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, player:objectName(), "", self:objectName(), "")
						room:moveCardTo(card, player, sgs.Player_PlaceTable, reason, true)
						room:getThread():delay()
						if not card:isKindOf("BasicCard") then
							room:throwCard(card_id, nil)
							room:setEmotion(player, "bad")
						else
							room:obtainCard(player, card_id)
							room:setEmotion(player, "good")
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：持重（锁定技）
	相关武将：铜雀台·伏完
	描述：你的手牌上限等于你的体力上限；其他角色死亡时，你加1点体力上限。 
	状态：验证通过
]]--
LuaXChizhongKeep = sgs.CreateMaxCardsSkill{
	name = "LuaXChizhong", 
	extra_func = function(self, target) 
		if target:hasSkill(self:objectName()) then
			return target:getLostHp()
		end
	end
}
LuaXChizhong = sgs.CreateTriggerSkill{
	name = "#LuaXChizhong",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if splayer then
			if event == sgs.Death then
				if player:objectName() ~= splayer:objectName() then
					local maxhp = splayer:getMaxHp() + 1
					room:setPlayerProperty(splayer, "maxhp", sgs.QVariant(maxhp))
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：聪慧（锁定技）
	相关武将：倚天·曹冲
	描述：你将永远跳过你的弃牌阶段 
	状态：验证通过
]]--
LuaXConghui = sgs.CreateTriggerSkill{
	name = "LuaXConghui",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseChanging},  
	on_trigger = function(self, event, player, data) 
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Discard then
			if not player:isSkipped(sgs.Player_Discard) then
				player:skip(sgs.Player_Discard)
			end
		end
		return false
	end
}