--[[
	代码速查手册（V区）
	（本区用于收录尚未实现或有争议的技能）
]]--
---------------------------------下面是Fs的0610未验证更改-----------------------------

--[[
Fs在这里多说几句：大家可以对这部分技能尽情测试，要不然的话我一个人边写边测，累也累死了…………
突然发现大家测试的热情不是很高…………
]]
-------------------------------------------------------------------------------
----------------------------[[暂时不会去验证的技能]]----------------------------
-------------------------------------------------------------------------------

--[[
	技能名：奇才（锁定技）
	相关武将：标准·黄月英
	描述：你使用锦囊牌无距离限制。你装备区里除坐骑牌外的牌不能被其他角色弃置。
	引用：LuaQicai
	状态：0610貌似无法实现（怀疑后半段被写入源码，因为在本来属于奇才的位置上的只有TargetMod）
]]--


--[[
	技能名：新生
	相关武将：山·左慈
	描述：每当你受到1点伤害后，你可以获得一张“化身牌”。
	引用：LuaXinSheng
	状态：0610未做
]]--

--[[
	技能名：涉猎
	相关武将：神·吕蒙
	描述：摸牌阶段开始时，你可以放弃摸牌，改为从牌堆顶亮出五张牌，你获得不同花色的牌各一张，将其余的牌置入弃牌堆。
	引用：LuaShelie
	状态：0610未做（貌似此版本有几条语句不能LUA）
]]--

--[[
	技能名：业炎（限定技）
	相关武将：神·周瑜
	描述：出牌阶段，你可以选择一至三名角色，你分别对他们造成最多共3点火焰伤害（你可以任意分配），若你将对一名角色分配2点或更多的火焰伤害，你须先弃置四张不同花色的手牌并失去3点体力。
	状态：0610未做
]]--
--[[
	技能名：伪帝（锁定技）
	相关武将：SP·袁术、SP·台版袁术
	描述：你拥有当前主公的主公技。
	状态：验证失败
]]--
--[[
	技能名：奇策
	相关武将：二将成名·荀攸
	描述：出牌阶段限一次，你可以将你的所有手牌（至少一张）当任意一张非延时锦囊牌使用。
]]--
--[[
	技能名：言笑
	相关武将：☆SP·大乔
	描述：出牌阶段，你可以将一张方块牌置于一名角色的判定区内，判定区内有“言笑”牌的角色下个判定阶段开始时，获得其判定区里的所有牌。
	状态：验证失败
]]--


--[[
	技能名：陷阵
	相关武将：一将成名·高顺
	描述：出牌阶段，你可以与一名其他角色拼点。
		若你赢，你获得以下技能直到回合结束：你无视与该角色的距离及其防具；你对该角色使用【杀】时无次数限制。
		若你没赢，你不能使用【杀】，直到回合结束。每阶段限一次。
	引用：LuaXianzhen
	状态：1217无法转化（源码修改杀的信息需要设置一个QStringList类型的Property，此类型在LUA只能输出不能输入）
]]--

--[[
	技能名：完杀（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。
	引用：LuaWansha
	状态：0610未做（暂时没有想法）
]]--

--[[
	技能名：纵玄
	相关武将：一将成名2013·虞翻
	描述：当你的牌因弃置而置入弃牌堆前，你可以将其中任意数量的牌以任意顺序依次置于牌堆顶。
]]--



--[[
	技能名：争锋（锁定技）
	相关武将：倚天·倚天剑
	描述：当你的装备区没有武器时，你的攻击范围为X，X为你当前体力值。
	状态：0610未做
	备注：争锋涉及更改“杀”以及获得攻击范围的源码，没法做
]]--

--[[
	技能名：危殆（主公技）
	相关武将：智·孙策
	描述：当你需要使用一张【酒】时，所有吴势力角色按行动顺序依次选择是否打出一张黑桃2~9的手牌，视为你使用了一张【酒】，直到有一名角色或没有任何角色决定如此做时为止
	状态：0610未做

	备注：validateInResponse部分已经没有bool引用部分，不知是源码bug还是这么写可以运行。
]]--
--[[

const Card *WeidaiCard::validateInResponse(ServerPlayer *user, bool &continuable) const {
//现在这个版本的validateInResponse已经没有bool引用了啊，这么写是不是运行不了么？这个技能有bug？
	continuable = true;
	Room *room = user->getRoom();
	foreach (ServerPlayer *liege, room->getLieges("wu", user)) {
		QVariant tohelp = QVariant::fromValue((PlayerStar)user);
		QString prompt = QString("@weidai-analeptic:%1").arg(user->objectName());
		const Card *card = room->askForCard(liege, ".|spade|2~9|hand", prompt, tohelp, Card::MethodDiscard, user);
		if(card){
			Analeptic *ana = new Analeptic(card->getSuit(), card->getNumber());
			ana->setSkillName("weidai");
			ana->addSubcard(card);
			return ana;
		}
	}
	room->setPlayerFlag(user, "Global_WeidaiFailed");
	return NULL;
}
]]
-------------------------------------------------------------------------------
---------------------------------[[就这么多了]]---------------------------------
-------------------------------------------------------------------------------
-----------------------------[[下面是验证失败的技能]]---------------------------
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
---------------------------------[[就这么多了]]---------------------------------
-------------------------------------------------------------------------------
------------------------------[[暂时不会动的技能]]------------------------------
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
---------------------------------[[就这么多了]]---------------------------------
-------------------------------------------------------------------------------

