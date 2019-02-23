package main

import (
	"flag"
	"log"
	"net"
	"net/http"

	mygrpc "github.com/krancour/hello-osiris/pkg/grpc"
	pb "github.com/krancour/hello-osiris/pkg/helloworld"
	myhttp "github.com/krancour/hello-osiris/pkg/http"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
	"google.golang.org/grpc"
)

// nolint: lll
var (
	http1xAddr = flag.String("http1x-addr", ":8080", "address for serving HTTP 1.x requests (no TLS)")
	h2cAddr    = flag.String("h2c-addr", ":8081", "address for serving h2c requests (HTTP/2 without TLS)")
	httpsAddr  = flag.String("https-addr", ":4430", "address for serving HTTPS requests (HTTP/1.x OR HTTP/2 with TLS)")
	httpsCert  = flag.String("https-cert", "server.crt", "cert for securing HTTPS requests (HTTP/1.x OR HTTP/2 with TLS)")
	httpsKey   = flag.String("https-key", "server.key", "private key for securing HTTPS requests (HTTP/1.x OR HTTP/2 with TLS)")
	grpcAddr   = flag.String("grpc-addr", ":8082", "address for serving insecure gRPC (no TLS)")
)

func main() {
	flag.Parse()

	log.Printf("Listening for HTTP/1.x without TLS on %s", *http1xAddr)
	go func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/", myhttp.GetHelloHandler(false))
		mux.HandleFunc("/healthz", myhttp.HealthzHandler)
		log.Fatal(http.ListenAndServe(*http1xAddr, mux))
	}()

	log.Printf("Listening for h2c (HTTP/2 without TLS) on %s", *h2cAddr)
	go func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/", myhttp.GetHelloHandler(false))
		mux.HandleFunc("/clockstream", myhttp.GetClockStreamHandler(false))
		log.Fatal(
			http.ListenAndServe(*h2cAddr, h2c.NewHandler(mux, &http2.Server{})),
		)
	}()

	log.Printf(
		"Listening for HTTPS (HTTP/1.x OR HTTP/2 with TLS) on %s",
		*httpsAddr,
	)
	go func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/", myhttp.GetHelloHandler(true))
		mux.HandleFunc("/clockstream", myhttp.GetClockStreamHandler(true))
		log.Fatal(
			http.ListenAndServeTLS(*httpsAddr, *httpsCert, *httpsKey, mux),
		)
	}()

	log.Printf(
		"Listening for insecure gRPC (no TLS) on %s",
		*grpcAddr,
	)
	go func() {
		listener, err := net.Listen("tcp", *grpcAddr)
		if err != nil {
			log.Fatalf("failed to listen: %s", err)
		}
		server := grpc.NewServer()
		pb.RegisterGreeterServer(server, &mygrpc.Server{})
		log.Fatal(server.Serve(listener))
	}()

	log.Println(
		"Note: Due to limitations of SNI, Osiris only supports one TLS-enabled " +
			"port per application, so this example does not demonstrate gRPC with " +
			"TLS, although this combination should work.",
	)

	select {}
}
