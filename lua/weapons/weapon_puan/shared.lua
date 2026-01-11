SWEP.Base                   = "weapon_base"
SWEP.PrintName              = "Puan Kitabı"
SWEP.ClassName              = "weapon_puankitabi"
SWEP.Author                 = "KrPoints"
SWEP.Category               = "KrPoints"
SWEP.Instructions           = "Puan verip - almanıza yarar"
SWEP.Spawnable              = true
SWEP.AdminOnly              = false
SWEP.Slot                   = 0
SWEP.SlotPos                = 5
SWEP.AutoSwitchTo           = false
SWEP.AutoSwitchFrom         = false
SWEP.ViewModel              = "models/weapons/c_grenade.mdl"
SWEP.WorldModel             = "models/weapons/c_arms.mdl"
SWEP.ViewModelFOV           = 60
SWEP.ViewModelFlip          = false
SWEP.UseHands               = true
SWEP.DrawAmmo               = false
SWEP.DrawCrosshair          = false
SWEP.HoldType               = "slam"
SWEP.Primary.Delay          = 0.8
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Ammo           = "none"
SWEP.Secondary.Delay        = 0.5
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"
SWEP.ThrownHoldType         = "normal"
SWEP.ShowViewModel          = true
SWEP.ShowWorldModel         = true

SWEP.ViewModelBoneMods = {
    ["ValveBiped.Bip01_Spine4"] = {scale = Vector(1,1,1), pos = Vector(0,0,1), angle = Angle(10,0,0)},
    ["ValveBiped.Grenade_body"] = {scale = Vector(0.009,0.009,0.009), pos = Vector(0,0,0), angle = Angle(0,0,0)}
}

SWEP.VElements = {
    ["Book"] = {
        type = "Model",
        model = "models/props_lab/binderblue.mdl",
        bone = "ValveBiped.Bip01_R_Hand",
        rel = "",
        pos = Vector(3.5, 4.349, -5.1),
        angle = Angle(0, 105, 0),
        size = Vector(0.56, 0.56, 0.56),
        color = Color(150, 125, 125, 255),
        surpresslightning = false,
        material = "",
        skin = 0,
        bodygroup = {}
    }
}

SWEP.WElements = {
    ["Book"] = {
        type = "Model",
        model = "models/props_lab/binderblue.mdl",
        bone = "ValveBiped.Bip01_R_Hand",
        rel = "",
        pos = Vector(4.199, 3.9, -4),
        angle = Angle(0, 110, 0),
        size = Vector(0.625, 0.625, 0.625),
        color = Color(150, 125, 125, 255),
        surpresslightning = false,
        material = "",
        skin = 0,
        bodygroup = {}
    }
}

function SWEP:SetupDataTables()
    self:NetworkVar("Int",   0, "SelectedPoints")
    self:NetworkVar("Bool",  0, "GiveMode")
end

function SWEP:Deploy()
    self:SetNextPrimaryFire(CurTime())
    self:SetNextSecondaryFire(CurTime())
    return true
end

function SWEP:SecondaryAttack()
    if not self:CanSecondaryAttack() then return end
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
    
    local current_mode = self:GetGiveMode()
    local new_mode = not current_mode
    self:SetGiveMode(new_mode)
end

function SWEP:Reload()
    if CurTime() < self:GetNextSecondaryFire() then return end
    self:SetNextSecondaryFire(CurTime() + 0.3)
    local current = self:GetSelectedPoints() or 1
    self:SetSelectedPoints((current % 5) + 1)
end

function SWEP:CanPrimaryAttack()
    return CurTime() >= self:GetNextPrimaryFire()
end

function SWEP:CanSecondaryAttack()
    return CurTime() >= self:GetNextSecondaryFire()
end
