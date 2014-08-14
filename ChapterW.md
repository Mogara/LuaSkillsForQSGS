代码速查手册（W区）
==
#技能索引
[完杀](#完杀)、[婉容](#婉容)、[忘隙](#忘隙)、[妄尊](#妄尊)、[危殆](#危殆)、[围堰](#围堰)、[帷幕](#帷幕)、[伪帝](#伪帝)、[温酒](#温酒)、[无谋](#无谋)、[无前](#无前)、[无双](#无双)、[无言](#无言)、[无言-旧](#无言-旧)、[五灵](#五灵)、[武魂](#武魂)、[武继](#武继)、[武神](#武神)、[武圣](#武圣)

[返回目录](README.md#目录)
##完杀
**相关武将**：林·贾诩、SP·贾诩  
**描述**：**锁定技，**在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。  
**引用**：LuaWansha  
**状态**：1217验证通过
```lua
	LuaWansha=sgs.CreateTriggerSkill{
		name = "LuaWansha",
		events = {sgs.AskForPeaches, sgs.EventPhaseChanging, sgs.Death},
		frequency = sgs.Skill_Compulsory,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.AskForPeaches then
				local dying = data:toDying()
				local jiaxu = room:getCurrent()
				if jiaxu and jiaxu:isAlive() and jiaxu:hasSkill(self:objectName()) and jiaxu:getPhase() ~= sgs.Player_NotActive then
					if dying.who:objectName() ~= player:objectName() and jiaxu:objectName() ~= player:objectName() then
						room:setPlayerFlag(player, "Global_PreventPeach")
					end
				end
			else
				if event == sgs.EventPhaseChanging then
					local change = data:toPhaseChange()
					if change.to ~= sgs.Player_NotActive then return false end
				elseif event == sgs.Death then
					local death = data:toDeath()
					if death.who:objectName() ~= player:objectName() or death.who:getPhase() == sgs.Player_NotActive then return false end
				end
				for _ , p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("Global_PreventPeach") then
	                			 room:setPlayerFlag(p, "-Global_PreventPeach")
					end
				end
			end
			return false
		end,
		can_trigger = function(self,target)
			return target
		end
	}
```
[返回索引](#技能索引)
##婉容
**相关武将**：1v1·大乔  
**描述**：每当你成为【杀】的目标后，你可以摸一张牌。   
**引用**：LuaWanrong  
**状态**：1217验证通过
```lua
	LuaWanrong = sgs.CreateTriggerSkill{
		name = "LuaWanrong",
		events = {sgs.TargetConfirmed},
		frequency = sgs.Skill_Frequent,
	    	on_trigger=function(self, event, player, data)
			local room = player:getRoom()
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") and use.to:contains(player) and room:askForSkillInvoke(player, self:objectName(), data)) then
				player:drawCards(1)
			end
			return false
		end
	}
```
[返回索引](#技能索引)
##忘隙
**相关武将**：势·李典  
**描述**：每当你对一名其他角色造成1点伤害后，或你受到其他角色造成的1点伤害后，若该角色存活，你可以与其各摸一张牌。  
**引用**：LuaWangxi  
**状态**：1217验证通过
```lua
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
```
[返回索引](#技能索引)
##妄尊
**相关武将**：标准·袁术  
**描述**：主公的准备阶段开始时，你可以摸一张牌，然后主公本回合手牌上限-1。  
**引用**：LuaWangzun、LuaWangzunMaxCards  
**状态**：1217验证通过
```lua
	LuaWangzun = sgs.CreatePhaseChangeSkill{
		name = "LuaWangzun" ,
		on_phasechange = function(self, target)
			local room = target:getRoom()
			local mode = room:getMode()
			if mode:endsWith("p") or mode:endsWith("pd") or mode:endsWith("pz") then
				if target:isLord() and target:getPhase() == sgs.Player_Start then
					local yuanshu = room:findPlayerBySkillName(self:objectName())
					if yuanshu and room:askForSkillInvoke(yuanshu, self:objectName()) then
						yuanshu:drawCards(1)
						room:setPlayerFlag(target, "LuaWangzunDecMaxCards")
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
```
[返回索引](#技能索引)
##危殆
**相关武将**：智·孙策  
**描述**：**主公技，**当你需要使用一张【酒】时，所有吴势力角色按行动顺序依次选择是否打出一张黑桃2~9的手牌，视为你使用了一张【酒】，直到有一名角色或没有任何角色决定如此做时为止  
**引用**：LuaWeidai  
**状态**：1217验证通过
```lua
	hasWuGenerals = function(player)
		for _, p in sgs.qlist(player:getSiblings()) do
			if p:isAlive() and p:getKingdom() == "wu" then
				return true
			end
		end
		return false
	end
	LuaWeidaiCard = sgs.CreateSkillCard{
		name = "LuaWeidaiCard",
		target_fixed = true,
	    	mute = true,
		on_validate = function(self, card_use)
			card_use.m_isOwnerUse = false
			local sunce = card_use.from
			local room = sunce:getRoom()
			for _ , liege in sgs.qlist(room:getLieges("wu", sunce)) do
				local tohelp = sgs.QVariant()
				tohelp:setValue(sunce)
				local prompt = string.format("@weidai-analeptic:%s", sunce:objectName())
				local card = room:askForCard(liege, ".|spade|2~9|hand", prompt, tohelp, sgs.Card_MethodNone)
				if card then
					local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, liege:objectName(), "LuaWeidai", "")
					room:moveCardTo(card, nil, sgs.Player_DiscardPile, reason, true)
					local ana = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
					ana:setSkillName("LuaWeidai")
					ana:addSubcard(card)
					return ana
				end
			end
			room:setPlayerFlag(sunce, "Global_LuaWeidaiFailed")
			return nil
		end,
		on_validate_in_response = function(self, user)
			local room = user:getRoom()
			for _ , liege in sgs.qlist(room:getLieges("wu", user)) do
				local tohelp = sgs.QVariant()
				tohelp:setValue(user)
				local prompt = string.format("@weidai-analeptic:%s", user:objectName())
				local card = room:askForCard(liege, ".|spade|2~9|hand", prompt, tohelp, sgs.Card_MethodNone)
				if card then
					local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, liege:objectName(), "LuaWeidai", "")
					room:moveCardTo(card, nil, sgs.Player_DiscardPile, reason, true)
					local ana = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
					ana:setSkillName("LuaWeidai")
					ana:addSubcard(card)
					return ana
				end
			end
			room:setPlayerFlag(user, "Global_LuaWeidaiFailed")
			return nil
		end
	}
	LuaWeidai = sgs.CreateZeroCardViewAsSkill{
		name = "LuaWeidai$",
		view_as = function()
			return LuaWeidaiCard:clone()
		end,
		enabled_at_play = function(self, player)
			return hasWuGenerals(player) and player:hasLordSkill("LuaWeidai")
	               and not player:hasFlag("Global_LuaWeidaiFailed")
	               and sgs.Analeptic_IsAvailable(player)
		end,
		enabled_at_response = function(self, player, pattern)
			return hasWuGenerals(player) and pattern == "peach+analeptic" and not player:hasFlag("Global_LuaWeidaiFailed")
		end
	}
```
[返回索引](#技能索引)
##围堰
**相关武将**：倚天·陆抗  
**描述**：你可以将你的摸牌阶段当作出牌阶段，出牌阶段当作摸牌阶段执行  
**引用**：LuaLukangWeiyan  
**状态**：1217验证通过
```lua
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
```
[返回索引](#技能索引)
##帷幕
**相关武将**：林·贾诩、SP·贾诩  
**描述**：**锁定技，**你不能被选择为黑色锦囊牌的目标。  
**引用**：LuaWeimu  
**状态**：1217验证通过
```lua
	LuaWeimu = sgs.CreateProhibitSkill{
		name = "LuaWeimu" ,
		is_prohibited = function(self, from, to, card)
			return to:hasSkill(self:objectName()) and (card:isKindOf("TrickCard") or card:isKindOf("QiceCard"))
				and card:isBlack() and not string.find(string.lower(card:getSkillName()),"nosguhuo")--特别注意旧蛊惑
		end
	}
```
[返回索引](#技能索引)
##伪帝
**相关武将**：SP·袁术、SP·台版袁术  
**描述**：**锁定技，**你拥有当前主公的主公技。  
**状态**：验证失败

[返回索引](#技能索引)
##温酒
**相关武将**：智·华雄  
**描述**：**锁定技，**你使用黑色的【杀】造成的伤害+1，你无法闪避红色的【杀】  
**引用**：LuaWenjiu  
**状态**：1217验证通过
```lua
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
```
[返回索引](#技能索引)
##无谋
**相关武将**：神·吕布  
**描述**：**锁定技，**当你使用一张非延时类锦囊牌选择目标后，你须弃1枚“暴怒”标记或失去1点体力。  
**引用**：LuaWumou  
**状态**：1217验证通过(须与技能“暴怒”配合使用)
```lua
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
```
[返回索引](#技能索引)
##无前
**相关武将**：神·吕布  
**描述**：出牌阶段，你可以弃2枚“暴怒”标记并选择一名其他角色，该角色的防具无效且你获得技能“无双”，直到回合结束。  
**引用**：LuaWuqian  
**状态**：1217验证通过
```lua
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
```
[返回索引](#技能索引)
##无双
**相关武将**：标准·吕布、SP·最强神话、SP·暴怒战神、SP·台版吕布  
**描述**：**锁定技，**当你使用【杀】指定一名角色为目标后，该角色需连续使用两张【闪】才能抵消；与你进行【决斗】的角色每次需连续打出两张【杀】。  
**引用**：LuaWushuang  
**状态**：1217验证通过
```lua
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
		events = {sgs.TargetConfirmed,sgs.CardEffected } ,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
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
			elseif event == sgs.CardEffected then
				local effect = data:toCardEffect()
				if effect.card:isKindOf("Duel") then				
					if effect.from and effect.from:isAlive() and effect.from:hasSkill(self:objectName()) then
						can_invoke = true
					end
					if effect.to and effect.to:isAlive() and effect.to:hasSkill(self:objectName()) then
						can_invoke = true
					end
				end
				if not can_invoke then return false end
				if effect.card:isKindOf("Duel") then
					if room:isCanceled(effect) then
	                    effect.to:setFlags("Global_NonSkillNullify")
	                    return true;
	                end
	                if effect.to:isAlive() then
						local second = effect.from
						local first = effect.to
	                    room:setEmotion(first, "duel");
						room:setEmotion(second, "duel")
						while true do
							if not first:isAlive() then
								break
							end
							local slash
							if second:hasSkill(self:objectName()) then
								slash = room:askForCard(first,"slash","@Luawushuang-slash-1:" .. second:objectName(),data,sgs.Card_MethodResponse, second);
								if slash == nil then
									break
								end	
								slash = room:askForCard(first, "slash", "@Luawushuang-slash-2:" .. second:objectName(),data,sgs.Card_MethodResponse,second);
								if slash == nil then
									break
								end
							else
								slash = room:askForCard(first,"slash","duel-slash:" .. second:objectName(),data,sgs.Card_MethodResponse,second)
								if slash == nil then
									break
								end
							end
							local temp = first
							first = second
							second = temp
						end
						local daamgeSource = function() if second:isAlive() then return secoud else return nil end end
						local damage = sgs.DamageStruct(effect.card, daamgeSource() , first)
						if second:objectName() ~= effect.from:objectName() then
							damage.by_user = false;
						end
						room:damage(damage)
					end
					room:setTag("SkipGameRule",sgs.QVariant(true))
				end
			end
			return false
		end ,
		can_trigger = function(self, target)
			return target
		end,
		priority = 1,
	}
```
[返回索引](#技能索引)
##无言
**相关武将**：一将成名·徐庶  
**描述**：**锁定技，**你防止你造成或受到的任何锦囊牌的伤害。  
**引用**：LuaWuyan  
**状态**：1217验证通过
```lua
	LuaWuyan = sgs.CreateTriggerSkill{
		name = "LuaWuyan",
		frequency = sgs.Skill_Compulsory,
		events = {sgs.DamageCaused, sgs.DamageInflicted},
		on_trigger = function(self, event, player, data)
			local damage = data:toDamage()
			if damage.card and (damage.card:getTypeId() == sgs.Card_TypeTrick) then
				if (event == sgs.DamageInflicted) and player:hasSkill(self:objectName()) then
					return true
				elseif (event == sgs.DamageCaused) and (damage.from and damage.from:isAlive() and damage.from:hasSkill(self:objectName())) then
					return true
				end
			end
			return false
		end,
		can_trigger = function(self, target)
			return target
		end
	}
```
[返回索引](#技能索引)
##无言-旧  
**相关武将**：怀旧·徐庶  
**描述**：**锁定技，**你使用的非延时类锦囊牌对其他角色无效；其他角色使用的非延时类锦囊牌对你无效。  
**引用**：LuaNosWuyan  
**状态**：1217验证通过
```lua
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
```
[返回索引](#技能索引)
##五灵
**相关武将**：倚天·晋宣帝  
**描述**：回合开始阶段，你可选择一种五灵效果发动，该效果对场上所有角色生效,该效果直到你的下回合开始为止，你选择的五灵效果不可与上回合重复  
- [风]场上所有角色受到的火焰伤害+1  
- [雷]场上所有角色受到的雷电伤害+1  
- [水]场上所有角色使用桃时额外回复1点体力  
- [火]场上所有角色受到的伤害均视为火焰伤害  
- [土]场上所有角色每次受到的属性伤害至多为1  
**引用**：LuaWulingExEffect、LuaWulingEffect、LuaWuling  
**状态**：1217验证通过
```lua
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
```
[返回索引](#技能索引)
##武魂
**相关武将**：神·关羽  
**描述**：**锁定技，**每当你受到1点伤害后，伤害来源获得一枚“梦魇”标记；你死亡时，令拥有最多该标记的一名其他角色进行一次判定，若判定结果不为【桃】或【桃园结义】，该角色死亡。  
**引用**：LuaWuhun、LuaWuhunRevenge、LuaWuhunClear  
**状态**：1217验证通过
```lua
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
```
[返回索引](#技能索引)
##武继
**相关武将**：SP·关银屏  
**描述**：**觉醒技，**结束阶段开始时，若你于此回合内已造成3点或更多伤害，你加1点体力上限，回复1点体力，然后失去技能“虎啸”。  
**引用**：LuaWujiCount、LuaWuji  
**状态**：1217验证通过
```lua
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
```
[返回索引](#技能索引)
##武神
**相关武将**：神·关羽  
**描述**：**锁定技，**你的红桃手牌均视为【杀】；你使用红桃【杀】时无距离限制。  
**引用**：LuaWushen、LuaWushenTargetMod  
**状态**：1217验证通过
```lua
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
```
[返回索引](#技能索引)
##武圣
**相关武将**：标准·关羽、翼·关羽、2013-3v3·关羽、1v1·关羽1v1  
**描述**：你可以将一张红色牌当【杀】使用或打出。  
**引用**：LuaWusheng  
**状态**：1217验证通过
```lua
	LuaWusheng = sgs.CreateOneCardViewAsSkill{
		name = "LuaWusheng",
		view_filter = function(self, card)
			if not card:isRed() then return false end
			if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
	    		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	        	slash:addSubcard(card:getEffectiveId())
	        	slash:deleteLater()
	        	return slash:isAvailable(sgs.Self)
	    	end
	    	return true
		end,
		view_as = function(self, originalCard)
			local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			slash:addSubcard(originalCard:getId())
			slash:setSkillName(self:objectName())
			return slash
		end,
		enabled_at_play = function(self, player)
			return sgs.Slash_IsAvailable(player)
		end, 
		enabled_at_response = function(self, player, pattern)
			return pattern == "slash"
		end
	}
```
[返回索引](#技能索引)
