

-- In logical coordinates, every game field is of size 10×10 with (0, 0) at the bottom left

-- Types of enemies:
--
-- 1 (world 1) : idle
-- 2 (world 2) : drops bombs
-- 3 (world 1) : fires at us
-- 4 (world 2) : drops bombs and fires at us
-- 5 : like 3/4 but with electrical power

-- Bonuses:
--
-- Life
-- Better weapon
-- Bomb

function initialize()
   game_size = 600
   
   ship_x = 5
   ship_y = 0.7
   ship_speed_x = 0
   ship_max_speed_x = 9
   ship_a_x = 500
   ship_d_x = 500
   
   guy_x = 55
   guy_y = 3.5
   landscape_x = 50
   speed_guy_y = 0
   speed_guy_x = 0
   a_guy_x = 2
   
   speed = 7.5
   speed_b = 5
   speed_e = 3
   speed_l = 1
   
   bullets = {}
   e_bullets = {}
   e_bombs = {}
   enemies = {}
   
   double_jump = false

   -- Generation of the field

   field = {}

   function create_column(i)
      x = love.math.random(1,3)
      column = {}
      for i = 0, 9 do
         if i < x  then column[i] = true else column[i] = false end
      end
      field[i] = column
   end

   for i = -1,101 do
      create_column(i)
   end
end

function sx(x)
   return (x * game_size / 10)
end

function sy(y)
   return ((10 - y) * game_size / 10)
end

function px(x)
   return ((x - landscape_x) * game_size / 10 + game_size)
end

function py(y)
   return ((10 - y) * game_size / 10)
end

function love.load()
   background_img = love.graphics.newImage("res/images/background.png")
   ship_img = love.graphics.newImage("res/images/ship.png")
   bullet_img = love.graphics.newImage("res/images/bullet.png")
   enemy_img = love.graphics.newImage("res/images/enemy.png")
   enemy2_img = love.graphics.newImage("res/images/enemy2.png")
   guy_img = love.graphics.newImage("res/images/guy.png")
   e_bullet_img = love.graphics.newImage("res/images/e_bullet.png")
   e_bomb_img = love.graphics.newImage("res/images/e_bomb.png")
   ground_img = love.graphics.newImage("res/images/ground.png")
   canon_img = love.graphics.newImage("res/images/canon.png")

   initialize()
end

function love.draw()
   -- love.graphics.setColor(255, 0, 0)
   -- love.graphics.rectangle("line", 0, 0, game_size, game_size)
   -- love.graphics.rectangle("line", game_size, 0, game_size, game_size)
   love.graphics.setColor(209, 209, 209)
   love.graphics.rectangle("fill", 0, 0, 1200, 600)

   -- Platform
   landscape_x = guy_x - 5
   if landscape_x < 0 then landscape_x = 0 end
   if landscape_x > 90 then landscape_x = 90 end


   love.graphics.setColor(255, 255, 255)
   love.graphics.draw(guy_img, px(guy_x), py(guy_y), 0, 1, 1, 27, 23)

   for i = math.floor(landscape_x), math.floor(landscape_x) + 10 do
      for j = 0, 9 do
         if field[i][j] then
            love.graphics.draw(ground_img, px(i), py(j + 1))
            -- love.graphics.rectangle("fill", px(i), py(j + 1),
            --                         game_size / 10, game_size / 10)
         end
      end
   end

   love.graphics.setColor(209, 209, 209)
   love.graphics.rectangle("fill", 0, 0, 600, 600)

   love.graphics.setColor(255, 255, 255)
   for _, b in pairs(enemies) do
      if b.world == 2 then
         love.graphics.draw(enemy2_img, px(b.x), py(b.y), 0, 1, 1, 24, 24)
         if b.type >= 2 then
            love.graphics.draw(canon_img, px(b.x), py(b.y), math.pi/2 - math.atan2(guy_y - b.y, guy_x - b.x), 1, 1, 15, 15)
         end
      end
   end

   for _, b in pairs(e_bombs) do
      love.graphics.draw(e_bomb_img, px(b.x), py(b.y), 0, 1, 1, 7, 7)
   end

   for _, b in pairs(e_bullets) do
      if b.world == 2 then
         love.graphics.draw(e_bullet_img, px(b.x), py(b.y), 0, 1, 1, 4, 4)
      end
   end

   -- Shoot them up

   love.graphics.setColor(255, 255, 255)

   love.graphics.draw(ship_img, sx(ship_x), sy(ship_y), 0, 1, 1, 27, 27)

   for _, b in pairs(bullets) do
      love.graphics.draw(bullet_img, sx(b.x), sy(b.y), 0, 1, 1, 4, 6)
   end

   for _, b in pairs(enemies) do
      if b.world == 1 then
         love.graphics.draw(enemy_img, sx(b.x), sy(b.y), 0, 1, 1, 24, 24)
         if b.type >= 2 then
            love.graphics.draw(canon_img, sx(b.x), sy(b.y), math.pi/2 - math.atan2(ship_y - b.y, ship_x - b.x), 1, 1, 15, 15)
         end
      end
   end

   for _, b in pairs(e_bullets) do
      if b.world == 1 then
         love.graphics.draw(e_bullet_img, sx(b.x), sy(b.y), 0, 1, 1, 4, 4)
      end
   end

   love.graphics.setColor(255, 255, 255)
   love.graphics.draw(background_img, 0, 0)
