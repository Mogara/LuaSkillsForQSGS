--[[
	代码速查手册（P区）
	技能索引：
		排异、咆哮、破军
]]--
--[[
	技能名：排异
	相关武将：一将成名·钟会
	描述：出牌阶段，你可以将一张“权”置入弃牌堆，令一名角色摸两张牌，然后若该角色的手牌数大于你的手牌数，你对其造成1点伤害。每阶段限一次。
	状态：验证通过
]]--
LuaPaiyiCard = sgs.CreateSkillCard{
	name = "LuaPaiyiCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local powers = source:getPile("power")
		if powers:length() > 0 then
			local id
			if powers:length() == 1 then
				id = powers:first()
			else
				room:fillAG(powers, source)
				id = room:askForAG(source, powers, false, self:objectName())
				source:invoke("clearAG")
			end
			if id ~= -1 then
				local card = sgs.Sanguosha:getCard(id)
				room:throwCard(card, nil, nil)
				room:drawCards(target, 2, self:objectName())
				if target:getHandcardNum() > source:getHandcardNum() then
					local damage = sgs.DamageStruct()
					damage.card = nil
					damage.from = source
					damage.to = target
					room:damage(damage)
				end
			end
		end
	end
}
LuaPaiyi = sgs.CreateViewAsSkill{
	name = "LuaPaiyi", 
	n = 0, 
	view_as = function(self, cards)
		return LuaPaiyiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		local powers = player:getPile("power")
		if not powers:isEmpty() then
			return not player:hasUsed("#LuaPaiyiCard")
		end
		return false
	end
}
--[[
	技能名：咆哮（锁定技）
	相关武将：标准·张飞、翼·张飞
	描述：你在出牌阶段内使用【杀】时无次数限制。
]]--
--[[
	技能名：破军
	相关武将：一将成名·徐盛
	描述：每当你使用【杀】对目标角色造成一次伤害后，你可以令其摸X张牌（X为该角色当前的体力值且至多为5），然后该角色将其武将牌翻面。
	状态：验证通过
]]--
LuaPojun = sgs.CreateTriggerSkill{
	name = "LuaPojun", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},  
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local dest = damage.to
		if not dest:isDead() then
			local slash = damage.card
			if slash then
				if slash:isKindOf("Slash") then
					if not damage.chain then
						if not damage.transfer then
							local room = player:getRoom()
							if room:askForSkillInvoke(player, self:objectName(), data) then
								local hp = dest:getHp()
								local count = math.min(5, hp)
								dest:drawCards(count)
								dest:turnOver()
							end
						end
					end
				end
			end
		end
		return false
	end
}