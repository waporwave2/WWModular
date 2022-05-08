--modules

function new_module(mod)
  -- advance nextmodaddr by 4 each time,
  -- so modules can store pass full 16.16 numbers
  -- to each other. todo: can/should this be reduced?
  mod.i={}
  for _=1,#mod.iname do
    add(mod.o,0)
    add(mod.i,nextmodaddr)
    nextmodaddr+=4
  end
  return add(modules,mod)
end

function new_saw()
  return new_module{
  saveid="saw",
  name="saw ∧",
  phase=0,
  iname=split"frq",
  oname=split"out",
  step=function(self)
    self.phase=phzstep(self.phase,self.i[1])
    self.o[1]=self.phase
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
    self.phase=phzstep(self.phase,self.i[1])
    self.o[1]=abs(self.phase)*2-1
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
    self.phase=phzstep(self.phase,self.i[1])
    self.o[1]=sin(self.phase/2)
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
  -- o={-1},
  gat=true,
  --prop={"gattrg"},
  propfunc=function(self,i)
    self.gat=not self.gat
  end,
  step=function(self)
    if self.state==0 then
      self.o[1]-=(((self.i[4]+1)*8)^2)/1024
    elseif self.state==1 then
      self.o[1]+=(((self.i[1]+1)*8)^2)/1024
    elseif self.state==2 then
      self.o[1]-=(((self.i[2]+1)*8)^2)/1024
    end

    if self.i[5]>0 then
      if self.state==0 then self.state=1 end
    elseif self.state!=1 or self.gat then
      self.state=0
    end
    if self.o[1]>=1 and self.state==1 then
      self.state=2
    end
    if self.o[1]<=self.i[3] and self.state==2 then
      self.state=3
    end
    self.o[1]=mid(-1,self.o[1],1)
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
    self.phase=phzstep(self.phase,(self.i[1]-255)/256)
    self.o[1]=sin(self.phase/2)
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
    self.phase=phzstep(self.phase,self.i[1])
    self.o[1]=sgn(self.phase+self.i[2])
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
    if self.i[2]>0 then
      
    else
      self.o[1]=mid(-1,self.i[1],1)
    end
  end
  }
end

function new_mixer()
  return new_module{
  saveid="mixer",
  name="mixer",
  iname=split"in,vol,in,vol",
  oname=split"out",
  prop=split"addrow,delrow",
  propfunc=function(self,i)
    if i==1 then
      if #self.i<8 then
        add(self.iname,"in")
        add(self.iname,"vol")
        add(self.i,0)
        add(self.i,0)
      end
    elseif #self.i>2 then
      for x=1,2 do
        local ix=wirex(self,3,#self.i)
        if ix>0then
          delwire(ix)
        end
        deli(self.i)
        deli(self.iname)
      end
    end
  end,
  step=function(self)
    local o=0
    for x=1,#self.i,2 do
      o+=self.i[x]*(self.i[x+1]+1)/2
    end
    self.o[1]=o
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
  oname=split"t1,gat,t2,gat,t3,gat,t4,gat,t5,gat,t6,gat,off,off",
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
      self.buffer[self.bufp]=self.i[1]
      self.bufp+=1
      local lenf=flr((self.i[2]+1)*2754+4)
      lenf=mid(3,lenf,5512)
      self.bufp=(self.bufp-1)%lenf+1
      self.o[1]=self.buffer[(self.bufp+lenf-1)%lenf+1]
  end
  }
end

function new_knobs()
  return new_module{
  saveid="knobs",
  name="knobs",
  iname={},
  oname=split"nob,nob,nob,nob",
  startp=0,
  knobanch=0,--original value
  knobind=0,
  custom_render=function(self)
    for i=0,3 do
      if hqmode then
        circfill(self.x+7,self.y+8+8*i,3,6)
        line(self.x+7.5,self.y+8.5+8*i,self.x+7.5-cos((self.o[i+1]+1)/2.5-.125)*2.8,self.y+8.5+8*i+sin((self.o[i+1]+1)/2.5-.125)*2.8,7)
        circ(self.x+7,self.y+8+8*i,3,1)
      else
        line(self.x+7.5,self.y+8.5+8*i,self.x+7.5-cos((self.o[i+1]+1)/2.5-.125)*2.8,self.y+8.5+8*i+sin((self.o[i+1]+1)/2.5-.125)*2.8,7)
      end
    end
  end,
  custom_input=function(self)
    if mbtnp(0) then
      for i=0,3 do
        if (self.x+7-mx)^2+(self.y+8+8*i-my)^2 < 9 then
          self.startp=mx
          self.knobanch=self.o[i+1]
          self.knobind=i+1
        end
      end
    end
    if mbtn(0) and self.knobind !=0 and (io_override==self or io_override==nil) then
      io_override=self
      self.o[self.knobind]=self.knobanch+(mx-self.startp)/24
      self.o[self.knobind]=mid(-1,self.o[self.knobind],1)
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
      local lenf=flr((self.i[2]+1)*2755.5+1)
      lenf=mid(1,lenf,5512)
      if self.count<lenf then
        self.count+=1
      else
        if self.oldinp != self.i[1] then
          self.count=0
        end
        self.o[1]=self.i[1]
      end
      self.oldinp=self.i[1]
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
    local target,now=self.i[1],self.o[1]
    local inc=((self.i[2]+1)/10)^4
    self.o[1]=now<target and min(now+inc,target) or max(now-inc,target)
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
    self.o[1]=self.i[1]*self.i[2]
    self.o[2]=self.i[1]+self.i[2]
    self.o[3]=(self.i[1]+1)*(self.i[2]+1)-1
  end
  }
end

function new_filter()
  return new_module{
  saveid="filter",
  name="filter",
  iname=split"in,res,frq",
  oname=split"lo,bnd,hi,ntc",
  step=function(self)
    local fs=2--sampling frequency
    local fc=(self.i[3]+1)/4--cutoff
    local f=2.0*-sin(.5*(fc/(fs)))--who really knows?
    local q=((1-self.i[2])+.1)*0.248756218905--resonance/bandwidth what the hell is bandwidth?
    local lpf,hpf,bpf,notch,inp=self.o[1],self.o[3],self.o[2],self.o[4],self.i[1]
    lpf=lpf+f*bpf;--low=low+f*band
    hpf=inp-lpf-q*bpf;--scale*input-low-q*band what the hell is scale? "scale=q"
    bpf=f*hpf+bpf;--f*high+band
    notch=hpf+lpf;--high+low
    self.o[1],self.o[3],self.o[2],self.o[4]=lpf,hpf,bpf,notch
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
    local lenf=flr((((self.i[1]+1)/2)^4)*5511+1)
    lenf=mid(1,lenf,5512)
    self.s+=1
    self.s%=lenf
    if(self.s==0)self.o[1]=rnd()*2-1
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
