-- Key Authentication System
local CurrentKey = MachoAuthenticationKey()  -- Replace this with the manually entered key

local validKeys = {
    "MACHO-FIVEM-SBQTQ-FIOUN",  -- Replace with actual keys
    "MACHO-FIVEM-CMWCY-IDJAB",
    "MACHO-FIVEM-TTWSJ-FBDNQ",
    "MACHO-FIVEM-NLXPP-OIANY",
    "4918682930182583707",
    "Key",
    "Key",
    "Key",
    "Key",
    "Key",
    "Key",
    "Key",
    "Key",
    "Key",
    "Key",
    "Key",
    "Key",
    "Key",
}

local KeyPresent = false
for _, key in ipairs(validKeys) do
    if key == CurrentKey then
        KeyPresent = true
        break
    end
end

if KeyPresent then
    print("Key is authenticated [" .. CurrentKey .. "]")
else
    print("Key is not in the list [" .. CurrentKey .. "]")
    return -- Exit script if authentication fails
end

local MENU_SIZE = vec2(769, 575)
local MENU_START_COORDS = vec2(300, 300)
local TABS_BAR_WIDTH = 170
local SECTION_CHILD_WIDTH = MENU_SIZE.x - TABS_BAR_WIDTH
local SECTIONS_COUNT = 2
local SECTIONS_PADDING = 10
local MACHO_PANE_GAP = 10
local EACH_SECTION_WIDTH = (SECTION_CHILD_WIDTH - (SECTIONS_PADDING * (SECTIONS_COUNT + 1))) / SECTIONS_COUNT
local SECTION_ONE_START = vec2(TABS_BAR_WIDTH + (SECTIONS_PADDING * 1), SECTIONS_PADDING + MACHO_PANE_GAP)
local SECTION_ONE_END = vec2(SECTION_ONE_START.x + EACH_SECTION_WIDTH, MENU_SIZE.y - SECTIONS_PADDING)
local SECTION_TWO_START = vec2(TABS_BAR_WIDTH + (SECTIONS_PADDING * 2) + EACH_SECTION_WIDTH, SECTIONS_PADDING + MACHO_PANE_GAP)
local SECTION_TWO_END = vec2(SECTION_TWO_START.x + EACH_SECTION_WIDTH, MENU_SIZE.y - SECTIONS_PADDING)
local TABBED_WINDOW = MachoMenuTabbedWindow("Extorted.lua", MENU_START_COORDS.x, MENU_START_COORDS.y, MENU_SIZE.x, MENU_SIZE.y, TABS_BAR_WIDTH)

MachoMenuSetAccent(TABBED_WINDOW, 0, 125, 255)
MachoMenuSmallText(TABBED_WINDOW, "Drowzy V2.3")

local PLAYER_TAB = MachoMenuAddTab(TABBED_WINDOW, "Self")
local PLAYER_TAB_GROUP_ONE = MachoMenuGroup(PLAYER_TAB, "General", SECTION_ONE_START.x, SECTION_ONE_START.y, SECTION_ONE_END.x, SECTION_ONE_END.y)
local PLAYER_TAB_GROUP_TWO = MachoMenuGroup(PLAYER_TAB, "Value", SECTION_TWO_START.x, SECTION_TWO_START.y, SECTION_TWO_END.x, SECTION_TWO_END.y)

MachoMenuSetKeybind(TABBED_WINDOW, 0x14)

local fiveguardResource = nil
local found = false
local isSpectating = false  -- Flag to check if we are in spectator mode
local spectatorPed = nil    -- Store the currently spectated ped
local markerCoords = nil  -- Store the marker coordinates globally
local markerVisible = false  -- Toggle visibility of the marker
local selected_ent = 0
local res_width, res_height = GetActiveScreenResolution()
local cam_active = false
local cam = nil
local features = { "Attach Trashtruck","Select", "Shoot","Make Player Fall", "Teleport","Worm Hole","Spectate TESTING","Door Unlocker", "Delete Entity", "Spawn Ped (Angry)","Clone Vehicle", "Map Destroyer","Spawn Spikestrip","Remote Ped", "Kick From Vehicle", "NPC Vehicle Takover", "Vehicle Yoinker", "Shoot Vehicle", }
local current_feature = 1
local teleportMarkerCoords = nil -- Store teleport marker coordinates
local mapDestroyerEntity = nil -- Store the entity ID of the map destroyer
local fuse_toggles = {
    remote_ped = {
        enabled = false,
        ped = nil,
        godmode = false,
        no_ragdoll = false,
        noclip = false,
        vehicle = {
            godmode = false,
            acc_disp = "1.0",
            acc_val = 1.0,
            dec_disp = "1.0",
            dec_val = 1.0,
        }
    }
}

-- Features
function GetEmptySeat(vehicle)
    local seats = {
        -1, -- Driver seat
        0,  -- Front passenger seat
        1,  -- Back left seat
        2,  -- Back right seat
    }

    for _, seat in ipairs(seats) do
        if IsVehicleSeatFree(vehicle, seat) then
            return seat
        end
    end

    return -1  -- No free seats found
end

function draw_rect_px(x, y, w, h, r, g, b, a)
    DrawRect((x + w / 2) / res_width, (y + h / 2) / res_height, w / res_width, h / res_height, r, g, b, a)
end

function RotationToDirection(rot)
    local radiansZ = math.rad(rot.z)
    local radiansX = math.rad(rot.x)
    local cosX = math.cos(radiansX)
    local direction = vector3(-math.sin(radiansZ) * cosX, math.cos(radiansZ) * cosX, math.sin(radiansX))
    return direction
end

function toggle_camera()
    cam_active = not cam_active
    if cam_active then
        local gameplay_cam_coords = GetGameplayCamCoord()
        local gameplay_cam_rot = GetGameplayCamRot()
        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", gameplay_cam_coords.x, gameplay_cam_coords.y, gameplay_cam_coords.z, gameplay_cam_rot.x, gameplay_cam_rot.y, gameplay_cam_rot.z, 70.0)
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 200, false, false)
    else
        SetCamActive(cam, false)
        RenderScriptCams(false, true, 0, false, false)
        DestroyCam(cam)
        cam = nil
        SetFocusEntity(PlayerPedId())
    end
end

Citizen.CreateThread(function()
    while true do
        if IsControlJustPressed(0, 74) then -- H key to toggle camera
            toggle_camera()
        end

        if cam_active then
            local coords = GetCamCoord(cam)
            local rot = GetCamRot(cam)
            local direction = RotationToDirection(rot)

            local horizontal_move = GetControlNormal(0, 1) * 4
            local vertical_move = GetControlNormal(0, 2) * 4

            if horizontal_move ~= 0.0 or vertical_move ~= 0.0 then
                SetCamRot(cam, rot.x - vertical_move, rot.y, rot.z - horizontal_move)
            end

            local shift = IsDisabledControlPressed(0, 21)
            local new_pos = vector3(0.0, 0.0, 0.0)

            if IsDisabledControlPressed(0, 32) then  -- Move forward with W
                new_pos = coords + direction * (shift and 4.0 or 1.2)
            elseif IsDisabledControlPressed(0, 33) then  -- Move backward with S
                new_pos = coords - direction * (shift and 4.0 or 1.2)
            elseif IsDisabledControlPressed(0, 34) then  -- Move left with A
                new_pos = coords + vector3(-direction.y, direction.x, 0.0) * (shift and 4.0 or 1.2)
            elseif IsDisabledControlPressed(0, 35) then  -- Move right with D
                new_pos = coords + vector3(direction.y, -direction.x, 0.0) * (shift and 4.0 or 1.2)
            end

            if new_pos ~= vector3(0.0, 0.0, 0.0) then
                SetCamCoord(cam, new_pos.x, new_pos.y, new_pos.z)
            end

            TaskStandStill(PlayerPedId(), 10)
            SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)

            local raycast = StartExpensiveSynchronousShapeTestLosProbe(coords.x, coords.y, coords.z, coords.x + direction.x * 500.0, coords.y + direction.y * 500.0, coords.z + direction.z * 500.0, -1)
            local _, hit, end_coords, _, entity_hit = GetShapeTestResult(raycast)

            -- Switch features using mouse scroll wheel
