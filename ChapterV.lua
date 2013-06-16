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
由于我刚刚过来不知道测试出来的技能怎么处理，所以暂时我个人测试完成的技能只在这里面更改状态，到时候放到哪里再说。
]]
--[[
	技能名：护驾（主公技）
	相关武将：标准·曹操、铜雀台·曹操
	描述：当你需要使用或打出一张【闪】时，你可以令其他魏势力角色打出一张【闪】（视为由你使用或打出）。 
	引用：LuaHujia
	状态：0610待验证（获取data重写）
]]--
LuaHujia = sgs.CreateTriggerSkill{
	name = "LuaHujia$",
	frequency = sgs.NotFrequent,
	events = {sgs.CardAsked},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toStringList():first()
		local prompt = data:toStringList():at(1)
		if (pattern ~= "jink") or string.find(prompt, "@hujia-jink") then return false end
		local lieges = room:getLieges("wei", player)
		if lieges:isEmpty() then return false end
		if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
		local tohelp = sgs.QVariant()
		tohelp:setValue(player)
		for _, p in sgs.qlist(lieges) do
			local prompt = string.format("@hujia-jink:%s", player:objectName())
			local jink = room:askForCard(p, "jink", prompt, tohelp, sgs.Card_MethodResponse, player)
			if jink then
				room:provide(jink)
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, player)
		if player then
			return player:hasLordSkill(self:objectName())
		end
		return false
	end
}

--[[
	技能名：突袭
	相关武将：标准·张辽
	描述：摸牌阶段开始时，你可以放弃摸牌，改为获得一至两名其他角色的各一张手牌。
	引用：LuaTuxi
	状态：0610待验证（技能卡重写）
]]--
LuaTuxiCard = sgs.CreateSkillCard{
	name = "LuaTuxiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select) 
		if (#targets >= 2) or (to_select:objectName() == sgs.Self:objectName()) then
			return false
		end
		return not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		local moves = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct()
		move1.card_ids:append(room:askForCardChosen(source, targets[1], "h", self:objectName()))
		move1.to = source
		move1.to_place = sgs.Player_PlaceHand
		moves:append(move1)
		if #targets == 2 then
			local move2 = sgs.CardsMoveStruct()
			move2.card_ids:append(room:askForCardChosen(source, targets[2], "h", self:objectName()))
			move2.to = source
			move2.to_place = sgs.Player_PlaceHand
			moves:append(move2)
		end
		room:moveCards(moves, false)
	end
}
LuaTuxiVS = sgs.CreateViewAsSkill{
	name = "LuaTuxi", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaTuxiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaTuxi"
	end
}
LuaTuxi = sgs.CreateTriggerSkill{
	name = "LuaTuxi", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = LuaTuxiVS, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _,target in sgs.qlist(other_players) do
				if not target:isKongcheng() then
					can_invoke = true
					break;
				end
			end
			if can_invoke then
				if room:askForUseCard(player, "@@LuaTuxi", "@tuxi-card") then
					return true
				end
			end
		end
		return false
	end
}

--[[
	技能名：天妒
	相关武将：标准·郭嘉
	描述：在你的判定牌生效后，你可以获得此牌。
	引用：LuaTiandu
	状态：0610待验证（小改）
]]--
LuaTiandu = sgs.CreateTriggerSkill{
	name = "LuaTiandu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local judge = data:toJudge()
		local card = judge.card
		local card_data = sgs.QVariant()
		card_data:setValue(card)
		if player:askForSkillInvoke(self:objectName(), card_data) then
			player:obtainCard(card)
		end
	end
}


--[[
	技能名：遗计
	相关武将：标准·郭嘉
	描述：每当你受到1点伤害后，你可以观看牌堆顶的两张牌，将其中一张交给一名角色，然后将另一张交给一名角色。
	引用：LuaYiji
	状态：0610待验证（完全重写）
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
			moves.append(move)
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
				moves.append(move)
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
				moves.append(move)
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
	技能名：刚烈
	相关武将：标准·夏侯惇
	描述：每当你受到一次伤害后，你可以进行一次判定，若判定结果不为红桃，则伤害来源选择一项：弃置两张手牌，或受到你对其造成的1点伤害。
	引用：LuaGanglie
	状态：0610待验证（judge.pattern重写）
]]--
LuaGanglie = sgs.CreateTriggerSkill{
	name = "LuaGanglie", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged}, 
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local from = damage.from
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if (not from) or from:isDead() then return end
			if judge:isGood() then
				if from:getHandcardNum < 2 then
					room:damage(sgs.DamageStruct(self:objectName(), player, from))
				else
					if not room:askForDiscard(from, self:objectName(), 2, 2, true) then
						room:damage(sgs.DamageStruct(self:objectName(), player, from))
					end
				end
			end
		end
	end
}

--[[
	技能名：鬼才
	相关武将：标准·司马懿
	描述：在一名角色的判定牌生效前，你可以打出一张手牌代替之。
	引用：LuaGuicai
	状态：0610待验证（完全重写）
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
		if forced and (card = nil) then
			card = player:getRandomHandCard()
		end
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end
}

--[[
	技能名：裸衣
	相关武将：标准·许褚
	描述：摸牌阶段，你可以少摸一张牌，若如此做，你使用的【杀】或【决斗】（你为伤害来源时）造成的伤害+1，直到回合结束。
	引用：LuaLuoyiBuff、LuaLuoyi
	状态：0610待验证（buff部分重写）
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
	技能名：洛神
	相关武将：标准·甄姬、SP·甄姬
	描述：回合开始阶段开始时，你可以进行一次判定，若判定结果为黑色，你获得此牌，你可以重复此流程，直到出现红色的判定结果为止。
	引用：LuaLuoshen
	状态：0610待验证（国战部分无法实现因为使用了QVariantList，judge.pattern重写）
]]--
LuaLuoshen = sgs.CreateTriggerSkill{
	name = "LuaLuoshen", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart, sgs.FinishJudge}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				while player:askForSkillInvoke(self:objectName()) do
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					judge.time_consuming = true
					room:judge(judge)
					if judge:isBad() then
						break
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				if card:isBlack() then
					player:obtainCard(card)
					return true
				end
			end
		end
		return false
	end
}


--[[
	技能名：仁德
	相关武将：标准·刘备
	描述：出牌阶段限一次，你可以将任意数量的手牌交给其他角色，若此阶段你给出的牌张数达到两张或更多时，你回复1点体力。
	引用：LuaRende
	状态：0610未做（更换技能）
]]--

--[[
	技能名：激将（主公技）
	相关武将：标准·刘备、山·刘禅
	描述：当你需要使用或打出一张【杀】时，你可以令其他蜀势力角色打出一张【杀】（视为由你使用或打出）。
	状态：0610待验证（以前无法实现，0610新增接口）
]]--

LuaJijiangCard = sgs.CreateSkillCard{
	name = "LuaJijiangCard" ,
	fliter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local plist = sgs.PlayerList()
		for i = 1, #targets, 1 do
			plist:append(targets[i])
		end
		return slash:targetFilter(plist, to_select, sgs.Self)
	end
	on_validate = function(self, cardUse) --这是0610新加的哦~~~~
		carduse.m_isOwnerUse = false
		local liubei = cardUse.from
		local targets = cardUse.to
		room = liubei:getRoom()
		local slash = nil
		local lieges = room:getLieges("shu", liubei)
		for _, target in sgs.qlist(targets) do
			target:setFlags("LuaJijiangTarget")
		end
		for _, liege in sgs.qlist(lieges) do
			slash = room:askForCard(liege, "slash", "@jijiang-slash:" .. liubei:objectName(), sgs.QVariant(), sgs.Card_MethodResponse, liubei) --未处理胆守
			if slash then
				for _, target in sgs.qlist(targets) do
					target:setFlags("-LuaJijiangTarget")
				end
				return slash
			end
		end
		for _, target in sgs.qlist(targets) do
			target:setFlags("-LuaJijiangTarget")
		end
		room:setPlayerFlag(liubei, "Global_LuaJijiangFailed")
		return nil
	end
}
hasShuGenerals = function(player)
	for _, p in sgs.qlist(player:getSiblings()) do
		if p:isAlive() and (p:getKingdom() == "shu") then
			return true
		end
	end
	return false
