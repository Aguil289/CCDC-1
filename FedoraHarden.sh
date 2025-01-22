#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or using sudo."
  exit 1
fi

# Update the system
dnf update -y

#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or using sudo."
  exit 1
fi

# Get a list of all user accounts excluding root
users=$(awk -F: '$3 >= 1000 && $1 != "root" {print $1}' /etc/passwd)

# Iterate through each user and change the password
for user in $users; do
  # Prompt for a new password
  read -p "Enter new password for user $user: " -s password
  echo

  # Change the password
  echo -e "$password\n$password" | passwd "$user"

  # Check if the password change was successful
  if [ $? -eq 0 ]; then
    echo "Password for user $user changed successfully."
  else
    echo "Failed to change password for user $user."
  fi
done

echo "All user passwords (excluding root) have been changed."

# Disable root login via SSH
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Configure SSH to allow only key-based authentication
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Install and configure a firewall (firewalld)
dnf install firewalld -y
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --zone=public --add-service=ssh --permanent
firewall-cmd --reload

# Enable and configure automatic security updates
dnf install dnf-automatic -y
systemctl enable --now dnf-automatic.timer

# Disable unnecessary services
systemctl disable avahi-daemon
systemctl disable cups

# Remove unnecessary packages
dnf autoremove -y

# Disable unused network protocols
echo "install dccp /bin/true" > /etc/modprobe.d/disable-dccp.conf
echo "install sctp /bin/true" > /etc/modprobe.d/disable-sctp.conf

# Enable auditd for system auditing
dnf install audit -y
systemctl enable auditd
systemctl start auditd

# Set restrictive permissions on critical files and directories
chmod 0700 /root
chmod 0700 /etc/ssh

# Set the secure permissions on user home directories
find /home -maxdepth 1 -type d -exec chmod 0700 {} \;

# Restrict access to system logs
chmod 0600 /var/log/*.log

# Set the secure permissions on system executables
chmod 0755 /bin /sbin /usr/bin /usr/sbin /lib /lib64 /usr/lib /usr/lib64

# Disable the use of USB storage devices
echo "install usb-storage /bin/true" > /etc/modprobe.d/disable-usb-storage.conf

echo "Security hardening completed."
