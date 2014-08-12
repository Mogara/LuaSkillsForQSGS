LuaSkillsForQSGS
================

新版太阳神三国杀武将技能代码速查手册（Lua版）

**Fs**: Most of the skills is written in the year 2012, and can't be used in the newest 1210 & 1217 versions anymore.
Coders needed badly, for we should update the skills to the newest version.

If you find BUG in reading, please [click here](https://github.com/DGAH/LuaSkillsForQSGS/issues/7) to let us know. We would fix it as quickly as possible.

##Acknowledgement

**Special thanks to the following for aid of looking for BUGs.^_^**

十一月的小胖(Baidu ID)、魅惑菇投手（Baidu ID)、赤魂go(Baidu ID)、whj329203709(Baidu ID)、波希米亚不后悔 (Baidu ID)、haoshuang(GitHub ID)、array88(GitHub ID)、自由fr(Baidu ID)

**Note**: The **sgs\_ex.lua** in QSanguosha-1217 has some typos, I upload a new one which fixed the typos.
Please copy the **sgs_ex.lua** to **QSanguosha-1217\lua** directory and use the lua skills to fix the bugs.

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
[逆乱](ChapterN.md#逆乱)、[鸟翔](ChapterN.md#鸟翔)、[涅槃](ChapterN.md#涅槃)
- Chapter O **暂无技能**
- [Chapter P](ChapterP.md)  
[排异](ChapterP.md#排异)、[咆哮](ChapterP.md#咆哮)、[翩仪](ChapterP.md#翩仪)、[破军](ChapterP.md#破军)、[普济](ChapterP.md#普济)
- [Chapter Q](ChapterQ.md)   
[七星](ChapterQ.md#七星)、[戚乱](ChapterQ.md#戚乱)、[奇才](ChapterQ.md#奇才)、[奇才-旧](ChapterQ.md#奇才-旧)、[奇策](ChapterQ.md#奇策)、[奇袭](ChapterQ.md#奇袭)、[千幻](ChapterQ.md#千幻)、[谦逊](ChapterQ.md#谦逊)、[潜袭](ChapterQ.md#潜袭)、[潜袭-旧](ChapterQ.md#潜袭-旧)、[枪舞](ChapterQ.md#枪舞)、[强袭](ChapterQ.md#强袭)、[巧变](ChapterQ.md#巧变)、[巧说](ChapterQ.md#巧说)、[琴音](ChapterQ.md#琴音)、[青囊](ChapterQ.md#青囊)、[倾城](ChapterQ.md#倾城)、[倾国](ChapterQ.md#倾国)、[倾国-1V1](ChapterQ.md#倾国-1v1)、[求援](ChapterQ.md#求援)、[驱虎](ChapterQ.md#驱虎)、[权计](ChapterQ.md#权计)
- [Chapter R](ChapterR.md)
- [Chapter S](ChapterS.md)
- [Chapter T](ChapterT.md)
- Chapter U **暂无技能**
- [Chapter V](ChapterV.md)
- [Chapter W](ChapterW.md)
- [Chapter X](ChapterX.md)
- [Chapter Y](ChapterY.md)
- [Chapter Z](ChapterZ.md)

