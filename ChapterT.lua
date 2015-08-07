--[[
	代码速查手册（T区）
	技能索引：
		抬榇、贪婪、探虎、探囊、替巾、天妒、天命、天香、天义、挑衅、铁骑、同疾、同心、偷渡、突骑、突袭、突袭、突袭、屯田
]]--
--[[
	技能名：抬榇
	相关武将：倚天·庞令明
	描述：出牌阶段，你可以自减1点体力或弃置一张武器牌，弃置你攻击范围内的一名角色区域的两张牌。每回合中，你可以多次使用抬榇
	引用：LuaTaichen
	状态：1217验证通过
]]--
LuaTaichenCard = sgs.CreateSkillCard{
	name = "LuaTaichenCard" ,
	will_throw = false ,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) or (not sgs.Self:canDiscard(to_select, "hej")) then return false end
		if self:subcardsLength() > 0 then
			local card_id = self:getSubcards():first()
			local range_fix = 0
			if sgs.Self:getWeapon() and (sgs.Self:getWeapon():getId() == card_id) then
				local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
				range_fix = range_fix + weapon:getRange() - 1
			elseif sgs.Self:getOffensiveHorse() and (self:getOffensiveHorse():getId() == card_id) then
				range_fix = range_fix + 1
			end
			return sgs.Self:distanceTo(to_select, range_fix) <= sgs.Self:getAttackRange()
		else
			return sgs.Self:inMyAttackRange(to_select)
		end
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if self:getSubcards():isEmpty() then
			room:loseHp(effect.from)
		else
			room:throwCard(self, effect.from)
		end
		for i = 1, 2, 1 do
			if effect.from:canDiscard(effect.to, "hej") then
				room:throwCard(room:askForCardChosen(effect.from, effect.to, "hej", "LuaTaichen"), effect.to, effect.from)
			end
		end
	end
}
LuaTaichen = sgs.CreateViewAsSkill{
	name = "LuaTaichen" ,
	n = 1,
	view_filter = function(self, selected, to_select)
		return (#selected == 0) and to_select:isKindOf("Weapon")
	end ,
	view_as = function(self, cards)
		if #cards <= 1 then
			local taichen_card = LuaTaichenCard:clone()
			if #cards == 1 then
				taichen_card:addSubcard(cards[1])
			end
			return taichen_card
		else
			return nil
		end
	end
}
--[[
	技能名：贪婪
	相关武将：智·许攸
	描述：每当你受到一次伤害，可与伤害来源进行拼点：若你赢，你获得两张拼点牌
	引用：LuaTanlan
	状态：1217验证通过
]]--
LuaTanlan = sgs.CreateTriggerSkill{
	name = "LuaTanlan" ,
	events = {sgs.Pindian, sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local from = damage.from
			local room = player:getRoom()
			if from and (from:objectName() ~= player:objectName()) and (not from:isKongcheng()) and (not player:isKongcheng()) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					player:pindian(from, self:objectName())
				end
			end
		else
			local pindian = data:toPindian()
			if (pindian.reason == self:objectName() and pindian.success) then
				player:obtainCard(pindian.to_card)
				player:obtainCard(pindian.from_card)
			end
		end
		return false
	end
}
--[[
	技能名：探虎
	相关武将：☆SP·吕蒙
	描述：出牌阶段限一次，你可以与一名角色拼点：若你赢，你拥有以下锁定技：你无视与该角色的距离，你使用的非延时类锦囊牌对该角色结算时不能被【无懈可击】响应，直到回合结束。
	引用：LuaTanhu
	状态：1217验证通过
]]--
LuaTanhuCard = sgs.CreateSkillCard{
	name = "LuaTanhuCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "LuaTanhu", nil)
		if success then
			local _playerdata = sgs.QVariant()
			_playerdata:setValue(targets[1])
			source:setTag("LuaTanhuInvoke", _playerdata)
			targets[1]:setFlags("LuaTanhuTarget")
			room:setFixedDistance(source, targets[1], 1)
		end
	end
}
LuaTanhuVS = sgs.CreateViewAsSkill{
	name = "LuaTanhu" ,
	n = 0,
	view_as = function()
		return LuaTanhuCard:clone()
	end ,
	enabled_at_play = function(self, target)
		return (not target:hasUsed("#LuaTanhuCard")) and (not target:isKongcheng())
	end
}
LuaTanhu = sgs.CreateTriggerSkill{
	name = "LuaTanhu" ,
	events = {sgs.EventPhaseChanging, sgs.Death, sgs.EventLoseSkill, sgs.TrickCardCanceling} ,
	view_as_skill = LuaTanhuVS ,
	on_trigger = function(self, event, player, data)
		if event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.from and effect.from:hasSkill(self:objectName()) and effect.from:isAlive()
					and effect.to and effect.to:hasFlag("LuaTanhuTarget") then
				return true
			end
		elseif player:getTag("LuaTanhuInvoke"):toPlayer() then
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to ~= sgs.Player_NotActive then return false end
			elseif event == sgs.Death then
				local death = data:toDeath()
				if death.who:objectName() ~= player:objectName() then return false end
			elseif event == sgs.EventLoseSkill then
				if data:toString() ~= "LuaTanhu" then return false end
			end
			local target = player:getTag("LuaTanhuInvoke"):toPlayer()
			target:setFlags("-LuaTanhuTarget")
			player:getRoom():setFixedDistance(player, target, -1)
			player:removeTag("LuaTanhuInvoke")
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：探囊（锁定技）
	相关武将：翼·张飞
	描述：你计算的与其他角色的距离-X（X为你已损失的体力值）。
	引用：LuaXTannang
	状态：0504验证通过
]]--
LuaXTannang = sgs.CreateDistanceSkill{
	name = "LuaXTannang",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return -from:getLostHp(
		end
	end
}

--[[
	技能名：替巾
	相关武将：TWYJ·祖茂
	描述：当其他角色使用【杀】指定目标时，若你在其攻击范围内且目标数为1，你可以将之转移给自己，若如此做，当此【杀】结算结束后，你弃置其一张牌。 
	引用：LuaTijin
	状态：0428验证通过
]]--
LuaTijinMap = {}
LuaTijin = sgs.CreateTriggerSkill{
    name = "LuaTijin" ,
    events = {sgs.TargetSpecifying, sgs.CardFinished} ,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end ,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if (event == sgs.TargetSpecifying) then
            if (use.from and use.card and use.card:isKindOf("Slash") and (use.to:length() == 1)) then
                local zumao = room:findPlayerBySkillName(self:objectName())
                if (not zumao) or (not (zumao:isAlive() and zumao:hasSkill(self))) or (use.from:objectName() == zumao:objectName()) or (not use.from:inMyAttackRange(zumao)) then
                    return false
                end
                
                if (zumao:askForSkillInvoke(self, data)) then
                    use.to:first():removeQinggangTag(use.card)
                    while not use.to:isEmpty() do
                        use.to:removeAt(0)
                    end
                    use.to:append(zumao)
                    
                    data:setValue(use)
                    
                    LuaTijinMap[use.card:toString()] = zumao
                end
            end
        else
            if (use.from and use.card) then
                if (LuaTijinMap[use.card:toString()]) then
                    local zumao = LuaTijinMap[use.card:toString()]
                    if (zumao and zumao:isAlive() and zumao:canDiscard(use.from, "he")) then
                        local id = room:askForCardChosen(zumao, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
                        room:throwCard(id, use.from, zumao)
                    end
                end
                LuaTijinMap[use.card:toString()] = nil
            end
        end
        return false
    end ,
}
--[[
	技能名：天妒
	相关武将：标准·郭嘉、SP·台版郭嘉
	描述：在你的判定牌生效后，你可以获得此牌。
	引用：LuaTiandu
	状态：1217验证通过
]]--
LuaTiandu = sgs.CreateTriggerSkill{
	name = "LuaTiandu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
		local card_data = sgs.QVariant()
		card_data:setValue(card)
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and player:askForSkillInvoke(self:objectName(), card_data) then
			player:obtainCard(card)
		end
	end
}
--[[
	技能名：天覆
	相关武将：阵·姜维
	描述：你或与你相邻的角色的回合开始时，该角色可以令你拥有“看破”，直到回合结束。 
	引用：LuaTianfu
	状态：1217验证通过
]]--
LuaTianfu = sgs.CreateTriggerSkill{
	name = "LuaTianfu",
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	priority = 4,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			local jiangweis = room:findPlayersBySkillName(self:objectName())
			for _, jiangwei in sgs.qlist(jiangweis) do 
				local _data = sgs.QVariant()
				_data:setValue(jiangwei)
				if jiangwei:isAlive() and player:objectName() == jiangwei:objectName() or player:isAdjacentTo(jiangwei) and room:askForSkillInvoke(player, self:objectName(),_data) then
					if player:objectName() ~= jiangwei:objectName() then
						room:notifySkillInvoked(jiangwei, self:objectName())
					end
					jiangwei:addMark(self:objectName())
					room:acquireSkill(jiangwei, "kanpo")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do 
				if p:getMark(self:objectName()) > 0 then
					p:setMark(self:objectName(), 0)
					room:detachSkillFromPlayer(p, "kanpo", false, true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--[[
	技能名：天命
	相关武将：铜雀台·汉献帝、SP·刘协
	描述： 每当你被指定为【杀】的目标时，你可以弃置两张牌，然后摸两张牌。若全场唯一的体力值最多的角色不是你，该角色也可以弃置两张牌，然后摸两张牌。 
	引用：LuaTianming
	状态：0405验证通过
]]--
LuaTianming = sgs.CreateTriggerSkill{
	name = "LuaTianming",
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and room:askForSkillInvoke(player,self:objectName()) then
			room:askForDiscard(player, self:objectName(), 2, 2, false, true)
			player:drawCards(2, self:objectName())
			local max = -1000
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getHp() > max then
					max = p:getHp()
				end
			end
			if player:getHp() == max then return false end
			local maxs = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getHp() == max then
					maxs:append(p)
				end
				if maxs:length() > 1 then return false end
			end
			local mosthp = maxs:first()
			if room:askForSkillInvoke(mosthp, self:objectName()) then
				room:doAnimate(sgs.QSanProtocol_S_ANIMATE_INDICATE, player:objectName(), mosthp:objectName())
				room:askForDiscard(mosthp, self:objectName(), 2, 2, false, true)
				mosthp:drawCards(2)
			end
		end
		return false
	end
}
--[[
	技能名：天香
	相关武将：风·小乔
	描述：每当你受到伤害时，你可以弃置一张红桃手牌，将此伤害转移给一名其他角色，然后该角色摸X张牌（X为该角色当前已损失的体力值）。
	引用：LuaTianxiang、LuaTianxiangDraw
	状态：1217验证
]]--
LuaTianxiangCard = sgs.CreateSkillCard{
	name = "LuaTianxiangCard" ,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		effect.to:addMark("LuaTianxiangTarget")
		local damage = effect.from:getTag("LuaTianxiangDamage"):toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			effect.from:removeQinggangTag(damage.card)
		end
		damage.to = effect.to
		damage.transfer = true
		room:damage(damage)
	end
}
LuaTianxiangVS = sgs.CreateViewAsSkill{
	name = "LuaTianxiang" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if #selected ~= 0 then return false end
		return (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Heart) and (not sgs.Self:isJilei(to_select))
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local tianxiangCard = LuaTianxiangCard:clone()
		tianxiangCard:addSubcard(cards[1])
		return tianxiangCard
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaTianxiang"
	end
}
LuaTianxiang = sgs.CreateTriggerSkill{
	name = "LuaTianxiang" ,
	events = {sgs.DamageInflicted} ,
	view_as_skill = LuaTianxiangVS ,
	on_trigger = function(self, event, player, data)
		if player:canDiscard(player, "h") then
			player:setTag("LuaTianxiangDamage", data)
			return player:getRoom():askForUseCard(player, "@@LuaTianxiang", "@tianxiang-card", -1, sgs.Card_MethodDiscard)
		end
		return false
	end
}
LuaTianxiangDraw = sgs.CreateTriggerSkill{
	name = "#LuaTianxiang" ,
	events = {sgs.DamageComplete} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if player:isAlive() and (player:getMark("LuaTianxiangTarget") > 0) and damage.transfer then
			player:drawCards(player:getLostHp())
			player:removeMark("LuaTianxiangTarget")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：天义
	相关武将：火·太史慈
	描述：出牌阶段限一次，你可以与一名角色拼点。若你赢，你获得以下锁定技，直到回合结束：你使用【杀】无距离限制；你于出牌阶段内能额外使用一张【杀】；你使用【杀】选择目标的个数上限+1。若你没赢，你不能使用【杀】，直到回合结束。
	引用：LuaTianyi、LuaTianyiTargetMod
	状态：1217验证通过
]]--
LuaTianyiCard = sgs.CreateSkillCard{
	name = "LuaTianyiCard",

	filter = function(self, targets, to_select)
		return #targets == 0 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
	end,

	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "tianyi", nil)
		if success then
			room:setPlayerFlag(source, "tianyi_success")
		else
			room:setPlayerCardLimitation(source, "use", "Slash", true)
		end
	end
}
LuaTianyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaTianyi",
	view_as = function(self) 
		return LuaTianyiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaTianyiCard") and not player:isKongcheng()
	end, 
}
LuaTianyi = sgs.CreateTriggerSkill{
	name = "LuaTianyi",
	events = {sgs.EventLoseSkill},
	view_as_skill = LuaTianyiVS,
	on_trigger = function(self, event, player, data)
		if data:toString() == self:objectName() then
			room:setPlayerFlag(player, "-tianyi_success")
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("tianyi_success")
	end,
}
LuaTianyiTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaTianyiTargetMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("tianyi_success") then
			return 1
		else
			return 0
		end
	end,
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("tianyi_success") then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("tianyi_success") then
			return 1
		else
			return 0
		end
	end,
}
--[[
	技能名：挑衅
	相关武将：山·姜维，1V1姜维
	描述：出牌阶段，你可以令一名你在其攻击范围内的其他角色选择一项：对你使用一张【杀】，或令你弃置其一张牌。每阶段限一次。
	引用：LuaTiaoxin
	状态：1217验证通过
]]--
LuaTiaoxinCard = sgs.CreateSkillCard{
	name = "LuaTiaoxinCard" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:inMyAttackRange(sgs.Self) and to_select:objectName() ~= sgs.Self:objectName()
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local use_slash = false
		if effect.to:canSlash(effect.from, nil, false) then
			use_slash = room:askForUseSlashTo(effect.to,effect.from, "@tiaoxin-slash:" .. effect.from:objectName())
		end
		if (not use_slash) and effect.from:canDiscard(effect.to, "he") then
			room:throwCard(room:askForCardChosen(effect.from,effect.to, "he", "LuaTiaoxin", false, sgs.Card_MethodDiscard), effect.to, effect.from)
		end
	end
}
LuaTiaoxin = sgs.CreateViewAsSkill{
	name = "LuaTiaoxin",
	n = 0 ,
	view_as = function()
		return LuaTiaoxinCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaTiaoxinCard")
	end
}
--[[
	技能名：铁骑
	相关武将：标准·马超-旧、SP·马超、1v1·马超1v1、SP·台版马超
	描述： 每当你指定【杀】的目标后，你可以进行判定：若结果为红色，该角色不能使用【闪】响应此【杀】。 
	引用：LuaTieji
	状态：0405验证通过
]]--
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
LuaNosTieji = sgs.CreateTriggerSkill{
	name = "LuaNosTieji" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			if not player:isAlive() then break end
			local _data = sgs.QVariant()
			_data:setValue(p)
			if player:askForSkillInvoke(self:objectName(), _data) then
				p:setFlags("LuaNosTiejiTarget")
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				player:getRoom():judge(judge)
				if judge:isGood() then
					jink_table[index] = 0
				end
				p:setFlags("-LuaNosTiejiTarget")
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
}
--[[
	技能名：同疾（锁定技）
	相关武将：标准·袁术
	描述：若你的手牌数大于你的体力值，且你在一名其他角色的攻击范围内，则其他角色不能被选择为该角色的【杀】的目标。
	引用：LuaTongji
	状态：1217验证通过
]]
LuaTongji = sgs.CreateProhibitSkill{
	name = "LuaTongji" ,
	is_prohibited = function(self, from, to, card)
		if card:isKindOf("Slash") then
			local rangefix = 0
			if card:isVirtualCard() then
				local subcards = card:getSubcards()
				if from:getWeapon() and subcards:contains(from:getWeapon():getId()) then
					local weapon = from:getWeapon():getRealCard():toWeapon()
					rangefix = rangefix + weapon:getRange() - 1
				end 
				if from:getOffensiveHorse() and subcards:contains(self:getOffensiveHorse():getId()) then
					rangefix = rangefix + 1
				end
			end
			for _, p in sgs.qlist(from:getAliveSiblings()) do
				if p:hasSkill(self:objectName()) and (p:objectName() ~= to:objectName()) and (p:getHandcardNum() > p:getHp())
						and (from:distanceTo(p, rangefix) <= from:getAttackRange()) then
					return true
				end
			end
		end
		return false
	end
}
--[[
	技能名：同心
	相关武将：倚天·夏侯涓
	描述：处于连理状态的两名角色，每受到一点伤害，你可以令你们两人各摸一张牌
	引用：LuaTongxin
	状态：1217验证通过
]]--
LuaTongxin = sgs.CreateTriggerSkill{
	name = "LuaTongxin" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		local xiahoujuan = room:findPlayerBySkillName(self:objectName())
		if xiahoujuan then
			if xiahoujuan:askForSkillInvoke(self:objectName(), data) then
				local zhangfei = nil
				if player:objectName() == xiahoujuan:objectName() then
					local players = room:getOtherPlayers(xiahoujuan)
					for _, _player in sgs.qlist(players) do
						if _player:getMark("@tied") > 0 then
							zhangfei = _player
							break
						end
					end
				else
					zhangfei = player
				end
				xiahoujuan:drawCards(damage.damage)
				if zhangfei then
					zhangfei:drawCards(damage.damage)
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getMark("@tied") > 0)
	end
}
--[[
	技能名：偷渡
	相关武将：倚天·邓士载
	描述：当你的武将牌背面向上时若受到伤害，你可以弃置一张手牌并将你的武将牌翻面，视为对一名其他角色使用了一张【杀】
	引用：LuaToudu、LuaTouduNDL
	状态：1217验证通过
]]--
LuaTouduCard = sgs.CreateSkillCard{
	name = "LuaTouduCard" ,

	filter = function(self, targets, to_select)
		return #targets == 0 and sgs.Self:canSlash(to_select,nil,false)
	end,

	on_effect = function(self, effect)
		effect.from:turnOver()
		local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			slash:setSkillName("LuaToudu")
		local use = sgs.CardUseStruct()
			use.card = slash
			use.from = effect.from
			use.to:append(effect.to)
			effect.from:getRoom():useCard(use)
		end
}
LuaTouduVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaToudu",
	
	view_filter = function(self,to_select)
		return not to_select:isEquipped()
	end,
	
	view_as = function(self, cards)
		local toudu = LuaTouduCard:clone()
			toudu:addSubcard(cards)
		return toudu
	end,

	enabled_at_play = function()
		return false
	end,
	
	enabled_at_response=function(self, player, pattern)
		return pattern == "@@LuaToudu"
	end
}
LuaToudu = sgs.CreateMasochismSkill{
	name = "LuaToudu",
	view_as_skill = LuaTouduVS,
	
	on_damaged = function(self, player)
		if player:faceUp() or player:isKongcheng() then return false end
			player:getRoom():askForUseCard(player, "@@LuaToudu","@toudu", -1,sgs.Card_MethodDiscard,false)
	end
}
--[[
	技能名：突骑（锁定技）
	相关武将：贴纸·公孙瓒
	描述：准备阶段开始时，若你的武将牌上有“扈”，你将所有“扈”置入弃牌堆：若X小于或等于2，你摸一张牌。本回合你与其他角色的距离-X。（X为准备阶段开始时置于弃牌堆的“扈”的数量）
	引用：LuaXTuqi、LuaXTuqiDist
	状态：1217验证通过
]]--
LuaXTuqi = sgs.CreateTriggerSkill{
	name = "LuaXTuqi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
		
			if player:getPhase() == sgs.Player_Start and player:getPile("retinue"):length() > 0 then
				room:notifySkillInvoked(player, self:objectName())
				local n = player:getPile("retinue"):length()
				room:setPlayerMark(player, "tuqi_dist", n)
				player:clearOnePrivatePile("retinue")
				if n <= 2 then
					player:drawCards(1)
				end
			end
		
		else
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
				room:setPlayerMark(player, "tuqi_dist", 0)
		end
	end
}
LuaXTuqiDist = sgs.CreateDistanceSkill{
	name = "#LuaXTuqi",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return -from:getMark("tuqi_dist")
		end
	end,
}
--[[
	技能名：突袭
	相关武将：界限突破·张辽
	描述：摸牌阶段，你可以少摸至少一张牌并选择等量的有手牌的手牌不少于你的其他角色：若如此做，你依次获得这些角色各一张手牌。 
	引用：LuaTuxi、LuaTuxiAct
	状态：0405验证通过
]]--
LuaTuxiCard = sgs.CreateSkillCard{
	name = "LuaTuxiCard",
	filter = function(self, targets, to_select)
		if #targets >= sgs.Self:getMark("LuaTuxi") or to_select:getHandcardNum() < sgs.Self:getHandcardNum() or to_select:objectName() == sgs.Self:objectName() then return false end
		return not to_select:isKongcheng()
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("LuaTuxiTarget")
	end
}
LuaTuxiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaTuxi",
	response_pattern = "@@LuaTuxi",
	view_as = function() 
		return LuaTuxiCard:clone()
	end
}
LuaTuxi = sgs.CreateDrawCardsSkill{
	name = "LuaTuxi" ,
	view_as_skill = LuaTuxiVS,
	priority = 1,
	draw_num_func = function(self, player, n)
		local room = player:getRoom()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHandcardNum() >= player:getHandcardNum() then
				targets:append(p)
			end
		end
		local num = math.min(targets:length(), n)
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			p:setFlags("-LuaTuxiTarget")
		end
		if num > 0 then
			room:setPlayerMark(player, "LuaTuxi", num)
			local count = 0
			if room:askForUseCard(player, "@@LuaTuxi", "@tuxi-card:::" .. tostring(num)) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasFlag("LuaTuxiTarget") then
						count = count + 1
					end
				end
			else 
				room:setPlayerMark(player, "LuaTuxi", 0)
			end
			return n - count
		else
			return n
		end
	end
}
LuaTuxiAct = sgs.CreateTriggerSkill{
	name = "#LuaTuxi" ,
	events = {sgs.AfterDrawNCards} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("LuaTuxi") == 0 then return false end
		room:setPlayerMark(player, "LuaTuxi", 0)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("LuaTuxiTarget") then
				p:setFlags("-LuaTuxiTarget")
				targets:append(p)
			end
		end
		for _, p in sgs.qlist(targets) do
			if not player:isAlive() then
				break
			end
			if p:isAlive() and not p:isKongcheng() then
				local card_id = room:askForCardChosen(player, p, "h", "LuaTuxi")
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
				room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
			end
		end
		return false
	end
}
--[[
	技能名：突袭
	相关武将：标准·张辽、SP·台版张辽
	描述：摸牌阶段开始时，你可以放弃摸牌并选择一至两名有手牌的其他角色：若如此做，你依次获得这些角色各一张手牌。 
	引用：LuaNosTuxi
	状态：0405验证通过
]]--

