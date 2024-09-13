pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--
--

cls()
-- original values
og={-0.937505972289, -0.933779264214, -0.929842331581, -0.925676063067, -0.921261347348, -0.916579073101, -0.911610129001, -0.90635451505, -0.900793119924, -0.894887720975, -0.888638318204, -0.882006688963, -0.874992833254, -0.859684663163, -0.842503583373, -0.833139034878, -0.8127090301, -0.789775441949, -0.76403248925, -0.750004777831, -0.719388437649, -0.68502627807, -0.867558528428, -0.851352126135, -0.823220258003, -0.801567128524, -0.777276636407, -0.73513616818, -0.702704252269,}
-- shrinko8 values
sh={-.9375,-.93378,-.92985,-.92568,-.92125,-.91657,-.91161,-.90635,-.9008,-.89489,-.88863,-.88201,-.87499,-.85969,-.8425,-.83313,-.8127,-.78977,-.76403,-.75,-.71938,-.68502,-.86756,-.85135,-.82322,-.80156,-.77727,-.73513,-.7027}
assert(#og==#sh)
for i=1,#sh do
	assert(og[i]==sh[i],i)
end
?"all tests ok"
