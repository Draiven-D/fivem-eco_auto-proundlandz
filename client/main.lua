local Config = {}
local script_name = GetCurrentResourceName()
ESX = nil
local token = nil
local IsDead = false
local Blips = {}
local UseSuit = false
local purgeday = false

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
    while ESX.GetPlayerData().job == nil do Citizen.Wait(100) end
    ESX.PlayerData = ESX.GetPlayerData()
    TriggerServerEvent(script_name .. ":server:LoadConfig")
end)

RegisterNetEvent(script_name .. ":client:GetConfig")
AddEventHandler(script_name .. ":client:GetConfig",  function(f)
	Config = f.c
	token = f.tk
	blipIcon()
    LoadConfig()
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(job)
	ESX.PlayerData.job = job
	Citizen.Wait(3000)
end)

AddEventHandler('esx:onPlayerDeath', function()
	IsDead = true
end)

AddEventHandler('esx:onPlayerSpawn', function()
	IsDead = false
end)

function CreateBlipCircle(coords, text, radius, color, sprite)
    local blip = AddBlipForCoord(coords)
    SetBlipHighDetail(blip, true)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
    table.insert(Blips, blip)
end

function blipIcon()
    Citizen.CreateThread(function()
        while Config == nil do Citizen.Wait(200) end
        local DataEvent = {}
        for k, v in pairs(Config.Zones) do
            if (v.Routine and v.Show) or not v.Routine then
                if v.Harvest ~= nil and v.Harvest.name ~= nil and v.Harvest.sprite ~= nil then
                    CreateBlipCircle(v.Harvest.coords, v.Harvest.name, v.Harvest.radius, v.Harvest.color, v.Harvest.sprite)
                end
                if v.Process ~= nil and v.Process.name ~= nil and v.Process.sprite ~= nil then
                    CreateBlipCircle(v.Process.coords, v.Process.name, v.Process.radius, v.Process.color, v.Process.sprite)
                end
            end
            if (v.Routine and v.Show) then
                local year, month, day, hour, minute, second = GetLocalTime()
                local Data = {
                    item = v.Item,
                    time = hour..':00 - '..hour..':20 น.'
                }
                table.insert(DataEvent, Data)
            end
        end
        if next(DataEvent) ~= nil then
            SendNUIMessage({type = "ShowEvent", data = DataEvent})
        else
            SendNUIMessage({type = "CloseEvent"})
        end
	end)
end

function deleteBlips()
	if Blips[1] ~= nil then
		for i=1, #Blips, 1 do
			RemoveBlip(Blips[i])
			Blips[i] = nil
		end
	end
end

