#!/bin/bash

###############################################################################
# Port Cleanup Utility for OpenManus
# Kills processes running on commonly used ports
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OpenManus Port Cleanup Utility${NC}"
echo -e "${GREEN}========================================${NC}"

# Common ports used by web applications and services
PORTS=(3000 5000 8000 8080 8888 9000 11434)

echo -e "\n${YELLOW}Checking and cleaning ports...${NC}\n"

for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}Port $port is in use${NC}"

        # Show what process is using the port
        echo -e "  Process info:"
        lsof -Pi :$port -sTCP:LISTEN | grep -v COMMAND

        # Kill the process
        echo -e "${RED}  Killing process on port $port...${NC}"
        lsof -ti:$port | xargs kill -9 2>/dev/null

        # Verify it's killed
        sleep 1
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${RED}  Failed to kill process on port $port${NC}"
        else
            echo -e "${GREEN}  Port $port is now free${NC}"
        fi
    else
        echo -e "${GREEN}Port $port is free${NC}"
    fi
done

echo -e "\n${YELLOW}Checking for OpenManus processes...${NC}\n"

# Kill any Python processes running OpenManus
for script in "main.py" "run_mcp.py" "run_flow.py"; do
    if pgrep -f "python.*$script" > /dev/null; then
        echo -e "${YELLOW}Found OpenManus process: $script${NC}"
        pkill -f "python.*$script"
        echo -e "${GREEN}Killed $script process${NC}"
    else
        echo -e "${GREEN}No $script process running${NC}"
    fi
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Port cleanup completed!${NC}"
echo -e "${GREEN}========================================${NC}"
