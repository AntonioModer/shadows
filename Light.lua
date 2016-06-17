local Shadows = ...
local Light = {}

Light.__index = Light
Light.x, Light.y, Light.z = 0, 0, 1
Light.Angle, Light.Arc = 0, 360
Light.Radius = 0

Light.R, Light.G, Light.B, Light.A = 255, 255, 255, 255

function Shadows.CreateLight(World, Radius)
	local Light = setmetatable({}, Light)
	
	Light.Radius = Radius
	Light.Canvas = love.graphics.newCanvas(Light.Radius * 2, Light.Radius * 2)
	Light.ShadowCanvas = love.graphics.newCanvas(Light.Radius * 2, Light.Radius * 2)
	
	World:AddLight(Light)
	
	return Light
end

function Shadows.CreateStar(World, Radius)
	local Light = setmetatable({}, Light)
	
	Light.Star = true
	Light.Radius = Radius
	Light.Canvas = love.graphics.newCanvas(Light.Radius * 2, Light.Radius * 2)
	Light.ShadowCanvas = love.graphics.newCanvas(Light.Radius * 2, Light.Radius * 2)
	
	World:AddStar(Light)
	
	return Light
end

function Light:GenerateShadows()
	local Shadows = {}
	for _, Body in pairs(self.World.Bodies) do
		for _, Shadow in pairs(Body:GenerateShadows(self)) do
			table.insert(Shadows, Shadow)
		end
	end
	return Shadows
end

function Light:Update()
	if self.Changed or self.World.Changed then
		local Translation = {
			self.x - self.Radius;
			self.y - self.Radius;
		}
		local LimitedTranslation = {
			math.min(math.max(Translation[1], 0), self.World.Canvas:getWidth() - self.Radius * 2);
			math.min(math.max(Translation[2], 0), self.World.Canvas:getHeight() - self.Radius * 2);
		}
		local OffsetTranslation = {
			LimitedTranslation[1] - Translation[1];
			LimitedTranslation[2] - Translation[2];
		}
		
		love.graphics.setCanvas(self.ShadowCanvas)
		love.graphics.translate(-LimitedTranslation[1], -LimitedTranslation[2])
		love.graphics.clear(255, 255, 255, 255)
		
		love.graphics.setBlendMode("alpha", "alphamultiply")
		love.graphics.setColor(0, 0, 0, 255)
		for _, Shadow in pairs(self:GenerateShadows()) do
			love.graphics[Shadow.type]("fill", unpack(Shadow))
		end
		
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setBlendMode("add")
		love.graphics.draw(self.World.BodyCanvas, 0, 0)
		
		love.graphics.setCanvas(self.Canvas)
		love.graphics.clear()
		love.graphics.origin()
		
		if self.Image then
			love.graphics.setBlendMode("lighten", "premultiplied")
			love.graphics.setColor(self.R, self.G, self.B, self.A)
			love.graphics.draw(self.Image, self.Radius - OffsetTranslation[1], self.Radius - OffsetTranslation[2])
		else
			Shadows.LightShader:send("LightColor", {self.R/255, self.G/255, self.B/255})
			Shadows.LightShader:send("LightRadius", self.Radius)
			Shadows.LightShader:send("Center", {self.Radius - OffsetTranslation[1], self.Radius - OffsetTranslation[2], self.z})
			
			local Arc = math.rad(self.Arc/2)
			local Angle = math.rad(self.Angle) - math.pi/2
			
			love.graphics.setShader(Shadows.LightShader)
			love.graphics.setBlendMode("alpha")
			love.graphics.setColor(255, 255, 255, self.A)
			love.graphics.arc("fill", self.Radius - OffsetTranslation[1], self.Radius - OffsetTranslation[2], self.Radius, Angle - Arc, Angle + Arc)
			love.graphics.setShader()
		end
		
		love.graphics.setBlendMode("darken", "premultiplied")
		love.graphics.draw(self.ShadowCanvas, 0, 0)
		
		love.graphics.setBlendMode("alpha", "alphamultiply")
		love.graphics.origin()
		love.graphics.setCanvas()
		
		self.Changed = nil
		self.World.UpdateCanvas = true
	end
end

function Light:SetAngle(Angle)
	if type(Angle) == "number" and Angle ~= self.Angle then
		self.Angle = Angle
		self.Changed = true
	end
	return self
end

function Light:GetAngle()
	return self.Angle
end

function Light:SetPosition(x, y, z)
	if x ~= self.x then
		self.x = x
		self.Changed = true
	end
	if y ~= self.y then
		self.y = y
		self.Changed = true
	end
	if z and z ~= self.z then
		self.z = z
		self.Changed = true
	end
	return self
end

function Light:GetPosition()
	return self.x, self.y, self.z
end

function Light:SetColor(R, G, B, A)
	if R ~= self.R then
		self.R = R
		self.Changed = true
	end
	if G ~= self.G then
		self.G = G
		self.Changed = true
	end
	if B ~= self.B then
		self.B = B
		self.Changed = true
	end
	if A ~= self.A then
		self.A = A
		self.Changed = true
	end
	return self
end

function Light:GetColor()
	return self.R, self.G, self.B, self.A
end

function Light:SetImage(Image)
	if Image ~= self.Image then
		self.Image = Image
		self.Radius = math.sqrt(Image:getWidth()^2 + Image:getHeight()^2) / 2
		self.Canvas = love.graphics.newCanvas(self.Radius * 2, self.Radius * 2)
		self.ShadowCanvas = love.graphics.newCanvas(self.Radius * 2, self.Radius * 2)
		self.Changed = true
	end
end

function Light:GetImage()
	return self.Image
end

function Light:SetRadius(Radius)
	if Radius ~= self.Radius then
		self.Radius = Radius
		self.Canvas = love.graphics.newCanvas(self.Radius * 2, self.Radius * 2)
		self.ShadowCanvas = love.graphics.newCanvas(self.Radius * 2, self.Radius * 2)
		self.Changed = true
	end
end

function Light:GetRadius()
	return self.Radius
end

function Light:Remove()
	if self.Star then
		self.World.Stars[self.ID] = nil
	else
		self.World.Lights[self.ID] = nil
	end
end