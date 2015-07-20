代码速查手册（P区）
==
#技能索引
[排异](#排异)、[咆哮](#咆哮)、[翩仪](#翩仪)、[破军](#破军)、[普济](#普济)

[返回目录](README.md#目录)
##排异
**相关武将**：一将成名·钟会  
**描述**：出牌阶段限一次，你可以将一张“权”置入弃牌堆并选择一名角色，该角色摸两张牌。然后若该角色手牌数大于你的手牌数，你对其造成1点伤害。  
**引用**：LuaPaiyi  
**状态**：1217验证通过
```lua
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
					room:clearAG(source)
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
```
[返回索引](#技能索引)
##咆哮
**相关武将**：界限突破·张飞、标准·张飞-旧、翼·张飞、夏侯霸、关兴&张苞  
**描述**：**锁定技，**出牌阶段，你使用【杀】无次数限制。 
**引用**：LuaPaoxiao  
**状态**：0405验证通过
```lua
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
```
[返回索引](#技能索引)
##翩仪（锁定技）
**相关武将**：1v1·貂蝉1v1  
**描述**：你登场时，若处于对手的回合，当前回合结束。  
**状态**：等某神杀版本支持throwEvent的时候我会考虑这个技能……

[返回索引](#技能索引)
##破军
**相关武将**：一将成名·徐盛  
**描述**：每当你使用【杀】对目标角色造成一次伤害后，你可以令其摸X张牌（X为该角色当前的体力值且至多为5），然后该角色将其武将牌翻面。  
**引用**：LuaPojun  
**状态**：1217验证通过
```lua
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
```
[返回索引](#技能索引)
##普济
相关武将：1v1·华佗
描述：出牌阶段限一次，若对手有牌，你可以弃置一张牌：若如此做，你弃置其一张牌，然后以此法弃置♠牌的角色摸一张牌。 
引用：LuaPuji
状态：1217验证成功
```lua
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
```
[返回索引](#技能索引)
