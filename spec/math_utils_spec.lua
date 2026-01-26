local MathUtils = require("src.utils.math")

-- Tolerance for floating point comparisons
local EPSILON = 0.0001

local function near(a, b, tolerance)
    tolerance = tolerance or EPSILON
    return math.abs(a - b) < tolerance
end

describe("MathUtils", function()
    describe("distance()", function()
        it("should return distance between two points", function()
            local d = MathUtils.distance(0, 0, 3, 4)
            assert.is_true(near(d, 5))
        end)

        it("should return 0 for identical points", function()
            local d = MathUtils.distance(5, 5, 5, 5)
            assert.are.equal(0, d)
        end)

        it("should work with negative coordinates", function()
            local d = MathUtils.distance(-3, -4, 0, 0)
            assert.is_true(near(d, 5))
        end)
    end)

    describe("distanceSquared()", function()
        it("should return squared distance", function()
            local d = MathUtils.distanceSquared(0, 0, 3, 4)
            assert.are.equal(25, d)
        end)
    end)

    describe("length()", function()
        it("should return length of vector (3, 4) as 5", function()
            local len = MathUtils.length(3, 4)
            assert.is_true(near(len, 5))
        end)

        it("should return 0 for zero vector", function()
            local len = MathUtils.length(0, 0)
            assert.are.equal(0, len)
        end)
    end)

    describe("normalize()", function()
        it("should return vector with length 1", function()
            local vx, vy = MathUtils.normalize(3, 4)
            local len = MathUtils.length(vx, vy)
            assert.is_true(near(len, 1))
        end)

        it("should return (0, 0) for zero vector", function()
            local vx, vy = MathUtils.normalize(0, 0)
            assert.are.equal(0, vx)
            assert.are.equal(0, vy)
        end)

        it("should maintain correct direction", function()
            local vx, vy = MathUtils.normalize(3, 4)
            -- Original ratio: 3/4 = 0.75
            -- Normalized should maintain same ratio
            assert.is_true(near(vx / vy, 0.75))
            -- Also verify actual values
            assert.is_true(near(vx, 0.6))
            assert.is_true(near(vy, 0.8))
        end)
    end)

    describe("angle()", function()
        it("should return 0 for angle to the right", function()
            local a = MathUtils.angle(0, 0, 10, 0)
            assert.is_true(near(a, 0))
        end)

        it("should return pi/2 for angle downward", function()
            local a = MathUtils.angle(0, 0, 0, 10)
            assert.is_true(near(a, math.pi / 2))
        end)

        it("should return pi or -pi for angle to the left", function()
            local a = MathUtils.angle(0, 0, -10, 0)
            -- atan2 returns pi for left direction
            assert.is_true(near(math.abs(a), math.pi))
        end)
    end)

    describe("direction()", function()
        it("should return (speed, 0) for angle 0", function()
            local vx, vy = MathUtils.direction(0, 10)
            assert.is_true(near(vx, 10))
            assert.is_true(near(vy, 0))
        end)

        it("should return (0, speed) for angle pi/2", function()
            local vx, vy = MathUtils.direction(math.pi / 2, 10)
            assert.is_true(near(vx, 0))
            assert.is_true(near(vy, 10))
        end)
    end)

    describe("lerp()", function()
        it("should return a when t is 0", function()
            local result = MathUtils.lerp(0, 10, 0)
            assert.are.equal(0, result)
        end)

        it("should return b when t is 1", function()
            local result = MathUtils.lerp(0, 10, 1)
            assert.are.equal(10, result)
        end)

        it("should return midpoint when t is 0.5", function()
            local result = MathUtils.lerp(0, 10, 0.5)
            assert.are.equal(5, result)
        end)

        it("should work with negative values", function()
            local result = MathUtils.lerp(-10, 10, 0.5)
            assert.are.equal(0, result)

            result = MathUtils.lerp(-20, -10, 0.5)
            assert.are.equal(-15, result)
        end)
    end)

    describe("clamp()", function()
        it("should not change value inside range", function()
            local result = MathUtils.clamp(5, 0, 10)
            assert.are.equal(5, result)
        end)

        it("should return min when value is below", function()
            local result = MathUtils.clamp(-5, 0, 10)
            assert.are.equal(0, result)
        end)

        it("should return max when value is above", function()
            local result = MathUtils.clamp(15, 0, 10)
            assert.are.equal(10, result)
        end)
    end)
end)
