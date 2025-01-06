# Pterodactyl Unattended Installation Script

This script automates the installation of the Pterodactyl Panel, allowing you to set it up effortlessly. All necessary credentials (admin email, password, database details) are automatically generated and saved in a file for your convenience.

## Features
- Fully unattended installation.
- Automatically generates admin email, password, and database credentials.
- Saves all generated credentials in `/home/pterodactyl.txt`.
- Minimal user input required — just run the script and walk away!

## Usage
To install the Pterodactyl panel, simply run the following command: 

```bash
curl -sSL https://raw.githubusercontent.com/FinnAppel/Pterodactyl-Unattended-Install/refs/heads/main/install.sh | sudo bash
```
Sit back and relax! The script will handle the installation process for you.

## Output
Once the installation is complete, you can find the following details in `/home/pterodactyl.txt`:

- Admin Email
- Admin Password
- Database Name
- Database User
- Database Password

## Supported Linux (Unix) OS

| Linux Distro | Supported Versions | Support          |
| ------------ | ------------------ | ---------------- |
| Ubuntu       | 22.04, 24.04       | ✅ Supported |
| Debian       | None               | :x: Unsupported  |
| CentOS       | None               | :x: Unsupported  |

`If your Distro and/or Version is not listed, it is unsupported.`

## Post-Installation
1. Access your Pterodactyl Panel via your server's public IP.
2. Log in using the credentials from `pterodactyl.txt`.
3. Configure your panel as needed and start managing your servers.

## Disclaimer
This script is provided "as is" without any warranty. Use it at your own risk. Ensure you review and understand the script before running it on your system.

## Contributions
Feel free to contribute to this project by submitting issues or pull requests. Suggestions for improvement are always welcome! 
If you do contribute, please ensure you add proper credits to me for your submission. :)


## License
This project is licensed under the MIT License. See the `LICENSE` file for details.
