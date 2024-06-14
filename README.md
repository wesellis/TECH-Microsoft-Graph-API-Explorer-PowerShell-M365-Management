# Microsoft Graph API Explorer

This repository contains a collection of PowerShell scripts designed to interact with the Microsoft Graph API for various administrative tasks in Microsoft 365.

## Table of Contents

- [Description](#description)
- [Installation](#installation)
- [Usage](#usage)
  - [Sample Script: Get User Information](#sample-script-get-user-information)
- [Scripts](#scripts)
- [Contributing](#contributing)
- [License](#license)

## Description

The Microsoft Graph API Explorer project aims to provide a set of tools to interact with the Microsoft Graph API, enabling automation and management of Microsoft 365 services.

## Installation

To get started, clone the repository and install the required dependencies.

\`ash
git clone https://github.com/wesellis/Microsoft-Graph-API-Explorer.git
cd Microsoft-Graph-API-Explorer
\`

## Usage

### Sample Script: Get User Information

To get user information from Microsoft 365, use the \get-user-info.ps1\ script.

\`powershell
./scripts/get-user-info.ps1 -tenantId "<Tenant-ID>" -clientId "<Client-ID>" -clientSecret "<Client-Secret>" -userId "<User-ID>"
\`

### Other Scripts

- **list-users.ps1**: Script to list all users in the organization.
- **create-user.ps1**: Script to create a new user.
- **update-user.ps1**: Script to update user information.
- **delete-user.ps1**: Script to delete a user.
- **list-groups.ps1**: Script to list all groups in the organization.
- **add-user-to-group.ps1**: Script to add a user to a group.
- **remove-user-from-group.ps1**: Script to remove a user from a group.
- **get-group-members.ps1**: Script to get all members of a group.
- **create-group.ps1**: Script to create a new group.
- **delete-group.ps1**: Script to delete a group.

## Contributing

We welcome contributions to improve and expand this collection of scripts. Please see our [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
