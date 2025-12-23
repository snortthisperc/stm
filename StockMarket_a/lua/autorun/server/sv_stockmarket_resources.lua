-- ========================================
-- Stock Market - Resource Download (Server)
-- Forces clients to download materials/sounds
-- Remove this once you publish to Workshop
-- ========================================

if not SERVER then return end

local resources = {
    -- Materials
    "materials/stockmarket/logo.png",
    "materials/stockmarket/icons/news.png",
    "materials/stockmarket/icons/portfolio.png",
    "materials/stockmarket/icons/statistics.png",
    "materials/stockmarket/icons/groups.png",
    "materials/stockmarket/icons/up_trend.png",
    "materials/stockmarket/icons/down_trend.png",

    -- Admin UI Materials
    "materials/stockmarket/icons/delete.png",
    "materials/stockmarket/icons/create.png",
    "materials/stockmarket/icons/preview.png",
    "materials/stockmarket/icons/edit.png",
    
    -- Sounds (uncomment if you have them)
     "sound/stockmarket/buy.wav",
     "sound/stockmarket/sell.wav",
     "sound/stockmarket/news_alert.wav",
     "sound/stockmarket/notification.wav",
}

-- Register all resources
for _, path in ipairs(resources) do
    resource.AddFile(path)
end

-- Debug command to verify files exist
concommand.Add("stockmarket_check_resources", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    print("\n========== STOCKMARKET RESOURCE CHECK ==========")
    for _, path in ipairs(resources) do
        local exists = file.Exists(path, "GAME")
        local status = exists and "[OK]" or "[MISSING]"
        print(status, path)
    end
    print("================================================\n")
end)