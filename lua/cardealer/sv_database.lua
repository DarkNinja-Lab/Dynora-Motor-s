function MyCarDealer.InitDatabase()
    local invQuery = [[
        CREATE TABLE IF NOT EXISTS mycardealer_inventory (
            steamid VARCHAR(32) NOT NULL,
            vehicle_id VARCHAR(64) NOT NULL,
            purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            tuning_data TEXT DEFAULT '{}',
            insurance BOOLEAN DEFAULT 0,
            insurance_cooldown INTEGER DEFAULT 0,
            total_distance INTEGER DEFAULT 0,
            crash_count INTEGER DEFAULT 0,
            favorite BOOLEAN DEFAULT 0,
            PRIMARY KEY (steamid, vehicle_id)
        )
    ]]
    
    if sql.Query(invQuery) == false then
        ErrorNoHalt("[Dynora Motor´s] Inventory table error: " .. sql.LastError() .. "\n")
    end

    local activeQuery = [[
        CREATE TABLE IF NOT EXISTS mycardealer_active (
            steamid VARCHAR(32) NOT NULL PRIMARY KEY,
            vehicle_id VARCHAR(64),
            entity_id INTEGER,
            spawn_time TIMESTAMP,
            insurance_active BOOLEAN DEFAULT 0
        )
    ]]
    
    if sql.Query(activeQuery) == false then
        ErrorNoHalt("[Dynora Motor´s] Active table error: " .. sql.LastError() .. "\n")
    end

    local lvsItemsQuery = [[
        CREATE TABLE IF NOT EXISTS mycardealer_lvs_items (
            steamid VARCHAR(32) NOT NULL,
            vehicle_id VARCHAR(64) NOT NULL,
            item_type VARCHAR(32) NOT NULL,
            item_data TEXT,
            PRIMARY KEY (steamid, vehicle_id, item_type)
        )
    ]]
    
    if sql.Query(lvsItemsQuery) == false then
        ErrorNoHalt("[Dynora Motor´s] LVS Items table error: " .. sql.LastError() .. "\n")
    end

    local historyQuery = [[
        CREATE TABLE IF NOT EXISTS mycardealer_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            seller_steamid VARCHAR(32),
            buyer_steamid VARCHAR(32),
            vehicle_id VARCHAR(64),
            price INTEGER,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]]
    
    if sql.Query(historyQuery) == false then
        ErrorNoHalt("[Dynora Motor´s] History table error: " .. sql.LastError() .. "\n")
    end

    sql.Query("CREATE INDEX IF NOT EXISTS idx_inv_steamid ON mycardealer_inventory(steamid)")
    sql.Query("CREATE INDEX IF NOT EXISTS idx_lvs_steamid ON mycardealer_lvs_items(steamid)")
    sql.Query("CREATE INDEX IF NOT EXISTS idx_history_seller ON mycardealer_history(seller_steamid)")
    sql.Query("CREATE INDEX IF NOT EXISTS idx_history_buyer ON mycardealer_history(buyer_steamid)")
    
    print("[Dynora Motor´s] Database initialized successfully")
end

hook.Add("Initialize", "MyCarDealer_InitDB", MyCarDealer.InitDatabase)