--[[
	代码速查手册（Y区）
	技能索引：
		延祸、严整、言笑、燕语、耀武、业炎、遗计、疑城、倚天、义从、义从、义舍、义释、异才、毅重、姻礼、银铃、英魂、英姿、影兵、庸肆、勇决、狱刎、御策、援护
]]--

--[[
	技能名：延祸
	相关武将：1v1·何进
	描述：你死亡时，你可以依次弃置对手的X张牌。（X为你死亡时的牌数）
	引用：LuaYanhuo
	状态：1217验证通过
]]--
LuaYanhuo = sgs.CreateTriggerSkill{
	name = "LuaYanhuo",
	events = {sgs.BeforeGameOverJudge,sgs.Death},
	can_trigger = function(self,target)
		return target and not target:isAlive() and target:hasSkill(self:objectName())
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.BeforeGameOverJudge then
			player:setMark(self:objectName(),player:getCardCount())
		else
			local n = player:getMark(self:objectName())
			if n == 0 then return false end			
			local killer = nil
			if room:getMode() == "02_1v1" then
				killer = room:getOtherPlayers(player):first()
			end
			if killer and killer:isAlive() and player:canDiscard(killer,"he") and room:askForSkillInvoke(player,self:objectName()) then
				for i = 1, n, 1 do
					if player:canDiscard(killer,"he") then
						local card_id = room:askForCardChosen(player,killer,"he",self:objectName(),false,sgs.Card_MethodDiscard)
						room:throwCard(sgs.Sanguosha:getCard(card_id),killer,player)
					else
						break
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：严整
	相关武将：☆SP·曹仁
	描述：若你的手牌数大于你的体力值，你可以将你装备区内的牌当【无懈可击】使用。
	引用：LuaYanzheng
	状态：1217验证通过
]]--
LuaYanzheng = sgs.CreateViewAsSkill{
	name = "LuaYanzheng" ,
	n = 1 ,
	view_filter = function(self, cards, to_select)
		return (#cards == 0) and to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local ncard = sgs.Sanguosha:cloneCard("nullification", cards[1]:getSuit(), cards[1]:getNumber())
		ncard:addSubcard(cards[1])
		ncard:setSkillName(self:objectName())
		return ncard
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "nullification") and (player:getHandcardNum() > player:getHp())
	end ,
	enabled_at_nullification = function(self, player)
		return (player:getHandcardNum() > player:getHp()) and (not player:getEquips():isEmpty())
	end
}

