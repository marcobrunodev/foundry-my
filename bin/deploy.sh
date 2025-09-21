#!/bin/bash

# Deploy Helper Script with Safety Checks
# Usage: ./bin/deploy.sh [network] [script]
# Example: ./bin/deploy.sh base-sepolia ClaimVerifier/DeployClaimVerifier

NETWORK=$1
SCRIPT=$2

if [ -z "$NETWORK" ] || [ -z "$SCRIPT" ]; then
    echo "Usage: ./deploy.sh [network] [script]"
    echo "Networks: base-sepolia, base-mainnet"
    echo "Scripts: DeployClaimVerifier, UpgradeClaimVerifier"
    exit 1
fi

# Safety Check 1: Run linting first
echo "🔍 Running linting before deployment..."
if ! forge fmt --check > /dev/null 2>&1; then
    echo ""
    echo "❌ DEPLOYMENT ABORTED: Code formatting issues found!"
    echo "💡 Please run 'forge fmt' to fix formatting before deploying."
    echo ""
    exit 1
fi
echo "✅ Code formatting is correct!"

# Safety Check 2: Run tests
echo "🔍 Running tests before deployment..."
if ! forge test > /dev/null 2>&1; then
    echo ""
    echo "❌ DEPLOYMENT ABORTED: Tests are failing!"
    echo "💡 Please fix all failing tests before deploying."
    echo ""
    echo "Run 'forge test' to see the failing tests."
    exit 1
fi
echo "✅ All tests passed!"

# Safety Check 3: Compilation check
echo "🔨 Verifying contracts compile..."
if ! forge build > /dev/null 2>&1; then
    echo ""
    echo "❌ DEPLOYMENT ABORTED: Compilation failed!"
    echo "💡 Please fix compilation errors before deploying."
    exit 1
fi
echo "✅ Compilation successful!"

# Safety Check 4: Special warning for mainnet
if [[ "$NETWORK" == *"-mainnet"* ]]; then
    echo ""
    echo "⚠️  🚨 MAINNET DEPLOYMENT WARNING 🚨 ⚠️"
    echo "You are about to deploy to MAINNET with REAL costs!"
    echo "Network: $NETWORK"
    echo "Script: $SCRIPT"
    echo "Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo ""
    read -p "Are you absolutely sure you want to proceed? (type 'YES' to confirm): " -r
    if [ "$REPLY" != "YES" ]; then
        echo "❌ Deployment cancelled for safety."
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

echo "🚀 Deploying $SCRIPT to $NETWORK..."
echo "📄 Using environment file: $ENV_FILE"

# Load and export environment variables
set -a
source $ENV_FILE
set +a

# Determine wallet based on network
case $NETWORK in
    "base-sepolia")
        WALLET_NAME="sepolia-deployer"
        RPC_VAR="BASE_RPC_URL"
        ;;
    "base-mainnet")
        WALLET_NAME="mainnet-deployer"
        RPC_VAR="BASE_RPC_URL"
        ;;
    "polygon-amoy")
        WALLET_NAME="amoy-deployer"
        RPC_VAR="POLYGON_RPC_URL"
        ;;
    "polygon-mainnet")
        WALLET_NAME="polygon-deployer"
        RPC_VAR="POLYGON_RPC_URL"
        ;;
    "ronin-saigon")
        WALLET_NAME="saigon-deployer"
        RPC_VAR="RONIN_RPC_URL"
        ;;
    "ronin-mainnet")
        WALLET_NAME="ronin-deployer"
        RPC_VAR="RONIN_RPC_URL"
        ;;
    *)
        echo "Unknown network: $NETWORK"
        exit 1
        ;;
esac

echo "🔑 Using deployer wallet: $WALLET_NAME"
echo "👑 Contract owner will be: $INITIAL_OWNER"

# Note: We'll verify the deployer address during the actual deployment
# cast wallet address requires additional parameters that we don't need here

# Get the RPC URL dynamically based on network
RPC_URL=${!RPC_VAR}

echo "🌐 Using RPC: $RPC_URL"

# Final confirmation before deployment
echo ""
echo "📋 DEPLOYMENT SUMMARY:"
echo "   Network: $NETWORK"
echo "   Script: $SCRIPT"
echo "   Wallet: $WALLET_NAME"
echo "   Owner: $INITIAL_OWNER"
echo "   RPC: $RPC_URL"
echo ""
read -p "🚀 Ready to deploy? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# Execute the script (without verification first)
echo ""
echo "🚀 Deploying contract..."
forge script script/$SCRIPT.s.sol \
    --rpc-url $RPC_URL \
    --account $WALLET_NAME \
    --broadcast

DEPLOY_EXIT_CODE=$?

if [ $DEPLOY_EXIT_CODE -eq 0 ]; then
    echo "✅ Contract deployed successfully!"
    echo ""

    # Ask for verification confirmation
    read -p "🔍 Do you want to verify the contract on the block explorer? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🔍 Verifying contract on block explorer..."

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
            echo "⚠️ Contract verification failed, but deployment was successful."
        fi
    else
        echo "⏭️ Skipping contract verification."
    fi
