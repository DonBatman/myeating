-- =================================================================
-- MYEATING: EATING ANIMATION & CRUMB PARTICLES
-- =================================================================

myeating = myeating or {}

-- Helper function to trigger eating visual effects
function myeating.animate_eating(user, itemstack)
    if not user or not user:is_player() then return end

    local p_pos = user:get_pos()
    local dir = user:get_look_dir()
    local name = user:get_player_name()

    -- 1. Eye Position for Crumbs (Just below eye height, 0.4 units in front)
    local mouth_pos = {
        x = p_pos.x + dir.x * 0.4,
        y = p_pos.y + 1.4 + dir.y * 0.2,
        z = p_pos.z + dir.z * 0.4
    }

    -- Determine item texture for matching crumb colors
    local item_name = itemstack:get_name()
    local item_def = core.registered_items[item_name]
    local texture = "default_wood.png^[colorize:#8b5a2b:220" -- Default brown crumb

    if item_def and item_def.inventory_image and item_def.inventory_image ~= "" then
        texture = item_def.inventory_image
    end

    -- 2. Spawn Crumb Explosion
    core.add_particlespawner({
        amount = 25,
        time = 1.0,
        minpos = {x = mouth_pos.x - 0.1, y = mouth_pos.y - 0.1, z = mouth_pos.z - 0.1},
        maxpos = {x = mouth_pos.x + 0.1, y = mouth_pos.y + 0.1, z = mouth_pos.z + 0.1},
        minvel = {x = -dir.z * 1.5 - 0.5, y = -0.5, z = dir.x * 1.5 - 0.5},
        maxvel = {x = dir.z * 1.5 + 0.5, y = 0.5, z = -dir.x * 1.5 + 0.5},
        minacc = {x = 0, y = -6, z = 0},
        maxacc = {x = 0, y = -9, z = 0},
        minexptime = 0.3,
        maxexptime = 0.7,
        minsize = 0.5,
        maxsize = 1.5,
        texture = texture,
        glow = 0,
    })

    -- 3. Chewing Sound Effects
    core.sound_play("default_dig_crumbly", {pos = p_pos, gain = 0.8, pitch = 1.2})

    core.after(0.3, function()
        if core.get_player_by_name(name) then
            core.sound_play("default_dig_crumbly", {pos = p_pos, gain = 0.8, pitch = 0.9})
        end
    end)

    core.after(0.6, function()
        if core.get_player_by_name(name) then
            core.sound_play("default_dig_crumbly", {pos = p_pos, gain = 0.8, pitch = 1.1})
        end
    end)

    -- 4. Hand Motion (Eye Micro-Bobbing)
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

-- 5. Reliable Item Override Hook
core.register_on_mods_loaded(function()
    for item_name, def in pairs(core.registered_items) do
        -- Catch any item with an on_use callback (food items use item_eat in on_use)
        if def.on_use then
            local old_on_use = def.on_use

            core.override_item(item_name, {
                on_use = function(itemstack, user, pointed_thing)
                    myeating.animate_eating(user, itemstack)
                    return old_on_use(itemstack, user, pointed_thing)
                end
            })
        end
    end
end)
