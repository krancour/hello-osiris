package http

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"
)

// GetHelloHandler returns a "hello world" handler.
func GetHelloHandler(withTLS bool) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		logRequest(r, withTLS)
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		w.Write([]byte("Hello, World!")) // nolint: errcheck
	}
}

// GetClockStreamHandler returns a handler that streams a response with the
// current time, once per second.
func GetClockStreamHandler(
	withTLS bool,
) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		logRequest(r, withTLS)
		clientGone := w.(http.CloseNotifier).CloseNotify()
		w.Header().Set("Content-Type", "text/event-stream")
		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()
		fmt.Fprintf(
			w,
			"# ~1KB of junk to force browsers to start rendering immediately: \n",
		)
		io.WriteString( // nolint: errcheck
			w,
			strings.Repeat(
				"# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n", // nolint: lll
				13,
			),
		)
		for {
			fmt.Fprintf(w, "%v\n", time.Now())
			w.(http.Flusher).Flush()
			select {
			case <-ticker.C:
			case <-clientGone:
				log.Printf("Client %v disconnected from the clock", r.RemoteAddr)
				return
			}
		}
	}
}

// HealthzHandler implements the application's health check.
func HealthzHandler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("{}")) // nolint: errcheck
}
