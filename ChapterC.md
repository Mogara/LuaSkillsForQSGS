代码速查手册（C区）
==
#技能索引
[藏机](#藏机)、[藏匿](#藏匿)、[缠怨](#缠怨)、[超级观星](#超级观星)、[称象](#称象)、[称象-倚天](#称象-倚天)、[持重](#持重)、[冲阵](#冲阵)、[筹粮](#筹粮)、[醇醪](#醇醪)、[聪慧](#聪慧)、[存嗣](#存嗣)、[挫锐](#挫锐)

[返回目录](README.md#目录)
##藏机
**相关武将**：1v1·黄月英1v1  
**描述**：你死亡时，你可以将装备区的所有装备牌移出游戏：若如此做，你的下个武将登场时，将这些牌置于装备区。  
**引用**：LuaCangji,LuaCangjiInstall  
**状态**：1217验证通过(KOF2013模式)
```lua
	LuaCangjiCard = sgs.CreateSkillCard{
		name = "LuaCangjiCard",
	    will_throw = false,
	    filter = function(self,targets,to_select)
	    	if #targets>0 or to_select:objectName() == sgs.Self:objectName() then return false end
	    	local equip_loc = sgs.IntList()
		    for _,id in sgs.qlist(self:getSubcards()) do
		        local card = sgs.Sanguosha:getCard(id)
		        local equip = card:getRealCard():toEquipCard()
		        if equip then
		            equip_loc:append(equip:location())
		        end
		    end
		    for _,loc in sgs.qlist(equip_loc) do
		        if to_select:getEquip(loc) then
		            return false
		        end
		    end
		    return true
		end,
		on_effect = function(self,effect)
			local room = effect.from:getRoom()
		    local move = sgs.CardsMoveStruct(self:getSubcards(), effect.from, effect.to, sgs.Player_PlaceUnknown, sgs.Player_PlaceEquip, sgs.CardMoveReason())
		    room:moveCardsAtomic(move, true)
		    if effect.from:getEquips():isEmpty() then
		        return
		    end
		    local loop = false;
		    for i = 0,3,1 do
		        if effect.from:getEquip(i) then
		            for _,p in sgs.qlist(room:getOtherPlayers(effect.from)) do
		                if not p:getEquip(i) then
		                    loop = true
		                    break
		                end
		            end
		            if loop then break end
		        end
		    end
		    if loop then
		        room:askForUseCard(effect.from, "@@cangji", "@cangji-install", -1, sgs.Card_MethodNone)
		    end
		end
	}	
	LuaCangjiVS = sgs.CreateViewAsSkill{
		name = "LuaCangji",
		n = 4,
		view_filter = function(self,selected,to_select)
			return to_select:isEquipped()
		end,
		view_as = function(self,cards)
			if #cards == 0 then return nil end
			local card = LuaCangjiCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end,
		enabled_at_play = function(self,player)
			return false
		end,
		enabled_at_response = function(self,player,pattern)
			return pattern == "@@LuaCangji"
		end
	}	
	LuaCangji = sgs.CreateTriggerSkill {
		name = "LuaCangji",
		events = {sgs.Death},
		view_as_skill = LuaCangjiVS,
		on_trigger = function(self,event,player,data)
			local death = data:toDeath()
			local room = player:getRoom()
			if death.who:objectName() ~= player:objectName() or not player:hasSkill(self:objectName()) or player:getEquips():isEmpty() then
				return false
			end
			if room:getMode() == "02_1v1" then
				if room:askForSkillInvoke(player,self:objectName(),data) then
					local d = {}
					local move = sgs.CardsMoveStruct()
					move.from = player
					move.to = nil
					move.to_place = sgs.Player_PlaceTable
					for _,equip in sgs.qlist(player:getEquips()) do
						table.insert(d,equip:getEffectiveId())
						move.card_ids:append(equip:getEffectiveId())
					end				
					player:setTag(self:objectName(),sgs.QVariant(table.concat(d,"+")))
					room:moveCardsAtomic(move,true)
				end
			else
				room:askForUseCard(player,"@@LuaCangji","@cangji-install",-1,sgs.Card_MethodNone)
			end
			return false
	    end,
	    can_trigger = function(self,target)
	    	return target ~= nil
	    end   
	}	
	LuaCangjiInstall = sgs.CreateTriggerSkill {
		name = "#LuaCangjiInstall",
		events = {sgs.Debut},
		priority = 5,
		can_trigger = function(self,target)
	    	return target:getTag("LuaCangji"):toString() ~= ""
	    end,  
	    on_trigger = function(self,event,player, data)
	    	local room = player:getRoom()
	    	local equip_list = sgs.IntList()
	    	for _,id in ipairs(player:getTag("LuaCangji"):toString():split("+")) do
	    		local card_id = tonumber(id)
	    		if sgs.Sanguosha:getCard(card_id):getTypeId() == sgs.Card_TypeEquip then
	    			equip_list:append(card_id)
	    		end
	    	end
	    	player:removeTag("LuaCangji")
	    	if equip_list:isEmpty() then return false end
	    	local log = sgs.LogMessage()
	    	log.from = player
	    	log.type = "$Install"
	    	log.card_str = table.concat(sgs.QList2Table(equip_list),"+")
	    	room:sendLog(log)
	    	room:moveCardsAtomic(sgs.CardsMoveStruct(equip_list,player,sgs.Player_PlaceEquip,sgs.CardMoveReason()),true)
	        return false
	    end
	}
```
[返回索引](#技能索引)
##藏匿
**相关武将**：铜雀台·伏皇后  
**描述**：弃牌阶段开始时，你可以回复1点体力或摸两张牌，然后将你的武将牌翻面；其他角色的回合内，当你获得（每回合限一次）/失去一次牌时，若你的武将牌背面朝上，你可以令该角色摸/弃置一张牌。  
**引用**：LuaCangni  
**状态**：1217验证通过
```lua
	LuaCangni = sgs.CreateTriggerSkill{
		name = "LuaCangni" ,
		events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime} ,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Discard) then
				if player:askForSkillInvoke(self:objectName()) then
					local choices = {}
					table.insert(choices, "draw")
					if player:isWounded() then
						table.insert(choices, recover)
					end
					local choice
					if #choices == 1 then
						choice = choices[1]
					else
						choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
					end
					if choice == "recover" then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
					else
						player:drawCards(2)
					end
					player:turnOver()
					return false
				end
			elseif (event == sgs.CardsMoveOneTime) and (not player:faceUp()) then
				if (player:getPhase() ~= sgs.Player_NotActive) then return false end
				local move = data:toMoveOneTime()
				local target = room:getCurrent()
				if target:isDead() then return false end
				if (move.from and (move.from:objectName() == player:objectName())) and ((not move.to) or (move.to:objectName() ~= player:objectName())) then
					local invoke = false
					for i = 0, move.card_ids:length() - 1, 1 do
						if (move.from_places:at(i) == sgs.Player_PlaceHand) or (move.from_places:at(i) == sgs.Player_PlaceEquip) then
							invoke = true
							break
						end
					end
					room:setPlayerFlag(player, "LuaCangniLose")
					if invoke and (not target:isNude()) then
						if player:askForSkillInvoke(self:objectName()) then
							room:askForDiscard(target, self:objectName(), 1, 1, false, true)
						end
					end
					room:setPlayerFlag(player, "-LuaCangniLose")
					return false
				end
				if (move.to and (move.to:objectName() == player:objectName())) and ((not move.from) or (move.from:objectName() ~= player:objectName())) then
					if (move.to_place == sgs.Player_PlaceHand) or (move.to_place == sgs.Player_PlaceEquip) then
						room:setPlayerFlag(player, "LuaCangniGet")
						if (not target:hasFlag("LuaCangni_Used")) then
							if player:askForSkillInvoke(self:objectName()) then
								room:setPlayerFlag(target, "LuaCangni_Used")
								target:drawCards(1)
							end
						end
						room:setPlayerFlag(player, "-LuaCangniGet")
					end
				end
			end
			return false
		end
	}
```
[返回索引](#技能索引)

##缠怨
**相关武将**：风·于吉  
**描述**：**锁定技，**你不能质疑“蛊惑”。若你的体力值为1，你的其他武将技能无效。  
**引用**：LuaChanyuan  
**状态**：1217验证通过(需与本手册的“蛊惑”配合使用)
```lua  
	LuaChanyuan = sgs.CreateTriggerSkill {
		name = "LuaChanyuan",
		events = {sgs.GameStart, sgs.HpChanged, sgs.MaxHpChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill},
		frequency = sgs.Skill_Compulsory,		
		can_trigger = function(self, target)
			return target
		end,		
		on_trigger = function(self, triggerEvent, player, data)
			local room = player:getRoom()
			if triggerEvent == sgs.EventLoseSkill then
				if data:toString() == self:objectName() then
					local LuaChanyuan_skills = player:getTag("LuaChanyuanSkills"):toString():split("+")
					for _, skill_name in ipairs(LuaChanyuan_skills) do
						room:removePlayerMark(player, "Qingcheng"..skill_name)
					end
					player:setTag("LuaChanyuanSkills", sgs.QVariant())
				end
				return false
			elseif triggerEvent == sgs.EventAcquireSkill then
				if data:toString() ~= self:objectName() then return false end
			end			
			if not player:isAlive() or not player:hasSkill(self:objectName()) then return false end		
			if player:getHp() == 1 then
				local LuaChanyuan_skills = player:getTag("LuaChanyuanSkills"):toString():split("+")
				local skills = player:getVisibleSkillList()
				for _, skill in sgs.qlist(skills) do
					if skill:objectName() ~= self:objectName() and skill:getLocation() == sgs.Skill_Right and not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not (Set(LuaChanyuan_skills))[skill:objectName()] then
						room:addPlayerMark(player, "Qingcheng"..skill:objectName())
						table.insert(LuaChanyuan_skills, skill:objectName())
					end
				end
				player:setTag("LuaChanyuanSkills", sgs.QVariant(table.concat(LuaChanyuan_skills, "+")))
			else
				local LuaChanyuan_skills = player:getTag("LuaChanyuanSkills"):toString():split("+")
				for _, skill_name in ipairs(LuaChanyuan_skills) do
					room:removePlayerMark(player, "Qingcheng"..skill_name)
				end
				player:setTag("LuaChanyuanSkills", sgs.QVariant())
			end
			return false
		end
	}
```
[返回索引](#技能索引)


##超级观星
**相关武将**：测试·五星诸葛  
**描述**：回合开始阶段，你可以观看牌堆顶的5张牌，将其中任意数量的牌以任意顺序置于牌堆顶，其余则以任意顺序置于牌堆底  
**引用**：LuaXSuperGuanxing  
**状态**：1217验证通过
```lua
	LuaXSuperGuanxing = sgs.CreateTriggerSkill{
		name = "LuaXSuperGuanxing",
		frequency = sgs.Skill_Frequent,
		events = {sgs.EventPhaseStart},
		on_trigger = function(self, event, player, data)
			if player:getPhase() == sgs.Player_Start then
				if player:askForSkillInvoke(self:objectName()) then
					local room = player:getRoom()
					local stars = room:getNCards(5,false)
					room:askForGuanxing(player, stars)
				end
			end
		end
	}
```
[返回索引](#技能索引)

##称象
**相关武将**：一将成名2013·曹冲  
**描述**： 每当你受到一次伤害后，你可以展示牌堆顶的四张牌，然后获得其中任意数量点数之和小于13的牌，并将其余的牌置入弃牌堆。  
**引用**：LuaChengxiang  
**状态**：1217验证通过
```lua
	LuaChengxiang = sgs.CreateTriggerSkill{
		name = "LuaChengxiang" ,
		frequency = sgs.Skill_Frequent ,
		events = {sgs.Damaged} ,
		on_trigger = function(self, event, player, data)
			local damage = data:toDamage()
			local room = player:getRoom()
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			local card_ids = room:getNCards(4)
			room:fillAG(card_ids)
			local to_get = sgs.IntList()
			local to_throw = sgs.IntList()
			while true do
				local sum = 0
				for _, id in sgs.qlist(to_get) do
					sum = sum + sgs.Sanguosha:getCard(id):getNumber()
				end
				for _, id in sgs.qlist(card_ids) do
					if sum + sgs.Sanguosha:getCard(id):getNumber() >= 13 then
						room:takeAG(nil, id, false)
						card_ids:removeOne(id)
						to_throw:append(id)
					end
				end
				if card_ids:isEmpty() then break end
				local card_id = room:askForAG(player, card_ids, true, self:objectName())
				if card_id == -1 then break end
				card_ids:removeOne(card_id)
				to_get:append(card_id)
				room:takeAG(player, card_id, false)
				if card_ids:isEmpty() then break end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if not to_get:isEmpty() then
				for _, id in sgs.qlist(to_get) do
					dummy:addSubcard(id)
				end
				player:obtainCard(dummy)
			end
			dummy:clearSubcards()
			if (not to_throw:isEmpty()) or (not card_ids:isEmpty()) then
				for _, id in sgs.qlist(to_throw) do
					dummy:addSubcard(id)
				end
				for _, id in sgs.qlist(card_ids) do
					dummy:addSubcard(id)
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
				room:throwCard(dummy, reason, nil)
			end
			room:clearAG()
			return false
		end
	}
```
[返回索引](#技能索引)

##称象-倚天
**相关武将**：倚天·曹冲  
**描述**：每当你受到一次伤害后，你可以弃置X张点数之和与造成伤害的牌的点数相等的牌，你可以选择至多X名角色，若其已受伤则回复1点体力，否则摸两张牌。  
**引用**：LuaYTChengxiang  
**状态**：1217验证通过
```lua
	LuaYTChengxiangCard = sgs.CreateSkillCard{
		name = "LuaYTChengxiang" ,
		filter = function(self, targets, to_select)
			return #targets < self:subcardsLength()
		end ,
		on_effect = function(self, effect)
			local room = effect.to:getRoom()
			if effect.to:isWounded() then
				local recover = sgs.RecoverStruct()
				recover.card = self
				recover.who = effect.from
				room:recover(effect.to, recover)
			else
				effect.to:drawCards(2)
			end
		end
	}
	LuaYTChengxiangVS = sgs.CreateViewAsSkill{
		name = "LuaYTChengxiang" ,
		n = 3 ,
		view_filter = function(self, selected, to_select)
			if #selected >= 3 then return false end
			local sum = 0
			for _, card in ipairs(selected) do
				sum = sum + card:getNumber()
			end
			sum = sum + to_select:getNumber()
			return sum <= sgs.Self:getMark("LuaYTChengxiang")
		end ,
		view_as = function(self, cards)
			local sum = 0
			for _, c in ipairs(cards) do
				sum = sum + c:getNumber()
			end
			if sum == sgs.Self:getMark("LuaYTChengxiang") then
				local card = LuaYTChengxiangCard:clone()
				for _, c in ipairs(cards) do
					card:addSubcard(c)
				end
				return card
			else
				return nil
			end
		end ,
		enabled_at_play = function()
			return false
		end ,
		enabled_at_response = function(self, player, pattern)
			return pattern == "@@LuaYTChengxiang"
		end
	}
	LuaYTChengxiang = sgs.CreateTriggerSkill{
		name = "LuaYTChengxiang" ,
		events = {sgs.Damaged} ,
		view_as_skill = LuaYTChengxiangVS ,
		on_trigger = function(self, event, player, data)
			local damage = data:toDamage()
			local card = damage.card
			if card == nil then return false end
			local point = card:getNumber()
			if (point < 1) or (point > 13) then return false end
			if player:isNude() then return false end
			local room = player:getRoom()
			room:setPlayerMark(player, "LuaYTChengxiang", point)
			local prompt = "@chengxiang-card:::" .. tostring(point)
			room:askForUseCard(player, "@@LuaYTChengxiang", prompt)
			return false
		end
	}
```
[返回索引](#技能索引)

##持重
**相关武将**：铜雀台·伏完  
**描述**：**锁定技，**你的手牌上限等于你的体力上限；其他角色死亡时，你加1点体力上限。  
**引用**：LuaChizhong、LuaChizhong2  
**状态**：1217验证通过
```lua
	LuaChizhong = sgs.CreateMaxCardsSkill{
		name = "LuaChizhong" ,
		extra_func = function(self, target)
			if target:hasSkill(self:objectName()) then
				return target:getLostHp()
			else
				return 0
			end
		end
	}
	LuaChizhong2 = sgs.CreateTriggerSkill{
		name = "#LuaChizhong" ,
		events = {sgs.Death} ,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local splayer = room:findPlayerBySkillName(self:objectName())
			if not splayer then return false end
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then return false end
			room:setPlayerProperty(splayer, "maxhp", sgs.QVariant(splayer:getMaxHp() + 1))
			return false
		end
	}
```
[返回索引](#技能索引)

##冲阵
**相关武将**：☆SP·赵云  
**描述**：每当你发动“龙胆”使用或打出一张手牌时，你可以立即获得对方的一张手牌。  
**引用**：LuaChongzhen  
**状态**：1217验证通过
```lua
	LuaChongzhen = sgs.CreateTriggerSkill{
		name = "LuaChongzhen" ,
		events = {sgs.CardResponded, sgs.TargetConfirmed} ,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.CardResponded then
				local resp = data:toCardResponse()
				if (resp.m_card:getSkillName() == "longdan") and resp.m_who and (not resp.m_who:isKongcheng()) then
					local _data = sgs.QVariant()
					_data:setValue(resp.m_who)
					if player:askForSkillInvoke(self:objectName(), _data) then
						local card_id = room:askForCardChosen(player, resp.m_who, "h", self:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
					end
				end
			else
				local use = data:toCardUse()
				if (use.from:objectName() == player:objectName()) and (use.card:getSkillName() == "longdan") then
					for _, p in sgs.qlist(use.to) do
						if p:isKongcheng() then continue end
						local _data = sgs.QVariant()
						_data:setValue(p)
						p:setFlags("LuaChongzhenTarget")
						local invoke = player:askForSkillInvoke(self:objectName(), _data)
						p:setFlags("-LuaChongzhenTarget")
						if invoke then
							local card_id = room:askForCardChosen(player,p,"h",self:objectName())
							room:obtainCard(player,sgs.Sanguosha:getCard(card_id), false)
						end
					end
				end
			end
			return false
		end
	}
```
[返回索引](#技能索引)

##筹粮
**相关武将**：智·蒋琬  
**描述**：回合结束阶段开始时，若你手牌少于三张，你可以从牌堆顶亮出4-X张牌（X为你的手牌数），你获得其中的基本牌，把其余的牌置入弃牌堆  
**引用**：LuaXChouliang  
**状态**：1217验证通过
```lua
	LuaXChouliang = sgs.CreateTriggerSkill{
		name = "LuaXChouliang",
		frequency = sgs.Skill_Frequent,
		events = {sgs.EventPhaseStart},
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local handcardnum = player:getHandcardNum()
			if player:getPhase() == sgs.Player_Finish then
				if handcardnum < 3 then
					if room:askForSkillInvoke(player, self:objectName()) then
						for i=1, 4-handcardnum, 1 do
							local card_id = room:drawCard()
							local card = sgs.Sanguosha:getCard(card_id)
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, player:objectName(), "", self:objectName(), "")
							room:moveCardTo(card, player, sgs.Player_PlaceTable, reason, true)
							room:getThread():delay()
							if not card:isKindOf("BasicCard") then
								room:throwCard(card_id, nil)
								room:setEmotion(player, "bad")
							else
								room:obtainCard(player, card_id)
								room:setEmotion(player, "good")
							end
						end
					end
				end
			end
			return false
		end
	}
```
[返回索引](#技能索引)

##醇醪
**相关武将**：二将成名·程普  
**描述**：结束阶段开始时，若你的武将牌上没有牌，你可以将任意数量的【杀】置于你的武将牌上，称为“醇”；当一名角色处于濒死状态时，你可以将一张“醇”置入弃牌堆，令该角色视为使用一张【酒】。  
**引用**：LuaChunlao、LuaChunlaoClear  
**状态**：1217验证通过
```lua
	LuaChunlaoCard = sgs.CreateSkillCard{
		name = "LuaChunlaoCard" ,
		will_throw = false ,
		target_fixed = true ,
		handling_method = sgs.Card_MethodNone,
		on_use = function(self, room, source, targets)
			source:addToPile("wine", self)
		end
	}
	LuaChunlaoWineCard = sgs.CreateSkillCard{
		name = "LuaChunlaoWine" ,
		target_fixed = true ,
		on_use = function(self, room, source, targets)
			if source:getPile("wine"):isEmpty() then return end
			local who = room:getCurrentDyingPlayer()
			if not who then return end
			local cards = source:getPile("wine")
			room:fillAG(cards, source)
			local card_id = room:askForAG(source, cards, false, "LuaChunlao")
			room:clearAG()
			if card_id ~= -1 then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, "LuaChunlao", nil)
				room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
				local analeptic = sgs.Sanguosha:cloneCard("Analeptic", sgs.Card_NoSuit, 0)
				analeptic:setSkillName("_LuaChunlao")
				room:useCard(sgs.CardUseStruct(analeptic, who, who, false))
			end
		end
	}
	LuaChunlaoVS = sgs.CreateViewAsSkill{
		name = "LuaChunlao" ,
		n = 999,
		view_filter = function(self, cards, to_select)
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "@@LuaChunlao" then
				return to_select:isKindOf("Slash")
			else
				return false
			end
		end ,
		view_as = function(self, cards)
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "@@LuaChunlao" then
				if #cards == 0 then return nil end
				local acard = LuaChunlaoCard:clone()
				for _, c in ipairs(cards) do
					acard:addSubcard(c)
				end
				acard:setSkillName(self:objectName())
				return acard
			else
				if #cards ~= 0 then return nil end
				return LuaChunlaoWineCard:clone()
			end
		end ,
		enabled_at_play = function()
			return false
		end ,
		enabled_at_response = function(self, player, pattern)
			return (pattern == "@@LuaChunlao") or (string.find(pattern, "peach") and (not player:getPile("wine"):isEmpty()))
		end
	}
	LuaChunlao = sgs.CreateTriggerSkill{
		name = "LuaChunlao" ,
		events = {sgs.EventPhaseStart} ,
		view_as_skill = LuaChunlaoVS ,
		on_trigger = function(self, event, player, data)
			if (event == sgs.EventPhaseStart)
					and (player:getPhase() == sgs.Player_Finish)
					and (not player:isKongcheng())
					and player:getPile("wine"):isEmpty() then
				player:getRoom():askForUseCard(player, "@@LuaChunlao", "@chunlao", -1, sgs.Card_MethodNone)
			end
			return false
		end
	}
	LuaChunlaoClear = sgs.CreateTriggerSkill{
		name = "#LuaChunlao-clear" ,
		events = {sgs.EventLoseSkill} ,
		on_trigger = function(self, event, player, data)
			if data:toString() == "LuaChunlao" then
				player:clearOnePrivatePile("wine")
			end
			return false
		end ,
		can_trigger = function(self, target)
			return target
		end
	}
```
[返回索引](#技能索引)

##聪慧
**相关武将**：倚天·曹冲  
**描述**：**锁定技，**你将永远跳过你的弃牌阶段  
**引用**：LuaConghui  
**状态**：1217验证通过
```lua
	LuaConghui = sgs.CreateTriggerSkill{
		name = "LuaConghui" ,
		frequency = sgs.Skill_Compulsory ,
		events = {sgs.EventPhaseChanging} ,
		on_trigger = function(self, event, player, data)
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then player:skip(change.to) end
			return false
		end
	}
```
[返回索引](#技能索引)
##存嗣
**相关武将**：势·糜夫人  
**描述**：限定技，出牌阶段，你可以失去“闺秀”和“存嗣”，然后令一名角色获得“勇决”（若一名角色于出牌阶段内使用的第一张牌为【杀】，此【杀】结算完毕后置入弃牌堆时，你可以令其获得之。）：若该角色不是你，该角色摸两张牌。   
**引用**：LuaCunsi、LuaCunsiStart  
**状态**：1217验证通过  
**注**：此技能与闺秀有联系，有联系的地方请使用本手册当中的闺秀，并非原版
```lua
	LuaCunsiCard = sgs.CreateSkillCard{
		name = "LuaCunsiCard",	
		filter = function(self, targets, to_select)
			return #targets == 0 
		end,		
		on_effect = function(self, effect)
			local room = effect.from:getRoom()
			room:handleAcquireDetachSkills(effect.from,"-LuaGuixiu|-LuaCunsi")
			room:acquireSkill(effect.to,"yongjue")
			if effect.to:objectName() ~= effect.from:objectName() then
				effect.to:drawCards(2)
			end
		end
	}
	LuaCunsi = sgs.CreateZeroCardViewAsSkill{
		name = "LuaCunsi",
		frequency = sgs.Skill_Limited,	
		view_as = function()
			return LuaCunsiCard:clone()
		end
	}
	LuaCunsiStart = sgs.CreateTriggerSkill{
		name = "#LuaCunsiStart",
		events = {sgs.GameStart,sgs.EventAcquireSkill},		
		on_trigger = function(self, event, player, data)
			player:getRoom():getThread():addTriggerSkill(sgs.Sanguosha:getTriggerSkill("yongjue"))
		end,
	}
```
[返回索引](#技能索引)
#挫锐
**相关武将**：1v1·牛金  
**描述**：**锁定技，**你的起始手牌数为X+2（X为你备选区里武将牌的数量），你跳过登场后的第一个判定阶段。   
**引用**：LuaCuorui  
**状态**：1217验证通过
```lua
	LuaCuorui = sgs.CreateTriggerSkill {
		name = "LuaCuorui",
		frequency = sgs.Skill_Compulsory,
		events = {sgs.DrawInitialCards,sgs.EventPhaseChanging},
		on_trigger = function(self,event,player,data)
			local room = player:getRoom()
			if event == sgs.DrawInitialCards then
				local n = 3 
				if room:getMode() == "02_1v1" then
					local list = player:getTag("1v1Arrange"):toStringList()
					n = #list
					player:speak(n)
					if sgs.GetConfig("1v1/Rule","2013") == "2013" then
						n = n + 3
					end
					local origin
					if sgs.GetConfig("1v1/Rule","2013") =="Classical" then
						origin = 4
					else
						origin = player:getMaxHp()
					end
					n = n + 2 - origin
					player:speak(n)
				end
				data:setValue(data:toInt() + n)
			elseif event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_Judge and player:getMark("CuoruiSkipJudge") == 0 then
					player:skip(sgs.Player_Judge)
					player:addMark("CuoruiSkipJudge")
				end
			end
			return false
		end
	}
```
[返回索引](#技能索引)