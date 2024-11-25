#!/bin/bash

# Constants
readonly LOG_FILE="cleanup.log"

# Logging functions
log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to safely remove Docker containers
cleanup_docker_containers() {
    log_info "Starting Docker container cleanup..."
    
    # Get lists of containers
    local running_containers
    local all_containers
    
    running_containers=$(docker ps -q) || {
        log_error "Failed to get running containers"
        return 1
    }
    
    all_containers=$(docker ps -aq) || {
        log_error "Failed to get all containers"
        return 1
    }
    
    if [ -z "$all_containers" ]; then
        log_info "No containers found to clean up"
        return 0
    fi
    
    # Counter for removed containers
    local removed_count=0
    
    for container in $all_containers; do
        if [[ ! " $running_containers " =~ " $container " ]]; then
            log_info "Removing container: $(docker ps -a --filter "id=$container" --format "{{.Names}}")"
            if docker rm -f "$container" &>/dev/null; then
                ((removed_count++))
            else
                log_warning "Failed to remove container: $container"
            fi
        fi
    done
    
    log_info "Container cleanup completed. Removed $removed_count containers"
}

# Function to safely remove Docker images
cleanup_docker_images() {
    log_info "Starting Docker image cleanup..."
    
    local docker_image_ids

    docker_image_ids=$(docker images | awk '$1 ~ /dev-peer*/ {print $3}') || {
        log_error "Failed to get Docker images"
        return 1
    }
    
    if [ -z "$docker_image_ids" ]; then
        log_info "No dev-peer images found for deletion"
        return 0
    fi
    
    # Counter for removed images
    local removed_count=0
    
    for image in $docker_image_ids; do
        log_info "Removing image: $image"
        if docker rmi -f "$image" &>/dev/null; then
            ((removed_count++))
        else
            log_warning "Failed to remove image: $image"
        fi
    done
    
    log_info "Image cleanup completed. Removed $removed_count images"
}

# Function to safely clean up files and directories
cleanup_files() {
    log_info "Starting file system cleanup..."
    
    local paths_to_remove=(
        "${ORGANIZATION_NAME_LOWERCASE}Ca/crypto-config/"
        "artifacts/"
        "./config/"
        "chaincode/node_modules"
        "configtx.yaml"
    )
    
    # Counter for removed items
    local removed_count=0
    
    for path in "${paths_to_remove[@]}"; do
        if [ -e "$path" ]; then
            log_info "Removing: $path"
            if sudo rm -rf "$path" &>/dev/null; then
                ((removed_count++))
                log_info "Successfully removed: $path"
            else
                log_error "Failed to remove: $path"
            fi
        else
            log_info "Path does not exist, skipping: $path"
        fi
    done
    
    log_info "File system cleanup completed. Removed $removed_count items"
}

# Function to create required directories
create_directories() {
    log_info "Creating required directories..."
    
    local directories=(
        "artifacts"
        "config"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            log_info "Creating directory: $dir"
            if mkdir -p "$dir" &>/dev/null; then
                log_info "Successfully created: $dir"
            else
                log_error "Failed to create directory: $dir"
                return 1
            fi
        else
            log_info "Directory already exists: $dir"
        fi
    done
    
    log_info "Directory creation completed"
}

# Function to check system requirements
check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check Docker daemon
    if ! docker info &>/dev/null; then
        log_error "Docker daemon is not running"
        return 1
    fi
    
    # Check available disk space
    local available_space
    available_space=$(df -k . | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 1000000 ]; then  # Less than 1GB
        log_warning "Low disk space detected: ${available_space}KB available"
    fi
    
    # Check if running as root or have sudo access
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        log_warning "Script may need sudo privileges for some operations"
    fi
    
    log_info "System requirements check completed"
}

# Main cleanup function
main() {
    # Initialize log file
    : > "$LOG_FILE"
    
    log_info "Starting cleanup process..."
    
    # Check system requirements
    if ! check_system_requirements; then
        log_error "System requirements check failed"
        exit 1
    fi
    
    # Perform cleanup operations
    cleanup_docker_containers || log_error "Docker container cleanup failed"
    cleanup_docker_images || log_error "Docker image cleanup failed"
    cleanup_files || log_error "File system cleanup failed"
    
    # Create required directories
    if ! create_directories; then
        log_error "Failed to create required directories"
        exit 1
    fi
    
    log_info "Cleanup process completed successfully"
}

# Execute main function with error handling
if ! main; then
    log_error "Cleanup process failed"
    exit 1
fi
