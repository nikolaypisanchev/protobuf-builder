ARG BASE_IMAGE=golang:1.13.4-buster
ARG PROTOC_VERSION=3.9.2
ARG PROTOC_GEN_GO_VERSION=v1.3.2
ARG GRPC_GATEWAY_VERSION=v1.11.3
ARG GOGO_PROTO_VERSION=v1.3.0
ARG GOOGLEAPI_VERSION=c6e62c7e5e61e6dae7fdc3bc3de81f60e6a9445c

FROM ${BASE_IMAGE} AS builder

ARG PROTOC_GEN_GO_VERSION
ARG PROTOC_VERSION

ENV GO111MODULE=on
ENV PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-x86_64.zip
ENV PROTOC_URL=https://github.com/google/protobuf/releases/download/v${PROTOC_VERSION}/${PROTOC_ZIP}

RUN apt-get update && apt-get install -y curl unzip && \
    curl -OL ${PROTOC_URL} && \
    unzip -o ${PROTOC_ZIP} -d /pb && \
    go get -u github.com/golang/protobuf/protoc-gen-go@${PROTOC_GEN_GO_VERSION}

FROM ${BASE_IMAGE}

ARG GRPC_GATEWAY_VERSION
ARG GOGO_PROTO_VERSION
ARG GOOGLEAPI_VERSION

ENV GO111MODULE=on

COPY --from=builder /pb/include/* /usr/local/include/google
COPY --from=builder /pb/bin/protoc /usr/local/bin/
COPY --from=builder /go/bin/protoc-gen-go /usr/local/bin/

RUN git clone -b ${GRPC_GATEWAY_VERSION} --depth 1 https://github.com/grpc-ecosystem/grpc-gateway /go/src/github.com/grpc-ecosystem/grpc-gateway && \
    go install github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway && \
    go install github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger && \
    git clone -b ${GOGO_PROTO_VERSION} --depth 1 https://github.com/gogo/protobuf /go/src/github.com/gogo/protobuf && \
    git clone https://github.com/googleapis/googleapis /go/src/github.com/googleapis/googleapis && \
    cd /go/src/github.com/googleapis/googleapis && \
    git reset --hard ${GOOGLEAPI_VERSION}

ENTRYPOINT ["/usr/local/bin/protoc", \
            "-I/usr/local/include",  \
            "-I/go/src/github.com/grpc-ecosystem/grpc-gateway", \
            "-I/go/src/github.com/gogo/protobuf", \
            "-I/go/src/github.com/googleapis/googleapis"]
CMD []
