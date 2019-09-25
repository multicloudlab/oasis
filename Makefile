GIT_HOST = github.com/multicloudlab
PWD := $(shell pwd)
BASE_DIR := $(shell basename $(PWD))

# Keep an existing GOPATH, make a private one if it is undefined
GOPATH_DEFAULT := $(PWD)/.go
export GOPATH ?= $(GOPATH_DEFAULT)
GOBIN_DEFAULT := $(GOPATH)/bin
export GOBIN ?= $(GOBIN_DEFAULT)
TESTARGS_DEFAULT := "-v"
export TESTARGS ?= $(TESTARGS_DEFAULT)
DEST := $(GOPATH)/src/$(GIT_HOST)/$(BASE_DIR)

VERSION ?= $(shell git describe --exact-match 2> /dev/null || \
                 git describe --match=$(git rev-parse --short=8 HEAD) --always --dirty --abbrev=8)

# Image URL to use all building/pushing image targets
IMG ?= asis
REGISTRY ?= quay.io/multicloudlab

ifneq ("$(realpath $(DEST))", "$(realpath $(PWD))")
	$(error Please run 'make' from $(DEST). Current directory is $(PWD))
endif

all: test build images

############################################################
# work section
############################################################
$(GOBIN):
	echo "create gobin"
	mkdir -p $(GOBIN)

work: $(GOBIN)	

############################################################
# check section
############################################################
check: fmt lint

fmt: fmt: format-go format-python

lint: lint-all

############################################################
# test section
############################################################

test:
	@go test -race ./...

############################################################
# build section
############################################################

build:
	@CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' ./cmd/oasis.go -o oasis

############################################################
# images section
############################################################

images: build build-push-images

build-push-images: config-docker
	@docker build . -f Dockerfile -t $(REGISTRY)/$(IMG):$(VERSION)
	@docker push $(REGISTRY)/$(IMG):$(VERSION)

############################################################
# clean section
############################################################
clean:
	rm -f oasis

include common/Makefile.common.mk
