--[[
  Presentation:
  In fact, it is not necessary to call this part of functions now only if you do not believe the library of Lua...
  This file will be removed after all skills disconnect from simulated bitwise operations.
]]--
--[[
  啦啦神英文……我来翻译下：
  事实上，现在除非你不信任LUA库，否则调用这部分函数已经完全没有必要了。
  这个文件将在所有涉及位运算的技能全部与这个文件脱离关系之后删除。

  附带此文件与LUA的bit32库的函数对比：
  bit:_xor     ==  bit32.bxor
  bit:_and     ==  bit32.band  （其实貌似现在的代码当中只用到了这个）
  bit:_or      ==  bit32.bor
  bit:_not     ==  bit32.bnot
  bit:_rshift  ==  bit32.rshift
  bit:_lshift  ==  bit32.lshift
]]--
--[[
  涉及位运算的技能请使用本文件的函数，将本文件放在游戏根目录，在需要使用位运算的lua中require("bit")即可访问变量bit
  例子：
  a,b按位与      bit:_and(a,b)
]]--
bit={data32={2147483648,1073741824,536870912,268435456,134217728,67108864,33554432,16777216,8388608,4194304,2097152,1048576,524288,262144,131072,65536,32768,16384,8192,4096,2048,1024,512,256,128,64,32,16,8,4,2,1}}

function bit:d2b(arg)
	local   tr={}
	for i=1,32 do
		if arg >= self.data32[i] then
		tr[i]=1
		arg=arg-self.data32[i]
		else
		tr[i]=0
		end
	end
	return   tr
end   --bit:d2b

function    bit:b2d(arg)
	local   nr=0
	for i=1,32 do
		if arg[i] ==1 then
		nr=nr+2^(32-i)
		end
	end
	return  nr
end   --bit:b2d

function    bit:_xor(a,b)
	local   op1=self:d2b(a)
	local   op2=self:d2b(b)
	local   r={}

	for i=1,32 do
		if op1[i]==op2[i] then
			r[i]=0
		else
			r[i]=1
		end
	end
	return  self:b2d(r)
end --bit:xor

function    bit:_and(a,b)
	local   op1=self:d2b(a)
	local   op2=self:d2b(b)
	local   r={}

	for i=1,32 do
		if op1[i]==1 and op2[i]==1  then
			r[i]=1
		else
			r[i]=0
		end
	end
	return  self:b2d(r)

end --bit:_and

function    bit:_or(a,b)
	local   op1=self:d2b(a)
	local   op2=self:d2b(b)
	local   r={}

	for i=1,32 do
		if  op1[i]==1 or   op2[i]==1   then
			r[i]=1
		else
			r[i]=0
		end
	end
	return  self:b2d(r)
end --bit:_or

function    bit:_not(a)
	local   op1=self:d2b(a)
	local   r={}

	for i=1,32 do
		if  op1[i]==1   then
			r[i]=0
		else
			r[i]=1
		end
	end
	return  self:b2d(r)
end --bit:_not

function    bit:_rshift(a,n)
	local   op1=self:d2b(a)
	local   r=self:d2b(0)

	if n < 32 and n > 0 then
		for i=1,n do
			for i=31,1,-1 do
				op1[i+1]=op1[i]
			end
			op1[1]=0
		end
	r=op1
	end
	return  self:b2d(r)
end --bit:_rshift

function    bit:_lshift(a,n)
	local   op1=self:d2b(a)
	local   r=self:d2b(0)

	if n < 32 and n > 0 then
		for i=1,n   do
			for i=1,31 do
				op1[i]=op1[i+1]
			end
			op1[32]=0
		end
	r=op1
	end
	return  self:b2d(r)
end --bit:_lshift


function    bit:print(ta)
	local   sr=""
	for i=1,32 do
		sr=sr..ta[i]
	end
	print(sr)
end

--end of bit.lua
