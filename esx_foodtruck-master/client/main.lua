ESX = nil
local PlayerData, CurrentActionData = {}, {}
local LastZone, CurrentAction, CurrentActionMsg, FoodInPlace
local OnJob, Cooking, HasAlreadyEnteredMarker = false, false, false
local myPlate = {}
local IsAnimated = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

function OpenCookingMenu(grill)
	local elements = {
		head = {_U('recipe'), _U('ingredients'), _U('action')},
		rows = {}
	}

	for k,v in pairs(Config.Recipes) do
		local ingredients = ""

		for l,w in pairs(v.Ingredients) do
			ingredients = ingredients .. " - " .. w[1] .. " (" .. w[2] .. ")"
		end

		table.insert(elements.rows,
		{
			data = v,
			cols = {
				v.Name,
				ingredients,
				'{{' .. _U('cook') .. '|cook}}'
			}
		})
	end

	ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'foodtruck',
		elements,
		function(data, menu)
			if data.value == 'cook' then
				if not Cooking then					
					ESX.TriggerServerCallback('esx_foodtruck:getStock', function(fridge)
						local enoughStock = false
						for k,v in pairs(data.data.Ingredients) do
							--TriggerServerEvent('esx:clientLog', 'in recipe looking at ' .. k)
							for i=1, #fridge, 1 do
								--TriggerServerEvent('esx:clientLog', 'in fridge looking at ' .. fridge[i].name)
								if fridge[i].name == k then
									--TriggerServerEvent('esx:clientLog', 'enough ?')
									if fridge[i].count >= v[2] then
										--TriggerServerEvent('esx:clientLog', 'enough ' .. k)
										enoughStock = true
									else
										--TriggerServerEvent('esx:clientLog', 'not enough ' .. k)
										enoughStock = false
									end
									break
								end
							end
							if not enoughStock then
								break
							end
						end
						if enoughStock then
							for k,v in pairs(data.data.Ingredients) do
								TriggerServerEvent('esx_foodtruck:removeItem', k, v[2])
							end
							Cooking = true						

							local coords  = GetEntityCoords(grill)
							local x, y, z = table.unpack(coords)

							ESX.Game.SpawnObject('prop_cs_steak', {
								x = x,
								y = y,
								z = z + 0.93
							}, function(steak)
								
								-- BBQing Animation
								local animationdictionary  = 'amb@prop_human_bbq@male@base'
								local animationName  = "base"
								RequestAnimDict(animationdictionary )
								while not HasAnimDictLoaded(animationdictionary ) do 
									 Citizen.Wait(0) 
								end   
								local _duration =  data.data.CookingTime 
								
								if not IsAnimated then 
									IsAnimated = true
									local playerPed		= GetPlayerPed(-1) 
									 
									TaskPlayAnim(playerPed, animationdictionary  , animationName ,8.0, -8.0, -1, 1, 0, false, false, false )	
									-- Mythic Progress Bar 
									TriggerEvent("mythic_progressbar:client:progress",  {
										name = "CookingProgress",
										duration = _duration,
										label = "Food Preperation In Progress",
										useWhileDead = false,
										canCancel = true,
										controlDisables = {
											disableMovement = true,
											disableCarMovement = true,
											disableMouse = false,
											disableCombat = true,
										},
										animation = {
											animDict = animationdictionary,
											anim = animationName, 
										},
									}, function(status)
										if not status then
											cancel = false
											exports.pNotify:SendNotification({
												text = (_U('cooked')), 
												type = "success", 
												timeout = 1000, 
												layout = "centerRight", 
												queue = "right",
												killer = false,
												animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}
											}) 
											 
											DeleteEntity(steak)
											local xF 		= GetEntityForwardX(grill) * 1.0
											local yF 		= GetEntityForwardY(grill) * 1.0
											local model = nil

											if data.data.Item == 'tacos' then
												model = 'prop_taco_01'
											elseif data.data.Item == 'burger' then
												model = 'prop_cs_burger_01'
											end

											local heading = GetEntityHeading(grill)

											local foodDistance = 0.7
		
											local angle = heading * math.pi / 180.0
											local theta = {
												x = math.cos(angle),
												y = math.sin(angle)
											}
											local pos = {
												x = coords.x + (foodDistance * theta.x),
												y = coords.y + (foodDistance * theta.y),
											}
		
											ESX.Game.SpawnObject(model, {
												x = pos.x,
												y = pos.y,
												z = z + 0.93
											}, function(food)
												local id = NetworkGetNetworkIdFromEntity(food)
												--TriggerServerEvent('esx:clientLog', 'creating entity netID: ' .. tostring(id))
												TriggerServerEvent('esx_foodtruck:placeFood', id)
												SetNetworkIdCanMigrate(id, true)
												FoodInPlace = food
											end)
 
											Cooking = false

											IsAnimated = false
										else 
											cancel = true
										end 
									end)
								end 
 
							end)
							
						else
							ESX.ShowNotification(_U('missing_ingredients'))
						end
					end)
				else
					ESX.ShowNotification(_U('already_cooking'))
				end
			end
			menu.close()
			CurrentAction     = 'foodtruck_cook'
			CurrentActionMsg  = _U('start_cooking_hint')
			CurrentActionData = {}
		end, function(data, menu)

			menu.close()
			CurrentAction     = 'foodtruck_cook'
			CurrentActionMsg  = _U('start_cooking_hint')
			CurrentActionData = {}
		end)