--[[
	技能名：慷忾
	相关武将：SP026·曹昂
	描述：每当一名角色成为【杀】的目标后，若你与其的距离不大于1，你可以摸一张牌，若如此做，你先将一张牌交给该角色再令其展示之，若此牌为装备牌，其可以使用之。
	引用：LuaKangkai
	状态：1217待验证（测试了一下，大概没啥问题） 
]]--
LuaKangkai = sgs.CreateTriggerSkill{
	name = "LuaKangkai",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.card:isKindOf("Slash") then
			for _,to in sgs.qlist(use.to) do
				if not player:isAlive() then break end
				if player:distanceTo(to) <= 1 and room:askForSkillInvoke(player,self:objectName()) then
					player:drawCards(1)
					if (not player:isNude()) and (player:objectName() ~= to:objectName()) then
						local card
						if player:getCardCount() > 1 then
							local prompt = string.format("@kangkai-give", to:objectName())
							card = room:askForCard(player,"..",prompt,data,self:objectName())
							if not card then
								card = player:getCards("he"):at(math.random(0,player:getCardCount()))
							end
						else
							if player:getCardCount() == 1 then
								card = player:getCards("he"):first()
							end
						end
						to:obtainCard(card)
						if card:getTypeId() == sgs.Card_TypeEquip and room:getCardOwner(card:getEffectiveId()):objectName() == to:objectName() and (not to:isLocked(card)) then
							to:setTag("kangkaiSlash",sgs.QVariant(data))
							local bool = false
							bool = room:askForSkillInvoke(to,"kangkai_use","use")
							to:removeTag("kangkaiSlash")
							if bool then
								room:useCard(sgs.CardUseStruct(card,to,to))
							end
						end
					end
				end
			end
		end
	end,
}


--[[
	技能名：肉林（锁定技）
	相关武将：林·董卓
	当你使用【杀】指定一名女性角色为目标后，该角色需连续使用两张【闪】才能抵消；当你成为女性角色使用【杀】的目标后，你需连续使用两张【闪】才能抵消。
	引用：LuaRoulin
	状态：1227验证失败
]]--
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
LuaRoulin = sgs.CreateTriggerSkill{
	name = "LuaRoulin" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (player:objectName() == use.from:objectName()) then
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			if (use.from and use.from:isAlive() and use.from:hasSkill(self:objectName())) then
				for _, p in sgs.qlist(use.to) do
					if p:isFemale() then
						if jink_table[index] == 1 then
							jink_table[index] = 2
						end
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				use.from:setTag("Jink_" .. use.card:toString(), jink_data)
			elseif use.from:isFemale() then
				for _, p in sgs.qlist(use.to) do
					if p:hasSkill(self:objectName()) then
						if jink_table[index] == 1 then
							jink_table[index] = 2
						end
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				use.from:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:hasSkill(self:objectName()) or target:isFemale())
	end ,
}
--[[
	技能名：巧变
	相关武将：山·张郃
	描述：你可以弃置一张手牌，跳过你的一个阶段（回合开始和回合结束阶段除外），若以此法跳过摸牌阶段，你获得其他至多两名角色各一张手牌；若以此法跳过出牌阶段，你可以将一名角色装备区或判定区里的一张牌移动到另一名角色区域里的相应位置。
	引用：LuaQiaobian
	状态：1217验证失败（移动装备会闪退）
]]--
LuaQiaobianCard = sgs.CreateSkillCard{
	name = "LuaQiaobianCard" ,
	filter = function(self, targets, to_select)
		local phase = sgs.Self:getMark("LuaQiaobianPhase")
		if phase == sgs.Player_Draw then
			return (#targets < 2) and (to_select:objectName() ~= sgs.Self:objectName()) and (not to_select:isKongcheng())
		elseif phase = sgs.Player_Play then
			return (#targets == 0) and ((not to_select:getJudgingArea():isEmpty()) or (not to_select:getEquips():isEmpty()))
		end
		return false
	end ,
	feasible = function(self, targets)
		local phase = sgs.Self:getMark("LuaQiaobianPhase")
		if phase == sgs.Player_Draw then
			return (#targets <= 2) and (not targets:isEmpty())
		elseif phase == sgs.Player_Play then
			return #targets == 1
		end
		return false
	end ,
	on_use = function(self, room ,source, targets)
		local phase = source:getMark("LuaQiaobianPhase")
		if phase == sgs.Player_Draw then
			if #targets == 0 then return end
			local moves = sgs.CardsMoveList()
			local move1 = sgs.CardsMoveStruct()
			move1.card_ids:append(room:askForCardChosen(source, targets[1], "h", self:objectName()))
			move1.to = player
			move1.to_place = sgs.Player_PlaceHand
			moves:append(move1)
			if #targets == 2 then
				local move2 = sgs.CardsMoveStruct()
				move2.card_ids:append(room:askForCardChosen(source, targets[2], "h", self:objectName()))
				move2.to = player
				move2.to_place = sgs.Player_PlaceHand
				moves:append(move2)
			end
			room:moveCards(move, false)
		elseif phase == sgs.Player_Play then
			if #targets == 0 then return end
			local from = targets[1]
			if (not from:hasEquip()) and from:getJudgingArea():isEmpty() then return end
			local card_id = room:askForCardChosen(player, from, "ej", self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			local place = room:getCardPlace(card_id)
			local equip_index = -1
			if place == sgs.Player_PlaceEquip then
				local equip = card:getRealCard():toEquipCard()
				equip_index = equip:location()
			end
			local tos = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayer()) do
				if equip_index ~= -1 then
					if p:getEquip(equip_index) == nil then
						tos:append(p)
					end
				else
					if (not player:isProhibited(p, card)) and (not p:containsTrick(card:objectName())) then
						tos:append(p)
					end
				end
			end
			local _targetdata = sgs.QVariant()
			_targetdata:setValue(from)
			room:setTag("LuaQiaobianTarget", _targetdata)
			local to = room:askForPlayerChosen(player, tos, self:objectName(), "@qiaobian-to:::" .. card:objectName())
			if to then
				room:moveCardTo(card, from, to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), nil))
			end
			room:removeTag("LuaQiaobianTarget")
		end
	end
}
LuaQiaobianVS = sgs.CreateViewAsSkill{
	name = "LuaQiaobian" ,
	n = 0 ,
	view_as = function()
		return LuaQiaobianCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, target, pattern)
		return pattern == "@LuaQiaobian"
	end
}
LuaQiaobian = sgs.CreateTriggerSkill{
	name = "LuaQiaobian" ,
	events = {sgs.EventPhaseChanging} ,
	view_as_skill = LuaQiaobianVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		room:setPlayerMark(player, "LuaQiaobianPhase", change.to)
		local index = 0
		if change.to == sgs.Player_Judge then
			index = 1
		elseif change.to == sgs.Plyaer_Draw then
			index = 2
		elseif change.to == sgs.Player_Play then
			index = 3
		elseif change.to == sgs.Player_Discard then
			index = 4
		else
			return false
		end
		local discard_prompt = "#qiaobian-" .. index
		local use_prompt = "@qiaobian-" .. index
		if index > 0 then
			if room:askForDiscard(player, self:objectName(), 1, 1, true, false, discard_prompt) then
				if (not player:isSkipped(change.to)) and ((index == 2) or (index == 3)) then
					room:askForUseCard(player, "@LuaQiaobian", use_prompt, index)
				end
				player:skip(change.to)
			end
		end
		return false
	end
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName())) and target:canDiscard(target, "h")
	end
}