else
    echo "❌ Deploy failed with exit code: $DEPLOY_EXIT_CODE"
    exit $DEPLOY_EXIT_CODE
fi

# Extract addresses if deployment was successful
if [ $DEPLOY_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "🎉 Deploy successful! Extracting addresses..."
    
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
    
    BROADCAST_DIR="broadcast/$(basename "$SCRIPT").s.sol/$CHAIN_ID"
    LATEST_FILE="$BROADCAST_DIR/run-latest.json"
    
    if [ -f "$LATEST_FILE" ]; then
        # Check if jq is available
        if command -v jq &> /dev/null; then
            # Check if we have return values (indicates proxy deployment from script)
            RETURNS_AVAILABLE=$(jq -r '.returns // empty' "$LATEST_FILE")
            
            # Determine contract variable names based on script name
            SCRIPT_NAME=$(basename "$SCRIPT" | sed 's/Deploy//')
            
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
            
            if [ -n "$RETURNS_AVAILABLE" ]; then
                # Check if this is a proxy deployment (has implementation and proxy fields)
                IMPLEMENTATION=$(jq -r '.returns.implementation.value // empty' "$LATEST_FILE")
                PROXY=$(jq -r '.returns.proxy.value // empty' "$LATEST_FILE")

                # Check if we can identify this as a proxy deployment first
                TRANSACTION_COUNT=$(jq -r '.transactions | length' "$LATEST_FILE")
                HAS_PROXY_TX=$(jq -r '.transactions[] | select(.contractName == "ERC1967Proxy") | .contractAddress' "$LATEST_FILE")

                # Only try to complete missing values if there's evidence of proxy deployment
                IS_PROXY_DEPLOYMENT=false

                # Evidence 1: Both implementation and proxy returned explicitly
                if [ -n "$IMPLEMENTATION" ] && [ -n "$PROXY" ] && [ "$IMPLEMENTATION" != "null" ] && [ "$PROXY" != "null" ]; then
                    IS_PROXY_DEPLOYMENT=true
                fi

                # Evidence 2: 2 transactions with one being ERC1967Proxy (incomplete returns scenario)
                if [ "$TRANSACTION_COUNT" -eq 2 ] && [ -n "$HAS_PROXY_TX" ] && [ "$HAS_PROXY_TX" != "null" ]; then
                    IS_PROXY_DEPLOYMENT=true

                    # Now we can safely complete missing values from transactions
                    if [ -z "$IMPLEMENTATION" ] || [ "$IMPLEMENTATION" = "null" ]; then
                        IMPLEMENTATION=$(jq -r '.returns."0".value // .returns[0].value // empty' "$LATEST_FILE")
                    fi

                    if [ -z "$PROXY" ] || [ "$PROXY" = "null" ]; then
                        PROXY="$HAS_PROXY_TX"
                    fi

                    # If we still don't have implementation, get it from transactions
                    if [ -z "$IMPLEMENTATION" ] || [ "$IMPLEMENTATION" = "null" ]; then
                        IMPLEMENTATION=$(jq -r '.transactions[] | select(.contractName != "ERC1967Proxy") | .contractAddress' "$LATEST_FILE")
                    fi
                fi

                if [ "$IS_PROXY_DEPLOYMENT" = true ]; then
                    # This is a proxy deployment - either from returns or detected from transactions
                    if [ -n "$HAS_PROXY_TX" ] && [ "$HAS_PROXY_TX" != "null" ]; then
                        echo "🔄 Proxy deployment detected (from transactions)"
                        # Ensure we have the correct addresses from transactions if returns were incomplete
                        if [ -z "$PROXY" ] || [ "$PROXY" = "null" ]; then
                            PROXY="$HAS_PROXY_TX"
                        fi
                        if [ -z "$IMPLEMENTATION" ] || [ "$IMPLEMENTATION" = "null" ]; then
                            IMPLEMENTATION=$(jq -r '.transactions[] | select(.contractName != "ERC1967Proxy") | .contractAddress' "$LATEST_FILE")
                        fi
                    else
                        echo "🔄 Proxy deployment detected (from returns)"
                    fi
                    echo "🏭 Implementation: $IMPLEMENTATION"
                    echo "🔄 Proxy: $PROXY"
                    
                    IMPL_VAR="${CONTRACT_NAME}_IMPL"
                    PROXY_VAR="${CONTRACT_NAME}_PROXY"
                    
                    echo "📝 Using variables: $IMPL_VAR and $PROXY_VAR"
                    
                    # Add comment header if adding new variables
                    NEEDS_COMMENT=false
                    if ! grep -q "$IMPL_VAR=" "$ENV_FILE" || ! grep -q "$PROXY_VAR=" "$ENV_FILE"; then
                        NEEDS_COMMENT=true
                    fi
                    
                    if [ "$NEEDS_COMMENT" = true ]; then
                        echo "" >> "$ENV_FILE"
                        echo "" >> "$ENV_FILE"
                        echo "# Contract addresses from last deploy of $SCRIPT_NAME" >> "$ENV_FILE"
                    fi
                    
                    # Update implementation address
                    if grep -q "$IMPL_VAR=" "$ENV_FILE"; then
                        sed -i '' "s/$IMPL_VAR=.*/$IMPL_VAR=$IMPLEMENTATION/" "$ENV_FILE"
                    else
                        echo "$IMPL_VAR=$IMPLEMENTATION" >> "$ENV_FILE"
                    fi
                    
                    # Update proxy address
                    if grep -q "$PROXY_VAR=" "$ENV_FILE"; then
                        sed -i '' "s/$PROXY_VAR=.*/$PROXY_VAR=$PROXY/" "$ENV_FILE"
                    else
                        echo "$PROXY_VAR=$PROXY" >> "$ENV_FILE"
                    fi
                    
                    echo ""
                    echo "✅ All proxy addresses automatically updated in $ENV_FILE"
                    echo "📝 $IMPL_VAR: $IMPLEMENTATION"
                    echo "📝 $PROXY_VAR: $PROXY"
                else
                    # This is a simple contract deployment with returns (like TrustedERC1155)
                    CONTRACT_ADDRESS=$(jq -r '.returns."0".value // .returns[0].value // empty' "$LATEST_FILE")
                    
                    if [ -z "$CONTRACT_ADDRESS" ] || [ "$CONTRACT_ADDRESS" = "null" ]; then
                        # Fallback to transaction contract address
                        CONTRACT_ADDRESS=$(jq -r '.transactions[0].contractAddress' "$LATEST_FILE")
                    fi
                    
                    echo "📄 Simple contract deployment detected (with returns)"
                    echo "📍 Contract: $CONTRACT_ADDRESS"
                    
                    CONTRACT_VAR="${CONTRACT_NAME}_ADDRESS"
                    
                    echo "📝 Using variable: $CONTRACT_VAR"
                    
                    # Add comment header if adding new variable
                    if ! grep -q "$CONTRACT_VAR=" "$ENV_FILE"; then
                        echo "" >> "$ENV_FILE"
                        echo "" >> "$ENV_FILE"
                        echo "# Contract address from last deploy of $SCRIPT_NAME" >> "$ENV_FILE"
                    fi
                    
                    # Update only contract address
                    if [ -n "$CONTRACT_ADDRESS" ] && [ "$CONTRACT_ADDRESS" != "null" ]; then
                        if grep -q "$CONTRACT_VAR=" "$ENV_FILE"; then
                            sed -i '' "s/$CONTRACT_VAR=.*/$CONTRACT_VAR=$CONTRACT_ADDRESS/" "$ENV_FILE"
                        else
                            echo "$CONTRACT_VAR=$CONTRACT_ADDRESS" >> "$ENV_FILE"
                        fi
                    fi
                    
                    echo ""
                    echo "✅ Contract address automatically updated in $ENV_FILE"
                    echo "📝 $CONTRACT_VAR: $CONTRACT_ADDRESS"
                fi
            else
                # This is a simple contract deployment (no proxy)
                CONTRACT_ADDRESS=$(jq -r '.transactions[0].contractAddress' "$LATEST_FILE")

                    echo "📄 Simple contract deployment detected"
                    echo "📍 Contract: $CONTRACT_ADDRESS"
                
                CONTRACT_VAR="${CONTRACT_NAME}_ADDRESS"
                
                echo "📝 Using variable: $CONTRACT_VAR"
                
                # Add comment header if adding new variable
                if ! grep -q "$CONTRACT_VAR=" "$ENV_FILE"; then
                    echo "" >> "$ENV_FILE"
                    echo "" >> "$ENV_FILE"
                    echo "# Contract address from last deploy of $SCRIPT_NAME" >> "$ENV_FILE"
                fi
                
                # Update only contract address
                if [ -n "$CONTRACT_ADDRESS" ] && [ "$CONTRACT_ADDRESS" != "null" ]; then
                    if grep -q "$CONTRACT_VAR=" "$ENV_FILE"; then
                        sed -i '' "s/$CONTRACT_VAR=.*/$CONTRACT_VAR=$CONTRACT_ADDRESS/" "$ENV_FILE"
                    else
                        echo "$CONTRACT_VAR=$CONTRACT_ADDRESS" >> "$ENV_FILE"
                    fi
                fi
                
                echo ""
                echo "✅ Contract address automatically updated in $ENV_FILE"
                echo "📝 $CONTRACT_VAR: $CONTRACT_ADDRESS"
            fi
        else
            echo "⚠️  jq not found. Install with: brew install jq"
            echo "   Addresses not automatically updated."
        fi
    else
        echo "⚠️  Broadcast file not found: $LATEST_FILE"
    fi
else
    echo "❌ Deploy failed with exit code: $DEPLOY_EXIT_CODE"
fi

echo "✅ Deploy completed!"