end

function OpenFoodTruckActionsMenu()
	local elements = {
		{label = _U('vehicle_list'), 	value = 'vehicle_list'} 
	}
  
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'foodtruck_actions', {
			title    = _U('blip_foodtruck'),
			elements = elements
		}, function(data, menu)

			if data.current.value == 'vehicle_list' then
				local elements = {
					{label = 'FoodTruck', value = 'taco'}
				}

				ESX.UI.Menu.CloseAll()

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_vehicle', {
						title    = _U('vehicles'),
						elements = elements
					}, function(data, menu)
						
						local playerPed = GetPlayerPed(-1)
						
						local coords    = Config.Zones.VehicleSpawnPoint.Pos

						if ESX.Game.IsSpawnPointClear(coords, 5.0) then
							ESX.Game.SpawnVehicle(data.current.value, coords, 230.0, function(vehicle)
								-- save & set plate
								local plate     = 'WORK' .. math.random(100, 900)
								SetVehicleNumberPlateText(vehicle, plate)
								table.insert(myPlate, plate)
								plate = string.gsub(plate, " ", "")

								TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
							end)
						else
							ESX.ShowNotification(_U('spawn_blocked'))
						end	

						ESX.UI.Menu.CloseAll()
					end,function(data, menu)
						menu.close()
					end)
					
				
			end 
		 
		end, function(data, menu)
			menu.close()
			CurrentAction     = 'foodtruck_actions_menu'
			CurrentActionMsg  = _U('foodtruck_actions_menu')
			CurrentActionData = {}
		end)
end
 

RegisterNetEvent('esx_foodtruck:refreshMarket')
AddEventHandler('esx_foodtruck:refreshMarket', function()
	OpenFoodTruckMarketMenu()
end)

function OpenFoodTruckMarketMenu()
	if PlayerData.job ~= nil and PlayerData.job.grade_name == 'cook' then
		ESX.TriggerServerCallback('esx_foodtruck:getStock', function(fridge, MarketPrices)
			local elements = {
				head = {_U('ingredients'), _U('price_unit'), _U('on_you'), _U('action')},
				rows = {}
			}

			local itemName = nil
			local price = nil

			for j=1, #MarketPrices, 1 do

				for i=1, #fridge, 1 do
					if fridge[i].name == MarketPrices[j].item then
						table.insert(elements.rows,
						{
							data = fridge[i],
							cols = {
								MarketPrices[j].label,
								MarketPrices[j].price,
								tostring(fridge[i].count),
								'{{' .. _U('buy_10') .. '|buy10}} {{' .. _U('buy_50') .. '|buy50}}'
							}
						})

						break
					end
				end
			end

			ESX.UI.Menu.CloseAll()

			ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'foodtruck', elements,
				function(data, menu)
					if data.value == 'buy10' then
						TriggerServerEvent('esx_foodtruck:buyItem', 10, data.data.name)
					elseif data.value == 'buy50' then
						TriggerServerEvent('esx_foodtruck:buyItem', 50, data.data.name)
					end
					menu.close()
				end, function(data, menu)
					menu.close()
					CurrentAction     = 'foodtruck_market_menu'
					CurrentActionMsg  = _U('foodtruck_market_menu')
					CurrentActionData = {}
				end)
		end)
	else
		ESX.ShowNotification(_U('need_more_exp'))
	end
end

function OpenFoodTruckBilling()
	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
			title = _U('bill_amount')
		}, function(data, menu)

			local amount = tonumber(data.value)

			if amount == nil then
				ESX.ShowNotification(_U('invalid_amount'))
			else							
				menu.close()							
				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer == -1 or closestDistance > 3.0 then
					ESX.ShowNotification(_U('no_player_nearby'))
				else
					TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_foodtruck', 'RasTacos', amount)
				end
			end
		end, function(data, menu)
		menu.close()
	end)
end

