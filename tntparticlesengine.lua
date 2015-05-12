-- ############################################# --
-- ## TNT Particles Engine v1.13              ## --
-- ## By Gianluca D'Angelo Copyright (C) 2012 ## --
-- ############################################# --
-- official website with full documentation http://www.tntparticlesengine.com/
-- Version v1.13  release note --------------------
-- added fixedDelay option to CParticles.new as last parameter. 
-- fixedDelay accepted values: "Y" | nil (backward compatible)
-- if fixedDelay=="Y", each new particle is born with a fixed delay (==maxStartupDelay) else it follows default random behaviour (v1.12)
--[[Example usage: 
(v. 1.13 only)
defaultParticle = CParticles.new(particlesSprite, particlesMax, particlesMaxLife, particlesMaxStartupDelay, blendingMode, fixedDelay)

defaultParticleFixedDelay = CParticles.new("sprites/ember.png", 10, 3, 0.3, "add", "Y")

]]
---------------------------------------------------
-- YOU CAN USE TNT PARTICLES ENGINE IN FREE AND  --
-- COMMERCIAL GAMES. IF YOU USE AND YOU LIKE IT  --
-- PLEASE CONSIDER TO MAKE A DONATION TO SUPPORT --
-- THE PROGRAMMER. THANKS.                       --
---------------------------------------------------

-------------------
-- Emitter Class --
-------------------