if IsControlJustPressed(0, 242) then  -- Scroll up
    current_feature = (current_feature % #features) + 1
elseif IsControlJustPressed(0, 241) then  -- Scroll down
    current_feature = (current_feature - 2) % #features + 1
end

-- Ensure current_feature is within valid range
current_feature = math.max(1, math.min(current_feature, #features))

-- Display features on screen
local feature_y_positions = {0.73, 0.75, 0.77}  -- Adjust these values to position the features vertically at the bottom center
local feature_indices = {
    (current_feature - 2) % #features + 1,  -- Previous feature
    current_feature,                       -- Current feature
    (current_feature % #features) + 1      -- Next feature
}

-- Draw text with dashes on both sides of the center feature
local function DrawSideDashes(x, y)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.3)  -- Adjust text size as needed
    SetTextColour(255, 0, 0, 255)  -- Text color (Red)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()

    -- Draw left dash
    SetTextEntry("STRING")
    AddTextComponentString(">>                                         <<")
    DrawText(x - 0.06, y)  -- Adjust x offset for positioning
end

for i, feature_index in ipairs(feature_indices) do
    local r, g, b, a = 255, 255, 255, 255  -- Default text color (white)
    
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.3)  -- Adjust text size as needed
    SetTextColour(255, 0, 0, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(features[feature_index])
    DrawText(0.5, feature_y_positions[i])
    
    if i == 2 then  -- Current feature
        DrawSideDashes(0.5, feature_y_positions[i])
    end
end




if features[current_feature] == "Attach Trashtruck" then
    if entity_hit ~= 0 then
        -- Check if the entity is a player (not a vehicle)
        if IsPedAPlayer(entity_hit) then
            local ent_coords = GetEntityCoords(entity_hit)
            
            -- Draw marker exactly where the player is
            DrawMarker(2, ent_coords.x, ent_coords.y, ent_coords.z + 1.0, 0.0, 0.0, 0.0, 
                0.0, 180.0, 0.0, 1.5, 1.5, 1.5, 255, 128, 0, 50, false, true, 2, nil, nil, false)
        end
    end

    if IsDisabledControlJustPressed(0, 24) then  -- Left Mouse Click
        Citizen.CreateThread(function()
            if not cam_active then return end  -- Ensure Freecam is active

            local camCoords = GetCamCoord(cam)  -- Get Freecam position
            local nearestPlayer = nil
            local nearestDistance = 999999.0
            local nearestCoords = nil  -- Store the coordinates of the nearest player

            -- Loop through players to find the nearest one to Freecam
            for _, player in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(player)
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(camCoords - targetCoords)

                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayer = targetPed
                    nearestCoords = targetCoords  -- Save the exact coords where the marker is
                end
            end

            -- Attach the trash model at the exact marker position
            if nearestPlayer and nearestCoords then
                local trashModel = GetHashKey("prop_bin_08a")  -- Change to appropriate trash model

                RequestModel(trashModel)
                while not HasModelLoaded(trashModel) do
                    Wait(0)
                end

                local object = CreateObject(trashModel, nearestCoords.x, nearestCoords.y, nearestCoords.z + 1.0, 
                    true, true, false)  -- Spawn object at marker position

                -- Attach to player exactly where marker was drawn
                AttachEntityToEntity(object, nearestPlayer, 0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 
                    false, false, false, true, 2, true)

                SetEntityAsMissionEntity(object, true, true)
                SetModelAsNoLongerNeeded(trashModel)
            end
        end)
    end
end





            if features[current_feature] == "Select" then
                if hit then
                    if entity_hit ~= 0 then
                        local ent_coords = GetEntityCoords(entity_hit)
                        DrawMarker(2, ent_coords.x, ent_coords.y, ent_coords.z + 2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 2.0, 2.0, 2.0, 255, 128, 0, 50, false, true, 2, nil, nil, false)

                        if IsDisabledControlJustPressed(0, 24) then
                            selected_ent = entity_hit
                        end

                        if IsDisabledControlJustPressed(0, 29) then
                            -- Additional actions for selecting entities can be added here
                        end
                    end

                    if DoesEntityExist(selected_ent) then
                        draw_rect_px(res_width / 2 - 3, (res_height / 2) - 3, 8, 8, 255, 115, 0, 255)

                        local _new_pos = coords + direction * 500.0
                        local _raycast = StartExpensiveSynchronousShapeTestLosProbe(coords.x, coords.y, coords.z, _new_pos.x, _new_pos.y, _new_pos.z, -1, selected_ent)
                        local _, _, _end_coords = GetShapeTestResult(_raycast)

                        if #(coords - _end_coords) > 30.0 then
                            local cord = coords + direction * 30.0
                            SetEntityCoordsNoOffset(selected_ent, cord.x, cord.y, cord.z)
                        else
                            SetEntityCoords(selected_ent, _end_coords.x, _end_coords.y, _end_coords.z)
                        end
                    end

                    draw_rect_px((res_width / 2) - 5, res_height / 2, 11, 1, 255, 255, 255, 255)
                    draw_rect_px(res_width / 2, (res_height / 2) - 5, 1, 11, 255, 255, 255, 255)
                end

                if IsDisabledControlJustReleased(0, 24) then
                    selected_ent = 0
                end

            elseif features[current_feature] == "Shoot" then
            ShowHudComponentThisFrame(14)
    local weaponHash = GetHashKey("WEAPON_APPISTOL")
    RequestWeaponAsset(weaponHash, 31, 0)
    while not HasWeaponAssetLoaded(weaponHash) do
        Wait(0)
    end
    
    if IsDisabledControlPressed(0, 24) then  -- Left mouse button to shoot
        local playerPed = PlayerPedId()
        
        -- Continuously shoot bullets
        Citizen.CreateThread(function()
            while IsDisabledControlPressed(0, 24) do
                local x, y, z = table.unpack(coords + direction * 5.0)
                    ShootSingleBulletBetweenCoords(coords.x, coords.y, coords.z, x, y, z, 1000, true, weaponHash, PlayerPedId(), true, false, -1.0)
                Wait(50)  -- Adjust the delay as needed for the rate of fire
            end
        end)
    end


-- Helper function to get the direction of the gameplay camera
function GetGameplayCamDir()
    local rot = GetGameplayCamRot(2)
    local pitch = math.rad(rot.x)
    local yaw = math.rad(rot.z)
    local cosPitch = math.cos(pitch)
    return vector3(-math.sin(yaw) * cosPitch, math.cos(yaw) * cosPitch, math.sin(pitch))
end






            elseif features[current_feature] == "Teleport" then
                draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 0, 255, 0, 255)  -- Visual indicator for teleport

                -- Store teleport marker coordinates if it's visible
                if hit then
                    teleportMarkerCoords = end_coords
                end

                -- Perform teleportation if teleport marker coordinates are set
                if teleportMarkerCoords ~= nil and IsDisabledControlJustPressed(0, 24) then
                    -- Check if the hit entity is a vehicle and teleport player to the nearest available seat
                    if entity_hit ~= 0 and IsEntityAVehicle(entity_hit) then
                        local vehicle = entity_hit
                        local playerPed = PlayerPedId()
                        local seat = GetEmptySeat(vehicle)

                        if seat == -1 then
                            TaskWarpPedIntoVehicle(playerPed, vehicle, -1) -- Driver's seat
                        elseif seat >= 0 then
                            TaskWarpPedIntoVehicle(playerPed, vehicle, seat)
                        else
                            -- No available seats, notify player or handle accordingly
                            print("No available seats in the vehicle.")
                        end
                    else
                        SetEntityCoords(PlayerPedId(), teleportMarkerCoords.x, teleportMarkerCoords.y, teleportMarkerCoords.z, false, false, false, false)
                    end

                    teleportMarkerCoords = nil  -- Clear marker coordinates after teleportation
                end

            elseif features[current_feature] == "Delete Entity" then
                draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 255, 0, 0, 255)  -- Visual indicator for deletion

                if IsDisabledControlJustPressed(0, 24) and hit and entity_hit ~= 0 then
                    if selected_ent ~= 0 and DoesEntityExist(selected_ent) then
                        local ent_coords = GetEntityCoords(selected_ent)  -- Get entity coordinates
                        DeleteEntity(selected_ent)
                        selected_ent = 0
                    elseif mapDestroyerEntity ~= nil and DoesEntityExist(mapDestroyerEntity) then
                        local ent_coords = GetEntityCoords(mapDestroyerEntity)  -- Get map destroyer entity coordinates
                        DeleteEntity(mapDestroyerEntity)
                        mapDestroyerEntity = nil
                    elseif DoesEntityExist(entity_hit) then
                        local ent_coords = GetEntityCoords(entity_hit)  -- Get hit entity coordinates
                        DeleteEntity(entity_hit)
                    end
                end



                

        

        elseif features[current_feature] == "Worm Hole" then
    draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 255, 0, 0, 255)  -- Visual indicator for clicking

    -- Update marker coordinates if the crosshair is pointing at something
    if hit then
        coordsMarker = end_coords
    end

    -- Toggle marker visibility with left mouse button
    if IsDisabledControlJustPressed(0, 24) then
        if markerVisible then
            markerVisible = false
            markerCoords = nil  -- Clear marker coordinates
        else
            markerCoords = coordsMarker  -- Store the marker coordinates
            markerVisible = true
        end
    end

    -- Draw the sphere marker and apply attraction force if it is visible
    if markerVisible and markerCoords ~= nil then
        -- Offset the marker's Y-coordinate
        local offsetY = 3.0  -- Adjust this value as needed
        local offsetMarkerCoords = vector3(markerCoords.x, markerCoords.y, markerCoords.z + offsetY)

        -- Draw the black sphere marker
        DrawMarker(28, offsetMarkerCoords.x, offsetMarkerCoords.y, offsetMarkerCoords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 0, 0, 0, 255, false, true, 2, false, nil, nil, false)

        -- Function to apply force to attract entities
        local function ApplyAttractionForce(markerPos, radius, force)
            local playerPed = PlayerPedId()
            local peds = GetGamePool('CPed')  -- Get all peds in the game
            local vehicles = GetGamePool('CVehicle')  -- Get all vehicles in the game

            local function normalize(vec)
                local length = #(vec)  -- Calculate vector length
                if length == 0 then return vector3(0, 0, 0) end
                return vec / length  -- Normalize the vector
            end

            -- Apply attraction force to vehicles
            for _, vehicle in ipairs(vehicles) do
                if DoesEntityExist(vehicle) and vehicle ~= GetVehiclePedIsIn(playerPed, false) then
                    local vehicleCoords = GetEntityCoords(vehicle)
                    local distance = #(vehicleCoords - markerPos)
                    if distance < radius then
                        local direction = markerPos - vehicleCoords
                        direction = normalize(direction)  -- Normalize direction vector
                        ApplyForceToEntity(vehicle, 1, direction * force, 0, 0, true, false, true, true, true, true)
                        SetEntityInvincible(vehicle, true)  -- Set vehicle to invincible
                    end
                end
            end

            -- Apply attraction force to peds
            for _, ped in ipairs(peds) do
                if DoesEntityExist(ped) and ped ~= playerPed then
                    local pedCoords = GetEntityCoords(ped)
                    local distance = #(pedCoords - markerPos)
                    if distance < radius then
                        local direction = markerPos - pedCoords
                        direction = normalize(direction)  -- Normalize direction vector
                        ApplyForceToEntity(ped, 1, direction * force, 0, 0, true, false, true, true, true, true)
                        SetPedToRagdoll(ped, 4000, 5000, 0, true, true, true)  -- Set ped to ragdoll
                        FreezeEntityPosition(ped, false)  -- Unfreeze ped position
                    end
                end
            end
        end

        -- Apply the attraction force
        ApplyAttractionForce(offsetMarkerCoords, 50.0, 5000.0)  -- Set radius and force as needed
    end








     


    






                
        







    

    



            elseif features[current_feature] == "Spawn Ped (Angry)" then
    draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 0, 0, 255, 255)  -- Visual indicator for spawning angry ped

    if IsDisabledControlJustPressed(0, 24) then  -- Left mouse button to spawn angry ped
        local pedModel = GetHashKey("a_m_m_skidrow_01")
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Wait(0)
        end

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local _, pedCoords = GetNthClosestVehicleNode(playerCoords.x, playerCoords.y, playerCoords.z, 1, 1, 0, 0)
        local ped = CreatePed(26, pedModel, pedCoords, 0.0, true, false)
        SetPedAsEnemy(ped, true)
        SetPedShootRate(ped, 1000)
        SetEntityHealth(ped, 200)
        SetPedArmour(ped, 100)
        SetModelAsNoLongerNeeded(pedModel)

        -- Find the nearest player ped to the spawned ped excluding the player who spawned it
        local nearestPlayerPed = nil
        local nearestDistance = 999999.0

        for _, playerId in ipairs(GetActivePlayers()) do
            local targetPed = GetPlayerPed(playerId)
            if targetPed ~= playerPed then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(pedCoords - targetCoords)
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayerPed = targetPed
                end
            end
        

        if nearestPlayerPed then
            TaskCombatPed(ped, nearestPlayerPed, 0, 16)
        end

        -- Move the spawned ped to the draw location if hit
        if hit then
            SetEntityCoords(ped, end_coords.x, end_coords.y, end_coords.z, false, false, false, false)
        end
    end
end

elseif features[current_feature] == "Clone Vehicle" then
    draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 0, 255, 0, 255)  -- Visual indicator for cloning vehicle

    if IsDisabledControlJustPressed(0, 24) then  -- Left mouse button to clone vehicle
        local vehiclePos = GetEntityCoords(entity_hit)
                local vehicleHeading = GetEntityHeading(entity_hit)
                local vehicleModel = GetEntityModel(entity_hit)
                
                -- Request and load the vehicle model
                RequestModel(vehicleModel)
                while not HasModelLoaded(vehicleModel) do
                    Wait(100)
                end
                
                -- Create a new vehicle (clone) at the same position and heading
                local clonedVehicle = CreateVehicle(vehicleModel, vehiclePos, vehicleHeading, true, true)
                
                -- Ensure the cloned vehicle is fully spawned
                Wait(0)
                
                -- Set the cloned vehicle as a mission entity
                SetEntityAsMissionEntity(clonedVehicle, true, true)
end


            elseif features[current_feature] == "Map Destroyer" then
                draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 255, 0, 255, 255)  -- Visual indicator for map destroyer

                if IsDisabledControlJustPressed(0, 24) then  -- Left mouse button to trigger map destroyer
                    local mapEntity = "hei_id2_lod_slod4"
                    local entityCoords = GetEntityCoords(PlayerPedId())
                    local mapModel = GetHashKey(mapEntity)

                    RequestModel(mapModel)
                    while not HasModelLoaded(mapModel) do
                        Wait(0)
                    end

                    local map = CreateObject(mapModel, entityCoords, true, false, true)
                    SetEntityAsMissionEntity(map, true, true)
                    SetEntityCollision(map, false, false)
                    SetEntityVisible(map, true)  -- Ensure map is completely visible

                    -- Move the map destroyer entity to the draw location
                    if hit then
                        SetEntityCoords(map, end_coords.x, end_coords.y, end_coords.z, false, false, false, false)
                    end

                    mapDestroyerEntity = map
                end





elseif features[current_feature] == "Door Unlocker" then
    draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 0, 255, 0, 255)  -- Visual indicator for door unlocker

    if IsDisabledControlJustPressed(0, 24) then  -- Left mouse button to unlock door
        if entity_hit and GetEntityType(entity_hit) == 3 then  -- Assuming doors are considered objects
            local isFrozen = IsEntityPositionFrozen(entity_hit)

            -- Toggle the lock state
            if isFrozen then  -- If the door is locked (position frozen)
                FreezeEntityPosition(entity_hit, false)  -- Unlock the door
            else
                FreezeEntityPosition(entity_hit, true)  -- Lock the door
            end
        end
    end








elseif features[current_feature] == "Spawn Spikestrip" then
    draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 255, 0, 255, 255)  -- Visual indicator for spikestrip

    if IsDisabledControlJustPressed(0, 24) then  -- Left mouse button to spawn spikestrip
        local mapEntity = "p_ld_stinger_s"
        local entityCoords = GetEntityCoords(PlayerPedId())
        local mapModel = GetHashKey(mapEntity)

        RequestModel(mapModel)
        while not HasModelLoaded(mapModel) do
            Wait(0)
        end

        local spikestrip = CreateObject(mapModel, entityCoords, true, false, true)
        SetEntityAsMissionEntity(spikestrip, true, true)
        SetEntityCollision(spikestrip, true, true)
        SetEntityVisible(spikestrip, true)  -- Ensure spikestrip is completely visible

        -- Move the spikestrip entity to the draw location
        if hit then
            SetEntityCoords(spikestrip, end_coords.x, end_coords.y, end_coords.z, false, false, false, false)
        end

        spikestripEntity = spikestrip

        -- Monitor vehicles running over the spikestrip
        Citizen.CreateThread(function()
            while DoesEntityExist(spikestripEntity) do
                local vehicles = GetVehiclesInRange(GetEntityCoords(spikestripEntity), 5.0)  -- Adjust the range as needed
                for _, vehicle in ipairs(vehicles) do
                    for i = 0, 7 do  -- Loop through all tires
                        if not IsVehicleTyreBurst(vehicle, i, false) then
                            SetVehicleTyreBurst(vehicle, i, true, 1000.0)  -- Burst the tire
                        end
                    end
                end
                Wait(100)  -- Check every 100 milliseconds
            end
        end)
    end