end
LuaJijiangVS = sgs.CreateViewAsSkill{
	name = "LuaJijiang$" ,
	n = 0 ,
	view_as = function()
		return LuaJijiangCard:clone()
	end
	enabled_at_play = function(self, player)
		return hasShuGenerals(player) 
		   and player:hasLordSkill("LuaJijiang") 
		   and (not player:hasFlag("Global_LuaJijiangFailed")) 
		   and sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return hasShuGenerals(player) 
		   and player:hasLordSkill("LuaJijiang")
		   and ((pattern == "slash") or (pattern == "@jijiang"))
		   and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		   and (not player:hasFlag("Global_LuaJijiangFailed"))
	end
}
LuaJijiang = sgs.CreateTriggerSkill{
	name = "LuaJijiang$" ,
	events = {sgs.CardAsked} ,
	view_as_skill = LuaJijiangVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toStringList():first()
		local prompt = data:toStringList():at(1)
		if (pattern ~= "slash") or string.find(prompt, "@jijiang-slash") then return false end
		local lieges = room:getLieges("shu", player)
		if lieges:isEmpty() then return false end
		if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
		for _, liege in sgs.qlist(lieges) do
			local slash = room:askForCard(liege, "slash", "@jijiang-slash:" .. player:objectName(), sgs.QVariant(), sgs.Card_MethodResponse, player)
			if slash then
				room:provide(slash)
				return true
			end
		end
		return false
	end ,
	can_trigger = function(self, player)
		return target and target:hasLordSkill("LuaJijiang")
	end
}
--[[
	技能名：武圣
	相关武将：标准·关羽、翼·关羽
	描述：你可以将一张红色牌当【杀】使用或打出。
	引用：LuaWusheng
	状态：0610待验证（view_fliter根据源码修改）
]]--
LuaWusheng = sgs.CreateViewAsSkill{
	name = "LuaWusheng",
	n = 1,
	view_filter = function(self, selected, to_select)
		if not to_select:isRed() then return false end
		local weapon = sgs.Self:getWeapon()
		if (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY) and sgs.Self:getWeapon() 
				and (card:getEffectiveId() == sgs.Self:getWeapon():getId()) and card:isKindOf("Crossbow") then
			return sgs.Self:canSlashWithoutCrossbow()
		else
			return true
		end
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber()) 
			slash:addSubcard(card:getId())
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
	技能名：龙胆
	相关武将：标准·赵云、☆SP·赵云、翼·赵云
	描述：你可以将一张【杀】当【闪】，一张【闪】当【杀】使用或打出。
	引用：LuaLongdan
	状态：0610待验证（完全重写）
]]--
LuaLongdan = sgs.CreateViewAsSkill{
	name = "LuaLongdan" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if #selected > 0 then return false end
		local card = to_select
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == CardUseStruct_CARD_USE_REASON_PLAY then
			return card:isKindOf("Jink")
		elseif (usereason == CardUseStruct_CARD_USE_REASON_RESPONSE) or (usereason == CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			else
				return card:isKindOf("Slash")
			end
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		local originalCard = cards[1]
		if originalCard:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink", originalCard:getSuit(), originalCard:getNumber())
			jink:addSubcard(originalCard)
			jink:setSkillName(self:objectName())
			return jink
		elseif originalCard:isKindOf("Jink") then
			local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			slash:addSubcard(originalCard)
			slash:setSkillName(self:objectName())
			return slash
		else
			return nil
		end
	end ,
	enabled_at_play = function(self, target)
		return sgs.Slash_IsAvailable(target)
	end, 
	enabled_at_response = function(self, target, pattern)
		return (pattern == "slash") or (pattern == "jink")
	end
}

--[[
	技能名：铁骑
	相关武将：标准·马超
	描述：每当你指定【杀】的目标后，你可以进行一次判定，若判定结果为红色，该角色不能使用【闪】对此【杀】进行响应。
	引用：
	状态：0610未做（由于更换实现方法）
]]--

--[[
	技能名：观星
	相关武将：标准·诸葛亮、山·姜维
	描述：回合开始阶段开始时，你可以观看牌堆顶的X张牌（X为存活角色数且至多为5），将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。
	引用：LuaGuanxing
	状态：0610待验证（getNCards按照源码修改）
]]--
LuaGuanxing = sgs.CreateTriggerSkill{
	name = "LuaGuanxing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local count = room:alivePlayerCount()
				if count > 5 then
					count = 5
				end
				local cards = room:getNCards(count)
				room:askForGuanxing(player, cards, false)
			end
		end
	end
}

--[[
	技能名：空城（锁定技）
	相关武将：标准·诸葛亮、测试·五星诸葛
	描述：若你没有手牌，你不能被选择为【杀】或【决斗】的目标。
	引用：LuaKongcheng
	状态：0610待验证（由于现在ProhibitSkill对所有人有效所以根据源码修改is_prohibited部分）
]]--
LuaKongcheng = sgs.CreateProhibitSkill{
	name = "LuaKongcheng",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Slash") or card:isKindOf("Duel")) and to:isKongcheng()
	end,
}
--[[
	技能名：集智
	相关武将：标准·黄月英
	描述：每当你使用锦囊牌选择目标后，你可以展示牌堆顶的一张牌。若此牌为基本牌，你选择一项：1.将之置入弃牌堆；2.用一张手牌替换之。若此牌不为基本牌，你获得之。
	引用：LuaJizhi
	状态：0610待验证（更换技能）
]]--

LuaJizhi = sgs.CreateTriggerSkill{
	name = "LuaJizhi" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if (use.card:getTypeId() == sgs.Card_TypeTrick) then
			if not player:getMark("JilveEvent") > 0 then
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
	技能名：奇才（锁定技）
	相关武将：标准·黄月英
	描述：你使用锦囊牌无距离限制。你装备区里除坐骑牌外的牌不能被其他角色弃置。
	引用：LuaQicai
	状态：0610貌似无法实现（怀疑后半段被写入源码，因为在本来属于奇才的位置上的只有TargetMod）
]]--

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
	技能名：反间
	相关武将：标准·周瑜
	描述：出牌阶段，你可以令一名其他角色说出一种花色，然后获得你的一张手牌并展示之，若此牌不为其所述之花色，你对该角色造成1点伤害。每阶段限一次。
	引用：LuaFanjian
	状态：0610待验证（根据源码修改使用on_effect并使用DamageStruct的构造函数）
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
	技能名：克己
	相关武将：标准·吕蒙
	描述：若你于出牌阶段未使用或打出过【杀】，你可以跳过此回合的弃牌阶段。
	引用：LuaKeji
	状态：0610待验证（修改实现方法）
]]--
LuaKeji = sgs.CreateTriggerSkill{
	name = "LuaKeji" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Discard then
			if not player:hasFlag("Global_SlashInPlayPhase") then
				if player:askForSkillInvoke(self:objectName()) then
					player:skip(sgs.Player_Discard)
				end
			end
		end
		return false
	end
}


--[[
	技能名：连营
	相关武将：标准·陆逊、倚天·陆抗
	描述：当你失去最后的手牌时，你可以摸一张牌。
	引用：LuaLianying、LuaLianyingForZeroMaxCards
	状态：0610待验证（被偷改）
]]--
LuaLianying = sgs.CreateTriggerSkill{
	name = "LuaLianYing" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		if (move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceHand) then
			if event == sgs.BeforeCardsMove then
				if player:isKongcheng() then return false end
				for _, id in sgs.qlist(player:handCards()) do
					if not move.card_ids:contains(id) then return false end
				end
				if (player:getMaxCards() == 0) and (player:getPhase() == sgs.Player_Discard) 
						and (move.reason:m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD) then
					player:getRoom():setPlayerFlag(player, "LuaLianyingZeroMaxCards")
					return false
				end
				player:addMark(self:objectName())
			else
				if player:getMark(self:objectName()) == 0 then return false end
				player:removeMark(self:objectName())
				if player:askForSkillInvoke(self:objectName(), data) then
					player:drawCards(1)
				end
			end
		end
		return false
	end
}
LuaLianyingForZeroMaxCards = sgs.CreateTriggerSkill{
	name = "#LuaLianyingForZeroMaxcards" ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if (change.from == sgs.Player_Discard) and player:hasFlag("LuaLianYingZeroMaxCards") then
			player:getRoom():setPlayerFlag("-LuaLianying")
			player:drawCards(1)
		end
		return false
	end
}
--[[
	技能名：流离
	相关武将：标准·大乔
	描述：当你成为【杀】的目标时，你可以弃置一张牌，将此【杀】转移给你攻击范围内的一名其他角色（此【杀】的使用者除外）。
	引用：LuaLiuli
	状态：0610待验证（修改实现方法）
]]--

LuaLiuliCard = sgs.CreateSkillCard{
	name = "LuaLiuliCard" ,
	target_fliter = function(self, targets, to_select)
		if #targets > 0 then return false end
		if to_select:hasFlag("LuaLiuliSlashSource") or (to_select:objectName() == sgs.Self:objectName()) then return false end
		local from
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
			if p:hasFlag("LuaLiuliSlashSource") then
				from = p
				break
			end
		end
		local slash = sgs.Card_Parse(sgs.Self:property("lualiuli"):toString())
		if from and (not from:canSlash(to_select, slash, false)) then return false end
		local card_id = self:subcards:first()
		local range_fix = 0
		if sgs.Self:getWeapon() and (sgs.Self:getWeapon():getId() == card_id) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			range_fix = range_fix + weapon:getRange() - 1
		elseif sgs.Self:getOffensiveHorse() and (self:getOffensiveHorse():getId() == card_id) then
			range_fix = range_fix + 1
		end
		return sgs.Self:distanceTo(to_select, range_fix) <= sgs.Self:getAttackRange()
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("LuaLiuliTarget")
	end
}
LuaLiuliVS = sgs.CreateViewAsSkill{
	name = "LuaLiuli" ,
	n = 1,
	view_fliter = function(self, selected, to_select)
		if #selected > 0 then return false end
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		if #cards == 1 then
			local liuli_card = LuaLiuliCard:clone()
			liuli_card:addSubcard(cards[1])
			return liuli_card
		end
	end ,
	enabled_at_play = function()
		return false
	end
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaLiuli"
	end
}
LuaLiuli = sgs.CreateTriggerSkill{
	name = "LuaLiuli" ,
	events = {sgs.TargetConfirming} ,
	view_as_skill = LuaLiuliVS ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") 
				and use.to:contains(player) and player:canDiscard(player,"he") and (room:alivePlayerCount() > 2) then
			local players = room:getOtherPlayers(player)
			players.removeOne(use.from)
			local can_invoke = false
			for _, p in sgs.qlist(players) do
				if use.from:canSlash(p, use.card) and player:inMyAttackRange(p) then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				local prompt = "@liuli:" .. use.from:objectName()
				room:setPlayerFlag(use.from, "LuaLiuliSlashSource") 
				room:setPlayerProperty(player, "lualiuli", use.card:toString())
				if room:askForUseCard(player, "@@liuli", prompt, -1, sgs.Card_MethodDiscard) then
					room:setPlayerProperty(player, "lualiuli", "")
					room:setPlayerFlag(use.from, "-LuaLiuliSlashSource")
					for _, p in sgs.qlist(players) do
						if p:hasFlag("LuaLiuliTarget") then
							p:setFlags("-LuaLiuliTarget")
							use.to:removeOne(player)
							use.to:append(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)
							room:getThread():trigger(sgs.TargetConfirming, room, p, data)
							return false
						end
					end
				else
					room:setPlayerProperty(player, "lualiuli", "")
					room:setPlayerFlag(use.from, "-LuaLiuliSlashSource")
				end
			end
		end
		return false
	end
}

--[[
	技能名：结姻
	相关武将：标准·孙尚香、SP·孙尚香
	描述：出牌阶段，你可以弃置两张手牌并选择一名已受伤的男性角色，你与其各回复1点体力。每阶段限一次。
	引用：LuaJieyin
	状态：0610待验证（被偷改）
]]--

