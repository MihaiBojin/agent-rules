REPO := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: build install project status uninstall

build:            ## regenerate generated/AGENTS.md from rules/*.md
	@$(REPO)install.sh build

install:          ## wire the rules into every tool detected, user-level
	@$(REPO)install.sh global

project:          ## wire the rules + prose hook into DIR (default: cwd)
	@$(REPO)install.sh project $(if $(DIR),$(DIR),$(CURDIR))

status:           ## show what is wired up right now
	@$(REPO)install.sh status $(if $(DIR),$(DIR),$(CURDIR))

uninstall:        ## remove every link and managed block this installer made
	@$(REPO)install.sh uninstall $(if $(DIR),$(DIR),$(CURDIR))
