#!/bin/bash
# scripts/deployment/deploy.sh

set -e

VERSION=${1:-latest}
STACK_NAME="neoevents"
COMPOSE_FILE="docker-stack-production.yml"

echo "🚀 Starting deployment of version: $VERSION"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if stack exists
stack_exists() {
    docker stack ls --format "table {{.Name}}" | grep -q "^${STACK_NAME}$"
}

# Function to wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local running_services=$(docker stack services $STACK_NAME --format "table {{.Name}} {{.Replicas}}" | grep -v NAME | grep "1/1" | wc -l)
        local total_services=$(docker stack services $STACK_NAME --format "table {{.Name}}" | grep -v NAME | wc -l)
        
        print_status "Services ready: $running_services/$total_services (attempt $attempt/$max_attempts)"
        
        if [ $running_services -eq $total_services ]; then
            print_status "All services are ready!"
            return 0
        fi
        
        sleep 10
        attempt=$((attempt + 1))
    done
    
    print_error "Services failed to become ready within timeout"
    return 1
}

# Function to perform health checks
health_check() {
    print_status "Performing health checks..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # Check backend health
        if curl -f -s http://localhost/api/actuator/health > /dev/null 2>&1; then
            print_status "Backend health check passed"
            # Check frontend health
            if curl -f -s http://localhost/health > /dev/null 2>&1; then
                print_status "Frontend health check passed"
                return 0
            fi
        fi
        
        print_status "Health check attempt $attempt/$max_attempts failed, retrying..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    print_error "Health checks failed"
    return 1
}

# Function to backup current deployment info
backup_deployment_info() {
    print_status "Backing up current deployment information..."
    
    mkdir -p ./deployment/backups
    
    if stack_exists; then
        # Get current image versions
        docker stack services $STACK_NAME --format "table {{.Name}} {{.Image}}" > ./deployment/backups/previous_deployment_$(date +%Y%m%d_%H%M%S).txt
        
        # Store previous version for rollback
        docker stack services $STACK_NAME --format "{{.Image}}" | grep backend | head -1 | cut -d':' -f2 > ./deployment/backups/previous_backend_version.txt
        docker stack services $STACK_NAME --format "{{.Image}}" | grep frontend | head -1 | cut -d':' -f2 > ./deployment/backups/previous_frontend_version.txt
    fi
}

# Function to rollback deployment
rollback_deployment() {
    print_error "Rolling back to previous version..."
    
    if [ -f ./deployment/backups/previous_backend_version.txt ] && [ -f ./deployment/backups/previous_frontend_version.txt ]; then
        local prev_backend_version=$(cat ./deployment/backups/previous_backend_version.txt)
        local prev_frontend_version=$(cat ./deployment/backups/previous_frontend_version.txt)
        
        print_status "Rolling back to backend: $prev_backend_version, frontend: $prev_frontend_version"
        
        export BACKEND_VERSION=$prev_backend_version
        export FRONTEND_VERSION=$prev_frontend_version
        
        docker stack deploy -c $COMPOSE_FILE $STACK_NAME
        
        if wait_for_services && health_check; then
            print_status "Rollback completed successfully"
            return 0
        else
            print_error "Rollback failed"
            return 1
        fi
    else
        print_error "No previous version information found for rollback"
        return 1
    fi
}

# Function to cleanup old images
cleanup_old_images() {
    print_status "Cleaning up old images..."
    
    # Keep last 3 versions
    docker images --format "table {{.Repository}}:{{.Tag}} {{.CreatedAt}}" | \
    grep "neoevents-" | \
    sort -k2 -r | \
    tail -n +4 | \
    awk '{print $1}' | \
    xargs -r docker rmi -f || true
}

# Main deployment logic
main() {
    print_status "Starting deployment process..."
    
    # Validate environment
    if [ -z "$VERSION" ]; then
        print_error "VERSION not specified"
        exit 1
    fi
    
    # Set image versions
    export BACKEND_VERSION=$VERSION
    export FRONTEND_VERSION=$VERSION
    
    print_status "Deploying backend version: $BACKEND_VERSION"
    print_status "Deploying frontend version: $FRONTEND_VERSION"
    
    # Backup current deployment
    backup_deployment_info
    
    # Initialize Docker Swarm if not already initialized
    if ! docker info | grep -q "Swarm: active"; then
        print_status "Initializing Docker Swarm..."
        docker swarm init
    fi
    
    # Deploy the stack
    print_status "Deploying Docker stack..."
    docker stack deploy -c $COMPOSE_FILE $STACK_NAME
    
    # Wait for services to be ready
    if ! wait_for_services; then
        print_error "Deployment failed: Services not ready"
        rollback_deployment
        exit 1
    fi
    
    # Perform health checks
    if ! health_check; then
        print_error "Deployment failed: Health checks failed"
        rollback_deployment
        exit 1
    fi
    
    # Cleanup old images
    cleanup_old_images
    
    print_status "✅ Deployment completed successfully!"
    print_status "Backend version: $BACKEND_VERSION"
    print_status "Frontend version: $FRONTEND_VERSION"
    
    # Show service status
    print_status "Current service status:"
    docker stack services $STACK_NAME
}

# Trap for cleanup on script exit
trap 'print_error "Deployment interrupted"' INT TERM

# Run main function
main "$@"
