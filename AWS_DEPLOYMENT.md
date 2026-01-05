# OpenManus AWS Deployment Guide

This guide explains how to deploy and run OpenManus on an AWS EC2 instance.

## Prerequisites

- AWS EC2 instance (Ubuntu 20.04 or later recommended)
- SSH access to the instance
- At least 2GB RAM and 10GB disk space
- API keys for your chosen LLM provider (OpenAI, Anthropic, etc.)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/FoundationAgents/OpenManus.git
cd OpenManus
```

### 2. Run the Deployment Script

The deployment script will:
- Kill any processes running on common ports (3000, 5000, 8000, 8080, 8888, 9000, 11434)
- Install Python 3.12 if not present
- Set up a virtual environment
- Install all dependencies
- Install Playwright browsers
- Create configuration file from template

```bash
chmod +x deploy_aws.sh
./deploy_aws.sh
```

### 3. Configure API Keys

Edit the configuration file and add your API keys:

```bash
nano config/config.toml
```

Update the `[llm]` section with your API credentials:

```toml
[llm]
model = "gpt-4o"  # or your preferred model
base_url = "https://api.openai.com/v1"
api_key = "sk-..."  # Replace with your actual API key
```

### 4. Run OpenManus

You have three options:

**Standard Version (Recommended):**
```bash
./deploy_aws.sh run
```

**MCP Version:**
```bash
./deploy_aws.sh run-mcp
```

**Multi-Agent Flow Version:**
```bash
./deploy_aws.sh run-flow
```

## Manual Port Management

If you need to manually kill processes on specific ports:

```bash
# Check what's running on a port
sudo lsof -i :8000

# Kill process on specific port
sudo lsof -ti:8000 | xargs kill -9
```

## Running as a Background Service

### Option 1: Using nohup

```bash
source venv/bin/activate
nohup python main.py > openmanus.log 2>&1 &
```

### Option 2: Using systemd (Recommended for Production)

Create a systemd service file:

```bash
sudo nano /etc/systemd/system/openmanus.service
```

Add the following content (adjust paths as needed):

```ini
[Unit]
Description=OpenManus AI Agent
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/OpenManus
Environment="PATH=/home/ubuntu/OpenManus/venv/bin"
ExecStart=/home/ubuntu/OpenManus/venv/bin/python /home/ubuntu/OpenManus/main.py
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/openmanus/output.log
StandardError=append:/var/log/openmanus/error.log

[Install]
WantedBy=multi-user.target
```

Create log directory:

```bash
sudo mkdir -p /var/log/openmanus
sudo chown ubuntu:ubuntu /var/log/openmanus
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable openmanus
sudo systemctl start openmanus
```

Check service status:

```bash
sudo systemctl status openmanus
```

View logs:

```bash
sudo journalctl -u openmanus -f
```

## Troubleshooting

### Port Already in Use

If you encounter "port already in use" errors:

```bash
# Kill all Python processes
pkill -f python

# Or use the deployment script's port cleanup
./deploy_aws.sh
```

### Python Version Issues

Ensure Python 3.12 is installed:

```bash
python3.12 --version
```

If not, the deployment script will attempt to install it automatically.

### Playwright Browser Issues

If Playwright browsers fail to install or you see validation errors:

```bash
source venv/bin/activate

# Install system dependencies (requires sudo)
sudo playwright install-deps chromium

# Install browser
playwright install chromium
```

### Configuration Errors

Verify your configuration file:

```bash
cat config/config.toml
```

Make sure API keys are properly set and not using placeholder values.

## Security Recommendations

1. **Secure API Keys**: Never commit API keys to version control
2. **Firewall Configuration**: Only open necessary ports
3. **Use IAM Roles**: For AWS services, use IAM roles instead of access keys
4. **Regular Updates**: Keep the system and dependencies updated
5. **Monitor Resources**: Set up CloudWatch alarms for resource usage

## AWS-Specific Tips

### Using EC2 Instance Profile (Recommended)

Instead of hardcoding AWS credentials, use an EC2 instance profile:

1. Create an IAM role with necessary permissions
2. Attach the role to your EC2 instance
3. Remove AWS credentials from config files

### Network Configuration

Make sure your security group allows:
- SSH (port 22) from your IP
- Any application ports you plan to expose

### Cost Optimization

- Use spot instances for development/testing
- Set up auto-shutdown for non-production instances
- Monitor usage with AWS Cost Explorer

## Additional Resources

- [OpenManus Documentation](https://github.com/FoundationAgents/OpenManus)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Systemd Service Management](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
