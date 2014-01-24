--[[
	代码速查手册（V区）
	（本区用于收录尚未实现或有争议的技能）
]]--
---------------------------------下面是Fs的0610未验证更改-----------------------------

--[[
Fs在这里多说几句：大家可以对这部分技能尽情测试，要不然的话我一个人边写边测，累也累死了…………
突然发现大家测试的热情不是很高…………
]]
-------------------------------------------------------------------------------
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
	技能名：奇才（锁定技）
	相关武将：标准·黄月英
	描述：你使用锦囊牌无距离限制。你装备区里除坐骑牌外的牌不能被其他角色弃置。
	引用：LuaQicai
	状态：0610貌似无法实现（怀疑后半段被写入源码，因为在本来属于奇才的位置上的只有TargetMod）
]]--

--[[
	技能名：急袭
	相关武将：山·邓艾
	描述：你可以将一张“田”当【顺手牵羊】使用。
	引用：LuaJixi
	状态：0901未完成（不知如何处理源码中关于强制类型转换的部分代码）
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

LuaLihuoVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaLihuo" ,
	filter_pattern = "%slash" ,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and pattern == "slash"
	end ,
	view_as = function(self, card)
		local acard = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
	end ,
}
--触发技没想好怎么变通


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
	状态：1217无法转化（源码修改杀的信息需要设置一个QStringList类型的Property，此类型在LUA只能输出不能输入）
]]--

--[[
	技能名：完杀（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。
	引用：LuaWansha
	状态：0610未做（暂时没有想法）
]]--

--[[
	技能名：纵玄
	相关武将：一将成名2013·虞翻
	描述：当你的牌因弃置而置入弃牌堆前，你可以将其中任意数量的牌以任意顺序依次置于牌堆顶。
]]--

--[[
	技能名：洞察
	相关武将：倚天·贾文和
	描述：回合开始阶段开始时，你可以指定一名其他角色：该角色的所有手牌对你处于可见状态，直到你的本回合结束。其他角色都不知道你对谁发动了洞察技能，包括被洞察的角色本身
	状态：验证失败（0610里面askForCardChosen里面有个bug，虽然洞察成功，但是在没有装备没有延时锦囊的时候还是会自动随机弃手牌，这是源码的bug，我们这些LUAer改不了。）
]]--
--[[
class Dongcha: public PhaseChangeSkill{
public:
	Dongcha():PhaseChangeSkill("dongcha"){

	}

	virtual bool onPhaseChange(ServerPlayer *jiawenhe) const{
		switch(jiawenhe->getPhase()){
		case Player::Start:{
				if(jiawenhe->askForSkillInvoke(objectName())){
					Room *room = jiawenhe->getRoom();
					QList<ServerPlayer *> players = room->getOtherPlayers(jiawenhe);
					ServerPlayer *dongchaee = room->askForPlayerChosen(jiawenhe, players, objectName());
					room->setPlayerFlag(dongchaee, "dongchaee");
					room->setTag("Dongchaee", dongchaee->objectName());
					room->setTag("Dongchaer", jiawenhe->objectName());

					room->showAllCards(dongchaee, jiawenhe);
				}

				break;
			}

		case Player::Finish:{
				Room *room = jiawenhe->getRoom();
				QString dongchaee_name = room->getTag("Dongchaee").toString();
				if(!dongchaee_name.isEmpty()){
					ServerPlayer *dongchaee = room->findChild<ServerPlayer *>(dongchaee_name);
					room->setPlayerFlag(dongchaee, "-dongchaee");

					room->setTag("Dongchaee", QVariant());
					room->setTag("Dongchaer", QVariant());
				}

				break;
			}

		default:
			break;
		}

		return false;
	}
};
]]

--[[
	技能名：争锋（锁定技）
	相关武将：倚天·倚天剑
	描述：当你的装备区没有武器时，你的攻击范围为X，X为你当前体力值。
	状态：0610未做
	备注：争锋涉及更改“杀”以及获得攻击范围的源码，没法做
]]--

--[[
	技能名：危殆（主公技）
	相关武将：智·孙策
	描述：当你需要使用一张【酒】时，所有吴势力角色按行动顺序依次选择是否打出一张黑桃2~9的手牌，视为你使用了一张【酒】，直到有一名角色或没有任何角色决定如此做时为止
	状态：0610未做

	备注：validateInResponse部分已经没有bool引用部分，不知是源码bug还是这么写可以运行。
]]--
--[[

const Card *WeidaiCard::validateInResponse(ServerPlayer *user, bool &continuable) const {
//现在这个版本的validateInResponse已经没有bool引用了啊，这么写是不是运行不了么？这个技能有bug？
	continuable = true;
	Room *room = user->getRoom();
	foreach (ServerPlayer *liege, room->getLieges("wu", user)) {
		QVariant tohelp = QVariant::fromValue((PlayerStar)user);
		QString prompt = QString("@weidai-analeptic:%1").arg(user->objectName());
		const Card *card = room->askForCard(liege, ".|spade|2~9|hand", prompt, tohelp, Card::MethodDiscard, user);
		if(card){
			Analeptic *ana = new Analeptic(card->getSuit(), card->getNumber());
			ana->setSkillName("weidai");
			ana->addSubcard(card);
			return ana;
		}
	}
	room->setPlayerFlag(user, "Global_WeidaiFailed");
	return NULL;
}
]]
-------------------------------------------------------------------------------
---------------------------------[[就这么多了]]---------------------------------
-------------------------------------------------------------------------------
-----------------------------[[下面是验证失败的技能]]---------------------------
-------------------------------------------------------------------------------

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
			if tag and (tag:toPlayer()) then
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
	状态：1217验证失败（双方均无装备时服务器会闪退）
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
	技能名：黄天（主公技）
	相关武将：风·张角
	描述：其他群雄角色可以在他们各自的出牌阶段交给你一张【闪】或【闪电】。每阶段限一次。
	引用：LuaHuangtian、LuaHuangtianv
	状态：1217验证失败（闪退）
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
if not sgs.Sanguosha:getSkill("LuaHuangtianv") then
	local skillList=sgs.SkillList()
	skillList:append(LuaHuangtianv)
	sgs.Sanguosha:addSkills(skillList)
end
-------------------------------------------------------------------------------
---------------------------------[[就这么多了]]---------------------------------
-------------------------------------------------------------------------------
--[[
	技能名：落雁（锁定技）
	相关武将：SP·大乔&小乔
	描述：若你的武将牌上有“星舞牌”，你视为拥有技能“天香”和“流离”。
	状态：1217验证失败
	
	注：此技能与星舞有联系，有联系的地方请使用本手册当中的星舞，并非原版
]]--

