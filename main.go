package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	// Define routes
	http.HandleFunc("/", homeHandler)
	http.HandleFunc("/health", healthHandler)

	// Start the server
	port := ":8080"
	fmt.Printf("Starting eevis-go server on port %s\n", port)
	log.Fatal(http.ListenAndServe(port, nil))
}

// homeHandler handles requests to the root path
func homeHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Welcome to eevis-go!\n")
	fmt.Fprintf(w, "This is a simple Go web application.\n")
}

// healthHandler provides a health check endpoint
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status": "healthy", "service": "eevis-go"}`)
}