CEmitter = Core.class(Sprite)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:init(xPos, yPos, direction, parentGroup)
	self.particlesCounter = 0 -- NUMBER OF PARTICLES ASSOCIATED WITH EMITTER
	self.pCounter = 0 -- particles counter
	self.emitter = {
		xPos = xPos, -- x position of emitter
		yPos = yPos, -- y position of emitter
		direction = math.rad(direction), -- direction (angle) of emitter
		parentGroup = parentGroup, -- parent sprite group
		particlesChild = {}, -- particles list attached at this emitter
		start = false, -- emitter is started ?
		pause = false, -- emitter paused ?
		hide = false, -- emitter hidden ?
	}
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:getVisibleParticles()
	return self.pCounter
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:getPosition()
	return self.emitter.xPos, self.emitter.yPos -- get emitter position
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:setPosition(xPos, yPos)
	for j = 1, self.particlesCounter do
		self.emitter.particlesChild[j].particles.moveX = xPos
		self.emitter.particlesChild[j].particles.moveY = yPos
	end
	self.emitter.xPos = xPos
	self.emitter.yPos = yPos
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:getDirection()
	return math.deg(self.emitter.direction) -- get emitter direction
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:setDirection(direction)
	self.emitter.direction = math.rad(direction) -- set emitter direction
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:getPartent()
	return self.emitter.parentGroup -- get emitter parentGroup (sprite)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:setParent(parentGroup)
	self.emitter.parentGroup = parentGroup -- set emitter parentGroup (sprite)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:start(...) -- start emitter (optional parameter startHidden)
	local arg = {...}
	local forceStart = arg[2]
	if (not self.emitter.start) or (forceStart) then
		if (self.emitter.parentGroup == nil) then
			error("error in emitter function start(): no parent sprite defined.")
		end
		if (self.particlesCounter == 0) then
			error("error in emitter function start(): no particles assigned.")
		end
		self.emitter.start = true -- start emitter
		self.emitter.hide = false -- start visible
		self.emitter.pause = false -- set not in pause
		
		if forceStart then
			self:removeEventListener(Event.ENTER_FRAME, self.onEnterFrame, self)
			for j = 1, self.particlesCounter do
				local particles = self.emitter.particlesChild[j].particles
				particles.loopCounter = particles.loopDefined
				particles.particlesEnded = false
				for j = 1, particles.particlesMax do
					local particlePoint = particles.particlesList[j]
					particlePoint.xPos = 0
					particlePoint.yPos = 0
					if particlePoint.isAlive then
						particles.particlesGroup:removeChild(particlePoint.sprite)
					end
					particlePoint.isAlive = false
					particlePoint.lifeStart = os.timer()
					particlePoint.loopCounter = 0
				end
				self.pCounter = 0
			end
		else
			for j = 1, self.particlesCounter do
				local particles = self.emitter.particlesChild[j].particles
				particles.loopCounter = particles.loopDefined
				particles.particlesEnded = false
				for j = 1, particles.particlesMax do
					local particlePoint = particles.particlesList[j]
					if not particlePoint.isAlive then
						particlePoint.lifeStart = os.timer()
					end
					particlePoint.loopCounter = 0
				end
			end
		end
		self:addEventListener(Event.ENTER_FRAME, self.onEnterFrame, self)
		local startHidden = arg[1] -- startHidden is optional parameter
		if (startHidden ~= nil) then -- check if present
			if startHidden then -- check if startHidden
				self:hide(true)
				self.emitter.hide = true
			else
				self.emitter.hide = false -- start visible
				self.emitter.pause = false -- set not in pause
			end
		end
		self:dispatchEvent(Event.new("EMITTER_START"))
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:pause(mode)
	self.emitter.pause = mode -- set in pause
	if mode then
		self:removeEventListener(Event.ENTER_FRAME, self.onEnterFrame, self)
		self:dispatchEvent(Event.new("EMITTER_PAUSED"))
		for j = 1, self.particlesCounter do
			local particles = self.emitter.particlesChild[j].particles
			for j = 1, particles.particlesMax do
				local particlePoint = particles.particlesList[j]
				if particlePoint.isAlive then
					particlePoint.lifeStart = os.timer() - particlePoint.lifeStart
				end
			end
		end
	else
		for j = 1, self.particlesCounter do
			local particles = self.emitter.particlesChild[j].particles
			for j = 1, particles.particlesMax do
				local particlePoint = particles.particlesList[j]
				if particlePoint.isAlive then
					particlePoint.lifeStart = os.timer() - particlePoint.lifeStart
				end
			end
		end
		self:dispatchEvent(Event.new("EMITTER_UNPAUSED"))
		self:addEventListener(Event.ENTER_FRAME, self.onEnterFrame, self)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:hide(mode)
	self.emitter.hide = mode
	if mode then
		for j = 1, self.particlesCounter do
			local particles = self.emitter.particlesChild[j].particles
			for j = 1, particles.particlesMax do
				local particlePoint = particles.particlesList[j]
				if particlePoint.isAlive then
					particlePoint.sprite:setVisible(false)
				end
			end
		end
		self:dispatchEvent(Event.new("EMITTER_HIDDEN"))
	else
		for j = 1, self.particlesCounter do
			local particles = self.emitter.particlesChild[j].particles
			for j = 1, particles.particlesMax do
				local particlePoint = particles.particlesList[j]
				if particlePoint.isAlive then
					particlePoint.sprite:setVisible(true)
				end
			end
		end
		self:dispatchEvent(Event.new("EMITTER_UNHIDDEN"))
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:stop()
	if self.emitter.start then
		self.emitter.start = false
		self:dispatchEvent(Event.new("EMITTER_STOPPED"))
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:isHidden() -- get if emitter currently is hidden
	return self.emitter.hide
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:paused() -- get if emitter currently is paused
	return self.emitter.pause
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:started() -- get if emitter currently is started
	return self.emitter.start
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:free() -- free emitter memory tntfx mod
	self:removeEventListener(Event.ENTER_FRAME, self.onEnterFrame, self)
	for j = 1, self.particlesCounter do
		--if self.emitter.particlesChild and self.emitter.particlesChild[j] then --tntfx add
			self.emitter.particlesChild[j]:free()
			self.emitter.particlesChild[j] = nil
		--end
	end
	self.emitter.parentGroup = nil
	self.emitter.particlesChild = nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:assignParticles(particlesObject) -- assign particles to emitter
	if (particlesObject.assignedToEmitter) then
		error("error in assignParticles function: particles are already assigned to an emitter.")
	else
		particlesObject.assignedToEmitter = true
		self.particlesCounter = self.particlesCounter + 1
		self.emitter.particlesChild[self.particlesCounter] = particlesObject
		self.emitter.parentGroup:addChild(particlesObject.particles.particlesGroup)
		particlesObject.particles.moveX = self.emitter.xPos
		particlesObject.particles.moveY = self.emitter.yPos
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CEmitter:onEnterFrame(event)		
	local qSin = math.sin
	local qCos = math.cos
	local qRandom = math.random
	local qRad = math.rad
	local qDeg = math.deg
	local STOPparticles = false

	local currentR = 0
	local currentG = 0
	local currentB = 0
	local alpha = 0
	local size = 0
	local speed = 0
	local direction = 0
	local cSize = 0
	local rTime = 0

	for k = 1, self.particlesCounter do
		local particles = self.emitter.particlesChild[k].particles
		STOPparticles = particles.particlesEnded		
		for j = 1, particles.particlesMax do
			local particlePoint = particles.particlesList[j]
			local timePassed = os.timer() - particlePoint.lifeStart
			if particlePoint.isAlive  then -- particles is alive ?

				if ((timePassed) >= particles.particlesMaxLife) or (particlePoint.currentSize < .01) then
					-- yes than kill!!! and hide from sprite group...
						particlePoint.isAlive = false
						particlePoint.xPos = 0
						particlePoint.yPos = 0
			--			if particlePoint.sprite:isVisible() then
							particlePoint.sprite:setVisible(false);
							self.pCounter = self.pCounter - 1
				--		end
				else -- Particle is alive then resize, rotate, etc...
					--------------------------------------------------
					-- Color Morph In & Out --------------------------
					--------------------------------------------------
					if particles.randomColors then
						currentR = particlePoint.r
						currentG = particlePoint.g
						currentB = particlePoint.b
					else
						currentR = particles.r / 255
						currentG = particles.g / 255
						currentB = particles.b / 255
					end
					if particles.colorMorphIn and particlePoint._ColorMorphIn then
						if timePassed <= particlePoint.targetColorTimeIn then
							local tStep = particlePoint.targetColorTimeIn / event.deltaTime
							particlePoint.cr = particlePoint.cr + (particlePoint.trIn - currentR) / (tStep)
							particlePoint.cg = particlePoint.cg + (particlePoint.tgIn - currentG) / (tStep)
							particlePoint.cb = particlePoint.cb + (particlePoint.tbIn - currentB) / (tStep)
							currentR = particlePoint.cr
							currentG = particlePoint.cg
							currentB = particlePoint.cb
						else
							currentR = particlePoint.cr
							currentG = particlePoint.cg
							currentB = particlePoint.cb
						end
					else
						particlePoint._ColorMorphIn = false
						currentR = particlePoint.cr
						currentG = particlePoint.cg
						currentB = particlePoint.cb
					end
					if particles.colorMorphOut and particlePoint._ColorMorphOut then
						rTime = (particles.particlesMaxLife - timePassed) / event.deltaTime
						if rTime < 0.5 then
							rTime = 0
						end
						if rTime > 0 then
							if timePassed >= particles.particlesMaxLife - particlePoint.targetColorTimeOut then
								particlePoint.cr = particlePoint.cr + (particlePoint.trOut - particlePoint.cr) / (rTime)
								particlePoint.cg = particlePoint.cg + (particlePoint.tgOut - particlePoint.cg) / (rTime)
								particlePoint.cb = particlePoint.cb + (particlePoint.tbOut - particlePoint.cb) / (rTime)
								currentR = particlePoint.cr
								currentG = particlePoint.cg
								currentB = particlePoint.cb
							end
						end
					else
						particlePoint._ColorMorphOut = false
						currentR = particlePoint.cr
						currentG = particlePoint.cg
						currentB = particlePoint.cb
					end
					--------------------------------------------------
					-- Speed Morph In & Out --------------------------
					--------------------------------------------------
					speed = particlePoint.speed
					if particles.speedMorphIn and particlePoint._SpeedMorphIn then
						if timePassed <= particlePoint.targetSpeedTimeIn then
							particlePoint.currentSpeed = particlePoint.currentSpeed + ((particlePoint.targetSpeedIn - speed) / ((particlePoint.targetSpeedTimeIn) / event.deltaTime))
							speed = particlePoint.currentSpeed
						else
							speed = particlePoint.currentSpeed
						end
					else
						particlePoint._SpeedMorphIn = false
						speed = particlePoint.currentSpeed
					end
					if particles.speedMorphOut and particlePoint._SpeedMorphOut then
						rTime = (particles.particlesMaxLife - timePassed) / event.deltaTime
						if rTime < 0.5 then
							rTime = 0
						end
						if rTime > 0 then
							if timePassed >= (particles.particlesMaxLife - particlePoint.targetSpeedTimeOut) then
								particlePoint.currentSpeed = particlePoint.currentSpeed + (particlePoint.targetSpeedOut - speed) / (rTime)
								speed = particlePoint.currentSpeed
							end
						end
					else
						particlePoint._SpeedMorphOut = false
						speed = particlePoint.currentSpeed
					end
					--------------------------------------------------
					-- Particle Morph Direction ----------------------
					--------------------------------------------------
					direction = particlePoint.direction
					if particles.directionMorphIn and particlePoint._directionMorphIn then
						if timePassed <= particlePoint.targetDirectionTimeIn then
							particlePoint.currentDirection = particlePoint.currentDirection + ((particlePoint.targetDirectionIn - direction) / ((particlePoint.targetDirectionTimeIn) / event.deltaTime))
							direction = particlePoint.currentDirection
						else
							direction = particlePoint.targetDirectionIn
						end
					else
						particlePoint._directionMorphIn = false
						direction = particlePoint.currentDirection
					end
					if particles.directionMorphOut and particlePoint._directionMorphOut then
						rTime = (particles.particlesMaxLife - timePassed) / event.deltaTime
						if rTime < 0.5 then
							rTime = 0
						end
						if rTime > 0 then
							if timePassed >= (particles.particlesMaxLife - particlePoint.targetDirectionTimeOut) then
								direction = particlePoint.currentDirection
								particlePoint.currentDirection = particlePoint.currentDirection + ((particlePoint.targetDirectionOut - direction) / (rTime))
								direction = (particlePoint.currentDirection)
							end
						end
					else
						particlePoint._directionMorphOut = false
					end
					--------------------------------------------------
					-- Particle Size Morph ---------------------------
					--------------------------------------------------
					size = particlePoint.size
					cSize = size
					if particles.sizeMorphIn and particlePoint._SizeMorphInEnabled then
						if timePassed <= particlePoint.targetSizeTimeIn then
							particlePoint.currentSize = particlePoint.currentSize + (particlePoint.targetSizeIn - cSize) / (particlePoint.targetSizeTimeIn / event.deltaTime)
							cSize = particlePoint.currentSize
						end
					else
						cSize = particlePoint.currentSize
						particlePoint._SizeMorphInEnabled = false
					end
					if particles.sizeMorphOut and particlePoint._SizeMorphOutEnabled then
						rTime = (particles.particlesMaxLife - timePassed) / event.deltaTime
						if rTime < 0.5 then
							rTime = 0
						end
						if rTime > 0 then
							if timePassed >= (particles.particlesMaxLife - particlePoint.targetSizeTimeOut) then
								particlePoint.currentSize = particlePoint.currentSize + (particlePoint.targetSizeOut - cSize) / (rTime)
								cSize = particlePoint.currentSize
							end
						end
					else
						cSize = particlePoint.currentSize
						particlePoint._SizeMorphOutEnabled = false
					end
					if cSize ~= size then
						particlePoint.sprite:setScale(cSize)
					end
					----------------------------------------------------------
					-- ALPHA MORPH IN & OUT-----------------------------------
					----------------------------------------------------------
					alpha = particlePoint.ca
					if particles.alphaMorphIn and particlePoint._AlphaMorphInEnabled then
						if timePassed <= particlePoint.targetAlphaTimeIn then
							--     particlePoint.ca = particlePoint.ca + ((particlePoint.targetAlphaIn - alpha) / ((particlePoint.targetAlphaTimeIn) / event.deltaTime))
							-- FIX by Paolo Manna
							particlePoint.ca = particlePoint.ca + ((particlePoint.targetAlphaIn - particlePoint.a) / ((particlePoint.targetAlphaTimeIn) / event.deltaTime))
							alpha = particlePoint.ca
						end
					else
						alpha = particlePoint.ca
						particlePoint._AlphaMorphInEnabled = false
					end
					if particles.alphaMorphOut and particlePoint._AlphaMorphOutEnabled then
						rTime = (particles.particlesMaxLife - timePassed) / event.deltaTime
						if rTime < 0.5 then
							rTime = 0
						end

						if rTime > 0 then
							if timePassed >= (particles.particlesMaxLife - particlePoint.targetAlphaTimeOut) then
								particlePoint.ca = particlePoint.ca + ((particlePoint.targetAlphaOut - alpha) / (rTime))
								--        particlePoint.ca = particlePoint.ca + ((particlePoint.targetAlphaOut - alpha) / (rTime))
								alpha = particlePoint.ca
							end
						end
					else
						alpha = particlePoint.ca
						particlePoint._AlphaMorphOutEnabled = false
					end
					--------------------------------------------------
					-- Particle Rotation -----------------------------
					--------------------------------------------------
					if particles.rotation then
						-- rotate always
						particlePoint.rotation = particlePoint.rotation + particlePoint.rotationVelocity * event.deltaTime
						particlePoint.sprite:setRotation(particlePoint.rotation)
					else
						local newAngle = qDeg(self.emitter.direction + particlePoint.direction)
						if particlePoint.crotation ~= newAngle then
							particlePoint.sprite:setRotation(newAngle)
							particlePoint.crotation = newAngle
						end
					end

					--------------------------------------------------------
					-- GRAVITY ---------------------------------------------
					--------------------------------------------------------
					particlePoint.gravityForceX = particlePoint.gravityForceX + (particles.gravityX * event.deltaTime)
					particlePoint.gravityForceY = particlePoint.gravityForceY + (particles.gravityY * event.deltaTime)
					--------------------------------------------------------
					-- POSITION --------------------------------------------
					--------------------------------------------------------
					particlePoint.xPos = (particlePoint.xPos + (particlePoint.gravityForceX + (qCos(self.emitter.direction + direction) * speed)) * event.deltaTime)
					particlePoint.yPos = (particlePoint.yPos + (particlePoint.gravityForceY + (qSin(self.emitter.direction + direction) * speed)) * event.deltaTime)
					--------------------------------------------------------
					-- WRITE SPRITE ----------------------------------------
					--------------------------------------------------------
					particlePoint.sprite:setColorTransform(currentR, currentG, currentB, alpha)
					particlePoint.sprite:setPosition(particlePoint.moveXPos + particlePoint.xPos + particlePoint.xDisplacement + particles.xOffset, particlePoint.moveYPos + particlePoint.yPos + particlePoint.yDisplacement + particles.yOffset)
				end
			else --if particles.isAlive
				-- particle is dead so if needed rebirth!!!
				if (timePassed > particlePoint.bornDelay) then
					if particles.loopCounter > 0 then
						particlePoint.loopCounter = particlePoint.loopCounter + 1
					end
					if (particlePoint.loopCounter <= particles.loopCounter) then
						if self.emitter.start then
							particles.particlesEnded = false
							particlePoint.isAlive = true
							particlePoint.restartCounter = self.emitter.restartCounter
							self.pCounter = self.pCounter + 1
							particlePoint.gravityForceX = particles.gravityForceX
							particlePoint.gravityForceY = particles.gravityForceY
							particlePoint.moveXPos = particles.moveX
							particlePoint.moveYPos = particles.moveY
							-------------------------------------------------------------------------
							-- Speed ----------------------------------------------------------------
							-------------------------------------------------------------------------
							if particles.randomSpeed then
								particlePoint.speed = qRandom(particles._speedMin, particles._speedMax)
								particlePoint.currentSpeed = particlePoint.speed

							else
								particlePoint.speed = particles._speedMin
								particlePoint.currentSpeed = particlePoint.speed
							end
							if particles.speedMorphIn then
								particlePoint._SpeedMorphIn = true
								if particles.randomSpeedIn then
									particlePoint.targetSpeedIn = qRandom(particles._targetSpeedInMin, particles._targetSpeedInMax)
								else
									particlePoint.targetSpeedIn = particles._targetSpeedInMin
								end
								if particles.randomSpeedInTime then
									particlePoint.targetSpeedTimeIn = qRandom(particles._targetSpeedInTimeMin, particles._targetSpeedInTimeMax) / 1000
								else
									particlePoint.targetSpeedTimeIn = particles._targetSpeedInTimeMin
								end
							else
								particlePoint._SpeedMorphIn = false
							end
							if particles.speedMorphOut then
								particlePoint._SpeedMorphOut = true
								if particles.randomSpeedOut then
									particlePoint.targetSpeedOut = qRandom(particles._targetSpeedOutMin, particles._targetSpeedOutMax)
								else
									particlePoint.targetSpeedOut = particles._targetSpeedOutMin
								end
								if particles.randomSpeedOutTime then
									particlePoint.targetSpeedTimeOut = qRandom(particles._targetSpeedOutTimeMin, particles._targetSpeedOutTimeMax) / 1000
								else
									particlePoint.targetSpeedTimeOut = particles._targetSpeedOutTimeMin
								end
							else
								particlePoint._SpeedMorphOut = false
							end
							-------------------------------------------------------------------------
							-- Direction ------------------------------------------------------------
							-------------------------------------------------------------------------
							if particles.randomDirection then
								particlePoint.direction = qRad(qRandom(particles._directionMin, particles._directionMax))
								particlePoint.currentDirection = particlePoint.direction
							else
								particlePoint.direction = qRad(particles._directionMin)
								particlePoint.currentDirection = particlePoint.direction
							end
							-------------------------------------------------------------------------
							-- Displacement ---------------------------------------------------------
							-------------------------------------------------------------------------
							if particles.randomDisplacement then
								particlePoint.xDisplacement = qRandom(-particles._widthDisplacement, particles._widthDisplacement)
								particlePoint.yDisplacement = qRandom(-particles._heightDisplacement, particles._heightDisplacement)
							end
							-------------------------------------------------------------------------
							-- Colors ---------------------------------------------------------------
							-------------------------------------------------------------------------
							if not particles.randomColors then
								particlePoint.r = particles.r / 255
								particlePoint.g = particles.g / 255
								particlePoint.b = particles.b / 255
							else -- random colors...
								particlePoint.r = qRandom(particles.r, particles._rMax) / 255
								particlePoint.g = qRandom(particles.g, particles._gMax) / 255
								particlePoint.b = qRandom(particles.b, particles._bMax) / 255
							end
							particlePoint.cr = particlePoint.r
							particlePoint.cg = particlePoint.g
							particlePoint.cb = particlePoint.b
							-------------------------------------------------------------------------
							-- Color Morph In/out ---------------------------------------------------
							-------------------------------------------------------------------------
							if particles.colorMorphIn then
								particlePoint._ColorMorphIn = true
								if particles.randomColorsIn then
									particlePoint.trIn = qRandom(particles._targetColorRInMin, particles._targetColorRInMax) / 255
									particlePoint.tgIn = qRandom(particles._targetColorGInMin, particles._targetColorGInMax) / 255
									particlePoint.tbIn = qRandom(particles._targetColorBInMin, particles._targetColorBInMax) / 255
								else
									particlePoint.trIn = particles._targetColorRInMin / 255
									particlePoint.tgIn = particles._targetColorGInMin / 255
									particlePoint.tbIn = particles._targetColorBInMin / 255
								end
								if particles.randomColorsInTime then
									particlePoint.targetColorTimeIn = qRandom(particles._targetColorTimeInMin, particles._targetColorTimeInMax) / 1000
								else
									particlePoint.targetColorTimeIn = particles._targetColorTimeInMin
								end
							else
								particlePoint._ColorMorphIn = false
							end
							if particles.colorMorphOut then
								particlePoint._ColorMorphOut = true
								if particles.randomColorsOut then
									particlePoint.trOut = qRandom(particles._targetColorROutMin, particles._targetColorROutMax) / 255
									particlePoint.tgOut = qRandom(particles._targetColorGOutMin, particles._targetColorGOutMax) / 255
									particlePoint.tbOut = qRandom(particles._targetColorBOutMin, particles._targetColorBOutMax) / 255
								else
									particlePoint.trOut = particles._targetColorROutMin / 255
									particlePoint.tgOut = particles._targetColorGOutMin / 255
									particlePoint.tbOut = particles._targetColorBOutMin / 255
								end
								if particles.randomColorsOutTime then
									particlePoint.targetColorTimeOut = qRandom(particles._targetColorTimeOutMin, particles._targetColorTimeOutMax) / 1000
								else
									particlePoint.targetColorTimeOut = particles._targetColorTimeOutMin
								end
							else
								particlePoint._ColorMorphOut = false
							end
							-----------------------------------------------------------------------
							-- rotation -----------------------------------------------------------
							-----------------------------------------------------------------------
							if particles.randomRotation then
								particlePoint.rotation = qRandom(particles._rotationMin, particles._rotationMax)
								particlePoint.rotationVelocity = qRandom(particles._velocityMin, particles._velocityMax)
							else
								particlePoint.rotation = particles._rotationMin
								particlePoint.crotation = particlePoint.rotation
								particlePoint.rotationVelocity = particles._velocityMin
							end
							-----------------------------------------------------------------------
							-- size ---------------------------------------------------------------
							-----------------------------------------------------------------------
							if particles.randomSize then
								particlePoint.size = qRandom(particles._sizeMin, particles._sizeMax) / 1000
								particlePoint.currentSize = particlePoint.size
							else
								particlePoint.size = particles._sizeMin
								particlePoint.currentSize = particles._sizeMin
							end
							------------------------------------------------------------------------
							-- Size Morph In/Out ----------------------------------------------------
							------------------------------------------------------------------------
							if particles.sizeMorphIn then
								particlePoint._SizeMorphInEnabled = true
								-- random size time in
								if particles._randomSizeInTime then
									particlePoint.targetSizeTimeIn = qRandom(particles._targetSizeTimeInMin, particles._targetSizeTimeInMax) / 1000
								else
									particlePoint.targetSizeTimeIn = particles._targetSizeTimeInMin
								end
								-- random size in
								if particles._randomSizeIn then
									particlePoint.targetSizeIn = qRandom(particles._targetSizeInMin, particles._targetSizeInMax) / 1000
								else
									particlePoint.targetSizeIn = particles._targetSizeInMin
								end
							else
								particlePoint._SizeMorphInEnabled = false
							end
							if particles.sizeMorphOut then
								particlePoint._SizeMorphOutEnabled = true
								-- random size time out
								if particles._randomSizeOutTime then
									particlePoint.targetSizeTimeOut = qRandom(particles._targetSizeTimeOutMin, particles._targetSizeTimeOutMax) / 1000
								else
									particlePoint.targetSizeTimeOut = particles._targetSizeTimeOutMin
								end
								if particles._randomSizeOut then
									particlePoint.targetSizeOut = qRandom(particles._targetSizeOutMin, particles._targetSizeOutMax) / 1000
								else
									particlePoint.targetSizeOut = particles._targetSizeOutMin
								end
							else
								particlePoint._SizeMorphOutEnabled = false
							end
							------------------------------------------------------------------------
							-- Alpha ---------------------------------------------------------------
							------------------------------------------------------------------------
							alpha = particles.a
							if particles.randomAlpha then
								particlePoint.a = qRandom(particles._alphaMin, particles._alphaMax) / 255
								particlePoint.ca = particlePoint.a
								alpha = particlePoint.a
							else
								particlePoint.a = alpha
								particlePoint.ca = alpha
							end
							-------------------------------------------------------------------------
							-- Alpha Morph In/Out ----------------------------------------------------
							-------------------------------------------------------------------------
							if particles.alphaMorphIn then
								particlePoint._AlphaMorphInEnabled = true
								if particles.randomInAlpha then
									particlePoint.targetAlphaIn = qRandom(particles._targetAlphaInMin, particles._targetAlphaInMax) / 255
								else
									particlePoint.targetAlphaIn = particles._targetAlphaInMin
								end
								if particles.randomInAlphaTime then
									particlePoint.targetAlphaTimeIn = qRandom(particles._targetAlphaTimeInMin, particles._targetAlphaTimeInMax) / 1000
								else
									particlePoint.targetAlphaTimeIn = particles._targetAlphaTimeInMin
								end
							else
								particlePoint._AlphaMorphInEnabled = false
							end
							if particles.alphaMorphOut then
								particlePoint._AlphaMorphOutEnabled = true
								if particles.randomOutAlpha then
									particlePoint.targetAlphaOut = qRandom(particles._targetAlphaOutMin, particles._targetAlphaOutMax) / 255
								else
									particlePoint.targetAlphaOut = particles._targetAlphaOutMin
								end
								if particles.randomOutAlphaTime then
									particlePoint.targetAlphaTimeOut = qRandom(particles._targetAlphaTimeOutMin, particles._targetAlphaTimeOutMax) / 1000
								else
									particlePoint.targetAlphaTimeOut = particles._targetAlphaTimeOutMin
								end
							else
								particlePoint._AlphaMorphOutEnabled = false
							end
							-------------------------------------------------------------------------
							-- Direction Morph In/Out------------------------------------------------
							-------------------------------------------------------------------------
							if particles.directionMorphIn then
								particlePoint._directionMorphIn = true
								particlePoint.currentDirection = particlePoint.direction
								if particles.randomDirectionMorphIn then
									particlePoint.targetDirectionIn = qRad(qRandom(particles._targetDirectionMorphInMin, particles._targetDirectionMorphInMax)) + particlePoint.direction
									particlePoint.targetDirectionTimeIn = qRandom(particles._targetDirectionMorphInTimeMin, particles._targetDirectionMorphInTimeMax) / 1000
								else
									particlePoint.targetDirectionIn = qRad(particles._targetDirectionMorphInMin) + particlePoint.direction -- ***
									particlePoint.targetDirectionTimeIn = particles._targetDirectionMorphInTimeMin
								end
							else
								particlePoint._directionMorphIn = false
							end
							if particles.directionMorphOut then
								particlePoint._directionMorphOut = true
								particlePoint.currentDirection = particlePoint.direction
								if particles.randomDirectionMorphOut then
									particlePoint.targetDirectionOut = qRad(qRandom(particles._targetDirectionMorphOutMin, particles._targetDirectionMorphOutMax)) + particlePoint.direction
									particlePoint.targetDirectionTimeOut = qRandom(particles._targetDirectionMorphOutTimeMin, particles._targetDirectionMorphOutTimeMax) / 1000
								else
									particlePoint.targetDirectionOut = qRad(particles._targetDirectionMorphOutMin) + particlePoint.direction
									particlePoint.targetDirectionTimeOut = particles._targetDirectionMorphOutTimeMin
								end
							else
								particlePoint._directionMorphOut = false
							end
							-------------------------------------------------------------------------
							-- Re-Bird Particles ----------------------------------------------------
							-------------------------------------------------------------------------
								if not particlePoint.sprite:isVisible() and (not self.emitter.hide) then
									particlePoint.sprite:setVisible(true)
								end
								particlePoint.sprite:setColorTransform(particlePoint.r, particlePoint.g, particlePoint.b, alpha)
								particlePoint.sprite:setPosition(particlePoint.moveXPos + particlePoint.xPos + particlePoint.xDisplacement + particles.xOffset, particlePoint.moveYPos + particlePoint.yPos + particlePoint.yDisplacement + particles.yOffset)
								particlePoint.sprite:setRotation(qDeg(self.emitter.direction + particlePoint.direction))
								if particlePoint.currentSize ~= 1 then
									particlePoint.sprite:setScale(particlePoint.size)
								end
								particlePoint.lifeStart = os.timer()
								if particlePoint.fixedDelay == "Y" then --if fixedDelay == YES 
									particlePoint.bornDelay = particles.maxDelay*(j-1)
								else --default tnt particle random behaviour
									particlePoint.bornDelay = qRandom(0, particles.maxDelay * 1000) / 1000
								end
							
						end
					else
						if self.pCounter == 0 then
							particles.particlesEnded = true
						end
					end --(particlePoint.loopCounter <= particles.loopCounter)
				end --if (timePassed > particlePoint.bornDelay)
			end --if particlePoint.isAlive then -- particles is alive ?
		end -- for j = 1, particles.particlesMax do
	end -- for k = 1, self.particlesCounter do browse all particles...
	if STOPparticles or (not self.emitter.start) then
		if self.pCounter == 0 then
			self.emitter.start = false
			self.playing = false
			self:removeEventListener(Event.ENTER_FRAME, self.onEnterFrame, self)
			self:dispatchEvent(Event.new("EMITTER_FINISHED"))
		end
	end -- if STOPEmitter then
