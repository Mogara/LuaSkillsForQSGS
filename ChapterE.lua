--[[
	代码速查手册（E区）
	技能索引：
		恩怨、恩怨
]]--
--[[
	技能名：恩怨
	相关武将：一将成名·法正
	描述：你每次获得一名其他角色两张或更多的牌时，可以令其摸一张牌；每当你受到1点伤害后，你可以令伤害来源选择一项：交给你一张手牌，或失去1点体力。
	引用：LuaEnyuan, findPlayerByName
	状态：0504验证通过
]]--

function findPlayerByName(room, name)
	for _, p in sgs.qlist(room:getAllPlayers()) do
		if p:objectName() == name then
			return p
		end
	end
end

LuaEnyuan = sgs.CreateTriggerSkill{
	name = "LuaEnyuan" ,
	events = {sgs.CardsMoveOneTime, sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to:objectName() == player:objectName() and move.from and move.from:isAlive()
					and move.from:objectName() ~= move.to:objectName()
					and move.card_ids:length() >= 2
					and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE
					and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip) then
				local _movefrom = findPlayerByName(room, move.from:objectName())
				_movefrom:setFlags("LuaEnyuanDrawTarget")
				local invoke = room:askForSkillInvoke(player, self:objectName(), data)
				_movefrom:setFlags("-LuaEnyuanDrawTarget")
				if invoke then
					room:drawCards(_movefrom, 1, self:objectName())
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			local source = damage.from
			if (not source or source:objectName() == player:objectName()) then return false end
			local x = damage.damage
			for i = 0, x - 1, 1 do
				if source:isAlive() and player:isAlive() and room:askForSkillInvoke(player, self:objectName(), data) then
					local card
					if not source:isKongcheng() then
						card = room:askForExchange(source, self:objectName(), 1, 1, false, "LuaEnyuanGive::"..player:objectName(), true)
					end
					if card then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),player:objectName(), self:objectName(), nil)
						reason.m_playerId = player:objectName()
						room:moveCardTo(card, source, player, sgs.Player_PlaceHand, reason)
					else
						room:loseHp(source)
					end
				else
					break
				end
			end
		end
		return false
	end
}

--[[
	技能名：恩怨（锁定技）
	相关武将：怀旧·法正
	描述：其他角色每令你回复1点体力，该角色摸一张牌；其他角色每对你造成一次伤害后，需交给你一张红桃手牌，否则该角色失去1点体力。
	引用：LuaNosEnyuan
	状态：0405验证通过
]]--
LuaNosEnyuan = sgs.CreateTriggerSkill{
	name = "LuaNosEnyuan" ,
	events = {sgs.HpRecover, sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpRecover then
			local recover = data:toRecover()
			if recover.who and (recover.who:objectName() ~= player:objectName()) then
				recover.who:drawCards(recover.recover, self:objectName())
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			local source = damage.from
			if source and (source:objectName() ~= player:objectName()) then
				local card = room:askForCard(source, ".|heart|.|hand", "@nosenyuan-heart", data, sgs.Card_MethodNone)
				if card then
					player:obtainCard(card)
				else
					room:loseHp(source)
				end
			end
		end
		return false
	end
}
