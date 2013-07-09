--[[
	代码速查手册（V区）
	技能索引：（本区用于收录尚未实现或有争议的技能）
	☆源代码转化失败，改写后通过：
		不屈、称象、虎啸、祸水、龙胆、龙魂、龙魂
	☆验证失败：
		洞察、激将、极略、连理、秘计、神速、探虎、伪帝、修罗、言笑
	☆尚未完成：
		蛊惑、归心、倾城
	☆尚未验证：
		明哲、军威、死谏、骁果、雄异、援护
	☆验证通过：
		弓骑、弘援、弘援、缓释、缓释、疠火
]]--
--[[
	技能名：不屈
	相关武将：风·周泰
	描述：每当你扣减1点体力后，若你当前的体力值为0：你可以从牌堆顶亮出一张牌置于你的武将牌上，若此牌的点数与你武将牌上已有的任何一张牌都不同，你不会死亡；若出现相同点数的牌，你进入濒死状态。
	状态：验证失败（第一次回复体力时不能移除不屈牌）
]]--
Remove = function(player)
	local room = player:getRoom()
	local buqu = player:getPile("buqu")
	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "buqu", "")
	local need = 1 - player:getHp()
	if need <= 0 then
		for _,id in sgs.qlist(buqu) do
			local card = sgs.Sanguosha:getCard(id)
			room:throwCard(card, reason, nil)
		end
	else
		local to_remove = buqu:length() - need
		for i=1, to_remove, 1 do
			room:fillAG(buqu)
			local card_id = room:askForAG(player, buqu, false, "LuaBuqu")
			buqu:removeOne(card_id)
			local card = sgs.Sanguosha:getCard(card_id)
			room:throwCard(card, reason, nil)
			room:broadcastInvoke("clearAG")
		end
	end
end
LuaBuquRemove = sgs.CreateTriggerSkill{
	name = "#LuaBuquRemove",
	frequency = sgs.Skill_Frequent,
	events = {sgs.HpRecover, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		if event == sgs.HpRecover then
			if player:isAlive() and player:hasSkill("LuaBuqu") then
				if player:getPile("buqu"):length() > 0 then
					Remove(player)
				end
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() == "buqu" then
				player:removePileByName("buqu")
				if player:getHp() <= 0 then
					local room = player:getRoom()
					room:enterDying(player, nil)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
LuaBuqu = sgs.CreateTriggerSkill{
	name = "LuaBuqu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PostHpReduced, sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PostHpReduced then
			if player:getHp() < 1 then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:setTag("Buqu", sgs.QVariant(player:objectName()))
					local buqu = player:getPile("buqu")
					local need = 1 - player:getHp()
					local n = need - buqu:length()
					if n > 0 then
						local card_ids = room:getNCards(n, false)
						for _,id in sgs.qlist(card_ids) do
							player:addToPile("buqu", id)
						end
					end
					local buqunew = player:getPile("buqu")
					local duplicate_numbers = sgs.IntList()
					local numbers = {}
					for _,card_id in sgs.qlist(buqunew) do
						local card = sgs.Sanguosha:getCard(card_id)
						local number = card:getNumber()
						if numbers[number] then
							duplicate_numbers:append(number)
						else
							numbers[number] = number
						end
					end
					if duplicate_numbers:isEmpty() then
						room:setTag("Buqu", sgs.QVariant())
						return true
					end
				end
			end
		elseif event == sgs.AskForPeachesDone then
			local buqu = player:getPile("buqu")
			if player:getHp() <= 0 then
				if room:getTag("Buqu"):toString() == player:objectName() then
					room:setTag("Buqu", sgs.QVariant())
					local duplicate_numbers = sgs.IntList()
					local numbers = {}
					for _,card_id in sgs.qlist(buqu) do
						local card = sgs.Sanguosha:getCard(card_id)
						local number = card:getNumber()
						if numbers[number] then
							if not duplicate_numbers:contains(number) then
								duplicate_numbers:append(number)
							else
								numbers[number] = number
							end
						else
							numbers[number] = number
						end
					end
					if duplicate_numbers:isEmpty() then
						room:setPlayerFlag(player, "-dying")
						return true
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：称象
	相关武将：倚天·曹冲
	描述：每当你受到1次伤害，你可打出X张牌（X小于等于3），它们的点数之和与造成伤害的牌的点数相等，你可令X名角色各恢复1点体力（若其满体力则摸2张牌）
	状态：验证通过
]]--
LuaXChengxiangCard = sgs.CreateSkillCard{
	name = "LuaXChengxiangCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		local count = self:subcardsLength()
		if #targets < count then
			return to_select:isWounded()
		end
		return false
	end,
	feasible = function(self, targets)
		local count = self:subcardsLength()
		return #targets <= count
	end,
	on_use = function(self, room, source, targets) 
		local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
		if #targets == 0 then
			effect.to = source
			self:onEffect(effect)
		else
			for _,tg in ipairs(targets) do
				effect.to = tg
				self:onEffect(effect)
			end
		end
	end,
	on_effect = function(self, effect) 
		local target = effect.to
		local room = target:getRoom()
		if target:isWounded() then
			local recover = sgs.RecoverStruct()
			recover.card = self
			recover.who = effect.from
			room:recover(target, recover)
		else
			target:drawCards(2)
		end
	end
}
LuaXChengxiangVS = sgs.CreateViewAsSkill{
	name = "LuaXChengxiangVS", 
	n = 3, 
	view_filter = function(self, selected, to_select)
		if #selected < 3 then
			local sum = 0
			for _,card in pairs(selected) do
				sum = sum + card:getNumber()
			end
			sum = sum + to_select:getNumber()
			local target = sgs.Self:getMark("LuaXChengxiang")
			return sum <= target
		end
		return false
	end, 
	view_as = function(self, cards) 
		local sum = 0
		for _,card in pairs(cards) do
			sum = sum + card:getNumber()
		end
		local target = sgs.Self:getMark("LuaXChengxiang")
		if sum == target then
			local vs_card = LuaXChengxiangCard:clone()
			for _,card in pairs(cards) do
				vs_card:addSubcard(card)
			end
			return vs_card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXChengxiang"
	end
}
LuaXChengxiang = sgs.CreateTriggerSkill{
	name = "LuaXChengxiang",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged},  
	view_as_skill = LuaXChengxiangVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card then
			local point = card:getNumber()
			if point > 0 then
				if not player:isNude() then
					room:setPlayerMark(player, self:objectName(), point)
					local prompt = string.format("@chengxiang-card:::%d", point)
					room:askForUseCard(player, "@@LuaXChengxiang", prompt)
				end
			end
		end
	end
}
--[[
	技能名：洞察
	相关武将：倚天·贾文和
	描述：回合开始阶段开始时，你可以指定一名其他角色：该角色的所有手牌对你处于可见状态，直到你的本回合结束。其他角色都不知道你对谁发动了洞察技能，包括被洞察的角色本身 
	状态：验证失败（被洞察的角色的手牌不能处于可见状态）
	验证失败是因为源码在创建手牌按钮时使用Self->hasSkill("dongcha")的命令，
	将之替换为Self->hasFlag("dongchaer")后重新编译，以下代码通过,这么底层的东西看起来还是要cpp啊
]]--
LuaXDongcha = sgs.CreateTriggerSkill{
	name = "LuaXDongcha",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		local room = player:getRoom()
		if phase == sgs.Player_Start then
			if player:askForSkillInvoke(self:objectName()) then
				local players = room:getOtherPlayers(player)
				local dongchaee = room:askForPlayerChosen(player, players, self:objectName())
				room:setPlayerFlag(dongchaee, "dongchaee")
				room:setPlayerFlag(player, "dongchaer")
				local tag = sgs.QVariant()
				tag:setValue(dongchaee)
				room:setTag("Dongchaee", tag)
				tag:setValue(player)
				room:setTag("Dongchaer", tag)
				room:showAllCards(dongchaee, player)
			end
		elseif phase == sgs.Player_Finish then
			local tag = room:getTag("Dongchaee")
			if tag then
				local dongchaee = tag:toPlayer()
				if dongchaee then
					room:setPlayerFlag(dongchaee, "-dongchaee")
					room:setTag("Dongchaee", sgs.QVariant())
					room:setTag("Dongchaer", sgs.QVariant())
				end
			end
		end
		return false
	end
}
--[[
	技能名：弓骑
	相关武将：怀旧·韩当
	描述：你可以将一张装备牌当【杀】使用或打出；你以此法使用【杀】时无距离限制。
	状态：1221验证通过
]]--
LuaGongqi = sgs.CreateViewAsSkill{
	name = "LuaGongqi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		local weapon = sgs.Self:getWeapon()
		if weapon and to_select:objectName() == weapon:objectName() and to_select:objectName() == "Crossbow" then
			return sgs.Self:canSlashWithoutCrossbow()
		end
		return to_select:getTypeId() == sgs.Card_Equip
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local slash = sgs.Sanguosha:cloneCard("WushenSlash", suit, point)
			slash:addSubcard(id)
			slash:setSkillName(self:objectName())
			return slash
		end
	end, 
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
--[[
	技能名：蛊惑
	相关武将：风·于吉
	描述： 你可以说出一张基本牌或非延时类锦囊牌的名称，并背面朝上使用或打出一张手牌。若无其他角色质疑，则亮出此牌并按你所述之牌结算。若有其他角色质疑则亮出验明：若为真，质疑者各失去1点体力；若为假，质疑者各摸一张牌。除非被质疑的牌为红桃且为真，此牌仍然进行结算，否则无论真假，将此牌置入弃牌堆。
	状态：尚未完成（莫名闪退，改日排查，暂搁置于此。）
]]--
function askforLuaGuhuoQuery(room, player, oldcard, newcard, suit)
	local query = false
	for _,theplayer in sgs.qlist(room:getOtherPlayers(player)) do
		room:setPlayerFlag(theplayer, "-LuaGuhuoQuery")
		if theplayer:getHp() > 0 then
			if room:askForSkillInvoke(theplayer, "LuaGuhuoQuery") then
				room:setPlayerFlag(theplayer, "LuaGuhuoQuery")
				query = true
			end
		end
	end
	if not query then return false end
	local istrue = false
	if newcard == oldcard then istrue = true end
	for _,theplayer in sgs.qlist(room:getOtherPlayers(player)) do
		if theplayer:hasFlag("LuaGuhuoQuery") then
			if istrue then
				room:loseHp(theplayer)
			else
				theplayer:drawCards(1)
			end
		end
		room:setPlayerFlag(theplayer, "-LuaGuhuoQuery")
	end
	return not (suit==sgs.Card_Heart and istrue)
end
LuaGuhuoCard = sgs.CreateSkillCard{
	name = "LuaGuhuoCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choices = "cancel"
		local card = nil
		local n = 0
		local new = false
		local choicetable = {}
		for cardid = 0,165,1 do
			card = nil
			card = sgs.Sanguosha:getCard(cardid)
			if card and (card:isKindOf("BasicCard") or card:isNDTrick()) and not(card:isKindOf("Nullification") or card:isKindOf("Jink") or (card:isKindOf("Peach") and source:getLostHp() == 0)) then
				choicetable = {}
				choicetable = choices:split("+");
				n = #choicetable
				new = true
				for var = 1, n, 1 do
					if choicetable[var] == card:objectName() then new = false end
				end
				if new then choices = choices.."+"..card:objectName() end
			end
		end
		local choice = room:askForChoice(source, "LuaGuhuo", choices)
		local marknum = 0
		for cardid = 0, 165, 1 do
			card = nil
			card = sgs.Sanguosha:getCard(cardid)
			if card and card:objectName() == choice then 
				marknum = cardid + 1
				break
			end
		end
		room:setPlayerMark(source, "@LuaGuhuo", marknum)
		if marknum ~= 0 then
			room:acquireSkill(source, "LuaGuhuoFT")
			local carduse = sgs.CardUseStruct()
			room:activate(source, carduse)
			room:setPlayerMark(source, "@LuaGuhuo", 0)
			room:detachSkillFromPlayer(source, "LuaGuhuoFT")
			if carduse:isValid() and not (carduse.card:isKindOf("IronChain") and carduse.to:isEmpty()) then
				local carda = sgs.Sanguosha:getCard(carduse.card:getSubcards():at(0))
				carduse.card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
				carduse.card:setSkillName("LuaGuhuoForLog")
				room:useCard(carduse, false)
				carduse.card = sgs.Sanguosha:cloneCard(choice, carda:getSuit(), carda:getNumber())
				carduse.card:addSubcard(carda:getId())
				carduse.card:setSkillName("LuaGuhuo")
				local useless = askforLuaGuhuoQuery(room, source, choice, carda:objectName(), carda:getSuit())
				room:throwCard(carda)
				if not useless then room:useCard(carduse) end
			end
		end
	end,
}
LuaGuhuo=sgs.CreateViewAsSkill{
	name = "LuaGuHuo",
	n = 0,
	view_as = function(self, cards)
		acard = LuaGuhuoCard:clone()
		return acard
	end,
	enabled_at_nullification = function(self, player)
		return true
	end,
}
LuaGuhuoFT = sgs.CreateFilterSkill{
	name = "LuaGuhuoFT",
	view_filter = function(self, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, card)
		local mark = sgs.Self:getMark("@LuaGuhuo")
		if mark == 0 then return card end
		local oldcard = sgs.Sanguosha:getCard(mark-1)
		local newcard = sgs.Sanguosha:cloneCard(oldcard:objectName(), card:getSuit(), card:getNumber())
		newcard:addSubcard(card:getId())
		newcard:setSkillName("LuaGuhuo")
		return newcard
	end,
}
LuaGuhuoTR = sgs.CreateTriggerSkill{
	name = "#LuaGuhuoTR",
	events = {sgs.CardAsked, sgs.CardUsed, sgs.AskForPeaches, sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			player:gainMark("cannull",1)
			return false
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			return use.card:getSkillName() == "LuaGuhuoForLog"
		end
		local str = ""
		if event == sgs.CardAsked then
			str = data:toString()
			if str == "slash" then str = "slash+fire_slash+thunder_slash" end
		end
		local dying = nil
		if event == sgs.AskForPeaches then
			dying = data:toDying()
			if dying.who:getSeat() == player:getSeat() then
				str = "peach+analeptic"
			else
				str = "peach"
			end
		end
		if player:isKongcheng() or not room:askForSkillInvoke(player, "LuaGuhuo") then return false end
		local choice = ""
		local choicetable = {}
		choicetable = str:split("+");
		n = #choicetable
		if n == 1 then choice = str else choice = room:askForChoice(player, "LuaGuhuo", str) end
		local canvs = 0
		local card = nil
		for cardid = 0, 165, 1 do
			card = nil
			card = sgs.Sanguosha:getCard(cardid)
			if card and card:objectName() == choice then 
				canvs = 1
				break
			end
		end
		if canvs == 0 then return false end
		if marknum ~= 0 then
			while true do
				local carda = room:askForCardShow(player, player,"LuaGuhuo")
				local carduse = sgs.CardUseStruct()
				carduse.card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
				carduse.card:setSkillName("LuaGuhuoForLog")
				carduse.from = player
				room:useCard(carduse)
				local useless = askforLuaGuhuoQuery(room, player, choice, carda:objectName(), carda:getSuit())
				room:throwCard(carda)
				if not useless then
					local s = sgs.Sanguosha:cloneCard(choice, carda:getSuit(), carda:getNumber())
					s:addSubcard(carda:getId())
					s:setSkillName("LuaGuhuo")
					if event == sgs.CardAsked then room:provide(s) end
					if event == sgs.AskForPeaches then
						local recover = sgs.RecoverStruct()
						recover.recover = 1
						recover.who = player
						room:recover(dying.who, recover)
					end
					return false
				else
					if player:isKongcheng() or not room:askForSkillInvoke(player, "LuaGuhuo") then return false end
				end
			end
		end
	end,
}
local skill = sgs.Sanguosha:getSkill("LuaGuhuoFT")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(LuaGuhuoFT)
	sgs.Sanguosha:addSkills(skillList)
end
--[[
	技能名：归心
	相关武将：倚天·魏武帝
	描述：回合结束阶段，你可以做以下二选一：
		1. 永久改变一名其他角色的势力
		2. 永久获得一项未上场或已死亡角色的主公技。(获得后即使你不是主公仍然有效) 
	状态：尚未完成（含有findChildren<Skill*>和qobject_cast<GameStartSkill*>等内容无法转换）
]]--
LuaXWeiwudiGuixin = sgs.CreateTriggerSkill{
	name = "LuaXWeiwudiGuixin",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				local choice = room:askForChoice(player, self:objectName(), "modify+obtain")
				if choice == "modify" then
					local others = room:getOtherPlayers(player)
					local to_modify = room:askForPlayerChosen(player, others, self:objectName())
					local tag = sgs.QVariant()
					tag:setValue(to_modify)
					room:setTag("Guixin2Modify", tag)
					local kingdom = room:askForChoice(player, self:objectName(), "wei+shu+wu+qun")
					room:removeTag("Guixin2Modify")
					room:setPlayerProperty(to_modify, "kingdom", sgs.QVariant(kingdom))
				elseif choice == "obtain" then
					local lords = sgs.Sanguosha:getLords()
					local players = room:getOtherPlayers(player)
					for _,p in sgs.qlist(players) do
						local name = p:getGeneralName()
						lords:removeOne(name)
					end
					local lord_skills
					--[[以下内容含有findChildren<Skill*>和qobject_cast<GameStartSkill*>等无法转换
					for _,lord in sgs.qlist(lords) do
						local general = sgs.Sanguosha:getGeneral(lord)
						QList<const Skill *> skills = general->findChildren<const Skill *>();
						for _,skill in sgs.qlist(skills) do
							if skill:isLordSkill() then
								local skillname = skill:objectName()
								if not player:hasSkill(skillname) then
									lord_skills:append(skillname)
								end
							end
						end
					end
					if not lord_skills:isEmpty() then
						local skill_name = room:askForChoice(player, self:objectName(), lord_skills.join("+"))
						local skill = sgs.Sanguosha:getSkill(skill_name)
						room:acquireSkill(player, skill)
						if skill:inherits("GameStartSkill") then
							const GameStartSkill *game_start_skill = qobject_cast<const GameStartSkill *>(skill)
							game_start_skill->onGameStart(player)
						end
					end
					]]--
				end
			end
		end
		return false
	end
}
--[[
	技能名：弘援
	相关武将：新3V3·诸葛瑾
	描述：摸牌阶段，你可以少摸一张牌，令其他己方角色各摸一张牌。
	状态：0224验证通过（源码AI::GetRelation3v3(zhugejin, other)无法转化，直接使用身份判断是否为队友）
]]--
Lua3V3_isFriend = function(player,other)
	local tb = { ["lord"] = "warm", ["loyalist"] = "warm", ["renegade"] = "cold", ["rebel"] = "cold" }
	return tb[player:getRole()] == tb[other:getRole()]
end
LuaXHongyuan = sgs.CreateTriggerSkill{
	name = "LuaXHongyuan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards },  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			player:setFlags(self:objectName())
			local count = data:toInt() - 1
			data:setValue(count)
		end
	end
}
LuaXHongyuanAct = sgs.CreateTriggerSkill {
	name = "#LuaXHongyuanAct",  
	frequency = sgs.Skill_Frequent, 
	events = { sgs.AfterDrawNCards },  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if player:hasFlag("LuaXHongyuan") then
				player:setFlags("-LuaXHongyuan")
				for _, other in sgs.qlist(room:getOtherPlayers(player)) do
					if Lua3V3_isFriend(player, other) then
						other:drawCards(1)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：弘援
	相关武将：新3V3·诸葛瑾（身份局）
	描述：摸牌阶段，你可以少摸一张牌，令一至两名其他角色各摸一张牌。
	状态：验证通过
]]--
LuaXHongyuanCard = sgs.CreateSkillCard {
	name = "LuaXHongyuanCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if to_select:objectName() ~= sgs.Self:objectName() then
			return #targets < 2
		end
		return false
	end,
	on_effect = function(self, effect) 
		effect.to:drawCards(1)
	end
}
LuaXHongyuanVS = sgs.CreateViewAsSkill {
	name = "LuaXHongyuan", 
	n = 0,
	view_as = function(self, cards)
		return LuaXHongyuanCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXHongyuan"
	end
}
LuaXHongyuan = sgs.CreateTriggerSkill{
	name = "LuaXHongyuan",  
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards },  
	view_as_skill = LuaXHongyuanVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			player:setFlags(self:objectName())
			local count = data:toInt() - 1
			data:setValue(count)
		end
	end
}
LuaXHongyuanAct = sgs.CreateTriggerSkill {
	name = "#LuaXHongyuanAct",
	frequency = sgs.Skill_Frequent,
	events = { sgs.AfterDrawNCards },
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if player:hasFlag("LuaXHongyuan") then
				player:setFlags("-LuaXHongyuan")
				if not room:askForUseCard(player, "@@LuaXHongyuan", "@hongyuan") then
					player:drawCards(1)
				end
			end
		end
		return false
	end
}
--[[
	技能名：虎啸
	相关武将：SP·关银屏
	描述：你于出牌阶段每使用一张【杀】被【闪】抵消，此阶段你可以额外使用一张【杀】。 
	状态：验证通过
]]--
LuaHuxiao = sgs.CreateTriggerSkill{
	name = "LuaHuxiao",
	events = { sgs.SlashMissed,sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		if event == sgs.SlashMissed then
			if player:getPhase() == sgs.Player_Play then
				player:addMark("Huxiao")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				player:setMark("Huxiao", 0)
			end
		end
	end,
}
LuaHuxiaoHid = sgs.CreateTargetModSkill {
	name = "#LuaHuxiaoHid",
	pattern = "Slash",
	residue_func = function(self, player)
		local num = player:getMark("Huxiao")
		if player:hasSkill(self:objectName()) then
			return num
		end
	end,
}
--[[
	技能名：缓释
	相关武将：新3V3·诸葛瑾
	描述：在一名己方角色的判定牌生效前，你可以打出一张牌代替之。
	状态：0224验证通过（源码AI::GetRelation3v3(zhugejin, other)无法转化，使用身份判断是否为队友）
]]--
Lua3V3_isFriend = function(player,other)
	local tb = { ["lord"] = "warm", ["loyalist"] = "warm", ["renegade"] = "cold", ["rebel"] = "cold" }
	return tb[player:getRole()] == tb[other:getRole()]
end
LuaXHuanshiCard = sgs.CreateSkillCard {
	name = "LuaXHuanshiCard",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodResponse
}
LuaXHuanshiVS = sgs.CreateViewAsSkill{
	name = "LuaXHuanshi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isCardLimited(to_select, sgs.Card_MethodResponse)
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaXHuanshiCard:clone()
			card:setSuit(cards[1]:getSuit())
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@LuaXHuanshi"
	end
}
LuaXHuanshi = sgs.CreateTriggerSkill {
	name = "LuaXHuanshi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForRetrial },
	view_as_skill = LuaXHuanshiVS,
	on_trigger = function(self, event, player, data)
		if player:isNude() then return false end
		local judge = data:toJudge()
		local can_invoke = false
		local room = player:getRoom()
		if Lua3V3_isFriend(player,judge.who) then
			can_invoke = true
		end
		if not can_invoke then
			return false
		end
		local prompt_list = { "@huanshi-card", judge.who:objectName(), self:objectName(), judge.reason, judge.card:getEffectIdString() }
		local prompt = table.concat(prompt_list, ":")
		local pattern = "@LuaXHuanshi"
		local card = room:askForCard(player, pattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end
}
--[[
	技能名：缓释
	相关武将：新3V3·诸葛瑾（身份局）
	描述：在一名角色的判定牌生效前，你可以令其选择是否由你打出一张牌代替之。
	状态：验证通过
]]--
LuaXHuanshiCard = sgs.CreateSkillCard{
	name = "LuaXHuanshiCard",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodResponse
}
LuaXHuanshiVS = sgs.CreateViewAsSkill{
	name = "LuaXHuanshi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isCardLimited(to_select, sgs.Card_MethodResponse)
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaXHuanshiCard:clone()
			card:setSuit(cards[1]:getSuit())
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@LuaXHuanshi"
	end
}
LuaXHuanshi = sgs.CreateTriggerSkill{
	name = "LuaXHuanshi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.AskForRetrial},  
	view_as_skill = LuaXHuanshiVS, 
	on_trigger = function(self, event, player, data)
		if player:isNude() then return false end
		local judge = data:toJudge()
		local can_invoke = false
		local room = player:getRoom()
		if judge.who:objectName() ~= player:objectName() then
			if room:askForSkillInvoke(player, self:objectName()) then
				if room:askForChoice(judge.who, self:objectName(), "yes+no") == "yes" then
					can_invoke = true
				end
			end
		else 
			can_invoke = true
		end
		if not can_invoke then
			return false
		end
		local prompt_list = {"@huanshi-card", judge.who:objectName(), self:objectName(), judge.reason, judge.card:getEffectIdString()}
		local prompt = table.concat(prompt_list, ":")
		local pattern = "@LuaXHuanshi"
		local card = room:askForCard(player, pattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end, 
}
--[[
	技能名：祸水（锁定技）
	相关武将：国战·邹氏
	描述：你的回合内，体力值不少于体力上限一半的其他角色所有武将技能无效。 
	状态：验证通过
]]--
function setHuoshuiFlag(room, player, is_lose) 
	for _,pl in sgs.qlist(room:getOtherPlayers(player)) do
		room:setPlayerFlag(pl, is_lose and "-huoshui" or "huoshui")
		room:filterCards(pl, pl:getCards("he"), not is_lose)
	end
end
LuaHuoshui = sgs.CreateTriggerSkill{
	name = "LuaHuoshui",
	events	= {sgs.EventPhaseStart,sgs.EventPhaseChanging,sgs.PostHpReduced,sgs.Death,sgs.MaxHpChanged,sgs.EventAcquireSkill,sgs.EventLoseSkill,sgs.HpRecover,sgs.PreHpLost},
	priority = 4,	
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		return player ~= nil
	end,
	on_trigger = function(self, event, player, data)
		if player == nil or player:isDead() then return end
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then
			setHuoshuiFlag(room, player, false)
		end
		if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive and player:hasSkill(self:objectName()) then 
			setHuoshuiFlag(room, player, true)
		end
		if event == sgs.Death then 
			local SI = data:toDeath()
			if player:objectName() == SI.who:objectName() then return end
			if player:hasSkill(self:objectName()) then
				setHuoshuiFlag(room, player, true)
			end
		end
		if event == sgs.EventLoseSkill and data:toString() == self:objectName() and room:getCurrent() and room:getCurrent():objectName() == player:objectName() then
			setHuoshuiFlag(room, player, true)
		end
		if event == sgs.EventAcquireSkill and data:toString() == self:objectName() and room:getCurrent() and room:getCurrent():objectName() == player:objectName()then
			setHuoshuiFlag(room, player, false)
		end
		if event == sgs.PostHpReduced or event == sgs.PreHpLost then
			if not player:hasFlag("huoshui") then return end
			local x=0
			if event == sgs.PostHpReduced then
				x = data:toDamage().damage
			else
				x=data:toInt()
			end
			local lhp=player:getHp()
			local xhp=(player:getMaxHp() + 1) / 2
			if (lhp < xhp and lhp + x >= xhp) then
				room:filterCards(player, player:getCards("he"), false)
			end
		end
		if event == sgs.MaxHpChanged and player:hasFlag("huoshui") then
			room:filterCards(player, player:getCards("he"), true)
		end
		if event == sgs.HpRecover then 
			local recov = data:toRecover()
			local nnx=recov.recover
			if player:hasFlag("huoshui") then
				local hp = player:getHp()
				local maxhp_2 = (player:getMaxHp() + 1) / 2
				if (hp >= maxhp_2 and hp - nnx < maxhp_2) then
					room:filterCards(player, player:getCards("he"), true)
				end
			end 
		end
	end,
}
--[[
	技能名：激将（主公技）
	相关武将：标准·刘备、山·刘禅
	描述：当你需要使用或打出一张【杀】时，你可以令其他蜀势力角色打出一张【杀】（视为由你使用或打出）。
	状态：验证失败（sgs.ClientInstance为空导致在打出杀时发动技能时出错）
]]--
LuaJijiangCard = sgs.CreateSkillCard{
	name = "LuaJijiangCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local players = sgs.PlayerList()
		if #targets > 0 then
			for _,p in pairs(targets) do
				players:append(p)
			end
		end
		return slash:targetFilter(players, to_select, sgs.Self)
	end,
	on_use = function(self, room, source, targets) 
		local lieges = room:getLieges("shu", source)
		local slash = NULL
		local tohelp = sgs.QVariant()
		tohelp:setValue(source)
		local prompt = string.format("@jijiang-slash:%s", source:objectName())
		for _,liege in sgs.qlist(lieges) do
			slash = room:askForCard(liege, "slash", prompt, tohelp, sgs.CardResponsed, source)
			if slash then
				local card_use = sgs.CardUseStruct()
				card_use.card = slash
				card_use.from = source
				card_use.to:append(targets[1])
				room:useCard(card_use)
				return;
			end
		end
		room:setPlayerFlag(source, "jijiang_failed")
	end
}
LuaJijiangVS = sgs.CreateViewAsSkill{
	name = "LuaJijiang$", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaJijiangCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:hasLordSkill("LuaJijiang") then
			return sgs.Slash_IsAvailable(player)
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		if pattern == "slash" then
			if not sgs.ClientInstance:hasNoTargetResponsing() then
				return not player:hasFlag("jijiang_failed")
			end
		end
		return false
	end
}
LuaJijiang = sgs.CreateTriggerSkill{
	name = "LuaJijiang$",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardAsked}, 
	view_as_skill = LuaJijiangVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local pattern = data:toString()
		if pattern == "slash" then 
			local lieges = room:getLieges("shu", player)
			if not lieges:isEmpty() then
				if room:askForSkillInvoke(player, self:objectName()) then
					local tohelp = sgs.QVariant()
					tohelp:setValue(player)
					local prompt = string.format("@jijiang-slash:%s", player:objectName())
					for _,liege in sgs.qlist(lieges) do
						local slash = room:askForCard(liege, "slash", prompt, tohelp, sgs.CardResponsed, player)
						if slash then
							room:provide(slash)
							return true;
						end
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasLordSkill("LuaJijiang")
		end
		return false
	end
}
--[[
	技能名：极略
	相关武将：神·司马懿
	描述：弃一枚“忍”标记发动下列一项技能——“鬼才”、“放逐”、“完杀”、“制衡”、“集智”。
	状态：0224验证通过（主触发技隐藏，会导致鬼才改判log格式不对。。囧，不隐藏则log正常，但是有两个技能按钮。。修改name和视为相同提示重复技能）
]]--
LuaJilveCard = sgs.CreateSkillCard{
	name = "LuaJilveCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local choices=nil
		local choice=nil
		local tag = room:getTag("JilveWansha")
		if tag and tag:toBool() then
			if not source:hasUsed("ZhihengCard") then
				choice="zhiheng"
			end
		else
			if not source:hasUsed("ZhihengCard") then
				choices="zhiheng+wansha"
			else
				choice="wansha"
			end
		end
		if(choices) then
			choice = room:askForChoice(source, "LuaJilve", choices)
		end
		source:loseMark("@bear")
		if choice == "wansha" then
			room:acquireSkill(source, "wansha")
			room:setTag("JilveWansha", sgs.QVariant(true))
		else
			room:askForUseCard(source, "@zhiheng", "@jilve-zhiheng")
		end
	end
}
LuaJilveVS = sgs.CreateViewAsSkill{
	name = "LuaJilveVS",
	n = 0,
	view_as = function(self, cards)
		return LuaJilveCard:clone()
	end,
	enabled_at_play = function(self, player)
		if (not player:hasInnateSkill("wansha")) and player:hasSkill("wansha") and player:hasUsed("ZhihengCard") then
			return false
		else
			return player:getMark("@bear") > 0
		end
	end
}
LuaJilve = sgs.CreateTriggerSkill{
	name = "#LuaJilve",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponsed, sgs.AskForRetrial, sgs.Damaged},
	view_as_skill = LuaJilveVS,
	on_trigger = function(self, event, player, data)
		player:setMark("JilveEvent", event)
		local room=player:getRoom() 
		if event == sgs.CardUsed or event == sgs.CardResponsed then
			local card = nil
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toResponsed().m_card
			end
			if card:isNDTrick() then
				if not player:hasSkill("jizhi") then
					if player:askForSkillInvoke("LuaJilve", data) then
						player:loseMark("@bear")
						player:drawCards(1)
					end
				end
			end
		elseif event == sgs.AskForRetrial then
			local judge=data:toJudge()
			if not player:isKongcheng() then
				if not player:hasSkill("guicai") then
					local prompt="@jilve-guicai:"..judge.who:objectName()..":"..self:objectName()..":"..judge.reason..":"..judge.card:getEffectIdString()
					local card=room:askForCard(player, "@guicai",prompt, data, sgs.Card_MethodResponse, judge.who, true)
					if card then
						room:broadcastSkillInvoke("jilve", 1)
						player:loseMark("@bear")
						room:retrial(card,player,judge,self:objectName())
					end
				end
			end		
		elseif event == sgs.Damaged then
			if not player:hasSkill("fangzhu") then
				local card=room:askForUseCard(player, "@@fangzhu", "@jilve-fangzhu")
				if card then
					player:loseMark("@bear")
					room:broadcastSkillInvoke("jilve",2);
				end
			end
		end
		player:setMark("JilveEvent", 0)
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				return target:getMark("@bear") > 0
			end
		end
		return false
	end
}
LuaJilveClear = sgs.CreateTriggerSkill{
	name = "#LuaJilveClear",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "wansha")
		room:removeTag("JilveWansha")
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) and target:isAlive() then
				if target:getPhase() == sgs.Player_NotActive then
					local room = sgs.Sanguosha:currentRoom()
					local tag = room:getTag("JilveWansha")
					if tag then
						return tag:toBool()
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：军威
	相关武将：☆SP·甘宁
	描述：回合结束阶段开始时，你可以将三张“锦”置入弃牌堆。若如此做，你须指定一名角色并令其选择一项：1.亮出一张【闪】，然后由你交给任意一名角色。2.该角色失去1点体力，然后由你选择将其装备区的一张牌移出游戏。在该角色的回合结束后，将以此法移出游戏的装备牌移回原处。
	状态：尚未验证 (原有bug:（若原位置有其他装备牌，把移出游戏的装备牌移回原处时出错。）)
]]--
LuaJunwei = sgs.CreateTriggerSkill{
	name = "LuaJunwei", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if player:getPile("brocade"):length() >= 3 then
				if player:askForSkillInvoke(self:objectName()) then
					local brocade = player:getPile("brocade")
					for i = 0, 2, 1 do
						local card_id = 0
						room:fillAG(brocade, player)
						if brocade:length() == 3 - i then
							card_id = brocade:at(0)
						else
							card_id = room:askForAG(player, brocade, false, self:objectName())
						end
						player:invoke("clearAG")
						brocade:removeOne(card_id)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
						local card = sgs.Sanguosha:getCard(card_id)
						room:throwCard(card, reason, nil)
					end
					local list = room:getAllPlayers()
					local target = room:askForPlayerChosen(player, list, self:objectName())
					local ai_data = sgs.QVariant()
					ai_data:setValue(player)
					local card = room:askForCard(target, ".junwei", "@junwei-show", ai_data, sgs.NonTrigger)
					if card then
						local show_id = card:getEffectiveId()
						room:showCard(target, show_id)
						local receiver = room:askForPlayerChosen(player, list, "junweigive")
						if receiver:objectName() ~= target:objectName() then
							receiver:obtainCard(card)
						end
					else
						room:loseHp(target, 1)
						if target:isAlive() then
							if target:hasEquip() then
								local card_id = room:askForCardChosen(player, target, "e", self:objectName())
								target:addToPile("junwei_equip", card_id)
							end
						end
					end
				end
			end
		end
		return false
	end
}
LuaJunweiGot = sgs.CreateTriggerSkill{
	name = "#LuaJunweiGot", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			local jw_equip = player:getPile("junwei_equip")
			if jw_equip:length() > 0 then
				local room = player:getRoom()
				for _,card_id in sgs.qlist(jw_equip) do
					local card = sgs.Sanguosha:getCard(card_id)
					local equip_index = -1
					local equip = card:getRealCard()
					if equip:isKindOf("Weapon") then
						equip_index = 0
					elseif equip:isKindOf("Armor") then
						equip_index = 1
					elseif equip:isKindOf("DefensiveHorse") then
						equip_index = 2
					elseif equip:isKindOf("OffensiveHorse") then
						equip_index = 3
					end
					local move1 = sgs.CardsMoveStruct()
					move1.card_ids:append(card_id)
					move1.to = player
					move1.to_place = sgs.Player_PlaceEquip
					move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName())
					local eqp = player:getEquip(equip_index)
					if eqp then
						local move2 = sgs.CardsMoveStruct()
						move2.card_ids:append(eqp:getId())
						move2.to = nil
						move2.to_place = sgs.Player_DiscardPile
						move2.reason = CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, player:objectName())
						room:moveCardsAtomic(move2, true)
					end
					room:moveCardsAtomic(move1, true)
				end
			end
		end
		return false;
	end, 
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：狂斧
	相关武将：国战·潘凤
	描述：每当你使用的【杀】对一名角色造成一次伤害后，你可以将其装备区里的一张牌弃置或置入你的装备区。 
	状态：尚未验证
]]--
function EquipInt(card) 
	local cardx = sgs.Sanguosha:getCard(card:getEffectiveId())
	if cardx:isKindOf("Weapon") then 
		return 0 
	elseif cardx:isKindOf("Armor") then 
		return 1
	elseif cardx:isKindOf("DefensiveHorse") then 
		return 2 
	elseif cardx:isKindOf("OffensiveHorse") then 
		return 3 
	else 
		return -1  
	end
