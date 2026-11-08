-- =================================================================
-- MYEATING: EATING ANIMATIONS (FUN vs CRUMBS STYLE)
-- =================================================================

myeating = myeating or {}

-- Setting: "fun" (camera eye-bob + item crumb particles) or "crumbs" (bottom HUD item + custom crumbs)
myeating.style = minetest.settings:get("myeating_style") or "crumbs"

-- Helper to safely retrieve an item's inventory texture string
local function get_item_texture(itemstack)
    local item_name = itemstack:get_name()
    local item_def = core.registered_items[item_name]
    if item_def and item_def.inventory_image and item_def.inventory_image ~= "" then
        return item_def.inventory_image
    end
    if item_def and item_def.wield_image and item_def.wield_image ~= "" then
        return item_def.wield_image
    end
    return "default_wood.png^[colorize:#8b5a2b:220"
end

-- Core animation dispatcher
function myeating.animate_eating(user, itemstack)
    if not user or not user:is_player() then return end

    local p_pos = user:get_pos()
    local dir = user:get_look_dir()
    local name = user:get_player_name()

    -- Common Chewing Sound Rhythm
    core.sound_play("default_dig_crumbly", {pos = p_pos, gain = 0.8, pitch = 1.2})
    core.after(0.25, function()
        if core.get_player_by_name(name) then
            core.sound_play("default_dig_crumbly", {pos = p_pos, gain = 0.8, pitch = 0.9})
        end
    end)
    core.after(0.5, function()
        if core.get_player_by_name(name) then
            core.sound_play("default_dig_crumbly", {pos = p_pos, gain = 0.8, pitch = 1.1})
        end
    end)

-- Helper to safely retrieve an item's 2D texture string for HUD display
local function get_item_hud_texture(itemstack)
    local item_name = itemstack:get_name()
    local item_def = core.registered_items[item_name]

    if item_def then
        if item_def.inventory_image and item_def.inventory_image ~= "" then
            return item_def.inventory_image
        elseif item_def.wield_image and item_def.wield_image ~= "" then
            return item_def.wield_image
        elseif item_def.tiles and item_def.tiles[1] then
            -- Fallback for node-based food items
            local tile = item_def.tiles[1]
            if type(tile) == "table" then tile = tile.name end
            return tile
        end
    end
    -- Fallback default texture if none is found
    return "default_apple.png"
end

-- Helper to safely retrieve an item's 2D texture string for HUD display
local function get_item_hud_texture(itemstack)
    local item_name = itemstack:get_name()
    local item_def = core.registered_items[item_name]

    if item_def then
        if item_def.inventory_image and item_def.inventory_image ~= "" then
            return item_def.inventory_image
        elseif item_def.wield_image and item_def.wield_image ~= "" then
            return item_def.wield_image
        elseif item_def.tiles and item_def.tiles[1] then
            -- Fallback for node-based food items
            local tile = item_def.tiles[1]
            if type(tile) == "table" then tile = tile.name end
            return tile
        end
    end
    -- Fallback default texture if none is found
    return "default_apple.png"
end