--[[
	技能名：屯田
	相关武将：山·邓艾
	描述：你的回合外，当你失去牌时，你可以进行一次判定，将非红桃结果的判定牌置于你的武将牌上，称为“田”；每有一张“田”，你计算的与其他角色的距离便-1。
	引用：LuaTuntian、LuaTuntianDistance
	状态：1217验证失败
]]--
LuaTuntian = sgs.CreateTriggerSkill{
	name = "LuaTuntian" ,
	events = {sgs.CardsMoveOnetime, sgs.FinishJudge} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from:objectName() == player:objectName())
					and (move.from_places:contains(sgs.Player_PlaceHand)
					or move.from_places:contains(sgs.Player_PlaceEquip)) then
				if player:askForSkillInvoke(self:objectName(), data) then
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|heart"
					judge.good = false
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if (judge.reason == self:objectName()) and judge:isGood() then
				player:addToPile("field", judge.card:getEffectiveId())
			end
		end
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName())) and (target:getPhase() == sgs.Player_NotActive)
	end
}
LuaTuntianDistance = sgs.CreateDistanceSkill{
	name = "#LuaTuntian-dist" ,
	correct_func = function(self, from, to)
		if from:hasSkill("LuaTuntian") then
			return -from:getPile("field"):length()
		else
			return 0
		end
	end
}
--[[
	技能名：制霸（主公技）
	相关武将：山·孙策
	描述：其他吴势力角色可以在他们各自的出牌阶段与你拼点（“魂姿”发动后，你可以拒绝此拼点），若该角色没赢，你可以获得双方拼点的牌。每阶段限一次。
	引用：LuaZhiba；LuaZhiba2（技能暗将）
	状态：0610待验证
]]--
LuaZhibaCard = sgs.CreateSkillCard{
	name = "LuaZhibaCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to:select:hasLordSkill("LuaZhiba") and (to_select:objectName() ~= sgs.Self:objectName())
				and (not to_select:isKongcheng()) and (not to_select:hasFlag("LuaZhibaInvoked"))
	end ,
	on_use = function(self, room, source, targets)
		local sunce = targets[1]
		room:setPlayrFlag(sunce, "LuaZhibaInvoked")
		if sunce:getMark("hunzi") > 0 then
			if room:askForChoice(sunce, "LuaZhiba", "accept+reject") == "reject" then return end
		end
		source:pindian(sunce, "LuaZhiba", nil)
		local sunces = sgs.SPlayerList()
		local players = room:getOtherPlayers(source)
		for _, p in sgs.qlist(players) do
			if p:hasLordSkill("LuaZhiba") and (not p:hasFlag("LuaZhibaInvoked")) then
				sunces:append(p)
			end
		end
		if sunces:isEmpty() then
			room:setPlayerFlag(source, "ForbidLuaZhiba")
		end
	end
}
LuaZhiba2 = sgs.CreateViewAsSkill{
	name = "LuaZhiba_pindian" ,
	n = 0 ,
	view_as = function()
		return LuaZhibaCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return (player:getKingdom() == "wu") and (not player:isKongcheng()) and (not player:hasFlag("ForbidLuaZhiba"))
	end
}
LuaZhiba = sgs.CreateTriggerSkill{
	name = "LuaZhiba$" ,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.Pindian, sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.GameStart) and (player:isLord()))
				or ((event == sgs.EventAcquireSkill) and data:toString() == "LuaZhiba") then
			local lords == sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasLordSkill(self:objectName()) then
					lords:append(p)
				end
			end
			if lords:isEmpty() then return false end
			local players = sgs.SPlayerList()
			if lords:length() > 1 then
				players = room:getAlivePlayers()
			else
				players = room:getOtherPlayers(lords:first())
			end
			for _, p in sgs.qlist(players) do
				if not p:hasSkill("LuaZhiba_pindian") then
					room:attachSkillToPlayer(p, "LuaZhiba_pindian")
				end
			end
		else (event == sgs.EventLoseSkill) and (data:toString() == "LuaZhiba") then
			local lords = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasLordSkill(self:objectName()) then
					lords:append(p)
				end
			end
			if lords:length() > 2 then return false end
			local player = sgs.SPlayerList()
			if lords:isEmpty() then
				players = room:getAlivePlayers()
			else
				players:append(lords:first())
			end
			for _, p in sgs.qlist(players) do
				if p:hasSkill("LuaZhiba_pindian") then
					room:detachSkillFromPlayer(p, "LuaZhiba_pindian", true)
				end
			end
		elseif event == sgs.Pindian then
			local pindain = data:toPindian()
			if (pindian.reason ~= "LuaZhiba") or (not pindian.to:hasLordSkill(self:objectName())) then return false end
			if not pindian.success then
				pindian.to:obtainCard(pindian.from_card)
				pindian.to:obtainCard(pindian.to_card)
			else

			end
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from ~= sgs.Player_Play then return false end
			if player:hasFlag("ForbidLuaZhiba") then
				room:setPlayerFlag(player, "-ForbidLuaZhiba")
			end
			local players = room:getOtherPlayers(player)
			for _, p in sgs.qlist(players) do
				if p:hasFlag("LuaZhibaInvoked") then
					room:setPlayerFlag(p, "-LuaZhibaInvoked")
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
	技能名：援护
	相关武将：SP·曹洪
	描述：结束阶段开始时，你可以将一张装备牌置于一名角色的装备区里，根据此牌的类别执行相应效果：
		武器牌——你弃置该角色距离为1的一名角色的区域里的一张牌；
		防具牌——该角色摸一张牌；
		坐骑牌——该角色回复1点体力。
	引用：LuaYuanhu
	状态：1217验证失败
]]--
LuaYuanhuCard = sgs.CreateSkillCard{
	name = "LuaYuanhuCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		if not (#targets == 0) then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end ,
	--虽然有onUse部分，但是只是实现room:broadcastSkillInvoke的，可以忽略
	on_effect = function(self, effect)
		local caohong = effect.from
		local room = caohong:getRoom()
		room:moveCardTo(self, caohong, effect,to, sgs.Player_PlaceEquip ,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, caohong:objectName(), "LuaYuanhu", nil))
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if card:isKindOf("Weapon") then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if (effect.to:distanceTo(p) == 1) and caohong:canDiscard(p, "hej") then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local to_dismantle = room:askForPlayerChosen(caohong, targets, "LuaYuanhu", "@yuanhu-discard:" .. effect.to:objectName())
				local card_id = room:askForCardChosen(caohong, to_dismantle, "hej", "LuaYuanhu", false, sgs.Card_MethodDiscard)
				room:throwCard(sgs.Sanguosha:getCard(card_id), to_dismantle, caohong)
			end
		elseif card:isKindOf("Armor") then
			effect.to:drawCards(1)
		elseif card:isKindOf("Horse") then
			local recover = sgs.RecoverStruct()
			recover.who = effect.from
			room:recover(effect.to, recover)
		end
	end
}
LuaYuanhuVS = sgs.CreateViewAsSkill{
	name = "LuaYuanhu" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if #selected >= 1 then return false end
		return to_select:isKindOf("EquipCard")
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local first = LuaYuanhuCard:clone()
		first:addSubcard(cards[1]:getId())
		first:setSkillName(self:objectName())
		return first
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, target, pattern)
		return pattern = "@@LuaYuanhu"
	end
}
LuaYuanhu = sgs.CreateTriggerSkill{
	name = "LuaYuanhu" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = LuaYuanhuVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getPhase() == sgs.Player_Finish) and (not player:isNude()) then
			room:askForUseCard(player, "@@LuaYuanhu", "@yuanhu-equip", -1, sgs.Card_MethodNone)
		end
		return false
	end
}

