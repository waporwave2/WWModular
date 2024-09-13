## hi

internal dev notes here, mainly. we don't expect anyone else to join in, but if you've got bugs feel free to file a github issue!

## how to export + push
1. edit the `__label__` section of wwmodular.p8: change the cpu meter to match the release version, e.g. v1.3 => 0.713, v1.4 => 0.714, etc
2. run ./export.sh
	- it'll let you know if you're missing some programs from your PATH
	- it's possible to do everything by hand but it would take a long time
3. run ./push.sh
