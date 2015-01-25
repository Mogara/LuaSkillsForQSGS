--[[
	代码速查手册（H区）
	技能索引：
		汉统、好施、鹤翼、横江、弘援、弘援、红颜、后援、胡笳、虎威、虎啸、护驾、护援、化身、怀异、缓释、缓释、皇恩、黄天、挥泪、魂姿、火计、祸首、祸水
]]--
--[[
	技能名：汉统
	相关武将：贴纸·刘协
	描述：弃牌阶段，你可以将你弃置的手牌置于武将牌上，称为“诏”。你可以将一张“诏”置入弃牌堆，然后你拥有并发动以下技能之一：“护驾”、“激将”、“救援”、“血裔”，直到当前回合结束。
	引用：LuaXHantong、LuaXHantongDetach
	状态：1217验证通过
]]--
function hasShuGenerals(player)
	for _,p in sgs.qlist(player:getAliveSiblings()) do
		if p:getKingdom() == "shu" then
			return true
		end
	end
	return false
end
LuaXHantongRemove = function(player)
	local room = player:getRoom()
	local card_ids = player:getPile("pile")
	room:fillAG(card_ids,player)
	local card_id = room:askForAG(player, card_ids, false, "LuaXHantong")
	room:clearAG(player)
	if card_id == -1 then return false end
	card_ids:removeOne(card_id)
	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "LuaXHantong", "")
	local card = sgs.Sanguosha:getCard(card_id)
	room:throwCard(card, reason, nil)
	player:setTag("LuaXHantong",sgs.QVariant(true))
	return true
