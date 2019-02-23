package http

import (
	"log"
	"net/http"
)

func logRequest(r *http.Request, withTLS bool) {
	var withOrWithout string
	if withTLS {
		withOrWithout = "with"
	} else {
		withOrWithout = "without"
	}
	log.Printf(
		"Received: %s %s %s (%s TLS)",
		r.Method,
		r.URL.Path,
		r.Proto,
		withOrWithout,
	)
}
