local structs = (...) or _G.structs

local _, ffi = pcall(require, "ffi")

local META = prototype.CreateTemplate("matrix44")

META.__index = META

if GRAPHENE then
	META.NumberType = "float"
else
	META.NumberType = "double"
end

META.Args = {
	"m00", "m01", "m02", "m03",
	"m10", "m11", "m12", "m13",
	"m20", "m21", "m22", "m23",
	"m30", "m31", "m32", "m33",
}

structs.AddOperator(META, "==")

local ctor

if ffi then
	ctor = ffi.typeof("struct { $ m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33; }", ffi.typeof(META.NumberType))
else
	local setmetatable = setmetatable
	ctor = function(m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33)
		return setmetatable({
			m00 = m00,
			m01 = m01,
			m02 = m02,
			m03 = m03,
			m10 = m10,
			m11 = m11,
			m12 = m12,
			m13 = m13,
			m20 = m20,
			m21 = m21,
			m22 = m22,
			m23 = m23,
			m30 = m30,
			m31 = m31,
			m32 = m32,
			m33 = m33,
		}, META)
	end
end

function META:GetI(i)
	return self[META.Args[i+1]]
end

function META:SetI(i, val)
	self[META.Args[i+1]] = val
end

function META:Unpack()
	return
		self.m00,
		self.m01,
		self.m02,
		self.m03,
		self.m10,
		self.m11,
		self.m12,
		self.m13,
		self.m20,
		self.m21,
		self.m22,
		self.m23,
		self.m30,
		self.m31,
		self.m32,
		self.m33
end

if ffi then
	local new = ffi.new
	local temp = new("float[16]")

	function META:GetFloatPointer()
		temp[0] = self.m00
		temp[1] = self.m01
		temp[2] = self.m02
		temp[3] = self.m03
		temp[4] = self.m10
		temp[5] = self.m11
		temp[6] = self.m12
		temp[7] = self.m13
		temp[8] = self.m20
		temp[9] = self.m21
		temp[10] = self.m22
		temp[11] = self.m23
		temp[12] = self.m30
		temp[13] = self.m31
		temp[14] = self.m32
		temp[15] = self.m33
		return temp
	end

	function META:GetFloatCopy()
		return new("float[16]", self.m00, self.m01, self.m02, self.m03, self.m10, self.m11, self.m12, self.m13, self.m20, self.m21, self.m22, self.m23, self.m30, self.m31, self.m32, self.m33)
	end
end

function META.CopyTo(a, b)

	b.m00 = a.m00
	b.m01 = a.m01
	b.m02 = a.m02
	b.m03 = a.m03
	b.m10 = a.m10
	b.m11 = a.m11
	b.m12 = a.m12
	b.m13 = a.m13
	b.m20 = a.m20
	b.m21 = a.m21
	b.m22 = a.m22
	b.m23 = a.m23
	b.m30 = a.m30
	b.m31 = a.m31
	b.m32 = a.m32
	b.m33 = a.m33

	return a
end

function META:Copy()
	return ctor(self.m00, self.m01, self.m02, self.m03, self.m10, self.m11, self.m12, self.m13, self.m20, self.m21, self.m22, self.m23, self.m30, self.m31, self.m32, self.m33)
end

META.__copy = META.Copy

function META:__tostring()
	return string.format("matrix44[%p]:\n" .. ("%f %f %f %f\n"):rep(4), self,
		self.m00, self.m01, self.m02, self.m03,
		self.m10, self.m11, self.m12, self.m13,
		self.m20, self.m21, self.m22, self.m23,
		self.m30, self.m31, self.m32, self.m33
	)
end

function META:__mul(b)
	return self:GetMultiplied(b)
end

function META:Identity()
	self.m00 = 1
	self.m11 = 1
	self.m22 = 1
	self.m33 = 1

	self.m01 = 0
	self.m02 = 0
	self.m03 = 0
	self.m10 = 0
	self.m12 = 0
	self.m13 = 0
	self.m20 = 0
	self.m21 = 0
	self.m23 = 0
	self.m30 = 0
	self.m31 = 0
	self.m32 = 0

	return self
end

META.LoadIdentity = META.Identity