end
LuaXHantongCard = sgs.CreateSkillCard{
	name = "LuaXHantongCard",
	target_fixed = true,
	on_validate = function(self,card_use)
		local source = card_use.from
		local room = source:getRoom()
		card_use.m_isOwnerUse = false;
		if not LuaXHantongRemove(source) then return false end		
		room:acquireSkill(source, "jijiang");
		if not room:askForUseCard(source, "@jijiang", "@hantong-jijiang")then
			room:setPlayerFlag(source, "Global_JijiangFailed");
			return nil
		end
        return self
	end,
	on_use = function(self, room, source, targets)
	end,
}
LuaXHantongVS = sgs.CreateViewAsSkill{
	name = "LuaXHantong",
	n = 0,
	view_as = function(self, cards)
		return LuaXHantongCard:clone()
	end,
	enabled_at_play = function(self, player)
		if not player:getPile("pile"):isEmpty() then
			if not player:hasFlag("Global_JijiangFailed") then
				return sgs.Slash_IsAvailable(player) and not player:hasSkill("jijiang")
			end
		end
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return player:getPile("pile"):length()>0 and hasShuGenerals(player) and pattern == "slash" and 
		sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and
		not player:hasFlag("Global_JijiangFailed") and not player:hasSkill("jijiang")
	end
}
LuaXHantong = sgs.CreateTriggerSkill{
	name = "LuaXHantong",
	events = {sgs.BeforeCardsMove,sgs.CardAsked, sgs.EventPhaseStart, sgs.TargetConfirmed},
	view_as_skill = LuaXHantongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BeforeCardsMove then
			if player:getPhase() ~= sgs.Player_Discard then return false end
			local move = data:toMoveOneTime()
			if 	move.from:objectName() ~= player:objectName() then return false end
			if move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
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
							player:addToPile("pile", cid)
							ids:removeOne(cid)
						end
					end
					data:setValue(move)
				end
			end
			return false
		end
		local hantongs = player:getPile("pile")
		if hantongs:length() > 0 then
			if event == sgs.CardAsked then
				local pattern = data:toStringList()[1]
				if pattern == "slash" and (not player:hasFlag("Global_JijiangFailed")) and not player:hasSkill("jijiang")then
					if (room:askForSkillInvoke(player,self:objectName())) then 
						if not LuaXHantongRemove(player) then return false end
						room:acquireSkill(player, "jijiang")
					end
				elseif pattern == "jink" and not player:hasSkill("hujia") then
					if (room:askForSkillInvoke(player,self:objectName()))then
						if not LuaXHantongRemove(player) then return false end
						room:acquireSkill(player, "hujia")
					end
				end
			elseif event == sgs.TargetConfirmed then
				local use = data:toCardUse()
				if (not use.card:isKindOf("Peach"))or(not use.from)or(use.from:getKingdom() ~= "wu")or(player:objectName() == use.from:objectName())or(not player:hasFlag("Global_Dying"))or(player:hasSkill("jiuyuan")) then return false end
				if room:askForSkillInvoke(player,self:objectName()) then
					if not LuaXHantongRemove(player) then return false end
					room:acquireSkill(player, "jiuyuan")
				end
			elseif event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Discard then
					if player:getPhase() ~= sgs.Player_Discard or player:hasSkill("xueyi") then return false end
					if room:askForSkillInvoke(player,self:objectName()) then
						if not LuaXHantongRemove(player) then return false end
						room:acquireSkill(player, "xueyi")
					end
				end
			end				
		end
	end,
	priority = 3,
}
LuaXHantongDetach = sgs.CreateTriggerSkill{
	name = "#LuaXHantongDetach", 
	events = {sgs.EventPhaseChanging}, 
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local room = player:getRoom()
        if change.to ~= sgs.Player_NotActive then return false end
        for _,p in sgs.qlist(room:getAllPlayers())do
            if p:getTag("LuaXHantong"):toBool() then
				room:handleAcquireDetachSkills(p, "-hujia|-jijiang|-jiuyuan|-xueyi")
				p:removeTag("LuaXHantong")
			end
        end
        return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--[[
	技能名：好施
	相关武将：林·鲁肃
	描述：摸牌阶段，你可以额外摸两张牌，若此时你的手牌多于五张，则将一半（向下取整）的手牌交给全场手牌数最少的一名其他角色。
	引用：LuaHaoshiGive、LuaHaoshi、LuaHaoshiVS
	状态：1217验证通过
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
	name = "LuaHaoshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},
	view_as_skill = LuaHaoshiVS,
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
	引用：LuaHeyi
	状态：1217验证通过
]]--
LuaHeyiCard = sgs.CreateSkillCard{
	name = "LuaHeyiCard", 
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select) 
		return #targets < 2
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets) 
		local data = sgs.QVariant()
		data:setValue(source)
		room:setTag("LuaHeyiSource",data)
		local players = room:getAllPlayers()
		local index1,index2 = players:indexOf(targets[1]), players:indexOf(targets[2])
		local index_self = players:indexOf(source)
		local cont_targets = sgs.SPlayerList()
		if index1 == index_self or index2 == index_self then
			while true do
				cont_targets:append(players:at(index1));
				if index1 == index2 then break end
				index1 = index1 + 1
				if index1 >= players:length() then
					index1 = index1 - players:length()
				end
			end
		else 
			if index1 > index2 then
				local temp = index1
				index1 = index2
				index2 = temp
				temp = nil
			end
			if (index_self > index1 and index_self < index2)then
				for i = index1,index2,1 do
					cont_targets:append(players:at(i))
				end
			else 
				while true do
					cont_targets:append(players:at(index2))
					if index1 == index2 then break end
					index2 = index2 + 1
					if index2 >= players:length() then
						index2 = index2 - players:length()
					end
				end
			end
		end
		cont_targets:removeOne(source)
		local list = {}
		for _,p in sgs.qlist(cont_targets)do
			if not p:isAlive() then continue end
			table.insert(list,p:objectName())
			source:setTag("LuaHeyi",sgs.QVariant(table.concat(list,"+")))
			room:acquireSkill(p, "feiying")
		end
	end,
}

LuaHeyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaHeyi", 
	response_pattern = "@@LuaHeyi",
	view_as = function(self, cards) 
		return LuaHeyiCard:clone()
	end, 
}