-- Inside myeating.animate_eating():
if myeating.style == "crumbs" then
    local texture = get_item_hud_texture(itemstack)

    -- Add HUD element centered at bottom of screen
    local hud_id = user:hud_add({
        hud_elem_type = "image",
        position      = {x = 0.5, y = 1.1},        -- Bottom Center
        alignment     = {x = 0, y = -1},           -- Anchored at bottom
        offset        = {x = 0, y = -50},          -- Placed slightly above hotbar
        text          = texture,
        scale         = {x = -20, y = -40},          -- Negative values force 4x pixel scaling
    })

    -- Verification check: If HUD failed to create, return early
    if not hud_id then return end

    -- Bob the HUD food item slightly up & down during chewing
    local bobs = {
        { time = 0.15, offset = {x = 0, y = -80} },
        { time = 0.35, offset = {x = 0, y = -55} },
        { time = 0.55, offset = {x = 0, y = -75} },
        { time = 0.75, offset = {x = 0, y = -50} },
    }

    for _, step in ipairs(bobs) do
        core.after(step.time, function()
            local player = core.get_player_by_name(name)
            if player and hud_id then
                player:hud_change(hud_id, "offset", step.offset)
            end
        end)
    end

    -- Remove HUD image when done chewing
    core.after(0.85, function()
        local player = core.get_player_by_name(name)
        if player and hud_id then
            player:hud_remove(hud_id)
        end
    end)

    -- Spawn custom crumb particles (myeating_crumbs.png) at 1/3 size
    local mouth_pos = {
        x = p_pos.x + dir.x * 0.4,
        y = p_pos.y + 1.3 + dir.y * 0.2,
        z = p_pos.z + dir.z * 0.4
    }

    core.add_particlespawner({
        amount = 35,
        time = 0.7,
        minpos = {x = mouth_pos.x - 0.1, y = mouth_pos.y - 0.1, z = mouth_pos.z - 0.1},
        maxpos = {x = mouth_pos.x + 0.1, y = mouth_pos.y + 0.1, z = mouth_pos.z + 0.1},
        minvel = {x = -dir.z * 2.0 - 0.8, y = -0.2, z = dir.x * 2.0 - 0.8},
        maxvel = {x = dir.z * 2.0 + 0.8, y = 0.8, z = -dir.x * 2.0 + 0.8},
        minacc = {x = 0, y = -7, z = 0},
        maxacc = {x = 0, y = -10, z = 0},
        minexptime = 0.3,
        maxexptime = 0.6,
        minsize = 0.25,
        maxsize = 0.6,
        texture = "myeating_crumbs.png",
        glow = 0,
    })


    -----------------------------------------------------------------
    -- STYLE 2: FUN (Classic Camera Bob + Dynamic Item Texture Crumbs)
    -----------------------------------------------------------------
    else
        local mouth_pos = {
            x = p_pos.x + dir.x * 0.4,
            y = p_pos.y + 1.4 + dir.y * 0.2,
            z = p_pos.z + dir.z * 0.4
        }
        local texture = get_item_texture(itemstack)

        core.add_particlespawner({
            amount = 25,
            time = 0.8,
            minpos = {x = mouth_pos.x - 0.1, y = mouth_pos.y - 0.1, z = mouth_pos.z - 0.1},
            maxpos = {x = mouth_pos.x + 0.1, y = mouth_pos.y + 0.1, z = mouth_pos.z + 0.1},
            minvel = {x = -dir.z * 1.5 - 0.5, y = -0.5, z = dir.x * 1.5 - 0.5},
            maxvel = {x = dir.z * 1.5 + 0.5, y = 0.5, z = -dir.x * 1.5 + 0.5},
            minacc = {x = 0, y = -6, z = 0},
            maxacc = {x = 0, y = -9, z = 0},
            minexptime = 0.3,
            maxexptime = 0.6,
            minsize = 0.5,
            maxsize = 1.5,
            texture = texture,
            glow = 0,
        })

        local bobs = {
            { time = 0.05, offset = {x = 0, y = -0.15, z = 0} },
            { time = 0.20, offset = {x = 0, y = 0.10, z = 0} },
            { time = 0.35, offset = {x = 0, y = -0.12, z = 0} },
            { time = 0.50, offset = {x = 0, y = 0.08, z = 0} },
            { time = 0.65, offset = {x = 0, y = 0.00, z = 0} },
        }

        for _, step in ipairs(bobs) do
            core.after(step.time, function()
                local player = core.get_player_by_name(name)
                if player then
                    player:set_eye_offset(step.offset, {x = 0, y = 0, z = 0})
                end
            end)
        end
    end
end

-- Override core item_eat API
local old_item_eat = core.item_eat
core.item_eat = function(hp_change, replace_with_item)
    local original_eat_func = old_item_eat(hp_change, replace_with_item)

    return function(itemstack, user, pointed_thing)
        if user and user:is_player() then
            myeating.animate_eating(user, itemstack)
        end
        return original_eat_func(itemstack, user, pointed_thing)
    end
end

minetest.item_eat = core.item_eat