function META:GetInverse(out)
	out = out or ctor(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)

	out.m00 = self.m11*self.m22*self.m33 - self.m11*self.m32*self.m23 - self.m12*self.m21*self.m33 + self.m12*self.m31*self.m23 + self.m13*self.m21*self.m32 - self.m13*self.m31*self.m22
	out.m01 = -self.m01*self.m22*self.m33 + self.m01*self.m32*self.m23 + self.m02*self.m21*self.m33 - self.m02*self.m31*self.m23 - self.m03*self.m21*self.m32 + self.m03*self.m31*self.m22
	out.m02 = self.m01*self.m12*self.m33 - self.m01*self.m32*self.m13 - self.m02*self.m11*self.m33 + self.m02*self.m31*self.m13 + self.m03*self.m11*self.m32 - self.m03*self.m31*self.m12
	out.m03 = -self.m01*self.m12*self.m23 + self.m01*self.m22*self.m13 + self.m02*self.m11*self.m23 - self.m02*self.m21*self.m13 - self.m03*self.m11*self.m22 + self.m03*self.m21*self.m12

	out.m10 = -self.m10*self.m22*self.m33 + self.m10*self.m32*self.m23 + self.m12*self.m20 *self.m33 - self.m12*self.m30*self.m23 - self.m13*self.m20 *self.m32 + self.m13*self.m30*self.m22
	out.m11 = self.m00*self.m22*self.m33 - self.m00*self.m32*self.m23 - self.m02*self.m20 *self.m33 + self.m02*self.m30*self.m23 + self.m03*self.m20 *self.m32 - self.m03*self.m30*self.m22
	out.m12 = -self.m00*self.m12*self.m33 + self.m00*self.m32*self.m13 + self.m02*self.m10*self.m33 - self.m02*self.m30*self.m13 - self.m03*self.m10*self.m32 + self.m03*self.m30*self.m12
	out.m13 = self.m00*self.m12*self.m23 - self.m00*self.m22*self.m13 - self.m02*self.m10*self.m23 + self.m02*self.m20 *self.m13 + self.m03*self.m10*self.m22 - self.m03*self.m20 *self.m12

	out.m20 = self.m10*self.m21*self.m33 - self.m10*self.m31*self.m23 - self.m11*self.m20 *self.m33 + self.m11*self.m30*self.m23 + self.m13*self.m20 *self.m31 - self.m13*self.m30*self.m21
	out.m21 = -self.m00*self.m21*self.m33 + self.m00*self.m31*self.m23 + self.m01*self.m20 *self.m33 - self.m01*self.m30*self.m23 - self.m03*self.m20 *self.m31 + self.m03*self.m30*self.m21
	out.m22 = self.m00*self.m11*self.m33 - self.m00*self.m31*self.m13 - self.m01*self.m10*self.m33 + self.m01*self.m30*self.m13 + self.m03*self.m10*self.m31 - self.m03*self.m30*self.m11
	out.m23 = -self.m00*self.m11*self.m23 + self.m00*self.m21*self.m13 + self.m01*self.m10*self.m23 - self.m01*self.m20 *self.m13 - self.m03*self.m10*self.m21 + self.m03*self.m20 *self.m11

	out.m30 = -self.m10*self.m21*self.m32 + self.m10*self.m31*self.m22 + self.m11*self.m20 *self.m32 - self.m11*self.m30*self.m22 - self.m12*self.m20 *self.m31 + self.m12*self.m30*self.m21
	out.m31 = self.m00*self.m21*self.m32 - self.m00*self.m31*self.m22 - self.m01*self.m20 *self.m32 + self.m01*self.m30*self.m22 + self.m02*self.m20 *self.m31 - self.m02*self.m30*self.m21
	out.m32 = -self.m00*self.m11*self.m32 + self.m00*self.m31*self.m12 + self.m01*self.m10*self.m32 - self.m01*self.m30*self.m12 - self.m02*self.m10*self.m31 + self.m02*self.m30*self.m11
	out.m33 = self.m00*self.m11*self.m22 - self.m00*self.m21*self.m12 - self.m01*self.m10*self.m22 + self.m01*self.m20 *self.m12 + self.m02*self.m10*self.m21 - self.m02*self.m20 *self.m11

	local det = 1 / (self.m00*out.m00 + self.m01*out.m10 + self.m02*out.m20 + self.m03*out.m30)

	out.m00 = out.m00 * det
	out.m01 = out.m01 * det
	out.m02 = out.m02 * det
	out.m03 = out.m03 * det
	out.m10 = out.m10 * det
	out.m11 = out.m11 * det
	out.m12 = out.m12 * det
	out.m13 = out.m13 * det
	out.m20 = out.m20 * det
	out.m21 = out.m21 * det
	out.m22 = out.m22 * det
	out.m23 = out.m23 * det
	out.m30 = out.m30 * det
	out.m31 = out.m31 * det
	out.m32 = out.m32 * det
	out.m33 = out.m33 * det

	return out
