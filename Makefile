.PHONY: dev clean docs lint test deploy

dev:
	mkdir -p ~/.local/share/nvim/site/pack/dev/start/quickfix-preview.nvim
	stow -d .. -t ~/.local/share/nvim/site/pack/dev/start/quickfix-preview.nvim quickfix-preview.nvim

clean:
	rm -rf ~/.local/share/nvim/site/pack/dev

docs:
	nvim --headless --noplugin -u NONE -c "luafile scripts/minidoc.lua" -c "qa"
	cp ./doc/quickfix-preview.txt README.txt

lint: 
	# https://luals.github.io/#install
	lua-language-server --check=./lua --checklevel=Error

test:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

deploy: test lint docs

