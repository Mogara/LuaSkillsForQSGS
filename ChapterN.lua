--[[
	代码速查手册（N区）
	技能索引：
		纳蛮、逆乱、鸟翔、涅槃
]]--
--[[
	技能名：纳蛮
	相关武将：SP·马良
	描述：每当其他角色打出的【杀】因打出而置入弃牌堆时，你可以获得之。 
	引用：LuaNaman
	状态：0405验证通过
]]--

LuaNaman = sgs.CreateTriggerSkill{
	name = "LuaNaman",
	events = {sgs.BeforeCardsMove}, 
	on_trigger = function(self, event, player, data)
		local room =  player:getRoom()
		local move = data:toMoveOneTime()
		if (move.to_place ~= sgs.Player_DiscardPile) then return end
		local to_obtain = nil
		if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ==    sgs.CardMoveReason_S_REASON_RESPONSE then 
			if move.from and player:objectName() == move.from:objectName() then return end 
			to_obtain = move.reason.m_extraData:toCard()
			if not to_obtain or not to_obtain:isKindOf("Slash") then return end
		else
			return 
		end
		if to_obtain and room:askForSkillInvoke(player, self:objectName(), data) then 
			room:obtainCard(player, to_obtain)
			move:removeCardIds(move.card_ids)
			data:setValue(move)
		end
	return
	end,
}
--[[
	技能名：逆乱
	相关武将：1v1·韩遂
	描述：对手的结束阶段开始时，若其当前的体力值比你大，或其于此回合内对你使用过【杀】，你可以将一张黑色牌当【杀】对其使用。 
	引用：LuaNiluan、LuaNiluanRecord
	状态：1217验证通过
]]--
LuaNiluanVS = sgs.CreateOneCardViewAsSkill {
	name = "LuaNiluan",
	filter_pattern = ".|black",
	response_pattern = "@@niluan",
	view_as = function(slef, card)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		slash:addSubcard(card)
		slash:setSkillName("LuaNiluan")
		return slash
	end,
}
LuaNiluan = sgs.CreateTriggerSkill{
	name = "LuaNiluan",
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaNiluanVS,
	can_trigger = function(self, player)
		return player:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			local owner = room:findPlayerBySkillName(self:objectName())
			if owner and owner:objectName()~=player:objectName() and owner:canSlash(player, false) then
				if player:getHp() > owner:getHp() or not owner:hasFlag("LuaNiluanSlashTarget") then
					if owner:isKongcheng() then
						local has_black = false
						for i=0, 3, 1 do
							local equip = owner:getEquip(i)
							if equip and equip:isBlack() then
								has_black = true
								break
							end
						end
						if not has_black then return false end
					end
					room:setPlayerFlag(owner, "slashTargetFix")
					room:setPlayerFlag(owner, "slashNoDistanceLimit")
					room:setPlayerFlag(owner, "slashTargetFixToOne")
					room:setPlayerFlag(player, "SlashAssignee")
					local slash = room:askForUseCard(owner, "@@niluan", "@niluan-slash:" .. player:objectName())
					if slash == nil then
						room:setPlayerFlag(owner, "-slashTargetFix")
						room:setPlayerFlag(owner, "-slashNoDistanceLimit")
						room:setPlayerFlag(owner, "-slashTargetFixToOne")
						room:setPlayerFlag(player, "-SlashAssignee")
					end
				end
			end
		end
		return false
	end,
}
LuaNiluanRecord = sgs.CreateTriggerSkill{
	name = "#LuaNiluan-record",
	events = {sgs.TargetConfirmed, sgs.EventPhaseStart},
	priority = 4,
	can_trigger = function(self, player)
		return player ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.card:isKindOf("Slash") then
				for _,to in sgs.qlist(use.to) do
					if not to:hasFlag("LuaNiluanSlashTarget") then
						to:setFlags("LuaNiluanSlashTarget")
					end
				end
			end
		else 
			if player:getPhase() == sgs.Player_RoundStart then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					p:setFlags("-LuaNiluanSlashTarget")
				end
			end
		end
		return false
	end,
}
--[[
	技能名：鸟翔
	相关武将：阵·蒋钦
	描述：每当一名角色被指定为【杀】的目标后，若你与此【杀】使用者均与该角色相邻，你可以令该角色须使用两张【闪】抵消此【杀】。 
	引用：LuaNiaoxiang
	状态：1217验证通过
]]--
function Table2IntList(thetable)
	local theqlist = sgs.IntList()
	for _, p in ipairs(thetable) do
		theqlist:append(p)
	end
	return theqlist
end
LuaNiaoxiang = sgs.CreateTriggerSkill{
	name = "LuaNiaoxiang",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.from:isAlive() then
			local jink_list = use.from:getTag("Jink_"..use.card:toString()):toIntList()
			for i=0, use.to:length()-1, 1 do
				local to = use.to:at(i)
				if to:isAlive() and to:isAdjacentTo(player) and to:isAdjacentTo(use.from) then
					local new_data = sgs.QVariant()
					new_data:setValue(to)			--for AI
					if room:askForSkillInvoke(player, self:objectName(), new_data) then
						local jink_table = sgs.QList2Table(jink_list)
						if jink_list:at(i) == 1 then
							jink_table[i+1] = 2
						end
						jink_list = Table2IntList(jink_table)
						local list_data = sgs.QVariant()
						list_data:setValue(jink_list)
						use.from:setTag("Jink_" .. use.card:toString(), list_data)
					end
				end
			end
		end
		return false
	end,
}
--[[
	技能名：涅槃（限定技）
	相关武将：火·庞统
	描述：当你处于濒死状态时，你可以：弃置你区域里所有的牌，然后将你的武将牌翻至正面朝上并重置之，再摸三张牌且体力回复至3点。
	引用：LuaNiepan、LuaNiepanStart
	状态：1217验证通过
]]--
LuaNiepan = sgs.CreateTriggerSkill{
	name = "LuaNiepan",
	frequency = sgs.Skill_Limited,
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:objectName() == player:objectName() then
			if player:askForSkillInvoke(self:objectName(), data) then
				player:loseMark("@nirvana")
				player:throwAllCards()
				local maxhp = player:getMaxHp()
				local hp = math.min(3, maxhp)
				room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
				player:drawCards(3)
				if player:isChained() then
					local damage = dying_data.damage
					if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
				end
				if not player:faceUp() then
					player:turnOver()
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return target:getMark("@nirvana") > 0
				end
			end
		end
		return false
	end
}
LuaNiepanStart = sgs.CreateTriggerSkill{
	name = "#LuaNiepanStart",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		player:gainMark("@nirvana")
	end
}