LuaHeyi = sgs.CreateTriggerSkill{
	name = "LuaHeyi", 
	events = {sgs.EventPhaseChanging,sgs.Death}, 
	view_as_skill = LuaHeyiVS,
	on_trigger = function(self, triggerEvent, player, data)
		local room = player:getRoom()
		if triggerEvent == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName() then
                return false
			end
        elseif triggerEvent == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive then
                return false
			end
        end
        if room:getTag("LuaHeyiSource"):toPlayer() and room:getTag("LuaHeyiSource"):toPlayer():objectName() == player:objectName()then
            room:removeTag("LuaHeyiSource")
            local list = player:getTag(self:objectName()):toString():split("+");
            player:removeTag(self:objectName())
            for _,p in sgs.qlist(room:getOtherPlayers(player))do
                if table.contains(list,p:objectName()) then
                    room:detachSkillFromPlayer(p, "feiying", false, true)
				end
            end
        end
        if player and player:isAlive() and player:hasSkill(self:objectName()) and triggerEvent == sgs.EventPhaseChanging then
            room:askForUseCard(player, "@@LuaHeyi", "@LuaHeyi")
		end
        return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 2
}
--[[
	技能名：横江
	相关武将：势·臧霸
	描述：每当你受到1点伤害后，你可以令当前回合角色本回合手牌上限-1，然后其回合结束时，若你于此回合发动过“横江”，且其未于弃牌阶段内弃置牌，你摸一张牌。 
	引用：LuaHengjiang,LuaHengjiangDraw,LuaHengjiangMaxcards
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
		return -target:getMark("@hengjiang")
	end
}
--[[
	技能名：弘援
	相关武将：新3V3·诸葛瑾
	描述：摸牌阶段，你可以少摸一张牌，令其他己方角色各摸一张牌。
	引用：LuaXHongyuan、LuaXHongyuanAct
	状态：1217验证通过
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
	引用：LuaHongyuan、LuaHongyuanAct
	状态：1217验证通过
]]--
LuaHongyuanCard = sgs.CreateSkillCard{
	name = "LuaHongyuanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, Self)
		if to_select:objectName() ~= Self:objectName() then
			return #targets < 2
		end
		return false
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("LuaHongyuan_Target")
	end
}
LuaHongyuanVS = sgs.CreateViewAsSkill{
	name = "LuaHongyuan",
	n = 0,
	view_as = function(self, cards)
		return LuaHongyuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaHongyuan"
	end
}
LuaHongyuan = sgs.CreateTriggerSkill{
	name = "LuaHongyuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},
	view_as_skill = LuaHongyuanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForUseCard(player, "@@LuaHongyuan", "@hongyuan") then
			local count = data:toInt() - 1
			data:setValue(count)
			player:setFlags("LuaHongyuan")
		end
		return false
	end
}
LuaHongyuanAct = sgs.CreateTriggerSkill{
	name = "#LuaHongyuanAct",
	frequency = sgs.Skill_Frequent,
	events = {sgs.AfterDrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw and player:hasFlag("LuaHongyuan") then
			player:setFlags("-LuaHongyuan")
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers())do
				if p:hasFlag("LuaHongyuan_Target") then
					p:setFlags("-LuaHongyuan_Target")
					targets:append(p)
				end
			end
			room:drawCards(targets,1,"LuaHongyuan")
		end
		return false
	end
}
--[[
	技能名：红颜（锁定技）
	相关武将：风·小乔、SP·王战小乔
	描述：你的黑桃牌均视为红桃牌。
	引用：LuaHongyan
	状态：1217验证通过
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
	状态：1217验证通过
]]--
LuaHuwei = sgs.CreateTriggerSkill{
	name = "LuaHuwei", 
	events = {sgs.Debut}, 
	on_trigger = function(self, event, player, data)
		local drowning = sgs.Sanguosha:cloneCard("drowning")
		local opponent = player:getNext()
		if not opponent:isAlive() then return false end
        drowning:setSkillName("_LuaHuwei")
        if not (drowning:isAvailable(player) and player:isProhibited(opponent, drowning)) then
            drowning:deleteLater()
            return false
        end
        if room:askForSkillInvoke(player, objectName()) then
            room:useCard(CardUseStruct(drowning,player,opponent),false)
		end
        return false
	end,
}

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
	状态：1217验证通过
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
			local jink = room:askForCard(p, "jink", prompt, tohelp, sgs.Card_MethodResponse, player, false,"", true)
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
	状态：1217验证通过
	注备：Xusine1131(数字君)：我真应该扇自己两巴掌……
]]--
LuaHuyuanCard = sgs.CreateSkillCard{
	name = "LuaHuyuanCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	
	filter = function(self, targets, to_select)
		if not #targets == 0 then return false end
		local card = sgs.Sanguosha:getCard(self:getEffectiveId())
		local equip = card:getRealCard():toEquipCard()
		local index = equip:location()
		return to_select:getEquip(index) == nil
	end,
	
	on_effect = function(self, effect)
		local caohong = effect.from
		local room = caohong:getRoom()
		room:moveCardTo(self, caohong, effect.to, sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, caohong:objectName(), "LuaYuanhu", ""))
		local card = sgs.Sanguosha:getCard(self:getEffectiveId())
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if effect.to:distanceTo(p) == 1 and caohong:canDiscard(p, "he") then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
		local to_dismantle = room:askForPlayerChosen(caohong, targets, "LuaHuyuan", "@huyuan-discard:" .. effect.to:objectName())
		local card_id = room:askForCardChosen(caohong, to_dismantle, "he", "LuaHuyuan", false,sgs.Card_MethodDiscard)
			room:throwCard(sgs.Sanguosha:getCard(card_id), to_dismantle, caohong)
		end
	end
}
LuaHuyuanVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaHuyuan",
	filter_pattern = "EquipCard",
	response_pattern = "@@LuaHuyuan",
	view_as = function(self, card)
		local first = LuaHuyuanCard:clone()
			first:addSubcard(card:getId())
			first:setSkillName(self:objectName())
		return first
	end,

}
LuaHuyuan = sgs.CreatePhaseChangeSkill{
	name = "LuaHuyuan",
	view_as_skill = LuaHuyuanVS,
	on_phasechange = function(self,target)
		local room = target:getRoom()
		if target:getPhase() == sgs.Player_Finish and not target:isNude() then
			room:askForUseCard(target, "@@LuaHuyuan", "@huyuan-equip", -1, sgs.Card_MethodNone)
		end
	end
}
--[[
	技能名：化身
	相关武将：山·左慈
	描述：所有人都展示武将牌后，你随机获得两张未加入游戏的武将牌，称为“化身牌”，选一张置于你面前并声明该武将的一项技能，你获得该技能且同时将性别和势力属性变成与该武将相同直到“化身牌”被替换。在你的每个回合开始时和结束后，你可以替换“化身牌”，然后（无论是否替换）你为当前的“化身牌”声明一项技能（你不可以声明限定技、觉醒技或主公技）。
	引用：LuaHuashen LuaHuashenDetach
	状态：1217验证通过（源码功能完全实现）
	备注：Xusine（所谓的数字君1131561728）：这个技能使用了JsonForLua的库，请将json.lua放在游戏目录或者放在lua\lib
]]--

