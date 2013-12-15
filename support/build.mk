# Copyright 2010-2013 RethinkDB, all rights reserved.

# Rules for downloading and building dependencies
#
# These rules are governed by the settings generated from ./configure
# Namely, the FETCH_LIST, *_VERSION and *_DEP variables
#
# Some of these rules are very complicated, to try and convince make to:
#  * not rebuild files that are already built
#  * not wait on files to be built when they are not needed yet

SUPPORT_SRC_DIR := $/support/src
SUPPORT_BUILD_DIR := $(BUILD_ROOT_DIR)/support
SUPPORT_LOG_DIR := $(SUPPORT_BUILD_DIR)
PKG_SCRIPT_VARIABLES := WGET CURL OS COMPILER CXX
PKG_SCRIPT := $(foreach v, $(PKG_SCRIPT_VARIABLES), $v='$($v)') MAKEFLAGS= $/support/pkg/pkg.sh

ifneq (1,$(VERBOSE))
  $(shell mkdir -p $(SUPPORT_LOG_DIR))
  SUPPORT_LOG_REDIRECT = > $1 2>&1 || ( tail -n 20 $1 ; echo ; echo Full error log: $1 ; false )
else
  SUPPORT_LOG_REDIRECT :=
endif

ALL_FETCH   := $(foreach pkg, $(FETCH_LIST), fetch-$(pkg))
ALL_SUPPORT := $(foreach pkg, $(FETCH_LIST), support-$(pkg))

.PHONY: fetch support
fetch: $(ALL_FETCH)
support: $(ALL_SUPPORT)

.PHONY: $(ALL_FETCH) $(ALL_SUPPORT)

$(foreach pkg, $(FETCH_LIST), \
  $(eval fetch-$(pkg): $(SUPPORT_SRC_DIR)/$(pkg)_$($(pkg)_VERSION)))

$(SUPPORT_SRC_DIR)/%:
	$P FETCH $*
	name='$*'; $(PKG_SCRIPT) fetch $${name%%_*} $(call SUPPORT_LOG_REDIRECT, $(SUPPORT_LOG_DIR)/$*.log)

#####

SUPPORT_TARGET_FILES := $(foreach var, $(filter %_LIBS_DEP %_BIN_DEP, $(.VARIABLES)), $((var)))


$(ALL_SUPPORT): support-%:
	$P BUILD $*
	$(PKG_SCRIPT) install $* $(call SUPPORT_LOG_REDIRECT, $(SUPPORT_LOG_DIR)/$*.log)

NEEDS_FETCH := $(foreach pkg, $(FETCH_LIST), \
	         $(if $(shell $(PKG_SCRIPT) fetched $(pkg) && echo y),,support-$(pkg)))

#####

var_PKG_NAME = $(word 1, $(subst _, $(space), $(patsubst $(SUPPORT_BUILD_DIR)/%, %, $($(var)))))
var_PKG_VERSION = $(word 2, $(subst _, $(space), $(subst /, $(space), $(patsubst $(SUPPORT_BUILD_DIR)/%, %, $($(var))))))

$(foreach var, $(filter %_INCLUDE_DEP, $(.VARIABLES)), \
  $(eval $(subst $(var_PKG_VERSION),%,$((var))): $(SUPPORT_SRC_DIR)/$(var_PKG_NAME)-% $(nl) \
    $(tab)$P INSTALL-INCLUDE $(var_PKG_NAME) $(nl) \
    $(tab)$(PKG_SCRIPT) install-include $(var_PKG_NAME) \
	$(call SUPPORT_LOG_REDIRECT, $(SUPPORT_LOG_DIR)/$(var_PKG_NAME).log)))

ifeq (0,1)



$(GPERFTOOLS_SRC_DIR):
	$P DOWNLAOD gperftools
	$(GETURL) http://gperftools.googlecode.com/files/gperftools-2.1.tar.gz | ( \
	  cd $(TC_SRC_DIR) && \
	  tar -xzf - && \
	  rm -rf gperftools && \
	  mv gperftools-2.1 gperftools )

$(LIBUNWIND_SRC_DIR):
	$P DOWNLOAD libunwind
	$(GETURL) http://gnu.mirrors.pair.com/savannah/savannah//libunwind/libunwind-1.1.tar.gz | ( \
	  cd $(TC_SRC_DIR) && \
	  tar -xzf - && \
	  rm -rf libunwind && \
	  mv libunwind-1.1 libunwind )

$(LIBUNWIND_DIR): $(LIBUNWIND_SRC_DIR)

# TODO: don't use colonize.sh
# TODO: seperate step and variable for building $(UNWIND_INT_LIB)
$(TCMALLOC_MINIMAL_INT_LIB): $(LIBUNWIND_DIR) $(GPERFTOOLS_DIR)
	$P MAKE libunwind gperftools
	cd $(TOP)/support/build && rm -f native_list.txt semistaged_list.txt staged_list.txt boost_list.txt post_boost_list.txt && touch native_list.txt semistaged_list.txt staged_list.txt boost_list.txt post_boost_list.txt && echo libunwind >> semistaged_list.txt && echo gperftools >> semistaged_list.txt && cp -pRP $(COLONIZE_SCRIPT_ABS) ./ && ( unset PREFIX && unset prefix && unset MAKEFLAGS && unset MFLAGS && unset DESTDIR && bash ./colonize.sh ; )



endif
