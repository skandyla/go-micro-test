.PHONY: all get build docker test loadtest kill
all: get build docker test loadtest kill
tests: test loadtest kill

OS = $(shell uname -s) 
IMAGENAME=go-micro-test
GOOS=linux
PORTHOST=8080
PORTCT=8080

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
	
	
	
	
	
	
	
	
 
