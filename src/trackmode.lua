--tracker
-- -1 to 1 to hz

local keys={}
for dat in all(split([[z,-0.937505972289,1
s,-0.933779264214,2
x,-0.929842331581,3
d,-0.925676063067,4
c,-0.921261347348,5
v,-0.916579073101,6
g,-0.911610129001,7
b,-0.90635451505,8
h,-0.900793119924,9
n,-0.894887720975,10
j,-0.888638318204,11
m,-0.882006688963,12
q,-0.874992833254,13
w,-0.859684663163,15
e,-0.842503583373,17
r,-0.833139034878,18
t,-0.8127090301,20
y,-0.789775441949,22
u,-0.76403248925,24
i,-0.750004777831,25
o,-0.719388437649,27
p,-0.68502627807,29
2,-0.867558528428,14
3,-0.851352126135,16
5,-0.823220258003,19
6,-0.801567128524,21
7,-0.777276636407,23
9,-0.73513616818,26
0,-0.702704252269,28]],"\n")) do
	local name,fr,id=unpacksplit(dat)
	local ascii=ord(name)
	local scancode=ascii==0x30 and 39 --0
			or 0x31<=ascii and ascii<0x40 and ascii-0x31+30 --123456789
			or ascii-0x61+4 -- a-z
	-- pq(name,ascii,scancode)
	keys[scancode]={fr,id} --frequency, id, was_down_last_frame=nil
end

local keyname=split"c,c+,d,d+,e,f,f+,g,g+,a,a+,b"

function ini_trackmode()
	upd,drw=upd_trackmode,drw_trackmode
	menuitems()
	if #page==0 then
		addpage()
	end
	-- we don't want to display the
	-- "devkit enabled" message until
	-- launching the tracker for the
	-- first time
	eat_keyboard=_real_eat_keyboard
end

function eat_keyboard()
end
function _real_eat_keyboard(allow_space)
	-- ignore most queued keyboard input
	while stat(30) do
		local ch=stat(31)
		if allow_space and ch==" " then
			toggle_playback()
		end
	end
end

function upd_trackmode()
	local bits = btnp()
	trkx+=bits\2%2-bits%2
	trky+=bits\8%2-bits\4%2
	trkx%=6
	trky%=16

	--gate and other buttons
	if topmenu_input() then
		--don't fall through
	elseif lmbp and rect_collide(2,120,96,7,mx,my) then
		local tk=mid(1,6,(mx-2)\16+1)
		pgtrg[tk]=not pgtrg[tk]
	elseif lmbp and rect_collide(96,10,31,23,mx,my) then
		local y=(my-10)\8
		if mx<=111 then
			if y==0 then
				oct-=1
			elseif y==1 then
				delpage(pg)
				pg-=1
			else
				pg-=1
			end
		else
			if y==0 then
				oct+=1
			elseif y==1 then
				addpage()
				pg+=1
			else
				pg+=1
			end
		end
		pg=(pg-1)%#page+1
		oct=mid(0,oct,4)
	end

	-- backspace, enter, tab
	while stat(30) do
		local ch=stat(31)
		if ch=="る" then
			--character recognized when clicking CTRL+C, will be changed with scancodes if we add that
			copiedpage=deepcopy(page[pg])
			toast("page copied")
		elseif ch=="コ" then
			--ditto for CTRL+V
			page[pg]=deepcopy(copiedpage)
			toast("page pasted")
		elseif ch=="\b" then
			for x=trky,15 do
				page[pg][trkx+1][x]=page[pg][trkx+1][x+1]
			end

			page[pg][trkx+1][16]=import_note(0,oct)
			trky-=1
			trky%=16
		elseif ch=="\r" or ch=="p" then
			poke(0x5f30,1) --prevent pause
			if ch=="\r" then
				for x=16,trky+2,-1 do
					page[pg][trkx+1][x]=page[pg][trkx+1][x-1]
				end

				page[pg][trkx+1][trky+1]=import_note(0,oct)
				trky+=1
				trky%=16
			end
		elseif ch=="\t" then
			trkx+=1
			trkx%=6
		elseif ch==" " then
			toggle_playback()
		end
	end

	-- read letters/numbers as piano keys,
	-- unless a modifier key is held down
	for scn=224,230 do
		if stat(28,scn) then
			return
		end
	end
	for scn,k in pairs(keys) do
		local down=stat(28,scn)
		local pressed=down and not k[3]
		k[3]=down
		if pressed then
			page[pg][trkx+1][trky+1]=key2note(k,oct)
			if not playing then
				-- write to t1, t2, t3, etc
				mem[leftbar[trkx+1]]=key2note(k,oct)[1]
			end
			trky+=1
			trky%=16
		end
	end
end

function key2note(k,octave)
	local f=(k[1]+1)*(2^octave)-1
	local nn=keyname[(k[2]-1)%12+1]..ceil(k[2]/12)+octave-1
	-- frequency, draw name, save data
	assert(k[2]<256,"need to change octave encoding")
	return {f,nn,k[2]+octave*256} -- frequency, name, savedata
end
function import_note(id,octave)
	if id==0 then return split"-2,--,0" end
	for _,k in pairs(keys) do
		if k[2]==id then return key2note(k,octave) end
	end
	toast("couldn't import_note "..tostr(id).." "..tostr(octave))
end

function pause()
	for ix=1,6 do
		mem[leftbar[ix+6]]=-1
	end
end

-- also used by import system
function addpage( pix,ids)
	local sheet={}
	page[pix or #page+1]=sheet
	local ii=0
	for _x=1,6 do
		local column=add(sheet,{})
		for _y=1,16 do
			ii+=1
			local dat=ids and ids[ii] or oct*256 --import_note(0,oct) when ids is nil
			add(column,import_note(dat&255,dat\256))
		end
	end
end

function delpage(ii)
	if(#page>1)deli(page,ii)
end

function drw_trackmode()
	cls(3)

	--top right menu
	--rectfill(95,0,128,8,0)
	sspr(0,8,32,64,95,9)
	sspr(96,8,32,120,96,8)
	?"oc- oc+",98,12,0
	?"pg- pg+",98,20,0
	?"pg< pg>",98,28,0

	--info
	rectfill(2,1,93,32,6)
	rectfill(3,2,92,31,0)
	print("waporware modular\na dsp synth toy.\ndesign,code: waporwave\n  fast code: pancelor"..(time()%1<.5 and "" or "█"),4,3,11)
	print("octave:"..oct.." page:"..pg,4,28,11)

	?"t1  t2  t3  t4  t5  t6",6,34,0
	rect(1,38,98,119,2)

	for x=0,5 do
		?pgtrg[x+1]and"trg"or"gat",x*16+4,122,0
		--trg gat buttons
		rectwh(17+x*16,120,1,6,4)
		rectwh(2+x*16,121,1,6,2)
		rectwh(2+x*16,126,15,1,2)
		rectwh(3+x*16,120,14,1,4)
		for y=0,15 do
			rectfillwh(x*16+2,y*5+39,16,5,(trkx==x and trky==y)and 13or((y+x)%2)*5+1)
			local ch=page[pg][x+1][y+1][2]
			?ch,x*16+3,y*5+40,0
		end
	end
	rectwh(1,trkp\1*5+39,1,5,10)

	draw_toprightmenu()
end
