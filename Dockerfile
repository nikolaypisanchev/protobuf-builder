ARG BASE_IMAGE=golang:1.12.7-buster

FROM ${BASE_IMAGE} AS builder

ARG PROTOC_VERSION=3.9.1
ENV PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-x86_64.zip
ENV PROTOC_URL=https://github.com/google/protobuf/releases/download/v${PROTOC_VERSION}/${PROTOC_ZIP}

RUN apt-get update && apt-get install -y curl unzip && \
    curl -OL ${PROTOC_URL} && \
    unzip -o ${PROTOC_ZIP} -d /pb && \
    go get -u github.com/golang/protobuf/protoc-gen-go

FROM ${BASE_IMAGE}

COPY --from=builder /pb/include/* /usr/local/include/google
COPY --from=builder /pb/bin/protoc /usr/local/bin/
COPY --from=builder /go/bin/protoc-gen-go /usr/local/bin/
RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger

ENTRYPOINT ["/usr/local/bin/protoc", "-I/usr/local/include", "-I/go/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis"]
CMD []