--[[
	技能名：醉乡（限定技）
	相关武将：☆SP·庞统
	描述：准备阶段开始时，你可以将牌堆顶的三张牌置于你的武将牌上。此后每个准备阶段开始时，你重复此流程，直到你的武将牌上出现同点数的“醉乡牌”，然后你获得所有“醉乡牌”（不能发动“漫卷”）。你不能使用或打出“醉乡牌”中存在的类别的牌，且这些类别的牌对你无效。
	引用：LuaZuixiang、LuaSleep1
	状态：0610待验证

	Fs注：此技能与“漫卷”有联系，而有联系部分使用的为本LUA手册的“漫卷”技能并非原版
]]--
LuaZuixiangType = {
	sgs.Card_TypeBasic = "BasicCard" ,
	sgs.Card_TypeTrick = "TrickCard" ,
	sgs.Card_TypeEquip = "EquipCard"
}
LuaDoZuixiang = function(player)
	local room = player:getRoom()
	local type_list = {
		sgs.Card_TypeBasic = 0,
		sgs.Card_TypeTrick = 0,
		sgs.Card_TypeEquip = 0
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
		if numbers:contains(card:getNumber()) then
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
	frequency = sgs.Skill_Limited ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local zuixiang = player:getPile("dream")
		if (event == sgs.EventPhaseStart) and (player:getMark("LuaZuixiangHasTrigger") == 0) then
			if player:getPhase() == sgs.Player_Start then
				if player:getMark("@sleep") > 0 then
					if not player:askForSkillInvoke(self:objectName()) then return false end
					room:removePlayerMark(player, "@sleep")
					doZuixiang(player)
				else
					doZuixiang(player)
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
LuaSleep1 = sgs.CreateTriggerSkill{
	name = "#@sleep-Lua-1" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		player:gainMark("@sleep", 1)
	end ,
}

--[[
	技能名：昭烈
	相关武将：☆SP·刘备
	描述：摸牌阶段摸牌时，你可以少摸一张牌，指定你攻击范围内的一名其他角色亮出牌堆顶上3张牌，将其中全部的非基本牌和【桃】置于弃牌堆，该角色进行二选一：你对其造成X点伤害，然后他获得这些基本牌；或他依次弃置X张牌，然后你获得这些基本牌。（X为其中非基本牌的数量）。
	引用：LuaZhaolie、LuaZhaolieAct
	状态：0610待验证
]]--
LuaZhaolie = sgs.CreateTriggerSkill{
	name = "LuaZhaolie" ,
	events = {sgs.DrawNCards} ,
	frequency = sgs.Skill_NotFrequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local targets = room:getOtherPlayers(player)
		local victims = sgs.SPlayerList()
		for _, p in sgs.qlist(targets) do
			if player:inMyAttackRange(p) then
				victims:append(p)
			end
		end
		if victims:isEmpty() then return end
		local victim = room:askForPlayerChosen(player, victims, "LuaZhaolie", "zhaolie-invoke", true, true)
		if victim then
			victim:setFlags("LuaZhaolieTarget")
			player:setFlags("LuaZhaolie")
			data:setValue(data:toInt() - 1)
			return
		end
		return
	end
}
LuaZhaolieAct = sgs.CreateTriggerSkill{
	name = "#LuaZhaolie" ,
	events = {sgs.AfterDrawCards} ,
	on_trigger = function(self, event, player, data)
		if not player:hasFlag("LuaZhaolie") then return false end
		player:setFlags("-LuaZhaolie")
		local victim
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("LuaZhaolieTarget") then
				p:setFlags("-LuaZhaolieTarget")
				victim = p
				break
			end
		end
		if not victim then return false end
		local cards = sgs.CardList()
		local no_basic = 0
		local cardIds = sgs.IntList()
		for i = 0, 2, 1 do
			local id = room:drawCard()
			cardIds:append(id)
			local move = sgs.CardsMoveStruct()
			move.card_ids:append(id)
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), nil, "LuaZhaolie", nil)
			room:moveCardsAtomic(move, true)
		end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for i = 0, 2, 1 do
			local card_id = cardIds:at(i)
			local card = sgs.Sanguosha:getCard(card_id)
			if (not card:isKindOf("BasicCard")) or card:isKindOf("Peach") then
				if not card:isKindOf("BasicCard") then
					no_basic = no_basic + 1
				end
				dummy:addSubcard(card_id)
			else
				cards:append(card)
			end
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, "LuaZhaolie", nil)
		if dummy:subcardsLength() > 0 then
			room:throwCard(dummy, reason, nil)
		end
		dummy:clearSubcards()
		if (no_basic == 0) and cards:isEmpty() then return false end
		for _, c in sgs.qlist(cards) do
			dummy:addSubcard(c)
		end
		if no_basic == 0 then
			if room:askForSkillInvoke(victim, "zhaolie_obtain", sgs.QVariant("obtain:" .. + player:objectName())) then
				player:obtainCard(dummy)
			else
				victim:obtainCard(dummy)
			end
		else
			if room:askForDiscard(victim, "LuaZhaolie", no_basic, no_basic, true, true, "@zhaolie-discard:" .. player:objectName()) then
				if dummy:subcardsLength() > 0 then
					if player:isAlive() then
						player:obtainCard(dummy)
					else
						room:throwCard(dummy, reason, nil)
					end
				end
			else
				if no_basic > 0 then
					room:damage(sgs.DamageStruct("LuaZhaolie", player, victim, no_basic))
				end
				if dummy:subcardsLength() > 0 then
					if victim:isAlive() then
						victim:obtainCard(dummy)
					else
						room:throwCard(dummy, reason, nil)
					end
				end
			end
		end
		return false
	end
}

