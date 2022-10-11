%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.modules.combat.constants import BattalionStatistics, BattalionIds, GoblinHealth, GoblinHealthMods

from contracts.settling_game.utils.game_structs import Army, Battalion, ArmyStatistics, HobgoblinGeneral
from contracts.settling_game.modules.goblintown.library import GoblinTown

func build_attacking_army() -> (a: Army) {
    tempvar values = new (2, 100, 2, 100, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,);
    let a = cast(values, Army*);
    return ([a],);
}

func build_defending_army() -> (a: Army) {
    tempvar values = new (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,);
    // tempvar values = new (1, 100, 1, 100, 10, 100, 2, 100, 2, 100, 2, 100, 2, 100, 1, 100,)
    let a = cast(values, Army*);
    return ([a],);
}

// @external
// func test_squad{
//     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
// }():
//     alloc_locals

// let (attacking_army) = build_attacking_army()
//     let (packed_army) = Combat.pack_army(attacking_army)
//     let (unpacked_army : Army) = Combat.unpack_army(packed_army)

// assert unpacked_army.LightCavalry.Quantity = 2
//     assert unpacked_army.LightCavalry.Health = 100
//     assert unpacked_army.HeavyInfantry.Quantity = 0
//     assert unpacked_army.HeavyInfantry.Health = 0

// return ()
// end

// @external
// func test_statistics{
//     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
// }():
//     alloc_locals

// let (attacking_army) = build_attacking_army()
//     let (packed_army) = Combat.pack_army(attacking_army)
//     let (unpacked_army : ArmyStatistics) = Combat.calculate_army_statistics(packed_army)

// return ()
// end

@external
func test_winner{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (attacking_army) = build_attacking_army();
    let (attacking_army_packed) = Combat.pack_army(attacking_army);

    let (defending_army) = build_defending_army();
    let (defending_army_packed) = Combat.pack_army(defending_army);

    let luck = 100;

    let (
        outcome, updated_attack_army_packed, updated_defence_army_packed
    ) = Combat.calculate_winner(luck, attacking_army_packed, defending_army_packed);

    assert outcome = 1;

    return ();
}

@external
func test_build_goblin_army{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let (goblin_army: Army) = Combat.build_goblin_army(1);

    let army_composition_valid = check_battalion_composition(goblin_army, 0,0,0,0,0,0,1,0);
    assert army_composition_valid = TRUE;
    
    let (goblin_army: Army) = Combat.build_goblin_army(2);

    let army_composition_valid = check_battalion_composition(goblin_army, 0,0,0,0,0,0,2,0);
    assert army_composition_valid = TRUE;
    
    let (goblin_army) = Combat.build_goblin_army(3);

    let army_composition_valid = check_battalion_composition(goblin_army, 0,0,1,0,0,0,2,1);
    assert army_composition_valid = TRUE;
    
    let (goblin_army) = Combat.build_goblin_army(6);

    let army_composition_valid = check_battalion_composition(goblin_army, 0,1,1,1,1,0,4,2);
    assert army_composition_valid = TRUE;
    
    let (goblin_army) = Combat.build_goblin_army(10);

    let army_composition_valid = check_battalion_composition(goblin_army, 1,1,2,1,1,0,7,3);
    assert army_composition_valid = TRUE;

    let (goblin_army) = Combat.build_goblin_army(12);

    let army_composition_valid = check_battalion_composition(goblin_army, 1,2,2,2,2,0,8,4);
    assert army_composition_valid = TRUE;

    // make sure that the check function is working as expected and not passing everything through
    let army_composition_valid = check_battalion_composition(goblin_army, 1,2,2,2,2,4,8,0);
    assert army_composition_valid = FALSE;

    return ();

}

