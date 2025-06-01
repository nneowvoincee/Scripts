#!/bin/bash

# Check for minimum arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <username> <password> [github_key_name]"
    exit 1
fi

USERNAME="$1"
PASSWORD="$2"
GITHUB_KEY="$3"

# Create user with home directory and bash shell
sudo useradd -m -s /bin/bash "$USERNAME" || {
    echo "Failed to create user $USERNAME"
    exit 1
}

# Set password
echo "$USERNAME:$PASSWORD" | sudo chpasswd || {
    echo "Failed to set password for $USERNAME"
    exit 1
}

# Create .ssh directory
sudo mkdir -p /home/"$USERNAME"/.ssh
sudo touch /home/"$USERNAME"/.ssh/authorized_keys
sudo touch /home/"$USERNAME"/.ssh/config

# Set ownership and permissions
sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
sudo chmod 700 /home/"$USERNAME"/.ssh
sudo chmod 600 /home/"$USERNAME"/.ssh/authorized_keys
sudo chmod 600 /home/"$USERNAME"/.ssh/config

# Configure GitHub SSH if key name is provided
if [ -n "$GITHUB_KEY" ]; then
    # Create SSH config snippet
    echo "Host github.com
    IdentityFile ~/.ssh/$GITHUB_KEY
    User git
    IdentitiesOnly yes" | sudo tee -a /home/"$USERNAME"/.ssh/config > /dev/null

    # Add GitHub to known_hosts
    sudo -u "$USERNAME" ssh-keyscan github.com 2>/dev/null >> /home/"$USERNAME"/.ssh/known_hosts
    sudo chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh/known_hosts
    sudo chmod 600 /home/"$USERNAME"/.ssh/known_hosts

    echo "Configured SSH for GitHub using key: $GITHUB_KEY"
fi

# Copy skeleton files (e.g., .bashrc)
sudo cp -r /etc/skel/. /home/"$USERNAME"/ || true

# Set final home directory ownership
sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

echo "User $USERNAME created successfully"
echo "Home directory: /home/$USERNAME"