XDG_BIN_HOME ?= $(shell xdg-user-dir)/.local/bin

default:
	@echo Run \`make install\` to install \`cl\` to $(XDG_BIN_HOME)

install: scripts/cl.sh
	ln -s $(abspath scripts/cl.sh) $(XDG_BIN_HOME)/cl