function GetVehiclesInRange(coords, range)
    local vehicles = {}
    for vehicle in EnumerateVehicles() do
        if #(coords - GetEntityCoords(vehicle)) <= range then
            table.insert(vehicles, vehicle)
        end
    end
    return vehicles
end

function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, vehicle = FindFirstVehicle()
        if not handle or handle == -1 then
            EndFindVehicle(handle)
            return
        end

        local success
        repeat
            coroutine.yield(vehicle)
            success, vehicle = FindNextVehicle(handle)
        until not success

        EndFindVehicle(handle)
    end)
end


elseif features[current_feature] == "Remote Ped" then
                draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 255, 0, 255, 255)  -- Visual indicator for map destroyer

                if IsDisabledControlJustPressed(0, 24) then
SetCamActive(cam, false)
        RenderScriptCams(false, true, 500, false, false)
        DestroyCam(cam)
        cam = nil
        SetFocusEntity(PlayerPedId())
         Citizen.CreateThread(function()
                    Wait(0)  -- Short delay to ensure the focus is set
                    SetControlNormal(0, 74, 1.0)  -- Simulate pressing "H"
end)

local function rotation_to_direction(rotation)
    local adjusted_rotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    local direction = vector3(
        -math.sin(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)),
        math.cos(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)),
        math.sin(adjusted_rotation.x)
    )
    return direction
end

local function get_control(entity)
    local player = PlayerId()
    NetworkRequestControlOfEntity(entity)
    local tries = 0
    while not NetworkHasControlOfEntity(entity) and tries < 10 do
        Citizen.Wait(10)
        NetworkRequestControlOfEntity(entity)
        tries = tries + 1
    end
end

local function remote_ped()
    local ped = fuse_toggles.remote_ped.ped

    SetCanAttackFriendly(ped, true, false)
    SetFocusEntity(ped)
    SetEntityAsMissionEntity(ped)
    SetPedAlertness(ped, 0.0)

    ClearPedTasksImmediately(ped)
    ClearPedSecondaryTask(ped)
    SetPedKeepTask(ped, false)

    while fuse_toggles.remote_ped.enabled do
        local p_dist = 999.0
        if IsControlJustPressed(0, 38) then -- H key
            local original_ped = fuse_toggles.remote_ped.ped
            local found_ped = false
            for _, v in pairs(GetGamePool("CPed")) do
                local ped_coords = GetEntityCoords(v)
                local onscreen, os_x, os_y = GetScreenCoordFromWorldCoord(ped_coords.x, ped_coords.y, ped_coords.z)
                local dist = math.abs((0.5 - os_x) + (0.5 - os_y))
                if #(ped_coords - GetEntityCoords(ped)) < 200.0 and onscreen and not IsPedAPlayer(v) and v ~= ped and HasEntityClearLosToEntity(ped, v, 1) and IsEntityVisible(v) and IsPedHuman(v) and GetEntityHealth(v) > 0 and p_dist > dist then
                    p_dist = dist
                    fuse_toggles.remote_ped.ped = v
                    found_ped = true
                end
            end
            if not found_ped then
                -- Create a new ped if none found
                local player_ped = PlayerPedId()
                local model_hash = GetHashKey("mp_m_freemode_01")
                RequestModel(model_hash)
                while not HasModelLoaded(model_hash) do
                    Citizen.Wait(0)
                end
                fuse_toggles.remote_ped.ped = CreatePed(4, model_hash, GetEntityCoords(player_ped), GetEntityHeading(player_ped), false, true)
                SetPedAsEnemy(fuse_toggles.remote_ped.ped, true)
                SetPedCanBeTargetted(fuse_toggles.remote_ped.ped, true)
                SetPedCanRagdoll(fuse_toggles.remote_ped.ped, true)
                SetPedCanBeKnockedOffVehicle(fuse_toggles.remote_ped.ped, true)
                SetEntityHealth(fuse_toggles.remote_ped.ped, 200)
                SetPedArmour(fuse_toggles.remote_ped.ped, 100)
                TaskCombatPed(fuse_toggles.remote_ped.ped, player_ped, 0, 16)
            elseif fuse_toggles.remote_ped.ped ~= original_ped then
                Citizen.CreateThread(remote_ped)
                return
            end
        end

        if not DoesEntityExist(ped) then
            fuse_toggles.remote_ped.enabled = false
            break
        end

        get_control(ped)
        local vehicle = GetVehiclePedIsUsing(ped)

        SetGameplayCamFollowPedThisUpdate(ped)
        SetPedInfiniteAmmo(ped, true, GetSelectedPedWeapon(ped))
        SetPedInfiniteAmmoClip(ped, true)
        TaskStandStill(PlayerPedId(), 10)
        SetEntityInvincible(ped, fuse_toggles.remote_ped.godmode)
        SetEntityCanBeDamaged(ped, not fuse_toggles.remote_ped.godmode)

        local coords = GetEntityCoords(ped)
        local _coords = coords
        local sprint, aiming, aim_coords

        if IsDisabledControlPressed(0, 21) then
            sprint = true
        end

        if IsDisabledControlPressed(0, 25) then
            aiming = true
            aim_coords = GetEntityCoords(GetCurrentPedWeaponEntityIndex(ped)) + (rotation_to_direction(GetGameplayCamRot(2)) * 20.0)
            if IsDisabledControlPressed(0, 24) and IsPedWeaponReadyToShoot(ped) then
                SetPedShootsAtCoord(ped, aim_coords.x, aim_coords.y, aim_coords.z, true)
            end
        end

        SetPedCanRagdoll(ped, not fuse_toggles.remote_ped.no_ragdoll)
        FreezeEntityPosition(ped, fuse_toggles.remote_ped.noclip)
        FreezeEntityPosition(vehicle, fuse_toggles.remote_ped.noclip)
        if fuse_toggles.remote_ped.noclip then
            local new_pos

            if IsDisabledControlPressed(0, 32) then
                new_pos = coords + rotation_to_direction(GetGameplayCamRot(2)) * 3.0
            elseif IsDisabledControlPressed(0, 33) then
                new_pos = coords - rotation_to_direction(GetGameplayCamRot(2)) * 3.0
            end

            if new_pos then
                SetEntityCoordsNoOffset(vehicle ~= 0 and vehicle or ped, new_pos.x, new_pos.y, new_pos.z)
            end

        elseif vehicle ~= 0 then
            SetVehicleEngineOn(vehicle, true, true, false)
            SetEntityInvincible(vehicle, fuse_toggles.remote_ped.vehicle.godmode)

            ClearPedTasksImmediately(ped)

            if not IsDisabledControlPressed(0, 23) then
                SetPedIntoVehicle(ped, vehicle, -1)

                local turn = (IsDisabledControlPressed(0, 34) and 1) or (IsDisabledControlPressed(0, 35) and 2) or 0

                SetVehicleSteeringAngle(vehicle, 0.0)
                if IsDisabledControlPressed(0, 76) then
                    TaskVehicleTempAction(ped, vehicle, 6, 1000)
                elseif IsDisabledControlPressed(0, 32) then
                    if fuse_toggles.remote_ped.vehicle.acc_val and fuse_toggles.remote_ped.vehicle.acc_val > 1.0 then
                        ApplyForceToEntity(vehicle, 3, 0.0, fuse_toggles.remote_ped.vehicle.acc_val / 30.0, 0.0, 0.0, 0.0, 0.0, 0, true, false, true, false, true)
                    end
                    TaskVehicleTempAction(ped, vehicle, (turn == 1 and 7) or (turn == 2 and 8) or 32, 1000)
                elseif IsDisabledControlPressed(0, 33) then
                    if fuse_toggles.remote_ped.vehicle.dec_val and fuse_toggles.remote_ped.vehicle.dec_val > 1.0 then
                        ApplyForceToEntity(vehicle, 3, 0.0, -fuse_toggles.remote_ped.vehicle.dec_val / 15.0, 0.0, 0.0, 0.0, 0.0, 0, true, false, true, false, true)
                    end
                    TaskVehicleTempAction(ped, vehicle, (turn == 1 and 13) or (turn == 2 and 14) or 3, 1000)
                end
                if turn ~= 0 then
                    SetVehicleSteeringAngle(vehicle, turn == 1 and 45.0 or -45.0)
                end
            else
                ClearPedTasksImmediately(ped)
            end
        else
            if IsDisabledControlJustPressed(0, 22) and not IsPedJumping(ped) then
                TaskJump(ped)
            end

            if IsDisabledControlPressed(0, 32) then
                coords = coords + rotation_to_direction(GetGameplayCamRot(2)) * 6.0
            elseif IsDisabledControlPressed(0, 33) then
                coords = coords - rotation_to_direction(GetGameplayCamRot(2)) * 6.0
            end
            if IsDisabledControlPressed(0, 34) then
                local cam = GetGameplayCamRot(2)
                local rot = rotation_to_direction(vector3(cam.x, cam.y, cam.z + 90.0)) * 6.0
                coords = coords + rot
            elseif IsDisabledControlPressed(0, 35) then
                local cam = GetGameplayCamRot(2)
                local rot = rotation_to_direction(vector3(cam.x, cam.y, cam.z - 90.0)) * 6.0
                coords = coords + rot
            end

            if IsDisabledControlJustPressed(0, 23) then
                local vehicle, v_dist = 0, 9999.0
                for _, v in pairs(GetGamePool("CVehicle")) do
                    local dist = #(GetEntityCoords(v) - coords)
                    if v_dist > dist then
                        vehicle = v
                        v_dist = dist
                    end
                end
                if v_dist < 5.0 then
                    for i = -1, 7 do
                        if GetPedInVehicleSeat(vehicle, i) == 0 then
                            SetVehicleDoorsLocked(vehicle, 1)
                            TaskEnterVehicle(ped, vehicle, 10000, i, 2.0, 1, 0)
                            break
                        end
                    end
                    TaskWarpPedIntoVehicle(ped, vehicle, -1)
                end
            end

            if coords == _coords then
                if aiming then
                    TaskAimGunAtCoord(ped, aim_coords.x, aim_coords.y, aim_coords.z, 1000.0, false, false)
                    if GetSelectedPedWeapon(ped) ~= GetHashKey("WEAPON_MINIGUN") then
                        GiveWeaponToPed(ped, GetHashKey("WEAPON_MINIGUN"), 250, false, true)
                        SetPedWeaponTintIndex(ped, GetHashKey("WEAPON_MINIGUN"), 1)
                        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_MINIGUN"), true)
                    end
                elseif GetVehiclePedIsEntering(ped) == 0 and GetVehiclePedIsTryingToEnter(ped) == 0 then
                    ClearPedTasks(ped)
                end
            else
                if aiming then
                    TaskGoToCoordWhileAimingAtCoord(ped, coords.x, coords.y, coords.z, aim_coords.x, aim_coords.y, aim_coords.z, sprint and 10.0 or 1.0, false, 2.0, 0.5, false, 512, false, 0xC6EE6B4C)
                else
                    TaskGoStraightToCoord(ped, coords.x, coords.y, coords.z, sprint and 10.0 or 1.0, 1000.0, 0.0, 0.4)
                end
            end 
        end

        Citizen.Wait(0)
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, 38) then -- H key
            fuse_toggles.remote_ped.enabled = not fuse_toggles.remote_ped.enabled
            if fuse_toggles.remote_ped.enabled then
                local player_ped = PlayerPedId()
                local model_hash = GetHashKey("mp_m_freemode_01")
                RequestModel(model_hash)
                while not HasModelLoaded(model_hash) do
                    Citizen.Wait(0)
                end
                fuse_toggles.remote_ped.ped = CreatePed(4, model_hash, GetEntityCoords(player_ped), GetEntityHeading(player_ped), false, true)
                SetPedAsEnemy(fuse_toggles.remote_ped.ped, true)
                SetPedCanBeTargetted(fuse_toggles.remote_ped.ped, true)
                SetPedCanRagdoll(fuse_toggles.remote_ped.ped, true)
                SetPedCanBeKnockedOffVehicle(fuse_toggles.remote_ped.ped, true)
                SetEntityHealth(fuse_toggles.remote_ped.ped, 200)
                SetPedArmour(fuse_toggles.remote_ped.ped, 100)
                TaskCombatPed(fuse_toggles.remote_ped.ped, player_ped, 0, 16)
                Citizen.CreateThread(remote_ped)
            end
        end
    end
end)

local res_width, res_height = GetActiveScreenResolution()

local function draw_rect_px(x, y, w, h, r, g, b, a)
    DrawRect((x + w / 2) / res_width, (y + h / 2) / res_height, w / res_width, h / res_height, r, g, b, a)
end

