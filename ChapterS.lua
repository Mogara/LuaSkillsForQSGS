--[[
	代码速查手册（S区）
	技能索引：
		烧营、涉猎、神愤、神戟、神君、神力、神速、神威、神智、师恩、誓仇、识破、恃才、恃勇、授业、淑德、双刃、双雄、水箭、水泳、死谏、死战、颂词、颂威、随势
]]--
--[[
	技能名：烧营
	相关武将：倚天·陆伯言
	描述：当你对一名不处于连环状态的角色造成一次火焰伤害时，你可选择一名其距离为1的另外一名角色并进行一次判定：若判定结果为红色，则你对选择的角色造成一点火焰伤害 
	状态：验证通过
]]--
LuaXShaoying = sgs.CreateTriggerSkill{
	name = "LuaXShaoying",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageComplete},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local source = damage.from
		local target = damage.to
		if player and source then
			if source:hasSkill(self:objectName()) then
				if not target:isChained() then
					if damage.nature == sgs.DamageStruct_Fire then 
						local room = player:getRoom()
						local targets = sgs.SPlayerList()
						local tag = sgs.QVariant(target:objectName())
						room:setTag("Shaoying", tag)
						local allplayers = room:getAlivePlayers()
						for _,p in sgs.qlist(allplayers) do
							if target:distanceTo(p) == 1 then
								targets:append(p)
							end
						end
						if not targets:isEmpty() then
							if source:askForSkillInvoke(self:objectName(), data) then
								local victim = room:askForPlayerChosen(source, targets, self:objectName())
								room:setTag("Shaoying", sgs.QVariant())
								local judge = sgs.JudgeStruct()
								judge.pattern = sgs.QRegExp("(.*):(heart|diamond):(.*)")
								judge.good = true
								judge.reason = self:objectName()
								judge.who = source
								room:judge(judge)
								if judge:isGood() then
									local shaoying_damage = sgs.DamageStruct()
									shaoying_damage.nature = sgs.DamageStruct_Fire
									shaoying_damage.from = source				
									shaoying_damage.to = victim
									room:damage(shaoying_damage)
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
		return target
	end
}
--[[
	技能名：涉猎
	相关武将：神·吕蒙
	描述：摸牌阶段开始时，你可以放弃摸牌，改为从牌堆顶亮出五张牌，你获得不同花色的牌各一张，将其余的牌置入弃牌堆。 
	状态：验证通过
]]--
LuaShelie = sgs.CreateTriggerSkill{
	name = "LuaShelie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Draw then
			return false
		end
		local room = player:getRoom()
		if not player:askForSkillInvoke(self:objectName()) then
			return false
		end
		local card_ids = room:getNCards(5)
		room:fillAG(card_ids)
		while (not card_ids:isEmpty()) do
			local card_id = room:askForAG(player, card_ids, false, self:objectName())
			card_ids:removeOne(card_id)
			local card = sgs.Sanguosha:getCard(card_id)
			local suit = card:getSuit()
			room:takeAG(player, card_id)
			local removelist = {}
			for _,id in sgs.qlist(card_ids) do
				local c = sgs.Sanguosha:getCard(id)
				if c:getSuit() == suit then
					room:takeAG(nil, c:getId())
					table.insert(removelist, id)
				end
			end
			if #removelist > 0 then
				for _,id in ipairs(removelist) do
					if card_ids:contains(id) then
						card_ids:removeOne(id)
					end
				end
			end
		end
		room:broadcastInvoke("clearAG")
		return true
	end
}
--[[
	技能名：神愤
	相关武将：神·吕布
	描述：出牌阶段，你可以弃6枚“暴怒”标记，对所有其他角色各造成1点伤害，所有其他角色先弃置各自装备区里的牌，再弃置四张手牌，然后将你的武将牌翻面。每阶段限一次。
	状态：验证通过
]]--
LuaShenfenCard = sgs.CreateSkillCard{
	name = "LuaShenfenCard", 
	target_fixed = true,
	will_throw = true, 
	on_use = function(self, room, source, targets)
		source:loseMark("@wrath", 6)
		local players = room:getOtherPlayers(source)
		for _,player in sgs.qlist(players) do
			local damage = sgs.DamageStruct()
			damage.card = self
			damage.from = source
			damage.to = player
			room:damage(damage)
		end
		for _,player in sgs.qlist(players) do
			player:throwAllEquips()
		end
		for _,player in sgs.qlist(players) do
			local count = player:getHandcardNum()
			if count <= 4 then
				player:throwAllHandCards()
			else
				room:askForDiscard(player, self:objectName(), 4, 4)
			end
		end
		source:turnOver()
	end
}
LuaShenfen = sgs.CreateViewAsSkill{
	name = "LuaShenfen", 
	n = 0,
	view_as = function(self, cards)
		return LuaShenfenCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:getMark("@wrath") >= 6 then
			return not player:hasUsed("#LuaShenfenCard")
		end
		return false
	end
}
--[[
	技能名：神戟
	相关武将：SP·暴怒战神
	描述：若你的装备区没有武器牌，当你使用【杀】时，你可以额外选择至多两个目标。 
]]--
--[[
	技能名：神君（锁定技）
	相关武将：倚天·陆伯言
	描述：游戏开始时，你必须选择自己的性别。回合开始阶段开始时，你必须倒转性别，异性角色对你造成的非雷电属性伤害无效 
	状态：验证通过
]]--
LuaXShenjun = sgs.CreateTriggerSkill{
	name = "LuaXShenjun",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.GameStart, sgs.EventPhaseStart, sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.GameStart then
			local gender = room:askForChoice(player, self:objectName(), "male+female")
			local is_male = player:isMale()
			if gender == "female" then
				if is_male then
					player:setGender(sgs.General_Female)
				end
			elseif gender == "male" then
				if not is_male then
					player:setGender(sgs.General_Male)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:isMale() then
					player:setGender(sgs.General_Female)
				else
					player:setGender(sgs.General_Male)
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Thunder then
				local source = damage.from
				if source and source:isMale() ~= player:isMale() then
					return true
				end
			end
		end
		return false
	end
}
--[[
	技能名：神力（锁定技）
	相关武将：倚天·古之恶来
	描述：出牌阶段，你使用【杀】造成的第一次伤害+X，X为当前死战标记数且最大为3 
	状态：验证通过
]]--
LuaXShenli = sgs.CreateTriggerSkill{
	name = "LuaXShenli",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.ConfirmDamage},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local slash = damage.card
		if slash and slash:isKindOf("Slash") then
			if player:getPhase() == sgs.Player_Play then
				if not player:hasFlag("shenli") then
					player:setFlags("shenli")
					local x = player:getMark("@struggle")
					if x > 0 then
						x = math.min(3, x)
						damage.damage = damage.damage + x
						data:setValue(damage)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：神速
	相关武将：风·夏侯渊
	描述：你可以选择一至两项：1.跳过你的判定阶段和摸牌阶段。2.跳过你的出牌阶段并弃置一张装备牌。你每选择一项，视为对一名其他角色使用一张【杀】（无距离限制）。
	状态：验证失败
]]--
--[[
	技能名：神威（锁定技）
	相关武将：SP·暴怒战神
	描述：摸牌阶段，你额外摸两张牌；你的手牌上限+2。
	状态：验证通过
]]--
LuaShenwei = sgs.CreateTriggerSkill{
	name = "LuaShenwei", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DrawNCards}, 
	on_trigger = function(self, event, player, data) 
		local count = data:toInt() + 2
		data:setValue(count)
	end
}
LuaShenweiKeep = sgs.CreateMaxCardsSkill{
	name = "#LuaShenwei", 
	extra_func = function(self, target) 
		if target:hasSkill(self:objectName()) then
			return 2
		end
	end
}
--[[
	技能：神智
	相关武将：国战·甘夫人
	描述：回合开始阶段开始时，你可以弃置所有手牌：若你以此法弃置的牌不少于X张，你回复1点体力。（X为你当前的体力值） 
	状态：尚未验证
]]--
--[[
	技能名：师恩
	相关武将：智·司马徽
	描述：其他角色使用非延时锦囊时，可以让你摸一张牌
	状态：验证通过
]]--
LuaXShien = sgs.CreateTriggerSkill{
	name = "LuaXShien",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardUsed, sgs.CardResponsed},  
	on_trigger = function(self, event, player, data) 
		if player and player:getMark("forbid_shien") == 0 then
			local card = nil
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
			elseif event == sgs.CardResponsed then
				card = data:toResponsed().m_card
			end
			if card:isNDTrick() then
				local room = player:getRoom()
				local teacher = room:findPlayerBySkillName(self:objectName())
				if teacher:isAlive() then
					local ai_data = sgs.QVariant()
					ai_data:setValue(teacher)
					if room:askForSkillInvoke(player, self:objectName(), ai_data) then
						teacher:drawCards(1)
					else
						local dontaskmeneither = room:askForChoice(player, "forbid_shien", "yes+no")
						if dontaskmeneither == "yes" then
							player:setMark("forbid_shien", 1)
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
--[[
	技能名：识破
	相关武将：智·田丰
	描述：任意角色判定阶段判定前，你可以弃置两张牌，获得该角色判定区里的所有牌 
	状态：验证通过
]]--
LuaXShipo = sgs.CreateTriggerSkill{
	name = "LuaXShipo",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Judge then
			local judges = player:getJudgingArea()
			if judges:length() > 0 then
				local room = player:getRoom()
				local list = room:getAlivePlayers()
				for _,source in sgs.qlist(list) do
					if source:hasSkill(self:objectName()) then
						if source:getCardCount(true) >= 2 then
							local ai_data = sgs.QVariant()
							ai_data:setValue(player)
							if room:askForSkillInvoke(source, self:objectName(), ai_data) then
								if room:askForDiscard(source, self:objectName(), 2, 2, false, true) then
									for _,jcd in sgs.qlist(judges) do
										source:obtainCard(jcd)
									end
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
		return target
	end
}
--[[
	技能名：誓仇（主公技、限定技）
	相关武将：☆SP·刘备
	描述：你的回合开始时，你可指定一名蜀国角色并交给其两张牌。本盘游戏中，每当你受到伤害时，改为该角色替你受到等量的伤害，然后摸等量的牌，直至该角色第一次进入濒死状态。
	状态：验证通过
]]--
LuaShichou = sgs.CreateTriggerSkill{
	name = "LuaShichou$", 
	frequency = sgs.Skill_Limited, 
	events = {sgs.GameStart, sgs.EventPhaseStart, sgs.DamageInflicted, sgs.Dying, sgs.DamageComplete},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:hasLordSkill(self:objectName()) then
				room:setPlayerMark(player, "@hate", 1)
			end
		elseif event == sgs.EventPhaseStart then
			if player:hasLordSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_Start then
					if player:getMark("shichouInvoke") == 0 then
						if player:getCards("he"):length() > 1 then
							local targets = room:getOtherPlayers(player)
							local victims = sgs.SPlayerList()
							for _,target in sgs.qlist(targets) do
								if target:getKingdom() == "shu" then
									victims:append(target)
								end
							end
							if victims:length() > 0 then
								if player:askForSkillInvoke(self:objectName()) then
									player:loseMark("@hate", 1)
									room:setPlayerMark(player, "shichouInvoke", 1)
									local victim = room:askForPlayerChosen(player, victims, self:objectName())
									room:setPlayerMark(victim, "@chou", 1)
									local tagvalue = sgs.QVariant()
									tagvalue:setValue(victim)
									room:setTag("ShichouTarget", tagvalue)
									local card = room:askForExchange(player, self:objectName(), 2, true, "ShichouGive")
									room:obtainCard(victim, card, false)
								end
							end
						end
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			if player:hasLordSkill(self:objectName(), true) then
				local tag = room:getTag("ShichouTarget")
				if tag then
					local target = tag:toPlayer()
					if target then
						room:setPlayerFlag(target, "Shichou")
						if player:objectName() ~= target:objectName() then
							local damage = data:toDamage()
							damage.to = target
							damage.transfer = true
							room:damage(damage)
							return true
						end
					end
				end
			end
		elseif event == sgs.DamageComplete then
			if player:hasFlag("Shichou") then
				local damage = data:toDamage()
				local count = damage.damage
				player:drawCards(count)
				room:setPlayerFlag(player, "-Shichou")
			end
		elseif event == sgs.Dying then
			if player:getMark("@chou") > 0 then
				player:loseMark("@chou")
				local list = room:getAlivePlayers()
				for _,lord in sgs.qlist(list) do
					if lord:hasLordSkill(self:objectName(), true) then
						local tag = room:getTag("ShichouTarget") 
						local target = tag:toPlayer()
						if target:objectName() == player:objectName() then
							room:removeTag("ShichouTarget")
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
	技能名：恃才（锁定技）
	相关武将：智·许攸
	描述：当你拼点成功时，摸一张牌 
	状态：验证通过
]]--
LuaXShicai = sgs.CreateTriggerSkill{
	name = "LuaXShicai",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Pindian},  
	on_trigger = function(self, event, player, data) 
		if player then
			local room = player:getRoom()
			local xuyou = room:findPlayerBySkillName(self:objectName())
			if xuyou then
				local pindian = data:toPindian()
				local source = pindian.from
				local target = pindian.to
				if source:objectName() == xuyou:objectName() or target:objectName() == xuyou:objectName() then
					local winner
					if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
						winner = source 
					else
						winner = target
					end
					if winner:objectName() == xuyou:objectName() then
						xuyou:drawCards(1)
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end, 
	priority = -1
}
--[[
	技能名：恃勇（锁定技）
	相关武将：二将成名·华雄
	描述：每当你受到一次红色的【杀】或因【酒】生效而伤害+1的【杀】造成的伤害后，你减1点体力上限。
	状态：验证通过
]]--
LuaShiyong = sgs.CreateTriggerSkill{
	name = "LuaShiyong",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local slash = damage.card
		if slash then
			if slash:isKindOf("Slash") then
				if slash:isRed() or slash:hasFlag("drank") then
					local room = player:getRoom()
					room:loseMaxHp(player)
				end
			end
		end
		return false
	end
}
--[[
	技能名：授业
	相关武将：智·司马徽
	描述：出牌阶段，你可以弃置一张红色手牌，指定最多两名其他角色各摸一张牌 
	状态：验证通过
]]--
LuaXShouyeCard = sgs.CreateSkillCard{
	name = "LuaXShouyeCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets < 2 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		effect.to:drawCards(1)
		if source:getMark("jiehuo") == 0 then
			source:gainMark("@shouye")
		end
	end
}
LuaXShouye = sgs.CreateViewAsSkill{
	name = "LuaXShouye", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return to_select:isRed()
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards > 0 then
			local shouye_card = LuaXShouyeCard:clone()
			shouye_card:addSubcard(cards[1]:getId())
			return shouye_card
		end
	end, 
	enabled_at_play = function(self, player)
		if player:getMark("shouyeonce") > 0 then
			return not player:hasUsed("#LuaXShouyeCard")
		end
		return true
	end
}
--[[
	技能名：淑德
	相关武将：贴纸·王元姬
	描述：回合结束阶段开始时，你可以将手牌数补至等同于体力上限的张数。 
	状态：验证通过
]]--
LuaShude = sgs.CreateTriggerSkill{
	name = "LuaShude",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = player:getMaxHp()-player:getHandcardNum()
		if player:getPhase()~=sgs.Player_Finish or x<=0 then return false end
		if room:askForSkillInvoke(player, self:objectName()) then
			player:drawCards(x)
		end
	end
}
--[[
	技能名：淑慎
	相关武将：国战·甘夫人
	描述：每当你回复1点体力后，你可以令一名其他角色摸一张牌。 
	状态：尚未验证
]]--
--[[
	技能名：双刃
	相关武将：国战·纪灵
	描述：出牌阶段开始时，你可以与一名其他角色拼点：若你赢，视为你一名其他角色使用一张无距离限制的普通【杀】（此【杀】不计入出牌阶段使用次数的限制）；若你没赢，你结束出牌阶段。 
	状态：尚未验证
]]--
--[[
	技能名：双雄
	相关武将：火·颜良文丑
	描述：摸牌阶段开始时，你可以放弃摸牌，改为进行一次判定，你获得生效后的判定牌，然后你可以将一张与此判定牌颜色不同的手牌当【决斗】使用，直到回合结束。 
	状态：验证通过
]]--
LuaShuangxiongVS = sgs.CreateViewAsSkill{
	name = "LuaShuangxiongVS", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			local value = sgs.Self:getMark("shuangxiong")
			if value == 1 then
				return to_select:isBlack()
			elseif value == 2 then
				return card:isRed()
			end
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local duel = sgs.Sanguosha:cloneCard("duel", suit, point)
			duel:addSubcard(card)
			duel:setSkillName(self:objectName())
			return duel
		end
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("shuangxiong") > 0
	end
}
LuaShuangxiong = sgs.CreateTriggerSkill{
	name = "LuaShuangxiong",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart, sgs.FinishJudge}, 
	view_as_skill = LuaShuangxiongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player, "shuangxiong", 0)
			elseif player:getPhase() == sgs.Player_Draw then
				if player:askForSkillInvoke(self:objectName()) then
					local judge = sgs.JudgeStruct()
					judge.pattern = sgs.QRegExp("(.*)")
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge.card:isRed() then
						room:setPlayerMark(player, "shuangxiong", 1)
					else
						room:setPlayerMark(player, "shuangxiong", 2)
					end
					return true
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				player:obtainCard(judge.card)
				return true
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
	技能名：水箭
	相关武将：奥运·孙扬
	描述：摸牌阶段摸牌时，你可以额外摸X+1张牌，X为你装备区的牌数量的一半（向下取整）。 
	状态：验证通过
]]--
LuaXShuijian = sgs.CreateTriggerSkill{
	name = "LuaXShuijian",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.DrawNCards},  
	on_trigger = function(self, event, player, data) 
		if player:askForSkillInvoke(self:objectName(), data) then
			local equips = player:getEquips()
			local length = equips:length()
			local extra = (length / 2) + 1
			local count = data:toInt() + extra
			data:setValue(count)
			return false
		end
	end
}
--[[
	技能名：水泳（锁定技）
	相关武将：奥运·叶诗文
	描述：防止你受到的火焰伤害。 
	状态：验证通过
]]--
LuaXShuiyong = sgs.CreateTriggerSkill{
	name = "LuaXShuiyong",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		return damage.nature == sgs.DamageStruct_Fire 
	end
}
--[[
	技能：死谏
	相关武将：国战·田丰
	描述：每当你失去最后的手牌后，你可以弃置一名其他角色的一张牌。 
	状态：尚未验证
]]--
--[[
	技能名：死战（锁定技）
	相关武将：倚天·古之恶来
	描述：当你受到伤害时，防止该伤害并获得与伤害点数等量的死战标记；你的回合结束阶段开始时，你须弃掉所有的X个死战标记并流失X点体力 
	状态：验证通过
]]--
LuaXSizhan = sgs.CreateTriggerSkill{
	name = "LuaXSizhan",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted, sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			player:gainMark("@struggle", damage.damage)
			return true
		elseif event == sgs.EventPhaseStart then	
			if player:getPhase() == sgs.Player_Finish then
				local x = player:getMark("@struggle")
				if x > 0 then
					local room = player:getRoom()
					player:loseMark("@struggle", x)
					room:loseHp(player, x)
				end
				player:setFlags("-shenli")
			end
		end
		return false
	end
}
--[[
	技能名：颂词
	相关武将：SP·陈琳
	描述：出牌阶段，你可以选择一项：1、令一名手牌数小于其当前的体力值的角色摸两张牌。2、令一名手牌数大于其当前的体力值的角色弃置两张牌。每名角色每局游戏限一次。
	状态：验证通过
]]--
LuaSongciCard = sgs.CreateSkillCard{
	name = "LuaSongciCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if to_select:getMark("@songci") == 0 then
			local num = to_select:getHandcardNum()
			local hp = to_select:getHp()
			return num ~= hp
		end
		return false
	end,
	on_effect = function(self, effect) 
		local target = effect.to
		local handcard_num = target:getHandcardNum()
		local hp = target:getHp()
		local room = target:getRoom()
		if handcard_num ~= hp then
			target:gainMark("@songci")
			if handcard_num > hp then
				room:askForDiscard(target, "LuaSongci", 2, 2, false, true)
			elseif handcard_num < hp then
				room:drawCards(target, 2, "LuaSongci")
			end
		end
	end
}
LuaSongci = sgs.CreateViewAsSkill{
	name = "LuaSongci", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaSongciCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:getMark("@songci") == 0 then
			if player:getHandcardNum() ~= player:getHp() then
				return true
			end
		end
		local siblings = player:getSiblings()
		for _,sib in sgs.qlist(siblings) do
			if sib:getMark("@songci") == 0 then
				if sib:getHandcardNum() ~= sib:getHp() then
					return true
				end
			end
		end
		return false
	end
}
LuaSongciClear = sgs.CreateTriggerSkill{
	name = "#LuaSongciClear",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Death},   
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local list = room:getAllPlayers()
		for _,p in sgs.qlist(list) do
			if p:getMark("@songci") > 0 then
				room:setPlayerMark(p, "@songci", 0)
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
	技能名：颂威（主公技）
	相关武将：林·曹丕、铜雀台·曹丕
	描述：其他魏势力角色的判定牌为黑色且生效后，该角色可以令你摸一张牌。
	状态：验证通过
]]--
LuaSongwei = sgs.CreateTriggerSkill{
	name = "LuaSongwei$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.FinishJudge},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
		if card:isBlack() then
			local targets = room:getOtherPlayers(player)
			for _,p in sgs.qlist(targets) do
				if p:hasLordSkill(self:objectName()) then
					if player:askForSkillInvoke(self:objectName()) then
						p:drawCards(1)
						p:setFlags("songweiused")
					end
				end
			end
			targets = room:getAllPlayers()
			for _,p in sgs.qlist(targets) do
				if p:hasFlag("songweiused") then
					p:setFlags("-songweiused")
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:getKingdom() == "wei"
		end
		return false
	end
}
--[[
	技能：随势
	相关武将：国战·田丰
	描述：每当其他角色进入濒死状态时，伤害来源可以令你摸一张牌；每当其他角色死亡时，伤害来源可以令你失去1点体力。
	状态：尚未验证
]]--