--[[
	技能名：誓仇（主公技、限定技）
	相关武将：☆SP·刘备
	描述：准备阶段开始时，你可以交给一名其他蜀势力角色两张牌。每当你受到伤害时，你将此伤害转移给该角色，然后该角色摸X张牌，直到其第一次进入濒死状态时。（X为伤害点数）
	引用：LuaShichou、LuaShichouDraw
	状态：0901待验证
]]--
LuaShichouCard = sgs.CreateSkillCard{
	name = "LuaShichouCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:getKingdom() == "shu") and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local player = effect.from
		local victim = effect.to
		room:removePlayerMark(player, "@hate")
		room:setPlayerMark("LuaxHate", 1)
		victim:gainMark("@hate_to")
		room:setPlayerMark(victim, "LuaHateTo_" .. player:objectName(), 1)
		--[[local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName())
		reason.m_playerId = victim:objectName()
		room:obtainCard(victim, self, reason, false)]] --LUA版本obtainCard没有原因
		room:obtainCard(victim, self, false)
	end
}
LuaShichouVS = sgs.CreateViewAsSkill{
	name = "LuaShichou" ,
	n = 2 ,
	view_filter = function(self, selected, to_select)
		return #selected < 2
	end ,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local card = LuaShichouCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaShichou"
	end
}
LuaShichou = sgs.CreateTriggerSkill{
	name = "LuaShichou$" ,
	frequency = sgs.Skill_Limited ,
	events = {sgs.GameStart, sgs.EventPhaseStart, sgs.DamageInflicted, sgs.Dying} ,
	view_as_skill = LuaShichouVS ,
	limit_mark = "@hate" ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.GameStart) and player:hasLordSkill("LuaShichou") then
			room:addPlayerMark(player, "@hate")
		elseif (event == sgs.EventPhaseStart) and (player:getMark("LuaxHate") == 0) and player:hasLordSkill("LuaShichou")
				and (player:getPhase() == sgs.Player_Start) and (player:getCards("he"):length() > 1) then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getKingdom() == "shu" then
					room:askForUseCard(player, "@@LuaShichou", "@shichou-give", -1, sgs.Card_MethodNone)
					break
				end
			end
		elseif (event == sgs.DamageInflicted) and player:hasLordSkill(self:objectName()) and (player:getMark("LuaShichouTarget") == 0) then
			local target
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if (p:getMark("LuaHateTo_" .. player:objectName()) > 0) and (p:getMark("@hate_to") > 0) then
					target = p
					break
				end
			end
			if (not target) or target:isDead() then return false end
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				player:removeQinggangTag(damage.card)
			end
			local newdamage = damage
			newdamage.to = target
			newdamage.transfer = true
			target:addMark("LuaShichouTarget")
			room:damage(newdamage) -- 未处理胆守
			return true
		elseif event == sgs.Dying then
			local dying = data:toDying()
			if dying.who:objectName() ~= player:objectName() then return false end
			if player:getMark("@hate_to") > 0 then
				player:loseAllMarks("@hate_to")
			end
		end
	end ,
	can_trigger = function(self, player)
		return player
	end
}
LuaShichouDraw = sgs.CreateTriggerSkill{
	name = "#LuaShichou" ,
	events = {sgs.DamageComplete} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if player:isAlive() and (player:getMark("LuaShichouTarget") > 0) and damage.transfer then
			player:drawCards(damage.damage)
			player:removeMark("LuaShichouTarget")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}

--[[
	技能名：突骑（锁定技）
	相关武将：贴纸·公孙瓒
	描述：准备阶段开始时，若你的武将牌上有“扈”，你将所有“扈”置入弃牌堆：若X小于或等于2，你摸一张牌。本回合你与其他角色的距离-X。（X为准备阶段开始时置于弃牌堆的“扈”的数量）
	引用：LuaTuqi、LuaTuqiDistance
	状态：1217验证失败
]]--
LuaTuqi = sgs.CreateTriggerSkill{
	name = "LuaTuqi" ,
	evnets = {sgs.EventPhaseStart, sgs.EventPhaseChanging} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if (player:getPhase() == sgs.Player_Start) and (player:getPile("retinue"):length() > 0) then
				local n = player:getPile("retinue"):length()
				room:setPlayerMark(player, "LuaTuqi_dist", n)
				player:clearOnePrivatePile("retinue")

				if n <= 2 then player:drawCards(1) end
			end
		else
			local change = sgs.EventPhaseChanging then
			if change.to ~= sgs.Player_NotActive then return false end
			room:setPlayerMark(player, "LuaTuqi_dist", 0)
		end
		return false
	end
}
LuaTuqiDistance = sgs.CreateDistanceSkill{
	name = "#LuaTuqi-dist" ,
	correct_func = function(self, from, to)
		if from:hasSkill("LuaTuqi") then
			return -from:getMark("LuaTuqi_dist")
		else
			return 0
		end
	end
}

