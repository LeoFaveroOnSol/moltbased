---
name: moltbased
version: 1.0.0
description: Deep knowledge skill for AI agents operating on Base L2. Token creation, DeFi, liquidity, and market making.
homepage: https://moltbased.com
metadata: {"moltbot":{"emoji":"🔵","category":"defi","chain":"base","chain_id":8453}}
---

# MoltBased

Deep knowledge skill for AI agents operating on **Base** (Coinbase's L2). Covers ETH fundamentals, ERC-20 token deployment, liquidity provisioning, DeFi operations, and wallet management.

## Skill Files

| File | URL |
|------|-----|
| **SKILL.md** (this file) | `https://moltbased.com/SKILL.md` |

**Install locally:**
```bash
mkdir -p ~/.moltbot/skills/moltbased
curl -fsSL https://moltbased.com/SKILL.md > ~/.moltbot/skills/moltbased/SKILL.md
```

---

## Base Network Fundamentals

### What is Base?

Base is an **Ethereum L2 rollup** built by Coinbase using the OP Stack (Optimism). It inherits Ethereum's security while providing faster and cheaper transactions.

### Key Parameters

| Parameter | Value |
|-----------|-------|
| **Chain ID** | `8453` |
| **RPC URL** | `https://mainnet.base.org` |
| **Block Explorer** | `https://basescan.org` |
| **Bridge** | `https://bridge.base.org` |
| **Native Token** | ETH (bridged from L1) |
| **Avg Block Time** | ~2 seconds |
| **Gas Token** | ETH |
| **Avg Gas Price** | 0.001-0.01 gwei (very cheap) |

### Testnet (Sepolia)

| Parameter | Value |
|-----------|-------|
| **Chain ID** | `84532` |
| **RPC URL** | `https://sepolia.base.org` |
| **Block Explorer** | `https://sepolia.basescan.org` |
| **Faucet** | Use Coinbase faucet or Alchemy faucet |

### Adding Base to a Wallet (ethers.js)

```javascript
const BASE_CHAIN = {
  chainId: '0x2105', // 8453 in hex
  chainName: 'Base',
  nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: ['https://mainnet.base.org'],
  blockExplorerUrls: ['https://basescan.org'],
};
```

---

## Wallet Management

### Creating a Wallet (ethers.js v6)

```javascript
import { ethers } from 'ethers';

// Random wallet
const wallet = ethers.Wallet.createRandom();
console.log('Address:', wallet.address);
console.log('Private Key:', wallet.privateKey);
console.log('Mnemonic:', wallet.mnemonic.phrase);

// From private key
const wallet2 = new ethers.Wallet(PRIVATE_KEY, provider);

// HD wallet derivation (BIP-44 path for ETH)
const hdNode = ethers.HDNodeWallet.fromPhrase(mnemonic);
const child = hdNode.derivePath("m/44'/60'/0'/0/0");
```

### Connecting to Base

```javascript
const provider = new ethers.JsonRpcProvider('https://mainnet.base.org');
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Check balance
const balance = await provider.getBalance(wallet.address);
console.log('Balance:', ethers.formatEther(balance), 'ETH');

// Check chain ID
const network = await provider.getNetwork();
console.log('Chain ID:', network.chainId); // 8453n
```

### Gas Estimation on Base

```javascript
const feeData = await provider.getFeeData();
console.log('Gas Price:', ethers.formatUnits(feeData.gasPrice, 'gwei'), 'gwei');
console.log('Max Fee:', ethers.formatUnits(feeData.maxFeePerGas, 'gwei'), 'gwei');
console.log('Max Priority Fee:', ethers.formatUnits(feeData.maxPriorityFeePerGas, 'gwei'), 'gwei');

// Base uses EIP-1559. Typical L2 fees are very low (< 0.01 gwei).
// Always estimate gas before sending:
const gasEstimate = await contract.deploymentTransaction().estimateGas();
```

### Security Best Practices

- **Never hardcode private keys** — use environment variables or encrypted keystores
- **Use HD wallets** for generating multiple addresses from one seed
- **Separate hot/cold wallets** — hot wallet for operations, cold for storage
- **Set gas limits** — always set explicit gas limits to avoid draining wallet on reverts
- **Monitor nonces** — track nonces to avoid stuck transactions

---

## ERC-20 Token Creation

### Minimal ERC-20 Contract (Solidity)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, totalSupply_ * 10 ** decimals());
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
```

### Deploying with ethers.js

```javascript
import { ethers, ContractFactory } from 'ethers';
import solc from 'solc';

// 1. Compile the contract (or use pre-compiled ABI + bytecode)
const abi = [...]; // Contract ABI
const bytecode = '0x...'; // Contract bytecode

// 2. Connect to Base
const provider = new ethers.JsonRpcProvider('https://mainnet.base.org');
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// 3. Deploy
const factory = new ContractFactory(abi, bytecode, wallet);
const token = await factory.deploy('MyToken', 'MTK', 1_000_000);
await token.waitForDeployment();

const address = await token.getAddress();
console.log('Token deployed at:', address);
console.log('TX:', token.deploymentTransaction().hash);

// 4. Verify on BaseScan
// https://basescan.org/address/<address>
```

### Using Hardhat for Deployment

```javascript
// hardhat.config.js
module.exports = {
  solidity: '0.8.20',
  networks: {
    base: {
      url: 'https://mainnet.base.org',
      accounts: [process.env.PRIVATE_KEY],
      chainId: 8453,
      gasPrice: 'auto',
    },
    baseSepolia: {
      url: 'https://sepolia.base.org',
      accounts: [process.env.PRIVATE_KEY],
      chainId: 84532,
    },
  },
  etherscan: {
    apiKey: { base: process.env.BASESCAN_API_KEY },
    customChains: [{
      network: 'base',
      chainId: 8453,
      urls: {
        apiURL: 'https://api.basescan.org/api',
        browserURL: 'https://basescan.org',
      },
    }],
  },
};
```

### Token with Tax/Fees

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TaxToken is ERC20, Ownable {
    uint256 public buyTax = 0;    // basis points (100 = 1%)
    uint256 public sellTax = 500; // 5%
    address public taxWallet;
    mapping(address => bool) public isExcludedFromTax;
    mapping(address => bool) public isDexPair;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 supply_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        taxWallet = msg.sender;
        isExcludedFromTax[msg.sender] = true;
        _mint(msg.sender, supply_ * 10 ** decimals());
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (isExcludedFromTax[from] || isExcludedFromTax[to]) {
            super._update(from, to, amount);
            return;
        }

        uint256 tax = 0;
        if (isDexPair[from]) tax = (amount * buyTax) / 10000;  // buy
        if (isDexPair[to]) tax = (amount * sellTax) / 10000;   // sell

        if (tax > 0) {
            super._update(from, taxWallet, tax);
            amount -= tax;
        }
        super._update(from, to, amount);
    }

    function setDexPair(address pair, bool status) external onlyOwner {
        isDexPair[pair] = status;
    }

    function setTaxes(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        require(_buyTax <= 1000 && _sellTax <= 1000, "Max 10%");
        buyTax = _buyTax;
        sellTax = _sellTax;
    }
}
```

---

## Liquidity Provisioning

### Aerodrome (Primary DEX on Base)

Aerodrome is a fork of Velodrome (Optimism), the dominant DEX on Base by TVL. It uses both volatile (x*y=k) and stable (curve-style) pools.

**Key Contracts (Base Mainnet):**

| Contract | Address |
|----------|---------|
| Router | `0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43` |
| Factory | `0x420DD381b31aEf6683db6B902084cB0FFECe40Da` |
| AERO Token | `0x940181a94A35A4569E4529A3CDfB74e38FD98631` |

**Adding Liquidity (ethers.js):**

```javascript
const AERODROME_ROUTER = '0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43';
const ROUTER_ABI = [
  'function addLiquidityETH(address token, bool stable, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) payable returns (uint amountToken, uint amountETH, uint liquidity)',
  'function removeLiquidityETH(address token, bool stable, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) returns (uint amountToken, uint amountETH)',
];

const router = new ethers.Contract(AERODROME_ROUTER, ROUTER_ABI, wallet);

// Approve token first
const tokenContract = new ethers.Contract(tokenAddress, ERC20_ABI, wallet);
await tokenContract.approve(AERODROME_ROUTER, ethers.MaxUint256);

// Add liquidity (volatile pool, token + ETH)
const deadline = Math.floor(Date.now() / 1000) + 600; // 10 min
const tx = await router.addLiquidityETH(
  tokenAddress,
  false,                              // stable = false for volatile
  ethers.parseEther('100000'),        // token amount
  ethers.parseEther('95000'),         // min token (5% slippage)
  ethers.parseEther('0.475'),         // min ETH
  wallet.address,
  deadline,
  { value: ethers.parseEther('0.5') } // ETH amount
);
await tx.wait();
```

### Uniswap V4 on Base

Uniswap V4 uses a singleton contract pattern with hooks. Key difference from V3: all liquidity lives in one contract.

**Key Concepts:**
- **PoolManager**: Single contract holding all pool state
- **Hooks**: Custom logic at pool lifecycle points (beforeSwap, afterSwap, etc.)
- **Flash Accounting**: Tokens only move at the end of a transaction batch

**Key Contracts (Base Mainnet):**

| Contract | Address |
|----------|---------|
| PoolManager | `0x498581fF718922c3f8e6A244956aF099B2652b2b` |
| SwapRouter | Check Uniswap docs for latest |
| PositionManager | Check Uniswap docs for latest |

```javascript
// Uniswap V4 swap via UniversalRouter
const UNIVERSAL_ROUTER = '0x6fF5693b99212Da76ad316178A184AB56D299b43'; // Base

// For simple swaps, use the SwapRouter02 or UniversalRouter
// V4 swaps are more complex due to hooks — use the Uniswap SDK:
// npm install @uniswap/v4-sdk @uniswap/sdk-core
```

### Choosing Between Aerodrome and Uniswap

| Factor | Aerodrome | Uniswap V4 |
|--------|-----------|-------------|
| **TVL on Base** | Highest | Growing |
| **Pool Types** | Volatile + Stable | Concentrated + Hooks |
| **Fee Tiers** | Fixed per pool type | Customizable |
| **Rewards** | AERO emissions | No native rewards |
| **Best For** | New tokens, quick LP | Advanced strategies, custom hooks |
| **Complexity** | Lower | Higher |

**Recommendation:** For new token launches, use **Aerodrome** (more liquidity, simpler). For advanced strategies, use **Uniswap V4** (hooks, concentrated liquidity).

---

## DeFi Operations

### Token Swaps

```javascript
// Aerodrome swap: ETH → Token
const ROUTER_SWAP_ABI = [
  'function swapExactETHForTokens(uint amountOutMin, (address from, address to, bool stable, address factory)[] routes, address to, uint deadline) payable returns (uint[] amounts)',
  'function getAmountsOut(uint amountIn, (address from, address to, bool stable, address factory)[] routes) view returns (uint[] amounts)',
];

const router = new ethers.Contract(AERODROME_ROUTER, ROUTER_SWAP_ABI, wallet);
const WETH = '0x4200000000000000000000000000000000000006'; // WETH on Base
const FACTORY = '0x420DD381b31aEf6683db6B902084cB0FFECe40Da';

// Get quote
const routes = [{ from: WETH, to: tokenAddress, stable: false, factory: FACTORY }];
const amountsOut = await router.getAmountsOut(ethers.parseEther('0.1'), routes);
const minOut = amountsOut[1] * 95n / 100n; // 5% slippage

// Execute swap
const tx = await router.swapExactETHForTokens(
  minOut,
  routes,
  wallet.address,
  Math.floor(Date.now() / 1000) + 600,
  { value: ethers.parseEther('0.1') }
);
```

### Yield Farming on Aerodrome

```javascript
// After adding liquidity, stake LP tokens in Aerodrome gauges
const GAUGE_ABI = [
  'function deposit(uint amount)',
  'function withdraw(uint amount)',
  'function getReward(address account)',
  'function earned(address account) view returns (uint)',
];

// 1. Find the gauge for your pool (check Aerodrome UI or factory)
const gauge = new ethers.Contract(gaugeAddress, GAUGE_ABI, wallet);

// 2. Approve LP token for gauge
const lpToken = new ethers.Contract(lpAddress, ERC20_ABI, wallet);
await lpToken.approve(gaugeAddress, ethers.MaxUint256);

// 3. Stake
await gauge.deposit(lpBalance);

// 4. Check rewards
const earned = await gauge.earned(wallet.address);
console.log('AERO earned:', ethers.formatEther(earned));

// 5. Claim rewards
await gauge.getReward(wallet.address);
```

### Price Feeds & Oracles

```javascript
// Chainlink price feeds on Base
const FEED_ABI = ['function latestRoundData() view returns (uint80, int256, uint256, uint256, uint80)'];

const ETH_USD_FEED = '0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70'; // Base mainnet
const feed = new ethers.Contract(ETH_USD_FEED, FEED_ABI, provider);
const [, price] = await feed.latestRoundData();
console.log('ETH/USD:', Number(price) / 1e8);
```

---

## Tools & Services

### BaseScan

- **Explorer:** https://basescan.org
- **API:** https://api.basescan.org/api
- **API Key:** Register at https://basescan.org/apis

```javascript
// Verify contract on BaseScan
// npx hardhat verify --network base <CONTRACT_ADDRESS> "MyToken" "MTK" "1000000"

// API: Get token balance
const url = `https://api.basescan.org/api?module=account&action=tokenbalance&contractaddress=${tokenAddr}&address=${walletAddr}&tag=latest&apikey=${API_KEY}`;
```

### Clanker

Clanker is a token deployment tool on Base that simplifies launching tokens directly from social media (Farcaster).

- **Website:** https://www.clanker.world
- **How it works:** Tag @clanker on Farcaster with token name/ticker → it deploys automatically
- **Contract:** Deploys standard ERC-20 + creates Uniswap V3 pool
- **Use case:** Quick, social-native token launches without code

### Base Bridge

```javascript
// Bridge ETH from Ethereum L1 → Base L2
// Official bridge: https://bridge.base.org
// Uses Optimism's Standard Bridge

const L1_BRIDGE = '0x3154Cf16ccdb4C6d922629664174b904d80F2C35'; // Base L1 bridge
const BRIDGE_ABI = [
  'function depositETHTo(address to, uint32 minGasLimit, bytes extraData) payable',
];

// On L1 (Ethereum mainnet):
const bridge = new ethers.Contract(L1_BRIDGE, BRIDGE_ABI, l1Wallet);
await bridge.depositETHTo(
  wallet.address,
  200_000,         // min gas limit on L2
  '0x',            // no extra data
  { value: ethers.parseEther('0.1') }
);
// Funds arrive on Base in ~1-5 minutes
```

### Useful Base Addresses

| Token/Contract | Address |
|---------------|---------|
| **WETH** | `0x4200000000000000000000000000000000000006` |
| **USDC** | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| **USDbC (bridged)** | `0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6Ca` |
| **DAI** | `0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb` |
| **cbETH** | `0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22` |
| **L2 Standard Bridge** | `0x4200000000000000000000000000000000000010` |
| **L2 Cross Domain Messenger** | `0x4200000000000000000000000000000000000007` |

---

## Common Patterns & Strategies

### Market Making (Grid Strategy)

```javascript
// Simple grid market maker
async function gridMarketMaker(tokenAddress, config) {
  const { gridSpacing, numLevels, orderSize, rebalanceInterval } = config;

  // Get current price
  const price = await getTokenPrice(tokenAddress);

  // Place grid orders
  for (let i = 1; i <= numLevels; i++) {
    const buyPrice = price * (1 - gridSpacing * i);
    const sellPrice = price * (1 + gridSpacing * i);

    await placeLimitOrder('buy', tokenAddress, buyPrice, orderSize);
    await placeLimitOrder('sell', tokenAddress, sellPrice, orderSize);
  }

  // Rebalance periodically
  setInterval(async () => {
    const newPrice = await getTokenPrice(tokenAddress);
    // Cancel and replace orders around new price
    await rebalanceGrid(tokenAddress, newPrice, config);
  }, rebalanceInterval);
}

// Usage
gridMarketMaker('0x...', {
  gridSpacing: 0.02,    // 2% between levels
  numLevels: 5,
  orderSize: '1000',    // tokens per level
  rebalanceInterval: 5 * 60 * 1000, // 5 minutes
});
```

### Sniping New Tokens

```javascript
// Monitor for new pair creation events
const factory = new ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI, provider);

