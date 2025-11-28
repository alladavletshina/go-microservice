package metrics

import (
    "net/http"
    "time"
    "github.com/gorilla/mux"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    TotalRequests = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint"},
    )

    RequestDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "Request duration in seconds",
        },
        []string{"method", "endpoint"},
    )
)

func MetricsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        
        // Получаем путь для метрик
        route := mux.CurrentRoute(r)
        path, _ := route.GetPathTemplate()
        
        next.ServeHTTP(w, r)
        
        duration := time.Since(start).Seconds()
        TotalRequests.WithLabelValues(r.Method, path).Inc()
        RequestDuration.WithLabelValues(r.Method, path).Observe(duration)
    })
}

func RegisterMetricsHandler(router *mux.Router) {
    router.Handle("/metrics", promhttp.Handler())
}