LuaJieyinCard = sgs.CreateSkillCard{
	name = "LuaJieyinCard" ,
	target_fixed = false ,
	will_throw = true ,
	filter = function(self, targets, to_select)
		if #targets ~= 0 then return false end
		return to_select:isMale() and to_select:isWounded and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = effect.from
		room:recover(effect.from, recover, true)
		room:recover(effect.to, recover, true)
	end
}
LuaJieyin = sgs.CreateViewAsSkill{
	name = "LuaJieyin" ,
	n = 2 ,
	view_fliter = function(self, selected, to_select)
		if (#selected > 1) or sgs.Self:isJilei(to_select) then return false end
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		jieyin_card = LuaJieyinCard:clone()
		jieyin_card:addSubcard(cards[1])
		jieyin_card:addSubcard(cards[2])
		return jieyin_card
	end ,
	enabled_at_play = function(self, target)
		return (target:getHandcardNum() >= 2) and (not player:hasUsed("#LuaJieyinCard"))
	end
}

--[[
	技能名：枭姬
	相关武将：标准·孙尚香、SP·孙尚香
	描述：当你失去装备区里的一张牌时，你可以摸两张牌。
	引用：LuaXiaoji
	状态：0610待验证（修改实现方法，尽量保持和源码一致）
]]--
LuaXiaoji = sgs.CreateTriggerSkill{
	name = "LuaXiaoji" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if (move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceEquip) then
			for i = 0, move.card_ids:size() - 1, 1 do
				if not player:isAlive() then return false end
				if move.from_places:at(i) == sgs.Player_PlaceEquip then
					if room:askForSkillInvoke(player, self:objectName())
						player:drawCards(2)
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
	技能名：无双（锁定技）
	相关武将：标准·吕布、SP·最强神话、SP·暴怒战神
	描述：当你使用【杀】指定一名角色为目标后，该角色需连续使用两张【闪】才能抵消；与你进行【决斗】的角色每次需连续打出两张【杀】。
	引用：LuaWushuang
	状态：0610貌似无法实现（和上几个版本一样，决斗部分还是写在源码的，悲催……）
]]--

]]
--[[
	技能名：离间
	相关武将：标准·貂蝉、SP·貂蝉
	描述：出牌阶段，你可以弃置一张牌并选择两名男性角色，视为其中一名男性角色对另一名男性角色使用一张【决斗】。此【决斗】不能被【无懈可击】响应。每阶段限一次。
	引用：LuaLijian
	状态：0610无法实现（由于此技能修改源码中的card:onUse()函数但是LUA中无此接口）
]]--

--[[
	技能名：青囊
	相关武将：标准·华佗
	描述：出牌阶段，你可以弃置一张手牌，令一名已受伤的角色回复1点体力。每阶段限一次。
	引用：LuaQingnang
	状态：0610待验证（技能卡filter部分和视为技enabled_at_play部分小改）
]]--
LuaQingnangCard = sgs.CreateSkillCard{
	name = "LuaQingnangCard",
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return (#targets == 0) and (to_select:isWounded())
	end,
	feasible = function(self, targets)
		if #targets == 1 then
			return targets[1]:isWounded()
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		local effect = sgs.CardEffectStruct()
		effect.card = self
		effect.from = source
		effect.to = target
		room:cardEffect(effect)
	end,
	on_effect = function(self, effect) 
		local dest = effect.to
		local room = dest:getRoom()
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = effect.from
		room:recover(dest, recover)
	end
}
LuaQingnang = sgs.CreateViewAsSkill{
	name = "LuaQingnang", 
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if #cards ==1 then
			local card = cards[1]
			local qn_card = LuaQingnangCard:clone()
			qn_card:addSubcard(card)
			return qn_card
		end
	end, 
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "h") and (not player:hasUsed("#LuaQingnangCard"))
	end
}

--[[
	技能名：谦逊（锁定技）
	相关武将：标准·陆逊、国战·陆逊
	描述：你不能被选择为【顺手牵羊】和【乐不思蜀】的目标。
	引用：LuaQianxun
	状态：0610待验证（由于现在ProhibitSkill对所有人有效所以根据源码修改is_prohibited部分）
]]--
LuaQianxun = sgs.CreateProhibitSkill{
	name = "LuaQianxun", 
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Snatch") or card:isKindOf("Indulgence"))
	end
}

--[[
	技能名：妄尊
	相关武将：标准·袁术
	描述：主公的准备阶段开始时，你可以摸一张牌，然后主公本回合手牌上限-1。
	引用：LuaWangzun、LuaWangzunMaxCards
	状态：0610待验证（新技能）
]]

LuaWangzun = sgs.CreateTriggerSkill{
	name = "LuaWangzun" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isLord() and (player:getPhase() == sgs.Player_Start) then
			local yuanshu = room:findPlayerBySkillName(self:objectName())
			if yuanshu then
				if room:askForSkillInvoke(yuanshu, self:objectName()) then
					yuanshu:drawCards(1)
					room:setPlayerFlag(player, "WangzunDecMaxCards")
				end
			end
		end
		return false
	end
	can_trigger = function(self, target)
		return target
	end
}
LuaWangzunMaxCards = sgs.CreateMaxCardsSkill{
	name = "#LuaWangzunMaxCards" ,
	extra_func = function(self, target)
		if target:hasFlag("WangzunDecMaxCards") then
			return -1
		else
			return 0
		end
	end
}

--[[
	技能名：同疾（锁定技）
	相关武将：标准·袁术
	描述：若你的手牌数大于你的体力值，且你在一名其他角色的攻击范围内，则其他角色不能被选择为该角色的【杀】的目标。
	引用：LuaTongji
	状态：0610待验证（新技能）
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
	技能名：耀武（锁定技）
	相关武将：标准·华雄
	描述：每当你受到红色【杀】的伤害时，伤害来源选择一项：回复1点体力，或摸一张牌。
	引用：LuaYaowu
	状态：0610待验证（新技能）
]]

LuaYaowu = sgs.CreateTriggerSkill{
	name = "LuaYaowu" ,
	events = {sgs.DamageInflicted} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindof("Slash") and damage.card:isRed() and damage.from and damage.from:isAlive() then
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
	技能名：鬼道
	相关武将：风·张角
	描述：在一名角色的判定牌生效前，你可以打出一张黑色牌替换之。
	引用：LuaGuidao
	状态：0610未验证（完全重写）
]]--

LuaGuidao = sgs.CreateTriggerSkill{
	name = "LuaGuidao" ,
	events = {sgs.AskForRetrial} ,
	on_trigger = function(self, event, player, data)
		local judge = data:toJudge()
		local prompt_list = {
			"@guidao-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			string.format("%d", judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local card = room:askForCard(player, ".|black", prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName(), true)
		end
		return false
	end ,
	can_trigger = function(self, target)
		if not sgs.TriggerSkill_triggerable(target) then return false end
		if target:isKongcheng() then
			local has_black = false
			for i = 0, 3, 1 do
				local equip = target:getEquip(i)
				if equip and equip:isBlack() then
					has_black = true
					break
				end
			end
			return has_black
		else
			return true
		end
	end
}
--[[
	技能名：雷击
	相关武将：风·张角
	描述：当你使用或打出一张【闪】（若为使用则在选择目标后），你可以令一名角色进行一次判定，若判定结果为黑桃，你对该角色造成2点雷电伤害。
	引用：LuaLeiji
	状态：0610未验证（完全重写）
]]--
LuaLeiji = sgs.CreateTriggerSkill{
	name = "LuaLeiji" ,
	events = {sgs.CardResponded} ,
	on_trigger = function(self, event, player, data)
		local card_star = data:toCardResponse().m_card
		local room = player:getRoom()
		if card_star:isKindOf("Jink") then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "LuaLeiji-invoke", true, true)
			if target then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|spade"
				judge.good = false
				judge.negative = true
				judge.reason = self:objectName()
				judge.who = target
				room:judge(judge)
				if judge:isBad() then
					room:damage(sgs.DamageStruct(self:objectName(), player, target, 2, sgs.DamageStruct_Thunder))
				end
			end
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
	技能名：神速
	相关武将：风·夏侯渊
	描述：你可以选择一至两项：
		1.跳过你的判定阶段和摸牌阶段。
		2.跳过你的出牌阶段并弃置一张装备牌。
		你每选择一项，视为对一名其他角色使用一张【杀】（无距离限制）。
	引用：LuaShensu
	状态：0610待验证（完全重写）
]]--

