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
build: 
	$(GOBUILD)  $(SYNCIMAP_LDFLAGS) -o $(SYNCIMAP_BINARY) $(SYNCIMAP_MAIN)
test: 
	$(GOTEST) -v ./...
clean: 
	$(GOCLEAN)
	rm -f $(BINARY_NAME)
	rm -f $(BINARY_UNIX)
run:
	$(GOBUILD) -o $(BINARY_NAME) -v ./...
	./$(BINARY_NAME)
deps:
	$(GOGET) github.com/markbates/goth
	$(GOGET) github.com/markbates/pop


# Cross compilation
build-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -o $(BINARY_UNIX) -v
docker-build:
	docker run --rm -it -v "$(GOPATH)":/go -w /go/src/bitbucket.org/rsohlich/makepost golang:latest go build -o "$(BINARY_UNIX)" -v

