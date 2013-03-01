--[[
	代码速查手册（A区）
	技能索引：
		安娴、安恤
]]--
--[[
	技能名：安娴
	相关武将：☆SP·大乔
	描述：每当你使用【杀】对目标角色造成伤害时，你可以防止此次伤害，令其弃置一张手牌，然后你摸一张牌；当你成为【杀】的目标时，你可以弃置一张手牌使之无效，然后该【杀】的使用者摸一张牌。
	状态：验证通过
]]--
LuaAnxian = sgs.CreateTriggerSkill{
	name = "LuaAnxian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused, sgs.TargetConfirming, sgs.SlashEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local card = damage.card
			if card and card:isKindOf("Slash") then
				if not damage.chain and not damage.transfer then
					local dest = damage.to
					if room:askForSkillInvoke(player, self:objectName(), data) then
						if not dest:isKongcheng() then
							room:askForDiscard(dest, self:objectName(), 1, 1)
						else
							player:drawCards(1)
						end
						return true
					end
				end
			end
		elseif event == sgs.TargetConfirming then
			local use = data:toCardUse()
			local card = use.card
			if card and card:isKindOf("Slash") then
				if room:askForCard(player, ".", "@anxian-discard", sgs.QVariant(), sgs.CardDiscarded) then
					player:addMark("anxian")
					use.from:drawCards(1)
				end
			end
		elseif event == sgs.SlashEffected then
			if player:getMark("anxian") > 0 then
				local count = player:getMark("anxian") - 1
				player:setMark("anxian", count)
				return true
			end
			return false
		end
	end
}
--[[
	技能名：安恤
	相关武将：二将成名·步练师
	描述：出牌阶段，你可以选择两名手牌数不相等的其他角色，令其中手牌少的角色获得手牌多的角色的一张手牌并展示之，若此牌不为黑桃，你摸一张牌。每阶段限一次。
	状态：验证通过
]]--
AnxuCard = sgs.CreateSkillCard{
	name = "AnxuCard",
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if to_select == sgs.Self then
			return false
		elseif #targets == 0 then
			return true
		elseif #targets == 1 then
			local first = targets[1]
			return to_select:getHandcardNum() ~= first:getHandcardNum()
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local playerA = targets[1]
		local playerB = targets[2]
		local from
		local to
		if playerA:getHandcardNum() > playerB:getHandcardNum() then
			from = playerB
			to = playerA
		else
			from = playerA
			to = playerB
		end
		local id = room:askForCardChosen(from, to, "h", self:objectName())
		local card = sgs.Sanguosha:getCard(id)
		room:obtainCard(from, card)
		room:showCard(from, id)
		if card:getSuit() ~= sgs.Card_Spade then
			source:drawCards(1)
		end
	end
}
LuaAnxu = sgs.CreateViewAsSkill{
	name = "LuaAnxu",
	n = 0,
	view_as = function(self, cards)
		local card = AnxuCard:clone()
		card:setSkillName(self:objectName())
		return card
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#AnxuCard")
	end, 
}