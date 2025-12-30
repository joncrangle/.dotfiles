# Go Production Examples

Production-ready code examples for Go 1.23+ applications.

---

## REST API: Complete Chi Application

```go
// main.go
package main

import (
    "context"
    "encoding/json"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/go-chi/chi/v5"
    "github.com/go-chi/chi/v5/middleware"
    "github.com/go-chi/cors"
    "github.com/go-playground/validator/v10"
    "github.com/jackc/pgx/v5/pgxpool"
)

type App struct {
    router   *chi.Mux
    db       *pgxpool.Pool
    server   *http.Server
    validate *validator.Validate
}

func main() {
    pool, err := pgxpool.New(context.Background(),
        os.Getenv("DATABASE_URL"))
    if err != nil {
        log.Fatal(err)
    }

    app := NewApp(pool)

    // Graceful shutdown
    go func() {
        if err := app.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("listen: %s\n", err)
        }
    }()

    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    log.Println("Shutting down server...")

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    if err := app.server.Shutdown(ctx); err != nil {
        log.Fatal("Server forced to shutdown:", err)
    }
    pool.Close()

    log.Println("Server exiting")
}

func NewApp(db *pgxpool.Pool) *App {
    r := chi.NewRouter()
    r.Use(middleware.Logger)
    r.Use(middleware.Recoverer)
    r.Use(cors.Handler(cors.Options{
        AllowedOrigins:   []string{"https://*", "http://*"},
        AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
        ExposedHeaders:   []string{"Link"},
        AllowCredentials: false,
        MaxAge:           300,
    }))

    app := &App{
        router:   r,
        db:       db,
        validate: validator.New(),
        server: &http.Server{
            Addr:         ":3000",
            Handler:      r,
            ReadTimeout:  10 * time.Second,
            WriteTimeout: 10 * time.Second,
        },
    }

    app.setupRoutes()
    return app
}

func (a *App) setupRoutes() {
    a.router.Get("/health", func(w http.ResponseWriter, r *http.Request) {
        respondJSON(w, http.StatusOK, map[string]string{"status": "ok"})
    })

    a.router.Route("/api/v1", func(r chi.Router) {
        r.Route("/users", func(r chi.Router) {
            r.Get("/", a.listUsers)
            r.Get("/{id}", a.getUser)
            r.Post("/", a.createUser)
            r.Put("/{id}", a.updateUser)
            r.Delete("/{id}", a.deleteUser)
        })
    })
}

// Models
type User struct {
    ID        int64     `json:"id"`
    Name      string    `json:"name"`
    Email     string    `json:"email"`
    CreatedAt time.Time `json:"created_at"`
}

type CreateUserRequest struct {
    Name  string `json:"name" validate:"required,min=2"`
    Email string `json:"email" validate:"required,email"`
}

// Helper functions
func respondJSON(w http.ResponseWriter, status int, payload interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(payload)
}

func respondError(w http.ResponseWriter, status int, message string) {
    respondJSON(w, status, map[string]string{"error": message})
}

// Handlers
func (a *App) listUsers(w http.ResponseWriter, r *http.Request) {
    rows, err := a.db.Query(r.Context(),
        "SELECT id, name, email, created_at FROM users ORDER BY created_at DESC LIMIT 10")
    if err != nil {
        respondError(w, http.StatusInternalServerError, err.Error())
        return
    }
    defer rows.Close()

    var users []User
    for rows.Next() {
        var u User
        if err := rows.Scan(&u.ID, &u.Name, &u.Email, &u.CreatedAt); err != nil {
            respondError(w, http.StatusInternalServerError, err.Error())
            return
        }
        users = append(users, u)
    }

    respondJSON(w, http.StatusOK, users)
}

func (a *App) getUser(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")

    var u User
    err := a.db.QueryRow(r.Context(),
        "SELECT id, name, email, created_at FROM users WHERE id = $1", id).
        Scan(&u.ID, &u.Name, &u.Email, &u.CreatedAt)
    if err != nil {
        respondError(w, http.StatusNotFound, "User not found")
        return
    }

    respondJSON(w, http.StatusOK, u)
}

func (a *App) createUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondError(w, http.StatusBadRequest, err.Error())
        return
    }

    if err := a.validate.Struct(req); err != nil {
        respondError(w, http.StatusBadRequest, err.Error())
        return
    }

    var u User
    err := a.db.QueryRow(r.Context(),
        "INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id, name, email, created_at",
        req.Name, req.Email).
        Scan(&u.ID, &u.Name, &u.Email, &u.CreatedAt)
    if err != nil {
        respondError(w, http.StatusInternalServerError, err.Error())
        return
    }

    respondJSON(w, http.StatusCreated, u)
}

func (a *App) updateUser(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")

    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondError(w, http.StatusBadRequest, err.Error())
        return
    }

    if err := a.validate.Struct(req); err != nil {
        respondError(w, http.StatusBadRequest, err.Error())
        return
    }

    var u User
    err := a.db.QueryRow(r.Context(),
        "UPDATE users SET name = $2, email = $3 WHERE id = $1 RETURNING id, name, email, created_at",
        id, req.Name, req.Email).
        Scan(&u.ID, &u.Name, &u.Email, &u.CreatedAt)
    if err != nil {
        respondError(w, http.StatusNotFound, "User not found")
        return
    }

    respondJSON(w, http.StatusOK, u)
}

func (a *App) deleteUser(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")

    result, err := a.db.Exec(r.Context(), "DELETE FROM users WHERE id = $1", id)
    if err != nil {
        respondError(w, http.StatusInternalServerError, err.Error())
        return
    }

    if result.RowsAffected() == 0 {
        respondError(w, http.StatusNotFound, "User not found")
        return
    }

    w.WriteHeader(http.StatusNoContent)
}
```

