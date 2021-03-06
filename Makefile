# if Makefile.local exists, include it
ifneq ("$(wildcard Makefile.local)", "")
	include Makefile.local
endif

PACKER_VERSION = $(shell packer --version | sed 's/^.* //g' | sed 's/^.//')
ifneq (0.5.0, $(word 1, $(sort 0.5.0 $(PACKER_VERSION))))
$(error Packer version less than 0.5.x, please upgrade)
endif

ORACLE70_X86_64 ?= http://mirrors.dotsrc.org/oracle-linux/OL7/u0/x86_64/OracleLinux-R7-U0-Server-x86_64-dvd.iso
ORACLE66_X86_64 ?= http://mirrors.dotsrc.org/oracle-linux/OL6/U6/x86_64/OracleLinux-R6-U6-Server-x86_64-dvd.iso
ORACLE65_X86_64 ?= http://mirrors.dotsrc.org/oracle-linux/OL6/U5/x86_64/OracleLinux-R6-U5-Server-x86_64-dvd.iso
ORACLE64_X86_64 ?= http://mirrors.dotsrc.org/oracle-linux/OL6/U4/x86_64/OracleLinux-R6-U4-Server-x86_64-dvd.iso
ORACLE511_X86_64 ?= http://mirrors.dotsrc.org/oracle-linux/EL5/U11/x86_64/Enterprise-R5-U11-Server-x86_64-dvd.iso
ORACLE510_X86_64 ?= http://mirrors.dotsrc.org/oracle-linux/EL5/U10/x86_64/Enterprise-R5-U10-Server-x86_64-dvd.iso
ORACLE59_X86_64 ?= http://mirrors.dotsrc.org/oracle-linux/EL5/U9/x86_64/Enterprise-R5-U9-Server-x86_64-dvd.iso
ORACLE58_X86_64 ?= http://mirrors.dotsrc.org/oracle-linux/EL5/U8/x86_64/OracleLinux-R5-U8-Server-x86_64-dvd.iso
ORACLE57_X86_64 ?= http://mirrors.dotsrc.org/oracle-linux/EL5/U7/x86_64/Enterprise-R5-U7-Server-x86_64-dvd.iso
ORACLE66_I386 ?= http://mirrors.dotsrc.org/oracle-linux/OL6/U6/i386/OracleLinux-R6-U6-Server-i386-dvd.iso
ORACLE65_I386 ?= http://mirrors.dotsrc.org/oracle-linux/OL6/U5/i386/OracleLinux-R6-U5-Server-i386-dvd.iso
ORACLE64_I386 ?= http://mirrors.dotsrc.org/oracle-linux/OL6/U4/i386/OracleLinux-R6-U4-Server-i386-dvd.iso
ORACLE511_I386 ?= http://mirrors.dotsrc.org/oracle-linux/EL5/U11/i386/Enterprise-R5-U11-Server-i386-dvd.iso
ORACLE510_I386 ?= http://mirrors.dotsrc.org/oracle-linux/EL5/U10/i386/Enterprise-R5-U10-Server-i386-dvd.iso
ORACLE59_I386 ?= http://mirrors.dotsrc.org/oracle-linux/EL5/U9/i386/Enterprise-R5-U9-Server-i386-dvd.iso
ORACLE58_I386 ?= http://mirrors.dotsrc.org/oracle-linux/EL5/U8/i386/OracleLinux-R5-U8-Server-i386-dvd.iso
ORACLE57_I386 ?= http://mirrors.dotsrc.org/oracle-linux/EL5/U7/i386/Enterprise-R5-U7-Server-i386-dvd.iso

# Possible values for CM: (nocm | chef | chefdk | salt | puppet)
CM ?= nocm
# Possible values for CM_VERSION: (latest | x.y.z | x.y)
CM_VERSION ?=
ifndef CM_VERSION
	ifneq ($(CM),nocm)
		CM_VERSION = latest
	endif
endif
BOX_VERSION ?= $(shell cat VERSION)
SSH_USERNAME ?= vagrant
SSH_PASSWORD ?= vagrant
INSTALL_VAGRANT_KEY ?= true
ifeq ($(CM),nocm)
	BOX_SUFFIX := -$(CM)-$(BOX_VERSION).box
else
	BOX_SUFFIX := -$(CM)$(CM_VERSION)-$(BOX_VERSION).box
endif
# Packer does not allow empty variables, so only pass variables that are defined
PACKER_VARS_LIST = 'cm=$(CM)' 'headless=$(HEADLESS)' 'update=$(UPDATE)' 'version=$(BOX_VERSION)' 'ssh_username=$(SSH_USERNAME)' 'ssh_password=$(SSH_PASSWORD)' 'install_vagrant_key=$(INSTALL_VAGRANT_KEY)'
ifdef CM_VERSION
	PACKER_VARS_LIST += 'cm_version=$(CM_VERSION)'
