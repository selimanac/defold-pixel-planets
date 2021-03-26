local config = {}

config.mouse_click = hash("touch")
config.seed = 0

config.rseed = 0
config.rpixel = 100
config.rrot = 0
config.rlight = {x = 0, y = 0}

config.msg = {
    load_planet = hash("load_planet"),
    set_planet_light = hash("set_planet_light"),
    set_planet_seed = hash("set_planet_seed"),
    set_planet_pixel = hash("set_planet_pixel"),
    set_planet_rotation = hash("set_planet_rotation")
}

config.main_url = msg.url()
config.target_script = hash("/scripts")
config.current_planet = 1

config.planets = {
    [1] = {
        name = "TERRAN WET",
        nodes = {}
    },
     [2] = {
        name = "TERRAN DRY",
        nodes = {}
    },
    [3] = {
        name = "ISLAND",
        nodes = {}
    },
    [4] = {
        name = "NO ATMOSPHERE",
        nodes = {}
    },
    [5] = {
        name = "GAS GIANT 1",
        nodes = {}
    },
    [6] = {
        name = "GAS GIANT 2",
        nodes = {}
    },
    [7] = {
        name = "ICE WORLD",
        nodes = {}
    },
    [8] = {
        name = "LAVA WORLD",
        nodes = {}
    },
    [9] = {
        name = "ASTEROID",
        nodes = {}
    },

    [10] = {
        name = "STAR",
        nodes = {}
    }
}

function config.set_seed(s)
    config.seed = s
    config.rseed = s % 1000 / 100.0
end
function config.set_light(_x, _y)
    config.rlight.x = (_x / 360)
    config.rlight.y = 1.0 - (_y / 360)
end

config.round = function(n)
    return n >= 0.0 and n - n % -1 or n - n % 1
end


return config
