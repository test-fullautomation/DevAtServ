#!/bin/bash

set -e

source start-devatserv.sh
 
show_success_message() {
  cat <<EOF
Device Automation Services App successfully deployed!
You can access the website at http://localhost:15672 to access RabbitMQ Management
---------------------------------------------------
EOF
}

exit_after_countdown() {

  exit_after_time=10
  elapsed_time=0
  interval=1

  # Hide cursor
  tput civis

  while [ $elapsed_time -lt $exit_after_time ]; do
      # Wait for an interval
      read -t $interval -n 1 input
      if [ $? -eq 0 ]; then
          echo -e "\nKey pressed. Exiting."
          # Show the cursor
          tput cnorm
          exit 0
      fi

      elapsed_time=$((elapsed_time + interval))
      remaining_time=$((exit_after_time - elapsed_time))
      
      # Update the remain time
      printf "\rPress any key to exit early in %ds" $remaining_time
  done

  tput cnorm
  exit 0
}

handle_error() {
  echo -e "${MSG_ERR} $1"
  read -p "Press Enter to continue..."
  exit -1
}

main() {
  echo "Starting DevAtServ installation..."

  pre_check_installation || handle_error 'Error pre-check installation'

  load_devatserv || handle_error 'Error loading Docker images'

  start_devatserv || handle_error 'Error starting Docker containers'

  show_success_message
  
  exit_after_countdown || handle_error 'Error exiting'

  return 0
}

############################
# main execution
############################
main
res=$?
if [ $res != 0 ]; then 
  echo "DevAtServ occurs error, please check and install it later."
fi