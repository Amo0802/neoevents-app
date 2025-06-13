#!/bin/bash
# scripts/monitoring/monitor.sh

set -e

STACK_NAME="neoevents"
LOG_DIR="./deployment/logs"
ALERT_EMAIL="${ALERT_EMAIL:-admin@your-domain.com}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Function to check service health
check_service_health() {
    local service_name=$1
    local service_info=$(docker service ps "$service_name" --format "table {{.Name}} {{.CurrentState}} {{.Error}}" --no-trunc)
    local running_count=$(echo "$service_info" | grep -c "Running" || echo "0")
    local desired_replicas=$(docker service ls --format "table {{.Name}} {{.Replicas}}" | grep "$service_name" | awk '{print $2}' | cut -d'/' -f2)
    
    if [ "$running_count" -eq "$desired_replicas" ]; then
        echo "✅ $service_name: $running_count/$desired_replicas replicas running"
        return 0
    else
        echo "❌ $service_name: $running_count/$desired_replicas replicas running"
        echo "$service_info" | grep -v "Running" || true
        return 1
    fi
}

# Function to check application endpoints
check_endpoints() {
    local backend_health=0
    local frontend_health=0
    
    # Check backend health endpoint
    if curl -f -s --max-time 30 http://localhost/api/actuator/health > /dev/null 2>&1; then
        echo "✅ Backend health endpoint: OK"
        backend_health=1
    else
        echo "❌ Backend health endpoint: FAILED"
    fi
    
    # Check frontend
    if curl -f -s --max-time 30 http://localhost/health > /dev/null 2>&1; then
        echo "✅ Frontend health endpoint: OK"
        frontend_health=1
    else
        echo "❌ Frontend health endpoint: FAILED"
    fi
    
    # Check main application endpoint
    if curl -f -s --max-time 30 http://localhost/ > /dev/null 2>&1; then
        echo "✅ Main application endpoint: OK"
    else
        echo "❌ Main application endpoint: FAILED"
    fi
    
    return $((2 - backend_health - frontend_health))
}

# Function to check database connectivity
check_database() {
    local db_container=$(docker ps --format "table {{.Names}}" | grep -E "(mysql|db)" | head -1)
    
    if [ -z "$db_container" ]; then
        echo "❌ Database container not found"
        return 1
    fi
    
    if docker exec "$db_container" mysqladmin ping -h localhost >/dev/null 2>&1; then
        echo "✅ Database connectivity: OK"
        return 0
    else
        echo "❌ Database connectivity: FAILED"
        return 1
    fi
}

# Function to check disk usage
check_disk_usage() {
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -lt 80 ]; then
        echo "✅ Disk usage: ${disk_usage}% (OK)"
        return 0
    elif [ "$disk_usage" -lt 90 ]; then
        echo "⚠️  Disk usage: ${disk_usage}% (WARNING)"
        return 1
    else
        echo "❌ Disk usage: ${disk_usage}% (CRITICAL)"
        return 2
    fi
}

# Function to check memory usage
check_memory_usage() {
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    
    if [ "$mem_usage" -lt 80 ]; then
        echo "✅ Memory usage: ${mem_usage}% (OK)"
        return 0
    elif [ "$mem_usage" -lt 90 ]; then
        echo "⚠️  Memory usage: ${mem_usage}% (WARNING)"
        return 1
    else
        echo "❌ Memory usage: ${mem_usage}% (CRITICAL)"
        return 2
    fi
}

# Function to check container resource usage
check_container_resources() {
    print_header "Container Resource Usage:"
    
    # Get container stats
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | \
    grep -E "(backend|frontend|mysql|nginx)" || echo "No matching containers found"
}

