--[[
	代码速查手册（K区）
	技能索引：
		看破、慷忾、克构、克己、空城、苦肉、狂暴、狂风、狂斧、狂骨、狂骨、溃围
]]--
--[[
	技能名：看破
	相关武将：火·诸葛亮
	描述：你可以将一张黑色手牌当【无懈可击】使用。
	引用：LuaKanpo
	状态：0610验证通过
]]--
LuaKanpo = sgs.CreateViewAsSkill{
	name = "LuaKanpo",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack() and (not to_select:isEquipped())
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local first = cards[1]
			local ncard = sgs.Sanguosha:cloneCard("nullification", first:getSuit(), first:getNumber())
			ncard:addSubcard(first)
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
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:isBlack() then return true end
		end
		return false
	end
}
--[[
	技能名：慷忾
	相关武将：SP·曹昂
	描述：每当一名距离1以内的角色成为【杀】的目标后，你可以摸一张牌，然后正面朝上交给该角色一张牌：若该牌为装备牌，该角色可以使用之。 
]]--
--[[
	技能名：克构（觉醒技）
	相关武将：倚天·陆抗
	描述：回合开始阶段开始时，若你是除主公外唯一的吴势力角色，你须减少1点体力上限并获得技能“连营”
	引用：LuaKegou
	状态：1217验证通过
]]--
LuaKegou = sgs.CreateTriggerSkill{
	name = "LuaKegou" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		for _, _player in sgs.qlist(player:getSiblings()) do
			if _player:isAlive() and (_player:getKingdom() == "wu")
					and (not _player:isLord()) and (_player:objectName() ~= player:objectName()) then
				return false
			end
		end
		player:setMark("LuaKegou", 1)
		local room = player:getRoom()
		player:gainMark("@waked")
		room:loseMaxHp(player)
		room:acquireSkill(player, "lianying")
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName())
				and (target:getPhase() == sgs.Player_Start)
				and (target:getMark("LuaKegou") == 0)
				and (target:getKingdom() == "wu")
				and (not target:isLord())
	end
}
--[[
	技能名：克己
	相关武将：标准·吕蒙
	描述：若你于出牌阶段未使用或打出过【杀】，你可以跳过此回合的弃牌阶段。
	引用：LuaKeji
	状态：0610验证通过
]]--
LuaKeji = sgs.CreateTriggerSkill{
	name = "LuaKeji" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Discard then
			if not player:hasFlag("Global_SlashInPlayPhase") then
				if player:askForSkillInvoke(self:objectName()) then
					player:skip(sgs.Player_Discard)
				end
			end
		end
		return false
	end
}
--[[
	技能名：空城（锁定技）
	相关武将：标准·诸葛亮、测试·五星诸葛
	描述：若你没有手牌，你不能被选择为【杀】或【决斗】的目标。
	引用：LuaKongcheng
	状态：1217验证通过
]]--
LuaKongcheng = sgs.CreateProhibitSkill{
	name = "LuaKongcheng",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Slash") or card:isKindOf("Duel")) and to:isKongcheng()
	end
}
--[[
	技能名：苦肉
	相关武将：标准·黄盖、SP·台版黄盖
	描述：出牌阶段，你可以失去1点体力，然后摸两张牌。
	引用：LuaKurou
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
	引用：LuaKuangbao、LuaWrath2、LuaKuangbaoClear
	状态：1217验证通过
]]--
LuaKuangbao = sgs.CreateTriggerSkill{
	name = "LuaKuangbao" ,
	events = {sgs.Damage, sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		player:getRoom():addPlayerMark(player,"@wrath",damage.damage)
	end
}
LuaWrath2 = sgs.CreateTriggerSkill{
	name = "#@wrath-Lua-2" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		player:getRoom():addPlayerMark(player,"@wrath",2)
	end
}
LuaKuangbaoClear = sgs.CreateTriggerSkill{
	name = "LuaKuangbao-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaKuangbao" then
			player:loseAllMarks("@wrath")
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：狂风
	相关武将：神·诸葛亮
	描述：结束阶段开始时，你可以将一张“星”置入弃牌堆并选择一名角色，若如此做，你的下回合开始前，每当其受到的火焰伤害结算开始时，此伤害+1。
	引用：LuaKuangfeng
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
	name = "LuaKuangfeng",
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
	引用：LuaKuangfu
	状态：1217验证通过
]]--
LuaKuangfu = sgs.CreateTriggerSkill{
	name = "LuaKuangfu" ,
	events = {sgs.Damage} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local target = damage.to
		if damage.card and damage.card:isKindOf("Slash") and target:hasEquip() and (not damage.chain) and (not damage.transfer) then
			local equiplist = {}
			for i = 0, 3, 1 do
				if not target:getEquip(i) then continue end
				if player:canDiscard(target, target:getEquip(i):getEffectiveId()) or (player:getEquip(i) == nil) then
					table.insert(equiplist,tostring(i))
				end
			end
			if #equiplist == nil then return false end
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			local _data = sgs.QVariant()
			_data:setValue(target)
			local room = player:getRoom()
			local equip_index = tonumber(room:askForChoice(player, "LuaKuangfu_equip", table.concat(equiplist, "+"), _data))
			local card = target:getEquip(equip_index)
			local card_id = card:getEffectiveId()
			local choicelist = {}
			if player:canDiscard(target, card_id) then
				table.insert(choicelist, "throw")
			end
			if (equip_index > -1) and (player:getEquip(equip_index) == nil) then
				table.insert(choicelist, "move")
			end
			local choice = room:askForChoice(player, "LuaKuangfu", table.concat(choicelist, "+"))
			if choice == "move" then
				room:moveCardTo(card, player, sgs.Player_PlaceEquip)
			else
				room:throwCard(card, target, player)
			end
		end
		return false
	end
}
--[[
	技能名：狂骨（锁定技）
	相关武将：风·魏延
	描述：每当你对距离1以内的一名角色造成1点伤害后，你回复1点体力。
	引用：LuaKuanggu
	状态：0610验证通过
]]--
LuaKuanggu = sgs.CreateTriggerSkill{
	name = "LuaKuanggu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage, sgs.PreDamageDone},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if (event == sgs.PreDamageDone) and damage.from and damage.from:hasSkill(self:objectName()) and damage.from:isAlive() then
			local weiyan = damage.from
			weiyan:setTag("invokeLuaKuanggu", sgs.QVariant((weiyan:distanceTo(damage.to) <= 1)))
		elseif (event == sgs.Damage) and player:hasSkill(self:objectName()) and player:isAlive() then
			local invoke = player:getTag("invokeLuaKuanggu"):toBool()
			player:setTag("invokeLuaKuanggu", sgs.QVariant(false))
			if invoke and player:isWounded() then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = damage.damage
				room:recover(player, recover)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：狂骨·1V1
	相关武将：1v1·魏延
	描述：每当你造成伤害后，你可以进行判定：若结果为黑色，你回复1点体力。
	引用：LuaKOFKuanggu
	状态：1217验证通过
]]--
LuaKOFKuanggu = sgs.CreateTriggerSkill{
	name = "LuaKOFKuanggu",
	events = {sgs.Damage},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player,self:objectName(),data) then
		local judge = sgs.JudgeStruct()
			judge.pattern = ".|black"
			judge.who = player
			judge.reason = self:objectName()
			room:judge(judge)
		if judge:isGood() and player:isWounded() then
			local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			end
		end
	end
}
--[[
	技能名：溃围
	相关武将：☆SP·曹仁
	描述：结束阶段开始时，你可以摸X+2张牌，然后将你的武将牌翻面，且你的下个摸牌阶段开始时，你弃置X张牌。（X为当前场上武器牌的数量）
	引用：LuaKuiwei
	状态：1217验证通过
]]--
getWeaponCountKuiwei = function(caoren)
	local n = 0
	for _, p in sgs.qlist(caoren:getRoom():getAlivePlayers()) do
		if p:getWeapon() then n = n + 1 end
	end
	return n
end
LuaKuiwei = sgs.CreateTriggerSkill{
	name = "LuaKuiwei" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			if not player:hasSkill(self:objectName()) then return false end
			if not player:askForSkillInvoke(self:objectName()) then return false end
			local n = getWeaponCountKuiwei(player)
			player:drawCards(n + 2)
			player:turnOver()
			if player:getMark("@kuiwei") == 0 then
				player:getRoom():addPlayerMark(player, "@kuiwei")
			end
		elseif player:getPhase() == sgs.Player_Draw then
			if player:getMark("@kuiwei") == 0 then return false end
			local room = player:getRoom()
			room:removePlayerMark(player, "@kuiwei")
			local n = getWeaponCountKuiwei(player)
			if n > 0 then
				room:askForDiscard(player, self:objectName(), n, n, false, true)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and (target:hasSkill(self:objectName()) or (target:getMark("@kuiwei") > 0))
	end
}
