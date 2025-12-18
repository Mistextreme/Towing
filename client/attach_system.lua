-- [esx-tow] client/attach_system.lua
local AttachSystem = {
    attachedVehicles = {}
}

function AttachSystem:AttachToRamp(towVehicle, targetVehicle)
    local ped = PlayerPedId()
    
    -- Verificar distância
    local distance = #(GetEntityCoords(towVehicle) - GetEntityCoords(targetVehicle))
    if distance > Config.Attach.maxDistance then
        lib.notify({
            title = 'Sistema de Attach',
            description = 'Veículo muito distante para ser rebocado!',
            type = 'error'
        })
        return false
    end
    
    -- Verificar tipo de veículo
    local towModel = GetDisplayNameFromVehicleModel(GetEntityModel(towVehicle))
    local towConfig = Config.MovableRamps[towModel] or Config.FixedRamps[towModel]
    
    if not towConfig then
        lib.notify({
            title = 'Sistema de Attach',
            description = 'Este veículo não suporta reboque!',
            type = 'error'
        })
        return false
    end
    
    -- Verificar se já está attachado
    if IsEntityAttached(targetVehicle) then
        lib.notify({
            title = 'Sistema de Attach',
            description = Config.Locale.vehicleAlreadyAttached,
            type = 'info'
        })
        return false
    end
    
    -- Calcular posição de attach
    local attachOffset = towConfig.attachOffset or vec3(0.0, -2.0, Config.Attach.defaultHeight)
    local towCoords = GetEntityCoords(towVehicle)
    local towRotation = GetEntityRotation(towVehicle, 2)
    
    -- Posicionar veículo no ponto de attach
    local attachPosition = GetOffsetFromEntityInWorldCoords(towVehicle, attachOffset)
    SetEntityCoords(targetVehicle, attachPosition)
    
    -- Obter bone de attach
    local attachBone = GetEntityBoneIndexByName(towVehicle, towConfig.attachBone or 'chassis')
    
    -- Attachar veículo
    AttachEntityToEntity(targetVehicle, towVehicle, attachBone, 
                        attachOffset.x, attachOffset.y, attachOffset.z,
                        0.0, 0.0, 0.0, false, false, true, false, 0, true)
    
    -- Nivelar veículo se necessário
    if Config.Attach.autoLevel then
        SetEntityRotation(targetVehicle, vec3(0.0, 0.0, towRotation.z))
    end
    
    -- Registrar attach
    self.attachedVehicles[targetVehicle] = {
        towVehicle = towVehicle,
        config = towConfig,
        offset = attachOffset
    }
    
    -- Para rampas móveis, registrar no sistema de rampas
    if Config.MovableRamps[towModel] and MovableRamps.rampStates[towVehicle] then
        table.insert(MovableRamps.rampStates[towVehicle].attachedVehicles, targetVehicle)
    end
    
    lib.notify({
        title = 'Sistema de Attach',
        description = Config.Locale.attachSuccess,
        type = 'success'
    })
    
    return true
end

function AttachSystem:DetachVehicle(vehicle)
    if not IsEntityAttached(vehicle) then
        lib.notify({
            title = 'Sistema de Attach',
            description = 'Este veículo não está attachado!',
            type = 'info'
        })
        return false
    end
    
    DetachEntity(vehicle, true, true)
    
    -- Remover dos registros
    if self.attachedVehicles[vehicle] then
        local towVehicle = self.attachedVehicles[vehicle].towVehicle
        self.attachedVehicles[vehicle] = nil
        
        -- Remover do sistema de rampas móveis
        if MovableRamps.rampStates[towVehicle] then
            local attachedVehicles = MovableRamps.rampStates[towVehicle].attachedVehicles
            for i, v in ipairs(attachedVehicles) do
                if v == vehicle then
                    table.remove(attachedVehicles, i)
                    break
                end
            end
        end
    end
    
    lib.notify({
        title = 'Sistema de Attach',
        description = Config.Locale.detachSuccess,
        type = 'success'
    })
    
    return true
end

function AttachSystem:GetClosestVehicleToAttach(towVehicle)
    local towCoords = GetEntityCoords(towVehicle)
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = Config.Attach.maxDistance + 5.0
    local closestVehicle = nil
    
    for _, vehicle in ipairs(vehicles) do
        if vehicle ~= towVehicle and not IsEntityAttached(vehicle) then
            local distance = #(GetEntityCoords(vehicle) - towCoords)
            if distance < closestDistance then
                closestDistance = distance
                closestVehicle = vehicle
            end
        end
    end
    
    return closestVehicle
end

-- Comandos de attach/detach
RegisterCommand('attach', function()
    local ped = PlayerPedId()
    local towVehicle = GetVehiclePedIsIn(ped, false)
    
    if not IsPlayerAuthorized() then
        lib.notify({
            title = 'Sistema de Attach',
            description = Config.Locale.notAuthorized,
            type = 'error'
        })
        return
    end
    
    if not DoesEntityExist(towVehicle) then
        lib.notify({
            title = 'Sistema de Attach',
            description = Config.Locale.notInVehicle,
            type = 'error'
        })
        return
    end
    
    if GetPedInVehicleSeat(towVehicle, -1) ~= ped then
        lib.notify({
            title = 'Sistema de Attach',
            description = Config.Locale.notDriver,
            type = 'error'
        })
        return
    end
    
    local targetVehicle = AttachSystem:GetClosestVehicleToAttach(towVehicle)
    
    if targetVehicle then
        AttachSystem:AttachToRamp(towVehicle, targetVehicle)
    else
        lib.notify({
            title = 'Sistema de Attach',
            description = Config.Locale.noVehicleNearby,
            type = 'error'
        })
    end
end, false)

RegisterCommand('detach', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not IsPlayerAuthorized() then
        lib.notify({
            title = 'Sistema de Attach',
            description = Config.Locale.notAuthorized,
            type = 'error'
        })
        return
    end
    
    if not DoesEntityExist(vehicle) then
        lib.notify({
            title = 'Sistema de Attach',
            description = Config.Locale.notInVehicle,
            type = 'error'
        })
        return
    end
    
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        lib.notify({
            title = 'Sistema de Attach',
            description = Config.Locale.notDriver,
            type = 'error'
        })
        return
    end
    
    AttachSystem:DetachVehicle(vehicle)
end, false)