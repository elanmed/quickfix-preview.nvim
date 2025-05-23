.PHONY: dev clean docs

dev:
	mkdir -p ~/.local/share/nvim/site/pack/dev/start/quickfix-preview.nvim
	stow -d .. -t ~/.local/share/nvim/site/pack/dev/start/quickfix-preview.nvim quickfix-preview.nvim

clean:
	rm -rf ~/.local/share/nvim/site/pack/dev

docs: 
	./deps/ts-vimdoc.nvim/scripts/docgen.sh README.md doc/quickfix-preview.txt quickfix-preview

