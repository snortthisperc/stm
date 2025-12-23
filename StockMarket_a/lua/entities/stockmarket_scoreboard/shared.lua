-- ========================================
-- Stock Market Scoreboard (Shared)
-- ========================================

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_gmodentity"
ENT.PrintName = "Stock Market Scoreboard"
ENT.Author    = "snortthisperc"
ENT.Category  = "Stock Market"
ENT.Spawnable = true
ENT.AdminOnly = true

-- Networked vars so admins can tweak later
function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "RotationSeconds") -- seconds between scroll step
    self:NetworkVar("Int",   0, "VisibleRows")     -- rows requested by server/admin
    self:NetworkVar("Bool",  0, "Enabled")
end

-- Safe getters with defaults
function ENT:GetRotationSecondsSafe()
    local s = tonumber(self:GetRotationSeconds()) or 0
    if s <= 0 or s ~= s then s = 8 end
    return s
end

function ENT:GetVisibleRowsSafe()
    local n = tonumber(self:GetVisibleRows()) or 0
    if n <= 0 or n ~= n then n = 8 end
    return math.Clamp(n, 1, 16) -- hard clamp; client will soft-cap
end

function ENT:GetEnabledSafe()
    return self:GetEnabled() ~= false
end