// -----------------------------------
//   Module.GoblinTown
//   Logic of the Goblin Town, as far as one can claim goblins follow logic

// ELI5:
//   WIP: Upgrade to new Combat.
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc721.IERC721 import IERC721

from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.modules.combat.interface import IL06_Combat
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.modules.goblintown.library import GoblinTown
from contracts.settling_game.utils.constants import (
    GOBLIN_WELCOME_PARTY_STRENGTH,
    DAY,
    HOUR,
    VAULT_LENGTH,
    BASE_RESOURCES_PER_DAY,
    PILLAGE_AMOUNT,
    UPGRADE_REQUIREMENT_MULTIPLIER,
    SCOUTING,
    BASE_NEMESIS_CHANCE,
)
from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds, RealmData
from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.utils.game_structs import Army

// -----------------------------------
// Events
// -----------------------------------

@event
func GoblinSpawn(realm_id: Uint256, goblin_army: Army, time_stamp: felt) {
}

// -----------------------------------
// Storage
// -----------------------------------

// TODO: write docs

@storage_var
func xoroshiro_address() -> (address: felt) {
}

@storage_var
func goblin_town_data(realm_id: Uint256) -> (packed: Uint256) {
}

@storage_var
func nemesis_data(realm_id: Uint256) -> (nemesis: felt) {
}

// -----------------------------------
// INITIALIZER & UPGRADE
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address_of_controller: felt, proxy_admin: felt
) {
    Module.initializer(address_of_controller);
    Proxy.initializer(proxy_admin);
    return ();
}

// @notice Set new proxy implementation
// @dev Can only be set by the arbiter
// @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

// -----------------------------------
// EXTERNAL
// -----------------------------------

@external
func attack_realm{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}(
    realm_id: Uint256, goblin_town_data_input: Uint256, now: felt) -> (status: felt) {
    alloc_locals;

    // Module.only_approved();

    // let (now) = get_block_timestamp();

    let (strength, spawn_ts, loot, general) = GoblinTown.new_unpack(goblin_town_data_input);

    let time_to_attack = is_le(spawn_ts + (12 * HOUR), now);

    if (time_to_attack == TRUE) {

        // let (combat_address) = Module.get_module_address(ModuleIds.L06_Combat);
        // let (combat_outcome) = IL06_Combat.initiate_goblintown_raid(combat_address, 0, realm_id);
        return (TRUE,);

    } else {
        return (FALSE,);
    }

}

@external
func add_resources_to_goblintown{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}(
        realm_id: Uint256,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        goblin_town_data_input: Uint256
        ) {

    // goblin towns only track how much of the rarest resource tier they have
    // looted so far in terms of when they upgrade

    // TODO: translate looted resources to units of "loot" -> ready to upgrade
    // when units of loot == current strength * multiplier, loot resets to 0 after upgrading
    // for now, we just go by number of successful raids

    let (strength, spawn_ts, loot, general) = GoblinTown.new_unpack(goblin_town_data_input);

    let loot = loot + 1;

    let (new_packed_data) = GoblinTown.new_pack(strength, spawn_ts, loot, general);
    goblin_town_data.write(realm_id, new_packed_data);

    // TODO?: track other resources for reclaiming purposes when town is defeated
    // TODO Alternative: adjust the fact that we know the most valuable loot a goblin town
    // would have looted to be upgraded and use that to set the reward bounty (on top of the $LORDS)

    return ();
}

// TODO: add camps to goblintowns if they are strongholds
// TODO: update available rivers -> strongholds claim camps for themselves with successful raids

@external
func upgrade_to_stronghold{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}(
    realm_id: Uint256, goblin_town_data_input: Uint256, input_timestamp: felt) -> (status: felt) {

    alloc_locals;
    // Module.only_approved();

    let (strength, spawn_ts, loot, general) = GoblinTown.new_unpack(goblin_town_data_input);
    // replace with: let (strength, spawn_ts, loot) = get_goblintown_stats(realm_id); for stateful implementation

    if (strength * UPGRADE_REQUIREMENT_MULTIPLIER != loot) {
        return (FALSE,);
    }

    let live_mode = is_le(input_timestamp, 0);

    if (live_mode == TRUE) {
        let (now) = get_block_timestamp();
        let time_to_upgrade = is_le(spawn_ts + (48 * HOUR), now);
        tempvar syscall_ptr = syscall_ptr;
    } else {
        let time_to_upgrade = is_le(spawn_ts + (48 * HOUR), input_timestamp);
        tempvar syscall_ptr = syscall_ptr;
    }

    if (time_to_upgrade == TRUE) {
        // upgrade town strength and reset loot counter, store new data
        let new_strength = strength + 1;
        let new_loot = 0;
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;

        // TODO: check and fetch a nemesis general to make a return appearance if one exists
        let (general, nemesis) = check_nemesis(realm_id, general);

        // if general == 0, then a new general is built. Otherwise, the existing general is upgraded
        let new_general = GoblinTown.build_or_upgrade_general(general, strength, new_strength, nemesis);

        let (new_packed_data) = GoblinTown.new_pack(new_strength, spawn_ts, new_loot, new_general);
        goblin_town_data.write(realm_id, new_packed_data);

        return (TRUE,);
    } else {
        return (FALSE,);
    }
}