LuaNosTuxiCard = sgs.CreateSkillCard{
	name = "LuaNosTuxiCard",
	filter = function(self, targets, to_select)
		if #targets >= 2 or to_select:objectName() == sgs.Self:objectName() then return false end
		return not to_select:isKongcheng()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if effect.from:isAlive() and not effect.to:isKongcheng() then
			local card_id = room:askForCardChosen(effect.from, effect.to, "h", "LuaNosTuxi")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName())
			room:obtainCard(effect.from, sgs.Sanguosha:getCard(card_id), reason, false)
		end
	end
}
LuaNosTuxiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaNosTuxi",
	response_pattern = "@@LuaNosTuxi",
	view_as = function(self) 
		return LuaNosTuxiCard:clone()
	end
}
LuaNosTuxi = sgs.CreatePhaseChangeSkill{
	name = "LuaNosTuxi" ,
	view_as_skill = LuaNosTuxiVS,
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _, player in sgs.qlist(other_players) do
				if not player:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if can_invoke and room:askForUseCard(player, "@@LuaNosTuxi", "@nostuxi-card") then
				return true
			end
		end
		return false
	end
}
--[[
	技能名：突袭
	相关武将：1v1·张辽1v1
	描述：摸牌阶段，若你的手牌数小于对手的手牌数，你可以少摸一张牌并你获得对手的一张手牌。
	引用：LuaKOFTuxi、LuaKOFTuxiAct
	状态：1217验证通过
]]--
LuaKOFTuxi = sgs.CreateDrawCardsSkill{
	name = "LuaKOFTuxi",
	
	draw_num_func = function(self,player,n)
		local room = player:getRoom() 
		local can_invoke = false
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHandcardNum() > player:getHandcardNum() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			can_invoke = true
		end 
		if can_invoke then
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "koftuxi-invoke", true, true)
			if (target) then
				target:setFlags("LuaKOFTuxiTarget")
				player:setFlags("Luakoftuxi")
				return n - 1
			else 
				return n
			end
		else
			return n
		end
