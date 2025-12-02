# Step-by-Step Instructions for Installing Helm on Windows

## Prerequisites
Before installing Helm, ensure you have the following prerequisites:

1. **Windows Operating System**: Helm can be installed on Windows 10 or later.
2. **Package Manager**: You can use Chocolatey for an easier installation process. If you don't have Chocolatey installed, you can follow the manual installation method.

## Installation Methods

### Method 1: Using Chocolatey
1. Open an elevated Command Prompt (Run as Administrator).
2. Install Helm by running the following command:
   ```
   choco install kubernetes-helm
   ```
3. Wait for the installation to complete.

### Method 2: Manual Installation
1. Download the latest Helm release from the official Helm GitHub repository:
   - Visit: [Helm Releases](https://github.com/helm/helm/releases)
   - Download the `helm-vX.Y.Z-windows-amd64.zip` file (replace `X.Y.Z` with the latest version number).
   
2. Extract the downloaded ZIP file to a directory of your choice (e.g., `C:\Program Files\Helm`).

3. Add the Helm executable to your system's PATH:
   - Right-click on "This PC" or "My Computer" and select "Properties".
   - Click on "Advanced system settings".
   - Click on the "Environment Variables" button.
   - In the "System variables" section, find the `Path` variable and select it, then click "Edit".
   - Click "New" and add the path to the directory where you extracted Helm (e.g., `C:\Program Files\Helm`).
   - Click "OK" to close all dialog boxes.

## Verification
To verify that Helm is installed correctly, open a new Command Prompt and run the following command:
```
helm version
```
You should see the version information for Helm, indicating that the installation was successful.