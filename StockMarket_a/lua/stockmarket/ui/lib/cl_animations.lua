-- cl_animations.lua
-- Stock Market Animation System
-- Uses Think-based runner to properly animate panel properties

StockMarket.UI.Animations = StockMarket.UI.Animations or {}

local function ensureThink(panel)
    if not IsValid(panel) then return end
    if panel._sm_animators then return end
    
    panel._sm_animators = {}
    
    function panel.Think(self)
        if not IsValid(self) then return end
        local t = self._sm_animators
        if not t then return end
        
        for key, fn in pairs(t) do
            if fn(self) == true then
                t[key] = nil
            end
        end
        
        if not next(t) then
            self._sm_animators = nil
            self.Think = nil
        end
    end
end

function StockMarket.UI.Animations:Lerp(panel, property, target, duration, callback)
    if not IsValid(panel) then return end
    
    ensureThink(panel)
    
    local start = panel[property]
    if start == nil then start = 0 end
    
    local startTime = CurTime()
    local id = "SM_Anim_" .. property .. "_" .. math.random(10000, 99999)
    
    panel._sm_animators[id] = function(self)
        local elapsed = CurTime() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        -- Easing: ease-out cubic
        local eased = 1 - (1 - progress) ^ 3
        
        self[property] = Lerp(eased, start, target)
        
        if progress >= 1 then
            self[property] = target
            if callback then callback(self) end
            return true -- signal removal
        end
        
        return false
    end
end

function StockMarket.UI.Animations:FadeIn(panel, duration, callback)
    if not IsValid(panel) then return end
    duration = duration or 0.3
    panel:SetAlpha(0)
    self:Lerp(panel, "Alpha", 255, duration, callback)
end

function StockMarket.UI.Animations:FadeOut(panel, duration, callback)
    if not IsValid(panel) then return end
    duration = duration or 0.3
    local onComplete = function(p)
        p:SetAlpha(0)
        if callback then callback(p) end
    end
    self:Lerp(panel, "Alpha", 0, duration, onComplete)
end

function StockMarket.UI.Animations:Scale(panel, targetScale, duration, callback)
    if not IsValid(panel) then return end
    -- For use with custom paint scale; example only
    panel._scaleVal = 1
    self:Lerp(panel, "_scaleVal", targetScale, duration, callback)
end

function StockMarket.UI.Animations:Stop(panel, property)
    if not IsValid(panel) then return end
    if panel._sm_animators and panel._sm_animators[property] then
        panel._sm_animators[property] = nil
    end
end

function StockMarket.UI.Animations:StopAll(panel)
    if not IsValid(panel) then return end
    panel._sm_animators = {}
    panel.Think = nil
end