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
- [Chapter I](ChapterI.md)
- [Chapter J](ChapterJ.md)
- [Chapter K](ChapterK.md)
- [Chapter L](ChapterL.md)
- [Chapter M](ChapterM.md)
- [Chapter N](ChapterN.md)
- [Chapter O](ChapterO.md)
- [Chapter P](ChapterP.md)
- [Chapter Q](ChapterQ.md) 
- [Chapter R](ChapterR.md)
- [Chapter S](ChapterS.md)
- [Chapter T](ChapterT.md)
- [Chapter U](ChapterU.md)
- [Chapter V](ChapterV.md)
- [Chapter W](ChapterW.md)
- [Chapter X](ChapterX.md)
- [Chapter Y](ChapterY.md)
- [Chapter Z](ChapterZ.md)

