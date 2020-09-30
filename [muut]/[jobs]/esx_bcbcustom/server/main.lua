ESX = nil
local Vehicles

TriggerEvent('tac:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('tac_bcbcustom:buyMod')
AddEventHandler('tac_bcbcustom:buyMod', function(price)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	price = tonumber(price)

	if Config.IsbcbJobOnly then
		local societyAccount

		TriggerEvent('tac_addonaccount:getSharedAccount', 'society_bcb', function(account)
			societyAccount = account
		end)

		if price < societyAccount.money then
			TriggerClientEvent('tac_bcbcustom:installMod', _source)
			TriggerClientEvent('tac:showNotification', _source, _U('purchased'))
			societyAccount.removeMoney(price)
		else
			TriggerClientEvent('tac_bcbcustom:cancelInstallMod', _source)
			TriggerClientEvent('tac:showNotification', _source, _U('not_enough_money'))
		end
	else
		if price < xPlayer.getMoney() then
			TriggerClientEvent('tac_bcbcustom:installMod', _source)
			TriggerClientEvent('tac:showNotification', _source, _U('purchased'))
			xPlayer.removeMoney(price)
		else
			TriggerClientEvent('tac_bcbcustom:cancelInstallMod', _source)
			TriggerClientEvent('tac:showNotification', _source, _U('not_enough_money'))
		end
	end
end)

RegisterServerEvent('tac_bcbcustom:refreshOwnedVehicle')
AddEventHandler('tac_bcbcustom:refreshOwnedVehicle', function(vehicleProps)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT vehicle FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = vehicleProps.plate
	}, function(result)
		if result[1] then
			local vehicle = json.decode(result[1].vehicle)

			if vehicleProps.model == vehicle.model then
				MySQL.Async.execute('UPDATE owned_vehicles SET vehicle = @vehicle WHERE plate = @plate', {
					['@plate'] = vehicleProps.plate,
					['@vehicle'] = json.encode(vehicleProps)
				})
			else
				print(('esx_bcbcustom: %s attempted to upgrade vehicle with mismatching vehicle model!'):format(xPlayer.identifier))
			end
		end
	end)
end)

ESX.RegisterServerCallback('tac_bcbcustom:getVehiclesPrices', function(source, cb)
	if not Vehicles then
		MySQL.Async.fetchAll('SELECT * FROM vehicles', {}, function(result)
			local vehicles = {}

			for i=1, #result, 1 do
				table.insert(vehicles, {
					model = result[i].model,
					price = result[i].price
				})
			end

			Vehicles = vehicles
			cb(Vehicles)
		end)
	else
		cb(Vehicles)
	end
end)