LuaShensuCard = sgs.CreateSkillCard{
	name = "LuaShensuCard" ,
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("LuaShensu")
		local tarlist = sgs.PlayerList()
		for i = 1, #targets, 1 do 
			tarlist:append(targets[i])
		end
		return slash:targetFliter(targets, to_select, sgs.Self)
	end ,
	on_use = function(self, room, source, targets)
		local tarlist = sgs.SPlayerList()
		for _, p in ipairs(targets) do
			tarlist:append(p)
		end
		for _, p in sgs.qlist(tarlist) do
			if not source:canSlash(p, nil, false) then
				tarlist:removeOne(p)
			end
		end
		if tarlist:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("_LuaShensu")
			room:useCard(sgs.CardUseStruct(slash, source, tarlist))
		end
	end
}
LuaShensuVS = sgs.CreateViewAsSkill{
	name = "LuaShensu" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if string.find(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then return false
		else
			return (#selected == 0) and to_select:isKindOf("EquipCard") and (not sgs.Self:isJilei(to_select))
		end
	end ,
	view_as = function(self, cards)
		if string.find(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then
			if #cards == 0 then return LuaShensuCard:clone() else return nil end
		else
			if #cards ~= 1 then return nil end
			local card = LuaShensuCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@LuaShensu") and sgs.Slash_IsAvailable(player)
	end
}
LuaShensu = sgs.CreateTriggerSkill{
	name = "LuaShensu" ,
	events = {sgs.EventPhaseChanging} ,
	view_as_skill = LuaShensuVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if (change.to == sgs.Player_Judge) and (not player:isSkipped(sgs.Player_Judge)) and (not player:isSkipped(sgs.Player_Draw)) then
			if sgs.Slash_IsAvailable(player) then
				if room:askForUseCard(player, "@@LuaShensu1", "@shensu1", 1) then
					player:skip(sgs.Player_Judge)
					player:skip(sgs.Player_Draw)
				end
			end
		elseif sgs.Slash_IsAvailable(player) and (change.to == sgs.Player_Play) and (not player:isSkipped(sgs.Player_Play)) then
			if player:canDiscard(player, "he") then
				if room:askForUseCard(player, "@@LuaShensu2". "@shensu2", 2, sgs.Card_MethodDiscard) then
					player:skip(sgs.Player_Play)
				end
			end
		end
		return false
	end
}

--[[
	技能名：据守
	相关武将：风·曹仁
	描述：回合结束阶段开始时，你可以摸三张牌，然后将你的武将牌翻面。
	引用：LuaJushou
	状态：0610待验证（根据源码微调）
]]--
LuaJushou = sgs.CreateTriggerSkill{
	name = "LuaJushou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				player:drawCards(3)
				player:turnOver()
			end
		end
	end
}

--[[
	技能名：烈弓
	相关武将：风·黄忠
	描述：当你在出牌阶段内使用【杀】指定一名角色为目标后，以下两种情况，你可以令其不可以使用【闪】对此【杀】进行响应：
		1.目标角色的手牌数大于或等于你的体力值。2.目标角色的手牌数小于或等于你的攻击范围。
	引用：LuaLiegong
	状态：0610未做（由于更换实现方法）(para提示：可以用toStringList，转换出来是一个table）
]]--

--[[
	技能名：狂骨（锁定技）
	相关武将：风·魏延
	描述：每当你对距离1以内的一名角色造成1点伤害后，你回复1点体力。
	引用：LuaKuanggu
	状态：0610待验证（事件修改，重写on_trigger）
]]--
LuaKuanggu = sgs.CreateTriggerSkill{
	name = "LuaKuanggu",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damage, sgs.PreDamageDone},
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local room = player:getRoom()
		if (event == sgs.PreDamageDone) and damage.from and damage.from:hasSkill(self:objectName()) and damage.from:isAlive() then
			local weiyan = damage.from
			weiyan:setTag("invokeLuaKuanggu", sgs.QVariant((weiyan:distanceTo(damage.to) <= 1)))
		elseif (event == sgs.Damage) and player:hasSkill(self:objectName()) and player:isAlive()
			local invoke = player:getTag("invokeLuaKuanggu"):toBool()
			weiyan:setTag("invokeLuaKuanggu", sgs.QVariant(false))
			if invoke and player:isWounded() then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = damage.damage
				room:recover(player, recover)
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：不屈
	相关武将：风·周泰
	描述：每当你扣减1点体力后，若你当前的体力值为0：你可以从牌堆顶亮出一张牌置于你的武将牌上，若此牌的点数与你武将牌上已有的任何一张牌都不同，你不会死亡；若出现相同点数的牌，你进入濒死状态。
	引用：LuaBuqu、LuaBuquRemove
	状态：0610未做（技能比较麻烦）
]]--
--[[
	技能名：天香
	相关武将：风·小乔
	描述：每当你受到伤害时，你可以弃置一张红桃手牌，将此伤害转移给一名其他角色，然后该角色摸X张牌（X为该角色当前已损失的体力值）。
	引用：LuaTianxiang、LuaTianxiangDraw
	状态：0610未做（代码有一行无法LUA）
]]--

--[[
//部分代码如下：
void TianxiangCard::onEffect(const CardEffectStruct &effect) const{
    Room *room = effect.to->getRoom();
    effect.to->addMark("TianxiangTarget");
    DamageStruct damage = effect.from->tag.value("TianxiangDamage").value<DamageStruct>();

    if (damage.card && damage.card->isKindOf("Slash")) {
        QStringList qinggang = effect.from->tag["Qinggang"].toStringList();
        if (!qinggang.isEmpty()) {
            qinggang.removeOne(damage.card->toString());
            effect.from->tag["Qinggang"] = qinggang; //LUA中找不到对应QStringList的setValue()函数
        }
    }

    damage.to = effect.to;
    damage.transfer = true;
    try {
        room->damage(damage);
    }
    catch (TriggerEvent triggerEvent) {
        if (triggerEvent == TurnBroken || triggerEvent == StageChange)
            effect.to->removeMark("TianxiangTarget");
        throw triggerEvent;
    }
}
]]

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
	技能名：驱虎
	相关武将：火·荀彧
	描述：出牌阶段，你可以与一名体力比你多的角色拼点。若你赢，则该角色对其攻击范围内你选择的另一名角色造成1点伤害。若你没赢，则其对你造成1点伤害。每阶段限一次。
	引用：LuaQuhu
	状态：0610待验证（根据源码拼点改为0牌视为技，修改技能卡filter，并在技能卡on_use里面使用DamageStruct的构造函数，修改视为技部分和源码同步）
]]--
LuaQuhuCard = sgs.CreateSkillCard{
	name = "LuaQuhuCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		return (#targets == 0) and (to_select:getHp() > sgs.Self:getHp()) and (not to_select:isKongcheng())
	end,
	on_use = function(self, room, source, targets) 
		local tiger = targets[1]
		local success = source:pindian(tiger, self:objectName(), nil)
		if success then
			local players = room:getOtherPlayers(tiger)
			local wolves = sgs.SPlayerList()
			for _,player in sgs.qlist(players) do
				if tiger:inMyAttackRange(player) then
					wolves:append(player)
				end
			end
			if wolves:isEmpty() then
				return
			end
			local wolf = room:askForPlayerChosen(source, wolves, self:objectName(), "@quhu-damage:" .. tiger:objectName())
			room:damage(sgs.DamageStruct(self:objectName(), tiger, wolf))
		else
			room:damage(sgs.DamageStruct(self:objectName(), tiger, source))
		end
	end
}
LuaQuhu = sgs.CreateViewAsSkill{
	name = "LuaQuhu",
	n = 0,
	view_as = function()
		return LuaQuhuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#LuaQuhuCard")) and (not player:isKongcheng())
	end
}

--[[
	技能名：节命
	相关武将：火·荀彧
	描述：每当你受到1点伤害后，你可以令一名角色将手牌补至X张（X为该角色的体力上限且至多为5）。
	引用：LuaJieming
	状态：0610待验证（完全重写，主要是因为askForPlayerChosen现在为可取消）
]]--

LuaJieming = sgs.CreateTriggerSkill{
	name = "LuaJieming" ,
	events == {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		for i = 0, damage.damage - 1, 1 do
			local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "jieming-invoke", true, true)
			if not to then break end
			local upper = math.min(5, to:getMaxHp())
			local x = upper - to:getHandcardNum()
			if x <= 0 then
			else
				to:drawCards(x)
			end
		end
	end
}
--[[
	技能名：强袭
	相关武将：火·典韦
	描述：出牌阶段，你可以失去1点体力或弃置一张武器牌，对你攻击范围内的一名角色造成1点伤害。每阶段限一次。
	引用：LuaQiangxi
	状态：0610待验证（技能卡大改，根据源码换用on_effect。技能卡filter部分根据源码修改）
]]--
LuaQiangxiCard = sgs.CreateSkillCard{
	name = "LuaQiangxiCard", 
	target_fixed = false, 
	will_throw = true,
	filter = function(self, targets, to_select) 
		if #targets ~= 0 then return false end
		local rangefix = 0
		if (not self:getSubcards():isEmpty()) and sgs.Self:getWeapon() and (sgs.Self:getWeapon():getId() == self:getSubcards():first()) then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - 1
		end
		return sgs.Self:distanceTo(to_select, rangefix) <= sgs.Self:getAttackRange()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if self:getSubcards():isEmpty() then room:loseHp(effect.from) end
		room:damage(sgs.DamageStruct("LuaQiangxi", effect.from, effect.to))
	end
}
LuaQiangxi = sgs.CreateViewAsSkill{
	name = "LuaQiangxi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isKindOf("Weapon")
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return LuaQiangxiCard:clone()
		elseif #cards == 1 then
			local card = LuaQiangxiCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaQiangxiCard")
	end
}

--[[
	技能名：双雄
	相关武将：火·颜良文丑
	描述：摸牌阶段开始时，你可以放弃摸牌，改为进行一次判定，你获得生效后的判定牌，然后你可以将一张与此判定牌颜色不同的手牌当【决斗】使用，直到回合结束。 
	引用：LuaShuangxiong
	状态：0610待验证（视为技小改，触发技大改）
]]--
LuaShuangxiongVS = sgs.CreateViewAsSkill{
	name = "LuaShuangxiong", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		local value = sgs.Self:getMark("LuaShuangxiong")
		if value == 1 then
			return to_select:isBlack()
		elseif value == 2 then
			return card:isRed()
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local duel = sgs.Sanguosha:cloneCard("duel", cards[1]:getSuit(), cards[1]:getNumber())
			duel:addSubcard(cards[1])
			duel:setSkillName(self:objectName())
			return duel
		end
	end, 
	enabled_at_play = function(self, player)
		return (player:getMark("LuaShuangxiong") > 0) and (not player:isKongcheng())
	end
}
LuaShuangxiong = sgs.CreateTriggerSkill{
	name = "LuaShuangxiong",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart, sgs.FinishJudge}, 
	view_as_skill = LuaShuangxiongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start() then
				room:setPlayerMark(player, "LuaShuangxiong", 0)
			elseif (player:getPhase() == sgs.Player_Draw) and sgs.TriggerSkill_triggerable(player) then
				if player:askForSkillInvoke(self:objectName()) then
					room:setPlayerFlag(player, "LuaShuangxiong") 
					local judge = sgs.JudgeStruct()
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					local markid = 2
					if judge.card:isRed() then markid = 1 end
					room:setPlayerMark(player, "LuaShuangxiong", markid)
					return true
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				player:obtainCard(judge.card)
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：猛进
	相关武将：火·庞德、SP·庞德
	描述：当你使用的【杀】被目标角色的【闪】抵消时，你可以弃置其一张牌。 
	引用：LuaMengjin
	状态：0610待验证（完全重写）
]]--

LuaMengjin = sgs.CreateTriggerSkill{
	name = "LuaMengjin" ,
	events = {sgs.SlashMissed} ,
	on_trigger = function(self, event, player, data)
		local effect = data:toSlashEffect()
		if effect.to:isAlive() and player:canDiscard(effect.to, "he") then
			if player:askForSkillInvoke(self:objectName(), data) then
				local to_throw = room:askForCardChosen(player, effect.to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
				player:getRoom():throwCard(sgs.Sanguosha:getCard(to_throw), effect.to, pangde)
			end
		end
		return false
	end
}
--[[
	技能名：连环
	相关武将：火·庞统
	描述：你可以将一张梅花手牌当【铁索连环】使用或重铸。
	引用：LuaLianhuan
	状态：0610待验证（根据源码调整）
]]--
LuaLianhuan = sgs.CreateViewAsSkill{
	name = "LuaLianhuan", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		retun (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Club)
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local chain = sgs.Sanguosha:cloneCard("iron_chain", cards[1]:getSuit(), cards[1]:getNumber())
			chain:addSubcard(cards[1])
			chain:setSkillName(self:objectName())
			return chain
		end
	end
}


--[[
	技能名：涅槃（限定技）
	相关武将：火·庞统
	描述：当你处于濒死状态时，你可以：弃置你区域里所有的牌，然后将你的武将牌翻至正面朝上并重置之，再摸三张牌且体力回复至3点。
	引用：LuaNiepan、LuaNiavana1
	状态：0610待测试（附触发技改名和源码对应，主触发技大改）
]]--
LuaNiepan = sgs.CreateTriggerSkill{
	name = "LuaNiepan",
	frequency = sgs.Skill_Limited, 
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		if dying_data.who:objectName() ~= player:objectName() then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
			room:removePlayerMark(player, "@niavana")
			player:throwAllHandCardsAndEquips()
			local tricks = player:getJudgingArea()
			for _, trick in sgs.qlist(tricks) do
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName())
				room:throwCard(trick, reason, nil)
			end
			local recover = sgs.RecoverStruct()
			recover.recover = math.min(3, player:getMaxHp()) - player:getHp()
			room:recover(player, recover)
			player:drawCards(3)
			if player:isChained() then
				room:setPlayerProperty(player, "chained", sgs.QVariant(false))
			end
			if not player:faceUp() then
				player:turnOver()
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return sgs.TriggerSkill_triggerable(target) and (target:getMark("@nirvana") > 0)
	end
}
LuaNirvana1 = sgs.CreateTriggerSkill{
	name = "#@nirvana-Lua-1",
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		player:gainMark("@nirvana")
	end
}

