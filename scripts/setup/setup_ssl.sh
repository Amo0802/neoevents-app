#!/bin/bash
# scripts/setup/setup_ssl.sh

set -e

SSL_DIR="./deployment/ssl"
DOMAIN=${1:-"your-domain.com"}

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

# Function to install certbot
install_certbot() {
    print_status "Installing certbot..."
    
    if command -v certbot >/dev/null 2>&1; then
        print_status "Certbot already installed"
        return 0
    fi
    
    # Install snapd if not present
    if ! command -v snap >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y snapd
    fi
    
    # Install certbot via snap
    sudo snap install core; sudo snap refresh core
    sudo snap install --classic certbot
    
    # Create symlink
    sudo ln -sf /snap/bin/certbot /usr/bin/certbot
    
    print_status "Certbot installed successfully"
}

# Function to obtain SSL certificate using standalone mode
obtain_ssl_standalone() {
    local domain=$1
    
    print_status "Obtaining SSL certificate for domain: $domain"
    print_warning "Make sure port 80 is accessible and no other service is running on it"
    
    # Stop nginx if running
    docker service ls --format "table {{.Name}}" | grep -q neoevents_nginx && {
        print_status "Stopping nginx service temporarily..."
        docker service scale neoevents_nginx=0
        sleep 10
    }
    
    # Obtain certificate
    sudo certbot certonly \
        --standalone \
        --preferred-challenges http \
        --email "admin@${domain}" \
        --agree-tos \
        --no-eff-email \
        -d "$domain" \
        -d "www.${domain}"
    
    # Copy certificates to SSL directory
    mkdir -p "$SSL_DIR"
    sudo cp "/etc/letsencrypt/live/${domain}/fullchain.pem" "${SSL_DIR}/fullchain.pem"
    sudo cp "/etc/letsencrypt/live/${domain}/privkey.pem" "${SSL_DIR}/privkey.pem"
    sudo chown $(whoami):$(whoami) "${SSL_DIR}"/*.pem
    chmod 600 "${SSL_DIR}"/*.pem
    
    print_status "SSL certificates copied to: $SSL_DIR"
    
    # Restart nginx service
    docker service ls --format "table {{.Name}}" | grep -q neoevents_nginx && {
        print_status "Restarting nginx service..."
        docker service scale neoevents_nginx=1
    }
}

# Function to obtain SSL certificate using webroot mode
obtain_ssl_webroot() {
    local domain=$1
    
    print_status "Obtaining SSL certificate for domain: $domain using webroot method"
    
    # Create webroot directory
    local webroot_dir="./deployment/webroot"
    mkdir -p "$webroot_dir"
    
    # Create temporary nginx config for ACME challenge
    create_acme_nginx_config "$domain" "$webroot_dir"
    
    # Deploy temporary nginx
    print_status "Deploying temporary nginx for ACME challenge..."
    docker run -d \
        --name nginx-acme \
        --network host \
        -v "$(pwd)/deployment/nginx/acme.conf:/etc/nginx/conf.d/default.conf:ro" \
        -v "$(pwd)/$webroot_dir:/var/www/html:ro" \
        nginx:alpine
    
    sleep 5
    
    # Obtain certificate
    sudo certbot certonly \
        --webroot \
        --webroot-path "$webroot_dir" \
        --email "admin@${domain}" \
        --agree-tos \
        --no-eff-email \
        -d "$domain" \
        -d "www.${domain}"
    
    # Stop temporary nginx
    docker stop nginx-acme && docker rm nginx-acme
    
    # Copy certificates
    mkdir -p "$SSL_DIR"
    sudo cp "/etc/letsencrypt/live/${domain}/fullchain.pem" "${SSL_DIR}/fullchain.pem"
    sudo cp "/etc/letsencrypt/live/${domain}/privkey.pem" "${SSL_DIR}/privkey.pem"
    sudo chown $(whoami):$(whoami) "${SSL_DIR}"/*.pem
    chmod 600 "${SSL_DIR}"/*.pem
    
    print_status "SSL certificates obtained and copied successfully"
}

# Function to create temporary nginx config for ACME
create_acme_nginx_config() {
    local domain=$1
    local webroot_dir=$2
    
    mkdir -p "./deployment/nginx"
    
    cat > "./deployment/nginx/acme.conf" << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    
    location /.well-known/acme-challenge/ {
        root $webroot_dir;
    }
    
    location / {
        return 200 'ACME Challenge Server';
        add_header Content-Type text/plain;
    }
}
EOF
}

# Function to create self-signed certificate for testing
create_self_signed() {
    local domain=$1
    
    print_status "Creating self-signed certificate for domain: $domain"
    
    mkdir -p "$SSL_DIR"
    
    # Generate private key
    openssl genrsa -out "${SSL_DIR}/privkey.pem" 2048
    
    # Generate certificate signing request
    openssl req -new -key "${SSL_DIR}/privkey.pem" -out "${SSL_DIR}/cert.csr" \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=$domain"
    
    # Generate self-signed certificate
    openssl x509 -req -days 365 -in "${SSL_DIR}/cert.csr" \
        -signkey "${SSL_DIR}/privkey.pem" -out "${SSL_DIR}/fullchain.pem"
    
    # Clean up CSR
    rm "${SSL_DIR}/cert.csr"
    
    # Set permissions
    chmod 600 "${SSL_DIR}"/*.pem
    
    print_warning "Self-signed certificate created. This is NOT suitable for production!"
    print_status "Certificate files created in: $SSL_DIR"
}

# Function to renew SSL certificates
renew_ssl() {
    print_status "Renewing SSL certificates..."
    
    # Stop nginx temporarily
    docker service ls --format "table {{.Name}}" | grep -q neoevents_nginx && {
        print_status "Stopping nginx service for renewal..."
        docker service scale neoevents_nginx=0
        sleep 10
    }
    
    # Renew certificates
    sudo certbot renew --standalone
    
    # Copy renewed certificates
    for domain_dir in /etc/letsencrypt/live/*/; do
        if [ -d "$domain_dir" ]; then
            domain=$(basename "$domain_dir")
            print_status "Copying renewed certificate for: $domain"
            sudo cp "${domain_dir}fullchain.pem" "${SSL_DIR}/fullchain.pem"
            sudo cp "${domain_dir}privkey.pem" "${SSL_DIR}/privkey.pem"
            sudo chown $(whoami):$(whoami) "${SSL_DIR}"/*.pem
            chmod 600 "${SSL_DIR}"/*.pem
            break
        fi
    done
    
    # Restart nginx
    docker service ls --format "table {{.Name}}" | grep -q neoevents_nginx && {
        print_status "Restarting nginx service..."
        docker service scale neoevents_nginx=1
    }
    
    print_status "SSL certificate renewal completed"
}

# Function to setup SSL certificate auto-renewal
setup_auto_renewal() {
    print_status "Setting up automatic SSL certificate renewal..."
    
    # Create renewal script
    local renewal_script="/usr/local/bin/neoevents-ssl-renew"
    
    sudo tee "$renewal_script" > /dev/null << EOF
#!/bin/bash
# Auto-renewal script for NeoEvents SSL certificates

cd $(pwd)

# Log file
LOG_FILE="./deployment/logs/ssl-renewal.log"
mkdir -p "\$(dirname "\$LOG_FILE")"

echo "\$(date): Starting SSL certificate renewal" >> "\$LOG_FILE"

# Stop nginx
docker service scale neoevents_nginx=0 >> "\$LOG_FILE" 2>&1
sleep 10

# Renew certificates
certbot renew --standalone >> "\$LOG_FILE" 2>&1

# Copy certificates
for domain_dir in /etc/letsencrypt/live/*/; do
    if [ -d "\$domain_dir" ]; then
        domain=\$(basename "\$domain_dir")
        cp "\${domain_dir}fullchain.pem" "${SSL_DIR}/fullchain.pem" >> "\$LOG_FILE" 2>&1
        cp "\${domain_dir}privkey.pem" "${SSL_DIR}/privkey.pem" >> "\$LOG_FILE" 2>&1
        chown $(whoami):$(whoami) "${SSL_DIR}"/*.pem >> "\$LOG_FILE" 2>&1
        chmod 600 "${SSL_DIR}"/*.pem >> "\$LOG_FILE" 2>&1
        break
    fi
done

# Restart nginx
docker service scale neoevents_nginx=1 >> "\$LOG_FILE" 2>&1

echo "\$(date): SSL certificate renewal completed" >> "\$LOG_FILE"
EOF
    
    sudo chmod +x "$renewal_script"
    
    # Add cron job for automatic renewal (runs at 2 AM on the 1st of every month)
    (crontab -l 2>/dev/null; echo "0 2 1 * * $renewal_script") | crontab -
    
    print_status "Auto-renewal setup completed"
    print_status "Certificates will be renewed automatically on the 1st of each month at 2 AM"
}

# Function to check SSL certificate status
check_ssl_status() {
    local domain=$1
    
    print_header "🔒 SSL Certificate Status for $domain"
    
    if [ -f "${SSL_DIR}/fullchain.pem" ]; then
        print_status "Certificate file found"
        
        # Check certificate details
        local cert_info=$(openssl x509 -in "${SSL_DIR}/fullchain.pem" -text -noout)
        local expiry_date=$(echo "$cert_info" | grep "Not After" | cut -d: -f2- | xargs)
        local issuer=$(echo "$cert_info" | grep "Issuer:" | cut -d: -f2- | xargs)
        local subject=$(echo "$cert_info" | grep "Subject:" | cut -d: -f2- | xargs)
        
        echo "Issuer: $issuer"
        echo "Subject: $subject"
        echo "Expiry Date: $expiry_date"
        
        # Check if certificate is valid for the domain
        if openssl x509 -in "${SSL_DIR}/fullchain.pem" -checkend 86400 -noout >/dev/null; then
            print_status "Certificate is valid for at least 24 hours"
        else
            print_warning "Certificate expires within 24 hours!"
        fi
        
        # Test SSL connection
        if command -v curl >/dev/null 2>&1; then
            print_status "Testing SSL connection..."
            if curl -I --connect-timeout 10 -m 30 "https://$domain" >/dev/null 2>&1; then
                print_status "SSL connection test: ✅ PASSED"
            else
                print_warning "SSL connection test: ❌ FAILED"
            fi
        fi
    else
        print_error "No SSL certificate found in: $SSL_DIR"
    fi
}

# Function to backup SSL certificates
backup_ssl() {
    if [ ! -d "$SSL_DIR" ]; then
        print_error "No SSL directory found"
        exit 1
    fi
    
    local backup_dir="./deployment/backups/ssl_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    cp -r "$SSL_DIR"/* "$backup_dir"/
    chmod -R 600 "$backup_dir"
    
    # Also backup Let's Encrypt config if it exists
    if [ -d "/etc/letsencrypt" ]; then
        sudo tar -czf "${backup_dir}/letsencrypt_config.tar.gz" -C /etc letsencrypt
        sudo chown $(whoami):$(whoami) "${backup_dir}/letsencrypt_config.tar.gz"
    fi
    
    print_status "SSL certificates backed up to: $backup_dir"
}

# Function to show help
show_help() {
    echo "Usage: $0 [command] [domain]"
    echo
    echo "Commands:"
    echo "  standalone DOMAIN    - Obtain SSL certificate using standalone method"
    echo "  webroot DOMAIN       - Obtain SSL certificate using webroot method"
    echo "  self-signed DOMAIN   - Create self-signed certificate (for testing)"
    echo "  renew               - Renew existing SSL certificates"
    echo "  auto-renew          - Setup automatic renewal"
    echo "  status DOMAIN       - Check SSL certificate status"
    echo "  backup              - Backup SSL certificates"
    echo "  help                - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 standalone myapp.com"
    echo "  $0 webroot myapp.com"
    echo "  $0 self-signed localhost"
    echo "  $0 status myapp.com"
    echo
}

# Main execution
case "${1:-help}" in
    "standalone")
        if [ -z "$2" ]; then
            print_error "Please specify domain name"
            show_help
            exit 1
        fi
        install_certbot
        obtain_ssl_standalone "$2"
        check_ssl_status "$2"
        ;;
    "webroot")
        if [ -z "$2" ]; then
            print_error "Please specify domain name"
            show_help
            exit 1
        fi
        install_certbot
        obtain_ssl_webroot "$2"
        check_ssl_status "$2"
        ;;
    "self-signed")
        if [ -z "$2" ]; then
            print_error "Please specify domain name"
            show_help
            exit 1
        fi
        create_self_signed "$2"
        check_ssl_status "$2"
        ;;
    "renew")
        renew_ssl
        ;;
    "auto-renew")
        setup_auto_renewal
        ;;
    "status")
        if [ -z "$2" ]; then
            print_error "Please specify domain name"
            show_help
            exit 1
        fi
        check_ssl_status "$2"
        ;;
    "backup")
        backup_ssl
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
