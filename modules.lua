--modules

function new_saw()
  return add(modules,{
  saveid="saw",
  name="saw ∧",
  phase=0,
  iname={"frq"},
  i={-0.159101767797},
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
  saveid="sine",
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
  iname={"atk","dec","sus","rel","gat"},
  i={0,0,0,0,0},
  oname={"out"},
  o={-1},
  gat=true,
  prop={"gattrg"},
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
  iname={"frq","len"},
  i={0,0},
  oname={"out"},
  o={0},
  step=function(self)
    self.phase=phzstep(self.phase,self.i[1])
    self.o[1]=sgn(self.phase+self.i[2])
  end
  })
end

function new_output()
  return add(modules,{
  saveid="output",
  name="output",
  undeletable=true,
  x=97,
  y=80,
  iname={"inp","spd"},
  i={32,1},
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
  i={32},
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
  iname={"in","cv","in","cv"},
  i={0,0,0,0},
  oname={"out"},
  o={0},
  prop={"addrow","delrow"},
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
        local wi=wirex(self,3,#self.i)
        if wi>0then
          deli(wires,wi)
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
  oname={"t1","gat","t2","gat","t3","gat","t4","gat","t5","gat","t6","gat","off","off","0","0"},
  o={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  step=function(self)

  end
  })
end

function new_delay()
    add(modules,{
    saveid="delay",
    name="delay",
    iname={"inp","len"},
    i={0,0},
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

-- used by the loading system
all_module_makers={
  saw=new_saw,
  tri=new_tri,
  sine=new_sine,
  adsr=new_adsr,
  lfo=new_lfo,
  square=new_square,
  output=new_output,
  clip=new_clip,
  mixer=new_mixer,
  leftbar=new_leftbar,
  delay=new_delay,
}
