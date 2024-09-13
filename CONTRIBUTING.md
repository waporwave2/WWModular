## hi

internal dev notes here, mainly. we don't expect anyone else to join in, but if you've got bugs feel free to file a github issue!

## how to export + push
1. run ./export.sh. there are some steps it'll talk you through, b/c of the `web_version=false` stuff
2. run ./push.sh
3. there is no step 3

needed programs in PATH:
- pico8 (to export)
- shrinko8 (to minify)
- sed (for html background color)
- ark (linux zip tool; for editing the exported zip to add in the examples)
- butler (for pushing to itch with ./push.sh)
