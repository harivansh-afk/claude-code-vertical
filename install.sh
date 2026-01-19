#!/usr/bin/env bash
#
# Claude Code Vertical - Install Script
#
# Installs skills and slash commands to your project's .claude directory
# Uses symlinks so updates to the source are automatically reflected
#
# Usage:
#   ./install.sh              # Install to current directory
#   ./install.sh /path/to/dir # Install to specified directory
#

set -euo pipefail

# Colors (disable if not a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# Get the directory where this script lives (source of truth)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target directory - default to current directory
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# What we're installing
COMPONENTS=(
    "commands:commands"
    "skills:skills"
    "skill-index:skill-index"
    "lib:lib"
)

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

log_info() {
    printf "${BLUE}[info]${NC} %s\n" "$1"
}

log_success() {
    printf "${GREEN}[ok]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[warn]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[error]${NC} %s\n" "$1"
}

log_header() {
    printf "\n${BOLD}%s${NC}\n" "$1"
    printf "%s\n" "$(printf '=%.0s' $(seq 1 ${#1}))"
}

check_prerequisites() {
    log_header "Checking prerequisites"

    # Check if source directories exist
    for component in "${COMPONENTS[@]}"; do
        local src="${component%%:*}"
        if [[ ! -d "$SCRIPT_DIR/$src" ]]; then
            log_error "Source directory not found: $SCRIPT_DIR/$src"
            exit 1
        fi
    done
    log_success "All source directories found"

    # Check if target is a git repo (optional warning)
    if [[ ! -d "$TARGET_DIR/.git" ]]; then
        log_warn "Target is not a git repository: $TARGET_DIR"
        log_info "Continuing anyway - this is not required"
    else
        log_success "Target is a git repository"
    fi

    # Check for tmux
    if command -v tmux &> /dev/null; then
        log_success "tmux is installed ($(tmux -V))"
    else
        log_warn "tmux is not installed - install with: brew install tmux"
    fi
}

create_directories() {
    log_header "Creating directories"

    local claude_dir="$TARGET_DIR/.claude"

    if [[ -d "$claude_dir" ]]; then
        log_info ".claude directory already exists"
    else
        mkdir -p "$claude_dir"
        log_success "Created $claude_dir"
    fi

    # Create vertical plans directory
    mkdir -p "$claude_dir/vertical/plans"
    log_success "Created $claude_dir/vertical/plans"
}

install_component() {
    local src_name="$1"
    local dest_name="$2"
    local src_path="$SCRIPT_DIR/$src_name"
    local dest_path="$TARGET_DIR/.claude/$dest_name"

    # Remove existing symlink or directory
    if [[ -L "$dest_path" ]]; then
        rm "$dest_path"
        log_info "Removed existing symlink: $dest_path"
    elif [[ -d "$dest_path" ]]; then
        log_warn "Directory exists (not a symlink): $dest_path"
        printf "  Replace with symlink? [y/N] "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf "$dest_path"
            log_info "Removed existing directory"
        else
            log_warn "Skipping $dest_name"
            return 0
        fi
    fi

    # Create symlink
    ln -s "$src_path" "$dest_path"
    log_success "Linked $dest_name -> $src_path"
}

install_components() {
    log_header "Installing components"

    for component in "${COMPONENTS[@]}"; do
        local src="${component%%:*}"
        local dest="${component##*:}"
        install_component "$src" "$dest"
    done
}

verify_installation() {
    log_header "Verifying installation"

    local claude_dir="$TARGET_DIR/.claude"
    local all_ok=true

    for component in "${COMPONENTS[@]}"; do
        local dest="${component##*:}"
        local dest_path="$claude_dir/$dest"

        if [[ -L "$dest_path" && -d "$dest_path" ]]; then
            local count=$(find -L "$dest_path" -type f | wc -l | tr -d ' ')
            log_success "$dest: $count files"
        else
            log_error "$dest: not found or broken symlink"
            all_ok=false
        fi
    done

    if $all_ok; then
        return 0
    else
        return 1
    fi
}

print_summary() {
    log_header "Installation complete"

    printf "\n${BOLD}Installed to:${NC} %s/.claude/\n" "$TARGET_DIR"
    printf "\n${BOLD}Available commands:${NC}\n"
    printf "  /plan         Start interactive planning session\n"
    printf "  /build <id>   Execute a plan with parallel weavers\n"
    printf "  /status [id]  Check plan and weaver status\n"

    printf "\n${BOLD}Quick start:${NC}\n"
    printf "  cd %s\n" "$TARGET_DIR"
    printf "  claude\n"
    printf "  > /plan\n"

    printf "\n${BOLD}Tmux helpers:${NC}\n"
    printf "  source %s/.claude/lib/tmux.sh\n" "$TARGET_DIR"
    printf "  vertical_status\n"

    printf "\n"
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

main() {
    printf "${BOLD}Claude Code Vertical Installer${NC}\n"
    printf "Source: %s\n" "$SCRIPT_DIR"
    printf "Target: %s\n" "$TARGET_DIR"

    # Don't install to self
    if [[ "$SCRIPT_DIR" == "$TARGET_DIR" ]]; then
        log_error "Cannot install to source directory"
        log_info "Run from your project directory or specify a target:"
        printf "  %s/install.sh /path/to/your/project\n" "$SCRIPT_DIR"
        exit 1
    fi

    check_prerequisites
    create_directories
    install_components

    if verify_installation; then
        print_summary
    else
        log_error "Installation completed with errors"
        exit 1
    fi
}

main "$@"