--[[
	技能名：火计
	相关武将：火·诸葛亮
	描述：你可以将一张红色手牌当【火攻】使用。
	引用：LuaHuoji
	状态：0610待验证（根据源码调整）
]]--
LuaHuoji = sgs.CreateViewAsSkill{
	name = "LuaHuoji",
	n = 1,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local fire_attack = sgs.Sanguosha:cloneCard("FireAttack", cards[1]:getSuit(), cards[1]:getNumber())
			fire_attack:setSkillName(self:objectName())
			fire_attack:addSubcard(cards[1])
			return fire_attack
		end
	end
}

--[[
	技能名：八阵（锁定技）
	相关武将：火·诸葛亮
	描述：若你的装备区没有防具牌，视为你装备着【八卦阵】。
	引用：LuaBazhen
	状态：0610未做（由于源码里将此技能处理成防具技能，所以在触发之前要把防具技能的一段代码写进去，包括无视防具等等）
]]--
--[[
	技能名：看破
	相关武将：火·诸葛亮
	描述：你可以将一张黑色手牌当【无懈可击】使用。
	引用：LuaKanpo
	状态：0610未验证（根据源码小改）
]]--
LuaKanpo = sgs.CreateViewAsSkill{
	name = "LuaKanpo", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:isBlack() and (not to_select:isEquipped())
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local first = cards[1]
			local ncard = sgs.Sanguosha:cloneCard("nullification", first:getSuit(), first:getNumber())
			ncard:addSubcard(first)
			ncard:setSkillName(self:objectName())
			return ncard
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "nullification"
	end,
	enabled_at_nullification = function(self, player)
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:isBlack() then return true end
		end
		return false
	end
}
--[[
	技能名：天义
	相关武将：火·太史慈
	描述：出牌阶段，你可以与一名其他角色拼点。
		若你赢，你获得以下技能直到回合结束：你使用【杀】时无距离限制；可以额外使用一张【杀】；使用【杀】时可以额外选择一个目标。
		若你没赢，你不能使用【杀】，直到回合结束。每阶段限一次。
	引用：LuaTianyi、LuaTianyiTargetMod
	状态：0610待验证（根据源码拼点改为0牌视为技，更改标识）
]]--
LuaTianyiCard = sgs.CreateSkillCard{
	name = "LuaTianyiCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select)
		return #targets == 0 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "LuaTianyi", nil)
		if success then
			room:setPlayerFlag(source, "LuaTianyiSuccess")
		else
			room:setPlayerCardLimitation(source, "use", "Slash", true)
		end
	end
}
LuaTianyiVS = sgs.CreateViewAsSkill{
	name = "LuaTianyi", 
	n = 0, 
	view_as = function() 
		return LuaTianyiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#LuaTianyiCard")) and (not player:isKongcheng())
	end,
}
LuaTianyi = sgs.CreateTriggerSkill{
	name = "LuaTianyi",
	events = {sgs.EventLoseSkill}, 
	view_as_skill = LuaTianyiVS,
	on_trigger = function(self, event, player, data)
		if data:toString() == self:objectName() then
			room:setPlayerFlag(player, "-LuaTianyiSuccess")
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("LuaTianyiSuccess")
	end,
}
LuaTianyiTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaTianyi-target",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("LuaTianyiSuccess") then
			return 1
		else
			return 0
		end
	end,
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("LuaTianyiSuccess") then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("LuaTianyiSuccess") then
			return 1
		else
			return 0
		end
	end,
}

--[[
	技能名：行殇
	相关武将：林·曹丕、铜雀台·曹丕
	描述：其他角色死亡时，你可以获得其所有牌。
	引用：LuaXingshang
	状态：0610待验证（基于源码完全重写）
]]--
LuaXingshang = sgs.CreateTriggerSkill{
	name = "LuaXingshang",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Death}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local _player = death.who
		if _player:isNude() or (player:objectName() == _player:objectName()) then return false end
		if player:isAlive() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  --将无色杀作为dummy，取消dummy skillcard，反正也不use，什么作用咱们也不管了
				local handcards = _player:getHandcards()
				for _, card in sgs.qlist(handcards) do
					dummy:addSubcard(card)
				end
				if dummy:subcardsLength() > 0 then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
					room:obtainCard(player, dummy, reason, false)
				end
			end
		end
		return false
	end
}

--[[
	技能名：放逐
	相关武将：林·曹丕、铜雀台·曹丕
	描述：每当你受到一次伤害后，你可以令一名其他角色摸X张牌（X为你已损失的体力值），然后该角色将其武将牌翻面。
	引用：LuaFangzhu
	状态：0610待验证（完全重写）
]]--
LuaFangzhu = sgs.CreateTriggerSkill{
	name = "LuaFangzhu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "fangzhu-invoke", player:getMark("JilveEvent") ~= sgs.Damaged, true)
		if to then
			to:drawCards(player:getLostHp())
			to:turnOver()
		end
	end
}

--[[
	技能名：颂威（主公技）
	相关武将：林·曹丕、铜雀台·曹丕
	描述：其他魏势力角色的判定牌为黑色且生效后，该角色可以令你摸一张牌。
	引用：LuaSongwei
	状态：0610待验证（完全重写）
]]--
LuaSongwei = sgs.CreateTriggerSkill{
	name = "LuaSongwei$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.FinishJudge},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
		if card:isBlack() then
			local caopis = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					caopis:append(p)
				end
			end
		end
		while not caopis:isEmpty() do
			local caopi = room:askForPlayerChosen(player, caopis, self:objectName(), "@LuaSongwei-to", true)
			if caopi then
				caopi:drawCards(1)
				caopis:removeOne(caopi)
			else
				break
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target and (target:getKingdom() == "wei")
	end
}

--[[
	技能名：断粮
	相关武将：林·徐晃
	描述：你可以将一张黑色牌当【兵粮寸断】使用，此牌必须为基本牌或装备牌；你可以对距离2以内的一名其他角色使用【兵粮寸断】。 
	引用：LuaDuanliang、LuaDuanliangTargetMod
	状态：0610待验证（根据源码小改）
]]--
LuaDuanliang = sgs.CreateViewAsSkill{
	name = "LuaDuanliang",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack() and (to_select:isKindOf("BasicCard") or to_select:isKindOf("EquipCard"))
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local shortage = sgs.Sanguosha:cloneCard("supply_shortage",cards[1]:getSuit(),cards[1]:getNumber())
		shortage:setSkillName(self:objectName())
		shortage:addSubcard(cards[1])
		return shortage
	end
}
LuaDuanliangTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaDuanliang-target",
	pattern = "SupplyShortage",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		else
			return 0
		end
	end
}


--[[
	技能名：祸首（锁定技）
	相关武将：林·孟获
	描述：【南蛮入侵】对你无效；当其他角色使用【南蛮入侵】指定目标后，你是该【南蛮入侵】造成伤害的来源。
	引用：LuaSavageAssaultAvoid、LuaHuoshou
	状态：0610待验证（小改）
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
			if player:isAlive() and sgs.TriggerSkill_triggerable(player) then
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
	技能名：烈刃
	相关武将：火·祝融
	描述：每当你使用【杀】对目标角色造成一次伤害后，你可以与其拼点，若你赢，你获得该角色的一张牌。
	引用：LuaLieren
	状态：0610待验证（根据源代码修改，删掉那烦人的一堆if--end）
]]--
LuaLieren = sgs.CreateTriggerSkill{
	name = "LuaLieren", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local room = player:getRoom()
		local target = damage.to
		if damage.card and damage.card:isKindOf("Slash") and (not player:isKongcheng()) 
				and (not target:isKongcheng()) and (target:objectName() ~= player:objectName() and (not damage.chain) and (not damage.transfer) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local success = player:pindian(target, "LuaLieren", nil)
				if not success then return false end
				if not target:isNude() then
					local card_id = room:askForCardChosen(player, target, "he", self:objectName())
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
					room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
				end
			end
		end
		return false
	end
}

--[[
	技能名：再起
	相关武将：林·孟获
	描述：摸牌阶段开始时，若你已受伤，你可以放弃摸牌，改为从牌堆顶亮出X张牌（X为你已损失的体力值），你回复等同于其中红桃牌数量的体力，然后将这些红桃牌置入弃牌堆，并获得其余的牌。
	引用：LuaZaiqi
	状态：0610待验证（根据源代码修改使用dummycard而不是一张一张扔）
]]--
LuaZaiqi = sgs.CreateTriggerSkill{
	name = "LuaZaiqi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			if player:isWounded() then
				local room = player:getRoom()
				if room:askForSkillInvoke(player, self:objectName()) then
					local x = player:getLostHp()
					local has_heart = false
					local ids = room:getNCards(x, false)
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = player
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					local card_to_throw = {}
					local card_to_gotback = {}
					for i=0, x-1, 1 do
						local id = ids:at(i)
						local card = sgs.Sanguosha:getCard(id)
						local suit = card:getSuit()
						if suit == sgs.Card_Heart then
							table.insert(card_to_throw, id)
						else
							table.insert(card_to_gotback, id)
						end
					end
					if #card_to_throw > 0 then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_throw) do
							dummy:addSubcard(id)
						end
						local recover = sgs.RecoverStruct()
						recover.card = nil
						recover.who = player
						recover.recover = #card_to_throw
						room:recover(player, recover)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
						room:throwCard(dummy, reason, nil)
						has_heart = true
					end
					if #card_to_gotback > 0 then
						local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_gotback) do
							dummy:addSubcard(id)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, player:objectName())
						room:obtainCard(player, dummy, reason)
					end
					return true
				end
			end
		end
		return false
	end
}

--[[
	技能名：巨象（锁定技）
	相关武将：林·祝融
	描述：【南蛮入侵】对你无效；当其他角色使用的【南蛮入侵】在结算后置入弃牌堆时，你获得之。
	引用：LuaSavageAssaultAvoid（祸首）、LuaJuxiang
	状态：0610待验证（完全重写）
]]--
LuaJuxiang = sgs.CreateTriggerSkill{
	name = "LuaJuxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BeforeCardsMove,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed() then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				if use.card:isVirtualCard() and (use.card:subcardsLength() ~= 1) then return false end
				if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId())
						and sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):isKindOf("SavageAssault") then
					room:setCardFlag(use.card:getEffectiveId(), "real_SA")
				end
			end
		elseif sgs.TriggerSkill_triggerable(player) then
			local move = data:toMoveOneTime()
			if (move.card_ids:length() == 1) and move.from_places:contains(sgs.Player_PlaceTable) and (move.to_place == sgs.Player_DiscardPile)
					and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE) then
				local card = sgs.Sanguosha:getCard(move.card_ids:first())
				if card:hasFlag("real_SA") and (player:objectName() ~= move.from:objectName()) then
					player:obtainCard(card)
					move.card_ids:clear()
					data:setValue(move)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