function OpenMobileFoodTruckActionsMenu()

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_foodtruck_actions', {
			title    = _U('blip_foodtruck'),
			align    = 'top-left',
			elements = { 
				{label = _U('gears'), 	value = 'gears'}
			}
		}, function(data, menu)
			if data.current.value == 'cook' then
				OpenCookingMenu()
			elseif data.current.value == 'gears' then
				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'foodtruck_gears', {
						title    = _U('gear'),
						align    = 'top-left',
						elements = {
							{label = _U('grill'), 	value = 'prop_bbq_5'},
							{label = _U('table'), 	value = 'prop_table_para_comb_02'},
							{label = _U('chair'), 	value = 'prop_table_03_chr'}, 
		  					{label = _U('clean'),   value = 'clean'}
						},
					}, function(data, menu)

						if data.current.value ~= 'clean' then
							local playerPed = GetPlayerPed(-1)							
							local x, y, z   = table.unpack(GetEntityCoords(playerPed))
							local xF = GetEntityForwardX(playerPed) * 1.0
							local yF = GetEntityForwardY(playerPed) * 1.0

							ESX.Game.SpawnObject(data.current.value, {
								x = x + xF,
								y = y + yF,
								z = z
							}, function(obj)
								-- chairs
								if data.current.value == 'prop_table_03_chr' then
									SetEntityHeading(obj, -GetEntityHeading(playerPed))
								else
									SetEntityHeading(obj, GetEntityHeading(playerPed))
								end
								PlaceObjectOnGroundProperly(obj)
							end)

							menu.close()
						else
							local obj, dist = ESX.Game.GetClosestObject({'prop_bbq_5', 'prop_table_para_comb_02', 'prop_table_03_chr'})
							if dist < 3.0 then
								DeleteEntity(obj)
							else
								ESX.ShowNotification(_U('clean_too_far'))
							end
						end
					end, function(data, menu)
						menu.close()
					end)
			end
		end, function(data, menu)
			menu.close()
		end)
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
	myPlate = {}  
end)

AddEventHandler('esx_foodtruck:hasEnteredMarker', function(zone) 
	if zone == 'Actions' then
		CurrentAction     = 'foodtruck_actions_menu'
		CurrentActionMsg  = _U('foodtruck_menu')
		CurrentActionData = {}
	end
	if zone == 'Market' then
		CurrentAction     = 'foodtruck_market'
		CurrentActionMsg  = _U('foodtruck_market_menu')
		CurrentActionData = {}
	end
	if zone == 'VehicleDeleter' then
		local playerPed = GetPlayerPed(-1)
		if IsPedInAnyVehicle(playerPed,  false) then
			CurrentAction     = 'delete_vehicle'
			CurrentActionMsg  = _U('store_veh')
			CurrentActionData = {}
		end
	end
end)

AddEventHandler('esx_foodtruck:hasExitedMarker', function(zone)
	CurrentAction = nil
	ESX.UI.Menu.CloseAll()
end)
 

-- Create Blips
Citizen.CreateThread(function()		
	local blip = AddBlipForCoord(Config.Zones.Actions.Pos.x, Config.Zones.Actions.Pos.y, Config.Zones.Actions.Pos.z)
	SetBlipSprite (blip, 479)
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, 1.0)
	SetBlipColour (blip, 5)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(_U('blip_foodtruck'))
	EndTextCommandSetBlipName(blip)

	blip = AddBlipForCoord(Config.Zones.Market.Pos.x, Config.Zones.Market.Pos.y, Config.Zones.Market.Pos.z)
	SetBlipSprite (blip, 52)
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, 1.0)
	SetBlipColour (blip, 5)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(_U('blip_market'))
	EndTextCommandSetBlipName(blip)
end)

-- Display markers
Citizen.CreateThread(function()
	while true do
		Wait(0)
		if PlayerData.job ~= nil and PlayerData.job.name == 'foodtruck' then
			local coords = GetEntityCoords(GetPlayerPed(-1))

			for k,v in pairs(Config.Zones) do
				if(v.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
					DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, true, 2, false, false, false, false)
				end
			end
		end
	end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
	while true do
		Wait(0)
		if PlayerData.job ~= nil and PlayerData.job.name == 'foodtruck' then
			local coords      = GetEntityCoords(GetPlayerPed(-1))
			local isInMarker  = false
			local currentZone = nil
			for k,v in pairs(Config.Zones) do
				if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < v.Size.x) then
					isInMarker  = true
					currentZone = k
				end
			end
			if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
				HasAlreadyEnteredMarker = true
				LastZone                = currentZone
				TriggerEvent('esx_foodtruck:hasEnteredMarker', currentZone)
			end
			if not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_foodtruck:hasExitedMarker', LastZone)
			end
		end
	end
end)