---

## CLI Tool: Complete Cobra Application

```go
// main.go
package main

import (
    "fmt"
    "os"

    "github.com/spf13/cobra"
    "github.com/spf13/viper"
)

var (
    cfgFile string
    verbose bool
)

func main() {
    if err := rootCmd.Execute(); err != nil {
        fmt.Fprintln(os.Stderr, err)
        os.Exit(1)
    }
}

var rootCmd = &cobra.Command{
    Use:   "myctl",
    Short: "A CLI tool for managing resources",
    Long:  `myctl is a comprehensive CLI tool for managing cloud resources.`,
    PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
        return initConfig()
    },
}

func init() {
    rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file")
    rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")

    rootCmd.AddCommand(serveCmd)
    rootCmd.AddCommand(migrateCmd)
    rootCmd.AddCommand(userCmd)
}

// Serve command
var serveCmd = &cobra.Command{
    Use:   "serve",
    Short: "Start the API server",
    RunE: func(cmd *cobra.Command, args []string) error {
        port, _ := cmd.Flags().GetInt("port")
        fmt.Printf("Starting server on port %d...\n", port)
        return nil
    },
}

func init() {
    serveCmd.Flags().IntP("port", "p", 3000, "Port to listen on")
    viper.BindPFlag("server.port", serveCmd.Flags().Lookup("port"))
}

// Migrate command
var migrateCmd = &cobra.Command{
    Use:   "migrate",
    Short: "Run database migrations",
}

var migrateUpCmd = &cobra.Command{
    Use:   "up",
    Short: "Run all pending migrations",
    RunE: func(cmd *cobra.Command, args []string) error {
        fmt.Println("Running migrations...")
        return nil
    },
}

var migrateDownCmd = &cobra.Command{
    Use:   "down",
    Short: "Rollback last migration",
    RunE: func(cmd *cobra.Command, args []string) error {
        steps, _ := cmd.Flags().GetInt("steps")
        fmt.Printf("Rolling back %d migrations...\n", steps)
        return nil
    },
}

func init() {
    migrateDownCmd.Flags().IntP("steps", "n", 1, "Number of migrations to rollback")
    migrateCmd.AddCommand(migrateUpCmd)
    migrateCmd.AddCommand(migrateDownCmd)
}

// User command
var userCmd = &cobra.Command{
    Use:   "user",
    Short: "Manage users",
}

var userListCmd = &cobra.Command{
    Use:   "list",
    Short: "List all users",
    RunE: func(cmd *cobra.Command, args []string) error {
        limit, _ := cmd.Flags().GetInt("limit")
        fmt.Printf("Listing %d users...\n", limit)
        return nil
    },
}

var userCreateCmd = &cobra.Command{
    Use:   "create [name] [email]",
    Short: "Create a new user",
    Args:  cobra.ExactArgs(2),
    RunE: func(cmd *cobra.Command, args []string) error {
        name, email := args[0], args[1]
        fmt.Printf("Creating user: %s <%s>\n", name, email)
        return nil
    },
}

func init() {
    userListCmd.Flags().IntP("limit", "l", 10, "Limit results")
    userCmd.AddCommand(userListCmd)
    userCmd.AddCommand(userCreateCmd)
}

func initConfig() error {
    if cfgFile != "" {
        viper.SetConfigFile(cfgFile)
    } else {
        home, err := os.UserHomeDir()
        if err != nil {
            return err
        }
        viper.AddConfigPath(home)
        viper.SetConfigName(".myctl")
    }

    viper.SetEnvPrefix("MYCTL")
    viper.AutomaticEnv()

    if err := viper.ReadInConfig(); err == nil {
        if verbose {
            fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
        }
    }

    return nil
}
```

---

## Concurrency: Worker Pool

