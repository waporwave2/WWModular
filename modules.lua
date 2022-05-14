--modules

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

-- temp functions; used mainly by
-- leftbar/tracker code for now
function temp_read_i(mod,iindex)
  return mem[mod[mod.iname[iindex]]]
end
function temp_read_o(mod,oindex)
  return mem[mod[mod.oname[oindex]]]
end
function temp_write_i(mod,iindex,val)
  mem[mod[mod.iname[iindex]]] = val
end
function temp_write_o(mod,oindex,val)
  mem[mod[mod.oname[oindex]]] = val
end



function new_saw()
  return new_module{
  saveid="saw",
  name="saw ∧",
  phase=0,
  iname=split"frq",
  oname=split"out",
  step=function(self)
    self.phase=phzstep(self.phase,mem[self.frq])
    mem[self.out]=self.phase
  end
  }
end

function new_tri()
  return new_module{
  saveid="tri",
  name="tri ∧",--name
  iname=split"frq",
  oname=split"out",
  phase=0,--code
  step=function(self)
    self.phase=phzstep(self.phase,mem[self.frq])
    mem[self.out]=abs(self.phase)*2-1
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
    self.phase=phzstep(self.phase,mem[self.frq])
    mem[self.out]=sin(self.phase/2)
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
    local out=mem[self.out]
    if self.state==0 then
      local rel=(mem[self.rel]+1)*8
      out-=rel*rel/1024
    elseif self.state==1 then
      local atk=(mem[self.atk]+1)*8
      out+=(atk*atk)/1024
    elseif self.state==2 then
      local dec=(mem[self.dec]+1)*8
      out-=(dec*dec)/1024
    end

    if mem[self.gat]>0 then
      if self.state==0 then self.state=1 end
    elseif self.state!=1 or self.hasgat then
      self.state=0
    end
    if out>=1 and self.state==1 then
      self.state=2
    end
    if out<=mem[self.sus] and self.state==2 then
      self.state=3
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
    self.phase=phzstep(self.phase,(mem[self.frq]-255)/256)
    mem[self.out]=sin(self.phase/2)
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
    self.phase=phzstep(self.phase,mem[self.frq])
    mem[self.out]=sgn(self.phase+mem[self.len])
  end
  }
end

function new_speaker()
  return new_module{
  saveid="speaker",
  name="output",
  undeletable=true,
  x=97,
  y=80,
  iname=split"inp,spd",
  oname={},
  step=function(self)

  end
  }
end

