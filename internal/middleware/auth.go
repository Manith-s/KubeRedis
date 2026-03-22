package middleware

import (
	"net/http"
	"strings"
)

// BearerAuth rejects requests whose Authorization header does not carry the
// expected API key. Public paths (e.g. /health) are exempted.
func BearerAuth(apiKey string, public map[string]bool, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if public[r.URL.Path] {
			next.ServeHTTP(w, r)
			return
		}

		header := r.Header.Get("Authorization")
		if header == "" {
			http.Error(w, `{"error":"missing authorization header"}`, http.StatusUnauthorized)
			return
		}

		token := strings.TrimPrefix(header, "Bearer ")
		if token == header || token != apiKey {
			http.Error(w, `{"error":"invalid api key"}`, http.StatusForbidden)
			return
		}

		next.ServeHTTP(w, r)
	})
}
