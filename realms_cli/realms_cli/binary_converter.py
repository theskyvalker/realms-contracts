import json

def decimalToBinary(n, chunksize):
    bit = []

    for x in n:
        num = bin(x).replace("0b", "")
        bit.append(num)

    reversed_bit = ""

    for i in reversed(bit):
        if len(i) < chunksize:
            difference = chunksize - len(i)
            reversed_bit += ("0" * difference) + i
        else:
            reversed_bit += i
    # print(reversed_bit)
    return int(reversed_bit, 2)


def createOutput(value, chunksize):
    # print(value)
    for index, x in enumerate(value):
        value[index]["costs_bitmap"] = decimalToBinary(x['costs'], chunksize)
        value[index]["ids_bitmap"] = decimalToBinary(x['ids'], chunksize)
    return value


# Maps the different attributes of a realm to a series of arra
def map_realm(value, resources, wonders, orders):
    traits = []
    resourceIds = []
    wonder = []
    order = []

    for a in value['attributes']:
        # traits
        if a['trait_type'] == "Cities":
            traits.append(a['value'])
        if a['trait_type'] == "Regions":
            traits.append(a['value'])
        if a['trait_type'] == "Rivers":
            traits.append(a['value'])
        if a['trait_type'] == "Harbors":
            traits.append(a['value'])

        # add resources
        if a['trait_type'] == "Resource":
            for b in resources:
                if b['trait'] == a['value']:
                    resourceIds.append(b['id'])

        # add wonders
        if a['trait_type'] == "Wonder (translated)":
            for index, w in enumerate(wonders):
                if w["trait"] == a['value']:
                    # adds index in arrary TODO: Hardcode Ids
                    wonder.append(index + 1)

        # add order
        if a['trait_type'] == "Order":
            for o in orders:
                if o["name"] in a['value']:
                    order.append(o["id"])

    # resource length to help with iteration in app
    resourceLength = [len(resourceIds)]

    # add extra 0 to fill up map if less than the max of 7 resources
    if len(resourceIds) < 7:
        for _ in range(7 - len(resourceIds)):
            resourceIds.append(0)

    # add extra 0 to fill wonder gap if none exist
    if len(wonder) < 1:
        wonder.append(0)

    # concat all together
    meta = traits + resourceLength + resourceIds + wonder + order
    return decimalToBinary(meta, 8)


# Maps the different attributes of a crypt to a series of arrays
def map_crypt(value, environments, affinities):
    size = []
    environment = []
    legendary = []
    numDoors = []
    numPoints = []
    structure = []
    affinity = [0]   # By default, most maps will not have an affinity

    # size is used to draw dungeosn and as a ratio for how many objects can be placed in a dungeon
    size.append(value["size"])

    # environment is used to determine the resource generated by a crypt
    environment_name = value["environment"]

    for e in environments:
        if e["name"] == environment_name:
            environment.append(e["id"])

    resourceIds = [23 + int(environment[0])]   # Crypts resources are 23->28. Environments start at id 0 in our json.
    
    # resource length to help with iteration in app
    resourceLength = [1]  # We only have 1 resource per dungeon


    # legendary is used as a multiplier for resource output
    legendary.append(value["legendary"])  # 1 is true, 0 is false

    # number of doors (which is flipped so we use number of points)
    numDoors.append(value["numPoints"])
    numPoints.append(value["numDoors"])

    # Is this a room-based dungeon (crypt) or a tunnel-based dungeon (cavern)?
    structure.append(value["structure"])

    # affinities are powerful societies that pre-date the Orders
    affinity_name = value["affinity"]
    for a in affinities:
        if a["name"] == affinity_name:
            affinity[0] = a["id"]

    # concat all together
    meta = resourceLength + resourceIds + environment + legendary + size + numDoors + numPoints + affinity

    return decimalToBinary(meta, 8)

if __name__ == '__main__':

    # f = open("data/realms_bit.json", "a")
    # output = []
    # for index in range(8000):
    #     output.append({str(index + 1): map_realm(realms[str(index + 1)])})

    # f.write(str(output))

    # # with open('scripts/json_data.json', 'w') as outfile:
    # #     outfile.write(str(createOutput(buildings, 6)))

    building_costs = [6, 6, 6, 6, 6, 6, 6, 6, 6]

    resource_ids = [1, 4, 6]
    resource_values = [10, 10, 10, 10, 10]

    buildings = [
        {
            "name": "Fairgrounds",
            "id": 1,
            "costs": [2, 12, 31, 21, 7],
            "ids":[2, 2, 3, 4, 7]
        }
    ]

    # Quickly test Realms metadata
    realms = json.load(open('data/realms.json'))
    resources = json.load(open('data/resources.json'))
    orders = json.load(open('data/orders.json'))
    wonders = json.load(open('data/wonders.json'))

    print(decimalToBinary(resource_ids, 8))
    print(decimalToBinary(resource_values, 12))

    print(map_realm(realms["1"], resources, wonders, orders))

    # Quickly test Crypts metadata
    crypts = json.load(open("data/crypts.json"))
    environments = json.load(open("data/crypts_environments.json"))
    affinities = json.load(open("data/crypts_affinities.json"))

    print(map_crypt(crypts["1"], environments, affinities))