local json = require ("json")
function isNormalGameMode (mode_name)
	return mode_name:endsWith("p") or mode_name:endsWith("pd") or mode_name:endsWith("pz")
end
function GetAvailableGenerals(zuoci) ----完全按照源码写的，累死了……
	local all = sgs.Sanguosha:getLimitedGeneralNames()
    local room = zuoci:getRoom()
        if (isNormalGameMode(room:getMode()) or room:getMode():find("_mini_")or room:getMode() == "custom_scenario") then
			table.removeTable(all,sgs.GetConfig("Banlist/Roles",""):split(","))
        elseif (room:getMode() == "04_1v3") then
			table.removeTable(all,sgs.GetConfig("Banlist/HulaoPass",""):split(","))
        elseif (room:getMode() == "06_XMode") then
			table.removeTable(all,sgs.GetConfig("Banlist/XMode",""):split(","))
            for _,p in sgs.qlist(room:getAlivePlayers())do
				table.removeTable(all,(p:getTag("XModeBackup"):toStringList()) or {})
			end
        elseif (room:getMode() == "02_1v1") then
			table.removeTable(all,sgs.GetConfig("Banlist/1v1",""):split(","))
            for _,p in sgs.qlist(room:getAlivePlayers())do
				table.removeTable(all,(p:getTag("1v1Arrange"):toStringList()) or {})
			end
        end
        local Huashens = {}
		local Hs_String = zuoci:getTag("LuaHuashens"):toString()
		if Hs_String and Hs_String ~= "" then
			Huashens = Hs_String:split("+")
		end
		table.removeTable(all,Huashens)
        for _,player in sgs.qlist(room:getAlivePlayers())do
            local name = player:getGeneralName()
            if sgs.Sanguosha:isGeneralHidden(name) then
                local fname = sgs.Sanguosha:findConvertFrom(name);
                if fname ~= "" then name = fname end
            end
            table.removeOne(all,name)

            if player:getGeneral2() == nil then continue end

            name = player:getGeneral2Name();
            if sgs.Sanguosha:isGeneralHidden(name) then
                local fname = sgs.Sanguosha:findConvertFrom(name);
                if fname ~= "" then name = fname end
            end
            table.removeOne(all,name)
        end

        local banned = {"zuoci", "guzhielai", "dengshizai", "caochong", "jiangboyue", "bgm_xiahoudun"}
		table.removeTable(all,banned)

        return all