@external
func test_build_goblin_army_with_general{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (unpacked_general) = generate_general_with_max_army_health_mods(1, FALSE);
    let (general) = GoblinTown.pack_general(unpacked_general);

    let (goblin_army: Army) = Combat.build_goblin_army_with_general(1, general);

    let army_composition_valid = check_battalion_composition(goblin_army, 0,0,0,0,0,0,1,0);
    assert army_composition_valid = TRUE;
    let army_health_valid = check_battalion_healths(goblin_army, unpacked_general);
    assert army_health_valid = TRUE;
    
    let (goblin_army: Army) = Combat.build_goblin_army_with_general(2, general);

    let army_composition_valid = check_battalion_composition(goblin_army, 0,0,0,0,0,0,2,0);
    assert army_composition_valid = TRUE;
    let army_health_valid = check_battalion_healths(goblin_army, unpacked_general);
    assert army_health_valid = TRUE;
    
    let (goblin_army) = Combat.build_goblin_army_with_general(3, general);

    let army_composition_valid = check_battalion_composition(goblin_army, 0,0,1,0,0,0,2,1);
    assert army_composition_valid = TRUE;
    let army_health_valid = check_battalion_healths(goblin_army, unpacked_general);
    assert army_health_valid = TRUE;

    let (unpacked_general) = generate_general_with_max_army_health_mods(4, TRUE);
    let (general) = GoblinTown.pack_general(unpacked_general);

    let (goblin_army) = Combat.build_goblin_army_with_general(3, general);

    let army_composition_valid = check_battalion_composition(goblin_army, 0,0,1,0,0,0,4,1);
    assert army_composition_valid = TRUE;
    let army_health_valid = check_battalion_healths(goblin_army, unpacked_general);
    assert army_health_valid = TRUE;

    let (unpacked_general) = generate_general_with_max_army_health_mods(6, TRUE);
    let (general) = GoblinTown.pack_general(unpacked_general);
    
    let (goblin_army) = Combat.build_goblin_army_with_general(6, general);

    let army_composition_valid = check_battalion_composition(goblin_army, 1,1,2,1,1,0,6,2);
    assert army_composition_valid = TRUE;
    let army_health_valid = check_battalion_healths(goblin_army, unpacked_general);
    assert army_health_valid = TRUE;

    let (unpacked_general) = generate_general_with_max_army_health_mods(8, TRUE);
    let (general) = GoblinTown.pack_general(unpacked_general);

    let (goblin_army) = Combat.build_goblin_army_with_general(6, general);

    let army_composition_valid = check_battalion_composition(goblin_army, 3,1,4,1,1,0,8,2);
    assert army_composition_valid = TRUE;
    let army_health_valid = check_battalion_healths(goblin_army, unpacked_general);
    assert army_health_valid = TRUE;

    let (unpacked_general) = generate_general_with_max_army_health_mods(12, FALSE);
    let (general) = GoblinTown.pack_general(unpacked_general);

    let (goblin_army) = Combat.build_goblin_army_with_general(12, general);

    let army_composition_valid = check_battalion_composition(goblin_army, 3,2,4,2,2,0,12,4);
    assert army_composition_valid = TRUE;
    let army_health_valid = check_battalion_healths(goblin_army, unpacked_general);
    assert army_health_valid = TRUE;

    return ();

}

// @external
// func test_calculate_total_battalions{
//     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
// }():
//     alloc_locals

// let (attacking_army) = build_attacking_army()
//     let (packed_army) = Combat.pack_army(attacking_army)
//     let (unpacked_army) = Combat.unpack_army(packed_army)
//     let (total_battalions) = Combat.calculate_total_battalions(attacking_army)

// assert total_battalions = 12

// let c_defence = unpacked_army.LightCavalry.Quantity * BattalionStatistics.Defence.Cavalry.LightCavalry + unpacked_army.HeavyCavalry.Quantity * BattalionStatistics.Defence.Cavalry.HeavyCavalry + unpacked_army.Archer.Quantity * BattalionStatistics.Defence.Cavalry.Archer + unpacked_army.Longbow.Quantity * BattalionStatistics.Defence.Cavalry.Longbow + unpacked_army.Mage.Quantity * BattalionStatistics.Defence.Cavalry.Mage + unpacked_army.Arcanist.Quantity * BattalionStatistics.Defence.Cavalry.Arcanist + unpacked_army.LightInfantry.Quantity * BattalionStatistics.Defence.Cavalry.LightInfantry + unpacked_army.HeavyInfantry.Quantity * BattalionStatistics.Defence.Cavalry.HeavyInfantry

