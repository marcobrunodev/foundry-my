# MyDuckly Smart Contracts

A comprehensive Foundry-based smart contract development environment for cross-chain deployment and lifecycle management. This repository serves as a universal foundation for all smart contract projects.

## 🚀 Features

- **Multi-Network Support**: Deploy to Base, Polygon, Ronin, and their testnets
- **Upgradeable Contracts**: Built-in proxy pattern support with OpenZeppelin
- **Automated Deployment**: Network-specific scripts with safety checks
- **Comprehensive Testing**: Gas reporting, coverage analysis, and verbose output
- **Developer Experience**: Git hooks, commit conventions, and automated workflows

## 🛠 Tech Stack

- **Foundry**: Blazing fast Ethereum development toolkit
- **OpenZeppelin**: Battle-tested smart contract libraries
- **Multi-network**: Base, Polygon, Ronin support
- **Gitmoji**: Conventional commit messages

## 📋 Quick Start

```bash
# Install dependencies
npm install
forge install

# Build contracts
npm run build

# Run tests
npm run test

# Deploy to testnet
npm run deploy:sepolia
```

## 🌐 Supported Networks

### Testnets
- **Base Sepolia**: `npm run deploy:sepolia`
- **Ronin Saigon**: `npm run deploy:saigon`
- **Polygon Amoy**: `npm run deploy:amoy`

### Mainnets
- **Base**: `npm run deploy:mainnet`
- **Ronin**: `npm run deploy:ronin`
- **Polygon**: `npm run deploy:polygon`

## 🔧 Development Commands

### Building & Testing
```bash
npm run build          # Build contracts
npm run test           # Run all tests
npm run test:verbose   # Verbose test output
npm run test:gas       # Gas usage report
npm run coverage       # Coverage analysis
```

### Deployment & Upgrades
```bash
# Deploy contracts
npm run deploy:<network>

# Upgrade contracts (for upgradeable patterns)
npm run upgrade:<network>
```

### Code Quality
```bash
forge fmt              # Format Solidity code
npm run setup-hooks    # Setup git hooks
npm run commit         # Gitmoji commit interface
```

## 📁 Project Structure

```
├── src/               # Smart contract source code
├── test/              # Test files (.t.sol)
├── script/            # Deployment scripts (.s.sol)
├── bin/               # Shell automation scripts
├── lib/               # Forge dependencies
└── .env.*             # Network-specific environment files
```

## ⚙️ Configuration

### Environment Files
Create network-specific `.env` files:
- `.env.base-sepolia` / `.env.base-mainnet`
- `.env.ronin-saigon` / `.env.ronin-mainnet`
- `.env.polygon-amoy` / `.env.polygon-mainnet`

Required variables:
```bash
# Network RPC URLs
BASE_RPC_URL=your_base_rpc_url
POLYGON_RPC_URL=your_polygon_rpc_url
RONIN_RPC_URL=your_ronin_rpc_url

# Deployment settings
INITIAL_OWNER=0x...
CLAIM_VERIFIER_PROXY=0x...  # For upgrades
```

### Wallet Configuration
Set up network-specific wallets:
- **Base**: `sepolia-deployer`, `mainnet-deployer`
- **Polygon**: `amoy-deployer`, `polygon-deployer`
- **Ronin**: `saigon-deployer`, `ronin-deployer`

## 🧪 Testing Patterns

```solidity
// Test contract pattern
contract MyContractTest is Test {
    MyContract public myContract;

    function setUp() public {
        myContract = new MyContract();
    }

    function test_MyFunction() public {
        // Test implementation
    }
}
```

Run specific tests:
```bash
forge test --match-contract MyContractTest
forge test --match-test test_MyFunction
```

## 🔐 Security Best Practices

- All deployment scripts include safety checks
- Mainnet deployments require explicit confirmation
- Environment variables for sensitive data
- Automated verification on deployment
- Comprehensive test coverage requirements

## 📖 Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Base Network Docs](https://docs.base.org/)
- [Polygon Docs](https://docs.polygon.technology/)
- [Ronin Docs](https://docs.roninchain.com/)

## 🤝 Contributing

1. Use `npm run commit` for conventional commits
2. Run tests before submitting PRs
3. Follow Solidity style guide
4. Update documentation for new features

## 📄 License

MIT License - see LICENSE file for details.
