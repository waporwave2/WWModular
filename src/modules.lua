--modules

-- approximation tables for speed:
-- https://www.desmos.com/calculator/cesdhphb2v
-- 4096 entries, 80kb

local sintab = {}
local atanish_tab = {}
for i=0,0x.fff,0x.001 do
  sintab[i] = sin(i)
  atanish_tab[i] = atan2(i,0.25)*4-3
end

function new_saw()
  return new_module{
  saveid="saw",
  name="saw ∧",
  phase=0,
  iname=split"frq",
  oname=split"out",
  step=function(self)
    local p=phzstep(self.phase,mem[self.frq])
    self.phase=p
    mem[self.out]=p
  end
  }
end

function new_tri()
  return new_module{
  saveid="tri",
  name="tri ⧗",--name
  iname=split"frq",
  oname=split"out",
  phase=0,--code
  step=function(self)
    --[[
    self.phase=phzstep(self.phase,mem[self.frq])
    mem[self.out]=abs(self.phase)*2-1
    --]]
    -- [[
    local p=phzstep(self.phase,mem[self.frq])
    self.phase=p
    mem[self.out]=( (p^^(p>>31)) <<1)-1
    --]]
  end
  }
end

function new_sine()
  return new_module{
  saveid="sin",
  name="sin …",
  phase=0,
  iname=split"frq",
  oname=split"out",
  step=function(self)
    --[[
    self.phase=phzstep(self.phase,mem[self.frq])
    mem[self.out]=sin(self.phase/2)
    --]]
    -- [[
    local p=phzstep(self.phase,mem[self.frq])
    self.phase=p
    mem[self.out]=sintab[(p>>1)&0x.fff]
    --]]
  end
  }
end

function new_adsr()
  return new_module{
  saveid="adsr",
  name="adsr",
  state=0,
  iname=split"atk,dec,sus,rel,gat",
  oname=split"out",
  hasgat=true,
  -- prop={"gattrg"},
  -- propfunc=function(self,i)
  --   self.hasgat=not self.hasgat
  -- end,
  step=function(self)
    -- want attack duration to range between 1 sample -> 5512 samples
    -- so the out increment ranges 1 -> 1/5512
    -- so... atk=-1 maps to incr=1/1
    --   and atk=1 maps to incr=1/5512
    -- so incr = 1/(1+5511*(atk+1)/2)
    --    incr = 1/(2755.5*atk+2756.5)
    -- then turning the knob linearly will the change the attack duration linearly
    -- \o/

    local out=mem[self.out]
    if self.state==0 then
      -- release
      out-=1/(2755.5*mem[self.rel]+2756.5)
      if mem[self.gat]>0 then
        self.state=1
      end
    elseif self.state==1 then
      -- attack
      out+=1/(2755.5*mem[self.atk]+2756.5)
      if mem[self.gat]<=0 and self.hasgat then
        self.state=0
      end
      if out>=1 then
        self.state=2
      end
    elseif self.state==2 then
      -- decay (or sustain)
      out-=1/(2755.5*mem[self.dec]+2756.5)
      if mem[self.gat]<=0 and self.hasgat then
        self.state=0
      end
      if out<mem[self.sus] then
        -- sustain
        out=mem[self.sus]
      end
    end
    mem[self.out]=mid(-1,out,1)
  end
  }
end

function new_lfo()
  return new_module{
  saveid="lfo",
  name="lfo …",
  phase=0,
  iname=split"frq",
  oname=split"out",
  step=function(self)
    --[[
    self.phase=phzstep(self.phase,(mem[self.frq]-255)/256)
    mem[self.out]=sin(self.phase/2)
    --]]
    -- [[
    local p=phzstep(self.phase,(mem[self.frq]-255)>>8)
    self.phase=p
    mem[self.out]=sintab[(p>>1)&0x.fff]
    --]]
  end
  }
end

function new_square()
  return new_module{
  saveid="square",
  name="sqr ░",
  phase=0,
  iname=split"frq,len",
  oname=split"out",
  step=function(self)
    --[[
    self.phase=phzstep(self.phase,mem[self.frq])
    mem[self.out]=sgn(p+mem[self.len])
    --]]
    -- [[
    local p=phzstep(self.phase,mem[self.frq])
    self.phase=p
    mem[self.out]=1+((p+mem[self.len])>>31<<17)
    --]]
  end
  }
end

function new_speaker()
  return new_module{
  saveid="speaker",
  name="speaker",
  undeletable=true,
  x=91,
  y=85,
  iname=split"inp,spd",
  oname={},
  -- step=function(self) end,
  custom_render=function(self)
    spr(20,self.x+21,self.y+6,1.125,1)
  end,
  custom_import=function(self)
    speaker=self
  end,
  }
