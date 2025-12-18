-- [esx-tow] server/main.lua
ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

-- Configurações salvas
local savedConfigs = {}

-- Eventos
RegisterNetEvent('esx-tow:saveEditorConfig')
AddEventHandler('esx-tow:saveEditorConfig', function(configData)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer and table.contains(Config.AuthorizedJobs, xPlayer.job.name) then
        savedConfigs[configData.vehicle.model] = configData
        
        lib.notify(source, {
            title = 'Editor de Veículos',
            description = Config.Locale.editorSaved,
            type = 'success'
        })
        
        -- Salvar no banco de dados
        MySQL.Async.execute('INSERT INTO tow_configs (model, config_data) VALUES (@model, @config) ON DUPLICATE KEY UPDATE config_data = @config', {
            ['@model'] = configData.vehicle.model,
            ['@config'] = json.encode(configData)
        })
    end
end)

-- Carregar configurações do banco
Citizen.CreateThread(function()
    local result = MySQL.Sync.fetchAll('SELECT * FROM tow_configs')
    
    for _, config in ipairs(result) do
        savedConfigs[config.model] = json.decode(config.config_data)
    end
end)

-- Comando para administradores
ESX.RegisterCommand('towadmin', 'admin', function(xPlayer, args, showError)
    TriggerClientEvent('esx-tow:openAdminMenu', args.playerId)
end, true, {help = 'Menu administrativo de reboque', validate = true, arguments = {
    {name = 'playerId', help = 'ID do jogador', type = 'player'}
}})