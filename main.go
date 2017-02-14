package main

import (
	"encoding/json"
	"github.com/thoas/stats"
	"log"
	"net/http"
	"os"
    "fmt"
	"net"
)

func handlerRoot(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}
func handlerTest(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte("{\"hello\": \"world\"}"))
}
func handlerLogs(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	ip, _, _ := net.SplitHostPort(r.RemoteAddr)
    fmt.Fprintf(w, "IP: %s", ip)
}

func main() {
	middleware := stats.New()
	mux := http.NewServeMux()

    mux.HandleFunc("/", handlerRoot)
    mux.HandleFunc("/test", handlerTest)
    mux.HandleFunc("/logs", handlerLogs)

	mux.HandleFunc("/stats", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		b, _ := json.Marshal(middleware.Data())
		w.Write(b)
	})
	port := os.Getenv("PORT")
	if port == "" {
		log.Fatal("PORT environment variable was not set")
	}
	err := http.ListenAndServe(":"+port, middleware.Handler(mux))
	if err != nil {
		log.Fatal("Could not listen: ", err)
	}
}
