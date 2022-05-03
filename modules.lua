--modules

function new_saw()
  return add(modules,{
  saveid="saw",
  name="saw ∧",
  phase=0,
  iname={"frq"},
  i={0},
  oname={"out"},
  o={0},
  step=function(self)
    self.phase=phzstep(self.phase,self.i[1])
    self.o[1]=self.phase
  end
  })
end

function new_tri()
  return add(modules,{
  saveid="tri",
  name="tri ∧",--name
  iname={"frq"},
  i={0},
  oname={"out"},
  o={0},
  phase=0,--code
  step=function(self)
    self.phase=phzstep(self.phase,self.i[1])
    self.o[1]=abs(self.phase)*2-1
  end
  })
end

function new_sine()
  return add(modules,{
  saveid="sin",
  name="sin …",
  phase=0,
  iname={"frq"},
  i={0},
  oname={"out"},
  o={0},
  step=function(self)
    self.phase=phzstep(self.phase,self.i[1])
    self.o[1]=sin(self.phase/2)
  end
  })
end

function new_adsr()
  return add(modules,{
  saveid="adsr",
  name="adsr",
  state=0,
  iname=split"atk,dec,sus,rel,gat",
  i=split"0,0,0,0,0",
  oname={"out"},
  o={-1},
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
  })
end

function new_lfo()
  return add(modules,{
  saveid="lfo",
  name="lfo …",
  phase=0,
  iname={"frq"},
  i={0},
  oname={"out"},
  o={0},
  step=function(self)
    self.phase=phzstep(self.phase,(self.i[1]-255)/256)
    self.o[1]=sin(self.phase/2)
  end
  })
end

function new_square()
  return add(modules,{
  saveid="square",
  name="sqr ░",
  phase=0,
  iname=split"frq,len",
  i=split"0,0",
  oname={"out"},
  o={0},
  step=function(self)
    self.phase=phzstep(self.phase,self.i[1])
    self.o[1]=sgn(self.phase+self.i[2])
  end
  })
end

function new_speaker()
  return add(modules,{
  saveid="speaker",
  name="output",
  undeletable=true,
  x=97,
  y=80,
  iname=split"inp,spd",
  i=split"0,0",
  o={},
  step=function(self)

  end
  })
end

function new_clip()
  return add(modules,{
  saveid="clip",
  name="clip",
  iname={"inp"},
  i={0},
  oname={"out"},
  o={0},
  step=function(self)
    self.o[1]=mid(-1,self.i[1],1)
  end
  })
end

function new_mixer()
  return add(modules,{
  saveid="mixer",
  name="mixer",
  iname=split"in,cv,in,cv",
  i=split"0,0,0,0",
  oname={"out"},
  o={0},
  prop=split"addrow,delrow",
  propfunc=function(self,i)
    if i==1 then
      if #self.i<8 then
        add(self.iname,"in")
        add(self.iname,"cv")
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
  })
end

function new_leftbar()
  return add(modules,{
  saveid="leftbar",
  name="",
  ungrabable=true,
  undeletable=true,
  x=-15,
  y=-5,
  iname={},
  i={},
  oname=split"t1,gat,t2,gat,t3,gat,t4,gat,t5,gat,t6,gat,off,off,0,0",
  o=split"0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0",
  step=function(self)

  end
  })
end

function new_delay()
  return add(modules,{
  saveid="delay",
  name="delay",
  iname=split"inp,len",
  i=split"0,0",
  oname={"out"},
  o={0},
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
  })
end

function new_knobs()
  return add(modules,{
  saveid="knobs",
  name="knobs",
  oname=split"nob,nob,nob,nob",
  o=split"0,0,0,0",
  startp=0,
  knobanch=0,--original value
  knobind=0,
  custom_render=function(self)
    for i=0,3 do
      circfill(self.x+7,self.y+8+8*i,3,6)
      circ(self.x+7,self.y+8+8*i,3,1)
      line(self.x+7,self.y+8+8*i,self.x+7-cos((self.o[i+1]+1)/2.5-.125)*3,self.y+8+8*i+sin((self.o[i+1]+1)/2.5-.125)*3,7)
      circ(self.x+7,self.y+8+8*i,4,3)
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
    if mbtn(0) and self.knobind !=0 then
      modulerelease()
      self.o[self.knobind]=self.knobanch+(mx-self.startp)/24
      self.o[self.knobind]=mid(-1,self.o[self.knobind],1)
    else
      self.knobind=0
    end
  end
  })
end

function new_hold()
  return add(modules,{
  saveid="hold",
  name="hold",
  iname=split"inp,len",
  i=split"0,0",
  oname={"out"},
  o={0},
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
  })
end

modmenu=split"saw,sin,square,mixer,tri,clip,lfo,adsr,delay,knobs,hold"
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
}