# Function to check logs for errors
check_logs_for_errors() {
    local error_count=0
    local warning_count=0
    
    # Check backend logs for errors (last 100 lines)
    local backend_container=$(docker ps --format "table {{.Names}}" | grep backend | head -1)
    if [ -n "$backend_container" ]; then
        local backend_errors=$(docker logs "$backend_container" --tail 100 2>&1 | grep -c -i "error\|exception\|failed" || echo "0")
        local backend_warnings=$(docker logs "$backend_container" --tail 100 2>&1 | grep -c -i "warn" || echo "0")
        
        echo "Backend logs (last 100 lines): $backend_errors errors, $backend_warnings warnings"
        error_count=$((error_count + backend_errors))
        warning_count=$((warning_count + backend_warnings))
    fi
    
    # Check nginx logs for errors
    local nginx_container=$(docker ps --format "table {{.Names}}" | grep nginx | head -1)
    if [ -n "$nginx_container" ]; then
        local nginx_errors=$(docker logs "$nginx_container" --tail 100 2>&1 | grep -c -i "error" || echo "0")
        
        echo "Nginx logs (last 100 lines): $nginx_errors errors"
        error_count=$((error_count + nginx_errors))
    fi
    
    if [ "$error_count" -gt 0 ]; then
        echo "❌ Found $error_count errors in recent logs"
        return 1
    elif [ "$warning_count" -gt 5 ]; then
        echo "⚠️  Found $warning_count warnings in recent logs"
        return 1
    else
        echo "✅ No significant errors in recent logs"
        return 0
    fi
}

# Function to check SSL certificate expiry
check_ssl_expiry() {
    local ssl_cert="./deployment/ssl/fullchain.pem"
    
    if [ ! -f "$ssl_cert" ]; then
        echo "❌ SSL certificate not found"
        return 1
    fi
    
    local expiry_date=$(openssl x509 -in "$ssl_cert" -noout -enddate | cut -d= -f2)
    local expiry_epoch=$(date -d "$expiry_date" +%s)
    local current_epoch=$(date +%s)
    local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
    
    if [ "$days_until_expiry" -gt 30 ]; then
        echo "✅ SSL certificate expires in $days_until_expiry days (OK)"
        return 0
    elif [ "$days_until_expiry" -gt 7 ]; then
        echo "⚠️  SSL certificate expires in $days_until_expiry days (WARNING)"
        return 1
    else
        echo "❌ SSL certificate expires in $days_until_expiry days (CRITICAL)"
        return 2
    fi
}