--[[
	技能名：好施
	相关武将：林·鲁肃
	描述：摸牌阶段，你可以额外摸两张牌，若此时你的手牌多于五张，则将一半（向下取整）的手牌交给全场手牌数最少的一名其他角色。
	引用：LuaHaoshiGive、LuaHaoshi、LuaHaoshiVS
	状态：0610待验证（LuaHaoshiGive重写，其余微调）
]]--
LuaHaoshiCard = sgs.CreateSkillCard{
	name = "LuaHaoshiCard", 
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) or to_select:objectName() == sgs.Self:objectName() then return false end
		return to_select:getHandcardsNum() == sgs.Self:getMark("LuaHaoshi")
	end,
	on_use = function(self, room, source, targets)
		room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, false)
	end
}
LuaHaoshiVS = sgs.CreateViewAsSkill{
	name = "LuaHaoshi", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() return false end
		local length = math.floor(sgs.Self:getHandcardNum() / 2)
		return #selected < length
	end, 
	view_as = function(self, cards)
		if #cards ~= math.floor(sgs.Self:getHandcardNum() / 2) then return nil end
		local card = LuaHaoshiCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaHaoshi"
	end
}
LuaHaoshiGive = sgs.CreateTriggerSkill{
	name = "#LuaHaoshiGive", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.AfterDrawNCards},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:hasFlag("LuaHaoshi") then
			player:setFlags("-LuaHaoshi")
			if player:getHandcardNum() <= 5 then return false end
			local other_players = room:getOtherPlayers(player)
			local least = 1000
			for _, _player in sgs.qlist(other_players) do
				least = math.min(_player:getHandcardNum(), least)
			end
			room:setPlayerMark(player, "LuaHaoshi", least)
			local used = room:askForUseCard(player, "@@LuaHaoshi", "@haoshi", -1, sgs.Card_MethodNone)
			if not used then
				local beggar
				for _, _player in sgs.qlist(other_players) do
					if _player:getHandcardNum() == least then
						beggar = _player
						break
					end
				end
				local n = math.floor(player:getHandcardNum() / 2)
				local to_give = player:handCards():mid(0, n)
				local haoshi_card = LuaHaoshiCard:clone()
				for _, card_id in sgs.qlist(to_give)
					haoshi_card:addSubcard(card_id)
				end
				local targets = {beggar}
				haoshi_card:on_use(room, player, targets)
			end
		end
	end
}
LuaHaoshi = sgs.CreateTriggerSkill{
	name = "#LuaHaoshi", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DrawNCards}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, "LuaHaoshi") then
			room:setPlayerFlag(player, "LuaHaoshi")
			local count = data:toInt() + 2
			data:setValue(count)
		end
	end
}

--[[
	技能名：缔盟
	相关武将：林·鲁肃
	描述：出牌阶段，你可以选择两名其他角色并弃置等同于他们手牌数差的牌，然后交换他们的手牌。每阶段限一次。
	引用：LuaDimeng
	状态：0610待验证（按照源码完全重写，胆守未处理）
]]--
LuaDimengCard = sgs.CreateSkillCard{
	name = "LuaDimengCard" ,
	target_fixed = false ,
	will_throw = true ,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if #targets == 0 then return true end
		if #targets == 1 then return math.abs(to_select:getHandcardNum() - targets[1]:getHandcardNum()) == self:subcardsLength()
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
		local move1 = sgs.CardMoveStruct()
		move1.card_ids = a:handCards()
		move1.to = b
		move1.to_place = sgs.Player_PlaceHand
		local move2 = sgs.CardMoveStruct()
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
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		local card = LuaDimengCard:clone()
		for _, c in ipairs(cards)
			card:addSubcard(c)
		end
		return card
	end ,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#LuaDimengCard")
	end
}
--[[
	技能名：完杀（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。
	引用：LuaWansha
	状态：0610未做（暂时没有想法）
]]--
--[[
	技能名：帷幕（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：你不能被选择为黑色锦囊牌的目标。
	引用：LuaWeimu
	状态：0610待验证（根据源码完全重做，现在的ProhibitSkill对所有人有效）
]]--
LuaWeimu = sgs.CreateProhibitSkill{
	name = "LuaWeimu" ,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("TrickCard") or card:isKindOf("QiceCard"))
				and card:isBlack() and (card:getSkillName() ~= "guhuo") --特别注意蛊惑
	end
}

--[[
	技能名：乱武（限定技）
	相关武将：林·贾诩、SP·贾诩
	描述：出牌阶段，你可以令所有其他角色各选择一项：对距离最近的另一名角色使用一张【杀】，或失去1点体力。
	引用：LuaLuanwu、LuaChaos1
	状态：0610待验证（重写技能卡on_effect，加入一个空时机触发技用于指示这个技能是限定技）
	
	Fs备注：其实可以把#@chaos-Lua-1直接写入LuaLuanwu的触发技里……
]]--
LuaLuanwuCard = sgs.CreateSkillCard{
	name = "LuaLuanwuCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@chaos")
		local players = room:getOtherPlayers(source)
		for _,p in sgs.qlist(players) do
			if p:isAlive() then
				room:cardEffect(self, source, p)
			end
		end
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local players = room:getOtherPlayers(effect.to)
		local distance_list = sgs.IntList()
		local nearest = 1000
		for _,player in sgs.qlist(players) do
			local distance = effect.to:distanceTo(player)
			distance_list:append(distance)
			nearest = math.min(nearest, distance)
		end
		local luanwu_targets = sgs.SPlayerList()
		local count = distance_list:length()
		for i = 0, count - 1, 1 do
			if (distance_list:at(i) == nearest) and effect.to:canSlash(players:at[i], nil, false) then
				luanwu_targets:append(players[i])
			end
		end
		if luanwu_targets:length() > 0 then
			if not room:askForUseSlashTo(effect.to, luanwu_targets, "@luanwu-slash") then
				room:loseHp(effect.to)
			end
		else
			room:loseHp(effect.to)
		end
	end
}
LuaLuanwuVS = sgs.CreateViewAsSkill{
	name = "LuaLuanwu", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaLuanwuCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@chaos") >= 1
	end
}
LuaLuanwu = sgs.CreateTriggerSkill{
	name = "LuaLuanwu" ,
	frequency = sgs.Skill_Limited ,
	events = {} ,
	view_as_skill = LuaLuanwuVS ,
	on_trigger = function()end
}
LuaChaos1 = sgs.CreateTriggerSkill{
	name = "#@chaos-Lua-1",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		player:gainMark("@chaos", 1)
	end
}

--[[
	技能名：酒池
	相关武将：林·董卓
	描述：你可以将一张黑桃手牌当【酒】使用。
	引用：LuaJiuchi
	状态：0610待验证（根据源代码修改enabled_at_play部分，其余小改）
]]--
LuaJiuchi = sgs.CreateViewAsSkill{
	name = "LuaJiuchi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Spade)
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local analeptic = sgs.Sanguosha:cloneCard("analeptic", cards[1]:getSuit(), cards[1]:getNumber())
			analeptic:setSkillName(self:objectName())
			analeptic:addSubcard(cards[1])
			return analeptic
		end
	end, 
	enabled_at_play = function(self, player)
		return not sgs.Analeptic_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic")
	end
}

--[[
	技能名：肉林（锁定技）
	相关武将：林·董卓
	当你使用【杀】指定一名女性角色为目标后，该角色需连续使用两张【闪】才能抵消；当你成为女性角色使用【杀】的目标后，你需连续使用两张【闪】才能抵消。
	引用：LuaRoulin
	状态：0610未做（源代码更换使用和马超黄忠吕布相同的方法，暂时没有做的想法）
]]--

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
		if (event == sgs.PreDamageDone) and damage.from then
			damage.from:setTag("InvokeLuaBaonve", damage.from:getKingdom() == "qun")
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
--[[
	技能名：毅重（锁定技）
	相关武将：一将成名·于禁
	描述：若你的装备区没有防具牌，黑色的【杀】对你无效。
	引用：LuaYizhong
	状态：0610待验证（can_trigger部分根据源码小改）
]]--
LuaYizhong = sgs.CreateTriggerSkill{
	name = "LuaYizhong", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.SlashEffected}, 
	on_trigger = function(self, event, player, data)
		local effect = data:toSlashEffect()
		if effect.slash:isBlack() then
			return true
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target and sgs.TriggerSkill_triggerable(target) and (target:getArmor() == nil)
	end
}

--[[
	技能名：落英
	相关武将：一将成名·曹植
	描述：当其他角色的梅花牌因弃置或判定而置入弃牌堆时，你可以获得之。
	引用：LuaLuoying
	状态：0610待验证（根据源代码完全重写，第一次使用LUA5.2的bit32库，可能出现问题）
]]--
--require("bit")
listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
LuaLuoying = sgs.CreateTriggerSkill{
	name = "LuaLuoying",
	frequency = sgs.Skill_Frequent,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if (move.from:objectName() == player:objectName()) or (move.from == nil) then return false end
		if (move.place == sgs.Player_DiscardPile) 
				and ((bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) 
				--and ((bit:_and(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
				or (move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE)) then
			local card_ids = sgs.IntList()
			local i = 0
			for _, card_id in sgs.qlist(move.card_ids) do
				if (sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Club)
						and (((move.reason.m_reason == sgs.CardMoveReasson_S_REASON_JUDGEDONE) 
						and (move.from_places:at(i) == sgs.Player_PlaceJudge)
						and (move.to_place == sgs.Player_DiscardPile))
						or ((move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_JUDGEDONE)
						and (room:getCardOwner(card_id):objectName() == move.from:objectName())
						and ((move.from_places[i] == sgs.Player_PlaceHand) or (move.from_places[i] == sgs.Player_PlaceEquip)))) then
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
							move.from_places:removeAt(listIndexOf(move.card_ids, id))
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
	技能名：酒诗
	相关武将：一将成名·曹植
	描述：若你的武将牌正面朝上，你可以将你的武将牌翻面，视为使用一张【酒】；若你的武将牌背面朝上时你受到伤害，你可以在伤害结算后将你的武将牌翻转至正面朝上。
	引用：LuaJiushi、LuaJiushiFlip
	状态：0610待验证（视为技enabled_at_xx部分根据源代码小改，触发技时机根据源代码修改，根据源代码删掉了一些很蛋疼但又没什么用的变量声明）
	
	Fs备注：其实我感觉这个技能比较无语，有很多视为+触发技直接做成触发技带view_as_skill部分的那种形式，直接引用一个技能即可，这个技能源码上面还是引用两部分…………
]]--
LuaJiushi = sgs.CreateViewAsSkill{
	name = "LuaJiushi",
	n = 0,
	view_as = function(self, cards)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		analeptic:setSkillName(self:objectName())
		return analeptic
	end, 
	enabled_at_play = function(self, player)
		return sgs.Analeptic_IsAvailable(player) and player:faceUp()
	end, 
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic") and player:faceUp()
	end
}
LuaJiushiFlip = sgs.CreateTriggerSkill{
	name = "#LuaJiushi-flip", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.PreCardUsed, sgs.PreDamageDone, sgs.DamageComplete},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card:getSkillName() == "LuaJiushi" then
				player:turnOver()
			end
		elseif event == sgs.PreDamageDone then
			room:setTag("PredamagedFace", sgs.QVariant(player:faceUp()))
		elseif event == sgs.DamageComplete then
			local faceup = room:getTag("PredamagedFace"):toBool()
			room:removeTag("PredamagedFace")
			if not (faceup or player:faceUp()) then
				if player:askForSkillInvoke("LuaJiushi", data) then
					player:turnOver()
				end
			end
		end
	end
}


--[[
	技能名：无言（锁定技）
	相关武将：一将成名·徐庶
	描述：你防止你造成或受到的任何锦囊牌的伤害。
	引用：LuaWuyan
	状态：0610待验证（根据源码修改，几乎完全重写）
]]--
LuaWuyan = sgs.CreateTriggerSkill{
	name = "LuaWuyan",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageCaused, sgs.DamageInflicted}, 
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.card and (damage.card:getTypeId() == sgs.Card_TypeTrick) then
			if (event == sgs.DamageInflicted) and player:hasSkill(self:objectName()) then
				return true
			end
			if (event == sgs.DamageCaused) and damage.from and sgs.TriggerSkill_triggerable(damage.from) then
				return true
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}


