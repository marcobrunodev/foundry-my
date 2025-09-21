#!/bin/bash

# Upgrade Helper Script with Safety Checks
# Usage: ./bin/upgrade.sh [network] [script]
# Example: ./bin/upgrade.sh base-sepolia ClaimVerifier/UpgradeClaimVerifier

NETWORK=$1
SCRIPT=$2

if [ -z "$NETWORK" ] || [ -z "$SCRIPT" ]; then
    echo "Usage: ./upgrade.sh [network] [script]"
    echo "Networks: base-sepolia, base-mainnet"
    echo "Scripts: UpgradeClaimVerifier"
    exit 1
fi

# Safety Check 1: Run linting first
echo "🔍 Running linting before upgrade..."
if ! forge fmt --check > /dev/null 2>&1; then
    echo ""
    echo "❌ UPGRADE ABORTED: Code formatting issues found!"
    echo "💡 Please run 'forge fmt' to fix formatting before upgrading."
    echo ""
    exit 1
fi
echo "✅ Code formatting is correct!"

# Safety Check 2: Run tests
echo "🔍 Running tests before upgrade..."
if ! forge test > /dev/null 2>&1; then
    echo ""
    echo "❌ UPGRADE ABORTED: Tests are failing!"
    echo "💡 Please fix all failing tests before upgrading."
    echo ""
    echo "Run 'forge test' to see the failing tests."
    exit 1
fi
echo "✅ All tests passed!"

# Safety Check 3: Compilation check
echo "🔨 Verifying contracts compile..."
if ! forge build > /dev/null 2>&1; then
    echo ""
    echo "❌ UPGRADE ABORTED: Compilation failed!"
    echo "💡 Please fix compilation errors before upgrading."
    exit 1
fi
echo "✅ Compilation successful!"

# Safety Check 4: Special warning for mainnet
if [[ "$NETWORK" == *"-mainnet"* ]]; then
    echo ""
    echo "⚠️  🚨 MAINNET UPGRADE WARNING 🚨 ⚠️"
    echo "You are about to upgrade contracts on MAINNET with REAL costs!"
    echo "Network: $NETWORK"
    echo "Script: $SCRIPT"
    echo "Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo ""
    read -p "Are you absolutely sure you want to proceed? (type 'YES' to confirm): " -r
    if [ "$REPLY" != "YES" ]; then
        echo "❌ Upgrade cancelled for safety."
        exit 1
    fi
    echo ""
fi

ENV_FILE=".env.$NETWORK"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE not found!"
    echo "Please create $ENV_FILE based on .env.example"
    exit 1
fi

echo "🔄 Upgrading $SCRIPT on $NETWORK..."
echo "📄 Using environment file: $ENV_FILE"

# Load and export environment variables
set -a
source $ENV_FILE
set +a

# Determine owner wallet based on network
case $NETWORK in
    "base-sepolia")
        WALLET_NAME="sepolia-owner"
        RPC_VAR="BASE_RPC_URL"
        ;;
    "base-mainnet")
        WALLET_NAME="mainnet-owner"
        RPC_VAR="BASE_RPC_URL"
        ;;
    "polygon-amoy")
        WALLET_NAME="amoy-owner"
        RPC_VAR="POLYGON_RPC_URL"
        ;;
    "polygon-mainnet")
        WALLET_NAME="polygon-owner"
        RPC_VAR="POLYGON_RPC_URL"
        ;;
    "ronin-saigon")
        WALLET_NAME="saigon-owner"
        RPC_VAR="RONIN_RPC_URL"
        ;;
    "ronin-mainnet")
        WALLET_NAME="ronin-owner"
        RPC_VAR="RONIN_RPC_URL"
        ;;
    *)
        echo "Unknown network: $NETWORK"
        exit 1
        ;;
esac

echo "🔑 Using owner wallet: $WALLET_NAME"
echo "👑 Contract owner: $INITIAL_OWNER"
echo "� Proxy to upgrade: $CLAIM_VERIFIER_PROXY"

# Check if proxy address exists
if [ -z "$CLAIM_VERIFIER_PROXY" ]; then
    echo "❌ CLAIM_VERIFIER_PROXY not found in environment"
    echo "💡 Make sure you have deployed the contract first"
    exit 1
fi

# Get the RPC URL dynamically based on network
RPC_URL=${!RPC_VAR}

echo "🌐 Using RPC: $RPC_URL"

# Final confirmation before upgrade
echo ""
echo "📋 UPGRADE SUMMARY:"
echo "   Network: $NETWORK"
echo "   Script: $SCRIPT"
echo "   Wallet: $WALLET_NAME"
echo "   Owner: $INITIAL_OWNER"
echo "   Proxy: $CLAIM_VERIFIER_PROXY"
echo "   RPC: $RPC_URL"
echo ""
read -p "🔄 Ready to upgrade? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Upgrade cancelled."
    exit 1
fi

# Execute the upgrade script (without verification first)
echo ""
echo "🔄 Upgrading contract..."
forge script script/$SCRIPT.s.sol \
    --rpc-url $RPC_URL \
    --account $WALLET_NAME \
    --broadcast

UPGRADE_EXIT_CODE=$?

