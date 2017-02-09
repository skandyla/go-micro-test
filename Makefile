.PHONY: all get build docker test loadtest kill deploy
all: get build docker test loadtest kill
tests: test loadtest kill

OS = $(shell uname -s) 
IMAGENAME = skandyla/go-micro-test
DOCKER_NAME = skandyla/go-micro-test
GOOS = linux
PORTHOST = 8080
PORTCT = 8080
DOCKERUSER = skandyla

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
	GOOS=$(GOOS) go build -v --ldflags '-extldflags "-static"' -o go-micro-test

docker:
	@echo build docker container docker
	docker version
	time docker build -t $(IMAGENAME) --build-arg GIT_COMMIT=$(TRAVIS_COMMIT) --build-arg GIT_BRANCH=$(TRAVIS_BRANCH)  -f Dockerfile_alpine .

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
	
kill:	
	@echo killing the container
	docker ps | grep $(IMAGENAME)
	docker ps | grep $(IMAGENAME) | awk '{print $$1}' | xargs docker kill 
	
#deploy:	
#	@echo deploying artifacts
#	docker tag $(IMAGENAME) $(DOCKERUSER)/$(IMAGENAME):latest
#	docker push $(DOCKERUSER)/$(IMAGENAME):latest

docker-tag:
	$(call tag_docker, $(DOCKER_NAME))

docker-push:
	docker push $(DOCKER_NAME)

inspect:
	@echo inspecting our image
	docker images
	docker inspect -f '{{index .ContainerConfig.Labels "git-commit"}}' $(IMAGENAME)
	docker inspect -f '{{index .ContainerConfig.Labels "git-branch"}}' $(IMAGENAME)

