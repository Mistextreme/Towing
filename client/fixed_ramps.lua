-- [esx-tow] client/fixed_ramps.lua
local FixedRamps = {
    deployedRamps = {}
}

function FixedRamps:DeployRamp(vehicle)
    local ped = PlayerPedId()
    local vehicleModel = GetEntityModel(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(vehicleModel)
    
    -- Verificar se o veículo tem rampa fixa
    if not Config.FixedRamps[modelName] then
        lib.notify({
            title = 'Sistema de Rampas Fixas',
            description = 'Este veículo não possui suporte para rampa fixa!',
            type = 'error'
        })
        return false
    end
    
    local config = Config.FixedRamps[modelName]
    
    -- Verificar se já tem uma rampa deployada
    if self.deployedRamps[vehicle] then
        lib.notify({
            title = 'Sistema de Rampas Fixas',
            description = 'Já existe uma rampa deployada para este veículo!',
            type = 'info'
        })
        return false
    end
    
    -- Carregar modelo da rampa
    RequestModel(config.rampModel)
    while not HasModelLoaded(config.rampModel) do
        Citizen.Wait(100)
    end
    
    -- Criar rampa
    local spawnCoords = GetOffsetFromEntityInWorldCoords(vehicle, config.deployOffset)
    local ramp = CreateObject(config.rampModel, spawnCoords, true, false, false)
    
    -- Anexar à veículo
    AttachEntityToEntity(ramp, vehicle, GetEntityBoneIndexByName(vehicle, config.deployBone), 
                        config.deployOffset.x, config.deployOffset.y, config.deployOffset.z,
                        config.deployRotation.x, config.deployRotation.y, config.deployRotation.z, 
                        0, 0, 1, 0, 0, 1)
    
    -- Registrar rampa
    self.deployedRamps[vehicle] = ramp
    
    lib.notify({
        title = 'Sistema de Rampas Fixas',
        description = 'Rampa fixa deployada com sucesso!',
        type = 'success'
    })
    
    return true
end

function FixedRamps:RetractRamp(vehicle)
    if not self.deployedRamps[vehicle] then
        lib.notify({
            title = 'Sistema de Rampas Fixas',
            description = 'Não existe rampa deployada para este veículo!',
            type = 'info'
        })
        return false
    end
    
    -- Remover rampa
    DeleteEntity(self.deployedRamps[vehicle])
    self.deployedRamps[vehicle] = nil
    
    lib.notify({
        title = 'Sistema de Rampas Fixas',
        description = 'Rampa fixa recolhida com sucesso!',
        type = 'success'
    })
    
    return true
end

-- Comandos
RegisterCommand('deployfixedramp', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not IsPlayerAuthorized() then
        lib.notify({
            title = 'Sistema de Rampas Fixas',
            description = Config.Locale.notAuthorized,
            type = 'error'
        })
        return
    end
    
    if not DoesEntityExist(vehicle) then
        lib.notify({
            title = 'Sistema de Rampas Fixas',
            description = Config.Locale.notInVehicle,
            type = 'error'
        })
        return
    end
    
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        lib.notify({
            title = 'Sistema de Rampas Fixas',
            description = Config.Locale.notDriver,
            type = 'error'
        })
        return
    end
    
    FixedRamps:DeployRamp(vehicle)
end, false)

RegisterCommand('retractfixedramp', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not IsPlayerAuthorized() then
        lib.notify({
            title = 'Sistema de Rampas Fixas',
            description = Config.Locale.notAuthorized,
            type = 'error'
        })
        return
    end
    
    if not DoesEntityExist(vehicle) then
        lib.notify({
            title = 'Sistema de Rampas Fixas',
            description = Config.Locale.notInVehicle,
            type = 'error'
        })
        return
    end
    
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        lib.notify({
            title = 'Sistema de Rampas Fixas',
            description = Config.Locale.notDriver,
            type = 'error'
        })
        return
    end
    
    FixedRamps:RetractRamp(vehicle)
end, false)