endif
PACKER_VARS := $(addprefix -var , $(PACKER_VARS_LIST))
ifdef PACKER_DEBUG
	PACKER := PACKER_LOG=1 packer --debug
else
	PACKER := packer
endif
BUILDER_TYPES := vmware virtualbox parallels
TEMPLATE_FILENAMES := $(wildcard *.json)
BOX_FILENAMES := $(TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
VMWARE_BOX_DIR := box/vmware
VIRTUALBOX_BOX_DIR := box/virtualbox
PARALLELS_BOX_DIR := box/parallels
VMWARE_TEMPLATE_FILENAMES := $(TEMPLATE_FILENAMES)
VMWARE_BOX_FILENAMES := $(VMWARE_TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
VMWARE_BOX_FILES := $(foreach box_filename, $(VMWARE_BOX_FILENAMES), $(VMWARE_BOX_DIR)/$(box_filename))
VIRTUALBOX_BOX_FILES := $(foreach box_filename, $(BOX_FILENAMES), $(VIRTUALBOX_BOX_DIR)/$(box_filename))
PARALLELS_TEMPLATE_FILENAMES := oel66-desktop.json oel66-i386.json oel66.json oel70-desktop.json
PARALLELS_BOX_FILENAMES := $(PARALLELS_TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
PARALLELS_BOX_FILES := $(foreach box_filename, $(PARALLELS_BOX_FILENAMES), $(PARALLELS_BOX_DIR)/$(box_filename))
BOX_FILES := $(VMWARE_BOX_FILES) $(VIRTUALBOX_BOX_FILES) $(PARALLELS_BOX_FILES)
TEST_BOX_FILES := $(foreach builder, $(BUILDER_TYPES), $(foreach box_filename, $(BOX_FILENAMES), test-box/$(builder)/$(box_filename)))
VMWARE_OUTPUT := output-vmware-iso
VIRTUALBOX_OUTPUT := output-virtualbox-iso
PARALLELS_OUTPUT := output-parallels-iso
VMWARE_BUILDER := vmware-iso
VIRTUALBOX_BUILDER := virtualbox-iso
PARALLELS_BUILDER := parallels-iso
CURRENT_DIR = $(shell pwd)
SOURCES := $(wildcard script/*.sh)

.PHONY: list

all: $(BOX_FILES)

test: $(TEST_BOX_FILES)

###############################################################################
# Target shortcuts
define SHORTCUT

vmware/$(1): $(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-vmware/$(1): test-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

ssh-vmware/$(1): ssh-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

virtualbox/$(1): $(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-virtualbox/$(1): test-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

ssh-virtualbox/$(1): ssh-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

parallels/$(1): $(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-parallels/$(1): test-$(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

ssh-parallels/$(1): ssh-$(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

$(1): vmware/$(1) virtualbox/$(1) parallels/$(1)

test-$(1): test-vmware/$(1) test-virtualbox/$(1) test-parallels/$(1)

s3cp-$(1): s3cp-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX) s3cp-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX) s3cp-$(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

s3cp-vmware/$(1): s3cp-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

s3cp-virtualbox/$(1): s3cp-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

s3cp-parallels/$(1): s3cp-$(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

endef

SHORTCUT_TARGETS := $(basename $(TEMPLATE_FILENAMES))
$(foreach i,$(SHORTCUT_TARGETS),$(eval $(call SHORTCUT,$(i))))
###############################################################################

# Generic rule - not used currently
#$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-vmware-iso
#	mkdir -p $(VMWARE_BOX_DIR)
#	packer build -only=vmware-iso $(PACKER_VARS) $<

$(VMWARE_BOX_DIR)/oel70$(BOX_SUFFIX): oel70.json $(SOURCES) http/ks7.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE70_X86_64)" $<

$(VMWARE_BOX_DIR)/oel70-desktop$(BOX_SUFFIX): oel70-desktop.json $(SOURCES) http/ks7-desktop.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE70_X86_64)" $<

$(VMWARE_BOX_DIR)/oel66$(BOX_SUFFIX): oel66.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE66_X86_64)" $<

$(VMWARE_BOX_DIR)/oel66-desktop$(BOX_SUFFIX): oel66-desktop.json $(SOURCES) http/ks6-desktop.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE66_X86_64)" $<

$(VMWARE_BOX_DIR)/oel65$(BOX_SUFFIX): oel65.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE65_X86_64)" $<

$(VMWARE_BOX_DIR)/oel65-desktop$(BOX_SUFFIX): oel65-desktop.json $(SOURCES) http/ks6-desktop.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE65_X86_64)" $<

$(VMWARE_BOX_DIR)/oel64$(BOX_SUFFIX): oel64.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE64_X86_64)" $<

$(VMWARE_BOX_DIR)/oel511$(BOX_SUFFIX): oel511.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE511_X86_64)" $<

$(VMWARE_BOX_DIR)/oel510$(BOX_SUFFIX): oel510.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE510_X86_64)" $<

$(VMWARE_BOX_DIR)/oel59$(BOX_SUFFIX): oel59.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE59_X86_64)" $<

$(VMWARE_BOX_DIR)/oel58$(BOX_SUFFIX): oel58.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE58_X86_64)" $<

$(VMWARE_BOX_DIR)/oel57$(BOX_SUFFIX): oel57.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE57_X86_64)" $<

$(VMWARE_BOX_DIR)/oel66-i386$(BOX_SUFFIX): oel66-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE66_I386)" $<

$(VMWARE_BOX_DIR)/oel65-i386$(BOX_SUFFIX): oel65-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE65_I386)" $<

$(VMWARE_BOX_DIR)/oel64-i386$(BOX_SUFFIX): oel64-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE64_I386)" $<

$(VMWARE_BOX_DIR)/oel511-i386$(BOX_SUFFIX): oel511-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE511_I386)" $<

$(VMWARE_BOX_DIR)/oel510-i386$(BOX_SUFFIX): oel510-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE510_I386)" $<

$(VMWARE_BOX_DIR)/oel59-i386$(BOX_SUFFIX): oel59-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE59_I386)" $<

$(VMWARE_BOX_DIR)/oel58-i386$(BOX_SUFFIX): oel58-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE58_I386)" $<

$(VMWARE_BOX_DIR)/oel57-i386$(BOX_SUFFIX): oel57-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE57_I386)" $<

# Generic rule - not used currently
#$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-virtualbox-iso
#	mkdir -p $(VIRTUALBOX_BOX_DIR)
#	packer build -only=virtualbox-iso $(PACKER_VARS) $<

$(VIRTUALBOX_BOX_DIR)/oel70$(BOX_SUFFIX): oel70.json $(SOURCES) http/ks7.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE70_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel70-desktop$(BOX_SUFFIX): oel70-desktop.json $(SOURCES) http/ks7-desktop.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE70_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel66$(BOX_SUFFIX): oel66.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE66_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel66-desktop$(BOX_SUFFIX): oel66-desktop.json $(SOURCES) http/ks6-desktop.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE66_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel65$(BOX_SUFFIX): oel65.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE65_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel65-desktop$(BOX_SUFFIX): oel65-desktop.json $(SOURCES) http/ks6-desktop.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE65_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel64$(BOX_SUFFIX): oel64.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE64_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel511$(BOX_SUFFIX): oel511.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE511_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel510$(BOX_SUFFIX): oel510.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE510_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel59$(BOX_SUFFIX): oel59.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE59_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel58$(BOX_SUFFIX): oel58.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE58_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel57$(BOX_SUFFIX): oel57.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE57_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/oel66-i386$(BOX_SUFFIX): oel66-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE66_I386)" $<

$(VIRTUALBOX_BOX_DIR)/oel65-i386$(BOX_SUFFIX): oel65-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE65_I386)" $<

$(VIRTUALBOX_BOX_DIR)/oel64-i386$(BOX_SUFFIX): oel64-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE64_I386)" $<

$(VIRTUALBOX_BOX_DIR)/oel511-i386$(BOX_SUFFIX): oel511-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE511_I386)" $<

$(VIRTUALBOX_BOX_DIR)/oel510-i386$(BOX_SUFFIX): oel510-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE510_I386)" $<

$(VIRTUALBOX_BOX_DIR)/oel59-i386$(BOX_SUFFIX): oel59-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE59_I386)" $<

$(VIRTUALBOX_BOX_DIR)/oel58-i386$(BOX_SUFFIX): oel58-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE58_I386)" $<

$(VIRTUALBOX_BOX_DIR)/oel57-i386$(BOX_SUFFIX): oel57-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE57_I386)" $<

# Generic rule - not used currently
#$(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-parallels-iso
#	mkdir -p $(PARALLELS_BOX_DIR)
#	packer build -only=parallels-iso $(PACKER_VARS) $<

$(PARALLELS_BOX_DIR)/oel70$(BOX_SUFFIX): oel70.json $(SOURCES) http/ks7.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE70_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel70-desktop$(BOX_SUFFIX): oel70-desktop.json $(SOURCES) http/ks7-desktop.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE70_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel66$(BOX_SUFFIX): oel66.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE66_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel66-desktop$(BOX_SUFFIX): oel66-desktop.json $(SOURCES) http/ks6-desktop.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE66_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel65$(BOX_SUFFIX): oel65.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE65_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel65-desktop$(BOX_SUFFIX): oel65-desktop.json $(SOURCES) http/ks6-desktop.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE65_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel64$(BOX_SUFFIX): oel64.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE64_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel511$(BOX_SUFFIX): oel511.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE511_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel510$(BOX_SUFFIX): oel510.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE510_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel59$(BOX_SUFFIX): oel59.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE59_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel58$(BOX_SUFFIX): oel58.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE58_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel57$(BOX_SUFFIX): oel57.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE57_X86_64)" $<

$(PARALLELS_BOX_DIR)/oel66-i386$(BOX_SUFFIX): oel66-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE66_I386)" $<

$(PARALLELS_BOX_DIR)/oel65-i386$(BOX_SUFFIX): oel65-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE65_I386)" $<

$(PARALLELS_BOX_DIR)/oel64-i386$(BOX_SUFFIX): oel64-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE64_I386)" $<

$(PARALLELS_BOX_DIR)/oel511-i386$(BOX_SUFFIX): oel511-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE511_I386)" $<

$(PARALLELS_BOX_DIR)/oel510-i386$(BOX_SUFFIX): oel510-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE510_I386)" $<

$(PARALLELS_BOX_DIR)/oel59-i386$(BOX_SUFFIX): oel59-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE59_I386)" $<

$(PARALLELS_BOX_DIR)/oel58-i386$(BOX_SUFFIX): oel58-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE58_I386)" $<

$(PARALLELS_BOX_DIR)/oel57-i386$(BOX_SUFFIX): oel57-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(ORACLE57_I386)" $<

list:
	@echo "prepend 'vmware/', 'virtualbox/' or 'parallels/' to build only one target platform:"
	@echo "  make vmware/oel65"
	@echo ""
	@echo "Targets:"
	@for shortcut_target in $(SHORTCUT_TARGETS) ; do \
		echo $$shortcut_target ; \
	done ;

validate:
	@for template_filename in $(TEMPLATE_FILENAMES) ; do \
		echo Checking $$template_filename ; \
		packer validate $$template_filename ; \
	done

clean: clean-builders clean-output clean-packer-cache

clean-builders:
	@for builder in $(BUILDER_TYPES) ; do \
		if test -d box/$$builder ; then \
			echo Deleting box/$$builder/*.box ; \
			find box/$$builder -maxdepth 1 -type f -name "*.box" ! -name .gitignore -exec rm '{}' \; ; \
		fi ; \
	done

clean-output:
	@for builder in $(BUILDER_TYPES) ; do \
		echo Deleting output-$$builder-iso ; \
		echo rm -rf output-$$builder-iso ; \
	done

clean-packer-cache:
	echo Deleting packer_cache
	rm -rf packer_cache

test-$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): $(VMWARE_BOX_DIR)/%$(BOX_SUFFIX)
	bin/test-box.sh $< vmware_desktop vmware_fusion $(CURRENT_DIR)/test/*_spec.rb

test-$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): $(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX)
	bin/test-box.sh $< virtualbox virtualbox $(CURRENT_DIR)/test/*_spec.rb

test-$(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX): $(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX)
	bin/test-box.sh $< parallels parallels $(CURRENT_DIR)/test/*_spec.rb

ssh-$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): $(VMWARE_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< vmware_desktop vmware_fusion $(CURRENT_DIR)/test/*_spec.rb

ssh-$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): $(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< virtualbox virtualbox $(CURRENT_DIR)/test/*_spec.rb

ssh-$(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX): $(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< parallels parallels $(CURRENT_DIR)/test/*_spec.rb

S3_STORAGE_CLASS ?= REDUCED_REDUNDANCY
S3_ALLUSERS_ID ?= uri=http://acs.amazonaws.com/groups/global/AllUsers

s3cp-$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): $(VMWARE_BOX_DIR)/%$(BOX_SUFFIX)
	aws --profile $(AWS_PROFILE) s3 cp $< $(VMWARE_S3_BUCKET) --storage-class $(S3_STORAGE_CLASS) --grants full=$(S3_GRANT_ID) read=$(S3_ALLUSERS_ID)

s3cp-$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): $(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX)
	aws --profile $(AWS_PROFILE) s3 cp $< $(VIRTUALBOX_S3_BUCKET) --storage-class $(S3_STORAGE_CLASS) --grants full=$(S3_GRANT_ID) read=$(S3_ALLUSERS_ID)

s3cp-$(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX): $(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX)
	aws --profile $(AWS_PROFILE) s3 cp $< $(PARALLELS_S3_BUCKET) --storage-class $(S3_STORAGE_CLASS) --grants full=$(S3_GRANT_ID) read=$(S3_ALLUSERS_ID)

s3cp-vmware: $(addprefix s3cp-,$(VMWARE_BOX_FILES))
s3cp-virtualbox: $(addprefix s3cp-,$(VIRTUALBOX_BOX_FILES))
s3cp-parallels: $(addprefix s3cp-,$(PARALLELS_BOX_FILES))
