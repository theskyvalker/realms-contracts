// -----------------------------------
// GoblinTown Library
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from contracts.settling_game.utils.constants import SHIFT_8_9, MAX_GOBLIN_TOWN_STRENGTH, SHIFT_41, SHIFT_HOBGOBLIN_GENERAL
from contracts.settling_game.utils.game_structs import RealmData, ResourceIds, HobgoblinGeneral
from contracts.settling_game.utils.general import unpack_data
from contracts.settling_game.modules.combat.constants import GoblinHealthMods, MAX_HEALTH

namespace GoblinTown {
    func pack{range_check_ptr}(strength: felt, spawn_ts: felt) -> (packed: felt) {
        let packed = strength + spawn_ts * SHIFT_8_9;
        return (packed,);
    }

    func unpack{range_check_ptr}(packed: felt) -> (strength: felt, spawn_ts: felt) {
        let (spawn_ts, strength) = unsigned_div_rem(packed, SHIFT_8_9);
        return (strength, spawn_ts);
    }

    func new_pack{range_check_ptr}(strength: felt, spawn_ts: felt, loot: felt, general: felt) -> (packed: Uint256) {

        let strength_val = strength * SHIFT_41._1;
        let spawn_ts_val = spawn_ts * SHIFT_41._2;
        let loot_val = loot * SHIFT_41._3;
        
        let metadata = strength_val + spawn_ts_val + loot_val;

        let packed = Uint256(metadata, general);
        
        return (packed,);
    }

    func new_unpack{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*} (
        packed: Uint256) -> (strength: felt, spawn_ts: felt, loot: felt, general: felt) {

        alloc_locals;

        let (strength) = unpack_data(packed.low, 0, 2199023255551);
        let (spawn_ts) = unpack_data(packed.low, 41, 2199023255551);
        let (loot) = unpack_data(packed.low, 82, 2199023255551);
        let general = packed.high;
        
        return (strength, spawn_ts, loot, general);
    }

