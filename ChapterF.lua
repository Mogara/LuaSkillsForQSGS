--[[
	代码速查手册（F区）
	技能索引：
		反间、反间、反馈、放权、放逐、飞影、焚心、愤勇、奉印、扶乱、伏枥、辅佐、父魂
]]--
--[[
	技能名：反间
	相关武将：标准·周瑜
	描述：出牌阶段，你可以令一名其他角色说出一种花色，然后获得你的一张手牌并展示之，若此牌不为其所述之花色，你对该角色造成1点伤害。每阶段限一次。
	状态：验证通过
]]--
LuaFanjianCard = sgs.CreateSkillCard{
	name = "LuaFanjianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local dest = targets[1]
		local id = source:getRandomHandCardId()
		local card = sgs.Sanguosha:getCard(id)
		local suit = room:askForSuit(dest, self:objectName())
		room:getThread():delay()
		dest:obtainCard(card);
		room:showCard(dest, id)
		if card:getSuit() ~= suit then
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.from = source
			damage.to = dest
			room:damage(damage)
		end
	end
}
LuaFanjian = sgs.CreateViewAsSkill{
	name = "LuaFanjian",
	n = 0,
	view_as = function(self, cards)
		local card = LuaFanjianCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#LuaFanjianCard") 
		end
		return false
	end
}
--[[
	技能名：反间
	相关武将：翼·周瑜
	描述：出牌阶段，你可以选择一张手牌，令一名其他角色说出一种花色后展示并获得之，若猜错则其受到你对其造成的1点伤害。每阶段限一次。 
	状态：验证通过
]]--
LuaXNeoFanjianCard = sgs.CreateSkillCard{
	name = "LuaXNeoFanjianCard", 
	target_fixed = false, 
	will_throw = false, 
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local subid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(subid)
		local card_id = card:getEffectiveId()
		local suit = room:askForSuit(target, "LuaXNeoFanjian")
		room:getThread():delay()
		target:obtainCard(self)
		room:showCard(target, card_id)
		if card:getSuit() ~= suit then
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.from = source
			damage.to = target
			room:damage(damage)
		end
	end
}
LuaXNeoFanjian = sgs.CreateViewAsSkill{
	name = "LuaXNeoFanjian", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaXNeoFanjianCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#LuaXNeoFanjianCard")
		end
		return false
	end
}
--[[
	技能名：反馈
	相关武将：标准·司马懿
	描述：每当你受到一次伤害后，你可以获得伤害来源的一张牌。
	状态：验证通过
]]--
LuaFankui = sgs.CreateTriggerSkill{
	name = "LuaFankui",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		local source_data = sgs.QVariant()
		source_data:setValue(source)
		if source then
			if not source:isNude() then
				if room:askForSkillInvoke(player, self:objectName(), source_data) then
					local card_id = room:askForCardChosen(player, source, "he", self:objectName())
					room:obtainCard(player, card_id)
				end
			end
		end
	end
}
--[[
	技能名：放权
	相关武将：山·刘禅
	描述：你可以跳过你的出牌阶段，若如此做，你在回合结束时可以弃置一张手牌令一名其他角色进行一个额外的回合。 
	状态：验证通过
]]--
LuaFangquan = sgs.CreateTriggerSkill{
	name = "LuaFangquan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local nextphase = change.to
		local room = player:getRoom()
		if nextphase == sgs.Player_Play then
			if not player:isSkipped(sgs.Player_Play) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:setPlayerFlag(player, "fangquan")
					player:skip(sgs.Player_Play)
				end
			end
		elseif nextphase == sgs.Player_NotActive then
			if player:hasFlag("fangquan") then
				if not player:isKongcheng() then
					if room:askForDiscard(player, "fangquan", 1, 1, true) then
						local list = room:getOtherPlayers(player)
						local target = room:askForPlayerChosen(player, list, self:objectName())
						local value = sgs.QVariant()
						value:setValue(target)
						room:setTag("FangquanTarget", value)
					end
				end
			end
		end
	end
}
LuaFangquanGive = sgs.CreateTriggerSkill{
	name = "#LuaFangquan-Give",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local tag = room:getTag("FangquanTarget")
		if tag then
			local target = tag:toPlayer()
			room:removeTag("FangquanTarget")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
	end,
	priority = -4
}
--[[
	技能名：放逐
	相关武将：林·曹丕、铜雀台·曹丕
	描述：每当你受到一次伤害后，你可以令一名其他角色摸X张牌（X为你已损失的体力值），然后该角色将其武将牌翻面。
	状态：验证通过
]]--
LuaFangzhu = sgs.CreateTriggerSkill{
	name = "LuaFangzhu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local list = room:getOtherPlayers(player)
			local target = room:askForPlayerChosen(player, list, self:objectName())
			if target then
				local count = player:getLostHp()
				room:drawCards(target, count, self:objectName())
				target:turnOver()
			end
		end
	end
}
--[[
	技能名：飞影（锁定技）
	相关武将：神·曹操、倚天·魏武帝
	描述：其他角色计算的与你的距离+1。
	状态：验证通过
]]--
LuaFeiying = sgs.CreateDistanceSkill{
	name = "LuaFeiying",
	correct_func = function(self, from, to)
		if to:hasSkill("LuaFeiying") then
			return 1
		end
	end,
}
--[[
	技能名：焚心（限定技）
	相关武将：铜雀台·灵雎、SP·灵雎
	描述：当你杀死一名非主公角色时，在其翻开身份牌之前，你可以与该角色交换身份牌。（你的身份为主公时不能发动此技能。）
	状态：验证通过
]]--
LuaXFenxin = sgs.CreateTriggerSkill{
	name = "LuaXFenxin",  
	frequency = sgs.Skill_Limited, 
	events = {sgs.AskForPeachesDone},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local mode = room:getMode()
		if string.sub(mode, -1) == "p" or string.sub(mode, -2) == "pd" or string.sub(mode, -2) == "pz" then
			local dying = data:toDying()
			if dying.damage then
				local killer = dying.damage.from
				if killer and not killer:isLord() then
					if not player:isLord() and player:getHp() <= 0 then
						if killer:hasSkill(self:objectName()) then
							if killer:getMark("@burnheart") > 0 then
								room:setPlayerFlag(player, "FenxinTarget")
								local ai_data = sgs.QVariant()
								ai_data:setValue(player)
								if room:askForSkillInvoke(killer, self:objectName(), ai_data) then
									killer:loseMark("@burnheart")
									local role1 = killer:getRole()
									local role2 = player:getRole()
									killer:setRole(role2)
									room:setPlayerProperty(killer, "role", sgs.QVariant(role2))
									player:setRole(role1)
									room:setPlayerProperty(player, "role", sgs.QVariant(role1))
								end
								room:setPlayerFlag(player, "-FenxinTarget")
								return false
							end
						end
					end
				end
			end
		end
	end, 
	can_trigger = function(self, target)
		return target
	end
}
LuaXFenxinStart = sgs.CreateTriggerSkill{
	name = "#LuaXFenxinStart",
	frequency = sgs.Skill_Frequent,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		player:gainMark("@burnheart", 1)
	end
}
--[[
	技能名：愤勇
	相关武将：☆SP·夏侯惇
	描述：每当你受到一次伤害后，你可以竖置你的体力牌；当你的体力牌为竖置状态时，防止你受到的所有伤害。
	状态：验证通过
]]--
LuaFenyong = sgs.CreateTriggerSkill{
	name = "LuaFenyong",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged, sgs.DamageInflicted}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.Damaged then
			if player:getMark("@fenyong") == 0 then
				if room:askForSkillInvoke(player, self:objectName()) then
					player:gainMark("@fenyong")
				end
			end
		elseif event == sgs.DamageInflicted then
			if player:getMark("@fenyong") > 0 then
				return true
			end
		end
		return false
	end, 
}
LuaFenyongClear = sgs.CreateTriggerSkill{
	name = "#LuaFenyongClear", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		player:loseAllMarks("@fenyong")
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if not target:hasSkill("LuaFenyong") then
				return target:getMark("@fenyong") > 0
			end
		end
		return false
	end
}
--[[
	技能名：奉印
	相关武将：铜雀台·伏完
	描述：其他角色的回合开始时，若其当前的体力值不比你少，你可以交给其一张【杀】，令其跳过其出牌阶段和弃牌阶段。
	状态：验证通过
]]--
LuaXFengyinCard = sgs.CreateSkillCard{
	name = "LuaXFengyinCard", 
	target_fixed = true, 
	will_throw = false, 
	on_use = function(self, room, source, targets) 
		local target = room:getCurrent()
		target:obtainCard(self)
		room:setPlayerFlag(target, "fengyin_target")
	end
}
LuaXFengyinVS = sgs.CreateViewAsSkill{
	name = "LuaXFengyinVS", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash")
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaXFengyinCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXFengyin"
	end
}
LuaXFengyin = sgs.CreateTriggerSkill{
	name = "LuaXFengyin",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseChanging, sgs.EventPhaseStart},  
	view_as_skill = LuaXFengyinVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if splayer then
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_Start then
					if player:getHp() > splayer:getHp() then
						room:askForUseCard(splayer, "@@LuaXFengyin", "@fengyin")
						return false
					end
				end
			end
			if event == sgs.EventPhaseStart then
				if player:hasFlag("fengyin_target") then
					player:skip(sgs.Player_Play)
					player:skip(sgs.Player_Discard)
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
	技能名：扶乱
	相关武将：贴纸·王元姬
	描述：出牌阶段，若你未于此阶段使用过【杀】，你可以弃置三张相同花色的牌并选择攻击范围内的一名其他角色，该角色将武将牌翻面，且此阶段你不可使用【杀】，每阶段限一次。 
]]--
--[[
	技能名：伏枥（限定技）
	相关武将：二将成名·廖化
	描述：当你处于濒死状态时，你可以将体力回复至X点（X为现存势力数），然后将你的武将牌翻面。
	状态：验证通过
]]--
KingdomCount = function(targets)
	local kingdoms = {}
	for _,target in sgs.qlist(targets) do
		local flag = true
		local kingdom = target:getKingdom()
		for _,k in pairs(kingdoms) do
			if k == kingdom then
				flag = false
				break
			end
		end
		if flag then
			table.insert(kingdoms, kingdom)
		end
	end
	return kingdoms
