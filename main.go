package main

import (
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-contrib/sessions"
	"github.com/gin-contrib/sessions/cookie"
	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"github.com/joho/godotenv"
)

var db *sql.DB

// Config holds application configuration
type Config struct {
	DBUser        string
	DBPassword    string
	DBHost        string
	DBPort        string
	DBName        string
	AppPort       string
	SessionSecret string
	UseTLS        bool
	TLSCertFile   string
	TLSKeyFile    string
	AppEnv        string
}

// LoadConfig loads configuration from environment variables
func LoadConfig() *Config {
	return &Config{
		DBUser:        getEnv("DB_USER", "eevis"),
		DBPassword:    getEnv("DB_PASSWORD", ""),
		DBHost:        getEnv("DB_HOST", "localhost"),
		DBPort:        getEnv("DB_PORT", "3306"),
		DBName:        getEnv("DB_NAME", "eevis"),
		AppPort:       getEnv("APP_PORT", "8080"),
		SessionSecret: getEnv("SESSION_SECRET", "change-this-secret-key"),
		UseTLS:        getEnv("USE_TLS", "false") == "true",
		TLSCertFile:   getEnv("TLS_CERT_FILE", ""),
		TLSKeyFile:    getEnv("TLS_KEY_FILE", ""),
		AppEnv:        getEnv("APP_ENV", "development"),
	}
}

// getEnv gets an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// sha256sum hashes a string using SHA256
func sha256sum(s string) string {
	h := sha256.Sum256([]byte(s))
	return hex.EncodeToString(h[:])
}

// User struct represents a user in the database
type User struct {
	ID             int
	Username       string
	Email          string
	HashedPassword string
	IsLoggedIn     bool
	IsAdmin        bool
}

// Initialize database connection
func initDB(config *Config) error {
	var err error
	// Connection string: username:password@tcp(host:port)/database
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true",
		config.DBUser,
		config.DBPassword,
		config.DBHost,
		config.DBPort,
		config.DBName,
	)
	db, err = sql.Open("mysql", dsn)
	if err != nil {
		return err
	}

	// Test the connection
	err = db.Ping()
	if err != nil {
		return err
	}

	log.Println("Database connection established")
	return nil
}

// getUserByUsername retrieves a user from the database by username
func getUserByUsername(username string) (*User, error) {
	user := &User{}
	query := "SELECT id, username, email, hashed_password, is_logged_in, is_admin FROM users WHERE username = ?"
	err := db.QueryRow(query, username).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.HashedPassword,
		&user.IsLoggedIn,
		&user.IsAdmin,
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}