LuaLuoyan = sgs.CreateTriggerSkill{
	name = "LuaLuoyan" ,
	events = {sgs.CardsMoveOneTime, sgs.EventAcquireSkill, sgs.EventLoseSkill} ,
	frequency = sgs.Skill_Compulsory ,
	can_trigger = function(self, target)
		return target
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EvnetLoseSkill) and (data:toString() == self:objectName()) then
			room:handleAcquireDetachSkills(player, "-tianxiang|-liuli", true)
		elseif (event == sgs.EventAcquireSkill) and (data:toString() == self:objectName()) then
			if not player:getPile("LuaXingwu"):isEmpty() then
				room:handleAcquireDetachSkills(player, "tianxiang|liuli")
			end
		elseif event == sgs.CardsMoveOneTime and player:isAlive() and player:hasSkill(self:objectName(), true) then
			local move = data:toMoveOneTime()
			if move.to and (move.to:objectName() == player:objectName()) and (move.to_place == sgs.Player_PlaceSpecial) 
					and (move.to_pile_name == "LuaXingwu") then
				if player:getPile("LuaXingwu") == 1 then
					room:handleAcquireDetachSkills(player, "tianxiang|liuli")
				end
			elseif move.from and (move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceSpecial)
					and table.contains(move.from_pile_names, "LuaXingwu") --[[这里是否是这样我不清楚]] then
				if player:getPile("LuaXingwu"):isEmpty() then
					room:handleAcquireDetachSkills(player, "-tianxiang|-liuli", true)
				end
			end
		end
		return false
	end
}
--[[
	技能名：肉林（锁定技）
	相关武将：林·董卓
	当你使用【杀】指定一名女性角色为目标后，该角色需连续使用两张【闪】才能抵消；当你成为女性角色使用【杀】的目标后，你需连续使用两张【闪】才能抵消。
	引用：LuaRoulin
	状态：1227验证失败
]]--
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
LuaRoulin = sgs.CreateTriggerSkill{
	name = "LuaRoulin" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (player:objectName() == use.from:objectName()) then
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			if (use.from and use.from:isAlive() and use.from:hasSkill(self:objectName())) then
				for _, p in sgs.qlist(use.to) do
					if p:isFemale() then
						if jink_table[index] == 1 then
							jink_table[index] = 2
						end
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				use.from:setTag("Jink_" .. use.card:toString(), jink_data)
			elseif use.from:isFemale() then
				for _, p in sgs.qlist(use.to) do
					if p:hasSkill(self:objectName()) then
						if jink_table[index] == 1 then
							jink_table[index] = 2
						end
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				use.from:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:hasSkill(self:objectName()) or target:isFemale())
	end ,
}
--[[
	技能名：巧变
	相关武将：山·张郃
	描述：你可以弃置一张手牌，跳过你的一个阶段（回合开始和回合结束阶段除外），若以此法跳过摸牌阶段，你获得其他至多两名角色各一张手牌；若以此法跳过出牌阶段，你可以将一名角色装备区或判定区里的一张牌移动到另一名角色区域里的相应位置。
	引用：LuaQiaobian
	状态：1217验证失败（移动装备会闪退）
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
				room:moveCardTo(card, from, to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), nil))
			end
			room:removeTag("LuaQiaobianTarget")
		end
	end
}
LuaQiaobianVS = sgs.CreateViewAsSkill{
	name = "LuaQiaobian" ,
	n = 0 ,
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
	events = {sgs.EventPhaseChanging} ,
	view_as_skill = LuaQiaobianVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
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
	技能名：悲歌
	相关武将：山·蔡文姬、SP·蔡文姬
	描述：每当一名角色受到【杀】造成的一次伤害后，你可以弃置一张牌，令其进行一次判定，
	判定结果为：红桃 该角色回复1点体力；方块 该角色摸两张牌；梅花 伤害来源弃置两张牌；黑桃 伤害来源将其武将牌翻面。
	引用：LuaBeige
	状态：0610未做
]]--
LuaBeige = sgs.CreateTriggerSkill{
	name = "LuaBeige" ,
	events = {sgs.Damaged, sgs.FinishJudge} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if (not damage.card) or (not damage.card:isKindOf("Slash")) or (damage.to:isDead()) then
				return false
			end
			local room = player:getRoom()
			local cais = room:findPlayersBySkillName(self:objectName())
			for _, caiwenji in sgs.qlist(cais) do
				if caiwenji:canDiscard(caiwenji, "he") then
					if room:askForCard(caiwenji, "..", "@beige", data, self:objectName()) then
						local judge = sgs.JudgeStruct()
						judge.good = true
						judge.who = player
						judge.reason = self:objectName()
						room:judge(judge)
						local suit = tonumber(judge.pattern)
						if suit == sgs.Card_Heart then
							local recover = sgs.RecoverStruct()
							recover.who = caiwenji
							room:recover(player, recover)
						elseif suit == sgs.Card_Diamond then
							player:drawCards(2)
						elseif suit == sgs.Card_Club then
							if damage.from and damage.from:isAlive() then
								room:askForDiscard(damage.from, "LuaBeige", 2, 2, false, true)
							end
						elseif suit == sgs.Card_Spade then
							if damage.from and damage.from:isAlive() then
								damage.from:turnOver()
							end
						end
					end
				end
			end
		else
			local judge = data:toJudge()
			if judge.reason ~= self:objectName() then return false end
			judge.pattern = tostring(judge.card:getSuit())
			data:setValue(judge)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}

--[[
	技能名：断肠（锁定技）
	相关武将：山·蔡文姬、SP·蔡文姬
	描述：你死亡时，杀死你的角色失去其所有武将技能。
	引用：LuaDuanchang
	状态：0610未做
]]--
LuaDuanchang = sgs.CreateTriggerSkill{
	name = "LuaDuanchang" ,
	events = {sgs.Death} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		if death.damage and death.damage.from then
			local skills = death.damage.from:getVisibleSkillList()
			local detachList = {}
			for _, skill in sgs.qlist(skills) do
				if skill:getLocation() == sgs.Skill_Right and (not skill:isAttachedLordSkill()) then
					detachList:append("-" .. skill:objectName())
				end
			end
			player:getRoom():handleAcquireDetachSkills(death.damage.from, table.concat(detachList, "|"))
			if death.damage.from:isAlive() then
				death.damage.from:gainMark("@duanchang")
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end ,
}

