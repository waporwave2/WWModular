# WWModular

A modular synth written in pico-8

## credits
- design, code: waporwave
- code, optimizations: pancelor

## todo / features

### MODULES
- [ ] adsr backwards (feedback that the a,d,r inputs scaled inverse to how they expected)
- [x] maths A B input * (-2 to 2) output + etc
- [x] glide module
- [x] filter module
- [x] sample module

### FEATURES
- [x] save/load patches
- [x] import custom samples
- [ ] panning...? cheap (programmer time + tokens) to do, but does it hurt the vibe/coziness/design?
- [ ] save button on tracker
  - probably below the waporware panel, making it shorter
- [ ] clipboard copy paste page
- [x] pause menu option to minimize drawing functions (remove outlines, etc)
- [x] make left bar nicer (remove old controls)
- [x] keyboard on tracker send to track 1 for optional audio feedback (gate too if possible?)
- [x] new i/o system - write module outputs directly to where they're needed; a few TODOs left to do here:
  - [x] temp_write_i - currently on tracker and knobs
    - tracker should basically own the leftbar's outputs, or have them reserved in some way
  - [x] extra mixer elements
  - [ ] why didn't removing wire propagation get as much speedup as expected? probably b/c of tracker/leftbar still using expensive `temp_write_i`?
  - [ ] others?
- [ ] highlight wires when hovered
- [ ] flash wire color when value changes
  - _some_ way of making hidden state visual somehow, and see what patterns show up
  - maybe, one color if this wire tends to change values slowly, and one color if it changes quickly, or oscillates, or something (cpu and token expensive, probably...)
- [ ] record "waporware" voice sample
- [ ] sampler smoothing (non ^2 increments sample in weird steps, causing harsh sounds, from surface level testing 1 frame interpolation works but gives all a lowpass kinda sound)
  ```bash
  # https://stackoverflow.com/questions/4854513/can-ffmpeg-convert-audio-to-raw-pcm-if-so-how
  ffmpeg -y -i audio2.mp4 -acodec pcm_u8 -f u8 -ac 1 -ar 5512 out.pcm
  echo wmsa > sample2.ww
  cat out.pcm >> sample2.ww
  # now, open the file and delete the newline
  ```

### BUGS
- [x] can drag wires when changing knobs
- [x] wires can drag to multiple inputs (either fix or make the input collision not overlap)
- [ ] first note with trigger on does not play
- [ ] module should spawn where right clicked; clamping to bottom of screen breaks this
- [x] loading an old patch moves the leftbar up 15ish pixels (wontfix)

### TECH DEBT
- [ ] ? make output a custom draw module
- [ ] ? make leftbar step() = play()
- [ ] move custom save/load into modules themselves (might save tokens)