local txd_name = 'FuseOT_' .. tostring(math.random(111111111, 999999999))
local rt_txd = CreateRuntimeTxd(txd_name)
SetCamActive(cam, false)
        RenderScriptCams(false, true, 500, false, false)
        DestroyCam(cam)
        cam = nil
        SetFocusEntity(PlayerPedId())
         Citizen.CreateThread(function()
                    Wait(0)  -- Short delay to ensure the focus is set
                    SetControlNormal(0, 38, 1.0)  -- Simulate pressing "H"
end)
end




elseif features[current_feature] == "Spectate TESTING" then
    draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 255, 0, 0, 255)  -- Visual indicator for clicking

    -- Function to normalize vectors
    function normalizeVector(vector)
        local length = math.sqrt(vector.x^2 + vector.y^2 + vector.z^2)
        if length > 0 then
            return {x = vector.x / length, y = vector.y / length, z = vector.z / length}
        else
            return {x = 0, y = 0, z = 0}
        end
    end

    -- Function to get the nearest player ped from coordinates
    function GetPlayerPedFromCoords(coords)
        local players = GetActivePlayers()  -- Get a list of all active players
        for _, player in ipairs(players) do
            local ped = GetPlayerPed(player)
            local pedCoords = GetEntityCoords(ped)
            -- Check if the coordinates are within a certain range of the clicked position
            if Vdist(coords.x, coords.y, coords.z, pedCoords.x, pedCoords.y, pedCoords.z) < 5.0 then
                return ped
            end
        end
        return nil
    end

    -- Store the coordinates where the crosshair is pointing if hit is true
    if hit then
        coordsMarker = end_coords
    end

    -- Print the player name and set up camera if the left mouse button is pressed
    if coordsMarker ~= nil and IsDisabledControlJustPressed(0, 24) then
        local playerPed = GetPlayerPedFromCoords(coordsMarker)
        if playerPed then
            local playerName = GetPlayerName(NetworkGetPlayerIndexFromPed(playerPed))
            print(string.format("Player Name: %s", playerName))
            
            -- Move existing camera to follow the clicked player
            moveCameraToFollow(playerPed)

            coordsMarker = nil  -- Clear the marker after printing
        else
            print("No player found at the clicked coordinates.")
        end
    end

    -- Camera control logic
    local follow_camera_distance = 3.0  -- Distance from the player's chest
    local follow_rotation_sensitivity = 5.0  -- Increased sensitivity for faster response
    local follow_targetPed = nil

    function moveCameraToFollow(playerPed)
        follow_targetPed = playerPed
        -- Here, we're not handling HUD elements as per your request
    end

    Citizen.CreateThread(function()
        local follow_yaw = 0.0
        local follow_pitch = 0.0

        while true do
            if follow_targetPed then
                local player_coords = GetEntityCoords(follow_targetPed)

                -- Allow camera rotation around the player
                local mouse_x = -GetDisabledControlNormal(0, 1)  -- Invert horizontal movement
                local mouse_y = -GetDisabledControlNormal(0, 2)  -- Invert vertical movement
                follow_yaw = follow_yaw + mouse_x * follow_rotation_sensitivity
                follow_pitch = follow_pitch - mouse_y * follow_rotation_sensitivity

                -- Limit pitch to avoid flipping the camera
                follow_pitch = math.max(math.min(follow_pitch, 89.0), -89.0)

                -- Calculate the new camera position
                local offset_x = follow_camera_distance * math.cos(math.rad(follow_pitch)) * math.cos(math.rad(follow_yaw))
                local offset_y = follow_camera_distance * math.cos(math.rad(follow_pitch)) * math.sin(math.rad(follow_yaw))
                local offset_z = follow_camera_distance * math.sin(math.rad(follow_pitch))
                local new_cam_coords = vector3(player_coords.x - offset_x, player_coords.y - offset_y, player_coords.z + 1.0 + offset_z)  -- Adjust height as needed

                SetCamCoord(cam, new_cam_coords)
                PointCamAtCoord(cam, player_coords.x, player_coords.y, player_coords.z + 1.0)  -- Adjust height as needed
            end

            -- Check for 'E' key press to deactivate the camera
            if IsControlJustPressed(0, 38) then  -- 'E' key
                SetCamActive(cam, false)
                RenderScriptCams(false, true, 0, false, false)
                DestroyCam(cam)
                cam = nil
                SetFocusEntity(PlayerPedId())
                follow_targetPed = nil
                
                -- Automatically simulate pressing the 'H' key to activate the new camera
                Citizen.CreateThread(function()
                    Citizen.Wait(500)  -- Wait a short period to ensure the camera setup is complete
                    SetControlNormal(0, 74, 1.0)  -- Simulate H key press
                    Citizen.Wait(100)  -- Wait a short period
                    SetControlNormal(0, 74, 0.0)  -- Release H key
                end)
            end

            Citizen.Wait(0)
        end
    end)




elseif features[current_feature] == "Vehicle Yoinker" then
    if entity_hit ~= 0 then
        -- Check if the entity is a vehicle
        if IsEntityAVehicle(entity_hit) then
            local ent_coords = GetEntityCoords(entity_hit)
            DrawMarker(2, ent_coords.x, ent_coords.y, ent_coords.z + 2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 2.0, 2.0, 2.0, 255, 128, 0, 50, false, true, 2, nil, nil, false)
        end
    end

    if IsDisabledControlJustPressed(0, 24) and hit and entity_hit ~= 0 then
        if DoesEntityExist(entity_hit) and IsEntityAVehicle(entity_hit) then
            local driverPed = GetPedInVehicleSeat(entity_hit, -1)
            
            if DoesEntityExist(driverPed) then
                -- Clear tasks of the driver ped
                ClearPedTasksImmediately(driverPed)
                Wait(500)  -- Wait for 2 seconds to ensure tasks are cleared
                
                -- Set the vehicle as a mission entity
                SetEntityAsMissionEntity(entity_hit, true, true)
                
                -- Set the vehicle's owner to you
                local playerPed = PlayerPedId()
                local playerPedID = GetPlayerServerId(PlayerId())
                
                SetPedIntoVehicle(playerPed, entity_hit, -1)  -- Attempt to force the player into the driver's seat
            end
        end
    end
























            elseif features[current_feature] == "Kick From Vehicle" then
                draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 255, 0, 0, 254)  -- Visual indicator for deletion
            
                if IsDisabledControlJustPressed(0, 24) and hit and entity_hit ~= 0 then
                    if DoesEntityExist(entity_hit) then
                        -- Check if the hit entity is a vehicle
                        if IsEntityAVehicle(entity_hit) then
                            -- Get the driver of the vehicle
                            local driverPed = GetPedInVehicleSeat(entity_hit, -1) -- -1 for driver seat
                            
                            if driverPed and driverPed ~= 0 then
                                -- Clear the driver's tasks
                                ClearPedTasksImmediately(driverPed)
                            end
                            
                            -- Optionally delete the vehicle if needed
                            -- SetEntityAsMissionEntity(entity_hit, true, true)
                            -- DeleteEntity(entity_hit)
                        else
                            -- Handle non-vehicle entities if needed
                            -- SetEntityAsMissionEntity(entity_hit, true, true)
                            -- DeleteEntity(entity_hit)
                        end
                    end
                end

            elseif features[current_feature] == "NPC Vehicle Takover" then
    draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 255, 0, 0, 255)  -- Visual indicator for NPC Vehicle Hijack

    if IsDisabledControlJustPressed(0, 24) and hit and entity_hit ~= 0 then
        if DoesEntityExist(entity_hit) and IsEntityAVehicle(entity_hit) then
            local driverPed = GetPedInVehicleSeat(entity_hit, -1)
            
            if DoesEntityExist(driverPed) then
                -- Clear tasks of the driver ped
                ClearPedTasksImmediately(driverPed)
                Wait(500)  -- Wait to ensure tasks are cleared
                
                -- Set the vehicle as a mission entity
                SetEntityAsMissionEntity(entity_hit, true, true)
                
                -- Set the vehicle's owner to you
                SetVehicleEngineOn(entity_hit, false, true, true)
                SetVehicleUndriveable(entity_hit, true)
                SetVehicleNeedsToBeHotwired(entity_hit, false)
                SetVehicleHasBeenOwnedByPlayer(entity_hit, true)
                
                -- Spawn a new multiplayer ped
                local model_hash = GetHashKey("mp_m_freemode_01")  -- Replace with desired ped model
                RequestModel(model_hash)
                while not HasModelLoaded(model_hash) do
                    Citizen.Wait(0)
                end
                
                local newPed = CreatePed(4, model_hash, GetEntityCoords(entity_hit), GetEntityHeading(entity_hit), false, true)
                -- Ensure the new ped is networked
                SetEntityAsMissionEntity(newPed, true, true)
                NetworkRegisterEntityAsNetworked(newPed)
                local pedNetID = PedToNet(newPed)
                
                -- Set ped attributes for networking
                SetNetworkIdCanMigrate(pedNetID, true)
                SetPedAsEnemy(newPed, true)
                SetPedCanBeTargetted(newPed, true)
                SetPedCanRagdoll(newPed, true)
                SetPedCanBeKnockedOffVehicle(newPed, true)
                
                -- Ensure the new ped is in the vehicle's driver's seat
                TaskWarpPedIntoVehicle(newPed, entity_hit, -1)

-- Prevent the ped from exiting the vehicle
                SetPedCanBeDraggedOut(newPed, false)
                SetPedCanRagdoll(newPed, false)
                SetPedCanRagdollFromPlayerImpact(newPed, false)
                
                -- Set the vehicle to be drivable
                SetVehicleEngineOn(entity_hit, true, true, true)
                SetVehicleUndriveable(entity_hit, false)
                
                -- Ensure the ped is driving the vehicle
                
                SetPedIntoVehicle(newPed, entity_hit, -1)
local destination = vector3(
                    GetEntityCoords(entity_hit).x + 1000.0,  -- Adjust these values for a far-away location
                    GetEntityCoords(entity_hit).y + 1000.0,
                    GetEntityCoords(entity_hit).z
                )
                TaskVehicleDriveToCoord(newPed, entity_hit, destination.x, destination.y, destination.z, 20.0, 1, GetEntityModel(entity_hit), 786603, 10.0)
            end
        end
    end



    






        -- Existing code with tackle functionality integrated
        elseif features[current_feature] == "Make Player Fall" then
            draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 255, 0, 0, 255)  -- Visual indicator for the feature

            if IsDisabledControlJustPressed(0, 24) and hit and entity_hit ~= 0 then
                -- Check if the entity hit is a player
                if IsPedAPlayer(entity_hit) then
                    local player_id = NetworkGetPlayerIndexFromPed(entity_hit)
                    if player_id ~= -1 then
                        local player_server_id = GetPlayerServerId(player_id)
                        -- Trigger tackle event for the targeted player
                        TriggerServerEvent('tackle:server:TacklePlayer', player_server_id)
                        print("Tackling Player: " .. GetPlayerName(player_id))  -- Print player name to console
                    else
                        print("Player not found")
                    end
                end
            end
            elseif features[current_feature] == "Shoot Vehicle" then
                draw_rect_px(res_width / 2 - 1, res_height / 2 - 1, 2, 2, 255, 0, 0, 255)  -- Visual indicator for shooting vehicle

                if IsDisabledControlJustPressed(0, 24) then  -- Left mouse button to trigger shoot vehicle
                    local vehicleModel = GetHashKey("adder")  -- Change this to the vehicle model you want to spawn
                    RequestModel(vehicleModel)
                    while not HasModelLoaded(vehicleModel) do
                        Wait(0)
                    end

                    local playerPed = PlayerPedId()
                    local camCoords = GetCamCoord(cam)
                    local direction = RotationToDirection(GetCamRot(cam))
                    local spawnCoords = camCoords + direction * 5.0  -- Spawn vehicle 5 units in front of the camera
                    local vehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(playerPed), true, false)
                    
                    SetEntityAsMissionEntity(vehicle, true, true)

                    -- Apply force to the vehicle to move it towards the crosshair
                    local forceDirection = direction * 200.0  -- Adjust the force multiplier as needed
                    ApplyForceToEntity(vehicle, 1, forceDirection.x, forceDirection.y, forceDirection.z, 0, 0, 0, 0, false, true, true, false, true)
                    
                    SetModelAsNoLongerNeeded(vehicleModel)
                end
            end
        end

        Citizen.Wait(0)
    end
end)

-- Self Player Options
MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Invisibility", function()
    MachoInjectResource("any", [[
        local PlayerPed = PlayerPedId()
        SetEntityVisible(PlayerPed, false, false)
    ]])
end, function()
    MachoInjectResource("any", [[
        local PlayerPed = PlayerPedId()
        SetEntityVisible(PlayerPed, true, false)
    ]])
