--[[
	代码速查手册（W区）
	技能索引：
		完杀、婉容、忘隙、妄尊、危殆、威重、围堰、帷幕、伪帝、温酒、无谋、无前、无双、无言、无言、五灵、武魂、武继、武神、武圣
]]--
--[[
	技能名：完杀（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。
	引用：LuaWansha
	状态：0405验证失败
]]--

--[[
	技能名：婉容
	相关武将：1v1·大乔
	描述：每当你成为【杀】的目标后，你可以摸一张牌。  
	引用：LuaWanrong
	状态：0405验证通过
]]--
LuaWanrong = sgs.CreateTriggerSkill{
	name = "LuaWanrong",
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.to:contains(player) and player:getRoom():askForSkillInvoke(player, self:objectName(), data) then
			player:drawCards(1, self:objectName())
		end
		return false
	end
}
--[[
	技能名：忘隙
	相关武将：势·李典
	描述：每当你对一名其他角色造成1点伤害后，或你受到其他角色造成的1点伤害后，若该角色存活，你可以与其各摸一张牌。
	引用：LuaWangxi
	状态：1217验证通过
]]--
LuaWangxi = sgs.CreateTriggerSkill{
	name = "LuaWangxi" ,
	events = {sgs.Damage,sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local target = nil
		if event == sgs.Damage then
			target = damage.to
		else
			target = damage.from
		end
		if not target or target:objectName() == player:objectName() then return false end
		local players = sgs.SPlayerList()
			players:append(player)
			players:append(target)
			room:sortByActionOrder(players)
		for i = 1, damage.damage, 1 do
			if not target:isAlive() or not player:isAlive() then return false end
			local value = sgs.QVariant()
				value:setValue(target)
			if room:askForSkillInvoke(player,self:objectName(),value) then
				room:drawCards(players,1,self:objectName())
			end
		end
	end
}
--[[
	技能名：妄尊
	相关武将：标准·袁术
	描述：主公的准备阶段开始时，你可以摸一张牌，然后主公本回合手牌上限-1。
	引用：LuaWangzun、LuaWangzunMaxCards
	状态：1217验证通过
]]--
LuaWangzun = sgs.CreatePhaseChangeSkill{
	name = "LuaWangzun" ,
	on_phasechange = function(self, target)
		local room = target:getRoom()
		local mode = room:getMode()
		if mode:endsWith("p") or mode:endsWith("pd") or mode:endsWith("pz") then
			if target:isLord() and target:getPhase() == sgs.Player_Start then
				local yuanshu = room:findPlayerBySkillName(self:objectName())
				if yuanshu and room:askForSkillInvoke(yuanshu, self:objectName()) then
					yuanshu:drawCards(1)
					room:setPlayerFlag(target, "LuaWangzunDecMaxCards")
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
LuaWangzunMaxCards = sgs.CreateMaxCardsSkill{
	name = "#LuaWangzunMaxCards" ,
	extra_func = function(self, target)
		if target:hasFlag("LuaWangzunDecMaxCards") then
			return -1
		else
			return 0
		end
	end
}
--[[
	技能名：威重（锁定技）
	相关武将：SP·诸葛诞
	描述：每当你的体力上限改变后，你摸一张牌。
	引用：LuaWeizhong
	状态：0405验证通过
]]--
LuaWeiZhong = sgs.CreateTriggerSkill{
	name = "LuaWeiZhong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.MaxHpChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName(), player)
        room:sendCompulsoryTriggerLog(player, self:objectName())
		player:drawCards(1, self:objectName())
	end
}
--[[
	技能名：危殆（主公技）
	相关武将：智·孙策
	描述：当你需要使用一张【酒】时，所有吴势力角色按行动顺序依次选择是否打出一张黑桃2~9的手牌，视为你使用了一张【酒】，直到有一名角色或没有任何角色决定如此做时为止
	引用：LuaWeidai
	状态：1217验证通过
]]--
hasWuGenerals = function(player)
	for _, p in sgs.qlist(player:getSiblings()) do
		if p:isAlive() and p:getKingdom() == "wu" then
			return true
		end
	end
	return false
end
LuaWeidaiCard = sgs.CreateSkillCard{
	name = "LuaWeidaiCard",
	target_fixed = true,
		mute = true,
	on_validate = function(self, card_use)
		card_use.m_isOwnerUse = false
		local sunce = card_use.from
		local room = sunce:getRoom()
		for _ , liege in sgs.qlist(room:getLieges("wu", sunce)) do
			local tohelp = sgs.QVariant()
			tohelp:setValue(sunce)
			local prompt = string.format("@weidai-analeptic:%s", sunce:objectName())
			local card = room:askForCard(liege, ".|spade|2~9|hand", prompt, tohelp, sgs.Card_MethodNone)
			if card then
				local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, liege:objectName(), "LuaWeidai", "")
				room:moveCardTo(card, nil, sgs.Player_DiscardPile, reason, true)
				local ana = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
				ana:setSkillName("LuaWeidai")
				ana:addSubcard(card)
				return ana
			end
		end
		room:setPlayerFlag(sunce, "Global_LuaWeidaiFailed")
		return nil
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		for _ , liege in sgs.qlist(room:getLieges("wu", user)) do
			local tohelp = sgs.QVariant()
			tohelp:setValue(user)
			local prompt = string.format("@weidai-analeptic:%s", user:objectName())
			local card = room:askForCard(liege, ".|spade|2~9|hand", prompt, tohelp, sgs.Card_MethodNone)
			if card then
				local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, liege:objectName(), "LuaWeidai", "")
				room:moveCardTo(card, nil, sgs.Player_DiscardPile, reason, true)
				local ana = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
				ana:setSkillName("LuaWeidai")
				ana:addSubcard(card)
				return ana
			end
		end
		room:setPlayerFlag(user, "Global_LuaWeidaiFailed")
		return nil
	end
}
LuaWeidai = sgs.CreateZeroCardViewAsSkill{
	name = "LuaWeidai$",
	view_as = function()
		return LuaWeidaiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return hasWuGenerals(player) and player:hasLordSkill("LuaWeidai")
			   and not player:hasFlag("Global_LuaWeidaiFailed")
			   and sgs.Analeptic_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return hasWuGenerals(player) and pattern == "peach+analeptic" and not player:hasFlag("Global_LuaWeidaiFailed")
	end
}