--[[
	技能名：举荐
	相关武将：一将成名·徐庶
	描述：回合结束阶段开始时，你可以弃置一张非基本牌，令一名其他角色选择一项：摸两张牌，或回复1点体力，或将其武将牌翻至正面朝上并重置之。
	引用：LuaJujian
	状态：0610待验证（小改）
]]--
LuaJujianCard = sgs.CreateSkillCard{
	name = "LuaJujianCard",
	target_fixed = false,
	will_throw = true, 
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_effect = function(self, effect) 
		local room = effect.from:getRoom()

		local choiceList = {"draw"}
		if effect.to:isWounded() then
			table.insert(choiceList, "recover")
		end
		if (not effect.to:faceUp()) or effect.to:isChained() then
			table.insert(choiceList, "reset")
		end
		local choice = room:askForChoice(effect.to, "LuaJujian", table.concat(choiceList, "+"))
		if choice == "draw" then
			effect.to:drawCards(2)
		elseif choice == "recover" then
			local recover = sgs.RecoverStruct()
			recover.who = effect.from
			room:recover(effect.to, recover)
		elseif choice == "reset" then
			if effect.to:isChained()
				room:setPlayerProperty(effect.to, "chained", sgs.QVariant(false))
			end
			if not effect.to:faceUp() then
				effect.to:turnOver()
			end
		end
	end
}
LuaJujianVS = sgs.CreateViewAsSkill{
	name = "LuaJujian", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return (not to_select:isKindOf("BasicCard")) and (not sgs.Self:isJilei(to_select))
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local jujiancard = LuaJujianCard:clone()
			jujiancard:addSubcard(cards[1])
			return jujiancard
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaJujian"
	end
}
LuaJujian = sgs.CreateTriggerSkill{
	name = "LuaJujian", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = LuaJujianVS, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getPhase() == sgs.Player_Finish) and player:canDiscard(player, "he") then
			room:askForUseCard(player, "@@LuaJujian", "@jujian-card", -1, sgs.Card_MethodNone)
		end
		return false
	end
}
--[[
	技能名：恩怨
	相关武将：一将成名·法正
	描述：你每次获得一名其他角色两张或更多的牌时，可以令其摸一张牌；每当你受到1点伤害后，你可以令伤害来源选择一项：交给你一张手牌，或失去1点体力。
	引用：LuaEnyuan
	状态：0610待验证（完全重写）
]]--

LuaEnyuan = sgs.CreateTriggerSkill{
	name = "LuaEnyuan" ,
	events == {sgs.CardsMoveOneTime, sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.to:objectName() == player:objectName()) and move.from and move.from:isAlive() and (move.from:objectName() ~= move.to:objectName())
					and (move.card_ids:length() >= 2)
					and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) then
				move.from:setFlags("LuaEnyuanDrawTarget")
				local invoke = room:askForSkillInvoke(player, self:objectName(), data)
				move.from:setFlags("-LuaEnyuanDrawTarget")
				if invoke then
					room:drawCards(move.from, 1)
				end
			end
		elseif event == sgs.Damged then
			local damage = data:toDamage()
			local source = damage.from
			if (not source) or (source:objectName() == player:objectName()) then return false end
			local x = damage.damage
			for i = 0, x - 1, 1 do
				if source:isAlive() and player:isAlive() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						local card
						if not source:isKongcheng() then
							card = room:askForExchange(source, self:objectName(), 1, false, "LuaEnyuanGive", true)
						end
						if card then
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
															  player:objectName(), self:objectName(), nil)
							reason.m_playerId = player:objectName()
							room:moveCardTo(card, source, plyaer, sgs.Player_PlaceHand, reason)
						else
							room:loseHp(source)
						end
					else
						break
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
	技能名：眩惑
	相关武将：一将成名·法正
	描述：摸牌阶段开始时，你可以放弃摸牌，改为令一名其他角色摸两张牌，然后令其对其攻击范围内你选择的另一名角色使用一张【杀】，若该角色未如此做或其攻击范围内没有其他角色，你获得其两张牌。
	引用：LuaXuanhuo、LuaXuanhuoFakeMove
	状态：0610待验证（完全重写，放弃技能卡，加入了假移动附属技能）
]]--

LuaXuanhuo = sgs.CreateTriggerSkill{
	name = "LuaXuanhuo" ,
	events == {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "xuanhuo-invoke", true, true)
			if to then
				room:drawCards(to, 2)
				if (not player:isAlive()) or (not to:isAlive()) then return true end
				local targets = sgs.SPlayerList()
				for _, vic in sgs.qlist(room:getOtherPlayers(to)) do
					if to:canSlash(vic) then
						targets:append(vic)
					end
				end
				local victim
				if not targets:isEmpty() then
					victim = room:askForPlayerChosen(player, targets, "xuanhuo_slash", "@dummy-slash2:" .. to:objectName())
				end
				if victim then --不得已写了两遍movecard…………
					if not room:askForUseSlashTo(to, victim, "xuanhuo-slash:" .. player:objectName() .. ":" .. victim:objectName()) then
						if to:isNude() then return true end
						room:setPlayerFlag(to, "LuaXuanhuo_InTempMoving")
						local first_id = room:askForCardChosen(player, to, "he", self:objectName())
						local original_place = room:getCardPlace(first_id)
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:addSubcard(first_id)
						to:addToPile("#xuanhuo", dummy, false)
						if not to:isNude() then
							local second_id = room:askForCardChosen(player, to, "he", self:objectName())
							dummy:addSubCard(second_id)
						end
						room:moveCardTo(sgs.Sanguosha:getCard(first_id), to, original_place, false)
						room:setPlayerFlag(to, "-LuaXuanhuo_InTempMoving")
						room:moveCardTo(dummy, player, sgs.Player_PlaceHand, false)
						--delete dummy
					end
				else
					if to:isNude() then return true end
					room:setPlayerFlag(to, "LuaXuanhuo_InTempMoving")
					local first_id = room:askForCardChosen(player, to, "he", self:objectName())
					local original_place = room:getCardPlace(first_id)
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					dummy:addSubcard(first_id)
					to:addToPile("#xuanhuo", dummy, false)
					if not to:isNude() then
						local second_id = room:askForCardChosen(player, to, "he", self:objectName())
						dummy:addSubCard(second_id)
					end
					room:moveCardTo(sgs.Sanguosha:getCard(first_id), to, original_place, false)
					room:setPlayerFlag(to, "-LuaXuanhuo_InTempMoving")
					room:moveCardTo(dummy, player, sgs.Player_PlaceHand, false)
					--delete dummy
				end
				return true
			end
		end
		return false
	end
}
LuaXuanhuoFakeMove = sgs.CreateTriggerSkill{
	name = "#LuaXuanhuo-fake-move" ,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime} ,
	priority = 10 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("LuaXuanhuo_InTempMoving") then return true end
		end
		return false
	end
}
--[[
	技能名：挥泪（锁定技）
	相关武将：一将成名·马谡
	描述：当你被其他角色杀死时，该角色弃置其所有的牌。
	引用：LuaHuilei
	状态：0610待验证
]]--

LuaHuilei = sgs.CreateTriggerSkill{
	name = "LuaHuilei", 
	events = {sgs.Death} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local killer
		if death.damage then
			killer = death.damage.from
		else
			killer = nil
		end
		if killer then
			killer:throwAllHandCardsAndEquips()
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}

--[[
	技能名：旋风
	相关武将：一将成名·凌统
	描述：当你失去装备区里的牌时，或于弃牌阶段内弃置了两张或更多的手牌后，你可以依次弃置一至两名其他角色的共计两张牌。
	引用：LuaXuanfeng
	状态：0610待验证
]]--