end

-- ######################################################################################################################################################################## --
-- ######################################################################################################################################################################## --
-- ######################################################################################################################################################################## --
-- ######################################################################################################################################################################## --
-- ######################################################################################################################################################################## --
-- ######################################################################################################################################################################## --
-- ######################################################################################################################################################################## --
-- ######################################################################################################################################################################## --
-- ######################################################################################################################################################################## --
-- ######################################################################################################################################################################## --
-- ######################################################################################################################################################################## --

---------------------
-- Particles Class --
---------------------

CParticles = Core.class()
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:init(particlesSprite, particlesMax, particlesMaxLife, particlesMaxStartupDelay, blendingMode, particleFixedStartupDelay)
	-- define particle common properties
	self.assignedToEmitter = false
	self.particles = {
		xOffset = 0,
		yOffset = 0,
		moveX = 0,
		moveY = 0,
		particlesMax = particlesMax, -- max number of particles allowed
		particlesMaxLife = particlesMaxLife, -- max life of particle...
		particleGFX = particlesSprite, -- particle gfx
		maxDelay = particlesMaxStartupDelay, -- max startup delay of particle
		fixedDelay = particleFixedStartupDelay, --@pie v.1.13 if "Y" then particles start with fixed delay == particlesMaxStartupDelay
		particlesGroup = Sprite.new(), -- particles sprite group
		loopDefined = 0, -- loops defined
		loopCounter = 0, -- loops count
		particlesList = {}, -- particles list
		randomAlpha = false,
		randomSize = false, -- Random size Enabled ?
		randomDisplacement = false,
		randomInAlpha = false,
		randomOutAlpha = false,
		randomInAlphaTime = false,
		randomOutAlphaTime = false,
		randomColors = false,
		randomColorsIn = false,
		randomColorsOut = false,
		randomColorsInTime = false,
		randomColorsOutTime = false,
		randomSpeed = false,
		randomSpeedIn = false,
		randomSpeedOut = false,
		randomSpeedInTime = false,
		randomSpeedOutTime = false,
		randomDirection = false, -- random direction enabled ?
		randomDirectionMorphIn = false,
		randomDirectionMorphOut = false,
		rotation = false, -- Roation Enable ?
		randomRotation = false,
		alphaMorphIn = false, -- alpha morph in (fade in)
		alphaMorphOut = false, -- alpha morph out (fade out)

		speedMorphIn = false,
		speedMorphOut = false,
		sizeMorphIn = false, -- Size morphing enabled ?
		sizeMorphOut = false, -- Size morphing enabled ?

		colorMorphIn = false, -- color morph
		colorMorphOut = false, -- color morph

		directionMorphIn = false,
		directionMorphOut = false,
		gravityForceX = 0, -- gravity x force
		gravityForceY = 0, -- gravity y force
		r = 1, -- particle RED
		g = 1, -- particle GREEN
		b = 1, -- particle BLUE
		a = 1, -- particle ALPHA

		_speedMin = 0,
		_speedMax = 0,
		_sizeMin = 1,
		_sizeMax = 1,
		particlesEnded = false,
		_directionMin = 0, -- local min direction of particle
		_directionMax = 0, -- local max direction of particle

		_widthDisplacement = 0,
		_heightDisplacement = 0,
		_targetAlphaInMin = 0,
		_targetAlphaInMax = 0,
		_targetAlphaOutMin = 0,
		_targetAlphaOutMax = 0,
		_targetAlphaTimeInMin = 0, -- target alpha in time (max)
		_targetAlphaTimeOutMin = 0, -- target alpha out time (max)

		_targetAlphaTimeInMax = 0, -- target alpha in time (max)
		_targetAlphaTimeOutMax = 0, -- target alpha out time (max)

		_randomSizeIn = false,
		_randomSizeOut = false,
		_randomSizeInTime = false,
		_randomSizeOutTime = false,
		_targetSizeInMin = 0,
		_targetSizeInMax = 0,
		_targetSizeOutMin = 0,
		_targetSizeOutMax = 0,
		_targetSizeTimeInMin = 0,
		_targetSizeTimeInMax = 0,
		_targetSizeTimeOutMin = 0,
		_targetSizeTimeOutMax = 0,
		_targetColorTimeInMin = 0,
		_targetColorTimeInMax = 0,
		_targetColorTimeOutMin = 0,
		_targetColorTimeOutMax = 0,
		_targetColorRInMin = 0,
		_targetColorGInMin = 0,
		_targetColorBInMin = 0,
		_targetColorRInMax = 0,
		_targetColorGInMax = 0,
		_targetColorBInMax = 0,
		_targetColorROutMin = 0,
		_targetColorGOutMin = 0,
		_targetColorBOutMin = 0,
		_targetColorROutMax = 0,
		_targetColorGOutMax = 0,
		_targetColorBOutMax = 0,
		_targetSpeedInMin = 0,
		_targetSpeedInMax = 0,
		_targetSpeedOutMin = 0,
		_targetSpeedOutMax = 0,
		_targetSpeedInTimeMin = 0,
		_targetSpeedInTimeMax = 0,
		_targetSpeedOutTimeMin = 0,
		_targetSpeedOutTimeMax = 0,
		_targetDirectionMorphInMin = 0,
		_targetDirectionMorphInMax = 0,
		_targetDirectionMorphOutMin = 0,
		_targetDirectionMorphOutMax = 0,
		_targetDirectionMorphInTimeMin = 0,
		_targetDirectionMorphInTimeMax = 0,
		_targetDirectionMorphOutTimeMin = 0,
		_targetDirectionMorphOutTimeMax = 0,
		_alphaMin = 0,
		_alphaMax = 1,
		_rMax = 0,
		_gMax = 0,
		_bMax = 0,
		_rotationMin = 0,
		_velocityMin = 0,
		_rotationMax = 0,
		_velocityMax = 0
	}
	-- define all particles pre-cache
	for j = 1, self.particles.particlesMax do
		self.particle = {
			sprite = nil, -- sprite pointer used for particle
			xDisplacement = 0,
			yDisplacement = 0,
			xPos = 0, -- local x of particle
			yPos = 0, -- local y of particle
			moveXPos = 0,
			moveYPos = 0,
			direction = 0, -- local direction of particle
			currentDirection = 0, -- local direction of particle
			crotation = 0, -- local rotation of particle
			rotation = 0, -- local rotation of particle
			rotationVelocity = 0, -- local rotation velocity of particle
			targetAlphaIn = 0, -- target alpha in value
			targetAlphaOut = 0, -- target alpha out value
			targetAlphaTimeIn = 0, -- target alpha in time
			targetAlphaTimeOut = 0, -- target alpha out time

			targetSpeedIn = 0,
			targetSpeedTimeIn = 0,
			targetSpeedOut = 0,
			targetSpeedTimeOut = 0,
			targetSizeIn = 1, -- current target size
			targetSizeTimeIn = 0, -- time to morph to target
			targetSizeOut = 1, -- current target size
			targetSizeTimeOut = 0, -- time to morph to target

			targetDirectionIn = 0,
			targetDirectionOut = 0,
			targetDirectionTimeIt = 0,
			targetDirectionTimeOut = 0,
			r = 1, -- red, green, blue, alpha value of particle
			g = 1,
			b = 1,
			a = 1,
			cr = 1, -- current red, green, blue, alpha value of particle
			cg = 1,
			cb = 1,
			ca = 1,
			trIn = 1, -- target red, green, blue, alpha value of particle
			tgIn = 1,
			tbIn = 1,
			taIn = 1,
			trOut = 1, -- target red, green, blue, alpha value of particle
			tgOut = 1,
			tbOut = 1,
			taOut = 1,
			targetColorTimeIn = 0, -- target time color
			targetColorTimeOut = 0, -- target time color

			loopCounter = 0, -- local loop counter
			isAlive = false, -- particle is alive
			lifeStart = 0, -- when particle is born...
			bornDelay = 0, -- delay before born poarticle
			size = 1, -- particle default size
			currentSize = size, -- current particle size
			speed = 1, -- local speed of particle
			currentSpeed = 0,
			_AlphaMorphInEnabled = false,
			_AlphaMorphOutEnabled = false,
			_SizeMorphInEnabled = false,
			_SizeMorphOutEnabled = false,
			_ColorMorphIn = false,
			_ColorMorphOut = false,
			_SpeedMorphIn = false,
			_SpeedMorphOut = false,
			_DirectionMorphIn = false,
			_DirectionMorphOut = false
		}
		self.particles.gravityX = 0
		self.particles.gravityY = 0
		
		if self.particles.fixedDelay == "Y" then
			self.particle.fixedDelay = "Y"
		end
		
		local newParticle = Bitmap.new(self.particles.particleGFX)
		newParticle:setAnchorPoint(.5, .5)

		self.particles.particlesGroup:addChild(newParticle)
		self.particles.loopCounter = 0
		self.particles.loopDefined = 0
		self.particles.particlesList[j] = self.particle
		self.particles.particlesList[j].loopCounter = 0
		self.particles.particlesList[j].sprite = self.particles.particlesGroup:getChildAt(j)
		self.particles.particlesList[j].sprite:setBlendMode(blendingMode)
		self.particles.particlesList[j].lifeStart = os.timer()
		self.particles.particlesList[j].isAlive = false
		if self.particles.particlesList[j].fixedDelay == "Y" then
			self.particles.particlesList[j].bornDelay = particlesMaxStartupDelay*j
		else --default behaviour
			self.particles.particlesList[j].bornDelay = math.random(0, particlesMaxStartupDelay * 1000) / 1000
		end
		self.particles.particlesList[j].sprite:setVisible(false)
	end -- for
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setMaxLife(maxLife)
	self.particles.particlesMaxLife = maxLife
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:getMaxLife()
	return self.particles.particlesMaxLife
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setMaxDelay(maxDelay)
	self.particles.maxDelay = maxDelay -- max startup delay of particle
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:getMaxDelay()
	return self.particles.maxDelay
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:free()
	for j = 1, self.particles.particlesMax do
		self.particles.particlesList[j].sprite = nil
	end
	self.particles.particlesList = nil
	self.particles.particlesGroup = nil
	self.particle = nil
	self.particles = nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setSpeed(speed, ...)
	local arg = {...}

	local speedMax = arg[1]
	if (speedMax ~= nil) then
		if (speed > speedMax) then
			speed, speedMax = speedMax, speed
		end
		self.particles.randomSpeed = true
		self.particles._speedMin = speed
		self.particles._speedMax = speedMax
	else
		self.particles.randomSpeed = false
		self.particles._speedMin = speed
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setDirection(direction, ...)
	local arg = {...}

	local directionMax = arg[1]
	if (directionMax ~= nil) then
		if direction > directionMax then
			direction, directionMax = directionMax, direction
		end
		self.particles.randomDirection = true
		self.particles._directionMin = direction
		self.particles._directionMax = directionMax
	else
		self.particles._directionMin = direction
		self.particles.randomDirection = false
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setDisplacement(width, height)
	self.particles.randomDisplacement = true
	self.particles._widthDisplacement = width / 2
	self.particles._heightDisplacement = height / 2
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setColor(r, g, b, ...)
	local arg = {...}
	local rMax = arg[1]
	local gMax = arg[2]
	local bMax = arg[3]

	self.particles.r = r
	self.particles.g = g
	self.particles.b = b
	self.particles.randomColors = false

	-- check optional color R
	if (rMax ~= nil) then
		self.particles.randomColors = true
		if r > rMax then
			r, rMax = rMax, r
		end
		self.particles._rMax = rMax
	end
	-- check optional color G
	if (gMax ~= nil) then
		self.particles.randomColors = true
		if g > gMax then
			g, gMax = gMax, g
		end
		self.particles._gMax = gMax
	end
	-- check optional color B
	if (bMax ~= nil) then
		self.particles.randomColors = true
		if b > bMax then
			b, bMax = bMax, b
		end
		self.particles._bMax = bMax
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setLoopMode(loopMode)
	self.particles.loopCounter = loopMode
	self.particles.loopDefined = loopMode
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setSize(size, ...)
	local arg = {...}

	local sizeMax = arg[1]
	if (sizeMax ~= nil) then
		self.particles.randomSize = true
		if size > sizeMax then
			size, sizeMax = sizeMax, size
		end
		self.particles._sizeMin = size * 1000
		self.particles._sizeMax = sizeMax * 1000
	else
		self.particles.randomSize = false
		self.particles._sizeMin = size
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setGravity(gravityX, gravityY)
	self.particles.gravityX = gravityX
	self.particles.gravityY = gravityY
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- thanks to Scouser
function CParticles:setGravityForce(gravityX, gravityY)
	self.particles.gravityForceX = gravityX -- gravity x force
	self.particles.gravityForceY = gravityY -- gravity y force
	for j = 1, self.particles.particlesMax do
		self.particles.particlesList[j].gravityForceX = gravityX -- gravity x force
		self.particles.particlesList[j].gravityForceY = gravityY -- gravity y force
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setAlpha(alpha, ...)
	local arg = {...}
	local alphaMax = arg[1]
	self.particles._targetAlphaInMin = alpha
	if alphaMax ~= nil then
		self.particles.randomAlpha = true
		if alpha > alphaMax then
			alpha, alphaMax = alphaMax, alpha
		end
		self.particles._alphaMin = alpha
		self.particles._alphaMax = alphaMax
	else
		self.particles.randomAlpha = false
		self.particles.a = alpha / 255
		self.particles.ca = self.particles.a
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setParticlesOffset(x, y)
	self.particles.xOffset = x
	self.particles.yOffset = y
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setMoveXY(x, y)
	self.particles.moveX = x
	self.particles.moveY = y
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setRotation(rotation, velocity, ...)
	local arg = {...}

	local maxRotation = arg[1]
	local maxVelocity = arg[2]
	self.particles.rotation = true
	if (maxRotation == nil) then
		self.particles.randomRotation = false
		self.particles._rotationMin = rotation
		self.particles._velocityMin = velocity
	else
		if (maxVelocity == nil) then
			maxVelocity = velocity
		else
			if (velocity > maxVelocity) then
				velocity, maxVelocity = maxVelocity, velocity
			end
		end
		if (rotation > maxRotation) then
			rotation, maxRotation = maxRotation, rotation
		end
		self.particles.randomRotation = true
		self.particles._rotationMin = rotation
		self.particles._velocityMin = velocity
		self.particles._rotationMax = maxRotation
		self.particles._velocityMax = maxVelocity
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setAlphaMorphIn(targetAlpha, targetTime, ...)
	self.particles.alphaMorphIn = true
	local arg = {...}

	local targetAlphaMax = arg[1]
	local targetTimeMax = arg[2]
	-- Check Alpha in Value
	if (targetAlphaMax ~= nil) then
		self.particles.randomInAlpha = true
		if targetAlpha > targetAlphaMax then
			targetAlpha, targetAlphaMax = targetAlphaMax, targetAlpha
		end
		self.particles._targetAlphaInMin = targetAlpha
		self.particles._targetAlphaInMax = targetAlphaMax
	else
		self.particles.randomInAlpha = false
		self.particles._targetAlphaInMin = targetAlpha / 255
	end
	-- Check Time in Value
	if (targetTimeMax ~= nil) then
		self.particles.randomInAlphaTime = true
		if targetTime > targetTimeMax then
			targetTime, targetTimeMax = targetTimeMax, targetTime
		end
		self.particles._targetAlphaTimeInMin = targetTime * 1000
		self.particles._targetAlphaTimeInMax = targetTimeMax * 1000
	else
		self.particles.randomInAlphaTime = false
		self.particles._targetAlphaTimeInMin = targetTime
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setAlphaMorphOut(targetAlpha, targetTime, ...)
	self.particles.alphaMorphOut = true
	local arg = {...}

	local targetAlphaMax = arg[1]
	local targetTimeMax = arg[2]
	-- Check Alpha in Value
	if (targetAlphaMax ~= nil) then
		self.particles.randomOutAlpha = true
		if targetAlpha > targetAlphaMax then
			targetAlpha, targetAlphaMax = targetAlphaMax, targetAlpha
		end
		self.particles._targetAlphaOutMin = targetAlpha
		self.particles._targetAlphaOutMax = targetAlphaMax
	else
		self.particles.randomOutAlpha = false
		self.particles._targetAlphaOutMin = targetAlpha / 255
	end
	-- Check Time in Value
	if (targetTimeMax ~= nil) then
		self.particles.randomOutAlphaTime = true
		if targetTime > targetTimeMax then
			targetTime, targetTimeMax = targetTimeMax, targetTime
		end
		self.particles._targetAlphaTimeOutMin = targetTime * 1000
		self.particles._targetAlphaTimeOutMax = targetTimeMax * 1000
	else
		self.particles.randomOutAlphaTime = false
		self.particles._targetAlphaTimeOutMin = targetTime
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setSizeMorphIn(targetSize, targetTime, ...)
	local arg = {...}

	local targetSizeMaxIn = arg[1]
	local targetTimeMaxIn = arg[2]
	self.particles.sizeMorphIn = true
	self.particles._targetSizeTimeInMin = targetTime

	if (targetSizeMaxIn == nil) then -- no random size morph...
		self.particles._randomSizeIn = false
		self.particles._targetSizeInMin = targetSize
	else
		if targetSize > targetSizeMaxIn then
			targetSize, targetSizeMaxIn = targetSizeMaxIn, targetSize
		end
		self.particles._randomSizeIn = true
		self.particles._targetSizeInMin = targetSize * 1000
		self.particles._targetSizeInMax = targetSizeMaxIn * 1000
		if targetTimeMaxIn ~= nil then
			if targetTime > targetTimeMaxIn then
				targetTime, targetTimeMaxIn = targetTimeMaxIn, targetTime
			end
			self.particles._targetSizeTimeInMin = targetTime * 1000
			self.particles._targetSizeTimeInMax = targetTimeMaxIn * 1000
			self.particles._randomSizeInTime = true
		else
			self.particles._randomSizeInTime = false
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setSizeMorphOut(targetSize, targetTime, ...)
	local arg = {...}

	local targetSizeMaxOut = arg[1]
	local targetTimeMaxOut = arg[2]
	self.particles.sizeMorphOut = true
	self.particles._targetSizeTimeOutMin = targetTime

	if (targetSizeMaxOut == nil) then -- no random size morph...
		self.particles._randomSizeOut = false
		self.particles._targetSizeOutMin = targetSize
	else
		if targetSize > targetSizeMaxOut then
			targetSize, targetSizeMaxOut = targetSizeMaxOut, targetSize
		end
		self.particles._randomSizeOut = true
		self.particles._targetSizeOutMin = targetSize * 1000
		self.particles._targetSizeOutMax = targetSizeMaxOut * 1000
		if targetTimeMaxOut ~= nil then
			self.particles._randomSizeOutTime = true
			if targetTime > targetTimeMaxOut then
				targetTime, targetTimeMaxOut = targetTimeMaxOut, targetTime
			end
			self.particles._targetSizeTimeOutMin = targetTime * 1000
			self.particles._targetSizeTimeOutMax = targetTimeMaxOut * 1000
		else
			self.particles._randomSizeOutTime = false
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setColorMorphIn(rTarget, gTarget, bTarget, targetTime, ...)
	self.particles.colorMorphIn = true
	local arg = {...}

	local rMax = arg[1]
	local gMax = arg[2]
	local bMax = arg[3]
	local targetTimeMax = arg[4]

	self.particles.randomColorsIn = false
	-- check optional target color R Max
	if (rMax ~= nil) then
		self.particles.randomColorsIn = true
		if rTarget > rMax then
			rTarget, rMax = rMax, rTarget
		end
		self.particles._targetColorRInMax = rMax
	end
	-- check optional target color G Max
	if (gMax ~= nil) then
		self.particles.randomColorsIn = true
		if gTarget > gMax then
			gTarget, gMax = gMax, gTarget
		end
		self.particles._targetColorGInMax = gMax
	end
	-- check optional target color B Max
	if (bMax ~= nil) then
		self.particles.randomColorsIn = true
		if bTarget > bMax then
			bTarget, bMax = bMax, bTarget
		end
		self.particles._targetColorBInMax = bMax
	end

	self.particles._targetColorRInMin = rTarget
	self.particles._targetColorGInMin = gTarget
	self.particles._targetColorBInMin = bTarget
	self.particles._targetColorTimeInMin = targetTime

	if targetTimeMax ~= nil then
		self.particles.randomColorsInTime = true
		if targetTime > targetTimeMax then
			targetTime, targetTimeMax = targetTimeMax, targetTime
		end
		self.particles._targetColorTimeInMin = targetTime * 1000
		self.particles._targetColorTimeInMax = targetTimeMax * 1000
	else
		self.particles.randomColorsInTime = false
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setColorMorphOut(rTarget, gTarget, bTarget, targetTime, ...)
	self.particles.colorMorphOut = true
	local arg = {...}

	local rMax = arg[1]
	local gMax = arg[2]
	local bMax = arg[3]
	local targetTimeMax = arg[4]

	self.particles.randomColorsOut = false
	-- check optional target color R Max
	if (rMax ~= nil) then
		self.particles.randomColorsOut = true
		if rTarget > rMax then
			rTarget, rMax = rMax, rTarget
		end
		self.particles._targetColorROutMax = rMax
	end
	-- check optional target color G Max
	if (gMax ~= nil) then
		self.particles.randomColorsOut = true
		if gTarget > gMax then
			gTarget, gMax = gMax, gTarget
		end
		self.particles._targetColorGOutMax = gMax
	end
	-- check optional target color B Max
	if (bMax ~= nil) then
		self.particles.randomColorsOut = true
		if bTarget > bMax then
			bTarget, bMax = bMax, bTarget
		end
		self.particles._targetColorBOutMax = bMax
	end

	self.particles._targetColorROutMin = rTarget
	self.particles._targetColorGOutMin = gTarget
	self.particles._targetColorBOutMin = bTarget
	self.particles._targetColorTimeOutMin = targetTime

	if targetTimeMax ~= nil then
		self.particles.randomColorsOutTime = true
		if targetTime > targetTimeMax then
			targetTime, targetTimeMax = targetTimeMax, targetTime
		end
		self.particles._targetColorTimeOutMin = targetTime * 1000
		self.particles._targetColorTimeOutMax = targetTimeMax * 1000
	else
		self.particles.randomColorsOutTime = false
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setSpeedMorphIn(targetSpeed, targetTime, ...)
	self.particles.speedMorphIn = true
	local arg = {...}

	local targetSpeedMax = arg[1]
	local targetTimeMax = arg[2]
	self.particles._targetSpeedInMin = targetSpeed
	self.particles._targetSpeedInTimeMin = targetTime
	if targetSpeedMax == nil then
		self.particles.randomSpeedIn = false
		self.particles.randomSpeedInTime = false
	else
		if (targetTimeMax == nil) then
			targetTimeMax = targetTime
		end
		if (targetSpeed > targetSpeedMax) then
			targetSpeed, targetSpeedMax = targetSpeedMax, targetSpeed
		end
		if (targetTime > targetTimeMax) then
			targetTime, targetTimeMax = targetTimeMax, targetTime
		end
		self.particles.randomSpeedIn = true
		self.particles.randomSpeedInTime = true
		self.particles._targetSpeedInMin = targetSpeed
		self.particles._targetSpeedInTimeMin = targetTime * 1000
		self.particles._targetSpeedInMax = targetSpeedMax
		self.particles._targetSpeedInTimeMax = targetTimeMax * 1000
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setSpeedMorphOut(targetSpeed, targetTime, ...)
	self.particles.speedMorphOut = true
	local arg = {...}

	local targetSpeedMax = arg[1]
	local targetTimeMax = arg[2]
	self.particles._targetSpeedOutMin = targetSpeed
	self.particles._targetSpeedOutTimeMin = targetTime
	if targetSpeedMax == nil then
		self.particles.randomSpeedOut = false
		self.particles.randomSpeedOutTime = false
	else
		if (targetTimeMax == nil) then
			targetTimeMax = targetTime
		end
		if (targetSpeed > targetSpeedMax) then
			targetSpeed, targetSpeedMax = targetSpeedMax, targetSpeed
		end
		if (targetTime > targetTimeMax) then
			targetTime, targetTimeMax = targetTimeMax, targetTime
		end
		self.particles.randomSpeedOut = true
		self.particles.randomSpeedOutTime = true
		self.particles._targetSpeedOutMin = targetSpeed
		self.particles._targetSpeedOutTimeMin = targetTime * 1000
		self.particles._targetSpeedOutMax = targetSpeedMax
		self.particles._targetSpeedOutTimeMax = targetTimeMax * 1000
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setDirectionMorphIn(targetAngle, targetTime, ...)
	local arg = {...}

	local maxTargetAngle = arg[1]
	local maxTargetTime = arg[2]
	self.particles.directionMorphIn = true
	--particles._directionMin = particles._directionMin + targetAngle
	if (maxTargetAngle == nil) then
		self.particles.randomDirectionMorphIn = false
		self.particles._targetDirectionMorphInMin = targetAngle
		self.particles._targetDirectionMorphInTimeMin = targetTime
	else
		if (maxTargetTime == nil) then
			maxTargetTime = targetTime
		end
		if (targetAngle > maxTargetAngle) then
			targetAngle, maxTargetAngle = maxTargetAngle, targetAngle
		end
		if (targetTime > maxTargetTime) then
			targetTime, maxTargetTime = maxTargetTime, targetTime
		end
		self.particles.randomDirectionMorphIn = true
		self.particles._targetDirectionMorphInMin = targetAngle
		self.particles._targetDirectionMorphInTimeMin = targetTime * 1000
		self.particles._targetDirectionMorphInMax = maxTargetAngle
		self.particles._targetDirectionMorphInTimeMax = maxTargetTime * 1000
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CParticles:setDirectionMorphOut(targetAngle, targetTime, ...)
	local arg = {...}

	local maxTargetAngle = arg[1]
	local maxTargetTime = arg[2]
	self.particles.directionMorphOut = true

	if (maxTargetAngle == nil) then
		self.particles.randomDirectionMorphOut = false
		self.particles._targetDirectionMorphOutMin = targetAngle
		self.particles._targetDirectionMorphOutTimeMin = targetTime
	else
		if (maxTargetTime == nil) then
			maxTargetTime = targetTime
		end
		if (targetAngle > maxTargetAngle) then
			targetAngle, maxTargetAngle = maxTargetAngle, targetAngle
		end
		if (targetTime > maxTargetTime) then
			targetTime, maxTargetTime = maxTargetTime, targetTime
		end
		self.particles.randomDirectionMorphOut = true
		self.particles._targetDirectionMorphOutMin = targetAngle
		self.particles._targetDirectionMorphOutTimeMin = targetTime * 1000
		self.particles._targetDirectionMorphOutMax = maxTargetAngle
		self.particles._targetDirectionMorphOutTimeMax = maxTargetTime * 1000
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Version 1.01

