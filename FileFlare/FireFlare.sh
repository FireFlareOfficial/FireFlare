#!/bin/bash

# Color codes for text styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'  # Reset color

# File for saving data
DATA_FILE="file_manager_data.txt"

# Arrays for locked and pinned files
locked_files=()  # Array to store locked files
pinned_files=()  # Array to store pinned files
is_admin=false   # Variable to track admin status

# Function to load data from the saved file
load_data() {
    if [ -f "$DATA_FILE" ]; then
        while IFS= read -r line; do
            if [[ "$line" == "LOCKED_FILES:"* ]]; then
                locked_files=($(echo "$line" | sed 's/LOCKED_FILES://'))
            elif [[ "$line" == "PINNED_FILES:"* ]]; then
                pinned_files=($(echo "$line" | sed 's/PINNED_FILES://'))
            elif [[ "$line" == "ADMIN_STATUS:"* ]]; then
                is_admin=$(echo "$line" | sed 's/ADMIN_STATUS://')
            fi
        done < "$DATA_FILE"
    fi
}

# Function to save data to the file
save_data() {
    echo "LOCKED_FILES: ${locked_files[*]}" > "$DATA_FILE"
    echo "PINNED_FILES: ${pinned_files[*]}" >> "$DATA_FILE"
    echo "ADMIN_STATUS: $is_admin" >> "$DATA_FILE"
}

# Simple styled header for the script
echo -e "${MAGENTA}###############################"
echo -e "#      File Manager v2.0      #"
echo -e "###############################${RESET}"

# Function to display fancy separators
fancy_separator() {
    echo -e "${BLUE}----------------------------------------${RESET}"
}

# Function to lock a file (Only allowed for admins)
lock_file() {
    if [ "$is_admin" = true ]; then
        locked_files+=("$1")
        echo -e "${GREEN}File locked successfully.${RESET}"
        save_data  # Save the progress after locking
    else
        echo -e "${RED}You do not have admin access to lock files.${RESET}"
    fi
}

# Function to unlock a file (Only allowed for admins)
unlock_file() {
    if [ "$is_admin" = true ]; then
        locked_files=("${locked_files[@]/$1}")
        echo -e "${GREEN}File unlocked successfully.${RESET}"
        save_data  # Save the progress after unlocking
    else
        echo -e "${RED}You do not have admin access to unlock files.${RESET}"
    fi
}

# Function to pin a file (Only allowed for admins)
pin_file() {
    if [ "$is_admin" = true ]; then
        pinned_files+=("$1")
        echo -e "${GREEN}File pinned successfully.${RESET}"
        save_data  # Save the progress after pinning
    else
        echo -e "${RED}You do not have admin access to pin files.${RESET}"
    fi
}

# Function to unpin a file (Only allowed for admins)
unpin_file() {
    if [ "$is_admin" = true ]; then
        pinned_files=("${pinned_files[@]/$1}")
        echo -e "${GREEN}File unpinned successfully.${RESET}"
        save_data  # Save the progress after unpinning
    else
        echo -e "${RED}You do not have admin access to unpin files.${RESET}"
    fi
}

# Function to show available actions (Only if the user is an admin)
show_actions() {
    if [ "$is_admin" = true ]; then
        echo -e "${MAGENTA}Available Actions:${RESET}"
        echo -e "${YELLOW}1. Lock File"
        echo -e "${YELLOW}2. Unlock File"
        echo -e "${YELLOW}3. Pin File"
        echo -e "${YELLOW}4. Unpin File"
        echo -e "${YELLOW}5. Exit Editing"
        fancy_separator
    else
        echo -e "${RED}You do not have admin access to perform actions on files.${RESET}"
    fi
}

