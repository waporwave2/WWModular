function ini_samplemode()
	upd,drw=upd_samplemode,drw_samplemode
	rcmenu=nil
	menuitems()
end

function upd_samplemode()
	eat_keyboard() --eat input while not in tracker mode
end

-- call this every time a new sample is loaded
function sample_cachedraw(ix)
	local chars=samples[ix]
	local nchars=#chars
	if nchars>1 then
		local heights={} --list of 125 heights [-1,1]

		for cix=1,nchars do
			heights[(cix/nchars*125)\1]=ord(chars,cix,1)/127.5-1
		end
		assert(#heights==125,nchars.." "..#heights)

		_sample_cachedraw[ix]=heights
	end
end

function drw_samplemode()
	cls()
	local y=-16
	for ix,chars in ipairs(samples) do
		y+=16
		rectwh(0,y,128,16,1)
		local heights=_sample_cachedraw[ix]
		if heights then
			line(11)
			for hix,h in ipairs(heights) do
				line(1+hix,y+8+h*8)
			end
		end
		?ix,2,y+2,7
	end
	?"samples",48,0,7
	?"enter to return",36,125,7
end