end
gzkuangfu=sgs.CreateTriggerSkill{
	name = "gzkuangfu",
	events = {sgs.Damage},	
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card == nil or not damage.card:isKindOf("Slash") or damage.to:getEquips():isEmpty() then 
			return 
		end
		if damage.chain or damage.transfer then 
			return 
		end
		if not player:askForSkillInvoke(self:objectName(), data) then 
			return 
		end
		local card_id = room:askForCardChosen(player, damage.to, "e", self:objectName())
		local card = sgs.Sanguosha:getCard(card_id)
		local index = EquipInt(card)
		local choicelist={}
		table.insert(choicelist, "throw")
		if (index >-1 and player:getEquip(index)==nil) then 
			table.insert(choicelist,"move") 
		end
		local option = room:askForChoice(player, self:objectName(), table.concat(choicelist,"+"))		  
		if option == "move" then 
			room:moveCardTo(card, player, sgs.Player_PlaceEquip, true)
		else 
			room:throwCard(card, damage.to, player) 
		end
		return
	end,
}
--[[
	技能名：龙胆
	相关武将：标准·赵云、☆SP·赵云、翼·赵云
	描述：你可以将一张【杀】当【闪】，一张【闪】当【杀】使用或打出。
	状态：验证失败（currentRoomState错误，认为sgs.Sanguosha是nil）
]]--
LuaLongdan = sgs.CreateViewAsSkill{
	name = "LuaLongdan",
	n = 1,
	view_filter = function(self, selected, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local state = room:getRoomState()
		local reason = state:getCurrentCardUseReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return to_select:isKindOf("Jink")
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			local pattern = state:getCurrentCardUsePattern()
			if pattern == "slash" then
				return to_select:isKindOf("Jink")
			elseif pattern == "jink" then
				return to_select:isKindOf("Slash")
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			if card:isKindOf("Slash") then
				local jink = sgs.Sanguosha:cloneCard("jink", suit, point)
				jink:addSubcard(card)
				jink:setSkillName(self:objectName())
				return jink
			elseif card:isKindOf("Jink") then
				local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
				slash:addSubcard(card)
				slash:setSkillName(self:objectName())
				return slash
			end
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "jink") or (pattern == "slash")
	end
}
--[[
	技能名：龙魂
	相关武将：神·赵云
	描述：你可以将同花色的X张牌按下列规则使用或打出：红桃当【桃】，方块当具火焰伤害的【杀】，梅花当【闪】，黑桃当【无懈可击】（X为你当前的体力值且至少为1）。
	状态：验证失败（currentRoomState()结果为空值）
]]--
LuaLonghun = sgs.CreateViewAsSkill{
	name = "LuaLonghun", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		local hp = sgs.Self:getHp()
		local n = math.max(1, hp)
		if #selected < n then
			if n > 1 then
				if #selected > 0 then
					local suit = selected[1]:getSuit()
					return to_select:getSuit() == suit
				end
			end
			local state = sgs.Sanguosha:currentRoomState()
			local reason = state:getCurrentCardUseReason()
			if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
				if sgs.Self:isWounded() then
					return card:getSuit() == sgs.Card_Heart
				elseif sgs.Slash_IsAvailable(sgs.Self) then
					return card:getSuit() == sgs.Card_Diamond
				else
					return false
				end
			elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
				local pattern = state:getCurrentCardUsePattern()
				if pattern == "jink" then
					return card:getSuit() == sgs.Card_Club
				elseif pattern == "nullification" then
					return card:getSuit() == sgs.Card_Spade
				elseif pattern == "peach" or pattern == "peach+analeptic" then
					return card:getSuit() == sgs.Card_Heart
				elseif pattern == "slash" then
					return card:getSuit() == sgs.Card_Diamond
				end
			end
		end
		return false
	end, 
	view_as = function(self, cards)
		local hp = sgs.Self:getHp()
		local n = math.max(1, hp)
		if #cards == n then
			local card = cards[1]
			local new_card = nil
			local suit = card:getSuit()
			local number = 0
			if #cards == 1 then
				number = card:getNumber()
			end
			if suit == sgs.Card_Spade then
				new_card = sgs.Sanguosha:cloneCard("nullification", suit, number)
			elseif suit == sgs.Card_Heart then
				new_card = sgs.Sanguosha:cloneCard("peach", suit, number)
			elseif suit == sgs.Card_Club then
				new_card = sgs.Sanguosha:cloneCard("jink", suit, number)
			elseif suit == sgs.Card_Diamond then
				new_card = sgs.Sanguosha:cloneCard("fire_slash", suit, number)
			end
			if new_card then
				new_card:setSkillName(self:objectName())
				for _,cd in pairs(cards) do
					new_card:addSubcard(cd)
				end
			end
			return new_card
		end
	end, 
	enabled_at_play = function(self, player)
		if player:isWounded() then
			return true
		elseif sgs.Slash_IsAvailable(player) then
			return true
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		if pattern == "slash" then
			return true
		elseif pattern == "jink" then
			return true
		elseif pattern:contains("peach") then
			return true
		elseif pattern == "nullification" then
			return true
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		local hp = player:getHp()
		local n = math.max(1, hp)
		local count = 0
		local cards = player:getHandcards()
		for _,card in sgs.qlist(cards) do
			if card:objectName() == "nullification" then
				return true
			end
			if card:getSuit() == sgs.Card_Spade then
				count = count + 1
			end
		end
		cards = player:getEquips()
		for _,card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Spade then
				count = count + 1
			end
		end
		return count >= n
	end
}
--[[
	技能名：龙魂
	相关武将：测试·高达一号
	描述：你可以将一张牌按以下规则使用或打出：♥当【桃】；♦当火【杀】；♠当【无懈可击】；♣当【闪】。回合开始阶段开始时，若其他角色的装备区内有【青釭剑】，你可以获得之。 
	状态：尚未验证
]]--
LuaXNosLonghun = sgs.CreateViewAsSkill{
	name = "LuaXNosLonghun", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if #selected < 1 then
			local state = sgs.Sanguosha:currentRoomState()
			local reason = state:getCurrentCardUseReason()
			local suit = to_select:getSuit()
			if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
				if sgs.Self:isWounded() then
					if suit == sgs.Card_Heart then
						return true
					end
				end
				if sgs.Slash_IsAvailable(sgs.Self) then
					if suit == sgs.Card_Diamond then
						local weapon = sgs.Self:getWeapon()
						if weapon and to_select:getEffectiveId() == weapon:getId() then
							if to_select:objectName() == "crossbow" then
								return sgs.Self:canSlashWithoutCrossbow()
							else
								return true
							end
						end
					else
						return false
					end
				end
			elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
				local pattern = state:getCurrentCardUsePattern()
				if pattern == "jink" then
					return suit == sgs.Card_Club
				elseif pattern == "nullification" then
					return suit == sgs.Card_Spade
				elseif pattern == "peach" or pattern == "peach+analeptic" then
					return suit == sgs.Card_Heart
				elseif pattern == "slash" then
					return suit == sgs.Card_Diamond
				end
			end
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local new_card = nil
			local suit = card:getSuit()
			local number = card:getNumber()
			if suit == sgs.Card_Spade then
				new_card = sgs.Sanguosha:cloneCard("nullification", suit, number)
			elseif suit == sgs.Card_Heart then
				new_card = sgs.Sanguosha:cloneCard("peach", suit, number)
			elseif suit == sgs.Card_Club then
				new_card = sgs.Sanguosha:cloneCard("jink", suit, number)
			elseif suit == sgs.Card_Diamond then
				new_card = sgs.Sanguosha:cloneCard("fire_slash", suit, number)
			end
			if new_card then
				new_card:setSkillName(self:objectName())
				new_card:addSubcard(card)
			end
			return new_card
		end
	end, 
	enabled_at_nullification = function(self, player)
		local cards = player:getHandcards()
		for _,card in sgs.qlist(cards) do
			if card:objectName() == "nullification" then
				return true
			end
			if card:getSuit() == sgs.Card_Spade then
				return true
			end
		end
		cards = player:getEquips()
		for _,card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Spade then
				return true
			end
		end
		return false
	end
}
LuaXDuojian = sgs.CreateTriggerSkill{
	name = "#LuaXDuojian",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local others = room:getOtherPlayers(player)
			for _,p in sgs.qlist(others) do
				local weapon = p:getWeapon()
				if weapon and weapon:objectName() == "QinggangSword" then
					if room:askForSkillInvoke(player, self:objectName()) then
						player:obtainCard(weapon)
					end
				end
			end
		end			
		return false	 
	end
}
--[[
	技能名：疠火
	相关武将：二将成名·程普
	描述：你可以将一张普通【杀】当火【杀】使用，若以此法使用的【杀】造成了伤害，在此【杀】结算后你失去1点体力；你使用火【杀】时，可以额外选择一个目标。
	状态：验证通过
]]--
LuaLihuoVS = sgs.CreateViewAsSkill{
	name = "LuaLihuo", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:objectName() == "slash"
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local number = card:getNumber()
			local id = card:getId()
			local acard = sgs.Sanguosha:cloneCard("fire_slash", suit, number)
			acard:addSubcard(id)
			acard:setSkillName(self:objectName())
			return acard
		end
	end, 
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
LuaLihuo = sgs.CreateTriggerSkill{
	name = "LuaLihuo",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageDone, sgs.CardFinished}, 
	view_as_skill = LuaLihuoVS, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageDone then
			local damage = data:toDamage()
			local card = damage.card
			if card then
				if card:isKindOf("Slash") then
					if card:getSkillName() == self:objectName() then
						room:setTag("Invokelihuo", sgs.QVariant(true))
					end
				end
			end
		elseif event == sgs.CardFinished then
			if player:hasSkill(self:objectName()) then
				local tag = room:getTag("Invokelihuo")
				if tag:toBool() then
					room:setTag("Invokelihuo", sgs.QVariant(false))
					room:loseHp(player, 1)
				end
			end
		end
		return false;
	end, 
	can_trigger = function(self, target)
		return target ~= nil
	end
}
LuaLihuoTarget = sgs.CreateTargetModSkill{
	name = "#LuaLihuoTarget",
	pattern = "FireSlash",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		else
			return 0
		end
	end,
}
--[[
	技能名：连理
	相关武将：倚天·夏侯涓
	描述：回合开始阶段开始时，你可以选择一名男性角色，你和其进入连理状态直到你的下回合开始：该角色可以帮你出闪，你可以帮其出杀 
	状态：验证失败
]]--
LuaXLianliCard = sgs.CreateSkillCard{
	name = "LuaXLianliCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return to_select:isMale()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		if source:getMark("@tied") == 0 then
			source:gainMark("@tied")
		end
		if target:getMark("@tied") == 0 then
			local players = room:getOtherPlayers(source)
			for _,player in sgs.qlist(players) do
				if player:getMark("@tied") > 0 then
					player:loseMark("@tied")
					break
				end
			end
			target:gainMark("@tied")
		end
	end
}
LuaXLianliStart = sgs.CreateTriggerSkill{
	name = "#LuaXLianliStart",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.GameStart},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local players = room:getOtherPlayers(player)
		for _,p in sgs.qlist(players) do
			if p:isMale() then
				room:attachSkillToPlayer(p, "LuaXLianliSlash")
			end
		end
	end
}
LuaXLianliSlashCard = sgs.CreateSkillCard{
	name = "LuaXLianliSlashCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return sgs.Self:canSlash(to_select)
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local room = source:getRoom()
		local dest = room:findPlayerBySkillName("LuaXLianli")
		if dest then
			local slash = room:askForCard(dest, "slash", "@lianli-slash")
			if slash then
				source:invoke("addHistory", "Slash")
				room:cardEffect(slash, source, effect.to)
				return
			end
		end
	end
}
LuaXLianliSlashVS = sgs.CreateViewAsSkill{
	name = "LuaXLianliSlash", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXLianliSlashCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:getMark("@tied") > 0 then
			return sgs.Slash_IsAvailable(player)
		end
		return false
	end
}
LuaXLianliSlash = sgs.CreateTriggerSkill{
	name = "#LuaXLianliSlash",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardAsked},  
	on_trigger = function(self, event, player, data) 
		local pattern = data:toString()
		if pattern == "slash" then
			if player:askForSkillInvoke("LuaLianliSlash", data) then
				local xiahoujuan = room:findPlayerBySkillName("LuaXLianli")
				if xiahoujuan then
					local slash = room:askForCard(xiahoujuan, "slash", "@lianli-slash")
					if slash then
						room:provide(slash)
						return true
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:getMark("@tied") > 0 then
				return not target:hasSkill("LuaXLianli")
			end
		end
		return false
	end
}
LuaXLianliJink = sgs.CreateTriggerSkill{
	name = "LuaXLianliJink",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardAsked},  
	on_trigger = function(self, event, player, data) 
		local pattern = data:toString()
		if pattern == "jink" then
			if player:askForSkillInvoke("LuaXLianliJink", data) then
				local players = room:getOtherPlayers(player)
				for _,p in sgs.qlist(players) do
					if p:getMark("@tied") > 0 then
						local jink = room:askForCard(p, "jink", "@lianli-jink")
						if jink then
							room:provide(jink)
							return true
						end
						break
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) and target:isAlive() then
				return target:getMark("@tied") > 0
			end
		end
		return false
	end
}
LuaXLianliVS = sgs.CreateViewAsSkill{
	name = "LuaXLianliVS", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXLianliCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXLianli"
	end
}
LuaXLianli = sgs.CreateTriggerSkill{
	name = "LuaXLianli",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	view_as_skill = LuaXLianliVS, 
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local used = room:askForUseCard(player, "@@LuaXLianli", "@lianli-card")
			if used then
				local spouse = nil
				local alives = room:getAlivePlayers()
				for _,p in sgs.qlist(alives) do
					if p:getMark("@tied") > 0 then
						if p:objectName() ~= player:objectName() then
							spouse = p
							break
						end
					end
				end
				if spouse then
					local kingdom = spouse:getKingdom()
					if player:getKingdom() ~= kingdom then
						--离迁：当你处于连理状态时，势力与连理对象的势力相同
						room:setPlayerProperty(player, "kingdom", sgs.QVariant(kingdom)) 
					end
				end
			else
				if player:getKingdom() ~= "wei" then
					--离迁：当你处于未连理状态时，势力为魏 
					room:setPlayerProperty(player, "kingdom", sgs.QVariant("wei")) 
				end
				local players = room:getAllPlayers()
				for _,p in sgs.qlist(players) do
					if p:getMark("@tied") > 0 then
						p:loseMark("@tied")
					end
				end
			end
		end
		return false
	end
}
--离迁：清除效果
LuaXLiqianClear = sgs.CreateTriggerSkill{
	name = "#LuaXLiqianClear",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data) 
		if player then
			local players = room:getAllPlayers()
			for _,p in sgs.qlist(players) do
				if p:getMark("@tied") > 0 then
					p:loseMark("@tied")
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then 
			return target:hasSkill(self:objectName())
		end
		return false
	end
}
--[[
	技能名：秘计
	相关武将：二将成名·王异
	描述：回合开始/结束阶段开始时，若你已受伤，你可以进行一次判定，若判定结果为黑色，你观看牌堆顶的X张牌（X为你已损失的体力值），然后将这些牌交给一名角色。
	状态：验证失败（mid出错无法给牌）
]]--
LuaMiji = sgs.CreateTriggerSkill{
	name = "LuaMiji",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:isWounded() then
			local phase = player:getPhase()
			if phase == sgs.Player_Start or phase == sgs.Player_Finish then
				if player:askForSkillInvoke(self:objectName()) then
					local room = player:getRoom()
					local judge = sgs.JudgeStruct()
					judge.pattern = sgs.QRegExp("(.*):(club|spade):(.*)")
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then
						local x = player:getLostHp()
						player:drawCards(x)
						local playerlist = room:getAllPlayers()
						local target = room:askForPlayerChosen(player, playerlist, self:objectName())
						local count = player:getHandcardNum() - x
						local handcards = player:getHandcards()
						local miji_cards = handcards:mid(count)
						for _,card in sgs.qlist(miji_cards) do
							room:obtainCard(target, card, nil, false)
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：明哲
	相关武将：新3V3·诸葛瑾
	描述：你的回合外，当你因使用、打出或弃置而失去一张红色牌时，你可以摸一张牌。 
	状态：0224验证通过
]]--
require ("bit")
LuaXMingzhe = sgs.CreateTriggerSkill{
	name = "LuaXMingzhe",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() ~= sgs.Player_NotActive then
			return false
		end
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() then
			if event == sgs.BeforeCardsMove then
				local reason = move.reason
				local basic = bit:_and(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
				local flag = (basic == sgs.CardMoveReason_S_REASON_USE)
				flag = flag or (basic == sgs.CardMoveReason_S_REASON_DISCARD)
				flag = flag or (basic == sgs.CardMoveReason_S_REASON_RESPONSE)
				if flag then
					local card
					local i = 0
					for _,card_id in sgs.qlist(move.card_ids) do
						card = sgs.Sanguosha:getCard(card_id)
						if card:isRed() then
							local places = move.from_places:at(i)
							if places == sgs.Player_PlaceHand or places == sgs.Player_PlaceEquip then
								player:addMark(self:objectName())
							end
						end
						i = i + 1
					end
				end
			else
				local count = player:getMark(self:objectName())
				for i=1, count, 1 do
					if player:askForSkillInvoke(self:objectName(), data) then
						player:drawCards(1)
					else
						break
					end
				end
				player:setMark(self:objectName(), 0)
			end
		end
		return false
	end
}
--[[
	技能名：倾城
	相关武将：国战·邹氏
	描述：出牌阶段，你可以弃置一张装备牌，令一名其他角色的一项武将技能无效，直到其下回合开始。 
	状态：尚未完成
]]--
LuaXQingchengCard = sgs.CreateSkillCard{
	name = "LuaXQingchengCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local room = effect.from:getRoom()
		local skill_list = ""
		for _,skill in sgs.qlist(effect.to:getVisibleSkillList()) do
			if not string.find(skill_list, skill:objectName()) then
				if not skill:inherits("SPConvertSkill") then
					if not skill:isAttachedLordSkill() then
						skill_list = skill_list.."+"..skill:objectName()
					end
				end
			end
		end
		local skill_qc;
		if skill_list ~= "" then
			skill_list = string.sub(skill_list, 2)
			local data_for_ai = sgs.QVariant()
			data_for_ai:setValue(effect.to)
			skill_qc = room:askForChoice(effect.from, "LuaXQingcheng", skill_list, data_for_ai)
		end
		room:throwCard(self, effect.from)
		if skill_qc ~= "" then
			--[[以下代码含有QStringList等无法转化
			QStringList Qingchenglist = effect.to->tag["Qingcheng"].toStringList();
			Qingchenglist << skill_qc;
			effect.to->tag["Qingcheng"] = QVariant::fromValue(Qingchenglist);
			room->setPlayerMark(effect.to, "Qingcheng" + skill_qc, 1);
			]]--
			local cards = effect.to:getCards("he")
			room:filterCards(effect.to, cards, true)
		}
	end
}
LuaXQingchengVS = sgs.CreateViewAsSkill{
	name = "LuaXQingcheng", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if to_select:isKindOf("EquipCard") then
			return not sgs.Self:isJilei(to_select)
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local first = LuaXQingchengCard:clone()
			first:addSubcard(cards[1])
			first:setSkillName(self:objectName())
			return first
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:isNude()
	end
}
LuaXQingcheng = sgs.CreateTriggerSkill{
	name = "LuaXQingcheng",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	view_as_skill = LuaXQingchengVS, 
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_RoundStart then
			--[[以下C++代码含有QStringList无法转化
			QStringList Qingchenglist = player->tag["Qingcheng"].toStringList();
			foreach (QString skill_name, Qingchenglist) {
				room->setPlayerMark(player, "Qingcheng" + skill_name, 0);
			}
			player->tag.remove("Qingcheng");
			]]--
			local cards = player:getCards("he")
			room:filterCards(player, cards, false);
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end, 
	priority = 4
}
--[[
	技能名：神速
	相关武将：风·夏侯渊
	描述：你可以选择一至两项：1.跳过你的判定阶段和摸牌阶段。2.跳过你的出牌阶段并弃置一张装备牌。你每选择一项，视为对一名其他角色使用一张【杀】（无距离限制）。
	状态：0224中测试时不能无视距离，1111无此问题，疑似源码失误，以下代码适用于0224，要在旧版本中使用，请去掉神速2时askForUseCard的最后一个参数
]]--
LuaShensuCard = sgs.CreateSkillCard{
	name = "LuaShensuCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return sgs.Self:canSlash(to_select,nil,false)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		local use = sgs.CardUseStruct()
		use.card = slash
		use.from = source
		for i=1,#targets,1 do
			use.to:append(targets[i])
		end
		room:useCard(use)
	end
}
LuaShensuVS = sgs.CreateViewAsSkill{
	name = "LuaShensuVS",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Self:hasFlag("shensu2") then
			if #selected == 0 then
				return to_select:isKindOf("EquipCard")
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return LuaShensuCard:clone()
		end
		if #cards == 1 then
			local card = LuaShensuCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@shensu") == 1
	end
}
LuaShensu = sgs.CreateTriggerSkill{
	name = "#LuaShensu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	view_as_skill = LuaShensuVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		local nextphase = change.to
		if nextphase == sgs.Player_Judge then
			if not player:isSkipped(sgs.Player_Judge) then
				if not player:isSkipped(sgs.Player_Draw) then
					if room:askForUseCard(player, "@@shensu1", "@shensu1", 1) then
						player:skip(sgs.Player_Judge)
						player:skip(sgs.Player_Draw)
					end
				end
			end
		elseif nextphase == sgs.Player_Play then
			if not player:isSkipped(sgs.Player_Play) then
				room:setPlayerFlag(player,"shensu2")
				if room:askForUseCard(player, "@@shensu2", "@shensu2",2,sgs.Card_MethodDiscard) then
					player:skip(sgs.Player_Play)
				end
			end
		end
		return false
	end
}
--[[
	技能名：死谏
	相关武将：国战·田丰
	描述：每当你失去最后的手牌后，你可以弃置一名其他角色的一张牌。 
	状态：0224验证通过
]]--
LuaXSijianCard = sgs.CreateSkillCard{
	name = "LuaXSijianCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			if not to_select:isNude() then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, effect) 
		local room = effect.from:getRoom()
		local card_id = room:askForCardChosen(effect.from, effect.to, "he", self:objectName())
		room:throwCard(card_id, effect.to, effect.from)
	end
}
LuaXSijianVS = sgs.CreateViewAsSkill{
	name = "LuaXSijian", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXSijianCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXSijian"
	end
}
LuaXSijian = sgs.CreateTriggerSkill{
	name = "LuaXSijian",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},  
	view_as_skill = LuaXSijianVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local source = move.from
		if source and source:objectName() == player:objectName() then
			if move.from_places:contains(sgs.Player_PlaceHand) then
				if event == sgs.BeforeCardsMove then
					for _,id in sgs.qlist(player:handCards()) do
						if not move.card_ids:contains(id) then
							return false
						end
					end
					player:addMark(self:objectName())
				else
					if player:getMark(self:objectName()) > 0 then
						player:removeMark(self:objectName())
						local can_invoke = false
						local other_players = room:getOtherPlayers(player)
						for _,p in sgs.qlist(other_players) do
							if not p:isNude() then
								can_invoke = true
								break
							end
						end
						if can_invoke then
							room:askForUseCard(player, "@@LuaXSijian", "@sijian-discard")
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：探虎
	相关武将：☆SP·吕蒙
	描述：出牌阶段，你可以与一名其他角色拼点。若你赢，你获得以下技能直到回合结束：你与该角色的距离为1.你对该角色使用的非延时类锦囊不能被【无懈可击】抵消，每阶段限一次。
	状态：验证失败（可以拼点与锁定距离，但不能禁止无懈可击）
]]--
LuaTanhuCard = sgs.CreateSkillCard{
	name = "LuaTanhuCard", 
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local dest = targets[1]
		local success = source:pindian(dest, "tanhu", self)
		if success then
			room:setPlayerFlag(dest, "TanhuTarget")
			room:setFixedDistance(source, dest, 1)
		end
	end
}
LuaTanhu = sgs.CreateViewAsSkill{
	name = "LuaTanhu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if #cards == 1 then
			local newCard = LuaTanhuCard:clone()
			newCard:addSubcard(cards[1])
			return newCard
		end
	end, 
	enabled_at_play = function(self, player)
		if not player:hasUsed("#LuaTanhuCard") then
			return not player:isKongcheng()
		end
		return false
	end
}
LuaTanhuClear = sgs.CreateTriggerSkill{
	name = "#LuaTanhu", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			local players = room:getAlivePlayers()
			for _,p in sgs.qlist(players) do
				if p:hasFlag("TanhuTarget") then	
					room:setPlayerFlag(p, "-TanhuTarget")
					room:setFixedDistance(player, p, -1)
				end
			end
		end
		return false
	end
}
--[[
	技能名：伪帝（锁定技）
	相关武将：SP·袁术
	描述：你拥有当前主公的主公技。
	状态：验证失败(激将、危殆失败)
]]--
LuaWeidiCard = sgs.CreateSkillCard{
	name = "LuaWeidiCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		local lord = room:getLord()
		local choices = {}
		if source:hasLordSkill("jijiang") then
			if lord:hasLordSkill("jijiang") then
				if sgs.Slash_IsAvailable(source) then
					table.insert(choices, "jijiang")
				end
			end
		end
		if source:hasLordSkill("weidai") then
			if lord:hasLordSkill("weidai") then
				if sgs.Analeptic_IsAvailable(source) then
					table.insert(choices, "weidai")
				end
			end
		end
		if #choices > 0 then
			local choice = ""
			if #choices == 1 then
				choice = choices[1]
			else
				choice = room:askForChoice(source, "LuaWeidi", "jijiang+weidai")
			end
			if choice == "jijiang" then
				local targetlist = sgs.SPlayerList()
				local others = room:getOtherPlayers(source)
				for _,target in sgs.qlist(others) do
					if source:canSlash(target) then
						targetlist:append(target)
					end
				end
				local target = room:askForPlayerChosen(source, targetlist, "jijiang")
				if target then
					local jijiang = JijiangCard:clone()
					jijiang:setSkillName("LuaWeidi")
					local use = sgs.CardUseStruct()
					use.card = jijiang
					use.from = source
					use.to:append(target)
					room:useCard(use)
				end
			elseif choice == "weidai" then
				local weidai = WeidaiCard:clone()
				weidai:setSkillName("LuaWeidi")
				local use = sgs.CardUseStruct()
				use.card = weidai
				use.from = source
				room:useCard(use)
			end
		end
	end
}
LuaWeidiVS = sgs.CreateViewAsSkill{
	name = "LuaWeidi", 
	n = 0,
	view_as = function(self, cards) 
		return LuaWeidiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:hasLordSkill("jijiang") then
			if sgs.Slash_IsAvailable(player) then
				return true
			end
		end
		if player:hasLordSkill("weidai") then
			if sgs.Analeptic_IsAvailable(player) then
				return true
			end
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if player:hasLordSkill("jijiang") and pattern=="slash" then
			return true
		end
		if player:hasLordSkill("weidai") and string.find(pattenr, "analeptic") then
			return true
		end
	end,
}
LuaWeidi = sgs.CreateTriggerSkill{
	name = "LuaWeidi", 
	frequency = sgs.Skill_NotFrequent,		--因为要用视为技 
	events = {sgs.GameStart}, 
	view_as_skill = LuaWeidiVS, 
	priority = 2,
	on_trigger = function(self, event, player, data) 
		local lord = player:getRoom():getLord()
		for _,sk in sgs.qlist(lord:getVisibleSkillList()) do
			if sk:isLordSkill() then
				player:getRoom():acquireSkill(player, sk:objectName(), false)
			end
		end
		return false
	end
}
--[[
	技能名：武神（锁定技）
	相关武将：神·关羽
	描述：你的红桃手牌均视为【杀】；你使用红桃【杀】时无距离限制。
	状态：1221验证通过
]]--
LuaWushen = sgs.CreateFilterSkill{
	name = "LuaWushen",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local id = to_select:getEffectiveId()
		local place = room:getCardPlace(id)
		if to_select:getSuit() == sgs.Card_Heart then
			return place == sgs.Player_PlaceHand
		end
		return false
	end, 
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local slash = sgs.Sanguosha:cloneCard("WushenSlash", suit, point)
		slash:setSkillName(self:objectName())
		local id = card:getId()
		local vs_card = sgs.Sanguosha:getWrappedCard(id)
		vs_card:takeOver(slash)
		return vs_card
	end
}
--[[
	技能：骁果
	相关武将：国战·乐进
	描述：其他角色的回合结束阶段开始时，你可以弃置一张基本牌：若如此做，该角色可以弃置一张装备牌，否则受到你造成的1点伤害。 
	状态：0224验证通过
]]--
LuaXXiaoguo = sgs.CreateTriggerSkill{
	name = "LuaXXiaoguo",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			local yuejin = room:findPlayerBySkillName(self:objectName())
			if yuejin and yuejin:objectName() ~= player:objectName() then
				if not yuejin:isKongcheng() then
					if room:askForCard(yuejin, ".Basic", "@xiaoguo", sgs.QVariant(),sgs.Card_MethodDiscard)) then
						if not room:askForCard(player, ".Equip", "@xiaoguo-discard", sgs.QVariant(),sgs.Card_MethodDiscard) then
							local damage = sgs.DamageStruct()
							damage.card = nil
							damage.from = yuejin
							damage.to = player
							room:damage(damage)
						end
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end, 
	priority = 1
}
--[[
	技能：雄异（限定技）
	相关武将：国战·马腾
	描述：出牌阶段，你可以令你与任意数量的角色摸三张牌：若以此法摸牌的角色数不大于全场角色数的一半，你回复1点体力。
	状态：0224验证通过
]]--
LuaXXiongyiCard = sgs.CreateSkillCard{
	name = "LuaXXiongyiCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return true
	end,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets) 
		source:loseMark("@arise")
		local effect = sgs.CardEffectStruct()
		effect.from = source
		effect.card = self
		local flag = true
		if #targets > 0 then
			for _,target in pairs(targets) do
				if target:objectName() == source:objectName() then
					flag = false
				end
				effect.to = target
				self:onEffect(effect)
			end
		end
		if flag then
			effect.to = source
			self:onEffect(effect)
		end
	end,
	on_effect = function(self, effect) 
		effect.to:drawCards(3)
		effect.from:addMark("xiongyi")
	end
}
LuaXXiongyi = sgs.CreateViewAsSkill{
	name = "LuaXXiongyi", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXXiongyiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@arise") >= 1
	end
}
LuaXXiongyiStart = sgs.CreateTriggerSkill{
	name = "LuaXXiongyi",  
	frequency = sgs.Skill_Limited, 
	events = {sgs.GameStart},  
	view_as_skill = LuaXXiongyi, 
	on_trigger = function(self, event, player, data) 
		player:gainMark("@arise")
	end
}
LuaXXiongyiRecover = sgs.CreateTriggerSkill{
	name = "#LuaXXiongyi",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardFinished},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:getMark("@arise") < 1 then
			local count = player:getMark("xiongyi")
			if count > 0 then
				local alives = room:getAlivePlayers()
				if count <= (alives:length()) / 2 then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
					player:setMark("xiongyi", 0)
				end
			end
		end
		return false
	end
}
--[[
	技能名：修罗
	相关武将：SP·暴怒战神
	描述：回合开始阶段开始时，你可以弃置一张手牌，若如此做，你弃置你判定区里的一张与你弃置手牌同花色的延时类锦囊牌。
	状态：验证失败（pattern构造出错）
]]--
LuaXiuluo = sgs.CreateTriggerSkill{
	name = "LuaXiuluo", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local once_success = false
		repeat
			once_success = false
			if player:askForSkillInvoke(self:objectName()) then
				local card_id = room:askForCardChosen(player, player, "j", self:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				local suit_str = card:getSuitString()
				local prompt = string.format("@xiuluo:::%s", suit_str)
				string.upper(suit_str)
				local suit = string.sub(suit_str, 1, 1)
				local pattern = string.format(".%s", suit)
				if room:askForCard(player, pattern, prompt, sgs.QVariant(), sgs.CardDiscarded) then
					room:throwCard(card, nil)
					once_success = true
				end
			end
		until ((player:getCards("j"):length() == 0) or once_success)
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start then
					if not target:isKongcheng() then
						local ja = target:getJudgingArea()
						return ja:length() > 0
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：言笑
	相关武将：☆SP·大乔
	描述：出牌阶段，你可以将一张方块牌置于一名角色的判定区内，判定区内有“言笑”牌的角色下个判定阶段开始时，获得其判定区里的所有牌。
	状态：验证失败
]]--
LuaYanxiaoCard = sgs.CreateSkillCard{
	name = "LuaYanxiaoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local id = self:getEffectiveId()
		room:setCardFlag(id, "LuaYanxiaoCard") 
		local card = sgs.Sanguosha:getCard(id)
		card:setSkillName("LuaYanxiaoVS") 
		room:moveCardTo(self, target, sgs.Player_PlaceDelayedTrick, true)
	end
}
LuaYanxiaoVS = sgs.CreateViewAsSkill{
	name = "LuaYanxiaoVS",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Diamond
	end,	
	view_as = function(self, cards)
		if #cards == 1 then
			local sub_card = cards[1]
			local skill_card = LuaYanxiaoCard:clone()
			skill_card:addSubcard(sub_card)
			return skill_card
		end
	end
}
LuaYanxiaoTS = sgs.CreateTriggerSkill{
	name = "#LuaYanxiaoTS",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local myplayer = room:findPlayerBySkillName(self:objectName())
		if player:getPhase() == sgs.Player_Judge then
			local judging_cards = player:getJudgingArea()
			local judging_cards_ids = sgs.IntList()
			local can_invoke = false
			for _,card in sgs.qlist(judging_cards) do
				local id = card:getId()
				judging_cards_ids:append(id)
				if card:hasFlag("LuaYanxiaoCard") then 
					can_invoke = true
				end
			end
			if can_invoke then
				local move = sgs.CardsMoveStruct()
				move.card_ids = judging_cards_ids
				move.to = player
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, name)
				move.to_place = sgs.Player_PlaceHand
				room:moveCards(move, false)
			end
			
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}
--[[
	技能名：援护
	相关武将：SP·曹洪
	描述：回合结束阶段开始时，你可以将一张装备牌置于一名角色的装备区里，然后根据此装备牌的种类执行以下效果。
		武器牌：弃置与该角色距离为1的一名角色区域中的一张牌；
		防具牌：该角色摸一张牌；
		坐骑牌：该角色回复一点体力。
	状态：尚未验证(原有问题（各装备类型效果可实现，但技能卡的filter部分有问题导致装备区有同类装备时仍可发动技能）)
]]--
LuaYuanhuCard = sgs.CreateSkillCard{
	name = "LuaYuanhuCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			local id = self:getSubcards():first()
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("Weapon") then
				return not to_select:getEquip(0)
			elseif card:isKindOf("Armor") then
				return not to_select:getEquip(1)
			elseif card:isKindOf("DefensiveHorse") then
				return not to_select:getEquip(2)
			elseif card:isKindOf("OffensiveHorse") then
				return not to_select:getEquip(3)
			end
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "LuaYuanhu", "")
		room:moveCardTo(self, source, target, sgs.Player_PlaceEquip, reason)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if card:isKindOf("Weapon") then
			local targets = sgs.SPlayerList()
			local allplayers = room:getAllPlayers()
			for _,p in sgs.qlist(allplayers) do
				if target:distanceTo(p) == 1 then
					if not p:isAllNude() then
						targets:append(p)
					end
				end
			end
			if not targets:isEmpty() then
				local to_dismantle = room:askForPlayerChosen(source, targets, "LuaYuanhu")
				local card_id = room:askForCardChosen(source, to_dismantle, "hej", "LuaYuanhu")
				local to_throw = sgs.Sanguosha:getCard(card_id)
				room:throwCard(to_throw, to_dismantle, source)
			end
		elseif card:isKindOf("Armor") then
			target:drawCards(1)
		elseif card:isKindOf("Horse") then
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(target, recover)
		end
	end
}
LuaYuanhuVS = sgs.CreateViewAsSkill{
	name = "LuaYuanhuVS", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local first = LuaYuanhuCard:clone()
			first:addSubcard(cards[1]:getId())
			first:setSkillName(self:objectName())
			return first
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaYuanhu"
	end
}
LuaYuanhu = sgs.CreateTriggerSkill{
	name = "LuaYuanhu", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = LuaYuanhuVS, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if not player:isNude() then
				room:askForUseCard(player, "@@LuaYuanhu", "@yuanhu-equip")
			end
		end
		return false
	end
}
--
--0224焚心【】
LuaXFenxin = sgs.CreateTriggerSkill{
name = "LuaXFenxin",  
frequency = sgs.Skill_Limited, 
events = {sgs.BeforeGameOverJudge,sgs.GameStart},  
can_trigger = function(self, target)
return target~=nil end,
on_trigger = function(self, event, player, data) 
local room = player:getRoom()
if (event==sgs.BeforeGameOverJudge) then
local mode = room:getMode()
if string.sub(mode, -1)~="p" and string.sub(mode, -2) ~= "pd" and string.sub(mode, -2) ~= "pz" then return end
local damage = data:toDamageStar()
if damage==nil then return end
local killer = damage.from
if not killer or killer:isLord() or player:isLord() or player:getHp()>0 then return end
if not killer:hasSkill(self:objectName()) or killer:getMark("@burnheart")==0 then return end
room:setPlayerFlag(player, "FenxinTarget")						
local ai_data = sgs.QVariant()
ai_data:setValue(player)
if room:askForSkillInvoke(killer,self:objectName(),ai_data) then
--room:broadcastInvoke("animate", "lightbox:$FenxinAnimate")
--room:getThread():delay(1500)
killer:loseMark("@burnheart")
local role1 = killer:getRole()									
killer:setRole(player:getRole())								
room:setPlayerProperty(killer, "role", sgs.QVariant(killer:setRole(player:getRole())))									
player:setRole(role1)									
room:setPlayerProperty(player, "role", sgs.QVariant(role1))									
end										
room:setPlayerFlag(player, "-FenxinTarget")	
end			
if (event==sgs.GameStart and player:hasSkill(self:objectName())) then player:gainMark("@burnheart", 1)
return
end						
end,								 
}

