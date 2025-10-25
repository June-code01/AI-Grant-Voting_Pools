# AIGrant Voting Pools

A community-driven platform for AI researchers to pitch and receive micro-grants through token-based voting.

## Overview

AIGrant Voting Pools enables decentralized funding for AI research projects. Token holders vote with their voting power, and grants are automatically distributed to projects reaching community-set thresholds.

## Features

- **Proposal Creation**: Researchers submit grant proposals with funding requests
- **Token-Weighted Voting**: Community votes based on voting power
- **Threshold-Based Funding**: Automatic approval when vote threshold is met
- **Transparent Tracking**: All proposals and votes recorded on-chain
- **Sybil Resistance**: Voting power assigned by contract owner

## Contract Functions

### Public Functions

- `create-proposal`: Submit a new grant proposal
- `vote-for-proposal`: Cast vote for a proposal
- `finalize-proposal`: Approve funding when threshold met (owner only)
- `set-voter-power`: Assign voting power to addresses (owner only)

### Read-Only Functions

- `get-proposal`: Retrieve proposal details
- `get-vote`: Check voting record
- `get-voter-power`: View voter's voting power
- `get-proposal-count`: Total proposals submitted
- `get-total-grants-distributed`: Cumulative grants funded

## Getting Started
```bash
clarinet contract new ai-grant-voting
clarinet check
clarinet test
```

## Usage Example

1. Owner assigns voting power to community members
2. Researcher creates proposal with funding amount and vote threshold
3. Community members vote on proposals
4. When threshold is reached, owner finalizes funding