function LoadConfig()
    local spawnedPropCount = 0
    local propPlants = {}
    local isAuto = false
	local pickcount = 0
	local pickMax = math.random(68, 130)
	local nearbyObject, nearbyID, nearbyCoords
	local MyData = {
		VehPlate = nil,
		VehMWeight = 0,
		VehCWeight = 0
	}
    local GotoStorage = false
    local isProcessing = false
    local isLock = false
    local Zone = nil
    local MiniStart = false

    Citizen.CreateThread(function()
		while true do
			local sleep = 300
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local area = false
            -- if not purgeday then
                for k, v in pairs(Config.Zones) do
                    if (v.Routine and v.Show) or (not v.Routine) then
                        local dist = #(coords - v.Harvest.coords)
                        if dist < 120.0 then
                            Zone = k
                            area = true
                            if v.Dist2 and dist < v.Dist2 then
                                if IsPedInAnyVehicle(ped, false) then
                                    local veh = GetVehiclePedIsIn(ped, false)
                                    if GetPedInVehicleSeat(veh, -1) == ped then
                                        if DoesEntityExist(veh) and NetworkHasControlOfEntity(veh) then
                                            local vehicleProps = ESX.Game.GetVehicleProperties(veh)
                                            local currentFuel = exports["LegacyFuel"]:GetFuel(veh)
                                            local currentHealth = exports["RealisticVehicleFailure"]:GetHealth(veh)
                                            ESX.TriggerServerCallback('esx_advancedgarage:storeVehicle', function(valid)
                                                if valid then
                                                    TriggerServerEvent('esx_advancedgarage:setVehicleState', vehicleProps.plate, true)
                                                    exports.pNotify:SendNotification({text = "ฝากยานพาหนะเรียบร้อย!", type = "success", queue = "garage"})
                                                end
                                                ESX.Game.DeleteVehicle(veh)
                                            end, vehicleProps, currentFuel, currentHealth, {state = Config.Zones[Zone].Storage.state})
                                        end
                                    end
                                end
                            end
                            break
                        end
                    end
                end
            -- end
			if not area then
                Zone = nil
				if next(propPlants) ~= nil then
					for k, v in pairs(propPlants) do
						DeleteEntity(v)
					end
					propPlants = {}
					spawnedPropCount = 0
				end
			end
            Citizen.Wait(sleep)
        end
    end)

    Citizen.CreateThread(function()
		while true do
			if Zone then
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local dist = #(coords - Config.Zones[Zone].Harvest.coords)
                if dist < Config.Zones[Zone].Dist then
                    if (not Config.Zones[Zone].Routine) or (Config.Zones[Zone].Routine and UseSuit) then
                        if Config.Zones[Zone].PropName then
                            SpawnProp(Zone)
                        end
                    elseif (Config.Zones[Zone].Routine and not UseSuit) then
                        if next(propPlants) ~= nil then
                            for x, r in pairs(propPlants) do
                                DeleteEntity(r)
                            end
                            propPlants = {}
                            spawnedPropCount = 0
                        end
                    end
                end
            end
            Citizen.Wait(500)
        end
    end)

    Citizen.CreateThread(function()
		while true do
			if Zone then
                if Config.Zones[Zone].Dist2 then
                    DrawMarker(1, Config.Zones[Zone].Harvest.coords.x, Config.Zones[Zone].Harvest.coords.y, Config.Zones[Zone].Harvest.coords.z -10, 0.0, 0.0, 0.0, 0, 0.0, 0.0, ((Config.Zones[Zone].Dist2*2)-2), ((Config.Zones[Zone].Dist2*2)-2), 30.0, 255, 0, 102, 40, false, true, 2, false, false, false, false)
                end
                    -- if Config.Zones[Zone].Routine and not UseSuit then
                --     local coords = GetEntityCoords(PlayerPedId())
                --     local dist = #(coords - Config.Zones[Zone].Harvest.coords)
                --     if dist < Config.Zones[Zone].Dist then
                --         DrawText3D(coords, "~w~ต้องใส่ชุดนักเรียนด้วยนะ~s~", 2.0)
                --         DisablePlayerFiring(PlayerPedId(), true) -- Disable weapon firing
                --         DisableControlAction(0, 24, true) -- disable attack
                --         DisableControlAction(0, 25, true) -- disable aim
                --         DisableControlAction(1, 37, true) -- disable weapon select
                --         DisableControlAction(0, 47, true) -- disable weapon
                --         DisableControlAction(0, 56, true) -- disable melee
                --         DisableControlAction(0, 58, true) -- disable weapon
                --         DisableControlAction(0, 140, true) -- disable melee
                --         DisableControlAction(0, 141, true) -- disable melee
                --         DisableControlAction(0, 142, true) -- disable melee
                --         DisableControlAction(0, 143, true) -- disable melee
                --         DisableControlAction(0, 263, true) -- disable melee
                --         DisableControlAction(0, 264, true) -- disable melee
                --         DisableControlAction(0, 257, true) -- disable melee
                --         DisableControlAction(0, 157, true) -- disable melee
                --         DisableControlAction(0, 158, true) -- disable melee
                --         DisableControlAction(0, 160, true) -- disable melee
                --     end
                -- end
                if isLock == true then
                    DisableControlAction(0, 29, true) -- B
                    DisableControlAction(0, 74, true) -- H
                    DisableControlAction(0, 22, true) -- SPACEBAR
                    DisableControlAction(0, 30, true) -- disable left/right
                    DisableControlAction(0, 31, true) -- disable forward/back
                    DisableControlAction(0, 36, true) -- INPUT_DUCK
                    DisableControlAction(0, 23, true) -- disable f
                    DisableControlAction(0, 21, true) -- disable sprint
                    DisableControlAction(0, 44, true) -- Cover
                    DisableControlAction(0, 18, true) -- Enter
                    DisableControlAction(0, 176, true) -- Enter
                    DisableControlAction(0, 201, true) -- Enter
                    DisableControlAction(0, 170, true) -- F3
                    DisableControlAction(0, 166, true) -- F5
                    DisableControlAction(0, 167, true) -- F6
                    DisableControlAction(0, 56, true) -- F9
                end
            else
                Citizen.Wait(500)
			end
            Citizen.Wait(0)
        end
    end)
    
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)
            if Zone then
                if isAuto then
                    if IsControlJustReleased(0, 73) or IsDead then
                        ClearPedTasks(PlayerPedId())
                        SendNUIMessage({type = "Exit"})
                        isAuto = false
                        TriggerEvent("pNotify:SendNotification", {text = "ยกเลิกการฟาร์มอัตโนมัติ", type = "error", queue = "job"})
                    end
                    DisableControlAction(0, 29, true) -- B
                    DisableControlAction(0, 74, true) -- H
                    DisableControlAction(0, 22, true) -- SPACEBAR
                    DisableControlAction(0, 30, true) -- disable left/right
                    DisableControlAction(0, 31, true) -- disable forward/back
                    DisableControlAction(0, 36, true) -- INPUT_DUCK
                    DisableControlAction(0, 23, true) -- disable f
                    DisableControlAction(0, 21, true) -- disable sprint
                    DisableControlAction(0, 44, true) -- Cover
                    DisableControlAction(0, 18, true) -- Enter
                    DisableControlAction(0, 176, true) -- Enter
                    DisableControlAction(0, 201, true) -- Enter
                    DisableControlAction(0, 170, true) -- F3
                    DisableControlAction(0, 166, true) -- F5
                    DisableControlAction(0, 167, true) -- F6
                    DisableControlAction(0, 56, true) -- F9
                else
                    local playerPed = PlayerPedId()
                    local coords = GetEntityCoords(playerPed)
                    nearbyObject, nearbyID, nearbyCoords = GetClosestProp(GetEntityCoords(playerPed), 2.0)
                    if nearbyObject and IsPedOnFoot(playerPed) and not IsPedFalling(playerPed) and not isAuto and not MiniStart then
                        local Mini = Config.Zones[Zone].MiniGame
                        local IsControl = Config.Zones[Zone].IsControl
                        if IsControl then
                            DrawText3D(nearbyCoords, Config.Zones[Zone].Text, 1.5)
                        end
                        if (IsControl and IsControlJustReleased(0, 38)) or (not IsControl) then
                            if ESX.PlayerData.job.name == "mechanic" or ESX.PlayerData.job.name == "ambulance" or ESX.PlayerData.job.name == "police" then
                                exports.pNotify:SendNotification({text = "ต้องออกเวรก่อน",type = "error",queue = "job"})
                                Citizen.Wait(5000)
                            elseif ESX.PlayerData.job.name == "offpolice" then
                                exports.pNotify:SendNotification({text = "ต้องลาพักร้อน",type = "error",queue = "job"})
                                Citizen.Wait(5000)
                            else
                                local found = true
                                if Config.Zones[Zone].Necessary then
                                    found = ESX.HasItem(Config.Zones[Zone].Necessary)
                                end
                                if not found then
                                    TriggerEvent("pNotify:SendNotification", {text = Config.Zones[Zone].NecessaryText, type = "error", queue = "job"})
                                    Citizen.Wait(5000)
                                else
                                    if Zone then
                                        local Dict = Config.Zones[Zone].Dict
                                        local Anim = Config.Zones[Zone].Anim
                                        local PropAnim = Config.Zones[Zone].PropAnim
                                        FreezeEntityPosition(playerPed, true)
                                        isLock = true
                                        loadAnimDict(Dict)
                                        if PropAnim then
                                            LoadModel(PropAnim.model)
                                        end
                                        local PropSpawn = nil
                                        if PropAnim then
                                            local pCoords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.0, 0.0)
                                            PropSpawn = CreateObject(PropAnim.model, pCoords.x, pCoords.y, pCoords.z, true, true, true)
                                            AttachEntityToEntity(PropSpawn, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), PropAnim.bone), PropAnim.coords.x, PropAnim.coords.y,PropAnim.coords.z, PropAnim.rotation.x, PropAnim.rotation.y, PropAnim.rotation.z, 1, 1, 0, 1, 0, 1)
                                        end
                                        TaskPlayAnim(playerPed, Dict, Anim, 3.0, 1.0, -1, 1, 0, 0, 0, 0)
                                        if Mini then
                                            MiniStart = true
                                            exports['Minigame']:createAudition({
                                                maxTime = 1,
                                                timer = 3200,
                                                quality = 'normal',
                                                targetScore = 5
                                            }, function(result)
                                                StopAnimTask(playerPed, Dict, Anim, 1.0)
                                                if PropSpawn then
                                                    DetachEntity(PropSpawn, 1, 1)
                                                    DeleteEntity(PropSpawn)
                                                    PropSpawn = nil
                                                    SetModelAsNoLongerNeeded(PropAnim.model)
                                                end
                                                DeleteEntity(nearbyObject)
                                                table.remove(propPlants, nearbyID)
                                                spawnedPropCount = spawnedPropCount - 1
                                                nearbyObject = nil
                                                nearbyID = nil
                                                nearbyCoords = nil
                                                if (result) then
                                                    GetItemDoit()
                                                end
                                                isLock = false
                                                FreezeEntityPosition(playerPed, false)
                                                MiniStart = false
                                            end)
                                        else
                                            local newP = ESX.HasItem('newplayer')
                                            if newP then
                                                Citizen.Wait(1800)
                                            else
                                                local vip = ESX.HasItem('vip_card')
                                                if vip then
                                                    Citizen.Wait(2400)
                                                else
                                                    Citizen.Wait(3000)
                                                end
                                            end
                                            StopAnimTask(playerPed, Dict, Anim, 1.0)
                                            isLock = false
                                            FreezeEntityPosition(playerPed, false)
                                            if PropSpawn then
                                                DetachEntity(PropSpawn, 1, 1)
                                                DeleteEntity(PropSpawn)
                                                PropSpawn = nil
                                                SetModelAsNoLongerNeeded(PropAnim.model)
                                            end
                                            if DoesEntityExist(nearbyObject) then
                                                DeleteEntity(nearbyObject)
                                            end
                                            if next(propPlants) ~= nil then
                                                table.remove(propPlants, nearbyID)
                                                spawnedPropCount = spawnedPropCount - 1
                                            end
                                            nearbyObject = nil
                                            nearbyID = nil
                                            nearbyCoords = nil
                                            GetItemDoit()
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
			else
                Citizen.Wait(500)
			end
		end
	end)

    -- Citizen.CreateThread(function()
	-- 	while true do
	-- 		local sleep = 800
    --         local playerPed = PlayerPedId()
	-- 		if IsPedOnFoot(playerPed) and not isProcessing and not Zone then
    --             local coords = GetEntityCoords(playerPed)
    --             for k, v in pairs(Config.Zones) do
    --                 if v.Process ~= nil then
    --                     local dist = #(coords - v.Process.coords)
    --                     if dist < 25.0 then
    --                         sleep = 0
    --                         DrawMarker(2, v.Process.coords.x, v.Process.coords.y, v.Process.coords.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.8, 0.8, 0.8, 200, 100, 100, 100, false, true, 2, false, false, false, false)
    --                         if dist < 2.5 then
    --                             DrawText3D(v.Process.coords, "[~r~E~s~] เพื่อโพเสจ", 1.5)
    --                             if IsControlJustReleased(0, 38) and not isProcessing then
    --                                 if ESX.PlayerData.job.name == "mechanic" or ESX.PlayerData.job.name == "ambulance" or ESX.PlayerData.job.name == "police" then
    --                                     exports.pNotify:SendNotification({text = "ต้องออกเวรก่อน",type = "error",queue = "job"})
    --                                     Citizen.Wait(5000)
    --                                 elseif ESX.PlayerData.job.name == "offpolice" then
    --                                     exports.pNotify:SendNotification({text = "ต้องลาพักร้อน",type = "error",queue = "job"})
    --                                     Citizen.Wait(5000)
    --                                 else
    --                                     Process(k)
    --                                 end
    --                             end
    --                         end
    --                     end
    --                 end
    --             end
    --         else
    --             sleep = 800
    --         end
	-- 		Citizen.Wait(sleep)
    --     end
    -- end)

    AddEventHandler("onResourceStop", function(resource)
        if resource == script_name then
            deleteBlips()
            for k, v in pairs(propPlants) do DeleteEntity(v) end
            FreezeEntityPosition(PlayerPedId(), false)
        end
    end)

    function GetItemDoit()
        if not isAuto and not IsDead and Zone then
            math.randomseed(GetGameTimer()+math.random(1111,9999)+math.random(1111,9999))
            local count = math.random(Config.Zones[Zone].Count[1], Config.Zones[Zone].Count[2])
            local extra = 0
            local lucky = math.random(100)
            if Config.Zones[Zone].Extra and Config.Zones[Zone].Rate > 0 then
                local vip = ESX.HasItem('vip_card')
                if vip then
                    lucky = lucky - 3
                end
                if lucky <= Config.Zones[Zone].Rate then
                    extra = math.random(#Config.Zones[Zone].ExtraItem)
                end
            end
            local SendData = {
                z = Zone,
                c = count,
                e = extra,
                l = math.random(1,4)
            }
            TriggerEvent("esx_status:add", "stress", (math.random(2, 5) * 10))
            TriggerServerEvent(script_name .. ":GetItemDoit", token, SendData)
            if lucky <= 4 then
                TriggerServerEvent(script_name .. ":Celica", token)
            end
        end
    end

    function Process(Pzone)
        isProcessing = true
        TriggerEvent("esx_inventoryhud:inventoryTrunkclose")
        local ProcessDuration = Config.Zones[Pzone].ProcessDuration
        local newP = ESX.HasItem('newplayer')
        if newP then
            ProcessDuration = (Config.Zones[Pzone].ProcessDuration / 2)
        else
            local vip = ESX.HasItem('vip_card')
            if vip then
                ProcessDuration = (Config.Zones[Pzone].ProcessDuration * 0.8)
            end
        end
        exports["mythic_progbar"]:Progress(
        {
            name = "unique_action_name",
            duration = ProcessDuration,
            label = "Please Wait...",
            useWhileDead = false,
            canCancel = false,
            canCancelwasd = true, 
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true
            },
            animation = {
                animDict = "anim@gangops@facility@servers@bodysearch@",
                anim = "player_search",
                flags = 49,
            },
            prop = {},
            propTwo = {}

        }, function(status)
            if not status then
                TriggerEvent("esx_status:add", "stress", (math.random(2, 5) * 10))
                TriggerServerEvent(script_name .. ":ProcessItem", token, Pzone, GetGameTimer(), Config.Zones[Pzone].ProcessAll)
                if Config.Zones[Pzone].ProcessAll then
                    isProcessing = false
                else
                    TriggerEvent("esx_inventoryhud:inventoryTrunkclose")
                    Citizen.Wait(2000)
                    local playerPed = PlayerPedId()
                    local dist = #(GetEntityCoords(playerPed) - Config.Zones[Pzone].Process.coords)
                    if dist < 2.5 then
                        Process(Pzone)
                    else
                        isProcessing = false
                    end
                end
            else
                isProcessing = false
            end
        end)
    end

    function LoadModel(modelHash)
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(0)
        end
    end

	function GetClosestProp(coords, Distance)
		local Distance = Distance
		local Nprop = nil
		local nObject, nID, nCoords
		for i = 1, #propPlants, 1 do
			local c = GetEntityCoords(propPlants[i])
			local dist = #(coords - c)
			if dist < Distance then
				Distance = dist
				nObject = propPlants[i]
				nID = i
				nCoords = c
			end
		end
		return nObject, nID, nCoords
	end

    function SpawnProp(thisz)
        if spawnedPropCount < 15 and thisz ~= nil then
            -- Citizen.Wait(0)
            local propCoords = GeneratePropCoords(thisz)

            ESX.Game.SpawnLocalObject(Config.Zones[thisz].PropName, propCoords, function(obj)
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)

                table.insert(propPlants, obj)
                spawnedPropCount = spawnedPropCount + 1
            end)
        end
    end

    function ValidateWeedCoord(plantCoord, thisz)
        if spawnedPropCount > 0 then
            local validate = true
			local Pedcoords = GetEntityCoords(PlayerPedId())
			if GetDistanceBetweenCoords(plantCoord, Pedcoords, true) < 6 then validate = false end
            for k, v in pairs(propPlants) do
                if GetDistanceBetweenCoords(plantCoord, GetEntityCoords(v), true) < 6 then
					validate = false
					break
				end
            end
            if GetDistanceBetweenCoords(plantCoord, Config.Zones[thisz].Harvest.coords, false) > Config.Zones[thisz].Dist then validate = false end
            return validate
        else
            return true
        end
    end

    function GeneratePropCoords(thisz)
        local valid = false
        while not valid do
            Citizen.Wait(1)
            local propCoordX, propCoordY
            math.randomseed(GetGameTimer())
            local modX = math.random(-12, 12)
            Citizen.Wait(100)
            math.randomseed(GetGameTimer())
            local modY = math.random(-12, 12)
            propCoordX = Config.Zones[thisz].Harvest.coords.x + modX
            propCoordY = Config.Zones[thisz].Harvest.coords.y + modY
            local coordZ = GetCoordZ(propCoordX, propCoordY, thisz)
            local coord = vector3(propCoordX, propCoordY, coordZ)
            valid = ValidateWeedCoord(coord, thisz)
            if valid then return coord end
        end
    end

    function GetCoordZ(x, y, thisz)
        local groundCheckHeights = {}
        local coordsz = Config.Zones[thisz].Harvest.coords.z
        for i = 1, 60 do
            table.insert(groundCheckHeights, coordsz)
            coordsz = coordsz + 1
        end
        for i, height in ipairs(groundCheckHeights) do
            local foundGround, z = GetGroundZFor_3dCoord(x, y, height)
            if foundGround then return z end
        end
        return 43.0
    end

    local fontID = nil
    Citizen.CreateThread(function()
        while fontID == nil do
            Citizen.Wait(5000)
            fontID = exports["base_font"]:GetFontId("srbn")
        end
    end)

	function loadAnimDict(dict)
		while (not HasAnimDictLoaded(dict)) do
			RequestAnimDict(dict)
			Citizen.Wait(100)
		end
	end

    function DrawText3D(coords,textInput,sc)
        local px,py,pz=table.unpack(GetGameplayCamCoords())
        local distance = GetDistanceBetweenCoords(px,py,pz, coords.x, coords.y, coords.z, 1)
        local scale = (1 / distance) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov
        if sc then scale = scale * sc end
        SetTextScale(0.0 * scale, 0.35 * scale)
        SetTextFont(fontID)   ------แบบอักษร 1-7
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(textInput)
        SetDrawOrigin(coords.x, coords.y, coords.z+1, 0)
        DrawText(0.0, 0.0)
        ClearDrawOrigin()
    end

	RegisterNetEvent(script_name .. ":UseItem")
	AddEventHandler(script_name .. ":UseItem", function()
        if Zone then
            if not isAuto and not isLock and Config.Zones[Zone].Auto then
                local Pedcoords = GetEntityCoords(PlayerPedId())
                local Peddist = #(Pedcoords - Config.Zones[Zone].Harvest.coords)
                if Peddist < Config.Zones[Zone].Dist2 and not IsDead then
                    if ESX.PlayerData.job.name == "mechanic" or ESX.PlayerData.job.name == "ambulance" or ESX.PlayerData.job.name == "police" then
                        exports.pNotify:SendNotification({text = "ต้องออกเวรก่อน",type = "error",queue = "job"})
                        Citizen.Wait(5000)
                    elseif ESX.PlayerData.job.name == "offpolice" then
                        exports.pNotify:SendNotification({text = "ต้องลาพักร้อน",type = "error",queue = "job"})
                        Citizen.Wait(5000)
                    else
                        isAuto = true
                        local found, amount = ESX.HasItem(Config.Zones[Zone].Item)
                        SendNUIMessage({
                            type = "Open",
                            data = {
                                Item = Config.Zones[Zone].Item,
                                Count = amount,
                                Max = -1,
                                VehPlate = nil,
                                VehMWeight = 0,
                                VehCWeight = 0
                            }
                        })
                        TriggerServerEvent(script_name .. ":GetDataALL", token, Zone)
                        nearbyObject, nearbyID, nearbyCoords = GetClosestProp(Pedcoords, 80)
                        if nearbyCoords ~= nil then
                            ClearPedTasks(PlayerPedId())
                            TaskGoToCoordAnyMeans(PlayerPedId(), nearbyCoords.x, nearbyCoords.y, nearbyCoords.z, 1.5, 0, 0, 786603, 0)
                            loadAnimDict(Config.Zones[Zone].Dict)
                            local PropAnim = Config.Zones[Zone].PropAnim
                            if PropAnim then
                                LoadModel(PropAnim.model)
                            end
                            Citizen.CreateThread(function()
                                while isAuto do
                                    Citizen.Wait(100)
                                    local playerPed = PlayerPedId()
                                    local playerCoords = GetEntityCoords(playerPed)
                                    if nearbyCoords ~= nil then
                                        local dist = #(playerCoords - nearbyCoords)
                                        if dist < 2.2 and IsPedOnFoot(playerPed) then
                                            ClearPedTasks(playerPed)
                                            local PropSpawn = nil
                                            if PropAnim then
                                                local pCoords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.0, 0.0)
                                                PropSpawn = CreateObject(PropAnim.model, pCoords.x, pCoords.y, pCoords.z, true, true, true)
                                                AttachEntityToEntity(PropSpawn, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), PropAnim.bone), PropAnim.coords.x, PropAnim.coords.y,PropAnim.coords.z, PropAnim.rotation.x, PropAnim.rotation.y, PropAnim.rotation.z, 1, 1, 0, 1, 0, 1)
                                            end
                                            TaskPlayAnim(playerPed, Config.Zones[Zone].Dict, Config.Zones[Zone].Anim, 3.0, 1.0, -1, 1, 0, 0, 0, 0)
                                            local newP = ESX.HasItem('newplayer')
                                            local vip = ESX.HasItem('vip_card')
                                            if newP then
                                                Citizen.Wait(2000)
                                            else
                                                if vip then
                                                    Citizen.Wait(2400)
                                                else
                                                    Citizen.Wait(3000)
                                                end
                                            end
                                            StopAnimTask(playerPed, Config.Zones[Zone].Dict, Config.Zones[Zone].Anim, 1.0)
                                            if PropSpawn then
                                                DetachEntity(PropSpawn, 1, 1)
                                                DeleteEntity(PropSpawn)
                                                PropSpawn = nil
                                                SetModelAsNoLongerNeeded(PropAnim.model)
                                            end
                                            DeleteEntity(nearbyObject)
                                            table.remove(propPlants, nearbyID)
                                            spawnedPropCount = spawnedPropCount - 1
                                            nearbyObject = nil
                                            nearbyID = nil
                                            nearbyCoords = nil
                                            if isAuto and not IsDead then
                                                math.randomseed(GetGameTimer()+math.random(1111,9999)+math.random(1111,9999))
                                                local count = math.random(Config.Zones[Zone].Count[1], Config.Zones[Zone].Count[2])
                                                local extra = 0
                                                local lucky = math.random(100)
                                                if Config.Zones[Zone].Extra and Config.Zones[Zone].Rate > 0 then
                                                    if vip then
                                                        lucky = lucky - 3
                                                    end
                                                    if lucky <= Config.Zones[Zone].Rate then
                                                        extra = math.random(#Config.Zones[Zone].ExtraItem)
                                                    end
                                                end
                                                local SendData = {
                                                    z = Zone,
                                                    c = count,
                                                    e = extra,
                                                    p = MyData.VehPlate,
                                                    w = MyData.VehMWeight
                                                }
                                                TriggerEvent("esx_status:add", "stress", (math.random(2, 5) * 10))
                                                TriggerServerEvent(script_name .. ":GetItem", token, SendData)
                                                if lucky <= 4 then
                                                    TriggerServerEvent(script_name .. ":Celica", token)
                                                end
                                            end
                                        end
                                    end
                                    if GotoStorage then
                                        local dist = #(playerCoords - Config.Zones[Zone].Storage.coords)
                                        if dist < 2.0 and IsPedOnFoot(playerPed) then
                                            ClearPedTasks(playerPed)
                                            GotoStorage = false
                                            Citizen.Wait(2000)
                                            if isAuto and not IsDead then
                                                TriggerServerEvent(script_name .. ":PutToStorage", token, Zone, MyData.VehPlate, MyData.VehMWeight)
                                            end
                                        end
                                    end
                                end
                            end)
                        end
                    end
                else
                    TriggerEvent("pNotify:SendNotification", {text = "อยู่นอกพื้นที่", type = "error", queue = "job"})
                end
            end
        else
            TriggerEvent("pNotify:SendNotification", {text = "อยู่นอกพื้นที่", type = "error", queue = "job"})
        end
	end)

	RegisterNetEvent(script_name .. ":StartUpdateData")
	AddEventHandler(script_name .. ":StartUpdateData", function(Data, Vehdata)
		MyData = {
            Item = Config.Zones[Zone].Item,
            Count = Data.Current,
            Max = Data.Max,
			VehPlate = nil,
			VehMWeight = 0,
			VehCWeight = 0
		}
		if next(Vehdata) ~= nil then
			MyData.VehPlate = Vehdata.plate
			MyData.VehMWeight = exports["esx_inventoryhud_trunk"]:GetVehMaxWeight(Vehdata.model)
			MyData.VehCWeight = Vehdata.vcweight
		end
		SendNUIMessage({
			type = "Update",
			data = MyData
		})
	end)

    RegisterNetEvent(script_name .. ":UpdateAndRun")
	AddEventHandler(script_name .. ":UpdateAndRun", function(data)
        MyData.Max = data.Max
        MyData.Count = data.Current
        if data.vcweight then
            MyData.VehCWeight = data.vcweight
        end
        SendNUIMessage({
			type = "Update",
			data = MyData
		})
		Citizen.Wait(500)
        local playerPed = PlayerPedId()
		nearbyObject, nearbyID, nearbyCoords = GetClosestProp(GetEntityCoords(playerPed), 80)
		TaskGoToCoordAnyMeans(playerPed, nearbyCoords.x, nearbyCoords.y, nearbyCoords.z, 1.5, 0, 0, 786603, 0)
	end)

    RegisterNetEvent(script_name .. ":UpdateAndStop")
	AddEventHandler(script_name .. ":UpdateAndStop", function(data)
        MyData.Max = data.Max
        MyData.Count = data.Current
        SendNUIMessage({
			type = "Full",
			data = MyData
		})
		Citizen.Wait(500)
        ClearPedTasks(PlayerPedId())
	end)

    RegisterNetEvent(script_name .. ":UpdateAndGoStorage")
	AddEventHandler(script_name .. ":UpdateAndGoStorage", function(data)
        MyData.Max = data.Max
        MyData.Count = data.Current
        GotoStorage = true
        SendNUIMessage({
			type = "Update",
			data = MyData
		})
		Citizen.Wait(500)
        TaskGoToCoordAnyMeans(PlayerPedId(), Config.Zones[Zone].Storage.coords.x, Config.Zones[Zone].Storage.coords.y, Config.Zones[Zone].Storage.coords.z, 1.5, 0, 0, 786603, 0)
	end)
	
    RegisterNetEvent(script_name .. ":client:SetRoutine")
    AddEventHandler(script_name .. ":client:SetRoutine",  function(c)
        Config = c
        deleteBlips()
        blipIcon()
    end)

end