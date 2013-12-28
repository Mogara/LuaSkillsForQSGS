--[[
	代码速查手册（A区）
	技能索引：
		安娴、安恤、暗箭、傲才
]]--
--[[
	技能名：安娴
	相关武将：☆SP·大乔
	描述：每当你使用【杀】对目标角色造成伤害时，你可以防止此次伤害，令其弃置一张手牌，然后你摸一张牌；当你成为【杀】的目标时，你可以弃置一张手牌使之无效，然后该【杀】的使用者摸一张牌。
	引用：LuaAnxian
	状态：验证通过
]]--
LuaAnxian = sgs.CreateTriggerSkill{
	name = "LuaAnxian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused, sgs.TargetConfirming, sgs.SlashEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local card = damage.card
			if card and card:isKindOf("Slash") then
				if not damage.chain and not damage.transfer then
					local dest = damage.to
					if room:askForSkillInvoke(player, self:objectName(), data) then
						if not dest:isKongcheng() then
							room:askForDiscard(dest, self:objectName(), 1, 1)
						end
						player:drawCards(1)
						return true
					end
				end
			end
		elseif event == sgs.TargetConfirming then
			local use = data:toCardUse()
			local card = use.card
			if card and card:isKindOf("Slash") then
				if room:askForCard(player, ".", "@anxian-discard", sgs.QVariant(), sgs.CardDiscarded) then
					player:addMark("anxian")
					use.from:drawCards(1)
				end
			end
		elseif event == sgs.SlashEffected then
			if player:getMark("anxian") > 0 then
				local count = player:getMark("anxian") - 1
				player:setMark("anxian", count)
				return true
			end
			return false
		end
	end
}
--[[
	技能名：安恤
	相关武将：二将成名·步练师
	描述：出牌阶段限一次，你可以选择两名手牌数不相等的其他角色，令其中手牌少的角色获得手牌多的角色的一张手牌并展示之，若此牌不为♠，你摸一张牌。
	引用：LuaAnxu
	状态：验证通过
]]--
AnxuCard = sgs.CreateSkillCard{
	name = "AnxuCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if to_select == sgs.Self then
			return false
		elseif #targets == 0 then
			return true
		elseif #targets == 1 then
			local first = targets[1]
			return to_select:getHandcardNum() ~= first:getHandcardNum()
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local playerA = targets[1]
		local playerB = targets[2]
		local from
		local to
		if playerA:getHandcardNum() > playerB:getHandcardNum() then
			from = playerB
			to = playerA
		else
			from = playerA
			to = playerB
		end
		local id = room:askForCardChosen(from, to, "h", self:objectName())
		local card = sgs.Sanguosha:getCard(id)
		room:obtainCard(from, card)
		room:showCard(from, id)
		if card:getSuit() ~= sgs.Card_Spade then
			source:drawCards(1)
		end
	end
}
LuaAnxu = sgs.CreateViewAsSkill{
	name = "LuaAnxu",
	n = 0,
	view_as = function(self, cards)
		local card = AnxuCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#AnxuCard")
	end,
}
--[[
	技能名：暗箭（锁定技）
	相关武将：一将成名2013·潘璋&马忠
	描述：每当你使用【杀】对目标角色造成伤害时，若你不在其攻击范围内，此伤害+1。
	引用：LuaAnjian
	状态：验证通过
]]--
LuaAnjian = sgs.CreateTriggerSkill{
	name = "LuaAnjian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.chain or damage.transfer or not damage.by_user then return false end
		if damage.from and not damage.to:inMyAttackRange(damage.from) then
		damage.damage = damage.damage + 1
		data:setValue(damage)
		end
	end
}
--[[
	技能名：傲才
	相关武将：SP·诸葛恪
	描述：你的回合外，每当你需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌，然后使用或打出其中一张该类别的基本牌。
	状态：0610验证通过[与源码略有区别]
]]--
function view(room, player, ids, enabled, disabled)
	local result = -1
		room:notifySkillInvoked(player, "LuaAocai")
		if enabled:isEmpty() then
		room:fillAG(ids, player)
		room:getThread():delay(tonumber(sgs.GetConfig("OriginAIDelay", "")))
		room:clearAG(player) --直接关闭
	else
		room:fillAG(ids, player, disabled)
		local id = room:askForAG(player, enabled, true, "LuaAocai")
		if id ~= -1 then
			ids:removeOne(id)
			result = id
		end
		room:clearAG(player)
	 end
