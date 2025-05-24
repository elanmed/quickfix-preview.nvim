.PHONY: dev clean docs lint test deploy

dev:
	mkdir -p ~/.local/share/nvim/site/pack/dev/start/quickfix-preview.nvim
	stow -d .. -t ~/.local/share/nvim/site/pack/dev/start/quickfix-preview.nvim quickfix-preview.nvim

clean:
	rm -rf ~/.local/share/nvim/site/pack/dev

docs: 
	./deps/ts-vimdoc.nvim/scripts/docgen.sh README.md doc/quickfix-preview.txt quickfix-preview

lint: 
	# https://luals.github.io/#install
	lua-language-server --check=./lua --checklevel=error

test:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

deploy: test lint docs