function new_clip()
  return new_module{
  saveid="clip",
  name="clip",
  iname=split"inp,sft",
  oname=split"out",
  step=function(self)
    if mem[self.sft]>0 then
      
    else
      mem[self.out]=mid(-1,mem[self.inp],1)
    end
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
        local ix=wirex(self,3,#self.iname)
        if ix>0then
          delwire(ix)
        end
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
      out+=mem[self[ix]]*(mem[self[ix+4]]+1)/2
    end
    mem[self.out]=out
  end
  }
end

function new_leftbar()
  return new_module{
  saveid="leftbar",
  name="\-vtrk",
  ungrabable=true,
  undeletable=true,
  x=-15,
  y=5,
  iname={},
  oname=split"1,7,2,8,3,9,4,10,5,11,6,12,btx,btz", --careful; can't call btx just "x" or it will overwrite position data!
  oname_user=split"t1,gat,t2,gat,t3,gat,t4,gat,t5,gat,t6,gat,x,z",
  step=function(self)

  end
  }
end

function new_delay()
  return new_module{
  saveid="delay",
  name="delay",
  iname=split"inp,len",
  oname=split"out",
  buffer={0},
  bufp=1,
  step=function(self)
      for x=1,5512-#self.buffer do
          add(self.buffer,0)
      end
      self.buffer[self.bufp]=mem[self.inp]
      self.bufp+=1
      local lenf=mid(3,5512,flr((mem[self.len]+1)*2754+4))
      self.bufp=(self.bufp-1)%lenf+1
      mem[self.out]=self.buffer[(self.bufp+lenf-1)%lenf+1]
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
      local xx,yy,ang=self.x+7.5,self.y+0.5+8*ix,mem[self[ix]]/2.5+0.275
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
        local dx,dy=self.x+7-mx,self.y+8*ix-my
        if dx*dx+dy*dy<9 then
          self.startp=mx
          self.knobaddr=self[ix]
          self.knobval=mem[self.knobaddr]
        end
      end
    end
    if mbtn(0) and self.knobaddr and (io_override==self or not io_override) then
      io_override=self
      mem[self.knobaddr]=mid(-1,1,self.knobval+(mx-self.startp)/24)
    else
      if io_override==self then
        io_override=nil
      end
      self.knobaddr=nil
    end
  end
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
      local lenf=mid(1,5512,flr((mem[self.len]+1)*2755.5+1))
      local inp=mem[self.inp]
      if self.count<lenf then
        self.count+=1
      else
        if self.oldinp != inp then
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
  iname=split"inp,len",
  oname=split"out",
  step=function(self)
    local target,now=mem[self.inp],mem[self.out]
    local inc=(mem[self.len]+1)/10
    inc*=inc
    inc*=inc -- 4th power
    mem[self.out]=now<target and min(now+inc,target) or max(now-inc,target)
  end
  }
end

function new_maths()
  return new_module{
  saveid="maths",
  name="maths",
  iname=split"a,b",
  oname_user=split"a*b,a+b,frq",
  oname=split"prod,sum,frq",
  step=function(self)
    local a,b=mem[self.a],mem[self.b]
    local prod,sum=a*b,a+b
    mem[self.prod]=prod
    mem[self.sum]=sum
    mem[self.frq]=prod+sum -- (a+1)*(b+1)-1  ==  a*b+a+b
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
    -- local fs=2--sampling frequency
    -- local fc=(mem[self.frq]+1)/4--cutoff
    -- local f=2.0*-sin(.5*(fc/(fs)))--who really knows?
    -- local q=((1-mem[self.res])+.1)*0.248756218905--resonance/bandwidth what the hell is bandwidth?
    -- local lpf,hpf,bpf,notch,inp=mem[self.lo],mem[self.hi],mem[self.bnd],mem[self.ntc],mem[self.inp]
    -- lpf=lpf+f*bpf;--low=low+f*band
    -- hpf=inp-lpf-q*bpf;--scale*input-low-q*band what the hell is scale? "scale=q"
    -- bpf=f*hpf+bpf;--f*high+band
    -- notch=hpf+lpf;--high+low
    -- mem[self.lo],mem[self.hi],mem[self.bnd],mem[self.ntc]=lpf,hpf,bpf,notch
    local f=-2*sin(mem[self.frq]+1>>4)--who really knows?
    local q=(1.1-mem[self.res])*0.248756218905--resonance/bandwidth what the hell is bandwidth?
    local bpf=mem[self.bnd]
    local lpf=mem[self.lo]+f*bpf;--low=low+f*band
    local hpf=mem[self.inp]-lpf-q*bpf;--scale*input-low-q*band what the hell is scale? "scale=q"
    mem[self.bnd]=f*hpf+bpf;--f*high+band
    mem[self.ntc]=hpf+lpf;--high+low
    mem[self.lo],mem[self.hi]=lpf,hpf
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
    local len=(mem[self.len]+1)/2
    len*=len
    len*=len -- 4th power
    local lenf=mid(1,5512,flr(len*5511+1))
    self.s+=1
    self.s%=lenf
    if(self.s==0)mem[self.out]=rnd(2)-1
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
    local n=mid(1,#samples,flr(((mem[self.smp]+1)*(#samples-1))/2+1))
    local sm=samples[n]
    local gat=mem[self.gat]
    if n!=self.n then
      self.s=#sm
      self.n=n
    end
    if gat>0 and self.oldgat!=gat then
      self.s=0
    end
    if self.s<#sm then
      mem[self.out]=ord(sm,flr(self.s)+1,1)/127.5-1
      self.s+=(mem[self.frq]+1)*4
    end
    if lup<1 then
      self.s%=#sm*mid(.01,(lup+1)/2,.99)
    end
    self.oldgat=gat
  end
  }
end

modmenu=split"saw,sin,square,mixer,tri,clip,lfo,adsr,delay,knobs,hold,glide,maths,filter,noise,sample"
modmenufunc={
  new_saw,
  new_sine,
  new_square,
  new_mixer,
  new_tri,
  new_clip,
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
  sine=new_sine, -- backwards compat; delete this line if necessary
  sin=new_sine,
  adsr=new_adsr,
  lfo=new_lfo,
  square=new_square,
  speaker=new_speaker,
  clip=new_clip,
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
