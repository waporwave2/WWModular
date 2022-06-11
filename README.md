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
- [x] pause menu option to minimize drawing functions (remove outlines, etc)
- [x] make left bar nicer (remove old controls)
- [x] keyboard on tracker send to track 1 for optional audio feedback (gate too if possible?)
- [x] wavetable ad synth module possibly
- [x] flash wire color when value changes
- [x] better palette
- [x] new i/o system - write module outputs directly to where they're needed; a few TODOs left to do here:
- [x] soft clipping or other distortion modes on clip module
- [x] sample import page
  - [ ] make it prettier?
  - [ ] allow sample playback on sample import page
- [x] clipboard copy paste page (copy/pasting page note data, making it easier to make tracks)
- limit 
- [ ] change CLIP to distortion, instead of hard, soft clip modes, make it some kind of distortion, and soft clip, with output being clipped by default for new users
- [ ] record "waporware" voice sample (+ make a demo song for examples, cool introduction)
- show them what this program can do!
- [ ] scancodes, to support non QWERTY keyboards
- [x] wrap documentation line length
- [x] update documentation to reflect ADSR and other changes
- [ ] change synth+ to use new ADSR formula?

### not-super-important-but-still-cool features
- [ ] ports should also pulse color even if no wire is connected
- [ ] find a useful space for maths? maybe not needed
- got stuck on these two
- [ ] sampler smoothing (non ^2 increments sample in weird steps, causing harsh sounds, from surface level testing 1 frame interpolation works but gives all a lowpass kinda sound) `https://www.lexaloffle.com/bbs/?pid=112153#p`
- [ ] delay on length, remap old buffer space to new (resulting in pitch shift)

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
- [x] first note with trigger on does not play
- [x] module should spawn where right clicked; clamping to bottom of screen breaks this
- [x] loading an old patch moves the leftbar up 15ish pixels (wontfix) (yeah, I manually updated the old examples too)
- [x] make web version "export" to clipboard
- [x] "0" key plays wrong note
- [ ] on reset, wires from leftbar are zero, but they change to -1 when you press play. seems odd
- initial values are always zero, gates are either -1 or 1, I think all gate input modules check if >0 anyways so shouldn't actually change anything

### TECH DEBT
- [ ] ? make output a custom draw module
- [ ] ? make leftbar step() = play()
- [x] move custom save/load into modules themselves (might save tokens)