---------------------------------下面是Fs的0610未验证更改-----------------------------

--[[
Fs在这里多说几句：大家可以对这部分技能尽情测试，要不然的话我一个人边写边测，累也累死了…………
突然发现大家测试的热情不是很高…………
]]
------------------------------------------------------------------------------
----------------------------[[暂时不会去验证的技能]]----------------------------
-------------------------------------------------------------------------------
--[[
	技能名：八阵（锁定技）
	相关武将：火·诸葛亮
	描述：若你的装备区没有防具牌，视为你装备着【八卦阵】。
	引用：LuaBazhen
	状态：0610未做（由于源码里将此技能处理成防具技能，所以在触发之前要把防具技能的一段代码写进去，包括无视防具等等）
]]--

--[[
	技能名：不屈
	相关武将：风·周泰
	描述：每当你扣减1点体力后，若你当前的体力值为0：你可以从牌堆顶亮出一张牌置于你的武将牌上，若此牌的点数与你武将牌上已有的任何一张牌都不同，你不会死亡；若出现相同点数的牌，你进入濒死状态。
	引用：LuaBuqu、LuaBuquRemove
	状态：0610未做（技能比较麻烦）
]]--
--[[
	技能名：蛊惑
	相关武将：风·于吉
	描述：你可以说出一张基本牌或非延时类锦囊牌的名称，并背面朝上使用或打出一张手牌。
		若无其他角色质疑，则亮出此牌并按你所述之牌结算。
		若有其他角色质疑则亮出验明：若为真，质疑者各失去1点体力；若为假，质疑者各摸一张牌。
		除非被质疑的牌为红桃且为真，此牌仍然进行结算，否则无论真假，将此牌置入弃牌堆。
	状态：0610没有做的打算
]]--


--[[
	技能名：仁德
	相关武将：标准·刘备
	描述：出牌阶段限一次，你可以将任意数量的手牌交给其他角色，若此阶段你给出的牌张数达到两张或更多时，你回复1点体力。
	引用：LuaRende
	状态：0610未做（更换技能）
]]--

--[[
	技能名：奇才（锁定技）
	相关武将：标准·黄月英
	描述：你使用锦囊牌无距离限制。你装备区里除坐骑牌外的牌不能被其他角色弃置。
	引用：LuaQicai
	状态：0610貌似无法实现（怀疑后半段被写入源码，因为在本来属于奇才的位置上的只有TargetMod）
]]--

--[[
	技能名：无双（锁定技）
	相关武将：标准·吕布、SP·最强神话、SP·暴怒战神
	描述：当你使用【杀】指定一名角色为目标后，该角色需连续使用两张【闪】才能抵消；与你进行【决斗】的角色每次需连续打出两张【杀】。
	引用：LuaWushuang
	状态：0610源码无法转化（没有对应QVariantList的SetValue接口）
]]--

--[[
	技能名：铁骑
	相关武将：标准·马超
	描述：每当你指定【杀】的目标后，你可以进行一次判定，若判定结果为红色，该角色不能使用【闪】对此【杀】进行响应。
	引用：
	状态：0610源码无法转化（没有对应QVariantList的SetValue接口）
]]--

--[[
	技能名：烈弓
	相关武将：风·黄忠
	描述：当你在出牌阶段内使用【杀】指定一名角色为目标后，以下两种情况，你可以令其不可以使用【闪】对此【杀】进行响应：
		1.目标角色的手牌数大于或等于你的体力值。2.目标角色的手牌数小于或等于你的攻击范围。
	引用：LuaLiegong
	状态：0610源码无法转化（没有对应QVariantList的SetValue接口）
]]--

--[[
	技能名：肉林（锁定技）
	相关武将：林·董卓
	当你使用【杀】指定一名女性角色为目标后，该角色需连续使用两张【闪】才能抵消；当你成为女性角色使用【杀】的目标后，你需连续使用两张【闪】才能抵消。
	引用：LuaRoulin
	状态：0610源码无法转化（没有对应QVariantList的SetValue接口）
]]--

--[[
	技能名：心战
	相关武将：一将成名·马谡
	描述：出牌阶段，若你的手牌数大于你的体力上限，你可以：观看牌堆顶的三张牌，然后亮出其中任意数量的红桃牌并获得之，其余以任意顺序置于牌堆顶。每阶段限一次。
	引用：LuaXinzhan
	状态：0610未完成（有部分代码不理解）
]]--
--[[ //部分代码如下：
        if (dummy->subcardsLength() > 0) {
            room->doBroadcastNotify(QSanProtocol::S_COMMAND_UPDATE_PILE, Json::Value(room->getDrawPile().length() + dummy->subcardsLength())); //应该是更新牌堆之类的吧，不明白，没有接口
            source->obtainCard(dummy);
            foreach (int id, dummy->getSubcards())
                room->showCard(source, id);
        }
]]


--[[
	技能名：悲歌
	相关武将：山·蔡文姬、SP·蔡文姬
	描述：每当一名角色受到【杀】造成的一次伤害后，你可以弃置一张牌，令其进行一次判定，
	判定结果为：红桃 该角色回复1点体力；方块 该角色摸两张牌；梅花 伤害来源弃置两张牌；黑桃 伤害来源将其武将牌翻面。
	引用：LuaBeige
	状态：0610未做（源码把判定结果在FinishJudge时机当中放入了judge.pattern中，而LUA没有这种处理方式）
	
	Fs说明：为什么要把判定结果放到judge.pattern里面啊，直接判断judge.card为什么不行…………
]]--

--[[
	技能名：断肠（锁定技）
	相关武将：山·蔡文姬、SP·蔡文姬
	描述：你死亡时，杀死你的角色失去其所有武将技能。
	引用：LuaDuanchang
	状态：0610未做
]]--


--[[
	技能名：急袭
	相关武将：山·邓艾
	描述：你可以将一张“田”当【顺手牵羊】使用。
	引用：LuaJixi
	状态：0610未完成（源码有一段修改card:onUse执行，LUA无此接口，只能替代运行）
]]--

--[[
	技能名：化身
	相关武将：山·左慈
	描述：所有人都展示武将牌后，你随机获得两张未加入游戏的武将牌，称为“化身牌”，选一张置于你面前并声明该武将的一项技能，你获得该技能且同时将性别和势力属性变成与该武将相同直到“化身牌”被替换。在你的每个回合开始时和结束后，你可以替换“化身牌”，然后（无论是否替换）你为当前的“化身牌”声明一项技能（你不可以声明限定技、觉醒技或主公技）。
	引用：LuaHuashen
	状态：0610未做
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
	技能名：极略
	相关武将：神·司马懿
	描述：弃一枚“忍”标记发动下列一项技能——“鬼才”、“放逐”、“完杀”、“制衡”、“集智”。
	状态：0610未完成（源码有一段修改card:onUse执行，LUA无此接口，只能替代运行）
]]--

--[[
	技能名：伪帝（锁定技）
	相关武将：SP·袁术、SP·台版袁术
	描述：你拥有当前主公的主公技。
	状态：验证失败
]]--

--[[
	技能名：落雁（锁定技）
	相关武将：SP·大乔&小乔
	描述：若你的武将牌上有“星舞牌”，你视为拥有技能“天香”和“流离”。
	状态：0610无法转换（源码getAcquiredSkills()为QSet类型，无法使用）
]]--

