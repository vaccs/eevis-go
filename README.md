# eevis-go

A simple Go web application.

## Features

- Basic HTTP server
- Health check endpoint
- Simple home page

## Getting Started

### Prerequisites

- Go 1.19 or higher

### Running the Application

1. Clone or navigate to the project directory:
   ```bash
   cd ~/eevis-go
   ```

2. Run the application:
   ```bash
   go run main.go
   ```

3. The server will start on port 8080. You can access it at:
   - Home page: http://localhost:8080
   - Health check: http://localhost:8080/health

### Building the Application

To build a binary:
```bash
go build -o eevis-go main.go
```

Then run the binary:
```bash
./eevis-go
```

## API Endpoints

- `GET /` - Home page with welcome message
- `GET /health` - Health check endpoint returning JSON status

## Development

The application uses Go's standard `net/http` package for routing and serving HTTP requests.