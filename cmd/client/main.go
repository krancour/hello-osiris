package main

import (
	"context"
	"log"
	"os"
	"time"

	pb "github.com/krancour/hello-osiris/pkg/helloworld"
	"google.golang.org/grpc"
)

const defaultAddress = "localhost:8082"

func main() {
	var address string
	if len(os.Args) > 1 {
		address = os.Args[1]
	} else {
		address = defaultAddress
	}
	conn, err := grpc.Dial(address, grpc.WithInsecure())
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()
	c := pb.NewGreeterClient(conn)
	// Use a big timeout because if we need to scale up from zero on a node
	// where the Docker image cache isn't warm, we could be here a while...
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	r, err := c.SayHello(ctx, &pb.HelloRequest{})
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Greeting: %s", r.Message)
}
