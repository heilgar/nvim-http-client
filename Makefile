
.PHONY: test

test:
	nvim --headless -c "PlenaryBustedDirectory tests/http_client {minimal_init = 'tests/minimal_init.lua'}"

