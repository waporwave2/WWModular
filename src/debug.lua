-- separated into its own file so it's easy to remove completely,
-- to save on pico8 compressed space

--[[
function check_page(flag)
	local sheet=page[pg]
	assert(#sheet==6,flag)
	for xx,column in ipairs(sheet) do
		assert(#column==16,flag)
		for yy,note in ipairs(column) do
			assert(note and note[3],qq(flag,xx,yy))
		end
	end
end
--]]

function cpsam(n)
	printh(samples[n],"@clip")
end

function debugmod( mod)
	mod=mod or modules[selectedmod]
	if mod then
		pq(mod.saveid,"i/o: index | name | addr | value")
		for ix,name in ipairs(mod.iname) do
			pq(" i",ix,name,mod[name],mem[mod[name]])
		end
		for ix,name in ipairs(mod.oname) do
			pq(" o",ix,name,mod[name],mem[mod[name]])
		end
	end
end
