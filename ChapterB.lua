--[[
	代码速查手册（B区）
	技能索引：
		八阵、霸刀、霸王、拜印、豹变、豹变、暴敛、暴凌、暴虐、悲歌、悲鸣、北伐、賁育、奔雷、奔袭、崩坏、笔伐、闭月、变天、秉壹、补益、不屈、不屈
]]--
--[[
	技能名：八阵（锁定技）
	相关武将：火·诸葛亮
	描述：若你的装备区没有防具牌，视为你装备【八卦阵】。
	引用：LuaBazhen
	状态：0405验证通过
]]--
LuaBazhen = sgs.CreateTriggerSkill{
	name = "LuaBazhen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardAsked},
	on_trigger = function(self, event, wolong, data)
		local room = wolong:getRoom()
		local pattern = data:toStringList()[1]
		if pattern ~= "jink" then return false end
		if wolong:askForSkillInvoke("eight_diagram") then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red"
			judge.good = true
			judge.reason = "eight_diagram"
			judge.who = wolong
			judge.play_animation = true
			room:judge(judge)
			if judge:isGood() then
				room:setEmotion(wolong, "armor/EightDiagram");
				local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
				jink:setSkillName(self:objectName())
				room:provide(jink)
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) 
		and not target:getArmor() and not target:hasArmorEffect("eight_diagram")
	end
}
--[[
	技能名：霸刀
	相关武将：智·华雄
	描述：当你成为黑色的【杀】目标后，你可以使用一张【杀】
	引用：LuaBadao
	状态：0405验证通过
]]--
LuaBadao = sgs.CreateTriggerSkill{
	name = "LuaBadao" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.card:isBlack() and use.to:contains(player) then
			room:askForUseCard(player, "slash", "@askforslash")
		end
		return false
	end
}
--[[
	技能名：霸王
	相关武将：智·孙策
	描述：每当你使用的【杀】被【闪】抵消时，你可以与目标角色拼点：若你赢，可以视为你对至多两名角色各使用了一张【杀】（此杀不计入每阶段的使用限制）。
	引用：LuaBawang
	状态：0405验证通过
]]--
LuaBawangCard = sgs.CreateSkillCard{
	name = "LuaBawangCard" ,
	filter = function(self, targets, to_select)
		if #targets >= 2 then return false end
		return sgs.Self:canSlash(to_select, false)
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local slash = sgs.Sanguosha:cloneCard("slash" sgs.Card_NoSuit, 0)
		slash:setSkillName("LuaBawang")
		room:useCard(sgs.CardUseStruct(slash, effect.from, effect.to), false)
	end
}
LuaBawangVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaBawang" ,
	response_pattern = "@@LuaBawang" ,
	view_as = function()
		return LuaBawangCard:clone()
	end
}
LuaBawang = sgs.CreateTriggerSkill{
	name = "LuaBawang" ,
	events = {sgs.SlashMissed} ,
	view_as_skill = LuaBawangVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
		if (not effect.to:isNude()) and (not player:isKongcheng()) and (not effect.to:isKongcheng()) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local success = player:pindian(effect.to, self:objectName(), nil)
				if success then
					if player:hasFlag("drank") then
						room:setPlayerFlag(player, "-drank")
					end
					room:askForUseCard(player, "@@LuaBawang", "@bawang")
				end
			end
		end
		return false
	end
}

--[[
	技能名：拜印（觉醒技）
	相关武将：神·司马懿
	描述：回合开始阶段开始时，若你拥有4枚或更多的“忍”标记，你须减1点体力上限，并获得技能“极略”。
	引用：LuaBaiyin
	状态：0405验证通过
]]--
LuaBaiyin = sgs.CreatePhaseChangeSkill{
	name = "LuaBaiyin" ,
	frequency = sgs.Skill_Wake ,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		room:setPlayerMark(player,"LuaBaiyin", 1)
		if room:changeMaxHpForAwakenSkill(player) then
			room:acquireSkill(player, "jilve")
		end
		return false
	end ,
	can_trigger = function(self,target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getPhase() == sgs.Player_Start)
				and (target:getMark("LuaBaiyin") == 0)
				and (target:getMark("@bear") >= 4)
	end
}
--[[
	技能名：豹变（锁定技）
	相关武将：SP·夏侯霸
	描述：锁定技。若你的体力值为：3或更低，你拥有“挑衅”；2或更低，你拥有“咆哮”；1或更低，你拥有“神速”。
	引用：LuaBaobian
	状态：0405验证通过
]]--
function BaobianChange(room, player, hp, skill_name)
	local baobian_skills = player:getTag("BaobianSkills"):toString():split("+")	
	if player:getHp() <= hp then		
		if not table.contains(baobian_skills, skill_name) then			
			room:notifySkillInvoked(player, "LuaBaobian")
			if player:getHp() == hp then				
				room:broadcastSkillInvoke("baobian", 4 - hp)
			end			
			room:handleAcquireDetachSkills(player, skill_name)
			table.insert(baobian_skills, skill_name)
		end
	else
		if table.contains(baobian_skills, skill_name) then			
			room:handleAcquireDetachSkills(player, "-"..skill_name)
			table.removeOne(baobian_skills, skill_name)
		end
	end
	player:setTag("BaobianSkills", sgs.QVariant(table.concat(baobian_skills, "+")))	
