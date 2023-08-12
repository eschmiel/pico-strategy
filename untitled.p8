pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
--main
function _init()
	factions={
		mkfact({
			name='player',
			units={{8,8},{6,7}}
		}),
		mkfact({
			name='enemy',
			units={{4,8},{5,6}}
		})
	}
	actfact=1
	game_state = selu_st({4,4})
end

function _update()
	game_state:update()
end

function _draw()
	cls()
	rect(0,0,127,127,10)
	map()
	drawfacts()
	game_state:draw()
end
-->8
--graphics
sprpos = function(sprite,pos)
	spr(sprite,pos[1]*8,pos[2]*8)
end

textbox=function(x,y,w,h)
	rectfill(x,y,x+w,y+h,15)
	rect(x,y,x+w,y+h,1)
	rect(x+1,y+1,x+w-1,y+h-1,12)
end

highlightpos = function(pos,col)
			local x = pos[1] * 8
			local y = pos[2] * 8
			rect(x, y, x+7, y+7, col)
end

drawfacts=function()
	for i, f in ipairs(factions) do
		f:draw(i)
	end
end
-->8
--controls

function create_selector(pos)

	local selector = {
		pos = copytbl(pos) or {0, 0},
		
		update = function(self)
		 if(btnp(0)) self.pos[1] -= 1
		 if(btnp(1)) self.pos[1] += 1
		 if(btnp(2)) self.pos[2] -= 1
		 if(btnp(3)) self.pos[2] += 1
		 
		 self:wallchk(1)
		 self:wallchk(2)
		end,
		
		wallchk = function(self,i)
			if(self.pos[i] > 15) then
		 	self.pos[i] = 15
		 elseif(self.pos[i] < 0) then
		 	self.pos[i] = 0
		 end
		end,
		
		draw = function(self, col)
			highlightpos(self.pos,col)
		end
	}
		
	return selector
end

--make menu controller
function mkmenuctrl(optnum)
	local ctrl = {
		sel=1,
		optnum=optnum,
		
		update = function(self)
		 if(btnp(0)
		 or btnp(2))
		 then self.sel-=1 end
		 if(btnp(1)
		 or btnp(3))
		 then self.sel+=1 end
		 
		 self:loop()
		end,
		
		loop = function(self)
			if(self.sel>self.optnum) then
		 	self.sel=1
		 elseif(self.sel<1) then
		 	self.sel=optnum
		 end
		end,
	}
		
	return ctrl
end
-->8
--helpers
function copytbl(tbl)
	if(not tbl) return
	local copy = {}
	for k, v in pairs(tbl) do
		local nv = v
		if(type(nv) == 'object') then
			nv = tblcopy(v)
		end
		copy[k] = v
	end
	
	return copy
end
		
function sametbl(tbl1, tbl2)
	if(tblctntbl(tbl1,tbl2)
	and tblctntbl(tbl2,tbl1))
	then return true
	end
end

--table contains table
function tblctntbl(src,tar)
	for k,v in pairs(src) do
		if(v != tar[k]) return false
	end
	return true
end

function tblhas(tbl,tar)
	for v in all(tbl) do
		if(v == tar) return true
	end
	return false
end
-->8
-- units

function mkunit(pos)
	return {
		pos=copytbl(pos),
		atk=8,
		def=2,
		hp=5,
		maxhp=5,
		move=3,
		sprite=1,
		act=true,
		
		draw = function(self)
			if(not self.act)then
			palt(0,false) pal(0,6)
			end
			sprpos(self.sprite,self.pos)
			pal()
		end
	}
end

--unit stats
function ustats(u,x,y)
	textbox(x,y,30,40)
	print('hp:'..u.hp..'/'..u.maxhp,x+4,y+8,13)
	print('atk:'..u.atk,x+4,y+18,13)
	print('def:'..u.def,x+4,y+28,13)
end

actions = {
	"attack",
	"move",
	"wait",
	"cancel"
}

--factions
function mkfact(data)
	local fact={
		name=data.name,
		units={},
		draw=function(self, i)
		 for u in all(self.units) do
			 pal(14,i)
				pal(11,10+i)
		 	u:draw()
		 end
		end
	}
	for u in all(data.units) do
		add(fact.units,mkunit(u))
	end
	return fact
end