end
}
LuaKOFTuxiAct = sgs.CreateTriggerSkill{
	name = "#Luakoftuxi",
	events = {sgs.AfterDrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not player:hasFlag("Luakoftuxi") then
			return false
		end
		player:setFlags("-Luakoftuxi")
		local target = nil
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("LuaKOFTuxiTarget") then
				p:setFlags("-LuaKOFTuxiTarget")
				target = p
				break
			end
		end
		if not target then return false end
		local card_id = room:askForCardChosen(player, target, "h", "koftuxi")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, self:objectName())
		room:moveCardTo(sgs.Sanguosha:getCard(card_id),player,sgs.Player_PlaceHand,reason)
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--[[
	技能名：屯田
	相关武将：山·邓艾
	描述：你的回合外，当你失去牌时，你可以进行一次判定，将非红桃结果的判定牌置于你的武将牌上，称为“田”；每有一张“田”，你计算的与其他角色的距离便-1。
	引用：LuaTuntian、LuaTuntianDistance
	状态：1217验证通过
]]--
LuaTuntian = sgs.CreateTriggerSkill{
	name = "LuaTuntian",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.FinishJudge, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and (move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or  move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
				if not player:askForSkillInvoke("LuaTuntian", data) then return end
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() and judge:isGood() and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
				player:addToPile("field", judge.card:getEffectiveId())
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				player:removePileByName("field")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_NotActive
	end
}
LuaTuntianDistance = sgs.CreateDistanceSkill{
	name = "#LuaTuntianDistance",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return - from:getPile("field"):length()
		else
			return 0
		end
	end  
}
