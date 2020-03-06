#!/bin/bash

# Compile gRPC code for Go
# Run gnorm to generate the proto file first

echo -e "[+] Generating Go-gPRC from proto files"

protoc \
-I "./" \
-I="${GOPATH}/src/" \
-I="${GOPATH}/src/github.com/gogo/protobuf/protobuf/" \
--gogofast_out="plugins=grpc,\
Mgoogle/protobuf/wrappers.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types:\
./" \
./generated/generated.proto