end
function AcquireGenerals(zuoci, n)
	local room = zuoci:getRoom();
    local Huashens = {}
	local Hs_String = zuoci:getTag("LuaHuashens"):toString()
	if Hs_String and Hs_String ~= "" then
		Huashens = Hs_String:split("+")
	end
    local list = GetAvailableGenerals(zuoci)
    if #list == 0 then return end
    n = math.min(n, #list)
	local acquired = {}
    repeat
		local rand = math.random(1,#list)
		if not table.contains(acquired,list[rand]) then
			table.insert(acquired,(list[rand]))
		end
	until #acquired == n
	
        for _,name in pairs(acquired)do
            table.insert(Huashens,name)
            localgeneral = sgs.Sanguosha:getGeneral(name)
            if general then
                for _,skill in sgs.list(general:getTriggerSkills()) do
                    if skill:isVisible() then
                        room:getThread():addTriggerSkill(skill)
					end
                end
            end
        end
        zuoci:setTag("LuaHuashens", sgs.QVariant(table.concat(Huashens, "+")))

        local hidden = {}
		for i = 1,n,1 do
			table.insert(hidden,"unknown")
		end
        for _,p in sgs.qlist(room:getAllPlayers())do
			local splist = sgs.SPlayerList()
			splist:append(p)
            if p:objectName() == zuoci:objectName() then
                room:doAnimate(4, zuoci:objectName(), table.concat(acquired,":"), splist)
            else
                room:doAnimate(4, zuoci:objectName(),table.concat(hidden,":"),splist);
			end
        end

        local log = sgs.LogMessage()
        log.type = "#GetHuashen"
        log.from = zuoci
        log.arg = n
        log.arg2 = #Huashens
        room:sendLog(log)
		--Json大法好 ^_^
		local jsonLog ={
			"#GetHuashenDetail",
			zuoci:objectName(),
			"",
			"",
			table.concat(acquired,"\\, \\"),
			"",
		}
        room:doNotify(zuoci,sgs.CommandType.S_COMMAND_LOG_SKILL,json.encode(jsonLog));
        room:setPlayerMark(zuoci, "@huashen", #Huashens)
end
function SelectSkill(zuoci)
	local room = zuoci:getRoom();
    local ac_dt_list = {}
	local huashen_skill = zuoci:getTag("LuaHuashenSkill"):toString();
        if huashen_skill ~= "" then
            table.insert(ac_dt_list,"-"..huashen_skill)
		end
        local Huashens = {}
		local Hs_String = zuoci:getTag("LuaHuashens"):toString()
		if Hs_String and Hs_String ~= "" then
			Huashens = Hs_String:split("+")
		end
        if #Huashens == 0 then return end
        local huashen_generals = {}
        for _,huashen in pairs(Huashens)do
            table.insert(huashen_generals,huashen)
		end
        local skill_names = {}
        local skill_name
        local general 
        local ai = zuoci:getAI();
        if (ai) then
			local hash = {}
            for _,general_name in pairs (huashen_generals) do
                local general = sgs.Sanguosha:getGeneral(general_name)
                for _,skill in (general:getVisibleSkillList())do
                    if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
                        continue
					end
                    if not table.contains(skill_names,skill:objectName()) then
                        hash[skill:objectName()] = general;
                        table.insert(skill_names,skill:objectName())
                    end
                end
            end
            if #skill_names == 0 then return end
            skill_name = ai:askForChoice("huashen",table.concat(skill_names,"+"), sgs.QVariant());
            general = hash[skill_name]
        else
			local general_name = room:askForGeneral(zuoci, table.concat(huashen_generals,"+"))
            general = sgs.Sanguosha:getGeneral(general_name)
			assert(general)
            for _,skill in sgs.qlist(general:getVisibleSkillList())do
                if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
                    continue
				end
                if not table.contains(skill_names,skill:objectName()) then
                    table.insert(skill_names,skill:objectName())
                end
            end
            if #skill_names > 0 then
                skill_name = room:askForChoice(zuoci, "huashen",table.concat(skill_names,"+"))
			end
        end
        local kingdom = general:getKingdom()
        if zuoci:getKingdom() ~= kingdom then
            if kingdom == "god" then
                kingdom = room:askForKingdom(zuoci);
                local log = sgs.LogMessage()
                log.type = "#ChooseKingdom";
                log.from = zuoci;
                log.arg = kingdom;
                room:sendLog(log);
            end
            room:setPlayerProperty(zuoci, "kingdom", sgs.QVariant(kingdom))
        end
        if zuoci:getGender() ~= general:getGender() then
            zuoci:setGender(general:getGender())
		end
		----Json大法又释放了一次英姿！
		local jsonValue = {
			9,
			zuoci:objectName(),
			general:objectName(),
			skill_name,
		}
        room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
        zuoci:setTag("LuaHuashenSkill",sgs.QVariant(skill_name))
        if skill_name ~= "" then
            table.insert(ac_dt_list,skill_name)
		end
        room:handleAcquireDetachSkills(zuoci, table.concat(ac_dt_list,"|"), true)
end
LuaHuashen = sgs.CreateTriggerSkill{
	name = "LuaHuashen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.EventPhaseStart},
	priority = -1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:notifySkillInvoked(player, "huashen")
			AcquireGenerals(player, 2)
			SelectSkill(player)
		else
			local phase = player:getPhase()
			if phase == sgs.Player_RoundStart or phase == sgs.Player_NotActive then
				if room:askForSkillInvoke(player, self:objectName()) then
					SelectSkill(player)
				end
			end
		end
	end
}
LuaHuashenDetach = sgs.CreateTriggerSkill{
	name = "#LuaHuashen-clear",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventLoseSkill},
	priority = -1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local skill_name = data:toString()
		if skill_name == "LuaHuashen" then
			if player:getKingdom() ~= player:getGeneral():getKingdom() and player:getGeneral():getKingdom() ~= "god" then
				room:setPlayerProperty(player, "kingdom", sgs.QVariant(player:getGeneral():getKingdom()))
			end
			if player:getGender() ~= player:getGeneral():getGender() then
				player:setGender(player:getGeneral():getGender())
			end
			local huashen_skill = player:getTag("LuaHuashenSkill"):toString()
			if  huashen_skill ~= "" then
				room:detachSkillFromPlayer(player, huashen_skill, false, true)
			end
			player:removeTag("LuaHuashens")
			room:setPlayerMark(player, "@huashen", 0)
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--[[
	技能名：缓释
	相关武将：新3V3·诸葛瑾
	描述：在一名己方角色的判定牌生效前，你可以打出一张牌代替之。
	引用：LuaXHuanshi
	状态:1217验证通过
]]--
Lua3V3_isFriend = function(player,other)
	local tb = { ["lord"] = "warm", ["loyalist"] = "warm", ["renegade"] = "cold", ["rebel"] = "cold" }
	return tb[player:getRole()] == tb[other:getRole()]
end
LuaXHuanshi = sgs.CreateTriggerSkill {
	name = "LuaXHuanshi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForRetrial },
	on_trigger = function(self, event, player, data)
		if player:isNude() then return false end
		local judge = data:toJudge()
		local room = player:getRoom()
		if not (Lua3V3_isFriend(player,judge.who) and room:getMode():startsWith("06_") )then return false end
		local prompt_list = { "@huanshi-card", judge.who:objectName(), self:objectName(), judge.reason, judge.card:getEffectiveId() }
		local prompt = table.concat(prompt_list, ":")
		local card = room:askForCard(player, "..", prompt, data, sgs.Card_MethodResponse, judge.who, true)
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
	状态：1217验证通过
]]--
LuaXHuanshi = sgs.CreateTriggerSkill {
	name = "LuaXHuanshi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForRetrial },
	on_trigger = function(self, event, player, data)
		if player:isNude() then return false end
		local judge = data:toJudge()
		local room = player:getRoom()
		local card
		local ids, disabled_ids,all = sgs.IntList(),sgs.IntList(),sgs.IntList()
            for _,card in sgs.qlist(player:getCards("he"))do
                if player:isCardLimited(card, sgs.Card_MethodResponse) then
                    disabled_ids:append(card:getEffectiveId())
                else
                    ids:append(card:getEffectiveId())
				end
				all:append(card:getEffectiveId())
            end
            if (not ids:isEmpty()) and room:askForSkillInvoke(player, self:objectName(), data)) {
                if judge.who:objectName() ~= player:objectName() and not player:isKongcheng() then
					local jsonLog ={
						"$ViewAllCards",
						judge.who:objectName(),
						player:objectName(),
						table.concat(sgs.QList2Table(player:handCards()),"+"),
						"",
						"",
					}
                    room:doNotify(judge.who,sgs.CommandType.S_COMMAND_LOG_SKILL, json.encode(jsonLog))
                end
                room:fillAG(all, judge.who, disabled_ids)
                local card_id = room:askForAG(judge.who, ids, false, self:objectName())
                room:clearAG(judge.who)
                card = sgs.Sanguosha:getCard(card_id)
            end
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end
}
--[[
	技能名：皇恩
	相关武将：贴纸·刘协
	描述：每当一张锦囊牌指定了不少于两名目标时，你可以令成为该牌目标的至多X名角色各摸一张牌，则该锦囊牌对这些角色无效。（X为你当前体力值）
	引用：LuaXHuangen
	状态：1217验证通过
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
	状态：1217验证通过
]]--
LuaHuangtianCard = sgs.CreateSkillCard{
	name = "LuaHuangtianCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("LuaHuangtian")
           and to_select:objectName() ~= sgs.Self:objectName() and not to_select:hasFlag("LuaHuangtianInvoked")
	end,
	on_use = function(self, room, source, targets)
		local zhangjiao = targets[1]
		if zhangjiao:hasLordSkill("LuaHuangtian") then
			room:setPlayerFlag(zhangjiao, "LuaHuangtianInvoked")
			room:notifySkillInvoked(zhangjiao, "LuaHuangtian")
			zhangjiao:obtainCard(self);
			local zhangjiaos = room:getLieges("qun",zhangjiao)
			if zhangjiaos:isEmpty() then
				room:setPlayerFlag(source, "ForbidHuangtian")
			end
		end
	end
}
LuaHuangtianVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaHuangtianVS",
	filter_pattern = "Jink,Lightning",
	view_as = function(self, card)
		local acard = LuaHuangtianCard:clone()
		acard:addSubcard(card)
		return acard
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
	events = {sgs.TurnStart, sgs.EventPhaseChanging,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	on_trigger = function(self, triggerEvent, player, data)
		local room = player:getRoom()
		local lords = room:findPlayersBySkillName(self:objectName())
		if (triggerEvent == sgs.TurnStart)or(triggerEvent == sgs.EventAcquireSkill and data:toString() == "LuaHuangtian") then 
            if lords:isEmpty() then return false end
            local players
            if lords:length() > 1 then
                players = room:getAlivePlayers()
            else
                players = room:getOtherPlayers(lords:first())
			end
            for _,p in sgs.qlist(players) do
                if not p:hasSkill("LuaHuangtianVS") then
                    room:attachSkillToPlayer(p, "LuaHuangtianVS")
				end
            end
        elseif triggerEvent == sgs.EventLoseSkill and data:toString() == "LuaHuangtian" then
            if lords:length() > 2 then return false end
            local players
            if lords:isEmpty() then
                players = room:getAlivePlayers()
            else
                players:append(lords:first())
			end
            for _,p in sgs.qlist(players) do
                if p:hasSkill("LuaHuangtianVS") then
                    room:detachSkillFromPlayer(p, "LuaHuangtianVS", true)
				end
            end
        elseif (triggerEvent == sgs.EventPhaseChanging) then
            local phase_change = data:toPhaseChange()
            if phase_change.from ~= sgs.Player_Play then return false end
            if player:hasFlag("ForbidHuangtian") then
                room:setPlayerFlag(player, "-ForbidHuangtian")
			end
            local players = room:getOtherPlayers(player);
            for _,p in sgs.qlist(players) do
                if p:hasFlag("HuangtianInvoked") then
                    room:setPlayerFlag(p, "-HuangtianInvoked")
				end
            end
        end
		return false
	end,
}
--[[
	技能名：挥泪（锁定技）
	相关武将：一将成名·马谡
	描述：当你被其他角色杀死时，该角色弃置其所有的牌。
	引用：LuaHuilei
	状态：1217验证通过
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
	状态：1217验证通过
]]--
LuaHuoji = sgs.CreateOneCardViewAsSkill{
	name = "LuaHuoji",
	filter_pattern = ".|red|.|hand",
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local id = card:getId()
		local fireattack = sgs.Sanguosha:cloneCard("FireAttack", suit, point)
		fireattack:setSkillName(self:objectName())
		fireattack:addSubcard(id)
		return fireattack
	end
}
--[[
	技能名：祸首（锁定技）
	相关武将：林·孟获
	描述：【南蛮入侵】对你无效；当其他角色使用【南蛮入侵】指定目标后，你是该【南蛮入侵】造成伤害的来源。
	引用：LuaHuoshou、LuaSavageAssaultAvoid
	状态：1217验证通过
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
	状态：1217验证通过（性能略差）（貌似有时候还会有Bug？）
]]--
LuaXHuoshui = sgs.CreateTriggerSkill{
	name = "LuaXHuoshui",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.Death,
			sgs.MaxHpChanged, sgs.EventAcquireSkill,
			sgs.EventLoseSkill,sgs.PreHpLost},
	on_trigger = function(self, triggerEvent, player, data)
		if player == nil or player:isDead() then return end
		local room = player:getRoom()
		local triggerable = function(target)
			return target and target:isAlive() and target:hasSkill(self:objectName())
		end
		if not triggerable(room:getCurrent()) then
			for _,p in sgs.qlist(room:getAlivePlayers())do --在重新加mark之前先全部消除掉……
				for _,skill in sgs.qlist(p:getVisibleSkillList())do
					room:removePlayerMark(p,"Qingcheng"..skill:objectName())
				end
			end
		end
		local jsonValue = {
			8
		}
        room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		if triggerEvent == sgs.EventPhaseStart then
            if (not triggerable(player)) or (player:getPhase() ~= sgs.Player_RoundStart and player:getPhase() ~= sgs.Player_NotActive) then
				return false
			end
        elseif triggerEvent == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName() or (not player:hasSkill(self:objectName())) then 
				return false 
			end
        elseif triggerEvent == sgs.EventLoseSkill then
            if data:toString() ~= self:objectName() or player:getPhase() == sgs.Player_NotActive then return false end
        elseif (triggerEvent == sgs.EventAcquireSkill) then
            if data:toString() ~= self:objectName() or (not player:hasSkill(self:objectName())) or player:getPhase() == sgs.Player_NotActive then
                return false
			end
        elseif triggerEvent == sgs.MaxHpChanged or triggerEvent == sgs.HpChanged then
            if not(room:getCurrent() and room:getCurrent():hasSkill(self:objectName())) then
				return false 
			end
        end
		
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if p:getHp() >= (p:getMaxHp()/2) then
				room:filterCards(p,p:getCards("he"),true)
				for _,skill in sgs.qlist(p:getVisibleSkillList())do
					room:addPlayerMark(p,"Qingcheng"..skill:objectName())
				end
			end
		end
        local jsonValue = {
			8
		}
        room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
	end,
	can_trigger = function(self, player)
		return player
	end,
	priority = 5
}