end

function META:GetTranspose(out)
	out = out or ctor(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)

	out.m00 = self.m00
	out.m01 = self.m10
	out.m02 = self.m20
	out.m03 = self.m30

	out.m10 = self.m01
	out.m11 = self.m11
	out.m12 = self.m21
	out.m13 = self.m31

	out.m20 = self.m02
	out.m21 = self.m12
	out.m22 = self.m22
	out.m23 = self.m32

	out.m30 = self.m03
	out.m31 = self.m13
	out.m32 = self.m23
	out.m33 = self.m33

	return out
end

function META.GetMultiplied(a, b, out)
	out = out or ctor(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)

	out.m00 = b.m00 * a.m00 + b.m01 * a.m10 + b.m02 * a.m20 + b.m03 * a.m30
	out.m01 = b.m00 * a.m01 + b.m01 * a.m11 + b.m02 * a.m21 + b.m03 * a.m31
	out.m02 = b.m00 * a.m02 + b.m01 * a.m12 + b.m02 * a.m22 + b.m03 * a.m32
	out.m03 = b.m00 * a.m03 + b.m01 * a.m13 + b.m02 * a.m23 + b.m03 * a.m33

	out.m10 = b.m10 * a.m00 + b.m11 * a.m10 + b.m12 * a.m20 + b.m13 * a.m30
	out.m11 = b.m10 * a.m01 + b.m11 * a.m11 + b.m12 * a.m21 + b.m13 * a.m31
	out.m12 = b.m10 * a.m02 + b.m11 * a.m12 + b.m12 * a.m22 + b.m13 * a.m32
	out.m13 = b.m10 * a.m03 + b.m11 * a.m13 + b.m12 * a.m23 + b.m13 * a.m33

	out.m20 = b.m20 * a.m00 + b.m21 * a.m10 + b.m22 * a.m20 + b.m23 * a.m30
	out.m21 = b.m20 * a.m01 + b.m21 * a.m11 + b.m22 * a.m21 + b.m23 * a.m31
	out.m22 = b.m20 * a.m02 + b.m21 * a.m12 + b.m22 * a.m22 + b.m23 * a.m32
	out.m23 = b.m20 * a.m03 + b.m21 * a.m13 + b.m22 * a.m23 + b.m23 * a.m33

	out.m30 = b.m30 * a.m00 + b.m31 * a.m10 + b.m32 * a.m20 + b.m33 * a.m30
	out.m31 = b.m30 * a.m01 + b.m31 * a.m11 + b.m32 * a.m21 + b.m33 * a.m31
	out.m32 = b.m30 * a.m02 + b.m31 * a.m12 + b.m32 * a.m22 + b.m33 * a.m32
	out.m33 = b.m30 * a.m03 + b.m31 * a.m13 + b.m32 * a.m23 + b.m33 * a.m33

	return out
end

META.Multiply = META.GetMultiplied

function META:Skew(x, y)
	y = y or x
	x = math.rad(x)
	y = math.rad(y)

	local skew = ctor(1,math.tan(x),0,0, math.tan(y),1,0,0, 0,0,1,0, 0,0,0,1)

	self:CopyTo(skew)

	return self
end

function META:GetTranslation()
	return self.m30, self.m31, self.m32
end

function META:GetClipCoordinates()
	return self.m30 / self.m33, self.m31 / self.m33, self.m32 / self.m33