--[[
	技能名：傲才
	相关武将：SP·诸葛恪
	描述：你的回合外，每当你需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌，然后使用或打出其中一张该类别的基本牌。
	状态：0610未做
]]--

--[[
	技能名：奇策
	相关武将：二将成名·荀攸
	描述：出牌阶段限一次，你可以将你的所有手牌（至少一张）当任意一张非延时锦囊牌使用。
]]--

--[[
	技能名：疠火
	相关武将：二将成名·程普
	描述：你可以将一张普通【杀】当火【杀】使用，若以此法使用的【杀】造成了伤害，在此【杀】结算后你失去1点体力；你使用火【杀】时，可以额外选择一个目标。
	引用：LuaLihuo、LuaLihuoTarget
	状态：0610验证失败（QVariantList没有接口）
]]--

--[[
	技能名：言笑
	相关武将：☆SP·大乔
	描述：出牌阶段，你可以将一张方块牌置于一名角色的判定区内，判定区内有“言笑”牌的角色下个判定阶段开始时，获得其判定区里的所有牌。
	状态：验证失败
]]--
--[[
	技能名：狼顾
	相关武将：贴纸·司马昭
	描述：每当你受到1点伤害后，你可以进行一次判定，然后你可以打出一张手牌代替此判定牌：若如此做，你观看伤害来源的所有手牌，并弃置其中任意数量的与判定牌花色相同的牌。 
	状态：0610未做（狼顾也是和悲歌一样写到了judge.pattern里面…………真想不到那么有意思的地方竟然能存这种东西）
]]

--[[
	技能名：汉统
	相关武将：贴纸·刘协
	描述：弃牌阶段，你可以将你弃置的手牌置于武将牌上，称为“诏”。你可以将一张“诏”置入弃牌堆，然后你拥有并发动以下技能之一：“护驾”、“激将”、“救援”、“血裔”，直到当前回合结束。 
	引用：LuaXHantong、LuaXHantongKeep
	状态：0610未做
]]--


--[[
	技能名：陷阵
	相关武将：一将成名·高顺
	描述：出牌阶段，你可以与一名其他角色拼点。
		若你赢，你获得以下技能直到回合结束：你无视与该角色的距离及其防具；你对该角色使用【杀】时无次数限制。
		若你没赢，你不能使用【杀】，直到回合结束。每阶段限一次。
	引用：LuaXianzhen
	状态：0610未完成（源码有一段修改card:onUse执行，LUA无此接口，只能替代运行）
]]--

--[[
void XianzhenSlashCard::onUse(Room *room, const CardUseStruct &card_use) const{
    ServerPlayer *target = card_use.from->tag["XianzhenTarget"].value<PlayerStar>();
    if (target == NULL || target->isDead())
        return;

    if (!card_use.from->canSlash(target, NULL, false))
        return;

    room->askForUseSlashTo(card_use.from, target, "@xianzhen-slash");
}
]]

--[[
	技能名：排异
	相关武将：一将成名·钟会
	描述：出牌阶段，你可以将一张“权”置入弃牌堆，令一名角色摸两张牌，然后若该角色的手牌数大于你的手牌数，你对其造成1点伤害。每阶段限一次。
	引用：LuaPaiyi
	状态：0610未完成（源码有一段修改card:onUse执行，LUA无此接口，只能替代运行）
]]--

--[[
	技能名：完杀（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。
	引用：LuaWansha
	状态：0610未做（暂时没有想法）
]]--

--[[
	技能名：空城（锁定技）
	相关武将：标准·诸葛亮、测试·五星诸葛
	描述：若你没有手牌，你不能被选择为【杀】或【决斗】的目标。
	引用：LuaKongcheng
	状态：0610验证失败（0610的LUA禁止技接口暂时出现不明原因引起闪退）
]]--
LuaKongcheng = sgs.CreateProhibitSkill{
	name = "LuaKongcheng",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Slash") or card:isKindOf("Duel")) and to:isKongcheng()
	end,
}

--[[
	技能名：帷幕（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：你不能被选择为黑色锦囊牌的目标。
	引用：LuaWeimu
	状态：0610验证失败（0610的LUA禁止技接口暂时出现不明原因引起闪退）
]]--
LuaWeimu = sgs.CreateProhibitSkill{
	name = "LuaWeimu" ,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("TrickCard") or card:isKindOf("QiceCard"))
				and card:isBlack() and (card:getSkillName() ~= "guhuo") --特别注意蛊惑
	end
}

--[[
	技能名：谦逊（锁定技）
	相关武将：标准·陆逊、国战·陆逊
	描述：你不能被选择为【顺手牵羊】和【乐不思蜀】的目标。
	引用：LuaQianxun
	状态：0610验证失败（0610的LUA禁止技接口暂时出现不明原因引起闪退）
]]--
LuaQianxun = sgs.CreateProhibitSkill{
	name = "LuaQianxun", 
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Snatch") or card:isKindOf("Indulgence"))
	end
}

--[[
	技能名：同疾（锁定技）
	相关武将：标准·袁术
	描述：若你的手牌数大于你的体力值，且你在一名其他角色的攻击范围内，则其他角色不能被选择为该角色的【杀】的目标。
	引用：LuaTongji
	状态：0610验证失败（0610的LUA禁止技接口暂时出现不明原因引起闪退）
]]
LuaTongji = sgs.CreateProhibitSkill{
	name = "LuaTongji" ,
	is_prohibited = function(self, from, to, card)
		if card:isKindOf("Slash") then
			if to:hasSkill(self:objectName()) then return false end
			local rangefix = 0
			if card:isVirtualCard() then
				local subcards = card:getSubcards()
				if from:getWeapon() and subcards:contains(from:getWeapon():getId()) then
					local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
					rangefix = rangefix + weapon:getRange() - 1
				elseif from:getOffensiveHorse() and subcards:contains(self:getOffensiveHorse():getId()) then
					rangefix = rangefix + 1
				end
				for _, p in sgs.qlist(from:getSiblings()) do
					if p:hasSkill(self:objectName()) and (p:getHandcardNum() > p:getHp())
							and (from:distanceTo(p, rangefix) <= from:getAttackRange()) then
						return true
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：遗计
	相关武将：标准·郭嘉
	描述：每当你受到1点伤害后，你可以观看牌堆顶的两张牌，将其中一张交给一名角色，然后将另一张交给一名角色。
	引用：LuaYiji
	状态：0610验证失败
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
			--[[local _guojia = sgs.SPlayerList()
			_guojia:append(player)]]
			local yiji_cards = room:getNCards(2, false)
			local move = sgs.CardsMoveStruct()
			move.card_ids = yiji_cards
			move.from = nil
			move.from_place = sgs.Player_PlaceTable
			move.to = player
			move.to_place = sgs.Player_PlaceHand
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil)
			local moves = sgs.CardsMoveList()
			moves:append(move)
			--[[room->notifyMoveCards(true, moves, false, _guojia);
				room->notifyMoveCards(false, moves, false, _guojia); 
			]] --这是干什么用的……sanguosha.i里面没有这函数啊…………
			local origin_yiji = yiji_cards
			while room:askForYiji(player, yiji_cards, self:objectName(), true, false, true, -1, room:getAlivePlayers()) do
				local move = sgs.CardsMoveStruct()
				move.from = player
				move.from_place = sgs.Player_PlaceHand
				move.to = nil
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil)
				for _, id in sgs.qlist(origin_yiji) do
					if room:getCardPlace(id) ~= sgs.Player_DrawPile then
						move.card_ids:append(id)
						yiji_cards:removeOne(id)
					end
				end
				origin_yiji = yiji_cards
				local moves = sgs.CardsMoveList()
				moves:append(move)
				--[[room->notifyMoveCards(true, moves, false, _guojia);
					room->notifyMoveCards(false, moves, false, _guojia);
				]]
				if not player:isAlive() then return end
			end
			if not yiji_cards:isEmpty() then
				local move = sgs.CardsMoveStruct()
				move.from = player
				move.from_place = sgs.Player_PlaceHand
				move.to = nil
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil)
				move.card_ids = yiji_cards
				local moves = sgs.CardsMoveList()
				moves:append(move)
				--[[room->notifyMoveCards(true, moves, false, _guojia);
					room->notifyMoveCards(false, moves, false, _guojia);
				]]
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist(yiji_cards) do
					dummy:addSubcard(id)
				end
				player:obtainCard(dummy, false)
				--delete dummy; --LUA里面怎么delete……求指教
			end
		end
	end
}


--[[
	技能名：天香
	相关武将：风·小乔
	描述：每当你受到伤害时，你可以弃置一张红桃手牌，将此伤害转移给一名其他角色，然后该角色摸X张牌（X为该角色当前已损失的体力值）。
	引用：LuaTianxiang、LuaTianxiangDraw
	状态：0610未做（转移伤害清除qinggang mark没有接口）
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
			local qinggang = effect.from:getTag("Qinggang"):toStringList()
			if not (#qinggang == 0) then
				qinggang.removeOne(damage.card:toString())
				_qinggangmark = sgs.QVariant()
				_qinggangmark:setValue(qinggang)
				effect.from:setTag(_qinggangmark)
				--effect.from:setTag(sgs.QVariant(qinggang))
			end
		end
		damage.to = effect.to
		damage.transfer = true
		room:damage(damage) -- 未处理胆守
	end
}
LuaTianxiangVS = sgs.CreateViewAsSkill{
	name = "LuaTianxiang" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if #selected ~= 0 then return false end
		return (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Heart) and (not self:isJilei(to_select))
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
	技能名：誓仇（主公技、限定技）
	相关武将：☆SP·刘备
	描述：准备阶段开始时，你可以交给一名其他蜀势力角色两张牌。每当你受到伤害时，你将此伤害转移给该角色，然后该角色摸X张牌，直到其第一次进入濒死状态时。（X为伤害点数）
	引用：LuaShichou、LuaShichouDraw
	状态：0610验证失败（转移伤害清除qinggang mark没有接口）
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
		victim:getMark("@hate_to")
		room:setPlayerMark(victim, "LuaHateTo_" .. player:objectName(), 1)
		reason.m_playerId = victim:objectName()
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
				local qinggang = effect.from:getTag("Qinggang"):toStringList()
				if not (#qinggang == 0) then
					qinggang.removeOne(damage.card:toString())
					_qinggangmark = sgs.QVariant()
					_qinggangmark:setValue(qinggang)
					effect.from:setTag(_qinggangmark)
					--effect.from:setTag(sgs.QVariant(qinggang))
				end
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

-------------------------------------------------------------------------------
---------------------------------[[就这么多了]]---------------------------------
-------------------------------------------------------------------------------
-----------------------------[[下面是验证失败的技能]]---------------------------
-------------------------------------------------------------------------------

--[[
	技能名：裸衣
	相关武将：标准·许褚
	描述：摸牌阶段，你可以少摸一张牌，若如此做，你使用的【杀】或【决斗】（你为伤害来源时）造成的伤害+1，直到回合结束。
	引用：LuaLuoyiBuff、LuaLuoyi
	状态：0610验证失败（可以少摸一张牌，但是伤害不+1）
]]--
LuaLuoyiBuff = sgs.CreateTriggerSkill{
	name = "#LuaLuoyiBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.chain or damage.transfer or (not damage.by_user) then return false end
		local reason = damage.card
		if reason and (reason:isKindOf("Slash") or reason:isKindOf("Duel")) then
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("LuaLuoYi") and target:isAlive()
	end
}
LuaLuoyi = sgs.CreateTriggerSkill{
	name = "LuaLuoyi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DrawNCards}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local count = data:toInt()
		if count > 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				count = count - 1
				room:setPlayerFlag(player, "LuaLuoyi")
				data:setValue(count)
			end
		end
	end
}

--[[
	技能名：祸首（锁定技）
	相关武将：林·孟获
	描述：【南蛮入侵】对你无效；当其他角色使用【南蛮入侵】指定目标后，你是该【南蛮入侵】造成伤害的来源。
	引用：LuaSavageAssaultAvoid（与巨象一致，注意重复技能）、LuaHuoshou
	状态：0610验证失败（LuaHuoshou部分导致作弊受到伤害时服务器闪退）
]]--
LuaSavageAssaultAvoid = sgs.CreateTriggerSkill{
	name = "#LuaSavageAssaultAvoid",
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			return true
		else
			return false
		end
	end
}
LuaHuoshou = sgs.CreateTriggerSkill{
	name = "LuaHuoshou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.ConfirmDamage, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			if player:isAlive() and (player and player:isAlive() and player:hasSkill(self:objectName())) then
				local use = data:toCardUse()
				local card = use.card
				local source = use.from
				if card:isKindOf("SavageAssault") then
					if not source:hasSkill(self:objectName()) then
						local tag = sgs.QVariant()
						tag:setValue(player)
						room:setTag("HuoshouSource", tag)
					end
				end
			end
		elseif event == sgs.ConfirmDamage then
			local tag = room:getTag("HuoshouSource")
			if tag then
				local damage = data:toDamage()
				local card = damage.card
				if card then
					if card:isKindOf("SavageAssault") then
						local source = tag:toPlayer()
						if source:isAlive() then
							damage.from = source
						else
							damage.from = nil
						end
						data:setValue(damage)
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("SavageAssault") then
				room:removeTag("HuoshouSource")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


--[[
	技能名：甘露
	相关武将：一将成名·吴国太
	描述：出牌阶段，你可以交换两名角色装备区里的牌，以此法交换的装备数差不能超过X（X为你已损失体力值）。每阶段限一次。
	引用：LuaGanlu
	状态：0610验证失败（双方均无装备时服务器会闪退）
]]--

swapEquip = function(first, second)
	local room = first:getRoom()
	local equips1 = sgs.IntList()
	local equips2 = sgs.IntList()
	for _, equip in sgs.qlist(first:getEquips()) do
		equips1:append(equip:getId())
	end
	for _, equip in sgs.qlist(second:getEquips()) do
		equips2:append(equip:getId())
	end
	local exchangeMove = sgs.CardsMoveList()
	local move1 = sgs.CardsMoveStruct()
	move1.card_dis = equip1
	move1.to = second
	move1.to_place = sgs.Player_PlaceEquip
	local move2 = sgs.CardsMoveStruct()
	move2.card_ids = equip2
	move2.to = first
	move2.to_place = sgs.Player_PlaceEquip
	exchangeMove:append(move1)
	exchangeMove:append(move2)
	room:moveCards(exchangeMove, false)
end
LuaGanluCard = sgs.CreateSkillCard{
	name = "LuaGanluCard" ,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			local n1 = targets[1]:getEquips():length()
			local n2 = to_select:getEquips():length()
			return math.abs(n1 - n2) <= sgs.Self:getLostHp()
		else
			return false
		end
	end ,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		swapEquip(targets[1], targets[2])
	end
}
LuaGanlu = sgs.CreateViewAsSkill{
	name = "LuaGanlu" ,
	n = 0 ,
	view_as = function()
		return LuaGanluCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaGanluCard")
	end
}


--[[
	技能名：明策
	相关武将：一将成名·陈宫
	描述：出牌阶段，你可以交给一名其他角色一张装备牌或【杀】，该角色选择一项：1. 视为对其攻击范围内你选择的另一名角色使用一张【杀】。2. 摸一张牌。每回合限一次。
	引用：LuaMingce
	状态：0610验证失败（客户端点击技能即闪退）
]]--
LuaMingceCard = sgs.CreateSkillCard{
	name = "LuaMingceCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local targets = sgs.SPlayerList()
		if sgs.Slash_IsAvaliable(effect.to) then
			for _, p in sgs.qlist(room:getOtherPlayers(effect.to)) do
				if effect.to:canSlash(p) then
					targets:append(p)
				end
			end
		end
		local target
		local choicelist = {"draw"}
		if (not targets:isEmpty()) and effect.from:isAlive() then
			target = room:askForPlayerChosen(effect.from, targets, self:objectName(), "@dummy-slash2:" .. effect.to:objectName())
			target:setFlags("LuaMingceTarget")
			table.insert(choicelist, "use")
		end
		effect.to:obtainCard(self)
		local choice = room:askForChoice(effect.to, self:objectName(), table.concat(choicelist, "+"))
		if target and target:hasFlag("LuaMingceTarget") then target:setFlags("-LuaMingceTarget") end
		if choice == "use" then
			if effect.to:canSlash(target, nil, false) then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("_LuaMingce")
				room:useCard(sgs.CardUseStruct(slash, effect.to, target), false)
			end
		elseif choice == "draw" then
			effect.to:drawCards(1)
		end
	end
}
LuaMingce = sgs.CreateViewAsSkill{
	name = "LuaMingce" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard") or to_select:isKindOf("Slash")
	end ,
	view_as = function(self, cards)
		local mingcecard = LuaMingceCard:clone()
		mingcecard:addSubcard(cards[1])
		return mingcecard
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaMingceCard")
	end
}



--[[
	技能名：鬼才
	相关武将：标准·司马懿
	描述：在一名角色的判定牌生效前，你可以打出一张手牌代替之。
	引用：LuaGuicai
	状态：0610验证可能失败（技能可以发动并且正常改判，但是改判之后的牌会留在桌面上）
]]--
LuaGuicai = sgs.CreateTriggerSkill{
	name = "LuaGuicai" ,
	events = {sgs.AskForRetrial} ,
	on_trigger = function(self, event, player, data)
		if player:isKongcheng() then return false end
		local judge = data:toJudge()
		local prompt_list = {
			"@guicai-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			string.format("%d", judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local forced = false
		if player:getMark("JilveEvent") == sgs.AskForRetrial then forced = true end
		local askforcardpattern = "."
		if forced then askforcardpattern = ".!" end
		local card = room:askForCard(player, askforcardpattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if forced and (card == nil) then
			card = player:getRandomHandCard()
		end
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end
}

--[[
	技能名：集智
	相关武将：标准·黄月英
	描述：每当你使用锦囊牌选择目标后，你可以展示牌堆顶的一张牌。若此牌为基本牌，你选择一项：1.将之置入弃牌堆；2.用一张手牌替换之。若此牌不为基本牌，你获得之。
	引用：LuaJizhi
	状态：0610验证貌似通过？（貌似现在是正面朝上进入摸牌堆的）
]]--

LuaJizhi = sgs.CreateTriggerSkill{
	name = "LuaJizhi" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if (use.card:getTypeId() == sgs.Card_TypeTrick) then
			if not (player:getMark("JilveEvent") > 0) then
				if not room:askForSkillInvoke(player, self:objectName()) then return false end
			end
			local ids = room:getNCards(1, false)
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = player
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
			room:moveCardsAtomic(move, true)
			local id = ids:first()
			local card = sgs.Sanguosha:getCard(id)
			if not card:isKindOf("BasicCard") then
				player:obtainCard(card)
			else
				local card_ex
				if not player:isKongcheng() then
					local card_data = sgs.QVariant()
					card_data:setValue(card)
					card_ex = room:askForCard(player, ".", "@jizhi-exchange:::" .. card:objectName(), card_data, sgs.Card_MethodNone)
				end
				if card_ex then
					local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), nil)
					local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE, player:objectName(), self:objectName(), nil)
					local move1 = sgs.CardsMoveStruct()
					move1.card_ids:append(card_ex:getEffectiveId())
					move1.from = player
					move1.to = nil
					move1.to_place = sgs.Player_DrawPile
					move1.reason = reason1
					local move2 = sgs.CardsMoveStruct()
					move2.card_ids = ids
					move2.from = player
					move2.to = player
					move2.to_place = sgs.Player_PlaceHand
					move2.reason = reason2
					local moves = sgs.CardsMoveList()
					moves:append(move1)
					moves:append(move2)
					room:moveCardsAtomic(moves, false)
				else
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NAUTRAL_ENTER, player:objectName(), self:objectName(), nil)
					room:throwCard(card, reason, nil)
				end
			end
		end
		return false
	end
}

--[[
	技能名：反间
	相关武将：标准·周瑜
	描述：出牌阶段，你可以令一名其他角色说出一种花色，然后获得你的一张手牌并展示之，若此牌不为其所述之花色，你对该角色造成1点伤害。每阶段限一次。
	引用：LuaFanjian
	状态：0610验证通过？（当时对AI不知道AI选的什么花色）
]]--
LuaFanjianCard = sgs.CreateSkillCard{
	name = "LuaFanjianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local zhouyu = effect.from
		local target = effect.to
		local room = zhouyu:getRoom()
		local card_id = zhouyu:getRandomHandCardId()
		local card = sgs.Sanguosha:getCard(card_id)
		local suit = room:askForSuit(target, "LuaFanjian")
		target:obtainCard(card)
		room:showCard(target, card_id)
		if card:getSuit() ~= suit then
			room:damage(sgs.DamageStruct("LuaFanjian", zhouyu, target))
		end
	end
}
LuaFanjian = sgs.CreateViewAsSkill{
	name = "LuaFanjian",
	n = 0,
	view_as = function(self, cards)
		local card = LuaFanjianCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and (not player:hasUsed("#LuaFanjianCard"))
	end
}

--[[
	技能名：缔盟
	相关武将：林·鲁肃
	描述：出牌阶段，你可以选择两名其他角色并弃置等同于他们手牌数差的牌，然后交换他们的手牌。每阶段限一次。
	引用：LuaDimeng
	状态：0610貌似验证通过？
]]--
LuaDimengCard = sgs.CreateSkillCard{
	name = "LuaDimengCard" ,
	target_fixed = false ,
	will_throw = true ,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if #targets == 0 then return true end
		if #targets == 1 then return math.abs(to_select:getHandcardNum() - targets[1]:getHandcardNum()) == self:subcardsLength() end
		return false
	end ,
	feasible = function(self, targets)
		return #targets == 2
	end ,
	on_use = function(self, room, source, targets)
		local a = targets[1]
		local b = targets[2]
		a:setFlags("LuaDimengTarget")
		b:setFlags("LuaDimengTarget")
		local n1 = a:getHandcardNum()
		local n2 = b:getHandcardNum()
		--[[ //这段代码不知道什么意思，也不知道怎么转换
		foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p != a && p != b)
                room->doNotify(p, QSanProtocol::S_COMMAND_EXCHANGE_KNOWN_CARDS,
                               QSanProtocol::Utils::toJsonArray(a->objectName(), b->objectName()));
        }
		]]
		local exchangeMove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct()
		move1.card_ids = a:handCards()
		move1.to = b
		move1.to_place = sgs.Player_PlaceHand
		local move2 = sgs.CardsMoveStruct()
		move2.card_ids = b:handCards()
		move2.to = a
		move2.to_place = sgs.Player_PlaceHand
		exchangeMove:append(move1)
		exchangeMove:append(move2)
		room:moveCards(exchangeMove, false)
		a:setFlags("-LuaDimengTarget")
		b:setFlags("-LuaDimengTarget")
	end
}
LuaDimeng = sgs.CreateViewAsSkill{
	name = "LuaDimeng" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		local card = LuaDimengCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end ,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#LuaDimengCard")
	end
}

-------------------------------------------------------------------------------
---------------------------------[[就这么多了]]---------------------------------
-------------------------------------------------------------------------------
------------------------------[[暂时不会动的技能]]------------------------------
-------------------------------------------------------------------------------

--[[
	技能名：救援（主公技、锁定技）
	相关武将：标准·孙权、测试·制霸孙权
	描述：其他吴势力角色使用的【桃】指定你为目标后，回复的体力+1。
	引用：LuaJiuyuan
	状态：0610待验证（on_trigger按照源代码重写）
]]--
LuaJiuyuan = sgs.CreateTriggerSkill{
	name = "LuaJiuyuan$", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.TargetConfirmed, sgs.PreHpRecover},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Peach") and use.from and (use.from:getKingdom() == "wu")
					and (player:objectName() ~= use.from:objectName()) and player:hasFlag("Global_Dying") then 
				room:setCardFlag(use.card, "LuaJiuyuan")
			end
		elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and rec.card:hasFlag("LuaJiuyuan") then
				rec.recover = rec.recover + 1
				data:setValue(rec)
			end
		end
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasLordSkill(self:objectName())
		end
		return false
	end
}


--[[
	技能名：黄天（主公技）
	相关武将：风·张角
	描述：其他群雄角色可以在他们各自的出牌阶段交给你一张【闪】或【闪电】。每阶段限一次。
	引用：LuaHuangtian；LuaHuangtianv（技能暗将）
	状态：0610待验证（完全重写）
]]--

LuaHuangtianCard = sgs.CreateSkillCard{
	name = "LuaHuangtianCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:hasLordSkill("LuaHuangtian") 
				and (to_select:objectName() ~= sgs.Self:objectName()) and (not to_select:hasFlag("LuaHuangtianInvoked"))
	end ,
	on_use = function(self, room, source, targets)
		local zhangjiao = targets[1]
		if zhangjiao:hasLordSkill("LuaHuangtian") then
			room:setPlayerFlag(zhangjiao, "LuaHuangtianInvoked")
			zhangjiao:obtainCard(self)
			local zhangjiaos = sgs.SPlayerList()
			local players = room:getOtherPlayers(source)
			for _, p in sgs.qlist(players) do
				if p:hasLordSkill("LuaHuangtian") and (not p:hasFlag("LuaHuangtianInvoked")) then
					zhangjiaos:append(p)
				end
			end
			if zhangjiaos:isEmpty() then
				room:setPlayerFlag(source, "ForbidLuaHuangtian")
			end
		end
	end
}
LuaHuangtianv = sgs.CreateViewAsSkill{
	name = "LuaHuangtianv" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if #selected > 0 then return false end
		return (to_select:objectName() == "jink") or (to_select:objectName() == "lightning")
	end ,
	view_as = function(self, cards)
		local card = LuaHuangtianCard:clone()
		card:addSubcard(cards[1])
		return card
	end ,
	enabled_at_play = function(self, player)
		return (player:getKingdom() == "qun") and (not player:hasFlag("ForbidLuaHuangtian"))
	end
}
LuaHuangtian = sgs.CreateTriggerSkill{
	name = "LuaHuangtian$" ,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.GameStart) and player:isLord()) or ((event == sgs.EventAcquireSkill) and (data:toString() == "LuaHuangtian")) then
			local lords = sgs.SPlayerList()
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
				if not p:hasSkill("LuaHuangtianv") then
					room:attachSkillToPlayer(p, "LuaHuangtianv")
				end
			end
		elseif (event == sgs.EventLoseSkill) and (data:toString() == "LuaHuangtian") then
			local lords = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasLordSkill(self:objectName()) then
					lords:append(p)
				end
			end
			if lords:length() > 2 then return false end
			local players = sgs.SPlayerList()
			if lords:isEmpty() then
				players = room:getAlivePlayers()
			else
				players:append(lords:first())
			end
			for _, p in sgs.qlist(players) do
				if p:hasSkill("LuaHuangtianv") then
					room:detachSkillFromPlayer(p, "LuaHuangtianv", true)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from ~= sgs.Player_Play then return false end
			if player:hasFlag("ForbidLuaHuangtian") then
				room:setPlayerFlag(player, "-ForbidLuaHuangtian")
			end
			local players = room:getOtherPlayrs(player)
			for _, p in sgs.qlist(players) do
				if p:hasFlag("LuaHuangtianInvoked") then
					room:setPlayerFlag(p, "-LusHuangtianInvoked")
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
	技能名：暴虐（主公技）
	相关武将：林·董卓
	描述：每当其他群雄角色造成一次伤害后，该角色可以进行一次判定，若判定结果为黑桃，你回复1点体力。
	引用：LuaBaonve
	状态：0610待验证（完全重写）
]]--
LuaBaonve = sgs.CreateTriggerSkill{
	name = "LuaBaonve$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage, sgs.PreDamageDone},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if (event == sgs.PreDamageDone) and damage.from then
			damage.from:setTag("InvokeLuaBaonve", sgs.QVariant(damage.from:getKingdom() == "qun"))
		elseif (event == sgs.Damage) and player:getTag("InvokeLuaBaonve"):toBool() and player:isAlive() then
			local dongzhuos = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					dongzhuos:append(p)
				end
			end
			while not dongzhuos:isEmpty() do
				local dongzhuo = room:askForPlayerChosen(player, dongzhuos, self:objectName(), "@baonve-to", true)
				if dongzhuo then
					dongzhuos:removeOne(dongzhuo)
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|spade"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then
						recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(dongzhuo, recover)
					end
				else
					break
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

-------------------------------------------------------------------------------
---------------------------------[[就这么多了]]---------------------------------
-------------------------------------------------------------------------------

--[[
	技能名：巧变
	相关武将：山·张郃
	描述：你可以弃置一张手牌，跳过你的一个阶段（回合开始和回合结束阶段除外），若以此法跳过摸牌阶段，你获得其他至多两名角色各一张手牌；若以此法跳过出牌阶段，你可以将一名角色装备区或判定区里的一张牌移动到另一名角色区域里的相应位置。
	引用：LuaQiaobian
	状态：0610待验证
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
				room:movecardto(card, from, to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), nil))
			end
			room:removeTag("LuaQiaobianTarget")
		end
	end
}
LuaQiaobianVS = sgs.CreateViewAsSkill{
	name = "LuaQiaobian" ,
	n = 0
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
	events == {sgs.EventPhaseChanging} ,
	view_as_skill = LuaQiaobianVS ,
	on_trigger = function(self, event, player, data)
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
	引用：LuaTuntian、LuaTuntianDistance、LuaTuntianClear
	状态：0610待验证
]]--
LuaTuntian = sgs.CreateTriggerSkill{
	name = "LuaTuntian" ,
	events == {sgs.CardsMoveOnetime, sgs.FinishJudge} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from:objectName() == player:objectName())
					and (move.from_places:contains(sgs.Player_PlaceHand)
					or move.from_placds:contains(sgs.Player_PlaceEquip)) then
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
LuaTuntianClear = sgs.CreateTriggerSkill{
	name = "#LuaTuntian-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaTuntian" then
			player:clearOnePrivatePile("field")
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：凿险（觉醒技）
	相关武将：山·邓艾
	描述：回合开始阶段开始时，若“田”的数量达到3或更多，你须减1点体力上限，并获得技能“急袭”。
	引用：LuaZaoxian
	状态：0610待验证
]]--
LuaZaoxian = sgs.CreateTriggerSkill{
	name = "LuaZaoxian" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "LuaZaoxian")
		if room:changeMaxHpForAwakenSkill(player) then
			room:acquireSkill(player, "jixi")
		end
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
			and (target:getPhase() == sgs.Player_Start)
			and (target:getMark("LuaZaoxian") == 0)
			and (target:getPile("field"):length() >= 3)
	end
}


