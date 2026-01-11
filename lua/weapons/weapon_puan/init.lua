AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

resource.AddWorkshop("1132622236")

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self:SetSelectedPoints(1)
    self:SetGiveMode(true)
end

function SWEP:Holster()
    if IsValid(self.Owner) then
        self.Owner:DrawViewModel(true)
        self.Owner:DrawWorldModel(true)
    end
    
    return true
end

function SWEP:OnRemove()
    self:Holster()
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
end
