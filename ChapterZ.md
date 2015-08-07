
代码速查手册（Z区）
==
#技能索引
[灾变](#灾变)、[再起](#再起)、[凿险](#凿险)、[早夭](#早夭)、[战神](#战神)、[昭烈](#昭烈)、[昭心](#昭心)、[贞烈](#贞烈)、[贞烈-旧](#贞烈-旧)、[鸩毒](#鸩毒)、[镇威](#镇威)、[镇卫](#镇卫)、[争锋](#争锋)、[争功](#争功)、[争功-0610版](#争功-0610版)、[征服](#征服)、[整军](#整军)、[直谏](#直谏)、[直言](#直言)、[志继](#志继)、[制霸](#制霸)、[制衡-制霸孙权](#制衡-制霸孙权)、[制衡](#制衡)、[智迟](#智迟)、[智愚](#智愚)、[忠义](#忠义)、[咒缚](#咒缚)、[筑楼](#筑楼)、[追忆](#追忆)、[惴恐](#惴恐)、[资粮](#资粮)、[自立](#自立)、[自守](#自守)、[宗室](#宗室)、[纵火](#纵火)、[纵适](#纵适)、[诈降](#诈降)、[纵玄](#纵玄)、[醉乡](#醉乡)

[返回目录](README.md#目录)
##灾变
**相关武将**：僵尸·僵尸  
**描述**：**锁定技，**你的出牌阶段开始时，若人类玩家数-僵尸玩家数+1大于0，你多摸该数目的牌。  
**引用**：LuaZaibian  
**状态**：1217验证通过
```lua
		isZombie = function(player)		--这里是以副将来判断是否僵尸，与源码以身份来判断不同
			if player:getGeneral2Name() == "zombie" then 
				return true
			end
		end
		LuaZaibian = sgs.CreateTriggerSkill{
			name = "LuaZaibian",
			events = {sgs.EventPhaseStart},
			frequency = sgs.Skill_Compulsory,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if player:getPhase() == sgs.Player_Play then
					local ZombieNo = 0
					local HumanNo = 0
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if isZombie(p) then
							ZombieNo = ZombieNo +1
						else
							HumanNo = HumanNo +1
						end
					end
					local x = HumanNo-ZombieNo+1
					if x> 0 then
						player:drawCards(x)
					end
				end
			end
		}
```
[返回索引](#技能索引)

##再起
**相关武将**：林·孟获  
**描述**：摸牌阶段开始时，若你已受伤，你可以放弃摸牌，改为从牌堆顶亮出X张牌（X为你已损失的体力值），你回复等同于其中红桃牌数量的体力，然后将这些红桃牌置入弃牌堆，并获得其余的牌。  
**引用**：LuaZaiqi  
**状态**：1217验证通过
```lua
		LuaZaiqi = sgs.CreateTriggerSkill{
			name = "LuaZaiqi",
			frequency = sgs.Skill_NotFrequent,
			events = {sgs.EventPhaseStart},
			on_trigger = function(self, event, player, data)
				if player:getPhase() == sgs.Player_Draw then
					if player:isWounded() then
						local room = player:getRoom()
						if room:askForSkillInvoke(player, self:objectName()) then
							local x = player:getLostHp()
							local has_heart = false
							local ids = room:getNCards(x, false)
							local move = sgs.CardsMoveStruct()
							move.card_ids = ids
							move.to = player
							move.to_place = sgs.Player_PlaceTable
							move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
							room:moveCardsAtomic(move, true)
							local card_to_throw = {}
							local card_to_gotback = {}
							for i=0, x-1, 1 do
								local id = ids:at(i)
								local card = sgs.Sanguosha:getCard(id)
								local suit = card:getSuit()
								if suit == sgs.Card_Heart then
									table.insert(card_to_throw, id)
								else
									table.insert(card_to_gotback, id)
								end
							end
							if #card_to_throw > 0 then
								local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								for _, id in ipairs(card_to_throw) do
									dummy:addSubcard(id)
								end
								local recover = sgs.RecoverStruct()
								recover.card = nil
								recover.who = player
								recover.recover = #card_to_throw
								room:recover(player, recover)
								local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
								room:throwCard(dummy, reason, nil)
								has_heart = true
							end
							if #card_to_gotback > 0 then
								local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								for _, id in ipairs(card_to_gotback) do
									dummy2:addSubcard(id)
								end
								room:obtainCard(player, dummy2)
							end
							return true
						end
					end
				end
				return false
			end
		}
```
[返回索引](#技能索引)

##凿险  
**相关武将**：山·邓艾  
**描述**：**锁定技，**回合开始阶段开始时，若“田”的数量达到3或更多，你须减1点体力上限，并获得技能“急袭”。  
**引用**：LuaZaoxian  
**状态**：1217验证通过  
```lua
		LuaZaoxian = sgs.CreateTriggerSkill{
			name = "LuaZaoxian" ,
			frequency = sgs.Skill_Wake ,
			events = {sgs.EventPhaseStart} ,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				room:addPlayerMark(player, "LuaZaoxian")
				if room:changeMaxHpForAwakenSkill(player) then
					room:acquireSkill(player, "jixi")
				end
			end ,
			can_trigger = function(self, target)
				return (target and target:isAlive() and target:hasSkill(self:objectName()))
					and (target:getPhase() == sgs.Player_Start)
					and (target:getMark("LuaZaoxian") == 0)
					and (target:getPile("field"):length() >= 3)
			end
		}
```
[返回索引](#技能索引)

##早夭
**相关武将**：倚天·曹冲  
**描述**：**锁定技，**回合结束阶段开始时，若你的手牌大于13张，则你必须弃置所有手牌并流失1点体力  
**引用**：LuaZaoyao  
**状态**：1217验证通过  
```lua
		LuaZaoyao = sgs.CreateTriggerSkill{
			name = "LuaZaoyao" ,
			frequency = sgs.Skill_Compulsory ,
			events = {sgs.EventPhaseStart} ,
			on_trigger = function(self, event, player, data)
				if (player:getPhase() == sgs.Player_Finish) and (player:getHandcardNum() > 13) then
					player:throwAllHandCards()
					player:getRoom():loseHp(player)
				end
				return false
			end
		}
```
[返回索引](#技能索引)

##战神
**相关武将**：2013-3v3·吕布  
**描述**：**觉醒技，**准备阶段开始时，若你已受伤且有己方角色已死亡，你减1点体力上限，弃置装备区的武器牌，然后获得技能“马术”和“神戟”。  
**引用**：LuaZhanshen  
**状态**：1217验证通过
```lua
		LuaZhanshen = sgs.CreateTriggerSkill{
			name = "LuaZhanshen",
			events = {sgs.Death, sgs.EventPhaseStart},
			frequency = sgs.Skill_Wake,
			can_trigger = function(self, target)
				return target ~= nil
			end,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if event == sgs.Death then
					local death = data:toDeath()
					if death.who:objectName() ~= player:objectName() then
						return false
					end
					local lvbu = room:findPlayerBySkillName(self:objectName())
					if string.sub(room:getMode(), 1, 3) == "06_" then
						if lvbu:getMark(self:objectName()) == 0 and lvbu:getMark("zhanshen_fight") == 0
								and string.sub(lvbu:getRole(), 1, 1) == string.sub(player:getRole(), 1, 1) then
							lvbu:addMark("zhanshen_fight")
						end
					else
						if lvbu:getMark(self:objectName()) == 0 and lvbu:getMark("@fight") == 0		--身份局
								and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("mark:"..lvbu:objectName())) then
							room:addPlayerMark(lvbu, "@fight")
						end
					end
				else
					if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 0 and player:isWounded()
							and (player:getMark("zhanshen_fight") > 0 or player:getMark("@fight") > 0) and player:hasSkill(self:objectName()) then
						if player:getMark("@fight") > 0 then
							room:setPlayerMark(player, "@fight", 0)
						end
						player:setMark("zhanshen_fight", 0)
						room:addPlayerMark(player, self:objectName())
						if room:changeMaxHpForAwakenSkill(player) then
							if player:getWeapon() then
								room:throwCard(player:getWeapon(), player)
							end
							room:handleAcquireDetachSkills(player, "mashu|shenji")
						end
					end
				end
				return false
			end,
		}
```
[返回索引](#技能索引)

##昭烈
**相关武将**：☆SP·刘备  
**描述**：摸牌阶段摸牌时，你可以少摸一张牌，指定你攻击范围内的一名其他角色亮出牌堆顶上3张牌，将其中全部的非基本牌和【桃】置于弃牌堆，该角色进行二选一：你对其造成X点伤害，然后他获得这些基本牌；或他依次弃置X张牌，然后你获得这些基本牌。（X为其中非基本牌的数量）。  
**引用**：LuaZhaolie、LuaZhaolieAct  
**状态**：1217验证通过  
```lua
		LuaZhaolie = sgs.CreateTriggerSkill{
			name = "LuaZhaolie",
			frequency = sgs.Skill_NotFrequent,
			events = {sgs.DrawNCards},
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				local targets = room:getOtherPlayers(player)
				local victims = sgs.SPlayerList()
				for _,p in sgs.qlist(targets) do
					if player:inMyAttackRange(p) then
						victims:append(p)
					end
				end
				if victims:length() > 0 then
					if room:askForSkillInvoke(player, self:objectName()) then
						room:setPlayerFlag(player, "Invoked")
						local count = data:toInt() - 1
						data:setValue(count)
					end
				end
			end
		}
		LuaZhaolieAct = sgs.CreateTriggerSkill{
			name = "#LuaZhaolie",
			frequency = sgs.Skill_Frequent,
			events = {sgs.AfterDrawNCards},
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				local no_basic = 0
				local cards = {}
				local targets = room:getOtherPlayers(player)
				local victims = sgs.SPlayerList()
				for _,p in sgs.qlist(targets) do
					if player:inMyAttackRange(p) then
						victims:append(p)
					end
				end
				if player:getPhase() == sgs.Player_Draw then
					if player:hasFlag("Invoked") then
						room:setPlayerFlag(player, "-Invoked")
						local victim = room:askForPlayerChosen(player, victims, "LuaZhaolie")
						local cardIds = sgs.IntList()
						for i=1, 3, 1 do
							local id = room:drawCard()
							cardIds:append(id)
						end
						assert(cardIds:length() == 3)
						local move = sgs.CardsMoveStruct()
						move.card_ids = cardIds
						move.to_place = sgs.Player_PlaceTable
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), "", "LuaZhaolie", "")
						room:moveCards(move, true)
						room:getThread():delay()
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, "", "LuaZhaolie", "")
						for i=0, 2, 1 do
							local card_id = cardIds:at(i)
							local card = sgs.Sanguosha:getCard(card_id)
							if not card:isKindOf("BasicCard") or card:isKindOf("Peach") then
								if not card:isKindOf("BasicCard") then
									no_basic = no_basic + 1
								end
								room:throwCard(card, reason, nil)
							else
								table.insert(cards, card)
							end
						end
						local choicelist = "damage"
						local flag = false
						local victim_cards = victim:getCards("he")
						if victim_cards:length() >= no_basic then
							choicelist = "damage+throw"
							flag = true
						end
						local choice
						if flag then
							local data = sgs.QVariant(no_basic)
							choice = room:askForChoice(victim, "LuaZhaolie", choicelist, data)
						else
							choice = "damage"
						end
						if choice == "damage" then
							if no_basic > 0 then
								local damage = sgs.DamageStruct()
								damage.card = nil
								damage.from = player
								damage.to = victim
								damage.damage = no_basic
								room:damage(damage)
							end
							if #cards > 0 then
								local reasonA = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, victim:objectName())
								local reasonB = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, victim:objectName(), "LuaZhaolie", "")
								for _,c in pairs(cards) do
									if victim:isAlive() then
										room:obtainCard(victim, c, true)
									else
										room:throwCard(c, reasonB, nil)
									end
								end
							end
						else
							if no_basic > 0 then
								while no_basic > 0 do
									room:askForDiscard(victim, "LuaZhaolie", 1, 1, false, true)
									no_basic = no_basic - 1
								end
							end
							if #cards > 0 then
								reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, player:objectName())
								for _,c in pairs(cards) do
									room:obtainCard(player, c)
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

##昭心
**相关武将**：贴纸·司马昭  
**描述**：摸牌阶段结束时，你可以展示所有手牌，若如此做，视为你使用一张【杀】，每阶段限一次。  
**引用**：LuaZhaoxin  
**状态**：1217验证通过  
```lua
		LuaZhaoxinCard = sgs.CreateSkillCard{
			name = "LuaZhaoxinCard" ,
			filter = function(self, targets, to_select)
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local tarlist = sgs.PlayerList()
				for i = 1, #targets, 1 do
					tarlist:append(targets[i])
				end
				return slash:targetFilter(tarlist, to_select, sgs.Self)
			end ,
			on_use = function(self, room, source, targets)
				room:showAllCards(source)
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("_LuaZhaoxin")
				local tarlist = sgs.SPlayerList()
				for i = 1, #targets, 1 do
					tarlist:append(targets[i])
				end
				room:useCard(sgs.CardUseStruct(slash, source, tarlist))
			end
		}
		LuaZhaoxinVS = sgs.CreateViewAsSkill{
			name = "LuaZhaoxin" ,
			n = 0 ,
			view_as = function()
				return LuaZhaoxinCard:clone()
			end ,
			enabled_at_play = function()
				return false
			end ,
			enabled_at_response = function(self, player, pattern)
				return (pattern == "@@LuaZhaoxin") and sgs.Slash_IsAvailable(player)
			end ,
		}
		LuaZhaoxin = sgs.CreateTriggerSkill{
			name = "LuaZhaoxin" ,
			events = {sgs.EventPhaseEnd} ,
			view_as_skill = LuaZhaoxinVS ,
			on_trigger = function(self, event, player, data)
				if player:getPhase() ~= sgs.Player_Draw then return false end
				if player:isKongcheng() or (not sgs.Slash_IsAvailable(player)) then return false end
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(player:getRoom():getAllPlayers()) do
					if player:canSlash(p) then
						targets:append(p)
					end
				end
				if targets:isEmpty() then return false end
				player:getRoom():askForUseCard(player, "@@LuaZhaoxin", "@zhaoxin")
				return false
			end
		}
```
[返回索引](#技能索引)

##贞烈
**相关武将**：一将成名2012·王异  
**描述**： 每当你成为一名其他角色使用的【杀】或非延时类锦囊牌的目标后，你可以失去1点体力，令此牌对你无效，然后你弃置其一张牌。  
**引用**：LuaZhenlie  
**状态**：0405验证通过
```lua
		LuaZhenlie = sgs.CreateTriggerSkill{
			name = "LuaZhenlie" ,
			events = {sgs.TargetConfirmed} , 
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if event == sgs.TargetConfirmed then
					local use = data:toCardUse()
					if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
						if use.card:isKindOf("Slash") or use.card:isNDTrick() then
							if room:askForSkillInvoke(player, self:objectName(), data) then
								player:setFlags("-ZhenlieTarget")
								player:setFlags("ZhenlieTarget")
								room:loseHp(player)
								if player:isAlive() and player:hasFlag("ZhenlieTarget") then
									player:setFlags("-ZhenlieTarget")
									local nullified_list = use.nullified_list
									table.insert(nullified_list, player:objectName())
									use.nullified_list = nullified_list
									data:setValue(use)
									if player:canDiscard(use.from, "he") then
										local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
										room:throwCard(id, use.from, player)
									end
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

##贞烈-旧
**相关武将**：怀旧-一将2·王异-旧  
**描述**：在你的判定牌生效前，你可以从牌堆顶亮出一张牌代替之。  
**引用**：LuaNosZhenlie  
**状态**：1217验证通过  
```lua
		LuaNosZhenlie = sgs.CreateTriggerSkill{
			name = "LuaNosZhenlie" ,
			events = {sgs.AskForRetrial} ,
			on_trigger = function(self, event, player, data)
				local judge = data:toJudge()
				if judge.who:objectName() ~= player:objectName() then return false end
				if player:askForSkillInvoke(self:objectName(), data) then
					local room = player:getRoom()
					local card_id = room:drawCard()
					room:getThread():delay()
					local card = sgs.Sanguosha:getCard(card_id)
					room:retrial(card, player, judge, self:objectName())
				end
				return false
			end
		}
```
[返回索引](#技能索引)

##鸩毒
**相关武将**：阵·何太后  
**描述**：每当一名其他角色的出牌阶段开始时，你可以弃置一张手牌：若如此做，视为该角色使用一张【酒】（计入限制），然后你对该角色造成1点伤害。   
**引用**：LuaZhendu  
**状态**：1217验证通过  
```lua
		LuaZhendu = sgs.CreateTriggerSkill {
			name = "LuaZhendu",
			events = {sgs.EventPhaseStart},
			can_trigger = function(self, target)
				return target ~= nil
			end,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if player:getPhase() ~= sgs.Player_Play then
					return false
				end
				local hetaihou = room:findPlayerBySkillName(self:objectName())
				if not hetaihou or not hetaihou:isAlive() or not hetaihou:canDiscard(hetaihou, "h")
						or hetaihou:getPhase() == sgs.Player_Play then
					return false
				end
				if room:askForCard(hetaihou, ".", "@zhendu-discard", sgs.QVariant(), self:objectName()) then
					local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
					analeptic:setSkillName(self:objectName())
					room:useCard(sgs.CardUseStruct(analeptic, player, sgs.SPlayerList(), true))
					if player:isAlive() then
						room:damage(sgs.DamageStruct(self:objectName(), hetaihou, player))
					end
				end
				return false
			end
		}
```
[返回索引](#技能索引)

##镇威
**相关武将**：倚天·倚天剑  
**描述**：你的【杀】被手牌中的【闪】抵消时，可立即获得该【闪】。  
**引用**：LuaYTZhenwei  
**状态**：1217验证通过  
```lua
		LuaYTZhenwei = sgs.CreateTriggerSkill{
			name = "LuaYTZhenwei" ,
			events = {sgs.SlashMissed} ,
			on_trigger = function(self, event, player, data)
				local effect = data:toSlashEffect()
				if effect.jink and (player:getRoom():getCardPlace(effect.jink:getEffectiveId()) == sgs.Player_DiscardPile) then
					if player:askForSkillInvoke(self:objectName(), data) then
						player:obtainCard(effect.jink)
					end
				end
				return false
			end
		}
```
[返回索引](#技能索引)

##镇卫
**相关武将**：2013-3v3·文聘  
**描述**：**锁定技，**对方角色与其他己方角色的距离+1。  
**身份局**：回合结束後，你可以令至多X名其他角色获得“守”(X为其他存活角色数的一半(向下取整))，则其他角色计算与目标角色的距离时，始终+1，直到你的下回合开始。  
**引用**：LuaZhenweiDistance、LuaZhenwei  
**状态**：1217验证成功  
```lua
		LuaZhenweiDistance = sgs.CreateDistanceSkill{
			name = "#LuaZhenwei",
			correct_func = function(self, from, to)
				if to:hasSkill("LuaZhenwei") then return 0
				else
					local hasWenpin = false
					for _,p in sgs.qlist(to:getAliveSiblings()) do
						if p:hasSkill("LuaZhenwei") then
							hasWenpin = true
							break
						end
					end
					if not hasWenpin then return 0 end
				end
				if sgs.GetConfig("GameMode", "06_3v3") == "06_3v3" then		--3v3
					if string.sub(from:getRole(), 1, 1) ~= string.sub(to:getRole(), 1, 1) then
						for _,p in sgs.qlist(to:getAliveSiblings()) do
							if p:hasSkill(self:objectName()) and string.sub(p:getRole(), 1, 1) == string.sub(to:getRole(), 1, 1) then
								return 1
							end
						end
					end
				else		--身份局
					if to:getMark("@defense") > 0 and from:getMark("@defense") == 0 and not from:hasSkill("LuaZhenwei") then
						return 1
					end
				end
				return 0
			end
		}
		LuaZhenweiCard = sgs.CreateSkillCard{
			name = "LuaZhenwei",
			filter = function(self, targets, to_select, player)
				local total = player:getSiblings():length()+1
				return #targets < total / 2 - 1 and to_select ~= player
			end,
			on_effect = function(self, effect)
				effect.to:gainMark("@defense")
			end,
		}
		LuaZhenweiViewAsSkill = sgs.CreateZeroCardViewAsSkill{
			name = "LuaZhenwei",
			response_pattern = "@@zhenwei",
			view_as = function(self)
				return LuaZhenweiCard:clone()
			end,
		}
		LuaZhenwei = sgs.CreateTriggerSkill{
			name = "LuaZhenwei",
			events = {sgs.EventPhaseChanging, sgs.Death, sgs.EventLoseSkill},
			view_as_skill = LuaZhenweiViewAsSkill,
			frequency = sgs.Skill_Compulsory,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if string.sub(room:getMode(),1,3) == "06_" then return false end
				if event == sgs.EventLoseSkill then
					if data:toString() ~= self:objectName() then 
						return false 
					end
				elseif event == sgs.Death then
					local death = data:toDeath()
					if death.who:objectName() ~= player:objectName() or not player:hasSkill(self:objectName()) then
						return false
					end
				elseif event == sgs.EventPhaseChanging then
					local change = data:toPhaseChange()
					if change.to ~= sgs.Player_NotActive then
						return false
					end
				end
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					room:setPlayerMark(p, "@defense", 0)
				end
				if event == sgs.EventPhaseChanging and sgs.Sanguosha:getPlayerCount(room:getMode()) > 3 then
					room:askForUseCard(player, "@@zhenwei", "@zhenwei")
					return false
				end
			end,
		}
```
[返回索引](#技能索引)

##争锋  
**相关武将**：倚天·倚天剑  
**描述**：**锁定技，**当你的装备区没有武器时，你的攻击范围为X，X为你当前体力值。  

[返回索引](#技能索引)
##争功
**相关武将**：倚天·邓士载  
**描述**：其他角色的回合开始前，若你的武将牌正面向上，你可以将你的武将牌翻面并立即进入你的回合，你的回合结束后，进入该角色的回合  
**引用**：LuaXZhenggong  
**状态**：1217验证通过  
```lua
		LuaXZhenggong = sgs.CreateTriggerSkill{
			name = "LuaXZhenggong",
			frequency = sgs.Skill_NotFrequent,
			events = {sgs.TurnStart},
			on_trigger = function(self, event, player, data)
				if player then
					local room = player:getRoom()
					local dengshizai = room:findPlayerBySkillName(self:objectName())
					if dengshizai and dengshizai:faceUp() then
						if dengshizai:askForSkillInvoke(self:objectName()) then
							dengshizai:turnOver()
							local tag = room:getTag("Zhenggong")
							if tag then
								local zhenggong = tag:toPlayer()
								if not zhenggong then
									tag:setValue(player)
									room:setTag("Zhenggong", tag)
									player:gainMark("@zhenggong")
								end
							end
							room:setCurrent(dengshizai)
							dengshizai:play()
							return true
						end
					end
					local tag = room:getTag("Zhenggong")
					if tag then
						local p = tag:toPlayer()
						if p and not player:hasFlag("isExtraTurn") then
							p:loseMark("@zhenggong")
							room:setCurrent(p)
							room:setTag("Zhenggong", sgs.QVariant())
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
```
[返回索引](#技能索引)

##争功-0610版
**相关武将**：倚天·邓士载  
**描述**：其他角色的回合开始前，若你的武将牌正面朝上，你可以进行一个额外的回合，然后将武将牌翻面。  
**引用**：LuaZhenggong610  
**状态**：1217验证通过  
```lua
		LuaZhenggong610 = sgs.CreateTriggerSkill{
			name = "LuaZhenggong610" ,
			events = {sgs.TurnStart} ,
			on_trigger = function(self, event, player, data)
				if not player then return false end
				local room = player:getRoom()
				local dengshizai = room:findPlayerBySkillName(self:objectName())
				if dengshizai and dengshizai:faceUp() then
					if dengshizai:askForSkillInvoke(self:objectName()) then
						dengshizai:gainAnExtraTurn()
						dengshizai:turnOver()
					end
				end
				return false
			end ,
			can_trigger = function(self, target)
				return target and not target:hasSkill(self:objectName())
			end
		}
```
[返回索引](#技能索引)

##征服
**相关武将**：E.SP 凯撒  
**描述**：当你使用【杀】指定一个目标后，你可以选择一种牌的类别，令其选择一项：1．将一张此类别的牌交给你，若如此做，此次对其结算的此【杀】对其无效；2．不能使用【闪】响应此【杀】。  
**引用**：LuaConqueror  
**状态**：0425验证通过  
```lua
	LuaConqueror = sgs.CreateTriggerSkill{
		name = "LuaConqueror" ,
		events = {sgs.TargetConfirmed} ,
		on_trigger = function(self, event, player, data)
			local use = data:toCardUse()
			if (use.card and use.card:isKindOf("Slash")) then
				local n = 0
				for _, target in sgs.qlist(use.to) do
					local _target = sgs.QVariant()
					_target:setValue(target)
					if (player:askForSkillInvoke(self, _target)) then
						local room = player:getRoom()
						local choice = room:askForChoice(player, self:objectName(), "BasicCard+EquipCard+TrickCard", _target)
						local c = room:askForCard(target, choice, "@conqueror-exchange:" .. player:objectName() .. "::" .. choice, sgs.QVariant(choice), sgs.Card_MethodNone)
						if c then
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), player:objectName(), self:objectName(), nil)
							room:obtainCard(player, c, reason)
							local nullified_list = use.nullified_list
							table.insert(nullified_list, target:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)
						else
							local jink_list = player:getTag("Jink_" .. use.card:toString()):toIntList()
							jink_list:replace(n, 0)
							local _jink_list = sgs.QVariant()
							_jink_list:setValue(jink_list)
							player:setTag("Jink_" .. use.card:toString(), _jink_list)
						end
					end
					n = n + 1
				end
			end
			return false
		end ,
	}
```
[返回索引](#技能索引)

##直谏
**相关武将**：山·张昭张纮  
**描述**：出牌阶段，你可以将手牌中的一张装备牌置于一名其他角色装备区内：若如此做，你摸一张牌。
**引用**：LuaZhijian  
**状态**：0405验证通过  
```lua
	LuaZhijianCard = sgs.CreateSkillCard{
		name = "LuaZhijianCard",
		will_throw = false,
		handling_method = sgs.Card_MethodNone,
		filter = function(self, targets, to_select, erzhang)
			if #targets ~= 0 or to_select:objectName() == erzhang:objectName() then return false end
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			local equip = card:getRealCard():toEquipCard()
			local equip_index = equip:location()
			return to_select:getEquip(equip_index) == nil
		end,
		on_effect = function(self, effect)
			local erzhang = effect.from
			erzhang:getRoom():moveCardTo(self, erzhang, effect.to, sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, erzhang:objectName(), "zhijian", ""))
			erzhang:drawCards(1, "zhijian")
		end
	}
	LuaZhijian = sgs.CreateOneCardViewAsSkill{
		name = "LuaZhijian",	
		filter_pattern = "EquipCard|.|.|hand",
		view_as = function(self, card)
			local zhijian_card = LuaZhijianCard:clone()
			zhijian_card:addSubcard(card)
			zhijian_card:setSkillName(self:objectName())
			return zhijian_card
		end
	}
```
[返回索引](#技能索引)

##直言
**相关武将**：一将成名2013·虞翻  
**描述**：结束阶段开始时，你可以令一名角色摸一张牌并展示之。若此牌为装备牌，该角色回复1点体力，然后使用之。  
**引用**：LuaZhiyan  
**状态**：1217验证通过  
```lua
		LuaZhiyan = sgs.CreateTriggerSkill{
			name = "LuaZhiyan" ,
			events = {sgs.EventPhaseStart} ,
			on_trigger = function(self, event, player, data)
				if player:getPhase() ~= sgs.Player_Finish then return false end
				local room = player:getRoom()
				local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "LuaZhiyan-invoke", true, true)
				if to then
					local ids = room:getNCards(1, false)
					local card = sgs.Sanguosha:getCard(ids:first())
					room:obtainCard(to, card, false)
					if not to:isAlive() then return false end
					room:showCard(to, ids:first())
					if card:isKindOf("EquipCard") then
						if (to:isWounded()) then
							local recover = sgs.RecoverStruct()
							recover.who = player
							room:recover(to, recover)
						end
						if to:isAlive() and (not to:isCardLimited(card, sgs.Card_MethodUse)) then
							room:useCard(sgs.CardUseStruct(card, to, to))
						end
					end
				end
				return false
			end
		}
```
[返回索引](#技能索引)

##志继
**相关武将**：山·姜维  
**描述**：**觉醒技，**回合开始阶段开始时，若你没有手牌，你须选择一项：回复1点体力，或摸两张牌。然后你减1点体力上限，并获得技能“观星”。  
**引用**：LuaZhiji  
**状态**：1217验证通过  
```lua
		LuaZhiji = sgs.CreateTriggerSkill{
			name = "LuaZhiji" ,
			frequency = sgs.Skill_Wake ,
			events = {sgs.EventPhaseStart} ,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if player:isWounded() then
					if room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
					else
						room:drawCards(player, 2)
					end
				else
					room:drawCards(player, 2)
				end
				room:addPlayerMark(player, "LuaZhiji")
				if room:changeMaxHpForAwakenSkill(player) then
					room:acquireSkill(player, "guanxing")
				end
				return false
			end ,
			can_trigger = function(self, target)
				return (target and target:isAlive() and target:hasSkill(self:objectName()))
						and (target:getMark("LuaZhiji") == 0)
						and (target:getPhase() == sgs.Player_Start)
						and target:isKongcheng()
			end
		}
```
[返回索引](#技能索引)

##制霸
**相关武将**：山·孙策  
**描述**：**主公技，**出牌阶段限一次，其他吴势力角色的出牌阶段可以与你拼点（“魂姿”发动后，你可以拒绝此拼点）。若其没赢，你可以获得两张拼点的牌。  
**引用**：LuaZhiba；LuaZhibaPindian（技能暗将）  
**状态**：1217验证通过  
```lua
		LuaZhibaCard = sgs.CreateSkillCard{
			name = "LuaZhibaCard",
			target_fixed = false,
			will_throw = false,
			filter = function(self, targets, to_select)
				if #targets == 0 then
					if to_select:hasLordSkill("LuaSunceZhiba") then
						if to_select:objectName() ~= sgs.Self:objectName() then
							if not to_select:isKongcheng() then
								return not to_select:hasFlag("ZhibaInvoked")
							end
						end
					end
				end
				return false
			end,
			on_use = function(self, room, source, targets)
				local target = targets[1]
				room:setPlayerFlag(target, "ZhibaInvoked")
				if target:getMark("hunzi") > 0 then
					local choice = room:askForChoice(target, "LuaZhibaPindian", "accept+reject")
					if choice == "reject" then
						return
					end
				end
				source:pindian(target, "LuaZhibaPindian", self)
				local sunces = sgs.SPlayerList()
				local players = room:getOtherPlayers(source)
				for _,p in sgs.qlist(players) do
					if p:hasLordSkill("sunce_zhiba") then
						if not p:hasFlag("ZhibaInvoked") then
							sunces:append(p)
						end
					end
				end
				if sunces:length() == 0 then
					room:setPlayerFlag(source, "ForbidZhiba")
				end
			end
		}
		LuaZhibaPindian = sgs.CreateViewAsSkill{
			name = "LuaZhibaPindian",
			n = 1,
			view_filter = function(self, selected, to_select)
				return not to_select:isEquipped()
			end,
			view_as = function(self, cards)
				if #cards == 1 then
					local card = LuaZhibaCard:clone()
					card:addSubcard(cards[1])
					return card
				end
			end,
			enabled_at_play = function(self, player)
				if player:getKingdom() == "wu" then
					if not player:isKongcheng() then
						return not player:hasFlag("ForbidZhiba")
					end
				end
				return false
			end
		}
		LuaZhiba = sgs.CreateTriggerSkill{
			name = "LuaZhiba$",
			frequency = sgs.Skill_NotFrequent,
			events = {sgs.TurnStart, sgs.Pindian, sgs.EventPhaseChanging, sgs.EventAcquireSkill, sgs.EventLoseSkill},
			can_trigger = function(self, target)
				return target ~= nil
			end,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if event == sgs.TurnStart or event == sgs.EventAcquireSkill and data:toString() == self:objectName() then
					local lords = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if p:hasLordSkill(self:objectName()) then
							lords:append(p)
						end
					end
					if lords:isEmpty() then return false end
					local players = sgs.SPlayerList()
					if lords:length()>1 then player = room:getAlivePlayers()
					else players = room:getOtherPlayers(lords:first())
					end
					for _,p in sgs.qlist(players) do
						if not p:hasSkill("LuaZhibaPindian") then
							room:attachSkillToPlayer(p, "LuaZhibaPindian")
						end
					end
				elseif event == sgs.EventLoseSkill and data:toString() == "LuaSunceZhiba" then
					local lords = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if p:hasLordSkill(self:objectName()) then
							lords:append(p)
						end
					end
					if lords:length() > 2 then return false end
					local players = sgs.SPlayerList()
					if lords:isEmpty() then player = room:getAlivePlayers()
					else players:append(lords:first())
					end
					for _,p in sgs.qlist(players) do
						if p:hasSkill("LuaZhibaPindian") then
							room:detachSkillToPlayer(p, "LuaZhibaPindian", true)
						end
					end
				elseif event == sgs.Pindian then
					local pindian = data:toPindian()
					if pindian.reason == "LuaZhibaPindian" then
						local target = pindian.to
						if target:hasLordSkill(self:objectName()) then
							if pindian.from_card:getNumber() <= pindian.to_card:getNumber() then
								local choice = room:askForChoice(target, "LuaSunceZhiba", "yes+no")
								if choice == "yes" then
									target:obtainCard(pindian.from_card)
									target:obtainCard(pindian.to_card)
								end
							end
						end
					end
				elseif event == sgs.EventPhaseChanging then
					local phase_change = data:toPhaseChange()
					if phase_change.from == sgs.Player_Play then
						if player:hasFlag("ForbidZhiba") then
							room:setPlayerFlag(player, "-ForbidZhiba")
						end
						local players = room:getOtherPlayers(player)
						for _,p in sgs.qlist(players) do
							if p:hasFlag("ZhibaInvoked") then
								room:setPlayerFlag(p, "-ZhibaInvoked")
							end
						end
					end
				end
				return false
			end,
			priority = -1,
		}
```
[返回索引](#技能索引)

##制衡-制霸孙权
**相关武将**：测试·制霸孙权  
**描述**：出牌阶段，你可以弃置任意数量的牌，然后摸取等量的牌。每阶段可用X+1次，X为你已损失的体力值  
**引用**：LuaXZhiBa  
**状态**：1217验证通过  
```lua
		LuaZhihengCard = sgs.CreateSkillCard{
			name = "LuaZhihengCard",
			target_fixed = true,
			will_throw = false,
			on_use = function(self, room, source, targets)
				room:throwCard(self, source)
				if source:isAlive() then
					local count = self:subcardsLength()
					room:drawCards(source, count)
				end
			end
		}
		LuaXZhiBa = sgs.CreateViewAsSkill{
			name = "LuaXZhiba",
			n = 999,
			view_filter = function(self, selected, to_select)
				return true
			end,
			view_as = function(self, cards)
				if #cards > 0 then
					local zhiheng_card = LuaZhihengCard:clone()
					for _,card in pairs(cards) do
						zhiheng_card:addSubcard(card)
					end
					zhiheng_card:setSkillName(self:objectName())
					return zhiheng_card
				end
			end,
			enabled_at_play = function(self, player)
				local lost = player:getLostHp()
				local used = player:usedTimes("#LuaZhihengCard")
				return used < (lost + 1)
			end
		}
```
[返回索引](#技能索引)

##制衡
**相关武将**：标准·孙权  
**描述**：出牌阶段限一次，你可以弃置至少一张牌：若如此做，你摸等量的牌。 
**引用**：LuaZhiheng  
**状态**：0405验证通过  
```lua
		LuaZhihengCard = sgs.CreateSkillCard{
			name = "LuaZhihengCard",
			target_fixed = true,
			mute = true,
			on_use = function(self, room, source, targets)
				if source:isAlive() then
					room:drawCards(source, self:subcardsLength(), "zhiheng")
				end
			end
		}
		LuaZhiheng = sgs.CreateViewAsSkill{
			name = "LuaZhiheng",
			n = 999,
			view_filter = function(self, selected, to_select)
				return not sgs.Self:isJilei(to_select)
			end,
			view_as = function(self, cards)
				if #cards == 0 then return nil end
				local zhiheng_card = LuaZhihengCard:clone()
				for _,card in pairs(cards) do
					zhiheng_card:addSubcard(card)
				end
				zhiheng_card:setSkillName(self:objectName())
				return zhiheng_card
			end,
			enabled_at_play = function(self, player)
				return not player:hasUsed("#LuaZhihengCard") and player:canDiscard(player, "he")
			end,
			enabled_at_response = function(self, target, pattern)
				return pattern == "@zhiheng"
			end
		}
```
[返回索引](#技能索引)

##智迟
**相关武将**：一将成名·陈宫  
**描述**：**锁定技**，你的回合外，每当你受到一次伤害后，【杀】或非延时类锦囊牌对你无效，直到回合结束。  
**引用**：LuaZhichi、LuaZhichiProtect、LuaZhichiClear  
**状态**：1217验证通过  
```lua
		LuaZhichi = sgs.CreateTriggerSkill{
			name = "LuaZhichi" ,
			events = {sgs.Damaged} ,
			frequency = sgs.Skill_Compulsory ,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if player:getPhase() ~= sgs.Player_NotActive then return false end
				local current = room:getCurrent()
				if current and current:isAlive() and (current:getPhase() ~= sgs.Player_NotActive) then
					if player:getMark("@late") == 0 then
						room:addPlayerMark(player, "@late")
					end
				end
			end
		}
		LuaZhichiProtect = sgs.CreateTriggerSkill{
			name = "#LuaZhichi-protect" ,
			events = {sgs.CardEffected} ,
			on_trigger = function(self, event, player, data)
				local effect = data:toCardEffect()
				if (effect.card:isKindOf("Slash") or effect.card:isNDTrick()) and (effect.to:getMark("@late") > 0) then
					return true
				end
				return false
			end ,
			can_trigger = function(self, target)
				return target
			end
		}
		LuaZhichiClear = sgs.CreateTriggerSkill{
			name = "#LuaZhichi-clear" ,
			events = {sgs.EventPhaseChanging, sgs.Death} ,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if event == sgs.EventPhaseChanging then
					local change = data:toPhaseChange()
					if change.to ~= sgs.Player_NotActive then
						return false
					end
				else
					local death = data:toDeath()
					if (death.who:objectName() ~= player:objectName()) or (player:objectName() ~= room:getCurrent():objectName()) then
						return false
					end
				end
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("@late") > 0 then
						room:setPlayerMark(p, "@late", 0)
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

##智愚
**相关武将**：二将成名·荀攸  
**描述**：每当你受到伤害后，你可以摸一张牌：若如此做，你展示所有手牌。若你的手牌均为同一颜色，伤害来源弃置一张手牌。 
**引用**：LuaZhiyu  
**状态**：0405验证通过  
```lua
		LuaZhiyu = sgs.CreateMasochismSkill{
			name = "LuaZhiyu" ,
			on_damaged = function(self, target, damage)
				if target:askForSkillInvoke(self:objectName(), sgs.QVariant():setValue(damage)) then
					target:drawCards(1, self:objectName())
					local room = target:getRoom()
					if target:isKongcheng() then return false end
					room:showAllCards(target)
					local cards = target:getHandcards()
					local color = cards:first():isRed()
					local same_color = true
					for _, card in sgs.qlist(cards) do
						if card:isRed() ~= color then
							same_color = false
							break
						end
					end
					if same_color and damage.from and damage.from:canDiscard(damage.from, "h") then
						room:askForDiscard(damage.from, self:objectName(), 1, 1)
					end
				end
			end
		}
```
[返回索引](#技能索引)

##忠义
**相关武将**：2013-3v3·关羽  
**描述**：**限定技，**出牌阶段，你可以将一张红色手牌置于武将牌上。若你有“忠义”牌，己方角色使用的【杀】对目标角色造成伤害时，此伤害+1。身份牌重置后，你将“忠义”牌置入弃牌堆。  
**引用**：LuaZhongyi  
**状态**：1217验证通过  
```lua
		LuaZhongyiCard = sgs.CreateSkillCard{
			name = "LuaZhongyiCard",
				will_throw = false,
				target_fixed = true,
				handling_method = sgs.Card_MethodNone,
			on_use = function(self, room, source, targets)
				room:removePlayerMark(source, "@loyal")
				source:addToPile("loyal", self)
			end,
		}
		LuaZhongyiViewAsSkill = sgs.CreateOneCardViewAsSkill{
			name = "LuaZhongyi",
			filter_pattern = ".|red|.|hand",
			enabled_at_play = function(self, player)
				return not player:isKongcheng() and player:getMark("@loyal") > 0
			end,
			view_as = function(self, originalCard)
				local card = LuaZhongyiCard:clone()
				card:addSubcard(originalCard)
				return card
			end,
		}
		LuaZhongyi = sgs.CreateTriggerSkill{
			name = "LuaZhongyi",
			events = {sgs.DamageCaused, sgs.EventPhaseStart, sgs.ActionedReset},
			frequency = sgs.Skill_Limited,
			limit_mark = "@loyal",
			view_as_skill = LuaZhongyiViewAsSkill,
			can_trigger = function(self, target)
				return target ~= nil
			end,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				local mode = room:getMode()
				if event == sgs.DamageCaused then
					local damage = data:toDamage()
					if damage.chain or damage.transfer or not damage.by_user then return false end
					if damage.card and damage.card:isKindOf("Slash") then
						for _,p in sgs.qlist(room:getAllPlayers()) do
							if not p:getPile("loyal"):isEmpty() then
								local on_effect = false
								if string.sub(room:getMode(), 1, 3) == "06_" then
									on_effect = string.sub(player:getRole(), 1, 1) == string.sub(p:getRole(), 1, 1)
								else
									on_effect = room:askForSkillInvoke(p, "zhongyi", data)
								end
								if on_effect then
									damage.damage = damage.damage + 1
								end
							end
						end
					end
					data:setValue(damage)
				elseif (mode == "06_3v3" and event == sgs.ActionedReset) or (mode ~= "06_3v3" and event == sgs.EventPhaseStart) then
					if event == sgs.EventPhaseStart and player:getPhase() ~= sgs.Player_RoundStart then
						return false
					end
					if player:getPile("loyal"):length() > 0 then
						player:clearOnePrivatePile("loyal")
					end
				end
				return false
			end,
		}
```
[返回索引](#技能索引)

##咒缚
**相关武将**：SP·张宝  
**描述**：阶段技。你可以将一张手牌移出游戏并选择一名无“咒缚牌”的其他角色：若如此做，该角色进行判定时，以“咒缚牌”作为判定牌。一名角色的回合结束后，若该角色有“咒缚牌”，你获得该牌。   
**引用**：LuaZhoufu  
**状态**：1217验证通过  
```lua
		LuaZhoufuCard = sgs.CreateSkillCard{
			name = "LuaZhoufuCard",
			will_throw = false,
			handling_method =sgs.Card_MethodNone,			
			filter = function(self, targets, to_select)
				return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getPile("incantation"):isEmpty()
			end,			
			on_use = function(self, room, source, targets)
				local target = targets[1]
				local value = sgs.QVariant()
					value:setValue(source)
					target:setTag("LuaZhoufuSource" .. tostring(self:getEffectiveId()),value)
					target:addToPile("incantation",self)
			end
		}
		LuaZhoufuVS = sgs.CreateOneCardViewAsSkill{
			name = "LuaZhoufu",
			filter_pattern = ".|.|.|hand",			
			view_as = function(self, cards)
				local card = LuaZhoufuCard:clone()
					card:addSubcard(cards)
				return card
			end,		
			enabled_at_play = function(self,player)
				return not player:hasUsed("#LuaZhoufuCard")
			end
		}
		LuaZhoufu = sgs.CreateTriggerSkill{
			name = "LuaZhoufu",
			events = {sgs.StartJudge,sgs.EventPhaseChanging},
			view_as_skill = LuaZhoufuVS,			
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if event == sgs.StartJudge then
					local card_id = player:getPile("incantation"):first()
					local judge = data:toJudge()
						judge.card = sgs.Sanguosha:getCard(card_id)
						room:moveCardTo(judge.card,nil,judge.who,sgs.Player_PlaceJudge,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_JUDGE,judge.who:objectName(),self:objectName(),"",judge.reason),true)
						judge:updateResult()
						room:setTag("SkipGameRule",sgs.QVariant(true))
				else
					local change = data:toPhaseChange()
					if change.to == sgs.Player_NotActive then
					local id = player:getPile("incantation"):first()
					local zhangbao = player:getTag("LuaZhoufuSource" .. tostring(id)):toPlayer()
					if zhangbao and zhangbao:isAlive() then
						zhangbao:obtainCard(sgs.Sanguosha:getCard(id))
						end
					end
				end
			end,
			can_trigger = function(self, target)
				return target ~= nil and target:getPile("incantation"):length() > 0
			end
		}
```
[返回索引](#技能索引)

##筑楼
**相关武将**：翼·公孙瓒  
**描述**：回合结束阶段开始时，你可以摸两张牌，然后失去1点体力或弃置一张武器牌。  
**引用**：LuaXZhulou  
**状态**：1217验证通过  
```lua
		LuaXZhulou = sgs.CreateTriggerSkill{
			name = "LuaXZhulou",
			frequency = sgs.Skill_NotFrequent,
			events = {sgs.EventPhaseStart},
			on_trigger = function(self, event, player, data)
				local room = player:getRoom();
				if player:getPhase() == sgs.Player_Finish then
					if player:askForSkillInvoke(self:objectName()) then
						player:drawCards(2)
						if not room:askForCard(player, ".Weapon", "@zhulou-discard", sgs.QVariant(), sgs.Card_MethodDiscard) then
							room:loseHp(player)
						end
					end
				end
				return false
			end
		}
```
[返回索引](#技能索引)

##追忆
**相关武将**：二将成名·步练师  
**描述**：你死亡时，可以令一名其他角色（杀死你的角色除外）摸三张牌并回复1点体力。  
**引用**：LuaZhuiyi  
**状态**：1217验证通过  
```lua
		LuaZhuiyi = sgs.CreateTriggerSkill{
			name = "LuaZhuiyi" ,
			events = {sgs.Death} ,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				local death = data:toDeath()
				if death.who:objectName() ~= player:objectName() then return false end
				local targets
				if death.damage and death.damage.from then
					targets = room:getOtherPlayers(death.damage.from)
				else
					targets = room:getAlivePlayers()
				end
				if targets:isEmpty() then return false end
				local prompt = "zhuiyi-invoke"
				if death.damage and death.damage.from and (death.damage.from:objectName() ~= player:objectName()) then
					prompt = "zhuiyi-invokex:" .. death.damage.from:objectName()
				end
				local target = room:askForPlayerChosen(player,targets,self:objectName(), prompt, true, true)
				if not target then return false end
				target:drawCards(3)
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1
				room:recover(target, recover, true)
				return false
			end,
			can_trigger = function(self, target)
				return target and target:hasSkill(self:objectName())
			end
		}
```
[返回索引](#技能索引)

##惴恐
**相关武将**：一将成名2013·伏皇后  
**描述**： 一名其他角色的回合开始时，若你已受伤，你可以与其拼点：若你赢，该角色跳过出牌阶段；若你没赢，该角色与你距离为1，直到回合结束。  
**引用**：LuaZhuikong、LuaZhuikongClear  
**状态**：1217验证通过  
```lua
		LuaZhuikong = sgs.CreateTriggerSkill{
			name = "LuaZhuikong",
			events = {sgs.EventPhaseStart},
			can_trigger = function(self, target)
				return target ~= nil
			end,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				if player:getPhase() ~= sgs.Player_RoundStart or player:isKongcheng() then
					return false
				end
				local skip = false
				local fuhuanghou = room:findPlayerBySkillName(self:objectName())
				if player:objectName() ~= fuhuanghou:objectName() and fuhuanghou:isWounded() and not fuhuanghou:isKongcheng()
						and room:askForSkillInvoke(fuhuanghou, self:objectName()) then
					if fuhuanghou:pindian(player, self:objectName(), nil) then
						if not skip then
							player:skip(sgs.Player_Play)
							skip = true
						end
					else
						room:setFixedDistance(player, fuhuanghou, 1)
						local new_data = sgs.QVariant()
						new_data:setValue(fuhuanghou)
						player:setTag(self:objectName(), new_data)
					end
				end
				return false
			end	
		}
		LuaZhuikongClear = sgs.CreateTriggerSkill{
			name = "#LuaZhuikong-clear",
			events = {sgs.EventPhaseChanging},
			can_trigger = function(self, target)
				return target ~= nil
			end,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				local change = data:toPhaseChange()
				if change.to ~= sgs.Player_NotActive then
					return false
				end
				local fuhuanghou = player:getTag("LuaZhuikong"):toPlayer() 
				if fuhuanghou then
					room:setFixedDistance(player, fuhuanghou, -1)
				end
				player:removeTag("zhuikong")
				return false
			end,
		}
```
[返回索引](#技能索引)

##资粮
**相关武将**：阵·邓艾  
**描述**：每当一名角色受到伤害后，你可以将一张“田”交给该角色。  
**引用**：LuaZiliang  
**状态**：1217验证成功  
```lua
		LuaZiliang = sgs.CreateTriggerSkill{
			name = "LuaZiliang",
			events  = {sgs.Damaged},
			can_trigger = function(self, target)
				return target ~= nil
			end,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				local dengai = room:findPlayerBySkillName(self:objectName())
				if not player:isAlive() then return false end
				if dengai:getPile("field"):isEmpty() then return false end
				if not room:askForSkillInvoke(dengai, self:objectName(), data) then return false end
				room:fillAG(dengai:getPile("field"), dengai)
				local id = room:askForAG(dengai, dengai:getPile("field"), false, self:objectName())
				room:clearAG(dengai)
				room:obtainCard(player, id)
				return false
			end,
		}
```
[返回索引](#技能索引)

##自立
**相关武将**：一将成名·钟会  
**描述**：**觉醒技，**准备阶段开始时，若“权”大于或等于三张，你失去1点体力上限，摸两张牌或回复1点体力，然后获得“排异”。  
**引用**：LuaZili  
**状态**：0405验证通过  
```lua
	LuaZili = sgs.CreatePhaseChangeSkill{
		name = "LuaZili" ,
		frequency = sgs.Skill_Wake ,
		on_phasechange = function(self, player)
			local room = player:getRoom()
			room:notifySkillInvoked(player, self:objectName())
			room:setPlayerMark(player, self:objectName(), 1)
			if room:changeMaxHpForAwakenSkill(player) then
				if player:isWounded() and room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
					room:recover(player, sgs.RecoverStruct(player))
				else
					room:drawCards(player, 2)
				end
				if player:getMark(self:objectName()) == 1 then
					room:acquireSkill(player, "paiyi")
				end
			end
			return false
		end ,
		can_trigger = function(self, target)
			return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
			and target:getMark(self:objectName()) == 0 and target:getPile("power"):length() >= 3
		end
	}
```
[返回索引](#技能索引)

##自守
**相关武将**：二将成名·刘表  
**描述**：摸牌阶段，若你已受伤，你可以额外摸X张牌（X为你已损失的体力值），然后跳过你的出牌阶段。  
**引用**：LuaZishou  
**状态**：1217验证通过  
```lua
		LuaZishou = sgs.CreateTriggerSkill{
			name = "LuaZishou" ,
			events = {sgs.DrawNCards} ,
			on_trigger = function(self, event, player, data)
				local n = data:toInt()
				local room = player:getRoom()
				if player:isWounded() then
					if room:askForSkillInvoke(player, self:objectName()) then
						local losthp = player:getLostHp()
						player:clearHistory()
						player:skip(sgs.Player_Play)
						data:setValue(n + losthp)
					else
						data:setValue(n)
					end
				else
					data:setValue(n)
				end
			end
		}
```
[返回索引](#技能索引)

##宗室
**相关武将**：二将成名·刘表  
**描述**：**锁定技，**你的手牌上限+X（X为现存势力数）。  
**引用**：LuaZongshi  
**状态**：1217验证通过  
```lua
		LuaZongshi = sgs.CreateMaxCardsSkill{
			name = "LuaZongshi" ,
			extra_func = function(self, target)
				local extra = 0
				local kingdom_set = {}
				table.insert(kingdom_set, target:getKingdom())
				for _, p in sgs.qlist(target:getSiblings()) do
					local flag = true
					for _, k in ipairs(kingdom_set) do
						if p:getKingdom() == k then
							flag = false
							break
						end
					end
					if flag then table.insert(kingdom_set, p:getKingdom()) end
				end
				extra = #kingdom_set
				if target:hasSkill(self:objectName()) then
					return extra
				else
					return 0
				end
			end
		}
```
[返回索引](#技能索引)

##纵火
**相关武将**：倚天·陆伯言  
**描述**：**锁定技，**你的杀始终带有火焰属性。  
**引用**：LuaZonghuo  
**状态**：1217验证通过  
```lua
		LuaZonghuo = sgs.CreateTriggerSkill{
			name = "LuaZonghuo" ,
			frequency = sgs.Skill_Compulsory ,
			events = {sgs.CardUsed} ,
			on_trigger = function(self, room, player, data)
				local use = data:toCardUse()
				if use.card:isKindOf("Slash") and (not use.card:isKindOf("FireSlash")) then
					local fire_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
					if not use.card:isVirtualCard() then
						fire_slash:addSubcard(use.card)
					elseif use.card:subcardsLength() > 0 then
						for _, id in sgs.qlist(use.card:getSubcards()) do
							fire_slash:addSubcard(id)
						end
					end
					fire_slash:setSkillName(self:objectName())
					use.card = fire_slash
					data:setValue(use)
				end
				return false
			end
		}
```
[返回索引](#技能索引)

##纵适
**相关武将**：一将成名2013·简雍  
**描述**：每当你拼点赢，你可以获得对方的拼点牌。每当你拼点没赢，你可以获得你的拼点牌。  
**引用**：LuaZongshih  
**状态**：1217验证通过  
```lua
		LuaZongshih = sgs.CreateTriggerSkill{
			name = "LuaZongshih" ,
			events = {sgs.Pindian} ,
			frequency = sgs.Skill_Frequent ,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				local pindian = data:toPindian()
				local to_obtain = nil
				local jianyong = nil
				if (pindian.from and pindian.from:isAlive() and pindian.from:hasSkill(self:objectName())) then
					jianyong = pindian.from
					if pindian.from_number > pindian.to_number then
						to_obtain = pindian.to_card
					else
						to_obtain = pindian.from_card
					end
				elseif (pindian.to and pindian.to:isAlive() and pindian.to:hasSkill(self:objectName())) then
					jianyong = pindian.to
					if pindian.from_number < pindian.to_number then
						to_obtain = pindian.from_card
					else
						to_obtain = pindian.to_card
					end
				end
				if jianyong and to_obtain and (room:getCardPlace(to_obtain:getEffectiveId()) == sgs.Player_PlaceTable) then
					if room:askForSkillInvoke(jianyong, self:objectName(), data) then
						jianyong:obtainCard(to_obtain)
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

##诈降
**相关武将**：界限突破·黄盖  
**描述**：**锁定技，**每当你失去1点体力后，你摸三张牌，若此时为你的回合，本回合，你可以额外使用一张【杀】，你使用红色【杀】无距离限制且此【杀】指定目标后，目标角色不能使用【闪】响应此【杀】。     
**引用**：LuaZhaxiang、LuaZhaxiangRedSlash、LuaZhaxiangTargetMod  
**状态**：0405验证通过  
```lua
	LuaZhaxiang = sgs.CreateTriggerSkill {
		name = "LuaZhaxiang",
		events = {sgs.HpLost, sgs.EventPhaseChanging},
		frequency = sgs.Skill_Compulsory,
		priority = function(self, event, priority)
			if event == sgs.EventPhaseChanging then
				return priority == 8
			end
			return self:getPriority(event)
		end,
		can_trigger = function(self, target)
			return target
		end,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.HpLost and player and player:isAlive() and player:hasSkill(self:objectName()) then
				local lose = data:toInt()
				for i = 1, lose, 1 do
					room:sendCompulsoryTriggerLog(player, self:objectName())
					player:drawCards(3)
					if player:getPhase() == sgs.Player_Play then
						room:addPlayerMark(player, self:objectName())
					end
				end
			elseif event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_NotActive or change.to == sgs.Player_RoundStart then
					room:setPlayerMark(player, self:objectName(), 0)
				end
			end
			return false
		end
	}
	LuaZhaxiangRedSlash = sgs.CreateTriggerSkill {
		name = "#LuaZhaxiang",
		events = {sgs.TargetSpecified},
		frequency = sgs.Skill_Compulsory,
		can_trigger = function(self, target)
			return target and target:isAlive() and target:getMark("LuaZhaxiang") > 0
		end,
		on_trigger = function(self, event, player, data)
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") or not use.card:isRed() then return end
			local jink_list = sgs.QList2Table(player:getTag("Jink_"..use.card:toString()):toIntList())
			local index = 1
			local new_jink_list = sgs.IntList()
			for _, p in sgs.qlist(use.to) do
				jink_list[index] = 0
				index = index + 1
			end
			local result = sgs.IntList()
			for i = 1, #jink_list, 1 do
				result:append(jink_list[i])
			end
			local d = sgs.QVariant()
			d:setValue(result)
			player:setTag("Jink_"..use.card:toString(), d)
			return false
		end
	}		
	LuaZhaxiangTargetMod = sgs.CreateTargetModSkill{
		name = "#LuaZhaxiang-target",
		distance_limit_func = function(self, from, card)
			if from:getMark("LuaZhaxiang") > 0 and card:isRed() then
				return 1000
			else
				return 0
			end
		end,
		residue_func = function(self, from)
			return from:getMark("LuaZhaxiang")
		end
	}
```
[返回索引](#技能索引)

##纵玄
**相关武将**：一将成名2013·虞翻  
**描述**：当你的牌因弃置而置入弃牌堆前，你可以将其中任意数量的牌以任意顺序依次置于牌堆顶。  
**引用**：LuaZongxuan  
**状态**：1217验证通过  
```lua
		LuaZongxuanCard = sgs.CreateSkillCard{
			name = "LuaZongxuanCard",
			target_fixed = true,
			will_throw = false,
			handling_method =sgs.Card_MethodNone,
			on_use = function(self, room, source, targets)
				local sbs = {}
				if source:getTag("LuaZongxuan"):toString() ~= "" then
					sbs = source:getTag("LuaZongxuan"):toString():split("+")
				end
				for _,cdid in sgs.qlist(self:getSubcards()) do table.insert(sbs, tostring(cdid))  end
				source:setTag("LuaZongxuan", sgs.QVariant(table.concat(sbs, "+")))
			end
		}
		LuaZongxuanVS = sgs.CreateViewAsSkill{
			name = "LuaZongxuan",
			n = 998,
			view_filter = function(self, selected, to_select)
				local str = sgs.Self:property("LuaZongxuan"):toString()
				return string.find(str, tostring(to_select:getEffectiveId())) end,
			view_as = function(self, cards)
				if #cards ~= 0 then
					local card = LuaZongxuanCard:clone()
					for var=1,#cards do card:addSubcard(cards[var]) end
					return card
				end
			end,
			enabled_at_play = function(self, player)
				return false
			end,
			enabled_at_response=function(self,player,pattern)
				return pattern == "@@LuaZongxuan"
			end,
		}
		function listIndexOf(theqlist, theitem)
			local index = 0
			for _, item in sgs.qlist(theqlist) do
				if item == theitem then return index end
				index = index + 1
			end
		end
		LuaZongxuan = sgs.CreateTriggerSkill{
			name = "LuaZongxuan",
			view_as_skill = LuaZongxuanVS,
			events = {sgs.BeforeCardsMove},
			on_trigger = function(self, event, player, data)
				local room=player:getRoom()
				local move = data:toMoveOneTime()
				local source = move.from
				if not move.from or source:objectName() ~= player:objectName() then return end
				local reason = move.reason.m_reason
				if move.to_place == sgs.Player_DiscardPile then
					if bit32.band(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
						local zongxuan_card = sgs.IntList()
						for i=0, (move.card_ids:length()-1), 1 do
							local card_id = move.card_ids:at(i)
							if room:getCardOwner(card_id):getSeat() == source:getSeat()
								and (move.from_places:at(i) == sgs.Player_PlaceHand
								or move.from_places:at(i) == sgs.Player_PlaceEquip) then
								zongxuan_card:append(card_id)
							end
						end
						if zongxuan_card:isEmpty() then
							return
						end
						local zongxuantable = sgs.QList2Table(zongxuan_card)
						room:setPlayerProperty(player, "LuaZongxuan", sgs.QVariant(table.concat(zongxuantable, "+")))
						while not zongxuan_card:isEmpty() do
							if not room:askForUseCard(player, "@@LuaZongxuan", "@LuaZongxuanput") then break end
							local subcards = sgs.IntList()
							local subcards_variant = player:getTag("LuaZongxuan"):toString():split("+")
							if #subcards_variant>0 then
								for _,ids in ipairs(subcards_variant) do 
									subcards:append(tonumber(ids)) 
								end
								local zongxuan = player:property("LuaZongxuan"):toString():split("+")
								for _, id in sgs.qlist(subcards) do
									zongxuan_card:removeOne(id)
									table.removeOne(zongxuan,tonumber(id))
									if move.card_ids:contains(id) then
										move.from_places:removeAt(listIndexOf(move.card_ids, id))
										move.card_ids:removeOne(id)
										data:setValue(move)
									end
									room:setPlayerProperty(player, "zongxuan_move", sgs.QVariant(tonumber(id)))
									room:moveCardTo(sgs.Sanguosha:getCard(id), player, nil ,sgs.Player_DrawPile, move.reason, true)
									if not player:isAlive() then break end
								end
							end
							player:removeTag("LuaZongxuan")
						end
					end
				end
				return
			end,
		}
```
[返回索引](#技能索引)

##醉乡
**相关武将**：☆SP·庞统  
**描述**：**限定技**，准备阶段开始时，你可以将牌堆顶的三张牌置于你的武将牌上。此后每个准备阶段开始时，你重复此流程，直到你的武将牌上出现同点数的“醉乡牌”，然后你获得所有“醉乡牌”（不能发动“漫卷”）。你不能使用或打出“醉乡牌”中存在的类别的牌，且这些类别的牌对你无效。  
**引用**：LuaZuixiang  
**状态**：1217验证成功  
**Fs注**：此技能与“漫卷”有联系，而有联系部分使用的为本LUA手册的“漫卷”技能并非原版  
```lua
		LuaZuixiangType = {
			"BasicCard",	--sgs.Card_TypeBasic (1)
			"TrickCard",	--sgs.Card_TypeTrick (2)
			"EquipCard"		--sgs.Card_TypeEquip (3)
		}
		LuaDoZuixiang = function(player)
			local room = player:getRoom()
			local type_list = {
				0,	--sgs.Card_TypeBasic (1)
				0,	--sgs.Card_TypeTrick (2)
				0	--sgs.Card_TypeEquip (3)
			}
			for _, card_id in sgs.qlist(player:getPile("dream")) do
				local c = sgs.Sanguosha:getCard(card_id)
				type_list[c:getTypeId()] = 1
			end
			local ids = room:getNCards(3, false)
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = player
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), "LuaZuixiang", nil)
			room:moveCardsAtomic(move, true)
			player:addToPile("dream", ids, true)
			for _, id in sgs.qlist(ids) do
				local cd = sgs.Sanguosha:getCard(id)
				if LuaZuixiangType[cd:getTypeId()] == "EquipCard" then
					if player:getMark("Equips_Nullified_to_Yourself") == 0 then
						room:setPlayerMark(player, "Equips_Nullified_to_Yourself", 1)
					end
					if player:getMark("Equips_of_Others_Nullified_to_You") == 0 then
						room:setPlayerMark(player, "Equips_of_Others_Nullified_to_You", 1)
					end
				end
				if type_list[cd:getTypeId()] == 0 then
					type_list[cd:getTypeId()] = 1
					room:setPlayerCardLimitation(player, "use,response", LuaZuixiangType[cd:getTypeId()], false)
				end
			end
			local zuixiang = player:getPile("dream")
			local numbers = {}
			local zuixiangDone = false
			for _, id in sgs.qlist(zuixiang) do
				local card = sgs.Sanguosha:getCard(id)
				if table.contains(numbers, card:getNumber()) then
					zuixiangDone = true
					break
				end
				table.insert(numbers, card:getNumber())
			end
			if zuixiangDone then
				player:addMark("LuaZuixiangHasTrigger")
				room:setPlayerMark(player, "Equips_Nullified_to_Yourself", 0)
				room:setPlayerMark(player, "Equips_of_Others_Nullified_to_You", 0)
				room:removePlayerCardLimitation(player, "use,response", "BasicCard$0")
				room:removePlayerCardLimitation(player, "use,response", "TrickCard$0")
				room:removePlayerCardLimitation(player, "use,response", "EquipCard%0")
				player:setFlags("LuaManjuanNullified")
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), nil, "LuaZuixiang", nil)
				local move = sgs.CardsMoveStruct()
				move.card_ids = zuixiang
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				move.reason = reason
				room:moveCardsAtomic(move, true)
				player:setFlags("-LuaManjuanNullified")
			end
		end
		LuaZuixiang = sgs.CreateTriggerSkill{
			name = "LuaZuixiang" ,
			events = {sgs.EventPhaseStart, sgs.SlashEffected, sgs.CardEffected} ,
			limit_mark = "@sleep",
			frequency = sgs.Skill_Limited ,
			on_trigger = function(self, event, player, data)
				local room = player:getRoom()
				local zuixiang = player:getPile("dream")
				if (event == sgs.EventPhaseStart) and (player:getMark("LuaZuixiangHasTrigger") == 0) then
					if player:getPhase() == sgs.Player_Start then
						if player:getMark("@sleep") > 0 then
							if not player:askForSkillInvoke(self:objectName()) then return false end
							room:removePlayerMark(player, "@sleep")
							LuaDoZuixiang(player)
						else
							LuaDoZuixiang(player)
						end
					end
				elseif event == sgs.CardEffected then
					if zuixiang:isEmpty() then return false end
					local effect = data:toCardEffect()
					if effect.card:isKindOf("Slash") then return false end
					local eff = true
					for _, card_id in sgs.qlist(zuixiang) do
						local c = sgs.Sanguosha:getCard(card_id)
						if c:getTypeId() == effect.card:getTypeId() then
							eff = false
							break
						end
					end
					return not eff
				elseif event == sgs.SlashEffected then
					if zuixiang:isEmpty() then return false end
					local effect = data:toSlashEffect()
					local eff = true
					for _, card_id in sgs.qlist(zuixiang) do
						local c = sgs.Sanguosha:getCard(card_id)
						if c:getTypeId() == sgs.Card_TypeBasic then
							eff = false
							break
						end
					end
					return not eff
				end
				return false
			end
		}
```
[返回索引](#技能索引)