# Function to view pinned files
view_pinned_files() {
    if [ ${#pinned_files[@]} -gt 0 ]; then
        echo -e "${CYAN}Pinned files:${RESET}"
        for pinned_file in "${pinned_files[@]}"; do
            echo -e "${BLUE}- ${pinned_file}${RESET}"
        done
    else
        echo -e "${RED}No pinned files found.${RESET}"
    fi
}

# Function to check if file is locked
is_locked() {
    for locked in "${locked_files[@]}"; do
        if [ "$1" == "$locked" ]; then
            return 0  # File is locked
        fi
    done
    return 1  # File is not locked
}

# Main loop
load_data  # Load the saved data at the start of the script

while true
do
    fancy_separator
    # Prompt user for the file name
    echo -e "${YELLOW}Enter file name to search (or 'exit' to quit):${RESET}"
    read file_name

    # Exit condition
    if [ "$file_name" == "exit" ]; then
        echo -e "${GREEN}Goodbye!${RESET}"
        break
    fi

    # Check if the user wants to view pinned files
    if [ "$file_name" == "view.pinned.files" ]; then
        view_pinned_files
        continue
    fi

    # Handle admin access
    if [ "$file_name" == "Open.Advanced.Mode" ]; then
        echo -e "${GREEN}Admin access granted! You can now lock, unlock, and manage files.${RESET}"
        is_admin=true
        save_data  # Save admin status
        continue
    fi

    # Searching in the user's primary directories: Desktop, Downloads, Documents, Music, Pictures, Videos
    echo -e "${CYAN}Searching for files in main locations...${RESET}"
    file_list=$(timeout 10s find ~/Desktop ~/Downloads ~/Documents ~/Music ~/Pictures ~/Videos -type f -iname "*$file_name*" 2>/dev/null)

    if [ -n "$file_list" ]; then
        echo -e "${GREEN}Files found:${RESET}"

        # Convert file list into an array
        file_array=($file_list)

        # Display files with clear numbering and limit per page
        file_counter=1
        total_files=${#file_array[@]}
        pages=$((total_files / 10))
        if [ $((total_files % 10)) -ne 0 ]; then
            pages=$((pages + 1))
        fi

        echo -e "${YELLOW}List of files found in your directories:${RESET}"
        fancy_separator

        while true; do
            echo -e "${YELLOW}Enter page number (1-$pages), 'show.all' to view all files, or 'exit' to quit:${RESET}"
            read page_input

            if [ "$page_input" == "exit" ]; then
                echo -e "${GREEN}Goodbye!${RESET}"
                break 2
            fi

            if [ "$page_input" == "show.all" ]; then
                # Show all files
                for file in "${file_array[@]}"; do
                    file_name_only=$(basename "$file")
                    if is_locked "$file"; then
                        if [ "$is_admin" = true ]; then
                            echo -e "${YELLOW}[Admin] ${RED}[$file_counter] ${file_name_only} (Locked - You have admin access)${RESET}"
                        else
                            echo -e "${RED}[$file_counter] ${file_name_only} (Locked)${RESET}"
                        fi
                    else
                        echo -e "${BLUE}[$file_counter] ${file_name_only}${RESET}"
                    fi
                    ((file_counter++))
                done
                break
            fi

            # Validate page input
            if [[ "$page_input" =~ ^[0-9]+$ ]] && [ "$page_input" -ge 1 ] && [ "$page_input" -le "$pages" ]; then
                # Show files for the selected page
                start=$(( (page_input - 1) * 10 ))
                end=$(( start + 9 ))

                # Limit the files shown to the selected range (from 1-10 per page)
                if [ "$end" -ge "$total_files" ]; then
                    end=$((total_files - 1))
                fi

                for ((i=start; i<=end; i++)); do
                    file_name_only=$(basename "${file_array[$i]}")
                    if is_locked "${file_array[$i]}"; then
                        if [ "$is_admin" = true ]; then
                            echo -e "${YELLOW}[Admin] ${RED}[$file_counter] ${file_name_only} (Locked - You have admin access)${RESET}"
                        else
                            echo -e "${RED}[$file_counter] ${file_name_only} (Locked)${RESET}"
                        fi
                    else
                        echo -e "${BLUE}[$file_counter] ${file_name_only}${RESET}"
                    fi
                    ((file_counter++))
                done
                break
            else
                echo -e "${RED}Invalid input. Please try again.${RESET}"
            fi
        done

        fancy_separator
        # Prompt to select a file
        echo -e "${YELLOW}Enter the number of the file you want to edit, or 'exit' to quit:${RESET}"
        read file_choice

        if [ "$file_choice" == "exit" ]; then
            echo -e "${GREEN}Goodbye!${RESET}"
            break
        fi

        # Ensure the file exists
        if [ "$file_choice" -gt 0 ] && [ "$file_choice" -le "$total_files" ]; then
            selected_file="${file_array[$((file_choice - 1))]}"

            # Show actions only if admin
            show_actions

            # Actions based on input
            read action_choice
            case "$action_choice" in
                1) lock_file "$selected_file" ;;
                2) unlock_file "$selected_file" ;;
                3) pin_file "$selected_file" ;;
                4) unpin_file "$selected_file" ;;
                5) break ;;
                *) echo -e "${RED}Invalid choice, returning to file selection.${RESET}" ;;
            esac
        else
            echo -e "${RED}Invalid file number selected.${RESET}"
        fi
    else
        echo -e "${RED}No files found with that name.${RESET}"
    fi
done

