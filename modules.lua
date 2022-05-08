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
      out-=(((mem[self.rel]+1)*8)^2)/1024
    elseif self.state==1 then
      out+=(((mem[self.atk]+1)*8)^2)/1024
    elseif self.state==2 then
      out-=(((mem[self.dec]+1)*8)^2)/1024
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
  iname=split"in_1,vol_1,in_2,vol_2",
  oname=split"out",
  -- TODO fix this for new mem i/o system
  -- prop=split"addrow,delrow",
  -- propfunc=function(self,i)
  --   if i==1 then
  --     if #self.i<8 then
  --       add(self.iname,"in")
  --       add(self.iname,"vol")
  --       add(self.i,0)
  --       add(self.i,0)
  --     end
  --   elseif #self.i>2 then
  --     for x=1,2 do
  --       local ix=wirex(self,3,#self.i)
  --       if ix>0then
  --         delwire(ix)
  --       end
  --       deli(self.i)
  --       deli(self.iname)
  --     end
  --   end
  -- end,
  step=function(self)
    local out=0
    for x=1,#self.iname,2 do
      out+=temp_read_i(self,x)*(temp_read_i(self,x+1)+1)/2
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
  oname=split"t1,gat_1,t2,gat_2,t3,gat_3,t4,gat_4,t5,gat_5,t6,gat_6,btx,btz", --careful; can't call btx just "x" or it will overwrite position data!
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
  oname=split"nob_1,nob_2,nob_3,nob_4",
  startp=0,
  knobanch=0,--original value
  knobind=0,
  custom_render=function(self)
    for i=0,3 do
      local val=temp_read_o(self,i+1)
      if hqmode then
        circfill(self.x+7,self.y+8+8*i,3,6)
        line(self.x+7.5,self.y+8.5+8*i,self.x+7.5-cos((val+1)/2.5-.125)*2.8,self.y+8.5+8*i+sin((val+1)/2.5-.125)*2.8,7)
        circ(self.x+7,self.y+8+8*i,3,1)
      else
        line(self.x+7.5,self.y+8.5+8*i,self.x+7.5-cos((val+1)/2.5-.125)*2.8,self.y+8.5+8*i+sin((val+1)/2.5-.125)*2.8,7)
      end
    end
  end,
  custom_input=function(self)
    if mbtnp(0) then
      for i=0,3 do
        if (self.x+7-mx)^2+(self.y+8+8*i-my)^2 < 9 then
          self.startp=mx
          self.knobanch=temp_read_o(self,i+1)
          self.knobind=i+1
        end
      end
    end
    if mbtn(0) and self.knobind !=0 and (io_override==self or io_override==nil) then
      io_override=self
      temp_write_o(self,knobind,mid(-1,self.knobanch+(mx-self.startp)/24,1))
    else
      if io_override==self then
        io_override=nil
      end
      self.knobind=0
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
    local inc=((mem[self.len]+1)/10)^4
    mem[self.out]=now<target and min(now+inc,target) or max(now-inc,target)
  end
  }
end

function new_maths()
  return new_module{
  saveid="maths",
  name="maths",
  iname=split"a,b",
  oname=split"a*b,a+b,frq",
  step=function(self)
    local a,b=mem[self.a],mem[self.b]
    local prod,sum=a*b,a+b
    mem[self["a*b"]]=prod
    mem[self["a+b"]]=sum
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
    local fs=2--sampling frequency
    local fc=(mem[self.frq]+1)/4--cutoff
    local f=2.0*-sin(.5*(fc/(fs)))--who really knows?
    local q=((1-mem[self.res])+.1)*0.248756218905--resonance/bandwidth what the hell is bandwidth?
    local lpf,hpf,bpf,notch,inp=mem[self.lo],mem[self.hi],mem[self.bnd],mem[self.ntc],mem[self.inp]
    lpf=lpf+f*bpf;--low=low+f*band
    hpf=inp-lpf-q*bpf;--scale*input-low-q*band what the hell is scale? "scale=q"
    bpf=f*hpf+bpf;--f*high+band
    notch=hpf+lpf;--high+low
    mem[self.lo],mem[self.hi],mem[self.bnd],mem[self.ntc]=lpf,hpf,bpf,notch
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
    local lenf=mid(1,5512,flr((((mem[self.len]+1)/2)^4)*5511+1))
    self.s+=1
    self.s%=lenf
    if(self.s==0)mem[self.out]=rnd(2)-1
  end
  }
end

modmenu=split"saw,sin,square,mixer,tri,clip,lfo,adsr,delay,knobs,hold,glide,maths,filter,noise"
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
}