------------------------------------------------------
--- Setters
function CParticles:setEnableDirectionMorph(EnableMorphIn, EnableMorphOut)
	self.particles.directionMorphIn = EnableMorphIn
	self.particles.directionMorphOut = EnableMorphOut
end

function CParticles:setEnableSpeedMorph(EnableMorphIn, EnableMorphOut)
	self.particles.speedMorphIn = EnableMorphIn
	self.particles.speedMorphOut = EnableMorphOut
end

function CParticles:setEnableColorMorph(EnableMorphIn, EnableMorphOut)
	self.particles.colorMorphIn = EnableMorphIn
	self.particles.colorMorphOut = EnableMorphOut
end

function CParticles:setEnableSizeMorph(EnableMorphIn, EnableMorphOut)
	self.particles.sizeMorphIn = EnableMorphIn
	self.particles.sizeMorphOut = EnableMorphOut
end

function CParticles:setEnableAlphaMorph(EnableMorphIn, EnableMorphOut)
	self.particles.alphaMorphIn = EnableMorphIn
	self.particles.alphaMorphOut = EnableMorphOut
end

function CParticles:setEnableDirectionMorphIn(EnableMorphIn)
	self.particles.directionMorphIn = EnableMorphIn
end

function CParticles:setEnableSpeedMorphIn(EnableMorphIn)
	self.particles.speedMorphIn = EnableMorphIn
