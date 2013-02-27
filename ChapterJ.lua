--[[
	代码速查手册（J区）
	代码索引：
		激昂、激将、鸡肋、疾恶、急救、极略、急速、急袭、集智、坚守、奸雄、将驰、节命、竭缘、结姻、解烦、解惑、尽瘁、禁酒、酒池、酒诗、救援、举荐、举荐、倨傲、据守、据守、巨象、绝汲、绝境、绝境、军威
]]--
--[[
	技能名：激昂
	相关武将：山·孙策
	描述：每当你使用（指定目标后）或被使用（成为目标后）一张【决斗】或红色的【杀】时，你可以摸一张牌。 
	状态：验证通过
]]--
LuaJiang = sgs.CreateTriggerSkill{
	name = "LuaJiang",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local source = use.from
		local targets = use.to
		if source:objectName() == player:objectName() or targets:contains(player) then
			local card = use.card
			if card:isKindOf("Duel") or (card:isKindOf("Slash") and card:isRed()) then
				local room = player:getRoom()
				if room:askForSkillInvoke(player, self:objectName(), data) then
					player:drawCards(1)
				end
			end
		end
	end
}
--[[
	技能名：激将（主公技）
	相关武将：标准·刘备、山·刘禅
	描述：当你需要使用或打出一张【杀】时，你可以令其他蜀势力角色打出一张【杀】（视为由你使用或打出）。
	状态：验证失败
]]--
--[[
	技能名：鸡肋
	相关武将：SP·杨修
	描述：每当你受到伤害时，你可以说出一种牌的类别，令伤害来源不能使用、打出或弃置其此类别的手牌，直到回合结束。
	状态：验证通过
]]--
LuaJilei = sgs.CreateTriggerSkill{
	name = "LuaJilei",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		if source then
			if room:askForSkillInvoke(player, self:objectName(), data) then
			local choice = room:askForChoice(player, self:objectName(), "basic+equip+trick")
				source:jilei(choice)
				source:invoke("jilei", choice)
				source:setFlags("jilei")
			end
		end
	end
}
LuaJileiClear = sgs.CreateTriggerSkill{
	name = "#LuaJileiClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		if phase == sgs.Player_NotActive then
			local room = player:getRoom()
			local list = room:getAllPlayers()
			for _,p in sgs.qlist(list) do
				if p:hasFlag("jilei") then
					p:jilei(".")
					p:invoke("jilei", ".")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return (target ~= nil)
	end
}
--[[
	技能名：疾恶（锁定技）
	相关武将：☆SP·张飞
	描述：你使用的红色【杀】造成的伤害+1。
	状态：验证通过
]]--
LuaJie = sgs.CreateTriggerSkill{
	name = "LuaJie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if card:isKindOf("Slash") and card:isRed() then
				local hurt = damage.damage
				damage.damage = hurt + 1
				data:setValue(damage)
			end
		end
		return false
	end
}
--[[
	技能名：急救
	相关武将：标准·华佗
	描述：你的回合外，你可以将一张红色牌当【桃】使用。
	状态：验证通过
]]--
LuaJijiu = sgs.CreateViewAsSkill{
	name = "LuaJijiu",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isRed()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local peach = sgs.Sanguosha:cloneCard("Peach", suit, point)
			peach:setSkillName(self:objectName())
			peach:addSubcard(id)
			return peach
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		local phase = player:getPhase()
		if phase == sgs.Player_NotActive then
			return string.find(pattern, "peach")
		end
		return false
	end
}
--[[
	技能名：极略
	相关武将：神·司马懿
	描述：弃一枚“忍”标记发动下列一项技能——“鬼才”、“放逐”、“完杀”、“制衡”、“集智”。
	状态：验证失败
]]--
--[[
	技能名：急速
	相关武将：奥运·叶诗文
	描述：你可以跳过你此回合的判定阶段和摸牌阶段。若如此做，视为对一名其他角色使用一张【杀】。 
	状态：验证通过
]]--
LuaXJisuCard = sgs.CreateSkillCard{
	name = "LuaXJisuCard", 
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
		for _,p in pairs(targets) do
			use.to:append(p)
		end
		room:useCard(use)
	end
}
LuaXJisuVS = sgs.CreateViewAsSkill{
	name = "LuaXJisuVS", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXJisuCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXJisu"
	end
}
LuaXJisu = sgs.CreateTriggerSkill{
	name = "LuaXJisu",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseChanging},  
	view_as_skill = LuaXJisuVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local change = data:toPhaseChange()
		local nextphase = change.to
		if nextphase == sgs.Player_Judge then
			if not player:isSkipped(sgs.Player_Judge) then
				if not player:isSkipped(sgs.Player_Draw) then
					if room:askForUseCard(player, "@@LuaXJisu", "@LuaXJisu") then
						player:skip(sgs.Player_Judge)
						player:skip(sgs.Player_Draw)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：急袭
	相关武将：山·邓艾
	描述：你可以将一张“田”当【顺手牵羊】使用。
	状态：验证通过
]]--
LuaJixiCard = sgs.CreateSkillCard{
	name = "LuaJixiCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local fields = source:getPile("field")
		local count = fields:length()
		local id
		if count == 0 then
			return 
		elseif count == 1 then
			id = fields:first()
		else
			room:fillAG(fields, source)
			id = room:askForAG(source, fields, false, self:objectName())
			source:invoke("clearAG")
			if id == -1 then
				return
			end
		end
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuit()
		local point = card:getNumber()
		local snatch = sgs.Sanguosha:cloneCard("Snatch", suit, point)
		snatch:setSkillName(self:objectName())
		snatch:addSubcard(id)
		local list = room:getAlivePlayers()
		local targets = sgs.SPlayerList()
		local emptylist = sgs.PlayerList()
		for _,p in sgs.qlist(list) do
			if snatch:targetFilter(emptylist, p, source) then
				if not source:isProhibited(p, snatch) then
					targets:append(p)
				end
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(source, targets, self:objectName())
			local use = sgs.CardUseStruct()
			use.card = snatch
			use.from = source
			use.to:append(target)
			room:useCard(use)
		end
	end
}
LuaJixi = sgs.CreateViewAsSkill{
	name = "LuaJixi", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaJixiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:getPile("field"):length() > 0
	end
}
--[[
	技能名：集智
	相关武将：标准·黄月英
	描述：当你使用非延时类锦囊牌选择目标后，你可以摸一张牌。
	状态：验证通过
]]--
LuaJizhi = sgs.CreateTriggerSkill{
	name = "LuaJizhi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.CardResponsed},
	on_trigger = function(self, event, player, data)
		local card = nil
		if event == sgs.CardUsed then
			use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponsed then
			local response = data:toResponsed()
			card = response.m_card
		end
		local room = player:getRoom()
		if card:isNDTrick() then		   
			if room:askForSkillInvoke(player, self:objectName()) then
				player:drawCards(1)
			end
		end
		return false
	end
}
--[[
	技能名：坚守
	相关武将：测试·蹲坑曹仁
	描述：回合结束阶段开始时，你可以摸五张牌，然后将你的武将牌翻面 
	状态：验证通过
]]--
LuaXJianshou = sgs.CreateTriggerSkill{
	name = "LuaXJianshou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			if player:askForSkillInvoke(self:objectName(), data) then
				player:drawCards(5, true, self:objectName())
				player:turnOver()
			end
		end
	end
}
--[[
	技能名：奸雄
	相关武将：标准·曹操、铜雀台·曹操
	描述：每当你受到一次伤害后，你可以获得对你造成伤害的牌。
	状态：验证通过
]]--
LuaJianxiong = sgs.CreateTriggerSkill{
	name = "LuaJianxiong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card then
			local id = card:getEffectiveId()
			if room:getCardPlace(id) == sgs.Player_PlaceTable then
				local card_data = sgs.QVariant()
				card_data:setValue(card)
				if room:askForSkillInvoke(player, self:objectName(), card_data) then
					player:obtainCard(card);
				end
			end
		end
	end
}
--[[
	技能名：将驰
	相关武将：二将成名·曹彰
	描述：摸牌阶段，你可以选择一项：1、额外摸一张牌，若如此做，你不能使用或打出【杀】，直到回合结束。2、少摸一张牌，若如此做，出牌阶段你使用【杀】时无距离限制且你可以额外使用一张【杀】，直到回合结束。
	状态：验证通过
]]--
LuaJiangchi = sgs.CreateTriggerSkill{
	name = "LuaJiangchi", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DrawNCards}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local count = data:toInt()
		local choice = room:askForChoice(player, self:objectName(), "jiang+chi+cancel")
		if choice == "jiang" then
			room:setPlayerCardLock(player, "Slash")
			count = count + 1
			data:setValue(count)
		elseif choice == "chi" then
			room:setPlayerFlag(player, "jiangchi_invoke")
			count = count - 1
			data:setValue(count)
		end
	end
}
LuaJiangchiClear = sgs.CreateTriggerSkill{
	name = "#LuaJiangchiClear",
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_NotActive then
			if player:hasCardLock("Slash") then
				local room = player:getRoom()
				room:setPlayerCardLock(player, "-Slash")
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() then
				return target:hasSkill(self:objectName())
			end
		end
		return false
	end
}
--[[
	技能名：节命
	相关武将：火·荀彧
	描述：每当你受到1点伤害后，你可以令一名角色将手牌补至X张（X为该角色的体力上限且至多为5）。
	状态：验证通过
]]--
LuaJieming = sgs.CreateTriggerSkill{
	name = "LuaJieming",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local count = data:toDamage().damage
		for i=1, count, 1 do
			if room:askForSkillInvoke(player, "LuaJieming", data) then
				local targets = room:getAlivePlayers()
				local dest = room:askForPlayerChosen(player, targets, "LuaJieming")
				local toCount = dest:getMaxHp()
				if toCount > 5 then
					toCount = 5
				end
				local hasCount = dest:getHandcardNum()
				local count = toCount - hasCount
				if count > 0 then
					room:drawCards(dest, count, "LuaJieming")
				end
			else
				break
			end
		end
	end
}
--[[
	技能名：竭缘
	相关武将：铜雀台·灵雎、SP·灵雎
	描述：当你对一名其他角色造成伤害时，若其体力值大于或等于你的体力值，你可弃置一张黑色手牌令此伤害+1；当你受到一名其他角色造成的伤害时，若其体力值大于或等于你的体力值，你可弃置一张红色手牌令此伤害-1 
	状态：验证通过
]]--
LuaXJieyuan = sgs.CreateTriggerSkill{
	name = "LuaXJieyuan",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageCaused, sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			local victim = damage.to
			if victim and victim:isAlive() then
				if victim:getHp() >= player:getHp() then
					if victim:objectName() ~= player:objectName() then
						if not player:isKongcheng() then
							if room:askForCard(player, ".black", "@JieyuanIncrease", data, sgs.CardDiscarded) then
								damage.damage = damage.damage + 1
								data:setValue(damage)
							end
						end
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local source = damage.from
			if source and source:isAlive() then
				if source:getHp() >= player:getHp() then
					if source:objectName() ~= player:objectName() then
						if not player:isKongcheng() then
							if room:askForCard(player, ".red", "@JieyuanDecrease", data, sgs.CardDiscarded) then
								damage.damage = damage.damage - 1
								if damage.damage < 1 then
									return true
								end
								data:setValue(damage)
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
	技能名：结姻
	相关武将：标准·孙尚香、SP·孙尚香
	描述：出牌阶段，你可以弃置两张手牌并选择一名已受伤的男性角色，你与其各回复1点体力。每阶段限一次。
	状态：验证通过
]]--
LuaJieyinCard = sgs.CreateSkillCard{
	name = "LuaJieyinCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:isWounded() then
				return to_select:isMale()
			end
		end
		return false
	end,
	on_use = function(self, room, player, targets)
		local dest = targets[1]
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = player
		room:recover(player, recover, true)
		room:recover(dest, recover, true)
	end
}
LuaJieyin = sgs.CreateViewAsSkill{
	name = "LuaJieyin",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected <2 then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local card = LuaJieyinCard:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			return card
		end
	end,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#LuaJieyinCard")
	end
}
--[[
	技能名：解烦
	相关武将：怀旧·韩当
	描述：你的回合外，当一名角色处于濒死状态时，你可以对当前正进行回合的角色使用一张【杀】（无距离限制），此【杀】造成伤害时，你防止此伤害，视为对该濒死角色使用一张【桃】。
	状态：验证通过
]]--
LuaJiefan = sgs.CreateTriggerSkill{
	name = "LuaJiefan", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.AskForPeaches, sgs.DamageCaused, sgs.CardFinished, sgs.CardUsed}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local source = room:findPlayerBySkillName(self:objectName())
		if source then
			local current = room:getCurrent()
			if current and not current:isDead() then
				if event == sgs.CardUsed then
					if source:hasFlag("jiefanUsed") then
						local use = data:toCardUse()
						if use.card:isKindOf("Slash") then
							room:setPlayerFlag(source, "-jiefanUsed")
							room:setCardFlag(use.card, "jiefan-slash")
						end
					end
				elseif event == sgs.AskForPeaches then
					if source:getPhase() == sgs.Player_NotActive then
						if source:askForSkillInvoke(self:objectName(), data) then
							local dying = data:toDying()
							while (true) do
								if source:hasFlag("jiefan_failed") then
									room:setPlayerFlag(source, "-jiefan_failed")
									break
								end
								if dying.who:getHp() > 0 then
									break
								end
								if source:isNude() then
									break
								end
								if current:isDead() then
									break
								end
								if not source:canSlash(current, nil, false) then
									break
								end
								room:setPlayerFlag(source, "jiefanUsed")
								room:setTag("JiefanTarget", data)
								local prompt = string.format("jiefan-slash:%s", dying.who:objectName())
								if not room:askForUseSlashTo(source, current, prompt) then
									room:setPlayerFlag(source, "-jiefanUsed")
									room:removeTag("JiefanTarget")
									break
								end
							end
						end
					end
				elseif event == sgs.DamageCaused then
					local damage = data:toDamage()
					local slash = damage.card
					if slash and slash:isKindOf("Slash") then
						if slash:hasFlag("jiefan-slash") then
							local tag = room:getTag("JiefanTarget")
							local dying = tag:toDying()
							local target = dying.who
							if target and target:getHp() > 0 then
							elseif target and target:isDead() then
							elseif current:hasSkill("wansha") and current:isAlive() and target:objectName() ~= source:objectName() then
							else
								local peach = sgs.Sanguosha:cloneCard("peach", slash:getSuit(), slash:getNumber())
								peach:setSkillName(self:objectName())
								local use = sgs.CardUseStruct()
								use.card = peach
								use.from = source
								use.to:append(target)
								room:setCardFlag(slash, "jiefan_success")
								room:useCard(use)
							end
							return true
						end
					end
					return false
				elseif event == sgs.CardFinished then
					local tag = room:getTag("JiefanTarget")
					if tag then
						local use = data:toCardUse()
						local slash = use.card
						if slash:hasFlag("jiefan-slash") then
							if not slash:hasFlag("jiefan_success") then
								room:setPlayerFlag(source, "jiefan_failed")
								room:removeTag("JiefanTarget")
							end
						end
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
	技能名：解惑（觉醒技）
	相关武将：智·司马徽
	描述：当你发动“授业”目标累计超过6个时，须减去一点体力上限，将技能“授业”改为每阶段限一次，并获得技能“师恩”
	状态：验证通过
]]--
LuaXJiehuo = sgs.CreateTriggerSkill{
	name = "LuaXJiehuo",  
	frequency = sgs.Skill_Wake, 
	events = {sgs.CardFinished},  
	on_trigger = function(self, event, player, data) 
		if player then
			local room = player:getRoom()
			room:setPlayerMark(player, "jiehuo", 1)
			player:loseAllMarks("@shouye")
			room:setPlayerMark(player, "shouyeonce", 1)
			room:acquireSkill(player, "shien")
			room:loseMaxHp(player)
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:getMark("jiehuo") == 0 then
				return target:getMark("@shouye") > 6
			end
		end
		return false
	end
}
--[[
	技能名：尽瘁
	相关武将：智·张昭
	描述：当你死亡时，可令一名角色摸取或者弃置三张牌 
	状态：验证通过
]]--
LuaXJincui = sgs.CreateTriggerSkill{
	name = "LuaXJincui",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data) 
		if player then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local allplayers = room:getAllPlayers()
				local target = room:askForPlayerChosen(player, allplayers, self:objectName())
				local choice = room:askForChoice(player, self:objectName(), "draw+throw")
				if choice == "draw" then
					target:drawCards(3)
				else
					local count = math.min(3, target:getCardCount(true))
					room:askForDiscard(target, self:objectName(), count, count, false, true)
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
	技能名：禁酒（锁定技）
	相关武将：一将成名·高顺
	描述：你的【酒】均视为【杀】。
	状态：验证通过
]]--
LuaJinjiu = sgs.CreateFilterSkill{
	name = "LuaJinjiu",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		if place == sgs.Player_PlaceHand then
			return to_select:objectName() == "analeptic"
		end
		return false
	end, 
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local id = card:getId()
		local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
		slash:setSkillName(self:objectName())
		local vs_card = sgs.Sanguosha:getWrappedCard(id)
		vs_card:takeOver(slash)
		return vs_card
	end
}
--[[
	技能名：酒池
	相关武将：林·董卓
	描述：你可以将一张黑桃手牌当【酒】使用。
	状态：验证通过
]]--
LuaJiuchi = sgs.CreateViewAsSkill{
	name = "LuaJiuchi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return to_select:getSuit() == sgs.Card_Spade
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local analeptic = sgs.Sanguosha:cloneCard("analeptic", suit, point)
			analeptic:setSkillName(self:objectName())
			analeptic:addSubcard(id)
			return analeptic
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("Analeptic")
	end, 
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic")
	end
}
--[[
	技能名：酒诗
	相关武将：一将成名·曹植
	描述：若你的武将牌正面朝上，你可以将你的武将牌翻面，视为使用一张【酒】；若你的武将牌背面朝上时你受到伤害，你可以在伤害结算后将你的武将牌翻转至正面朝上。
	状态：验证通过
]]--
LuaJiushi = sgs.CreateViewAsSkill{
	name = "LuaJiushi",
	n = 0,
	view_as = function(self, cards)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		analeptic:setSkillName(self:objectName())
		return analeptic
	end, 
	enabled_at_play = function(self, player)
		if not player:hasUsed("Analeptic") then
			return player:faceUp()
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		if string.find(pattern, "analeptic") then
			return player:faceUp()
		end
		return false
	end
}
LuaJiushiFlip = sgs.CreateTriggerSkill{
	name = "#LuaJiushiFlip", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardUsed, sgs.PreHpReduced, sgs.DamageComplete},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card:getSkillName() == "LuaJiushi" then
				player:turnOver()
			end
		elseif event == sgs.PreHpReduced then
			local state = player:faceUp()
			local tag = sgs.QVariant(state)
			room:setTag("PredamagedFace", tag)
		elseif event == sgs.DamageComplete then
			local tag = room:getTag("PredamagedFace")
			local faceup = tag:toBool()
			room:removeTag("PredamagedFace")
			local state = player:faceUp()
			if not (faceup or state) then
				if player:askForSkillInvoke(self:objectName(), data) then
					player:turnOver()
				end
			end
		end
	end
}
--[[
	技能名：救援（主公技、锁定技）
	相关武将：标准·孙权、测试·制霸孙权
	描述：其他吴势力角色使用的【桃】指定你为目标后，回复的体力+1。
	状态：验证通过
]]--
LuaJiuyuan = sgs.CreateTriggerSkill{
	name = "LuaJiuyuan$", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.AskForPeachesDone, sgs.TargetConfirmed, sgs.HpRecover},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local peach = use.card
			local source = use.from
			if peach:isKindOf("Peach") then
				if source then
					if source:getKingdom() == "wu" then
						if source:objectName() ~= player:objectName() then
							if player:hasFlag("dying") then
								room:setPlayerFlag(player, "jiuyuan")
								room:setCardFlag(peach, "jiuyuan")
							end
						end
					end
				end
			end
		elseif event == sgs.HpRecover then
			local rec = data:toRecover()
			local peach = rec.card
			if peach then
				if peach:hasFlag("jiuyuan") then
					rec.recover = rec.recover + 1
					data:setValue(rec)
				end
			end
		elseif event == sgs.AskForPeachesDone then
			if player:hasFlag("jiuyuan") then
				room:setPlayerFlag(player, "-jiuyuan")
				if player:getHp() > 0 then
					room:getThread():delay(2000)
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasLordSkill(self:objectName())
		end
		return false
	end
}
--[[
	技能名：举荐
	相关武将：一将成名·徐庶
	描述：回合结束阶段开始时，你可以弃置一张非基本牌，令一名其他角色选择一项：摸两张牌，或回复1点体力，或将其武将牌翻至正面朝上并重置之。
	状态：验证通过
]]--
LuaJujianCard = sgs.CreateSkillCard{
	name = "LuaJujianCard",
	target_fixed = false,
	will_throw = true, 
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local dest = effect.to
		local room = source:getRoom()
		local choicelist = {}
		if dest:isWounded() then
			table.insert(choicelist, "recover")
		end
		if (not dest:faceUp()) or dest:isChained() then
			table.insert(choicelist, "reset")
		end
		local choice
		if #choicelist >= 2 then
			local choiceString = "recover+reset"
			choice = room:askForChoice(dest, "LuaJujian", choiceString)
		else
			choice = "draw"
		end
		if choice == "draw" then
			room:drawCards(player, 2, self:objectName())
		elseif choice == "recover" then
			local recover = sgs.RecoverStruct()
			recover.who = dest
			room:recover(dest, recover)
		elseif choice == "reset" then
			room:setPlayerProperty(dest, "chained", false);
			if not dest:faceUp() then
				dest:turnOver()
			end
		end
	end
}
LuaJujianVS = sgs.CreateViewAsSkill{
	name = "LuaJujianVS", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isKindOf("BasicCard")
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local vs_card = LuaJujianCard:clone()
			vs_card:addSubcard(card)
			return vs_card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jujian"
	end
}
LuaJujian = sgs.CreateTriggerSkill{
	name = "LuaJujian", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = LuaJujianVS, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			if not player:isNude() then
				room:askForUseCard(player, "@@jujian", "@jujian-card")
			end
		end
		return false
	end
}
--[[
	技能名：举荐
	相关武将：怀旧·徐庶
	描述：出牌阶段，你可以弃置至多三张牌，然后令一名其他角色摸等量的牌。若你以此法弃置三张同一类别的牌，你回复1点体力。每阶段限一次。
	状态：验证通过
]]--
LuaNosJujianCard = sgs.CreateSkillCard{
	name = "LuaNosJujianCard",
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect) 
		local n = self:subcardsLength()
		effect.to:drawCards(n)
		local source = effect.from
		local room = source:getRoom()
		if n == 3 then
			local types = {}
			local ids = effect.card:getSubcards()
			for _,id in sgs.qlist(ids) do
				local flag = true
				local card = sgs.Sanguosha:getCard(id)
				local card_type = card:getTypeId()
				for _,t in pairs(types) do
					if t == card_type then
						flag = false
						break
					end
				end
				if flag then
					table.insert(types, card_type)
				end
			end
			if #types == 1 then
				local recover = sgs.RecoverStruct()
				recover.card = self
				recover.who = source
				room:recover(source, recover)
			end
		end
	end
}
LuaNosJujian = sgs.CreateViewAsSkill{
	name = "LuaNosJujian", 
	n = 3, 
	view_filter = function(self, selected, to_select)
		return #selected < 3
	end, 
	view_as = function(self, cards)
		if #cards > 0 then
			local card = LuaNosJujianCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaNosJujianCard")
	end
}
--[[
	技能名：倨傲
	相关武将：智·许攸
	描述：出牌阶段，你可以选择两张手牌背面向上移出游戏，指定一名角色，被指定的角色到下个回合开始阶段时，跳过摸牌阶段，得到你所移出游戏的两张牌。每阶段限一次 
	状态：验证通过
]]--
LuaXJuaoCard = sgs.CreateSkillCard{
	name = "LuaXJuaoCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		return #targets == 0
	end,
	on_effect = function(self, effect) 
		local subcards = self:getSubcards()
		local target = effect.to
		for _,cardid in sgs.qlist(subcards) do
			target:addToPile("hautain", cardid, false)
		end
		target:addMark("juao")
	end
}
LuaXJuaoVS = sgs.CreateViewAsSkill{
	name = "LuaXJuaoVS", 
	n = 2, 
	view_filter = function(self, selected, to_select)
		if #selected <= 2 then
			return not to_select:isEquipped()
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 2 then
			local card = LuaXJuaoCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaXJuaoCard")
	end
}
LuaXJuao = sgs.CreateTriggerSkill{
	name = "LuaXJuao",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	view_as_skill = LuaXJuaoVS, 
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			player:setMark("juao", 0)
			local xuyou = room:findPlayerBySkillName(self:objectName())
			local hautains = player:getPile("hautain")
			for _,card_id in sgs.qlist(hautains) do
				if not xuyou then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "hautain", "")
					local card = sgs.Sanguosha:getCard(card_id)
					room:throwCard(card, reason, nil)
				else
					room:obtainCard(player, card_id)
				end
			end
			if not xuyou then
				return false
			end
			player:skip(sgs.Player_Draw)
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:getMark("juao") > 0
		end
		return false
	end
}
--[[
	技能名：据守
	相关武将：风·曹仁
	描述：回合结束阶段开始时，你可以摸三张牌，然后将你的武将牌翻面。
	状态：验证通过
]]--
LuaJushou = sgs.CreateTriggerSkill{
	name = "LuaJushou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:drawCards(player, 3, self:objectName())
				player:turnOver()
			end
		end
	end
}
--[[
	技能名：据守
	相关武将：翼·曹仁
	描述：回合结束阶段开始时，你可以摸2+X张牌（X为你已损失的体力值），然后将你的武将牌翻面。
	状态：验证通过
]]--
LuaXNeoJushou = sgs.CreateTriggerSkill{
	name = "LuaXNeoJushou",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				local lost = player:getLostHp()
				player:drawCards(2 + lost)
				player:turnOver()
			end
		end
		return false
	end
}
--[[
	技能名：巨象（锁定技）
	相关武将：林·祝融
	描述：【南蛮入侵】对你无效；当其他角色使用的【南蛮入侵】在结算后置入弃牌堆时，你获得之。
	状态：验证通过
]]--
LuaJuxiang = sgs.CreateTriggerSkill{
	name = "LuaJuxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PostCardEffected},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local card = use.card
		if card:isKindOf("SavageAssault") then
			if card:isVirtualCard() then
				return false
			end
			local ids = card:getSubcards()
			if ids:length() == 1 then
				local id = ids:first()
				local sa_card = sgs.Sanguosha:getCard(id)
				if sa_card:isKindOf("SavageAssault") then
					if player then
						local room = player:getRoom()
						local place = room:getCardPlace(id)
						if place == sgs.Player_DiscardPile then
							local targets = room:getAllPlayers()
							for _,p in sgs.qlist(targets) do
								if p:hasSkill(self:objectName()) then
									p:obtainCard(card)
									break
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return not target:hasSkill(self:objectName())
		end
		return false
	end
}
LuaJuxiangSavageAssaultAvoid = sgs.CreateTriggerSkill{
	name = "#LuaJuxiangSavageAssaultAvoid",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			return true
		end
	end
}
--[[
	技能名：绝汲
	相关武将：倚天·张儁乂
	描述：出牌阶段，你可以和一名角色拼点：若你赢，你获得对方的拼点牌，并可立即再次与其拼点，如此反复，直到你没赢或不愿意继续拼点为止。每阶段限一次。 
	状态：验证通过
]]--
LuaXJuejiCard = sgs.CreateSkillCard{
	name = "LuaXJuejiCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return not to_select:isKongcheng()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local success = source:pindian(target, "LuaXJueji", self)
		local data = sgs.QVariant()
		data:setValue(target)
		while success do
			if target:isKongcheng() then
				break
			elseif source:isKongcheng() then
				break
			elseif source:askForSkillInvoke("LuaXJueji", data) then
				success = source:pindian(target, "LuaXJueji")
			else
				break
			end
		end
	end
}
LuaXJueji = sgs.CreateViewAsSkill{
	name = "LuaXJueji", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local juejiCard = LuaXJuejiCard:clone()
			juejiCard:addSubcard(cards[1])
			return juejiCard
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaXJuejiCard")
	end
}
LuaXJuejiGet = sgs.CreateTriggerSkill{
	name = "#LuaXJuejiGet",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Pindian},  
	on_trigger = function(self, event, player, data) 
		local pindian = data:toPindian()
		if pindian.reason == "LuaXJueji" then
			if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
				player:obtainCard(pindian.to_card)
			end
		end
		return false
	end,
	priority = -1
}
--[[
	技能名：绝境（锁定技）
	相关武将：神·赵云
	描述：摸牌阶段，你摸牌的数量改为你已损失的体力值+2；你的手牌上限+2。
	状态：验证通过
]]--
LuaJuejing = sgs.CreateTriggerSkill{
	name = "#LuaJuejingDraw",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local count = data:toInt()
		local lose = player:getLostHp()
		count = count + lose
		data:setValue(count)
	end
}
LuaJuejingKeep = sgs.CreateMaxCardsSkill{
	name = "LuaJuejing",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return 2
		end
	end
}
--[[
	技能名：绝境（锁定技）
	相关武将：测试·高达一号
	描述：摸牌阶段，你不摸牌。每当你的手牌数变化后，若你的手牌数不为4，你须将手牌补至或弃置至四张。
	状态：验证通过
]]--
LuaXNosJuejing = sgs.CreateTriggerSkill{
	name = "LuaXNosJuejing",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardsMoveOneTime, sgs.CardDrawnDone, sgs.EventPhaseChanging},  
	on_trigger = function(self, event, player, data) 
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			local target = move.to
			if not source or source:objectName() ~= player:objectName() then
				if not target or target:objectName() ~= player:objectName() then
					return false
				end
			end
			if move.to_place ~= sgs.Player_PlaceHand then
				if not move.from_places:contains(sgs.Player_PlaceHand) then
					return false
				end
			end
			if player:getPhase() == sgs.Player_Discard then
				return false
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local nextphase = change.to
			if nextphase == sgs.Player_Draw then
				player:skip(nextphase)
				return false
			elseif nextphase ~= sgs.Player_Finish then
				return false
			end
		end
		local count = player:getHandcardNum()
		if count == 4 then
			return false
		elseif count < 4 then
			player:drawCards(4 - count)
		elseif count > 4 then
			local room = player:getRoom()
			room:askForDiscard(player, self:objectName(), count - 4, count - 4)
		end
		return false
	end
}
--[[
	技能名：军威
	相关武将：☆SP·甘宁
	描述：回合结束阶段开始时，你可以将三张“锦”置入弃牌堆。若如此做，你须指定一名角色并令其选择一项：1.亮出一张【闪】，然后由你交给任意一名角色。2.该角色失去1点体力，然后由你选择将其装备区的一张牌移出游戏。在该角色的回合结束后，将以此法移出游戏的装备牌移回原处。
	状态：验证失败
]]--