end
LuaBaobian = sgs.CreateTriggerSkill{
	name = "LuaBaobian" ,
	events = {sgs.TurnStart, sgs.HpChanged, sgs.MaxHpChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		if event == sgs.TurnStart then			
			local xiahouba = room:findPlayerBySkillName(self:objectName())
			if not xiahouba or not xiahouba:isAlive() then return false end
				BaobianChange(room, xiahouba, 1, "shensu")
				BaobianChange(room, xiahouba, 2, "paoxiao")
				BaobianChange(room, xiahouba, 3, "tiaoxin")
			end
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local baobian_skills = player:getTag("BaobianSkills"):toString():split("+")
				local detachList = {}
				for _, skill_name in ipairs(baobian_skills) do
					table.insert(detachList,"-"..skill_name)
				end
				room:handleAcquireDetachSkills(player, table.concat(detachList,"|"))
				player:setTag("BaobianSkills", sgs.QVariant())
			end
			return false
		elseif event == sgs.EventAcquireSkill then
			if data:toString() ~= self:objectName() then return false end
		end
		if not player:isAlive() or not player:hasSkill(self:objectName(), true) then return false end		
			BaobianChange(room, player, 1, "shensu")
			BaobianChange(room, player, 2, "paoxiao")
			BaobianChange(room, player, 3, "tiaoxin")		
		return false
	end ,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--[[
	技能名：豹变
	相关武将：TW一将成名·夏侯霸
	描述：当你使用【杀】或【决斗】对目标角色造成伤害时，若其势力与你：相同，你可以防止此伤害，令其将手牌补至X张（X为其体力上限）；不同且其手牌数大于其体力值，你可以弃置其Y张手牌（Y为其手牌数与体力值的差）。 
	引用：LuaTWBaobian
	状态：0405验证通过
]]--
LuaTWBaobian = sgs.CreateTriggerSkill{
	name = "LuaTWBaobian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel"))
			and (not damage.chain) and (not damage.transfer) and damage.by_user then
			if damage.to:getKingdom() == player:getKingdom() then
				if player:askForSkillInvoke(self:objectName(), data) then
					if damage.to:getHandcardNum() < damage.to:getMaxHp() then
						local n = damage.to:getMaxHp() - damage.to:getHandcardNum()
						room:drawCards(damage.to, n, self:objectName())
					end
					return true
				end
			elseif damage.to:getHandcardNum() > math.max(damage.to:getHp(), 0) and player:canDiscard(damage.to, "h") then
				if player:askForSkillInvoke(self:objectName(), data) then
					local hc = damage.to:handCards()
					local n = damage.to:getHandcardNum() - math.max(damage.to:getHp(), 0)
					local dummy = sgs.Sanguosha:cloneCard("slash")
					math.randomseed(os.time())
					while n > 0 do
						local id = hc:at(math.random(0, hc:length() - 1))--取随机手牌代替askForCardChosen
						hc:removeOne(id)
						dummy:addSubcard(id)
						n = n - 1
					end
					room:throwCard(dummy, damage.to, player)
				end
			end
		end
	end
}
--[[
	技能名：暴敛（锁定技）
	相关武将：闯关模式·牛头，闯关模式·白无常
	描述：结束阶段开始时，你摸两张牌。 
	引用：LuaBossBaolian
	状态：0405验证通过
]]--
LuaBossBaolian = sgs.CreatePhaseChangeSkill{
	name = "LuaBossBaolian",
	frequency = sgs.Skill_Compulsory,
	priority = 4,
	on_phasechange = function(self, target)
		if target:getPhase() ~= sgs.Player_Finish then return false end
		local room = target:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:sendCompulsoryTriggerLog(target, self:objectName())
		target:drawCards(2, self:objectName())
		return false
	end
}
--[[
	技能名：暴凌（觉醒技）
	相关武将：势·董卓
	描述：出牌阶段结束时，若你本局游戏发动过“横征”，你增加3点体力上限，回复3点体力，然后获得“崩坏”。
	引用：LuaBaoling
	状态：0405验证通过
]]--
LuaBaoling = sgs.CreateTriggerSkill{
	name = "LuaBaoling",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:notifySkillInvoked(player, self:objectName())
		local log = sgs.LogMessage()
		log.type = "#BaolingWake"
		log.from = player
		log.arg = self:objectName()
		log.arg2 = "hengzheng"
		room:sendLog(log)
		room:setPlayerMark(player, "baoling", 1)
		if room:changeMaxHpForAwakenSkill(player, 3) then
			room:recover(player, sgs.RecoverStruct(player, nil, 3))
			if player:getMark("baoling") == 1 then
				room:acquireSkill(player, "benghuai")
			end
		end
	end,
	can_trigger = function(self, target)
		return target:getPhase() == sgs.Player_Play and target:getMark("baoling") == 0
			and target:getMark("HengzhengUsed") >= 1
	end
}
--[[
	技能名：暴虐（主公技）
	相关武将：林·董卓
	描述：主公技。其他群雄角色造成伤害后，该角色可以进行判定：若结果为黑桃，你回复1点体力。
	引用：LuaBaonue
	状态：0405验证通过
]]--
LuaBaonue = sgs.CreateTriggerSkill{
	name = "LuaBaonue$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage, sgs.PreDamageDone},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.PreDamageDone and damage.from then
			damage.from:setTag("InvokeBaonue", sgs.QVariant(damage.from:getKingdom() == "qun"))
		elseif event == sgs.Damage and player:getTag("InvokeBaonue"):toBool() and player:isAlive() then
			local dongzhuos = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					dongzhuos:append(p)
				end
			end
			while (not dongzhuos:isEmpty()) do
				local dongzhuo = room:askForPlayerChosen(player, dongzhuos, self:objectName(), "@baonue-to", true)
				if dongzhuo then
					dongzhuos:removeOne(dongzhuo)
					local log = sgs.LogMessage()
					log.type = "#InvokeOthersSkill"
					log.from = player
					log.to:append(dongzhuo)
					log.arg = self:objectName()
					room:sendLog(log)
					room:notifySkillInvoked(dongzhuo, self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|spade"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then
						room:recover(dongzhuo, sgs.RecoverStruct(player))
					end
				else
					break
				end
			end
		end
		return false
	end,
}
--[[
	技能名：悲歌
	相关武将：山·蔡文姬、SP·蔡文姬
	描述：每当一名角色受到【杀】造成的一次伤害后，你可以弃置一张牌，令其进行一次判定，判定结果为：红桃 该角色回复1点体力；方块 该角色摸两张牌；梅花 伤害来源弃置两张牌；黑桃 伤害来源将其武将牌翻面。
	引用：LuaBeige
	状态：0405验证通过
]]--
LuaBeige = sgs.CreateTriggerSkill{
	name = "LuaBeige",
	events = {sgs.Damaged, sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card == nil or not damage.card:isKindOf("Slash") or damage.to:isDead() then
				return false
			end
			for _, caiwenji in sgs.qlist(room:getAllPlayers()) do
				if not caiwenji or caiwenji:isDead() or not caiwenji:hasSkill(self:objectName()) then continue end
				if caiwenji:canDiscard(caiwenji, "he") and room:askForCard(caiwenji, "..", "@LuaBeige", data, self:objectName()) then
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.play_animation = false
					judge.who = player
					judge.reason = self:objectName()
					room:judge(judge)
					local suit = judge.card:getSuit()
					if suit == sgs.Card_Heart then
						room:recover(player, sgs.RecoverStruct(caiwenji))
					elseif suit == sgs.Card_Diamond then
						player:drawCards(2, self:objectName())
					elseif suit == sgs.Card_Club then
						if damage.from and damage.from:isAlive() then
							room:askForDiscard(damage.from, self:objectName(), 2, 2, false, true)
						end
					elseif suit == sgs.Card_Spade then
						if damage.from and damage.from:isAlive() then
							damage.from:turnOver()
						end
					end
				end
			end
		else
			local judge = data:toJudge()
			if judge.reason ~= self:objectName() then return false end
			judge.pattern = tostring(judge.card:getEffectiveId())
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
 --[[
	技能名：悲鸣（锁定技）
	相关武将：闯关模式·魅
	描述：你死亡时，杀死你的其他角色弃置其所有手牌。
	引用：LuaBossBeiming
	状态：0405验证通过
]]--
LuaBossBeiming = sgs.CreateTriggerSkill{
	name = "LuaBossBeiming" ,
	events = {sgs.Death} ,
	frequency = sgs.Skill_Compulsory ,
	can_trigger = function(self, player)
		return target and target:hasSkill(self:objectName())
	end ,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local killer = death.damage and death.damage.from
		if killer and killer:objectName() ~= player:objectName() then
            	local log = sgs.LogMessage()
            	log.type = "#BeimingThrow"
            	log.from = player
            	log.to:append(killer)
            	log.arg = self:objectName()
            	room:sendLog(log);
            	room:notifySkillInvoked(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		killer:throwAllHandCards()
		return false
        end
}
--[[
	技能名：北伐（锁定技）
	相关武将：智·姜维
	描述：锁定技。当你失去最后的手牌时，视为你对一名其他角色使用了一张【杀】，若不能如此做，则视为你对自己使用了一张【杀】
	引用：LuaBeifa
	状态：0405验证通过
]]--
LuaBeifa = sgs.CreateTriggerSkill{
	name = "LuaBeifa" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, jiangwei, data)
		local room = jiangwei:getRoom()
		local move = data:toMoveOneTime()
		if move.from and (move.from:objectName() == jiangwei:objectName()) and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
			local players = sgs.SPlayerList()
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			for _, player in sgs.qlist(room:getOtherPlayers(jiangwei)) do
				if jiangwei:canSlash(player, slash, false) then
					players:append(player)
				end
			end
			local target = nil
			if not players:isEmpty() then
				target = room:askForPlayerChosen(jiangwei, players, self:objectName())--没有处理TargetMod
			end
			if (not target) and (not jiangwei:isProhibited(jiangwei, slash)) then
				target = jiangwei
			end
			if not target then return false end
			local use = sgs.CardUseStruct()
			use.card = slash
			use.from = jiangwei
			use.to:append(target)
			room:useCard(use)
		end
		return false
	end
}
--[[
	技能名：贲育
	相关武将：SP·程昱
	描述：每当你受到有来源的伤害后，若伤害来源存活，若你的手牌数：小于X，你可以将手牌补至X（至多为5）张；大于X，你可以弃置至少X+1张手牌，然后对伤害来源造成1点伤害。（X为伤害来源的手牌数）
	引用：LuaBeiyu
	状态：0405验证通过
]]--
LuaBenyuCard = sgs.CreateSkillCard{
	name = "LuaBenyuCard",
	will_throw = true,
	target_fixed = true
}
LuaBenyuVs = sgs.CreateViewAsSkill{
	name = "LuaBenyu",
	n = 998,
	response_pattern = "@@LuaBenyu",
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards < sgs.Self:getMark("LuaBenyu") then
			return nil
		end
		local vscard = LuaBenyuCard:clone()
		for _, i in ipairs(cards) do
			vscard:addSubcard(i)
		end
		return vscard
	end
}
LuaBenyu = sgs.CreateMasochismSkill{
	name = "LuaBenyu",
	view_as_skill = LuaBenyuVs,
	on_damaged = function(self, target, damage)
		if (not damage.from) or damage.from:isDead() then
			return false
		end
		local room = target:getRoom()
		local from_handcard_num, handcard_num = damage.from:getHandcardNum(), target:getHandcardNum()
		local data = sgs.QVariant()
		data:setValue(damage)
		if handcard_num == from_handcard_num then
			return false
		elseif handcard_num < from_handcard_num and handcard_num < 5 and room:askForSkillInvoke(target, self:objectName(), data) then
			room:drawCards(target, math.min(5, from_handcard_num) - handcard_num, self:objectName())
		elseif handcard_num > from_handcard_num then
			room:setPlayerMark(target, "LuaBenyu", from_handcard_num + 1)
			if room:askForUseCard(target, "@@LuaBenyu", "@benyu-discard::"..damage.from:objectName()..":"..tostring(from_handcard_num+1), -1, sgs.Card_MethodDiscard) then
				room:damage(sgs.DamageStruct(self:objectName(), target, damage.from))
			end
		end
		return false
	end
}
--[[
	技能名：奔雷（锁定技）
	相关武将：守卫剑阁·机雷白虎
	描述：准备阶段开始时，攻城器械受到1点雷电伤害。 
]]--
--[[
	技能名：奔袭（锁定技）
	相关武将：一将成名2014·吴懿
	描述：锁定技。你的回合内，你与其他角色的距离-X。你的回合内，若你与所有其他角色距离均为1，其他角色的防具无效，你使用【杀】可以额外选择一个目标。（X为本回合你已使用结算完毕的牌数）
	引用：LuaBenxi、LuaBenxiTargetMod、LuaBenxiDistance
	状态：0405验证通过
]]--
function isAllAdjacent(from, card)
	local rangefix = 0
	if card then
		if card:isVirtualCard() and from:getOffensiveHorse()
			and card:getSubcards():contains(from:getOffensiveHorse():getEffectiveId()) then
			rangefix = 1
		end
	end
	for _, p in sgs.qlist(from:getAliveSiblings()) do
		if from:distanceTo(p, rangefix) ~= 1 then
			return false
		end
	end
	return true
end
LuaBenxi = sgs.CreateTriggerSkill{
	name = "LuaBenxi",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.EventPhaseChanging, sgs.CardEffected, sgs.CardFinished, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "@LuaBenxi", 0)
				room:setPlayerMark(player, "LuaBenxi", 0)
				if player:hasFlag("LuaBenxiArmor") then
					room:setPlayerFlag(player, "-LuaBenxiArmor")
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						room:removePlayerMark(p, "Armor_Nullified")
					end
				end
			end
		elseif event == sgs.CardEffected then
			local from = data:toCardEffect().from
			if from:isAlive() and data:toCardEffect().to:objectName() ~= from:objectName() and from:hasSkill("LuaBenxi") and from:getPhase() ~= sgs.Player_NotActive then
				if from:hasFlag("LuaBenxiArmor") and not isAllAdjacent(from, nil) then
					room:setPlayerFlag(from, "-LuaBenxiArmor")
					for _, p in sgs.qlist(room:getOtherPlayers(from)) do
						room:removePlayerMark(p, "Armor_Nullified")
					end
				elseif isAllAdjacent(from, nil) and not from:hasFlag("LuaBenxiArmor") then
					room:setPlayerFlag(from, "LuaBenxiArmor")
					for _, p in sgs.qlist(room:getOtherPlayers(from)) do
						room:addPlayerMark(p, "Armor_Nullified")
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill
				and player:isAlive() and player:getPhase() ~= sgs.Player_NotActive then
				room:addPlayerMark(player, "LuaBenxi")
				if player:hasSkill("LuaBenxi") then
					room:setPlayerMark(player, "@LuaBenxi", player:getMark("LuaBenxi"))
					if player:hasFlag("LuaBenxiArmor") and not isAllAdjacent(player, nil) then
						room:setPlayerFlag(player, "-LuaBenxiArmor")
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							room:removePlayerMark(p, "Armor_Nullified")
						end
					elseif isAllAdjacent(player, nil) and not player:hasFlag("LuaBenxiArmor") then
						room:setPlayerFlag(player, "LuaBenxiArmor")
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							room:addPlayerMark(p, "Armor_Nullified")
						end
					end
				end
			end
		elseif event == sgs.EventAcquireSkill or event == sgs.EventLoseSkill then
			if data:toString() ~= "LuaBenxi" then return false end
			local num = 0
			if event == sgs.EventAcquireSkill then
				num = player:getMark("LuaBenxi")
				if isAllAdjacent(player, nil) and player:getPhase() ~= sgs.Player_NotActive then
					room:setPlayerFlag(player, "LuaBenxiArmor")
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						room:addPlayerMark(p, "Armor_Nullified")
					end
				end
			else
				if player:hasFlag("LuaBenxiArmor") then
					room:setPlayerFlag(player, "-LuaBenxiArmor")
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						room:removePlayerMark(p, "Armor_Nullified")
					end
				end
			end
			room:setPlayerMark(player, "@LuaBenxi", num)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
LuaBenxiTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaBenxiTargetMod",
	pattern = "Slash",
	extra_target_func = function(self, from, card)
		if from:hasSkill("LuaBenxi") and isAllAdjacent(from, card) then
			return 1
		else
			return 0
		end
	end,
}
LuaBenxiDistance = sgs.CreateDistanceSkill{
	name = "#LuaBenxiDistance",
	correct_func = function(self, from, to)
		if from:hasSkill("LuaBenxi") and from:getPhase() ~= sgs.Player_NotActive then
			return -from:getMark("LuaBenxi")
		end
		return 0
	end,
}
--[[
	技能名：崩坏（锁定技）
	相关武将：林·董卓
	描述：结束阶段开始时，若你的体力值不为场上最少（或之一），你须选择一项：失去1点体力，或失去1点体力上限。
	引用：LuaBenghuai
	状态：0405验证通过
]]--
LuaBenghuai = sgs.CreatePhaseChangeSkill{
	name = "LuaBenghuai",
	frequency = sgs.Skill_Compulsory,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local cantrigger = false
		if player:getPhase() == sgs.Player_Finish then
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHp() > player:getHp() then
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
	描述：结束阶段开始时，你可以将一张手牌移出游戏并选择一名其他角色，该角色的回合开始时，观看该牌，然后选择一项：交给你一张与该牌类型相同的牌并获得该牌，或将该牌置入弃牌堆并失去1点体力。
	引用：LuaBifa
	状态：0405验证通过
]]--
LuaBifaCard = sgs.CreateSkillCard{
	name = "LuaBifa",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getPile("bifa"):isEmpty() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local tag = sgs.QVariant()
		tag:setValue(source)
		target:setTag("BifaSource"..tostring(self:getEffectiveId()), tag)
		target:addToPile("bifa", self, false)
	end
}
LuaBifaVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaBifa",
	response_pattern = "@@LuaBifa" ,
	filter_pattern = ".|.|.|hand" ,
	view_as = function(self, cd)
		local card = LuaBifaCard:clone()
		card:addSubcard(cd)
		return card
	end
}
LuaBifa = sgs.CreatePhaseChangeSkill{
	name = "LuaBifa",
	view_as_skill = LuaBifaVS,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish and not player:isKongcheng() then
			room:askForUseCard(player, "@@LuaBifa", "@bifa-remove")
			return false
		elseif player:getPhase() == sgs.Player_RoundStart and player:getPile("bifa"):length() > 0 then
			local card_id = player:getPile("bifa"):first()
			local chenlin = player:getTag("BifaSource"..tostring(card_id)):toPlayer()
			local ids = sgs.IntList()
			ids:append(card_id)
			 local log = sgs.LogMessage()
			log.type = "$BifaView"
			log.from = player
			log.card_str = tostring(card_id)
			log.arg = self:objectName()
			room:sendLog(log, player)
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
			pattern = pattern.."|.|.|hand"
			local to_give = nil
			if not player:isKongcheng() and chenlin and chenlin:isAlive() then
				to_give = room:askForCard(player, pattern, "@bifa-give", data_for_ai, sgs.Card_MethodNone, chenlin)
 			end
			if chenlin and to_give then
				room:broadcastSkillInvoke(self:objectName(), 2)
				local reasonG = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), chenlin:objectName(), self:objectName(), "")
				room:obtainCard(chenlin, to_give, reasonG, false)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName(), self:objectName(), "")
				room:obtainCard(player, cd, reason, false)					
			else
				room:broadcastSkillInvoke(self:objectName(), 3)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
				room:throwCard(cd, reason, nil)
				room:loseHp(player)
			end
			room:clearAG(player)
			player:removeTag("BifaSource"..tostring(card_id))
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：闭月
	相关武将：标准·貂蝉、SP貂蝉、☆SP貂蝉、1v1·貂蝉1v1、怀旧-标准·貂蝉-旧、SP·台版貂蝉
	描述：结束阶段开始时，你可以摸一张牌。
	引用：LuaBiyue
	状态：0405验证通过
]]--
LuaBiyue = sgs.CreatePhaseChangeSkill{
	name = "LuaBiyue",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				player:drawCards(1, self:objectName())
			end
		end
		return false
	end
}
--[[
	技能名：变天
	相关武将：守卫剑阁·天候孔明
	描述：锁定技。准备阶段开始时，你进行判定：若结果为黑色，直到你的回合开始时，所有己方角色处于“大雾”状态；若结果为红色，指导你的回合开始时，所有对方角色处于“狂风”状态。 
	引用：
	状态：
]]--
--[[
	技能名：秉壹
	相关武将：一将成名2014·顾雍
	描述：结束阶段开始时，若你有手牌，你可以展示所有手牌：若均为同一颜色，你可以令至多X名角色各摸一张牌。（X为你的手牌数）
	引用：LuaBingyi
	状态：0405验证通过
]]--
LuaBingyiCard = sgs.CreateSkillCard{
	name = "LuaBingyiCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		local handcard = player:getHandcards()
		for _, cd in sgs.qlist(handcard) do
			if handcard:first():sameColorWith(cd) then continue end
			return false
		end
		return #targets < player:getHandcardNum()
	end,
	feasible = function(self, targets, player)
		local handcard = player:getHandcards()
		for _, cd in sgs.qlist(handcard) do
			if handcard:first():sameColorWith(cd) then continue end
			return #targets == 0
		end
		return #targets <= player:getHandcardNum()
	end,
	on_use = function(self, room, source, targets)
		room:showAllCards(source)
		for _, p in ipairs(targets) do
			room:drawCards(p, 1, "LuaBingyi")
		end
	end
}
LuaBingyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaBingyi",
	response_pattern = "@@LuaBingyi",
	view_as = function()
		return LuaBingyiCard:clone()
	end
}
LuaBingyi = sgs.CreatePhaseChangeSkill{
	name = "LuaBingyi",
	view_as_skill = LuaBingyiVS,
	on_phasechange = function(self, target)
		if target:getPhase() ~= sgs.Player_Finish or target:isKongcheng() then return false end
		target:getRoom():askForUseCard(target, "@@LuaBingyi", "@bingyi-card")
		return false
	end
}
--[[
	技能名：补益
	相关武将：一将成名·吴国太
	描述：当一名角色进入濒死状态时，你可以展示该角色的一张手牌，若此牌不为基本牌，该角色弃置之，然后回复1点体力。
	引用：LuaBuyi
	状态：0405验证通过
]]--
LuaBuyi = sgs.CreateTriggerSkill{
	name = "LuaBuyi",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local _player = dying.who
		if _player:isKongcheng() then return false end
		if _player:getHp() < 1 and player:askForSkillInvoke(self:objectName(), data) then
			local card
			if player:objectName() == _player:objectName() then
				card = room:askForCardShow(_player, player, "LuaBuyi")
			else
				local id = room:askForCardChosen(player, _player, "h", self:objectName())
				card = sgs.Sanguosha:getCard(id)
			end
			room:showCard(_player, card:getEffectiveId())
			if card:getTypeId() ~= sgs.Card_TypeBasic then
				if not _player:isJilei(card) then
					room:throwCard(card, _player)
				end
				room:broadcastSkillInvoke(self:objectName())
				room:recover(_player, sgs.RecoverStruct(player))
			end
		end
		return false
	end,
}
--[[
	技能名：不屈（锁定技）
	相关武将：风·周泰
	描述：锁定技。每当你处于濒死状态时，你将牌堆顶的一张牌置于武将牌上：若无同点数的“不屈牌”，你回复至1点体力；否则你将此牌置入弃牌堆。若你有“不屈牌”，你的手牌上限等于“不屈牌”的数量。 
	引用：LuaBuqu、LuaBuquMaxCards
	状态：0405验证通过
]]--
LuaBuqu = sgs.CreateTriggerSkill{
	name = "LuaBuqu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, zhoutai, data)
		local room = zhoutai:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() ~= zhoutai:objectName() then
			return false
		end
		if zhoutai:getHp() > 0 then return false end
		room:sendCompulsoryTriggerLog(zhoutai, self:objectName())
		local id = room:drawCard()
		local num = sgs.Sanguosha:getCard(id):getNumber()
		local duplicate = false
		for _, card_id in sgs.qlist(zhoutai:getPile("luabuqu")) do
			if sgs.Sanguosha:getCard(card_id):getNumber() == num then
				duplicate = true
				break
			end
		end
		zhoutai:addToPile("luabuqu", id)
		if duplicate then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
			room:throwCard(sgs.Sanguosha:getCard(id), reason, nil)
		else
			room:recover(zhoutai, sgs.RecoverStruct(zhoutai, nil, 1 - zhoutai:getHp()))
		end
		return false
	end
}
LuaBuquMaxCards = sgs.CreateMaxCardsSkill{
	name = "#LuaBuqu",
	fixed_func = function(self, target)
		local len = target:getPile("luabuqu"):length()
		if len > 0 then
			return len
		else
			return -1
		end
	end
}
--[[
	技能名：不屈
	相关武将：怀旧·周泰
	描述：每当你扣减1点体力后，若你的体力值为0，你可以将牌堆顶的一张牌置于武将牌上，称为“创”，若所有“创”的点数均不同，你不会进入濒死状态。
	引用：LuaNosBuqu、LuaNosBuquRemove
	状态：0405验证通过
]]--
function Remove(zhoutai)
	local room = zhoutai:getRoom()
	local nosbuqu = zhoutai:getPile("luanosbuqu")
	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "LuaNosBuqu", "")
	local need = 1 - zhoutai:getHp()
	if need <= 0 then
		for _, card_id in sgs.qlist(nosbuqu) do
			local log = sgs.LogMessage()
			log.type = "$NosBuquRemove"
			log.from = zhoutai
			log.card_str = sgs.Sanguosha:getCard(card_id):toString()
			room:sendLog(log)
			room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
		end
	else
		local to_remove = nosbuqu:length() - need
		for i = 0, to_remove - 1, 1 do
			room:fillAG(nosbuqu)
			local card_id = room:askForAG(zhoutai, nosbuqu, false, "LuaNosBuqu")
			local log = sgs.LogMessage()
			log.type = "$NosBuquRemove"
			log.from = zhoutai
			log.card_str = sgs.Sanguosha:getCard(card_id):toString()
			room:sendLog(log)
			nosbuqu:removeOne(card_id)
			room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
			room:clearAG()
		end
	end
