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
local pgmode,   rec,playing,tracker_mode=0

-- each wire is {from_mod,from_port_ix, to_mod,to_port_ix, value}
--held: nil, or module index we're holding right now
--con: module we're dragging a wire from right now
--conin: boolean to do with dragging wires
--conid: which port on con we're interacting with
local selectedmod,conid,concol,conin,   con,held=unpacksplit"-1,0,3,1"
local rcpx,rcpy,rcpyc,anchorx,anchory=unpacksplit"0,0,0,0"
local samples=split"~,~,~,~,~,~,~,~"
-- io_override: custom module interaction
-- hqmode: performance mode for rendering
-- speaker/leftbar: references to specific modules
local cpuusage,samplesel,hqmode,   projid,io_override,rcmenu,rcfunc,speaker,leftbar=unpacksplit"0,0,1"
