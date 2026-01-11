include("shared.lua")

local KrPoints = KrPoints

SWEP.vRenderOrder = nil
SWEP.wRenderOrder = nil

local function FullCopyInternal(tab)
    if not tab then return nil end
    local res = {}
    for k, v in pairs(tab) do
        if type(v) == "table" then res[k] = FullCopyInternal(v)
        elseif type(v) == "Vector" then res[k] = Vector(v.x, v.y, v.z)
        elseif type(v) == "Angle" then res[k] = Angle(v.p, v.y, v.r)
        else res[k] = v end
    end
    return res
end

if not table.FullCopy then table.FullCopy = FullCopyInternal end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self:SetSelectedPoints(1)
    self:SetGiveMode(true)
    
    self.VElements = table.FullCopy(self.VElements)
    self.WElements = table.FullCopy(self.WElements)
    self.ViewModelBoneMods = table.FullCopy(self.ViewModelBoneMods)
    self:CreateModels(self.VElements)
    self:CreateModels(self.WElements)

    if IsValid(self.Owner) then
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            self:ResetBonePositions(vm)
            if self.ShowViewModel == nil or self.ShowViewModel then
                vm:SetColor(Color(255, 255, 255, 255))
            else
                vm:SetColor(Color(255, 255, 255, 1))
                vm:SetMaterial("Debug/hsv")
            end
        end
    end
end

function SWEP:Holster()
    if IsValid(self.Owner) then
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then self:ResetBonePositions(vm) end
    end
    
    return true
end

function SWEP:OnRemove()
    self:Holster()
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    
    if IsFirstTimePredicted() then
        local owner = self.Owner
        if not IsValid(owner) then return end
        
        local trace_ent = owner:GetEyeTrace().Entity
        
        if not IsValid(trace_ent) or not trace_ent:IsPlayer() then
            chat.AddText(
                KrPoints.White, "[",
                Color(201, 152, 18), "KrPoints",
                KrPoints.White, "] ",
                "Baktığın yerde",
                KrPoints.Red, " öğrenci olmadığından",
                KrPoints.White, " puan veremezsin veya alamazsın."
            )
            return
        end
        
        local mode = self:GetGiveMode() and "ver" or "al"
        local points = self:GetSelectedPoints()
        
        net.Start("KrPoints.GivePoints")
            net.WriteString(mode)
            net.WriteInt(points, 16)
            net.WriteEntity(trace_ent)
        net.SendToServer()
    end
end

function SWEP:ViewModelDrawn()
    local vm = self.Owner:GetViewModel()
    if not IsValid(vm) then return end
    if not self.VElements then return end
    
    self:UpdateBonePositions(vm)

    if not self.vRenderOrder then
        self.vRenderOrder = {}
        for k, v in pairs(self.VElements) do
            if v.type == "Model" then
                table.insert(self.vRenderOrder, 1, k)
            elseif v.type == "Sprite" or v.type == "Quad" then
                table.insert(self.vRenderOrder, k)
            end
        end
    end

    for i = 1, #self.vRenderOrder do
        local name = self.vRenderOrder[i]
        local v = self.VElements[name]
        if not v then self.vRenderOrder = nil break end
        if v.hide then continue end
        
        local model = v.modelEnt
        local sprite = v.spriteMaterial
        if not v.bone then continue end
        
        local pos, ang = self:GetBoneOrientation(self.VElements, v, vm)
        if not pos then continue end
        
        if v.type == "Model" and IsValid(model) then
            model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)
            model:SetAngles(ang)
            
            local matrix = Matrix()
            matrix:Scale(v.size)
            model:EnableMatrix("RenderMultiply", matrix)
            
            if v.material == "" then model:SetMaterial("")
            elseif model:GetMaterial() ~= v.material then model:SetMaterial(v.material) end
            
            if v.skin and v.skin ~= model:GetSkin() then model:SetSkin(v.skin) end
            
            if v.bodygroup then
                for bg_k, bg_v in pairs(v.bodygroup) do
                    if model:GetBodygroup(bg_k) ~= bg_v then model:SetBodygroup(bg_k, bg_v) end
                end
            end
            
            if v.surpresslightning then render.SuppressEngineLighting(true) end
            render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
            render.SetBlend(v.color.a / 255)
            model:DrawModel()
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)
            if v.surpresslightning then render.SuppressEngineLighting(false) end
            
        elseif v.type == "Sprite" and sprite then
            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            render.SetMaterial(sprite)
            render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
            
        elseif v.type == "Quad" and v.draw_func then
            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)
            cam.Start3D2D(drawpos, ang, v.size)
                v.draw_func(self)
            cam.End3D2D()
        end
    end
end

