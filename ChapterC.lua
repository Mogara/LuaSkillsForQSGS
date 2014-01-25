--[[
	代码速查手册（C区）
	技能索引：
		藏机、藏匿、谗陷、缠蛇、缠怨、超级观星、称象、称象、持重、冲阵、筹粮、醇醪、聪慧、存嗣、挫锐
]]--
--[[
	技能名：藏机
	相关武将：1v1·黄月英1v1
	描述：你死亡时，你可以将装备区的所有装备牌移出游戏：若如此做，你的下个武将登场时，将这些牌置于装备区。
]]--
--[[
	技能名：藏匿
	相关武将：铜雀台·伏皇后
	描述：弃牌阶段开始时，你可以回复1点体力或摸两张牌，然后将你的武将牌翻面；其他角色的回合内，当你获得（每回合限一次）/失去一次牌时，若你的武将牌背面朝上，你可以令该角色摸/弃置一张牌。
	引用：LuaCangni
	状态：1217验证通过
]]--
LuaCangni = sgs.CreateTriggerSkill{
	name = "LuaCangni" ,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Discard) then
			if player:askForSkillInvoke(self:objectName()) then
				local choices = {}
				table.insert(choices, "draw")
				if player:isWounded() then
					table.insert(choices, recover)
				end
				local choice
				if #choices == 1 then
					choice = choices[1]
				else
					choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
				end
				if choice == "recover" then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				else
					player:drawCards(2)
				end
				player:turnOver()
				return false
			end
		elseif (event == sgs.CardsMoveOneTime) and (not player:faceUp()) then
			if (player:getPhase() ~= sgs.Player_NotActive) then return false end
			local move = data:toMoveOneTime()
			local target = room:getCurrent()
			if target:isDead() then return false end
			if (move.from and (move.from:objectName() == player:objectName())) and ((not move.to) or (move.to:objectName() ~= player:objectName())) then
				local invoke = false
				for i = 0, move.card_ids:length() - 1, 1 do
					if (move.from_places:at(i) == sgs.Player_PlaceHand) or (move.from_places:at(i) == sgs.Player_PlaceEquip) then
						invoke = true
						break
					end
				end
				room:setPlayerFlag(player, "LuaCangniLose")
				if invoke and (not target:isNude()) then
					if player:askForSkillInvoke(self:objectName()) then
						room:askForDiscard(target, self:objectName(), 1, 1, false, true)
					end
				end
				room:setPlayerFlag(player, "-LuaCangniLose")
				return false
			end
			if (move.to and (move.to:objectName() == player:objectName())) and ((not move.from) or (move.from:objectName() ~= player:objectName())) then
				if (move.to_place == sgs.Player_PlaceHand) or (move.to_place == sgs.Player_PlaceEquip) then
					room:setPlayerFlag(player, "LuaCangniGet")
					if (not target:hasFlag("LuaCangni_Used")) then
						if player:askForSkillInvoke(self:objectName()) then
							room:setPlayerFlag(target, "LuaCangni_Used")
							target:drawCards(1)
						end
					end
					room:setPlayerFlag(player, "-LuaCangniGet")
				end
			end
		end
		return false
	end
}
--[[
	技能名：谗陷
	相关武将：3D织梦·孙鲁班
	描述： 出牌阶段，你可以将一张方片牌交给一名其他角色，该角色进行二选一：1、对其攻击范围内的另一名由你指定的角色使用一张【杀】。2.令你选择获得其一张牌或对其造成一点伤害。每阶段限一次。
	引用：LuaXChanxian
	状态：验证通过
]]--
LuaXChanxianCard = sgs.CreateSkillCard{
	name = "LuaXChanxianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		local room = source:getRoom()
		room:obtainCard(dest, self, true)
		if source:isAlive() and dest:isAlive() then
			local can_use = false
			local list = room:getOtherPlayers(dest)
			for _,p in sgs.qlist(list) do
				if dest:canSlash(p) then
					can_use = true
					break
				end
			end
			local victim = nil
			if can_use then
				local targets = sgs.SPlayerList()
				for _,v in sgs.qlist(list) do
					if dest:canSlash(v) then
						targets:append(v)
					end
				end
				victim = room:askForPlayerChosen(source, targets, self:objectName())
				local prompt = string.format("@ChanxianSlash", source:objectName(), victim:objectName())
				if not room:askForUseSlashTo(dest, victim, prompt) then
					if not dest:isNude() then
						local choice = room:askForChoice(source, self:objectName(), "getcard+damage")
						if choice == "getcard" then
							local card_id = room:askForCardChosen(source, dest, "he", self:objectName())
							room:obtainCard(source, card_id)
						else
							local damage = sgs.DamageStruct()
							damage.from = source
							damage.to = dest
							damage.damage = 1
							damage.card = nil
							room:damage(damage)
						end
					else
						local damage = sgs.DamageStruct()
						damage.from = source
						damage.to = dest
						damage.damage = 1
						damage.card = nil
						room:damage(damage)
					end
				end
			else
				local damage = sgs.DamageStruct()
				damage.from = source
				damage.to = dest
				damage.damage = 1
				damage.card = nil
				room:damage(damage)
			end
		end
	end,
}
LuaXChanxian = sgs.CreateViewAsSkill{
	name = "LuaXChanxian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Diamond
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local chanxian_card = LuaXChanxianCard:clone()
			chanxian_card:addSubcard(cards[1])
			return chanxian_card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaXChanxianCard")
	end,
}
--[[
	技能名：缠蛇（聚气技）
	相关武将：长坂坡·神张飞
	描述：出牌阶段，你可以将你的任意方片花色的“怒”当【乐不思蜀】使用。
]]--
--[[
	技能名：缠怨（锁定技）
	相关武将：风·于吉
	描述：你不能质疑“蛊惑”。若你的体力值为1，你的其他武将技能无效。
]]--
--[[
	技能名：超级观星
	相关武将：测试·五星诸葛
	描述：回合开始阶段，你可以观看牌堆顶的5张牌，将其中任意数量的牌以任意顺序置于牌堆顶，其余则以任意顺序置于牌堆底
	引用：LuaXSuperGuanxing
	状态：1217验证通过
]]--
LuaXSuperGuanxing = sgs.CreateTriggerSkill{
	name = "LuaXSuperGuanxing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			if player:askForSkillInvoke(self:objectName()) then
				local room = player:getRoom()
				local stars = room:getNCards(5,false)
				room:askForGuanxing(player, stars)
			end
		end
	end
}
--[[
	技能名：称象
	相关武将：一将成名2013·曹冲
	描述： 每当你受到一次伤害后，你可以展示牌堆顶的四张牌，然后获得其中任意数量点数之和小于13的牌，并将其余的牌置入弃牌堆。
	引用：LuaChengxiang
	状态：1217验证通过
]]--
LuaChengxiang = sgs.CreateTriggerSkill{
	name = "LuaChengxiang" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if not player:askForSkillInvoke(self:objectName(), data) then return false end
		local card_ids = room:getNCards(4)
		room:fillAG(card_ids)
		local to_get = sgs.IntList()
		local to_throw = sgs.IntList()
		while true do
			local sum = 0
			for _, id in sgs.qlist(to_get) do
				sum = sum + sgs.Sanguosha:getCard(id):getNumber()
			end
			for _, id in sgs.qlist(card_ids) do
				if sum + sgs.Sanguosha:getCard(id):getNumber() >= 13 then
					room:takeAG(nil, id, false)
					card_ids:removeOne(id)
					to_throw:append(id)
				end
			end
			if card_ids:isEmpty() then break end
			local card_id = room:askForAG(player, card_ids, true, self:objectName())
			if card_id == -1 then break end
			card_ids:removeOne(card_id)
			to_get:append(card_id)
			room:takeAG(player, card_id, false)
			if card_ids:isEmpty() then break end
		end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if not to_get:isEmpty() then
			for _, id in sgs.qlist(to_get) do
				dummy:addSubcard(id)
			end
			player:obtainCard(dummy)
		end
		dummy:clearSubcards()
		if (not to_throw:isEmpty()) or (not card_ids:isEmpty()) then
			for _, id in sgs.qlist(to_throw) do
				dummy:addSubcard(id)
			end
			for _, id in sgs.qlist(card_ids) do
				dummy:addSubcard(id)
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
			room:throwCard(dummy, reason, nil)
		end
		room:clearAG()
		return false
	end
}
--[[
	技能名：称象
	相关武将：倚天·曹冲
	描述：每当你受到一次伤害后，你可以弃置X张点数之和与造成伤害的牌的点数相等的牌，你可以选择至多X名角色，若其已受伤则回复1点体力，否则摸两张牌。
	引用：LuaYTChengxiang
	状态：1217验证通过
]]--
LuaYTChengxiangCard = sgs.CreateSkillCard{
	name = "LuaYTChengxiang" ,
	filter = function(self, targets, to_select)
		return #targets < self:subcardsLength()
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if effect.to:isWounded() then
			local recover = sgs.RecoverStruct()
			recover.card = self
			recover.who = effect.from
			room:recover(effect.to, recover)
		else
			effect.to:drawCards(2)
		end
	end
}
LuaYTChengxiangVS = sgs.CreateViewAsSkill{
	name = "LuaYTChengxiang" ,
	n = 3 ,
	view_filter = function(self, selected, to_select)
		if #selected >= 3 then return false end
		local sum = 0
		for _, card in ipairs(selected) do
			sum = sum + card:getNumber()
		end
		sum = sum + to_select:getNumber()
		return sum <= sgs.Self:getMark("LuaYTChengxiang")
	end ,
	view_as = function(self, cards)
		local sum = 0
		for _, c in ipairs(cards) do
			sum = sum + c:getNumber()
		end
		if sum == sgs.Self:getMark("LuaYTChengxiang") then
			local card = LuaYTChengxiangCard:clone()
			for _, c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		else
			return nil
		end
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaYTChengxiang"
	end
}
LuaYTChengxiang = sgs.CreateTriggerSkill{
	name = "LuaYTChengxiang" ,
	events = {sgs.Damaged} ,
	view_as_skill = LuaYTChengxiangVS ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local card = damage.card
		if card == nil then return false end
		local point = card:getNumber()
		if (point < 1) or (point > 13) then return false end
		if player:isNude() then return false end
		local room = player:getRoom()
		room:setPlayerMark(player, "LuaYTChengxiang", point)
		local prompt = "@chengxiang-card:::" .. tostring(point)
		room:askForUseCard(player, "@@LuaYTChengxiang", prompt)
		return false
	end
}
--[[
	技能名：持重（锁定技）
	相关武将：铜雀台·伏完
	描述：你的手牌上限等于你的体力上限；其他角色死亡时，你加1点体力上限。
	引用：LuaChizhong、LuaChizhong2
	状态：1217验证通过
]]--
LuaChizhong = sgs.CreateMaxCardsSkill{
	name = "LuaChizhong" ,
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getLostHp()
		else
			return 0
		end
	end
}
LuaChizhong2 = sgs.CreateTriggerSkill{
	name = "#LuaChizhong" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if not splayer then return false end
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then return false end
		room:setPlayerProperty(splayer, "maxhp", sgs.QVariant(splayer:getMaxHp() + 1))
		return false
	end
}
--[[
	技能名：冲阵
	相关武将：☆SP·赵云
	描述：每当你发动“龙胆”使用或打出一张手牌时，你可以立即获得对方的一张手牌。
	引用：LuaChongzhen
	状态：1217验证通过
]]--
LuaChongzhen = sgs.CreateTriggerSkill{
	name = "LuaChongzhen" ,
	events = {sgs.CardResponded, sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if (resp.m_card:getSkillName() == "longdan") and resp.m_who and (not resp.m_who:isKongcheng()) then
				local _data = sgs.QVariant()
				_data:setValue(resp.m_who)
				if player:askForSkillInvoke(self:objectName(), _data) then
					local card_id = room:askForCardChosen(player, resp.m_who, "h", self:objectName())
					room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
				end
			end
		else
			local use = data:toCardUse()
			if (use.from:objectName() == player:objectName()) and (use.card:getSkillName() == "longdan") then
				for _, p in sgs.qlist(use.to) do
					if p:isKongcheng() then continue end
					local _data = sgs.QVariant()
					_data:setValue(p)
					p:setFlags("LuaChongzhenTarget")
					local invoke = player:askForSkillInvoke(self:objectName(), _data)
					p:setFlags("-LuaChongzhenTarget")
					if invoke then
						local card_id = room:askForCardChosen(player,p,"h",self:objectName())
						room:obtainCard(player,sgs.Sanguosha:getCard(card_id), false)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：筹粮
	相关武将：智·蒋琬
	描述：回合结束阶段开始时，若你手牌少于三张，你可以从牌堆顶亮出X张牌（X为4减当前手牌数），拿走其中的基本牌，把其余的牌置入弃牌堆
	引用：LuaXChouliang
	状态：验证通过
]]--
LuaXChouliang = sgs.CreateTriggerSkill{
	name = "LuaXChouliang",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local handcardnum = player:getHandcardNum()
		if player:getPhase() == sgs.Player_Finish then
			if handcardnum < 3 then
				if room:askForSkillInvoke(player, self:objectName()) then
					for i=1, 4-handcardnum, 1 do
						local card_id = room:drawCard()
						local card = sgs.Sanguosha:getCard(card_id)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, player:objectName(), "", self:objectName(), "")
						room:moveCardTo(card, player, sgs.Player_PlaceTable, reason, true)
						room:getThread():delay()
						if not card:isKindOf("BasicCard") then
							room:throwCard(card_id, nil)
							room:setEmotion(player, "bad")
						else
							room:obtainCard(player, card_id)
							room:setEmotion(player, "good")
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：醇醪
	相关武将：二将成名·程普
	描述：结束阶段开始时，若你的武将牌上没有牌，你可以将任意数量的【杀】置于你的武将牌上，称为“醇”；当一名角色处于濒死状态时，你可以将一张“醇”置入弃牌堆，令该角色视为使用一张【酒】。
	引用：LuaChunlao、LuaChunlaoClear
	状态：1217验证通过
]]--
LuaChunlaoCard = sgs.CreateSkillCard{
	name = "LuaChunlaoCard" ,
	will_throw = false ,
	target_fixed = true ,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		source:addToPile("wine", self)
	end
}
LuaChunlaoWineCard = sgs.CreateSkillCard{
	name = "LuaChunlaoWine" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		if source:getPile("wine"):isEmpty() then return end
		local who = room:getCurrentDyingPlayer()
		if not who then return end
		local cards = source:getPile("wine")
		room:fillAG(cards, source)
		local card_id = room:askForAG(source, cards, false, "LuaChunlao")
		room:clearAG()
		if card_id ~= -1 then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, "LuaChunlao", nil)
			room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
			local analeptic = sgs.Sanguosha:cloneCard("Analeptic", sgs.Card_NoSuit, 0)
			analeptic:setSkillName("_LuaChunlao")
			room:useCard(sgs.CardUseStruct(analeptic, who, who, false))
		end
	end
}
LuaChunlaoVS = sgs.CreateViewAsSkill{
	name = "LuaChunlao" ,
	n = 999,
	view_filter = function(self, cards, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@LuaChunlao" then
			return to_select:isKindOf("Slash")
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@LuaChunlao" then
			if #cards == 0 then return nil end
			local acard = LuaChunlaoCard:clone()
			for _, c in ipairs(cards) do
				acard:addSubcard(c)
			end
			acard:setSkillName(self:objectName())
			return acard
		else
			if #cards ~= 0 then return nil end
			return LuaChunlaoWineCard:clone()
		end
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "@@LuaChunlao") or (string.find(pattern, "peach") and (not player:getPile("wine"):isEmpty()))
	end
}
LuaChunlao = sgs.CreateTriggerSkill{
	name = "LuaChunlao" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = LuaChunlaoVS ,
	on_trigger = function(self, event, player, data)
		if (event == sgs.EventPhaseStart)
				and (player:getPhase() == sgs.Player_Finish)
				and (not player:isKongcheng())
				and player:getPile("wine"):isEmpty() then
			player:getRoom():askForUseCard(player, "@@LuaChunlao", "@chunlao", -1, sgs.Card_MethodNone)
		end
		return false
	end
}
LuaChunlaoClear = sgs.CreateTriggerSkill{
	name = "#LuaChunlao-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaChunlao" then
			player:clearOnePrivatePile("wine")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：聪慧（锁定技）
	相关武将：倚天·曹冲
	描述：你将永远跳过你的弃牌阶段
	引用：LuaConghui
	状态：1217验证通过
]]--
LuaConghui = sgs.CreateTriggerSkill{
	name = "LuaConghui" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Discard then player:skip(change.to) end
		return false
	end
}
--[[
	技能名：存嗣
	相关武将：势·糜夫人
	描述：限定技，出牌阶段，你可以失去“闺秀”和“存嗣”，然后令一名角色获得“勇决”（若一名角色于出牌阶段内使用的第一张牌为【杀】，此【杀】结算完毕后置入弃牌堆时，你可以令其获得之。）：若该角色不是你，该角色摸两张牌。 
	引用：LuaCunsi、LuaCunsiStart
	状态：1217验证通过
	
	注：此技能与闺秀有联系，有联系的地方请使用本手册当中的闺秀，并非原版
]]--
LuaCunsiCard = sgs.CreateSkillCard{
	name = "LuaCunsiCard",

	filter = function(self, targets, to_select)
		return #targets == 0 
	end,
	
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:handleAcquireDetachSkills(effect.from,"-LuaGuixiu|-LuaCunsi")
		room:acquireSkill(effect.to,"yongjue")
		if effect.to:objectName() ~= effect.from:objectName() then
			effect.to:drawCards(2)
		end
	end
}
LuaCunsi = sgs.CreateZeroCardViewAsSkill{
	name = "LuaCunsi",
	frequency = sgs.Skill_Limited,

	view_as = function()
		return LuaCunsiCard:clone()
	end
}
LuaCunsiStart = sgs.CreateTriggerSkill{
	name = "#LuaCunsiStart",
	events = {sgs.GameStart,sgs.EventAcquireSkill},
	
	on_trigger = function(self, event, player, data)
		player:getRoom():getThread():addTriggerSkill(sgs.Sanguosha:getTriggerSkill("yongjue"))
	end,
}
--[[
	技能名：挫锐（锁定技）
	相关武将：1v1·牛金
	描述：你的起始手牌数为X+2（X为你备选区里武将牌的数量），你跳过登场后的第一个判定阶段。 
]]--
