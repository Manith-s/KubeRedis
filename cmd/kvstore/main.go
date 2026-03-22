package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/shashankx86/kuberedis/internal/handler"
	"github.com/shashankx86/kuberedis/internal/middleware"
	"github.com/shashankx86/kuberedis/internal/store"
)

func main() {
	port := envOrDefault("APP_PORT", "8080")
	logLevel := envOrDefault("LOG_LEVEL", "info")
	apiKey := os.Getenv("API_KEY")
	if apiKey == "" {
		log.Fatal("API_KEY environment variable is required")
	}

	log.Printf("starting kvstore  port=%s  log_level=%s", port, logLevel)

	kvStore := store.New()
	h := handler.New(kvStore)

	mux := http.NewServeMux()
	h.Register(mux)

	publicPaths := map[string]bool{"/health": true}
	authed := middleware.BearerAuth(apiKey, publicPaths, mux)

	addr := fmt.Sprintf(":%s", port)
	log.Printf("listening on %s", addr)
	if err := http.ListenAndServe(addr, authed); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

func envOrDefault(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
