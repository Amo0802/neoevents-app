#!/bin/bash
# scripts/setup/setup_secrets.sh

set -e

SECRETS_DIR="./deployment/secrets"

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

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to generate JWT secret
generate_jwt_secret() {
    openssl rand -base64 64 | tr -d "=+/" | cut -c1-64
}

# Function to create secret file
create_secret() {
    local secret_name=$1
    local secret_value=$2
    local secret_file="${SECRETS_DIR}/${secret_name}.txt"
    
    echo "$secret_value" > "$secret_file"
    chmod 600 "$secret_file"
    print_status "Created secret: $secret_name"
}

# Function to prompt for input
prompt_for_input() {
    local prompt_text=$1
    local default_value=$2
    local is_password=${3:-false}
    
    if [ "$is_password" = true ]; then
        echo -n "$prompt_text: "
        read -s user_input
        echo
    else
        echo -n "$prompt_text"
        if [ -n "$default_value" ]; then
            echo -n " (default: $default_value): "
        else
            echo -n ": "
        fi
        read user_input
    fi
    
    if [ -z "$user_input" ]; then
        echo "$default_value"
    else
        echo "$user_input"
    fi
}

# Main setup function
setup_secrets() {
    print_header "🔐 Setting up secrets for NeoEvents deployment"
    echo
    
    # Create secrets directory
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"
    
    # Check if secrets already exist
    if [ -f "${SECRETS_DIR}/mysql_root_password.txt" ]; then
        echo -n "Secrets already exist. Overwrite? (y/N): "
        read -r overwrite
        if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
            print_status "Keeping existing secrets"
            return 0
        fi
    fi
    
    print_status "Creating secrets..."
    
    # MySQL root password
    local mysql_root_password=$(generate_password)
    create_secret "mysql_root_password" "$mysql_root_password"
    
    # MySQL application password
    local mysql_password=$(generate_password)
    create_secret "mysql_password" "$mysql_password"
    
    # JWT secret
    local jwt_secret=$(generate_jwt_secret)
    create_secret "jwt_secret" "$jwt_secret"
    
    # Email configuration
    print_header "📧 Email Configuration"
    local mail_username=$(prompt_for_input "Email username (for SMTP)")
    local mail_password=$(prompt_for_input "Email password (for SMTP)" "" true)
    
    create_secret "mail_username" "$mail_username"
    create_secret "mail_password" "$mail_password"
    
    print_status "All secrets created successfully!"
    
    # Create environment file template
    create_env_template
    
    # Display summary
    print_header "📋 Setup Summary"
    echo "Secrets created in: $SECRETS_DIR"
    echo "- MySQL root password: ✓"
    echo "- MySQL app password: ✓"
    echo "- JWT secret: ✓"
    echo "- Email credentials: ✓"
    echo
    print_warning "Keep these secrets secure and backed up!"
    echo
}

# Function to create environment template
create_env_template() {
    local env_file="./deployment/environments/production/.env"
    mkdir -p "$(dirname "$env_file")"
    
    cat > "$env_file" << EOF
# Production Environment Variables
# Generated on $(date)

# Database Configuration
MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password
MYSQL_PASSWORD_FILE=/run/secrets/mysql_password
MYSQL_DATABASE=eventsdb
MYSQL_USER=eventsapp

# Application Configuration
SPRING_PROFILES_ACTIVE=prod
SPRING_DATASOURCE_URL=jdbc:mysql://db:3306/eventsdb
SPRING_DATASOURCE_USERNAME=eventsapp

# JWT Configuration
JWT_SECRET_FILE=/run/secrets/jwt_secret
JWT_EXPIRATION=86400000

# Email Configuration
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME_FILE=/run/secrets/mail_username
MAIL_PASSWORD_FILE=/run/secrets/mail_password

# Server Configuration
SERVER_PORT=8080

# Logging Configuration
LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_SECURITY=INFO
LOGGING_LEVEL_COM_EXAMPLE_EVENTSAMOBE=INFO

# Health Check Configuration
MANAGEMENT_ENDPOINT_HEALTH_SHOW_DETAILS=always
MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics

# Docker Image Versions (will be overridden by CI/CD)
BACKEND_VERSION=latest
FRONTEND_VERSION=latest
EOF
    
    chmod 600 "$env_file"
    print_status "Environment template created: $env_file"
}

# Function to backup secrets
backup_secrets() {
    if [ ! -d "$SECRETS_DIR" ]; then
        print_error "No secrets directory found"
        exit 1
    fi
    
    local backup_dir="./deployment/backups/secrets_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    cp -r "$SECRETS_DIR"/* "$backup_dir"/
    chmod -R 600 "$backup_dir"
    
    print_status "Secrets backed up to: $backup_dir"
}

# Function to restore secrets from backup
restore_secrets() {
    local backup_dir=$1
    
    if [ ! -d "$backup_dir" ]; then
        print_error "Backup directory not found: $backup_dir"
        exit 1
    fi
    
    echo -n "This will overwrite current secrets. Continue? (y/N): "
    read -r confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_status "Restore cancelled"
        exit 0
    fi
    
    mkdir -p "$SECRETS_DIR"
    cp -r "$backup_dir"/* "$SECRETS_DIR"/
    chmod -R 600 "$SECRETS_DIR"
    
    print_status "Secrets restored from: $backup_dir"
}

# Function to show help
show_help() {
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  setup        - Setup new secrets (default)"
    echo "  backup       - Backup current secrets"
    echo "  restore DIR  - Restore secrets from backup directory"
    echo "  help         - Show this help message"
    echo
}

# Main execution
case "${1:-setup}" in
    "setup"|"")
        setup_secrets
        ;;
    "backup")
        backup_secrets
        ;;
    "restore")
        if [ -z "$2" ]; then
            print_error "Please specify backup directory"
            show_help
            exit 1
        fi
        restore_secrets "$2"
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
