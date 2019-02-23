package grpc

import (
	"context"
	"log"

	pb "github.com/krancour/hello-osiris/pkg/helloworld"
)

// Server is used to implement helloworld.GreeterServer.
type Server struct{}

// SayHello implements helloworld.GreeterServer
func (s *Server) SayHello(
	context.Context,
	*pb.HelloRequest,
) (*pb.HelloReply, error) {
	log.Println("gRPC SayHello invoked")
	return &pb.HelloReply{Message: "Hello, World!"}, nil
}
