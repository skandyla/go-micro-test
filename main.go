package main

import (
    "fmt"
    "net/http"
    "log"
    "os"
)

func Log(handler http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	hostname, err := os.Hostname()
	if err != nil {
      fmt.Printf("Oops:   %v\n", err)
      return
	}
    log.Printf("%s %s %s %s - %s", r.RemoteAddr, r.Method, r.Host, r.URL, hostname)
	handler.ServeHTTP(w, r)
    })
}

func main() {
	hostname, err := os.Hostname()
	if err != nil {
      fmt.Printf("Oops:   %v\n", err)
      return
	}
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello %s - %s!", r.URL.Path[1:], hostname)
    })
    http.ListenAndServe(":8080", Log(http.DefaultServeMux))
}

