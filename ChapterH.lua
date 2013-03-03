--[[
	代码速查手册（H区）
	技能索引：
		汉统、好施、红颜、弘援、后援、虎啸、胡笳、护驾、化身、缓释、缓释、皇恩、黄天、挥泪、魂姿、火计、祸首、祸水
]]--
--[[
	技能名：汉统
	相关武将：贴纸·刘协
	描述：弃牌阶段，你可以将你弃置的手牌置于武将牌上，称为“诏”。你可以将一张“诏”置入弃牌堆，然后你拥有并发动以下技能之一：“护驾”、“激将”、“救援”、“血裔”，直到当前回合结束。 
]]--
LuaHantongRemove=function(room,player)
	local card_ids=player:getPile("hantongpile")
	room:fillAG(card_ids,nil)
	local card_id=room:askForAG(player,card_ids,true,"thshengzhi")
	for _,p in sgs.qlist(room:getPlayers()) do
		p:invoke("clearAG")
	end
	return card_id
end

LuaHantongCard=sgs.CreateSkillCard{
	name="LuaHantongCard",
	filter = function(self, targets, to_select, player)
		return #targets==0 and player:canSlash(to_select,sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0),true)
	end,
	on_use = function(self, room, source, targets)
		if not source:hasFlag("hantongjijiang") then
			local card_id=LuaHantongRemove(room,source)
			if card_id==-1 then return end
			local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, "LuaHantong", "")
			room:moveCardTo(sgs.Sanguosha:getCard(card_id),nil,sgs.Player_DiscardPile,reason,true)
			room:setPlayerFlag(source,"hantong")
			room:setPlayerFlag(source,"hantongjijiang")
		end
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
			local slash
			if(p:getKingdom() == "shu") then
				slash = room:askForCard(p, "slash", "@jijiang-slash" , sgs.QVariant() , sgs.CardResponsed)
				if(slash) then
					local use=sgs.CardUseStruct()
						use.card=slash
						use.to:append(targets[1])
						use.from=source
					room:useCard(use,true)
					break
				else
					room:setPlayerFlag(p,"sbleba")
				end
			end
		end
	end,
}

LuaHantongVS=sgs.CreateViewAsSkill{
	name="LuaHantong",
	n=0,
	view_as = function(self, cards)
		return LuaHantongCard:clone()
	end,
	enabled_at_play=function(self, player)
		return ((player:canSlashWithoutCrossbow()) or (player:getWeapon() and player:getWeapon():getClassName() == "Crossbow")) and (not player:getPile("hantongpile"):isEmpty() or player:hasFlag("hantongjijiang"))
	end,
}

