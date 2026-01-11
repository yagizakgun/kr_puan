ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Puan Tablosu"
ENT.Author = "Kronax"
ENT.Category = "KR-PUAN"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.AdminSpawnable = true
ENT.Model = "models/hunter/plates/plate2x4.mdl"

-- Reference global house configuration from KrPoints API
ENT.Houses = KrPoints.HouseList
ENT.HouseKeys = KrPoints.HouseKeys

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "TopStudentGryffindor")
    self:NetworkVar("String", 1, "TopStudentSlytherin")
    self:NetworkVar("String", 2, "TopStudentRavenclaw")
    self:NetworkVar("String", 3, "TopStudentHufflepuff")
end
