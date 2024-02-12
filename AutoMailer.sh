#!/bin/bash

# Function to check if sendemail is installed
check_sendemail_installed() {
    if ! command -v sendemail &> /dev/null; then
        echo "sendemail is not installed. Installing..."
        sudo apt update
        sudo apt install sendemail -y
    else
        echo "sendemail is already installed."
    fi
}

# Call the function to check and install sendemail if necessary
check_sendemail_installed

# Function to prompt user for SMTP data
prompt_smtp_data() {
    echo "Enter SMTP server details:"
    read -p "SMTP Server: " smtp_server
    read -p "SMTP Port: " smtp_port
    read -p "SMTP Username: " smtp_username
    read -sp "SMTP Password: " smtp_password
    echo
    echo "$smtp_server" > smtp_data.txt
    echo "$smtp_port" >> smtp_data.txt
    echo "$smtp_username" >> smtp_data.txt
    echo "$smtp_password" >> smtp_data.txt
}

# Check if SMTP data exists
if [ ! -f "smtp_data.txt" ]; then
    echo "SMTP data not found. Please enter SMTP data:"
    prompt_smtp_data
else
    smtp_server=$(sed -n 1p smtp_data.txt)
    smtp_port=$(sed -n 2p smtp_data.txt)
    smtp_username=$(sed -n 3p smtp_data.txt)
    smtp_password=$(sed -n 4p smtp_data.txt)
fi

# Function to send email
send_email() {
    sendemail -f "$1" -t "$2" -u "$3" -m "$4" -s "$smtp_server":"$smtp_port" -xu "$smtp_username" -xp "$smtp_password" "$5"
}

# Function to send email with attachments
send_email_with_attachments() {
    sendemail -f "$1" -t "$2" -u "$3" -m "$4" -s "$smtp_server":"$smtp_port" -xu "$smtp_username" -xp "$smtp_password" -a "$5" "$6"
}

# Function to prompt user for email details
prompt_email_details() {
    read -p "Enter receiver email: " receiver_email
    read -p "Enter subject: " subject
    read -p "Enter message body: " message_body
}

# Function to prompt user for attachment file path
prompt_attachment() {
    read -p "Attach file? (y/n): " attach_file
    if [ "$attach_file" = "y" ]; then
        read -p "Enter path to attachment file: " attachment_file
        echo "$attachment_file"
    else
        echo ""
    fi
}

# Main menu loop
while true; do
    echo "Choose an option:"
    echo "1. Send email from a list of sender emails"
    echo "2. Send email to a list of receiver emails"
    echo "3. Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            read -p "Enter path to sender emails file: " sender_emails_file
            if [ ! -f "$sender_emails_file" ]; then
                echo "Sender emails file not found!"
                continue
            fi
            prompt_email_details
            attachment_file=$(prompt_attachment)
            if [ -n "$attachment_file" ]; then
                while IFS= read -r sender_email; do
                    send_email_with_attachments "$sender_email" "$receiver_email" "$subject" "$message_body" "$attachment_file"
                done < "$sender_emails_file"
            else
                while IFS= read -r sender_email; do
                    send_email "$sender_email" "$receiver_email" "$subject" "$message_body"
                done < "$sender_emails_file"
            fi
            ;;
        2)
            read -p "Enter path to receiver emails file: " receiver_emails_file
            if [ ! -f "$receiver_emails_file" ]; then
                echo "Receiver emails file not found!"
                continue
            fi
            read -p "Enter sender email: " sender_email
            read -p "Enter subject: " subject
            read -p "Enter message body: " message_body
            attachment_file=$(prompt_attachment)
            if [ -n "$attachment_file" ]; then
                while IFS= read -r receiver_email; do
                    send_email_with_attachments "$sender_email" "$receiver_email" "$subject" "$message_body" "$attachment_file"
                done < "$receiver_emails_file"
            else
                while IFS= read -r receiver_email; do
                    send_email "$sender_email" "$receiver_email" "$subject" "$message_body"
                done < "$receiver_emails_file"
            fi
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice!"
            ;;
    esac
done