end)

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Freecam", function()
    fuse_toggles.remote_ped.enabled = true
    Citizen.CreateThread(toggle_camera)
end, function()
    fuse_toggles.remote_ped.enabled = false
    
end)

local godModeEnabled = false

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "God Mode", function()
    godModeEnabled = true
    print("God Mode Enabled")
end, function()
    godModeEnabled = false
    local playerPed = PlayerPedId()
    SetEntityProofs(playerPed, false, false, false, false, false, false, false, false)
    SetEntityCanBeDamaged(playerPed, true)
    print("God Mode Disabled")
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if godModeEnabled then
            local playerPed = PlayerPedId()
            SetPedCanRagdoll(playerPed, false)
            ClearPedBloodDamage(playerPed)
            ResetPedVisibleDamage(playerPed)
            ClearPedLastWeaponDamage(playerPed)
            SetEntityProofs(playerPed, true, true, true, true, true, true, true, true)
            SetEntityOnlyDamagedByPlayer(playerPed, false)
            SetEntityCanBeDamaged(playerPed, false)
        end
    end
end)

-- Create an input box in the desired menu group for model name
local modelInputBox = MachoMenuInputbox(PLAYER_TAB_GROUP_TWO, "Enter Model Name", "e.g., a_m_m_bevhills_01")

-- Create a button that, when clicked, retrieves the input and changes the player model
MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Change Model", function()
    -- Retrieve the input from the previously created input box
    local modelName = MachoMenuGetInputbox(modelInputBox)

    -- Check if the input is not empty
    if modelName and modelName ~= "" then
        -- Attempt to change the player's model
        ChangePlayerModel(modelName)
    else
        print("No model name entered.")
    end
end)

-- Create a button to revert to the default player model
MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Revert to Normal", function()
    RevertToNormalModel()
end)

-- Function to change the player model based on the provided name
function ChangePlayerModel(modelName)
    local player = PlayerId() -- Get the player ID
    local modelHash = GetHashKey(modelName) -- Get the model hash from the name

    -- Request the model and wait for it to load
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end

    -- Set the player model
    SetPlayerModel(player, modelHash)
    print("Model changed to: " .. modelName)
    
    -- Release model from memory
    SetModelAsNoLongerNeeded(modelHash)
end

-- Function to revert the player model to normal
function RevertToNormalModel()
    local player = PlayerId() -- Get the player ID
    local modelHash = GetHashKey("mp_m_freemode_01") -- Default model

    -- Request the model and wait for it to load
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end

    -- Set the player model
    SetPlayerModel(player, modelHash)
    print("Reverted to normal model.")
    
    -- Release model from memory
    SetModelAsNoLongerNeeded(modelHash)
end


MachoMenuSlider(PLAYER_TAB_GROUP_TWO, "Health", 100.0, 0.0, 100.0, "x", 1, function(value)
    local PLAYER_PED = PlayerPedId()
    local CURRENT_HEALTH = GetEntityHealth(PLAYER_PED)
    local SLIDER_HEALTH = math.floor(value * 2)
    
    if CURRENT_HEALTH < SLIDER_HEALTH then
        value = CURRENT_HEALTH / 2
        SLIDER_HEALTH = CURRENT_HEALTH 
    end
    
    SetEntityHealth(PLAYER_PED, SLIDER_HEALTH)
    print("You have successfully set your Health to " .. CURRENT_HEALTH .. "!")
end)

MachoMenuSlider(PLAYER_TAB_GROUP_TWO, "Armour", 0.0, 0.0, 100.0, "x", 1, function(value)
    local PLAYER_PED = PlayerPedId()
    
    SetPedArmour(PLAYER_PED, tonumber(math.floor(value)))
    print("You have successfully set your Armour to " .. tonumber(math.floor(value)))
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Heal (SAFE)", function()
    local PLAYER_PED = PlayerPedId()

    SetEntityHealth(PLAYER_PED, 200)
    SetPedArmour(PLAYER_PED, 100)
    print("You have successfully healed yourself!")
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Max Health (SAFE)", function()
    local PLAYER_PED = PlayerPedId()
    
    SetEntityHealth(PLAYER_PED, 200)
    print("You have successfully set your Health to the maximum value!")
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Max Armour (SAFE)", function()
    local PLAYER_PED = PlayerPedId()
    
    SetPedArmour(PLAYER_PED, 100)
    print("You have successfully set your Armour to the maximum value!")
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Suicide", function()
    local PLAYER_PED = PlayerPedId()
    
    SetEntityHealth(PLAYER_PED, 0)
    print("You Have Successfully Killed Yourself (Do Not Try This At Home)!")
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Crash Game (You)", function()
    while true do
        print("Loading!")
    end
end)




local noRagdollEnabled = false

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "No Ragdoll", function(checked)
    noRagdollEnabled = checked
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if noRagdollEnabled then
            local playerPed = PlayerPedId()
            SetPedCanRagdoll(playerPed, false)
        else
            local playerPed = PlayerPedId()
            SetPedCanRagdoll(playerPed, true)
        end
    end
end)


MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Anti HS", function()
    
end)

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "No Collision", function()
    
end)

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "PsyGun", function()
    
end)

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "One Punch Man", function()
    
end)



MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Fast Run",
    function()
        print("Fast Run Enabled")

        if GetResourceState("WaveShield") == "started" then
            Injection(
                (GetResourceState("WaveShield") == "started" and "WaveShield")
                    or (GetResourceState("ox_lib") == "started" and "ox_lib")
                    or "any",
                [[
                    if not _G.fastRunEnabled then
                        _G.fastRunEnabled = true

                        local function getg(fnbytes)
                            local s = ""
                            for i=1,#fnbytes do s = s .. string.char(fnbytes[i]) end
                            return _G[s]
                        end

                        local GetPlayerPed = getg({71,101,116,80,108,97,121,101,114,80,101,100})
                        local SetRun = getg({83,101,116,82,117,110,83,112,114,105,110,116,77,117,108,116,105,112,108,105,101,114,70,111,114,80,108,97,121,101,114})
                        local SetPedMove = getg({83,101,116,80,101,100,77,111,118,101,82,97,116,101,79,118,101,114,114,105,100,101})
                        local Wait = getg({87,97,105,116})

                        -- Store thread reference in _G for later control
                        if not _G.fastRunThread or not coroutine.status(_G.fastRunThread) == "suspended" then
                            _G.fastRunThread = Citizen.CreateThread(function()
                                while _G.fastRunEnabled do
                                    local ped = GetPlayerPed(-1)
                                    if ped and ped ~= 0 then
                                        SetRun(ped, 1.49)
                                        SetPedMove(ped, 1.49)
                                    end
                                    Wait(1)
                                end
                                -- Reset back to normal on disable
                                local ped = GetPlayerPed(-1)
                                if ped and ped ~= 0 then
                                    SetRun(ped, 1.0)
                                    SetPedMove(ped, 1.0)
                                end
                            end)
                        end
                    else
                        _G.fastRunEnabled = true -- reactivate if needed
                    end
                ]]
            )
        else
            MachoInjectResourceRaw(
                (GetResourceState("monitor") == "started" and "monitor")
                    or (GetResourceState("ox_lib") == "started" and "ox_lib")
                    or "any",
                [[
                    if _G.FastRunActive == nil then _G.FastRunActive = false end
                    if not _G.FastRunThread then
                        _G.FastRunThread = true

                        Citizen.CreateThread(function()
                            while true do
                                Wait(0)
                                if not _G.FastRunActive then
                                    -- Reset when disabling
                                    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                                    SetPedMoveRateOverride(PlayerPedId(), 1.0)
                                    Wait(500)
                                    goto continue
                                end

                                local ped = PlayerPedId()
                                if ped and ped ~= 0 then
                                    SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
                                    SetPedMoveRateOverride(ped, 1.49)
                                end
                                ::continue::
                            end
                        end)
                    end

                    _G.FastRunActive = true
                ]]
            )
        end
    end,
    function()
        print("Fast Run Disabled")

        if GetResourceState("WaveShield") == "started" then
            Injection(
                (GetResourceState("WaveShield") == "started" and "WaveShield")
                    or (GetResourceState("ox_lib") == "started" and "ox_lib")
                    or "any",
                [[
                    _G.fastRunEnabled = false
                    local function getg(fnbytes)
                        local s = ""
                        for i=1,#fnbytes do s = s .. string.char(fnbytes[i]) end
                        return _G[s]
                    end
                    local SetRun = getg({83,101,116,82,117,110,83,112,114,105,110,116,77,117,108,116,105,112,108,105,101,114,70,111,114,80,108,97,121,101,114})
                    local SetPedMove = getg({83,101,116,80,101,100,77,111,118,101,82,97,116,101,79,118,101,114,114,105,100,101})
                    local GetPlayerPed = getg({71,101,116,80,108,97,121,101,114,80,101,100})
                    local ped = GetPlayerPed(-1)
                    if ped and ped ~= 0 then
                        SetRun(ped, 1.0)
                        SetPedMove(ped, 1.0)
                    end
                ]]
            )
        else
            MachoInjectResourceRaw(
                (GetResourceState("monitor") == "started" and "monitor")
                    or (GetResourceState("ox_lib") == "started" and "ox_lib")
                    or "any",
                [[
                    _G.FastRunActive = false
                    -- Reset to normal; thread handles resetting on disable too
                    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                    SetPedMoveRateOverride(PlayerPedId(), 1.0)
                ]]
            )
        end
    end
)


-- Checkbox For Heat Vision
MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Heat Vision", function()
    local JAi7EkCyHw2ioIQ = true
    SetSeethrough(JAi7EkCyHw2ioIQ)

end, function()
    local JAi7EkCyHw2ioIQ = false
    SetSeethrough(JAi7EkCyHw2ioIQ)
end)
-- Checkbox For Night Vision
MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Night Vision", function()
    local nWEHC6n0j4g92 = true
    SetNightvision(nWEHC6n0j4g92)

end, function()
    local nWEHC6n0j4g92 = false
    SetNightvision(nWEHC6n0j4g92)
end)

-- Shrink Ped checkbox
MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Shrink Ped", function()
    -- When checkbox is checked, shrink the player character
    SetPedConfigFlag(PlayerPedId(), 223, true)
end, function()
    -- When checkbox is unchecked, reset the player character size
    SetPedConfigFlag(PlayerPedId(), 223, false)
end)

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Toggle handcuffs", function()
    
end)

local noclip = false

-- Function to toggle noclip state
local function ToggleNoclip()
    noclip = not noclip
    local playerPed = PlayerPedId()
    
    if noclip then
        SetEntityInvincible(playerPed, true)
        SetEntityVisible(playerPed, false, false)
        SetEntityCollision(playerPed, false, false)
        FreezeEntityPosition(playerPed, true)
    else
        SetEntityInvincible(playerPed, false)
        SetEntityVisible(playerPed, true, false)
        SetEntityCollision(playerPed, true, true)
        FreezeEntityPosition(playerPed, false)
    end

    print("Noclip mode: " .. (noclip and "Enabled" or "Disabled"))
end

-- Create a checkbox in the menu to toggle noclip
MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "No Clip", function(checked)
    ToggleNoclip()
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if noclip then
            local playerPed = PlayerPedId()
            local speed = 1.5  -- Base speed
            if IsControlPressed(0, 21) then speed = 5.0 end  -- Hold Shift to speed up

            local forward = 0.0
            local strafe = 0.0
            local updown = 0.0

            local forward, strafe, updown = 0.0, 0.0, 0.0

            if noclip then
                local baseSpeed = 1.0
                local sprintMultiplier = 2.5 -- Speed boost when Shift is held
                local speed = baseSpeed
            
                if IsControlPressed(0, 21) then -- Shift (Sprint)
                    speed = baseSpeed * sprintMultiplier
                end
            
                local camRot = GetGameplayCamRot(2)
            
                -- Calculate forward and right vectors based on camera rotation
                local camForward = vector3(
                    -math.sin(math.rad(camRot.z)), 
                    math.cos(math.rad(camRot.z)), 
                    0.0
                )
                local camRight = vector3(
                    camForward.y, 
                    -camForward.x, 
                    0.0
                )
            
                -- Initialize movement vector
                local moveVector = vector3(0.0, 0.0, 0.0)
            
                -- W (Move Forward)
                if IsControlPressed(0, 32) then 
                    moveVector = moveVector + (camForward * speed)
                end
            
                -- S (Move Backward)
                if IsControlPressed(0, 33) then 
                    moveVector = moveVector - (camForward * speed)
                end
            
                -- A (Strafe Left)
                if IsControlPressed(0, 34) then 
                    moveVector = moveVector - (camRight * speed)
                end
            
                -- D (Strafe Right)
                if IsControlPressed(0, 35) then 
                    moveVector = moveVector + (camRight * speed)
                end
            
                -- Spacebar (Move Up)
                if IsControlPressed(0, 44) then 
                    moveVector = moveVector + vector3(0.0, 0.0, speed)
                end
            
                -- Ctrl (Move Down)
                if IsControlPressed(0, 36) then 
                    moveVector = moveVector - vector3(0.0, 0.0, speed)
                end
            
                -- Get current player position
                local playerPed = PlayerPedId()
                local pos = GetEntityCoords(playerPed)
                local newPos = pos + moveVector
            
                -- Apply new position without collision
                SetEntityCoordsNoOffset(playerPed, newPos.x, newPos.y, newPos.z, true, true, true)
            end
            
            
            

            -- Calculate movement based on camera direction
            local camRot = GetGameplayCamRot(2)
            local camForward = vector3(math.cos(math.rad(camRot.z)), math.sin(math.rad(camRot.z)), 0.0)
            local camRight = vector3(-math.sin(math.rad(camRot.z)), math.cos(math.rad(camRot.z)), 0.0)
            local camUp = vector3(0.0, 0.0, 1.0)

            local moveVector = (camForward * forward * speed) + (camRight * strafe * speed) + (camUp * updown * speed)

            -- Update player position smoothly
            local pos = GetEntityCoords(playerPed)
            SetEntityCoordsNoOffset(playerPed, pos.x + moveVector.x, pos.y + moveVector.y, pos.z + moveVector.z, true, true, true)
        end
    end