factory.on('PoolCreated', async (token0, token1, stable, pool) => {
  console.log('New pool:', { token0, token1, pool });

  // Quick safety checks
  const isHoneypot = await checkHoneypot(token0 === WETH ? token1 : token0);
  if (isHoneypot) return;

  // Buy immediately
  const tokenToBuy = token0 === WETH ? token1 : token0;
  await swapETHForToken(tokenToBuy, ethers.parseEther('0.01'));
});
```

### Token Launch Checklist

1. **Deploy token contract** (with or without tax)
2. **Verify on BaseScan** (builds trust)
3. **Create liquidity pool** on Aerodrome or Uniswap
4. **Add initial liquidity** (recommended: lock LP tokens)
5. **Renounce ownership** if applicable (builds trust)
6. **Set up monitoring** (price, volume, holder count)
7. **Optional:** Set up market making bot

---

## Gas Optimization Tips

1. **Base is cheap** — typical tx costs < $0.01, but still optimize for high-frequency operations
2. **Batch transactions** — use multicall patterns to combine multiple operations
3. **Use `estimateGas()`** before every transaction
4. **Set reasonable gas limits** — don't use unlimited gas
5. **EIP-1559 is standard** — use `maxFeePerGas` and `maxPriorityFeePerGas`
6. **Off-peak hours** — gas is slightly cheaper during low-activity periods (but it's almost always cheap on Base)

```javascript
// Multicall pattern for batch operations
const MULTICALL3 = '0xcA11bde05977b3631167028862bE2a173976CA11'; // Same on all chains
const MULTICALL_ABI = [
  'function aggregate3(tuple(address target, bool allowFailure, bytes callData)[] calls) returns (tuple(bool success, bytes returnData)[])',
];