--room:doBroadcastNotify(sgs.CommandType.S_COMMAND_UPDATE_PILE, tostring(drawPile:length())) 无效果不知道为什么
	local dummy = sgs.Sanguosha:cloneCard("jink")
	local moves = {}
	if ids:length() > 0 then
		for _, id in sgs.qlist(ids) do table.insert(moves, id) end
		local unmoves = sgs.reverse(moves)
		for _, id in ipairs(unmoves) do dummy:addSubcard(id) end
		player:addToPile("#LuaAocai", dummy, false) --只能强制移到特殊区域再移动到摸牌堆
		room:moveCardTo(dummy, nil, sgs.Player_DrawPile, false)
	end
	if result == -1 then
		room:setPlayerFlag(player, "Global_LuaAocaiFailed")
	end
	return result
end
LuaAocaiVS = sgs.CreateViewAsSkill{
	name = "LuaAocai",
	n = 0,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response=function(self, player, pattern)
		 if (player:getPhase() ~= sgs.Player_NotActive or player:hasFlag("Global_LuaAocaiFailed")) then return end
		 if pattern == "slash" then
			 	return sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			elseif (pattern == "peach") then
				 return not player:hasFlag("Global_PreventPeach")
			elseif string.find(pattern, "analeptic") then
			return true
		end
			return false
		end,
	view_as = function(self, cards)
		local acard = LuaAocaiCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "peach+analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then
			pattern = "analeptic"
		end
		acard:setUserString(pattern)
			return acard
		end,
}
LuaAocai = sgs.CreateTriggerSkill{
	name = "LuaAocai",
	view_as_skill = LuaAocaiVS,
	events={sgs.CardAsked},
	on_trigger=function(self,event,player,data)
		if player:getPhase() ~= sgs.Player_NotActive then return end
		local room = player:getRoom()
		local pattern = data:toStringList()[1]
		if (pattern == "slash" or pattern == "jink")
			and room:askForSkillInvoke(player, self:objectName(), data) then
			local ids = room:getNCards(2, false)
			local enabled, disabled = sgs.IntList(), sgs.IntList()
			for _,id in sgs.qlist(ids) do
				if string.find(sgs.Sanguosha:getCard(id):objectName(), pattern) then
					enabled:append(id)
				else
					disabled:append(id)
				end
			end
			local id = view(room, player, ids, enabled, disabled)
			if id ~= -1 then
				local card = sgs.Sanguosha:getCard(id)
				room:provide(card)
				return true
			end
		end
	end,
}
LuaAocaiCard=sgs.CreateSkillCard{
	name="LuaAocaiCard",
	will_throw = false,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
	end ,
	feasible = function(self, targets)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local ids = room:getNCards(2, false)
		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names,"fire_slash")
			table.insert(names,"thunder_slash")
		end
		local enabled, disabled = sgs.IntList(), sgs.IntList()
		for _,id in sgs.qlist(ids) do
			if table.contains(names, sgs.Sanguosha:getCard(id):objectName()) then
				enabled:append(id)
			else
				disabled:append(id)
			end
		end
		local id = view(room, user, ids, enabled, disabled)
		return sgs.Sanguosha:getCard(id)
	end,
	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local user = cardUse.from
		local room = user:getRoom()
		local ids = room:getNCards(2, false)
		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names,"fire_slash")
			table.insert(names,"thunder_slash")
		end
		local enabled, disabled = sgs.IntList(), sgs.IntList()
		for _,id in sgs.qlist(ids) do
			if table.contains(names, sgs.Sanguosha:getCard(id):objectName()) then
				enabled:append(id)
			else
				disabled:append(id)
			end
		end
		local id = view(room, user, ids, enabled, disabled)
		return sgs.Sanguosha:getCard(id)
	end
}
