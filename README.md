[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://discord.gg/uQnjZhZPfu)
[![Twitter](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/LootRealms)

<!-- badges -->
<p>
  <a href="https://starkware.co/">
    <img src="https://img.shields.io/badge/powered_by-StarkWare-navy">
  </a>
  <a href="https://github.com/dontpanicdao/starknet-burner/blob/main/LICENSE/">
    <img src="https://img.shields.io/badge/license-MIT-black">
  </a>
</p>

![Realms x Bibliotheca header](/static/realmsxbibliotheca.jpg)

# Realmverse Contracts

## Realms is an ever-expanding on-chain permission-less gaming Lootverse built on StarkNet. 

### This fork contains my work for the MatchboxDAO hackathon #2 where I have tried to expand the GoblinTown module with new features.

### Summary of Contributions

1. Goblin town launches attacks at regular intervals after spawning, trying to loot resources. In order to do this, a Goblin army is generated based on the goblin town's strength parameter
2. Goblin towns can upgrade to "strongholds" after a number of successful raids, which increases their "strength" as well as allow them to have a Hobgoblin general.
3. A Hobgoblin general boosts the combat strength of the goblin armies as the stats of the general are used to boost the quantity and health of the battalions comprising the goblin army.
4. A scouting function to pay a $LORDS fee to try and scout the details of the goblin forces to better prepare defense/attack forces
5. Functions to generate a new general with semi-randomized stats or upgrading an existing general when a stronghold increases in strength and level (strongholds can keep increasing in level with successful raids). 'Nemesis' generals have a higher chance to get better upgrades and higher levels.
6. A Hobgoblin general drops bonus rewards when defeated but can be allowed to escape by not attacking the goblin town with a vastly superior force, thereby allowing them to escape and become a "nemesis", who will return the next time a stronghold appears with a higher rarity item drop.

I have added new Protostar tests accordingly in:

tests/protostar/settling_game/goblintown/test_goblintown.cairo and \
tests/protostar/settling_game/combat/test_combat_2.cairo

---

# Contracts
| Directory | Title | Description                     |
| --------- | ----- | ------------------------------- |
| [/settling_game](./contracts/settling_game) | The Realms Settling Game | A modular game engine architecture built on StarkNet. |
| [/desiege](./contracts/desiege) | Desiege | A web-based team game built on Starknet. |
| [/loot](./contracts/loot/) | Loot | Loot contracts ported to Cairo. |
| [/exchange](./contracts/exchange/) | Exchange | Allows trades between pairs of ERC20 and ERC1155 contract tokens. |
| [/nft_marketplace](./contracts/nft_marketplace/) | NFT Marketplace | A marketplace for Realms, Dungeons, etc. built on Starknet. |

---
# Learn more about Realms

## Follow these steps bring a 🔦

## 1. Visit the [Bibliotheca DAO Site](https://bibliothecadao.xyz/) for an overview of our ecosystem

## 2. The [Master Scroll](https://scroll.bibliothecadao.xyz/). This is our deep dive into everything about the game. The Master Scroll is the source of truth before this readme

## 3. Visit [The Atlas](https://atlas.bibliothecadao.xyz/) to see the Settling game in action

## 4. Get involved at the [Realms x Bibliotheca Discord](https://discord.gg/uQnjZhZPfu)

---

# Development

https://development.bibliothecadao.xyz/docs/getting-started/environment

---
## Realms Repositories

The Realms Settling Game spans a number of repositories:

| Content         | Repository       | Description                                              |
| --------------- | ---------------- | -------------------------------------------------------- |
| **contracts**       | [realms-contracts](https://github.com/BibliothecaForAdventurers/realms-contracts) | StarkNet/Cairo and Ethereum/solidity contracts.          |
| **ui, atlas**       | [realms-react](https://github.com/BibliothecaForAdventurers/realms-react)     | All user-facing react code (website, Atlas, ui library). |
| **indexer**         | [starknet-indexer](https://github.com/BibliothecaForAdventurers/starknet-indexer) | A graphql endpoint for the Lootverse on StarkNet.        |
| **bot**             | [squire](https://github.com/BibliothecaForAdventurers/squire)           | A Twitter/Discord bot for the Lootverse.                 |
| **subgraph**        | [loot-subgraph](https://github.com/BibliothecaForAdventurers/loot-subgraph)    | A subgraph (TheGraph) for the Lootverse on Eth Mainnet.  |