end

function update_e(enemy, dt)
   if enemy.world == 1 then
      enemy.y = enemy.y - speed_e * dt
      if enemy.y < 0 then mutate(enemy) end
      if enemy.type == 2 then
         if math.random(1,150) == 1 then enemy.fire(enemy.x, enemy.y, 1) end
      elseif enemy.type >= 3 then
         if math.random(1,75) == 1 then enemy.fire(enemy.x, enemy.y, 1) end
      end
   else
      enemy.x = enemy.x - speed_e * dt
      if enemy.x < landscape_x + 0.3 then mutate(enemy) end
      if math.random(1,150) == 1 then enemy.bomb(enemy.x, enemy.y) end
      if enemy.type >= 2 and math.random(1,75) == 1 then enemy.fire(enemy.x, enemy.y, 2) end
   end
end

function mutate(enemy)
   if enemy.world == 1 then
      enemy.world = 2
      enemy.y = enemy.x / 2 + 5
      enemy.x = 10 + landscape_x
   else
      enemy.world = 1
      enemy.type = enemy.type + 1
      enemy.x = (enemy.y - 5) * 2
      enemy.y = 10
   end
end

function bomb_enemy(x, y)
   function update(bullet, dt)
      bullet.speed = bullet.speed + 4 * dt
      bullet.y = bullet.y - bullet.speed * dt
   end
   bullet1 = {x = x; y = y - 2/6; speed = 2; upd = update}
   table.insert(e_bombs, bullet1)
end

function fire_enemy(x, y, world)
   function update(bullet, dt)
      bullet.x = bullet.x - bullet.speed * dt * math.cos(bullet.angle)
      bullet.y = bullet.y - bullet.speed * dt * math.sin(bullet.angle)
   end
   local player_x, player_y
   if world == 1 then
      player_x, player_y = ship_x, ship_y
   else
      player_x, player_y = guy_x, guy_y
   end
   bullet1 = {world = world; x = x; y = y; speed = speed_b; angle = math.atan2(y - player_y, x - player_x); upd = update}
   table.insert(e_bullets, bullet1)
end

function new_enemy(x)
   x = x or love.math.random() * 9 + 0.5

   enemy = {world = 1; type = 1; x = x; y = 10; size = 25/60; upd = update_e; bomb = bomb_enemy; fire = fire_enemy}
   table.insert(enemies, enemy)
end

epsilon = 0.001