--[[
	技能名：激昂
	相关武将：山·孙策
	描述：每当你使用（指定目标后）或被使用（成为目标后）一张【决斗】或红色的【杀】时，你可以摸一张牌。
	引用：LuaJiang
	状态：0610待验证
]]--
LuaJiang = sgs.CreateTriggerSkill{
	name = "LuaJiang" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if (use.from:objectName() == player:objectName()) or use.to:contains(player) then
			if use.card:isKindOf("Duel") or (use.card:isKindOf("Slash") and use.card:isRed()) then
				if player:askForSkillInvoke(self:objectName(), data) then
					player:drawCards(1)
				end
			end
		end
		return false
	end
}
--[[
	技能名：魂姿（觉醒技）
	相关武将：山·孙策
	描述：回合开始阶段开始时，若你的体力为1，你须减1点体力上限，并获得技能“英姿”和“英魂”。
	引用：LuaHunzi
	状态：0610待验证
]]--

LuaHunzi = sgs.CreateTriggerSkill{
	name = "LuaHunzi" ,
	events == {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "LuaHunzi")
		if room:changeMaxHpForAwakenSkill(player) then
			room:handleAcquireDetachSkills(player, "yingzi|yinghun")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("LuaHunzi") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and (target:getHp() == 1)
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
	events == {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.Pindian, sgs.EventPhaseChanging} ,
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
	技能名：挑衅
	相关武将：山·姜维
	描述：出牌阶段，你可以令一名你在其攻击范围内的其他角色选择一项：对你使用一张【杀】，或令你弃置其一张牌。每阶段限一次。
	引用：LuaTiaoxin
	状态：0610待验证
]]--
LuaTiaoxinCard = sgs.CreateSkillCard{
	name = "LuaTiaoxinCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:inMyAttackRange(sgs.Self) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local use_slash = false
		if effect.to:canSlash(effect.from, nil, false) then
			use_slash = room:askForUseSlashTo(effect,to, effect,from, "@tiaoxin-slash:" .. effect.from:objectName())
		end
		if (not use_slash) and effect.from:canDiscard(effect.to, "he") then
			room:throwCard(room:askForCardChosen(effect.from, effect.to, "he", "LuaTiaoxin", false, sgs.Card_MethodDiscard), effect.to, effect.from)
		end
	end
}
LuaTiaoxin = sgs.CreateViewAsSkill{
	name = "LuaTiaoxin" ,
	n = 0 ,
	view_as = function()
		return LuaTiaoxinCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaTiaoxinCard")
	end
}
--[[
	技能名：志继（觉醒技）
	相关武将：山·姜维
	描述：回合开始阶段开始时，若你没有手牌，你须选择一项：回复1点体力，或摸两张牌。然后你减1点体力上限，并获得技能“观星”。
	引用：LuaZhiji
	状态：0610待验证
]]--
LuaZhiji = sgs.CreateTriggerSkill{
	name = "LuaZhiji" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isWounded() then
			if room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			else
				room:drawCards(player, 2)
			end
		else
			room:drawCards(player, 2)
		end
		room:addPlayerMark(player, "LuaZhiji")
		if room:changeMaxHpForAwakenSkill(player) then
			room:acquireSkill(player, "guanxing")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("LuaZhiji") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and target:isKongcheng()
	end
}
--[[
	技能名：直谏
	相关武将：山·张昭张纮
	描述：出牌阶段，你可以将手牌中的一张装备牌置于一名其他角色的装备区里（不能替换原装备），然后摸一张牌。
	引用：LuaZhijian
	状态：0610待验证
]]--
LuaZhijianCard = sgs.CreateSkillCard{
	name = "LuaZhijianCard" ,
	will_throw = false
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		if (not targets:isEmpty()) or (to_select:objectName() == sgs.Self:objectName()) then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end ,
	on_effect = function(self, effect)
		local erzhang = effect.from
		erzhang:getRoom()moveCardTo(self, erzhang, effect.to, sgs.Player_PlaceEquip, 
									sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
													   erzhang:objectName(), self:objectName(), nil))
		erzhang:drawCards(1)
	end
}
LuaZhijian = sgs.CreateViewAsSkill{
	name = "LuaZhijian" ,
	n = 1 ,
	view_filter = function(self, cards, to_select)
		return (not to_select:isEquipped()) and (to_select:getTypeId() == sgs.Card_TypeEquip)
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local zhijian_card = LuaZhijianCard:clone()
		zhijian_card:addSubcard(cards[1])
		return zhijian_card
	end
}
--[[
	技能名：固政
	相关武将：山·张昭张纮
	描述：其他角色的弃牌阶段结束时，你可以将该角色于此阶段中弃置的一张牌从弃牌堆返回其手牌，若如此做，你可以获得弃牌堆里其余于此阶段中弃置的牌。
	引用：LuaGuzheng、LuaGuzhengGet
	状态：0610待验证
]]--
containCardGuzheng = function(cards_list, card_id)
	for i = 1, #cards_list, 1 do
		if cards_list[i] == card_id then return true end
	end
	return false
end
list2strGuzheng = function(cards_list)
	local cards_str
	if #cards_list == 0 then return "" end
	cards_str = tostring(cards_list[1])
	for i = 2, #cards_list, 1 do
		cards_str = cards_str .. "+" .. tostring(cards_list[i])
	end
	return cards_str
end
str2listGuzheng = function(cards_str)
	local cards_list = {}
	local cards_str_list = cards_str:split("+")
	for _, card_str in ipairs(cards_str_list) do
		table.insert(cards_list, tonumber(card_str))
	end
	return cards_list
end
LuaGuzheng = sgs.CreateTriggerSkill{
	name = "LuaGuzheng" ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		local move = data:toMoveOneTime()
		if player:objectName() == current:objectName() then return false end
		if current:getPhase() == sgs.Player_Discard then
			local guzhengToGet = str2listGuzheng(player:getTag("LuaGuzhengToGet"):toString())
			local guzhengToOther = str2listGuzheng(player:getTag("LuaGuzhengToOther"):toString())
			for _, card_id in sgs.qlist(move.card_ids) do
				if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
					if move.from:objectName() == current:objectName() then
						table.insert(guzhengToGet, card_id)
					elseif not containCardGuzheng(guzhengToGet, card_id) then
						table.insert(guzhengToOther, card_id)
					end
				end
			end
			player:setTag("LuaGuzhengToGet", sgs.QVariant(list2strGuzheng(guzhengToGet)))
			player:setTag("LuaGuzhengToOther", sgs.QVariant(list2strGuzheng(guzhengToOther)))
		end
		return false
	end
}
LuaGuzhengGet = sgs.CreateTriggerSkill{
	name = "#LuaGuzheng-get" ,
	events = {sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local erzhang = room:findPlayerBySkillName(self:objectName())
		if not erzhang then return false end
		local guzheng_cardsToGet = str2listGuzheng(erzhang:getTag("LuaGuzhengToGet"):toString())
		local guzheng_cardsToOther = str2listGuzheng(erzhang:getTag("LuaGuzhengToOther"):toString())
		erzhang:removeTag("LuaGuzhengToGet")
		erzhang:removeTag("LuaGuzhengToOther")
		if player:isDead() then return false end
		local cards = sgs.IntList()
		local cardsToGet = sgs.IntList()
		local cardsToOter = sgs.IntList()
		for _, card_id in ipairs(guzheng_cardsToGet) do
			if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
				cardsToGet:append(card_id)
				cards:append(card_id)
			end
		end
		for _, card_id in ipairs(guzheng_cardsToOther) do
			if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
				cardsToOther:append(card_id)
				cards:append(card_id)
			end
		end
		if cardsToGet:isEmpty() then return false end
		if erzhang:askForSkillInvoke("LuaGuzheng", sgs.QVariant(cards:length())) then
			room:fillAG(cards, erzhang, cardsToOther)
			local go_back = room:askForAG(erzhang, cardsToGet, false, "LuaGuzheng")
			player:obtainCard(sgs.Sanguosha:getCard(go_back))
			cards:removeOne(go_back)
			room:clearAG(erzhang)
			local move = sgs.CardsMoveStruct()
			move.card_ids = cards
			move.to = erzhang
			move.to_place = sgs.Player_PlaceHand
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:moveCardsAtomic(moves, true)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Discard)
	end
}

--[[
	技能名：享乐（锁定技）
	相关武将：山·刘禅
	描述：当其他角色使用【杀】指定你为目标时，需弃置一张基本牌，否则此【杀】对你无效。
	引用：LuaXiangle
	状态：0610待验证
]]--
LuaXiangle = sgs.CreateTriggerSkill{
	name = "LuaXiangle" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.SlashEffected, sgs.TargetConfirming} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				player:setMark("LuaXiangle", 0)
				local dataforai = sgs.QVariant()
				dataforai:setValue(player)
				if not room:askForCard(use.from, ".Basic", "@xiangle-discard", dataforai) then
					player:addMark("LuaXiangle")
				end
			end
		else
			local effect= data:toSlashEffect()
			if player:getMark("LuaXiangle") > 0 then
				player:removeMark("LuaXiangle")
				return true
			end
		end
	end
}

--[[
	技能名：放权
	相关武将：山·刘禅
	描述：你可以跳过你的出牌阶段，若如此做，你在回合结束时可以弃置一张手牌令一名其他角色进行一个额外的回合。
	引用：LuaFangquan、LuaFangquanGive
	状态：0610待验证
]]--
LuaFangquan = sgs.CreateTriggerSkill{
	name = "LuaFangquan" ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play then
			local invoked = false
			if player:isSkipped(sgs.Player_Play) then return false end
			invoked = player:askForSkillInvoke(objectName())
			if invoked then
				player:setFlags("LuaFangquan")
				player:skip(sgs.Player_Play)
			end
		elseif change.to == sgs.Player_NotActive then
			if player:hasFlag("LuaFangquan") then
				if not player:canDiscard(player, "h") then return false end
				if not room:askForDiscard(player, "LuaFangquan", 1, 1, true) then return false end
				local _player = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				local p = _player
				local playerdata = sgs.QVariant()
				playerdata:setValue(p)
				room:setTag("LuaFangquanTarget", playerdata)
			end
		end
		return false
	end
}
LuaFangquanGive = sgs.CreateTriggerSkill{
	name = "#LuaFangquan-give" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("LuaFangquanTarget") then
			local target = room:getTag("LuaFangquanTarget"):toPlayer()
			room:removeTag("LuaFangquanTarget")
			if target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end ,
	priority = 1
}
--[[
	技能名：若愚（主公技、觉醒技）
	相关武将：山·刘禅
	描述：回合开始阶段开始时，若你的体力是全场最少的（或之一），你须加1点体力上限，回复1点体力，并获得技能“激将”。
	引用：LuaRuoyu
	状态：0610待验证
]]--
LuaRuoyu = sgs.CreateTriggerSkill{
	name = "LuaRuoyu$" ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_invoke = true
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if player:getHp() > p:getHp() then
				can_invoke = false
				break
			end
		end
		if can_invoke then
			room:addPlayerMark(player, "LuaRuoyu")
			if room:changeMaxHpForAwakenSkill(player, 1) then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
				if player:isLord() then
					room:acquireSkill(player, "jijiang")
				end
			end
		end
		return false
	end
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasLordSkill("LuaRuoyu")
				and taret:isAlive()
				and (target:getMark("LuaRuoyu") == 0)
	end
}

--[[
	技能名：武神（锁定技）
	相关武将：神·关羽
	描述：你的红桃手牌均视为【杀】；你使用红桃【杀】时无距离限制。
	引用：LuaWushen、LuaWushenTargetMod
	状态：0610待验证
]]--
LuaWushen = sgs.CreateFilterSkill{
	name = "LuaWushen" ,
	view_filter = function(self, card)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to:select:getEffectiveId())
		return (to_select:getSuit == sgs.Card_Heart) and (place == sgs.Player_PlaceHand)
	end ,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("Slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		local _card = sgs.Sangosha:getWrappedCard(card:getId())
		_card:takeOver(slash)
		return _card
	end
}
LuaWushenTargetMod = sgs.CreateTargetModSkill{
	name = "LuaWushen-target" ,
	distance_limit_skill = function(self, from, card)
		if from:hasSkill("LuaWushen") and (card:getSuit() == sgs.Card_Heart) then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：武魂（锁定技）
	相关武将：神·关羽
	描述：每当你受到1点伤害后，伤害来源获得一枚“梦魇”标记；你死亡时，令拥有最多该标记的一名其他角色进行一次判定，若判定结果不为【桃】或【桃园结义】，该角色死亡。
	引用：LuaWuhun、LuaWuhunRevenge、LuaWuhunClear
	状态：0610待验证
]]--
LuaWuhun = sgs.CreateTriggerSkill{
	name = "LuaWuhun" ,
	events = {sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.from and (damage.from:objectName() ~= player:objectName()) then
			damage.from:gainMark("@nightmare", damage.damage)
		end
	end
}
LuaWuhunRevenge = sgs.CreateTriggerSkill{
	name = "#LuaWuhun" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local players = room:getOtherPlayers(player)
		local _max = 0
		for _, _player in sgs.qlist(players) do
			_max = math.max(_max, _player:getMark("@nightmare"))
		end
		if _max == 0 then return false end
		local foes = sgs.SPlayerList()
		for _, _player in sgs.qlist(players) do
			if _player:getMark("@nightmare") == _max then
				foes:append(_player)
			end
		end
		if foes:isEmpty() then return false end
		local foe
		if foes:length() == 1 then
			foe = foes:first()
		else
			foe = room:askForPlayerChosen(player, foes, self:objectName(), "@wuhun-revenge")
		end
		local judge = sgs.JudgeStruct()
		judge.pattern = "Peach,GodSalvation" 
		judge.good = true
		judge.reason = "LuaWuhun" 
		judge.who = foe
		room:judge(judge)
		if judge:isBad() then
			room:killPlayer(foe)
		end
		local killers = room:getAllPlayers()
		for _, _player in sgs.qlist(killers) do
			_player:loseAllMarks("@nightmare")
		end 
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill("LuaWuhun")
	end
}
LuaWuhunClear = sgs.CreateTriggerSkill{
	name = "LuaWuhun-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaWuhun" then 
			for _, p in sgs.qlist(player:getRoom():getAllPlayers()) do
				p:loseAllMarks("@nightmare")
			end
		end
	end ,
	can_trigger = function(self, target)
		return target
	end ,
}

--[[
	技能名：攻心
	相关武将：神·吕蒙
	描述：出牌阶段，你可以观看任意一名角色的手牌，并可以展示其中一张红桃牌，然后将其弃置或置于牌堆顶。每阶段限一次。 
	引用：LuaGongxin
	状态：0610待验证
]]--
LuaGongxinCard = sgs.CreateSkillCard{
	name = "LuaGongxinCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		if not effect.to:isKongcheng() then
			effect.from:getRoom():doGongxin(effect.from, effect.to)
		end
	end
}
LuaGongxin = sgs.CreateViewAsSkill{
	name = "LuaGongxin" ,
	n = 0 ,
	view_as = function()
		return LuaGongxinCard:clone()
	end ,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#LuaGongxinCard")
	end
}

--[[
	技能名：琴音
	相关武将：神·周瑜
	描述：当你于弃牌阶段内弃置了两张或更多的手牌后，你可以令所有角色各回复1点体力或各失去1点体力。每阶段限一次。
	引用：LuaQinyin
	状态：0610待验证
]]--
performQinyin = function(shenzhouyu)
	local room = shenzhouyu:getRoom()
	local result = room:askForChoice(shenzhouyu, "LuaQinyin", "up+down")
	local all_players = room:getAllPlayers()
	if result == "up" then
		for _, player in sgs.qlist(all_players) do
			local recover = sgs.RecoverList()
			recover.who = shenzhouyu
			room:recover(player, recover)
		end
	elseif result == "down" then
		for _, player in sgs.qlist(all_players) do
			room:loseHp(player)
		end
	end
end
LuaQinyin = sgs.CreateTriggerSkill{
	name = "LuaQinyin" ,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Discard then return false end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from:objectName() == player:objectName()) 
					and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				player:setMark("LuaQinyin", player:getMark("LuaQinyin") + move.card_ids:length())
				if (not player:hasFlag("LuaQinyinUsed")) and (player:getMark("LuaQinyin") >= 2) then
					if player:askForSkillInvoke(self:objectName()) then
						player:setFlags("LuaQinyinUsed")
						performQinyin(player)
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			player:setMark("qinyin", 0)
			player:setFlags("-QinyinUsed")
		end
		return false
	end
}
--[[
	技能名：归心
	相关武将：神·曹操
	描述：每当你受到1点伤害后，你可以分别从每名其他角色的区域获得一张牌，然后将你的武将牌翻面。
	引用：LuaGuixin
	状态：0610待验证
]]--

LuaGuixin = sgs.CreateTriggerSkill{
	name = "LuaGuixin" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local n = player:getMark("LuaGuixinTimes")
		player:setMark("LuaGuixinTimes", 0)
		local damage = data:toDamage()
		local players = room:getOtherPlayers(player)
		for i = 0, damage.damage - 1, 1 do
			local can_invoke = false
			for _, p in sgs.qlist(players) do
				if not p:isAllNude() then
					can_invoke = true
					break
				end
			end
			if not can_invoke then break end
			player:addMark("LuaGuixinTimes")
			if player:askForSkillInvoke(self:objectName(), data) then
				player:setFlags("LuaGuixinUsing")
				for _, _player in sgs.qlist(players) do
					if _player:isAlive() and (not _player:isAllNude()) then
						local card_id = room:askForCardChosen(player, _player, "hej", self:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					end
				end
				player:turnOver()
				player:setFlags("-LuaGuixinUsing")
			else
				break
			end
		end
		player:setMark("LuaGuixinTimes", n)
	end
}

--[[
	技能名：飞影（锁定技）
	相关武将：神·曹操、倚天·魏武帝
	描述：其他角色计算的与你的距离+1。
	引用：LuaFeiying
	状态：0610待验证
]]--
LuaFeiying = sgs.CreateDistanceSkill{
	name = "LuaFeiying" ,
	correct_func = function(self, from ,to)
		if to:hasSkill(self:objectName()) then
			return 1
		else 
			return 0
		end
	end
}
--[[
	技能名：狂暴（锁定技）
	相关武将：神·吕布
	描述：游戏开始时，你获得2枚“暴怒”标记；每当你造成或受到1点伤害后，你获得1枚“暴怒”标记。
	引用：LuaKuangbao、LuaWrath2、LuaKuangbaoClear
	状态：0610待验证
]]--
LuaKuangbao = sgs.CreateTriggerSkill{
	name = "LuaKuangbao" ,
	events = {sgs.Damage, sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		player:gainMark("@wrath", damage.damage)
	end
}
LuaWrath2 = sgs.CreateTriggerSkill{
	name = "#@wrath-Lua-2" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		player:gainMark("@wrath", 2)
	end
}
LuaKuangbaoClear = sgs.CreateTriggerSkill{
	name = "LuaKuangbao-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaKuangbao" then
			player:loseAllMarks("@wrath")
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：无谋（锁定技）
	相关武将：神·吕布
	描述：当你使用一张非延时类锦囊牌选择目标后，你须弃1枚“暴怒”标记或失去1点体力。
	引用：LuaWumou
	状态：0610待验证
]]--
LuaWumou = sgs.CreateTriggerSkill{
	name = "LuaWumou" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardUsed, sgs.CardResponded} ,
	on_trigger = function(self, event, player, data)
		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		if card:isNDTrick() then
			local num = player:getMark("@wrath")
			if num >= 1 then
				if player:getRoom():askForChoice(player, self:objectName(), "discard+losehp") == "discard" then
					player:loseMark("@wrath")
				else
					player:getRoom():loseHp(player)
				end
			else
				player:getRoom():loseHp(player)
			end
		end
		return false
	end
}
--[[
	技能名：神愤
	相关武将：神·吕布
	描述：出牌阶段，你可以弃6枚“暴怒”标记，对所有其他角色各造成1点伤害，所有其他角色先弃置各自装备区里的牌，再弃置四张手牌，然后将你的武将牌翻面。每阶段限一次。
	引用：LuaShenfen
	状态：0610待验证（未处理胆守）
]]--
LuaShenfenCard = sgs.CreateSkillCard{ 
	name = "LuaShenfenCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		source:setFlags("LuaShenfenUsing")
		source:loseMark("@wrath", 6)
		local players = room:getOtherPlayers(source)
		for _, player in sgs.qlist(players) do
			room:damage(sgs.DamageStruct("LuaShenfen", source, player))
		end
		for _, player in sgs.qlist(players) do
			player:throwAllEquips()
		end
		for _, player in sgs.qlist(players) do
			room:askForDiscard(player, "LuaShenfen", 4, 4)
		end
		source:turnOver()
		source:setFlags("-LuaShenfenUsing")
	end
}
LuaShenfen = sgs.CreateViewAsSkill{
	name = "LuaShenfen" ,
	n = 0
	view_as = function()
		return LuaShenfenCard:Clone()
	end ,
	enabled_at_play = function(self, target)
		return (player:getMark("@warth") >= 6) and (not player:hasUsed("#LuaShenFenCard"))
	end
}
--[[
	技能名：无前
	相关武将：神·吕布
	描述：出牌阶段，你可以弃2枚“暴怒”标记并选择一名其他角色，该角色的防具无效且你获得技能“无双”，直到回合结束。
	引用：LuaWuqian
	状态：0610待验证
]]--
LuaWuqianCard = sgs.CreateSkillCard{
	name = "LuaWuqianCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		effect.from:loseMark("@wrath", 2)
		room:acquireSkill(effect.from, "wushuang")
		effect.from:setFlags("LuaWuqianSource")
		effect.to:setFlags("LuaWuqianTarget")
		room:addPlayerMark(effect.to, "Armor_Nullified")
	end
}
LuaWuqianVS = sgs.CreateViewAsSkill{
	name = "LuaWuqian" ,
	view_as = function()
		return LuaWuqinCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@wrath") >= 2
	end
}
LuaWuqian = sgs.CreateTriggerSkill{
	name = "LuaWuqian" ,
	events = {sgs.EventPhaseChanging, sgs.Death} ,
	view_as_skill = LuaWuqianVS ,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then
				return false 
			end
		end
		for _, p in sgs.qlist(player:getRoom():getAllPlayers()) do
			if p:hasFlag("WuqianTarget") then
				p:setFlags("-WuqianTarget")
				if p:getMark("Armor_Nullified") then
					player:getRoom():removePlayerMark(p, "Armor_Nullified")
				end
			end
		end
		player:getRoom():detachSkillFromPlayer(player, "wushuang")
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasFlag("LuaWuqianSource")
	end
}
--[[
	技能名：七星
	相关武将：神·诸葛亮
	描述：分发起始手牌时，共发你十一张牌，你选四张作为手牌，其余的面朝下置于一旁，称为“星”；摸牌阶段结束时，你可以用任意数量的手牌等量替换这些“星”。
	引用：LuaQixing、LuaQixingStart、LuaQixingAsk、LuaQixingClear、LuaQixingFakeMove
	状态：0610待验证
	
	Fs备注：由于“七星”“狂风”“大雾”三个技能相关度非常高，所以在LUA版的“七星”技能当中引用的为本次LUA版的“狂风”和“大雾”，并非原版技能。
			如果想要改为引用原版技能的话，可以将LuaQixingAsk部分的askForUseCard的pattern修改为"@@kuangfeng"和"@@dawu"即可
]]--

exchangeQixing = function(shenzhuge)
	local stars = shenzhuge:getPile("stars")
	if stars:isEmpty() then return end
	shenzhuge:exchangeFreelyFromPrivatePile("LuaQixing", "stars")
end
discardStarQixing = function(shenzhuge, n, skillName)
	local room = shenzhuge:getRoom()
	local stars = shenzhuge:getPile("stars")
	for i = 0, n - 1, 1 do
		room:fillAG(stars, shenzhuge)
		local card_id = room:askForAG(shenzhuge, stars, false, "qixing-discard")
		room:clearAG(shenzhuge)
		stars:removeOne(card_id)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, skillName, nil)
		room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
	end