if [ $UPGRADE_EXIT_CODE -eq 0 ]; then
    echo "✅ Contract upgraded successfully!"
    echo ""

    # Ask for verification confirmation
    read -p "🔍 Do you want to verify the new implementation on the block explorer? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🔍 Verifying new implementation on block explorer..."

        # Use appropriate verifier based on network
        if [[ "$NETWORK" == *"ronin"* ]]; then
            # Ronin uses Sourcify with official endpoint
            forge script script/$SCRIPT.s.sol \
                --rpc-url $RPC_URL \
                --account $WALLET_NAME \
                --verifier sourcify \
                --verifier-url https://sourcify.roninchain.com/server/ \
                --verify \
                --resume
        else
            # Base and Polygon use Etherscan-compatible APIs
            forge script script/$SCRIPT.s.sol \
                --rpc-url $RPC_URL \
                --account $WALLET_NAME \
                --verify \
                --resume
        fi

        if [ $? -eq 0 ]; then
            echo "✅ Contract verification successful!"
        else
            echo "⚠️ Contract verification failed, but upgrade was successful."
        fi
    else
        echo "⏭️ Skipping contract verification."
    fi
else
    echo "❌ Upgrade failed with exit code: $UPGRADE_EXIT_CODE"
    exit $UPGRADE_EXIT_CODE
fi

# Extract addresses if upgrade was successful
if [ $UPGRADE_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "🎉 Upgrade successful! Extracting new implementation address..."
    
    # Map network to chain ID for broadcast directory
    case $NETWORK in
        "base-sepolia")
            CHAIN_ID="84532"
            ;;
        "base-mainnet")
            CHAIN_ID="8453"
            ;;
        "polygon-amoy")
            CHAIN_ID="80002"
            ;;
        "polygon-mainnet")
            CHAIN_ID="137"
            ;;
        "ronin-saigon")
            CHAIN_ID="2021"
            ;;
        "ronin-mainnet")
            CHAIN_ID="2020"
            ;;
    esac
    
    # Extract just the script name without directory prefix
    SCRIPT_NAME=$(basename "$SCRIPT")
    BROADCAST_DIR="broadcast/$SCRIPT_NAME.s.sol/$CHAIN_ID"
    LATEST_FILE="$BROADCAST_DIR/run-latest.json"
    
    if [ -f "$LATEST_FILE" ]; then
        # Check if jq is available
        if command -v jq &> /dev/null; then
            # Extract new implementation address from broadcast file
            NEW_IMPLEMENTATION=$(jq -r '.transactions[] | select(.transactionType == "CREATE" and .function == null) | .contractAddress' "$LATEST_FILE" | head -1)
            
            echo "🏭 New implementation: $NEW_IMPLEMENTATION"
            
            # Determine contract variable names based on script name (without directory)
            SCRIPT_NAME=$(basename "$SCRIPT" | sed 's/Upgrade//')
            
            # Convert camelCase to SCREAMING_SNAKE_CASE with intelligent handling of common patterns
            # First, handle known acronyms and patterns to preserve them
            TEMP_NAME="$SCRIPT_NAME"
            
            # Preserve common token standards
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/ERC1155/__ERC1155__/g')
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/ERC721/__ERC721__/g')
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/ERC20/__ERC20__/g')
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/NFT/__NFT__/g')
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/URI/__URI__/g')
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/ID/__ID__/g')
            
            # Add underscores before capital letters (but not at start or after underscore)
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/\([a-z0-9]\)\([A-Z]\)/\1_\2/g')
            
            # Restore preserved acronyms without extra underscores
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/__ERC1155__/ERC1155/g')
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/__ERC721__/ERC721/g')
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/__ERC20__/ERC20/g')
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/__NFT__/NFT/g')
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/__URI__/URI/g')
            TEMP_NAME=$(echo "$TEMP_NAME" | sed 's/__ID__/ID/g')
            
            # Convert to uppercase
            CONTRACT_NAME=$(echo "$TEMP_NAME" | tr '[:lower:]' '[:upper:]')
            
            IMPL_VAR="${CONTRACT_NAME}_IMPL"
            
            echo "📝 Updating variable: $IMPL_VAR"
            
            # Update implementation address in .env file
            if [ -n "$NEW_IMPLEMENTATION" ] && [ "$NEW_IMPLEMENTATION" != "null" ]; then
                if grep -q "$IMPL_VAR=" "$ENV_FILE"; then
                    # Update existing line
                    sed -i '' "s/$IMPL_VAR=.*/$IMPL_VAR=$NEW_IMPLEMENTATION/" "$ENV_FILE"
                    echo "✅ Updated existing $IMPL_VAR in $ENV_FILE"
                else
                    # Add new line
                    echo "$IMPL_VAR=$NEW_IMPLEMENTATION" >> "$ENV_FILE"
                    echo "✅ Added $IMPL_VAR to $ENV_FILE"
                fi
                
                echo "📝 $IMPL_VAR: $NEW_IMPLEMENTATION"
            else
                echo "⚠️  Could not extract implementation address"
            fi
        else
            echo "⚠️  jq not found. Install with: brew install jq"
            echo "   Implementation address not automatically updated."
        fi
    else
        echo "⚠️  Broadcast file not found: $LATEST_FILE"
    fi
else
    echo "❌ Upgrade failed with exit code: $UPGRADE_EXIT_CODE"
fi

echo "✅ Upgrade completed!"