function unitatpos(pos)
	for f in all(factions) do
		for u in all(f.units) do
		 if(sametbl(pos,u.pos)) then
		 	return {fact=f,u=u}
		 end
		end
	end
end

function getactfact()
	return factions[actfact]
end

function atk(a,t)
	t.hp-=a.atk-t.def
	a.act=false
	if(t.hp<0) kill(t)
end

function kill(u)
	for f in all(factions) do
		if(tblhas(f.units,u))then
		 del(f.units,u) return
		end
	end
end
-->8
--game state

--select unit state
function selu_st(startpos)
	return {
		sel = create_selector(startpos),
	 update = function(self)
	 	self.sel:update()
	 	local af = getactfact()
	 	local u=unitatpos(self.sel.pos)
	 	if(btnp(4)
	 	and u
	 	and u.u.act
	 	and u.fact.name==af.name)
	 	then game_state = selact_st(u.u)
	 	end
	 end,
	 draw = function(self)
	 	local selcol = 7
	 	local af=getactfact()
	 	local u=unitatpos(self.sel.pos)
			if(u)then	
				ustats(u.u,30,80)
				selcol=10
				if(u.fact.name!=af.name)then
					selcol=8
				end
			end
	 	self.sel:draw(selcol)
	 end
	}
end

function selact_st(u)
	return {
	 u=u,
	 ctrl=mkmenuctrl(#actions),
	 update=function(self)
	 	self.ctrl:update()
	 	if(btnp(4)) self:runaction()
	 	if(btnp(5))game_state=selu_st(self.u.pos)
	 end,
	 runaction=function(self)
	 	local sel=actions[self.ctrl.sel]
			if(sel=='move')then
				game_state=selmove_st(self.u)
			elseif(sel=='cancel')then
				game_state=selu_st(self.u.pos)
			elseif(sel=='wait')then
				self.u.act=false
				game_state=selu_st(self.u.pos)
			elseif(sel=='attack')then
				game_state=selacttar_st(u,sel)
			end			
		end,
	 draw=function(self)
	 	textbox(20,20,30,36)
	 	for i,a in ipairs(actions) do
	 		local col=5
	 		if(i==self.ctrl.sel) col=6
	 		print(a,24,24+(i-1)*8,col)
	 	end
		 local x=self.u.pos[1] * 8
		 local y=self.u.pos[2] * 8
		 rect(x,y,x+7,y+7,11)
	 end
	} 
end

function selmove_st(u)
	return{
		u=u,
		sel=create_selector(u.pos),
		update=function(self)
			self.sel:update()
			if(btnp(4)) then
				self.u.pos=copytbl(self.sel.pos)
				self.u.act = false
			 game_state=selu_st(self.sel.pos)
			end
			if(btnp(5))game_state=selact_st(self.u)
		end,
		draw=function(self)
			highlightpos(self.u.pos,10)
			local selcol = 7
			if(unitatpos(self.sel.pos))
			then	
				selcol=6
			end
	 	self.sel:draw(selcol)
		end
		}
end

function selacttar_st(u,act)
	return{
		u=u,
		sel=create_selector(u.pos),
		update=function(self)
			self.sel:update()
			if(btnp(4))self:runact(act,tar)
			if(btnp(5))then
				game_state=selact_st(self.u)
			end
		end,
		runact=function(self,act)
			if(act=='attack') then
				local tar=unitatpos(self.sel.pos)
				local afname=getactfact().name
			 if( tar
			 and tar.fact.name!=afname)
			 then
			  atk(self.u,tar.u)
			  game_state=selu_st(tar.u.pos)
			 end
			end
		end,
		draw=function(self)
			local afname = getactfact().name
			selcol=7
			local tar=unitatpos(self.sel.pos)
			if(tar)then
				selcol=8
			 if(tar.fact.name==afname)
				then selcol=10
				end
			end
			self.sel:draw(selcol)
		end
	}
end
__gfx__
00000000006070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000600607000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070006eeee700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700060eaae070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700006eeee700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000beeb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c5555cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15cccc5c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15155c5c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15155c5c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15111c5c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
115555cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000
10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000
10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000
10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000
10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000
10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000111111
10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000001111111111111000000
10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000011111111111110001000000000000000
10000000000000001000000000000000100000000000000010000000000000001000000000000000100011111111111110000000000000001000000000000000
10000000000000001000000000000000100000000000000010000000000000001000000111111111111100000000000010000000000000001000000000000000
10000000000000001000000000000000100000000000000010000000001111111111111000000000100000000000000010000000000000001000000000000000
10000000000000001000000000000000100000000000011111111111110000001000000000000000100000000000000010000000000000001000000000000111
10000000000000001000000000000000111111111111100010000000000000001000000000000000100000000000000010000000000000001000000111111000
10000000000000001000111111111111100000000000000010000000000000001000000000000000100000000000000010000000000000001111111000000000
10000001111111111111000000000000100000000000000010000000000000001000000000000000100000000000000010000000001111111000000000000000
11111110000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010001111110000001000000000000000
10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000011111110000000000001000000000000000
10000000000000001000000000000000100000000000000010000000000000001000000000000000100000011111100010000000000000001000000000000011
10000000000000001000000000000000100000000000000010000000000000001000000000000000111111100000000010000000000000001000000000111100
10000000000000001000000000000000100000000000000010000000000000001000000000111111100000000000000010000000000000001000001111000000
10000000000000001000000000000000100000000000000010000000000000001000111111000000100000000000000010000000000000001011110000000000
10000000000000001000000000000000100000000000000010000000000001111111000000000000100000000000000010000000000001111100000000000000
10000000000000001000000000000000100000000000000010000001111110001000000000000000100000000000000010000000011110001000000000000000
10000000000000001000000000000000100000000000000011111110000000001000000000000000100000000000000010000111100000001000000000000001
10000000000000001000000000000000100000000011111110000000000000001000000000000000100000000000000011111000000000001000000000001110
10000000000000001000000000000000100011111100000010000000000000001000000000000000100000000000111110000000000000001000000001110000
10000000000000001000000000000111111100000000000010000000000000001000000000000000100000001111000010000000000000001000011110000000
10000000000000001000000111111000100000000000000010000000000000001000000000000000100011110000000010000000000000001011100000000000
10000000000000001111111000000000100000000000000010000000000000001000000000000001111100000000000010000000000000011100000000000000
10000000001111111000000000000000100000000000000010000000000000001000000000011110100000000000000010000000000011101000000000000001
10001111110000001000000000000000100000000000000010000000000000001000000111100000100000000000000010000000011100001000000000000110
11110000000000001000000000000000100000000000000010000000000000001001111000000000100000000000000010000111100000001000000000111000
10000000000000001000000000000000100000000000000010000000000000111110000000000000100000000000000010111000000000001000000011000000
10000000000000001000000000000000100000000000000010000000001111001000000000000000100000000000000111000000000000001000011100000000
10000000000000001000000000000000100000000000000010000011110000001000000000000000100000000000111010000000000000001011100000000000
10000000000000001000000000000000100000000000000010111100000000001000000000000000100000000111000010000000000000001100000000000001
10000000000000001000000000000000100000000000011111000000000000001000000000000000100001111000000010000000000001111000000000000110
10000000000000001000000000000000100000000111100010000000000000001000000000000000101110000000000010000000000110001000000000011000
10000000000000001000000000000000100001111000000010000000000000001000000000000001110000000000000010000000111000001000000001100000
10000000000000001000000000000000111110000000000010000000000000001000000000001110100000000000000010000011000000001000000110000000
10000000000000001000000000001111100000000000000010000000000000001000000001110000100000000000000010011100000000001000011000000000
10000000000000001000000011110000100000000000000010000000000000001000011110000000100000000000000011100000000000001001100000000000
10000000000000001000111100000000100000000000000010000000000000001011100000000000100000000000001110000000000000001110000000000011
10000000000000011111000000000000100000000000000010000000000000011100000000000000100000000001110010000000000000111000000000001100
10000000000111101000000000000000100000000000000010000000000011101000000000000000100000000110000010000000000011001000000000110000
10000001111000001000000000000000100000000000000010000000011100001000000000000000100000111000000010000000001100001000000011000000
10011110000000001000000000000000100000000000000010000111100000001000000000000000100011000000000010000000110000001000001100000000
11100000000000001000000000000000100000000000000010111000000000001000000000000000111100000000000010000011000000001000010000000000
10000000000000001000000000000000100000000000000111000000000000001000000000000001100000000000000010001100000000001001100000000011
10000000000000001000000000000000100000000000111010000000000000001000000000001110100000000000000010110000000000001110000000000100
10000000000000001000000000000000100000000111000010000000000000001000000001110000100000000000000111000000000000011000000000011000
10000000000000001000000000000000100001111000000010000000000000001000000110000000100000000000011010000000000001101000000001100000
10000000000000001000000000000000101110000000000010000000000000001000111000000000100000000001100010000000000110001000000010000000
10000000000000001000000000000001110000000000000010000000000000001011000000000000100000000110000010000000001000001000001100000000
10000000000000001000000000001110100000000000000010000000000000011100000000000000100000011000000010000000110000001000010000000011
10000000000000001000000001110000100000000000000010000000000001101000000000000000100001100000000010000011000000001001100000000100
10000000000000001000011110000000100000000000000010000000001110001000000000000000100110000000000010001100000000001110000000001000
10000000000000001011100000000000100000000000000010000000110000001000000000000000111000000000000010110000000000001000000000110000
10000000000000011100000000000000100000000000000010000111000000001000000000000011100000000000000011000000000000111000000001000000
10000000000011101000000000000000100000000000000010111000000000001000000000001100100000000000000110000000000001001000000110000000
10000000011100001000000000000000100000000000000011000000000000001000000000110000100000000000011010000000000110001000001000000001
10000111100000001000000000000000100000000000011110000000000000001000000011000000100000000001100010000000011000001000110000000110
10111000000000001000000000000000100000000001100010000000000000001000001100000000100000000110000010000000100000001001000000001000
11000000000000001000000000000000100000001110000010000000000000001000110000000000100000011000000010000011000000001010000000010000
10000000000000001000000000000000100000110000000010000000000000001011000000000000100000100000000010000100000000001100000001100000
10000000000000001000000000000000100111000000000010000000000000011100000000000000100011000000000010011000000000011000000010000000
10000000000000001000000000000000111000000000000010000000000001101000000000000000101100000000000011100000000001101000000100000001
10000000000000001000000000000011100000000000000010000000000110001000000000000000110000000000000010000000000010001000001000000010
10000000000000001000000000011100100000000000000010000000011000001000000000000011100000000000001110000000001100001000110000001100
10000000000000001000000001100000100000000000000010000001100000001000000000001100100000000000010010000000010000001001000000010000
10000000000000001000001110000000100000000000000010000110000000001000000000010000100000000001100010000000100000001010000000100000
10000000000000001000110000000000100000000000000010011000000000001000000001100000100000000110000010000011000000001100000001000000
10000000000000001111000000000000100000000000000011100000000000001000000110000000100000001000000010000100000000011000000010000001
10000000000000011000000000000000100000000000001110000000000000001000011000000000100000110000000010011000000000101000000100000010
10000000000011101000000000000000100000000000110010000000000000001001100000000000100001000000000010100000000001001000011000000100
10000000011100001000000000000000100000000011000010000000000000001110000000000000100110000000000011000000000110001000100000001000
10000001100000001000000000000000100000001100000010000000000000001000000000000000111000000000000110000000001000001001000000010000
10001110000000001000000000000000100000110000000010000000000000111000000000000000100000000000001010000000010000001010000000100000
10110000000000001000000000000000100011000000000010000000000011001000000000000011100000000000110010000000100000001100000001000001
11000000000000001000000000000000101100000000000010000000001100001000000000000100100000000001000010000011000000001000000110000010
10000000000000001000000000000001110000000000000010000000110000001000000000011000100000000110000010000100000000111000001000000100
10000000000000001000000000000110100000000000000010000011000000001000000001100000100000001000000010001000000001001000010000001000
10000000000000001000000000011000100000000000000010000100000000001000000010000000100000010000000010110000000010001000100000010000
10000000000000001000000001100000100000000000000010011000000000001000001100000000100001100000000011000000000100001001000000100000
10000000000000001000000110000000100000000000000011100000000000001000010000000000100010000000000010000000001000001010000001000001
10000000000000001000011000000000100000000000000110000000000000001001100000000000101100000000000110000000010000001100000010000010
10000000000000001001100000000000100000000000011010000000000000001110000000000000110000000000011010000001100000001000000100000100
10000000000000001110000000000000100000000001100010000000000000001000000000000001100000000000100010000010000000011000001000001000
10000000000000111000000000000000100000000010000010000000000000111000000000000010100000000001000010000100000000101000010000010000
10000000000011001000000000000000100000001100000010000000000001001000000000000100100000000110000010001000000001001000100000010000
10000000001100001000000000000000100000110000000010000000000110001000000000011000100000001000000010010000000010001001000000100001
10000000110000001000000000000000100011000000000010000000011000001000000000100000100000010000000010100000000100001010000001000010
10000011000000001000000000000000101100000000000010000000100000001000000011000000100000100000000011000000001000001100000010000100
10001100000000001000000000000000110000000000000010000011000000001000000100000000100011000000000110000000010000001000000100000100
10110000000000001000000000000001100000000000000010000100000000001000011000000000100100000000001010000001100000011000001000001000
11000000000000001000000000000110100000000000000010011000000000001000100000000000101000000000010010000010000000101000010000010000
10000000000000001000000000011000100000000000000011100000000000001001000000000000110000000000100010000100000001001000100000100000
10000000000000001000000001100000100000000000000010000000000000001110000000000001100000000001000010001000000010001001000001000000
10000000000000001000000110000000100000000000001110000000000000001000000000000010100000000010000010010000000100001010000010000000
10000000000000001000001000000000100000000000010010000000000000111000000000000100100000001100000010100000001000001100000100000000
10000000000000001000110000000000100000000001100010000000000001001000000000011000100000010000000011000000010000001000000100000000
10000000000000001011000000000000100000000110000010000000000010001000000000100000100000100000000010000000100000001000001000000000
10000000000000001100000000000000100000001000000010000000001100001000000001000000100001000000000110000001000000011000010000000000
10000000000000111000000000000000100000110000000010000000010000001000000010000000100010000000001010000010000000101000100000000000
10000000000011001000000000000000100001000000000010000001100000001000001100000000100100000000010010000100000001001001000000000000
10000000000100001000000000000000100110000000000010000010000000001000010000000000111000000000100010001000000010001010000000000000
10000000011000001000000000000000111000000000000010001100000000001000100000000000100000000001000010010000000100001100000000000000
10000001100000001000000000000000100000000000000010010000000000001011000000000001100000000010000010100000001000001100000000000000
10000110000000001000000000000011100000000000000010100000000000001100000000000010100000000100000011000000010000001000000000000000
10011000000000001000000000000100100000000000000011000000000000001000000000000100100000011000000010000000100000011000000000000000
11100000000000001000000000011000100000000000000110000000000000011000000000001000100000100000000010000001000000101000000000000000
10000000000000001000000001100000100000000000011010000000000001101000000000110000100001000000000110000010000001001000000000000000
10000000000000001000000010000000100000000000100010000000000010001000000001000000100010000000001010000100000010001000000000000000
10000000000000001000001100000000100000000011000010000000000100001000000010000000100100000000010010000100000010001000000000000000
10000000000000001000010000000000100000000100000010000000011000001000000100000000101000000000100010001000000100001000000000000000
10000000000000001001100000000000100000001000000010000000100000001000001000000000110000000001000010010000001000001000000000000000
10000000000000001110000000000000100000110000000010000001000000001000010000000000100000000010000010100000010000001000000000000000
10000000000000001000000000000000100001000000000010000010000000001001100000000001100000000100000011000000100000001000000000000000
10000000000000111000000000000000100110000000000010001100000000001010000000000010100000001000000010000001000000001000000000000000
10000000000001001000000000000000101000000000000010010000000000001100000000000100100000010000000110000010000000001000000000000000
10000000000110001000000000000000110000000000000010100000000000001000000000001000100000100000001010000010000000001000000000000000
10000000011000001000000000000001100000000000000011000000000000011000000000010000100001000000010010000100000000001000000000000000
10000000100000001000000000000010100000000000000110000000000000101000000000100000100010000000100010001000000000001000000000000000
10000011000000001000000000001100100000000000001010000000000011001000000001000000100100000001000010010000000000001000000000000000
10000100000000001000000000010000100000000000010010000000000100001000000110000000101000000001000010100000000000001000000000000000
10011000000000001000000001100000100000000001100010000000001000001000001000000000110000000010000011000000000000001000000000000000
11100000000000001000000010000000100000000010000010000000010000001000010000000000100000000100000010000000000000001000000000000000

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