--[[
	技能名：屯田
	相关武将：山·邓艾
	描述：你的回合外，当你失去牌时，你可以进行一次判定，将非红桃结果的判定牌置于你的武将牌上，称为“田”；每有一张“田”，你计算的与其他角色的距离便-1。
	引用：LuaTuntian、LuaTuntianDistance
	状态：1227待验证
]]--
LuaTuntian = sgs.CreateTriggerSkill{
	name = "LuaTuntian" ,
	events = {sgs.CardsMoveOnetime, sgs.FinishJudge} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from:objectName() == player:objectName())
					and (move.from_places:contains(sgs.Player_PlaceHand)
					or move.from_places:contains(sgs.Player_PlaceEquip)) then
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
--[[
	技能名：魂姿（觉醒技）
	相关武将：山·孙策
	描述：回合开始阶段开始时，若你的体力为1，你须减1点体力上限，并获得技能“英姿”和“英魂”。
	引用：LuaHunzi
	状态：1217待验证
]]--
LuaHunzi = sgs.CreateTriggerSkill{
	name = "LuaHunzi" ,
	events = {sgs.EventPhaseStart} ,
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
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.Pindian, sgs.EventPhaseChanging} ,
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
	技能名：固政
	相关武将：山·张昭张纮
	描述：其他角色的弃牌阶段结束时，你可以将该角色于此阶段中弃置的一张牌从弃牌堆返回其手牌，若如此做，你可以获得弃牌堆里其余于此阶段中弃置的牌。
	引用：LuaGuzheng、LuaGuzhengGet
	状态：1227验证失败
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
	技能名：单骑（觉醒技）
	相关武将：SP·关羽
	描述：准备阶段开始时，若你的手牌数大于体力值，且本局游戏主公为曹操，你减1点体力上限，然后获得技能“马术”。
	引用：LuaDanji
	状态：1227验证失败
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
	状态：1217验证失败
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
	技能名：笔伐
	相关武将：SP·陈琳
	描述：结束阶段开始时，你可以将一张手牌移出游戏并选择一名其他角色，该角色的回合开始时，观看该牌，然后选择一项：交给你一张与该牌类型相同的牌并获得该牌，或将该牌置入弃牌堆并失去1点体力。
	引用：LuaBifa
	状态：1217验证失败（也许24K debug眼能够破此代码）
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
	n = 1,
	view_filter = function(self, selected, to_select)
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
	events = {sgs.EventPhaseStart} ,
	view_as_skill = LuaBifaVS ,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player and player:isAlive() and player:hasSkill(self:objectName()) ) and (player:getPhase() == sgs.Player_Finish) and (not player:isKongcheng()) then
			room:askForUseCard(player,"@@LuaBifa", "@bifa-remove", -1, sgs.Card_MethodNone)
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
	end,
}
--[[
	技能名：豹变（锁定技）
	相关武将：SP·夏侯霸
	描述：若你的体力值为3或更少，你视为拥有技能“挑衅”;若你的体力值为2或更少;你视为拥有技能“咆哮”;若你的体力值为1，你视为拥有技能“神速”。
	引用：LuaBaobian
	状态：1227不想验证 = =（使用table全局变量，BaobianSkills Tag的类型由QStringList（在LUA里为table）变为string，然后在技能里面处理字符串（真TM麻烦！））
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
		player:gainMark("@sleep", 1)
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
	技能名：誓仇（主公技、限定技）
	相关武将：☆SP·刘备
	描述：准备阶段开始时，你可以交给一名其他蜀势力角色两张牌。每当你受到伤害时，你将此伤害转移给该角色，然后该角色摸X张牌，直到其第一次进入濒死状态时。（X为伤害点数）
	引用：LuaShichou、LuaShichouDraw
	状态：0901待验证
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
		victim:gainMark("@hate_to")
		room:setPlayerMark(victim, "LuaHateTo_" .. player:objectName(), 1)
		--[[local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName())
		reason.m_playerId = victim:objectName()
		room:obtainCard(victim, self, reason, false)]] --LUA版本obtainCard没有原因
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
	limit_mark = "@hate" ,
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
				player:removeQinggangTag(damage.card)
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
--[[
	技能名：军威
	相关武将：☆SP·甘宁
	描述：结束阶段开始时，你可以将三张“锦”置入弃牌堆并选择一名角色，令该角色选择一项：1.展示一张【闪】并将该【闪】交给由你选择的一名角色；2.失去1点体力，然后你将其装备区的一张牌移出游戏，该角色的下个回合结束后，将这张装备牌移回其装备区。
	引用：LuaJunwei、LuaJunweiGot
	状态：1217验证失败
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
	技能名：皇恩
	相关武将：贴纸·刘协
	描述：每当一张锦囊牌指定了不少于两名目标时，你可以令成为该牌目标的至多X名角色各摸一张牌，则该锦囊牌对这些角色无效。（X为你当前体力值）
	引用：LuaHuangen
	状态：1217验证失败
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
	n = 0,
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
	技能名：突骑（锁定技）
	相关武将：贴纸·公孙瓒
	描述：准备阶段开始时，若你的武将牌上有“扈”，你将所有“扈”置入弃牌堆：若X小于或等于2，你摸一张牌。本回合你与其他角色的距离-X。（X为准备阶段开始时置于弃牌堆的“扈”的数量）
	引用：LuaTuqi、LuaTuqiDistance
	状态：1217验证失败
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
--[[
	技能名：谋溃
	相关武将：铜雀台·穆顺、SP·伏完
	描述：当你使用【杀】指定一名角色为目标后，你可以选择一项：摸一张牌，或弃置其一张牌。若如此做，此【杀】被【闪】抵消时，该角色弃置你的一张牌。
	引用：LuaMoukui
	状态：1217验证失败
]]--
LuaMoukui = sgs.CreateTriggerSkill{
	name = "LuaMoukui" ,
	events = {sgs.TargetConfirmed, sgs.SlashMissed, sgs.CardFinished} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if ((not use.from) or (use.from:objectName() ~= player:objectName()))
					or (not (player and player:isAlive() and player:hasSkill(self:objectName())))
					or (not use.card:isKindOf("Slash")) then return false end
			for _, p in sgs.qlist(use.to) do
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player:askForSkillInvoke(self:objectName(), _data) then
					local choice
					if not player:canDiscard(p, "he") then
						choice = "draw"
					else
						choice = room:askForChoice(player, self:objectName(), "draw+discard", _data)
					end
					if choice == "draw" then
						player:drawCards(1)
					else
						local disc = room:askForCardChosen(player, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)
						room:throwCard(disc, p, player)
					end
					room:addPlayerMark(p, self:objectName() .. use.card:toString())
				end
			end
		elseif event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			if effect.to:isDead() or (effect.to:getMark(self:objectName() .. effect.slash:toString()) <= 0) then return false end
			if (not effect.from:isAlive()) or (not effect.to:isAlive()) or effect.to:canDiscard(effect.from, "he") then return false end
			local disc = room:askForCardChosen(effect.to, effect.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
			room:throwCard(disc, effect.from, effect.to)
			room:removePlayerMark(effect.to, self:objectName() .. effect.slash:toString())
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:setPlayerMark(p, self:objectName() .. use.card:toString(), 0)
			end
		end
	end ,
	can_trigger = function(self, target)
		return target
	end ,
}

--[[
	技能名：天命
	相关武将：铜雀台·汉献帝、SP·刘协
	描述：当你成为【杀】的目标时，你可以弃置两张牌（不足则全弃，无牌则不弃），然后摸两张牌；若此时全场体力值最多的角色仅有一名（且不是你），该角色也可如此做
	引用：LuaTianming
	状态：1217验证失败
]]--
LuaTianming = sgs.CreateTriggerSkill{
	name = "LuaTianming" ,
	events = {sgs.TargetConfirming} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.card and use.card:isKindOf("Slash") then
			if room:askForSkillInvoke(player, self:objectName()) then
				room:askForDiscard(player, self:objectName(), 2, 2, false, true)
				player:drawCards(2)
				local _max = -1000
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getHp() > _max then
						m_max = p:getHp()
					end
				end
				if (player:getHp() == _max) then return false end
				local maxs = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getHp() == _max then
						maxs:append(p)
					end
					if maxs:length() > 1 then
						return false
					end
				end
				local mosthp = maxs:first()
				if room:askForSkillInvoke(mosthp, self:objectName()) then
					room:askForDiscard(mosthp, self:objectName(), 2, 2, false, true)
					mosthp:drawCards(2)
				end
			end
		end
		return false
	end
}

--[[
	技能名：密诏
	相关武将：铜雀台·汉献帝、SP·刘协
	描述：出牌阶段限一次，你可以将所有手牌（至少一张）交给一名其他角色：若如此做，你令该角色与另一名由你指定的有手牌的角色拼点：若一名角色赢，视为该角色对没赢的角色使用一张【杀】。
	引用：LuaMizhao、LuaMizhaoNDL
	状态：1217验证失败（isSuccess无接口）
]]--
LuaMizhaoCard = sgs.CreateSkillCard{
	name = "LuaMizhaoCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		effect.to:obtainCard(effect.card, false)
		if effect.to:isKongcheng() then return end
		local room = effect.from:getRoom()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(effect.to)) do
			if not p:isKongcheng() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(effect.from, targets, "LuaMizhao", "@mizhao-pindian:" .. effect.to:objectName())
			target:setFlags("LuaMizhaoPindianTarget")
			effect.to:pindian(target, "LuaMizhao", nil)
			target:setFlags("-LuaMizhaoPindianTarget")
		end
	end
}
LuaMizhaoVS = sgs.CreateViewAsSkill{
	name = "LuaMizhao" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards < sgs.Self:getHandcardNum() then return nil end
		local card = LuaMizhaoCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and (not player:hasUsed("#LuaMizhaoCard"))
	end
}
LuaMizhao = sgs.CreateTriggerSkill{
	name = "LuaMizhao" ,
	events = {sgs.Pindian} ,
	view_as_skill = LuaMizhaoVS ,
	on_trigger = function(self, event, player, data)
		local pindian = data:toPindian()
		if (pindian.reason ~= self:objectName()) or (pindian.from_number == pindian.to_number) then return false end
		local winner
		local loser
		if pindian:isSuccess() then
			winner = pindian.from
			loser = pindian.to
		else
			winner = pindian.to
			loser = pindian.from
		end
		if winner:canSlash(loser, nil, false) then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("_LuaMizhao")
			room:useCard(sgs.CardUseStruct(slash, winner, loser), false)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
LuaMizhaoNDL = sgs.CreateTargetModSkill{
	name = "#LuaMizhao-slash-ndl" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, from, card)
		if card:isKindOf("Slash") and (card:getSkillName() == "LuaMizhao") then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：焚心（限定技）
	相关武将：铜雀台·灵雎、SP·灵雎
	描述：当你杀死一名非主公角色时，在其翻开身份牌之前，你可以与该角色交换身份牌。（你的身份为主公时不能发动此技能。）
	引用：LuaFenxin、LuaBurnheart1
	状态：1217验证通过
]]--
isNormalGameMode = function(mode)
	return (string.sub(mode, string.len(mode)) == "p")
		or (string.sub(mode, string.len(mode) - 1) == "pd")
		or (string.sub(mode, string.len(mode) - 1) == "pz")
end
LuaFenxin = sgs.CreateTriggerSkill{
	name = "LuaFenxin" ,
	events == {sgs.BeforeGameOverJudge} ,
	frequency = sgs.Skill_Limited ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not isNormalGameMode(room:getMode()) then return false end
		local death = data:toDeath()
		if not death.damage then return false end
		local killer = death.damage:from()
		if (not killer) or killer:isLord() or player:isLord() or (player:getHp() > 0) then return false end
		if (not (killer and killer:isAlive() and killer:hasSkill(self:objectName()))) or (killer:getMark("@burnheart") == 0) then return false end
		player:setFlags("LuaFenxinTarget")
		local _data = sgs.QVariant()
		_data:setValue(player)
		local invoke = room:askForSkillInvoke(killer, self:objectName(), _data)
		player:setFlags("-LuaFenxinTarget")
		if invoke then
			room:removePlayerMark(killer, "@burnheart")
			local role1 = killer:getRole()
			killer:setRole(player:getRole())
			room:notifyProperty(killer, killer, "role", player:getRole())
			room:setPlayerProperty(player, "role", role1)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
LuaBurnheart1 = sgs.CreateTriggerSkill{
	name = "#@burnheart-Lua-1" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		player:gainMark("@burnheart", 1)
	end
}
--[[
	技能名：密信
	相关武将：铜雀台·伏皇后
	描述：出牌阶段限一次，你可以将一张手牌交给一名其他角色，该角色须对你选择的另一名角色使用一张【杀】（无距离限制），否则你选择的角色观看其手牌并获得其中任意一张。
	引用：LuaMixin
	状态：1217验证失败
]]--
LuaMixinCard = sgs.CreateSkillCard{
	name = "LuaMixinCard" ,
	will_throw = false,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self)
	end ,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		target:obtainCard(self, fasle)
		local others = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(target)) do
			if target:canSlash(p, nil, false) then
				others:append(p)
			end
		end
		if others:isEmpty() then return end
		local target2 = room:askForPlayerChosen(source, others, "LuaMixin")
		if room:askForUseSlashTo(target, target2, "#mixin", false) then
			-- Do Nothing
		else
			local card_ids = target:handCards()
			room:fillAG(cards, target2)
			local cdid = room:askForAG(target2, card_dis, false, self:objectName())
			room:obtainCard(target2, cdid, false)
			room:clearAG(target2)
		end
	end
}
LuaMixin = sgs.CreateViewAsSkill{
	name = "LuaMixin" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return (#selected == 0) and (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards ~= 0 then return nil end
		local card = LuaMixinCard:clone()
		card:addSubcard(cards[1])
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaMixinCard")
	end
}
--[[
	技能名：断指
	相关武将：铜雀台·吉本
	描述：当你成为其他角色使用的牌的目标后，你可以弃置其至多两张牌（也可以不弃置），然后失去1点体力。
	引用：LuaDuanzhi、LuaDuanzhiFakeMove
	状态：1217验证失败
]]--
LuaDuanzhi = sgs.CreateTriggerSkill{
	name = "LuaDuanzhi" ,
	evnets = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if (use.card:getTypeId() == sgs.Card_TypeSkill) or (use.from and use.from:objectName() == player:objectName()) or (not use.to:contains(player)) then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
			local room = player:getRoom()
			room:setPlayerFlag(player, "LuaDuanzhi_InTempMoving")
			local target = use.from
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local card_ids = sgs.IntList()
			local original_places = sgs.IntList()
			for i = 0, 1, 1 do
				if not player:canDiscard(target, "he") then break end
				if room:askForChoice(player, self:objectName(), "discard+cancel") == "cancel" then break end
				card_ids:append(room:askForCardChosen(player, target, "he", self:objectName()))
				original_places:append(room:getCardPlace(card_ids:at(i)))
				dummy:addSubCard(card_ids:at(i))
				target:addToPile("#LuaDuanzhi", card_ids:at(i), false)
			end
			if dummy:subcardsLength() > 0 then
				for i = 0, dummy:subcardsLength() - 1, 1 do
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), target, original_places:at(i), false)
				end
			end
			room:setPlayerFlag(player, "-LuaDuanzhi_InTempMoving")
			if dummy:subcardsLength() > 0 then
				room:throwCard(dummy, target, player)
			end
			room:loseHp(player)
		end
		return false
	end ,
}
LuaDuanzhiFakeMove = sgs.CreateTriggerSkill{
	name = "LuaDuanzhi-fake-move" ,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime} ,
	priority = 10 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("LuaDuanzhi_InTempMoving") then return true end
		end
		return false
	end
}
--[[
	技能名：礼让
	相关武将：国战·孔融
	描述：当你的牌因弃置而置入弃牌堆时，你可以将其中任意数量的牌以任意分配方式交给任意数量的其他角色。
	引用：LuaLirang
	状态：1217验证失败
]]--
LuaLirang = sgs.CreateTriggerSkill{
	name = "LuaLirang" ,
	events = {sgs.BeforeCardsMove} ,
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		if (not move.from) or (move.from:objectName() ~= player:objectName()) then return false end
		if (move.to_place == sgs.Player_DiscardPile) and
				(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
			local i = 0
			local lirang_card = sgs.IntList()
			for _, card_id in sgs.qlist(move.card_ids) do
				local owner = player:getRoom():getCardOwner(card_id)
				if (owner and (owner:objectName() == move.from:objectName())) and
						((move.from_places[i] == sgs.Player_PlaceHand) or (move.from_places[i] == sgs.Player_PlaceEquip)) then
					lirang_card:append(card_id)
				end
				i = i + 1
			end
			if lirang_card:isEmpty() then return false end
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			local original_lirang = lirang_card
			while player:getRoom():askForYiji(player, lirang_card, self:objectName(), false, true, true, -1, sgs.SPlayerList(), move.reason) do
				if player:isDead() then return false end
			end
			local ids = move.card_ids
			i = 0
			for _, card_id in sgs.qlist(ids) do
				if original_lirang:contains(card_id) and (not lirang_card:contains(card_id)) then
					move.card_ids:removeOne(card_id)
					move.from_places:removeAt(i)
				end
				i = i + 1
			end
			data:setValue(move)
		end
		return false
	end
}
--[[
	技能名：双刃
	相关武将：国战·纪灵
	描述：出牌阶段开始时，你可以与一名其他角色拼点：若你赢，视为你一名其他角色使用一张无距离限制的普通【杀】（此【杀】不计入出牌阶段使用次数的限制）；若你没赢，你结束出牌阶段。
	引用：LuaShuangren、LuaShuangrenNDL
	状态：1217验证失败（闪退）
]]--
LuaShuangrenCard = sgs.CreateSkillCard{
	name = "LuaShuangrenCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local success = effect.from:pindian(effect.to, "LuaShuangren", nil)
		if success then
			local targets = sgs.SPlayerList()
			for _, target in sgs.qlist(room:getAlivePlayers()) do
				if effect.from:canSlash(target, nil, false) then
					targets:append(target)
				end
			end
			if targets:isEmpty() then return end
			local target = room:askForPlayerChosen(effect.from, targets, "LuaShuangren", "@dummy-slash")
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("_LuaShuangren")
			room:useCard(sgs.CardUseStruct(slash, effect.from, target), false)
		else
			room:setPlayerFlag(effect.from, "LuaShuangrenSkipPlay")
		end
	end
}
LuaShuangrenVS = sgs.CreateViewAsSkill(){
	name = "LuaShuangren" ,
	n = 0 ,
	view_as = function()
		return LuaShuangrenCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaShuangren"
	end
}
LuaShuangren = sgs.CreateTriggerSkill{
	name = "LuaShuangren" ,
	view_as_skill = LuaShuangrenVS ,
	on_trigger = function(self, event, player, data)
		if (player:getPhase() == sgs.Player_Play) and (not player:isKongcheng()) then
			local room = player:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _, _player in sgs.qlist(other_players) do
				if not _player:isKongcheng() then
					return true
					break
				end
			end
			if can_invoke then
				room:askForUseCard(player, "@@LuaShuangren", "@shuangren-card")
			end
			if player:hasFlag("LuaShuangrenSkipPlay") then
				return true
			end
		end
		return false
	end
}
LuaShuangrenNDL = sgs.CreateTargetModSkill{
	name = "#LuaShuangren-slash-ndl" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("LuaShuangren") and (card:getSkillName() == "LuaShuangren") then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：陷嗣
	相关武将：一将成名2013·刘封
	描述：准备阶段开始时，你可以将一至两名角色的各一张牌置于你的武将牌上，称为“逆”。其他角色可以将两张“逆”置入弃牌堆，视为对你使用一张【杀】。
	引用：LuaXiansi、LuaXiansiAttach、LuaXiansiSlash（技能暗将
	状态：暂时搁置
]]--
LuaXiansiCard = sgs.CreateSkillCard{
	name = "LuaXiansi" ,
	filter = function(self, targets, to_select)
		return (#targets < 2) and (not to_select:isNude())
	end ,
	on_effect = function(self, effect)
		if effect.to:isNude() then return end
		local id = effect.from:getRoom():askForPlayerChosen(effect.from, effect.to, "he", "LuaXiansi")
		effect.from:addToPile("counter", id)
	end ,
}
LuaXiansiVS = sgs.CreateViewAsSkill{
	name = "LuaXiansi" ,
	n = 0 ,
	view_as = function()
		return LuaXiansiCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern = "@@LuaXiansi"
	end
}
LuaXiansi = sgs.CreateTriggerSkill{
	name = "LuaXiansi" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = LuaXiansiVS ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			player:getRoom():askForUseCard(player, "@@LuaXiansi", "@xiansi-card")
		end
		return false
	end
}
LuaXiansiAttach = sgs.CreateTriggerSkill{
	name = "#LuaXiansi-attach" ,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.GameStart) and (player and player:isAlive() and player:hasSkill(self:objectName())))
				or ((event == sgs.EventAcquireSkill) and (data:toString() == "LuaXiansi")) then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:hasSkill("LuaXiansi_slash") then
					room:attachSkillToPlayer("LuaXiansi_slash")
				end
			end
		elseif (event == sgs.EventLoseSkill) and (data:toString() == "LuaXiansi") then
			player:clearOnePrivatePile("counter")
			for _ , p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("LuaXiansi_slash") then
					room:detachSkillFromPlayer(p, "LuaXiansi_slash", true)
				end
			end
		end
		return false
	end
	can_trigger = function(self, target)
		return target
	end
}
LuaXiansiSlashCard = sgs.CreateSkillCard{
	name = "LuaXiansiSlashCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		local liufeng = room:findPlayerBySkillName("LuaXiansi")
		if (not liufeng) or (liufeng:getPile("counter"):length() < 2) then return end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if liufeng:getPile("counter"):length() == 2 then
			dummy:addSubcard(liufeng:getPile("counter"):first())
			dummy:addSubcard(liufeng:getPile("counter"):last())
		else
			local ids = liufeng:getPile("counter")
			for i = 0, 1, 1 do
				room:fillAG(ids, source)
				local id = room:askForAG(source, ids, false, "LuaXiansi")
				dummy:addSubcard(id)
				ids:removeOne(id)
				room:clearAG(source)
			end
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, "LuaXiansi", nil)
		room:throwCard(dummy, reason, nil)
		if source:canSlash(liufeng, nil, false) then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:setSkillName("_LuaXiansi")
			room:useCard(sgs.CardUseStruct(slash, source, liufeng))
		end
	end
}
canSlashLiufeng = function(self, player)
	local liufeng = nil
	for _, p in sgs.qlist(player:getSiblings()) do
		if p:isAlive() and p:hasSkill("LuaXiansi") and (p:getPile("counter"):length() > 1) then
			liufeng = p
			break
		end
	end
	if not liufeng then return false end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	return slash:targetFilter(sgs.PlayerList(), liufeng, player)