end
LuaFuli = sgs.CreateTriggerSkill{
	name = "LuaFuli",  
	frequency = sgs.Skill_Limited, 
	events = {sgs.AskForPeaches},  
	on_trigger = function(self, event, player, data) 
		local dying_data = data:toDying()
		local dest = dying_data.who
		if dest:objectName() == player:objectName() then
			if player:askForSkillInvoke(self:objectName(), data) then
				player:loseMark("@laoji")
				local room = player:getRoom()
				local players = room:getAlivePlayers()
				local kingdoms = KingdomCount(players)
				local hp = player:getHp()
				local recover = sgs.RecoverStruct()
				recover.recover = #kingdoms - hp
				room:recover(player, recover)
				player:turnOver()
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() then
				if target:hasSkill(self:objectName()) then
					return target:getMark("@laoji") > 0
				end
			end
		end
		return false
	end
}
--[[
	技能名：辅佐
	相关武将：智·张昭
	描述：当有角色拼点时，你可以打出一张点数小于8的手牌，让其中一名角色的拼点牌加上这张牌点数的二分之一（向下取整）
	状态：验证通过（但并不能实际影响拼点结果）
]]--
LuaXFuzuo = sgs.CreateTriggerSkill{
	name = "LuaXFuzuo",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Pindian},   
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local zhangzhao = room:findPlayerBySkillName(self:objectName())
		if zhangzhao then
			local pindian = data:toPindian()
			local source = pindian.from
			local target = pindian.to
			local choices = string.format("%s+%s+%s", source:getGeneralName(), target:getGeneralName(), "cancel")
			local choice = room:askForChoice(zhangzhao, self:objectName(), choices)
			if choice ~= "cancel" then
				local intervention = room:askForCard(zhangzhao, ".|.|~7|hand", "@fuzuo_card")
				if intervention then
					local dest = zhangzhao
					local pindian_card
					if choice == source:getGeneralName() then
						dest = source
						pindian_card = pindian.from_card
					else
						dest = target
						pindian_card = pindian.to_card
					end
					local id = pindian_card:getId()
					local num = pindian_card:getNumber() + intervention:getNumber() / 2
					local new_card = sgs.Sanguosha:getWrappedCard(id)
					new_card:setNumber(num)
					new_card:setSkillName(self:objectName())
					new_card:setModified(true)
					room:broadcastUpdateCard(room:getPlayers(), id, new_card)
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
	技能名：父魂
	相关武将：二将成名·关兴张苞
	描述：摸牌阶段开始时，你可以放弃摸牌，改为从牌堆顶亮出两张牌并获得之，若亮出的牌颜色不同，你获得技能“武圣”、“咆哮”，直到回合结束。
	状态：验证通过
]]--
LuaFuhun = sgs.CreateTriggerSkill{
	name = "LuaFuhun",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Draw then
			if player:askForSkillInvoke(self:objectName()) then
				local id1 = room:drawCard()
				local id2 = room:drawCard()
				local move = sgs.CardsMoveStruct()
				local move2 = sgs.CardsMoveStruct()
				move.card_ids:append(id1)
				move.card_ids:append(id2)
				move.to_place = sgs.Player_PlaceTable
				room:moveCardsAtomic(move, true)
				room:getThread():delay()
				move2 = move
				move2.to_place = sgs.Player_PlaceHand
				move2.to = player
				room:moveCardsAtomic(move2, true)
				local card1 = sgs.Sanguosha:getCard(id1)
				local card2 = sgs.Sanguosha:getCard(id2)
				if card1:isBlack() ~= card2:isBlack() then
					room:setEmotion(player, "good")
					room:acquireSkill(player, "wusheng")
					room:acquireSkill(player, "paoxiao")
					player:setFlags(self:objectName())
				else
					room:setEmotion(player, "bad")
				end
				return true
			end
		elseif phase == sgs.Player_NotActive then
			if player:hasFlag(self:objectName()) then
				room:detachSkillFromPlayer(player, "wusheng")
				room:detachSkillFromPlayer(player, "paoxiao")
			end
		end
	end
}