end

function META:Translate(x, y, z)
	if x == 0 and y == 0 and z == 0 then return self end

	self.m30 = self.m00 * x + self.m10 * y + self.m20 * z + self.m30
	self.m31 = self.m01 * x + self.m11 * y + self.m21 * z + self.m31
	self.m32 = self.m02 * x + self.m12 * y + self.m22 * z + self.m32
	self.m33 = self.m03 * x + self.m13 * y + self.m23 * z + self.m33

	return self
end

function META:SetShear(x, y, z)
	self.m01 = x
	self.m10 = y
	-- z?
end

function META:SetTranslation(x, y, z)
	self.m30 = x
	self.m31 = y
	self.m32 = z

	return self
end

function META:Rotate(a, x, y, z, out)
	if a == 0 then return self end

	out = out or ctor(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)

	local xx, yy, zz, xy, yz, zx, xs, ys, zs, one_c
	local optimized = false

	local s = math.sin(a)
	local c = math.cos(a)

	if x == 0 then
		if y == 0 then
			if z ~= 0 then
				optimized = true
				-- rotate only around z axis

				out.m00 = c
				out.m11 = c

				if z < 0 then
					out.m10 = s
					out.m01 = -s
				else
					out.m10 = -s
					out.m01 = s
				end
			elseif z == 0 then
				optimized = true
				-- rotate only around y axis

				out.m00 = c
				out.m22 = c

				if y < 0 then
					out.m20 = -s
					out.m02 = s
				else
					out.m20 = s
					out.m02 = -s
				end
			end
		end
	elseif y == 0 then
		if z == 0 then
			optimized = true
			-- rotate only around x axis

			out.m11 = c
			out.m22 = c

			if x < 0 then
				out.m21 = s
				out.m12 = -s
			else
				out.m21 = -s
				out.m12 = s
			end
		end
	end

	if not optimized then
		local mag = math.sqrt(x * x + y * y + z * z)

		if mag <= 1.0e-4 then
			return
		end

		x = x / mag
		y = y / mag
		z = z / mag

		xx = x * x
		yy = y * y
		zz = z * z
		xy = x * y
		yz = y * z
		zx = z * x
		xs = x * s
		ys = y * s
		zs = z * s
		one_c = 1 - c

		out.m00 = (one_c * xx) + c
		out.m10 = (one_c * xy) - zs
		out.m20 = (one_c * zx) + ys

		out.m01 = (one_c * xy) + zs
		out.m11 = (one_c * yy) + c
		out.m21 = (one_c * yz) - xs

		out.m02 = (one_c * zx) - ys
		out.m12 = (one_c * yz) + xs
		out.m22 = (one_c * zz) + c

	end

	self.GetMultiplied(self:Copy(), out, self)

	return self
end

function META:Scale(x, y, z)
	if x == 1 and y == 1 and z == 1 then return self end

	self.m00 = self.m00 * x
	self.m10 = self.m10 * y
	self.m20 = self.m20 * z

	self.m01 = self.m01 * x
	self.m11 = self.m11 * y
	self.m21 = self.m21 * z

	self.m02 = self.m02 * x
	self.m12 = self.m12 * y
	self.m22 = self.m22 * z

	self.m03 = self.m03 * x
	self.m13 = self.m13 * y
	self.m23 = self.m23 * z

	return self
end

