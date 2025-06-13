#!/bin/bash
# scripts/deployment/rollback.sh

set -e

STACK_NAME="neoevents"
COMPOSE_FILE="docker-stack-production.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to list available backups
list_backups() {
    print_header "=== Available Deployment Backups ==="
    
    if [ ! -d "./deployment/backups" ]; then
        print_error "No backup directory found"
        exit 1
    fi
    
    local backups=($(ls -1 ./deployment/backups/previous_deployment_*.txt 2>/dev/null | sort -r))
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_error "No deployment backups found"
        exit 1
    fi
    
    echo "Available backups:"
    for i in "${!backups[@]}"; do
        local backup_file=${backups[$i]}
        local backup_date=$(basename "$backup_file" | sed 's/previous_deployment_\(.*\)\.txt/\1/')
        local formatted_date=$(date -d "${backup_date:0:8} ${backup_date:9:2}:${backup_date:11:2}:${backup_date:13:2}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$backup_date")
        
        echo "  $((i+1)). $formatted_date"
        cat "$backup_file" | grep -v "NAME" | while read line; do
            echo "     $line"
        done
        echo
    done
    
    return ${#backups[@]}
}

# Function to get current deployment status
show_current_status() {
    print_header "=== Current Deployment Status ==="
    
    if docker stack ls --format "table {{.Name}}" | grep -q "^${STACK_NAME}$"; then
        docker stack services $STACK_NAME --format "table {{.Name}} {{.Image}} {{.Replicas}} {{.Ports}}"
    else
        print_warning "Stack '$STACK_NAME' is not currently deployed"
    fi
    echo
}

# Function to perform rollback to specific backup
rollback_to_backup() {
    local backup_index=$1
    local backups=($(ls -1 ./deployment/backups/previous_deployment_*.txt 2>/dev/null | sort -r))
    
    if [ $backup_index -lt 1 ] || [ $backup_index -gt ${#backups[@]} ]; then
        print_error "Invalid backup selection"
        exit 1
    fi
    
    local selected_backup=${backups[$((backup_index-1))]}
    local backup_date=$(basename "$selected_backup" | sed 's/previous_deployment_\(.*\)\.txt/\1/')
    
    print_status "Rolling back to backup from: $backup_date"
    
    # Extract image versions from backup
    local backend_image=$(grep "backend" "$selected_backup" | awk '{print $2}')
    local frontend_image=$(grep "frontend" "$selected_backup" | awk '{print $2}')
    
    if [ -z "$backend_image" ] || [ -z "$frontend_image" ]; then
        print_error "Could not extract image information from backup"
        exit 1
    fi
    
    local backend_version=$(echo "$backend_image" | cut -d':' -f2)
    local frontend_version=$(echo "$frontend_image" | cut -d':' -f2)
    
    print_status "Backend version: $backend_version"
    print_status "Frontend version: $frontend_version"
    
    # Confirm rollback
    echo -n "Are you sure you want to rollback to these versions? (y/N): "
    read -r confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_status "Rollback cancelled"
        exit 0
    fi
    
    # Set environment variables
    export BACKEND_VERSION=$backend_version
    export FRONTEND_VERSION=$frontend_version
    
    # Pull images
    print_status "Pulling rollback images..."
    docker pull ghcr.io/$(whoami)/neoevents-backend:$backend_version || {
        print_error "Failed to pull backend image: $backend_version"
        exit 1
    }
    
    docker pull ghcr.io/$(whoami)/neoevents-frontend:$frontend_version || {
        print_error "Failed to pull frontend image: $frontend_version"
        exit 1
    }
    
    # Deploy rollback
    print_status "Deploying rollback..."
    docker stack deploy -c $COMPOSE_FILE $STACK_NAME
    
    # Wait for services
    print_status "Waiting for services to be ready..."
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local running_services=$(docker stack services $STACK_NAME --format "table {{.Name}} {{.Replicas}}" | grep -v NAME | grep "1/1" | wc -l)
        local total_services=$(docker stack services $STACK_NAME --format "table {{.Name}}" | grep -v NAME | wc -l)
        
        if [ $running_services -eq $total_services ]; then
            print_status "All services are ready!"
            break
        fi
        
        print_status "Services ready: $running_services/$total_services (attempt $attempt/$max_attempts)"
        sleep 10
        attempt=$((attempt + 1))
        
        if [ $attempt -gt $max_attempts ]; then
            print_error "Services failed to become ready within timeout"
            exit 1
        fi
    done
    
    # Health checks
    print_status "Performing health checks..."
    sleep 30  # Give services time to fully start
    
    local health_attempts=30
    local health_attempt=1
    
    while [ $health_attempt -le $health_attempts ]; do
        if curl -f -s http://localhost/api/actuator/health > /dev/null 2>&1 && \
           curl -f -s http://localhost/health > /dev/null 2>&1; then
            print_status "✅ Rollback completed successfully!"
            print_status "Current deployment:"
            docker stack services $STACK_NAME
            exit 0
        fi
        
        print_status "Health check attempt $health_attempt/$health_attempts..."
        sleep 10
        health_attempt=$((health_attempt + 1))
    done
    
    print_error "❌ Rollback completed but health checks failed"
    print_warning "Manual intervention may be required"
    exit 1
}

# Function to rollback to previous version (quick rollback)
quick_rollback() {
    if [ -f ./deployment/backups/previous_backend_version.txt ] && [ -f ./deployment/backups/previous_frontend_version.txt ]; then
        local prev_backend_version=$(cat ./deployment/backups/previous_backend_version.txt)
        local prev_frontend_version=$(cat ./deployment/backups/previous_frontend_version.txt)
        
        print_status "Quick rollback to:"
        print_status "  Backend: $prev_backend_version"
        print_status "  Frontend: $prev_frontend_version"
        
        echo -n "Proceed with quick rollback? (y/N): "
        read -r confirm
        
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            print_status "Rollback cancelled"
            exit 0
        fi
        
        export BACKEND_VERSION=$prev_backend_version
        export FRONTEND_VERSION=$prev_frontend_version
        
        # Pull and deploy
        print_status "Pulling images..."
        docker pull ghcr.io/$(whoami)/neoevents-backend:$prev_backend_version
        docker pull ghcr.io/$(whoami)/neoevents-frontend:$prev_frontend_version
        
        print_status "Deploying rollback..."
        docker stack deploy -c $COMPOSE_FILE $STACK_NAME
        
        print_status "✅ Quick rollback initiated"
        print_status "Monitor the deployment with: docker stack services $STACK_NAME"
    else
        print_error "No quick rollback information available"
        exit 1
    fi
}

# Main function
main() {
    print_header "🔄 NeoEvents Rollback Tool"
    echo
    
    case "${1:-}" in
        "quick"|"q")
            quick_rollback
            ;;
        "list"|"l")
            show_current_status
            list_backups
            ;;
        "status"|"s")
            show_current_status
            ;;
        *)
            show_current_status
            
            local backup_count=$(list_backups)
            
            if [ $backup_count -gt 0 ]; then
                echo -n "Select backup to rollback to (1-$backup_count), 'q' for quick rollback, or 'Enter' to cancel: "
                read -r selection
                
                if [ "$selection" = "q" ] || [ "$selection" = "Q" ]; then
                    quick_rollback
                elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le $backup_count ]; then
                    rollback_to_backup "$selection"
                else
                    print_status "Rollback cancelled"
                fi
            fi
            ;;
    esac
}

# Help function
show_help() {
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  quick, q     - Quick rollback to previous version"
    echo "  list, l      - List available backups and current status"
    echo "  status, s    - Show current deployment status only"
    echo "  help, h      - Show this help message"
    echo
    echo "If no command is provided, interactive mode will be used."
}

# Check for help
if [ "${1:-}" = "help" ] || [ "${1:-}" = "h" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    show_help
    exit 0
fi

# Run main function
main "$@"