LuaHantong=sgs.CreateTriggerSkill{
	name="LuaHantong",
	frequency=sgs.Skill_NotFrequent,
	events={sgs.CardDiscarded,sgs.EventPhaseStart,sgs.CardAsked,sgs.HpRecover},
	view_as_skill=LuaHantong,
	on_trigger=function(self,event,player,data)
		local card_id
		local room=player:getRoom()
		local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, "LuaHantong", "")
		if event==sgs.CardDiscarded then
			if player:getPhase() ~= sgs.Player_Discard then return end
			if not player:askForSkillInvoke(self:objectName()) then return end
			player:addToPile("hantongpile", data:toCard(), true)
			return
		end
		if (player:getPile("hantongpile"):isEmpty() and not player:hasFlag("hantong")) then return end
		if event==sgs.CardAsked then
			if(data:toString() == "jink") then
				if not player:hasFlag("hantonghujia") and player:getPile("hantongpile"):isEmpty() then return end
				if not player:askForSkillInvoke("hujia") then return end
				if not player:hasFlag("hantonghujia") then
					card_id=LuaHantongRemove(room,player)
					if card_id==-1 then return end
					room:moveCardTo(sgs.Sanguosha:getCard(card_id),nil,sgs.Player_DiscardPile,reason,true)
					room:setPlayerFlag(player,"hantong")
					room:setPlayerFlag(player,"hantonghujia")
				end
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					local jink
					if(p:getKingdom() == "wei") then
						jink = room:askForCard(p, "jink", "@hujia-liuxie", sgs.QVariant(), sgs.CardResponsed)
						if(jink) then
							room:provide(jink)
							return true
						end
					end
				end
				return
			end
			if(data:toString() == "slash") then
				if not player:hasFlag("hantongjijiang") and player:getPile("hantongpile"):isEmpty() then return end
				if not player:askForSkillInvoke("jijiang") then return end
				if not player:hasFlag("hantongjijiang") then
					card_id=LuaHantongRemove(room,player)
					if card_id==-1 then return end
					room:moveCardTo(sgs.Sanguosha:getCard(card_id),nil,sgs.Player_DiscardPile,reason,true)
					room:setPlayerFlag(player,"hantong")
					room:setPlayerFlag(player,"hantongjijiang")
				end
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					local slash
					if(p:getKingdom() == "shu") then
						slash = room:askForCard(p, "slash", "@jijiang-slash", sgs.QVariant(), sgs.CardResponsed)
						if(slash) then
							room:provide(slash)
							return true
						end
					end
				end
				return
			end
			return
		end
		if event==sgs.HpRecover then
			local recover=data:toRecover()
			if not (recover.card:isKindOf("Peach") and player:hasFlag("dying") and recover.who:getKingdom() == "wu" and recover.who:objectName()~=player:objectName()) then return end
			if not player:hasFlag("hantongjiuyuan") then
				if player:getPile("hantongpile"):isEmpty() then return end
				if not player:askForSkillInvoke("jiuyuan") then return end
				card_id=LuaHantongRemove(room,player)
				if card_id==-1 then return end
				room:moveCardTo(sgs.Sanguosha:getCard(card_id),nil,sgs.Player_DiscardPile,reason,true)
				room:setPlayerFlag(player,"hantong")
				room:setPlayerFlag(player,"hantongjiuyuan")
			end
			local index
			if recover.who:isMale() then
				index=2
			else
				index=3
			end
			recover.recover=recover.recover+1
			data:setValue(recover)
		end
		if event==sgs.EventPhaseStart then
			if player:getPhase()~=sgs.Player_Discard then return end
			room:setPlayerMark(player,"hantong",0)
			if not player:hasFlag("hantongxueyi") then
				if player:getPile("hantongpile"):isEmpty() then return end
				if not player:askForSkillInvoke("xueyi") then return end
				card_id=hantongremove(room,player)
				if card_id==-1 then return end
				room:moveCardTo(sgs.Sanguosha:getCard(card_id),nil,sgs.Player_DiscardPile,reason,true)
				room:setPlayerFlag(player,"hantong")
				room:setPlayerFlag(player,"hantongxueyi")
				local qunnum=0
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if(p:getKingdom() == "qun") then
						qunnum=qunnum+1
					end
				end
				room:setPlayerMark(player,"hantong",qunnum)
			end
		end
	end,
}

LuaHantongMax=sgs.CreateMaxCardsSkill{
	name="#LuaHantongMax",
	extra_func=function(self,target)
		if not target:hasSkill(self:objectName()) then return 0 end
		return 2*target:getMark("hantong")
	end
}