AddEventHandler('esx_foodtruck:hasEnteredEntityZone', function(entity)

	if PlayerData.job ~= nil and PlayerData.job.name == 'foodtruck' then

		if GetEntityModel(entity) == GetHashKey('prop_bbq_5') then
			CurrentAction     = 'foodtruck_cook'
			CurrentActionMsg  = _U('start_cooking_hint')
			CurrentActionData = {entity = entity}
		end

		if GetEntityModel(entity) == GetHashKey('prop_cs_burger_01') then
			CurrentAction     = 'foodtruck_client_burger'
			CurrentActionMsg  = _U('take') .. ' ' .. _U('burger')
			CurrentActionData = {entity = entity, item = 'burger'}
		end

		if GetEntityModel(entity) == GetHashKey('prop_taco_01') then
			CurrentAction     = 'foodtruck_client_tacos'
			CurrentActionMsg  = _U('take') .. ' ' .. _U('tacos')
			CurrentActionData = {entity = entity, item = 'tacos'}
		end

	end

end)

AddEventHandler('esx_foodtruck:hasExitedEntityZone', function(entity)
	CurrentAction = nil
end)

-- Enter / Exit entity zone events
Citizen.CreateThread(function()

	local trackedEntities = {
		'prop_bbq_5',
		'prop_table_para_comb_02',
		'prop_table_03_chr',
		'prop_cs_burger_01',
		'prop_taco_01'
	}

	while true do

		Citizen.Wait(0)

		local playerPed = GetPlayerPed(-1)
		local coords    = GetEntityCoords(playerPed)

		local closestDistance = -1
		local closestEntity   = nil

		for i=1, #trackedEntities, 1 do

			local object = GetClosestObjectOfType(coords.x,  coords.y,  coords.z,  3.0,  GetHashKey(trackedEntities[i]), false, false, false)

			if DoesEntityExist(object) then

				local objCoords = GetEntityCoords(object)
				local distance  = GetDistanceBetweenCoords(coords.x,  coords.y,  coords.z,  objCoords.x,  objCoords.y,  objCoords.z,  true)

				if closestDistance == -1 or closestDistance > distance then
					closestDistance = distance
					closestEntity   = object
				end
			end
		end

		if closestDistance ~= -1 and closestDistance <= 3.0 then

 			if LastEntity ~= closestEntity then
 				TriggerEvent('esx_basicneeds:isEating', function(isEating)
 					if not isEating then
						TriggerEvent('esx_foodtruck:hasEnteredEntityZone', closestEntity)
					end
				end)
				LastEntity = closestEntity
			end

		else

			if LastEntity ~= nil then
				TriggerEvent('esx_foodtruck:hasExitedEntityZone', LastEntity)
				LastEntity = nil
			end
		end
	end
end)

-- Key Controls
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if CurrentAction ~= nil then
            SetTextComponentFormat('STRING')
            AddTextComponentString(CurrentActionMsg)
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
			
			--Control Pressed E 
            if IsControlJustReleased(0, 38) and PlayerData.job ~= nil and PlayerData.job.name == 'foodtruck' then
 
                if CurrentAction == 'foodtruck_actions_menu' then
                    OpenFoodTruckActionsMenu()
                elseif CurrentAction == 'foodtruck_market' then
                    OpenFoodTruckMarketMenu()
                elseif CurrentAction == 'foodtruck_cook' then
                    OpenCookingMenu(CurrentActionData.entity)
				elseif CurrentAction == 'delete_vehicle' then
					local playerPed = PlayerPedId(-1) 

					if IsPedInAnyVehicle(playerPed, false) then
						local vehicle 	= GetVehiclePedIsIn(playerPed, false)
						local plate 	= GetVehicleNumberPlateText(vehicle)
						plate 			= string.gsub(plate, " ", "")
						local driverPed = GetPedInVehicleSeat(vehicle, -1) 
						local hash      = GetEntityModel(vehicle)

						if playerPed == driverPed then 
							for i=1, #myPlate, 1 do
								if myPlate[i] == plate then
									if hash == GetHashKey('taco') then
										if Config.MaxInService ~= -1 then
											TriggerServerEvent('esx_service:disableService', 'foodtruck')
										end
										DeleteVehicle(vehicle)

										table.remove(myPlate, i)
									else
										ESX.ShowNotification(_U('wrong_veh'))
									end
								end
							end
						else
							ESX.ShowNotification(_U('not_your_vehicle'))
						end  
					end
                elseif CurrentAction == 'foodtruck_client_burger' or CurrentAction == 'foodtruck_client_tacos' or CurrentAction == 'foodtruck_client_makiriime' then 
                    TriggerServerEvent('esx_foodtruck:addItem', CurrentActionData.item, 1)
                    ESX.Game.DeleteObject(FoodInPlace)
                    FoodInPlace = nil
                end

                CurrentAction = nil
            end
        end

		-- Control Press F6  
		if IsControlJustReleased(0, 167) and PlayerData.job ~= nil and PlayerData.job.name == 'foodtruck'   then 
			if IsPedSittingInAnyVehicle(PlayerPedId(-1)) == false then
				OpenMobileFoodTruckActionsMenu() 
			end
        end
    end
end)