```go
package main

import (
    "context"
    "fmt"
    "sync"
    "time"

    "golang.org/x/sync/errgroup"
    "golang.org/x/sync/semaphore"
)

type Job struct {
    ID   int
    Data string
}

type Result struct {
    JobID int
    Data  string
    Error error
}

// Worker pool with fixed number of workers
func workerPool(ctx context.Context, jobs <-chan Job, numWorkers int) <-chan Result {
    results := make(chan Result, 100)

    var wg sync.WaitGroup
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func(workerID int) {
            defer wg.Done()
            for job := range jobs {
                select {
                case <-ctx.Done():
                    return
                default:
                    result := processJob(job)
                    results <- result
                }
            }
        }(i)
    }

    go func() {
        wg.Wait()
        close(results)
    }()

    return results
}

func processJob(job Job) Result {
    time.Sleep(100 * time.Millisecond)
    return Result{JobID: job.ID, Data: fmt.Sprintf("Processed: %s", job.Data)}
}

// Rate-limited concurrent operations with semaphore
func rateLimitedOperations(ctx context.Context, items []string, maxConcurrent int64) error {
    sem := semaphore.NewWeighted(maxConcurrent)
    g, ctx := errgroup.WithContext(ctx)

    for _, item := range items {
        item := item
        g.Go(func() error {
            if err := sem.Acquire(ctx, 1); err != nil {
                return err
            }
            defer sem.Release(1)
            return processItem(ctx, item)
        })
    }

    return g.Wait()
}

func processItem(ctx context.Context, item string) error {
    select {
    case <-ctx.Done():
        return ctx.Err()
    case <-time.After(100 * time.Millisecond):
        fmt.Printf("Processed: %s\n", item)
        return nil
    }
}

// Fan-out/fan-in pattern
func fanOutFanIn(ctx context.Context, input <-chan int, workers int) <-chan int {
    channels := make([]<-chan int, workers)
    for i := 0; i < workers; i++ {
        channels[i] = worker(ctx, input)
    }
    return merge(ctx, channels...)
}

func worker(ctx context.Context, input <-chan int) <-chan int {
    output := make(chan int)
    go func() {
        defer close(output)
        for n := range input {
            select {
            case <-ctx.Done():
                return
            case output <- n * 2:
            }
        }
    }()
    return output
}

func merge(ctx context.Context, channels ...<-chan int) <-chan int {
    output := make(chan int)
    var wg sync.WaitGroup

    for _, ch := range channels {
        wg.Add(1)
        go func(c <-chan int) {
            defer wg.Done()
            for n := range c {
                select {
                case <-ctx.Done():
                    return
                case output <- n:
                }
            }
        }(ch)
    }

    go func() {
        wg.Wait()
        close(output)
    }()

    return output
}
```

---

## Docker Deployment

### Dockerfile (Minimal ~10-20MB)

```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o main .

FROM scratch
COPY --from=builder /app/main /main
EXPOSE 3000
ENTRYPOINT ["/main"]
```

### Docker Compose

```yaml
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgres://postgres:password@db:5432/myapp
    depends_on:
      db:
        condition: service_healthy
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: "0.5"
          memory: 256M

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=myapp
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

---

## Integration Tests

```go
package main

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http/httptest"
    "strings"
    "testing"

    "github.com/gofiber/fiber/v3"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "github.com/testcontainers/testcontainers-go"
    "github.com/testcontainers/testcontainers-go/modules/postgres"
    "github.com/jackc/pgx/v5/pgxpool"
)

func setupTestDB(t *testing.T) (*pgxpool.Pool, func()) {
    ctx := context.Background()

    container, err := postgres.Run(ctx, "postgres:16-alpine",
        postgres.WithDatabase("test"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
    )
    require.NoError(t, err)

    connStr, err := container.ConnectionString(ctx, "sslmode=disable")
    require.NoError(t, err)

    pool, err := pgxpool.New(ctx, connStr)
    require.NoError(t, err)

    _, err = pool.Exec(ctx, `
        CREATE TABLE users (
            id BIGSERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT NOW()
        )
    `)
    require.NoError(t, err)

    cleanup := func() {
        pool.Close()
        container.Terminate(ctx)
    }

    return pool, cleanup
}

func TestUserAPI(t *testing.T) {
    pool, cleanup := setupTestDB(t)
    defer cleanup()

    app, _ := NewApp(Config{Port: "3000", DatabaseURL: ""})
    app.db = pool

    t.Run("create and get user", func(t *testing.T) {
        body := `{"name": "John Doe", "email": "john@example.com"}`
        req := httptest.NewRequest("POST", "/api/v1/users", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/json")

        resp, err := app.fiber.Test(req)
        require.NoError(t, err)
        assert.Equal(t, 201, resp.StatusCode)

        var created User
        json.NewDecoder(resp.Body).Decode(&created)
        assert.Equal(t, "John Doe", created.Name)
        assert.NotZero(t, created.ID)

        req = httptest.NewRequest("GET", fmt.Sprintf("/api/v1/users/%d", created.ID), nil)
        resp, err = app.fiber.Test(req)
        require.NoError(t, err)
        assert.Equal(t, 200, resp.StatusCode)

        var fetched User
        json.NewDecoder(resp.Body).Decode(&fetched)
        assert.Equal(t, created.ID, fetched.ID)
    })

    t.Run("get non-existent user", func(t *testing.T) {
        req := httptest.NewRequest("GET", "/api/v1/users/99999", nil)
        resp, err := app.fiber.Test(req)
        require.NoError(t, err)
        assert.Equal(t, 404, resp.StatusCode)
    })
}
```

---

Last Updated: 2025-12-07
Version: 1.0.0