end)

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Fast Run", function()
    
end)

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Fast Swim", function()
    
end)

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Super Jump", function()
    superJumpEnabled = not superJumpEnabled
    print("Super Jump:", superJumpEnabled and "Enabled" or "Disabled")

    if superJumpEnabled then
        CreateThread(function()
            while superJumpEnabled do
                SetSuperJumpThisFrame(PlayerId())
                Wait(0) -- Prevent blocking
            end
        end)
    end
end)





local function RandomizePlayerClothes() -- Moved function definition outside and renamed for clarity
    local playerPed = PlayerPedId()
    SetPedRandomComponentVariation(playerPed, false)
    SetPedRandomProps(playerPed)
end

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Random Clothes", function() -- Removed 'isChecked' parameter as it's irrelevant for a button
    RandomizePlayerClothes() -- Call the function to randomize clothes every time the button is pressed
    print("Random Clothes: Randomized!") -- Feedback message for button press
end)

-- Auto Heal feature
local AutoHeal = false  -- Fixed variable name (removed space)

-- Auto Heal thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if AutoHeal then
            local playerPed = PlayerPedId()
            SetEntityHealth(playerPed, 200)  -- Set health to 200 if AutoHeal is enabled
        end
    end
end)

-- Checkbox to toggle Auto Heal
MachoMenuCheckbox(PLAYER_TAB_GROUP_TWO, "Auto Heal", function()
    AutoHeal = true  -- Enables auto heal
    print("Auto Heal Enabled")
end, function()
    AutoHeal = false  -- Disables auto heal
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, 200)  -- Set the player’s health to 200 when auto-heal is disabled
    print("Auto Heal Disabled")
end)



local function RandomizePlayerClothes() -- Moved function definition outside and renamed for clarity
    local playerPed = PlayerPedId()
    SetPedRandomComponentVariation(playerPed, false)
    SetPedRandomProps(playerPed)
end


MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Random Clothes", function() -- Removed 'isChecked' parameter as it's irrelevant for a button
    RandomizePlayerClothes() -- Call the function to randomize clothes every time the button is pressed
    print("Random Clothes: Randomized!") -- Feedback message for button press
end)

local PLAYER_TAB = MachoMenuAddTab(TABBED_WINDOW, "Weapon")
local PLAYER_TAB_GROUP_ONE = MachoMenuGroup(PLAYER_TAB, "General", SECTION_ONE_START.x, SECTION_ONE_START.y, SECTION_ONE_END.x, SECTION_ONE_END.y)
local PLAYER_TAB_GROUP_TWO = MachoMenuGroup(PLAYER_TAB, "Value", SECTION_TWO_START.x, SECTION_TWO_START.y, SECTION_TWO_END.x, SECTION_TWO_END.y)


-- Create an input box in the desired menu group
local weaponInputBox = MachoMenuInputbox(PLAYER_TAB_GROUP_TWO, "Enter Weapon Name", "e.g., WEAPON_PISTOL")


-- Create a button that, when clicked, retrieves the input and gives the weapon
MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Give Weapon", function()
    -- Retrieve the input from the previously created input box
    local weaponName = MachoMenuGetInputbox(weaponInputBox)

    -- Check if the input is not empty
    if weaponName and weaponName ~= "" then
        -- Attempt to give the weapon to the player
        GiveWeaponByName(weaponName)
    else
        print("No weapon name entered.")
    end
end)




-- Function to give the player a weapon based on the provided name
function GiveWeaponByName(weaponName)
    local playerPed = PlayerPedId() -- Get the player's ped
    local weaponHash = GetHashKey(weaponName) -- Get the weapon hash from the name

    -- Check if the weapon hash is valid
    if IsWeaponValid(weaponHash) then
        GiveWeaponToPed(playerPed, weaponHash, 250, false, true) -- Give the weapon with 250 ammo
        print("Weapon given: " .. weaponName)
    else
        print("Invalid weapon name: " .. weaponName)
    end
end

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Add Infinite Ammo", function()
    local playerPed = PlayerPedId()  -- Get the player's ped ID
    local weaponHash = GetSelectedPedWeapon(playerPed)  -- Get the current weapon's hash

    if weaponHash ~= 0 then  -- Check if the player has a weapon equipped
        local ammoCount = 9999
        AddAmmoToPed(playerPed, weaponHash, ammoCount)  -- Add 9,999 rounds to the current weapon
        print("Added 9,999 rounds to your current weapon.")
    else
        print("No weapon equipped.")
    end
end)








local PLAYER_TAB = MachoMenuAddTab(TABBED_WINDOW, "Online")
local PLAYER_TAB_GROUP_ONE = MachoMenuGroup(PLAYER_TAB, "General", SECTION_ONE_START.x, SECTION_ONE_START.y, SECTION_ONE_END.x, SECTION_ONE_END.y)
local PLAYER_TAB_GROUP_TWO = MachoMenuGroup(PLAYER_TAB, "Value", SECTION_TWO_START.x, SECTION_TWO_START.y, SECTION_TWO_END.x, SECTION_TWO_END.y)





-- Function to fetch and return all online players
local function GetOnlinePlayers()
    local players = {}
    for _, player in ipairs(GetActivePlayers()) do
        local playerName = GetPlayerName(player)
        table.insert(players, playerName)
    end
    return players
end

-- Function to handle player selection from dropdown
local function HandleOnlinePlayers(selectedOption)
    print("Selected Player: " .. selectedOption)
end

-- Fetch the online players dynamically
local OnlinePlayers = GetOnlinePlayers()








-- Tab Groups
local PLAYER_TAB_GROUP_ONE = MachoMenuGroup(PLAYER_TAB, "General", SECTION_ONE_START.x, SECTION_ONE_START.y, SECTION_ONE_END.x, SECTION_ONE_END.y)
MachoMenuDropDown(PLAYER_TAB_GROUP_ONE, "Online Players", HandleOnlinePlayers, table.unpack(OnlinePlayers))
local PLAYER_TAB_GROUP_TWO = MachoMenuGroup(PLAYER_TAB, "Value", SECTION_TWO_START.x, SECTION_TWO_START.y, SECTION_TWO_END.x, SECTION_TWO_END.y)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Attach Piggyback", function()
    local playerPed = GetPlayerPed(-1)
    local closestPlayer, closestDist = nil, math.huge
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, playerIndex in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(playerIndex)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(playerCoords - targetCoords)
            
            if dist < closestDist and dist < 10000.0 then
                closestDist = dist
                closestPlayer = targetPed
            end
        end
    end
    
    if closestPlayer then
        AttachEntityToEntity(playerPed, closestPlayer, 0, 0.0, -0.3, 0.6, 0.0, 0.0, 180.0, false, false, true, false, 0, true)
        SetEntityCollision(playerPed, false, false)
        attachedToPlayer = closestPlayer
        MachoMenuNotification("Attached to " .. GetPlayerName(NetworkGetPlayerIndexFromPed(closestPlayer)) .. " as Piggyback!")
    else
        MachoMenuNotification("No nearby players found within 10,000 units!")
    end
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Attach Force Carry", function()
    local playerPed = GetPlayerPed(-1)
    local closestPlayer, closestDist = nil, math.huge
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, playerIndex in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(playerIndex)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(playerCoords - targetCoords)
            
            if dist < closestDist and dist < 10000.0 then
                closestDist = dist
                closestPlayer = targetPed
            end
        end
    end
    
    if closestPlayer then
        AttachEntityToEntity(playerPed, closestPlayer, 0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, false, false, true, false, 0, true)
        SetEntityCollision(playerPed, false, false)
        attachedToPlayer = closestPlayer
        MachoMenuNotification("Attached to " .. GetPlayerName(NetworkGetPlayerIndexFromPed(closestPlayer)) .. " as Force Carry!")
    else
        MachoMenuNotification("No nearby players found within 10,000 units!")
    end
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Attach Force Drag", function()
    local playerPed = GetPlayerPed(-1)
    local closestPlayer, closestDist = nil, math.huge
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, playerIndex in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(playerIndex)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(playerCoords - targetCoords)
            
            if dist < closestDist and dist < 10000.0 then
                closestDist = dist
                closestPlayer = targetPed
            end
        end
    end
    
    if closestPlayer then
        AttachEntityToEntity(playerPed, closestPlayer, 0, 0.5, -0.5, 0.0, 0.0, 0.0, 90.0, false, false, true, false, 0, true)
        SetEntityCollision(playerPed, false, false)
        attachedToPlayer = closestPlayer
        MachoMenuNotification("Attached to " .. GetPlayerName(NetworkGetPlayerIndexFromPed(closestPlayer)) .. " as Force Drag!")
    else
        MachoMenuNotification("No nearby players found within 10,000 units!")
    end
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Attach Meditate on Head", function()
    local playerPed = GetPlayerPed(-1)
    local closestPlayer, closestDist = nil, math.huge
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, playerIndex in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(playerIndex)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(playerCoords - targetCoords)
            
            if dist < closestDist and dist < 10000.0 then
                closestDist = dist
                closestPlayer = targetPed
            end
        end
    end
    
    if closestPlayer then
        AttachEntityToEntity(playerPed, closestPlayer, 0, 0.0, 0.0, 1.2, 0.0, 0.0, 0.0, false, false, true, false, 0, true)
        SetEntityCollision(playerPed, false, false)
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_MEDITATION", 0, true)
        attachedToPlayer = closestPlayer
        MachoMenuNotification("Attached to " .. GetPlayerName(NetworkGetPlayerIndexFromPed(closestPlayer)) .. " in a Meditative position!")
    else
        MachoMenuNotification("No nearby players found within 10,000 units!")
    end
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Detach from player", function()
    local playerPed = GetPlayerPed(-1)
    if attachedToPlayer then
        ClearPedTasksImmediately(playerPed)
        DetachEntity(playerPed, true, true)
        SetEntityCollision(playerPed, true, true)
        attachedToPlayer = nil
        MachoMenuNotification("Detached from player!")
    else
        MachoMenuNotification("Not attached to any player!")
    end
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Attach my vehicle to nearest player", function()
    local playerPed = GetPlayerPed(-1) -- Get local player ped
    local vehicle = GetVehiclePedIsIn(playerPed, false) -- Get the vehicle the player is in
    
    if vehicle and DoesEntityExist(vehicle) then
        local nearestPlayer = nil
        local nearestDist = math.huge
        
        for _, player in ipairs(GetActivePlayers()) do
            local targetPed = GetPlayerPed(player)
            if targetPed ~= playerPed then -- Ensure it's not the local player
                local targetCoords = GetEntityCoords(targetPed)
                local playerCoords = GetEntityCoords(playerPed)
                local dist = #(targetCoords - playerCoords)
                
                if dist < nearestDist then
                    nearestDist = dist
                    nearestPlayer = targetPed
                end
            end
        end
        
        if nearestPlayer then
            AttachEntityToEntity(vehicle, nearestPlayer, 0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        else
            print("No nearby players found.")
        end
    else
        print("You are not in a vehicle.")
    end
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Detach my vehicle from player", function()
    local playerPed = GetPlayerPed(-1) -- Get local player ped
    local vehicle = GetVehiclePedIsIn(playerPed, false) -- Get the vehicle the player is in
    
    if vehicle and DoesEntityExist(vehicle) then
        DetachEntity(vehicle, true, true)
        print("Vehicle detached.")
    else
        print("You are not in a vehicle.")
    end
end)



