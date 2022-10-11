// Module Interfaces
// MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IGoblinTown {
    func spawn_goblin_welcomparty(realm_id: Uint256) {
    }

    func get_goblintown_stats(realm_id: Uint256) -> (
        strength: felt, spawn_ts: felt, loot: felt, general: felt) {
    }
    
    func attack_realm(goblin_town_data_input: felt, now: felt) {
    }

    func upgrade_to_stronghold(goblin_town_data_input: felt, now: felt) {
    }

    func spawn_next(realm_id: Uint256) {
    }

    func add_resources_to_goblintown(
        realm_id: Uint256,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        ) {
    }

    func update_nemesis_status(
        attack_army_dominance: felt,
        realm_id: Uint256,
        rnd: felt,
        ) {
    }

}
