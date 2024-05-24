function unpacksplit(...)
	return unpack(split(...))
end

-- mem: memory for module io values
local mem,modmenu,modmenufunc,modprop,modpropfunc,oscbuf,modules,wires={[0]=0},{},{},{},{},{},{},{}

--tracker
local trkx,trky,trkp,pg,oct=unpacksplit"0,0,0,1,1"
local page={}
local pgtrg={false,false,false,false,false,false}

--top menu
local pgmode,   rec,playing=0

-- each wire is {from_mod,from_port_ix, to_mod,to_port_ix, value}
--held: nil, or module index we're holding right now
--con: module we're dragging a wire from right now
--conin: boolean to do with dragging wires
--conid: which port on con we're interacting with
local selectedmod,conid,concol,conin,   con,held=unpacksplit"-1,0,3,1"
local rcpx,rcpy,rcpyc,anchorx,anchory=unpacksplit"0,0,0,0"
local samples=split"~,~,~,~,~,~,~,~"
local _sample_cachedraw={} --see drw_samplemode()
-- hqmode: performance mode for rendering
-- speaker/leftbar: references to specific modules
local cpuusage,hqmode,   projid,rcmenu,rcfunc,speaker,leftbar=unpacksplit"0,1"
--fillpatterns
local fills=split"0,0X8000,0X8020,0XA020,0XA0A0,0XA4A0,0XA4A1,0XA5A1,0XA5A5,0XE5A5,0XE5B5,0XF5B5,0XF5F5,0XFDF5,0XFDF7,0XFFF7,0XFFFF"
local wirecols=split"0x8F,0xA9,0x5E,0xBE"
--tracker clipboard, we could copy to actual clipboard? but this way seems a bit nicer,
--and doesn't overwrite your actual clipboard, especially for exporting on web version
local copiedpage
local upd,drw
