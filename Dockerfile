FROM golang:1.10.2
MAINTAINER FOUCHARD Tony <t.fouchard@qwant.com>
RUN apt-get update
RUN apt-get install -qy --no-install-recommends wget lv tcpdump emacs24-nox
RUN go get -u github.com/golang/dep/cmd/dep
RUN go get github.com/osrg/gobgp/gobgp
RUN go get github.com/osrg/gobgp/gobgpd
WORKDIR /go/src/github.com/osrg/gobgp
RUN dep ensure
WORKDIR /go/src/github.com/osrg/gobgp/gobgp
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/gobgp -ldflags "-w -s -v -extldflags -static"
WORKDIR /go/src/github.com/osrg/gobgp/gobgpd
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/gobgpd -ldflags "-w -s -v -extldflags -static"
RUN go get github.com/a8m/envsubst/cmd/envsubst
WORKDIR /go/src/github.com/a8m/envsubst/cmd/envsubst
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/envsubst -ldflags "-w -s -v -extldflags -static"
RUN ls -al /bin/gobgp
RUN ls -al /bin/gobgpd
RUN ls -al /bin/envsubst
RUN wget -O /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
RUN chmod +x /bin/jq

FROM busybox:1.28.3
COPY entrypoint.sh /entrypoint.sh
COPY --from=0 /bin/gobgp /bin/gobgp
COPY --from=0 /bin/gobgpd /bin/gobgpd
COPY --from=0 /bin/envsubst /bin/envsubst
COPY --from=0 /bin/jq /bin/jq
CMD ["/entrypoint.sh"]
