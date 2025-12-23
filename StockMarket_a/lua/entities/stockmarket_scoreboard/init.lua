-- ========================================
-- Stock Market Scoreboard (Server)
-- ========================================

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DEFAULT_ROTATE = 8
local DEFAULT_ROWS   = 8

-- Admin-only spawn
function ENT:SpawnFunction(ply, tr, classname)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    if not tr.Hit then return end

    local ent = ents.Create(classname)
    if not IsValid(ent) then return end

    ent:SetPos(tr.HitPos + tr.HitNormal * 2)
    ent:SetModel("models/hunter/plates/plate.mdl")
    ent:Spawn()
    ent:Activate()

    -- Angle upright like a sign
    local ang = tr.HitNormal:Angle()
    ang:RotateAroundAxis(ang:Right(), 90)
    ent:SetAngles(ang)

    ent:PhysicsInit(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetSolid(SOLID_VPHYSICS)

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(true) -- allow physgun; admin can freeze
    end

    ent:SetRotationSeconds(DEFAULT_ROTATE)
    ent:SetVisibleRows(DEFAULT_ROWS)
    ent:SetEnabled(true)

    return ent
end

function ENT:Initialize()
    if self:GetModel() == "" then
        self:SetModel("models/hunter/plates/plate.mdl")
    end
    self:SetUseType(SIMPLE_USE)
end

-- Optional: prevent non-admin from picking up with physgun (keep admins allowed)
hook.Add("PhysgunPickup", "SM_ScoreboardAdminPickup", function(ply, ent)
    if ent:GetClass() == "stockmarket_scoreboard" then
        return ply:IsAdmin()
    end
end)

-- View-only for now
function ENT:Use(activator, caller) end