@external
func scout_goblin_town{range_check_ptr, syscall_ptr: felt*}(
    realm_id: Uint256, fee_provided: felt, rnd: felt
) -> (success: felt) {
    let (boost) = get_scouting_rate(fee_provided); // fee provided in $LORDS. TODO: implement burning $LORDS provided as scouting fees
    
    let success = is_le(100, rnd + boost + SCOUTING.BASE_SUCCESS_RATE); // rnd range between 1 to 100, inclusive
    
    return (success,);
}

@external
func spawn_next{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    realm_id: Uint256
) {
    alloc_locals;

    // TODO: turn on NOT working for some reason.
    // Module.only_approved()

    let (xoroshiro_addr) = xoroshiro_address.read();
    let (rnd) = IXoroshiro.next(xoroshiro_addr);

    // calculate the next spawn timestamp
    let (_, spawn_delay_hours) = unsigned_div_rem(rnd, 25);  // [0,24]
    let (now) = get_block_timestamp();

    // get DAY / 24
    let (day_cycle_hour, _) = unsigned_div_rem(DAY, 24);
    let next_spawn_ts = now + (DAY + spawn_delay_hours * day_cycle_hour);

    // calculate the strength
    // normal and staked Realms have the same ID, so the following will work
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms);
    let (realm_data: RealmData) = IRealms.fetch_realm_data(realms_address, realm_id);
    let (_, extras) = unsigned_div_rem(rnd, 5);  // [0,4]
    let (strength) = GoblinTown.calculate_strength(realm_data, extras);

    // pack & store the data
    let (packed) = GoblinTown.new_pack(strength, next_spawn_ts, 0, 0); // no general and no loot for a new goblintown
    goblin_town_data.write(realm_id, packed);

    // emit goblin spawn
    let (goblins: Army) = Combat.get_goblin_army(strength, 0);
    GoblinSpawn.emit(realm_id, goblins, next_spawn_ts);

    return ();
}

@external
func update_nemesis_status{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}(
    attacking_army_dominance: felt,
    realm_id: Uint256,
    rnd: felt
) {
    // let rnd be a random number between 1 to 100
    if (is_le(rnd, BASE_NEMESIS_CHANCE + attacking_army_dominance) == TRUE) {
        let (strength, ts, loot, general) = get_goblintown_stats(realm_id);
        let (unpacked_general) = GoblinTown.unpack_general(general);
        unpacked_general.Nemesis = TRUE;
        let (packed_general) = GoblinTown.pack_general(unpacked_general);
        nemesis_data.write(realm_id, packed_general);

        tempvar range_check_ptr;
        return ();
    } else {
        tempvar range_check_ptr;
        return ();
    }
}

// -----------------------------------
// INTERNAL
// -----------------------------------

func check_nemesis{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}(
realm_id: Uint256, general: felt) -> (general: felt, nemesis: felt) {
    if (general == 0) {
        let (nemesis_general) = nemesis_data.read(realm_id);
        return (nemesis_general, TRUE);
    } else {
        let (unpacked_general) = GoblinTown.unpack_general(general);
        return (general, unpacked_general.Nemesis);
    }
}

func get_scouting_rate(fee_provided: felt) -> (rate: felt) {
    if (fee_provided == SCOUTING.FEE_MAX) {
        return (SCOUTING.RATE_MAX,);
    }
    if (fee_provided == SCOUTING.FEE_MID) {
        return (SCOUTING.RATE_MID,);
    }
    if (fee_provided == SCOUTING.FEE_MIN) {
        return (SCOUTING.RATE_MIN,);
    }
    return (0,);
}

// -----------------------------------
// GETTERS
// -----------------------------------

@view
func get_goblintown_stats{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    realm_id: Uint256
) -> (strength: felt, timestamp: felt, loot: felt, general: felt) {
    let (packed) = goblin_town_data.read(realm_id);
    let (strength, ts, loot, general) = GoblinTown.new_unpack(packed);
    return (strength, ts, loot, general);
}

// -----------------------------------
// ADMIN
// -----------------------------------

@external
func set_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    xoroshiro: felt
) {
    Proxy.assert_only_admin();
    xoroshiro_address.write(xoroshiro);
    return ();
}
