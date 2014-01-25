--[[
	代码速查手册（H区）
	技能索引：
		汉统、好施、鹤翼、横江、弘援、弘援、红颜、后援、胡笳、虎威、虎啸、护驾、护援、化身、怀异、缓释、缓释、皇恩、黄天、挥泪、魂姿、火计、祸首、祸水
]]--
--[[
	技能名：汉统
	相关武将：贴纸·刘协
	描述：弃牌阶段，你可以将你弃置的手牌置于武将牌上，称为“诏”。你可以将一张“诏”置入弃牌堆，然后你拥有并发动以下技能之一：“护驾”、“激将”、“救援”、“血裔”，直到当前回合结束。
	引用：LuaXHantong、LuaXHantongKeep
	状态：验证通过
]]--
LuaXHantongRemove = function(room, player)
	local card_ids = player:getPile("hantongpile")
	room:fillAG(card_ids, nil)
	local card_id = room:askForAG(player, card_ids, true, "thshengzhi")
	local players = room:getPlayers()
	for _,p in sgs.qlist(players) do
		p:invoke("clearAG")
	end
	return card_id
end
LuaXHantongCard = sgs.CreateSkillCard{
	name = "LuaXHantongCard",
	filter = function(self, targets, to_select, player)
		if #targets == 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			return player:canSlash(to_select, slash, true)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		if not source:hasFlag("hantongjijiang") then
			local card_id = LuaXHantongRemove(room, source)
			if card_id == -1 then return end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "LuaXHantong", "")
			local card = sgs.Sanguosha:getCard(card_id)
			room:throwCard(card, reason, nil)
		end
		local others = room:getOtherPlayers(source)
		for _,p in sgs.qlist(others) do
			if p:getKingdom() == "shu" then
				local slash = room:askForCard(p, "slash", "@jijiang-slash" , sgs.QVariant() , sgs.CardResponsed)
				if slash then
					local use = sgs.CardUseStruc()
					use.card = slash
					use.to:append(targets[1])
					use.from = source
					room:useCard(use, true)
				else
					room:setPlayerFlag(p, "Hantongjj_failed")
				end
			end
		end
	end,
}
LuaXHantongVS = sgs.CreateViewAsSkill{
	name = "LuaXFHantong",
	n = 0,
	view_as = function(self, cards)
		return LuaXHantongCard:clone()
	end,
	enabled_at_play = function(self, player)
		if not player:getPile("hantongpile"):isEmpty() then
			if not player:hasFlag("Hantongjj_failed") then
				local weapon = player:getWeapon()
				if weapon and weapon:getClassName() == "Crossbow" then
					return true
				elseif player:canSlashWithoutCrossbow() then
					return true
				end
			end
		end
		return false
	end,
}
LuaXHantong = sgs.CreateTriggerSkill{
	name = "LuaXHantong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoving, sgs.EventPhaseStart, sgs.CardAsked, sgs.PreHpRecover, sgs.TargetConfirmed},
	view_as_skill = LuaHantongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local re = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "LuaHantong", "")
		if event == sgs.CardsMoving then
			if player:getPhase() == sgs.Player_Discard then
				local move = data:toMoveOneTime()
				local source = move.from
				if source and source:objectName() == player:objectName() then
					local place = move.to_place
					if place == sgs.Player_DiscardPile then
						if move.from_places:contains(sgs.Player_PlaceHand) then
							if player:askForSkillInvoke(self:objectName()) then
								local ids = move.card_ids
								local dummy = {}
								local i = 0
								for _,card in sgs.qlist(ids) do
									local id = sgs.Sanguosha:getCard(card)
									table.insert(dummy, id)
								end
								local count = #dummy
								if count > 0 then
									for _,c in pairs(dummy) do
										local cid = c:getEffectiveId()
										player:addToPile("hantongpile", cid)
									end
								end
							end
						end
					end
				end
			end
		end
		local hantongs = player:getPile("hantongpile")
		if hantongs:length() > 0 then
			if player:hasFlag("hantong") then
				local others = room:getOtherPlayers(player)
				if event == sgs.CardAsked then
					if data:toString() == "jink" then
						if player:askForSkillInvoke("hujia") then
							if not player:hasFlag("hantonghujia") then
								local card_id = LuaXHantongRemove(room, player)
								if card_id > 0 then
									local card = sgs.Sanguosha:getCard(card_id)
									room:throwCard(card, re, nil)
								end
							end
							for _,p in sgs.qlist(others) do
								local jink
								if p:getKingdom() == "wei" then
									jink = room:askForCard(p, "jink", "@hujia-liuxie", sgs.QVariant(), sgs.CardResponsed)
									if jink then
										room:provide(jink)
										return true
									end
								end
							end
						end
					elseif data:toString() == "slash" then
						if player:hasFlag("hantongjijiang") then
							if player:askForSkillInvoke("jijiang") then
								local card_id = LuaXHantongRemove(room, player)
								if card_id > 0 then
									local card = sgs.Sanguosha:getCard(card_id)
									room:throwCard(card, re, nil)
								end
							end
							for _,p in sgs.qlist(others) do
								local slash
								if p:getKingdom() == "shu" then
									slash = room:askForCard(p, "slash", "@jijiang-slash", sgs.QVariant(), sgs.CardResponsed)
									if slash then
										room:provide(slash)
										return true
									end
								end
							end
						end
					end
				elseif event == sgs.TargetConfirmed then
					local use = data:toCardUse()
					local peach = use.card
					local source = use.from
					if peach:isKindOf("Peach") then
						if source then
							if source:getKingdom() == "wu" then
								if source:objectName() ~= player:objectName() then
									if player:hasFlag("dying") then
										room:setPlayerFlag(player, "jiuyuan-hantong")
										room:setCardFlag(peach, "jiuyuan-hantong")
									end
								end
							end
						end
					end
				elseif event == sgs.PreHpRecover then
					local recover = data:toRecover()
					local peach = recover.card
					if peach then
						if peach:hasFlag("jiuyuan-hantong") then
							if player:askForSkillInvoke("jiuyuan") then
								local card_id = LuaXHantongRemove(room,player)
								if card_id > 0 then
									local card = sgs.Sanguosha:getCard(card_id)
									room:throwCard(card, re, nil)
									recover.recover = recover.recover + 1
									data:setValue(recover)
								end
							end
						end
					end
				end
				if event == sgs.EventPhaseStart then
					if player:getPhase() == sgs.Player_Discard then
						room:setPlayerMark(player, "hantong", 0)
						if player:askForSkillInvoke("xueyi") then
							local card_id = LuaXHantongRemove(room,player)
							if card_id > 0 then
								local card = sgs.Sanguosha:getCard(card_id)
								room:throwCard(card, re, nil)
								local qunnum = 0
								for _,p in sgs.qlist(others) do
									if p:getKingdom() == "qun" then
										qunnum = qunnum + 1
									end
								end
								room:setPlayerMark(player, "hantong", qunnum)
							end
						end
					end
				end
			end
		end
	end,
}
LuaXHantongKeep = sgs.CreateMaxCardsSkill{
	name = "#LuaXHantongKeep",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return 2 * target:getMark("hantong")
		end
		return 0
	end
}
--[[
	技能名：好施
	相关武将：林·鲁肃
	描述：摸牌阶段，你可以额外摸两张牌，若此时你的手牌多于五张，则将一半（向下取整）的手牌交给全场手牌数最少的一名其他角色。
	引用：LuaHaoshiGive、LuaHaoshi、LuaHaoshiVS
	状态：0610验证通过
]]--
LuaHaoshiCard = sgs.CreateSkillCard{
	name = "LuaHaoshiCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) or to_select:objectName() == sgs.Self:objectName() then return false end
		return to_select:getHandcardNum() == sgs.Self:getMark("LuaHaoshi")
	end,
	on_use = function(self, room, source, targets)
		room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, false)
	end
}
LuaHaoshiVS = sgs.CreateViewAsSkill{
	name = "LuaHaoshi",
	n = 999,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		local length = math.floor(sgs.Self:getHandcardNum() / 2)
		return #selected < length
	end,
	view_as = function(self, cards)
		if #cards ~= math.floor(sgs.Self:getHandcardNum() / 2) then return nil end
		local card = LuaHaoshiCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaHaoshi"
	end
}
LuaHaoshiGive = sgs.CreateTriggerSkill{
	name = "#LuaHaoshiGive",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.AfterDrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasFlag("LuaHaoshi") then
			player:setFlags("-LuaHaoshi")
			if player:getHandcardNum() <= 5 then return false end
			local other_players = room:getOtherPlayers(player)
			local least = 1000
			for _, _player in sgs.qlist(other_players) do
				least = math.min(_player:getHandcardNum(), least)
			end
			room:setPlayerMark(player, "LuaHaoshi", least)
			local used = room:askForUseCard(player, "@@LuaHaoshi", "@haoshi", -1, sgs.Card_MethodNone)
			if not used then
				local beggar
				for _, _player in sgs.qlist(other_players) do
					if _player:getHandcardNum() == least then
						beggar = _player
						break
					end
				end
				local n = math.floor(player:getHandcardNum() / 2)
				local to_give = player:handCards():mid(0, n)
				local haoshi_card = LuaHaoshiCard:clone()
				for _, card_id in sgs.qlist(to_give) do
					haoshi_card:addSubcard(card_id)
				end
				local targets = {beggar}
				haoshi_card:on_use(room, player, targets)
			end
		end
	end
}
LuaHaoshi = sgs.CreateTriggerSkill{
	name = "#LuaHaoshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, "LuaHaoshi") then
			room:setPlayerFlag(player, "LuaHaoshi")
			local count = data:toInt() + 2
			data:setValue(count)
		end
	end
}
--[[
	技能名：鹤翼
	相关武将：阵·曹洪
	描述：回合结束时，你可以选择包括你在内的至少两名连续的角色，这些角色（除你外）拥有“飞影”，直到你的下个回合结束时。 
]]--
--[[
	技能名：横江
	相关武将：势·臧霸
	描述：每当你受到1点伤害后，你可以令当前回合角色本回合手牌上限-1，然后其回合结束时，若你于此回合发动过“横江”，且其未于弃牌阶段内弃置牌，你摸一张牌。 
	引用：LuaWangxi
	状态：1217验证通过
	
	DB:效果（处理方法）和源码一致，但我始终觉得有问题。描述写错了么，还是我脑子还没转过来·····
]]--
LuaHengjiang = sgs.CreateMasochismSkill{
	name = "LuaHengjiang",
	
	on_damaged = function(self,player,damage)
		local room = player:getRoom()
		for i = 1, damage.damage, 1 do 
			local current = room:getCurrent()
			if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then
		break 
	end		
			local value = sgs.QVariant()
				value:setValue(current)
			if room:askForSkillInvoke(player,self:objectName(),value) then
				room:addPlayerMark(current,"@hengjiang")
			end
		end
	end

}
LuaHengjiangDraw = sgs.CreateTriggerSkill{
	name = "#LuaHengjiangDraw",
	events = {sgs.TurnStart,sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnStart then
			room:setPlayerMark(player,"@hengjiang",0)
        elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
            if move.from and player:objectName() == move.from:objectName() and player:getPhase() == sgs.Player_Discard and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				player:setFlags("LuaHengjiangDiscarded")
		end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			local zangba = room:findPlayerBySkillName("LuaHengjiang")
			if not zangba then return false end
			if player:getMark("@hengjiang") > 0 then
			local invoke = false
			if not player:hasFlag("LuaHengjiangDiscarded") then
				invoke = true
			end
				player:setFlags("-LuaHengjiangDiscarded")
				room:setPlayerMark(player,"@hengjiang",0)
			if invoke then
				zangba:drawCards(1)	
				end
			end
		end
	end,

	can_trigger = function(self, target)
		return target ~= nil
	end
}
LuaHengjiangMaxCards = sgs.CreateMaxCardsSkill{
	name = "#LuaHengjiangMaxCards",

	extra_func = function(self, target)
	if target:hasSkill("LuaHengjiang") then
		return -target:getMark("@hengjiang")
		end
	end
}
--[[
	技能名：弘援
	相关武将：新3V3·诸葛瑾
	描述：摸牌阶段，你可以少摸一张牌，令其他己方角色各摸一张牌。
	引用：LuaXHongyuan、LuaXHongyuanAct
	状态：验证通过
]]--
Lua3V3_isFriend = function(player,other)
	local tb = { ["lord"] = "warm", ["loyalist"] = "warm", ["renegade"] = "cold", ["rebel"] = "cold" }
	return tb[player:getRole()] == tb[other:getRole()]
end
LuaXHongyuan = sgs.CreateTriggerSkill{
	name = "LuaXHongyuan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			player:setFlags(self:objectName())
			local count = data:toInt() - 1
			data:setValue(count)
		end
	end
}
LuaXHongyuanAct = sgs.CreateTriggerSkill {
	name = "#LuaXHongyuanAct",
	frequency = sgs.Skill_Frequent,
	events = { sgs.AfterDrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if player:hasFlag("LuaXHongyuan") then
				player:setFlags("-LuaXHongyuan")
				for _, other in sgs.qlist(room:getOtherPlayers(player)) do
					if Lua3V3_isFriend(player, other) then
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
	引用：LuaXHongyuan、LuaXHongyuanAct
	状态：验证通过
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
		local room = player:getRoom()
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
	技能名：红颜（锁定技）
	相关武将：风·小乔、SP·王战小乔
	描述：你的黑桃牌均视为红桃牌。
	引用：LuaHongyan
	状态：验证通过
]]--
LuaHongyan = sgs.CreateFilterSkill{
	name = "LuaHongyan",
	view_filter = function(self, to_select)
		return to_select:getSuit() == sgs.Card_Spade
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Heart)
		new_card:setModified(true)
		return new_card
	end
}
--[[
	技能名：后援
	相关武将：智·蒋琬
	描述：出牌阶段，你可以弃置两张手牌，指定一名其他角色摸两张牌，每阶段限一次
	引用：LuaHouyuan
	状态：1217验证通过
]]--
LuaHouyuanCard = sgs.CreateSkillCard{
	name = "LuaHouyuanCard" ,
	on_effect = function(self, effect)
		effect.to:drawCards(2)
	end ,
}
LuaHouyuan = sgs.CreateViewAsSkill{
	name = "LuaHouyuan" ,
	n = 2,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and (#selected < 2)
	end ,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local card = LuaHouyuanCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaHouyuanCard")
	end
}
--[[
	技能名：胡笳
	相关武将：倚天·蔡昭姬
	描述：回合结束阶段开始时，你可以进行判定：若为红色，立即获得此牌，如此往复，直到出现黑色为止，连续发动3次后武将翻面
	引用：LuaCaizhaojiHujia
	状态：1217验证通过
]]--
LuaCaizhaojiHujia = sgs.CreateTriggerSkill{
	name = "LuaCaizhaojiHujia" ,
	events = {sgs.EventPhaseStart, sgs.FinishJudge} ,
	on_trigger = function(self, event, player, data)
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Finish) then
			local times = 0
			local room = player:getRoom()
			while player:askForSkillInvoke(self:objectName()) do
				player:setFlags("LuaCaizhaojiHujia")
				times = times + 1
				if times == 3 then player:turnOver() end
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if judge:isBad() then break end
			end
			player:setFlags("-LuaCaizhaojiHujia")
		elseif event == sgs.FinishJudge then
			if player:hasFlag("LuaCaizhaojiHujia") then
				local judge = data:toJudge()
				if judge.card:isRed() then
					player:obtainCard(judge.card)
				end
			end
		end
		return false
	end
}
--[[
	技能名：虎威
	相关武将：1v1·关羽1v1
	描述：你登场时，你可以视为使用一张【水淹七军】。
]]--
--[[
	技能名：虎啸
	相关武将：SP·关银屏
	描述：你于出牌阶段每使用一张【杀】被【闪】抵消，此阶段你可以额外使用一张【杀】。
	引用：LuaHuxiaoCount、LuaHuxiao、LuaHuxiaoClear
	状态：1217验证通过
]]--
LuaHuxiao = sgs.CreateTargetModSkill{
	name = "LuaHuxiao",
	
	residue_func = function(self, from)
		if from:hasSkill(self:objectName()) then
			return from:getMark(self:objectName())
		else
			return 0
		end
	end
}
LuaHuxiaoCount = sgs.CreateTriggerSkill{
	name = "#LuaHuxiao-count" ,
	events = {sgs.SlashMissed,sgs.EventPhaseChanging},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.SlashMissed then
			if player:getPhase() == sgs.Player_Play then
				room:addPlayerMark(player, "LuaHuxiao")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				if player:getMark("LuaHuxiao") > 0 then
					room:setPlayerMark(player, "LuaHuxiao", 0)
				end
			end
		end
	end
}
LuaHuxiaoClear = sgs.CreateTriggerSkill{
	name = "LuaHuxiao-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaHuxiao" then
			player:getRoom():setPlayerMark(player, "LuaHuxiao", 0)
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：护驾（主公技）
	相关武将：标准·曹操、铜雀台·曹操
	描述：当你需要使用或打出一张【闪】时，你可以令其他魏势力角色打出一张【闪】（视为由你使用或打出）。
	引用：LuaHujia
	状态：0610验证通过
]]--
LuaHujia = sgs.CreateTriggerSkill{
	name = "LuaHujia$",
	frequency = sgs.NotFrequent,
	events = {sgs.CardAsked},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toStringList()[1]
		local prompt = data:toStringList()[2]
		if (pattern ~= "jink") or string.find(prompt, "@hujia-jink") then return false end
		local lieges = room:getLieges("wei", player)
		if lieges:isEmpty() then return false end
		if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
		local tohelp = sgs.QVariant()
		tohelp:setValue(player)
		for _, p in sgs.qlist(lieges) do
			local prompt = string.format("@hujia-jink:%s", player:objectName())
			local jink = room:askForCard(p, "jink", prompt, tohelp, sgs.Card_MethodResponse, player)
			if jink then
				room:provide(jink)
				return true
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
	技能名：护援
	相关武将：阵·曹洪
	描述：结束阶段开始时，你可以将一张装备牌置于一名角色装备区内，然后你弃置该角色距离1的一名角色区域内的一张牌。 
]]--
--[[
	技能名：化身
	相关武将：山·左慈
	描述：所有人都展示武将牌后，你随机获得两张未加入游戏的武将牌，称为“化身牌”，选一张置于你面前并声明该武将的一项技能，你获得该技能且同时将性别和势力属性变成与该武将相同直到“化身牌”被替换。在你的每个回合开始时和结束后，你可以替换“化身牌”，然后（无论是否替换）你为当前的“化身牌”声明一项技能（你不可以声明限定技、觉醒技或主公技）。
	引用：LuaHuashen
	状态：验证通过
]]--
function acquireGenerals(zuoci, n)
	local room = zuoci:getRoom()
	local Huashens = {}
	local Hs_String = zuoci:getTag("LuaHuashens"):toString()
	if Hs_String and Hs_String ~= "" then
		Huashens = Hs_String:split("+")
	end
	for i=1, n, 1 do
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		local banned = {"zuoci", "guzhielai", "dengshizai", "caochong", "jiangboyue", "bgm_xiahoudun"}
		local alives = room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if not table.contains(banned, p:getGeneralName()) then
				table.insert(banned, p:getGeneralName())
			end
			if p:getGeneral2() and not table.contains(banned, p:getGeneral2Name()) then
				table.insert(banned, p:getGeneral2Name())
			end
		end
		for i=1, #generals, 1 do
			if table.contains(banned, generals[i]) then
				table.remove(generals, i)
			end
		end
		if #generals > 0 then
			table.insert(Huashens, generals[math.random(1, #generals)])
		end
	end
	zuoci:setTag("LuaHuashens", sgs.QVariant(table.concat(Huashens, "+")))
end
function askForChooseSkill(zuoci)
	local room = zuoci:getRoom()
	local old_skill = zuoci:getTag("LuaHuashensSkill"):toString()
	if old_skill and zuoci:hasSkill(old_skill) then
		room:detachSkillFromPlayer(zuoci, old_skill)
	end
	zuoci:setTag("LuaHuashensSkill", sgs.QVariant())
	local Hs_String = zuoci:getTag("LuaHuashens"):toString()
	if Hs_String and Hs_String ~= "" then
		local Huashens = Hs_String:split("+")
		local general_name = room:askForGeneral(zuoci, table.concat(Huashens, "+"))
		local general = sgs.Sanguosha:getGeneral(general_name)
		local kingdom = general:getKingdom()
		if zuoci:getKingdom() ~= kingdom then
			if kingdom == "god" then
				kingdom = room:askForKingdom(zuoci)
			end
			room:setPlayerProperty(zuoci, "kingdom", sgs.QVariant(kingdom))
		end
		if zuoci:getGender() ~= general:getGender() then
			zuoci:setGender(general:getGender())
		end
		local sks = {}
		for _,sk in sgs.qlist(general:getVisibleSkillList()) do
			if not sk:isLordSkill() then
				if sk:getFrequency() ~= sgs.Skill_Limited then
					if sk:getFrequency() ~= sgs.Skill_Wake then
						table.insert(sks, sk:objectName())
					end
				end
			end
		end
		local choice = room:askForChoice(zuoci, "LuaHuashen", table.concat(sks, "+"))
		zuoci:setTag("LuaHuashensSkill", sgs.QVariant(choice))
		room:acquireSkill(zuoci, choice)
	end
end
LuaHuashen = sgs.CreateTriggerSkill{
	name = "LuaHuashen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.EventPhaseStart},
	priority = -1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			acquireGenerals(player, 2)
			askForChooseSkill(player)
		else
			local phase = player:getPhase()
			if phase == sgs.Player_RoundStart or phase == sgs.Player_NotActive then
				if room:askForSkillInvoke(player, self:objectName()) then
					askForChooseSkill(player)
				end
			end
		end
	end
}
--[[
	技能名：怀异
	相关武将：3D织梦·司马昭
	描述： 每当你体力值发生一次变化后，你可以摸一张牌。
	引用：LuaXHuaiyi
	状态：尚未验证
]]--
LuaXHuaiyi = sgs.CreateTriggerSkill {
	name = "LuaXHuaiyi",
	events={sgs.HpChanged},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		player:drawCards(1)
	end
}
--[[
	技能名：缓释
	相关武将：新3V3·诸葛瑾
	描述：在一名己方角色的判定牌生效前，你可以打出一张牌代替之。
	引用：LuaXHuanshi
	状态:验证通过
]]--
Lua3V3_isFriend = function(player,other)
	local tb = { ["lord"] = "warm", ["loyalist"] = "warm", ["renegade"] = "cold", ["rebel"] = "cold" }
	return tb[player:getRole()] == tb[other:getRole()]
end
LuaXHuanshiCard = sgs.CreateSkillCard {
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
LuaXHuanshi = sgs.CreateTriggerSkill {
	name = "LuaXHuanshi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForRetrial },
	view_as_skill = LuaXHuanshiVS,
	on_trigger = function(self, event, player, data)
		if player:isNude() then return false end
		local judge = data:toJudge()
		local can_invoke = false
		local room = player:getRoom()
		if Lua3V3_isFriend(player,judge.who) then
			can_invoke = true
		end
		if not can_invoke then
			return false
		end
		local prompt_list = { "@huanshi-card", judge.who:objectName(), self:objectName(), judge.reason, judge.card:getEffectIdString() }
		local prompt = table.concat(prompt_list, ":")
		local pattern = "@LuaXHuanshi"
		local card = room:askForCard(player, pattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end
}
--[[
	技能名：缓释
	相关武将：新3V3·诸葛瑾（身份局）
	描述：每当一名角色的判定牌生效前，你可以令该角色观看你的手牌，然后该角色选择一张牌，你打出该牌代替之。
	引用：LuaXHuanshi
	状态：此为旧版缓释
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
					can_invoke = true
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
		player:setTag("Judge", data)
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
	技能名：皇恩
	相关武将：贴纸·刘协
	描述：每当一张锦囊牌指定了不少于两名目标时，你可以令成为该牌目标的至多X名角色各摸一张牌，则该锦囊牌对这些角色无效。（X为你当前体力值）
	引用：LuaXHuangen
	状态：验证通过
]]--
LuaXHuangenCard = sgs.CreateSkillCard{
	name = "LuaXHuangenCard",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		if #targets < player:getHp() then
			return to_select:hasFlag("huangen")
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		for _,p in ipairs(targets) do
			room:setPlayerFlag(p, "huangenremove")
		end
	end
}
LuaXHuangenVS = sgs.CreateViewAsSkill{
	name = "LuaXHuangen",
	n = 0,
	view_as = function(self, cards)
		return LuaXHuangenCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXHuangen"
	end,
}
LuaXHuangen = sgs.CreateTriggerSkill{
	name = "LuaXHuangen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed},
	view_as_skill = LuaXHuangenVS,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local trick = use.card
		if trick and trick:isKindOf("TrickCard") then
			if use.to:length() >= 2 then
				local room = player:getRoom()
				if trick:subcardsLength() ~= 0 or trick:getEffectiveId() ~= -1 then
					room:moveCardTo(trick, nil, sgs.Player_PlaceTable, true)
				end
				local splayer = room:findPlayerBySkillName(self:objectName())
				if splayer then
					for _,p in sgs.qlist(use.to) do
						room:setPlayerFlag(p,"huangen")
					end
					local x = 1
					local cardname = trick:objectName()
					room:setPlayerFlag(splayer, cardname)
					if room:askForUseCard(splayer,"@@LuaXHuangen","@LuaXHuangen") then
						local newtargets = sgs.SPlayerList()
						for _,p in sgs.qlist(use.to) do
							room:setPlayerFlag(p, "-huangen")
							if p:hasFlag("huangenremove") then
								room:setPlayerFlag(p, "-huangenremove")
								p:drawCards(1)
							else
								newtargets:append(p)
							end
						end
						room:setPlayerFlag(splayer, "-" .. cardname)
						use.to = newtargets
						if use.to:isEmpty() then
							return true
						end
						data:setValue(use)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}
--[[
	技能名：黄天（主公技）
	相关武将：风·张角
	描述：出牌阶段限一次，其他群雄角色的出牌阶段，该角色可以交给你一张【闪】或【闪电】。
	引用：LuaHuangtian；LuaHuangtianVS（技能暗将）
	状态：验证通过
]]--
LuaHuangtianCard = sgs.CreateSkillCard{
	name = "LuaHuangtianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:hasLordSkill("LuaHuangtian") then
				if to_select:objectName() ~= sgs.Self:objectName() then
					return not to_select:hasFlag("HuangtianInvoked")
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local zhangjiao = targets[1]
		if zhangjiao:hasLordSkill("LuaHuangtian") then
			room:setPlayerFlag(zhangjiao, "HuangtianInvoked")
			zhangjiao:obtainCard(self)
			local subcards = self:getSubcards()
			for _,card_id in sgs.qlist(subcards) do
				room:setCardFlag(card_id, "visible")
			end
			room:setEmotion(zhangjiao, "good")
			local zhangjiaos = sgs.SPlayerList()
			local players = room:getOtherPlayers(source)
			for _,p in sgs.qlist(players) do
				if p:hasLordSkill("LuaHuangtian") then
					if not p:hasFlag("HuangtianInvoked") then
						zhangjiaos:append(p)
					end
				end
			end
			if zhangjiaos:length() == 0 then
				room:setPlayerFlag(source, "ForbidHuangtian")
			end
		end
	end
}
LuaHuangtianVS = sgs.CreateViewAsSkill{
	name = "LuaHuangtianVS",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:objectName() == "jink" or to_select:objectName() == "lightning"
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = LuaHuangtianCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getKingdom() == "qun" then
			return not player:hasFlag("ForbidHuangtian")
		end
		return false
	end
}
LuaHuangtian = sgs.CreateTriggerSkill{
	name = "LuaHuangtian$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and player:hasLordSkill(self:objectName()) then
			local others = room:getOtherPlayers(player)
			for _,p in sgs.qlist(others) do
				if not p:hasSkill("LuaHuangtianVS") then
					room:attachSkillToPlayer(p, "LuaHuangtianVS")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from == sgs.Player_Play then
				if player:hasFlag("ForbidHuangtian") then
					room:setPlayerFlag(player, "-ForbidHuangtian")
				end
				local players = room:getOtherPlayers(player)
				for _,p in sgs.qlist(players) do
					if p:hasFlag("HuangtianInvoked") then
						room:setPlayerFlag(p, "-HuangtianInvoked")
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
	技能名：挥泪（锁定技）
	相关武将：一将成名·马谡
	描述：当你被其他角色杀死时，该角色弃置其所有的牌。
	引用：LuaHuilei
	状态：0610验证通过
]]--
LuaHuilei = sgs.CreateTriggerSkill{
	name = "LuaHuilei",
	events = {sgs.Death} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local killer
		if death.damage then
			killer = death.damage.from
		else
			killer = nil
		end
		if killer then
			killer:throwAllHandCardsAndEquips()
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
--[[
	技能名：魂姿（觉醒技）
	相关武将：山·孙策
	描述：回合开始阶段开始时，若你的体力为1，你须减1点体力上限，并获得技能“英姿”和“英魂”。
	引用：LuaHunzi
	状态：1217验证通过
]]--
LuaHunzi = sgs.CreateTriggerSkill{
	name = "LuaHunzi" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "LuaHunzi")
		if room:changeMaxHpForAwakenSkill(player) then
			room:handleAcquireDetachSkills(player, "yingzi|yinghun")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("LuaHunzi") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and (target:getHp() == 1)
	end
}
--[[
	技能名：火计
	相关武将：火·诸葛亮
	描述：你可以将一张红色手牌当【火攻】使用。
	引用：LuaHuoji
	状态：验证通过
]]--
LuaHuoji = sgs.CreateViewAsSkill{
	name = "LuaHuoji",
	n = 1,
	view_filter = function(self, selected, to_select)
		if to_select:isRed() then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local fireattack = sgs.Sanguosha:cloneCard("FireAttack", suit, point)
			fireattack:setSkillName(self:objectName())
			fireattack:addSubcard(id)
			return fireattack
		end
	end
}
--[[
	技能名：祸首（锁定技）
	相关武将：林·孟获
	描述：【南蛮入侵】对你无效；当其他角色使用【南蛮入侵】指定目标后，你是该【南蛮入侵】造成伤害的来源。
	引用：LuaHuoshou、LuaSavageAssaultAvoid
	状态：验证通过
]]--
LuaHuoshou = sgs.CreateTriggerSkill{
	name = "LuaHuoshou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.ConfirmDamage, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				local use = data:toCardUse()
				local card = use.card
				local source = use.from
				if card:isKindOf("SavageAssault") then
					if not source:hasSkill(self:objectName()) then
						local tag = sgs.QVariant()
						tag:setValue(player)
						room:setTag("HuoshouSource", tag)
					end
				end
			end
		elseif event == sgs.ConfirmDamage then
			local tag = room:getTag("HuoshouSource")
			if tag then
				local damage = data:toDamage()
				local card = damage.card
				if card then
					if card:isKindOf("SavageAssault") then
						local source = tag:toPlayer()
						if source:isAlive() then
							damage.from = source
						else
							damage.from = nil
						end
						data:setValue(damage)
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("SavageAssault") then
				room:removeTag("HuoshouSource")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
LuaSavageAssaultAvoid = sgs.CreateTriggerSkill{
	name = "#LuaSavageAssaultAvoid",
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
	技能名：祸水（锁定技）
	相关武将：国战·邹氏
	描述：你的回合内，体力值不少于体力上限一半的其他角色所有武将技能无效。
	引用：LuaHuoshui
	状态：验证通过
]]--
function setHuoshuiFlag(room, player, is_lose)
	local others = room:getOtherPlayers(player)
	for _,pl in sgs.qlist(others) do
		room:setPlayerFlag(pl, is_lose and "-huoshui" or "huoshui")
		room:filterCards(pl, pl:getCards("he"), not is_lose)
	end
end
LuaXHuoshui = sgs.CreateTriggerSkill{
	name = "LuaXHuoshui",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.PostHpReduced, sgs.Death, sgs.MaxHpChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.HpRecover, sgs.PreHpLost},
	on_trigger = function(self, event, player, data)
		if player == nil or player:isDead() then return end
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart
				if player:hasSkill(self:objectName()) then
					setHuoshuiFlag(room, player, false)
				end
			end
		end
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_NotActive then
				if player:hasSkill(self:objectName()) then
					setHuoshuiFlag(room, player, true)
				end
			end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			if player:objectName() ~= death.who:objectName() then
				if player:hasSkill(self:objectName()) then
					setHuoshuiFlag(room, player, true)
				end
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local current = room:getCurrent()
				if current and current:objectName() == player:objectName() then
					setHuoshuiFlag(room, player, true)
				end
			end
		end
		if event == sgs.EventAcquireSkill then
			if data:toString() == self:objectName() then
				if room:getCurrent() and room:getCurrent():objectName() == player:objectName() then
					setHuoshuiFlag(room, player, false)
				end
			end
		end
		if event == sgs.PostHpReduced or event == sgs.PreHpLost then
			if player:hasFlag("huoshui") then
				local x = 0
				if event == sgs.PostHpReduced then
					x = data:toDamage().damage
				else
					x = data:toInt()
				end
				local lhp = player:getHp()
				local xhp = (player:getMaxHp() + 1) / 2
				if lhp < xhp then
					if lhp + x >= xhp then
						room:filterCards(player, player:getCards("he"), false)
					end
				end
			end
		end
		if event == sgs.MaxHpChanged then
			if player:hasFlag("huoshui") then
				room:filterCards(player, player:getCards("he"), true)
			end
		end
		if event == sgs.HpRecover then
			local recov = data:toRecover()
			local nnx = recov.recover
			if player:hasFlag("huoshui") then
				local hp = player:getHp()
				local maxhp_2 = (player:getMaxHp() + 1) / 2
				if hp >= maxhp_2 then
					if hp - nnx < maxhp_2 then
						room:filterCards(player, player:getCards("he"), true)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
	priority = 4
}