end
LuaQixing = sgs.CreateTriggerSkill{
	name = "LuaQixing" ,
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		exchangeQixing(player)
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName())) and (target:getPile("stars"):length() > 0)
				and (target:getPhase() == sgs.Player_Draw)
	end
}
LuaQixingFakeMove = sgs.CreateTriggerSkill{
	name = "LuaQixing-fake-move" ,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime} ,
	priority = 10 ,
	on_trigger = function(self, event, player, data)
		if player:hasFlag("LuaQixing_InTempMoving") then return true end
		return false
	end
	can_trigger = function(self, target)
		return target
	end ,
}
LuaQixingStart = sgs.CreateTriggerSkill{
	name = "#LuaQixing" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setTag("FirstRound", sgs.QVariant(true))
		player:drawCards(7)
		room:setTag("FirstRound", sgs.QVariant(false))
		local exchange_card = room:askForExchange(player, "LuaQixing", 7)
		player:addToPile("stars", exchange_card:getSubcards(), false)
	end
}
LuaQixingAsk = sgs.CreateTriggerSkill{
	name = "#LuaQixing-ask" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if (player:getPile("stars"):length() > 0) and player:hasSkill("LuaKuangfeng") then
				room:askForUseCard(player, "@@LuaKuangfeng" ,"@kuangfeng-card", -1, sgs.Card_MethodNone)
			end
			if (player:getPlie("stars"):length() > 0) and player:hasSkill("LuaDawu") then
				room:askForUseCard(player, "@@LuaDawu", "@dawu-card", -1, sgs.Card_MethodNone)
			end
		end
		return false
	end
}
LuaQixingClear = sgs.CreateTriggerSkill{
	name = "#LuaQixing-clear" ,
	events = {sgs.EventPhaseStart, sgs.Death, sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) or (event == sgs.Death) then
			if event == sgs.Death then
				local death = data:toDeath()
				if death.who:objectName() ~= player:objectName() then return false end
			end
			if not player:getTag("LuaQixing_user"):toBool() then return false end
			local invoke = false
			if ((event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_RoundStart)) or (event == sgs.Death) then
				invoke = true
			end
			if not invoke then return false end
			local players = room:getAllPlayers()
			for _, _player in sgs.qlist(players) do
				_player:loseAllMarks("@gale")
				_player:loseAllMarks("@fog")
			end
			player:removeTag("LuaQixing_user")
		elseif (event == sgs.EventLoseSkill) and (data:toString() == "LuaQixing") then
			player:clearOnePrivatePile("stars")
		end
	end
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：狂风
	相关武将：神·诸葛亮
	描述：回合结束阶段开始时，你可以将一张“星”置入弃牌堆并选择一名角色，若如此做，每当该角色受到的火焰伤害结算开始时，此伤害+1，直到你的下回合开始。
	引用：LuaKuangfeng
	状态：0610待验证
	
	Fs备注：需要调用本次Lua手册里面“七星”技能的discardStarQixing函数
]]--
LuaKuangfengCard = sgs.CreateSkillCard{ 
	name = "LuaKuangfengCard" ,
	handling_method == sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		return #targets == 0
	end ,
	on_effect = function(self, effect)
		discardStarQixing(effect.from, 1, "LuaKuangfeng")
		effect.from:setTag("LuaQixing_user", sgs.QVariant(true))
		effect.to:gainMark("@gale")
	end
}
LuaKuangfengVS = sgs.CreateViewAsSkill{
	name = "LuaKuangfeng" ,
	n = 0
	view_as = function()
		return LuaKuangfengCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaKuangfeng"
	end
}
LuaKuangfeng = sgs.CreateTriggerSkill{
	name = "LuaKuangfeng" ,
	events = {sgs.DamageForseen} ,
	view_as_skill = LuaKuangfengVS ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.nature == sgs.DamageStruce_Fire then
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end ,
	can_trigger = function(self, target)
		return target and (target:getMark("@gale") > 0)
	end
}
--[[
	技能名：大雾
	相关武将：神·诸葛亮
	描述：回合结束阶段开始时，你可以将X张“星”置入弃牌堆并选择X名角色，若如此做，每当这些角色受到的非雷电伤害结算开始时，防止此伤害，直到你的下回合开始。
	引用：LuaDawu
	状态：0610待验证
	
	Fs备注：需要调用本次Lua手册里面“七星”技能的discardStarQixing函数
]]--
LuaDawuCard = sgs.CreateSkillCard{  
	name = "LuaDawuCard" ,
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getPile("stars"):length()
	end ,
	on_use = function(self, room, source, targets)
		local n = #targets 
		discardStarQixing(source, n, "LuaDawu")
		source:setTag("LuaQixing_user", sgs.QVariant(true))
		for _, target in ipairs(target) do
			target:gainMark("@fog")
		end
	end
}
LuaDawuVS = sgs.CreateViewAsSkill{
	name = "LuaDawu" ,
	n = 0 ,
	view_as = function()
		return LuaDawuCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabeld_at_response = function(self, player, pattern)
		return pattern == "@@LuaDawu"
	end
}
LuaDawu = sgs.CreateTriggerSkill{
	name = "LuaDawu" ,
	events == {sgs.DamageForseen} ,
	view_as_skill = LuaDawuVS ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Thunder then
			return true
		else
			return false
		end
	end
}
--[[
	技能名：忍戒（锁定技）
	相关武将：神·司马懿
	描述：每当你受到一次伤害后或于弃牌阶段弃置手牌后，你获得等同于受到伤害或弃置手牌数量的“忍”标记。
	引用：LuaRenjie、LuaRenjieClear
	状态：0610待验证
]]--
LuaRenjie = sgs.CreateTriggerSkill{
	name = "LuaRenjie" ,
	events = {sgs.Damaged, sgs.CardsMoveOneTime} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		if event == sgs.CardsMoveOneTime then
			if player:getPhase() == sgs.Player_Discard then
				local move = data:toMoveOneTime()
				if (move.from:objectName() == player:objectName()) 
						and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
					local n = move.card_ids:length()
					if n > 0 then
						player:gainMark("@bear", n)
					end
				end
			end
		elseif event == sgs.Damaged then
			local damge = data:toDamage()
			player:gainMark("@bear", damage.damage)
		end
		return false
	end
}
LuaRenjieClear = sgs.CreateTriggerSkill{
	name = "#LuaRenjie-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaRenjie" then
			player:loseAllMarks("@bear")
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：拜印（觉醒技）
	相关武将：神·司马懿
	描述：回合开始阶段开始时，若你拥有4枚或更多的“忍”标记，你须减1点体力上限，并获得技能“极略”。
	引用：LuaBaiyin
	状态：0610待验证
]]--
LuaBaiyin = sgs.CreateTriggerSkill{
	name = "LuaBaiyin" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark("LuaBaiyin", 1)
		if room:changeMaxHpForAwakenSkill(player) then
			room:acquireSkill(player, "jilve")
		end
		return false
	end ,
	can_trigger = function(self,target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getPhase() == sgs.Player_Start)
				and (target:getMark("LuaBaiyin") == 0)
				and (target:getMark("@bear") >= 4)
	end
}
--[[
	技能名：连破
	相关武将：神·司马懿
	描述：若你在一回合内杀死了至少一名角色，此回合结束后，你可以进行一个额外的回合。
	引用：LuaLianpoCount、LuaLianpo、LuaLianpoDo
	状态：0610待验证
]]--
LuaLianpoCount = sgs.CreateTriggerSkill{
	name = "#LuaLianpo-count" ,
	events = {sgs.Death, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
			local killer
			if death.damage then
				killer = death.damage.from
			else
				killer = nil
			end
			local current = player:getRoom():getCurrent()
			if killer and current and current:isAlive() and (current:getPhase() ~= sgs.Playr_NotActive) then
				killer:addMark("LuaLianpo")
			end
		elseif player:getPhase() == sgs.Player_NotActive then
			for _, p in sgs.qlist(player:getRoom():getAlivePlayers()) do
				p:setMark("LuaLianpo", 0)
			end
		end
		return false
	end	
	can_trigger = function(self,target)
		return target
	end
}
LuaLianpo = sgs.CreateTriggerSkill{
	name = "LuaLianpo" ,
	events = {sgs.EventPhaseChanging} ,
	frequency = sgs.Skill_Frequent , --这句话源代码没有，但是我感觉应该加上，毕竟连破一点副作用都没有
	priority = 1,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		local shensimayi = player:getRoom():findPlayerBySkillName("LuaLianpo")
		if (not shensimayi) or (shensimayi:getMark("LuaLianpo") <= 0) then return false end
		local n = shensimayi:getMark("LuaLianpo")
		shensimayi:setMark("LuaLianpo",0)
		if not shensimayi:askForSkillInvoke("LuaLianpo") then return false end
		local p = shensimayi
		local playerdata = sgs.QVariant()
		playerdata:setValue(p)
		room:setTag("LuaLianpoInvoke", playerdata)
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end ,
}
LuaLianpoDo = sgs.CreateTriggerSkill{
	name = "LuaLianpo-do" ,
	events = {sgs.EventPhaseStart}
	priority = 1 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("LuaLianpoInvoke") then
			local target = room:getTag("LuaLianpoInvoke"):toPlayer()
			room:removeTag("LuaLianpoInvoke")
			if target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end
}
--[[
	技能名：绝境（锁定技）
	相关武将：神·赵云
	描述：摸牌阶段，你摸牌的数量改为你已损失的体力值+2；你的手牌上限+2。
	引用：LuaJuejing、LuaJuejingDraw
	状态：0610待验证
]]--
LuaJuejing = sgs.CreateMaxCardsSkill{
	name = "LuaJuejing" ,
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return 2
		else
			return 0
		end
	end 
}
LuaJuejingDraw = sgs.CreateTriggerSkill{
	name = "#LuaJuejing-draw" ,
	events = {sgs.DrawNCards} ,
	on_trigger = function(self, event, player, data)
		data:setValue(data:toInt() + player:getLostHp())
	end
}
--[[
	技能名：龙魂
	相关武将：神·赵云
	描述：你可以将同花色的X张牌按下列规则使用或打出：红桃当【桃】，方块当具火焰伤害的【杀】，梅花当【闪】，黑桃当【无懈可击】（X为你当前的体力值且至少为1）。
	引用：LuaLonghun
	状态：0610待验证
]]--
LuaLonghun = sgs.CreateViewAsSkill{
	name = "LuaLonghun" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		local n = math.max(1, sgs.Self:getHp())
		if (#selected >= n) or to_select:hasFlag("using") return false end
		if (n > 1) and (not (#selected == 0)) then
			local suit = selected[1]:getSuit()
			return to_select:getSuit() == suit
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Self:isWounded() and (to_select:getSuit() == sgs.Card_Heart) then
				return true
			elseif sgs.Slash:isAvailable(sgs.Self) and (to_select:getSuit() == sgs.Card_Diamond) then
				if sgs.Self:getWeapon() and (to_select:getEffectiveId() == self:getWeapon():getId()) 
						and to_select:isKindOf("Crossbow") then
					return sgs.Self:canSlashWithoutCrossbow()
				else
					return true
				end
			else
				return false
			end
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				return to_select:getSuit() == sgs.Card_Club
			elseif pattern = "nullification" then
				return to_select:getSuit() == sgs.Card_Spade
			elseif string.find(pattern, "peach") then
				return to_select:getSuit() == sgs.Card_Heart
			elseif pattern == "slash" then
				return to_select:getSuit() == sgs.Card_Diamond
			end
			return false
		end
		return false
	end ,
	view_as = function(self, cards)
		local n = math.max(1, sgs.Self:getHp())
		if #cards ~= n then return nil end
		local card = cards[1]
		local new_card = nil
		if card:getSuit() == sgs.Card_Spade then
			new_card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Heart then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0) 
		elseif card:getSuit() == sgs.Card_Club then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Diamond then
			new_card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			new_card:setSkillName(self:objectName())
			for _, c in ipairs(cards) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end ,
	enabled_at_play = function(self, player)
		return player:isWounded() or sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash")
				or (pattern == "jink")
				or (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")))
				or (pattern == "nullification")
	end ,
	enabled_at_nullification = function(self, player)
		local n = math.max(1, player:getHp())
		local count = 0
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= n then return true end
		end
		for _, card in sgs.qlist(player:getEquips()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= n then return true end
		end
	end
}

--[[
	技能名：啖酪
	相关武将：SP·杨修
	描述：当一张锦囊牌指定包括你在内的多名目标后，你可以摸一张牌，若如此做，此锦囊牌对你无效。
	引用：LuaDanlao
	状态：0610待验证
]]--
LuaDanalao = sgs.CreateTriggerSkill{
	name = "LuaDanlao" ,
	events = {sgs.TargetConfirmed, sgs.CardEffected} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (use.to:length <= 1) or (not use.to:contains(player)) or (not use.card:isKindOf("TrickCard")) then
				return false
			end
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			player:setTag("LuaDanlao", sgs.QVariant(use.card:toString()))
			player:drawCards(1)
		else
			if (not player:isAlive()) or (not player:hasSkill(self:objectName())) then return false end
			local effect = data:toCardEffect()
			if player:getTag("LuaDanlao"):isNull() or (player:getTag("LuaDanlao"):toString() ~= effect.card:toString()) then return false end
			player:setTag("LuaDanlao", sgs.QVariant(""))
			return true
		end
		return false
	end
}
--[[
	技能名：庸肆（锁定技）
	相关武将：SP·袁术、SP·台版袁术
	描述：摸牌阶段，你额外摸等同于现存势力数的牌；弃牌阶段开始时，你须弃置等同于现存势力数的牌。
	引用：LuaYongsi
	状态：0610待验证
]]--
getKingdomsYongsi = function(yuanshu)
	local kingdoms = {}
	local room = yuanshu:getRoom()
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		local flag = true
		for _, k in ipairs(kingdoms) do
			if p:getKingdom() == k then
				flag = false
				break
			end
		end
		if flag then table.insert(kingdoms, p:getKingdom()) end
	end
	return #kingdoms
end
LuaYongsi = sgs.CreateTriggerSkill{
	name = "LuaYongsi" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.DrawNCards, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = getKingdomsYongsi(player)
		if event == sgs.DrawNCards then
			data:setValue(data:toInt() + x)
		elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Discard) then
			if x > 0 then
				room:askForDiscard(player, "LuaYongsi", x, x, false, true)
			end
		end
		return false
	end
}

--[[
	技能名：义从（锁定技）
	相关武将：SP·公孙瓒、翼·公孙瓒、翼·赵云
	描述：若你当前的体力值大于2，你计算的与其他角色的距离-1；若你当前的体力值小于或等于2，其他角色计算的与你的距离+1。
	引用：LuaYicong
	状态：0610待验证
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
	技能名：单骑（觉醒技）
	相关武将：SP·关羽
	描述：准备阶段开始时，若你的手牌数大于体力值，且本局游戏主公为曹操，你减1点体力上限，然后获得技能“马术”。
	引用：LuaDanji
	状态：0610待验证
]]--
LuaDanji = sgs.CreateTriggerSkill{
	name = "LuaDanji" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local the_lord = room:getLord()
		if the_lord and ((the_lord:getGeneralName() == "caocao") or (the_lord:getGeneral2Name() == "caocao")) then
			room:addPlayerMark(player, "danji")
			if room:changeMaxHpForAwakenSkill(player) then
				room:acquireSkill(player, "mashu")
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getPhase() == sgs.Player_Start)
				and (target:getMark("danji") == 0)
				and (target:getHandcardNum() > target:getHp())
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
	状态：0610待验证
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
	技能名：血祭
	相关武将：SP·关银屏
	描述：出牌阶段限一次，你可以弃置一张红色牌并选择你攻击范围内的至多X名其他角色，对这些角色各造成1点伤害（X为你已损失的体力值），然后这些角色各摸一张牌。
	引用：LuaXueji
	状态：0610待验证
]]--
LuaXuejiCard = sgs.CreateSkillCard{
	name = "LuaXuejiCard" ,
	filter = function(self, targets, to_select)
		if #targets >= sgs.Self:getLostHp() then return false end
		if to_select:objectName() == sgs.Self:objectName() then return false end
		local range_fix = 0
		if sgs.Self:getWeapon() and (sgs.Self:getWeapon():getEffectiveId() == self:getEffectiveId()) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			range_fix = range_fix + weapon:getRange() - 1
		elseif sgs.Self:getOffensiveHorse() and (self:getOffensiveHorse():getEffectiveId() == self:getEffectiveId()) then
			range_fix = range_fix + 1
		end
		return sgs.Self:distanceTo(to_select, range_fix) <= sgs.Self:getAttackRange()
	end ,
	on_use = function(self, room, source, targets)
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.reason = "LuaXueji" 
		for _, p in ipairs(targets) do
			damage.to = p
			room:damage(damage)
		end
		for _, p in ipairs(targets) do
			if p:isAlive() then
				p:drawCards(1)
			end
		end
	end
}
LuaXueji = sgs.CreateViewAsSkill{
	name = "LuaXueji" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if #selected >= 1 then return false end
		return to_select:isRed() and (not self:isJilei(to_select))
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local first = LuaXuejiCard:clone()
		first:addSubcard(cards[1]:getId())
		first:setSkillName(self:objectName())
		return first
	end ,
	enabled_at_play = function(self, player)
		return (player:getLostHp() > 0) and player:canDiscard(player, "he") and (not player:hasUsed("#LuaXuejiCard"))
	end 
}
--[[
	技能名：虎啸
	相关武将：SP·关银屏
	描述：你于出牌阶段每使用一张【杀】被【闪】抵消，此阶段你可以额外使用一张【杀】。 
	引用：LuaHuxiaoCount、LuaHuxiao、LuaHuxiaoClear
	状态：0610待验证
]]--
LuaHuxiao = sgs.CreateTargetModSkill{
	name = "LuaHuxiao" ,
	residue_func = function(self, from)
		if from:hasSkill(self:objectName())
			return from:getMark(self:objectName())
		else
			return 0
		end
	end
}
LuaHuxiaoCount = sgs.CreateTriggerSkill{
	name = "#LuaHuxiao-count" ,
	events = {sgs.SlashMissed, sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.SlashMissed then
			if player:getPhase(sgs.Player_Play) then
				room:addPlayerMark(player, "LuaHuxiao")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				if player:getMark("LuaHuxiao") > 0 then
					room:setPlayerMark(player, "LuaHuxiao", 0)
				end
			end
		end
		return false
	end 
}
LuaHuxiaoClear = sgs.CreateTriggerSkill{
	name = "LuaHuxiao-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaHuxiao" then
			player:getRoom():setPlayerMark(player, "LuaHuxiao", 0)
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：武继（觉醒技）
	相关武将：SP·关银屏
	描述：结束阶段开始时，若你于此回合内已造成3点或更多伤害，你加1点体力上限，回复1点体力，然后失去技能“虎啸”。
	引用：LuaWujiCount、LuaWuji
	状态：0610待验证
]]--
LuaWujiCount = sgs.CreateTriggerSkill{
	name = "#LuaWuji-count" ,
	events = {sgs.PreDamageDone, sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreDamageDone then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and (damage.from:objectName() == room:getCurrent():objectName()) and (damage.from:getMark("LuaWuji") == 0) then
				room:addPlayerMark(damage.from, "LuaWuji_damage", damage.damage)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:getMark("LuaWuji_damage") > 0 then
					room:setPlayerMark(player, "LuaWuji_damage", 0)
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
LuaWuji = sgs.CreateTriggerSkill{
	name = "LuaWuji",
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "LuaWuji")
		if room:changeMaxHpForAwakenSkill(player, 1) then
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
			room:detachSkillFromPlayer(player, "huxiao")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getPhase() == sgs.Player_Finish)
				and (target:getMark("LuaWuji") == 0)
				and (target:getMark("LuaWuji_damage") >= 3)
	end
}

--[[
	技能名：笔伐
	相关武将：SP·陈琳
	描述：结束阶段开始时，你可以将一张手牌移出游戏并选择一名其他角色，该角色的回合开始时，观看该牌，然后选择一项：交给你一张与该牌类型相同的牌并获得该牌，或将该牌置入弃牌堆并失去1点体力。
	引用：LuaBifa
	状态：0610待验证
]]--

LuaBifaCard = sgs.CreateSkillCard{
	name = "LuaBifaCard" ,
	will_throw = false ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:getPile("LuaBifa"):isEmpty()) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local _data = sgs.QVariant()
		_data:setValue(source)
		target:setTag("LuaBifaSource" .. tostring(self:getEffectiveId()), _data)
		target:addToPile("LuaBifa", self, false)
	end
}
LuaBifaVS = sgs.CreateViewAsSkill{
	name = "LuaBifa" ,
	n = 1;
	view_fliter = function(self, selected, to_select)
		return (#selected == 0) and (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		local card = LuaBifaCard:clone()
		card:addSubcard(cards[1])
		return card
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaBifa"
	end ,
}
LuaBifa = sgs.CreateTriggerSkill{
	name = "LuaBifa" ,
	events == {sgs.EventPhaseStart} ,
	view_as_skill = LuaBifaVS ,
	on_trigger = function(self, event, player, data)
		local room = player;getRoom()
		if (player and player:isAlive() and player:hasSkill(self:objectName()) ) and (player:getPhase() == sgs.Player_Finish) and (not player:isKongcheng()) then
			room:askForUseCard(player, "@@LuaBifa", "@bifa-remove", -1, sgs.Card_MethodNone)
		elseif (player:getPhase() == sgs.Player_RoundStart) and (player:getPile("LuaBifa"):length() > 0) then
			local bifa_list = player:getPile("LuaBifa")
			while not bifa_list:isEmpty() do
				local card_id = bifa_list:last()
				local chenlin = player:getTag("LuaBifaSource" .. tostring(card_id)):toPlayer()
				local ids = sgs.IntList()
				ids:append(card_id)
				room:fillAG(ids, player)
				local cd = sgs.Sanguosha:getCard(card_id)
				local pattern = ""
				if cd:idKindOf("BasicCard") then
					pattern = "BasicCard"
				elseif cd:isKindOf("TrickCard") then
					pattern = "TrickCard"
				elseif cd:isKindOf("EquipCard") then
					pattern = "EquipCard"
				end
				local data_for_ai = sgs.QVariant(pattern)
				pattern = pattern .. "|.|.|hand"
				local to_give = nil
				if (not player:isKongcheng()) and chenlin and chenlin:isAlive() then
					to_give = room:askForCard(player, pattern, "@bifa-give", data_for_ai, sgs.Card_MethodNone, chenlin)
				end
				if chenlin and to_give then
					chenlin:obtainCard(to_give, false)
					player:obtainCard(cd, false)
				else
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, self:objectName(), nil)
					room:throwCard(cd, reason, nil)
					room:loseHp(player)
				end
				bifa_list:removeOne(card_id)
				room:clearAG(player)
				player:removeTag("LuaBifaSource" .. tostring(card_id))
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end ,
}

--[[
	技能名：颂词
	相关武将：SP·陈琳
	描述：出牌阶段，你可以选择一项：1、令一名手牌数小于其当前的体力值的角色摸两张牌。2、令一名手牌数大于其当前的体力值的角色弃置两张牌。每名角色每局游戏限一次。
	引用：LuaSongci
	状态：0610待验证
]]--
LuaSongciCard = sgs.CreateSkillCard{
	name = "LuaSongciCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:getMark("@songci") == 0) and (to_select:getHandcardNum() ~= to_select:getHp())
	end ,
	on_effect = function(self, effect)
		local handcard_num = effect.to:getHandcardNum()
		local hp = effect.to:getHp()
		effect.to:gainMark("@songci")
		if handcard_num > hp then
			effect.to:getRoom():askForDiscard(effect.to, "LuaSongci", 2, 2, false, true)
		else
			effect.to:drawCards(2, "LuaSongci")
		end
	end
}
LuaSongciVS = sgs.CreateViewAsSkill{
	name = "LuaSongci" ,
	n = 0 ,
	view_as = function()
		return LuaSongciCard:clone()
	end ,
	enabled_at_play = function(self, player)
		if (player:getMark("@songci") == 0) and (player:getHandCardNum() ~= player:getHp()) then return true end
		for _, sib in sgs.qlist(player:getSiblings()) do
			if (sib:getMark("@songci") == 0) and (sib:getHandcardNum() ~= sib:getHp()) then return true end
		end
		return false
	end
}
LuaSongci = sgs.CreateTriggerSkill{
	name = "LuaSongci" ,
	events = {sgs.Death} ,
	view_as_skill = LuaSongciVS ,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		for _, p in sgs.qlist(player:getRoom():getAllPlayers()) do
			if p:getMark("@songci") > 0 then
				player:getRoom():setPlayerMark(p, "@songci", 0)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
--[[
	技能名：修罗
	相关武将：SP·暴怒战神
	描述：准备阶段开始时，你可以弃置一张与判定区内延时类锦囊牌花色相同的手牌，然后弃置该延时类锦囊牌。
	引用：LuaXiuluo
	状态：0610待验证
]]--
hasDelayedTrickXiuluo = function(target)
	for _, card in sgs.qlist(target:getJudgingArea()) do
		if not card:isKindOf("SkillCard") then return true end
	end
	return false
end
containsTable = function(t, tar)
	for _, i in ipairs(t) do
		if i == tar then return true end
	end
	return false
end
LuaXiuluo = sgs.CreateTriggerSkill{
	name = "LuaXiuluo" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		while hasDelayedTrickXiuluo(player) and player:canDiscard(player, "h") do
			local suits = {}
			for _, jcard in sgs.qlist(player:getJudgingArea()) do
				if not containsTable(suits, jcard:getSuitString()) then
					table.insert(suits, jcard:getSuitString())
				end
			end
			local card = room:askForCard(player, ".|" .. table.concat(suits, ",") .. "|.|hand", "@xiuluo", nil, self:objectName())
			if (not card) or (not hasDelayedTrickXiuluo(player)) then break end
			local avail_list = sgs.IntList()
			local other_list = sgs.IntList()
			for _, jcard in sgs.qlist(player:getJudgingArea()) do
				if jcard:isKindOf("SkillCard") then 
				elseif jcard:getSuit() == card:getSuit() then
					avail_list:append(jcard:getEffectiveId())
				else
					other_list:append(jcard:getEffectiveId())
				end
			end
			local all_list = sgs.IntList()
			for _, l in sgs.qlist(avail_list) do
				all_list:append(l)
			end
			for _, l in sgs.qlist(other_list) do
				all_list:append(l)
			end
			room:fillAG(all_list, nil, other_list)
			local id = room:askForAG(player, avail_list, false, self:objectName())
			room:clearAG()
			room:throwCard(id, nil)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkil(self:objectName()))
				and (target:getPhase() == sgs.Player_Start)
				and target:canDiscard(target, "h")
				and hasDelayedTrickXiuluo(target)
	end
}
--[[
	技能名：神威（锁定技）
	相关武将：SP·暴怒战神
	描述：摸牌阶段，你额外摸两张牌；你的手牌上限+2。
	引用：LuaShenwei、LuaShenweiDraw
	状态：0610待验证
]]--
LuaShenweiDraw = sgs.CreateTriggerSkill{
	name = "#LuaShenwei-draw" ,
	events = {sgs.DrawNCards} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		data:setValue(data:toInt() + 2)
	end
}
LuaShenwei = sgs.CreateMaxCardsSkill{
	name = "LuaShenwei" ,
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return 2
		else
			return 0
		end
	end ,
}
--[[
	技能名：神戟
	相关武将：SP·暴怒战神、2013-3v3·吕布
	描述：若你的装备区没有武器牌，当你使用【杀】时，你可以额外选择至多两个目标。
	状态：0610待验证
]]--
LuaShenji = sgs.CreateTargetModSkill{
	name = "LuaShenji" ,
	extra_target_func = function(self, from)
		if from:hasSkill(self:objectName()) then
			return 2
		else
			return 0
		end
	end ,
}

--[[
	技能名：豹变（锁定技）
	相关武将：SP·夏侯霸
	描述：若你的体力值为3或更少，你视为拥有技能“挑衅”;若你的体力值为2或更少;你视为拥有技能“咆哮”;若你的体力值为1，你视为拥有技能“神速”。 
	引用：LuaBaobian
	状态：0610待验证（使用table全局变量，BaobianSkills Tag的类型由QStringList（在LUA里为table）变为string，然后在技能里面处理字符串（真TM麻烦！））
]]--

acquired_skillsBaobian = {}
detached_skillsBaobian = {}
LuaBaobianChange = function(room, player, hp, skill_name)
	local baobian_skills = player:getTag("LuaBaobianSkills"):toString():split("|")
	if player:getHp() <= hp then
		if not baobian_skills:contains(skill_name) then
			table.insert(acquired_skillsBaobian, skill_name)
			table.insert(baobian_skills, skill_name)
		end
	else
		if baobian_skills:contains(skill_name) then
			table.insert(detached_skillsBaobian, "-" .. skill_name)
			baobian_skills:removeOne(skill_name)
		end
	end
	player:setTag("LuaBaobianSkills", sgs.QVariant(table.concat(baobian_skills, "|")))
end
LuaBaobian = sgs.CreateTriggerSkill{
	name = "LuaBaobian" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.GameStart, sgs.HpChanged, sgs.MaxHpChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local baobian_skills = player:getTag("LuaBaobianSkills"):toString():split("|")
				local detachList = {}
				for _, skill_name in ipairs(baobian_skills) do
					table.insert(detachList, "-" .. skill_name)
				end
				room:handleAcquireDetachSkills(player, table.concat(detachList, "|"))
				player:removeTag("LuaBaobianSkills")
			end
			return false
		elseif event == sgs.EventAcquireSkill then
			if data:toString() ~= self:objectName() then return false end
		end
		if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return false end
		acquired_skillsBaobian = {}
		detached_skillsBaobian = {}
		LuaBaobianChange(room, player, 1, "shensu")
		LuaBaobianChange(room, player, 2, "paoxiao")
		LuaBaobianChange(room, player, 3, "tiaoxin")
		-----------------------------可能bug会很多-----------------------------
		local ac = table.concat(acquired_skillsBaobian, "|")
		local de = table.concat(detached_skillsBaobian, "|")
		local plus = ""
		if ac == "" then
			if de == "" then
				return false
			else
				plus = de
			end
		else
			if de == "" then
				plus = ac
			else
				plus = ac .. "|" .. de
			end
		end
		-----------------------------------------------------------------------
		if plus ~= "" then
			room:handleAcquireDetachSkills(player, plus)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}

--[[
	技能名：星舞
	相关武将：SP·大乔&小乔
	描述：弃牌阶段开始时，你可以将一张与你本回合使用的牌颜色均不同的手牌置于武将牌上。
		若你有三张“星舞牌”，你将其置入弃牌堆，然后选择一名男性角色，你对其造成2点伤害并弃置其装备区的所有牌。
	状态：0610待验证
]]--
LuaXingwu = sgs.CreateTriggerSkill{
	name = "LuaXingwu" ,
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseStart, sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.PreCardUsed) or (event == sgs.CardResponded) then
			local card = nil
			if event == sgs.PreCardUsed then
				card = data:toCard()
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and (card:getTypeId() ~= sgs.Card_TypeSkill) and (card:getHandlingMethod() == sgs.Card_MethodUse) then
				local n = player:getMark()
				if card:isBlack() then
					n = bit32.bor(n, 1)
				elseif card:isRed() then
					n = bit32.bor(n, 2)
				end
				player:setMark(self:objectName(), n)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				local n = player:getMark(self:objectName())
				local red_avail = (bit32.band(n, 2) == 0)
				local black_avail = (bit32.band(n, 1) == 0)
				if player:isKongcheng() or ((not red_avail) and (not black_avail)) then return false end
				local pattern = ".|.|.|hand" 
				if red_avail ~= black_avail then
					if red_avail then
						pattern = ".|red|.|hand"
					else
						pattern = ".|black|.|hand"
					end
				end
				local card = room:askForCard(player, pattern, "@xingwu", nil, sgs.Card_MethodNone)
				if card then
					player:addToPile(self:objectName(), card)
				end
			elseif player:getPhase() == sgs.Player_RoundStart then
				player:setMark(self:objectName(), 0)
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.to:objectName() == player:objectName()) and (move.to_place == sgs.Player_PlaceSpecial) and (player:getPile(self:objectName()):length() >= 3) then
				player:clearOnePrivatePile(self:objectName())
				local males = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers) do
					if p:isMale() then
						males:append(p)
					end
				end
				if males:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, males, self:objectName(), "@xingwu-choose")
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 2))
				if not player:isAlive() then return false end
				local equips = target:getEquips()
				if not equips:isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, equip in sgs.qlist(equips) do
						if player:canDiscard(target, equip:getEffectiveId()) then
							dummy:addSubcard(equip)
						end
					end
					if dummy:subcardsLength() > 0 then
						room:throwCard(dummy, target, player)
					end
				end
			end
		end
		return false
	end
}