end

function CParticles:setEnableColorMorphIn(EnableMorphIn)
	self.particles.colorMorphIn = EnableMorphIn
end

function CParticles:setEnableSizeMorphIn(EnableMorphIn)
	self.particles.sizeMorphIn = EnableMorphIn
end

function CParticles:setEnableAlphaMorphIn(EnableMorphIn)
	self.particles.alphaMorphIn = EnableMorphIn
end

function CParticles:setEnableDirectionMorphOut(EnableMorphOut)
	self.particles.directionMorphOut = EnableMorphOut
end

function CParticles:setEnableSpeedMorphOut(EnableMorphOut)
	self.particles.speedMorphOut = EnableMorphOut
end

function CParticles:setEnableColorMorphOut(EnableMorphOut)
	self.particles.colorMorphOut = EnableMorphOut
end

function CParticles:setEnableSizeMorphOut(EnableMorphOut)
	self.particles.sizeMorphOut = EnableMorphOut
end

function CParticles:setEnableAlphaMorphOut(EnableMorphOut)
	self.particles.alphaMorphOut = EnableMorphOut
end

------------------------------------------------------
--- Getters
function CParticles:getDirectionMorphEnabled()
	return self.particles.directionMorphIn, self.particles.directionMorphOut
end

function CParticles:getSpeedMorphEnabled()
	return self.particles.speedMorphIn, self.particles.speedMorphOut
