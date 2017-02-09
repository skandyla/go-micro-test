.PHONY: all get build build_in_docker docker test loadtest clean docker-tag docker-push
all: get build docker test loadtest clean
tests: test loadtest clean

OS = $(shell uname -s) 
IMAGENAME = skandyla/go-micro-test
ARTF = go-micro-test
CGO_ENABLED=0
GOOS = linux
PORTHOST = 8080
PORTCT = 8080

define tag_docker
  @if [ "$(TRAVIS_BRANCH)" = "master" -a "$(TRAVIS_PULL_REQUEST)" = "false" ]; then \
    docker tag $(1) $(1):latest; \
  fi
  @if [ "$(TRAVIS_BRANCH)" != "master" ]; then \
    docker tag $(1) $(1):$(TRAVIS_BRANCH); \
  fi
  @if [ "$(TRAVIS_PULL_REQUEST)" != "false" ]; then \
    docker tag $(1) $(1):PR_$(TRAVIS_PULL_REQUEST); \
  fi
endef

get:
	@echo get dependencies
	go get -v  ./...

build:
	@echo build go code
	GOOS=$(GOOS) CGO_ENABLED=$(CGO_ENABLED) go build -v --ldflags '-extldflags "-static"' -o $(ARTF)

build_in_docker:
	@echo build go code inside docker container - optional for testing
	docker run --rm -v "$$PWD":/opt -w /opt golang:1.7 /bin/bash -c "\
		export GOBIN=$$GOPATH/bin ;\
		go get -v  ./... ;\
		GOOS=$(GOOS) CGO_ENABLED=$(CGO_ENABLED) go build -v --ldflags '-extldflags "-static"' -o $(ARTF)"

docker:
	@echo build docker container docker
	docker version
	docker build -t $(IMAGENAME) --build-arg GIT_COMMIT=$(TRAVIS_COMMIT) --build-arg GIT_BRANCH=$(TRAVIS_BRANCH)  -f Dockerfile_alpine .

test:
	@echo testing the container
	docker run -d -p $(PORTHOST):$(PORTCT) $(IMAGENAME)
	docker ps 
	curl -w "\n" http://localhost:8080 
	curl -w "\n" http://localhost:8080/stats 
  
loadtest:
	@echo make loadtest of the container
	docker run --net="host" --rm skandyla/wrk -c60 -d5 -t10  http://localhost:8080/stats
	curl -w "\n" http://localhost:8080/stats 
	
clean:	
	@echo cleaning the environment
	rm -rvf $(ARTF)
	docker ps | grep $(IMAGENAME)
	docker ps | grep $(IMAGENAME) | awk '{print $$1}' | xargs docker kill 

docker-tag:
	@echo tag_docker depend of branch
	$(call tag_docker, $(IMAGENAME))

docker-push:
	@echo push image to dockerhub
	docker push $(IMAGENAME)

inspect:
	@echo inspecting our image
	docker images
	docker inspect -f '{{index .ContainerConfig.Labels "git-commit"}}' $(IMAGENAME)
	docker inspect -f '{{index .ContainerConfig.Labels "git-branch"}}' $(IMAGENAME)