--[[
	技能名：天命
	相关武将：铜雀台·汉献帝、SP·刘协
	描述：当你成为【杀】的目标时，你可以弃置两张牌（不足则全弃，无牌则不弃），然后摸两张牌；若此时全场体力值最多的角色仅有一名（且不是你），该角色也可如此做
	引用：LuaTianming
	状态：1217验证失败
]]--
LuaTianming = sgs.CreateTriggerSkill{
	name = "LuaTianming" ,
	events = {sgs.TargetConfirming} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.card and use.card:isKindOf("Slash") then
			if room:askForSkillInvoke(player, self:objectName()) then
				room:askForDiscard(player, self:objectName(), 2, 2, false, true)
				player:drawCards(2)
				local _max = -1000
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getHp() > _max then
						m_max = p:getHp()
					end
				end
				if (player:getHp() == _max) then return false end
				local maxs = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getHp() == _max then
						maxs:append(p)
					end
					if maxs:length() > 1 then
						return false
					end
				end
				local mosthp = maxs:first()
				if room:askForSkillInvoke(mosthp, self:objectName()) then
					room:askForDiscard(mosthp, self:objectName(), 2, 2, false, true)
					mosthp:drawCards(2)
				end
			end
		end
		return false
	end
}


--[[
	技能名：双刃
	相关武将：国战·纪灵
	描述：出牌阶段开始时，你可以与一名其他角色拼点：若你赢，视为你一名其他角色使用一张无距离限制的普通【杀】（此【杀】不计入出牌阶段使用次数的限制）；若你没赢，你结束出牌阶段。
	引用：LuaShuangren、LuaShuangrenNDL
	状态：1217验证失败（闪退）
]]--
LuaShuangrenCard = sgs.CreateSkillCard{
	name = "LuaShuangrenCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local success = effect.from:pindian(effect.to, "LuaShuangren", nil)
		if success then
			local targets = sgs.SPlayerList()
			for _, target in sgs.qlist(room:getAlivePlayers()) do
				if effect.from:canSlash(target, nil, false) then
					targets:append(target)
				end
			end
			if targets:isEmpty() then return end
			local target = room:askForPlayerChosen(effect.from, targets, "LuaShuangren", "@dummy-slash")
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("_LuaShuangren")
			room:useCard(sgs.CardUseStruct(slash, effect.from, target), false)
		else
			room:setPlayerFlag(effect.from, "LuaShuangrenSkipPlay")
		end
	end
}
LuaShuangrenVS = sgs.CreateViewAsSkill(){
	name = "LuaShuangren" ,
	n = 0 ,
	view_as = function()
		return LuaShuangrenCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaShuangren"
	end
}
LuaShuangren = sgs.CreateTriggerSkill{
	name = "LuaShuangren" ,
	view_as_skill = LuaShuangrenVS ,
	on_trigger = function(self, event, player, data)
		if (player:getPhase() == sgs.Player_Play) and (not player:isKongcheng()) then
			local room = player:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _, _player in sgs.qlist(other_players) do
				if not _player:isKongcheng() then
					return true
					break
				end
			end
			if can_invoke then
				room:askForUseCard(player, "@@LuaShuangren", "@shuangren-card")
			end
			if player:hasFlag("LuaShuangrenSkipPlay") then
				return true
			end
		end
		return false
	end
}
LuaShuangrenNDL = sgs.CreateTargetModSkill{
	name = "#LuaShuangren-slash-ndl" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("LuaShuangren") and (card:getSkillName() == "LuaShuangren") then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：陷嗣
	相关武将：一将成名2013·刘封
	描述：准备阶段开始时，你可以将一至两名角色的各一张牌置于你的武将牌上，称为“逆”。其他角色可以将两张“逆”置入弃牌堆，视为对你使用一张【杀】。
	引用：LuaXiansi、LuaXiansiAttach、LuaXiansiSlash（技能暗将
	状态：暂时搁置
]]--
LuaXiansiCard = sgs.CreateSkillCard{
	name = "LuaXiansi" ,
	filter = function(self, targets, to_select)
		return (#targets < 2) and (not to_select:isNude())
	end ,
	on_effect = function(self, effect)
		if effect.to:isNude() then return end
		local id = effect.from:getRoom():askForPlayerChosen(effect.from, effect.to, "he", "LuaXiansi")
		effect.from:addToPile("counter", id)
	end ,
}
LuaXiansiVS = sgs.CreateViewAsSkill{
	name = "LuaXiansi" ,
	n = 0 ,
	view_as = function()
		return LuaXiansiCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern = "@@LuaXiansi"
	end
}
LuaXiansi = sgs.CreateTriggerSkill{
	name = "LuaXiansi" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = LuaXiansiVS ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			player:getRoom():askForUseCard(player, "@@LuaXiansi", "@xiansi-card")
		end
		return false
	end
}
LuaXiansiAttach = sgs.CreateTriggerSkill{
	name = "#LuaXiansi-attach" ,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.GameStart) and (player and player:isAlive() and player:hasSkill(self:objectName())))
				or ((event == sgs.EventAcquireSkill) and (data:toString() == "LuaXiansi")) then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:hasSkill("LuaXiansi_slash") then
					room:attachSkillToPlayer("LuaXiansi_slash")
				end
			end
		elseif (event == sgs.EventLoseSkill) and (data:toString() == "LuaXiansi") then
			player:clearOnePrivatePile("counter")
			for _ , p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("LuaXiansi_slash") then
					room:detachSkillFromPlayer(p, "LuaXiansi_slash", true)
				end
			end
		end
		return false
	end
	can_trigger = function(self, target)
		return target
	end
}
LuaXiansiSlashCard = sgs.CreateSkillCard{
	name = "LuaXiansiSlashCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		local liufeng = room:findPlayerBySkillName("LuaXiansi")
		if (not liufeng) or (liufeng:getPile("counter"):length() < 2) then return end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if liufeng:getPile("counter"):length() == 2 then
			dummy:addSubcard(liufeng:getPile("counter"):first())
			dummy:addSubcard(liufeng:getPile("counter"):last())
		else
			local ids = liufeng:getPile("counter")
			for i = 0, 1, 1 do
				room:fillAG(ids, source)
				local id = room:askForAG(source, ids, false, "LuaXiansi")
				dummy:addSubcard(id)
				ids:removeOne(id)
				room:clearAG(source)
			end
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, "LuaXiansi", nil)
		room:throwCard(dummy, reason, nil)
		if source:canSlash(liufeng, nil, false) then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:setSkillName("_LuaXiansi")
			room:useCard(sgs.CardUseStruct(slash, source, liufeng))
		end
	end
}
canSlashLiufeng = function(self, player)
	local liufeng = nil
	for _, p in sgs.qlist(player:getSiblings()) do
		if p:isAlive() and p:hasSkill("LuaXiansi") and (p:getPile("counter"):length() > 1) then
			liufeng = p
			break
		end
	end
	if not liufeng then return false end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	return slash:targetFilter(sgs.PlayerList(), liufeng, player)
