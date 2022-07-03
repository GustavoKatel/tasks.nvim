TEST_PATH ?= lua/tests

test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory $(TEST_PATH) { minimal_init = './scripts/minimal_init.vim' }"

test-watch:
	watchexec -w lua make test

format:
	stylua lua

lint:
	luacheck lua

docgen:
	# TODO
