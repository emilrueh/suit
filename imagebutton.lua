-- This file is part of SUIT, copyright (c) 2016 Matthias Richter

local BASE = (...):match("(.-)[^%.]+$")

local function isType(val, typ)
	return type(val) == "userdata" and val.typeOf and val:typeOf(typ)
end

return function(core, normal, ...)
	local opt, x, y = core.getOptionsAndSize(...)
	opt.normal = normal or opt.normal or opt[1]
	opt.hovered = opt.hovered or opt[2] or opt.normal
	opt.active = opt.active or opt[3] or opt.hovered
	opt.id = opt.id or opt.normal

	local image = assert(opt.normal, "No image for state `normal'")

	core:registerMouseHit(opt.id, x, y, function(u, v)
		-- Adjust mouse coordinates to account for center origin
		local w, h = image:getWidth(), image:getHeight()
		u = u + w / 2 -- Shift origin from center to top-left
		v = v + h / 2

		u, v = math.floor(u + 0.5), math.floor(v + 0.5)
		if u < 0 or u >= w or v < 0 or v >= h then
			return false
		end

		if opt.mask then
			-- Use adjusted u/v for mask check
			assert(isType(opt.mask, "ImageData"), "Mask must be ImageData")
			assert(u < opt.mask:getWidth() and v < opt.mask:getHeight(), "Mask too small")
			local _, _, _, a = opt.mask:getPixel(u, v)
			return a > 0
		end

		return true
	end)

	if core:isActive(opt.id) then
		image = opt.active
	elseif core:isHovered(opt.id) then
		image = opt.hovered
	end

	assert(isType(image, "Image"), "state image is not a love.graphics.image")

	core:registerDraw(opt.draw or function(image, x, y, r, g, b, a)
		love.graphics.setColor(r, g, b, a)

		-- Snap position to integer coordinates to prevent subpixel blur
		local ix, iy = math.floor(x + 0.5), math.floor(y + 0.5)
		local iw, ih = math.floor(image:getWidth() / 2), math.floor(image:getHeight() / 2)

		love.graphics.draw(image, x, y, 0, 1, 1, iw, ih)
	end, image, x, y, love.graphics.getColor())

	return {
		id = opt.id,
		hit = core:mouseReleasedOn(opt.id),
		hovered = core:isHovered(opt.id),
		entered = core:isHovered(opt.id) and not core:wasHovered(opt.id),
		left = not core:isHovered(opt.id) and core:wasHovered(opt.id),
	}
end
