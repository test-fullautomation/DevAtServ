#!/bin/bash

source start-devatserv.sh

# Service name
SERVICE="DevAtServ"
PACKAGE_VERSION="0.1.0.0"

display_commands() {
    echo "Commands:"
    echo "  startup     Start up DevAtServ. NOTE: Run this command for the first-time setup."
    echo "  start       Start one or all service of DevAtServ"
    echo "  stop        Stop one or all services of DevAtServ"
    echo "  status      Print one or all services status of DevAtServ"
    echo "  restart     Restart one or all services of DevAtServ"
    echo "  rm          Remove stopped service containers of DevAtSev"
    echo "  down        Stop and remove one/all services of DevAtServ, networks"
    echo "  load        Load one or all images of DevAtSev"
}

display_devatserv_gui() {
    echo "DevAtServ GUI:"
    echo "  gui         Start up DevAtServ GUI"
}

display_options() {
    echo "Options:"
    echo "  -v, --version       Print version information and quit"
    echo "  -h, --help          Show this help message"
}

# Function to show help with both commands and global options
show_help() {
  echo "Usage: $0 [command]"
  echo
  display_commands
  echo
  display_devatserv_gui
  echo
  display_options
}

# Parse command-line arguments
if [ $# -eq 0 ]; then
  show_help
else
  case $1 in
      startup) 
        startup_devatserv
        ;;
      start) 
        shift # Skip from 'start'
        start_devatserv "$@"
        ;;
      stop) 
        shift
        stop_devatserv "$@"
        ;;
      status) 
        shift 
        status_devatserv "$@"
        ;;
      restart)
        shift 
        restart_devatserv "$@"
        ;;
      rm)
        shift 
        rm_devatserv "$@"
        ;;
      down)
        shift 
        down_devatserv "$@"
        ;;
      load)
        load_devatserv
        ;;
      gui)
        startup_devatservGUI
        ;;
      -v|--version)
        echo "$SERVICE version: $PACKAGE_VERSION"
        exit 0
        ;; 
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        echo "Error: Invalid option $1"
        show_help
        exit 1
        ;;
  esac
fi