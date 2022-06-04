function ini_samplemode()
  upd,drw=upd_samplemode,drw_samplemode
  rcmenu=nil
  menuitems()
  menuitem(3,"return",ini_patchmode)
end

function upd_samplemode()
  
end

function drw_samplemode()
  cls()
  ?"sample mode",0,0,7
end