function SWEP:DrawWorldModel()
    if self.ShowWorldModel == nil or self.ShowWorldModel then self:DrawModel() end
    if not self.WElements then return end
    
    if not self.wRenderOrder then
        self.wRenderOrder = {}
        for k, v in pairs(self.WElements) do
            if v.type == "Model" then table.insert(self.wRenderOrder, 1, k)
            elseif v.type == "Sprite" or v.type == "Quad" then table.insert(self.wRenderOrder, k) end
        end
    end
    
    local bone_ent = IsValid(self.Owner) and self.Owner or self
    
    for i = 1, #self.wRenderOrder do
        local name = self.wRenderOrder[i]
        local v = self.WElements[name]
        if not v then self.wRenderOrder = nil break end
        if v.hide then continue end
        
        local pos, ang
        if v.bone then pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent)
        else pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand") end
        if not pos then continue end
        
        local model = v.modelEnt
        local sprite = v.spriteMaterial
        
        if v.type == "Model" and IsValid(model) then
            model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)
            model:SetAngles(ang)
            
            local matrix = Matrix()
            matrix:Scale(v.size)
            model:EnableMatrix("RenderMultiply", matrix)
            
            if v.material == "" then model:SetMaterial("")
            elseif model:GetMaterial() ~= v.material then model:SetMaterial(v.material) end
            
            if v.skin and v.skin ~= model:GetSkin() then model:SetSkin(v.skin) end
            
            if v.bodygroup then
                for bg_k, bg_v in pairs(v.bodygroup) do
                    if model:GetBodygroup(bg_k) ~= bg_v then model:SetBodygroup(bg_k, bg_v) end
                end
            end
            
            if v.surpresslightning then render.SuppressEngineLighting(true) end
            render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
            render.SetBlend(v.color.a / 255)
            model:DrawModel()
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)
            if v.surpresslightning then render.SuppressEngineLighting(false) end
            
        elseif v.type == "Sprite" and sprite then
            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            render.SetMaterial(sprite)
            render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
            
        elseif v.type == "Quad" and v.draw_func then
            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)
            cam.Start3D2D(drawpos, ang, v.size)
                v.draw_func(self)
            cam.End3D2D()
        end
    end
end

function SWEP:GetBoneOrientation(basetab, tab, ent, bone_override)
    local bone, pos, ang
    
    if tab.rel and tab.rel ~= "" then
        local v = basetab[tab.rel]
        if not v then return end
        
        pos, ang = self:GetBoneOrientation(basetab, v, ent)
        if not pos then return end
        
        pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
        ang:RotateAroundAxis(ang:Up(), v.angle.y)
        ang:RotateAroundAxis(ang:Right(), v.angle.p)
        ang:RotateAroundAxis(ang:Forward(), v.angle.r)
    else
        bone = ent:LookupBone(bone_override or tab.bone)
        if not bone then return end
        
        pos, ang = Vector(0, 0, 0), Angle(0, 0, 0)
        local m = ent:GetBoneMatrix(bone)
        if m then pos, ang = m:GetTranslation(), m:GetAngles() end
        
        if IsValid(self.Owner) and self.Owner:IsPlayer() and ent == self.Owner:GetViewModel() and self.ViewModelFlip then
            ang.r = -ang.r
        end
    end
    
    return pos, ang
end

function SWEP:CreateModels(tab)
    if not tab then return end

    for k, v in pairs(tab) do
        if v.type == "Model" and v.model and v.model ~= "" and (not IsValid(v.modelEnt) or v.createdModel ~= v.model and string.find(v.model, ".mdl") and file.Exists(v.model, "GAME")) then
            v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
            if IsValid(v.modelEnt) then
                v.modelEnt:SetPos(self:GetPos())
                v.modelEnt:SetAngles(self:GetAngles())
                v.modelEnt:SetParent(self)
                v.modelEnt:SetNoDraw(true)
                v.createdModel = v.model
            else
                v.modelEnt = nil
            end
            
        elseif v.type == "Sprite" and v.sprite and v.sprite ~= "" and (not v.spriteMaterial or v.createdSprite ~= v.sprite) and file.Exists("materials/" .. v.sprite .. ".vmt", "GAME") then
            local name = v.sprite .. "-"
            local params = {["$basetexture"] = v.sprite}
            local tocheck = {"nocull", "additive", "vertexalpha", "vertexcolor", "ignorez"}
            
            for i = 1, #tocheck do
                local j = tocheck[i]
                if v[j] then params["$" .. j] = 1 name = name .. "1"
                else name = name .. "0" end
            end

            v.createdSprite = v.sprite
            v.spriteMaterial = CreateMaterial(name, "UnlitGeneric", params)
        end
    end
end

local allbones = {}
local hasGarryFixedBoneScalingYet = false

function SWEP:UpdateBonePositions(vm)
    if self.ViewModelBoneMods then
        if not vm:GetBoneCount() then return end

        local loopthrough = self.ViewModelBoneMods
        
        if not hasGarryFixedBoneScalingYet then
            allbones = {}
            for i = 0, vm:GetBoneCount() do
                local bonename = vm:GetBoneName(i)
                if self.ViewModelBoneMods[bonename] then 
                    allbones[bonename] = self.ViewModelBoneMods[bonename]
                else
                    allbones[bonename] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
                end
            end
            loopthrough = allbones
        end
        
        for k, v in pairs(loopthrough) do
            local bone = vm:LookupBone(k)
            if not bone then continue end

            local s = Vector(v.scale.x, v.scale.y, v.scale.z)
            local p = Vector(v.pos.x, v.pos.y, v.pos.z)
            local ms = Vector(1, 1, 1)
            
            if not hasGarryFixedBoneScalingYet then
                local cur = vm:GetBoneParent(bone)
                while cur >= 0 do
                    local pscale = loopthrough[vm:GetBoneName(cur)].scale
                    ms = ms * pscale
                    cur = vm:GetBoneParent(cur)
                end
            end
            
            s = s * ms

            if vm:GetManipulateBoneScale(bone) ~= s then vm:ManipulateBoneScale(bone, s) end
            if vm:GetManipulateBoneAngles(bone) ~= v.angle then vm:ManipulateBoneAngles(bone, v.angle) end
            if vm:GetManipulateBonePosition(bone) ~= p then vm:ManipulateBonePosition(bone, p) end
        end
    else
        self:ResetBonePositions(vm)
    end
end
 
function SWEP:ResetBonePositions(vm)
    if not vm:GetBoneCount() then return end
    for i = 0, vm:GetBoneCount() do
        vm:ManipulateBoneScale(i, Vector(1, 1, 1))
        vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
        vm:ManipulateBonePosition(i, Vector(0, 0, 0))
    end
end
