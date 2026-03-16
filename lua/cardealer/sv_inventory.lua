function MyCarDealer.GetPlayerVehicles(ply, callback)
    MyCarDealer.GetInventory(ply, function(inventory)
        local vehicles = {}

        for _, item in ipairs(inventory) do
      
            for _, v in ipairs(MyCarDealer.Vehicles) do
                if v.id == item.vehicle_id then
                    table.insert(vehicles, {
                        id = v.id,
                        name = v.name,
                        category = v.category,
                        model = v.model,
                        price = v.price,
                        purchase_date = item.purchase_date,
                        tuning = util.JSONToTable(item.tuning_data or "{}")
                    })
                    break
                end
            end
        end

        callback(vehicles)
    end)
end
