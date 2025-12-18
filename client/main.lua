-- [esx-tow] client/main.lua
ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

-- Verificar autorização
function IsPlayerAuthorized()
    local playerData = ESX.GetPlayerData()
    return playerData.job and table.contains(Config.AuthorizedJobs, playerData.job.name)
end

-- Carregar módulos
Citizen.CreateThread(function()
    -- Inicializar sistemas
    lib.registerContext({
        id = 'tow_menu',
        title = 'Menu de Reboque',
        options = {
            {
                title = 'Deployar Rampa',
                description = 'Deployar rampa móvel',
                icon = 'truck-ramp-box',
                onSelect = function()
                    local ped = PlayerPedId()
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if DoesEntityExist(vehicle) then
                        MovableRamps:DeployRamp(vehicle)
                    end
                end
            },
            {
                title = 'Recolher Rampa',
                description = 'Recolher rampa móvel',
                icon = 'truck-ramp-box',
                onSelect = function()
                    local ped = PlayerPedId()
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if DoesEntityExist(vehicle) then
                        MovableRamps:RetractRamp(vehicle)
                    end
                end
            },
            {
                title = 'Deployar Rampa Fixa',
                description = 'Deployar rampa fixa',
                icon = 'square-arrow-up-right',
                onSelect = function()
                    local ped = PlayerPedId()
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if DoesEntityExist(vehicle) then
                        FixedRamps:DeployRamp(vehicle)
                    end
                end
            },
            {
                title = 'Recolher Rampa Fixa',
                description = 'Recolher rampa fixa',
                icon = 'square-arrow-up-right',
                onSelect = function()
                    local ped = PlayerPedId()
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if DoesEntityExist(vehicle) then
                        FixedRamps:RetractRamp(vehicle)
                    end
                end
            },
            {
                title = 'Rebocar Veículo',
                description = 'Attachar veículo próximo',
                icon = 'link',
                onSelect = function()
                    local ped = PlayerPedId()
                    local towVehicle = GetVehiclePedIsIn(ped, false)
                    if DoesEntityExist(towVehicle) then
                        local targetVehicle = AttachSystem:GetClosestVehicleToAttach(towVehicle)
                        if targetVehicle then
                            AttachSystem:AttachToRamp(towVehicle, targetVehicle)
                        end
                    end
                end
            },
            {
                title = 'Desprender Veículo',
                description = 'Detachar veículo',
                icon = 'unlink',
                onSelect = function()
                    local ped = PlayerPedId()
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if DoesEntityExist(vehicle) then
                        AttachSystem:DetachVehicle(vehicle)
                    end
                end
            },
            {
                title = 'Usar Guincho',
                description = 'Usar sistema de guincho',
                icon = 'anchor',
                onSelect = function()
                    WinchSystem:StartCable()
                end
            },
            {
                title = 'Modo de Edição',
                description = 'Configurar veículos por laser',
                icon = 'wrench',
                onSelect = function()
                    Editor:Open()
                end
            }
        }
    })
    
    -- Comando para abrir menu
    RegisterCommand('towmenu', function()
        if IsPlayerAuthorized() then
            lib.showContext('tow_menu')
        else
            lib.notify({
                title = 'Menu de Reboque',
                description = Config.Locale.notAuthorized,
                type = 'error'
            })
        end
    end, false)
end)