end

function CParticles:getColorMorphEnabled()
	return self.particles.colorMorphIn, self.particles.colorMorphOut
end

function CParticles:getSizeMorphEnabled()
	return self.particles.sizeMorphIn, self.particles.sizeMorphOut
end

function CParticles:getAlphaMorphEnabled()
	return self.particles.alphaMorphIn, self.particles.alphaMorphOut
end

function CParticles:getDirectionMorphInEnabled()
	return self.particles.directionMorphIn
end

function CParticles:getSpeedMorphInEnabled()
	return self.particles.speedMorphIn
end

function CParticles:getColorMorphInEnabled()
	return self.particles.colorMorphIn
end

function CParticles:getSizeMorphInEnabled()
	return self.particles.sizeMorphIn
end

function CParticles:getAlphaMorphInEnabled()
	return self.particles.alphaMorphIn
end

function CParticles:getDirectionMorphOutEnabled()
	return self.particles.directionMorphOut
end

function CParticles:getSpeedMorphOutEnabled()
	return self.particles.speedMorphOut
end

function CParticles:getColorMorphOutEnabled()
	return self.particles.colorMorphOut
end

function CParticles:getSizeMorphOutEnabled()
	return self.particles.sizeMorphOut
end

function CParticles:getAlphaMorphOutEnabled()
	return self.particles.alphaMorphOut
end