const multicall = new ethers.Contract(MULTICALL3, MULTICALL_ABI, wallet);
const results = await multicall.aggregate3([
  { target: token1, allowFailure: false, callData: token1Interface.encodeFunctionData('balanceOf', [wallet.address]) },
  { target: token2, allowFailure: false, callData: token2Interface.encodeFunctionData('balanceOf', [wallet.address]) },
]);
```

---

## Error Handling

Common errors on Base and how to handle them:

| Error | Cause | Fix |
|-------|-------|-----|
| `INSUFFICIENT_FUNDS` | Not enough ETH for gas | Fund wallet with more ETH |
| `NONCE_TOO_LOW` | Nonce already used | Get fresh nonce from provider |
| `UNPREDICTABLE_GAS_LIMIT` | Contract will revert | Check approval, balance, or contract state |
| `CALL_EXCEPTION` | Contract reverted | Decode revert reason, check inputs |
| `TRANSACTION_REPLACED` | TX replaced by higher gas | Resubmit or wait for replacement |

```javascript
// Robust transaction sending
async function sendTx(txPromise, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const tx = await txPromise;
      const receipt = await tx.wait();
      if (receipt.status === 0) throw new Error('Transaction reverted');
      return receipt;
    } catch (err) {
      if (err.code === 'NONCE_EXPIRED' || err.code === 'NONCE_TOO_LOW') {
        continue; // Retry with fresh nonce
      }
      if (i === retries - 1) throw err;
      await new Promise(r => setTimeout(r, 2000 * (i + 1)));
    }
  }
}
```

---

## Quick Reference

```
Chain ID:        8453 (mainnet) / 84532 (sepolia)
RPC:             https://mainnet.base.org
Explorer:        https://basescan.org
Bridge:          https://bridge.base.org
WETH:            0x4200000000000000000000000000000000000006
USDC:            0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
Aerodrome:       0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43 (router)
Multicall3:      0xcA11bde05977b3631167028862bE2a173976CA11
```

---

*Built for AI agents on Base. Deploy, trade, dominate.* 🔵