end
LuaXiansiSlash = sgs.CreateViewAsSkill{
	name = "LuaXiansi_slash" ,
	n = 0 ,
	view_as = function()
		return LuaXiansiSlashCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and canSlashLiufeng(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash") and (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
				and canSlashLiufeng(player)
	end ,
}
--[[
	技能名：惴恐
	相关武将：一将成名2013·伏皇后
	描述： 一名其他角色的回合开始时，若你已受伤，你可以与其拼点：若你赢，该角色跳过出牌阶段；若你没赢，该角色与你距离为1，直到回合结束。
	引用：LuaZhuikong、LuaZhuikongClear
	状态：1217验证失败（闪退）
]]--
LuaZhuikong = sgs.CreateTriggerSkill{
	name = "LuaZhuikong" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if (player:getPhase() ~= sgs.Player_RoundStart) or player:isKongcheng() then return false end
		local skip = false
		local room = player:getRoom()
		for _, fuhuanghou in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if (player:objectName() ~= fuhuanghou:objectName()) and fuhuanghou:isWounded and (not fuhuanghou:isKongcheng()) then
				if room:askForSkillInvoke(fuhuanghou, self:objectName()) then
					if fuhuanghou:pindian(player, self:objectName(), nil) then
						if not skip then
							player:skip(sgs.Player_Play)
							skip = true
						end
					else
						room:setFixedDistance(player, fuhuanghou, 1)
						local zhuikonglist = player:getTag(self:objectName()):toString():split("+")
						table.insert(zhuikonglist, fuhuanghou:objectName())
						player:setTag(self:objectName(), table.concat(zhuikonglist, "+"))
					end
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
LuaZhuikongClear = sgs.CreateTriggerSkill{
	name = "#LuaZhuikongClear" ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		local zhuikonglist = player:getTag("LuaZhuikong"):toString():split("+")
		if #zhuikonglist == 0 then return false end
		for _, p in ipairs(zhuikonglist) do
			local fuhuanghou = nil
			for _, n in sgs.qlist(room:getAlivePlayers()) do
				if p == n:objectName() then
					fuhuanghou = n
					break
				end
			end
			room:setFixedDistance(player, fuhuanghou, -1)
		end
		player:removeTag("LuaZhuikong")
		return false
	end
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：眩惑
	相关武将：怀旧·法正
	描述：出牌阶段，你可以将一张红桃手牌交给一名其他角色，然后你获得该角色的一张牌并交给除该角色外的其他角色。每阶段限一次。
	引用：LuaNosXuanhuo
	状态：1217验证失败
]]--
LuaNosXuanhuoCard = sgs.CreateSkillCard{
	name = "LuaNosXuanhuoCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		effect.to:obtainCard(self)
		local room = effect.from:getRoom()
		local card_id = room:askForCardChosen(effect.from, effect.to, "he", "LuaNosXuanhuo")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName())
		room:obtainCard(effect.from, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
		local targets = room:getOtherPlayers(effect.to)
		local target = room:askForPlayerChosen(effect.from, targets, "LuaNosXuanhuo", "@nosxuanhuo-give:" .. effect.to:objectName())
		if target:objectName() ~= effect.from:objectName() then
			local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, effect.from:objectName())
			reason2.m_playerId = target:objectName()
			room:obtainCard(target, sgs.Sanguosha:getCard(card_id), reason2, false)
		end
	end
}
LuaNosXuanhuo = sgs.CreateViewAsSkill{
	name = "LuaNosXuanhuo" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return (#selected == 0) and (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Heart)
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local xuanhuoCard = LuaNosXuanhuoCard:clone()
		xuanhuoCard:addSubcard(cards[1])
		return xuanhuoCard
	end ,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and (not player:hasUsed("#LuaNosXuanhuoCard"))
	end
}

--[[
	技能名：旋风
	相关武将：怀旧·凌统
	描述：当你失去一次装备区里的牌时，你可以选择一项：1. 视为对一名其他角色使用一张【杀】；你以此法使用【杀】时无距离限制且不计入出牌阶段内的使用次数限制。2. 对距离为1的一名角色造成1点伤害。
	引用：LuaNosXuanfeng、LuaNosXuanfengNDL
	状态：1217验证失败（choicelist明显写错了以及各种不和谐）
]]--
LuaNosXuanfeng = sgs.CreateTriggerSkill{
	name = "LuaNosXuanfeng" ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and (move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceEquip) then
			local choicelist = "nothing"
			local targets1 = sgs.SPlayerList()
			for _, target in sgs.qlist(room:getAlivePlayers()) do
				if player:canSlash(target, nil, false) then
					targets1:append(target)
				end
				local slashx = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if (not targets1:isEmpty()) and (not player:isCardLimited(slashx, sgs.Card_MethodUse)) then
					choicelist = choicelist .. "+slash"
				end
				local targets2 = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:distanceTo(p) <= 1 then
						targets2:append(p)
					end
				end
				if not targets2:isEmpty() then
					choicelist = choicelist .. "+damage"
				end
				local choice = room:askForChoice(player, self:objectName(), choicelist)
				if choice == "slash" then
					local target = room:askForPlayerChosen(player, targets1, "nosxuanfeng_slash", "dummy-slash")
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName(self:objectName())
					room:useCard(sgs.CardUseStruct(slash, player, target), false)
				elseif choice == "damage" then
					local target = room:askForPlayerChosen(player, targets2, "nosxuanfeng_damage", "@nosxuanfeng-damage")
					room:damage(sgs.DamageStruct("LuaNosXuanfeng", player, target))
				end
			end
		end
		return false
	end
}
LuaNosXuanfengNDL = sgs.CreateTargetModSkill{
	name = "#LuaNosXuanfeng-slash-ndl" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("LuaNosXuanfeng") and (card:getSkillName() == "LuaNosXuanfeng") then
			return 1000
		else
			return 0
		end
	end
}
--[[
	技能名：父魂
	相关武将：怀旧-一将2·关&张-旧
	描述：摸牌阶段开始时，你可以放弃摸牌，改为从牌堆顶亮出两张牌并获得之，若亮出的牌颜色不同，你获得技能“武圣”、“咆哮”，直到回合结束。
	引用：LuaNosFuhun
	状态：1217验证失败（getColor无接口，这个好处理，先把其他的坑填了再说）
]]--
LuaNosFuhun = sgs.CreateTriggerSkill{
	name = "LuaNosFuhun" ,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Draw) and (player and player:isAlive() and player:hasSkill(self:objectName())) then
			if player:askForSkillInvoke(self:objectName()) then
				local card1 = room:drawCard()
				local card2 = room:drawCard()
				local diff = (sgs.Sanguosha:getCard(card1):getColor() ~= sgs.Sanguosha:getCard(card2):getColor())
				local move = sgs.CardsMoveStruct()
				move.card_ids:append(card1)
				move.card_ids:append(card2)
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), "LuaNosFuhun", nil)
				move.to_place = sgs.Player_PlaceTable
				room:moveCardsAtomic(move, true)
				local move2 = move
				move2.to_place = sgs.Player_PlaceHand
				move2.to = player
				move2.reason.m_reason = sgs.CardMoveReason_S_REASON_DRAW
				room:moveCardsAtomic(move2, true)
				if diff then
					room:handleAcquireDetachSkills(player, "wusheng|paoxiao")
					player:setFlags(self:objectName())
				end
				return true
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) and player:hasFlag(self:objectName()) then
				room:handleAcquierDetachSkills(player, "-wusheng|-paoxiao")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：解烦
	相关武将：怀旧·韩当
	描述：你的回合外，当一名角色处于濒死状态时，你可以对当前正进行回合的角色使用一张【杀】（无距离限制），此【杀】造成伤害时，你防止此伤害，视为对该濒死角色使用一张【桃】。
	引用：LuaNosJiefan
	状态：1217验证失败（客户端闪退）
]]--
LuaNosJiefanCard = sgs.CreateSkillCard{
	name = "LuaNosJiefanCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		local current = room:getCurrent()
		if (not current) or current:isDead() or (current:getPhase() == sgs.Player_NotActive) then return end
		local who = room:getCurrentDyingPlayer()
		if not who then return end
		source:setFlags("LuaNosJiefanUsed")
		local _data = sgs.QVariant()
		_data:setValue(who)
		room:setTag("LuaNosJiefanTarget", _data)
		local use_slash = room:askForUseSlashTo(souce, current, "jiefan-slash:" .. current:objectName(), false)
		if not use_slash then
			source:setFlags("-LuaNosJiefanUsed")
			room:removeTag("LuaNosJiefanTarget")
			room:setPlayerFlag(source, "Global_LuaNosJiefanFailed")
		end
	end
}
LuaNosJiefanVS = sgs.CreateViewAsSkill{
	name = "LuaNosJiefan" ,
	n = 0 ,
	view_as = function()
		return LuaNosJiefanCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		if (not string.find(pattern, "peach")) then return false end
		if (player:hasFlag("Global_NosJiefanFailed")) then return false end
		for _, p in sgs.qlist(player:getSiblings()) do
			if p:isAlive() and (p:getPhase() ~= sgs.Player_NotActive) then
				return true
			end
		end
		return false
	end
}
LuaNosJiefan = sgs.CreateTriggerSkill{
	name = "LuaNosJiefan" ,
	events = {sgs.DamageCaused, sgs.CardFinished, sgs.PreCardUsed} ,
	view_as_skill = LuaNosJiefanVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			if not player:hasFlag("LuaNosJiefanUsed") then
				return false
			end
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				player:setFlags("-LuaNosJiefanUsed")
				room:setCardFlag(use.card, "LuaNosJiefan-slash")
			end
		elseif event == sgs.DamageCaused then
			local current = room:getCurrent()
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("LuaNosJiefan-slash") then
				local target = room:getTag("LuaNosJiefanTarget"):toPlayer()
				if target and (target:getHp() > 0) then
					-- Do Nothing
				elseif target and target:isDead() then
					-- Do Nothing too
				elseif player:hasFlag("Global_PreventPeach") then
					-- Do Nothing too too
				else
					local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
					peach:setSkillName("_LuaJiefan")
					room:setCardFlag(damage.card, "LuaNosJiefan_success")
					room:useCard(sgs.CardUseStruct(peach, player, target))
				end
				return true
			end
			return false
		elseif (event == sgs.CardFinished) and (room:getTag("LuaNosJiefanTarget")) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:hasFlag("LuaNosJiefan-slash") then
				if not use.card:hasFlag("LuaNosJiefan_success") then
					room:setPlayerFlag(player, "Global_NosJiefanFailed")
				end
				room:removeTag("LuaNosJiefanTarget")
			end
		end
		return false
	end ,
}
--[[
	技能名：连理
	相关武将：倚天·夏侯涓
	描述：回合开始阶段开始时，你可以选择一名男性角色，你和其进入连理状态直到你的下回合开始：该角色可以帮你出闪，你可以帮其出杀
	引用：LuaLianli、LuaLianliSlashAsk、LuaLianliStart、LuaLianliJink、LuaLianliClear、LuaLianliSlash（技能暗将）
	状态：1217验证失败（闪退）
]]--
LuaLianliSlashCard = sgs.CreateSkillCard{
	name = "LuaLianliSlashCard" ,
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local targetlist = sgs.PlayerList()
		for _, t in ipairs(targets) do
			targetlist:append(t)
		end
		return slash:targetFilter(targetlist, to_select, sgs.Self)
	end ,
	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local zhangfei = cardUse.from
		local room = zhangfei:getRoom()
		local xiahoujuan = room:findPlayersBySkillName("LuaLianli")
		if xiahoujuan then
			local slash = room:askForCard(xiahoujuan, "slash", "@lianli-slash", sgs.QVariant, sgs.Card_MethodResponse)
			if slash then return slash end
		end
		room:setPlayerFlag(zhangfei, "Global_LuaLianliFailed")
		return nil
	end
}
LuaLianliSlash = sgs.CreateViewAsSkill{
	name = "LuaLianli-slash" ,
	n = 0 ,
	view_as = function()
		return LuaLianliSlashCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return (player:getMark("@tied") > 0) and sgs.Slash:isAvailable(player) and (not player:hasFlag("Global_LuaLianliFailed"))
	end
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash")
				and (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
				and (not player:hasFlag("Global_LuaLianliFailed"))
	end
}
LuaLianliSlashAsk = sgs.CreateTriggerSkill{
	name = "#LuaLianli-slash" ,
	events = {sgs.CardAsked} ,
	on_trigger = function(self, event, player, data)
		local pattern = data:toStringList()[1]
		if (pattern ~= "slash") then return false end
		if not player:askForSkillInvoke("LuaLianli-slash", data) then return false end
		local xiahoujuan = room:findPlayerBySkillName("LuaLianli")
		if xiahoujuan then
			local slash = room:askForCard(xiahoujuan, "slash", "@lianli-slash", data, sgs.Card_MethodResponse)
			if slash then
				room:provide(slash)
				return true
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getMark("@tied") > 0) and (not target:hasSkill("LuaLianli"))
	end
}
LuaLianliStart = sgs.CreateTriggerSkill{
	name = "#LuaLianli-start" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local players = room:getOtherPlayers(player)
		for _, _player in sgs.qlist(players) do
			if _player:isMale() then
				room:attachSkillToPlayer(_player, "LuaLianli-slash")
			end
		end
		return false
	end
}
LuaLianliJink = sgs.CreateTriggerSkill{
	name = "#LuaLianli-jink" ,
	events = {sgs.CardAsked} ,
	on_trigger = function(self, event, player, data)
		local pattern = data:toStringList()[1]
		if pattern ~= "jink" then return false end
		if not player:askForSkillInvoke("LuaLianli", data) then return false end
		local players = room:getOtherPlayers(player)
		for _, _player in sgs.qlist(players) do
			if _player:getMark("@tied") > 0 then
				local zhangfei = _player
				local jink = room:askForCard(zhangfei, "jink", "@lianli-jink", data, sgs.Card_MethodResponse)
				if jink then
					room:provide(jink)
					return true
				end
				break
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and (target:getMark("@tied") > 0)
	end
}
LuaLianliCard = sgs.CreateSkillCard{
	name = "LuaLianliCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:isMale()
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if effect.from:getMark("@tied") == 0 then
			effect.from:gainMark("@tied")
		end
		if effect.to:getMark("@tied") == 0 then
			local players = room:getOtherPlayers(effect.from)
			for _, player in sgs.qlist(players) do
				if player:getMark("@tied") > 0 then
					player:loseMark("@tied")
					break
				end
			end
			effect.to:gainMark("@tied")
		end
	end
}
LuaLianliVS = sgs.CreateViewAsSkill{
	name = "LuaLianli" ,
	n = 0 ,
	view_as = function()
		return LuaLianliCard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaLianli"
	end
}
LuaLianli = sgs.CreateTriggerSkill{
	name = "LuaLianli" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = LuaLianliVS ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local used = room:askForUseCard(player, "@@LuaLianli", "@lianli-card")
			if used then
				local spouse = nil
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (p:getMark("@tied") > 0) and (p:objectName() ~= player:objectName()) then
						spouse = p
						break
					end
				end
				if spouse then
					local kingdom = spouse:getKingdom()
					if player:getKingdom ~= kingdom then
						room:setPlayerProperty(player, "kingdom", sgs.QVariant(kingdom))
					end
				end
			else
				if (player:getKingdom() ~= "wei") then
					room:setPlayerProperty(player, "kingdom", sgs.QVariant("wei"))
				end
				local players = room:getAllPlayers()
				for _, _player in sgs.qlist(players) do
					if _player:getMark("@tied") > 0 then
						_player:loseMark("@tied")
					end
				end
			end
		end
		return false
	end
}
LuaLianliClear = sgs.CreateTriggerSkill{
	name = "#LuaLianli-clear" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		for _, _player in sgs.qlist(player:getRoom():getAlivePlayers()) do
			if _player:getMark("@tied") > 0 then
				_player:loseMark("@tied")
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
--[[
	技能名：绝汲
	相关武将：倚天·张儁乂
	描述：出牌阶段，你可以和一名角色拼点：若你赢，你获得对方的拼点牌，并可立即再次与其拼点，如此反复，直到你没赢或不愿意继续拼点为止。每阶段限一次。
	引用：LuaJueji
	状态：1217验证失败（isSuccess无接口）
]]--
LuaJuejiCard = sgs.CreateSkillCard{
	name = "LuaJuejiCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodPindian ,
	target_filter = function(self, targets, to_select)
		return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_effect = function(self, effect)
		local success = effect.from:pindian(effect.to, "LuaJueji", self)
		local to = effect.to
		local _data = sgs.QVariant()
		_data:setValue(to)
		while success and (not effect.to:isKongcheng()) do
			if effect.from:isKongcheng() then
				break
			elseif not effect.from:askForSkillInvoke("LuaJueji", _data) then
				break
			end
			success = effect.from:pindian(effect.to, "LuaJueji")
		end
	end
}
LuaJuejiVS = sgs.CreateViewAsSkill{
	name = "LuaJueji" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return (#selected == 0) and (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local juejicard = LuaJuejiCard:clone()
		juejicard:addSubcard(cards[1])
		return juejicard
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaJuejiCard")
	end
}
LuaJueji = sgs.CreateTriggerSkill{
	name = "LuaJueji" ,
	events = {sgs.Pindian} ,
	view_as_skill = LuaJuejiVS ,
	on_trigger = function(self, event, player, data)
		local pindian = data:toPindian()
		if (pindian.reason == "LuaJueji") and (pindian:isSuccess()) then
			player:obtainCard(pindian.card)
		end
		return false
	end ,
}
--[[
	技能名：共谋
	相关武将：倚天·钟士季
	描述：回合结束阶段开始时，可指定一名其他角色：其在摸牌阶段摸牌后，须给你X张手牌（X为你手牌数与对方手牌数的较小值），然后你须选择X张手牌交给对方
	引用：LuaGongmou、LuaGongmouExchange
	状态：1217验证失败（不换牌）
]]--
LuaGongmou = sgs.CreateTriggerSkill{
	name = "LuaGongmou" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if player:askForSkillInvoke(self:objectName()) then
				local players = room:getOtherPlayers(player)
				local target = room:askForPlayerChosen(player, players, "LuaGongmou")
				player:gainMark("@conspiracy")
			end
		elseif player:getPhase() == sgs.Player_Start then
			local players = room:getOtherPlayers(player)
			for _, p in sgs.qlist(players) do
				if player:getMark("@conspiracy") > 0 then
					player:loseMark("@conspiracy")
				end
			end
		end
		return false
	end
}
LuaGongmouExchange = sgs.CreateTriggerSkill{
	name = "#LuaGongmou-exchange" ,
	events = {sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Draw then return false end
		player:loseMark("@conspiracy")
		local room = player:getRoom()
		local zhongshiji = room:findPlayerBySkillName()
		if zhongshiji then
			local x = math.min(zhongshiji:getHandcardNum(), player:getHandcardNum())
			if x == 0 then return false end
			local to_exchange = nil
			if player:getHandcardNum() == x then
				to_exchange = player:wholeHandCards()
			else
				to_exchange = room:askForExchange(player, "LuaGongmou", x)
			end
			room:moveCardTo(to_exchange, zhongshiji, sgs.Player_PlaceHand, false)
			to_exchange = room:askForExchange(zhongshiji, "LuaGongmou", x)
			room:moveCardTo(to_exchange, player, sgs.Player_PlaceHand, false)
		end
		return false
	end
	can_trigger = function(self, target)
		return target and target:getMark("@conspiracy") > 0
	end
}
--[[
	技能名：义舍
	相关武将：倚天·张公祺
	描述：出牌阶段，你可将任意数量手牌正面朝上移出游戏称为“米”（至多存在五张）或收回；其他角色在其出牌阶段可选择一张“米”询问你，若你同意，该角色获得这张牌，每阶段限两次
	引用：LuaYishe；LuaYisheAsk（技能暗将）
	状态：暂时搁置
]]--
LuaYisheCard = sgs.CreateSkillCard{
	name = "LuaYisheCard" ,
	target_fixed = true ,
	will_throw = false ,
	on_use = function(self, room, source, targets)
		local rice = source:getPile("rice")
		if self:getSubcards():isEmpty() then
			for _, card_id in sgs.qlist(rice) do
				room:obtainCard(source, card_id)
			end
		else
			for _, card_id in sgs.qlist(self:getSubcards()) do
				source:addToPile("rice", card_id)
			end
		end
	end
}
LuaYisheVS = sgs.CreateViewAsSkill{
	name = "LuaYishe" ,
	n = 5 ,
	view_filter = function(self, selected, to_select)
		local n = sgs.Self:getPile("rice"):length()
		if (#selected + n) >= 5 then return false end
		return not to_select:isEquipped()
	end ,
	card = LuaYisheCard:clone() ,
	view_as = function(self, cards)
		if sgs.Self:getPiel("rice"):isEmpty() and (#cards == 0) return nil end
		card:clearSubcards()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end ,
	enabled_at_play = function(self, player)
		if (player:getPile("rice"):isEmpty()) then
			return not player:isKongcheng()
		else
			return true
		end
	end ,
}
LuaYisheAskCard = sgs.CreateSkillCard(){
	name = "LuaYisheAskCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		local zhanglu = room:findPlayerBySkillName("LuaYishe")
		if not zhanglu then return end
		local yishe = zhanglu:getPile("rice")
		if yishe:isEmpty() then return end
		local card_id
		if yishe:length() == 1 then
			card_id = yishe:first()
		else
			room:fillAG(yishe, source)
			card_id = room:askForAG(source, yishe, false, "LuaYisheAsk")
			room:clearAG(source)
		end
		room:showCard(zhanglu, card_id)
		if room:askForChoice(zhanglu, "LuaYisheAsk", "allow+disallow") == "allow" then
			source:obtainCard(sgs.Sanguosha:getCard(card_id))
			room:showCard(source, card_id)
		end
	end ,
}
LuaYisheAsk = sgs.CreateViewAsSkill{
	name = "LuaYisheAsk" ,
	n = 0 ,
	view_as = function()
		return LuaYisheAskCard:clone()
	end ,
	enabled_at_play = function(self, player)
		if player:hasSkill("LuaYishe") then return false end
		if player:usedTimes("#LuaYisheAskCard") >= 2 then return false end
		local zhanglu = nil
		for _ p in sgs.qlist(player:getSiblings()) do
			if p:isAlive() and p:hasSkill("LuaYishe") then
				zhanglu = p
				break
			end
		end
		return zhanglu and (not zhanglu:getPile("rice"):isEmpty())
	end ,
}
LuaYishe = sgs.CreateGameStartSkill{
	name = "LuaYishe" ,
	view_as_skill = LuaYisheVS ,
	on_gamestart = function(self, player)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			room:attachSkillToPlayer(p, "LuaYisheAsk")
		end
	end ,
}

--[[
	技能名：贪婪
	相关武将：智·许攸
	描述：每当你受到一次伤害，可与伤害来源进行拼点：若你赢，你获得两张拼点牌
	引用：LuaTanlan
	状态：1217验证失败（isSuccess无接口）
]]--
LuaTanlan = sgs.CreateTriggerSkill{
	name = "LuaTanlan" ,
	events = {sgs.Pindian, sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local from = damage.from
			local room = player:getRoom()
			if from and (from:objectName() ~= player:objectName()) and (not from:isKongcheng()) and (not player:isKongcheng()) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					player:pindian(from, self:objectName())
				end
			end
		else
			local pindian = data:toPindian()
			if (pindian.reason == self:objectName()) and pindian:isSuccess() then
				player:obtainCard(pindian.to_card)
				player:obtainCard(pindian.from_card)
			end
		end
		return false
	end ,
}
--[[
	技能名：异才
	相关武将：智·姜维
	描述：每当你使用一张非延时类锦囊时(在它结算之前)，可立即对攻击范围内的角色使用一张【杀】
	引用：LuaYicai
	状态：1217验证失败
]]--
LuaYicai = sgs.CreateTriggerSkill{
	name = "LuaYicai" ,
	events == {sgs.CardUsed, sgs.CardResponded} ,
	on_trigger = function(self, event, player, data)
		local card = nil
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		if card and card:isNDTrick() then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:askForUseCard(player, "slash", "@askforslash")
			end
		end
	end ,
}
--[[
	技能名：筹粮
	相关武将：智·蒋琬
	描述：回合结束阶段开始时，若你手牌少于三张，你可以从牌堆顶亮出X张牌（X为4减当前手牌数），拿走其中的基本牌，把其余的牌置入弃牌堆
	引用：LuaChouliang
	状态：1217验证失败
]]--
LuaChouliang = sgs.CreateTriggerSkill{
	name = "LuaChouliang" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local handcardnum = player:getHandcardNum()
		if (player:getPhase() == sgs.Player_Finish) and (handcardnum < 3) then
			if room:askForSkillInvoke(player, self:objectName()) then
				local x = 4 - handcardnum
				local ids = room:getNCards(x, false)
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
				room:moveCardsAtomic(move, true)
				local card_to_throw = sgs.IntList()
				local card_to_gotback = sgs.IntList()
				for i = 0, x - 1, 1 do
					if not (sgs.Sanguosha:getCard(ids.at(i)):isKindOf("BasicCard")) then
						card_to_throw:append(ids.at(i))
					else
						card_to_gotback:append(ids.at(i))
					end
				end
				if not card_to_gotback:isEmpty() then
					local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, id in sgs.qlist(card_to_gotback) do
						dummy2:addSubcard(id)
					end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, player:objectName())
					room:obtainCard(player, dummy2, reason)
				end
				if not card_to_throw:isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, id in sgs.qlist(card_to_throw) do
						dummy:addSubcard(id)
					end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
					room:throwCard(dummy, reason, nil)
				end
			end
		end
		return false
	end
}
--[[
	技能名：尽瘁
	相关武将：智·张昭
	描述：当你死亡时，可令一名角色摸取或者弃置三张牌
	引用：LuaJincui
	状态：1217验证失败
]]--
LuaJincui = sgs.CreateTriggerSkill{
	name = "LuaJincui" ,
	events == {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local room = player:getRoom()
		local targets = room:getAlivePlayers()
		if targets:isEmpty() then return false end
		if not player:askForSkillInvoke(self:objectName()) then return false end
		local target = room:askForPlayerChosen(player, targets, self:objectName())
		local t_data = sgs.QVariant()
		t_data:setValue(target)
		if room:askForChoice(player, self:objectName(), "draw+throw", t_data) == "draw" then
			target:drawCards(3)
		else
			room:askForDiscard(target, self:objectName(), 3, 3, false, true)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
--[[
	技能名：狱刎（锁定技）
	相关武将：智·田丰
	描述：当你死亡时，凶手视为自己
	引用：LuaXYuwen
	状态：1217验证失败
]]--
LuaYuwen = sgs.CreateTriggerSkill{
	name = "LuaYuwen" ,
	events = {sgs.GameOverJudge} ,
	frequency = sgs.Skill_Compulsory ,
	priority = 4,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.damage then
			if death.damage.from:objectName() == player:objectName() then
				return false
			end
		else
			death.damage = sgs.DamageStruct()
			death.damage.to = player
		end
		death.damage.from = player
		data:setValue(death)
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}