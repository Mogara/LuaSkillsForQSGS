--[[
	代码速查手册（P区）
	技能索引：
		排异、咆哮、翩仪、破军、普济
]]--
--[[
	技能名：排异
	相关武将：一将成名·钟会
	描述：出牌阶段限一次，你可以将一张“权”置入弃牌堆并选择一名角色：若如此做，该角色摸两张牌：若其手牌多于你，该角色受到1点伤害。
	引用：LuaPaiyi
	状态：0405证通过
]]--
LuaPaiyiCard = sgs.CreateSkillCard{
	name = "LuaPaiyiCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local powers = source:getPile("power")
		if powers:isEmpty() then return false end
		local card_id = self:getSubcards():first()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", target:objectName(), self:objectName(), "")
		room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
		room:drawCards(target, 2, self:objectName())
		if target:getHandcardNum() > source:getHandcardNum() then
			room:damage(sgs.DamageStruct(self:objectName(), source, target))
		end
	end
}
LuaPaiyi = sgs.CreateOneCardViewAsSkill{
	name = "LuaPaiyi",
	filter_pattern = ".|.|.|power",
	expand_pile = "power",
	view_as = function(self, card)
		local py = LuaPaiyiCard:clone()
		py:addSubcard(card)
		return py
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaPaiyiCard") and not player:getPile("power"):isEmpty()
	end
}
--[[
	技能名：咆哮（锁定技）
	相关武将：界限突破·张飞、标准·张飞-旧、翼·张飞。夏侯霸、关兴&张苞
	描述：你在出牌阶段内使用【杀】时无次数限制。
	引用：LuaPaoxiao
	状态：0405验证通过
]]--
LuaPaoxiao = sgs.CreateTargetModSkill{
	name = "LuaPaoxiao",
	frequency = sgs.Skill_NotCompulsory,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：翩仪（锁定技）
	相关武将：1v1·貂蝉1v1
	描述：你登场时，若处于对手的回合，当前回合结束。
	状态：等某神杀版本支持throwEvent的时候我会考虑这个技能……
]]--
--[[
	技能名：破军
	相关武将：一将成名·徐盛
	描述：每当你使用【杀】对目标角色造成一次伤害后，你可以令其摸X张牌（X为该角色当前的体力值且至多为5），然后该角色将其武将牌翻面。
	引用：LuaPojun
	状态：1217验证通过
]]--
LuaPojun = sgs.CreateTriggerSkill{
	name = "LuaPojun" ,
	events = {sgs.Damage} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer)
				and damage.to:isAlive() then
			if player:getRoom():askForSkillInvoke(player, self:objectName(), data) then
				local x = math.min(5, damage.to:getHp())
				damage.to:drawCards(x)
				damage.to:turnOver()
			end
		end
		return false
	end
}
--[[
	技能名：普济
	相关武将：1v1·华佗
	描述：出牌阶段限一次，若对手有牌，你可以弃置一张牌：若如此做，你弃置其一张牌，然后以此法弃置♠牌的角色摸一张牌。 
	引用：LuaPuji
	状态：1217验证成功
]]--
LuaPujiCard = sgs.CreateSkillCard{
	name = "LuaPuji",
	filter = function(self, targets, to_select, player)
		return #targets<1 and player:canDiscard(to_select, "he") and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local id = room:askForCardChosen(effect.from, effect.to, "he", "LuaPuji")
		room:throwCard(id, effect.to, effect.from)
		if effect.from:isAlive() and self:getSuit() == sgs.Card_Spade then
			effect.from:drawCards(1)
		end
		if effect.to:isAlive() and sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade then
			effect.to:drawCards(1)
		end
	end,
}
LuaPuji = sgs.CreateOneCardViewAsSkill{
	name = "LuaPuji",
	filter_pattern = ".!",
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and not player:hasUsed("#LuaPuji")
	end,
	view_as = function(self, card)
		local pujiCard = LuaPujiCard:clone()
		pujiCard:addSubcard(card)
		return pujiCard
	end,
}
