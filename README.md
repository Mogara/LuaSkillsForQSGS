LuaSkillsForQSGS
================

新版太阳神三国杀武将技能代码速查手册（Lua版）

**Fs**: Most of the skills is written in the year 2012, and can't be used in the newest 1210 & 1217 versions anymore.
Coders needed badly, for we should update the skills to the newest version.

If you find BUG in reading, please [click here](https://github.com/DGAH/LuaSkillsForQSGS/issues/7) to let us know. We would fix it as quickly as possible.

##Acknowledgement

**Special thanks to the following for aid of looking for BUGs.^_^**

十一月的小胖(Baidu ID)、魅惑菇投手（Baidu ID)、赤魂go(Baidu ID)、whj329203709(Baidu ID)、波希米亚不后悔 (Baidu ID)、haoshuang(GitHub ID)、array88(GitHub ID)、自由fr(Baidu ID)

把本项目中的sgs_ex.lua拷贝到神杀目录的lua文件夹下覆盖原有的同名文件
==

 简介 
====================

本手册分为A~Z共26个章节，分别以技能名第一个字的拼音首字母归类，其中**ChapterV**用于存放一些待完善的技能。 
目录
====================
- [Chapter A](ChapterA.md)  
 [安娴](ChapterA.md#安娴)、[安恤](ChapterA.md#安恤)、[暗箭](ChapterA.md#暗箭)、[傲才](ChapterA.md#傲才)
- [Chapter B](ChapterB.md)  
[八阵](ChapterB.md#八阵)、[霸刀](ChapterB.md#霸刀)、[霸王](ChapterB.md#霸王)、[拜印](ChapterB.md#拜印)、[豹变](ChapterB.md#豹变)、[暴虐](ChapterB.md#暴虐)、[悲歌](ChapterB.md#悲歌)、[北伐](ChapterB.md#北伐)、[崩坏](ChapterB.md#崩坏)、[笔伐](ChapterB.md#笔伐)、[闭月](ChapterB.md#闭月)、[补益](ChapterB.md#补益)、[不屈](ChapterB.md#不屈)、[不屈-旧风](ChapterB.md#不屈-旧风) 
- [Chapter C](ChapterC.md)  
 [藏机](ChapterC.md#藏机)、[藏匿](ChapterC.md#藏匿)、[缠怨](ChapterC.md#缠怨)、[超级观星](ChapterC.md#超级观星)、[称象](ChapterC.md#称象)、[称象-倚天](ChapterC.md#称象-倚天)、[持重](ChapterC.md#持重)、[冲阵](ChapterC.md#冲阵)、[筹粮](ChapterC.md#筹粮)、[醇醪](ChapterC.md#醇醪)、[聪慧](ChapterC.md#聪慧)、[存嗣](ChapterC.md#存嗣)、[挫锐](ChapterC.md#挫锐)
- [Chapter D](ChapterD.md)  
[大喝](ChapterD.md#大喝)、[大雾](ChapterD.md#大雾)、[单骑](ChapterD.md#单骑)、[胆守](ChapterD.md#胆守)、[啖酪](ChapterD.md#啖酪)、[当先](ChapterD.md#当先)、[缔盟](ChapterD.md#缔盟)、[洞察](ChapterD.md#洞察)、[毒士](ChapterD.md#毒士)、[毒医](ChapterD.md#毒医)、[黩武](ChapterD.md#黩武)、[短兵](ChapterD.md#短兵)、[断肠](ChapterD.md#断肠)、[断粮](ChapterD.md#断粮)、[断指](ChapterD.md#断指)、[度势](ChapterD.md#度势)、[夺刀](ChapterD.md#夺刀)
- [Chapter E](ChapterE.md)  
[恩怨](ChapterE.md#恩怨)、[恩怨-旧](ChapterE.md#恩怨-旧)
- [Chapter F](ChapterF.md)   
[反间](ChapterF.md#反间)、[反间-翼](ChapterF.md#反间-翼)、[反馈](ChapterF.md#反馈)、[放权](ChapterF.md#放权)、[放逐](ChapterF.md#放逐)、[飞影](ChapterF.md#飞影)、[焚城](ChapterF.md#焚城)、[焚心](ChapterF.md#焚心)、[奋激](ChapterF.md#奋激)、[奋迅](ChapterF.md#奋迅)、[愤勇](ChapterF.md#愤勇)、[奉印](ChapterF.md#奉印)、[伏枥](ChapterF.md#伏枥)、[扶乱](ChapterF.md#扶乱)、[辅佐](ChapterF.md#辅佐)、[父魂](ChapterF.md#父魂)、[父魂-旧](ChapterF.md#父魂-旧)
- [Chapter G](ChapterG.md)  
[甘露](ChapterG.md#甘露)、[感染](ChapterG.md#感染)、[刚烈](ChapterG.md#刚烈)、[刚烈-3v3](ChapterG.md#刚烈-3v3)、[刚烈-翼](ChapterG.md#刚烈-翼)、[弓骑](ChapterG.md#弓骑)、[弓骑-旧](ChapterG.md#弓骑-旧)、[攻心](ChapterG.md#攻心)、[共谋](ChapterG.md#共谋)、[蛊惑](ChapterG.md#蛊惑)、[蛊惑-旧](ChapterG.md#蛊惑-旧)、[固守](ChapterG.md#固守)、[固政](ChapterG.md#固政)、[观星](ChapterG.md#观星)、[归汉](ChapterG.md#归汉)、[归心](ChapterG.md#归心)、[归心-倚天](ChapterG.md#归心-倚天)、[闺秀](ChapterG.md#闺秀)、[鬼才](ChapterG.md#鬼才)、[鬼道](ChapterG.md#鬼道)、[国色](ChapterG.md#国色)
- [Chapter H](ChapterH.md)  
[汉统](ChapterH.md#汉统)、[好施](ChapterH.md#好施)、[鹤翼](ChapterH.md#鹤翼)、[横江](ChapterH.md#横江)、[弘援](ChapterH.md#弘援)、[弘援sp](ChapterH.md#弘援sp)、[红颜](ChapterH.md#红颜)、[后援](ChapterH.md#后援)、[胡笳](ChapterH.md#胡笳)、[虎威](ChapterH.md#虎威)、[虎啸](ChapterH.md#虎啸)、[护驾](ChapterH.md#护驾)、[护援](ChapterH.md#护援)、[化身](ChapterH.md#化身)、[怀异](ChapterH.md#排异)、[缓释](ChapterH.md#缓释)、[缓释sp](ChapterH.md#缓释sp)、[皇恩](ChapterH.md#皇恩)、[黄天](ChapterH.md#黄天)、[挥泪](ChapterH.md#挥泪)、[魂姿](ChapterH.md#魂姿)、[火计](ChapterH.md#火计)、[祸首](ChapterH.md#祸首)、[祸水](ChapterH.md#祸水)
- Chapter I **暂无技能**
- [Chapter J](ChapterJ.md)  
[鸡肋](ChapterJ.md#鸡肋)、[激昂](ChapterJ.md#激昂)、[激将](ChapterJ.md#激将)、[极略](ChapterJ.md#极略)、[急救](ChapterJ.md#急救)、[急速](ChapterJ.md#急速)、[急袭](ChapterJ.md#急袭)、[集智](ChapterJ.md#集智)、[集智-旧](ChapterJ.md#集智-旧)、[嫉恶](ChapterJ.md#嫉恶)、[奸雄](ChapterJ.md#奸雄)、[坚守](ChapterJ.md#坚守)、[将驰](ChapterJ.md#将驰)、[节命](ChapterJ.md#节命)、[结姻](ChapterJ.md#结姻)、[竭缘](ChapterJ.md#竭缘)、[解烦](ChapterJ.md#解烦)、[解烦-旧](ChapterJ.md#解烦-旧)、[解惑](ChapterJ.md#解惑)、[解围](ChapterJ.md#解围)、[尽瘁](ChapterJ.md#尽瘁)、[禁酒](ChapterJ.md#禁酒)、[精策](ChapterJ.md#精策)、[精锐](ChapterJ.md#精锐)、[酒池](ChapterJ.md#酒池)、[酒诗](ChapterJ.md#酒诗)、[救援](ChapterJ.md#救援)、[救主](ChapterJ.md#救主)、[举荐](ChapterJ.md#举荐)、[举荐-旧](ChapterJ.md#举荐-旧)、[巨象](ChapterJ.md#巨象)、[倨傲](ChapterJ.md#倨傲)、[据守](ChapterJ.md#据守)、[据守-旧](ChapterJ.md#据守-旧)、[据守-翼](ChapterJ.md#据守-翼)、[聚武](ChapterJ.md#聚武)、[绝策](ChapterJ.md#绝策)、[绝汲](ChapterJ.md#绝汲)、[绝境](ChapterJ.md#绝境)、[绝境-旧](ChapterJ.md#绝境-旧)、[绝情](ChapterJ.md#绝情)、[军威](ChapterJ.md#军威)、[峻刑](ChapterJ.md#峻刑)
- [Chapter K](ChapterK.md)  
[看破](ChapterK.md#看破)、[慷忾](ChapterK.md#慷忾)、[克构](ChapterK.md#克构)、[克己](ChapterK.md#克己)、[空城](ChapterK.md#空城)、[苦肉](ChapterK.md#苦肉)、[狂暴](ChapterK.md#狂暴)、[狂风](ChapterK.md#狂风)、[狂斧](ChapterK.md#狂斧)、[狂骨](ChapterK.md#狂骨)、[狂骨-1v1](ChapterK.md#狂骨-1v1)、[溃围](ChapterK.md#溃围)
- [Chapter L](ChapterL.md)  
[狼顾](ChapterL.md#狼顾)、[乐学](ChapterL.md#乐学)、[雷击](ChapterL.md#雷击)、[雷击-旧](ChapterL.md#雷击-旧)、[离魂](ChapterL.md#离魂)、[离间](ChapterL.md#离间)、[离间-旧](ChapterL.md#离间-旧)、[离迁](ChapterL.md#离迁)、[礼让](ChapterL.md#礼让)、[疠火](ChapterL.md#疠火)、[连环](ChapterL.md#连环)、[连理](ChapterL.md#连理)、[连破](ChapterL.md#连破)、[连营](ChapterL.md#连营)、[烈弓](ChapterL.md#烈弓)、[烈弓-1v1](ChapterL.md#烈弓-1v1)、[烈刃](ChapterL.md#烈刃)、[裂围](ChapterL.md#裂围)、[流离](ChapterL.md#流离)、[龙胆](ChapterL.md#龙胆)、[龙魂](ChapterL.md#龙魂)、[龙魂-高达](ChapterL.md#龙魂-高达)、[龙吟](ChapterL.md#龙吟)、[笼络](ChapterL.md#笼络)、[乱击](ChapterL.md#乱击)、[乱武](ChapterL.md#乱武)、[裸衣](ChapterL.md#裸衣)、[裸衣-翼](ChapterL.md#裸衣-翼)、[洛神](ChapterL.md#洛神)、[落雁](ChapterL.md#落雁)、[落英](ChapterL.md#落英)
- [Chapter M](ChapterM.md)  
[马术](ChapterM.md#马术)、[蛮裔](ChapterM.md#蛮裔)、[漫卷](ChapterM.md#漫卷)、[猛进](ChapterM.md#猛进)、[秘计](ChapterM.md#秘计)、[秘计-旧](ChapterM.md#秘计-旧)、[密信](ChapterM.md#密信)、[密诏](ChapterM.md#密诏)、[灭计](ChapterM.md#灭计)、[名士](ChapterM.md#名士)、[名士-国](ChapterM.md#名士-国)、[明策](ChapterM.md#明策)、[明鉴](ChapterM.md#明鉴)、[明哲](ChapterM.md#明哲)、[谋断](ChapterM.md#谋断)、[谋溃](ChapterM.md#谋溃)、[谋诛](ChapterM.md#谋诛)
- [Chapter N](ChapterN.md)  
[纳蛮](ChapterN.md#纳蛮)、[逆乱](ChapterN.md#逆乱)、[鸟翔](ChapterN.md#鸟翔)、[涅槃](ChapterN.md#涅槃)
- Chapter O **暂无技能**
- [Chapter P](ChapterP.md)  
[排异](ChapterP.md#排异)、[咆哮](ChapterP.md#咆哮)、[翩仪](ChapterP.md#翩仪)、[破军](ChapterP.md#破军)、[普济](ChapterP.md#普济)
- [Chapter Q](ChapterQ.md)   
[七星](ChapterQ.md#七星)、[戚乱](ChapterQ.md#戚乱)、[奇才](ChapterQ.md#奇才)、[奇才-旧](ChapterQ.md#奇才-旧)、[奇策](ChapterQ.md#奇策)、[奇袭](ChapterQ.md#奇袭)、[千幻](ChapterQ.md#千幻)、[谦逊](ChapterQ.md#谦逊)、[潜袭](ChapterQ.md#潜袭)、[潜袭-旧](ChapterQ.md#潜袭-旧)、[枪舞](ChapterQ.md#枪舞)、[强袭](ChapterQ.md#强袭)、[巧变](ChapterQ.md#巧变)、[巧说](ChapterQ.md#巧说)、[琴音](ChapterQ.md#琴音)、[青囊](ChapterQ.md#青囊)、[倾城](ChapterQ.md#倾城)、[倾国](ChapterQ.md#倾国)、[倾国-1V1](ChapterQ.md#倾国-1v1)、[求援](ChapterQ.md#求援)、[驱虎](ChapterQ.md#驱虎)、[权计](ChapterQ.md#权计)
- [Chapter R](ChapterR.md)  
[仁德](ChapterR.md#仁德)、[仁德-旧](ChapterR.md#仁德-旧)、[仁望](ChapterR.md#仁望)、[仁心](ChapterR.md#仁心)、[忍戒](ChapterR.md#忍戒)、[肉林](ChapterR.md#肉林)、[若愚](ChapterR.md#若愚)
- [Chapter S](ChapterS.md)  
[伤逝](ChapterS.md#伤逝)、[伤逝-旧](ChapterS.md#伤逝-旧)、[尚义](ChapterS.md#尚义)、[烧营](ChapterS.md#烧营)、[涉猎](ChapterS.md#涉猎)、[神愤](ChapterS.md#神愤)、[甚贤](ChapterS.md#甚贤)、[神戟](ChapterS.md#神戟)、[神君](ChapterS.md#神君)、[神力](ChapterS.md#神力)、[神速](ChapterS.md#神速)、[神威](ChapterS.md#神威)、[神智](ChapterS.md#神智)、[生息](ChapterS.md#生息)、[师恩](ChapterS.md#师恩)、[识破](ChapterS.md#识破)、[恃才](ChapterS.md#恃才)、[恃勇](ChapterS.md#恃勇)、[弑神](ChapterS.md#弑神)、[誓仇](ChapterS.md#誓仇)、[慎拒](ChapterS.md#慎拒)、[守成](ChapterS.md#守成)、[授业](ChapterS.md#授业)、[淑德](ChapterS.md#淑德)、[淑慎](ChapterS.md#淑慎)、[双刃](ChapterS.md#双刃)、[双雄](ChapterS.md#双雄)、[水箭](ChapterS.md#水箭)、[水泳](ChapterS.md#水泳)、[死谏](ChapterS.md#死谏)、[死节](ChapterS.md#死节)、[死战](ChapterS.md#死战)、[颂词](ChapterS.md#颂词)、[颂威](ChapterS.md#颂威)、[肃资](ChapterS.md#肃资)、[随势](ChapterS.md#随势)
- [Chapter T](ChapterT.md)  
[抬榇](ChapterT.md#抬榇)、[贪婪](ChapterT.md#贪婪)、[探虎](ChapterT.md#探虎)、[探囊](ChapterT.md#探囊)、[天妒](ChapterT.md#天妒)、[天命](ChapterT.md#天命)、[天香](ChapterT.md#天香)、[天义](ChapterT.md#天义)、[挑衅](ChapterT.md#挑衅)、[铁骑](ChapterT.md#铁骑)、[同疾](ChapterT.md#同疾)、[同心](ChapterT.md#同心)、[偷渡](ChapterT.md#偷渡)、[突骑](ChapterT.md#突骑)、[突袭](ChapterT.md#突袭)、[突袭-1v1](ChapterT.md#突袭-1v1)、[屯田](ChapterT.md#屯田)
- Chapter U **暂无技能**
- Chapter V **暂无技能**
- [Chapter W](ChapterW.md)  
[完杀](ChapterW.md#完杀)、[婉容](ChapterW.md#婉容)、[忘隙](ChapterW.md#忘隙)、[妄尊](ChapterW.md#妄尊)、[危殆](ChapterW.md#危殆)、[围堰](ChapterW.md#围堰)、[帷幕](ChapterW.md#帷幕)、[伪帝](ChapterW.md#伪帝)、[温酒](ChapterW.md#温酒)、[无谋](ChapterW.md#无谋)、[无前](ChapterW.md#无前)、[无双](ChapterW.md#无双)、[无言](ChapterW.md#无言)、[无言-旧](ChapterW.md#无言-旧)、[五灵](ChapterW.md#五灵)、[武魂](ChapterW.md#武魂)、[武继](ChapterW.md#武继)、[武神](ChapterW.md#武神)、[武圣](ChapterW.md#武圣)
- [Chapter X](ChapterX.md)  
[惜粮](ChapterX.md#惜粮)、[陷嗣](ChapterX.md#陷嗣)、[陷阵](ChapterX.md#陷阵)、[享乐](ChapterX.md#享乐)、[枭姬](ChapterX.md#枭姫)、[枭姬-1v1](ChapterX.md#枭姬-1v1)、[骁果](ChapterX.md#骁果)、[骁袭](ChapterX.md#骁袭)、[孝德](ChapterX.md#孝德)、[挟缠](ChapterX.md#挟缠)、[心战](ChapterX.md#心战)、[新生](ChapterX.md#新生)、[星舞](ChapterX.md#星舞)、[行殇](ChapterX.md#行殇)、[雄异](ChapterX.md#雄异)、[修罗](ChapterX.md#修罗)、[旋风](ChapterX.md#旋风)、[旋风-旧](ChapterX.md#旋风-旧)、[眩惑](ChapterX.md#昡惑)、[眩惑-旧](ChapterX.md#眩惑-旧)、[雪恨](ChapterX.md#雪恨)、[血祭](ChapterX.md#血祭)、[血裔](ChapterX.md#血裔)、[恂恂](ChapterX.md#恂恂)、[迅猛](ChapterX.md#迅猛)、[殉志](ChapterX.md#殉志)
- [Chapter Y](ChapterY.md)  
[延祸](ChapterY.md#延祸)、[严整](ChapterY.md#严整)、[言笑](ChapterY.md#言笑)、[燕语](ChapterY.md#燕语)、[耀武](ChapterY.md#耀武)、[业炎](ChapterY.md#业炎)、[遗计](ChapterY.md#遗计)、[疑城](ChapterY.md#疑城)、[倚天](ChapterY.md#倚天)、[义从](ChapterY.md#义从)、[义从-贴纸](ChapterY.md#义从-贴纸)、[义舍](ChapterY.md#义舍)、[义释](ChapterY.md#义释)、[异才](ChapterY.md#异才)、[毅重](ChapterY.md#毅重)、[姻礼](ChapterY.md#姻礼)、[银铃](ChapterY.md#银铃)、[英魂](ChapterY.md#英魂)、[英姿](ChapterY.md#英姿)、[影兵](ChapterY.md#影兵)、[庸肆](ChapterY.md#庸肆)、[勇决](ChapterY.md#勇决)、[狱刎](ChapterY.md#狱刎)、[御策](ChapterY.md#御策)、[援护](ChapterY.md#援护)
- [Chapter Z](ChapterZ.md)  
[灾变](ChapterZ.md#灾变)、[再起](ChapterZ.md#再起)、[凿险](ChapterZ.md#凿险)、[早夭](ChapterZ.md#早夭)、[战神](ChapterZ.md#战神)、[昭烈](ChapterZ.md#昭烈)、[昭心](ChapterZ.md#昭心)、[贞烈](ChapterZ.md#贞烈)、[贞烈-旧](ChapterZ.md#贞烈-旧)、[鸩毒](ChapterZ.md#鸩毒)、[镇威](ChapterZ.md#镇威)、[镇卫](ChapterZ.md#镇卫)、[争锋](ChapterZ.md#争锋)、[争功](ChapterZ.md#争功)、[争功-0610版](ChapterZ.md#争功-0610版)、[整军](ChapterZ.md#整军)、[直谏](ChapterZ.md#直谏)、[直言](ChapterZ.md#直言)、[志继](ChapterZ.md#志继)、[制霸](ChapterZ.md#制霸)、[制霸-制霸孙权](ChapterZ.md#制霸-制霸孙权)、[制衡](ChapterZ.md#制衡)、[智迟](ChapterZ.md#智迟)、[智愚](ChapterZ.md#智愚)、[忠义](ChapterZ.md#忠义)、[咒缚](ChapterZ.md#咒缚)、[筑楼](ChapterZ.md#筑楼)、[追忆](ChapterZ.md#追忆)、[惴恐](ChapterZ.md#惴恐)、[资粮](ChapterZ.md#资粮)、[自立](ChapterZ.md#自立)、[自守](ChapterZ.md#自守)、[宗室](ChapterZ.md#宗室)、[纵火](ChapterZ.md#纵火)、[纵适](ChapterZ.md#纵适)、[纵玄](ChapterZ.md#纵玄)、[醉乡](ChapterZ.md#醉乡)