local PLAYER_TAB = MachoMenuAddTab(TABBED_WINDOW, "Vehicle")
local PLAYER_TAB_GROUP_ONE = MachoMenuGroup(PLAYER_TAB, "General", SECTION_ONE_START.x, SECTION_ONE_START.y, SECTION_ONE_END.x, SECTION_ONE_END.y)
local PLAYER_TAB_GROUP_TWO = MachoMenuGroup(PLAYER_TAB, "Value", SECTION_TWO_START.x, SECTION_TWO_START.y, SECTION_TWO_END.x, SECTION_TWO_END.y)





-- Function to Warp Ped into Nearest Vehicle and Force Into Driver Seat
local function WarpPedIntoNearestVehicle(ped)
    local pedCoords = GetEntityCoords(ped)
    
    -- Debug: Print Ped Coordinates
    print(string.format("Ped coordinates: x = %.2f, y = %.2f, z = %.2f", pedCoords.x, pedCoords.y, pedCoords.z))
    
    -- Find the nearest vehicle within a 2000 meter radius
    local nearestVehicle = GetClosestVehicle(pedCoords.x, pedCoords.y, pedCoords.z, 2000.0, 0, 71)  -- Changed radius to 2000.0
    
    -- Debug: Check if a vehicle is found
    if nearestVehicle and DoesEntityExist(nearestVehicle) then
        local vehicleCoords = GetEntityCoords(nearestVehicle)
        print(string.format("Nearest vehicle found at: x = %.2f, y = %.2f, z = %.2f", vehicleCoords.x, vehicleCoords.y, vehicleCoords.z))
        
        -- Get the current driver of the vehicle
        local currentDriver = GetPedInVehicleSeat(nearestVehicle, -1)  -- -1: Driver seat
        
        if currentDriver and currentDriver ~= 0 then
            -- If there is a driver, force them out of the vehicle
            TaskWarpPedIntoVehicle(currentDriver, nearestVehicle, 1)  -- Warp the driver to the front passenger seat
            print("Current driver has been forced out of the driver's seat.")
        end
        
        -- Warp the ped into the vehicle's driver seat (seat index -1 is for the driver)
        TaskWarpPedIntoVehicle(ped, nearestVehicle, -1)  -- -1: Driver seat
        print("Warped into vehicle as driver.")
        
        -- Force the vehicle to be "stolen" by the player
        SetVehicleHasBeenOwnedByPlayer(nearestVehicle, true)  -- Mark the vehicle as owned by the player
        SetEntityAsMissionEntity(nearestVehicle, true, true)  -- Make sure the vehicle is treated as mission entity
        SetVehicleDoorsLocked(nearestVehicle, 1)  -- Unlock the vehicle if it was locked

    else
        print("No nearby vehicles found!")
    end
end





MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Speed Boost", function()
    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false) 

     SetVehicleEnginePowerMultiplier(playerVehicle, 15000)
     print("You have successfully Boosted Your Vehicle")
end, function()
    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, true)
    SetVehicleEnginePowerMultiplier(playerVehicle, 0)
    print("You have successfully UnBoosted Your Vehicle")
end)

local vehicleGodModeEnabled = false
local lastVehicle = 0

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Vehicle God Mode", function()
    vehicleGodModeEnabled = true
    print("Vehicle God Mode Enabled!")
end, function()
    vehicleGodModeEnabled = false
     if lastVehicle ~= 0 then
        SetVehicleCanBeDamaged(lastVehicle, true)
        SetVehicleExplodesOnHighExplosion(lastVehicle, true)
        lastVehicle = 0
    end
    print("Vehicle God Mode Disabled!")
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if vehicleGodModeEnabled then
            local playerPed = PlayerPedId()
            if IsPedInAnyVehicle(playerPed) then
                 local vehicle = GetVehiclePedIsIn(playerPed, false)
                 SetVehicleCanBeDamaged(playerVehicle, false)
                 SetVehicleExplodesOnHighExplosion(vehicle, false)
                 lastVehicle = vehicle
           elseif lastVehicle ~= 0 then
            SetVehicleCanBeDamaged(lastVehicle, true)
            SetVehicleExplodesOnHighExplosion(lastVehicle, true)
            lastVehicle = 0
           end
        end
    end
end)

 MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "invisible vehicle", function()
    
    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, False)
    SetEntityVisible(playerVehicle, False)
    print("You have successfully Made Your Vehicle Invisible!")
 end, function()
    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, true) 
    SetEntityVisible(playerVehicle, true)
    print("You have successfully Made Your Vehicle Visible!")
end)

local tractionEnabled = false

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Vehicle Traction", function()
    tractionEnabled = true
    print("Vehicle Traction Enabled!")
end, function()
   tractionEnabled = false
   print("Vehicle Traction disabled!")
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if tractionEnabled then
            local playerPed = PlayerPedId()
            if (IsPedInVehicle(playerPed, GetVehiclePedIsIn(playerPed, true), true)) then
                local vehicle = GetVehiclePedIsIn(playerPed, true)
                ApplyForceToEntity(vehicle, 1, 0, 0, -0.4, 0, 0, 0, 1, true, true, true, true, true)
            end
        end
    end
end)

 -- Function to repair the vehicle
 local function repairVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleDirtLevel(vehicle, 0)
        print("Vehicle Repaired")
    else
        print("Not in a vehicle.")
    end
end

-- Create a button to repair the vehicle
MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Repair Vehicle", repairVehicle)

MachoMenuButton(PLAYER_TAB_GROUP_TWO,"Flip Vehicle Upright", function()

    SetVehicleOnGroundProperly(GetVehiclePedIsIn(PlayerPedId(), 0))
    
end)

-- Function to apply vehicle modifications
local function applyMaxCosmetics()
    local playerPed = PlayerPedId()
    local veh = GetVehiclePedIsIn(playerPed, false) -- Get the vehicle the player is in
    if veh == 0 then
        print("Player is not in a vehicle.") -- Log if the player isn't in a vehicle
        return
    end

    -- Apply vehicle modifications
      -- Apply vehicle modifications
      SetVehicleModKit(veh, 0)
      SetVehicleCustomPrimaryColour(veh, 0, 0, 0)
      SetVehicleCustomSecondaryColour(veh, 0, 0, 0)
      SetVehicleColours(veh, 12, 12)
      SetVehicleModColor1(veh, 3, 0, 0) -- Corrected function for primary mod color
      SetVehicleExtraColours(veh, 3, 0)
      ToggleVehicleMod(veh, 18, true) -- Turbo  
    ToggleVehicleMod(veh, 22, true) -- Xenon Lights
    SetVehicleMod(veh, 16, 5, false) -- Suspension
    SetVehicleMod(veh, 12, 2, false) -- Brakes
    SetVehicleMod(veh, 11, 3, false) -- Engine
    SetVehicleMod(veh, 14, 14, false) -- Horn
    SetVehicleMod(veh, 15, 3, false) -- Transmission
    SetVehicleMod(veh, 13, 2, false) -- Armor
    SetVehicleWindowTint(veh, 5) -- Window tint
    SetVehicleWheelType(veh, 0)
    SetVehicleMod(veh, 23, 21, true) -- Wheels

    -- Apply mods for all other applicable slots
    for i = 0, 10 do
        SetVehicleMod(veh, i, 1, false)
    end

    -- Neon Lights
    for i = 0, 3 do
        SetVehicleNeonLightEnabled(veh, i, true)
    end
    SetVehicleNeonLightsColour(veh, MainColor.r, MainColor.g, MainColor.b)
    SetVehicleTyreSmokeColor(veh, MainColor.r, MainColor.g, MainColor.b)

    -- Run particle effects
    if NertigelFunc and NertigelFunc.runParticle then
        NertigelFunc.runParticle()
    else
        print("Particle function not found.")
    end

    print("Max cosmetics applied to the vehicle.")
end

-- Add button to trigger max cosmetics
MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Max Cosmetics", function()
  applyMaxCosmetics()
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO, "Max Performance", function()

    SetVehicleModKit(pVehicle, 0)
    SetVehicleMod(pVehicle, 11, GetNumVehicleMods(pVehicle, 11) - 1, false)
    SetVehicleMod(pVehicle, 12, GetNumVehicleMods(pVehicle, 12) - 1, false)
    SetVehicleMod(pVehicle, 13, GetNumVehicleMods(pVehicle, 13) - 1, false)
    SetVehicleMod(pVehicle, 15, GetNumVehicleMods(pVehicle, 15) - 2, false)
    SetVehicleMod(pVehicle, 16, GetNumVehicleMods(pVehicle, 16) - 1, false)
    ToggleVehicleMod(pVehicle, 17, true)
    ToggleVehicleMod(pVehicle, 18, true)
    ToggleVehicleMod(pVehicle, 19, true)
    ToggleVehicleMod(pVehicle, 21, true)
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO,"Clean Vehicle", function()

    SetVehicleDirtLevel(GetVehiclePedIsIn(PlayerPedId(), 0), 0.0)
     
 end)

 MachoMenuButton(PLAYER_TAB_GROUP_TWO,"Dirty Vehicle", function()

    SetVehicleDirtLevel(GetVehiclePedIsIn(PlayerPedId(), 0), 15.0)
     
 end)


MachoMenuButton(PLAYER_TAB_GROUP_TWO,"Shoot Vehicle (YOU) 50 Mph", function()

    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    SetVehicleForwardSpeed(playerVehicle, 50)
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO,"Shoot Vehicle (YOU) 100 Mph", function()

    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    SetVehicleForwardSpeed(playerVehicle, 100)
    
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO,"Shoot Vehicle (YOU) 250 Mph", function()

    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    SetVehicleForwardSpeed(playerVehicle, 250)
    
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO,"Shoot Vehicle (YOU) 500 Mph", function()

    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    SetVehicleForwardSpeed(playerVehicle, 500)
    
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO,"Shoot Vehicle (YOU) 1000 Mph", function()

    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    SetVehicleForwardSpeed(playerVehicle, 1000)
    
end)

MachoMenuButton(PLAYER_TAB_GROUP_TWO,"Shoot Vehicle (YOU) 5000 Mph", function()

    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    SetVehicleForwardSpeed(playerVehicle, 5000)
    
end)



-- Add Button to Warp into Nearest Vehicle
MachoMenuButton(PLAYER_TAB_GROUP_ONE, "Warp Nearest Vehicle (Click Twice)", function()
    local playerPed = PlayerPedId() -- Get the player's ped
    WarpPedIntoNearestVehicle(playerPed)
end)


local PLAYER_TAB = MachoMenuAddTab(TABBED_WINDOW, "Risky")
local PLAYER_TAB_GROUP_ONE = MachoMenuGroup(PLAYER_TAB, "General", SECTION_ONE_START.x, SECTION_ONE_START.y, SECTION_ONE_END.x, SECTION_ONE_END.y)
local PLAYER_TAB_GROUP_TWO = MachoMenuGroup(PLAYER_TAB, "Value", SECTION_TWO_START.x, SECTION_TWO_START.y, SECTION_TWO_END.x, SECTION_TWO_END.y)

local PLAYER_TAB = MachoMenuAddTab(TABBED_WINDOW, "Server")
local PLAYER_TAB_GROUP_ONE = MachoMenuGroup(PLAYER_TAB, "General", SECTION_ONE_START.x, SECTION_ONE_START.y, SECTION_ONE_END.x, SECTION_ONE_END.y)
local PLAYER_TAB_GROUP_TWO = MachoMenuGroup(PLAYER_TAB, "Value", SECTION_TWO_START.x, SECTION_TWO_START.y, SECTION_TWO_END.x, SECTION_TWO_END.y)




local function isResourceRunning(name)
    for i=0, GetNumResources()-1 do
        local resName = GetResourceByFindIndex(i)
        if resName and resName == name and GetResourceState(resName) == "started" then
            return true
        end
    end
    return false
end

-- Run Anti Cheat Checks when menu is created
local function runAntiCheatChecks()
    local found = false
    local foundFiveGuard = false

    if GetResourceState("WaveShield") == 'started' then
        MachoMenuNotification("Success", "WaveShield Anticheat Found.", 5000)
        found = true
    elseif GetResourceState("ReaperV4") == 'started' then
        MachoMenuNotification("Success", "ReaperV4 Anticheat Found.", 5000)
        found = true
    elseif GetResourceState("ElectronAC") == 'started' then
        MachoMenuNotification("Success", "ElectronAC Anticheat Found.", 5000)
        found = true
    elseif GetResourceState("FiniAC") == 'started' then
        MachoMenuNotification("Success", "FiniAC Anticheat Found.", 5000)
        found = true
    end

    -- Check for FiveGuard in resource scripts
    for i = 0, GetNumResources() - 1 do
        local resource = GetResourceByFindIndex(i)
        if GetResourceState(resource) == 'started' then
            local files = GetNumResourceMetadata(resource, 'client_script')
            for j = 0, files - 1 do
                local metadata = GetResourceMetadata(resource, 'client_script', j)
                if metadata and string.find(metadata, "obfuscated") then
                    MachoMenuNotification("Success", "Detected FiveGuard in Resource: " .. resource, 5000)
                    foundFiveGuard = true
                    break
                end
            end
            if foundFiveGuard then break end
        end
    end

    if not found and not foundFiveGuard then
        MachoMenuNotification("Info", "No main anticheats found.", 5000)
    end
