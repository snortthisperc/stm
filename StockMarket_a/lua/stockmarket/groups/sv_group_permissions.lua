-- ========================================
-- Group Permissions & Roles
-- ========================================

StockMarket.GroupPermissions = StockMarket.GroupPermissions or {}

function StockMarket.GroupPermissions:SetRole(groupId, ownerPly, targetSteamID, newRole)
    -- Only owner can change roles
    local ownerRole = StockMarket.Groups:GetPlayerRole(groupId, ownerPly)
    if ownerRole ~= StockMarket.Enums.GroupRole.OWNER then
        return false, "Only the owner can change roles"
    end
    
    sql.Query(string.format([[
        UPDATE stockmarket_group_members 
        SET role = %d 
        WHERE group_id = %d AND steam_id = %s
    ]], newRole, groupId, sql.SQLStr(targetSteamID)))
    
    return true, "Role updated"
end

function StockMarket.GroupPermissions:InviteMember(groupId, ownerPly, targetPly)
    if not IsValid(ownerPly) then return false, "Owner not valid" end
    if not IsValid(targetPly) then return false, "Target not valid" end
    
    local ownerRole = StockMarket.Groups:GetPlayerRole(groupId, ownerPly)
    if (ownerRole or 0) < (StockMarket.Enums.GroupRole.MANAGER or 3) then
        return false, "Insufficient permissions (need Manager or higher)"
    end
    
    local group = StockMarket.Groups:GetGroup(groupId)
    if not group then return false, "Group not found" end
    
    local members = group.members or {}
    local maxMembers = (StockMarket.Config and StockMarket.Config.Groups and StockMarket.Config.Groups.maxMembers) or 10
    
    if #members >= maxMembers then
        return false, string.format("Group is full (max %d members)", maxMembers)
    end
    
    local targetSid = targetPly:SteamID64()
    if not targetSid or targetSid == "" then
        return false, "Target has no SteamID64"
    end
    
    -- Check if already a member
    local existing = sql.Query(string.format([[
        SELECT 1 FROM stockmarket_group_members
        WHERE group_id = %d AND steam_id = %s
        LIMIT 1
    ]], groupId, sql.SQLStr(targetSid)))
    
    if existing and #existing > 0 then
        return false, "Already a member of this group"
    end
    
    local defaultLimit = (StockMarket.Config and StockMarket.Config.Groups and StockMarket.Config.Groups.defaultTraderDailyLimit) or 0.20
    
    sql.Query(string.format([[
        INSERT INTO stockmarket_group_members (group_id, steam_id, role, daily_limit, joined)
        VALUES (%d, %s, %d, %f, %d)
    ]], groupId, sql.SQLStr(targetSid), StockMarket.Enums.GroupRole.VIEWER, tonumber(defaultLimit) or 0.20, os.time()))
    
    -- Invalidate cache to force refresh
    if StockMarket.Groups.Cache then
        StockMarket.Groups.Cache[groupId] = nil
    end
    
    return true, "Member invited successfully"
end
