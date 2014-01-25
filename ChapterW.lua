--[[
	代码速查手册（W区）
	技能索引：
		完杀、婉容、忘隙、妄尊、危殆、围堰、帷幕、伪帝、温酒、无谋、无前、无双、无言、无言、五灵、武魂、武继、武神、武圣
]]--
--[[
	技能名：完杀（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。
	引用：LuaWansha
	状态：验证通过
]]--
LuaWansha = sgs.CreateTriggerSkill{
	name = "LuaWansha",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		if current:isAlive() then
			if current:hasSkill(self:objectName()) then
				local dying = data:toDying()
				local victim = dying.who
				local seat = player:getSeat()
				if current:getSeat() ~= seat then
					return victim:getSeat() ~= seat
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：婉容
	相关武将：1v1·大乔
	描述：每当你成为【杀】的目标后，你可以摸一张牌。 
]]--
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
	状态：0610验证通过
]]--
LuaWangzun = sgs.CreateTriggerSkill{
	name = "LuaWangzun" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isLord() and (player:getPhase() == sgs.Player_Start) then
			local yuanshu = room:findPlayerBySkillName(self:objectName())
			if yuanshu then
				if room:askForSkillInvoke(yuanshu, self:objectName()) then
					yuanshu:drawCards(1)
					room:setPlayerFlag(player, "LuaWangzunDecMaxCards")
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
	技能名：危殆（主公技）
	相关武将：智·孙策
	描述：当你需要使用一张【酒】时，所有吴势力角色按行动顺序依次选择是否打出一张黑桃2~9的手牌，视为你使用了一张【酒】，直到有一名角色或没有任何角色决定如此做时为止
	引用：LuaXWeidai
	状态：验证通过
]]--
LuaXWeidaiCard = sgs.CreateSkillCard{
	name = "LuaXWeidaiCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		if not source:hasFlag("drank") then
			if source:hasLordSkill("LuaXWeidai") then
				local players = room:getAlivePlayers()
				for _,liege in sgs.qlist(players) do
					if liege:getKingdom() == "wu" then
						if source:getHp() <= 0 or not source:hasUsed("Analeptic") then
							local tohelp = sgs.QVariant()
							tohelp:setValue(source)
							local prompt = string.format("@weidai-analeptic:%s", source:objectName())
							local analeptic = room:askForCard(liege, ".|spade|2~9|hand", prompt, tohelp, sgs.CardResponsed, source)
							if analeptic then
								local suit = analeptic:getSuit()
								local point = analeptic:getNumber()
								local ana = sgs.Sanguosha:cloneCard("analeptic", suit, point)
								ana:setSkillName("LuaXWeidai")
								local use = sgs.CardUseStruct()
								use.card = ana
								use.from = source
								use.to:append(use.from)
								room:useCard(use)
								if source:getHp() > 0 then
									break
								end
							end
						end
					end
				end
			end
		end
	end
}
LuaXWeidaiVS = sgs.CreateViewAsSkill{
	name = "LuaXWeidai$",
	n = 0,
	view_as = function(self, cards)
		return LuaXWeidaiCard:clone()
	end,
	enabled_at_play = function(self, player)
		if player:hasLordSkill("LuaXWeidai") then
			if not player:hasUsed("Analeptic") then
				return not player:hasUsed("#LuaXWeidaiCard")
			end
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXWeidai"
	end
}
LuaXWeidai = sgs.CreateTriggerSkill{
	name = "LuaXWeidai$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Dying},
	view_as_skill = LuaXWeidaiVS,
	on_trigger = function(self, event, player, data)
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() then
			local room = player:getRoom()
			room:askForUseCard(player, "@@LuaXWeidai", "@weidai")
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:hasLordSkill("LuaXWeidai")
		end
		return false
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
	状态：1217验证通过
]]--
LuaWeimu = sgs.CreateProhibitSkill{
	name = "LuaWeimu" ,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("TrickCard") or card:isKindOf("QiceCard"))
				and card:isBlack() and (card:getSkillName() ~= "guhuo") --特别注意蛊惑
	end
}
--[[
	技能名：伪帝（锁定技）
	相关武将：SP·袁术、SP·台版袁术
	描述：你拥有当前主公的主公技。
	状态：验证失败
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
	相关武将：神·吕布
	描述：当你使用一张非延时类锦囊牌选择目标后，你须弃1枚“暴怒”标记或失去1点体力。
	引用：LuaWumou
	状态：1217验证通过
]]--
LuaWumou = sgs.CreateTriggerSkill{
	name = "LuaWumou" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardUsed, sgs.CardResponded} ,
	on_trigger = function(self, event, player, data)
		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		if card:isNDTrick() then
			local num = player:getMark("@wrath")
			if num >= 1 then
				if player:getRoom():askForChoice(player, self:objectName(), "discard+losehp") == "discard" then
					player:loseMark("@wrath")
				else
					player:getRoom():loseHp(player)
				end
			else
				player:getRoom():loseHp(player)
			end
		end
	end
}
--[[
	技能名：无前
	相关武将：神·吕布
	描述：出牌阶段，你可以弃2枚“暴怒”标记并选择一名其他角色，该角色的防具无效且你获得技能“无双”，直到回合结束。
	引用：LuaWuqian
	状态：1217验证通过
]]--
LuaWuqianCard = sgs.CreateSkillCard{
	name = "LuaWuqianCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
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
LuaWuqianVS = sgs.CreateViewAsSkill{
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
	on_trigger = function(self, event, player, data)
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
		for _, p in sgs.qlist(player:getRoom():getAllPlayers()) do
			if p:hasFlag("WuqianTarget") then
				p:setFlags("-WuqianTarget")
				if p:getMark("Armor_Nullified") then
					player:getRoom():removePlayerMark(p, "Armor_Nullified")
				end
			end
		end
		player:getRoom():detachSkillFromPlayer(player, "wushuang")
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("LuaWuqianSource")
	end
}
--[[
	技能名：无双（锁定技）
	相关武将：标准·吕布、SP·最强神话、SP·暴怒战神、SP·台版吕布
	描述：当你使用【杀】指定一名角色为目标后，该角色需连续使用两张【闪】才能抵消；与你进行【决斗】的角色每次需连续打出两张【杀】。
	引用：LuaWushuang
	状态：0901验证通过

	备注：0610版本中源码上有个WushuangInvoke就可以触发决斗无双效果，但无奈没有QVariant::toIntList和QVariant:setValue(QList <int>)这两个接口所以杀的无双效果无法实现
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
	events = {sgs.TargetConfirmed, sgs.CardFinished} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local can_invoke = false
			if use.card:isKindOf("Slash") and (player and player:isAlive() and player:hasSkill(self:objectName())) and (use.from:objectName() == player:objectName()) then
				can_invoke = true
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_table[i + 1] == 1 then
						jink_table[i + 1] = 2 --只要设置出两张闪就可以了，不用两次askForCard
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
			if use.card:isKindOf("Duel") then
				if (use.from and use.from:isAlive() and use.from:hasSkill(self:objectName())) and (use.from:objectName() == player:objectName()) then
					can_invoke = true
				end
				if (player and player:isAlive() and player:hasSkill(self:objectName())) and use.to:contains(player) then
					can_invoke = true
				end
			end
			if not can_invoke then return false end
			if use.card:isKindOf("Duel") then
				player:getRoom():setPlayerMark(player, "WushuangTarget", 1) --决斗的具体部分在源码中
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Duel") then
				local room = player:getRoom()
				for _, lvbu in sgs.qlist(room:getAllPlayers()) do
					if lvbu:getMark("WushuangTarget") > 0 then
						room:setPlayerMark(lvbu, "WushuangTarget", 0)
					end
				end
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
	状态：0610验证通过
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
			end
			if (event == sgs.DamageCaused) and (damage.from and damage.from:isAlive() and damage.from:hasSkill(self:objectName())) then
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
	描述：每当你受到1点伤害后，伤害来源获得一枚“梦魇”标记；你死亡时，令拥有最多该标记的一名其他角色进行一次判定，若判定结果不为【桃】或【桃园结义】，该角色死亡。
	引用：LuaWuhun、LuaWuhunRevenge、LuaWuhunClear
	状态：1217验证通过
]]--
LuaWuhun = sgs.CreateTriggerSkill{
	name = "LuaWuhun" ,
	events = {sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.from and (damage.from:objectName() ~= player:objectName()) then
			damage.from:gainMark("@nightmare", damage.damage)
		end
	end
}
LuaWuhunRevenge = sgs.CreateTriggerSkill{
	name = "#LuaWuhun" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local players = room:getOtherPlayers(player)
		local _max = 0
		for _, _player in sgs.qlist(players) do
			_max = math.max(_max, _player:getMark("@nightmare"))
		end
		if _max == 0 then return false end
		local foes = sgs.SPlayerList()
		for _, _player in sgs.qlist(players) do
			if _player:getMark("@nightmare") == _max then
				foes:append(_player)
			end
		end
		if foes:isEmpty() then return false end
		local foe
		if foes:length() == 1 then
			foe = foes:first()
		else
			foe = room:askForPlayerChosen(player, foes, self:objectName(), "@wuhun-revenge")
		end
		local judge = sgs.JudgeStruct()
		judge.pattern = "Peach,GodSalvation"
		judge.good = true
		judge.reason = "LuaWuhun"
		judge.who = foe
		room:judge(judge)
		if judge:isBad() then
			room:killPlayer(foe)
		end
		local killers = room:getAllPlayers()
		for _, _player in sgs.qlist(killers) do
			_player:loseAllMarks("@nightmare")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill("LuaWuhun")
	end
}
LuaWuhunClear = sgs.CreateTriggerSkill{
	name = "LuaWuhun-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaWuhun" then
			for _, p in sgs.qlist(player:getRoom():getAllPlayers()) do
				p:loseAllMarks("@nightmare")
			end
		end
	end ,
	can_trigger = function(self, target)
		return target
	end ,
}
--[[
	技能名：武继（觉醒技）
	相关武将：SP·关银屏
	描述：结束阶段开始时，若你于此回合内已造成3点或更多伤害，你加1点体力上限，回复1点体力，然后失去技能“虎啸”。
	引用：LuaWujiCount、LuaWuji
	状态：1217验证通过
]]--
LuaWujiCount = sgs.CreateTriggerSkill{
	name = "#LuaWuji-count" ,
	events = {sgs.PreDamageDone, sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreDamageDone then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and (damage.from:objectName() == room:getCurrent():objectName()) and (damage.from:getMark("LuaWuji") == 0) then
				room:addPlayerMark(damage.from, "LuaWuji_damage", damage.damage)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:getMark("LuaWuji_damage") > 0 then
					room:setPlayerMark(player, "LuaWuji_damage", 0)
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
LuaWuji = sgs.CreateTriggerSkill{
	name = "LuaWuji",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "LuaWuji")
		if room:changeMaxHpForAwakenSkill(player, 1) then
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
			room:detachSkillFromPlayer(player, "huxiao")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getPhase() == sgs.Player_Finish)
				and (target:getMark("LuaWuji") == 0)
				and (target:getMark("LuaWuji_damage") >= 3)
	end
}
--[[
	技能名：武神（锁定技）
	相关武将：神·关羽
	描述：你的红桃手牌均视为【杀】；你使用红桃【杀】时无距离限制。
	引用：LuaWushen、LuaWushenTargetMod
	状态：1217验证通过
]]--
LuaWushen = sgs.CreateFilterSkill{
	name = "LuaWushen",
	
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:getSuit() == sgs.Card_Heart) and (place == sgs.Player_PlaceHand)
	end,
	
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("Slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		local _card = sgs.Sanguosha:getWrappedCard(card:getId())
		_card:takeOver(slash)
		return _card
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
	相关武将：标准·关羽、翼·关羽、2013-3v3·关羽、1v1·关羽1v1
	描述：你可以将一张红色牌当【杀】使用或打出。
	引用：LuaWusheng
	状态：0610验证通过
]]--
LuaWusheng = sgs.CreateViewAsSkill{
	name = "LuaWusheng",
	n = 1,
	view_filter = function(self, selected, to_select)
		if not to_select:isRed() then return false end
		local weapon = sgs.Self:getWeapon()
		if (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY) and sgs.Self:getWeapon()
				and (to_select:getEffectiveId() == sgs.Self:getWeapon():getId()) and to_select:isKindOf("Crossbow") then
			return sgs.Self:canSlashWithoutCrossbow()
		else
			return true
		end
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:addSubcard(card:getId())
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