LuaXuanfengCard = sgs.CreateSkillCard{
	name = "LuaXuanfengCard" ,
	view_filter = function(self, targets, to_select)
		if #targets >= 2 then return false end
		if to:select:objectName() == sgs.Self:objectName() then return false end
		return sgs.Self:canDiscard(to_select, "he")
	end ,
	on_use = function(self, room, source, targets)
		local map = {}
		local totaltarget = 0
		for _, sp in ipairs(targets) do
			map[sp] = 1
		end
		for i = 0, #map - 1, 1 do
			totaltarget = totaltarget + 1
		end
		if totaltarget == 1 then
			for sp, _ in ipairs(map) do
				map[sp] = map[sp] + 1
			end
		end
		for sp, _ in ipairs(map) do
			while map[sp] > 0 do
				if source:isAlive() and sp:isAlive() and source:canDiscard(sp, "he") then
					local card_di = room:askForCardChosen(source, sp, "he", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(card_id, sp, source)
				end
				map[sp] = map[sp] - 1
			end
		end
	end
}
LuaXuanfengVS = sgs.CreateViewAsSkill{
	name = "LuaXuanfeng" ,
	n = 0 ,
	view_as = function()
		return LuaXuanfengCard:clone()
	end
	enabled_at_play = function()
		return false 
	end
	enabled_at_response = function(self, target, pattern)
		return pattern == "@@LuaXuanfeng"
	end
}
--require("bit")
LuaXuanfeng = sgs.CreateTriggerSkill{
	name = "LuaXuanfeng" ,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart} ,
	view_as_skill = LuaXuanfengVS ,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			player:setMark("LuaXuanfeng", 0)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from:objectName() ~= player:objectName() then return false end
			if (move.to_place == sgs.Player_DiscardPile) and (player:getPhase() == sgs.Player_Discard)
					and (bit32:band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
					--and (bit:_and(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				player:setMark("LuaXuanfeng", player:getMark("LuaXuanfeng") + move.card_ids:length())
			end
			if ((player:getMark("LuaXuanfeng") >= 2) and (not lingtong:hasFlag("LuaXuanfengUsed")))
					or move.from_places:contains(sgs.Player_PlaceEquip) then
				local targets = sgs.SPlayerList()
				for _, target in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canDiscard(target, "he") then
						targets:append(target)
					end
				end
				if targets:isEmpty() then return false end
				local choice = room:askForChoice(player, self:objectName(), "throw+nothing") --这个地方令我非常无语…………用askForSkillInvoke不好么…………
				if choice == "throw" then
					player:setFlags("LuaXuanfengUsed")
					room:askForUseCard(player, "@@LuaXuanfeng", "@xuanfeng-card")
				end
			end
		end
		return false
	end
}

--[[
	技能名：破军
	相关武将：一将成名·徐盛
	描述：每当你使用【杀】对目标角色造成一次伤害后，你可以令其摸X张牌（X为该角色当前的体力值且至多为5），然后该角色将其武将牌翻面。
	引用：LuaPojun
	状态：0610待验证
]]--
LuaPojun = sgs.CreateTriggerSkill{
	name = "LuaPojun" ,
	events = {sgs.Damage} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer)
				and damage.to:isAlive() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local x = math.min(5, damage.to:getHp())
				damage.to:drawCards(x)
				damage.to:turnOver()
			end
		end
		return false
	end
}
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
	技能名：禁酒（锁定技）
	相关武将：一将成名·高顺
	描述：你的【酒】均视为【杀】。
	引用：LuaJinjiu
	状态：0610待验证
]]--

LuaJinjiu = sgs.CreateFilterSkill{
	name = "LuaJinjiu" ,
	view_filter = function(self, card)
		return card:objectName() == "analepitc"
	end ,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(slash)
		return wrap
	end
}
--[[
	技能名：明策
	相关武将：一将成名·陈宫
	描述：出牌阶段，你可以交给一名其他角色一张装备牌或【杀】，该角色选择一项：1. 视为对其攻击范围内你选择的另一名角色使用一张【杀】。2. 摸一张牌。每回合限一次。
	引用：LuaMingce
	状态：0610待验证（未处理胆守）
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
		if (not targets:isEmpty) and effect.from:isAlive() then
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
	end
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaMingceCard")
	end
}

--[[
	技能名：智迟（锁定技）
	相关武将：一将成名·陈宫
	描述：你的回合外，每当你受到一次伤害后，【杀】或非延时类锦囊牌对你无效，直到回合结束。
	引用：LuaZhichi、LuaZhichiProtect、LuaZhichiClear
	状态：0610待验证
]]--

LuaZhichi = sgs.CreateTriggerSkill{
	name = "LuaZhichi" ,
	events = {sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		local current = room:getCurrent()
		if current and current:isAlive() and (current:getPhase ~= sgs.Player_NotActive) then
			if player:getMark("@late") == 0 then
				room:addPlayerMark(player, "@late")
			end
		end
	end
}
LuaZhichiProtect = sgs.CreateTriggerSkill{
	name = "#LuaZhichi-protect" ,
	events = {sgs.CardEffected} ,
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if (effect.card:isKindOf("Slash") or effect.card:isNDTrick()) and (effect.to:getMark("@late") > 0) then
			return true
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
LuaZhichiClear = sgs.CreateTriggerSkill{
	name = "#LuaZhichi-clear" ,
	events = {sgs.EventPhaseChanging, sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		else
			local death = data:toDeath()
			if (death.who:objectName() ~= player:objectName()) or (player:objectName() ~= room:getCurrent:objectName()) then
				return false
			end
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("@late") > 0 then
				room:setPlayerMark(p, "@late", 0)
			end
		end
		return false
	end
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：甘露
	相关武将：一将成名·吴国太
	描述：出牌阶段，你可以交换两名角色装备区里的牌，以此法交换的装备数差不能超过X（X为你已损失体力值）。每阶段限一次。
	引用：LuaGanlu
	状态：0610待验证
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
	move.to = second
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
			int n1 = targets:first():getEquips():length()
			int n2 = to_select:getEquips():length()
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
	技能名：补益
	相关武将：一将成名·吴国太
	描述：当一名角色进入濒死状态时，你可以展示该角色的一张手牌，若此牌不为基本牌，该角色弃置之，然后回复1点体力。
	引用：LuaBuyi
	状态：0610待验证
]]--

LuaBuyi = sgs.CreateTriggerSkill{
	name = "LuaBuyi",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local _player = dying.who
		if _player:isKongcheng() then return false end
		if _player:getHp() < 1 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local card
				if player:objectName() == _player:objectName() then 
					card = room:askForCardShow(_player, player, "LuaBuyi")
				else
					local id = room:askForCardChosen(player, _player, "h", self:objectName())
					card = sgs.Sanguosha:getCard(id) 
				end
				room:showCard(_player, card:getEffectiveId())
				if card:getTypeId() ~= sgs.Card_TypeBasic then
					if not _player:isJilei(card) then 
						room:throwCard(card, _player)
					end
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(_player, recover) 		
				end
			end
		end
		return false
	end,
}
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
	技能名：权计
	相关武将：一将成名·钟会
	描述：每当你受到1点伤害后，你可以摸一张牌，然后将一张手牌置于你的武将牌上，称为“权”；每有一张“权”，你的手牌上限便+1。
	引用：LuaQuanji、LuaQuanjiKeep、LuaQuanjiRemove
	状态：0610待验证
]]--
LuaQuanji = sgs.CreateTriggerSkill{
	name = "LuaQuanji", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Damaged}, 
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		local x = damage.damage
		for i = 0, x - 1, 1 do
			if player:askForSkillInvoke(self:objectName()) then
				room:drawCards(player, 1)
				if not player:isKongcheng() then
					local card_id
					if player:getHandcardNum() == 1 then
						card_id = player:handCards():first()
					else
						card_id = room:askForExchange(player, self:objectName(), 1, false, "QuanjiPush"):getSubcards():first()
					end
					player:addToPile("power", card_id)
				end
			end
		end
	end
}
LuaQuanjiKeep = sgs.CreateMaxCardsSkill{
	name = "#LuaQuanji-keep", 
	extra_func = function(self, target) 
		if target:hasSkill(self:objectName()) then
			returntarget:getPile("power"):length()
		else
			return 0
		end
	end
}
LuaQuanjiRemove = sgs.CreateTriggerSkill{
	name = "#LuaQuanjiRemove", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventLoseSkill}, 
	on_trigger = function(self, event, player, data)
		if data:toString() == "LuaQuanji" then
			player:clearOnePrivatePile("power")
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}


--[[
	技能名：自立（觉醒技）
	相关武将：一将成名·钟会
	描述：回合开始阶段开始时，若“权”的数量达到3或更多，你须减1点体力上限，然后回复1点体力或摸两张牌，并获得技能“排异”。
	引用：LuaZili
	状态：0610待验证
]]
LuaZili = sgs.CreateTriggerSkill{
	name = "LuaZili" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "LuaZili")
		if room:changeMaxHpForAwakenSkill(player) then
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
			room:acquireSkill(player, "paiyi")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return sgs.TriggerSkill_triggerable(target)
		   and (target:getPhase() == sgs.Player_Start)
		   and (target:getMark("LuaZili") == 0)
		   and (target:getPile("power"):length() >= 3)
	end
}

--[[
	技能名：排异
	相关武将：一将成名·钟会
	描述：出牌阶段，你可以将一张“权”置入弃牌堆，令一名角色摸两张牌，然后若该角色的手牌数大于你的手牌数，你对其造成1点伤害。每阶段限一次。
	引用：LuaPaiyi
	状态：0610未完成（源码有一段修改card:onUse执行，LUA无此接口，只能替代运行）
]]--


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
		return sgs.TriggerSkill_triggerable(target) and target:canDiscard(target, "h")
	end
}

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
		return sgs.TriggerSkill_triggerable(target) and (target:getPhase() == sgs.Player_NotActive)
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
	end
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：凿险（觉醒技）
	相关武将：山·邓艾
	描述：回合开始阶段开始时，若“田”的数量达到3或更多，你须减1点体力上限，并获得技能“急袭”。
	引用：LuaZaoxian
	状态：验证通过
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
		return sgs.TriggerSkill_triggerable(target)
			and (target:getPhase() == sgs.Player_Start)
			and (target:getMark("LuaZaoxian") == 0)
			and (target:getPile("field"):length() >= 3)
	end
}

--[[
	技能名：急袭
	相关武将：山·邓艾
	描述：你可以将一张“田”当【顺手牵羊】使用。
	引用：LuaJixi
	状态：0610未完成（源码有一段修改card:onUse执行，LUA无此接口，只能替代运行）
]]--
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
		return sgs.TriggerSkill_triggerable(target)
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
		return sgs.TriggerSkill_triggerable(target)
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
	状态：验证通过
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
	状态：0610未做（太麻烦，还没有下手）
]]--
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
	end
}
--[[
	技能名：涉猎
	相关武将：神·吕蒙
	描述：摸牌阶段开始时，你可以放弃摸牌，改为从牌堆顶亮出五张牌，你获得不同花色的牌各一张，将其余的牌置入弃牌堆。 
	引用：LuaShelie
	状态：0610未做（貌似此版本有几条语句不能LUA）
]]--
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
	技能名：业炎（限定技）
	相关武将：神·周瑜
	描述：出牌阶段，你可以选择一至三名角色，你分别对他们造成最多共3点火焰伤害（你可以任意分配），若你将对一名角色分配2点或更多的火焰伤害，你须先弃置四张不同花色的手牌并失去3点体力。
	状态：0610未做
]]--
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
	状态：0610待验证（源码有bug，暂时搁置）
]]--

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
				if player:getRoom():askForChoice(player, self:objectName(), "discard+losehp") == "discard" the
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
	状态：验证通过
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
		return sgs.TriggerSkill_triggerable(target) and (target:getPile("stars"):length() > 0)
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
		return target and sgs.TriggerSkill_triggerable(target)
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
	enabled_at_nullification(self, player)
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