--[[
	技能名：言笑
	相关武将：☆SP·大乔
	描述：出牌阶段，你可以将一张方块牌置于一名角色的判定区内，判定区内有“言笑”牌的角色下个判定阶段开始时，获得其判定区里的所有牌。
	引用：LuaYanxiao
	状态：1217验证通过
]]--
LuaYanxiaoCard = sgs.CreateTrickCard{
	name = "YanxiaoCard",
	class_name = "YanxiaoCard",
	target_fixed = false,
	subclass = sgs.LuaTrickCard_TypeDelayedTrick, -- LuaTrickCard_TypeNormal, LuaTrickCard_TypeSingleTargetTrick, LuaTrickCard_TypeDelayedTrick, LuaTrickCard_TypeAOE, LuaTrickCard_TypeGlobalEffect
	filter = function(self, targets, to_select) 
		if #targets ~= 0 then return false end
		if to_select:containsTrick("YanxiaoCard") then return false end		
		return true
	end,
	is_cancelable = function(self, effect)
		return false
	end,
}
LuaYanxiaoVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaYanxiao",
	filter_pattern = ".|diamond",
	view_as = function(self,originalCard)
		local yanxiao = LuaYanxiaoCard:clone()
		yanxiao:addSubcard(originalCard:getId())
		yanxiao:setSkillName(self:objectName())
		return yanxiao
	end
}
LuaYanxiao = sgs.CreatePhaseChangeSkill{
	name = "LuaYanxiao",
	view_as_skill = LuaYanxiaoVS,
	can_trigger = function(self,target)
		if target and target:getPhase() == sgs.Player_Judge then			
			if target:containsTrick("YanxiaoCard") then return true end
		end
		return false
	end,
	on_phasechange = function(self,target)
		local room = target:getRoom()
		local move = sgs.CardsMoveStruct()
		local log = sgs.LogMessage()
		log.type = "$YanxiaoGot"
		log.from = target		
		for _,card in sgs.qlist(target:getJudgingArea()) do
			move.card_ids:append(card:getEffectiveId())			
		end
		log.card_str = table.concat(sgs.QList2Table(move.card_ids),"+")
		room:sendLog(log)
		move.to = target
		move.to_place = sgs.Player_PlaceHand
		room:moveCardsAtomic(move,true)
		return false
	end
}
--[[
	技能名：燕语
	相关武将：SP·夏侯氏
	描述：一名角色的出牌阶段开始时，你可以弃置一张牌：若如此做，本回合的出牌阶段内限三次，一张与该牌类型相同的牌置入弃牌堆时，你可以令一名角色获得之。 
	引用：LuaYanyu
	状态：1217验证通过
]]--
LuaYanyu = sgs.CreateTriggerSkill{
	name = "LuaYanyu" ,
	events = {sgs.EventPhaseStart, sgs.BeforeCardsMove , sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local xiahou = room:findPlayerBySkillName(self:objectName())
			if xiahou and player:getPhase() == sgs.Player_Play then
				if not xiahou:canDiscard(xiahou, "he") then return false end
				local card = room:askForCard(xiahou, "..", "@yanyu-discard", sgs.QVariant(), self:objectName())
				if card then
					xiahou:addMark("LuaYanyuDiscard" .. tostring(card:getTypeId()), 3)
				end
			end
		elseif event == sgs.BeforeCardsMove and self:triggerable(player) then
			local current = room:getCurrent()
			if not current or current:getPhase() ~= sgs.Player_Play then return false end
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile then
				local ids, disabled = sgs.IntList(), sgs.IntList()
				local all_ids = move.card_ids
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if player:getMark("LuaYanyuDiscard" .. tostring(card:getTypeId())) > 0 then
						ids:append(id)
					else
						disabled:append(id)
					end
				end
				if ids:isEmpty() then return false end
					while not ids:isEmpty() do
					room:fillAG(all_ids, player, disabled)
					local only = (all_ids:length() == 1)
					local card_id = -1 
					if only then
						card_id = ids:first()
					else
						card_id = room:askForAG(player, ids, true, self:objectName())
					end
					room:clearAG(player)
					if card_id == -1 then break end
					if only then
						player:setMark("YanyuOnlyId", card_id + 1)
					end
					local card = sgs.Sanguosha:getCard(card_id)
					local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
						string.format("@yanyu-give:::%s:%s\\%s", card:objectName(), card:getSuitString().."_char"
						, card:getNumberString()),only, true)
					player:setMark("YanyuOnlyId", 0)
					if target then
						player:removeMark("LuaYanyuDiscard" .. tostring(card:getTypeId()))
						local index = move.card_ids:indexOf(card_id)
						local place = move.from_places:at(index)
						move.from_places:removeAt(index)
						move.card_ids:removeOne(card_id)
						data:setValue(move)
						ids:removeOne(card_id)
						disabled:append(card_id)
						for _, id in sgs.qlist(ids) do
							local card = sgs.Sanguosha:getCard(id)
							if player:getMark("LuaYanyuDiscard" .. tostring(card:getTypeId())) == 0 then
												ids:removeOne(id)
												disabled:append(id)
							end
						end
						if move.from and move.from:objectName() == target:objectName() and place ~= sgs.Player_PlaceTable then																																																																																														   
							local log = sgs.LogMessage()
							log.type = "$MoveCard"
							log.from = target
							log.to:append(target)
							log.card_str = tostring(card_id)
							room:sendLog(log)
						end
						target:obtainCard(card)
					else
						break
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
							p:setMark("LuaYanyuDiscard1", 0)
							p:setMark("LuaYanyuDiscard2", 0)
							p:setMark("LuaYanyuDiscard3", 0)
						end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--[[
	技能名：耀武（锁定技）
	相关武将：标准·华雄
	描述：每当你受到红色【杀】的伤害时，伤害来源选择一项：回复1点体力，或摸一张牌。
	引用：LuaYaowu
	状态：1217验证通过
]]--
LuaYaowu = sgs.CreateTriggerSkill{
	name = "LuaYaowu" ,
	events = {sgs.DamageInflicted} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:isRed() and damage.from and damage.from:isAlive() then
			local choice = "draw"
			if damage.from:isWounded() then
				choice = room:askForChoice(damage.from, self:objectName(), "recover+draw", data)
			end
			if choice == "recover" then
				local recover = sgs.RecoverStruct()
				recover.who = damage.to
				room:recover(damage.from, recover)
			else
				damage.from:drawCards(1)
			end
		end
		return false
	end
}


--[[
	技能名：业炎（限定技）
	相关武将：神·周瑜
	描述：出牌阶段，你可以对一至三名角色各造成1点火焰伤害；或你可以弃置四种花色的手牌各一张，失去3点体力并选择一至两名角色：若如此做，你对这些角色造成共计至多3点火焰伤害且对其中一名角色造成至少2点火焰伤害。 
	引用：LuaYeyan
	状态：0405验证通过
]]--

Fire = function(player,target,damagePoint)
	local damage = sgs.DamageStruct()
	damage.from = player
	damage.to = target
	damage.damage = damagePoint
	damage.nature = sgs.DamageStruct_Fire
	player:getRoom():damage(damage)
end
function toSet(self)
	local set = {}
	for _,ele in pairs(self)do
		if not table.contains(set,ele) then
			table.insert(set,ele)
		end
	end
	return set
end
LuaGreatYeyanCard = sgs.CreateSkillCard{
	name="LuaGreatYeyanCard",
	will_throw = true,
	skill_name = "LuaYeyan",
	filter = function(self, targets, to_select)
		local i = 0
		for _,p in pairs(targets)do
			if p:objectName() == to_select:objectName() then
				i = i + 1
			end
		end
		local maxVote = math.max(3-#targets,0)+i
		return maxVote
	end,
	feasible = function(self, targets)
		if self:getSubcards():length() ~= 4 then return false end
		local all_suit = {}
		for _,id in sgs.qlist(self:getSubcards())do
			local c = sgs.Sanguosha:getCard(id)
			if not table.contains(all_suit,c:getSuit()) then
				table.insert(all_suit,c:getSuit())
			else
				return false
			end
		end
		if #toSet(targets) == 1 then
			return true
		elseif #toSet(targets) == 2 then
			return #targets == 3
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local criticaltarget = 0
		local totalvictim = 0
		local map = {}
		for _,sp in pairs(targets)do
			if map[sp:objectName()] then
				map[sp:objectName()] = map[sp:objectName()] + 1
			else
				map[sp:objectName()] = 1
			end
		end
		
		if #targets == 1 then
			map[targets[1]:objectName()] = map[targets[1]:objectName()] + 2
		end
		local target_table = sgs.SPlayerList()
		for sp,va in pairs(map)do
			if va > 1 then criticaltarget = criticaltarget + 1  end
			totalvictim = totalvictim + 1
			for _,p in pairs(targets)do
				if p:objectName() == sp then
					target_table:append(p)
					break
				end
			end
		end
		if criticaltarget > 0 then
			room:removePlayerMark(source, "@flame")	
			room:loseHp(source, 3)	
			room:sortByActionOrder(target_table)
			for _,sp in sgs.qlist(target_table)do
				Fire(source, sp, map[sp:objectName()])
			end
		end
	end,
}
LuaSmallYeyanCard = sgs.CreateSkillCard{
	name="LuaSmallYeyanCard",
	will_throw = true,
	skill_name = "LuaYeyan",
	filter = function(self, targets, to_select)
		return #targets < 3
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@flame")
		for _,sp in sgs.list(targets)do
			Fire(source, sp, 1)
		end
	end,
}
LuaYeyanVS = sgs.CreateViewAsSkill{ 
	name = "LuaYeyan",
	n = 4,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() or sgs.Self:isJilei(to_select) then
			return false
		end
		for _,ca in sgs.list(selected)do
			if ca:getSuit() == to_select:getSuit() then return false end
		end
		return true
	end,
	view_as = function(self,cards) 
		if #cards == 0 then
			return LuaSmallYeyanCard:clone()
		end
		if #cards == 4 then
			local YeyanCard = LuaGreatYeyanCard:clone()
			for _,card in ipairs(cards) do
				YeyanCard:addSubcard(card)
			end
			return YeyanCard
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@flame") > 0
	end
}
LuaYeyan = sgs.CreateTriggerSkill{
		name = "LuaYeyan",
		frequency = sgs.Skill_Limited,
		limit_mark = "@flame",
		view_as_skill = LuaYeyanVS ,
		on_trigger = function() 
		end
}
--[[
	技能名：遗计
	相关武将：标准·郭嘉
	描述：每当你受到1点伤害后，你可以观看牌堆顶的两张牌，将其中一张交给一名角色，然后将另一张交给一名角色。
	引用：LuaYiji
	状态：1217验证通过
]]--
LuaYiji = sgs.CreateTriggerSkill{
	name = "LuaYiji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local x = damage.damage
		for i = 0, x - 1, 1 do
			if not player:isAlive() then return end
			if not room:askForSkillInvoke(player, self:objectName()) then return end
			local _guojia = sgs.SPlayerList()
			_guojia:append(player)
			local yiji_cards = room:getNCards(2, false)
			local move = sgs.CardsMoveStruct(yiji_cards, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, _guojia)
			room:notifyMoveCards(false, moves, false, _guojia)
			local origin_yiji = sgs.IntList()
			for _, id in sgs.qlist(yiji_cards) do
				origin_yiji:append(id)
			end
			while room:askForYiji(player, yiji_cards, self:objectName(), true, false, true, -1, room:getAlivePlayers()) do
				local move = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
				for _, id in sgs.qlist(origin_yiji) do
					if room:getCardPlace(id) ~= sgs.Player_DrawPile then
						move.card_ids:append(id)
						yiji_cards:removeOne(id)
					end
				end
				origin_yiji = sgs.IntList()
				for _, id in sgs.qlist(yiji_cards) do
					origin_yiji:append(id)
				end
				local moves = sgs.CardsMoveList()
				moves:append(move)
				room:notifyMoveCards(true, moves, false, _guojia)
				room:notifyMoveCards(false, moves, false, _guojia)
				if not player:isAlive() then return end
			end
			if not yiji_cards:isEmpty() then
				local move = sgs.CardsMoveStruct(yiji_cards, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
				local moves = sgs.CardsMoveList()
				moves:append(move)
				room:notifyMoveCards(true, moves, false, _guojia)
				room:notifyMoveCards(false, moves, false, _guojia)
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist(yiji_cards) do
					dummy:addSubcard(id)
				end
				player:obtainCard(dummy, false)
			end
		end
		return false
	end
}
--[[
	技能名：疑城
	相关武将：阵·徐盛
	描述：每当一名角色被指定为【杀】的目标后，你可以令该角色摸一张牌，然后弃置一张牌。
	引用：LuaYicheng
	状态：1217验证通过 
]]--
LuaYicheng = sgs.CreateTriggerSkill{
	name = "LuaYicheng",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return false end
		for _,p in sgs.qlist(use.to) do
			local d = sgs.QVariant()
			d:setValue(p)
			if room:askForSkillInvoke(player,self:objectName(),d) then
				p:drawCards(1)
				if p:isAlive() and p:canDiscard(p,"he") then
					room:askForDiscard(p,self:objectName(),1,1,false,true)
				end
				if not player:isAlive() then
					break
				end
			end
		end
		return false
	end
}
--[[
	技能名：倚天（联动技）
	相关武将：倚天·倚天剑
	描述：当你对曹操造成伤害时，可令该伤害-1
	引用：LuaYitian
	状态：1217验证通过
]]--
LuaYitian = sgs.CreateTriggerSkill{
	name = "LuaYitian" ,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if string.find(damage.to:getGeneralName(), "caocao") or string.find(damage.to:getGeneral2Name(), "caocao") then
			if player:askForSkillInvoke(self:objectName(), data) then
				damage.damage = damage.damage - 1
				if damage.damage <= 0 then return true end
				data:setValue(damage)
			end
		end
		return false
	end
}
--[[
	技能名：义从（锁定技）
	相关武将：界限突破·公孙瓒、SP·公孙瓒、翼·公孙瓒、翼·赵云、JSP·赵云
	描述：若你的体力值大于2，你与其他角色的距离-1；若你的体力值小于或等于2，其他角色与你的距离+1。 
	引用：LuaYicong
	状态：0405证通过
]]--
LuaYicong = sgs.CreateDistanceSkill{
	name = "LuaYicong" ,
	correct_func = function(self, from, to)
		local correct = 0
		if from:hasSkill(self:objectName()) and (from:getHp() > 2) then
			correct = correct - 1
		end
		if to:hasSkill(self:objectName()) and (to:getHp() <= 2) then
			correct = correct + 1
		end
		return correct
	end
}
--[[
	技能名：义从
	相关武将：贴纸·公孙瓒
	描述：弃牌阶段结束时，你可以将任意数量的牌置于武将牌上，称为“扈”。每有一张“扈”，其他角色计算与你的距离+1。
	引用：LuaDIYYicong、LuaDIYYicongDistance、LuaDIYYicongClear
	状态：1217验证通过
]]--
LuaDIYYicongCard = sgs.CreateSkillCard{
	name = "LuaDIYYicongCard" ,
	target_fixed = true ,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		source:addToPile("retinue", self)
	end
}
LuaDIYYicongVS = sgs.CreateViewAsSkill{
	name = "LuaDIYYicong" ,
	n = 999,
	view_filter = function()
		return true
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local acard = LuaDIYYicongCard:clone()
		for _, c in ipairs(cards) do
			acard:addSubcard(c)
		end
		return acard
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player , pattern)
		return pattern == "@@LuaDIYYicong"
	end ,
}
LuaDIYYicong = sgs.CreateTriggerSkill{
	name = "LuaDIYYicong" ,
	events = {sgs.EventPhaseEnd} ,
	view_as_skill = LuaDIYYicongVS ,
	on_trigger = function(self, event, player, data)
		if (player:getPhase() == sgs.Player_Discard) and (not player:isNude()) then
			player:getRoom():askForUseCard(player, "@@LuaDIYYicong", "@diyyicong", -1, sgs.Card_MethodNone)
		end
		return false
	end
}
LuaDIYYicongDistance = sgs.CreateDistanceSkill{
	name = "#LuaDIYYicong-dist" ,
	correct_func = function(self, from, to)
		if to:hasSkill("LuaDIYYicong") then
			return to:getPile("retinue"):length()
		else
			return 0
		end
	end
}
LuaDIYYicongClear = sgs.CreateTriggerSkill{
	name = "#LuaDIYYicong-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaDIYYicong" then
			player:clearOnePrivatePile("retinue")
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：义舍
	相关武将：倚天·张公祺
	描述：出牌阶段，你可将任意数量手牌正面朝上移出游戏称为“米”（至多存在五张）或收回；其他角色在其出牌阶段可选择一张“米”询问你，若你同意，该角色获得这张牌，每阶段限两次
	引用：LuaXYishe；LuaXYisheAsk（技能暗将）
	状态：1217验证通过
]]--
LuaXYisheCard = sgs.CreateSkillCard{
	name = "LuaXYisheCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local rice = source:getPile("rice")
		local subs = self:getSubcards()
		if subs:isEmpty() then
			for _,card_id in sgs.qlist(rice) do
				room:obtainCard(source, card_id)
			end
		else
			for _,card_id in sgs.qlist(subs) do
				source:addToPile("rice", card_id)
			end
		end
	end
}
LuaXYisheVS = sgs.CreateViewAsSkill{
	name = "LuaXYishe",
	n = 5,
	view_filter = function(self, selected, to_select)
		local n = sgs.Self:getPile("rice"):length()
		if #selected + n >= 5 then
			return false
		end
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local n = sgs.Self:getPile("rice"):length()
		if n == 0 and #cards == 0 then return nil end
		local card = LuaXYisheCard:clone()
		for _,cd in ipairs(cards) do
			card:addSubcard(cd)
		end
		return card		
	end,
	enabled_at_play = function(self, player)
		if player:getPile("rice"):isEmpty() then
			return not player:isKongcheng()
		else
			return true
		end
	end
}
LuaXYisheAskCard = sgs.CreateSkillCard{
	name = "LuaXYisheAskCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local boss = room:findPlayerBySkillName("LuaXYishe")
		if boss then
			local yishe = boss:getPile("rice")
			if not yishe:isEmpty() then
				local card_id
				if yishe:length() == 1 then
					card_id = yishe:first()
				else
					room:fillAG(yishe, source)
					card_id = room:askForAG(source, yishe, false, "LuaXYisheAsk")
					source:invoke("clearAG")
				end
				room:showCard(source, card_id)
				local choice = room:askForChoice(boss, "LuaXYisheAsk", "allow+disallow")
				if choice == "allow" then
					local card = sgs.Sanguosha:getCard(card_id)
					source:obtainCard(card)
					room:showCard(source, card_id)
				end
			end
		end
	end
}
LuaXYisheAsk = sgs.CreateViewAsSkill{
	name = "LuaXYisheAsk",
	n = 0,
	view_as = function(self, cards)
		return LuaXYisheAskCard:clone()
	end,
	enabled_at_play = function(self, player)
		if not player:hasSkill("LuaXYishe") then
			if player:usedTimes("#LuaXYisheAskCard") < 2 then
				local boss = nil
				local players = player:getSiblings()
				for _,p in sgs.qlist(players) do
					if p:isAlive() then
						if p:hasSkill("LuaXYishe") then
							boss = p
							break
						end
					end
				end
				if boss then
					return not boss:getPile("rice"):isEmpty()
				end
			end
		end
		return false
	end
}
LuaXYishe = sgs.CreateTriggerSkill{
	name = "LuaXYishe",
	events = {sgs.GameStart},
	view_as_skill = LuaXYisheVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local others = room:getOtherPlayers(player)
		for _,p in sgs.qlist(others) do
			room:attachSkillToPlayer(p, "LuaXYisheAsk")
		end
	end
}
--[[
	技能名：义释
	相关武将：翼·关羽
	描述：每当你使用红桃【杀】对目标角色造成伤害时，你可以防止此伤害，改为获得其区域里的一张牌。
	引用：LuaXYishi
	状态：1217验证通过
]]--
LuaXYishi = sgs.CreateTriggerSkill{
	name = "LuaXYishi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local slash = damage.card
		if slash and slash:isKindOf("Slash") then
			if slash:getSuit() == sgs.Card_Heart then
				if not damage.chain and not damage.transfer then
					if player:askForSkillInvoke(self:objectName(), data) then
						local target = damage.to
						if not target:isAllNude() then
							local room = player:getRoom()
							local card_id = room:askForCardChosen(player, target, "hej", self:objectName())
							local name = player:objectName()
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, name)
							local card = sgs.Sanguosha:getCard(card_id)
							local place = room:getCardPlace(card_id)
							room:obtainCard(player, card, place ~= sgs.Player_PlaceHand)
						end
						return true
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：异才
	相关武将：智·姜维
	描述：每当你使用一张非延时类锦囊时(在它结算之前)，可立即对攻击范围内的角色使用一张【杀】
	引用：LuaXYicai
	状态：1217验证通过
]]--
LuaXYicai = sgs.CreateTriggerSkill{
	name = "LuaXYicai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponsed},
	on_trigger = function(self, event, player, data)
		local card = nil
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponsed then
			card = data:toResponsed().m_card
		end
		if card:isNDTrick() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:throwCard(card, nil)
				room:askForUseCard(player, "slash", "@askforslash")
			end
		end
		return false
	end
}
--[[
	技能名：毅重（锁定技）
	相关武将：一将成名·于禁
	描述：若你的装备区没有防具牌，黑色【杀】对你无效。 
	引用：LuaYizhong
	状态：0405验证通过
]]--

