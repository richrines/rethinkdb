# Copyright 2010-2013 RethinkDB, all rights reserved.

SUPPORT_SRC_DIR := $/support/src
SUPPORT_BUILD_DIR := $(BUILD_ROOT_DIR)/support
SUPPORT_LOG_DIR := $(SUPPORT_BUILD_DIR)
PKG_SCRIPT := $/support/pkg/pkg.sh

export WGET
export CURL

ifneq (1,$(VERBOSE))
  $(shell mkdir -p $(SUPPORT_LOG_DIR))
  SUPPORT_LOG_REDIRECT = > $1 2>&1 || ( tail -n 20 $1 ; echo ; echo Full error log: $1 ; false )
else
  SUPPORT_LOG_REDIRECT :=
endif

ALL_FETCH   := $(foreach pkg, $(FETCH_LIST), $(if $(shell test -e $(SUPPORT_SRC_DIR) || echo y),fetch-$(pkg)))
ALL_SUPPORT := $(foreach pkg, $(FETCH_LIST), support-$(pkg))

.PHONY: fetch support
fetch: $(ALL_FETCH)
support: $(ALL_SUPPORT)

.PHONY:  $(ALL_FETCH) $(ALL_SUPPORT)

$(ALL_FETCH): fetch-%:
	$P FETCH $*
	$(PKG_SCRIPT) fetch $* $(call SUPPORT_LOG_REDIRECT, $(SUPPORT_LOG_DIR)/$*.log)

$(ALL_SUPPORT): support-%: fetch-%
	$P BUILD $*
	$(PKG_SCRIPT) install $* $(call SUPPORT_LOG_REDIRECT, $(SUPPORT_LOG_DIR)/$*.log)

$(filter-out $(ALL_FETCH), $(foreach pkg, $(FETCH_LIST), fetch-$(pkg))):
	true

support-include-%: fetch-%
	$P COPY
	$(PKG_SCRIPT) install-include $* $(call SUPPORT_LOG_REDIRECT, $(SUPPORT_LOG_DIR)/$*.log)

EXTRACT_PKG_NAME = $(word 1, $(subst _, $(space), $(patsubst $(SUPPORT_BUILD_DIR)/%, %, $($(var)))))

$(foreach var, $(filter %_INCLUDE_DEP, $(.VARIABLES)), \
    $(eval $($(var)): support-include-$(EXTRACT_PKG_NAME) ))

$(foreach var, $(filter %_LIBS_DEP %_BIN_DEP, $(.VARIABLES)), \
    $(eval $($(var)): support-$(EXTRACT_PKG_NAME) ))

ifeq (0,1)


NPM ?= NO_NPM
ifeq ($(NPM),$(TC_NPM_INT_EXE))
  NPM_DEP := $(NPM)
endif

ifeq ($(TCMALLOC_MINIMAL_INT_LIB),$(TCMALLOC_MINIMAL_LIBS))
  TCMALLOC_DEP := $(TCMALLOC_MINIMAL_INT_LIB)
endif



$(NODE_SRC_DIR):
	$P DOWNLOAD node
	rm -rf $@
	$(GETURL) http://nodejs.org/dist/v$(NODE_INT_VERSION)/node-v$(NODE_INT_VERSION).tar.gz | ( \
	  cd $(TC_SRC_DIR) && tar -xzf - )

$(TC_NPM_INT_EXE): $(NODE_DIR) | $(SUPPORT_DIR)/usr/bin/.
	$P MAKE npm
	rm -f $(SUPPORT_DIR_ABS)/usr/bin/npm
	( unset prefix PREFIX DESTDIR MAKEFLAGS MFLAGS && \
	  cd $(NODE_DIR) && \
	  ./configure --prefix=$(SUPPORT_DIR_ABS)/usr && \
	  $(EXTERN_MAKE) prefix=$(SUPPORT_DIR_ABS)/usr DESTDIR=/ && \
	  $(EXTERN_MAKE) install prefix=$(SUPPORT_DIR_ABS)/usr DESTDIR=/ ) $(SUPPORT_LOG_REDIRECT)
	mv $(SUPPORT_DIR_ABS)/usr/bin/npm $@ && touch $@

$(PROTOC_SRC_DIR):

ifeq ($(COMPILER) $(OS),CLANG Darwin)
  BUILD_PROTOC_ENV := CXX=clang++ CXXFLAGS='-std=c++11 -stdlib=libc++' LDFLAGS=-lc++
else
  BUILD_PROTOC_ENV :=
endif

$(PROTOBUF_INT_LIB): $(TC_PROTOC_INT_EXE)
$(TC_PROTOC_INT_EXE): $(PROTOC_DIR)
	$P MAKE protoc
	( cd $(PROTOC_DIR) && \
	  $(BUILD_PROTOC_ENV) \
	  ./configure --prefix=$(SUPPORT_DIR_ABS)/usr && \
	  $(EXTERN_MAKE) PREFIX=$(SUPPORT_DIR_ABS)/usr prefix=$(SUPPORT_DIR_ABS)/usr DESTDIR=/ && \
	  $(EXTERN_MAKE) install PREFIX=$(SUPPORT_DIR_ABS)/usr prefix=$(SUPPORT_DIR_ABS)/usr DESTDIR=/ ) \
	    $(SUPPORT_LOG_REDIRECT)

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



  PROTOC_RUN := env LD_LIBRARY_PATH=$(TC_PROTOC_INT_LIB_DIR):$(LD_LIBRARY_PATH) PATH=$(TC_PROTOC_INT_BIN_DIR):$(PATH) $(PROTOC)

endif