// Middleware to require authentication
func requireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")

		if username == nil {
			c.HTML(http.StatusUnauthorized, "error.html", gin.H{
				"error":   "Unauthorized",
				"message": "You must be logged in to access this page.",
				"homeUrl": "/eevis",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// Middleware to require admin privileges
func requireAdmin() gin.HandlerFunc {
	return func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")

		if username == nil {
			c.HTML(http.StatusUnauthorized, "error.html", gin.H{
				"error":   "Unauthorized",
				"message": "You must be logged in to access this page.",
				"homeUrl": "/eevis",
			})
			c.Abort()
			return
		}

		// Get user from database to check admin status
		user, err := getUserByUsername(username.(string))
		if err != nil || !user.IsAdmin {
			c.HTML(http.StatusForbidden, "error.html", gin.H{
				"error":   "Forbidden",
				"message": "You must be an administrator to access this page.",
				"homeUrl": "/eevis",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

func main() {
	// Load environment variables from .env file
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using environment variables or defaults")
	}

	// Load configuration
	config := LoadConfig()

	// Set Gin mode based on environment
	if config.AppEnv == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Initialize database
	if err := initDB(config); err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Create Gin router
	r := gin.Default()

	// Setup session store
	store := cookie.NewStore([]byte(config.SessionSecret))
	r.Use(sessions.Sessions("eevis-session", store))

	// Load HTML templates
	r.LoadHTMLGlob("eevis/*.html")

	// Serve static files from visual directory
	r.Static("/eevis/visual", "./visual")

	r.GET("/eevis", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		isLoggedIn := username != nil
		isAdmin := false

		if isLoggedIn {
			user, err := getUserByUsername(username.(string))
			if err == nil && user.IsAdmin {
				isAdmin = true
			}
		}

		c.HTML(http.StatusOK, "home.html", gin.H{
			"username":   username,
			"isLoggedIn": isLoggedIn,
			"isAdmin":    isAdmin,
		})
	})

	// Login page
	r.GET("/eevis/login", func(c *gin.Context) {
		c.HTML(http.StatusOK, "login.html", nil)
	})

	// Login handler
	r.POST("/eevis/login", func(c *gin.Context) {
		username := c.PostForm("username")
		password := c.PostForm("password")

		// Get user from database
		_, err := getUserByUsername(username)
		if err != nil {
			c.HTML(http.StatusOK, "login.html", gin.H{
				"error": "Invalid username or password",
			})
			return
		}

		// In production, use proper password hashing comparison (bcrypt)
		// For now, we'll just check if user exists
		if username != "" && password != "" {
			session := sessions.Default(c)
			session.Set("username", username)
			session.Save()

			c.Redirect(http.StatusFound, "/eevis")
			return
		}

		c.HTML(http.StatusOK, "login.html", gin.H{
			"error": "Invalid username or password",
		})
	})

	// Logout handler
	r.GET("/eevis/logout", func(c *gin.Context) {
		session := sessions.Default(c)
		session.Clear()
		session.Save()

		c.Redirect(http.StatusFound, "/eevis")
	})

	// Protected routes - Admin only
	adminRoutes := r.Group("/eevis")
	adminRoutes.Use(requireAuth(), requireAdmin())
	{
		// GET /eevis/report-issue - Display issue reporting form
		adminRoutes.GET("/report-issue", func(c *gin.Context) {
			session := sessions.Default(c)
			username := session.Get("username")

			c.HTML(http.StatusOK, "report_issue.html", gin.H{
				"username": username,
			})
		})

		// POST /eevis/report-issue - Submit GitHub issue
		adminRoutes.POST("/report-issue", func(c *gin.Context) {
			log.Printf("POST /eevis/report-issue from %s", c.ClientIP())
			session := sessions.Default(c)
			username := session.Get("username")

			title := c.PostForm("title")
			body := c.PostForm("body")
			repo := c.PostForm("repo")

			if title == "" || body == "" || repo == "" {
				log.Printf("Missing form data from user %v", username)
				c.HTML(http.StatusOK, "report_issue.html", gin.H{
					"username": username,
					"error":    "Missing title, description, or repository",
				})
				return
			}

			if repo != "eevis-go" && repo != "eevis_flutter" {
				log.Printf("Invalid repo selection '%s' from user %v", repo, username)
				c.HTML(http.StatusOK, "report_issue.html", gin.H{
					"username": username,
					"error":    "Invalid repository selection",
				})
				return
			}

			// Create GitHub issue
			githubToken := os.Getenv("GITHUB_TOKEN")
			if githubToken == "" {
				c.HTML(http.StatusOK, "report_issue.html", gin.H{
					"username": username,
					"error":    "GitHub token not configured",
				})
				return
			}

			owner := "vaccs"
			apiURL := "https://api.github.com/repos/" + owner + "/" + repo + "/issues"

			client := &http.Client{Timeout: 10 * time.Second}
			reqBody := `{"title":"` + title + `","body":"` + body + `"}`
			req, err := http.NewRequest("POST", apiURL, strings.NewReader(reqBody))
			if err != nil {
				c.HTML(http.StatusOK, "report_issue.html", gin.H{
					"username": username,
					"error":    "Failed to create request",
				})
				return
			}

			req.Header.Set("Authorization", "token "+githubToken)
			req.Header.Set("Accept", "application/vnd.github+json")
			req.Header.Set("Content-Type", "application/json")

			resp, err := client.Do(req)
			if err != nil {
				log.Printf("GitHub API error: %v", err)
				c.HTML(http.StatusOK, "report_issue.html", gin.H{
					"username": username,
					"error":    "GitHub API error",
				})
				return
			}
			defer resp.Body.Close()

			if resp.StatusCode != 201 {
				log.Printf("Failed to create issue, status: %d", resp.StatusCode)
				c.HTML(http.StatusOK, "report_issue.html", gin.H{
					"username": username,
					"error":    "Failed to create issue",
				})
				return
			}

			log.Printf("User %v successfully created issue in %s", username, repo)
			c.HTML(http.StatusOK, "report_issue.html", gin.H{
				"username": username,
				"success":  "Issue submitted successfully!",
			})
		})

		// GET /eevis/add-user - Display add user form
		adminRoutes.GET("/add-user", func(c *gin.Context) {
			session := sessions.Default(c)
			username := session.Get("username")

			c.HTML(http.StatusOK, "add_user.html", gin.H{
				"username": username,
			})
		})

		// POST /eevis/add-user - Process add user form
		adminRoutes.POST("/add-user", func(c *gin.Context) {
			log.Printf("POST /eevis/add-user from %s", c.ClientIP())
			session := sessions.Default(c)
			username := session.Get("username")

			newUsername := c.PostForm("username")
			email := c.PostForm("email")
			password := c.PostForm("password")
			confirmPassword := c.PostForm("confirm_password")
			isAdmin := c.PostForm("is_admin") == "true"

			// Validate required fields
			if newUsername == "" || email == "" || password == "" {
				log.Printf("Missing required fields in add user form")
				c.HTML(http.StatusOK, "add_user.html", gin.H{
					"username": username,
					"error":    "All fields are required",
				})
				return
			}

			// Validate password confirmation
			if password != confirmPassword {
				log.Printf("Password confirmation mismatch")
				c.HTML(http.StatusOK, "add_user.html", gin.H{
					"username": username,
					"error":    "Passwords do not match",
				})
				return
			}

			// Check if username or email already exists
			var existingCount int
			err := db.QueryRow("SELECT COUNT(*) FROM users WHERE username=? OR email=?", newUsername, email).Scan(&existingCount)
			if err != nil {
				log.Printf("Database error checking existing user: %v", err)
				c.HTML(http.StatusOK, "add_user.html", gin.H{
					"username": username,
					"error":    "Database error",
				})
				return
			}

			if existingCount > 0 {
				log.Printf("Username or email already exists: %s, %s", newUsername, email)
				c.HTML(http.StatusOK, "add_user.html", gin.H{
					"username": username,
					"error":    "Username or email already exists",
				})
				return
			}

			// Hash password using SHA256
			hashedPassword := sha256sum(password)

			// Insert new user
			_, err = db.Exec("INSERT INTO users (username, email, hashed_password, is_logged_in, is_admin) VALUES (?, ?, ?, FALSE, ?)",
				newUsername, email, hashedPassword, isAdmin)
			if err != nil {
				log.Printf("Failed to insert new user: %v", err)
				c.HTML(http.StatusOK, "add_user.html", gin.H{
					"username": username,
					"error":    "Failed to create user",
				})
				return
			}

			log.Printf("Admin %v successfully created user: %s (email: %s, admin: %v)", username, newUsername, email, isAdmin)
			c.HTML(http.StatusOK, "add_user.html", gin.H{
				"username": username,
				"success":  "User created successfully!",
			})
		})
	}

	// Health check endpoint
	r.GET("/eevis/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "eevis-go",
		})
	})

	// Start the server
	serverAddr := ":" + config.AppPort

	if config.UseTLS {
		// Validate TLS configuration
		if config.TLSCertFile == "" || config.TLSKeyFile == "" {
			log.Fatal("TLS is enabled but TLS_CERT_FILE or TLS_KEY_FILE is not set")
		}

		log.Printf("Starting EEVIS server with TLS on https://localhost%s\n", serverAddr)
		if err := r.RunTLS(serverAddr, config.TLSCertFile, config.TLSKeyFile); err != nil {
			log.Fatalf("Failed to start server with TLS: %v", err)
		}
	} else {
		log.Printf("Starting EEVIS server on http://localhost%s\n", serverAddr)
		if err := r.Run(serverAddr); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}
}
