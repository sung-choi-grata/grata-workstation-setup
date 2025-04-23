#!/bin/bash

# Define the desired Python version
PYTHON_VERSION="3.13"
BREW_PATH="/opt/homebrew/bin/brew"
ZPROFILE=~/.zprofile

# Function to print messages with formatting
function print_message() {
  echo "======================================"
  echo "$1"
  echo "======================================"
}

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


# Install AWS CLI 
if command -v aws &> /dev/null; then
  print_message "AWS CLI is already installed. Skipping..."
else
  print_message "Installing AWS CLI..."
  brew install awscli
  aws --version
  print_message "AWS CLI installed successfully. Run 'aws configure' to set up your credentials."
fi

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

add_alias_if_missing "dc" "docker-compose"
add_alias_if_missing "appm" "docker-compose run --rm app python manage.py"



print_message "Setup complete. Please restart your terminal or run 'source ~/.zshrc'."


