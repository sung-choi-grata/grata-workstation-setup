#!/bin/bash

# Define the desired Python version
PYTHON_VERSION="3.13"
BREW_PATH="/opt/homebrew/bin/brew"
ZPROFILE=~/.zprofile
ZSHRC=~/.zshrc
NVM_DIR=~/.nvm

# Function to print messages with formatting
function print_message() {
  echo "======================================"
  echo "$1"
  echo "======================================"
}

# Add aliases if not already present
add_alias_if_missing() {
  local alias_name=$1
  local alias_command=$2
  if ! grep -q "alias $alias_name=" "$ZPROFILE"; then
    echo "alias $alias_name=\"$alias_command\"" >> "$ZPROFILE"
    print_message "Added alias: $alias_name"
  else
    print_message "Alias $alias_name already exists. Skipping..."
  fi
}

# Ensure ~/.zshrc exists
if [ ! -f "$ZSHRC" ]; then
  print_message "Creating ~/.zshrc..."
  touch "$ZSHRC"
fi


# Ensure ~/.zprofile exists
if [ ! -f "$ZPROFILE" ]; then
  print_message "Creating ~/.zprofile..."
  touch "$ZPROFILE"
fi


# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
  print_message "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Re-evaluate path after install
  if [[ -d "/opt/homebrew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  elif [[ -d "/usr/local/Homebrew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
  fi
else
  print_message "Homebrew is already installed. Skipping..."
fi

# Ensure Homebrew is available in PATH
if [[ -d "/opt/homebrew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  SHELL_ENV_LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'
elif [[ -d "/usr/local/Homebrew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
  SHELL_ENV_LINE='eval "$(/usr/local/bin/brew shellenv)"'
fi

# Add Homebrew PATH to shell startup file if missing
if ! grep -q "$SHELL_ENV_LINE" ~/.zprofile; then
  echo "$SHELL_ENV_LINE" >> ~/.zprofile
fi



# Update Homebrew
print_message "Updating Homebrew..."
brew update


# Install Python with the specified version
if brew list | grep -q "python@$PYTHON_VERSION"; then
  print_message "Python $PYTHON_VERSION is already installed. Skipping..."
else
  print_message "Installing Python $PYTHON_VERSION..."
  brew install python@$PYTHON_VERSION
  brew link python@$PYTHON_VERSION --force --overwrite
fi

# Install git
if brew list | grep -q "git"; then
  print_message "Git is already installed. Skipping..."
else
  print_message "Installing Git..."
  brew install git
fi

# Install pre-commit
if brew list | grep -q "pre-commit"; then
  print_message "pre-commit is already installed. Skipping..."
else
  print_message "Installing pre-commit..."
  brew install pre-commit
fi


# Remove AWS_ACCESS_KEY_ID from shell configuration files
cleanup_aws_credentials() {
  print_message "Cleaning up AWS credentials from shell configuration files..."
  
  # Remove from .zshrc if it exists
  if [ -f ~/.zshrc ]; then
    sed -i '' '/export AWS_ACCESS_KEY_ID=/d' ~/.zshrc
    sed -i '' '/export AWS_SECRET_ACCESS_KEY=/d' ~/.zshrc
    print_message "Removed AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from .zshrc"
  fi
  
  # Remove from .zprofile
  if [ -f ~/.zprofile ]; then
    sed -i '' '/export AWS_ACCESS_KEY_ID=/d' ~/.zprofile
    sed -i '' '/export AWS_SECRET_ACCESS_KEY=/d' ~/.zprofile
    print_message "Removed AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from .zprofile"
  fi
}

cleanup_aws_credentials


# Install AWS CLI 
if command -v aws &> /dev/null; then
  print_message "AWS CLI is already installed. Skipping..."
else
  print_message "Installing AWS CLI..."
  brew install awscli
  aws --version
  print_message "AWS CLI installed successfully. Run 'aws configure' to set up your credentials."
fi

# Setup AWS credentials directory
print_message "Setting up AWS credentials directory..."
if [ ! -d ~/.aws ]; then
  mkdir -p ~/.aws
  print_message "Created ~/.aws directory"
fi

# Backup existing credentials if they exist
if [ -d ~/.aws/credentials ]; then
  mv ~/.aws/credentials ~/.aws/credentials_bkp
  print_message "Backed up existing AWS credentials to ~/.aws/credentials_bkp"
fi

# Configure AWS SSO
print_message "Configuring AWS SSO..."
read -p "Enter AWS SSO profile name: " aws_profile_name
read -p "When prompted, enter following details:
- SSO Session Name: your_name
- CLI default client Region: default just hit enter
- SSO Start URL: https://grata.awsapps.com/start#/
- SSO Region: us-east-1
- SSO registration scopes: default just hit enter"


if [ -n "$aws_profile_name" ]; then
  aws configure sso --profile "$aws_profile_name"
  print_message "AWS SSO configuration completed for profile: $aws_profile_name"
else
  print_message "No profile name provided. Skipping AWS SSO configuration."
fi

# Add\Update AWS_PROFILE to shell startup file 
print_message "Updating AWS_PROFILE in ~/.zprofile"
sed -i '' '/export AWS_PROFILE=/d' ~/.zprofile
echo "export AWS_PROFILE=$aws_profile_name" >> ~/.zprofile

print_message "Run the following command to check if AWS credentials work:
     aws sts get-caller-identity --profile $aws_profile_name   "


add_alias_if_missing "sso" "aws sso login"

# Install AWS Session Manager Plugin
if brew list | grep -q "session-manager-plugin"; then
  print_message "AWS Session Manager Plugin is already installed. Skipping..."
else
  print_message "Installing AWS Session Manager Plugin..."
  brew install session-manager-plugin
fi


# Install Docker Desktop
if brew list | grep -q "docker"; then
  print_message "Docker is already installed. Skipping..."
else
  print_message "Installing Docker Desktop..."
  brew install docker --cask docker
fi

add_alias_if_missing "dc" "docker-compose"
add_alias_if_missing "appm" "docker-compose run --rm app python manage.py"


# Install Githup CLI
if brew list | grep -q "gh"; then
  print_message "Github CLI is already installed. Skipping..."
else
  print_message "Installing Github CLI..."
  brew install gh
fi

# Install Node.js
if brew list | grep -q "node"; then
  print_message "Node.js is already installed. Skipping..."
else
  print_message "Installing Node.js..."
  brew install node
fi

# Install NVM
if brew list | grep -q "nvm"; then
  print_message "NVM is already installed. Skipping..."
else
  print_message "Installing NVM..."
  brew install nvm
fi

# Add NVM configuration to .zshrc if not present
print_message "Configuring NVM in .zshrc..."
NVM_CONFIG='export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"'

if ! grep -q "export NVM_DIR=$HOME/.nvm" "$ZSHRC"; then
  echo "$NVM_CONFIG" >> "$ZSHRC"
  print_message "Added NVM configuration to .zshrc"
else
  print_message "NVM configuration already exists in .zshrc. Skipping..."
fi



print_message "Setup complete. Please restart your terminal or run 'source ~/.zshrc'."


