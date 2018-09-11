# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
SYNCIMAP_BINARY=cmd/syncimap/syncimap
BINARY_UNIX=$(BINARY_NAME)_unix
SYNCIMAP_VERSION=0.1
SYNCIMAP_BUILD=`git rev-parse HEAD 2>/dev/null`
SYNCIMAP_LDFLAGS = -ldflags "-X=main.Version=$(SYNCIMAP_VERSION) -X=main.Build=$(SYNCIMAP_VERSION)"
SYNCIMAP_MAIN = cmd/syncimap/main.go
all: build

dep-exe:
ifndef DEP_EXE
	@echo ">>> dep does not seem to be installed. installing dep..."
	go get -u github.com/golang/dep/cmd/dep
endif

dep-rebuild: dep-exe Gopkg.toml
	@echo ">>> Rebuilding vendored deps (respecting Gopkg.toml constraints)"
	rm -rf vendor Gopkg.lock
	dep ensure -v && dep status

dep-update: dep-exe Gopkg.toml
	@echo ">>> Updating vendored deps (respecting Gopkg.toml constraints)"
	dep ensure -update -v && dep status

# download automatically the vendored deps when "vendor" doesn't exist
vendor: dep-exe
	@[ -d vendor ] || dep ensure -v

build: 
	$(GOBUILD)  $(SYNCIMAP_LDFLAGS) -o $(SYNCIMAP_BINARY) $(SYNCIMAP_MAIN)
test: 
	$(GOTEST) -v ./...
clean: 
	$(GOCLEAN)
	rm -f $(SYNCIMAP_BINARY)
run:
	$(GOBUILD)  $(SYNCIMAP_LDFLAGS) -o $(SYNCIMAP_BINARY) $(SYNCIMAP_MAIN)
	./$(SYNCIMAP_BINARY)


# Cross compilation
build-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -o $(BINARY_UNIX) -v
docker-build:
	docker run --rm -it -v "$(GOPATH)":/go -w /go/src/bitbucket.org/rsohlich/makepost golang:latest go build -o "$(BINARY_UNIX)" -v

