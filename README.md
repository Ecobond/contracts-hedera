# 🌿 Ecobond — Green Bond Investment Platform

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/dadadave80/bonds)

A blockchain-based platform that tokenizes environmental projects and manages USDC-backed investments. Ecobond uses a **dual-token architecture** — an ERC4626 vault for fungible investment shares and an ERC721 registry for unique project identities — powered by **Chainlink CRE** for off-chain impact scoring.

---

## Architecture

### Contract Relationships & Token Flow

```mermaid
graph TB
    subgraph Investors
        INV[Investor]
    end

    subgraph Ecobond Platform
        IM["InvestmentMod<br/>(ERC4626 Vault)"]
        PM["ProjectMod<br/>(ERC721 Registry)"]
        CRE["CREentrypoint<br/>(Oracle Bridge)"]
    end

    subgraph External
        USDC["USDC Token"]
        CL["Chainlink CRE<br/>(Off-chain Scoring)"]
        FW["Trusted Forwarder"]
    end

    INV -- "deposit(USDC)" --> IM
    IM -- "EBS Shares" --> INV
    IM -- "fundProject()" --> USDC
    USDC -- "Transfer to<br/>Project Owner" --> PM
    IM -- "getProjectScore()" --> PM
    CL -- "Impact Report" --> FW
    FW -- "onReport()" --> CRE
    CRE -- "updateProjects()" --> PM
```

### Dual-Token System

```mermaid
graph LR
    subgraph "Investment Shares — ERC4626"
        EBS["EBS Token<br/>Ecobond Shares"]
        VAULT["InvestmentMod Vault<br/>Asset: USDC (6 decimals)<br/>Shares: EBS (18 decimals)<br/>Offset: 12 decimals"]
    end

    subgraph "Project Identity — ERC721"
        EBP["EBP Token<br/>Ecobond Projects"]
        REG["ProjectMod Registry<br/>Sequential IDs (1, 2, 3...)<br/>On-chain: ImpactScore<br/>Off-chain: projectURI"]
    end

    EBS --- VAULT
    EBP --- REG
    VAULT -- "queries scores" --> REG
```

### Impact Scoring Pipeline

```mermaid
sequenceDiagram
    participant CRE as Chainlink CRE
    participant FW as Trusted Forwarder
    participant EP as CREentrypoint
    participant PM as ProjectMod
    participant IM as InvestmentMod

    CRE->>FW: Encoded ProjectDetails[] report
    FW->>EP: onReport(metadata, report)
    EP->>EP: _decodeReport(report)
    EP->>PM: updateProjects(ProjectDetails[])
    PM->>PM: Store ImpactScore per project
    PM-->>PM: emit ProjectUpdated()
    Note over IM,PM: InvestmentMod queries scores for expected returns
    IM->>PM: getProjectScore(projectId)
    PM-->>IM: ImpactScore(creditQuality, greenImpact)
    IM->>IM: expectedReturn = investment * (cq + gi) / 200
```

---

## Core Contracts

| Contract | Type | Description |
|---|---|---|
| **`ProjectMod`** | ERC721 + Enumerable + URIStorage | Project registry. Each project is an NFT with on-chain `ImpactScore` and off-chain metadata URI. |
| **`InvestmentMod`** | ERC4626 Vault + OwnableRoles | USDC-backed vault. Investors deposit USDC for shares. Issuer funds projects. `totalAssets()` includes expected returns. |
| **`CREentrypoint`** | ReceiverTemplate | Oracle bridge. Receives Chainlink CRE reports and forwards decoded project updates to `ProjectMod`. |
| **`IProjectMod`** | Interface | Defines the project registry interface with `ImpactScore` and `ProjectDetails` structs. |

### Key Data Structures

```solidity
struct ImpactScore {
    uint8 creditQuality; // 0-100 (financial risk)
    uint8 greenImpact;   // 0-100 (environmental integrity)
}

struct ProjectDetails {
    ImpactScore impactScore;
    uint256 projectId;
    string projectURI;
}
```

### Expected Returns Formula

The vault's `totalAssets()` accounts for expected returns from funded projects:

```
totalAssets = USDC balance + totalInvestments + expectedReturns

expectedReturn(project) = investment × (creditQuality + greenImpact) / 200
```

The average of both impact scores (0–100) is treated as a yield percentage on the invested capital.

---

## Access Control

```mermaid
graph TD
    OW["Owner (Multisig/DAO)"]
    IS["Issuer (ISSUER_ROLE)"]
    WL["Whitelisted Addresses"]
    CR["CRE Entrypoint"]

    OW -- "setWhitelist()" --> PM["ProjectMod"]
    OW -- "setCreEntrypointAddress()" --> PM
    OW -- "grantRoles()" --> IM["InvestmentMod"]
    IS -- "fundProject()" --> IM
    WL -- "createProject()" --> PM
    CR -- "updateProjects()" --> PM
```

| Role | Contract | Permissions |
|---|---|---|
| **Owner** | `ProjectMod` | Manage whitelist, set CRE entrypoint |
| **Owner** | `InvestmentMod` | Grant/revoke roles |
| **Issuer** | `InvestmentMod` | Fund projects from vault |
| **Whitelisted** | `ProjectMod` | Create new projects |
| **CRE Entrypoint** | `ProjectMod` | Batch update project scores |

---

## Security

- **Oracle Validation** — `CREentrypoint` extends `ReceiverTemplate` with multi-layer validation: forwarder address verification, workflow ID matching, workflow author validation, and workflow name hashing.
- **Transfer Restrictions** — `InvestmentMod` overrides `approve()`, `transfer()`, and `transferFrom()` to revert on zero addresses.
- **Liquidity Guard** — `_beforeWithdraw` ensures the vault has sufficient liquid USDC before allowing redemptions, accounting for capital locked in project investments.
- **Role Isolation** — Solady `OwnableRoles` with `keccak256`-derived role constants for the issuer.

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Format

```bash
forge fmt
```

### Deploy

```bash
forge script script/DeployEcobond.s.sol --rpc-url <RPC_URL> --broadcast
```

---

## Project Structure

```
src/
├── CREentrypoint.sol          # Chainlink CRE oracle bridge
├── InvestmentMod.sol          # ERC4626 USDC vault
├── ProjectMod.sol             # ERC721 project registry
├── interfaces/
│   ├── IProjectMod.sol        # Project registry interface
│   └── IReceiver.sol          # CRE receiver interface
└── libraries/
    └── ReceiverTemplate.sol   # Chainlink receiver base contract
test/
├── CREentrypoint.t.sol
├── InvestmentMod.t.sol
├── ProjectMod.t.sol
└── mock/
    └── MockUSDC.sol
script/
└── DeployEcobond.s.sol
```

---

## Dependencies

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) — ERC721, ERC20
- [Solady](https://github.com/Vectorized/solady) — ERC4626, OwnableRoles, SafeTransferLib
- [Forge Std](https://github.com/foundry-rs/forge-std) — Testing utilities

---

## License

MIT
