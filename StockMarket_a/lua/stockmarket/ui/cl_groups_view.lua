-- ========================================
-- Investment Groups View
-- ========================================

StockMarket.UI.GroupsView = {}

function StockMarket.UI.GroupsView:Create(parent)
    local view = vgui.Create("DPanel", parent)
    view:Dock(FILL)
    view.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, StockMarket.UI.Colors.Background)
    end
    
    -- Header
    local header = vgui.Create("DPanel", view)
    header:Dock(TOP)
    header:SetTall(80)
    header:DockMargin(20, 20, 20, 10)
    header.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
        draw.SimpleText("Investment Groups", "StockMarket_TitleFont", 20, h/2, 
            StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    -- Create group button
    local createBtn = StockMarket.UI.Lib:Button(header, "Create Group", function()
        StockMarket.UI.OpenCreateGroupDialog()
    end)
    createBtn:SetSize(150, 40)
    createBtn:SetPos(header:GetWide() - 170, 20)
    
    -- Groups list
    local scroll = StockMarket.UI.Lib:ScrollPanel(view)
    scroll:Dock(FILL)
    scroll:DockMargin(20, 0, 20, 20)
    
    -- Placeholder
    local placeholder = vgui.Create("DLabel", scroll)
    placeholder:Dock(TOP)
    placeholder:SetTall(200)
    placeholder:SetFont("StockMarket_TextFont")
    placeholder:SetTextColor(StockMarket.UI.Colors.TextMuted)
    placeholder:SetText("Investment groups allow you to pool resources and trade together.\nCreate or join a group to get started.")
    placeholder:SetContentAlignment(5)
    placeholder:SetWrap(true)
    
    return view
end

function StockMarket.UI.OpenCreateGroupDialog()
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 200)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()
    
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
        draw.SimpleText("Create Investment Group", "StockMarket_SubtitleFont", w/2, 30, 
            StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    local nameLabel = vgui.Create("DLabel", frame)
    nameLabel:SetPos(30, 70)
    nameLabel:SetSize(100, 20)
    nameLabel:SetFont("StockMarket_TextFont")
    nameLabel:SetTextColor(StockMarket.UI.Colors.TextSecondary)
    nameLabel:SetText("Group Name:")
    
    local nameEntry = StockMarket.UI.Lib:TextEntry(frame, "My Investment Group")
    nameEntry:SetPos(30, 95)
    nameEntry:SetSize(340, 40)
    
    local createBtn = StockMarket.UI.Lib:Button(frame, "Create", function()
        local name = nameEntry:GetValue()
        if name == "" then
            StockMarket.UI.Notifications:Add("Please enter a group name", "error")
            return
        end
        
        net.Start("StockMarket_CreateGroup")
        net.WriteString(name)
        net.SendToServer()
        
        frame:Close()
    end)
    createBtn:SetPos(30, 145)
    createBtn:SetSize(340, 40)
end
