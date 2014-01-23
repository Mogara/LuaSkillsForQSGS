--[[
	代码速查手册（S区）
	技能索引：
		伤逝、伤逝、尚义、烧营、涉猎、神愤、甚贤、神戟、神君、神力、神速、神威、神智、生息、师恩、识破、3D识破、恃才、恃勇、弑神、誓仇、慎拒、守成、授业、淑德、淑慎、双刃、双雄、水箭、水泳、死谏、死节、死战、颂词、颂威、肃资、随势
]]--
--[[
	技能名：伤逝（锁定技）
	相关武将：一将成名·张春华
	描述：弃牌阶段外，当你的手牌数小于X时，你将手牌补至X张（X为你已损失的体力值且最多为2）。
	引用：LuaShangshi
	状态：验证通过
]]--
LuaShangshi = sgs.CreateTriggerSkill{
	name = "LuaShangshi",
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.MaxHpChanged, sgs.HpChanged},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local num = player:getHandcardNum()
		local lost = player:getLostHp()
		if lost > 2 then lost = 2 end
		if num >= lost then return end
		if player:getPhase() ~= sgs.Player_Discard then
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if move.from:objectName() == player:objectName() then
					if not room:askForSkillInvoke(player,self:objectName()) then return end
					player:drawCards(lost-num)
				end
			end
			if event == sgs.MaxHpChanged or event == sgs.HpChanged then
				if not room:askForSkillInvoke(player,self:objectName()) then return end
				player:drawCards(lost-num)
			end
		end
	end
}
--[[
	技能名：伤逝
	相关武将：怀旧·张春华
	描述：弃牌阶段外，当你的手牌数小于X时，你可以将手牌补至X张（X为你已损失的体力值）
	引用：LuaNosShangshi
	状态：验证通过
]]--
LuaNosShangshi = sgs.CreateTriggerSkill {
	name = "LuaNosShangshi",
	events={sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.HpChanged, sgs.MaxHpChanged, sgs.EventAcquireSkill},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local CAN = nil
			if move.from:objectName() == player:objectName() then
				CAN = move.from_places:contains(sgs.Player_PlaceHand)
			elseif move.to:objectName() == player:objectName() then
				CAN = move.to_place==sgs.Player_PlaceHand
			end
			if not CAN then
				return
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_Finish then
				return
			end
		end
		if event == sgs.EventAcquireSkill then
			local string = data:toString()
			if string ~= self:objectName() then
				return
			end
		end
		local Num = player:getHandcardNum()
		local Mhp = player:getMaxHp()
		local Lhp = player:getLostHp()
		local x = math.min(Lhp, Mhp) - Num
		if x > 0 and player:getHp() > 0 then
			if player:getPhase() ~= sgs.Player_Discard then
				if player:askForSkillInvoke(self:objectName()) then
					player:drawCards(x)
				end
			end
		end
	end
}
--[[
	技能名：尚义
	相关武将：阵·蒋钦
	描述：出牌阶段限一次，你可以令一名其他角色观看你的手牌，然后你选择一项：1.观看其手牌，然后你可以弃置其中一张黑色牌。2.观看其身份牌。 
]]--
--[[
	技能名：烧营
	相关武将：倚天·陆伯言
	描述：当你对一名不处于连环状态的角色造成一次火焰伤害时，你可选择一名其距离为1的另外一名角色并进行一次判定：若判定结果为红色，则你对选择的角色造成一点火焰伤害
	引用：LuaShaoying
	状态：1217验证通过
]]--
LuaShaoying = sgs.CreateTriggerSkill{
	name = "LuaShaoying" ,
	events = {sgs.PreDamageDone, sgs.DamageComplete} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if event == sgs.PreDamageDone then
			if (not player:isChained()) and damage.from and (damage.nature == sgs.DamageStruct_Fire) and
					(damage.from:isAlive() and damage.from:hasSkill(self:objectName())) then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (player:distanceTo(p) == 1) then
						targets:append(p)
					end
				end
				if targets:isEmpty() then return false end
				if damage.from:askForSkillInvoke(self:objectName(), data) then
					local target = room:askForPlayerChosen(damage.from, targets, self:objectName())
					local _data = sgs.QVariant()
					_data:setValue(target)
					damage.from:setTag("LuaShaoyingTarget", _data)
				end
			end
			return false
		elseif event == sgs.DamageComplete then
			if damage.from == nil then return false end
			local target = damage.from:getTag("LuaShaoyingTarget"):toPlayer()
			damage.from:removeTag("LuaShaoyingTarget")
			if (not target) or (not damage.from) or (damage.from:isDead()) then return false end
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = damage.from
			room:judge(judge)
			if judge:isGood() then
				local shaoying_damage = sgs.DamageStruct()
				shaoying_damage.nature = sgs.DamageStruct_Fire
				shaoying_damage.from = damage.from
				shaoying_damage.to = target
				room:damage(shaoying_damage)
			end
			return false
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：涉猎
	相关武将：神·吕蒙
	描述：摸牌阶段开始时，你可以放弃摸牌，改为从牌堆顶亮出五张牌，你获得不同花色的牌各一张，将其余的牌置入弃牌堆。
	引用：LuaShelie
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
	引用：LuaShenfen
	状态：1217验证通过（未处理胆守）
]]--
LuaShenfenCard = sgs.CreateSkillCard{
	name = "LuaShenfenCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		source:setFlags("LuaShenfenUsing")
		source:loseMark("@wrath", 6)
		local players = room:getOtherPlayers(source)
		for _, player in sgs.qlist(players) do
			room:damage(sgs.DamageStruct("LuaShenfen", source, player))
		end
		for _, player in sgs.qlist(players) do
			player:throwAllEquips()
		end
		for _, player in sgs.qlist(players) do
			room:askForDiscard(player, "LuaShenfen", 4, 4)
		end
		source:turnOver()
		source:setFlags("-LuaShenfenUsing")
	end
}
LuaShenfen = sgs.CreateViewAsSkill{
	name = "LuaShenfen" ,
	n = 0,
	
	view_as = function()
		return LuaShenfenCard:clone()
	end ,
	
	enabled_at_play = function(self,player)
		return player:getMark("@wrath") >= 6 and not player:hasUsed("#LuaShenfenCard")
	end
}
--[[
	技能名：甚贤
	相关武将：SP·星彩
	描述：你的回合外，每当有其他角色因弃置而失去牌时，若其中有基本牌，你可以摸一张牌。
	引用：LuaShenxian
	状态：1217验证通过
]]--
LuaShenxian = sgs.CreateTriggerSkill{
	name = "LuaShenxian" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		if move.from and (move.from:objectName() ~= player:objectName())
				and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
				and (player:getPhase() == sgs.Player_NotActive) then
			local can_draw = 0
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
					can_draw = can_draw + 1
				end
			end
			if can_draw > 0 then
				if move.reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD then
					local n = 0
					for n = 1, can_draw , 1 do
						if player:askForSkillInvoke(self:objectName()) then
							player:drawCards(1)
						else
							break
						end
					end
				elseif player:askForSkillInvoke(self:objectName()) then
					player:drawCards(1)
				end
			end
		end
		return false
	end ,
}
--[[
	技能名：神戟
	相关武将：SP·暴怒战神、2013-3v3·吕布
	描述：若你的装备区没有武器牌，当你使用【杀】时，你可以额外选择至多两个目标。
	状态：1217验证通过
]]--
LuaShenji = sgs.CreateTargetModSkill{
	name = "LuaShenji" ,
	extra_target_func = function(self, from)
		if from:hasSkill(self:objectName()) and from:getWeapon() == nil then
			return 2
		else
			return 0
		end
	end
}
--[[
	技能名：神君（锁定技）
	相关武将：倚天·陆伯言
	描述：游戏开始时，你必须选择自己的性别。回合开始阶段开始时，你必须倒转性别，异性角色对你造成的非雷电属性伤害无效
	引用：LuaShenjun
	状态：1217验证通过
]]--
LuaShenjun = sgs.CreateTriggerSkill{
	name = "LuaShenjun" ,
	events = {sgs.GameStart, sgs.EventPhaseStart, sgs.DamageInflicted} ,
	frequency = sgs.Skill_Compulsory ,
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
			if (damage.nature ~= sgs.DamageStruct_Thunder) and damage.from and
					(damage.from:isMale() ~= player:isMale()) then
				return true
			end
		end
		return false
	end
}
--[[
	技能名：神力（锁定技）
	相关武将：倚天·古之恶来
	描述：出牌阶段，你使用【杀】造成的第一次伤害+X，X为当前死战标记数且最大为3
	引用：LuaShenli
	状态：1217验证通过
]]--
LuaShenli = sgs.CreateTriggerSkill{
	name = "LuaShenli" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.ConfirmDamage} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and (player:getPhase() == sgs.Player_Play) and (not player:hasFlag("shenli")) then
			player:setFlags("shenli")
			local x = player:getMark("@struggle")
			if x > 0 then
				x = math.min(3, x)
				damage.damage = damage.damage + x
				data:setValue(damage)
			end
		end
		return false
	end
}
--[[
	技能名：神速
	相关武将：风·夏侯渊、1v1·夏侯渊1v1
	描述：你可以选择一至两项：
		1.跳过你的判定阶段和摸牌阶段。
		2.跳过你的出牌阶段并弃置一张装备牌。
		你每选择一项，视为对一名其他角色使用一张【杀】（无距离限制）。
	引用：LuaShensu、LuaShensuNDL
	状态：0610验证通过
]]--
LuaShensuCard = sgs.CreateSkillCard{
	name = "LuaShensuCard" ,
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("LuaShensu")
		local tarlist = sgs.PlayerList()
		for i = 1, #targets, 1 do
			tarlist:append(targets[i])
		end
		return slash:targetFilter(tarlist, to_select, sgs.Self)
	end ,
	on_use = function(self, room, source, targets)
		local tarlist = sgs.SPlayerList()
		for _, p in ipairs(targets) do
			tarlist:append(p)
		end
		for _, p in sgs.qlist(tarlist) do
			if not source:canSlash(p, nil, false) then
				tarlist:removeOne(p)
			end
		end
		if tarlist:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("_LuaShensu")
			room:useCard(sgs.CardUseStruct(slash, source, tarlist))
		end
	end
}
LuaShensuVS = sgs.CreateViewAsSkill{
	name = "LuaShensu" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if string.find(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then return false
		else
			return (#selected == 0) and to_select:isKindOf("EquipCard") and (not sgs.Self:isJilei(to_select))
		end
	end ,
	view_as = function(self, cards)
		if string.find(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then
			if #cards == 0 then return LuaShensuCard:clone() else return nil end
		else
			if #cards ~= 1 then return nil end
			local card = LuaShensuCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@LuaShensu") and sgs.Slash_IsAvailable(player)
	end
}
LuaShensu = sgs.CreateTriggerSkill{
	name = "LuaShensu" ,
	events = {sgs.EventPhaseChanging} ,
	view_as_skill = LuaShensuVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if (change.to == sgs.Player_Judge) and (not player:isSkipped(sgs.Player_Judge)) and (not player:isSkipped(sgs.Player_Draw)) then
			if sgs.Slash_IsAvailable(player) then
				if room:askForUseCard(player, "@@LuaShensu1", "@shensu1", 1) then
					player:skip(sgs.Player_Judge)
					player:skip(sgs.Player_Draw)
				end
			end
		elseif sgs.Slash_IsAvailable(player) and (change.to == sgs.Player_Play) and (not player:isSkipped(sgs.Player_Play)) then
			if player:canDiscard(player, "he") then
				if room:askForUseCard(player, "@@LuaShensu2", "@shensu2", 2, sgs.Card_MethodDiscard) then
					player:skip(sgs.Player_Play)
				end
			end
		end
		return false
	end
}
LuaShensuNDL = sgs.CreateTargetModSkill{
	name = "#LuaShensu-slash-ndl" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("LuaShensu") and (card:getSkillName() == "LuaShensu") then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：神威（锁定技）
	相关武将：SP·暴怒战神
	描述：摸牌阶段，你额外摸两张牌；你的手牌上限+2。
	引用：LuaShenwei、LuaShenweiDraw
	状态：1217验证通过
]]--
LuaShenweiDraw = sgs.CreateTriggerSkill{
	name = "#LuaShenwei-draw" ,
	events = {sgs.DrawNCards} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		data:setValue(data:toInt() + 2)
	end
}
LuaShenwei = sgs.CreateMaxCardsSkill{
	name = "LuaShenwei" ,
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return 2
		else
			return 0
		end
	end
}
--[[
	技能名：神智
	相关武将：国战·甘夫人
	描述：准备阶段开始时，你可以弃置所有手牌。若你以此法弃置的牌不少于X张，你回复1点体力。（X为你当前的体力值）
	引用：LuaShenzhi
	状态：1217验证通过
]]--
LuaShenzhi = sgs.CreateTriggerSkill{
	name = "LuaShenzhi" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getPhase() ~= sgs.Player_Start) or (player:isKongcheng()) then return false end
		if room:askForSkillInvoke(player, self:objectName()) then
			for _, card in sgs.qlist(player:getHandcards()) do
				if player:isJilei(card) then return false end
			end
			local handcard_num = player:getHandcardNum()
			player:throwAllHandCards()
			if handcard_num >= player:getHp() then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			end
		end
		return false
	end
}
--[[
	技能名：生息
	相关武将：阵·蒋琬&费祎
	描述：每当你的出牌阶段结束时，若你于此阶段未造成伤害，你可以摸两张牌。 
]]--
--[[
	技能名：师恩
	相关武将：智·司马徽
	描述：其他角色使用非延时锦囊时，可以让你摸一张牌
	引用：LuaShien
	状态：1217验证通过

	注：智水镜的三个技能均有联系，为了方便起见统一使用本LUA版本的技能，并非原版
]]--
LuaShien = sgs.CreateTriggerSkill{
	name = "LuaShien" ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		if not player then return false end
		if (player:getMark("forbid_LuaShien") > 0) or (player:hasFlag("forbid_LuaShien")) then return false end
		local card = data:toCardUse().card
		if card and card:isNDTrick() then
			local room = player:getRoom()
			local shuijing = room:findPlayerBySkillName(self:objectName())
			if not shuijing then return false end
			local _data = sgs.QVariant()
			_data:setValue(shuijing)
			if room:askForSkillInvoke(player, self:objectName(), _data) then
				shuijing:drawCards(1)
			else
				local choice = room:askForChoice(player, "forbid_LuaShien", "yes+no+maybe")
				if choice == "yes" then
					room:setPlayerMark(player, "forbid_LuaShien", 1)
				elseif choice == "maybe" then
					room:setPlayerFlag(player, "forbid_LuaShien")
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (not target:hasSkill(self:objectName()))
	end
}
--[[
	技能名：识破
	相关武将：智·田丰
	描述：任意角色判定阶段判定前，你可以弃置两张牌，获得该角色判定区里的所有牌
	引用：LuaShipo
	状态：1217验证通过
]]--
LuaShipo = sgs.CreateTriggerSkill{
	name = "LuaShipo" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if (player:getPhase() ~= sgs.Player_Judge) or (player:getJudgingArea():length() == 0) then return false end
		local room = player:getRoom()
		local tians = room:findPlayersBySkillName(self:objectName())
		for _, tianfeng in sgs.qlist(tians) do
			if tianfeng:getCardCount(true) >= 2 then
				local _data = sgs.QVariant()
				_data:setValue(player)
				if room:askForSkillInvoke(tianfeng, self:objectName(), _data) then
					if room:askForDiscard(tianfeng, self:objectName(), 2, 2, false, true) then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:addSubcards(player:getJudgingArea())
						tianfeng:obtainCard(dummy)
						break
					end
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：3D识破（锁定技）
	相关武将：3D织梦·李儒
	描述：你不能成为黑桃【杀】或黑桃锦囊的目标。
]]--
Lua3dShipo = sgs.CreateProhibitSkill{
	name = "Lua3dShipo",
	is_prohibited = function(self, from, to, card)
		return card:isKindOf("Slash") or card:isKindOf("TrickCard") and card:getSuit() == sgs.Card_Spade
	end
}
--[[
	技能名：恃才（锁定技）
	相关武将：智·许攸
	描述：当你拼点成功时，摸一张牌
	引用：LuaShicai
	状态：1217验证通过
]]--
LuaShicai = sgs.CreateTriggerSkill{
	name = "LuaShicai" ,
	events = {sgs.Pindian} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local xuyou = room:findPlayerBySkillName(self:objectName())
		if not xuyou then return false end
		local pindian = data:toPindian()
		if (pindian.from:objectName() ~= xuyou:objectName()) and (pindian.to:objectName() ~= xuyou:objectName()) then return false end
		local winner = nil
		if pindian.from_number > pindian.to_number then
			winner = pindian.from
		else
			winner = pindian.to
		end
		if winner:objectName() == xuyou:objectName() then
			xuyou:drawCards(1)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：恃勇（锁定技）
	相关武将：二将成名·华雄
	描述：每当你受到一次红色的【杀】或因【酒】生效而伤害+1的【杀】造成的伤害后，你减1点体力上限。
	引用：LuaShiyong
	状态：1217验证通过
]]--
LuaShiyong = sgs.CreateTriggerSkill{
	name = "LuaShiyong" ,
	events = {sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash")
				and (damage.card:isRed() or damage.card:hasFlag("drank")) then
			player:getRoom():loseMaxHp(player)
		end
		return false
	end
}
--[[
	技能名：弑神（聚气技）
	相关武将：长坂坡·神张飞
	描述：出牌阶段，你可以弃两张相同颜色的“怒”，令任一角色流失1点体力。
]]--
--[[
	技能名：誓仇（主公技、限定技）
	相关武将：☆SP·刘备
	描述：准备阶段开始时，你可以交给一名其他蜀势力角色两张牌。每当你受到伤害时，你将此伤害转移给该角色，然后该角色摸X张牌，直到其第一次进入濒死状态时。（X为伤害点数）
	引用：LuaShichou
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
	技能名：慎拒（锁定技）
	相关武将：1v1·吕蒙
	描述：你的手牌上限+X。（X为弃牌阶段开始时其他角色最大的体力值） 
]]--
--[[
	技能名：守成
	相关武将：阵·蒋琬费祎
	描述：每当一名角色于其回合外失去最后的手牌后，你可以令该角色选择是否摸一张牌。 
]]--
--[[
	技能名：授业
	相关武将：智·司马徽
	描述：出牌阶段，你可以弃置一张红色手牌，指定最多两名其他角色各摸一张牌
	引用：LuaShouye
	状态：1217验证通过

	注：智水镜的三个技能均有联系，为了方便起见统一使用本LUA版本的技能，并非原版
]]--
LuaShouyeCard = sgs.CreateSkillCard{
	name = "LuaShouyeCard" ,
	filter = function(self, targets, to_select)
		if #targets >= 2 then return false end
		if to_select:objectName() == sgs.Self:objectName() then return false end
		return true
	end ,
	on_effect = function(self, effect)
		effect.to:drawCards(1)
		if effect.from:getMark("LuaJiehuo") == 0 then
			effect.from:gainMark("@shouye")
		end
	end
}
LuaShouye = sgs.CreateViewAsSkill{
	name = "LuaShouye" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return (#selected == 0) and (not to_select:isEquipped()) and (to_select:isRed())
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = LuaShouyeCard:clone()
		card:addSubcard(cards[1])
		return card
	end ,
	enabled_at_play = function(self, player)
		return (player:getMark("LuaJiehuo") == 0) or (not player:hasUsed("#LuaShouyeCard"))
	end
}
--[[
	技能名：淑德
	相关武将：贴纸·王元姬
	描述：结束阶段开始时，你可以将手牌数补至等于体力上限的张数。
	引用：LuaShude
	状态：1217验证通过
]]--
LuaShude = sgs.CreateTriggerSkill{
	name = "LuaShude" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local upper = player:getMaxHp()
			local handcard = player:getHandcardNum()
			if handcard < upper then
				if player:getRoom():askForSkillInvoke(player, self:objectName()) then
					player:drawCards(upper - handcard)
				end
			end
		end
	end
}
--[[
	技能名：淑慎
	相关武将：国战·甘夫人
	描述：每当你回复1点体力后，你可以令一名其他角色摸一张牌。
	引用：LuaShushen
	状态：1217验证通过
]]--
LuaShushen = sgs.CreateTriggerSkill{
	name = "LuaShushen" ,
	events = {sgs.HpRecover} ,
	on_trigger = function(self, event, player, data)
		local recover_struct = data:toRecover()
		local recover = recover_struct.recover
		local room = player:getRoom()
		for i = 0, recover - 1, 1 do
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "shushen-invoke", true, true)
			if target then
				target:drawCards(1)
			else
				break
			end
		end
		return false
	end
}
--[[
	技能名：双刃
	相关武将：国战·纪灵
	描述：出牌阶段开始时，你可以与一名其他角色拼点：若你赢，视为你一名其他角色使用一张无距离限制的普通【杀】（此【杀】不计入出牌阶段使用次数的限制）；若你没赢，你结束出牌阶段。
	引用：LuaXShuangren
	状态：0224验证通过
]]--
LuaXShuangrenCard = sgs.CreateSkillCard{
	name = "LuaXShuangrenCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodPindian,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local success = effect.from:pindian(effect.to, "LuaXShuangren", self)
		if success then
			local targets = sgs.SPlayerList()
			local others = room:getOtherPlayers(effect.from)
			for _,target in sgs.qlist(others) do
				if effect.from:canSlash(target, nil, false) then
					targets:append(target)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(effect.from, targets, "shuangren-slash")
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("LuaXShuangren")
				local card_use = sgs.CardUseStruct()
				card_use.card = slash
				card_use.from = effect.from
				card_use.to:append(target)
				room:useCard(card_use, false)
			end
		else
			room:setPlayerFlag(effect.from, "SkipPlay")
		end
	end
}
LuaXShuangrenVS = sgs.CreateViewAsSkill{
	name = "LuaXShuangren",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = LuaXShuangrenCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXShuangren"
	end
}
LuaXShuangren = sgs.CreateTriggerSkill{
	name = "LuaXShuangren",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaXShuangrenVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _,p in sgs.qlist(other_players) do
				if not player:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				room:askForUseCard(player, "@@LuaXShuangren", "@shuangren-card", -1, sgs.Card_MethodPindian)
			end
			if player:hasFlag("SkipPlay") then
				return true
			end
		end
		return false
	end
}
--[[
	技能名：双雄
	相关武将：火·颜良文丑
	描述：摸牌阶段开始时，你可以放弃摸牌，改为进行一次判定，你获得生效后的判定牌，然后你可以将一张与此判定牌颜色不同的手牌当【决斗】使用，直到回合结束。
	引用：LuaShuangxiong
	状态：0610验证通过
]]--
LuaShuangxiongVS = sgs.CreateViewAsSkill{
	name = "LuaShuangxiong",
	n = 1,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		local value = sgs.Self:getMark("LuaShuangxiong")
		if value == 1 then
			return to_select:isBlack()
		elseif value == 2 then
			return to_select:isRed()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local duel = sgs.Sanguosha:cloneCard("duel", cards[1]:getSuit(), cards[1]:getNumber())
			duel:addSubcard(cards[1])
			duel:setSkillName(self:objectName())
			return duel
		end
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("LuaShuangxiong") > 0) and (not player:isKongcheng())
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
				room:setPlayerMark(player, "LuaShuangxiong", 0)
			elseif (player:getPhase() == sgs.Player_Draw) and (player and player:isAlive() and player:hasSkill(self:objectName())) then
				if player:askForSkillInvoke(self:objectName()) then
					room:setPlayerFlag(player, "LuaShuangxiong")
					local judge = sgs.JudgeStruct()
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					local markid = 2
					if judge.card:isRed() then markid = 1 end
					room:setPlayerMark(player, "LuaShuangxiong", markid)
					return true
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				player:obtainCard(judge.card)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：水箭
	相关武将：奥运·孙扬
	描述：摸牌阶段摸牌时，你可以额外摸X+1张牌，X为你装备区的牌数量的一半（向下取整）。
	引用：LuaXShuijian
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
	引用：LuaXShuiyong
	状态：验证通过
]]--
LuaXShuiyong = sgs.CreateTriggerSkill{
	name = "LuaXShuiyong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		return damage.nature == sgs.DamageStruct_Fire
	end
}
--[[
	技能：死谏
	相关武将：国战·田丰
	描述：每当你失去最后的手牌后，你可以弃置一名其他角色的一张牌。
	引用：LuaSijian
	状态：1217验证通过
]]--
LuaSijian = sgs.CreateTriggerSkill{
	name = "LuaSijian" ,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		if (move.from and move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceHand) then
			if event == sgs.BeforeCardsMove then
				if player:isKongcheng() then return false end
				for _, id in sgs.qlist(player:handCards()) do
					if not move.card_ids:contains(id) then return false end
				end
				player:addMark(self:objectName())
			else
				if player:getMark(self:objectName()) == 0 then return false end
				player:removeMark(self:objectName())
				local room = player:getRoom()
				local other_players = room:getOtherPlayers(player)
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(other_players) do
					if player:canDiscard(p, "he") then
						targets:append(p)
					end
				end
				if targets:isEmpty() then return false end
				local to = room:askForPlayerChosen(player, targets, self:objectName(), "sijian-invoke", true, true)
				if to then
					local card_id = room:askForCardChosen(player, to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(card_id, to, tianfeng)
				end
			end
		end
		return false
	end
}
--[[
	技能名：死节
	相关武将：3D织梦·沮授
	描述：每当你受到1点伤害后，可弃置一名角色的X张牌（X为该角色已损失的体力值，且至少为1）。
]]--
--[[
	技能名：死战（锁定技）
	相关武将：倚天·古之恶来
	描述：当你受到伤害时，防止该伤害并获得与伤害点数等量的死战标记；你的回合结束阶段开始时，你须弃掉所有的X个死战标记并流失X点体力
	引用：LuaSizhan
	状态：1217验证通过
]]--
LuaSizhan = sgs.CreateTriggerSkill{
	name = "LuaSizhan" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.DamageInflicted, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			player:gainMark("@struggle", damage.damage)
			return true
		elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Finish) then
			local x = player:getMark("@struggle")
			if x > 0 then
				player:getRoom():loseHp(player, x)
			end
			player:setFlags("-shenli")
		end
		return false
	end
}
--[[
	技能名：颂词
	相关武将：SP·陈琳
	描述：出牌阶段，你可以选择一项：1、令一名手牌数小于其当前的体力值的角色摸两张牌。2、令一名手牌数大于其当前的体力值的角色弃置两张牌。每名角色每局游戏限一次。
	引用：LuaSongci
	状态：1217验证通过
]]--
LuaSongciCard = sgs.CreateSkillCard{
	name = "LuaSongciCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:getMark("@songci") == 0) and (to_select:getHandcardNum() ~= to_select:getHp())
	end ,
	on_effect = function(self, effect)
		local handcard_num = effect.to:getHandcardNum()
		local hp = effect.to:getHp()
		effect.to:gainMark("@songci")
		if handcard_num > hp then
			effect.to:getRoom():askForDiscard(effect.to, "LuaSongci", 2, 2, false, true)
		else
			effect.to:drawCards(2, "LuaSongci")
		end
	end
}
LuaSongciVS = sgs.CreateViewAsSkill{
	name = "LuaSongci" ,
	n = 0 ,
	view_as = function()
		return LuaSongciCard:clone()
	end ,
	enabled_at_play = function(self, player)
		if (player:getMark("@songci") == 0) and (player:getHandcardNum() ~= player:getHp()) then return true end
		for _, sib in sgs.qlist(player:getSiblings()) do
			if (sib:getMark("@songci") == 0) and (sib:getHandcardNum() ~= sib:getHp()) then return true end
		end
		return false
	end
}
LuaSongci = sgs.CreateTriggerSkill{
	name = "LuaSongci" ,
	events = {sgs.Death} ,
	view_as_skill = LuaSongciVS ,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		for _, p in sgs.qlist(player:getRoom():getAllPlayers()) do
			if p:getMark("@songci") > 0 then
				player:getRoom():setPlayerMark(p, "@songci", 0)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
--[[
	技能名：颂威（主公技）
	相关武将：林·曹丕、铜雀台·曹丕
	描述：其他魏势力角色的判定牌为黑色且生效后，该角色可以令你摸一张牌。
	引用：LuaSongwei
	状态：0610验证通过
]]--
LuaSongwei = sgs.CreateTriggerSkill{
	name = "LuaSongwei$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
		local caopis = sgs.SPlayerList()
		if card:isBlack() then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					caopis:append(p)
				end
			end
		end
		while not caopis:isEmpty() do
			local caopi = room:askForPlayerChosen(player, caopis, self:objectName(), "@LuaSongwei-to", true)
			if caopi then
				caopi:drawCards(1)
				caopis:removeOne(caopi)
			else
				break
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and (target:getKingdom() == "wei")
	end
}

--[[
	技能：肃资
	相关武将：1v1·夏侯渊1v1
	描述：每当已死亡的对手的牌因弃置而置入弃牌堆前，你可以获得之。
]]--
--[[
	技能：随势
	相关武将：国战·田丰
	描述：每当其他角色进入濒死状态时，伤害来源可以令你摸一张牌；每当其他角色死亡时，伤害来源可以令你失去1点体力。
	引用：LuaSuishi
	状态：1217验证通过
]]--
LuaSuishi = sgs.CreateTriggerSkill{
	name = "LuaSuishi" ,
	events = {sgs.Dying, sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local target = nil
		if event == sgs.Dying then
			local dying = data:toDying()
			if dying.damage and dying.damage.from then
				target = dying.damage.from
			end
			if (dying.who:objectName() ~= player:objectName()) and target then
				if player:getRoom():askForSkillInvoke(target, self:objectName(), sgs.QVariant("draw:" .. player:objectName())) then
					player:drawCards(1)
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.damage and death.damage.from then
				target = death.damage.from
			end
			if target then
				if player:getRoom():askForSkillInvoke(target, self:objectName(), sgs.QVariant("losehp:" .. player:objectName())) then
					player:getRoom():loseHp(player)
				end
			end
		end
		return false
	end
}
