assert(nil,"don't include this file. this is just a place to put dead code")

function phzstep(phz,fr)
	-- phz+=(fr+1)*0.189841269841
	-- return ((phz+1)%2)-1 --wrap into -1,1
	return ((phz+fr*0.18984+1.18984)&0x1.ffff)-1 --wrap into -1,1
end