--[[
	技能名：黩武
	相关武将：SP·诸葛恪
	描述：出牌阶段，你可以选择攻击范围内的一名其他角色并弃置X张牌：若如此做，你对该角色造成1点伤害。
		若你以此法令该角色进入濒死状态，濒死结算后你失去1点体力，且本阶段你不能再次发动“黩武”。（X为该角色当前的体力值）
	状态：0610待验证
]]--
LuaDuwuCard = sgs.CreateSkillCard{
	name = "LuaDuwuCard" ,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) or (math.max(0, to_select:getHp()) ~= self:subcardsLength()) then return false end
		if (not sgs.Self:inMyAttackRange(to_select)) or (sgs.Self:objectName() == to_select:objectName()) then return false end
		if sgs.Self:getWeapon() and self:getSubcards():contains(sgs.Self:getWeapon():getId()) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			local distance_fix = weapon:getRange() - 1
			if sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
				distance_fix = distance_fix + 1
			end
			return sgs.Self:distanceTo(to_select, distance_fix) <= sgs.Self:getAttackRange()
		elseif sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
			return sgs.Self:distanceTo(to_select, 1) <= sgs.Self:getAttackRange()
		else
			return true
		end
	end ,
	on_effect = function(self, effect)
		effect.from:getRoom():damage(sgs.DamageStruct("LuaDuwu", effect.from, effect.to))
	end
}
LuaDuwuVS = sgs.CreateViewAsSkill{
	name = "LuaDuwu" ,
	n = 999 ,
	view_filter = function()
		return true
	end ,
	view_as = function(self, cards)
		local duwu = LuaDuwuCard:clone()
		if #cards ~= 0 then
			for _, c in ipairs(cards) do
				duwu:addSubcards(c)
			end
		end
		return duwu
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and (not player:hasFlag("LuaDuwuEnterDying"))
	end
}
LuaDuwu = sgs.CreateTriggerSkill{
	name = "LuaDuwu" ,
	events = sgs.QuitDying ,
	view_as_skill = LuaDuwuVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.damage and (dying.damage:getReason() == "LuaDuwu") then
			local from = dying.damage.from
			if from and from:isAlive() then
				room:setPlayerFlag(from, "LuaDuwuEnterDying")
				room:loseHp(from, 1)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end 
}

--[[
	技能名：贞烈
	相关武将：一将成名2012·王异
	描述： 每当你成为一名其他角色使用的【杀】或非延时类锦囊牌的目标后，你可以失去1点体力，令此牌对你无效，然后你弃置其一张牌。
	引用：LuaZhenlie
	状态：0610待验证
]]--
LuaZhenlie = sgs.CreateTriggerSkill{
	name = "LuaZhenlie" ,
	events = {sgs.TargetConfirmed, sgs.CardEffected, sgs.SlashEffected} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				local use = data:toCardUse()
				if use.to:contains(player) and (use.from:objectName() ~= player:objectName()) then
					if use.card:isKindOf("Slash") or use.card:isNDTrick() then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:setCardFlag(use.card, "LuaZhenlieNullify")
							player:setFlags("LuaZhenlieTarget")
							room:loseHp(player)
							if player:isAlive and player:hasFlag("LuaZhenlieTarget") and player:canDiscard(use.from, "he") then
								local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
								room:throwCard(id, use.from, player)
							end
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if (not effect.card:isKindOf("Slash")) and effect.card:hasFlag("LuaZhenlieNullify") and player:hasFlag("LuaZhenlieTarget") then
				player:setFlags("-LuaZhenlieTarget")
				return true
			end
		elseif event == sgs.SlashEffected then
			local effect = data:toSlashEffect()
			if effect.slash:hasFlag("LuaZhenlieNullify") and player:hasFlag("LuaZhenlieTarget") then
				player:setFlags("-LuaZhenlieTarget")
				return true
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}

--[[
	技能名：秘计
	相关武将：一将成名2012·王异
	描述：结束阶段开始时，若你已受伤，你可以摸一至X张牌（X为你已损失的体力值），然后将相同数量的手牌以任意分配方式交给任意数量的其他角色。
	引用：LuaMiji
	状态：0610待验证
]]--
LuaMiji = sgs.CreateTriggerSkill{
	name = "LuaMiji" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getPhase == sgs.Player_Finish) and player:isWounded() then
			if player:askForSkillInvoke(self:objectName()) then
				local draw_num = {}
				for i = 1, player:getLostHp(), 1 do
					table.insert(draw_num, tostring(i))
				end
				local num = tonumber(room:askForChoice(player, "LuaMiji_draw", table.concat(draw_num, "+")))
				player:drawCards(num, self:objectName())
				if not player:isKongcheng() then
					local n = 0
					while true do
						local original_handcardnum = player:getHandcardNum()
						if (n < num) and (not player:isKongcheng()) then
							local handcards = player:getHandcards()
							if (not room:askForYiji(player, handcards, self:objectName(), false, false, false, num - n)) then break end
							n = n + (original_handcardnum - player:getHandcardNum())
						else
							break
						end
					end
					if (n < num) and (not player:isKongcheng()) then
						local rest_num = num - n
						while true do
							local handcard_list = player:handCards()
							--qShuffle(handcard_list);
							math.randomseed(os.time)
							local give = math.random(1, rest_num)
							rest_num = rest_num - give
							local to_give
							if handcard_list:length() < give then
								to_give = handcard_list
							else
								to_give = handcard_list:mid(0, give)
							end
							local receiver = room:getOtherPlayers(player):at(math.random(0, player:aliveCount() - 1))
							local dummy = sgs.Sanguosha:getCard("slash", sgs.Card_NoSuit, 0)
							for _, id in sgs.qlist(to_give) do
								dummy:addSubcard(id)
							end
							room:obtainCard(receiver, dummy, false)
							if (rest_num == 0) or player:isKongcheng() then break end
						end
					end
				end
			end
		end
		return false
	end
}

--[[
	技能名：智愚
	相关武将：二将成名·荀攸
	描述：每当你受到一次伤害后，你可以摸一张牌，然后展示所有手牌，若颜色均相同，伤害来源弃置一张手牌。
	引用：LuaZhiyu
	状态：0610待验证
]]--
LuaZhiyu = sgs.CreateTriggerSkill{
	name = "LuaZhiyu" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			player:drawCards(1)
			local room = player:getRoom()
			if player:isKongcheng() then return false end
			room:showAllCards(player)
			local cards = player:getHandcards()
			local color = cards:first():getColor()
			local same_color = true
			for _, card in sgs.qlist(cards) do
				if card:getColor() ~= color then
					same_color = false
					break
				end
			end
			local damage = data:toDamage()
			if same_color and damage.from and damage.from:canDiscard(damage.from, "h") then
				room:askForDiscard(damage.from, self:objectName(), 1, 1)
			end
		end
	end
}
--[[
	技能名：将驰
	相关武将：二将成名·曹彰
	描述：摸牌阶段，你可以选择一项：1、额外摸一张牌，若如此做，你不能使用或打出【杀】，直到回合结束。2、少摸一张牌，若如此做，出牌阶段你使用【杀】时无距离限制且你可以额外使用一张【杀】，直到回合结束。
	引用：LuaJiangchi、LuaJiangchiTargetMod
	状态：0610待验证
]]--
LuaJiangchi = sgs.CreateTriggerSkill{
	name = "LuaJiangchi" ,
	events = {sgs.DrawNCards} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local choice = room:askForChoice(player, self:objectName(), "jiang+chi+cancel")
		if choice == "cancel" then return false end
		if choice == "jiang" then
			room:setPlayerCardLimitation(player, "use,response", "Slash", true)
			data:setValue(data:toInt() + 1)
			return false
		else
			room:setPlayerFlag(player, "LuaJiangchiInvoke")
			data:setValue(data:toInt() - 1)
			return false
		end
	end
}
LuaJiangchiTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaJiangchi-target" ,
	residue_func = function(self, from)
		if from:hasSkill("LuaJiangchi") and from:hasFlag("LuaJiangchiInvoke") then
			return 1
		else
			return 0
		end
	end ,
	distance_func = function(self, from)
		if from:hasSkill("LuaJiangchi") and from:hasFlag("LuaJiangchiInvoke") then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：潜袭
	相关武将：一将成名2012·马岱
	描述：准备阶段开始时，你可以进行一次判定，然后令一名距离为1的角色不能使用或打出与判定结果颜色相同的手牌，直到回合结束。
	引用：LuaQianxi、LuaQianxiClear
	状态：0610待验证
]]--
LuaQianxi = sgs.CreateTriggerSkill{
	name = "LuaQianxi" ,
	events = {sgs.EventPhaseStart, sgs.FinishJudge} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player and player:isAlive() and player:hasSkill(self:objectName())) and (player:getPhase() == sgs.Player_Start) then
			if room:askForSkillInvoke(player, self:objectName()) then
				local judge = sgs.JudgeStruct()
				judge.reason = self:objectName()
				judge.who = target
				room:judge(judge)
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if (judge.reason ~= self:objectName()) or (not player:isAlive()) then return false end
			local color
			if judge.card:isRed() then
				color = "red"
			else
				color = "black"
			end
			player:setTag(self:objectName(), sgs.QVariant(color))
			local to_choose = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:distanceTo(p)  == 1 then
					to_choose:append(p)
				end
			end
			if to_choose:isEmpty() then return false end
			local victim = room:askForPlayerChosen(player, to_choose, self:objectName())
			local pattern = ".|" .. color .. "|.hand$0"
			room:setPlayerFlag(victim, "LuaQianxiTarget")
			room:addPlayerMark(victim, "@qianxi_" .. color)
			room:setPlayerCardLimitation(victim, "use,response", pattern, false)
		end
		return false
	end ,
	can_trigger = function(self,target)
		return target
	end
}
LuaQianxiClear = sgs.CreateTriggerSkill{
	name = "#LuaQianxi-clear" ,
	events = {sgs.EventPhaseChanging, sgs.Death} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
		end
		local color = player:getTag("LuaQianxi"):toString()
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("LuaQianxiTarget") then
				room:removePlayerCardLimitation(p, "use,response", ".|" .. color .. ".|hand$0")
				room:setPlayerMark(p, "@qianxi_" .. color, 0)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return not (target:getTag("LuaQianxi"):toString() == "")
	end
}

--[[
	技能名：当先（锁定技）
	相关武将：二将成名·廖化
	描述：回合开始时，你执行一个额外的出牌阶段。
	引用：LuaDangxian
	状态：0610待验证
]]--
LuaDangxian = sgs.CreateTriggerSkill{
	name = "LuaDangxian" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_RoundStart then
			local room = player:getRoom()
			local thread = room:getThread()
			player:setPhase(sgs.Player_Play)
			room:broadcastProperty(player, "phase")
			if not thread:trigger(sgs.EventPhaseStart, room, player) then
				thread:trigger(sgs.EventPhaseProceeding, room, player)
			end
			thread:trigger(sgs.EventPhaseEnd, room, player)
			player:setPhase(sgs.Player_RoundStart)
			room:broadcastProperty(player, "phase")
		end
	end 
}

--[[
	技能名：伏枥（限定技）
	相关武将：二将成名·廖化
	描述：当你处于濒死状态时，你可以将体力回复至X点（X为现存势力数），然后将你的武将牌翻面。
	引用：LuaFuli、LuaLaoji1
	状态：0610待验证
	备注：需调用庸嗣部分的getKingdomsYongsi函数
]]--
LuaFuli = sgs.CreateTriggerSkill{
	name = "LuaFuli" ,
	frequency = sgs.Skill_Limited ,
	events = {sgs.AskForPeaches} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		if dying_data.who:objectName() ~= player:objectName() then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
			room:removePlayerMark(player, "@laoji")
			local recover = sgs.RecoverStruct()
			recover.recover = math.min(getKingdomsYongsi(player), player:getMaxHp()) - player:getHp()
			room:recover(player, recover)
			player:turnOver()
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName())) and (target:getMark("@laoji") > 0)
	end
}
LuaLaoji1 = sgs.CreateTriggerSkill{
	name = "#@laoji-Lua-1" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		player:gainMark("@laoji", 1)
	end
}

--[[
	技能名：自守
	相关武将：二将成名·刘表
	描述：摸牌阶段，若你已受伤，你可以额外摸X张牌（X为你已损失的体力值），然后跳过你的出牌阶段。
	引用：LuaZishou
	状态：0610待验证
]]--
LuaZishou = sgs.CreateTriggerSkill{
	name = "LuaZishou" ,
	events = {sgs.DrawNCards} ,
	on_trigger = function(self, event, player, data)
		local n = data:toInt()
		local room = player:getRoom()
		if player:isWounded() then
			if room:askForSkillInvoke(player, self:objectName()) then
				local losthp = player:getLostHp()
				player:clearHistory()
				player:skip(sgs.Player_Play)
				data:setValue(n + losthp)
			else
				data:setValue(n)
			end
		else
			data:setValue(n)
		end
	end
}
--[[
	技能名：宗室（锁定技）
	相关武将：二将成名·刘表
	描述：你的手牌上限+X（X为现存势力数）。
	引用：LuaZongshi
	状态：0610待验证
]]--
LuaZongshi = sgs.CreateMaxCardsSkill{
	name = "LuaZongshi" ,
	extra_func = function(self, target)
		local extra = 0
		local kingdom_set = {}
		table.insert(kingdom_set, target:getKingdom())
		for _, p in sgs.qlist(target:getSiblings()) do
			local flag = true
			for _, k in ipairs(kingdoms) do
				if p:getKingdom() == k then
					flag = false
					break
				end
			end
			if flag then table.insert(kingdom_set, p:getKingdom()) end
		end
		extra = #kingdom_set
		if target:hasSkill(self:objectName()) then
			return extra
		else
			return 0
		end
	end
}
--[[
	技能名：恃勇（锁定技）
	相关武将：二将成名·华雄
	描述：每当你受到一次红色的【杀】或因【酒】生效而伤害+1的【杀】造成的伤害后，你减1点体力上限。
	引用：LuaShiyong
	状态：0610待验证
]]--
LuaShiyong = sgs.CreateTriggerSkill{
	name = "LuaShiyong" ,
	events = {sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash")
				and (damage.card:isRed() or damage.card:hasFlag("drank")) then
			player:getRoom():loseMaxHp(player)
		end
		return false
	end
}

--[[
	技能名：弓骑
	相关武将：一将成名2012·韩当
	描述：出牌阶段限一次，你可以弃置一张牌，令你于此回合内攻击范围无限，若你以此法弃置的牌为装备牌，你可以弃置一名其他角色的一张牌。
	引用：LuaGongqi
	状态：0610待验证
]]--
LuaGongqiCard = sgs.CreateSkillCard{
	name = "LuaGongqiCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(source, "InfinityAttackRage")
		local cd = sgs.Sanguosha:getCard(self:getSubcards():first())
		if cd:isKindOf("EquipCard") then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if source:canDiscard(p, "he") then _targets:append(p) end
			end
			if not _targets:isEmpty() then
				local to_discard = room:askForPlayerChosen(source, _targets, "LuaGongqi", "@gongqi-discard", true)
				if to_discard then
					room:throwCard(room:askForCardChosen(source, to_discard, "he", "LuaGongqi", false, sgs.Card_MethodDiscard), to_discard, source)
				end
			end
		end
	end
}
LuaGongqi = sgs.CreateViewAsSkill{
	name = "LuaGongqi" ,
	n = 1 ,
	view_filter = function(self, cards, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = LuaGongqiCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaGongqiCard")
	end
}

--[[
	技能名：父魂
	相关武将：一将成名2012·关兴&张苞
	描述：你可以将两张手牌当普通【杀】使用或打出。每当你于出牌阶段内以此法使用【杀】造成伤害后，你获得技能“武圣”、“咆哮”，直到回合结束。
	引用：LuaFuhun
	状态：0610待验证 
]]--
LuaFuhunVS = sgs.CreateViewAsSkill{
	name = "LuaFuhun" ,
	n = 2,
	view_filter = function(self, selected, to_select)
		return (#selected < 2) and (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_SuitToBeDecided, 0)
		slash:setSkillName(self:objectName())
		slash:addSubcard(cards[1])
		slash:addSubcard(cards[2])
		return slash
	end ,
	enabled_at_play = function(self, player)
		return (player:getHandcardNum() >= 2) and sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return (player:getHandcardNum() >= 2) and (pattern == "slash")
	end
}
LuaFuhun = sgs.CreateTriggerSkill{
	name = "LuaFuhun" ,
	events = {sgs.Damage, sgs.EventPhaseChanging} ,
	view_as_skill = LuaFuhunVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) and (player and player:isAlive() and player:hasSkill(self:objectName())) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and (damage.card:getSkillName() == self:objectName())
					and (player:getPhase == sgs.Player_Play) then
				room:handleAcquireDetachSkills(player, "wusheng|paoxiao")
				player:setFlags(self:objectName())
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) and player:hasFlag(self:objectName()) then
				room:handleAcquireDetachSkills(player, "-wusheng|-paoxiao")
			end
		end
		return false
	end
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：解烦（限定技）
	相关武将：二将成名·韩当
	描述：出牌阶段，你可以指定一名角色，攻击范围内含有该角色的所有角色须依次选择一项：弃置一张武器牌；或令该角色摸一张牌。 
	引用：LuaJiefan、LuaRescue1
	状态：0610待验证
]]--
LuaJiefanCard = sgs.CreateSkillCard{
	name = "LuaJiefanCard" ,
	filter = function(self, targets, to_select)
		return #targets == 0
	end  ,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@rescue")
		local target = targets[1]
		local _targetdata = sgs.QVariant()
		_targetdata:setValue(target)
		source:setTag("LuaJiefanTarget", _targetdata)
		for _, player in sgs.qlist(room:getAllPlayers()) do
			if player:isAlive() and player:inMyAttackRange(target) then
				room:cardEffect(self, source, player)
			end
		end
		source:removeTag("LuaJiefanTarget")
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local target = effect.from:getTag("LuaJiefanTarget"):toPlayer()
		local data = effect.from:getTag("LuaJiefanTarget")
		if target then
			if not room:askForCard(effect.to, ".Weapon", "@jiefan-discard::" .. target:objectName(), data) then
				target:drawCards(1)
			end
		end
	end
}
LuaJiefanVS = sgs.CreateViewAsSkill{
	name = "LuaJiefan" ,
	n = 0,
	view_as = function()
		return LuaJiefanCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@rescue") >= 1
	end
}
LuaJiefan = sgs.CreateTriggerSkill{
	name = "LuaJiefan" ,
	frequency = sgs.Skill_Limited ,
	events = {} ,
	view_as_skill = LuaJiefanVS ,
	on_trigger = function()
		return false
	end ,
}
LuaRescue1 = sgs.CreateTriggerSkill{
	name = "#@rescue-Lua-1" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		player:gainMark("@rescue", 1)
	end ,
}
--[[
	技能名：安恤
	相关武将：二将成名·步练师
	描述：出牌阶段限一次，你可以选择两名手牌数不相等的其他角色，令其中手牌少的角色获得手牌多的角色的一张手牌并展示之，若此牌不为♠，你摸一张牌。
	引用：LuaAnxu
	状态：0610待验证
]]--
LuaAnxuCard = sgs.CreateSkillCard{
	name = "LuaAnxuCard" ,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if #targets == 0 then 
			return true
		elseif #targets == 1 then
			return (to_select:getHandcardNum() ~= targets[1]:getHandcardNum())
		else
			return false
		end
	end ,
	feasible = function(self, targets)
		return #targets == 2
	end ,
	on_use = function(self, room, source, targets)
		local from
		local to
		if targets[1]:getHandcardNum() < targets[2]:getHandcardNum() then
			from = targets[1]
			to = targets[2]
		else
			from = targets[2]
			to = targets[1]
		end
		local id = room:askForPlayerChosen(from, to, "h", "LuaAnxu")
		local cd = sgs.Sanguosha:getCard(id)
		room:obtainCard(from, cd)
		room:showCard(from, id)
		if cd:getSuit() ~= sgs.Card_Spade then
			source:drawCards(1)
		end
	end ,
}
LuaAnxu = sgs.CreateViewAsSkill{
	name = "LuaAnxu" ,
	n = 0,
	view_as = function()
		return LuaAnxuCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaAnxuCard")
	end
}

--[[
	技能名：追忆
	相关武将：二将成名·步练师
	描述：你死亡时，可以令一名其他角色（杀死你的角色除外）摸三张牌并回复1点体力。
	引用：LuaZhuiyi
	状态：0610待验证
]]--
LuaZhuiyi = sgs.CreateTriggerSkill{
	name = "LuaZhuiyi" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local targets
		if death.damage and death.damage.from then
			targets = room:getOtherPlayers(death.damage.from)
		else
			targets = room:getAlivePlayers()
		end
		if targets:isEmpty() then return false end
		local prompt = "zhuiyi-invoke"
		if death.damage and death.damage.from and (death.damage.from:objectName() ~= player:objectName()) then
			prompt = "zhuiyi-invokex:" .. death.damage.from:objectName()
		end
		local target = room:askForPlyaerChosen(player, targets, self:objectName(), prompt, true, true)
		if not target then return false end
		target:drawCards(3)
		local recover = sgs.RecoverStruct()
		recover.who = player
		recover.recover = 1
		room:recover(target, recover, true)
		return false
	end
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}

--[[
	技能名：醇醪
	相关武将：二将成名·程普
	描述：结束阶段开始时，若你的武将牌上没有牌，你可以将任意数量的【杀】置于你的武将牌上，称为“醇”；当一名角色处于濒死状态时，你可以将一张“醇”置入弃牌堆，令该角色视为使用一张【酒】。
	引用：LuaChunlao、LuaChunlaoClear
	状态：0610待验证
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
			room:useCard(sgs.CardUseSTruct(analeptic, who, who, false))
		end
	end
}
LuaChunlaoVS = sgs.CreateViewAsSkill{
	name = "LuaChunlao" ,
	n = 999,
	view_filter = function(self, cards, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@LuaChunlao" then
			return to_selct:isKindOf("Slash")
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
				and (player:getPhase == sgs.Player_Finish)
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
	技能名：冲阵
	相关武将：☆SP·赵云
	描述：每当你发动“龙胆”使用或打出一张手牌时，你可以立即获得对方的一张手牌。
	引用：LuaChongzhen
	状态：0610待验证
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
						local card_id = room:askForCardChosen(player, resp.m_who, "h", self:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：离魂
	相关武将：☆SP·貂蝉
	描述：出牌阶段限一次，你可以弃置一张牌将武将牌翻面，然后获得一名男性角色的所有手牌，且出牌阶段结束时，你交给该角色X张牌。（X为该角色的体力值）
	引用：LuaLihun
	状态：0610待验证
]]--
LuaLihunCard = sgs.CreateSkillCard{
	name = "LuaLihunCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to:select:isMale() and (to:select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		effect.from:turnOver()
		local dummy_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, cd in sgs.qlist(effect.to:getHandcards()) do
			dummy_card:addSubcard(cd)
		end
		if not effect.to:isKongcheng() then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, effect.from:objectName()
											  effect.to:objectName(), "LuaLihun", nil)
			room:moveCardTo(dummy_card, effect.to, effect.from, sgs.Player_PlaceHand, reason, false)
		end
		effect.to:setFlags("LuaLihunTarget")
	end
}
LuaLihunVS = sgs.CreateViewAsSkill{
	name = "LuaLihun" ,
	n = 1,
	view_filter = function(self, cards, to_select)
		if #cards == 0 then
			return not sgs.Self:isJilei(to_select)
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = LuaLihunCard:clone()
		card:addSubcard(cards[1])
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and (not player:hasUsed("#LuaLihunCard"))
	end
}
LuaLihun = sgs.CreateTriggerSkill{
	name = "LuaLihun" ,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd} ,
	view_as_skill = LuaLihunVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseEnd) and (player:getPhase() == sgs.Player_Play) then
			local target
			for _, other in sgs.qlist(room:getOtherPlayers(player)) do
				if other:hasFlag("LuaLihunTarget") then
					other:setFlags("-LuaLihunTarget")
					target = other
					break
				end
			end
			if (not target) or (target:getHp() < 1) or player:isNude() then return false end
			local to_back = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if player:getCardCount(true) <= target:getHp() then
				if not player:isKongcheng() then to_goback = player:wholeHandCards() end
				for i = 0, 3, 1 do
					if player:getEquip(i) then to_goback:addSubcard(player:getEquip(i):getEffectiveId()) end
				end
			else
				to_goback = room:askForExchange(player, self:objectName(), target:getHp(), true, "LuaLihunGoBack")
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), nil)
			reason_m.playerId = target:objectName()
			room:moveCardTo(to_goback, player, target, sgs.Player_PlaceHand, reason)
		elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_NotActive) then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("LuaLihunTarget") then
					p:setFlags("-LuaLihunTarget")
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return target and target:hasUsed("#LuaLihunCard")
	end
}

