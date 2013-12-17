# Copyright 2010-2013 RethinkDB, all rights reserved.

# Rules for downloading and building dependencies
#
# These rules are governed by the settings generated from ./configure
# Namely, the FETCH_LIST, *_VERSION and *_DEP variables
#
# Some of these rules are complicated and delicate. They try to convince make to:
#  * not rebuild files that are already built
#  * not wait on files to be built when they are not needed yet

# Recurrent directories
SUPPORT_SRC_DIR := $/support/src
SUPPORT_BUILD_DIR := $(BUILD_ROOT_DIR)/support
SUPPORT_LOG_DIR := $(SUPPORT_BUILD_DIR)

# How to call the pkg.sh script
PKG_SCRIPT_VARIABLES := WGET CURL OS COMPILER CXX
PKG_SCRIPT := $(foreach v, $(PKG_SCRIPT_VARIABLES), $v='$($v)') MAKEFLAGS= $/support/pkg/pkg.sh

# How to log the output of fetching and building packages
ifneq (1,$(VERBOSE))
  $(shell mkdir -p $(SUPPORT_LOG_DIR))
  SUPPORT_LOG_REDIRECT = > $1 2>&1 || ( tail -n 20 $1 ; echo ; echo Full error log: $1 ; false )
else
  SUPPORT_LOG_REDIRECT :=
endif

# Phony targets to fetch and build all dependencies
.PHONY: fetch support
fetch: $(foreach pkg, $(FETCH_LIST), fetch-$(pkg))
support: $(foreach pkg, $(FETCH_LIST), support-$(pkg))

# Download a dependency
$(SUPPORT_SRC_DIR)/%:
	$P FETCH $*
	name='$*'; $(PKG_SCRIPT) fetch $${name%%_*} $(call SUPPORT_LOG_REDIRECT, $(SUPPORT_LOG_DIR)/$*_fetch.log)

# Lst of files that make expects the packages to install
SUPPORT_TARGET_FILES := $(foreach var, $(filter %_LIBS_DEP %_BIN_DEP, $(.VARIABLES)), $($(var)))
SUPPORT_INCLUDE_DIRS := $(foreach var, $(filter %_INCLUDE_DEP,        $(.VARIABLES)), $($(var)))

# This function generates the suppport-* and fetch-* rules for each package
# $1 = target files, $2 = pkg name, $3 = pkg version
define support_rules

# Download a single packages
.PHONY: fetch-$2
fetch-$2: $$(SUPPORT_SRC_DIR)/$2_$3

# Build a single package
.PHONY: support-$2
support-$2: support-$2_$3

# The actual rule that builds the package
.PHONY: support-$2_$3
support-$2_% $(foreach target,$1,$(subst _$3/,_%/,$(target))): $(SUPPORT_SRC_DIR)/$2_$3 | $(filter $(SUPPORT_BUILD_DIR)/$2_$3/include, $(SUPPORT_INCLUDE_DIRS))
	$$P BUILD $2_$3
	$$(PKG_SCRIPT) install $2 $$(call SUPPORT_LOG_REDIRECT, $$(SUPPORT_LOG_DIR)/$2_$3_install.log)

endef

# For each package, list the target files and generate custom rules for that package
pkg_TARGET_FILES = $(filter $(SUPPORT_BUILD_DIR)/$(pkg)_%, $(SUPPORT_TARGET_FILES))
$(foreach pkg,$(FETCH_LIST),\
  $(eval $(call support_rules,$(pkg_TARGET_FILES),$(pkg),$($(pkg)_VERSION))))

# This function generates the support-include-* rules for a package
# $1 = include dir, $2 = pkg name, $3 = pkg version
define support_include_rules

# Install the include files for a given package
.PHONY: support-include-$2 support-include-$2_$3
.PRECIOUS: $3
support-include-$2: support-include-$2_$3
support-include-$2_% $(subst _$3/,_%/,$1): $(SUPPORT_SRC_DIR)/$2_$3
	$$P INSTALL-INCLUDE $2_$3
	$$(PKG_SCRIPT) install-include $2 \
	  $$(call SUPPORT_LOG_REDIRECT, $$(SUPPORT_LOG_DIR)/$2_$3_install-include.log)
	touch $1

endef

# List all the packages that have include files and generate custom rules for those files
include_PKG_NAME = $(word 1, $(subst _, $(space), $(patsubst $(SUPPORT_BUILD_DIR)/%, %, $(include))))
include_PKG_VERSION = $(word 2, $(subst _, $(space), $(subst /, $(space), $(patsubst $(SUPPORT_BUILD_DIR)/%, %, $(include)))))
$(foreach include, $(SUPPORT_INCLUDE_DIRS), \
  $(eval $(call support_include_rules,$(include),$(include_PKG_NAME),$(include_PKG_VERSION))))
