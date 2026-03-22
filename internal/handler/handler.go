package handler

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/shashankx86/kuberedis/internal/store"
)

type Handler struct {
	store *store.KVStore
}

func New(s *store.KVStore) *Handler {
	return &Handler{store: s}
}

// Register wires routes onto the provided mux.
func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("/health", h.health)
	mux.HandleFunc("/keys/", h.keys)
}

func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func (h *Handler) keys(w http.ResponseWriter, r *http.Request) {
	key := strings.TrimPrefix(r.URL.Path, "/keys/")
	if key == "" {
		http.Error(w, `{"error":"key is required"}`, http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodGet:
		h.getKey(w, key)
	case http.MethodPut:
		h.putKey(w, r, key)
	case http.MethodDelete:
		h.deleteKey(w, key)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handler) getKey(w http.ResponseWriter, key string) {
	val, ok := h.store.Get(key)
	if !ok {
		http.Error(w, `{"error":"key not found"}`, http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"key": key, "value": val})
}

func (h *Handler) putKey(w http.ResponseWriter, r *http.Request, key string) {
	var body struct {
		Value string `json:"value"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, `{"error":"invalid json body"}`, http.StatusBadRequest)
		return
	}
	h.store.Set(key, body.Value)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"key": key, "value": body.Value})
}

func (h *Handler) deleteKey(w http.ResponseWriter, key string) {
	if !h.store.Delete(key) {
		http.Error(w, `{"error":"key not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
