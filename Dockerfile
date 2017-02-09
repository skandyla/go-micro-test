FROM scratch
MAINTAINER skandyla@gmail.com
ADD main .
ENV PORT 8080
EXPOSE 8080
ENTRYPOINT ["/main"]