# Function to perform comprehensive health check
comprehensive_health_check() {
    local overall_status="OK"
    local issues=()
    
    print_header "🏥 NeoEvents Health Check - $(date)"
    echo
    
    # Check if stack is deployed
    if ! docker stack ls --format "table {{.Name}}" | grep -q "^${STACK_NAME}$"; then
        print_error "Stack '$STACK_NAME' is not deployed!"
        return 1
    fi
    
    print_header "Service Status:"
    local service_issues=0
    for service in "${STACK_NAME}_backend" "${STACK_NAME}_frontend" "${STACK_NAME}_db" "${STACK_NAME}_nginx"; do
        if ! check_service_health "$service"; then
            service_issues=$((service_issues + 1))
            issues+=("Service $service has issues")
        fi
    done
    
    if [ $service_issues -gt 0 ]; then
        overall_status="CRITICAL"
    fi
    
    echo
    print_header "Endpoint Health:"
    if ! check_endpoints; then
        overall_status="CRITICAL"
        issues+=("Application endpoints are not responding")
    fi
    
    echo
    print_header "Database Health:"
    if ! check_database; then
        overall_status="CRITICAL"
        issues+=("Database connectivity issues")
    fi
    
    echo
    print_header "System Resources:"
    
    local disk_status
    check_disk_usage
    disk_status=$?
    if [ $disk_status -eq 2 ]; then
        overall_status="CRITICAL"
        issues+=("Critical disk usage")
    elif [ $disk_status -eq 1 ] && [ "$overall_status" = "OK" ]; then
        overall_status="WARNING"
        issues+=("High disk usage")
    fi
    
    local mem_status
    check_memory_usage
    mem_status=$?
    if [ $mem_status -eq 2 ]; then
        overall_status="CRITICAL"
        issues+=("Critical memory usage")
    elif [ $mem_status -eq 1 ] && [ "$overall_status" != "CRITICAL" ]; then
        overall_status="WARNING"
        issues+=("High memory usage")
    fi
    
    echo
    check_container_resources
    
    echo
    print_header "Log Analysis:"
    if ! check_logs_for_errors; then
        if [ "$overall_status" = "OK" ]; then
            overall_status="WARNING"
        fi
        issues+=("Errors found in application logs")
    fi
    
    echo
    print_header "SSL Certificate:"
    local ssl_status
    check_ssl_expiry
    ssl_status=$?
    if [ $ssl_status -eq 2 ]; then
        overall_status="CRITICAL"
        issues+=("SSL certificate expires soon")
    elif [ $ssl_status -eq 1 ] && [ "$overall_status" != "CRITICAL" ]; then
        overall_status="WARNING"
        issues+=("SSL certificate expiring")
    fi
    
    echo
    print_header "Overall Health Status: $overall_status"
    
    if [ ${#issues[@]} -gt 0 ]; then
        echo "Issues found:"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
    fi
    
    # Log results
    mkdir -p "$LOG_DIR"
    {
        echo "$(date): Health check completed - Status: $overall_status"
        if [ ${#issues[@]} -gt 0 ]; then
            echo "Issues:"
            for issue in "${issues[@]}"; do
                echo "  - $issue"
            done
        fi
    } >> "$LOG_DIR/health_check.log"
    
    # Return appropriate exit code
    case "$overall_status" in
        "OK") return 0 ;;
        "WARNING") return 1 ;;
        "CRITICAL") return 2 ;;
    esac
}

# Function to show service logs
show_logs() {
    local service_name=${1:-""}
    local lines=${2:-50}
    
    if [ -z "$service_name" ]; then
        echo "Available services:"
        docker stack services "$STACK_NAME" --format "table {{.Name}}"
        echo
        echo "Usage: $0 logs <service_name> [lines]"
        return 1
    fi
    
    local full_service_name="${STACK_NAME}_${service_name}"
    
    print_header "Logs for $full_service_name (last $lines lines):"
    
    # Get the container ID for the service
    local container_id=$(docker ps --filter "label=com.docker.swarm.service.name=$full_service_name" --format "{{.ID}}" | head -1)
    
    if [ -n "$container_id" ]; then
        docker logs "$container_id" --tail "$lines" --timestamps
    else
        print_error "No running container found for service: $full_service_name"
        return 1
    fi
}

# Function to show metrics
show_metrics() {
    print_header "📊 NeoEvents Metrics - $(date)"
    echo
    
    print_header "System Metrics:"
    echo "Uptime: $(uptime)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo
    
    print_header "Docker Metrics:"
    echo "Running Containers: $(docker ps | wc -l)"
    echo "Total Images: $(docker images | wc -l)"
    echo "System DF:"
    docker system df
    echo
    
    print_header "Service Metrics:"
    docker stack services "$STACK_NAME" --format "table {{.Name}} {{.Mode}} {{.Replicas}} {{.Image}}"
    echo
    
    print_header "Network Connections:"
    netstat -tuln | grep -E ":(80|443|8080|3306)"
}

# Function to setup monitoring cron job
setup_monitoring() {
    print_status "Setting up automated monitoring..."
    
    # Create monitoring script in system location
    local monitor_script="/usr/local/bin/neoevents-monitor"
    
    sudo tee "$monitor_script" > /dev/null << EOF
#!/bin/bash
cd $(pwd)
./scripts/monitoring/monitor.sh health-check
EOF
    
    sudo chmod +x "$monitor_script"
    
    # Add cron job for health checks (every 5 minutes)
    (crontab -l 2>/dev/null; echo "*/5 * * * * $monitor_script >> ./deployment/logs/monitor.log 2>&1") | crontab -
    
    print_status "Automated monitoring setup completed"
    print_status "Health checks will run every 5 minutes"
}

# Function to show help
show_help() {
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  health-check         - Perform comprehensive health check"
    echo "  logs SERVICE [LINES] - Show logs for a specific service"
    echo "  metrics             - Show system and application metrics"
    echo "  setup               - Setup automated monitoring"
    echo "  help                - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 health-check"
    echo "  $0 logs backend 100"
    echo "  $0 metrics"
    echo
}

# Main execution
case "${1:-health-check}" in
    "health-check"|"health"|"check")
        comprehensive_health_check
        ;;
    "logs")
        show_logs "$2" "$3"
        ;;
    "metrics")
        show_metrics
        ;;
    "setup")
        setup_monitoring
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