LuaHantongClear=sgs.CreateTriggerSkill{
	name="#LuaHantongClear",
	frequency=sgs.Skill_NotFrequent,
	events={sgs.EventPhaseChanging},
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local change=data:toPhaseChange()
		if change.to~=sgs.Player_NotActive then return end
		local room=player:getRoom()
		local splayer=room:findPlayerBySkillName(self:objectName())
		if splayer:hasFlag("hantong") then
			room:setPlayerFlag(splayer,"-hantong")
			room:setPlayerFlag(splayer,"-hantongjijiang")
			room:setPlayerFlag(splayer,"-hantonghujia")
			room:setPlayerFlag(splayer,"-hantongjiuyuan")
			room:setPlayerFlag(splayer,"-hantongxueyi")
		end
	end,
}
--[[
	技能名：好施
	相关武将：林·鲁肃
	描述：摸牌阶段，你可以额外摸两张牌，若此时你的手牌多于五张，则将一半（向下取整）的手牌交给全场手牌数最少的一名其他角色。
	状态：验证通过
]]--
LuaHaoshiCard = sgs.CreateSkillCard{
	name = "LuaHaoshiCard", 
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				return to_select:getHandcardNum() == sgs.Self:getMark("LuaHaoshi")
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		if #targets == 1 then
			local beggar = targets[1]
			room:moveCardTo(self, beggar, sgs.Player_PlaceHand, false)
			room:setEmotion(beggar, "draw-card")
		end
	end
}
LuaHaoshiVS = sgs.CreateViewAsSkill{
	name = "LuaHaoshi", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			local length = sgs.Self:getHandcardNum() / 2
			return #selected < length
		end
		return false
	end, 
	view_as = function(self, cards)
		local count = sgs.Self:getHandcardNum() / 2
		if #cards == count then
			local card = LuaHaoshiCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@haoshi!"
	end
}
LuaHaoshiGive = sgs.CreateTriggerSkill{
	name = "#LuaHaoshiGive", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if player:hasFlag("LuaHaoshi") then
				room:setPlayerFlag(player, "-LuaHaoshi")
				if player:getHandcardNum() > 5 then	  
					local other_players = room:getOtherPlayers(player)
					local least = 1000
					for _,p in sgs.qlist(other_players) do
						least = math.min(p:getHandcardNum(), least)
					end
					room:setPlayerMark(player, "haoshi", least)
					local used = room:askForUseCard(player, "@@haoshi!", "@haoshi")
					if not used then
						local beggar = nil
						for _,p in sgs.qlist(other_players) do
							if p:getHandcardNum() == least then
								beggar = player
								break
							end
						end
						local n = player:getHandcardNum()/2
						local to_give = player:handCards():mid(0, n)
						local haoshi_card = LuaHaoshiCard:clone()
						for _,card_id in sgs.qlist(to_give) do
							haoshi_card:addSubcard(card_id)
						end
						local targets = sgs.SPlayerList()
						targets:append(beggar)
						haoshi_card:on_use(haoshi_card, room, player, targets)
					end
				end
			end
		end
		return false
	end, 
	priority = -1
}
LuaHaoshi = sgs.CreateTriggerSkill{
	name = "#LuaHaoshi", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DrawNCards}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			room:setPlayerFlag(player, "LuaHaoshi")
			local count = data:toInt() + 2
			data:setValue(count)
		end
	end
}
--[[
	技能名：红颜（锁定技）
	相关武将：风·小乔
	描述：你的黑桃牌均视为红桃牌。
	状态：验证通过
]]--
LuaHongyan = sgs.CreateFilterSkill{
	name = "LuaHongyan",
	view_filter = function(self, to_select)
		return to_select:getSuit() == sgs.Card_Spade
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Heart)
		new_card:setModified(true)
		return new_card
	end
}
--[[
	技能名：弘援
	相关武将：新3V3·诸葛瑾
	描述：摸牌阶段，你可以少摸一张牌，令其他己方角色各摸一张牌。
	状态：尚未验证
]]--
--[[
	技能名：弘援
	相关武将：新3V3·诸葛瑾（身份局）
	描述：摸牌阶段，你可以少摸一张牌，令一至两名其他角色各摸一张牌。
	状态：尚未验证
]]--
--[[
	技能名：后援
	相关武将：智·蒋琬
	描述：出牌阶段，你可以弃置两张手牌，指定一名其他角色摸两张牌，每阶段限一次 
	状态：验证通过
]]--
LuaXHouyuanCard = sgs.CreateSkillCard{
	name = "LuaXHouyuanCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local n = self:subcardsLength()
		effect.to:drawCards(n)
	end
}
LuaXHouyuan = sgs.CreateViewAsSkill{
	name = "LuaXHouyuan", 
	n = 2, 
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return #selected < 2
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 2 then
			local card = LuaXHouyuanCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaXHouyuanCard")
	end
}
--[[
	技能名：虎啸
	相关武将：SP·关银屏
	描述：你于出牌阶段每使用一张【杀】被【闪】抵消，此阶段你可以额外使用一张【杀】。 
	状态：验证失败
]]--
--[[
	技能名：胡笳
	相关武将：倚天·蔡昭姬
	描述：回合结束阶段开始时，你可以进行判定：若为红色，立即获得此牌，如此往复，直到出现黑色为止，连续发动3次后武将翻面 
	状态：验证通过
]]--
LuaXCaizhaojiHujia = sgs.CreateTriggerSkill{
	name = "LuaXCaizhaojiHujia",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart, sgs.FinishJudge},  
	on_trigger = function(self, event, player, data) 
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local times = 0
				local room = player:getRoom()
				while (player:askForSkillInvoke(self:objectName())) do
					player:setFlags("caizhaoji_hujia")
					times = times + 1
					if times == 3 then
						player:turnOver()
					end
					local judge = sgs.JudgeStruct()
					judge.pattern = sgs.QRegExp("(.*):(heart|diamond):(.*)")
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					judge.time_consuming = true
					room:judge(judge)
					if judge:isBad() then
						break
					end
				end
				player:setFlags("-caizhaoji_hujia")
			end
		elseif event == sgs.FinishJudge then
			if player:hasFlag("caizhaoji_hujia") then
				local judge = data:toJudge()
				local card = judge.card
				if card:isRed() then
					player:obtainCard(card)
					return true
				end
			end
		end
		return false
	end
}
--[[
	技能名：护驾（主公技）
	相关武将：标准·曹操、铜雀台·曹操
	描述：当你需要使用或打出一张【闪】时，你可以令其他魏势力角色打出一张【闪】（视为由你使用或打出）。 
	状态：验证失败
]]--
--[[
	技能名：化身
	相关武将：山·左慈
	描述：所有人都展示武将牌后，你随机获得两张未加入游戏的武将牌，称为“化身牌”，选一张置于你面前并声明该武将的一项技能，你获得该技能且同时将性别和势力属性变成与该武将相同直到“化身牌”被替换。在你的每个回合开始时和结束后，你可以替换“化身牌”，然后（无论是否替换）你为当前的“化身牌”声明一项技能（你不可以声明限定技、觉醒技或主公技）。
	状态：验证通过
]]--
function acquireGenerals(zuoci, n)
	local room = zuoci:getRoom()
	local Huashens = {}
	local Hs_String = zuoci:getTag("LuaHuashens"):toString()
	if Hs_String and Hs_String~="" then
		Huashens = Hs_String:split("+")
	end
	for i=1, n, 1 do
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		local banned = {"zuoci", "guzhielai", "dengshizai", "caochong", "jiangboyue", "bgm_xiahoudun"}
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if not table.contains(banned, p:getGeneralName()) then
				table.insert(banned, p:getGeneralName())
			end
			if p:getGeneral2() and not table.contains(banned, p:getGeneral2Name()) then
				table.insert(banned, p:getGeneral2Name())
			end
		end
		for i=1, #generals, 1 do
			if table.contains(banned, generals[i]) then
				table.remove(generals, i)
			end
		end
		if #generals~=0 then
			table.insert(Huashens, generals[math.random(1, #generals)])
		end
	end
	zuoci:setTag("LuaHuashens", sgs.QVariant(table.concat(Huashens, "+")))
end

function askForChooseSkill(zuoci)
	local room = zuoci:getRoom()
	local old_skill = zuoci:getTag("LuaHuashensSkill"):toString()
	if old_skill and zuoci:hasSkill(old_skill) then
		room:detachSkillFromPlayer(zuoci, old_skill)
	end
	zuoci:setTag("LuaHuashensSkill", sgs.QVariant())
	local Hs_String = zuoci:getTag("LuaHuashens"):toString()
	if not Hs_String or Hs_String=="" then return end
	local Huashens = Hs_String:split("+")
	local general_name = room:askForGeneral(zuoci, table.concat(Huashens, "+"))
	local general = sgs.Sanguosha:getGeneral(general_name)
	local kingdom = general:getKingdom()
	if zuoci:getKingdom() ~= kingdom then
		if kingdom == "god" then
			kingdom = room:askForKingdom(zuoci)
		end
		room:setPlayerProperty(zuoci, "kingdom", sgs.QVariant(kingdom))
	end
	if zuoci:getGender() ~= general:getGender() then
		zuoci:setGender(general:getGender())
	end
	local sks = {}
	for _,sk in sgs.qlist(general:getVisibleSkillList()) do
		if not sk:isLordSkill() and sk:getFrequency()~=sgs.Skill_Limited and sk:getFrequency()~=sgs.Skill_Wake then
			table.insert(sks, sk:objectName())
		end
	end
	local choice = room:askForChoice(zuoci, "LuaHuashen", table.concat(sks, "+"))
	zuoci:setTag("LuaHuashensSkill", sgs.QVariant(choice))
	room:acquireSkill(zuoci, choice)
end	

LuaHuashen = sgs.CreateTriggerSkill{
	name = "LuaHuashen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.EventPhaseStart},
	priority = -1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			acquireGenerals(player, 2)
			askForChooseSkill(player)
		else
			if player:getPhase() == sgs.Player_RoundStart or player:getPhase() == sgs.Player_NotActive then
				if room:askForSkillInvoke(player, self:objectName()) then
					askForChooseSkill(player)
				end
			end
		end
	end
}

--[[
	技能名：缓释
	相关武将：新3V3·诸葛瑾
	描述：在一名己方角色的判定牌生效前，你可以打出一张牌代替之。
	状态：尚未完成
]]--
--[[
	技能名：缓释
	相关武将：新3V3·诸葛瑾（身份局）
	描述：在一名角色的判定牌生效前，你可以令其选择是否由你打出一张牌代替之。
	状态：尚未完成
]]--
--[[
	技能名：皇恩
	相关武将：贴纸·刘协
	描述：每当一张锦囊牌指定了不少于两名目标时，你可以令成为该牌目标的至多X名角色各摸一张牌，则该锦囊牌对这些角色无效。（X为你当前体力值） 
]]--
LuaHuangenCard=sgs.CreateSkillCard{
	name="LuaHuangenCard",
	target_fixed=false,
	filter = function(self, targets, to_select, player)
		return to_select:hasFlag("huangen") and #targets<player:getHp()
	end,
	on_use = function(self, room, source, targets)
		for _,p in ipairs(targets) do
			room:setPlayerFlag(p,"huangenremove")
		end
	end,
}

LuaHuangenVS=sgs.CreateViewAsSkill{
	name="LuaHuangen",
	n=0,
	view_as = function(self, cards)
		return LuaHuangenCard:clone()
	end,
	enabled_at_play=function(self, player)
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern=="@@LuaHuangen"
	end,
}

LuaHuangen=sgs.CreateTriggerSkill{
	name="huangen",
	frequency=sgs.Skill_NotFrequent,
	events={sgs.CardUsed},
	view_as_skill=LuaHuangenVS,
	on_trigger=function(self,event,player,data)
		local use=data:toCardUse()
		if not use.card:isKindOf("TrickCard") then return end
		if use.to:length()<2 then return end
		local room=player:getRoom()
		if (use.card:subcardsLength()~=0 or use.card:getEffectiveId()~=-1) then
			room:moveCardTo(use.card,nil,sgs.Player_PlaceTable,true)
		end
		local splayer=room:findPlayerBySkillName(self:objectName())
		if not splayer then return false end
		for _,p in sgs.qlist(use.to) do
			room:setPlayerFlag(p,"huangen")
		end
		local x = 1
		local cardname = use.card:objectName()
		room:setPlayerFlag(splayer,cardname)
		if room:askForUseCard(splayer,"@@LuaHuangen","@LuaHuangen") then
			local newtargets=sgs.SPlayerList()
			for _,p in sgs.qlist(use.to) do
				room:setPlayerFlag(p,"-huangen")
				if p:hasFlag("huangenremove") then
					room:setPlayerFlag(p,"-huangenremove")
					p:drawCards(1)
				else
					newtargets:append(p)
				end
			end
			room:setPlayerFlag(splayer,"-" .. cardname)
			use.to=newtargets
			if use.to:isEmpty() then return true end
			data:setValue(use)
		end
	end,
	can_trigger=function(self,target)
		return true
	end,
}
--[[
	技能名：黄天（主公技）
	相关武将：风·张角
	描述：其他群雄角色可以在他们各自的出牌阶段交给你一张【闪】或【闪电】。每阶段限一次。
	状态：验证通过
]]--
LuaHuangtianCard = sgs.CreateSkillCard{
	name = "LuaHuangtianCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			if to_select:hasLordSkill("LuaHuangtian") then
				if to_select:objectName() ~= sgs.Self:objectName() then
					return not to_select:hasFlag("HuangtianInvoked")
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local zhangjiao = targets[1]
		if zhangjiao:hasLordSkill("LuaHuangtian") then
			room:setPlayerFlag(zhangjiao, "HuangtianInvoked")
			zhangjiao:obtainCard(self)
			local subcards = self:getSubcards()
			for _,card_id in sgs.qlist(subcards) do
				room:setCardFlag(card_id, "visible")
			end
			room:setEmotion(zhangjiao, "good")
			local zhangjiaos = sgs.SPlayerList()
			local players = room:getOtherPlayers(source)
			for _,p in sgs.qlist(players) do
				if p:hasLordSkill("LuaHuangtian") then
					if not p:hasFlag("HuangtianInvoked") then
						zhangjiaos:append(p)
					end
				end
			end
			if zhangjiaos:length() == 0 then
				room:setPlayerFlag(source, "ForbidHuangtian")
			end
		end
	end
}
LuaHuangtianVS = sgs.CreateViewAsSkill{
	name = "LuaHuangtianVS", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:objectName() == "jink" or to_select:objectName() == "lightning"
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaHuangtianCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		if player:getKingdom() == "qun" then
			return not player:hasFlag("ForbidHuangtian")
		end
		return false
	end
}
LuaHuangtian = sgs.CreateTriggerSkill{
	name = "LuaHuangtian$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.GameStart, sgs.EventPhaseChanging},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.GameStart and player:hasLordSkill(self:objectName()) then
			local others = room:getOtherPlayers(player)
			for _,p in sgs.qlist(others) do
				if not p:hasSkill("LuaHuangtianVS") then
					room:attachSkillToPlayer(p, "LuaHuangtianVS")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from == sgs.Player_Play then
				if player:hasFlag("ForbidHuangtian") then
					room:setPlayerFlag(player, "-ForbidHuangtian")
				end
				local players = room:getOtherPlayers(player)
				for _,p in sgs.qlist(players) do
					if p:hasFlag("HuangtianInvoked") then
						room:setPlayerFlag(p, "-HuangtianInvoked")
					end
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
	技能名：挥泪（锁定技）
	相关武将：一将成名·马谡
	描述：当你被其他角色杀死时，该角色弃置其所有的牌。
	状态：验证通过
]]--
LuaHuilei = sgs.CreateTriggerSkill{
	name = "LuaHuilei",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamageStar()
		if damage then
			local killer = damage.from
			if killer then
				killer:throwAllHandCardsAndEquips()
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return target:hasSkill(self:objectName())
		end
		return false
	end
}
--[[
	技能名：魂姿（觉醒技）
	相关武将：山·孙策
	描述：回合开始阶段开始时，若你的体力为1，你须减1点体力上限，并获得技能“英姿”和“英魂”。
	状态：验证通过
]]--
LuaHunzi = sgs.CreateTriggerSkill{
	name = "LuaHunzi",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:gainMark("@waked")
		room:loseMaxHp(player)
		room:acquireSkill(player, "yinghun")
		room:acquireSkill(player, "yingzi")
		room:setPlayerMark(player, "hunzi", 1)
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getMark("hunzi") == 0 then
					if target:getPhase() == sgs.Player_Start then
						return target:getHp() == 1
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：火计
	相关武将：火·诸葛亮
	描述：你可以将一张红色手牌当【火攻】使用。
	状态：验证通过
]]--
LuaHuoji = sgs.CreateViewAsSkill{
	name = "LuaHuoji",
	n = 1,
	view_filter = function(self, selected, to_select)
		if to_select:isRed() then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local fireattack = sgs.Sanguosha:cloneCard("FireAttack", suit, point)
			fireattack:setSkillName(self:objectName())
			fireattack:addSubcard(id)
			return fireattack
		end
	end
}
--[[
	技能名：祸首（锁定技）
	相关武将：林·孟获
	描述：【南蛮入侵】对你无效；当其他角色使用【南蛮入侵】指定目标后，你是该【南蛮入侵】造成伤害的来源。
	状态：验证通过
]]--
LuaHuoshou = sgs.CreateTriggerSkill{
	name = "LuaHuoshou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.ConfirmDamage, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			if player:isAlive() and player:hasSkill(self:objectName()) then
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
		return (target ~= nil) 
	end
}
LuaSavageAssaultAvoid = sgs.CreateTriggerSkill{
	name = "#LuaSavageAssaultAvoid",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			return true
		end
	end
}
--[[
	技能名：祸水（锁定技）
	相关武将：国战·邹氏
	描述：你的回合内，体力值不少于体力上限一半的其他角色所有武将技能无效。 
	状态：尚未完成
]]--