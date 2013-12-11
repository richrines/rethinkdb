# Rules for fetching and building external dependencies
#
# Each mk file in this directory should support the following targets:
#
# $(TGZ): fetch the source for the dependency into the $(TGZ) file
# build: unpack and build the source in the $(BUILD) folder.
# install: Copy the executable to $(BIN),
#          and/or a static library to $(LIB)
#          and/or include files into $(INCLUDE).
#
# Those targets should not depend on one another.
#
# Each mk file should also define the VERSION variable.

ifeq ($(NAME),)
  $(error NAME not defined)
endif

SUPPORT_PREFIX ?= ../support
FETCH_DIR ?= ../fetched
SPECS = .
BIN_DIR = $(SUPPORT_PREFIX)/bin
LIB_DIR = $(SUPPORT_PREFIX)/lib
BIN = $(SUPPORT_PREFIX)/bin/$(NAME)-$(VERSION)
LIB = $(SUPPORT_PREFIX)/lib/lib$(NAME).a.$(VERSION)
INCLUDE = $(SUPPORT_PREFIX)/include/$(NAME)-$(VERSION)
BUILD = $(SUPPORT_PREFIX)/build/$(NAME)-$(VERSION)
TGZ = $(FETCH_DIR)/$(NAME)-$(VERSION).tgz

default:
	$(error target should be fetch, build install or another valid target for $(NAME))

include $(NAME).mk

.PHONY: fetch build install
fetch: $(TGZ)
$(TGZ): | $(BUILD)/. $(FETCH_DIR)/.
build: | $(BUILD)/.
$(BIN): | $(BIN_DIR)/.
$(LIB): | $(LIB_DIR)/.

%/.:
	mkdir -p $*

.PHONY: version
version:
	echo $(VERSION)