LuaYizhong = sgs.CreateTriggerSkill{
	name = "LuaYizhong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.SlashEffected},
	on_trigger = function(self, event, player, data)
		local effect = data:toSlashEffect()
		if effect.slash:isBlack() then
			player:getRoom():notifySkillInvoked(player, self:objectName())
			return true
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil and target:isAlive() and target:hasSkill(self:objectName()) and (target:getArmor() == nil)
	end
}
--[[
	技能名：姻礼
	相关武将：1v1·孙尚香1v1
	描述： 对手的回合内，其拥有的装备牌以未经转化的方式置入弃牌堆时，你可以获得之。
	引用：LuaYinli
	状态：1217验证通过
]]--
LuaYinli = sgs.CreateTriggerSkill{
	name = "LuaYinli",
	events = {sgs.BeforeCardsMove},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if (move.from == nil) or (move.from:objectName() == player:objectName()) then return false end
		if (move.from:getPhase() ~= sgs.Player_NotActive) and (move.to_place == sgs.Player_DiscardPile) then
				local card_ids = sgs.IntList()
			local i = 0
				for _, card_id in sgs.qlist(move.card_ids) do
						if (sgs.Sanguosha:getCard(card_id):getTypeId() == sgs.Card_TypeEquip)  
						and (room:getCardOwner(card_id):objectName() == move.from:objectName())
						and ((move.from_places:at(i) == sgs.Player_PlaceHand) or (move.from_places:at(i) == sgs.Player_PlaceEquip)) then
							card_ids:append(card_id)
						end
				i = i + 1
			end
			if card_ids:isEmpty() then
				return false
	  			elseif player:askForSkillInvoke(self:objectName(), data) then
					while not card_ids:isEmpty() do
					room:fillAG(card_ids, player)
	   				local id = room:askForAG(player, card_ids, true, self:objectName())
						if id == -1 then
					room:clearAG(player)
					break
				end
						card_ids:removeOne(id)
				room:clearAG(player)
					end
			if not card_ids:isEmpty() then
						for _, id in sgs.qlist(card_ids) do
								if move.card_ids:contains(id) then
									move.from_places:removeAt(move.card_ids:indexOf(id))
						 			move.card_ids:removeOne(id)
						data:setValue(move)
								end
					room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
								if not player:isAlive() then break end 
								end
						end
					end
			end
			return false
	end
}
--[[
	技能名：银铃
	相关武将：☆SP·甘宁
	描述：出牌阶段，你可以弃置一张黑色牌并指定一名其他角色。若如此做，你获得其一张牌并置于你的武将牌上，称为“锦”。（数量最多为四）
	引用：LuaYinling、LuaYinlingClear
	状态：1217验证通过
]]--
LuaYinlingCard = sgs.CreateSkillCard{
	name = "LuaYinlingCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if not effect.from:canDiscard(effect.to, "he") or (effect.from:getPile("brocade"):length() >= 4) then return end
		local card_id = room:askForCardChosen(effect.from, effect.to, "he", "LuaYinling", false, sgs.Card_MethodDiscard)
		effect.from:addToPile("brocade", card_id)
	end
}
LuaYinling = sgs.CreateViewAsSkill{
	name = "LuaYinling" ,
	n = 1,
	view_filter = function(self, selected, to_select)
		return (#selected == 0) and to_select:isBlack() and (not sgs.Self:isJilei(to_select))
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = LuaYinlingCard:clone()
		card:addSubcard(cards[1])
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:getPile("brocade"):length() < 4
	end
}
LuaYinlingClear = sgs.CreateTriggerSkill{
	name = "#LuaYinling-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaYinling" then
			player:clearOnePrivatePile("brocade")
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}

--[[
	技能名：英魂
	相关武将：林·孙坚、山·孙策
	描述：准备阶段开始时，若你已受伤，你可以选择一名其他角色并选择一项：1.令其摸一张牌，然后弃置X张牌；2.令其摸X张牌，然后弃置一张牌。（X为你已损失的体力值）
	引用：LuaYinghun
	状态：1217验证通过
]]--
LuaYinghunCard = sgs.CreateSkillCard{
	name = "LuaYinghunCard",
	target_fixed = false,
	will_throw = true,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		local x = source:getLostHp()
		local room = source:getRoom()
		local good = false
		if x == 1 then
			dest:drawCards(1)
			room:askForDiscard(dest, self:objectName(), 1, 1, false, true);
			good = true
		else
			local choice = room:askForChoice(source, self:objectName(), "d1tx+dxt1")
			if choice == "d1tx" then
				dest:drawCards(1)
				x = math.min(x, dest:getCardCount(true))
				room:askForDiscard(dest, self:objectName(), x, x, false, true)
				good = false
			else
				dest:drawCards(x)
				room:askForDiscard(dest, self:objectName(), 1, 1, false, true)
				good = true
			end
		end
		if good then
			room:setEmotion(dest, "good")
		else
			room:setEmotion(dest, "bad")
		end
	end
}
LuaYinghunVS = sgs.CreateViewAsSkill{
	name = "LuaYinghun",
	n = 0,
	view_as = function(self, cards)
		return LuaYinghunCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaYinghun"
	end
}
LuaYinghun = sgs.CreateTriggerSkill{
	name = "LuaYinghun",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaYinghunVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:askForUseCard(player, "@@LuaYinghun", "@yinghun")
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start then
					return target:isWounded()
				end
			end
		end
		return false
	end
}
--[[
	技能名：英姿
	相关武将：标准·周瑜、山·孙策、翼·周瑜
	描述：摸牌阶段，你可以额外摸一张牌。
	引用：LuaYingzi
	状态：1217验证通过
]]--
LuaYingzi = sgs.CreateTriggerSkill{
	name = "LuaYingzi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, "LuaYingzi", data) then
			local count = data:toInt() + 1
			data:setValue(count)
		end
	end
}
--[[
	技能名：影兵
	相关武将：SP·张宝
	描述：每当一张“咒缚牌”成为判定牌后，你可以摸两张牌。
	引用：LuaYingbing
	状态：1217验证通过
	
	注：此技能与咒缚有联系，有联系的地方请使用本手册当中的咒缚，并非原版
]]--
LuaYingbing = sgs.CreateTriggerSkill{
	name = "LuaYingbing",
	events = {sgs.StartJudge},
	frequency = sgs.Skill_Frequent,
	priority = -1,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local id = judge.card:getEffectiveId()
		local zhangbao = player:getTag("LuaZhoufuSource" .. tostring(id)):toPlayer()
		if zhangbao and zhangbao:isAlive() and zhangbao:hasSkill(self:objectName()) and zhangbao:askForSkillInvoke(self:objectName(),data) then
			zhangbao:drawCards(2)
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--[[
	技能名：庸肆（锁定技）
	相关武将：SP·袁术、SP·台版袁术
	描述：摸牌阶段，你额外摸X张牌。弃牌阶段开始时，你须弃置X张牌。（X为现存势力数） 
	引用：LuaYongsi
	状态：0405验证通过
]]--
getKingdoms = function(yuanshu)
	local kingdom_set = {}
	local room = yuanshu:getRoom()
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		local kingdom = p:getKingdom()
		if not table.contains(kingdom_set, kingdom) then
			table.insert(kingdom_set, kingdom)
		end
	end
	return #kingdom_set
end
LuaYongsi = sgs.CreateTriggerSkill{
	name = "LuaYongsi" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.DrawNCards, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = getKingdoms(player)
		if event == sgs.DrawNCards then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			data:setValue(data:toInt() + x)
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			if x > 0 then
				room:askForDiscard(player, self:objectName(), x, x, false, true)
			end
		end
		return false
	end
}
--[[
	技能名：勇决
	相关武将：势·糜夫人
	描述：若一名角色于出牌阶段内使用的第一张牌为【杀】，此【杀】结算完毕后置入弃牌堆时，你可以令其获得之。
	引用：LuaYongjue,LuaYongjueRecord
	状态：1217验证通过
]]--
LuaYongjueRecord = sgs.CreateTriggerSkill{
	name = "#LuaYongjueRecord",
	events = {sgs.PreCardUsed,sgs.CardResponded,sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target ~= nil
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed or event == sgs.CardResponded then
			if player:getPhase() ~= sgs.Player_Play then return false end
			local card = nil
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse and player:getMark("LuaYongjue") == 0 then
				player:addMark("LuaYongjue")
				if card:isKindOf("Slash") then
					local ids = sgs.IntList()
					if not card:isVirtualCard() then
						ids:append(card:getEffectiveId())
					else
						if card:subcardsLength() > 0 then
							ids = card:getSubcards()
						end
					end
					if not ids:isEmpty() then
						room:setCardFlag(card,"LuaYongjue")
						local pdata ,cdata= sgs.QVariant() ,sgs.QVariant()
						pdata:setValue(player)
						cdata:setValue(card)
						room:setTag("LuaYongjue_user",pdata)
						room:setTag("LuaYongjue_card",cdata)
					end
				end
			end			
		else
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Play then
				player:setMark("LuaYongjue",0)
			end
		end
		return false
	end		
}
LuaYongjue = sgs.CreateTriggerSkill{
	name = "LuaYongjue",
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.card_ids:isEmpty() then return false end
		if not (move.from and move.from:isAlive() and move.from:getPhase() == sgs.Player_Play) then return false end		
		local basic = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
		if move.from_places:contains(sgs.Player_PlaceTable) and move.to_place == sgs.Player_DiscardPile and
			(basic == sgs.CardMoveReason_S_REASON_USE) then			
			local yongjue_user = room:getTag("LuaYongjue_user"):toPlayer()
			local yongjue_card = room:getTag("LuaYongjue_card"):toCard()
			room:removeTag("LuaYongjue_card")
			room:removeTag("LuaYongjue_user")
			if yongjue_card and yongjue_user and yongjue_card:hasFlag("LuaYongjue") and move.from:objectName() == yongjue_user:objectName() then
				local ids = sgs.IntList()
				if not yongjue_card:isVirtualCard() then					
					ids:append(yongjue_card:getEffectiveId())
				else
					if yongjue_card:subcardsLength() > 0 then
						ids = yongjue_card:getSubcards()
					end
				end
				if not ids:isEmpty() then					
					for _,id in sgs.qlist(ids) do						
						if not move.card_ids:contains(id) then return false end
					end
				else
					return false
				end
				local pdata = sgs.QVariant()
				pdata:setValue(yongjue_user)				
				if room:askForSkillInvoke(player,self:objectName(),pdata) then
					local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
					for _,id in sgs.qlist(ids) do
						slash:addSubcard(id)
					end
					yongjue_user:obtainCard(slash)
					slash:deleteLater()
					move.card_ids = sgs.IntList()
					data:setValue(move)
				end
			end
		end
		return false
	end	
}
--[[
	技能名：狱刎（锁定技）
	相关武将：智·田丰
	描述：当你死亡时，凶手视为自己
	引用：LuaXYuwen
	状态：1217验证通过（和源码不同）
	附注：除死亡笔记结果不可更改外，其他情况均通过
]]--
LuaXYuwen = sgs.CreateTriggerSkill{
	name = "luaXYuwen",
	events = {sgs.AskForPeachesDone},
	frequency = sgs.Skill_Compulsory,
	priority = 1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if player:getHp() <= 0 and dying.damage and dying.damage.from then
			dying.damage.from = player
			room:killPlayer(player,dying.damage)
			room:setTag("SkipGameRule",sgs.QVariant(true))
		end
	end,
}

--[[
	技能名：御策
	相关武将：一将成名2013·满宠
	描述：每当你受到一次伤害后，你可以展示一张手牌，若此伤害有来源，伤害来源须弃置一张与该牌类型不同的手牌，否则你回复1点体力。
	引用：LuaYuce
	状态：1217验证通过
]]--
LuaYuce = sgs.CreateTriggerSkill{
	name = "LuaYuce" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		if player:isKongcheng() then return false end
		local room = player:getRoom()
		local card = room:askForCard(player, ".", "@yuce-show", data, sgs.Card_MethodNone)
		if card then
			room:showCard(player, card:getEffectiveId())
			local damage = data:toDamage()
			if (not damage.from) or (damage.from:isDead()) then return false end
			local type_name = {"BasicCard", "TrickCard", "EquipCard"}
			local types = {"BasicCard", "TrickCard", "EquipCard"}
			table.removeOne(types,type_name[card:getTypeId()])
			if not damage.from:canDiscard(damage.from, "h") then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			elseif not room:askForCard(damage.from, table.concat(types, ",") .. "|.|.hand",
					"@yuce-discard:" .. player:objectName() .. "::" .. types[1] .. ":" .. types[2], data) then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			end
		end
		return false
	end
}
--[[
	技能名：援护
	相关武将：SP·曹洪
	描述：结束阶段开始时，你可以将一张装备牌置于一名角色装备区内：若此牌为武器牌，你弃置该角色距离1的一名角色区域内的一张牌；若此牌为防具牌，该角色摸一张牌；若此牌为坐骑牌，该角色回复1点体力。  
	引用：LuaYuanhu
	状态：0405验证通过
]]--
LuaYuanhuCard = sgs.CreateSkillCard{
	name = "LuaYuanhuCard",
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		if #targets ~= 0 then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local room = source:getRoom()
		room:moveCardTo(self, source, effect.to, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "LuaYuanhu", ""))
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if card:isKindOf("Weapon") then
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if effect.to:distanceTo(p) == 1 and source:canDiscard(p, "hej") then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local to_dismantle = room:askForPlayerChosen(source, targets, "LuaYuanhu", "@yuanhu-discard:"..effect.to:objectName())
				local card_id = room:askForCardChosen(source, to_dismantle, "hej", "LuaYuanhu", false, sgs.Card_MethodDiscard)
				room:throwCard(sgs.Sanguosha:getCard(card_id), to_dismantle, source)
			end
		elseif card:isKindOf("Armor") then
			effect.to:drawCards(1, "LuaYuanhu")
		elseif card:isKindOf("Horse") then
			room:recover(effect.to, sgs.RecoverStruct(source))
		end
	end
}
LuaYuanhuVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaYuanhu",
	filter_pattern = "EquipCard",
	response_pattern = "@@LuaYuanhu",
	view_as = function(self, card)
		local first = LuaYuanhuCard:clone()
		first:addSubcard(card:getId())
		first:setSkillName(self:objectName())
		return first
	end
}
LuaYuanhu = sgs.CreatePhaseChangeSkill{
	name = "LuaYuanhu",
	view_as_skill = LuaYuanhuVS,
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Finish and not player:isNude() then
			player:getRoom():askForUseCard(player, "@@LuaYuanhu", "@yuanhu-equip", -1, sgs.Card_MethodNone)
		end
		return false
	end
}
