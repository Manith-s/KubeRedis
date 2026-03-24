package store

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

type RedisStore struct {
	client *redis.Client
}

func NewRedis(addr, password string, db int) (*RedisStore, error) {
	client := redis.NewClient(&redis.Options{
		Addr:         addr,
		Password:     password,
		DB:           db,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		client.Close()
		return nil, fmt.Errorf("redis ping failed: %w", err)
	}

	return &RedisStore{client: client}, nil
}

func (s *RedisStore) Get(ctx context.Context, key string) (string, bool, error) {
	val, err := s.client.Get(ctx, key).Result()
	if err == redis.Nil {
		return "", false, nil
	}
	if err != nil {
		return "", false, fmt.Errorf("redis GET: %w", err)
	}
	return val, true, nil
}

func (s *RedisStore) Set(ctx context.Context, key, value string) error {
	if err := s.client.Set(ctx, key, value, 0).Err(); err != nil {
		return fmt.Errorf("redis SET: %w", err)
	}
	return nil
}

func (s *RedisStore) Delete(ctx context.Context, key string) (bool, error) {
	n, err := s.client.Del(ctx, key).Result()
	if err != nil {
		return false, fmt.Errorf("redis DEL: %w", err)
	}
	return n > 0, nil
}

func (s *RedisStore) Ping(ctx context.Context) error {
	return s.client.Ping(ctx).Err()
}

func (s *RedisStore) Close() error {
	return s.client.Close()
}