end
LuaXiansiSlash = sgs.CreateViewAsSkill{
	name = "LuaXiansi_slash" ,
	n = 0 ,
	view_as = function()
		return LuaXiansiSlashCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and canSlashLiufeng(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash") and (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
				and canSlashLiufeng(player)
	end ,
}
--[[
	技能名：惴恐
	相关武将：一将成名2013·伏皇后
	描述： 一名其他角色的回合开始时，若你已受伤，你可以与其拼点：若你赢，该角色跳过出牌阶段；若你没赢，该角色与你距离为1，直到回合结束。
	引用：LuaZhuikong、LuaZhuikongClear
	状态：1217验证失败（闪退）
]]--
LuaZhuikong = sgs.CreateTriggerSkill{
	name = "LuaZhuikong" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if (player:getPhase() ~= sgs.Player_RoundStart) or player:isKongcheng() then return false end
		local skip = false
		local room = player:getRoom()
		for _, fuhuanghou in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if (player:objectName() ~= fuhuanghou:objectName()) and fuhuanghou:isWounded and (not fuhuanghou:isKongcheng()) then
				if room:askForSkillInvoke(fuhuanghou, self:objectName()) then
					if fuhuanghou:pindian(player, self:objectName(), nil) then
						if not skip then
							player:skip(sgs.Player_Play)
							skip = true
						end
					else
						room:setFixedDistance(player, fuhuanghou, 1)
						local zhuikonglist = player:getTag(self:objectName()):toString():split("+")
						table.insert(zhuikonglist, fuhuanghou:objectName())
						player:setTag(self:objectName(), table.concat(zhuikonglist, "+"))
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
LuaZhuikongClear = sgs.CreateTriggerSkill{
	name = "#LuaZhuikongClear" ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		local zhuikonglist = player:getTag("LuaZhuikong"):toString():split("+")
		if #zhuikonglist == 0 then return false end
		for _, p in ipairs(zhuikonglist) do
			local fuhuanghou = nil
			for _, n in sgs.qlist(room:getAlivePlayers()) do
				if p == n:objectName() then
					fuhuanghou = n
					break
				end
			end
			room:setFixedDistance(player, fuhuanghou, -1)
		end
		player:removeTag("LuaZhuikong")
		return false
	end
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：眩惑
	相关武将：怀旧·法正
	描述：出牌阶段，你可以将一张红桃手牌交给一名其他角色，然后你获得该角色的一张牌并交给除该角色外的其他角色。每阶段限一次。
	引用：LuaNosXuanhuo
	状态：1217验证失败
]]--
LuaNosXuanhuoCard = sgs.CreateSkillCard{
	name = "LuaNosXuanhuoCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		effect.to:obtainCard(self)
		local room = effect.from:getRoom()
		local card_id = room:askForCardChosen(effect.from, effect.to, "he", "LuaNosXuanhuo")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName())
		room:obtainCard(effect.from, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
		local targets = room:getOtherPlayers(effect.to)
		local target = room:askForPlayerChosen(effect.from, targets, "LuaNosXuanhuo", "@nosxuanhuo-give:" .. effect.to:objectName())
		if target:objectName() ~= effect.from:objectName() then
			local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, effect.from:objectName())
			reason2.m_playerId = target:objectName()
			room:obtainCard(target, sgs.Sanguosha:getCard(card_id), reason2, false)
		end
	end
}
LuaNosXuanhuo = sgs.CreateViewAsSkill{
	name = "LuaNosXuanhuo" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return (#selected == 0) and (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Heart)
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local xuanhuoCard = LuaNosXuanhuoCard:clone()
		xuanhuoCard:addSubcard(cards[1])
		return xuanhuoCard
	end ,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and (not player:hasUsed("#LuaNosXuanhuoCard"))
	end
}

--[[
	技能名：旋风
	相关武将：怀旧·凌统
	描述：当你失去一次装备区里的牌时，你可以选择一项：1. 视为对一名其他角色使用一张【杀】；你以此法使用【杀】时无距离限制且不计入出牌阶段内的使用次数限制。2. 对距离为1的一名角色造成1点伤害。
	引用：LuaNosXuanfeng、LuaNosXuanfengNDL
	状态：1217验证失败（choicelist明显写错了以及各种不和谐）
]]--
LuaNosXuanfeng = sgs.CreateTriggerSkill{
	name = "LuaNosXuanfeng" ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and (move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceEquip) then
			local choicelist = "nothing"
			local targets1 = sgs.SPlayerList()
			for _, target in sgs.qlist(room:getAlivePlayers()) do
				if player:canSlash(target, nil, false) then
					targets1:append(target)
				end
				local slashx = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if (not targets1:isEmpty()) and (not player:isCardLimited(slashx, sgs.Card_MethodUse)) then
					choicelist = choicelist .. "+slash"
				end
				local targets2 = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:distanceTo(p) <= 1 then
						targets2:append(p)
					end
				end
				if not targets2:isEmpty() then
					choicelist = choicelist .. "+damage"
				end
				local choice = room:askForChoice(player, self:objectName(), choicelist)
				if choice == "slash" then
					local target = room:askForPlayerChosen(player, targets1, "nosxuanfeng_slash", "dummy-slash")
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName(self:objectName())
					room:useCard(sgs.CardUseStruct(slash, player, target), false)
				elseif choice == "damage" then
					local target = room:askForPlayerChosen(player, targets2, "nosxuanfeng_damage", "@nosxuanfeng-damage")
					room:damage(sgs.DamageStruct("LuaNosXuanfeng", player, target))
				end
			end
		end
		return false
	end
}
LuaNosXuanfengNDL = sgs.CreateTargetModSkill{
	name = "#LuaNosXuanfeng-slash-ndl" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("LuaNosXuanfeng") and (card:getSkillName() == "LuaNosXuanfeng") then
			return 1000
		else
			return 0
		end
	end
}

--[[
	技能名：义舍
	相关武将：倚天·张公祺
	描述：出牌阶段，你可将任意数量手牌正面朝上移出游戏称为“米”（至多存在五张）或收回；其他角色在其出牌阶段可选择一张“米”询问你，若你同意，该角色获得这张牌，每阶段限两次
	引用：LuaYishe；LuaYisheAsk（技能暗将）
	状态：暂时搁置
]]--
LuaYisheCard = sgs.CreateSkillCard{
	name = "LuaYisheCard" ,
	target_fixed = true ,
	will_throw = false ,
	on_use = function(self, room, source, targets)
		local rice = source:getPile("rice")
		if self:getSubcards():isEmpty() then
			for _, card_id in sgs.qlist(rice) do
				room:obtainCard(source, card_id)
			end
		else
			for _, card_id in sgs.qlist(self:getSubcards()) do
				source:addToPile("rice", card_id)
			end
		end
	end
}
LuaYisheVS = sgs.CreateViewAsSkill{
	name = "LuaYishe" ,
	n = 5 ,
	view_filter = function(self, selected, to_select)
		local n = sgs.Self:getPile("rice"):length()
		if (#selected + n) >= 5 then return false end
		return not to_select:isEquipped()
	end ,
	card = LuaYisheCard:clone() ,
	view_as = function(self, cards)
		if sgs.Self:getPiel("rice"):isEmpty() and (#cards == 0) return nil end
		card:clearSubcards()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end ,
	enabled_at_play = function(self, player)
		if (player:getPile("rice"):isEmpty()) then
			return not player:isKongcheng()
		else
			return true
		end
	end ,
}
LuaYisheAskCard = sgs.CreateSkillCard(){
	name = "LuaYisheAskCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		local zhanglu = room:findPlayerBySkillName("LuaYishe")
		if not zhanglu then return end
		local yishe = zhanglu:getPile("rice")
		if yishe:isEmpty() then return end
		local card_id
		if yishe:length() == 1 then
			card_id = yishe:first()
		else
			room:fillAG(yishe, source)
			card_id = room:askForAG(source, yishe, false, "LuaYisheAsk")
			room:clearAG(source)
		end
		room:showCard(zhanglu, card_id)
		if room:askForChoice(zhanglu, "LuaYisheAsk", "allow+disallow") == "allow" then
			source:obtainCard(sgs.Sanguosha:getCard(card_id))
			room:showCard(source, card_id)
		end
	end ,
}
LuaYisheAsk = sgs.CreateViewAsSkill{
	name = "LuaYisheAsk" ,
	n = 0 ,
	view_as = function()
		return LuaYisheAskCard:clone()
	end ,
	enabled_at_play = function(self, player)
		if player:hasSkill("LuaYishe") then return false end
		if player:usedTimes("#LuaYisheAskCard") >= 2 then return false end
		local zhanglu = nil
		for _ p in sgs.qlist(player:getSiblings()) do
			if p:isAlive() and p:hasSkill("LuaYishe") then
				zhanglu = p
				break
			end
		end
		return zhanglu and (not zhanglu:getPile("rice"):isEmpty())
	end ,
}
LuaYishe = sgs.CreateGameStartSkill{
	name = "LuaYishe" ,
	view_as_skill = LuaYisheVS ,
	on_gamestart = function(self, player)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			room:attachSkillToPlayer(p, "LuaYisheAsk")
		end
	end ,
}

--[[
	技能名：贪婪
	相关武将：智·许攸
	描述：每当你受到一次伤害，可与伤害来源进行拼点：若你赢，你获得两张拼点牌
	引用：LuaTanlan
	状态：1217验证失败（isSuccess无接口）
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
			if (pindian.reason == self:objectName()) and pindian:isSuccess() then
				player:obtainCard(pindian.to_card)
				player:obtainCard(pindian.from_card)
			end
		end
		return false
	end ,
}
--[[
	技能名：异才
	相关武将：智·姜维
	描述：每当你使用一张非延时类锦囊时(在它结算之前)，可立即对攻击范围内的角色使用一张【杀】
	引用：LuaYicai
	状态：1217验证失败
]]--
LuaYicai = sgs.CreateTriggerSkill{
	name = "LuaYicai" ,
	events == {sgs.CardUsed, sgs.CardResponded} ,
	on_trigger = function(self, event, player, data)
		local card = nil
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		if card and card:isNDTrick() then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:askForUseCard(player, "slash", "@askforslash")
			end
		end
	end ,
}

--[[
	技能名：狱刎（锁定技）
	相关武将：智·田丰
	描述：当你死亡时，凶手视为自己
	引用：LuaXYuwen
	状态：1217验证失败
]]--
LuaYuwen = sgs.CreateTriggerSkill{
	name = "LuaYuwen" ,
	events = {sgs.GameOverJudge} ,
	frequency = sgs.Skill_Compulsory ,
	priority = 4,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.damage then
			if death.damage.from:objectName() == player:objectName() then
				return false
			end
		else
			death.damage = sgs.DamageStruct()
			death.damage.to = player
		end
		death.damage.from = player
		data:setValue(death)
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