do -- projection
	function META:Perspective(fov, near, far, aspect)
		local yScale = 1.0 / math.tan(fov / 2)
		local xScale = yScale / aspect
		local nearmfar =  far - near

		self.m00 = xScale
		self.m01 = 0
		self.m02 = 0
		self.m03 = 0

		self.m10 = 0
		self.m11 = yScale
		self.m12 = 0
		self.m13 = 0

		self.m20 = 0
		self.m21 = 0
		self.m22 = (far + near) / nearmfar
		self.m23 = -1

		self.m30 = 0
		self.m31 = 0
		self.m32 = 2*far*near / nearmfar
		self.m33 = 0

		return self
	end

	function META:Frustum(l, r, b, t, n, f)
		local temp = 2.0 * n
		local temp2 = r - l
		local temp3 = t - b
		local temp4 = f - n

		self.m00 = temp / temp2
		self.m01 = 0.0
		self.m02 = 0.0
		self.m03 = 0.0
		self.m10 = 0.0
		self.m11 = temp / temp3
		self.m12 = 0.0
		self.m13 = 0.0
		self.m20 = (r + l) / temp2
		self.m21 = (t + b) / temp3
		self.m22 = (-f - n) / temp4
		self.m23 = -1.0
		self.m30 = 0.0
		self.m31 = 0.0
		self.m32 = (-temp * f) / temp4
		self.m33 = 0.0

		return self
	end

	function META:Ortho(left, right, bottom, top, near, far)
		self.m00 = 2 / (right - left)
		--self.m10 = 0
		--self.m20 = 0
		self.m30 = -(right + left) / (right - left)

	--	self.m01 = 0
		self.m11 = 2 / (top - bottom)
	--	self.m21 = 0
		self.m31 = -(top + bottom) / (top - bottom)

	--	self.m02 = 0
	--	self.m12 = 0
		self.m22 = -2 / (far - near)
		self.m32 = -(far + near) / (far - near)

	--	self.m03 = 0
	--	self.m13 = 0
	--	self.m23 = 0
	--	self.m33 = 1

		return self
	end
end

function META:TransformVector(x, y, z)
	local div = x * self.m03 + y * self.m13 + z * self.m23 + self.m33

	return
		(x * self.m00 + y * self.m10 + z * self.m20 + self.m30) / div,
		(x * self.m01 + y * self.m11 + z * self.m21 + self.m31) / div,
		(x * self.m02 + y * self.m12 + z * self.m22 + self.m32) / div
end

function META:TransformPoint(x, y, z)
	return
		self.m00 * x + self.m01 * y + self.m02 * z + self.m03,
		self.m10 * x + self.m11 * y + self.m12 * z + self.m13,
		self.m20 * x + self.m21 * y + self.m22 * z + self.m23
end

function META:Lerp(alpha, other)
	for i = 1, 16 do
		math.lerp(alpha, self[i-1], other[i-1])
	end
end

function META:GetRotation(out)
	local w = math.sqrt(1 + self.m00 + self.m11 + self.m22) / 2
	local w2 = w * 4

	local x = (self.m21 - self.m12) / w2
	local y = (self.m02 - self.m20 ) / w2
	local z = (self.m10 - self.m01) / w2

	out = out or structs.Quat()
	out:Set(x,y,z,w)

	return out
end

function META:SetRotation(q)
	local sqw = q.w*q.w
	local sqx = q.x*q.x
	local sqy = q.y*q.y
	local sqz = q.z*q.z

	-- invs (inverse square length) is only required if quaternion is not already normalised
	local invs = 1 / (sqx + sqy + sqz + sqw)

	self.m00 = ( sqx - sqy - sqz + sqw)*invs -- since sqw + sqx + sqy + sqz =1/invs*invs
	self.m11 = (-sqx + sqy - sqz + sqw)*invs
	self.m22 = (-sqx - sqy + sqz + sqw)*invs

	local tmp1, tmp2

	tmp1 = q.x*q.y;
	tmp2 = q.z*q.w;
	self.m10 = 2.0 * (tmp1 + tmp2)*invs
	self.m01 = 2.0 * (tmp1 - tmp2)*invs

	tmp1 = q.x*q.z
	tmp2 = q.y*q.w
	self.m20 = 2.0 * (tmp1 - tmp2)*invs
	self.m02 = 2.0 * (tmp1 + tmp2)*invs

	tmp1 = q.y*q.z
	tmp2 = q.x*q.w
	self.m21 = 2.0 * (tmp1 + tmp2)*invs
	self.m12 = 2.0 * (tmp1 - tmp2)*invs

	return self
end

function META:SetAngles(ang)
	self:SetRotation(Quat():SetAngles(ang))
end

function META:GetAngles()
	return self:GetRotation():GetAngles()
end

if ffi then
	ffi.metatype(ctor, META)
end

function Matrix44(x, y, z)
	return ctor(1,0,0,0, 0,1,0,0, 0,0,1,0, x or 0, y or 0, z or 0,1)
end

META:Register()