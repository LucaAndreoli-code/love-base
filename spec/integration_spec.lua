local Entity = require("src.systems.entity")
local EntityManager = require("src.systems.entity_manager")
local StateMachine = require("src.systems.state_machine")
local MathUtils = require("src.utils.math")
local CollisionUtils = require("src.utils.collision")
local Logger = require("src.logger")

describe("Integration Tests", function()
    setup(function()
        Logger.disable()
    end)

    teardown(function()
        Logger.enable()
    end)

    describe("Entity + EntityManager", function()
        local manager

        before_each(function()
            manager = EntityManager.new()
        end)

        it("should create multiple entities with different tags and query correctly", function()
            local player = Entity.new({ tags = { "player", "collidable" } })
            local enemy1 = Entity.new({ tags = { "enemy", "collidable" } })
            local enemy2 = Entity.new({ tags = { "enemy", "collidable" } })
            local powerup = Entity.new({ tags = { "powerup" } })

            manager:add(player)
            manager:add(enemy1)
            manager:add(enemy2)
            manager:add(powerup)

            -- Verify getByTag returns correct entities
            local players = manager:getByTag("player")
            assert.is_true(players[player])
            assert.is_nil(players[enemy1])

            local enemies = manager:getByTag("enemy")
            assert.is_true(enemies[enemy1])
            assert.is_true(enemies[enemy2])
            assert.is_nil(enemies[player])

            local collidables = manager:getByTag("collidable")
            assert.is_true(collidables[player])
            assert.is_true(collidables[enemy1])
            assert.is_true(collidables[enemy2])
            assert.is_nil(collidables[powerup])

            local powerups = manager:getByTag("powerup")
            assert.is_true(powerups[powerup])
        end)

        it("should update cache when refreshTags is called after tag modification", function()
            local entity = Entity.new({ tags = { "enemy" } })
            manager:add(entity)

            assert.is_true(manager:getByTag("enemy")[entity])
            assert.is_nil(manager:getByTag("boss")[entity])

            -- Modify tags
            entity:removeTag("enemy")
            entity:addTag("boss")

            -- Cache is stale before refresh
            assert.is_true(manager:getByTag("enemy")[entity])  -- Still in old cache

            -- Refresh cache
            manager:refreshTags(entity)

            -- Now cache is updated
            assert.is_nil(manager:getByTag("enemy")[entity])
            assert.is_true(manager:getByTag("boss")[entity])
        end)

        it("should remove destroyed entities after cleanup", function()
            local e1 = Entity.new({ tags = { "a" } })
            local e2 = Entity.new({ tags = { "b" } })
            local e3 = Entity.new({ tags = { "c" } })

            manager:add(e1)
            manager:add(e2)
            manager:add(e3)

            assert.are.equal(3, #manager.entities)

            -- Destroy some entities
            e1:destroy()
            e3:destroy()

            -- Still 3 in the list (not cleaned up yet)
            assert.are.equal(3, #manager.entities)

            -- Cleanup
            manager:cleanup()

            -- Now only 1 remains
            assert.are.equal(1, #manager.entities)
            assert.are.equal(e2, manager.entities[1])

            -- Verify cache is also cleaned
            assert.is_nil(manager:getByTag("a")[e1])
            assert.is_nil(manager:getByTag("c")[e3])
            assert.is_true(manager:getByTag("b")[e2])
        end)
    end)

    describe("Entity + EntityManager + MathUtils", function()
        local manager

        before_each(function()
            manager = EntityManager.new()
        end)

        it("should update entity positions based on velocity", function()
            local e1 = Entity.new({ x = 0, y = 0, vx = 100, vy = 50 })
            local e2 = Entity.new({ x = 200, y = 100, vx = -50, vy = 25 })

            manager:add(e1)
            manager:add(e2)

            local dt = 0.5
            manager:update(dt)

            -- e1: x = 0 + 100*0.5 = 50, y = 0 + 50*0.5 = 25
            assert.are.equal(50, e1.x)
            assert.are.equal(25, e1.y)

            -- e2: x = 200 + (-50)*0.5 = 175, y = 100 + 25*0.5 = 112.5
            assert.are.equal(175, e2.x)
            assert.are.equal(112.5, e2.y)
        end)

        it("should calculate distance between entities using MathUtils", function()
            local e1 = Entity.new({ x = 0, y = 0 })
            local e2 = Entity.new({ x = 30, y = 40 })

            manager:add(e1)
            manager:add(e2)

            local distance = MathUtils.distance(e1.x, e1.y, e2.x, e2.y)
            assert.are.equal(50, distance)  -- 3-4-5 triangle scaled by 10
        end)

        it("should track distance changes after movement", function()
            local e1 = Entity.new({ x = 0, y = 0, vx = 10, vy = 0 })
            local e2 = Entity.new({ x = 100, y = 0, vx = 0, vy = 0 })

            manager:add(e1)
            manager:add(e2)

            local initialDistance = MathUtils.distance(e1.x, e1.y, e2.x, e2.y)
            assert.are.equal(100, initialDistance)

            -- Move entities (e1 moves towards e2)
            manager:update(1.0)

            local newDistance = MathUtils.distance(e1.x, e1.y, e2.x, e2.y)
            assert.are.equal(90, newDistance)
        end)
    end)

    describe("Entity + EntityManager + CollisionUtils", function()
        local manager

        before_each(function()
            manager = EntityManager.new()
        end)

        it("should detect collision between overlapping entities", function()
            local bullet = Entity.new({ x = 100, y = 100, radius = 5, tags = { "bullet" } })
            local asteroid = Entity.new({ x = 103, y = 104, radius = 20, tags = { "asteroid" } })

            manager:add(bullet)
            manager:add(asteroid)

            local bullets = manager:getByTag("bullet")
            local asteroids = manager:getByTag("asteroid")

            -- Check collision
            for b, _ in pairs(bullets) do
                for a, _ in pairs(asteroids) do
                    assert.is_true(CollisionUtils.circleCircle(b, a))
                end
            end
        end)

        it("should not detect collision between distant entities", function()
            local bullet = Entity.new({ x = 100, y = 100, radius = 5, tags = { "bullet" } })
            local asteroid = Entity.new({ x = 300, y = 300, radius = 20, tags = { "asteroid" } })

            manager:add(bullet)
            manager:add(asteroid)

            local bullets = manager:getByTag("bullet")
            local asteroids = manager:getByTag("asteroid")

            -- Check no collision
            for b, _ in pairs(bullets) do
                for a, _ in pairs(asteroids) do
                    assert.is_false(CollisionUtils.circleCircle(b, a))
                end
            end
        end)

        it("should destroy colliding entities and cleanup correctly", function()
            local bullet = Entity.new({ x = 100, y = 100, radius = 5, tags = { "bullet" } })
            local asteroid = Entity.new({ x = 103, y = 104, radius = 20, tags = { "asteroid" } })

            manager:add(bullet)
            manager:add(asteroid)

            -- Simulate collision detection and destruction
            local bullets = manager:getByTag("bullet")
            local asteroids = manager:getByTag("asteroid")

            for b, _ in pairs(bullets) do
                for a, _ in pairs(asteroids) do
                    if CollisionUtils.circleCircle(b, a) then
                        b:destroy()
                        a:destroy()
                    end
                end
            end

            -- Both should be marked dead
            assert.is_false(bullet.alive)
            assert.is_false(asteroid.alive)

            -- Cleanup
            manager:cleanup()

            -- Entities removed
            assert.are.equal(0, #manager.entities)
            assert.are.equal(0, manager:count())
        end)
    end)

    describe("StateMachine + Entity + EntityManager", function()
        it("should create and clear entities when changing states", function()
            local sm = StateMachine.new()
            local gameManager

            sm:addState("menu", {})
            sm:addState("playing", {
                enter = function()
                    gameManager = EntityManager.new()
                    gameManager:add(Entity.new({ tags = { "player" } }))
                    gameManager:add(Entity.new({ tags = { "enemy" } }))
                    gameManager:add(Entity.new({ tags = { "enemy" } }))
                end,
                exit = function()
                    gameManager:clear()
                end
            })

            -- Start at menu
            sm:setState("menu")
            assert.is_nil(gameManager)

            -- Go to playing - entities created
            sm:setState("playing")
            assert.is_not_nil(gameManager)
            assert.are.equal(3, #gameManager.entities)

            -- Back to menu - entities cleared
            sm:setState("menu")
            assert.are.equal(0, #gameManager.entities)
        end)
    end)

    describe("StateMachine push/pop with game logic", function()
        it("should only update the topmost state", function()
            local sm = StateMachine.new()
            local manager = EntityManager.new()
            local playingUpdated = false
            local pauseUpdated = false

            local entity = Entity.new({ x = 0, y = 0, vx = 100, vy = 0 })
            manager:add(entity)

            sm:addState("playing", {
                update = function(dt)
                    playingUpdated = true
                    manager:update(dt)
                end,
                pause = function()
                    -- Reset flag to track if playing.update runs during pause
                    playingUpdated = false
                end,
                resume = function()
                    -- Resume playing
                end
            })

            sm:addState("pause", {
                update = function(dt)
                    pauseUpdated = true
                    -- Pause screen doesn't update game entities
                end
            })

            -- Playing state
            sm:setState("playing")
            sm:update(1.0)

            assert.is_true(playingUpdated)
            assert.are.equal(100, entity.x)

            -- Reset and push pause
            playingUpdated = false
            sm:pushState("pause")

            -- Verify pause callback was called
            assert.is_false(playingUpdated)  -- Was reset by pause callback

            -- Update while paused
            sm:update(1.0)

            -- Only pause update ran, not playing
            assert.is_true(pauseUpdated)
            assert.is_false(playingUpdated)
            assert.are.equal(100, entity.x)  -- Entity didn't move

            -- Pop pause and resume
            pauseUpdated = false
            sm:popState()
            sm:update(1.0)

            -- Playing update runs again
            assert.is_true(playingUpdated)
            assert.are.equal(200, entity.x)  -- Entity moved again
        end)
    end)

    describe("Complete game loop simulation", function()
        it("should handle multi-frame game simulation with collisions", function()
            local sm = StateMachine.new()
            local manager
            local player, asteroid, bullet

            sm:addState("playing", {
                enter = function()
                    manager = EntityManager.new()
                    player = Entity.new({ x = 100, y = 300, radius = 10, tags = { "player" } })
                    asteroid = Entity.new({ x = 500, y = 100, radius = 30, tags = { "asteroid" } })
                    manager:add(player)
                    manager:add(asteroid)
                end,
                update = function(dt)
                    manager:update(dt)

                    -- Check bullet-asteroid collisions
                    local bullets = manager:getByTag("bullet")
                    local asteroids = manager:getByTag("asteroid")

                    for b, _ in pairs(bullets) do
                        for a, _ in pairs(asteroids) do
                            if b.alive and a.alive and CollisionUtils.circleCircle(b, a) then
                                b:destroy()
                                a:destroy()
                            end
                        end
                    end

                    manager:cleanup()
                end
            })

            -- Frame 1: Setup
            sm:setState("playing")
            assert.are.equal(2, manager:count())

            -- Frame 2: Fire bullet towards asteroid
            bullet = Entity.new({
                x = player.x,
                y = player.y,
                vx = 200,
                vy = -100,
                radius = 3,
                tags = { "bullet" }
            })
            manager:add(bullet)
            assert.are.equal(3, manager:count())

            -- No collision yet
            sm:update(1/60)  -- 1 frame at 60fps
            assert.is_true(bullet.alive)
            assert.is_true(asteroid.alive)

            -- Frame 3-N: Simulate until collision
            -- Move bullet directly to asteroid position for test
            bullet.x = asteroid.x
            bullet.y = asteroid.y

            sm:update(1/60)

            -- Collision detected, both destroyed and cleaned up
            assert.is_false(bullet.alive)
            assert.is_false(asteroid.alive)
            assert.are.equal(1, manager:count())  -- Only player remains

            -- Verify final state
            assert.is_true(player.alive)
            local players = manager:getByTag("player")
            assert.is_true(players[player])
        end)
    end)

    describe("Query and filtering", function()
        local manager

        before_each(function()
            manager = EntityManager.new()
        end)

        it("should handle complex tag queries correctly", function()
            -- Create 10 entities with various tags
            local asteroids = {}
            local bullets = {}
            local powerups = {}
            local largeAsteroids = {}

            -- 3 entities with tag "asteroid" only
            for i = 1, 3 do
                local e = Entity.new({ tags = { "asteroid" } })
                table.insert(asteroids, e)
                manager:add(e)
            end

            -- 3 entities with tag "bullet"
            for i = 1, 3 do
                local e = Entity.new({ tags = { "bullet" } })
                table.insert(bullets, e)
                manager:add(e)
            end

            -- 2 entities with tag "powerup"
            for i = 1, 2 do
                local e = Entity.new({ tags = { "powerup" } })
                table.insert(powerups, e)
                manager:add(e)
            end

            -- 2 entities with both "asteroid" and "large"
            for i = 1, 2 do
                local e = Entity.new({ tags = { "asteroid", "large" } })
                table.insert(largeAsteroids, e)
                manager:add(e)
            end

            -- Verify counts
            assert.are.equal(10, #manager.entities)

            -- getByTag("asteroid") should return 5 (3 + 2 large)
            local asteroidGroup = manager:getByTag("asteroid")
            local asteroidCount = 0
            for _, _ in pairs(asteroidGroup) do
                asteroidCount = asteroidCount + 1
            end
            assert.are.equal(5, asteroidCount)

            -- getByTag("large") should return 2
            local largeGroup = manager:getByTag("large")
            local largeCount = 0
            for _, _ in pairs(largeGroup) do
                largeCount = largeCount + 1
            end
            assert.are.equal(2, largeCount)

            -- getByTag("bullet") should return 3
            local bulletGroup = manager:getByTag("bullet")
            local bulletCount = 0
            for _, _ in pairs(bulletGroup) do
                bulletCount = bulletCount + 1
            end
            assert.are.equal(3, bulletCount)

            -- Destroy all bullets
            for _, b in ipairs(bullets) do
                b:destroy()
            end
            manager:cleanup()

            -- Verify count decreased
            assert.are.equal(7, #manager.entities)
            assert.are.equal(7, manager:count())

            -- getByTag("bullet") should now be empty
            local remainingBullets = manager:getByTag("bullet")
            local remainingBulletCount = 0
            for _, _ in pairs(remainingBullets) do
                remainingBulletCount = remainingBulletCount + 1
            end
            assert.are.equal(0, remainingBulletCount)

            -- Asteroid count unchanged
            local asteroidGroupAfter = manager:getByTag("asteroid")
            local asteroidCountAfter = 0
            for _, _ in pairs(asteroidGroupAfter) do
                asteroidCountAfter = asteroidCountAfter + 1
            end
            assert.are.equal(5, asteroidCountAfter)
        end)
    end)

    describe("Edge cases and robustness", function()
        it("should handle entity with no tags", function()
            local manager = EntityManager.new()
            local entity = Entity.new({ x = 100, y = 100 })

            manager:add(entity)

            assert.are.equal(1, #manager.entities)
            assert.are.same({}, manager:getByTag("anything"))
        end)

        it("should handle rapid tag changes with refresh", function()
            local manager = EntityManager.new()
            local entity = Entity.new({ tags = { "a" } })

            manager:add(entity)

            -- Multiple tag changes
            entity:removeTag("a")
            entity:addTag("b")
            entity:addTag("c")
            entity:removeTag("b")
            entity:addTag("d")

            manager:refreshTags(entity)

            -- Only c and d remain
            assert.is_nil(manager:getByTag("a")[entity])
            assert.is_nil(manager:getByTag("b")[entity])
            assert.is_true(manager:getByTag("c")[entity])
            assert.is_true(manager:getByTag("d")[entity])
        end)

        it("should handle state machine with shared entity manager", function()
            local sm = StateMachine.new()
            local sharedManager = EntityManager.new()

            sm:addState("menu", {
                enter = function()
                    sharedManager:clear()
                    sharedManager:add(Entity.new({ tags = { "ui" } }))
                end
            })

            sm:addState("playing", {
                enter = function()
                    sharedManager:clear()
                    sharedManager:add(Entity.new({ tags = { "player" } }))
                    sharedManager:add(Entity.new({ tags = { "enemy" } }))
                end
            })

            -- Start in menu
            sm:setState("menu")
            assert.are.equal(1, sharedManager:count())

            local uiCount = 0
            for _, _ in pairs(sharedManager:getByTag("ui")) do
                uiCount = uiCount + 1
            end
            assert.are.equal(1, uiCount)

            -- Switch to playing
            sm:setState("playing")
            assert.are.equal(2, sharedManager:count())

            local playerCount = 0
            for _, _ in pairs(sharedManager:getByTag("player")) do
                playerCount = playerCount + 1
            end
            assert.are.equal(1, playerCount)

            -- UI should be gone
            local uiCountAfter = 0
            for _, _ in pairs(sharedManager:getByTag("ui")) do
                uiCountAfter = uiCountAfter + 1
            end
            assert.are.equal(0, uiCountAfter)
        end)

        it("should handle MathUtils with entities at same position", function()
            local e1 = Entity.new({ x = 100, y = 100 })
            local e2 = Entity.new({ x = 100, y = 100 })

            local dist = MathUtils.distance(e1.x, e1.y, e2.x, e2.y)
            assert.are.equal(0, dist)

            local angle = MathUtils.angle(e1.x, e1.y, e2.x, e2.y)
            assert.are.equal(0, angle)  -- atan2(0, 0) = 0
        end)

        it("should handle collision detection with zero-radius entities", function()
            local e1 = Entity.new({ x = 100, y = 100, radius = 0 })
            local e2 = Entity.new({ x = 100, y = 100, radius = 0 })

            -- Same position, zero radius - should collide (touching)
            assert.is_true(CollisionUtils.circleCircle(e1, e2))

            -- Different position, zero radius - should not collide
            e2.x = 101
            assert.is_false(CollisionUtils.circleCircle(e1, e2))
        end)
    end)
end)