// let (cavalry_defence) = Combat.calculate_defence_values(
//         c_defence,
//         total_battalions,
//         unpacked_army.LightCavalry.Quantity + unpacked_army.HeavyCavalry.Quantity,
//     )

// assert cavalry_defence = c_defence

// return ()
// end

// @external
// func test_health_remaining{
//     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
// }():
//     alloc_locals

// let (attacking_army) = build_attacking_army()
//     let (packed_army) = Combat.pack_army(attacking_army)
//     let (unpacked_army) = Combat.unpack_army(packed_army)

// let (total_health, total_battalions) = Combat.calculate_health_remaining(100, 2, 3, 100, 100)

// %{ print('total_health:', ids.total_health) %}
//     %{ print('total_battalions:', ids.total_battalions) %}
//     return ()
// end

// @external
// func test_add_battalions_to_army{
//     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
// }():
//     alloc_locals

// let (attacking_army) = build_attacking_army()
//     let (packed_army) = Combat.pack_army(attacking_army)
//     let (unpacked_army) = Combat.unpack_army(packed_army)

// let (battalion_ids : felt*) = alloc()
//     assert battalion_ids[0] = BattalionIds.LightCavalry
//     assert battalion_ids[1] = BattalionIds.HeavyCavalry

// let (battalions : felt*) = alloc()
//     assert battalions[0] = 3
//     assert battalions[1] = 3

// let (total_battalions : Army) = Combat.add_battalions_to_army(
//         unpacked_army, 2, battalion_ids, 2, battalions
//     )

// assert total_battalions.LightCavalry.Quantity = battalions[0]

// return ()
// end

func check_battalion_composition{}(
    probe_army: Army,
    light_cavalry_qty: felt,
    heavy_cavalry_qty: felt,
    archer_qty: felt,
    longbow_qty: felt,
    mage_qty: felt,
    arcanist_qty: felt,
    light_infantry_qty: felt,
    heavy_infantry_qty: felt,
) -> felt {

    if (probe_army.LightCavalry.Quantity != light_cavalry_qty) {
        return FALSE;
    }
    if (probe_army.HeavyCavalry.Quantity != heavy_cavalry_qty) {
        return FALSE;
    }
    if (probe_army.Archer.Quantity != archer_qty) {
        return FALSE;
    }
    if (probe_army.Longbow.Quantity != longbow_qty) {
        return FALSE;
    }
    if (probe_army.Mage.Quantity != mage_qty) {
        return FALSE;
    }
    if (probe_army.Arcanist.Quantity != arcanist_qty) {
        return FALSE;
    }
    if (probe_army.LightInfantry.Quantity != light_infantry_qty) {
        return FALSE;
    }
    if (probe_army.HeavyInfantry.Quantity != heavy_infantry_qty) {
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

func check_battalion_healths{}(
    probe_army: Army,
    general: HobgoblinGeneral
) -> felt {

    if (probe_army.LightCavalry.Health != GoblinHealth.LightCavalry + general.LightCavalry) {
        return FALSE;
    }
    if (probe_army.HeavyCavalry.Health != GoblinHealth.HeavyCavalry + general.HeavyCavalry) {
        return FALSE;
    }
    if (probe_army.Archer.Health != GoblinHealth.Archer + general.Archer) {
        return FALSE;
    }
    if (probe_army.Longbow.Health != GoblinHealth.Longbow + general.Longbow) {
        return FALSE;
    }
    if (probe_army.Mage.Health != GoblinHealth.Mage + general.Mage) {
        return FALSE;
    }
    if (probe_army.Arcanist.Health != GoblinHealth.Arcanist + general.Arcanist) {
        return FALSE;
    }
    if (probe_army.LightInfantry.Health != GoblinHealth.LightInfantry + general.LightInfantry) {
        return FALSE;
    }
    if (probe_army.HeavyInfantry.Health != GoblinHealth.HeavyInfantry + general.HeavyInfantry) {
        return FALSE;
    }

    return TRUE;
}
