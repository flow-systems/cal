#!/bin/bash

# Cal.com Secret Generator Script
# Generate secure random keys for Cal.com deployment

echo "================================================"
echo "  Cal.com Secret Generator"
echo "================================================"
echo ""
echo "Copy these values to your Coolify environment variables:"
echo ""
echo "------------------------------------------------"
echo "NEXTAUTH_SECRET (32 bytes for session encryption):"
echo "------------------------------------------------"
openssl rand -base64 32
echo ""

echo "------------------------------------------------"
echo "CALENDSO_ENCRYPTION_KEY (24 bytes for AES-256):"
echo "------------------------------------------------"
openssl rand -base64 24
echo ""

echo "------------------------------------------------"
echo "CRON_API_KEY (32 bytes for cron job authentication):"
echo "------------------------------------------------"
openssl rand -base64 32
echo ""

echo "================================================"
echo "Important: Save these secrets securely!"
echo "Never commit them to version control."
echo "================================================"

