#!/bin/bash

###############################################################################
# OpenManus AWS Deployment Script
# This script sets up and runs OpenManus on an AWS EC2 instance
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

###############################################################################
# Step 1: Kill all processes on common ports
###############################################################################
kill_port_processes() {
    log_info "Killing processes on common ports..."

    # Common ports used by web applications
    PORTS=(3000 5000 8000 8080 8888 9000 11434)

    for port in "${PORTS[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            log_warn "Port $port is in use. Killing process..."
            lsof -ti:$port | xargs kill -9 2>/dev/null || true
            log_info "Port $port cleared"
        else
            log_info "Port $port is free"
        fi
    done

    # Kill any Python processes that might be running OpenManus
    log_info "Checking for existing OpenManus processes..."
    pkill -f "python.*main.py" 2>/dev/null || log_info "No existing OpenManus main.py processes found"
    pkill -f "python.*run_mcp.py" 2>/dev/null || log_info "No existing OpenManus run_mcp.py processes found"
    pkill -f "python.*run_flow.py" 2>/dev/null || log_info "No existing OpenManus run_flow.py processes found"

    log_info "Port cleanup completed"
}

###############################################################################
# Step 2: Check system requirements
###############################################################################
check_requirements() {
    log_info "Checking system requirements..."

    # Check if Python 3.12 is available
    if ! command -v python3.12 &> /dev/null; then
        log_warn "Python 3.12 not found. Attempting to install..."

        # Update package list
        sudo apt-get update

        # Install Python 3.12
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt-get update
        sudo apt-get install -y python3.12 python3.12-venv python3.12-dev
    fi

    # Check if pip is available
    if ! command -v pip3 &> /dev/null; then
        log_warn "pip3 not found. Installing..."
        sudo apt-get install -y python3-pip
    fi

    # Install lsof if not present
    if ! command -v lsof &> /dev/null; then
        log_warn "lsof not found. Installing..."
        sudo apt-get install -y lsof
    fi

    log_info "System requirements check completed"
}

###############################################################################
# Step 3: Setup Python virtual environment
###############################################################################
setup_virtualenv() {
    log_info "Setting up Python virtual environment..."

    # Remove existing venv if present
    if [ -d "venv" ]; then
        log_warn "Removing existing virtual environment..."
        rm -rf venv
    fi

    # Create new virtual environment with Python 3.12
    python3.12 -m venv venv

    # Activate virtual environment
    source venv/bin/activate

    # Upgrade pip
    pip install --upgrade pip

    log_info "Virtual environment setup completed"
}

###############################################################################
# Step 4: Install dependencies
###############################################################################
install_dependencies() {
    log_info "Installing Python dependencies..."

    # Make sure we're in the virtual environment
    source venv/bin/activate

    # Install requirements
    pip install -r requirements.txt

    # Install Playwright browsers (optional but recommended)
    log_info "Installing Playwright browsers (this may take a few minutes)..."
    playwright install chromium || log_warn "Playwright browser installation failed. You may need to install manually."

    log_info "Dependencies installation completed"
}

###############################################################################
# Step 5: Setup configuration
###############################################################################
setup_config() {
    log_info "Setting up configuration..."

    if [ ! -f "config/config.toml" ]; then
        log_warn "config/config.toml not found. Creating from example..."
        cp config/config.example.toml config/config.toml
        log_warn "Please edit config/config.toml and add your API keys before running!"
        log_warn "Required: API key in [llm] section"
    else
        log_info "config/config.toml already exists"
    fi
}

###############################################################################
# Step 6: Run OpenManus
###############################################################################
run_openmanus() {
    log_info "Starting OpenManus..."

    # Make sure we're in the virtual environment
    source venv/bin/activate

    # Check if user wants to run a specific version
    if [ "$1" == "mcp" ]; then
        log_info "Running MCP version..."
        python run_mcp.py
    elif [ "$1" == "flow" ]; then
        log_info "Running multi-agent flow version..."
        python run_flow.py
    else
        log_info "Running standard version..."
        python main.py
    fi
}

###############################################################################
# Main execution
###############################################################################
main() {
    log_info "=========================================="
    log_info "OpenManus AWS Deployment Script"
    log_info "=========================================="

    # Change to script directory
    cd "$(dirname "$0")"

    # Execute steps
    kill_port_processes
    check_requirements
    setup_virtualenv
    install_dependencies
    setup_config

    log_info "=========================================="
    log_info "Setup completed successfully!"
    log_info "=========================================="
    log_info ""
    log_info "Next steps:"
    log_info "1. Edit config/config.toml and add your API keys"
    log_info "2. Run one of the following commands:"
    log_info "   - ./deploy_aws.sh run        (standard version)"
    log_info "   - ./deploy_aws.sh run-mcp    (MCP version)"
    log_info "   - ./deploy_aws.sh run-flow   (multi-agent version)"
    log_info ""

    # If user provided a run argument, start the application
    if [ "$1" == "run" ]; then
        run_openmanus
    elif [ "$1" == "run-mcp" ]; then
        run_openmanus mcp
    elif [ "$1" == "run-flow" ]; then
        run_openmanus flow
    fi
}

# Run main function with all arguments
main "$@"
