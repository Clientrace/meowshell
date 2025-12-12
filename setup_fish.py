import os
import platform
import subprocess
import shutil

# --- Configuration ---
# The standard location where Fish looks for its configuration
FISH_CONFIG_DIR = os.path.expanduser("~/.config/fish")
# The directory of your repository (where this script is located)
REPO_ROOT = os.path.dirname(os.path.abspath(__file__))


def run_command(command, check=True):
    """A helper function to run shell commands."""
    try:
        print(f"--> Executing: {' '.join(command)}")
        subprocess.run(command, check=check, text=True, capture_output=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {' '.join(command)}")
        print(f"Output:\n{e.stderr}")
        return False
    except FileNotFoundError:
        print(f"Error: Command not found. Is the required tool installed?")
        return False


def check_and_install_fish(os_name):
    """Checks for and attempts to install the fish shell."""
    print("--- 1. Checking for Fish Shell ---")
    if shutil.which("fish"):
        print("Fish is already installed.")
        return True

    print("Fish not found. Attempting installation...")

    if os_name == "Linux":
        # Supports Debian/Ubuntu
        if run_command(["sudo", "apt", "update"], check=False):
            # Use the fish PPA for the latest version and better dependency handling
            if run_command(
                ["sudo", "apt-add-repository", "--yes", "ppa:fish-shell/release-3"],
                check=False,
            ):
                run_command(["sudo", "apt", "update"])
                return run_command(["sudo", "apt", "install", "fish"])
            else:
                # Fallback to default repo if PPA fails
                print("PPA failed, trying standard apt install.")
                return run_command(["sudo", "apt", "install", "fish"])
        else:
            print("Could not update apt repositories. Installation failed.")
            return False

    elif os_name == "Darwin":
        # macOS using Homebrew
        if not shutil.which("brew"):
            print("Homebrew (brew) is required but not found. Please install it first.")
            return False
        return run_command(["brew", "install", "fish"])

    elif os_name == "Windows":
        # Windows using Winget (preferred) or Scoop
        if shutil.which("winget"):
            return run_command(["winget", "install", "--id=FishShell.FishShell"])
        elif shutil.which("scoop"):
            return run_command(["scoop", "install", "fish"])
        else:
            print("No suitable package manager (Winget or Scoop) found on Windows.")
            return False

    else:
        print(f"Unsupported operating system: {os_name}")
        return False


def setup_fish_config():
    """Sets up the configuration by backing up and creating symlinks."""
    print("--- 2. Setting up Fish Configuration ---")

    # 2a. Create the config directory if it doesn't exist
    os.makedirs(FISH_CONFIG_DIR, exist_ok=True)
    print(f"Ensured configuration directory exists at: {FISH_CONFIG_DIR}")

    # 2b. Backup existing files if they exist
    BACKUP_DIR = os.path.expanduser(
        "~/.config/fish_backup_" + platform.system().lower()
    )
    if os.path.exists(os.path.join(FISH_CONFIG_DIR, "config.fish")):
        print(f"Existing Fish config found. Backing up to {BACKUP_DIR}")
        if os.path.exists(BACKUP_DIR):
            shutil.rmtree(BACKUP_DIR)
        shutil.copytree(FISH_CONFIG_DIR, BACKUP_DIR, dirs_exist_ok=True)

    # Files/directories to be symlinked from your repo
    items_to_link = ["functions", "scripts", "config.fish", "fish_variables"]

    # 2c. Create symlinks
    for item in items_to_link:
        src = os.path.join(REPO_ROOT, item)
        dest = os.path.join(FISH_CONFIG_DIR, item)

        if not os.path.exists(src) or item == ".DS_Store":
            continue

        # Remove existing file/symlink before linking
        if os.path.lexists(dest):
            if os.path.isdir(dest) and not os.path.islink(dest):
                shutil.rmtree(dest)  # Remove directory only if it's not a symlink
            else:
                os.remove(dest)  # Remove file or existing symlink

        # Symlink the files from the repository
        try:
            os.symlink(src, dest)
            print(f"Created symlink: {dest} -> {src}")
        except OSError as e:
            # Note: Symlinks on Windows require admin rights or Developer Mode
            print(f"Failed to create symlink for {item}. Error: {e}")
            print(
                "On Windows, you may need to run this script as an administrator or enable Developer Mode."
            )
            return False

    print("\n--- Setup Complete ---")
    print("Your Fish configuration has been updated.")
    print(
        "You may need to run 'chsh -s $(which fish)' and restart your terminal for Fish to become your default shell."
    )
    return True


def main():
    """Main execution function."""
    system = platform.system()

    print(f"Detected OS: {system}")

    if check_and_install_fish(system):
        setup_fish_config()


if __name__ == "__main__":
    main()
