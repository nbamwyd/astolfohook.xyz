local ParticleFramework = {}

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Miscs = ReplicatedStorage:WaitForChild("Miscs")
local Projectiles = Miscs.Projectiles

local targetEvent
if RunService:IsClient() then
	targetEvent = RunService.RenderStepped
else
	targetEvent = RunService.Heartbeat
end

local DebugVisualization = false

-- Legends
-->green: stopped
-->red: entered object
-->blue: exited object
-->yellow: ricochet
-->viollet: penetrated humanoid

local function FromAxisAngle(x, y, z)
	if not y then
		x, y, z = x.x, x.y, x.z
	end
	local m = (x * x + y * y + z * z)^0.5
	if m > 1e-5 then
		local si = math.sin(m / 2) / m
		return CFrame.new(0, 0, 0, si * x, si * y, si * z, math.cos(m / 2))
	else
		return CFrame.new()
	end
end

do
    local setmt = setmetatable
	local insert = table.insert
  	local remove = table.remove
  	local tick = tick
  	local new = Instance.new
  	local c3 = Color3.new
  	local ns = NumberSequence.new
  	local v3 = Vector3.new
  	local cf = CFrame.new
  	local ray = Ray.new
  	local nv = v3()
  	local nc = cf()
  	local dot = nv.Dot
  	local ptos = nc.pointToObjectSpace
  	local vtws = nc.vectorToWorldSpace
  	local camera = Workspace.CurrentCamera
  	local ffc = game.FindFirstChild
  	local particles = {}
  	local removelist = {}
  	local time = tick()
  	local camcf = camera.CFrame
 	local newbeam
  	do
	    function newbeam(w0, partprop, ricochetdata)
      		local t0, p0, v0
      		local t1, p1, v1 = tick(), ptos(camcf, w0)
      		local attach0 = Instance.new("Attachment", Workspace.Terrain)
      		local attach1 = Instance.new("Attachment", Workspace.Terrain)
      		local beam = Instance.new("Beam", Workspace.Terrain)
      		beam.Attachment0 = attach0
      		beam.Attachment1 = attach1
			beam.Enabled = partprop[1]
      		beam.Segments = 16
      		beam.TextureSpeed = 0
      		beam.Transparency = NumberSequence.new(0)
      		beam.FaceCamera = true
      		local function update(w2, t2, size, bloom, brightness)
        		local t2 = tick()
        		local p2 = ptos(camcf, w2)
        		local v2
        		if t0 then
          			v2 = 2 / (t2 - t1) * (p2 - p1) - (p2 - p0) / (t2 - t0)
        		else
         			v2 = (p2 - p1) / (t2 - t1)
          			v1 = v2
       			end
        		t0, v0, p0 = t1, v1, p1
        		t1, v1, p1 = t2, v2, p2
        		local dt = t1 - t0
        		local m0 = v0.magnitude
        		local m1 = v1.magnitude
        		beam.CurveSize0 = dt / 3 * m0
        		beam.CurveSize1 = dt / 3 * m1
        		attach0.Position = camcf * p0
        		attach1.Position = camcf * p1
        		if m0 > 1.0E-8 then
         			attach0.Axis = vtws(camcf, v0 / m0)
        		end
        		if m1 > 1.0E-8 then
          			attach1.Axis = vtws(camcf, v1 / m1)
        		end
        		local dist0 = -p0.z
        		local dist1 = -p1.z
        		if dist0 < 0 then
		          	dist0 = 0
        		end
        		if dist1 < 0 then
          			dist1 = 0
        		end
        		local w0 = size + bloom * dist0
        		local w1 = size + bloom * dist1
        		local l = ((p1 - p0)*v3(1, 1, 0)).magnitude
        		local tr = 1 - 4 * size * size / ((w0 + w1) * (2 * l + w0 + w1)) * brightness
        		beam.Width0 = w0
        		beam.Width1 = w1
        		beam.Transparency = ns(tr)
      		end
      		local function remove()
        		attach0:Destroy()
        		attach1:Destroy()
        		beam:Destroy()
      		end
			local part
			if partprop[4] ~= "None" then
				part = Projectiles[partprop[4]]:Clone()
				part.CFrame = CFrame.new(partprop[2], partprop[2] + partprop[3])
				part.Parent = camera

				for _,child in pairs(part:GetDescendants()) do
					if child:IsA("ParticleEmitter") then
						child.Enabled = true
					elseif child:IsA("Sound") then
						child:Play()
					elseif child:IsA("PointLight") then
						child.Enabled = true
					elseif child:IsA("Trail") then
						child.Enabled = true
					elseif child:IsA("Beam") then
						child.Enabled = true
					end
				end
			end
			local function updatepart(position, velocity, offset, t, av, rot)
				if part then
					if partprop[5] then
						if ricochetdata[2] then
							part.CFrame = CFrame.new(position + offset) * FromAxisAngle(t * av) * rot
						else
							if ricochetdata[1] > 0  then
								part.CFrame = CFrame.new(position + offset) * FromAxisAngle(t * av) * rot
							else
								part.CFrame = CFrame.new(position, position + velocity) * CFrame.Angles(math.rad(-360 * (tick() * partprop[6] - math.floor(tick() * partprop[6]))), math.rad(-360 * (tick() * partprop[7] - math.floor(tick() * partprop[7]))), math.rad(-360 * (tick() * partprop[8] - math.floor(tick() * partprop[8]))))
							end
						end
					else
						part.CFrame = CFrame.new(position, position + velocity)
					end
				end
			end
      		local function removepart()
				if part then
					part.Transparency = 1
					for _,child in pairs(part:GetDescendants()) do
						if (child:IsA("BasePart") or child:IsA("Decal") or child:IsA("Texture")) then
							child.Transparency = 1
						elseif child:IsA("ParticleEmitter") then
							child.Enabled = false
						elseif child:IsA("Sound") then
							child:Stop()
						elseif child:IsA("PointLight") then
							child.Enabled = false
						--[[elseif child:IsA("Trail") then -- There is a case that trail is barely visible when projectile hits (especially at high speed). So I marked it as comment.
							child.Enabled = false]]
						elseif child:IsA("Beam") then
							child.Enabled = false
						end
					end
					Debris:AddItem(part, 5) -- Previously 10
				end
      		end
      		return beam, update, remove, part, updatepart, removepart
    	end
  	end
	local function GetVisualizationContainer()
		local fcVisualizationObjects = Workspace.Terrain:FindFirstChild("VisualizationObjects")
		if fcVisualizationObjects ~= nil then
			return fcVisualizationObjects
		end
		
		fcVisualizationObjects = Instance.new("Folder")
		fcVisualizationObjects.Name = "VisualizationObjects"
		fcVisualizationObjects.Archivable = false -- TODO: Keep this as-is? You can't copy/paste it if this is false. I have it false so that it doesn't linger in studio if you save with the debug data in there.
		fcVisualizationObjects.Parent = Workspace.Terrain
		return fcVisualizationObjects
	end
	function DbgVisualizeCone(atCF, color)
		if DebugVisualization ~= true then return end
		local adornment = Instance.new("ConeHandleAdornment")
		adornment.Adornee = Workspace.Terrain
		adornment.CFrame = atCF
		adornment.AlwaysOnTop = true
		adornment.Height = 1
		adornment.Color3 = color
		adornment.Radius = 0.05
		adornment.Transparency = 0.5
		adornment.Parent = GetVisualizationContainer()
		Debris:AddItem(adornment, 30)
		return adornment
	end
	function DbgVisualizeSphere(atCF, color)
		if DebugVisualization ~= true then return end
		local adornment = Instance.new("SphereHandleAdornment")
		adornment.Adornee = Workspace.Terrain
		adornment.CFrame = atCF
		adornment.Radius = 0.15
		adornment.Transparency = 0.5
		adornment.Color3 = color
		adornment.Parent = GetVisualizationContainer()
		Debris:AddItem(adornment, 30)
		return adornment
	end
	local function castwithwhitelist(origin, direction, whitelist, ignoreWater)
		if not whitelist or typeof(whitelist) ~= "table" then
			-- This array is faulty.
			error("Call in castwithwhitelist failed! whitelist table is either nil, or is not actually a table.", 0)
		end
		local castRay = Ray.new(origin, direction)
		-- Now here's something bizarre: FindPartOnRay and FindPartOnRayWithIgnoreList have a "terrainCellsAreCubes" boolean before ignoreWater. FindPartOnRayWithWhitelist, on the other hand, does not!
		return Workspace:FindPartOnRayWithWhitelist(castRay, whitelist, ignoreWater)
	end
	local function castwithblacklist(origin, direction, blacklist, ignoreWater)
		if not blacklist or typeof(blacklist) ~= "table" then
			-- This array is faulty
			error("Call in castwithblacklist failed! blacklist table is either nil, or is not actually a table.", 0)
		end
		local castRay = Ray.new(origin, direction)
		local hitPart, hitPoint, hitNormal, hitMaterial = nil, origin + direction, Vector3.new(0,1,0), Enum.Material.Air
		local success = false	
		repeat
			hitPart, hitPoint, hitNormal, hitMaterial = Workspace:FindPartOnRayWithIgnoreList(castRay, blacklist, false, ignoreWater)
			if hitPart then
				if (hitPart.Transparency > 0.75
				or hitPart.Name == "Missile"
				or hitPart.Name == "Handle"
				or hitPart.Name == "Effect"
				or hitPart.Name == "Bullet"
				or hitPart.Name == "Laser"
				or string.lower(hitPart.Name) == "water"
				or hitPart.Name == "Rail"
				or hitPart.Name == "Arrow"
				or ((hitPart.Parent:FindFirstChildOfClass("Humanoid") and hitPart.Parent:FindFirstChildOfClass("Humanoid").Health == 0) or (hitPart.Parent.Parent:FindFirstChildOfClass("Humanoid") and hitPart.Parent.Parent:FindFirstChildOfClass("Humanoid").Health == 0))
				--[[or (hitPart.Parent:FindFirstChildOfClass("Tool") or hitPart.Parent.Parent:FindFirstChildOfClass("Tool"))]]) then
					insert(blacklist, hitPart)
					success	= false
				else
					success	= true
				end
			else
				success	= true
			end
		until success
		return hitPart, hitPoint, hitNormal, hitMaterial
	end
	local function particlewind(t, p)
		local xy, yz, zx = p.x + p.y, p.y + p.z, p.z + p.x
		return Vector3.new(
			(math.sin(yz + t * 2) + math.sin(yz + t)) / 2 + math.sin((yz + t) / 10) / 2,
			(math.sin(zx + t * 2) + math.sin(zx + t)) / 2 + math.sin((zx + t) / 10) / 2,
			(math.sin(xy + t * 2) + math.sin(xy + t)) / 2 + math.sin((xy + t) / 10) / 2
		)
	end
  	function ParticleFramework.new(prop)
    	local self = {}
    	local position = prop.position or nv
    	local velocity = prop.velocity or nv
    	local acceleration = prop.acceleration or nv
		local visible = prop.visible --or true
    	local size = prop.size or 1
    	local bloom = prop.bloom or 0
    	local brightness = prop.brightness or 1
    	local cancollide = prop.cancollide == nil or prop.cancollide
		local windspeed = prop.windspeed or 10
		local windresistance  = prop.windresistance or 1
		local penetrationtype = prop.penetrationtype or "WallPenetration"
    	local penetrationdepth = prop.penetrationdepth or 0
		local penetrationamount = prop.penetrationamount or 0
		local ricochetamount = prop.ricochetamount or 0 
		local bounceelasticity = prop.bounceelasticity or 0.3
		local frictionconstant = prop.frictionconstant or 0.08
		local noexplosionwhilebouncing = prop.noexplosionwhilebouncing or false
		local stopbouncingonhithumanoid = prop.stopbouncingonhithumanoid or false
		local superricochet = prop.superricochet or false
    	local visualorigin = prop.visualorigin or position
		local visualdirection = prop.visualdirection or nv
    	local visualoffset = visualorigin - position
    	local penetrationpower = penetrationdepth
		local penetrationcount = penetrationamount
		local currentbounces = ricochetamount
    	local life = tick() + (prop.life or 10)
		local bullettype = prop.bullettype or "None"
		local canspinpart = prop.canspinpart or false
		local spinx = prop.spinx or 0
		local spiny = prop.spiny or 0 
		local spinz = prop.spinz or 0
		local toucheventontimeout = prop.toucheventontimeout or false
    	local physignore = prop.physicsignore or {
      		camera,
    	}
    	local onstep = prop.onstep
    	local ontouch = prop.ontouch
		local onenter = prop.onenter
		local onexit = prop.onexit
		local onbounce = prop.onbounce
    	local initpenetrationdepth = penetrationdepth
		local lastbounce = false
		local wind
		local h, p, n, m = nil, visualorigin + visualdirection, Vector3.new(0,1,0), Enum.Material.Air
    	function self:remove()
      		removelist[self] = true
    	end
    	local part
    	local bullet, bulletupdate, bulletremove, projectile, projectileupdate, projectileremove = newbeam(position + visualoffset, {visible, visualorigin, visualdirection, bullettype, canspinpart, spinx, spiny, spinz}, {ricochetamount, superricochet})
    	bullet.Texture = prop.texture or "http://www.roblox.com/asset/?id=2650195052"
    	bullet.LightEmission = 1
    	bullet.Color = ColorSequence.new(prop.color or c3(1, 1, 1))
    	self.bullet = bullet
    	self.bulletupdate = bulletupdate
    	self.bulletremove = bulletremove
    	self.projectile = projectile
    	self.projectileupdate = projectileupdate
    	self.projectileremove = projectileremove
		local t0 = tick()
		local av0 = Vector3.new(spinx, spiny, spinz)
		local rot0 = projectile and (projectile.CFrame - projectile.CFrame.p) or CFrame.new()
		local offset = Vector3.new()
    	function self.step(dt, time)
      		if life and time > life then
        		removelist[self] = true
				if toucheventontimeout then
		            if ontouch then
						ontouch(part, h, p, n, m)
		            end
					DbgVisualizeSphere(CFrame.new(p), Color3.new(0.2, 1, 0.5))
					DbgVisualizeCone(CFrame.new(p, p + n), Color3.new(0.2, 1, 0.5))
				end
        		return
      		end
			local t = tick() - t0
      		do
        		local position0 = position
				local velocity0 = velocity
				wind = (particlewind(tick(), position0) * windspeed - velocity0) * (1 - windresistance)
				local dposition = dt * velocity0 + dt * dt / 2 * (acceleration + wind)
        		if cancollide then
          			local hit, enterpoint, norm, material = castwithblacklist(position0, dposition, physignore, true)
          			if hit then
						t0 = tick()
						av0 = norm:Cross(velocity) / 0.2
						rot0 = projectile and (projectile.CFrame - projectile.CFrame.p) or CFrame.new()
						offset = 0.2 * norm
						h = hit
						p = enterpoint
						n = norm
						m = material
						if superricochet then
							--[[position = enterpoint
							local truevelocity = (velocity0 - 2 * norm:Dot(velocity0) / norm:Dot(norm) * norm)
							velocity = truevelocity + dt * acceleration]]
							local delta = enterpoint - position
							local fix = 1 - 0.001 / delta.magnitude
					        fix = fix < 0 and 0 or fix
					 		position = position + fix * delta + 0.05 * norm
							--position = enterpoint + norm * 0.0001
							local normvel = Vector3.new().Dot(norm, velocity) * norm
							local tanvel = velocity - normvel
							local geometricdeceleration
					        local d1 = -Vector3.new().Dot(norm, acceleration)
					        local d2 = -(1 + bounceelasticity) * Vector3.new().Dot(norm, velocity)
					        geometricdeceleration = 1 - frictionconstant * (10 * (d1 < 0 and 0 or d1) * dt + (d2 < 0 and 0 or d2)) / tanvel.magnitude
							--[[if lastbounce then
								geometricdeceleration = 1 - frictionconstant * acceleration.magnitude * dt / tanvel.magnitude
							else
								geometricdeceleration = 1 - frictionconstant * (acceleration.magnitude + (1 + bounceelasticity) * normvel.magnitude) / tanvel.magnitude
							end]]
							velocity = (geometricdeceleration < 0 and 0 or geometricdeceleration) * tanvel - bounceelasticity * normvel
							lastbounce = true
							if velocity.magnitude > 0 then
								if currentbounces > 0 then
									currentbounces = currentbounces - 1
									if stopbouncingonhithumanoid then
										if ((hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent:FindFirstChildOfClass("Humanoid").Health > 0) or (hit.Parent.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent.Parent:FindFirstChildOfClass("Humanoid").Health > 0)) then
							            	removelist[self] = true
			              					position = enterpoint
				            				if ontouch then
												ontouch(part, hit, enterpoint, norm, material)
				            				end
											DbgVisualizeSphere(CFrame.new(enterpoint), Color3.new(0.2, 1, 0.5))
											DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.new(0.2, 1, 0.5))
										else
						            		if onbounce then
												onbounce(part, hit, enterpoint, norm, material, noexplosionwhilebouncing)
						            		end
											DbgVisualizeSphere(CFrame.new(enterpoint), Color3.fromRGB(245, 205, 48))
											DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.fromRGB(245, 205, 48))
										end
									else
						            	if onbounce then
											onbounce(part, hit, enterpoint, norm, material, noexplosionwhilebouncing)
						            	end
										DbgVisualizeSphere(CFrame.new(enterpoint), Color3.fromRGB(245, 205, 48))
										DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.fromRGB(245, 205, 48))
									end
								end
							end
						else
							if ricochetamount > 0 then
								if currentbounces > 0 then
									--[[position = enterpoint
									local truevelocity = (velocity0 - 2 * norm:Dot(velocity0) / norm:Dot(norm) * norm)
									velocity = truevelocity + dt * acceleration]]
									local delta = enterpoint - position
									local fix = 1 - 0.001 / delta.magnitude
					            	fix = fix < 0 and 0 or fix
					 				position = position + fix * delta + 0.05 * norm
									--position = enterpoint + norm * 0.0001
									local normvel = Vector3.new().Dot(norm, velocity) * norm
									local tanvel = velocity - normvel
									local geometricdeceleration
					           		local d1 = -Vector3.new().Dot(norm, acceleration)
					            	local d2 = -(1 + bounceelasticity) * Vector3.new().Dot(norm, velocity)
					            	geometricdeceleration = 1 - frictionconstant * (10 * (d1 < 0 and 0 or d1) * dt + (d2 < 0 and 0 or d2)) / tanvel.magnitude
									--[[if lastbounce then
										geometricdeceleration = 1 - frictionconstant * acceleration.magnitude * dt / tanvel.magnitude
									else
										geometricdeceleration = 1 - frictionconstant * (acceleration.magnitude + (1 + bounceelasticity) * normvel.magnitude) / tanvel.magnitude
									end]]
									velocity = (geometricdeceleration < 0 and 0 or geometricdeceleration) * tanvel - bounceelasticity * normvel
									lastbounce = true
									if velocity.magnitude > 0 then
										currentbounces = currentbounces - 1
										if stopbouncingonhithumanoid then
											if ((hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent:FindFirstChildOfClass("Humanoid").Health > 0) or (hit.Parent.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent.Parent:FindFirstChildOfClass("Humanoid").Health > 0)) then
								            	removelist[self] = true
				              					position = enterpoint
					            				if ontouch then
													ontouch(part, hit, enterpoint, norm, material)
					            				end
												DbgVisualizeSphere(CFrame.new(enterpoint), Color3.new(0.2, 1, 0.5))
												DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.new(0.2, 1, 0.5))
											else
							            		if onbounce then
													onbounce(part, hit, enterpoint, norm, material, noexplosionwhilebouncing)
							            		end
												DbgVisualizeSphere(CFrame.new(enterpoint), Color3.fromRGB(245, 205, 48))
												DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.fromRGB(245, 205, 48))
											end
										else
							            	if onbounce then
												onbounce(part, hit, enterpoint, norm, material, noexplosionwhilebouncing)
							            	end
											DbgVisualizeSphere(CFrame.new(enterpoint), Color3.fromRGB(245, 205, 48))
											DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.fromRGB(245, 205, 48))
										end
									end
								else
						            removelist[self] = true
		              				position = enterpoint
			            			if ontouch then
										ontouch(part, hit, enterpoint, norm, material)
			            			end
									DbgVisualizeSphere(CFrame.new(enterpoint), Color3.new(0.2, 1, 0.5))
									DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.new(0.2, 1, 0.5))
								end
							else
								if penetrationtype == "WallPenetration" then
			            			local unit = dposition.unit
			            			local maxextent = hit.Size.magnitude * unit
			            			local exithit, exitpoint, exitnorm, exitmaterial = castwithwhitelist(enterpoint + maxextent, -maxextent, {hit}, true)
			            			local diff = exitpoint - enterpoint
			            			local dist = dot(unit, diff)
									local human = hit.Parent:FindFirstChildOfClass("Humanoid") or hit.Parent.Parent:FindFirstChildOfClass("Humanoid")
									--[[local pass = (hit.Transparency > 0.75
										or hit.Name == "Missile"
										or hit.Name == "Handle"
										or hit.Name == "Effect"
										or hit.Name == "Bullet"
										or hit.Name == "Laser"
										or string.lower(hit.Name) == "water"
										or hit.Name == "Rail"
										or hit.Name == "Arrow"
										or ((hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent:FindFirstChildOfClass("Humanoid").Health == 0) or (hit.Parent.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent.Parent:FindFirstChildOfClass("Humanoid").Health == 0))
										or (hit.Parent:FindFirstChildOfClass("Tool") or hit.Parent.Parent:FindFirstChildOfClass("Tool")))]]
			            			local exited
			            			--[[if pass then
										insert(physignore, hit)
										--physignore[#physignore + 1] = hit
			              				position = position0 + dposition
			              				velocity = velocity0 + dt * acceleration
										p = position
			              				exited = nil
			            			else]]if dist < penetrationdepth then
				            			if onexit then
											onexit(part, exithit, exitpoint, exitnorm, exitmaterial)
											DbgVisualizeSphere(CFrame.new(exitpoint), Color3.fromRGB(13, 105, 172))
											DbgVisualizeCone(CFrame.new(exitpoint, exitpoint + exitnorm), Color3.fromRGB(13, 105, 172))
				            			end
										if (hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent:FindFirstChildOfClass("Humanoid").Health > 0) or (hit.Parent.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent.Parent:FindFirstChildOfClass("Humanoid").Health > 0) then
											local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid") or hit.Parent.Parent:FindFirstChildOfClass("Humanoid")
											insert(physignore, humanoid.Parent)
											--physignore[#physignore + 1] = humanoid.Parent
										else
											insert(physignore, hit)
											--physignore[#physignore + 1] = hit
										end
			              				position = enterpoint + 0.01 * unit
										p = position
			              				local truedt = dot(dposition, enterpoint - position0) / dot(dposition, dposition) * dt
			              				velocity = velocity0 + truedt * acceleration
										penetrationdepth = human and penetrationdepth or penetrationdepth - dist
			              				exited = true
				            			if onenter then
											onenter(part, hit, enterpoint, norm, material, exited)
				            			end
										DbgVisualizeSphere(CFrame.new(enterpoint), Color3.new(1, 0.2, 0.2))
										DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.new(1, 0.2, 0.2))
			            			else
							            removelist[self] = true
			              				position = enterpoint
			              				exited = nil
				            			if ontouch then
											ontouch(part, hit, enterpoint, norm, material)
				            			end
										DbgVisualizeSphere(CFrame.new(enterpoint), Color3.new(0.2, 1, 0.5))
										DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.new(0.2, 1, 0.5))
			            			end
								elseif penetrationtype == "HumanoidPenetration" then
									if penetrationcount > 0 then
										if (hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent:FindFirstChildOfClass("Humanoid").Health > 0) or (hit.Parent.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent.Parent:FindFirstChildOfClass("Humanoid").Health > 0) then
											local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid") or hit.Parent.Parent:FindFirstChildOfClass("Humanoid")
											insert(physignore, humanoid.Parent)
											--physignore[#physignore + 1] = humanoid.Parent
									        --[[position = position0 + dposition
						            		velocity = velocity0 + dt * acceleration
											p = position]]
											penetrationcount = hit and (penetrationcount - 1) or 0
						            		if onenter then
												onenter(part, hit, enterpoint, norm, material, nil)
						            		end
											DbgVisualizeSphere(CFrame.new(enterpoint), Color3.fromRGB(107, 50, 124))
											DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.fromRGB(107, 50, 124))
					            		else
									        removelist[self] = true
					              			position = enterpoint
						            		if ontouch then
												ontouch(part, hit, enterpoint, norm, material)
						            		end
											DbgVisualizeSphere(CFrame.new(enterpoint), Color3.new(0.2, 1, 0.5))
											DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.new(0.2, 1, 0.5))
										end
									else
									    removelist[self] = true
					              		position = enterpoint
						            	if ontouch then
											ontouch(part, hit, enterpoint, norm, material)
						            	end
										DbgVisualizeSphere(CFrame.new(enterpoint), Color3.new(0.2, 1, 0.5))
										DbgVisualizeCone(CFrame.new(enterpoint, enterpoint + norm), Color3.new(0.2, 1, 0.5))
									end
								end
							end
						end
					else
						wind = (particlewind(tick(), position0) * windspeed - velocity0) * (1 - windresistance)
			            position = position0 + dposition
						velocity = velocity0 + dt * (acceleration + wind)
						h = nil
						p = position
						n = Vector3.new(0,1,0)
						m = Enum.Material.Air
						lastbounce = false
          			end
				else
					wind = (particlewind(tick(), position0) * windspeed - velocity0) * (1 - windresistance)
          			position = position0 + dposition
					velocity = velocity0 + dt * (acceleration + wind)
					h = nil
					p = position
					n = Vector3.new(0,1,0)
					m = Enum.Material.Air
		        end
      		end
      		if onstep then
        		onstep(part, dt)
      		end
      		bulletupdate(position + visualoffset, time, size, bloom, brightness)
			projectileupdate(position, velocity, offset, t, av0, rot0)
    	end
    	particles[self] = true
    	local get = {}
    	local set = {}
    	local meta = {}
    	function meta.__index(table, index)
      		return get[index]()
    	end
    	function meta.__newindex(table, index, value)
      		return set[index](value)
    	end
    	function get.position()
      		return position
	    end
    	function get.velocity()
      		return velocity
	    end
    	function get.acceleration()
      		return acceleration
	    end
    	function get.cancollide()
      		return cancollide
	    end
    	function get.size()
      		return size
    	end
    	function get.bloom()
      		return bloom
    	end
    	function get.brightness()
      		return brightness
    	end
    	function get.color()
      		return bullet.Color
    	end
		function get.texture()
			return bullet.Texture
		end
    	function get.life()
      		return life - tick()
    	end
    	function get.distance()
      		return 1
    	end
    	function get.hitwall()
      		return penetrationdepth ~= initpenetrationdepth
    	end
		function get.penetrationcount()
			return penetrationcount
		end
		function get.currentbounces()
			return currentbounces
		end
	    function set.position(p)
      		position = p
    	end
	    function set.velocity(v)
      		velocity = v
    	end
    	function set.acceleration(a)
      		acceleration = a
    	end
    	function set.cancollide(newcancollide)
	      	cancollide = newcancollide
   	    end
    	function set.size(newsize)
      		size = newsize
    	end
    	function set.bloom(newbloom)
      		bloom = newbloom
    	end
    	function set.brightness(newbrightness)
      		brightness = newbrightness
    	end
    	function set.color(newcolor)
      		bullet.Color = newcolor
    	end
    	function set.life(newlife)
      		life = tick() + newlife
    	end
    	part = setmt(self, meta)
	    if prop.dt then
      		self.step(prop.dt, tick())
    	end
    	return part
  	end
  	function ParticleFramework.step(dt)
    	local newtime = tick()
    	local dt = newtime - time
    	time = newtime
    	camcf = camera.CoordinateFrame
    	for p in next, particles, nil do
      		if removelist[p] then
        		removelist[p] = nil
        		particles[p] = nil
        		p.bulletremove()
				p.projectileremove()
      		else
        		p.step(dt, time)
      		end
    	end
  	end
  	function ParticleFramework:reset()
    	for p in next, particles, nil do
      		p.bulletremove()
			p.projectileremove()
    	end
    	particles = {}
    	removelist = {}
  	end
end

targetEvent:connect(function(dt)
	ParticleFramework.step(dt)
end)

return ParticleFramework
