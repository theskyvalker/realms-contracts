%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from contracts.settling_game.utils.constants import MAX_GOBLIN_TOWN_STRENGTH, SCOUTING
from contracts.settling_game.utils.game_structs import RealmData, ResourceIds, HobgoblinGeneral
from contracts.settling_game.modules.goblintown.library import GoblinTown
from contracts.settling_game.modules.goblintown.GoblinTown import attack_realm, upgrade_to_stronghold, scout_goblin_town
from contracts.settling_game.modules.combat.constants import GoblinHealthMods

@external
func test_pack_unpack{range_check_ptr}() {
    alloc_locals;

    let strength = 15;
    let spawn_ts = 1700000000;
    let (packed) = GoblinTown.pack(strength, spawn_ts);
    assert packed = 31359464925306237747200000015;

    let (unpacked_strength, unpacked_spawn_ts) = GoblinTown.unpack(packed);
    assert unpacked_strength = strength;
    assert unpacked_spawn_ts = spawn_ts;

    return ();
}

@external
func test_new_pack_unpack{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;

    let strength = 15;
    let spawn_ts = 1700000000;
    let loot = 100;
    let (general) = generate_general_with_max_army_health_mods(4, TRUE);
    let (packed_general) = GoblinTown.pack_general(general);
    
    let (packed) = GoblinTown.new_pack(strength, spawn_ts, loot, packed_general);

    let (unpacked_strength, unpacked_spawn_ts, unpacked_loot, unpacked_general) = GoblinTown.new_unpack(packed);
    assert unpacked_strength = strength;
    assert unpacked_spawn_ts = spawn_ts;
    assert unpacked_loot = loot;
    assert unpacked_general = packed_general;

    return ();
}

@external
func test_calculate_strength{range_check_ptr}() {
    alloc_locals;

    let realm_data = RealmData(
        regions=4,
        cities=12,
        harbours=2,
        rivers=7,
        resource_number=3,
        resource_1=ResourceIds.Stone,
        resource_2=ResourceIds.Ironwood,
        resource_3=ResourceIds.Ruby,
        resource_4=0,
        resource_5=0,
        resource_6=0,
        resource_7=0,
        wonder=0,
        order=1,
    );

    let (strength) = GoblinTown.calculate_strength(realm_data, 0);
    assert strength = 5;

    let (strength) = GoblinTown.calculate_strength(realm_data, 3);
    assert strength = 8;

    let (strength) = GoblinTown.calculate_strength(realm_data, 20);
    assert strength = MAX_GOBLIN_TOWN_STRENGTH;

    return ();
}

@external
func test_get_squad_strength_of_resource{range_check_ptr}() {
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Wood);
    assert e = 1;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Stone);
    assert e = 1;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Coal);
    assert e = 1;

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Copper);
    assert e = 2;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Obsidian);
    assert e = 2;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Silver);
    assert e = 2;

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Ironwood);
    assert e = 3;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.ColdIron);
    assert e = 3;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Gold);
    assert e = 3;

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Hartwood);
    assert e = 4;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Diamonds);
    assert e = 4;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Sapphire);
    assert e = 4;

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Ruby);
    assert e = 5;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.DeepCrystal);
    assert e = 5;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Ignium);
    assert e = 5;

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.EtherealSilica);
    assert e = 6;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.TrueIce);
    assert e = 6;

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.TwilightQuartz);
    assert e = 7;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.AlchemicalSilver);
    assert e = 7;

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Adamantine);
    assert e = 8;
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Mithral);
    assert e = 8;

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Dragonhide);
    assert e = 9;

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.fish);
    assert e = 1;

    return ();
}

@external
func test_attack_realm{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;

    let strength = 15;
    let spawn_ts = 1700000000;
    let realm_id = Uint256(1, 0);
    let (packed) = GoblinTown.new_pack(strength, spawn_ts,0,0);

    let (test_attack_1) = attack_realm(realm_id, packed, spawn_ts + 4 * 3600);
    assert test_attack_1 = FALSE;
    let (test_attack_2) = attack_realm(realm_id, packed, spawn_ts + 12 * 3600 + 1);
    assert test_attack_2 = TRUE;

    return ();
}

@external
func test_upgrade_to_stronghold{syscall_ptr: felt*, range_check_ptr,  pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;

    let strength = 12;
    let spawn_ts = 1700000000;
    let loot = 12;
    let general = 0;

    let (packed) = GoblinTown.new_pack(strength, spawn_ts, loot, general);

    let realm_id = Uint256(1, 0);

    let (test_upgrade_1) = upgrade_to_stronghold(realm_id, packed, spawn_ts + 40 * 3600);
    assert test_upgrade_1 = FALSE;
    let (test_upgrade_2) = upgrade_to_stronghold(realm_id, packed, spawn_ts + 48 * 3600 + 1);
    assert test_upgrade_2 = TRUE;
    let (test_upgrade_3) = upgrade_to_stronghold(realm_id, packed, -1);
    assert test_upgrade_3 = FALSE;

    return ();
}

@external
func test_scout_goblin_town{range_check_ptr, syscall_ptr: felt*}() {
    alloc_locals;

    let realm_id = Uint256(1, 0);
    
    let (success) = scout_goblin_town(realm_id, SCOUTING.FEE_MIN, 0);
    assert success = FALSE;

    let (success) = scout_goblin_town(realm_id, 0, 64);
    assert success = FALSE;

    let (success) = scout_goblin_town(realm_id, SCOUTING.FEE_MIN, 44);
    assert success = FALSE;

    let (success) = scout_goblin_town(realm_id, SCOUTING.FEE_MIN, 45);
    assert success = TRUE;

    let (success) = scout_goblin_town(realm_id, SCOUTING.FEE_MAX, 4);
    assert success = FALSE;

    let (success) = scout_goblin_town(realm_id, SCOUTING.FEE_MAX, 5);
    assert success = TRUE;

    return ();

}