--[[
	技能名：围堰
	相关武将：倚天·陆抗
	描述：你可以将你的摸牌阶段当作出牌阶段，出牌阶段当作摸牌阶段执行
	引用：LuaLukangWeiyan
	状态：1217验证通过
]]--
LuaLukangWeiyan = sgs.CreateTriggerSkill{
	name = "LuaLukangWeiyan" ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Draw then
			if not player:isSkipped(sgs.Player_Draw) then
				if player:askForSkillInvoke(self:objectName(), sgs.QVariant("draw2play")) then
					change.to = sgs.Player_Play
					data:setValue(change)
				end
			end
		elseif change.to == sgs.Player_Play then
			if not player:isSkipped(sgs.Player_Play) then
				if player:askForSkillInvoke(self:objectName(), sgs.QVariant("play2draw")) then
					change.to = sgs.Player_Draw
					data:setValue(change)
				end
			end
		else
			return false
		end
		return false
	end
}
--[[
	技能名：帷幕（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：你不能被选择为黑色锦囊牌的目标。
	引用：LuaWeimu
	状态：0405验证通过
]]--
LuaWeimu = sgs.CreateProhibitSkill{
	name = "LuaWeimu" ,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("TrickCard") or card:isKindOf("QiceCard")) 
		and card:isBlack() and card:getSkillName() ~= "nosguhuo" --特别注意旧蛊惑
	end
}
--[[
	技能名：伪帝（锁定技）
	相关武将：SP·袁术、SP·台版袁术
	描述：你拥有当前主公的主公技。
	状态：0405验证失败--目测永远实现不了
]]--
--[[
	技能名：温酒（锁定技）
	相关武将：智·华雄
	描述：你使用黑色的【杀】造成的伤害+1，你无法闪避红色的【杀】
	引用：LuaWenjiu
	状态：1217验证通过
]]--
LuaWenjiu = sgs.CreateTriggerSkill{
	name = "LuaWenjiu" ,
	events = {sgs.ConfirmDamage, sgs.SlashProceed} ,
	frequency = sgs.Skill_Compulsory ,
	priority = 3 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local hua = room:findPlayerBySkillName(self:objectName())
		if not hua then return false end
		if event == sgs.SlashProceed then
			local effect = data:toSlashEffect()
			if (effect.to:objectName() == hua:objectName()) and effect.slash:isRed() then
				room:slashResult(effect, nil)
				return true
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			local reason = damage.card
			if (not reason) or (damage.from:objectName() ~= hua:objectName()) then return false end
			if reason:isKindOf("Slash") and reason:isBlack() then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：无谋（锁定技）
	相关武将：神·吕布、SP·神吕布
	描述：每当你使用一张非延时锦囊牌时，你须选择一项：失去1点体力，或弃一枚“暴怒”标记。 
	引用：LuaWumou
	状态：0405验证通过
]]--
LuaWumou = sgs.CreateTriggerSkill{
	name = "LuaWumou" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isNDTrick() then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local num = player:getMark("@wrath")
			if num >= 1 and room:askForChoice(player, self:objectName(), "discard+losehp") == "discard" then
				player:loseMark("@wrath")
			else
				room:loseHp(player)
			end
		end
		return false
	end
}
--[[
	技能名：无前
	相关武将：神·吕布、SP·神吕布
	描述：出牌阶段，你可以弃两枚“暴怒”标记并选择一名其他角色：若如此做，你拥有“无双”且该角色防具无效，直到回合结束。
	引用：LuaWuqian
	状态：0405验证通过
]]--
LuaWuqianCard = sgs.CreateSkillCard{
	name = "LuaWuqianCard" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		effect.from:loseMark("@wrath", 2)
		room:acquireSkill(effect.from, "wushuang")
		effect.from:setFlags("LuaWuqianSource")
		effect.to:setFlags("LuaWuqianTarget")
		room:addPlayerMark(effect.to, "Armor_Nullified")
	end
}
LuaWuqianVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaWuqian" ,
	view_as = function()
		return LuaWuqianCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@wrath") >= 2
	end
}
LuaWuqian = sgs.CreateTriggerSkill{
	name = "LuaWuqian" ,
	events = {sgs.EventPhaseChanging, sgs.Death} ,
	view_as_skill = LuaWuqianVS ,
	can_trigger = function(self, target)
		return target and target:hasFlag("LuaWuqianSource")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("WuqianTarget") then
				p:setFlags("-WuqianTarget")
				if p:getMark("Armor_Nullified") then
					room:removePlayerMark(p, "Armor_Nullified")
				end
			end
		end
		room:detachSkillFromPlayer(player, "wushuang", false, true)
		return false
	end
}
--[[
	技能名：无双（锁定技）
	相关武将：界限突破·吕布、标准·吕布、SP·最强神话、SP·暴怒战神、SP·台版吕布
	描述：当你使用【杀】指定一名角色为目标后，该角色需连续使用两张【闪】才能抵消；与你进行【决斗】的角色每次需连续打出两张【杀】。
	引用：LuaWushuang
	状态：0405验证通过
	备注：与源码略有不同，体验感稍差
]]--
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
LuaWushuang = sgs.CreateTriggerSkill{
	name = "LuaWushuang" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.TargetSpecified,sgs.CardEffected } ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player and player:isAlive() and player:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_list[i + 1] == 1 then
						jink_list[i + 1] = 2
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_list))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local can_invoke = false
			if effect.card:isKindOf("Duel") then				
				if effect.from and effect.from:isAlive() and effect.from:hasSkill(self:objectName()) then
					can_invoke = true
				end
				if effect.to and effect.to:isAlive() and effect.to:hasSkill(self:objectName()) then
					can_invoke = true
				end
			end
			if not can_invoke then return false end
			if effect.card:isKindOf("Duel") then
				if room:isCanceled(effect) then
					effect.to:setFlags("Global_NonSkillNullify")
					return true;
				end
				if effect.to:isAlive() then
					local second = effect.from
					local first = effect.to
					room:setEmotion(first, "duel");
					room:setEmotion(second, "duel")
					while true do
						if not first:isAlive() then
							break
						end
						local slash
						if second:hasSkill(self:objectName()) then
							slash = room:askForCard(first,"slash","@Luawushuang-slash-1:" .. second:objectName(),data,sgs.Card_MethodResponse, second);
							if slash == nil then
								break
							end

							slash = room:askForCard(first, "slash", "@Luawushuang-slash-2:" .. second:objectName(),data,sgs.Card_MethodResponse,second);
							if slash == nil then
								break
							end
						else
							slash = room:askForCard(first,"slash","duel-slash:" .. second:objectName(),data,sgs.Card_MethodResponse,second)
							if slash == nil then
								break
							end
						end
						local temp = first
						first = second
						second = temp
					end
					local daamgeSource = function() if second:isAlive() then return secoud else return nil end end
					local damage = sgs.DamageStruct(effect.card, daamgeSource() , first)
					if second:objectName() ~= effect.from:objectName() then
						damage.by_user = false;
					end
					room:damage(damage)
				end
				room:setTag("SkipGameRule",sgs.QVariant(true))
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：无言（锁定技）
	相关武将：一将成名·徐庶
	描述：你防止你造成或受到的任何锦囊牌的伤害。
	引用：LuaWuyan
	状态：1217验证通过
]]--
LuaWuyan = sgs.CreateTriggerSkill{
	name = "LuaWuyan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.card and (damage.card:getTypeId() == sgs.Card_TypeTrick) then
			if (event == sgs.DamageInflicted) and player:hasSkill(self:objectName()) then
				return true
			elseif (event == sgs.DamageCaused) and (damage.from and damage.from:isAlive() and damage.from:hasSkill(self:objectName())) then
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：无言（锁定技）
	相关武将：怀旧·徐庶
	描述：你使用的非延时类锦囊牌对其他角色无效；其他角色使用的非延时类锦囊牌对你无效。
	引用：LuaNosWuyan
	状态：1217验证通过
]]--
LuaNosWuyan = sgs.CreateTriggerSkill{
	name = "LuaNosWuyan" ,
	events = {sgs.CardEffected} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if effect.to:objectName() == effect.from:objectName() then return false end
		if effect.card:isNDTrick() then
			if effect.from and effect.from:hasSkill(self:objectName()) then
				return true
			elseif effect.to:hasSkill(self:objectName()) and effect.from then
				return true
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：五灵
	相关武将：倚天·晋宣帝
	描述：回合开始阶段，你可选择一种五灵效果发动，该效果对场上所有角色生效
		该效果直到你的下回合开始为止，你选择的五灵效果不可与上回合重复
		[风]场上所有角色受到的火焰伤害+1
		[雷]场上所有角色受到的雷电伤害+1
		[水]场上所有角色使用桃时额外回复1点体力
		[火]场上所有角色受到的伤害均视为火焰伤害
		[土]场上所有角色每次受到的属性伤害至多为1
	引用：LuaWulingExEffect、LuaWulingEffect、LuaWuling
	状态：1217验证通过
]]--
LuaWulingExEffect = sgs.CreateTriggerSkill{
	name = "#LuaWuling-ex-effect" ,
	events = {sgs.PreHpRecover, sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local xuandi = room:findPlayerBySkillName(self:objectName())
		if not xuandi then return false end
		local wuling = xuandi:getTag("LuaWuling"):toString()
		if (event == sgs.PreHpRecover) and (wuling == "water") then
			local rec = data:toRecover()
			if rec.card and (rec.card:isKindOf("Peach")) then
				rec.recover = rec.recover + 1
				data:setValue(rec)
			end
		elseif (event == sgs.DamageInflicted) and (wuling == "earth") then
			local damage = data:toDamage()
			if (damage.nature ~= sgs.DamageStruct_Normal) and (damage.damage > 1) then
				damage.damage = 1
				data:setValue(damage)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
LuaWulingEffect = sgs.CreateTriggerSkill{
	name = "#LuaWuling-effect" ,
	events = {sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local xuandi = room:findPlayerBySkillName(self:objectName())
		if not xuandi then return false end
		local wuling = xuandi:getTag("LuaWuling"):toString()
		local damage = data:toDamage()
		if wuling == "wind" then
			if damage.nature == sgs.DamageStruct_Fire then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif wuling == "thunder" then
			if damage.nature == sgs.DamageStruct_Thunder then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif wuling == "fire" then
			if damage.nature ~= sgs.DamageStruct_Fire then
				damage.nature = sgs.DamageStruct_Fire
				data:setValue(damage)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end ,
}
LuaWuling = sgs.CreateTriggerSkill{
	name = "LuaWuling" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local LuaWulingEffects = {"wind", "thunder", "water", "fire", "earth"}
		if player:getPhase() == sgs.Player_Start then
			local current = player:getTag("LuaWuling"):toString()
			local choices = {}
			for _, effect in ipairs(LuaWulingEffects) do
				if effect ~= current then
					table.insert(choices, effect)
				end
			end
			local room = player:getRoom()
			local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
			if not (current == "" or current == nil) then
				player:loseMark("@" .. current)
			end
			player:gainMark("@" .. choice)
			player:setTag("LuaWuling", sgs.QVariant(choice))
		end
		return false
	end
}
--[[
	技能名：武魂（锁定技）
	相关武将：神·关羽
	描述：每当你受到伤害扣减体力前，伤害来源获得等于伤害点数的“梦魇”标记。你死亡时，你选择一名存活的“梦魇”标记数最多（不为0）的角色，该角色进行判定：若结果不为【桃】或【桃园结义】，该角色死亡。 
	引用：LuaWuhun、LuaWuhunRevenge
	状态：0405验证通过
]]--
LuaWuhun = sgs.CreateTriggerSkill{
	name = "LuaWuhun" ,
	events = {sgs.PreDamageDone},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if damage.from and damage.from:objectName() ~= player:objectName() then
			damage.from:gainMark("@nightmare", damage.damage)
			room:notifySkillInvoked(player, self:objectName())
		end
		return false
	end
}
LuaWuhunRevenge = sgs.CreateTriggerSkill{
	name = "#LuaWuhun" ,
	events = {sgs.Death},
	can_trigger = function(self, target)
		return target ~= nil and target:hasSkill("LuaWuhun");
	end ,
	on_trigger = function(self, event, shenguanyu, data)
		local death = data:toDeath()
		local room = shenguanyu:getRoom()
		if death.who:objectName() ~= shenguanyu:objectName() then
			return false
		end
		local players = room:getOtherPlayers(shenguanyu)
		local max = 0
		for _, player in sgs.qlist(players) do
			max = math.max(max, player:getMark("@nightmare"))
		end
		if max == 0 then return false end
		local foes = sgs.SPlayerList()
		for _, player in sgs.qlist(players) do
			if player:getMark("@nightmare") == max then
				foes:append(player)
			end
		end
		if foes:isEmpty() then
			return false
		end
		local foe
		if foes:length() == 1 then
			foe = foes:first()
		else
			foe = room:askForPlayerChosen(shenguanyu, foes, "wuhun", "@wuhun-revenge")
		end
		room:notifySkillInvoked(shenguanyu, "wuhun")
		local judge = sgs.JudgeStruct()
		judge.pattern = "Peach,GodSalvation"
		judge.good = true
		judge.negative = true
		judge.reason = "wuhun"
		judge.who = foe
		room:judge(judge)
		if judge:isBad() then
			room:killPlayer(foe)
		end
		local killers = room:getAllPlayers()
		for _, player in sgs.qlist(killers) do
			player:loseAllMarks("@nightmare")
		end
		return false
	end
}
--[[
	技能名：武继（觉醒技）
	相关武将：SP·关银屏
	描述：结束阶段开始时，若你于本回合造成了至少3点伤害，你增加1点体力上限，回复1点体力，然后失去“虎啸”。 
	引用：LuaWuji
	状态：0405验证通过
]]--
LuaWuji = sgs.CreatePhaseChangeSkill{
	name = "LuaWuji",
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		room:setPlayerMark(player, self:objectName(), 1)
		if room:changeMaxHpForAwakenSkill(player, 1) then
			room:recover(player, sgs.RecoverStruct(player))
			room:detachSkillFromPlayer(player, "huxiao")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Finish 
		and target:getMark(self:objectName()) == 0 and target:getMark("damage_point_round") >= 3
	end
}
--[[
	技能名：武神（锁定技）
	相关武将：神·关羽
	描述：你的红桃手牌视为普通【杀】。你使用红桃【杀】无距离限制。 
	引用：LuaWushen、LuaWushenTargetMod
	状态：0405验证通过
]]--


LuaWushen = sgs.CreateFilterSkill{
	name = "LuaWushen", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:getSuit() == sgs.Card_Heart) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}
LuaWushenTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaWushen-target",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("LuaWushen") and (card:getSuit() == sgs.Card_Heart) then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：武圣
	相关武将：界限突破·关羽、JSP·关羽、SP·关羽、标准·关羽、翼·关羽、2013-3v3·关羽、1v1·关羽1v1
	描述：你可以将一张红色牌当【杀】使用或打出。
	引用：LuaWusheng
	状态：0405验证通过
]]--
LuaWusheng = sgs.CreateOneCardViewAsSkill{
	name = "LuaWusheng",
	response_or_use = true,
	view_filter = function(self, card)
		if not card:isRed() then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