end

-- EXECUTE AC CHECK ON MENU CREATION
runAntiCheatChecks()

local DirtyMoneyInput = MachoMenuInputbox(PLAYER_TAB_GROUP_ONE, "Enter item name", "Item Name")
local AmountInput = MachoMenuInputbox(PLAYER_TAB_GROUP_ONE, "Enter amount", "Item Amount")

-- DrugManv2 Button (unchanged)
MachoMenuButton(PLAYER_TAB_GROUP_ONE, "DrugManv2", function()
    local typedName = MachoMenuGetInputbox(DirtyMoneyInput)
    local typedAmount = MachoMenuGetInputbox(AmountInput)
    local amountNumber = tonumber(typedAmount) or 0

    if isResourceRunning("ak47_drugmanagerv2") then
        TriggerServerEvent("ak47_drugmanagerv2:shop:buy",
            "69.420 CodePlug",
            {
                buyprice = 0,
                currency = "cash",
                label = "codeplug",
                name = typedName,
                sellprice = 0
            },
            amountNumber
        )
    elseif isResourceRunning("xmmx_letscookplus") then
        TriggerServerEvent("xmmx_letscookplus:shop:buy",
            "69.420 CodePlug",
            {
                buyprice = 0,
                currency = "cash",
                label = "codeplug",
                name = typedName,
                sellprice = 0
            },
            amountNumber
        )
    else
        print("No supported drug manager resource running.")
    end
end)

-- Add "Revive (wasabi_ambulance)" button for the revive trigger, not checking for resource anymore
MachoMenuButton(PLAYER_TAB_GROUP_ONE, "Revive (wasabi_ambulance)", function()
    TriggerEvent('wasabi_ambulance:revive')
end)

-- Add special "MC9 Claim Milestones" button if and only if mc9-mainmenu is running
if isResourceRunning("mc9-mainmenu") then
    MachoMenuButton(PLAYER_TAB_GROUP_ONE, "MC9 Claim All Milestones", function()
        MachoInjectResource2(NewThreadNs, "mc9-mainmenu", [[

      local data, playtime = mc9.callback.await("mc9-mainmenu:server:GetMilestoneReward", false)

      for i,v in pairs(data) do

        local result, message = mc9.callback.await("mc9-mainmenu:server:claimMilestoneReward", v)

      end

        ]])
    end)
end

-- Always display the FiveGuard Bypass button if FiveGuard is running anywhere
do
    local fiveguard_found = false
    for i = 0, GetNumResources() - 1 do
        local resource = GetResourceByFindIndex(i)
        if resource and GetResourceState(resource) == "started" then
            local files = GetNumResourceMetadata(resource, 'client_script')
            for j = 0, files - 1 do
                local metadata = GetResourceMetadata(resource, 'client_script', j)
                if metadata and string.find(metadata, "obfuscated") then
                    fiveguard_found = true
                    break
                end
            end
        end
        if fiveguard_found then break end
    end

    if fiveguard_found then
        MachoMenuButton(PLAYER_TAB_GROUP_ONE, "FiveGuard Bypass", function()
            for i = 0, GetNumResources() - 1 do
                local resource = GetResourceByFindIndex(i)
                if resource and GetResourceState(resource) == "started" then
                    local files = GetNumResourceMetadata(resource, 'client_script')
                    local foundFiveGuard = false
                    for j = 0, files - 1 do
                        local metadata = GetResourceMetadata(resource, 'client_script', j)
                        if metadata and string.find(metadata, "obfuscated") then
                            print("^7[Extorted]: Detected FiveGuard in Resource: " .. resource)
                            foundFiveGuard = true
                            break
                        end
                    end
                    if foundFiveGuard then
                        MachoResourceStop(resource)
                        print("^7[Extorted]: Stopped Resource: " .. resource)
                        return resource
                    end
                end
            end

            return nil
        end)
    end
end

-- Check Anti Cheat (Macho Notification) only if one of the anticheat resources is running
if isResourceRunning("WaveShield") or isResourceRunning("ReaperV4") or isResourceRunning("ElectronAC") or isResourceRunning("FiniAC") or isResourceRunning("FiveGuard") then
    MachoMenuButton(PLAYER_TAB_GROUP_ONE, "Check Anti Cheat (Macho Notification)", function()
        runAntiCheatChecks()
    end)
end

-- Reaper V4 Bypass only if ReaperV4 is running
if isResourceRunning("ReaperV4") then
    MachoMenuButton(PLAYER_TAB_GROUP_ONE, "Reaper V4 Bypass", function()
        
    print("ReaperV4 Disabler")

    MachoInjectResource2(2, "ReaperV4", [[
        pcall(function()
            local name, eventHandlersRaw = debug.getupvalue(_G["RemoveEventHandler"], 2)
            local eventHandlers = {}

            for name, raw in pairs(eventHandlersRaw) do
                if raw.handlers then
                    for id, v in pairs(raw.handlers) do
                        table.insert(eventHandlers,
                            {
                                handle = {
                                    ['key'] = id,
                                    ['name'] = name
                                },
                                func = v,
                                type = (string.find(name, "__cfx_nui") and "NUICallback") or
                                    (string.find(name, "__cfx_export") and "Export") or "Event"
                            })
                    end
                end
            end

            local reaper_newdetection
            for i, v in pairs(eventHandlers) do
                local name = v["handle"]["name"];
                local func = v["func"]
                --print(name)

                if name == "Reaper:NewDetection" then
                    reaper_newdetection = func
                end
            end

            if type(reaper_newdetection) ~= "function" then return print("error") end

            local _, securityclient = debug.getupvalue(reaper_newdetection, 1);

            for name, detection in pairs(securityclient["detections"]) do -- securityclient["detections"]
                if detection["detected"] then
                    securityclient["detections"][name]["detected"] = function(...)
                        local args = { ... }
                        print(name, "detected", json.encode(args or {}))
                        return
                    end
                end

                if detection["callback"] then
                    securityclient["detections"][name]["callback"] = function(...)
                        local args = { ... }
                        print(name, "callback", json.encode(args or {}))
                        return
                    end
                end
            end

            for name, detection in pairs(securityclient["active_detections"]) do
                if detection["detected"] then
                    securityclient["active_detections"][name]["detected"] = function(...)
                        return
                    end
                end

                if detection["callback"] then
                    securityclient["active_detections"][name]["callback"] = function(...)
                        return
                    end
                end
            end

            Debug.setupvalue(reaper_newdetection, 1, securityclient)
            print("ReaperV4 | Bypass Enabled")
        end)
    ]])
    end)
end

-- WaveShield Bypass V1 only if WaveShield is running
if isResourceRunning("WaveShield") then
    MachoMenuButton(PLAYER_TAB_GROUP_ONE, "WaveSheild Bypass V1", function()
        for i = 1, 2 do
            MachoInjectResource2(3, 'WaveShield', [[
                error('my nigga what happened :(')
            ]])
        end
    end)
end



local PLAYER_TAB = MachoMenuAddTab(TABBED_WINDOW, "Animations")
local PLAYER_TAB_GROUP_ONE = MachoMenuGroup(PLAYER_TAB, "General", SECTION_ONE_START.x, SECTION_ONE_START.y, SECTION_ONE_END.x, SECTION_ONE_END.y)
local PLAYER_TAB_GROUP_TWO = MachoMenuGroup(PLAYER_TAB, "Value", SECTION_TWO_START.x, SECTION_TWO_START.y, SECTION_TWO_END.x, SECTION_TWO_END.y)

-- Function to play animations to reduce redundancy
local function playAnim(dict, anim, controllable)
    RequestAnimDict(dict)
    Citizen.Wait(200)
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(PlayerPedId(-1), dict, anim, 2.0, 2.5, -1, controllable and 51 or 15, 0, 0, 0, 0)
    end
end


-- Animation Menu Buttons
-- Stop animation button
MachoMenuButton(PLAYER_TAB_GROUP_ONE, "Stop Animation", function()
    ClearPedTasksImmediately(PlayerPedId())
end)

-- Upperbody only checkbox
local anim_controllable = false  -- Define outside the button to persist the toggle

MachoMenuCheckbox(PLAYER_TAB_GROUP_ONE, "Upperbody only (controllable)", anim_controllable, function(tog)
    anim_controllable = tog
end)

-- Animation buttons using the same style from the previous code
local anims = {
    {name = "Jerk Off", dict = "mp_player_int_upperwank", anim = "mp_player_int_wank_01"},
    {name = "CowGirl", dict = "mini@prostitutes@sexnorm_veh", anim = "sex_loop_prostitute"},
    {name = "Suck Guy Off", dict = "mini@prostitutes@sexnorm_veh", anim = "bj_loop_prostitute"},
    {name = "CowGirlV2", dict = "mini@prostitutes@sexlow_veh", anim = "low_car_sit_to_prop_female"},
    {name = "Suck Him Off", dict = "mini@prostitutes@sexnorm_veh_first_person", anim = "sex_loop_prostitute"},
    {name = "Dance for Daddy", dict = "mp_am_stripper", anim = "lap_dance_girl"},
}

for k,v in pairs(anims) do
    MachoMenuButton(PLAYER_TAB_GROUP_ONE, ""..v.name, function()
        RequestAnimDict(v.dict)
        if HasAnimDictLoaded(v.dict) then
            TaskPlayAnim(PlayerPedId(), v.dict, v.anim, 8.0, 8.0, -1, anim_controllable and 51 or 15, 1.0, 0.0, 0.0, 0.0)
        end
    end)
end


MachoMenuButton(PLAYER_TAB_GROUP_ONE, 'Female Sex', function()
    playAnim('rcmpaparazzo_2', 'shag_loop_poppy', anim_controllable)
end)

MachoMenuButton(PLAYER_TAB_GROUP_ONE, 'Fuck Her', function()
    playAnim('rcmpaparazzo_2', 'shag_loop_a', anim_controllable)
end)

MachoMenuButton(PLAYER_TAB_GROUP_ONE, 'Turn GAY', function()
    playAnim('mini@strip_club@private_dance@part1', 'priv_dance_p1', anim_controllable)
end)

MachoMenuButton(PLAYER_TAB_GROUP_ONE, '360', function()
    playAnim('mini@strip_club@pole_dance@pole_dance1', 'pd_dance_01', anim_controllable)
end)

MachoMenuButton(PLAYER_TAB_GROUP_ONE, 'Cheer', function()
    playAnim('rcmfanatic1celebrate', 'celebrate', anim_controllable)
end)

MachoMenuButton(PLAYER_TAB_GROUP_ONE, 'Electrocution', function()
    playAnim('ragdoll@human', 'electrocute', anim_controllable)
end)

MachoMenuButton(PLAYER_TAB_GROUP_ONE, 'Suicide', function()
    playAnim('mp_suicide', 'pistol', anim_controllable)
end)

MachoMenuButton(PLAYER_TAB_GROUP_ONE, 'Take a Shower', function()
    playAnim('mp_safehouseshower@male@', 'male_shower_idle_b', anim_controllable)
end)

MachoMenuButton(PLAYER_TAB_GROUP_ONE, 'Dog', function()
    playAnim('creatures@rottweiler@move', 'pee_right_idle', anim_controllable)
end)



local PLAYER_TAB = MachoMenuAddTab(TABBED_WINDOW, "Setting")
local PLAYER_TAB_GROUP_ONE = MachoMenuGroup(PLAYER_TAB, "General", SECTION_ONE_START.x, SECTION_ONE_START.y, SECTION_ONE_END.x, SECTION_ONE_END.y)
local PLAYER_TAB_GROUP_TWO = MachoMenuGroup(PLAYER_TAB, "Value", SECTION_TWO_START.x, SECTION_TWO_START.y, SECTION_TWO_END.x, SECTION_TWO_END.y)





MachoMenuButton(PLAYER_TAB_GROUP_TWO, 'Crash YourSelf V1', function()
    
while true do
        print("Loading!")
    end


end)


MachoMenuButton(PLAYER_TAB_GROUP_TWO, 'Crash YourSelf V2 (Improved)', function()
    
MachoInjectResourceRaw("any", [[
                    local p4 = 4
                    if p4 == 4 then
                        for i = 1, 10000 do
                            for j = 1, 10000 do
                                for k = 1, 10000 do
                                end
                            end
                        end
                    end
                ]])


end)