--[[
	技能名：溃围
	相关武将：☆SP·曹仁
	描述：结束阶段开始时，你可以摸X+2张牌，然后将你的武将牌翻面，且你的下个摸牌阶段开始时，你弃置X张牌。（X为当前场上武器牌的数量）
	引用：LuaKuiwei
	状态：0610待验证
]]--
getWeaponCountKuiwei = function(caoren)
	local n = 0
	for _, p in sgs.qlist(caoren:getRoom():getAlivePlayers()) do
		if p:getWeapon() then n = n + 1 end
	end
	return n
end
LuaKuiwei = sgs.CreateTriggerSkill{
	name = "LuaKuiwei" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			if not player:hasSkill(self:objectName()) then return false end
			if not player:askForSkillInvoke(self:objectName()) then return false end
			local n = getWeaponCountKuiwei(player)
			player:drawCards(n + 2)
			player:turnOver()
			if player:getMark("@kuiwei") == 0 then
				player:getRoom():addPlayerMark(player, "@kuiwei")
			end
		elseif player:getPhase() == sgs.Player_Draw then
			if player:getMark("@kuiwei") == 0 then return false end
			local room = player:getRoom()
			room:removePlayerMark(player, "@kuiwei")
			local n = getWeaponCountKuiwei(player)
			if n > 0 then
				room:askForDiscard(player, self:objectName(), n, n, false, true)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and (target:hasSkill(self:objectName()) or (target:getMark("@kuiwei") > 0))
	end
}
--[[
	技能名：严整
	相关武将：☆SP·曹仁
	描述：若你的手牌数大于你的体力值，你可以将你装备区内的牌当【无懈可击】使用。
	引用：LuaYanzheng
	状态：0610待验证
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
	技能名：漫卷
	相关武将：☆SP·庞统
	描述：每当你将获得任何一张手牌，将之置于弃牌堆。若此情况处于你的回合中，你可依次将与该牌点数相同的一张牌从弃牌堆置于你的手上。
	引用：LuaManjuan
	状态：0610待验证
]]--

LuaDoManjuan = function(sp_pangtong, card_id)
	local room = sp_pangtong:getRoom()
	sp_pangtong:setFlags("LuaManjuanInvoke")
	local DiscardPile = room:getDiscardPile()
	local toGainList = sgs.IntList()
	local card = sgs.Sanguosha:getCard(card_id)
	for _, id in sgs.qlist(DiscardPile) do
		local cd = sgs.Sanguosha:getCard(id)
		if cd:getNumber() == card:getNumber() then
			toGainList:append(id)
		end
	end
	if toGainList:isEmpty() then return end
	room:fillAG(toGainList, sp_pangtong)
	local id = room:askForAG(sp_pangtong, toGainList, false, self:objectName())
	if id ~= -1 then
		room:moveCardTo(sgs.Sanguosha:getCard(id), sp_pangtong, sgs.Player_PlaceHand, true)
	end
	room:clearAG(sp_pangtong)
end
LuaManjuan = sgs.CreateTriggerSkill{
	name = "LuaManjuan" ,
	events = {sgs.BeforeCardsMove} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data)
		if player:hasFlag("LuaManjuanInvoke") then
			player:setFlags("-LuaManjuanInvoke")
			return false
		end
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local ids = sgs.IntList()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "LuaManjuan", nil)
		if room:getTag("FirstRound"):toBool() then return false end
		if player:hasFlag("LuaManjuanNullified") then return false end
		if (move.to and (move.to:objectName() ~= player:objectName())) or (move.to_place ~= sgs.Player_PlaceHand) then return false end
		for _, card_id in sgs.qlist(move.card_ids) do
			local card = sgs.Sanguosha:getCard(card_id)
			room:moveCardTo(card, nil, nil, sgs.Player_DiscardPile, reason)
		end
		ids = move.card_ids
		move.card_ids:clear()
		data:setValue(move)
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		if not player:askForSkillInvoke(self:objectName(), data) then return false end
		for _, _card_id in sgs.qlist(ids) do
			LuaDoManjuan(player, _card_id)
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
		player:getRoom():setPlayerMark(player, "@sleep", 1)
	end ,
}

--[[
	技能名：嫉恶（锁定技）
	相关武将：☆SP·张飞
	描述：你使用的红色【杀】造成的伤害+1。
	引用：LuaJie
	状态：0610待验证
]]--
LuaJie = sgs.CreateTriggerSkill{ -- 其实我感觉这个技能应该是“ji wu”
	name = "LuaJie" ,
	events == {sgs.DamageCaused} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.chain or damage.transfer or (not damage.by_user)
				or (not damage.card) or (not damage.card:isKindOf("Slash")) or (not damage.card:isRed()) then
			return false
		end
		damage.damage = damage.damage + 1
		data:setValue(damage)
		return false
	end
}
--[[
	技能名：大喝
	相关武将：☆SP·张飞
	描述：出牌阶段限一次，你可以与一名角色拼点：若你赢，你可以将该角色的拼点牌交给一名体力值不多于你的角色，本回合该角色使用的非♥【闪】无效；若你没赢，你展示所有手牌，然后弃置一张手牌。
	引用：LuaDahe、LuaDahePD
	状态：0610待验证
]]--
LuaDaheCard = sgs.CreateSkillCard{
	name = "LuaDaheCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName())
	end
	on_use = function(self, room, source, targets)
		source:pindian(targets[1], "LuaDahe", nil)
	end
}
LuaDaheVS = sgs.CreateViewAsSkill{
	name = "LuaDahe" ,
	n = 0 ,
	view_as = function()
		return LuaDaheCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#LuaDaheCard")) and (not player:isKongcheng())
	end
}
LuaDahe = sgs.CreateTriggerSkill{
	name = "LuaDahe" ,
	events = {sgs.JinkEffect, sgs.EventPhaseChanging, sgs.Death}
	view_as_skill = LuaDaheVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.JinkEffect() then
			local jink = data:toCard()
			local bgm_zhangfei = room:findPlayerBySkillName(self:objectName())
			if bgm_zhangfei and bgm_zhangfei:isAlive() and player:hasFlag(self:objectName()) and (jink:getSuit() ~= sgs.Card_Heart) then
				return true
			end
			return false
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
		end
		for _, other in sgs.qlist(room:getOtherPlayers(player)) do
			if other:hasFlag(self:objectName()) then
				room:setPlayerFlag(other, "-" .. self:objectName())
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
LuaDahePD = sgs.CreateTriggerSkill{
	name = "#LuaDahe" ,
	events == {sgs.Pindian} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pindian = data:toPindian()
		if (pindian.reason ~= "LuaDahe") or (not pindian.from:hasSkill(self:objectName())) 
				or (room:getCardPlace(pindian.to_card:getEffectiveID()) ~= sgs.Player_PlaceTable) then
			return false
		end
		if pindian:isSuccess() then
			room:setPlayerFlag(pindian.to, "LuaDahe")
			local to_givelist = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() <= pindian.from:getHp() then
					to_givelist:append(p)
				end
			end
			if not to_givelist:isEmpty() then
				local to_give = room:askForPlayerChosen(pindian.from, to_givelist, "LuaDahe", "@dahe-give", true)
				if not to_give then return false end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, pindian.from:objectName())
				reason.m_playerId = to_give:objectName()
				to_give:obtainCard(pindian.to_card)
			end
		else
			if not pindian.from:isKongcheng() then
				room:showAllCards(pindian.from)
				room:askForDiscard(pindian.from, "LuaDahe", 1, 1, false, false)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：探虎
	相关武将：☆SP·吕蒙
	描述：出牌阶段限一次，你可以与一名角色拼点：若你赢，你拥有以下锁定技：你无视与该角色的距离，你使用的非延时类锦囊牌对该角色结算时不能被【无懈可击】响应，直到回合结束。
	引用：LuaTanhu
	状态：0610待验证
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
	n = 0
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
				if change.to ~= sgs.Player_NotActive() then return false end
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
	技能名：谋断（转化技）
	相关武将：☆SP·吕蒙
	描述：通常状态下，你拥有标记“武”并拥有技能“激昂”和“谦逊”。当你的手牌数为2张或以下时，你须将你的标记翻面为“文”，将该两项技能转化为“英姿”和“克己”。任一角色的回合开始前，你可弃一张牌将标记翻回。
	引用：LuaMouduanStart、LuaMouduan、LuaMouduanClear
	状态：0610待验证
]]--
LuaMouduanStart = sgs.CreateTriggerSkill{
	name = "#LuaMouduan-start" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:gainMark("@wu")
		room:acquireSkill(player, "jiang")
		room:acquireSkill(player, "qianxun")
	end ,
}
LuaMouduan = sgs.CreateTriggerSkill{
	name = "LuaMouduan" ,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local lvmeng = room:findPlayerBySkillName(self:objectName())
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from:objectName() == player:objectName()) and (player and player:isAlive() and player:hasSkill(self:objectName()))
					and (player:getMark("@wu") > 0) and (player:getHandcardNum() <= 2) then
				player:loseMark("@wu")
				player:gainMark("@wen")
				room:handleAcquireDetachSkills(player, "-jiang|-qianxun|yingzi|keji")
			end
		elseif (player:getPhase() == sgs.Player_RoundStart) and lvmeng and (lvmeng:getMark("@wen") > 0)
				and lvmeng:canDiscard(lvmeng, "he") then
			if room:askForCard(lvmeng, "..", "@LuaMouduan", sgs.QVariant(), self:objectName()) then
				if lvmeng:getHandcardNum() > 2 then
					lvmeng:loseMark("@wen")
					lvmeng:gainMark("@wu")
					room:handleAcquireDetachSkills(lvmeng, "-yingzi|-keji|jiang|qianxun")
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end 
}
LuaMouduanClear = sgs.CreateTriggerSkill{
	name = "#LuaMouduan-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaMouduan" then
			local room = player:getRoom()
			if player:getMark("@wu") > 0 then
				player:loseMark("@wu")
				room:detachSkillFromPlayer(player, "jiang")
				room:detachSkillFromPlayer(player, "qianxun")
			elseif player:getMark("@wen") > 0 then
				player:loseMark("@wen")
				room:detachSkillFromPlayer(player, "yingzi")
				room:detachSkillFormPlayer(player, "keji")
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
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
	技能名：安娴
	相关武将：☆SP·大乔
	描述：每当你使用【杀】对目标角色造成伤害时，你可以防止此次伤害，令其弃置一张手牌，然后你摸一张牌；当你成为【杀】的目标时，你可以弃置一张手牌使之无效，然后该【杀】的使用者摸一张牌。
	引用：LuaAnxian
	状态：0610待验证
]]--
LuaAnxian = sgs.CreateTriggerSkill{
	name = "LuaAnxian" ,
	events = {sgs.DamageCaused, sgs.TargetConfirming, sgs.SlashEffected} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") 
					and damage.by_user and (not damage.chain) and (not damage.transfer) then
				if player:askForSkillInvoke(self:objectName(), data) then
					if damage.to:canDiscard(damage.to, "h") then
						room:askForDiscard(damage.to, "LuaAnxian", 1, 1)
					end
					player:drawCards(1)
					return true
				end
			end
		elseif event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if (not use.to:contains(player)) or (not player:canDiscard(player, "h")) then return false end
			if use.card and use.card:isKindOf("Slash") then
				player:setMark("LuaAnxian", 0)
				if room:askForCard(player, ".", "@anxian-discard", data, self:objectName()) then
					player:addMark("LuaAnxian")
					use.from:drawCards(1)
				end
			end
		elseif event == sgs.SlashEffected then
			local effect = data:toSlashEffect()
			if player:getMark("LuaAnxian") > 0 then
				player:removeMark("LuaAnxian")
				return true
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
	状态：0610待验证
]]--
LuaYinlingCard = sgs.CreateSkillCard{
	name = "LuaYinlingCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if effect.from:canDiscard(effect.to, "he") or (effect.from:getPile("brocade"):length() >= 4) then return end
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
	enabled_at_play = function(self, palyer)
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
	技能名：军威
	相关武将：☆SP·甘宁
	描述：结束阶段开始时，你可以将三张“锦”置入弃牌堆并选择一名角色，令该角色选择一项：1.展示一张【闪】并将该【闪】交给由你选择的一名角色；2.失去1点体力，然后你将其装备区的一张牌移出游戏，该角色的下个回合结束后，将这张装备牌移回其装备区。
	引用：LuaJunwei、LuaJunweiGot
	状态：0610待验证
]]--
LuaJunwei = sgs.CreateTriggerSkill{
	name = "LuaJunwei" ,
	event = {sgs.EventPhaseStart} ,
	on_trigger = function(self ,event, player, data)
		local room = player:getRoom()
		if (player:getPahse() == sgs.Player_Finish) and (player:getPile("brocade"):length() >= 3) then
			local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "junwei-invoke", true, true)
			if not target then return false end
			local brocade = player:getPile("brocade")
			local to_throw = sgs.CardList()
			for i = 0 , 2, 1 do
				local card_id = 0
				room:fillAG(brocade, player)
				if (brocade:length() == 3 - i) then
					card_id = brocade:first()
				else
					card_id = room:askForAG(player, brocade, false, self:objectName())
				end
				room:clearAG(player)
				brocade:removeOne(card_id)
				to_throw:append(sgs.Sanguosha:getCard(card_id))
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:addSubcards(to_throw)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, self:objectName(), nil)
			room:throwCard(dummy, reason, nil)
			local ai_data = sgs.QVariant()
			ai_data:setValue(player)
			local card = room:askForCard(target, "Jink", "@junwei-show", ai_data, sgs.Card_MethodNone)
			if card then
				room:showCard(target, card:getEffectiveId())
				local receiver = room:askForCardChosen(player, room:getAllPlayers(), "LuaJunweigive", "@junwei-give")
				if (receiver:objectName() ~= target:objectName()) then
					receiver:obtainCard(card)
				end
			else
				room:loseHp(target, 1)
				if (not target:isAlive()) then return false end
				if target:hasEquip() then
					local card_id = room:askForCardChosen(player, target, "e", self:objectName())
					target:addToPile("LuaJunwei_equip", card_id)
				end
			end
		end
		return false
	end ,
}
LuaJunweiGot = sgs.CreateTriggerSkill{
	name = "#LuaJunwei-got" ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if (change.to ~= sgs.Player_NotActive) or (player:getPile("LuaJunwei_equip"):length() == 0) then return false end
		for _, card_id in sgs.qlist(player:getPile("LuaJunwei_equip")) do
			local card = sgs.Sanguosha:getCard(card_id)
			local equip_index = -1
			local equip = card:getRealCard():toEquipCard()
			equip_index = equip:location()
			local exchangeMove = sgs.CardsMoveList()
			local move1 = sgs.CardsMoveStruct()
			move1.card_ids:append(card_id)
			move1.to = player
			move1.to_place = sgs.Player_PlaceEquip
			move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName())
			exchangeMove:append(move1)
			if player:getEquip(equip_index) then
				local move2 = sgs.CardsMoveStruct()
				move2.card_ids:append(player:getEquip(equip_index):getId())
				move2.to = nil
				move2.to_place = sgs.Player_DiscardPile
				move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, player:objectName())
				exchangeMove:append(move2)
			end
			room:moveCardsAtomic(exchangeMove, true)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end ,
}

--[[
	技能名：愤勇
	相关武将：☆SP·夏侯惇
	描述：每当你受到一次伤害后，你可以竖置你的体力牌；当你的体力牌为竖置状态时，防止你受到的所有伤害。
	引用：LuaFenyong、LuaFenyongClear
	状态：0610待验证
]]--
LuaFenyong = sgs.CreateTriggerSkill{
	name = "LuaFenyong" ,
	events = {sgs.Damaged, sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			if player:getMark("@fenyong") == 0 then
				if player:askForSkillInvoke(player, self:objectName()) then
					player:gainMark("@fenyong")
				end
			end
		elseif event == sgs.DamageInflicted then
			if player:getMark("@fenyong") > 0 then
				return true
			end
		end
		return false
	end 
}
LuaFenyongClear = sgs.CreateTriggerSkill{
	name = "#LuaFenyong-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaFenyong" then
			player:loseAllMarks("@fenyong")
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}

--[[
	技能名：雪恨（锁定技）
	相关武将：☆SP·夏侯惇
	描述：一名角色的结束阶段开始时，若你的体力牌处于竖置状态，你横置之，然后选择一项：1.弃置当前回合角色X张牌。 2.视为你使用一张无距离限制的【杀】。（X为你已损失的体力值）
	引用：LuaXuehen、LuaXuehenNDL、LuaXuehenFakeMove
	状态：0610待验证
]]--
LuaXuehen = sgs.CreateTriggerSkill{
	name = "LuaXuehen" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local xiahou = room:findPlayerBySkillName(self:objectName())
		if not xiahou then return false end
		if (player:getPhase() == sgs.Player_Finish) and (xiahou:getMark("@fenyong") > 0) then
			xiahou:loseMark("@fenyong")
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(xiahou)) do
				if xiahou:canSlash(p, nil, false) then
					targets:append(p)
				end
			end
			local choice
			if (not sgs.Slash_IsAvailable(xiahou)) or targets:isEmpty() then
				choice = "discard"
			else
				choice = room:askForChoice(xiahou, self:objectName(), "discard+slash")
			end
			if choice == "slash" then
				local victim = room:askForPlayerChosen(xiahou, targets, objectName(), "@dummy-slash")
				local slash = sgs.Sanghuosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName(self:objectName())
				room:useCard(sgs.CardUseStruct(slash, xiahou, victim), false)
			else
				room:setPlayerFlag(player, "LuaXuehen_InTempMoving")
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local card_ids = sgs.IntList()
				local original_places = sgs.IntList()
				for i = 0, xiahou:getLostHp() - 1, 1 do
					if not xiahou:canDiscard(player, "he") then break end
					card_ids:append(room:askForPlayerChosen(xiahou, player, "he", self:objectName(), false, sgs.Card_MethodDiscard))
					original_places:append(room:getCardPlace(card_ids:at(i)))
					dummy:addSubcard(card_ids:at(i))
					player:addToPlie("#LuaXuehen", card_ids:at(i), false)
				end
				for i = 0, dummy:subcardsLength() - 1, 1 do
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), player, original_places:at(i), false)
				end
				room:setPlayerFlag(player, "-LuaXuehen_InTempMoving")
				if dummy:subcardsLength() > 0 then
					room:throwCard(dummy, player, xiahou)
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end ,
}
LuaXuehenNDL = sgs.CreateTargetModSkill{
	name = "#LuaXuehen-slash-ndl" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("LuaXuehen") and (card:getSkillName() == "LuaXuehen") then
			return 1000
		else
			return 0
		end
	end
}
LuaXuehenFakeMove = sgs.CreateTriggerSkill{
	name = "#LuaXuehen-fake-move" ,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime} ,
	priority = 10 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("LuaXuehen_InTempMoving") then return true end
		end
		return false
	end
}
--[[
	技能名：昭心
	相关武将：贴纸·司马昭
	描述：摸牌阶段结束时，你可以展示所有手牌，若如此做，视为你使用一张【杀】，每阶段限一次。 
	引用：LuaZhaoxin
	状态：0610待验证
]]--
LuaZhaoxinCard = sgs.CreateSkillCard{
	name = "LuaZhaoxinCard" ,
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local tarlist = sgs.PlayerList()
		for i = 1, #targets, 1 do 
			tarlist:append(targets[i])
		end
		return slash:targetFilter(tarlist, to_select, sgs.Self)
	end ,
	on_use = function(self, room, source, targets)
		room:showAllCards(source)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("_LuaZhaoxin")
		local tarlist = sgs.SPlayerList()
		for i = 1, #targets, 1 do 
			tarlist:append(targets[i])
		end
		room:useCard(sgs.CardUseStruct(slash, source, tarlist))
	end
}
LuaZhaoxinVS = sgs.CreateViewAsSkill{
	name = "LuaZhaoxin" ,
	n = 0 ,
	view_as = function()
		return LuaZhaoxinCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "@@LuaZhaoxin") and sgs.Slash_IsAvailable(player)
	end ,
}
LuaZhaoxin = sgs.CreateTriggerSkill{
	name = "LuaZhaoxin" ,
	events = {sgs.EventPhaseEnd} ,
	view_as_skill = LuaZhaoxinVS ,
	on_trigger = function(self, event, player, data)
		if player:getPahse() ~= sgs.Player_Draw then return false end
		if player:isKongcheng() or (not sgs.Slash_IsAvailable(player)) then return false end
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(player:getRoom():getAllPlayers()) do
			if player:canSlash(p) then 
				targets:append(p)
			end
		end
		if targets:isEmpty() then return false end
		player:getRoom():askForUseCard(player, "@@LuaZhaoxin", "@zhaoxin")
		return false
	end
}


--[[
	技能名：扶乱
	相关武将：贴纸·王元姬
	描述：出牌阶段限一次，若你未于本阶段使用过【杀】，你可以弃置三张相同花色的牌，令你攻击范围内的一名其他角色将武将牌翻面，然后你不能使用【杀】直到回合结束。
	引用：LuaFuluan、LuaFuluanForbid
	状态：0610待验证
]]--
LuaFuluanCard = sgs.CreateSkillCard{
	name = "LuaFuluanCard" ,
	filter = function(self, targets, to_select)
		if #targets ~= 0 then return false end
		if (not sgs.Self:inMyAttackRange(to_select)) or (sgs.Self:objectName() == to_select:objectName()) then return false end
		if sgs.Self:getWeapon() and self:getSubcards():contains(sgs.Self:getWeapon():getId()) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			local distance_fix = weapon:getRange() - 1
			if sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
				distance_fix = distance_fix + 1
			end
			return sgs.Self:distanceTo(to_select, distance_fix) <= sgs.Self:getAttackRange()
		elseif sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
			return sgs.Self:distanceTo(to_select, 1) <= sgs.Self:getAttackRange()
		else
			return true
		end
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		effect.to:turnOver()
		room:setPlayerCardLimitation(effect.from, "use", "Slash", true)
	end ,
}
LuaFuluan = sgs.CreateViewAsSkill{
	name = "LuaFuluan" ,
	n = 3 ,
	view_filter = function(self, selected, to_select)
		if #selected >= 3 then return false end
		if sgs.Self:isJilei(to_select) then return false end
		if #selected ~= 0 then
			local suit = selected[1]:getSuit()
			return to_select:getSuit() == suit
		end
		return true
	end ,
	view_as = function(self, cards)
		if #cards ~= 3 then return nil end
		local card = LuaFuluanCard:clone()
		card:addSubcard(cards[1])
		card:addSubcard(cards[2])
		card:addSubcard(cards[3])
		return card
	end ,
	enabled_at_play = function(self, player)
		return (player:getCardCount(true) >= 3) and (not player:hasUsed("#LuaFuluanCard")) and (not player:hasFlag("ForbidLuaFuluan"))
	end
}
LuaFuluanForbid = sgs.CreateTriggerSkill{
	name = "#LuaFuluan-forbid" ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (player:getPhase() == sgs.Player_Play) and (not player:hasFlag("ForbidLuaFuluan")) then
			player:getRoom():setPlayerFlag(player, "ForbidLuaFuluan")
		end
		return false
	end
}
--[[
	技能名：淑德
	相关武将：贴纸·王元姬
	描述：结束阶段开始时，你可以将手牌数补至等于体力上限的张数。
	引用：LuaShude
	状态：0610待验证
]]--
LuaShude = sgs.CreateTriggerSkill{
	name = "LuaShude" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Frequent, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local upper = player:getMaxHp()
			local handcard = player:getHandcardNum()
			if handcard < upper then
				if player:getRoom():askForSkillInvoke(player, self:objectName()) then
					player:drawCards(upper - handcard)
				end
			end
		end
	end
}
--[[
	技能名：皇恩
	相关武将：贴纸·刘协
	描述：每当一张锦囊牌指定了不少于两名目标时，你可以令成为该牌目标的至多X名角色各摸一张牌，则该锦囊牌对这些角色无效。（X为你当前体力值） 
	引用：LuaHuangen
	状态：0610待验证
]]--
LuaHuangenCard = sgs.CreateSkillCard{
	name = "LuaHuangenCard" ,
	filter = function(self, targets, to_select)
		return (#targets < sgs.Self:getHp()) and to_select:hasFlag("LuaHuangenTarget")
	end ,
	on_effect = function(self, effect)
		effect.to:setTag("LuaHuangen" , effect.from:getTag("LuaHuangen_user"))
		effect.to:drawCards(1)
	end
}
LuaHuangenVS = sgs.CreateViewAsSkill{
	name = "LuaHuangen" ,
	n = 0;
	view_as = function()
		return LuaHuangenCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaHuangen"
	end
}
LuaHuangen = sgs.CreateTriggerSkill{
	name = "LuaHuangen" ,
	events = {sgs.TargetConfirmed, sgs.CardEffected} ,
	view_as_skill = LuaHuangenVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local liuxie = room:findPlayerBySkillName(self:objectName())
		if not liuxie then return false end
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (player:objectName() ~= liuxie:objectName()) or (liuxie:getHp() <= 0) then return false end
			if (use.to:length() <= 1) or (not use.card:isKindOf("TrickCard")) or use.card:isKindOf("Collateral") then return false end
			liuxie:setTag("LuaHuangen_user", sgs.QVariant(use.card:toString()))
			for _, p in sgs.qlist(use.to) do
				room:setPlayerFlag(p, "LuaHuangenTarget")
			end
			room:askForUseCard(liuxie, "@@huangen", "@huangen-card")
			for _, p in sgs.qlist(use.to) do
				room:setPlayerFlag(p, "-LuaHuangenTarget")
			end
		elseif event == sgs.CardEffected then
			if liuxie:getTag("LuaHuangen_user"):toString() == effect.card:toString() then
				liuxie:removeTag("LuaHuangen_user")
			end
			if not player:isAlive() then return false end
			if (not player:getTag("LuaHuangen")) or (player:getTag("LuaHuangen"):toString() ~= effect.card:toString()) then return false end
			player:setTag("LuaHuangen", sgs.QVariant(""))
			return true
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}

--[[
	技能名：义从
	相关武将：贴纸·公孙瓒
	描述：弃牌阶段结束时，你可以将任意数量的牌置于武将牌上，称为“扈”。每有一张“扈”，其他角色计算与你的距离+1。
	引用：LuaDIYYicong、LuaDIYYicongDistance、LuaDIYYicongClear
	状态：0610待验证
]]--
LuaDIYYicongCard = sgs.CreateSkillCard{
	name = "LuaDIYYicongCard" ,
	target_fixed = true ,
	will_throw = false, 
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		soucre:addToPile("retinue", self)
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
	技能名：突骑（锁定技）
	相关武将：贴纸·公孙瓒
	描述：准备阶段开始时，若你的武将牌上有“扈”，你将所有“扈”置入弃牌堆：若X小于或等于2，你摸一张牌。本回合你与其他角色的距离-X。（X为准备阶段开始时置于弃牌堆的“扈”的数量）
	引用：LuaTuqi、LuaTuqiDistance
	状态：0610待验证
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

