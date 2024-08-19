Sure, here's the `README.md` in English:

```markdown
# WordPress Automation Scripts

This repository contains automation scripts for installing WordPress using Bash. The project simplifies the WordPress installation process by executing a series of automated commands.

## Installation Steps

Follow these steps to install WordPress using these scripts:

### 1. Clone the Repository

First, clone this repository to your local machine using the following Git command:

```bash
git clone https://github.com/tirtahakimpambudhi/wordpress-automation-scripts.git
```

### 2. Access the Project Directory

Navigate to the project directory:

```bash
cd wordpress-automation-scripts
```

### 3. Run the Installation Script

Execute the installation script to set up WordPress:

```bash
bash install_wordpress.sh
#or
chmod +x install_wordpress.sh && ./install_wordpress.sh
```

### 4. Database Configuration

The installation script will prompt you to enter database configuration details. Ensure you have access to a MySQL or MariaDB database and note the following details:
- Database name
- Database user
- Database user password

### 5. Complete the Installation

Once the script completes, WordPress will be installed and ready for use. You can proceed with configuring the WordPress installation through the web interface by visiting your site’s URL.

## Notes

- Ensure you have access to a web server (e.g., Apache or Nginx) and the necessary database server.
- These scripts require Bash to run. Ensure you are using an operating system that supports Bash, such as Linux or macOS. If you are using Windows, you can run these scripts using WSL (Windows Subsystem for Linux).

## License

This project is licensed under the [MIT License](LICENSE.md).
