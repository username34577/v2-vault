-- Small helpers to build cartoony shapes out of parts (no uploaded meshes).
-- Defaults: anchored, SmoothPlastic, no collisions, no shadow (small props).
-- Pass props to override, e.g. { CanCollide = true, CastShadow = true }.
local Build = {}

local DEFAULTS = {
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	CastShadow = false,
	Material = Enum.Material.SmoothPlastic,
	TopSurface = Enum.SurfaceType.Smooth,
	BottomSurface = Enum.SurfaceType.Smooth,
}

local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- turns a cylinder's X axis to point up

function Build.part(props, parent)
	local p = Instance.new("Part")
	for k, v in DEFAULTS do
		p[k] = v
	end
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function apply(base, color, cframe, props, parent)
	base.Color = color
	base.CFrame = cframe
	if props then
		for k, v in props do
			base[k] = v
		end
	end
	return Build.part(base, parent)
end

function Build.block(size: Vector3, color: Color3, cframe: CFrame, parent, props)
	return apply({ Size = size }, color, cframe, props, parent)
end

function Build.ball(diameter: number, color: Color3, cframe: CFrame, parent, props)
	return apply({ Shape = Enum.PartType.Ball, Size = Vector3.one * diameter }, color, cframe, props, parent)
end

-- Upright cylinder (axis along Y). cframe is the center.
function Build.cylinder(diameter: number, height: number, color: Color3, cframe: CFrame, parent, props)
	return apply({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
	}, color, cframe * UPRIGHT, props, parent)
end

-- Cylinder whose axis follows the part's own X axis (for rails, arms, handles).
function Build.cylinderX(length: number, diameter: number, color: Color3, cframe: CFrame, parent, props)
	return apply({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(length, diameter, diameter),
	}, color, cframe, props, parent)
end

-- Squashed/stretched sphere: a block with a sphere mesh that fills its size.
function Build.ellipsoid(size: Vector3, color: Color3, cframe: CFrame, parent, props)
	local p = apply({ Size = size }, color, cframe, props, parent)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- Wedge (for slices, roofs). Slope faces local -Z/up like a normal WedgePart.
function Build.wedge(size: Vector3, color: Color3, cframe: CFrame, parent, props)
	local w = Instance.new("WedgePart")
	for k, v in DEFAULTS do
		if k ~= "TopSurface" and k ~= "BottomSurface" then
			w[k] = v
		end
	end
	w.Size = size
	w.Color = color
	w.CFrame = cframe
	if props then
		for k, v in props do
			w[k] = v
		end
	end
	w.Parent = parent
	return w
end

function Build.model(name: string, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function Build.lerp(a: Color3, b: Color3, t: number): Color3
	return a:Lerp(b, t)
end

return Build