end
LuaNosBuqu = sgs.CreateTriggerSkill{
	name = "LuaNosBuqu",
	events = {sgs.HpChanged, sgs.AskForPeachesDone},
	priority = {1, 2},
	on_trigger = function(self, event, zhoutai, data)
		local room = zhoutai:getRoom()
		if event == sgs.HpChanged and ((data:toDamage() and data:toDamage().to) or data:toInt() > 0) and zhoutai:getHp() < 1 then
			if room:askForSkillInvoke(zhoutai, self:objectName(), data) then
				room:setTag("LuaNosBuqu", sgs.QVariant(zhoutai:objectName()))
				local nosbuqu = zhoutai:getPile("luanosbuqu")
				local need = 1 - zhoutai:getHp()
				local n = need - nosbuqu:length()
				if n > 0 then
					local card_ids = room:getNCards(n, false)
					zhoutai:addToPile("luanosbuqu", card_ids)
				end
				local nosbuqunew = zhoutai:getPile("luanosbuqu")
				local duplicate_numbers = sgs.IntList()
				local numbers = {}
				for _, card_id in sgs.qlist(nosbuqunew) do
					local card = sgs.Sanguosha:getCard(card_id)
					local number = card:getNumber()
					if table.contains(numbers, number) then
						duplicate_numbers:append(number)
					else
						table.insert(numbers, number)
					end
				end
				if duplicate_numbers:isEmpty() then
					room:setTag("LuaNosBuqu", sgs.QVariant())
					return true
				end
			end
		elseif event == sgs.AskForPeachesDone then
			local nosbuqu = zhoutai:getPile("luanosbuqu")
			if zhoutai:getHp() > 0 then
				return false
			end
			if room:getTag("LuaNosBuqu"):toString() ~= zhoutai:objectName() then
				return false
			end
			room:setTag("LuaNosBuqu", sgs.QVariant())
			local duplicate_numbers = sgs.IntList()
			local numbers = {}
			for _, card_id in sgs.qlist(nosbuqu) do
				local card = sgs.Sanguosha:getCard(card_id)
				local number = card:getNumber()
				if table.contains(numbers, number) then
					duplicate_numbers:append(number)
				else
					table.insert(numbers, number)
				end
			end
			if duplicate_numbers:isEmpty() then
				room:setPlayerFlag(zhoutai, "-Global_Dying")
				return true
			else
				local log = sgs.LogMessage()
				log.type = "#NosBuquDuplicate"
				log.from = zhoutai
				log.arg = duplicate_numbers:length()
				room:sendLog(log)
				for i = 0, duplicate_numbers:length() - 1, 1 do
					local number = duplicate_numbers:at(i)
					local log = sgs.LogMessage()
					log.type = "#NosBuquDuplicateGroup"
					log.from = zhoutai
					log.arg = i + 1
					if number == 10 then
						log.arg2 = 10
					else
						local number_string = "-A23456789-JQK"
						log.arg2 = number_string[number]
					end
					room:sendLog(log)
					for _, card_id in sgs.qlist(nosbuqu) do
						local card = sgs.Sanguosha:getCard(card_id)
						if card:getNumber() == number then
							local log = sgs.LogMessage()
							log.type = "$NosBuquDuplicateItem"
							log.from = zhoutai
							log.card_str = card_id
							room:sendLog(log)
						end
					end
				end
			end
		end
		return false
	end
}
LuaNosBuquRemove = sgs.CreateTriggerSkill{
	name = "#LuaNosBuquRemove",
	events = {sgs.HpRecover, sgs.EventLoseSkill},
	on_trigger = function(self, event, zhoutai, data)
		if event == sgs.HpRecover then
			if zhoutai:getPile("luanosbuqu"):length() > 0 then
				Remove(zhoutai)
			end
			return false
		else
			if data:toString() == "LuaNosBuqu" then
				zhoutai:removePileByName("luanosbuqu")
				if zhoutai:getHp() < 0 then
					zhoutai:getRoom():enterDying(zhoutai, nil)
				end
			end
			return false
		end
	end
}
