--modules

function saw()
  return add(modules,{
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

function tri()
  return add(modules,{
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

function sine()
  return add(modules,{
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

function adsr()
  return add(modules,{
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
    end
    if self.state==1 then
      self.o[1]+=(((self.i[1]+1)*8)^2)/1024
    end
    if self.state==2 then
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

function lfo()
  return add(modules,{
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

function square()
  return add(modules,{
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

function output()
  return add(modules,{
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

function cut()
  return add(modules,{
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

function mixer()
  return add(modules,{
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

function leftbar()
  return add(modules,{
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
