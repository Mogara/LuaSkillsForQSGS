--[[
	代码速查手册（V区）
	技能索引：（本区用于收录尚未实现或有争议的技能）
	☆源代码转化失败，改写后通过：
		不屈、称象、虎啸、祸水、龙胆、龙魂、龙魂
	☆验证失败：
		洞察、弘援、缓释、激将、极略、连理、秘计、神速、探虎、伪帝、修罗
	☆尚未完成：
		蛊惑、归心、倾城
	☆尚未验证：
		明哲、军威、死谏、骁果、雄异、援护
	☆验证通过：
		弓骑、弘援、缓释、疠火
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
	if player:getRole()=="lord" then return other:getRole()=="loyalist" end
	if player:getRole()=="loyalist" then return other:getRole()=="lord" end
	if player:getRole()=="renegade" then return other:getRole()=="rebel" end
	if player:getRole()=="rebel" then return other:getRole()=="renegade" end
end
LuaXHongyuan = sgs.CreateTriggerSkill{
	name = "LuaXHongyuan",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DrawNCards},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			room:setPlayerFlag(player, self:objectName())
			local count = data:toInt() - 1
			data:setValue(count)
		end
	end
}
LuaXHongyuanAct = sgs.CreateTriggerSkill{
	name = "#LuaXHongyuanAct",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.AfterDrawNCards},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if player:hasFlag("LuaXHongyuan") then
				room:setPlayerFlag(player, "-Invoked")
				for _,other in sgs.qlist(room:getOtherPlayers(player)) do
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
LuaXHongyuanCard = sgs.CreateSkillCard{
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
LuaXHongyuanVS = sgs.CreateViewAsSkill{
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
	events = {sgs.DrawNCards},  
	view_as_skill = LuaXHongyuanVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			room:setPlayerFlag(player, self:objectName())
			local count = data:toInt() - 1
			data:setValue(count)
		end
	end
}
LuaXHongyuanAct = sgs.CreateTriggerSkill{
	name = "#LuaXHongyuanAct",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.AfterDrawNCards},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if player:hasFlag("LuaXHongyuan") then
				room:setPlayerFlag(player, "-Invoked")
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
	events = {sgs.SlashMissed,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		if event == sgs.SlashMissed then
			if player:getPhase() == sgs.Player_Play then
				player:gainMark("Huxiao", 1)
			end
		elseif event == sgs.EventPhaseChanging then	
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				local x = player:getMark("Huxiao")
				if x > 0 then
					player:loseMark("Huxiao", x)
				end
			end
		end
	end,
}
LuaHuxiaoHid = sgs.CreateTargetModSkill{
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
	if player:getRole()=="lord" then return other:getRole()=="loyalist" end
	if player:getRole()=="loyalist" then return other:getRole()=="lord" end
	if player:getRole()=="renegade" then return other:getRole()=="rebel" end
	if player:getRole()=="rebel" then return other:getRole()=="renegade" end
end

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
		local judge = data:toJudge()
		local can_invoke = false
		local room = player:getRoom()
		if Lua3V3_isFriend(player,judge.who) then
			can_invoke = true
		end
		if not can_invoke then
			return false
		end
		local prompt_list = {"@huanshi-card", judge.who:objectName(), self:objectName(), judge.reason, judge.card:getEffectIdString()}
		local prompt = table.concat(prompt_list, ":")
		player:setTag("Judge", data)
		local pattern = "@LuaXHuanshi"
		local card = room:askForCard(player, pattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				return not target:isNude()
			end
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
		local judge = data:toJudge()
		local can_invoke = false
		local room = player:getRoom()
		if judge.who:objectName() ~= player:objectName() then
			if room:askForSkillInvoke(player, self:objectName()) then
				if room:askForChoice(judge.who, self:objectName(), "yes+no") == "yes" then
					can_invoke = true;
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
		player:setTag("Judge", data)
		local pattern = "@LuaXHuanshi"
		local card = room:askForCard(player, pattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				return not target:isNude()
			end
		end
		return false
	end
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
	状态：验证失败（不能拥有主公技）
]]--
LuaWeidiCard = sgs.CreateSkillCard{
	name = "LuaWeidiCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		local lord = room:getLord()
		local choices = sgs.StringList()
		if source:hasLordSkill("jijiang") then
			if lord:hasLordSkill("jijiang") then
				if sgs.Slash_IsAvailable(source) then
					choices:append("jijiang")
				end
			end
		end
		if source:hasLordSkill("weidai") then
			if lord:hasLordSkill("weidai") then
				if sgs.Analeptic_IsAvailable(source) then
					choices:append("weidai")
				end
			end
		end
		if choices:length() > 0 then
			local choice = ""
			if choices:length() == 1 then
				choice = choices:first()
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
	name = "LuaWeidiVS", 
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
	end
}
LuaWeidi = sgs.CreateTriggerSkill{
	name = "LuaWeidi", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.GameStart}, 
	view_as_skill = LuaWeidiVS, 
	on_trigger = function(self, event, player, data) 
		-- do nothing --
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