function love.update(dt)
   if amidead() then return end

   -- Movements

   if love.keyboard.isDown("left") then
      ship_speed_x = math.max(- ship_max_speed_x, ship_speed_x - dt * ship_a_x)
   elseif love.keyboard.isDown("right") then
      ship_speed_x = math.min(ship_max_speed_x, ship_speed_x + dt * ship_a_x)
   else
      if ship_speed_x > 0 then
         ship_speed_x = math.max(0, ship_speed_x - dt * ship_d_x)
      else
         ship_speed_x = math.min(0, ship_speed_x + dt * ship_d_x)
      end
   end
   ship_x = ship_x + dt * ship_speed_x

   guy_x = guy_x + dt * ship_speed_x / 2

   if ship_x < 0.3 then
      ship_x = ship_x + 9.4
   end

   if ship_x > 9.7 then
      ship_x = ship_x - 9.4
   end

   if guy_x < 0.5 then guy_x = 0.5 end
   if guy_x > 99.4 then guy_x = 99.4 end
   
   -- Bullets and enemies

   for ib, b in pairs(bullets) do
      b.upd(b, dt)
   end

   for ib, b in pairs(e_bullets) do
      b.upd(b, dt)
      if b.world == 2 and field[math.floor(b.x)][math.floor(b.y)] then
         table.remove(e_bullets, ib)
      end
   end

   for ib, b in pairs(e_bombs) do
      b.upd(b, dt)
      if field[math.floor(b.x)][math.floor(b.y)] then
         table.remove(e_bombs, ib)
      end
   end
   
   for _,e in pairs(enemies) do
      e.upd(e, dt)
   end
   
   for ib, b in pairs(bullets) do
      for ie, e in pairs(enemies) do
         check_collision(ib, ie, b, e)
      end
   end

   if math.random(1,100) == 1 then new_enemy() end
   
   half_w = 0.45
   half_h = 0.45

   function wrap(x, y, sx, sy)
      x1 = math.floor(x - half_w)
      dx1 = x1 + 1 - (x - half_w)

      x2 = math.floor(x + half_w)
      dx2 = x + half_w - x2

      y1 = math.floor(y - half_h)
      dy1 = y1 + 1 - (y - half_h)

      y2 = math.floor(y + half_h)
      dy2 = y + half_h - y2

      a11 = field[x1][y1]
      a12 = field[x1][y2]
      a21 = field[x2][y1]
      a22 = field[x2][y2]

      function ms() return x, y, sx, sy end
      function ml() return x2 - half_w - epsilon, y, (sx < 0) and sx or 0, sy end
      function mr() return x2 + half_w + epsilon, y, (sx > 0) and sx or 0, sy end
      function md() return x, y2 - half_h - epsilon, sx, (sy < 0) and sy or 0 end
      function mu() return x, y2 + half_h + epsilon, sx, (sy > 0) and sy or 0 end
      function mdl()return x2 - half_w - epsilon, y2 - half_h - epsilon, 0, 0 end
      function mdr()return x2 + half_w + epsilon, y2 - half_h - epsilon, 0, 0 end
      function mul()return x2 - half_w - epsilon, y2 + half_h + epsilon, 0, 0 end
      function mur()return x2 + half_w + epsilon, y2 + half_h + epsilon, 0, 0 end

      if x1 == x2 and y1 ~= y2 and a11 ~= a12 then
         if a11 then
            return mu()
         else
            return md()
         end
      elseif x1 ~= x2 and y1 == y2 and a11 ~= a21 then
         if a11 then
            return mr()
         else
            return ml()
         end
      elseif x1 ~= x2 and y1 ~= y2 then
         -- All empty
         if not a11 and not a12 and not a21 and not a22 then
            return ms()
         -- Two blocks side by side
         elseif a11 and a12 and not a21 and not a22 then
            return mr()
         elseif not a11 and not a12 and a21 and a22 then
            return ml()
         elseif a11 and a21 and not a12 and not a22 then
            return mu()
         elseif a12 and a22 and not a11 and not a21 then
            return md()
         -- Two diagonal blocks
         elseif a11 and not a12 and not a21 and a22 then
            if dx1 < dx2 then
               return mdr()
            else
               return mul()
            end
         elseif not a11 and a12 and a21 and not a22 then
            if dx1 < dx2 then
               return mul()
            else
               return mdr()
            end
         -- Three blocks
         elseif a11 and a12 and a21 and not a22 then
            return mur()
         elseif a11 and a12 and not a21 and a22 then
            return mdr()
         elseif a11 and not a12 and a21 and a22 then
            return mul()
         elseif not a11 and a12 and a21 and a22 then
            return mdl()
         -- One block
         elseif a11 then
            if dx1 < dy1 then
               return mr()
            else
               return mu()
            end
         elseif a12 then
            if dx1 < dy2 then
               return mr()
            else
               return md()
            end
         elseif a21 then
            if dx2 < dy1 then
               return ml()
            else
               return mu()
            end
         elseif a22 then
            if dx2 < dy2 then
               return ml()
            else
               return md()
            end
         end
      else
         return ms()
      end
   end

   speed_guy_y = speed_guy_y - dt * 10

   guy_x, guy_y, speed_guy_x, speed_guy_y = wrap(guy_x, guy_y + dt * speed_guy_y, speed_guy_x, speed_guy_y)
   if speed_guy_y == 0 then
      double_jump = false
   end
end

function fire()
   function update(bullet, dt)
      bullet.y = bullet.y + speed_b * dt
   end
   bullet2 = {x = ship_x - 2/6; y = 0.75; upd = update}
   bullet3 = {x = ship_x + 2/6; y = 0.75; upd = update}
   table.insert(bullets, bullet2)
   table.insert(bullets, bullet3)
end

function jump()
   speed_guy_y = 6
end

function check_collision(ib, ie, b, e)
   if (b.x - e.x) ^ 2 + (b.y - e.y) ^ 2 < e.size * e.size
   then
      table.remove(enemies, ie)
      table.remove(bullets, ib)
   end
end

function amidead()
   -- if true then
   --    return false
   -- end

   for _, e in pairs(enemies) do
      if e.world == 1 and (ship_x - e.x) ^ 2 + (ship_y - e.y) ^ 2 < 4 * e.size ^ 2 then
         return true
      end
      if e.world == 2 and (guy_x - e.x) ^ 2 + (guy_y - e.y) ^ 2 < 4 * e.size ^ 2 then
         return true
      end
   end

   for _, b in pairs(e_bullets) do
      if b.world == 1 and (ship_x - b.x) ^ 2 + (ship_y - b.y) ^ 2 < (25 / 60) ^ 2 then
         return true
      end
      if b.world == 2 and (guy_x - b.x) ^ 2 + (guy_y - b.y) ^ 2 < (25 / 60) ^ 2 then
         return true
      end
   end

   for _, b in pairs(e_bombs) do
      if (guy_x - b.x) ^ 2 + (guy_y - b.y) ^ 2 < (25 / 60) ^ 2 then
         return true
      end
   end

   return false
end

function love.keypressed(key, r)
   if (key == " " or key == "up") and not double_jump then
      if speed_guy_y ~= 0 then
         double_jump = true
      end
      fire()
      jump()
   end

   if key == "return" and amidead() then
      initialize()
   end
end