end

function new_dist()
  return new_module{
  saveid="dist",
  name="dist",
  iname=split"inp,mod",
  oname=split"out",
  step=function(self)
    --[[
    if mem[self.mod]>0 then
      mem[self.out]=(mem[self.inp]+1)%2-1
    else
      mem[self.out]=atan2(mem[self.inp],.25)*4-3
    end
    --]]
    -- [[
    if mem[self.mod]>0 then
      mem[self.out]=((mem[self.inp]+1)&0x1.ffff)-1
    else
      -- atan2(x=x,y=0.25) approximation: https://www.desmos.com/calculator/cesdhphb2v
      -- alternate: https://yal.cc/fast-atan2/
      mem[self.out]=atanish_tab(mem[self.inp]&0x.fff)
    end
    --]]
  end
  }
end

function new_mixer()
  return new_module{
  saveid="mixer",
  name="mixer",
  iname=split"1,5,2,6", --split"1,5,2,6,3,7,4,8",
  iname_user=split"in,vol,in,vol,in,vol,in,vol",
  oname=split"out",
  prop=split"addrow,delrow",
  propfunc=function(self,i)
    local num=#self.iname\2
    if i==1 then
      if num<4 then
        num+=1
        addall(self.iname,num,num+4)
        addall(self.iname_user,"in","vol")
        self[num]=0
        self[num+4]=0
      end
    elseif num>1 then
      for _=0,1 do
        delwire(wirex(self,3,#self.iname))
        -- old inputs stick around in memory, but will be reset when re-added
        deli(self.iname)
        deli(self.iname_user)
      end
    end
  end,
  step=function(self)
    local out=0
    for ix=1,#self.iname\2 do
      -- in*(vol+1)/2
      out+=mem[self[ix]]*((mem[self[ix+4]]+1)>>1)
    end
    mem[self.out]=out
  end,
  custom_export=function(self)
    return #self.iname
  end,
  custom_import=function(self,num_iname)
    if num_iname==2 then
      self:propfunc(2)
    else
      for i=1,(num_iname/2-2) do
        self:propfunc(1)
      end
    end
  end,
  }
end

function new_leftbar()
  return new_module{
  saveid="leftbar",
  name="\-xtrk",
  ungrabable=true,
  undeletable=true,
  x=-17,
  y=5,
  iname={},
  oname=split"1,7,2,8,3,9,4,10,5,11,6,12,btx,btz", --careful; can't call btx just "x" or it will overwrite position data!
  oname_user=split"t1,gat,t2,gat,t3,gat,t4,gat,t5,gat,t6,gat,x,z",
  -- step=function(self) end,
  custom_import=function(self)
    leftbar=self
  end,
  }
end

function new_delay()
  return new_module{
  saveid="delay",
  name="delay",
  iname=split"inp,len",
  oname=split"out",
  buffer={},
  bufp=1,
  step=function(self)
    local buffer,bufp=self.buffer,self.bufp
    for x=1,5512-#buffer do
      add(buffer,0)
    end
    buffer[bufp]=mem[self.inp]
    local lenf=mid(1,5512,(mem[self.len]+1)*2754+4)&-1
    -- bufp+=1
    -- bufp=(bufp-1)%lenf+1
    bufp=bufp%lenf+1
    mem[self.out]=buffer[bufp]
    self.buffer,self.bufp=buffer,bufp
  end
  }
end

function new_knobs()
  return new_module{
  saveid="knobs",
  name="knobs",
  iname={},
  oname_user=split"nob,nob,nob,nob",
  oname=split"1,2,3,4",
  -- startp=nil,
  -- knobval=nil,--original value
  -- knobaddr=nil,
  custom_render=function(self)
    for ix=1,4 do
      local xx,yy,ang=self.x+4.5+(1-ix&1)*8,self.y+4.5+4*ix,mem[self[ix]]/2.5+0.275
      if hqmode then
        circfill(xx,yy,3,6)
        line(xx,yy,xx-cos(ang)*2.8,yy+sin(ang)*2.8,7)
        circ(xx,yy,3,1)
      else
        line(xx,yy,xx-cos(ang)*2.8,yy+sin(ang)*2.8,7)
      end
    end
  end,
  custom_input=function(self)
    if mbtnp(0) then
      for ix=1,4 do
        local dx,dy=self.x+4+(1-ix&1)*8-mx,self.y+4+4*ix-my
        if dx*dx+dy*dy<9 then
          self.startp=mx
          self.knobaddr=self[ix]
          self.knobval=mem[self.knobaddr]
        end
      end
    end
    if mbtn(0) and self.knobaddr then
      mem[self.knobaddr]=mid(-1,1,self.knobval+(mx-self.startp)/36)
    else
      self.knobaddr=nil
    end
    return self.knobaddr -- return truthy if input was consumed
  end,
  custom_export=function(self)
    local s=""
    for ix=1,4 do
      s..=tostr(mem[self[ix]],1)..":"
    end
    -- note: this will leave a trailing :, but it's fine
    return s
  end,
  custom_import=function(self,k1,k2,k3,k4)
    mem[self[1]],mem[self[2]],mem[self[3]],mem[self[4]]=k1,k2,k3,k4
  end,
  }
end

function new_hold()
  return new_module{
  saveid="hold",
  name="hold",
  iname=split"inp,len",
  oname=split"out",
  oldinp=0,
  count=5512,
  step=function(self)
    local lenf=mid(1,5512,(mem[self.len]+1)*2755.5+1)&-1
    local inp=mem[self.inp]
    if self.count<lenf then
      self.count+=1
    else
      if self.oldinp!=inp then
        self.count=0
      end
      mem[self.out]=inp
    end
    self.oldinp=inp
  end
  }
end

function new_glide()
  return new_module{
  saveid="glide",
  name="glide",
  iname=split"inp,rat",
  oname=split"out",
  step=function(self)
    local target,now=mem[self.inp],mem[self.out]
    local inc=(mem[self.rat]+1)/10
    inc*=inc
    inc*=inc -- 4th power
    mem[self.out]=mid(target,now-inc,now+inc) --approach target
  end
  }
end

function new_maths()
  return new_module{
  saveid="maths",
  name="maths",
  iname=split"a,b",
  oname_user=split"-a,a*b",
  oname=split"inv,frq",
  step=function(self)
    local a,b=mem[self.a],mem[self.b]
    mem[self.inv]=-a
    mem[self.frq]=a*b+a+b
  end
  }
end

function new_filter()
  return new_module{
  saveid="filter",
  name="filter",
  iname=split"inp,res,frq",
  oname=split"lo,bnd,hi,ntc",
  step=function(self)
    -- local f=-2*sin(mem[self.frq]+1>>4)--who really knows?
    local f=-2*sintab[(mem[self.frq]+1>>4)&0x.fff]--who really knows?
    local q=(1.1-mem[self.res])*0.248756218905--resonance/bandwidth what the hell is bandwidth?
    local self_bnd,self_lo=self.bnd,self.lo
    local bpf=mem[self_bnd]
    local lpf=mem[self_lo]+f*bpf --low=low+f*band
    local hpf=mem[self.inp]-lpf-q*bpf --scale*input-low-q*band what the hell is scale? "scale=q"
    mem[self_bnd]=f*hpf+bpf --f*high+band
    mem[self.ntc]=hpf+lpf --high+low
    mem[self_lo],mem[self.hi]=lpf,hpf
  end
  }
end

function new_noise()
  return new_module{
  saveid="noise",
  name="noise",
  iname=split"len",
  oname=split"out",
  s=0,
  step=function(self)
    local len=(mem[self.len]+1)>>1
    len*=len
    len*=len -- 4th power
    local lenf=mid(1,5512,len*5511+1)&-1
    local s=(self.s+1)%lenf
    if(s==0)mem[self.out]=rnd(2)-1
    self.s=s
  end
  }
end

function new_sample()
  return new_module{
  saveid="sample",
  name="sample",
  iname=split"smp,gat,lup,frq",
  oname=split"out",
  s=0,
  n=2,
  oldgat=0,
  step=function(self)
    local lup=mem[self.lup]
    local n=mid(1,#samples,(((mem[self.smp]+1)*#samples)>>1)+1)&-1
    local sm=samples[n]
    local len_sm=#sm
    local gat=mem[self.gat]
    local s=self.s
    if self.n!=n then
      s=len_sm
      self.n=n
    end
    if gat>0 and self.oldgat!=gat then
      s=0
      self.oldgat=gat
    end
    if s<len_sm then
      mem[self.out]=ord(sm,s\1+1,1)/127.5-1
      s+=(mid(-1,1,mem[self.frq])+1)<<2
    end
    if lup<1 then
      s%=len_sm*mid(.01,(lup+1)>>1,.99)
    end
    self.s=s
  end
  }
end

local synth_plus_wavetable = {
  function(p) return sintab[(p>>1)&0x.fff] end, --sin(self.phase/2),
  function(p) return ( (p^^(p>>31)) <<1)-1 end, --abs(self.phase)*2-1,
  function(p) return p end, --self.phase,
  function(p) return 1+(p>>31<<17) end, --sgn(self.phase),
}
function new_synth_plus()
  return new_module{
  saveid="synth_plus",
  name="synth+",
  phase=0,
  envelope=-1,
  hpf=0,
  bpf=0,
  iname=split"frq,wav,atk,rel,res,gat",
  oname=split"out",
  step=function(self)
    --[[
    --wave
    self.phase=phzstep(self.phase,mem[self.frq])
    local wavetable = {sin(self.phase/2),abs(self.phase)*2-1,self.phase,sgn(self.phase)}
    local wav = mid(1,4,mem[self.wav]*1.5+2.5)
    local final = lerp(wavetable[flr(wav)],wavetable[ceil(wav)],wav%1)
    --]]
    -- [[
    local final
    do --wave
      local p=phzstep(self.phase,mem[self.frq])
      self.phase=p

      local wav=mid(1,4,mem[self.wav]*1.5+2.5)
      local a=synth_plus_wavetable[wav&-1](p) --flr(wav)
      local b=synth_plus_wavetable[-(-wav&-1)](p) --ceil(wav)
      final=a+(b-a)*(wav&0x.ffff) --lerp
    end
    --]]

    --envelope
    local envelope=self.envelope
    if mem[self.gat]>0 then
      envelope+=1/(2755.5*mem[self.atk]+2756.5)
    else
      envelope-=1/(2755.5*mem[self.rel]+2756.5)
    end
    envelope=envelope/0x.0002*0x.0002 -- envelope=mid(-1,0x.ffff,envelope)

    --filter; see new_filter().step
    local f=-2*sintab[(envelope+1>>4)&0x.fff]--who really knows?
    local q=(1.1-mem[self.res])*0.248756218905--resonance/bandwidth what the hell is bandwidth?
    local bpf=self.bpf
    local self_out=self.out
    local lpf=mem[self_out]+f*bpf --low=low+f*band
    local hpf=final-lpf-q*bpf --scale*input-low-q*band what the hell is scale? "scale=q"
    self.bpf=f*hpf+bpf --f*high+band
    self.hpf=hpf
    if (envelope==-1) lpf=0
    mem[self_out]=lpf
    self.envelope=envelope
  end
  }
end

modmenu=split"saw,sin,square,tri,synth+,mixer,dist,lfo,adsr,delay,knobs,hold,glide,maths,filter,noise,sample"
modmenufunc={
  new_saw,
  new_sine,
  new_square,
  new_tri,
  new_synth_plus,
  new_mixer,
  new_dist,
  new_lfo,
  new_adsr,
  new_delay,
  new_knobs,
  new_hold,
  new_glide,
  new_maths,
  new_filter,
  new_noise,
  new_sample,
}

-- used by the loading system
all_module_makers={
  saw=new_saw,
  tri=new_tri,
  synth_plus=new_synth_plus,
  sine=new_sine, -- backwards compat; delete this line if necessary
  sin=new_sine,
  adsr=new_adsr,
  lfo=new_lfo,
  square=new_square,
  speaker=new_speaker,
  dist=new_dist,
  clip=new_dist, -- backwards compat
  mixer=new_mixer,
  leftbar=new_leftbar,
  delay=new_delay,
  knobs=new_knobs,
  hold=new_hold,
  glide=new_glide,
  maths=new_maths,
  filter=new_filter,
  noise=new_noise,
  sample=new_sample,
}



-- attach mod inputs/outputs and
-- add it to the list of modules
function new_module(mod)
  -- i/o are name=>address mappings;
  -- the name is from mod.iname/oname
  -- the address is an index in mem
  -- these mappings get added to the mod object itself
  -- note: output addresses are unique; input address get assigned to already-existing output addresses (see addwire())
  for name in all(mod.iname) do
    assert(not mod[name],"iname is not unique: "..name)
    mod[name]=0 -- modmem[0] is always 0
  end
  for name in all(mod.oname) do
    assert(not mod[name],"oname is not unique: "..name)
    add(mem,0)
    mod[name]=#mem
  end
  return add(modules,mod)
end

function nth_inaddr(mod,ix)
  return mod[mod.iname[ix]]
end
function nth_outaddr(mod,ix)
  return mod[mod.oname[ix]]
end

-- returns whether any module consumed the LMB input
function module_custom_input()
  for mod in all(modules) do
    if mod.custom_input and mod:custom_input() then
      return true
    end
  end
end
