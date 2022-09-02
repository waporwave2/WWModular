# WWModular

A modular synth written in pico-8

## credits
- design, code: waporwave
- code, optimizations: pancelor

## how to use

Make sure to read the docs (WWM DOCUMENTATION.txt)
To get compiled or html builds, download from https://waporwave.itch.io/wwmodular.
If you want to run it locally, open PICO-8 and run 'wwmodular.p8'; it has include statements that combine all the .lua files.

To add a module:
- go to modules.lua, and write a new function (see existing ones for example)
- add your new module function to the three lists at the bottom

If you want to write your own PICO-8 audio experiments, here some example code:

```lua
-- the amount of values to be written to the audio buffer.
-- stat(108) gets the number currently buffered, so 1536 lowers if there is too many being buffered.
-- A minimum is set to make up for any dropped frames later on.
local len=min(94,1536-stat(108))

-- for each value in the buffer, write a value (for example you might write the value of a sin() of an increasing step).
for i=0,len-1 do
  a = 128 -- 0-255 value, this should be silent write now since we're writing a constant value.
  poke(0x4300+i,a) -- write these values in memory
end
-- write 'len' number bytes from 0x4300 to 0x808 (the audio buffer)
serial(0x808,0x4300,len)
```

This is just one very minimal example of writing audio, you can most likely get help from the PICO-8 discord server or forums.
