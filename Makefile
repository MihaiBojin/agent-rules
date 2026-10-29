REPO := $(shell cd "$$(dirname "$(MAKEFILE_LIST)")" && pwd)/

.PHONY: build install install-limited project project-limited status uninstall test

build:            ## regenerate both compiled profiles
	@"$(REPO)install.sh" build

install:          ## wire the rules into every tool detected, user-level
	@"$(REPO)install.sh" global

project:          ## wire the full rules into DIR (default: cwd)
	@"$(REPO)install.sh" project "$(if $(DIR),$(DIR),$(CURDIR))"

install-limited:  ## wire the limited profile, user-level
	@"$(REPO)install.sh" global-limited

project-limited:  ## wire the limited profile into DIR
	@"$(REPO)install.sh" project-limited "$(if $(DIR),$(DIR),$(CURDIR))"

test:             ## run installer integration tests with a temporary HOME
	@python3 -B -m unittest discover -s "$(REPO)tests" -v

status:           ## show what is wired up right now
	@"$(REPO)install.sh" status "$(if $(DIR),$(DIR),$(CURDIR))"

uninstall:        ## remove every link and managed block this installer made
	@"$(REPO)install.sh" uninstall "$(if $(DIR),$(DIR),$(CURDIR))"
