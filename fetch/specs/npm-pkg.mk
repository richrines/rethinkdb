# Fetch and build an npm package

# Expects NPM_PACKAGE_NAME to be set

NPM_CONF = $(SPECS)/npm.conf
NPM = npm --userconfig $(abspath $(NPM_CONF)) --no-cache
DIR = $(BUILD)/fetch-$(NPM_PACKAGE_NAME)-$(VERSION)

PACKAGE_JSON := { "name": "packed-$(NPM_PACKAGE_NAME)",
PACKAGE_JSON +=   "version": "$(VERSION)",
PACKAGE_JSON +=   "dependencies": { "$(NPM_PACKAGE_NAME)": "$(VERSION)" },
PACKAGE_JSON +=   "bundleDependencies": [ "$(NPM_PACKAGE_NAME)" ] }

fetch: $(TGZ)

$(TGZ):
	mkdir $(DIR) || :
	cp -f $(SPECS)/$(NPM_PACKAGE_NAME).shrinkwrap $(DIR)/npm-shrinkwrap.json
	echo '$(PACKAGE_JSON)' > $(DIR)/package.json
	cd $(DIR) && $(NPM) install
	cd $(DIR) && $(NPM) pack
	mv $(DIR)/packed-$(NPM_PACKAGE_NAME)-$(VERSION).tgz $@

.PHONY: shrinkwrap
shrinkwrap: $(SPECS)/$(NPM_PACKAGE_NAME).shrinkwrap

$(SPECS)/$(NPM_PACKAGE_NAME).shrinkwrap:
	mkdir $(DIR)-shrinkwrap || :
	echo '$(PACKAGE_JSON)' > $(DIR)-shrinkwrap/package.json
	cd $(DIR)-shrinkwrap && $(NPM) install
	cd $(DIR)-shrinkwrap && $(NPM) shrinkwrap
	cp $(DIR)-shrinkwrap/npm-shrinkwrap.json $@

build:
	mkdir $(BUILD)/node_modules || :
	cd $(BUILD) && $(NPM) --no-registry install $(abspath $(TGZ))

install: $(BIN)

$(BIN):
	echo '#!/bin/sh' > $@
	echo $(abspath $(BUILD))/node_modules/packed-$(NPM_PACKAGE_NAME)/node_modules/.bin/$(NAME) "$$@" > $@
	chmod +x $@
