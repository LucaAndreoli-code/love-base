local CollisionUtils = require("src.utils.collision")

describe("CollisionUtils", function()
    describe("circleCircle()", function()
        it("should return true for overlapping circles", function()
            local a = { x = 0, y = 0, radius = 10 }
            local b = { x = 15, y = 0, radius = 10 }
            assert.is_true(CollisionUtils.circleCircle(a, b))
        end)

        it("should return false for distant circles", function()
            local a = { x = 0, y = 0, radius = 10 }
            local b = { x = 50, y = 0, radius = 10 }
            assert.is_false(CollisionUtils.circleCircle(a, b))
        end)

        it("should return true for circles touching exactly", function()
            local a = { x = 0, y = 0, radius = 10 }
            local b = { x = 20, y = 0, radius = 10 }
            assert.is_true(CollisionUtils.circleCircle(a, b))
        end)

        it("should return true for circles with same center", function()
            local a = { x = 5, y = 5, radius = 10 }
            local b = { x = 5, y = 5, radius = 5 }
            assert.is_true(CollisionUtils.circleCircle(a, b))
        end)
    end)

    describe("rectRect()", function()
        it("should return true for overlapping rectangles", function()
            local a = { x = 0, y = 0, width = 20, height = 20 }
            local b = { x = 10, y = 10, width = 20, height = 20 }
            assert.is_true(CollisionUtils.rectRect(a, b))
        end)

        it("should return false for distant rectangles", function()
            local a = { x = 0, y = 0, width = 20, height = 20 }
            local b = { x = 50, y = 50, width = 20, height = 20 }
            assert.is_false(CollisionUtils.rectRect(a, b))
        end)

        it("should return true for rectangles touching on edge", function()
            local a = { x = 0, y = 0, width = 20, height = 20 }
            local b = { x = 20, y = 0, width = 20, height = 20 }
            assert.is_true(CollisionUtils.rectRect(a, b))
        end)

        it("should return true for rectangles with same center", function()
            local a = { x = 10, y = 10, width = 20, height = 20 }
            local b = { x = 10, y = 10, width = 10, height = 10 }
            assert.is_true(CollisionUtils.rectRect(a, b))
        end)
    end)

    describe("circleRect()", function()
        it("should return true for circle inside rectangle", function()
            local circle = { x = 10, y = 10, radius = 5 }
            local rect = { x = 10, y = 10, width = 50, height = 50 }
            assert.is_true(CollisionUtils.circleRect(circle, rect))
        end)

        it("should return false for circle outside rectangle", function()
            local circle = { x = 100, y = 100, radius = 5 }
            local rect = { x = 10, y = 10, width = 20, height = 20 }
            assert.is_false(CollisionUtils.circleRect(circle, rect))
        end)

        it("should return true for circle touching rectangle edge", function()
            local circle = { x = 30, y = 10, radius = 5 }
            local rect = { x = 10, y = 10, width = 30, height = 20 }
            -- rect right edge at x = 25, circle left at x = 25
            assert.is_true(CollisionUtils.circleRect(circle, rect))
        end)

        it("should return true for circle touching rectangle corner", function()
            -- Rect from (0,0) to (20,20), center at (10,10)
            local rect = { x = 10, y = 10, width = 20, height = 20 }
            -- Circle at corner with radius that just reaches
            local circle = { x = 25, y = 25, radius = 10 }
            -- Distance from (20,20) to (25,25) = sqrt(50) ≈ 7.07, radius 10 covers it
            assert.is_true(CollisionUtils.circleRect(circle, rect))
        end)
    end)

    describe("pointCircle()", function()
        it("should return true for point inside circle", function()
            local circle = { x = 10, y = 10, radius = 10 }
            assert.is_true(CollisionUtils.pointCircle(12, 12, circle))
        end)

        it("should return false for point outside circle", function()
            local circle = { x = 10, y = 10, radius = 10 }
            assert.is_false(CollisionUtils.pointCircle(50, 50, circle))
        end)

        it("should return true for point on circle edge", function()
            local circle = { x = 0, y = 0, radius = 10 }
            assert.is_true(CollisionUtils.pointCircle(10, 0, circle))
        end)

        it("should return true for point at circle center", function()
            local circle = { x = 10, y = 10, radius = 10 }
            assert.is_true(CollisionUtils.pointCircle(10, 10, circle))
        end)
    end)

    describe("pointRect()", function()
        it("should return true for point inside rectangle", function()
            local rect = { x = 10, y = 10, width = 20, height = 20 }
            assert.is_true(CollisionUtils.pointRect(12, 12, rect))
        end)

        it("should return false for point outside rectangle", function()
            local rect = { x = 10, y = 10, width = 20, height = 20 }
            assert.is_false(CollisionUtils.pointRect(50, 50, rect))
        end)

        it("should return true for point on rectangle edge", function()
            local rect = { x = 10, y = 10, width = 20, height = 20 }
            -- Left edge at x = 0
            assert.is_true(CollisionUtils.pointRect(0, 10, rect))
        end)

        it("should return true for point at rectangle center", function()
            local rect = { x = 10, y = 10, width = 20, height = 20 }
            assert.is_true(CollisionUtils.pointRect(10, 10, rect))
        end)
    end)
end)