@external
func test_pack_unpack_general{
    range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;

    let (to_be_packed) = generate_general_with_max_army_health_mods(4, TRUE);
    local original: HobgoblinGeneral = to_be_packed;

    let (packed_general) = GoblinTown.pack_general(to_be_packed);
    let (unpacked_general) = GoblinTown.unpack_general(packed_general);

    assert unpacked_general.LightCavalry = to_be_packed.LightCavalry;
    assert unpacked_general.HeavyCavalry = to_be_packed.HeavyCavalry;
    assert unpacked_general.Archer = to_be_packed.Archer;
    assert unpacked_general.Longbow = to_be_packed.Longbow;
    assert unpacked_general.Mage = to_be_packed.Mage;
    assert unpacked_general.Arcanist = to_be_packed.Arcanist;
    assert unpacked_general.LightInfantry = to_be_packed.LightInfantry;
    assert unpacked_general.HeavyInfantry = to_be_packed.HeavyInfantry;
    assert unpacked_general.Level = to_be_packed.Level;
    assert unpacked_general.Nemesis = to_be_packed.Nemesis;

    return ();
}

@external
func test_build_general{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}() {

    alloc_locals;

    let general = GoblinTown.build_general(3, 79, 0, FALSE);
    local original = general;

    let (unpacked_general) = GoblinTown.unpack_general(general);
    
    assert unpacked_general.Level = 3;
    assert unpacked_general.Nemesis = FALSE;
    let valid_army_health_mods = validate_army_health_mods(general, 0, 0, 0, 0, 0, 0, 0, 0);
    assert valid_army_health_mods = TRUE;

    let general = GoblinTown.build_general(3, 60, 50, TRUE);
    local original = general;
    
    let (unpacked_general) = GoblinTown.unpack_general(general);
    assert unpacked_general.Level = 4;
    assert unpacked_general.Nemesis = TRUE;
    let valid_army_health_mods = validate_army_health_mods(general, 25, 20, 20, 15, 30, 30, 10, 5);
    assert valid_army_health_mods = TRUE;

    return ();
}

@external
func test_upgrade_general{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}() {

    alloc_locals;

    let old_general = HobgoblinGeneral(
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1,
        FALSE,
    );

    let (old_general_packed) = GoblinTown.pack_general(old_general);

    let general = GoblinTown.upgrade_general(old_general_packed, 1, 2);
    local original = general;

    let (unpacked_general) = GoblinTown.unpack_general(general);
    
    assert unpacked_general.Level = 2;
    assert unpacked_general.Nemesis = FALSE;
    let valid_army_health_mods = validate_army_health_mods(general, 5, 5, 5, 5, 5, 5, 5, 5);
    assert valid_army_health_mods = TRUE;

    let old_general = HobgoblinGeneral(
        50,
        40,
        20,
        20,
        20,
        20,
        15,
        0,
        10,
        TRUE,
    );

    let (old_general_packed) = GoblinTown.pack_general(old_general);

    let general = GoblinTown.upgrade_general(old_general_packed, 8, 9);
    local original = general;
    
    let (unpacked_general) = GoblinTown.unpack_general(general);
    assert unpacked_general.Level = 11;
    assert unpacked_general.Nemesis = TRUE;
    let valid_army_health_mods = validate_army_health_mods(general, 50, 40, 25, 25, 25, 25, 20, 5);
    assert valid_army_health_mods = TRUE;

    return ();
}

func validate_army_health_mods{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*}(
    packed_general: felt,
    light_cavalry_health_mod: felt,
    heavy_cavalry_health_mod: felt,
    archer_health_mod: felt,
    longbow_health_mod: felt,
    mage_health_mod: felt,
    arcanist_health_mod: felt,
    light_infantry_health_mod: felt,
    heavy_infantry_health_mod: felt
) -> felt {

    let (unpacked_general) = GoblinTown.unpack_general(packed_general);

    if (unpacked_general.LightCavalry != light_cavalry_health_mod) {
        return FALSE;
    }
    if (unpacked_general.HeavyCavalry != heavy_cavalry_health_mod) {
        return FALSE;
    }
    if (unpacked_general.Archer != archer_health_mod) {
        return FALSE;
    }
    if (unpacked_general.Longbow != longbow_health_mod) {
        return FALSE;
    }
    if (unpacked_general.Mage != mage_health_mod) {
        return FALSE;
    }
    if (unpacked_general.Arcanist != arcanist_health_mod) {
        return FALSE;
    }
    if (unpacked_general.LightInfantry != light_infantry_health_mod) {
        return FALSE;
    }
    if (unpacked_general.HeavyInfantry != heavy_infantry_health_mod) {
        return FALSE;
    }
    return TRUE;
}

func generate_general_with_max_army_health_mods{}(level: felt, nemesis: felt) -> (general: HobgoblinGeneral) {

    let light_cavalry_health = GoblinHealthMods.LightCavalry;
    let heavy_cavalry_health = GoblinHealthMods.HeavyCavalry;
    let archer_health = GoblinHealthMods.Archer;
    let longbow_health = GoblinHealthMods.Longbow;
    let mage_health = GoblinHealthMods.Mage;
    let arcanist_health = GoblinHealthMods.Arcanist;
    let light_infantry_health = GoblinHealthMods.LightInfantry;
    let heavy_infantry_health = GoblinHealthMods.HeavyInfantry;

    let to_be_packed = HobgoblinGeneral(
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
    );
    
    return (to_be_packed,);
}
