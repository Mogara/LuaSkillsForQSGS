代码速查手册（A区）
==================
#技能索引 
[安娴](#安娴)、[安恤](#安恤)、[暗箭](#暗箭)、[傲才](#傲才)

[返回目录](README.md#目录)
##安娴  
**相关武将**：☆SP·大乔  
**描述**：每当你使用【杀】对目标角色造成伤害时，你可以防止此次伤害，令其弃置一张手牌，然后你摸一张牌；当你成为【杀】的目标时，你可以弃置一张手牌使之无效，然后该【杀】的使用者摸一张牌。  
**引用**：LuaAnxian  
**状态**：1217验证通过  
```lua
	LuaAnxian = sgs.CreateTriggerSkill{      
		name = "LuaAnxian" ,   
		events = {sgs.DamageCaused, sgs.TargetConfirming,  sgs.SlashEffected} ,   
		on_trigger = function(self, event, player, data)  
			local room = player:getRoom()  
			if event == sgs.DamageCaused then  
				local damage = data:toDamage()  
				if damage.card and damage.card:isKindOf("Slash")
					and damage.by_user and (not damage.chain) and (not damage.transfer) then  
					if player:askForSkillInvoke(self:objectName(), data) then  
						if damage.to:canDiscard(damage.to, "h") then  
							room:askForDiscard(damage.to, "LuaAnxian", 1, 1)  
						end  
						player:drawCards(1)  
						return true  
					end  
				end  
			elseif event == sgs.TargetConfirming then  
				local use = data:toCardUse()  
				if (not use.to:contains(player)) or (not player:canDiscard(player, "h")) then return false end   
				if use.card and use.card:isKindOf("Slash") then  
					player:setMark("LuaAnxian", 0)  
					if room:askForCard(player, ".", "@anxian-discard", data, self:objectName()) then  
						player:addMark("LuaAnxian")  
						use.from:drawCards(1)  
					end  
				end  
			elseif event == sgs.SlashEffected then  
				local effect = data:toSlashEffect()  
				if player:getMark("LuaAnxian") > 0 then  
					player:removeMark("LuaAnxian")  
					return true  
				end  
			end  
			return false  
		end  
	} 
``` 
[返回索引](#技能索引) 
##安恤
**相关武将**：二将成名·步练师  
**描述**：出牌阶段限一次，你可以选择两名手牌数不相等的其他角色，令其中手牌少的角色获得手牌多的角色的一张手牌并展示之，若此牌不为♠，你摸一张牌。  
**引用**：LuaAnxu  
**状态**：1217验证通过
```lua
	LuaAnxuCard = sgs.CreateSkillCard{
		name = "LuaAnxuCard" ,
		filter = function(self, targets, to_select)
			if to_select:objectName() == sgs.Self:objectName() then return false end
			if #targets == 0 then
				return true
			elseif #targets == 1 then
				return (to_select:getHandcardNum() ~= targets[1]:getHandcardNum())
			else
				return false
			end
		end ,
		feasible = function(self, targets)
			return #targets == 2
		end ,
		on_use = function(self, room, source, targets)
			local from
			local to
			if targets[1]:getHandcardNum() < targets[2]:getHandcardNum() then
				from = targets[1]
				to = targets[2]
			else
				from = targets[2]
				to = targets[1]
			end
			local id = room:askForCardChosen(from,to,"h", "LuaAnxu")
			local cd = sgs.Sanguosha:getCard(id)
			room:obtainCard(from, cd)
			room:showCard(from, id)
			if cd:getSuit() ~= sgs.Card_Spade then
				source:drawCards(1)
			end
		end 
	}
	LuaAnxu = sgs.CreateViewAsSkill{
		name = "LuaAnxu" ,
		n = 0,
		view_as = function()
			return LuaAnxuCard:clone()
		end ,
		enabled_at_play = function(self, player)
			return not player:hasUsed("#LuaAnxuCard")
		end
	}
```
[返回索引](#技能索引) 

##暗箭
**相关武将**：一将成名2013·潘璋&马忠  
**描述**：每当你使用【杀】对目标角色造成伤害时，若你不在其攻击范围内，此伤害+1。  
**引用**：LuaAnjian  
**状态**：1217验证通过  
```lua
	LuaAnjian = sgs.CreateTriggerSkill{
		name = "LuaAnjian",
		frequency = sgs.Skill_Compulsory,
		events = {sgs.DamageCaused},
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.chain or damage.transfer or not damage.by_user then return false end
			if not (damage.card and damage.card:isKindOf("Slash")) then return false end
			if damage.from and not damage.to:inMyAttackRange(damage.from) then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	}
```
[返回索引](#技能索引) 

##傲才
**相关武将**：SP·诸葛恪  
**描述**：你的回合外，每当你需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌，然后使用或打出其中一张该类别的基本牌。  
**状态**：1217验证通过[与源码略有区别]  
```lua
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
```
[返回索引](#技能索引) 
