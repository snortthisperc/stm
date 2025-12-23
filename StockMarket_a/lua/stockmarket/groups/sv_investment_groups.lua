-- ========================================
-- Investment Groups Management
-- ========================================

StockMarket.Groups = StockMarket.Groups or {}
StockMarket.Groups.Cache = {}

function StockMarket.Groups:Create(ply, name)
    if not IsValid(ply) then return false, "Invalid player" end
    if name == "" or string.len(name) > 32 then return false, "Invalid name" end
    
    -- Check if name exists
    local check = sql.Query(string.format(
        "SELECT id FROM stockmarket_groups WHERE name = %s", sql.SQLStr(name)
    ))
    if check then return false, "Group name already exists" end
    
    -- Create group
    sql.Query(string.format([[
        INSERT INTO stockmarket_groups (name, owner_steam_id, cash, created)
        VALUES (%s, %s, 0, %d)
    ]], sql.SQLStr(name), sql.SQLStr(ply:SteamID64()), os.time()))
    
    local groupId = sql.QueryValue("SELECT last_insert_rowid()")
    
    -- Add owner as member
    sql.Query(string.format([[
        INSERT INTO stockmarket_group_members (group_id, steam_id, role, daily_limit, joined)
        VALUES (%d, %s, %d, 0, %d)
    ]], groupId, sql.SQLStr(ply:SteamID64()), StockMarket.Enums.GroupRole.OWNER, os.time()))
    
    return true, "Group created", groupId
end

function StockMarket.Groups:GetGroup(groupId)
    if self.Cache[groupId] then return self.Cache[groupId] end
    
    local result = sql.Query(string.format(
        "SELECT * FROM stockmarket_groups WHERE id = %d", groupId
    ))
    
    if not result or not result[1] then return nil end
    
    local group = result[1]
    group.id = tonumber(group.id)
    group.cash = tonumber(group.cash)
    
    -- Load members
    local members = sql.Query(string.format(
        "SELECT * FROM stockmarket_group_members WHERE group_id = %d", groupId
    ))
    group.members = members or {}
    
    -- Load positions
    local positions = sql.Query(string.format(
        "SELECT * FROM stockmarket_group_positions WHERE group_id = %d", groupId
    ))
    group.positions = {}
    if positions then
        for _, pos in ipairs(positions) do
            group.positions[pos.ticker] = {
                shares = tonumber(pos.shares),
                avgCost = tonumber(pos.avg_cost)
            }
        end
    end
    
    self.Cache[groupId] = group
    return group
end

function StockMarket.Groups:GetPlayerRole(groupId, ply)
    local sid = ply:SteamID64()
    local result = sql.Query(string.format([[
        SELECT role FROM stockmarket_group_members 
        WHERE group_id = %d AND steam_id = %s
    ]], groupId, sql.SQLStr(sid)))
    
    if result and result[1] then
        return tonumber(result[1].role)
    end
    return nil
end

function StockMarket.Groups:CanTrade(groupId, ply)
    local role = self:GetPlayerRole(groupId, ply)
    return role and role >= StockMarket.Enums.GroupRole.TRADER
end

function StockMarket.Groups:AddCash(groupId, amount)
    sql.Query(string.format(
        "UPDATE stockmarket_groups SET cash = cash + %f WHERE id = %d", amount, groupId
    ))
    self.Cache[groupId] = nil -- Invalidate cache
end

function StockMarket.Groups:RemoveCash(groupId, amount)
    local group = self:GetGroup(groupId)
    if not group or group.cash < amount then return false end
    
    sql.Query(string.format(
        "UPDATE stockmarket_groups SET cash = cash - %f WHERE id = %d", amount, groupId
    ))
    self.Cache[groupId] = nil
    return true
end

-- Network handlers
net.Receive("StockMarket_CreateGroup", function(len, ply)
    local name = net.ReadString()
    local success, message, groupId = StockMarket.Groups:Create(ply, name)
    
    net.Start("StockMarket_GroupUpdate")
    net.WriteString(success and "created" or "error")
    net.WriteString(message)
    if success then net.WriteInt(groupId, 32) end
    net.Send(ply)
end)