    // @notice Unpacks bitmapped HobgoblinGeneral struct
    // @param packed_general: current packed HobgoblinGeneral struct
    // @returns unpacked HobgoblinGeneral struct
    func unpack_general{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(packed_general: felt) -> (general: HobgoblinGeneral) {
        alloc_locals;

        let (light_cavalry_health) = unpack_data(packed_general, 0, 127);  // 7
        let (heavy_cavalry_health) = unpack_data(packed_general, 7, 127);  // 7
        let (archer_health) = unpack_data(packed_general, 14, 127);  // 7
        let (longbow_health) = unpack_data(packed_general, 21, 127);  // 7
        let (mage_health) = unpack_data(packed_general, 28, 127);  // 7
        let (arcanist_health) = unpack_data(packed_general, 35, 127);  // 7
        let (light_infantry_health) = unpack_data(packed_general, 42, 127);  // 7
        let (heavy_infantry_health) = unpack_data(packed_general, 49, 127);  // 7
        let (level) = unpack_data(packed_general, 56, 127);  // 7
        let (nemesis) = unpack_data(packed_general, 63, 127);  // 7

        return (
            HobgoblinGeneral(
                light_cavalry_health,
                heavy_cavalry_health,
                archer_health,
                longbow_health,
                mage_health,
                arcanist_health,
                light_infantry_health,
                heavy_infantry_health,
                level,
                nemesis
                ),
        );
    }

    // @notice Packs HobgoblinGeneral into single felt
    // @param general: current unpacked HobgoblinGeneral
    // @returns packed HobgoblinGeneral in the form of a felt
    func pack_general{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(general: HobgoblinGeneral) -> (packed_general: felt) {
        alloc_locals;

        let light_cavalry_health = general.LightCavalry * SHIFT_HOBGOBLIN_GENERAL._1;
        let heavy_cavalry_health = general.HeavyCavalry * SHIFT_HOBGOBLIN_GENERAL._2;
        let archer_health = general.Archer * SHIFT_HOBGOBLIN_GENERAL._3;
        let longbow_health = general.Longbow * SHIFT_HOBGOBLIN_GENERAL._4;
        let mage_health = general.Mage * SHIFT_HOBGOBLIN_GENERAL._5;
        let arcanist_health = general.Arcanist * SHIFT_HOBGOBLIN_GENERAL._6;
        let light_infantry_health = general.LightInfantry * SHIFT_HOBGOBLIN_GENERAL._7;
        let heavy_infantry_health = general.HeavyInfantry * SHIFT_HOBGOBLIN_GENERAL._8;
        let level = general.Level * SHIFT_HOBGOBLIN_GENERAL._9;
        let nemesis = general.Nemesis * SHIFT_HOBGOBLIN_GENERAL._10;

        let packed = nemesis + level + heavy_infantry_health + light_infantry_health + arcanist_health + mage_health + longbow_health + archer_health + heavy_cavalry_health + light_cavalry_health;
        return (packed,);
    }

    func build_or_upgrade_general{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}(
        general_in: felt, old_strength: felt, target_strength: felt, nemesis: felt) -> felt {
        if (general_in == 0) {
            return build_general(target_strength, 0, 0, nemesis); //TODO: send actual random values instead of 0s
        } else {
            return upgrade_general(general_in, old_strength, target_strength);
        }
    }

    func get_general_uplevel_threshold{}(nemesis: felt) -> felt {
        if (nemesis == TRUE) {
            return 60;
        } else {
            return 80;
        }
    }

    func build_general{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}(
        target_strength: felt, rnd_1: felt, rnd_2: felt, nemesis: felt) -> felt {
        // TODO: rnd_1 and rnd_2 should be randomly generated numbers between 1 to 100
        
        let uplevel_threshold = get_general_uplevel_threshold(nemesis);
        
        let (q, r) = unsigned_div_rem(rnd_1, uplevel_threshold);
        let level = q + target_strength;
        
        let (army_health_mod_multiplier, r) = unsigned_div_rem(rnd_2, 10);
        
        let general = HobgoblinGeneral(
            GoblinHealthMods.LIGHT_CAVALRY_UNITS * army_health_mod_multiplier,
            GoblinHealthMods.HEAVY_CAVALRY_UNITS * army_health_mod_multiplier,
            GoblinHealthMods.ARCHER_UNITS * army_health_mod_multiplier,
            GoblinHealthMods.LONGBOW_UNITS * army_health_mod_multiplier,
            GoblinHealthMods.MAGE_UNITS * army_health_mod_multiplier,
            GoblinHealthMods.ARCANIST_UNITS * army_health_mod_multiplier,
            GoblinHealthMods.LIGHT_INFANTRY_UNITS * army_health_mod_multiplier,
            GoblinHealthMods.HEAVY_INFANTRY_UNITS * army_health_mod_multiplier,
            level,
            nemesis
        );
        
        let (packed_general) = pack_general(general);
        
        return packed_general;
    }

    func upgrade_general{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}(
        general_in: felt, old_strength: felt, target_strength: felt) -> felt {

        alloc_locals;

        let (unpacked_general_in) = unpack_general(general_in);
        
        let new_level = unpacked_general_in.Level - old_strength + target_strength; // maintain any level offset the general has

        // local original_unpacked_general_in: HobgoblinGeneral = unpacked_general_in;

        let upgraded_light_cavalry_health_mod = check_limit_and_upgrade(unpacked_general_in.LightCavalry, GoblinHealthMods.LightCavalry);
        let upgraded_heavy_cavalry_health_mod = check_limit_and_upgrade(unpacked_general_in.HeavyCavalry, GoblinHealthMods.HeavyCavalry);
        let upgraded_archer_health_mod = check_limit_and_upgrade(unpacked_general_in.Archer, GoblinHealthMods.Archer);
        let upgraded_longbow_health_mod = check_limit_and_upgrade(unpacked_general_in.Longbow, GoblinHealthMods.Longbow);
        let upgraded_mage_health_mod = check_limit_and_upgrade(unpacked_general_in.Mage, GoblinHealthMods.Mage);
        let upgraded_arcanist_health_mod = check_limit_and_upgrade(unpacked_general_in.Arcanist, GoblinHealthMods.Arcanist);
        let upgraded_light_infantry_health_mod = check_limit_and_upgrade(unpacked_general_in.LightInfantry, GoblinHealthMods.LightInfantry);
        let upgraded_heavy_infantry_health_mod = check_limit_and_upgrade(unpacked_general_in.HeavyInfantry, GoblinHealthMods.HeavyInfantry);

        let general_out = HobgoblinGeneral(
            upgraded_light_cavalry_health_mod,
            upgraded_heavy_cavalry_health_mod,
            upgraded_archer_health_mod,
            upgraded_longbow_health_mod,
            upgraded_mage_health_mod,
            upgraded_arcanist_health_mod,
            upgraded_light_infantry_health_mod,
            upgraded_heavy_infantry_health_mod,
            new_level,
            unpacked_general_in.Nemesis,
        );

        let (packed_general_out) = pack_general(general_out);
        
        return packed_general_out;
    }

    func calculate_strength{range_check_ptr}(realm_data: RealmData, rnd: felt) -> (strength: felt) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        // find the most precious resource the Realm has
        let rd: felt* = &realm_data;
        let precious: felt = rd[RealmData.resource_number + realm_data.resource_number];

        // associate the resource with the "default goblin town strength"
        // based on Realm's resources
        let (strength) = get_squad_strength_of_resource(precious);

        // add a random element to the calculated strength
        let strength = strength + rnd;

        // cap it
        let is_within_bounds = is_le(strength, MAX_GOBLIN_TOWN_STRENGTH);
        if (is_within_bounds == TRUE) {
            return (strength,);
        }

        return (MAX_GOBLIN_TOWN_STRENGTH,);
    }

    func check_limit_and_upgrade{range_check_ptr}(input_health_mod: felt, max: felt) -> felt {
        if (is_le(input_health_mod + 5, max) == TRUE) {
            return input_health_mod + 5;
        } else {
            return max;
        }
    }

    func create_general_for_stronghold(strength: felt) -> (general: HobgoblinGeneral) {

    }

    func get_squad_strength_of_resource(resource: felt) -> (strength: felt) {
        // Wood, Stone, Coal -> 1
        // Copper, Obsidian, Silver -> 2
        // Ironwood, ColdIron, Gold -> 3
        // Hartwood, Diamonds, Sapphire -> 4
        // Ruby, DeepCrystal, Ignium -> 5
        // EtherealSilica, TrueIce -> 6
        // TwilightQuartz, AlchemicalSilver -> 7
        // Adamantine, Mithral -> 8
        // Dragonhide -> 9

        if (resource == ResourceIds.Wood) {
            return (1,);
        }
        if (resource == ResourceIds.Stone) {
            return (1,);
        }
        if (resource == ResourceIds.Coal) {
            return (1,);
        }

        if (resource == ResourceIds.Copper) {
            return (2,);
        }
        if (resource == ResourceIds.Obsidian) {
            return (2,);
        }
        if (resource == ResourceIds.Silver) {
            return (2,);
        }
        if (resource == ResourceIds.Ironwood) {
            return (3,);
        }
        if (resource == ResourceIds.ColdIron) {
            return (3,);
        }
        if (resource == ResourceIds.Gold) {
            return (3,);
        }
        if (resource == ResourceIds.Hartwood) {
            return (4,);
        }
        if (resource == ResourceIds.Diamonds) {
            return (4,);
        }
        if (resource == ResourceIds.Sapphire) {
            return (4,);
        }
        if (resource == ResourceIds.Ruby) {
            return (5,);
        }
        if (resource == ResourceIds.DeepCrystal) {
            return (5,);
        }
        if (resource == ResourceIds.Ignium) {
            return (5,);
        }
        if (resource == ResourceIds.EtherealSilica) {
            return (6,);
        }
        if (resource == ResourceIds.TrueIce) {
            return (6,);
        }
        if (resource == ResourceIds.TwilightQuartz) {
            return (7,);
        }
        if (resource == ResourceIds.AlchemicalSilver) {
            return (7,);
        }
        if (resource == ResourceIds.Adamantine) {
            return (8,);
        }
        if (resource == ResourceIds.Mithral) {
            return (8,);
        }
        if (resource == ResourceIds.Dragonhide) {
            return (9,);
        }

        return (1,);  // a fallback, just in case
    }
}
