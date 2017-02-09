package main

import (
	"encoding/json"
	"github.com/thoas/stats"
	"log"
	"net/http"
	"os"
)

func main() {
	middleware := stats.New()
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte("{\"hello\": \"world\"}"))
	})
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
