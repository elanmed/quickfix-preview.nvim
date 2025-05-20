.PHONY: dev clean

dev:
	mkdir -p ~/.local/share/nvim/site/pack/dev/start/quickfix-preview.nvim
	stow -d .. -t ~/.local/share/nvim/site/pack/dev/start/quickfix-preview.nvim quickfix-preview.nvim

clean:
	rm -rf ~/.local/share/nvim/site/pack/dev

