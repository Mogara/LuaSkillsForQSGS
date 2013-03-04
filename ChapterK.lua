--[[
	代码速查手册（K区）
	技能索引：
		看破、克构、克己、空城、苦肉、狂暴、狂风、狂斧、狂骨、溃围
]]--
--[[
	技能名：看破
	相关武将：火·诸葛亮
	描述：你可以将一张黑色手牌当【无懈可击】使用。
	状态：验证通过
]]--
LuaKanpo = sgs.CreateViewAsSkill{
	name = "LuaKanpo", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if to_select:isBlack() then
			return not to_select:isEquipped()
		end
		return false
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
		return pattern == "nullification"
	end,
	enabled_at_nullification = function(self, player)
		local handcards = player:getHandcards()
		for _,card in sgs.qlist(handcards) do
			if card:isBlack() then
				return true
			end
			if card:objectName() == "nullification" then
				return true
			end
		end
		return false
	end
}
--[[
	技能名：克构（觉醒技）
	相关武将：倚天·陆抗
	描述：回合开始阶段开始时，若你是除主公外唯一的吴势力角色，你须减少1点体力上限并获得技能“连营” 
	状态：验证通过
]]--
LuaXKegou = sgs.CreateTriggerSkill{
	name = "LuaXKegou",  
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		local siblings = player:getSiblings()
		for _,p in sgs.qlist(siblings) do
			if p:isAlive() then
				if p:getKingdom() == "wu" then
					if not p:isLord() then
						if p:objectName() ~= player:objectName() then
							return false
						end
					end
				end
			end
		end
		player:setMark("kegou", 1)
		local room = player:getRoom()
		room:loseMaxHp(player)
		room:acquireSkill(player, "lianying")
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start then
					if target:getMark("kegou") == 0 then
						if target:getKingdom() == "wu" then
							return not target:isLord()
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：克己
	相关武将：标准·吕蒙
	描述：若你于出牌阶段未使用或打出过【杀】，你可以跳过此回合的弃牌阶段。
	状态：验证通过
]]--
LuaKeji = sgs.CreateTriggerSkill{
	name = "LuaKeji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging, sgs.CardResponsed},
	on_trigger = function(self, event, player, data)
		if event == sgs.CardResponsed then
			local phase = player:getPhase()
			if phase == sgs.Player_Play then
				local card = data:toResponsed().m_card
				if card:isKindOf("Slash") then
					player:setFlags("keji_use_slash")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_Discard then
				if not player:hasFlag("keji_use_slash") then
					if player:getSlashCount() == 0 then
						if player:askForSkillInvoke(self:objectName()) then
							player:skip(sgs.Player_Discard)
						end
					end
				end
			end
		end
		return false;
	end
}
--[[
	技能名：空城（锁定技）
	相关武将：标准·诸葛亮、测试·五星诸葛
	描述：若你没有手牌，你不能被选择为【杀】或【决斗】的目标。
	状态：验证通过
]]--
LuaKongcheng = sgs.CreateProhibitSkill{
	name = "LuaKongcheng",
	is_prohibited = function(self, from, to, card)
		if to:hasSkill(self:objectName()) then
			if to:isKongcheng() then
				return card:isKindOf("Slash") or card:isKindOf("Duel")
			end
		end
	end,
}
--[[
	技能名：苦肉
	相关武将：标准·黄盖
	描述：出牌阶段，你可以失去1点体力，然后摸两张牌。
	状态：验证通过
]]--
KurouCard = sgs.CreateSkillCard{
	name = "KurouCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
		room:loseHp(player, 1)
		if player:isAlive() then
			room:drawCards(player, 2)
		end
	end
}
LuaKurou = sgs.CreateViewAsSkill{
	name = "LuaKurou",
	n = 0,
	view_as = function(self, cards)
		return KurouCard:clone()
	end,
}
--[[
	技能名：狂暴（锁定技）
	相关武将：神·吕布
	描述：游戏开始时，你获得2枚“暴怒”标记；每当你造成或受到1点伤害后，你获得1枚“暴怒”标记。
	状态：验证通过
]]--
LuaKuangbao = sgs.CreateTriggerSkill{
	name = "LuaKuangbao", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.GameStart, sgs.Damage, sgs.Damaged},   
	on_trigger = function(self, event, player, data) 
		if event == sgs.GameStart then
			player:gainMark("@wrath", 2)
		else
			local damage = data:toDamage()
			local count = damage.damage
			player:gainMark("@wrath", count)
		end
		return false
	end
}
--[[
	技能名：狂风
	相关武将：神·诸葛亮
	描述：回合结束阶段开始时，你可以将一张“星”置入弃牌堆并选择一名角色，若如此做，每当该角色受到的火焰伤害结算开始时，此伤害+1，直到你的下回合开始。
	状态：验证通过
]]--
LuaKuangfengCard = sgs.CreateSkillCard{
	name = "LuaKuangfengCard", 
	target_fixed = true, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local dest = targets[1]
		local stars = source:getPile("stars")
		room:fillAG(stars, source)
		local card_id = room:askForAG(source, stars, false, "qixing-discard")
		source:invoke("clearAG")
		stars:removeOne(card_id)
		local card = sgs.Sanguosha:getCard(card_id)
		room:throwCard(card, nil, nil)
		dest:gainMark("@gale")
	end
}
LuaKuangfengVS = sgs.CreateViewAsSkill{
	name = "LuaKuangfengVS", 
	n = 0,
	view_as = function(self, cards)
		return LuaKuangfengCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@kuangfeng"
	end
}
LuaKuangfeng = sgs.CreateTriggerSkill{
	name = "LuaKuangfeng", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.DamageForseen},
	view_as_skill = LuaKuangfengVS, 
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.nature == sgs.DamageStruct_Fire then
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:getMark("@gale") > 0
		end
		return false
	end
}
--[[
	技能名：狂斧
	相关武将：国战·潘凤
	描述：每当你使用的【杀】对一名角色造成一次伤害后，你可以将其装备区里的一张牌弃置或置入你的装备区。 
	状态：尚未完成
]]--
--[[
	技能名：狂骨（锁定技）
	相关武将：风·魏延
	描述：每当你对距离1以内的一名角色造成1点伤害后，你回复1点体力。
	状态：验证通过
]]--
LuaKuanggu = sgs.CreateTriggerSkill{
	name = "LuaKuanggu",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damage, sgs.PreHpReduced},
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local source = damage.from
		local victim = damage.to
		local count = damage.damage
		local room = player:getRoom()
		if event == sgs.PreHpReduced then
			if source then
				if source:hasSkill(self:objectName()) then
					local dist = source:distanceTo(victim)
					local value = sgs.QVariant(dist<=1)
					room:setTag("InvokeKuanggu", value)
				end
			end
		elseif event == sgs.Damage then
			if player:hasSkill(self:objectName()) then
				local tag = room:getTag("InvokeKuanggu")
				local invoke = tag:toBool()
				room:setTag("InvokeKuanggu", sgs.QVariant(false))
				if invoke then
					if player:isWounded() then
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.recover = count
						room:recover(player, recover)
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
--[[
	技能名：溃围
	相关武将：☆SP·曹仁
	描述：回合结束阶段开始时，你可以摸2+X张牌，然后将你的武将牌翻面。在你的下个摸牌阶段开始时，你须弃置X张牌。X等于当时场上装备区内的武器牌的数量。
	状态：验证通过
]]--
LuaKuiwei = sgs.CreateTriggerSkill{
	name = "LuaKuiwei", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data) 
		local phase = player:getPhase()
		local weaponCount = 0
		local room = player:getRoom()
		if phase == sgs.Player_Finish then
			weaponCount = 0
			if player:hasSkill(self:objectName()) then
				if player:askForSkillInvoke(self:objectName()) then
					local list = room:getAlivePlayers()
					for _,p in sgs.qlist(list) do
						if p:getWeapon() then
							weaponCount = weaponCount + 1
						end
					end
					player:drawCards(weaponCount+2)
					player:turnOver()
					if player:getMark("@kuiwei") == 0 then
						player:gainMark("@kuiwei")
					end
				end
			end
		elseif phase == sgs.Player_Draw then
			weaponCount = 0
			if player:getMark("@kuiwei") > 0 then
				local list = room:getAlivePlayers()
				for _,p in sgs.qlist(list) do
					if p:getWeapon() then
						weaponCount = weaponCount + 1
					end
				end
				if weaponCount > 0 then
					local cards = player:getCards("he")
					if cards:length() <= weaponCount then
						player:throwAllHandCardsAndEquips()
					else
						room:askForDiscard(player, self:objectName(), weaponCount, weaponCount, false, true);
					end
					player:loseMark("@kuiwei")
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() then
				if target:hasSkill(self:objectName()) then
					return true
				elseif target:getMark("@kuiwei") > 0 then
					return true
				end
			end
		end
	end, 
	priority = 3
}