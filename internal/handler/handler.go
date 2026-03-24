package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"github.com/shashankx86/kuberedis/internal/store"
)

type Handler struct {
	store store.Store
}

func New(s store.Store) *Handler {
	return &Handler{store: s}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("/health", h.health)
	mux.HandleFunc("/ready", h.ready)
	mux.HandleFunc("/keys/", h.keys)
}

func (h *Handler) health(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func (h *Handler) ready(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if err := h.store.Ping(r.Context()); err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		json.NewEncoder(w).Encode(map[string]string{"status": "not ready", "error": err.Error()})
		return
	}
	json.NewEncoder(w).Encode(map[string]string{"status": "ready"})
}

func (h *Handler) keys(w http.ResponseWriter, r *http.Request) {
	key := strings.TrimPrefix(r.URL.Path, "/keys/")
	if key == "" {
		http.Error(w, `{"error":"key is required"}`, http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodGet:
		h.getKey(w, r, key)
	case http.MethodPut:
		h.putKey(w, r, key)
	case http.MethodDelete:
		h.deleteKey(w, r, key)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handler) getKey(w http.ResponseWriter, r *http.Request, key string) {
	val, ok, err := h.store.Get(r.Context(), key)
	if err != nil {
		log.Printf("store GET error: %v", err)
		http.Error(w, `{"error":"internal server error"}`, http.StatusInternalServerError)
		return
	}
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
	if err := h.store.Set(r.Context(), key, body.Value); err != nil {
		log.Printf("store SET error: %v", err)
		http.Error(w, `{"error":"internal server error"}`, http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"key": key, "value": body.Value})
}

func (h *Handler) deleteKey(w http.ResponseWriter, r *http.Request, key string) {
	existed, err := h.store.Delete(r.Context(), key)
	if err != nil {
		log.Printf("store DEL error: %v", err)
		http.Error(w, `{"error":"internal server error"}`, http.StatusInternalServerError)
		return
	}
	if !existed {
		http.Error(w, `{"error":"key not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
