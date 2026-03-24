package store

import (
	"context"
	"sync"
)

type Store interface {
	Get(ctx context.Context, key string) (string, bool, error)
	Set(ctx context.Context, key, value string) error
	Delete(ctx context.Context, key string) (bool, error)
	Ping(ctx context.Context) error
	Close() error
}

type MemoryStore struct {
	mu   sync.RWMutex
	data map[string]string
}

func NewMemory() *MemoryStore {
	return &MemoryStore{data: make(map[string]string)}
}

func (s *MemoryStore) Get(_ context.Context, key string) (string, bool, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	v, ok := s.data[key]
	return v, ok, nil
}

func (s *MemoryStore) Set(_ context.Context, key, value string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data[key] = value
	return nil
}

func (s *MemoryStore) Delete(_ context.Context, key string) (bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, ok := s.data[key]
	if ok {
		delete(s.data, key)
	}
	return ok, nil
}

func (s *MemoryStore) Ping(_ context.Context) error {
	return nil
}

func (s *MemoryStore) Close() error {
	return nil
}
