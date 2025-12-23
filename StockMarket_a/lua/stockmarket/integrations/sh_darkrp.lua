-- ========================================
-- DarkRP Integration
-- ========================================

if not DarkRP then return end

StockMarket.DarkRP = {}

-- Convert DarkRP money to stock market cash
function StockMarket.DarkRP:DepositMoney(ply, amount)
    if not IsValid(ply) then return false end
    if not ply:canAfford(amount) then return false end
    
    ply:addMoney(-amount)
    StockMarket.PlayerData:AddCash(ply, amount)
    
    DarkRP.notify(ply, 1, 5, string.format("Deposited %s%d to your stock market account", 
        DarkRP.getCurrencySymbol(), amount))
    
    return true
end

-- Withdraw from stock market to DarkRP money
function StockMarket.DarkRP:WithdrawMoney(ply, amount)
    if not IsValid(ply) then return false end
    
    local cash = StockMarket.PlayerData:GetCash(ply)
    if cash < amount then return false end
    
    StockMarket.PlayerData:RemoveCash(ply, amount)
    ply:addMoney(amount)
    
    DarkRP.notify(ply, 1, 5, string.format("Withdrew %s%d from your stock market account", 
        DarkRP.getCurrencySymbol(), amount))
    
    return true
end

-- Network handlers
if SERVER then
    util.AddNetworkString("StockMarket_DarkRP_Deposit")
    util.AddNetworkString("StockMarket_DarkRP_Withdraw")

    StockMarket._rl_bank = StockMarket._rl_bank or {}
    local function BankLimited(ply)
        local sid = IsValid(ply) and ply:SteamID64() or "?"
        local last = StockMarket._rl_bank[sid] or 0
        if CurTime() - last < 0.5 then return true end -- 2 ops/sec
        StockMarket._rl_bank[sid] = CurTime()
        return false
    end

    local function ClampAmount(n)
        n = tonumber(n) or 0
        if n < 1 then return 0 end
        if n > 10^9 then n = 10^9 end
        return math.floor(n)
    end
    
    net.Receive("StockMarket_DarkRP_Deposit", function(len, ply)
        if BankLimited(ply) then return end
        local amount = ClampAmount(net.ReadInt(32))
        if amount <= 0 then return end
        StockMarket.DarkRP:DepositMoney(ply, amount)
    end)

    net.Receive("StockMarket_DarkRP_Withdraw", function(len, ply)
        if BankLimited(ply) then return end
        local amount = ClampAmount(net.ReadInt(32))
        if amount <= 0 then return end
        StockMarket.DarkRP:WithdrawMoney(ply, amount)
    end)
end

-- Add banking menu option
if CLIENT then
    function StockMarket.UI.OpenBankingMenu()
        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 300)
        frame:Center()
        frame:SetTitle("")
        frame:SetDraggable(true)
        frame:ShowCloseButton(true)
        frame:MakePopup()
        
        frame.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
            draw.SimpleText("Stock Market Banking", "StockMarket_SubtitleFont", w/2, 30, 
                StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
        
        -- Deposit section
        local depositLabel = vgui.Create("DLabel", frame)
        depositLabel:SetPos(30, 70)
        depositLabel:SetFont("StockMarket_TextFont")
        depositLabel:SetTextColor(StockMarket.UI.Colors.TextSecondary)
        depositLabel:SetText("Deposit Amount:")
        depositLabel:SizeToContents()
        
        local depositEntry = StockMarket.UI.Lib:TextEntry(frame, "0")
        depositEntry:SetPos(30, 95)
        depositEntry:SetSize(340, 40)
        depositEntry:SetNumeric(true)
        
        local depositBtn = StockMarket.UI.Lib:Button(frame, "Deposit", function()
            local amount = tonumber(depositEntry:GetValue()) or 0
            if amount <= 0 then
                StockMarket.UI.Notifications:Add("Enter valid amount", "error")
                return
            end
            
            net.Start("StockMarket_DarkRP_Deposit")
            net.WriteInt(amount, 32)
            net.SendToServer()
            
            frame:Close()
        end)
        depositBtn:SetPos(30, 145)
        depositBtn:SetSize(160, 40)
        
        -- Withdraw button
        local withdrawBtn = StockMarket.UI.Lib:Button(frame, "Withdraw", function()
            local amount = tonumber(depositEntry:GetValue()) or 0
            if amount <= 0 then
                StockMarket.UI.Notifications:Add("Enter valid amount", "error")
                return
            end
            
            net.Start("StockMarket_DarkRP_Withdraw")
            net.WriteInt(amount, 32)
            net.SendToServer()
            
            frame:Close()
        end)
        withdrawBtn:SetPos(210, 145)
        withdrawBtn:SetSize(160, 40)
        
        -- Info label
        local infoLabel = vgui.Create("DLabel", frame)
        infoLabel:SetPos(30, 200)
        infoLabel:SetSize(340, 60)
        infoLabel:SetFont("StockMarket_SmallFont")
        infoLabel:SetTextColor(StockMarket.UI.Colors.TextMuted)
        infoLabel:SetText("Transfer money between your wallet and stock market account.")
        infoLabel:SetWrap(true)
    end
end
