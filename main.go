package main

import (
    "log"
    "net/http"
    
    "github.com/gorilla/mux"
    "go-microservice/handlers"
    "go-microservice/metrics"
    "go-microservice/utils"
)

func main() {
    router := mux.NewRouter()
    
    userHandler := handlers.NewUserHandler()
    
    // API routes с middleware
    apiRouter := router.PathPrefix("/api").Subrouter()
    apiRouter.Use(utils.RateLimitMiddleware)
    apiRouter.Use(metrics.MetricsMiddleware)
    
    apiRouter.HandleFunc("/users", userHandler.GetUsers).Methods("GET")
    apiRouter.HandleFunc("/users/{id}", userHandler.GetUser).Methods("GET")
    apiRouter.HandleFunc("/users", userHandler.CreateUser).Methods("POST")
    apiRouter.HandleFunc("/users/{id}", userHandler.UpdateUser).Methods("PUT")
    apiRouter.HandleFunc("/users/{id}", userHandler.DeleteUser).Methods("DELETE")
	apiRouter.HandleFunc("/users/{id}/avatar", userHandler.UploadUserAvatar).Methods("POST")
    
    // Метрики (без rate limiting)
    metrics.RegisterMetricsHandler(router)
    
    // Health check
    router.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(`{"status": "healthy"}`))
    }).Methods("GET")
    
    log.Println("Server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", router))
}