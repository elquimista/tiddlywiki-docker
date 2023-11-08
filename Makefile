#
# MIT License
# Copyright (c) 2017-2022 Nicola Worthington <nicolaw@tfb.net>
#
# https://gitlab.com/nicolaw/tiddlywiki
# https://nicolaw.uk
# https://nicolaw.uk/#TiddlyWiki
#

.PHONY: build push ami
.DEFAULT_GOAL := build

TW_VERSION = 5.3.1
BASE_IMAGE = node:20.9-alpine3.17
REPOSITORY = elquimista/tiddlywiki
USER       = node

IMAGE_TAGS = $(REPOSITORY):$(TW_VERSION) \
	           $(REPOSITORY):$(TW_VERSION)-$(subst /,,$(subst :,,$(BASE_IMAGE))) \
	           $(REPOSITORY):latest

MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

AWS_REGIONS = $(shell aws ec2 describe-regions \
				--filter "Name=opt-in-status,Values=opt-in-not-required" \
				--output json --query 'Regions[].RegionName[]' \
				| tr -d '[[:space:]]')

build:
	DOCKER_BUILDKIT=1 docker $@ \
	  --no-cache \
	  --build-arg TW_VERSION=$(TW_VERSION) \
	  --build-arg BASE_IMAGE=$(BASE_IMAGE) \
	  --build-arg USER=$(USER) \
	  -f Dockerfile \
	  $(addprefix -t ,$(IMAGE_TAGS)) \
	  $(MAKEFILE_DIR)

push:
	for t in $(IMAGE_TAGS) ; do docker $@ $$t ; done

ami:
	packer init -upgrade .
	packer build -var ami_regions='[$(AWS_REGIONS)]' .

