pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
//system core loop
function _init()
 create_game_manager()
end

function _update()
 gm.update()
end

function _draw()
 cls()
 gm.draw()
end
-->8
//game

function create_game_manager()
 gm = {}
 gm.state = 'menu'
 gm.menu_manager = create_menu_manager()
 gm.game_player = create_game_player()
 gm.start_game = function()
  gm.state = 'game'
 end
 gm.update = function()
  if gm.state == 'menu' then
   gm.menu_manager.update()
  elseif gm.state == 'game' or gm.state == 'over' then
   gm.game_player.update()
  end
 end
 gm.draw = function()
  if gm.state == 'menu' then
   gm.menu_manager.draw()
  elseif gm.state == 'game' then
   gm.game_player.draw()
  elseif gm.state == 'over' then
   gm.game_player.draw()
   print('x to try again', 10,84,7)
   print('c to go back to menu', 10, 94, 7)
   if player.dead and (player.win == false or player.win == nil) then
    print('crash!', 50, 64, 14) 
   else 
    print('you formed a stable loop!', 10, 64, 14)
    if player.warps_collected and planet_manager.warps then
     print('you collected '..player.warps_collected..'/'..#planet_manager.warps..' bonuses!', 10, 74, 14)
    end
   end
  end
 end
end


-->8
//menu manager
function create_menu_manager()
 menu = {}
 demo = create_demo(true)
 menu.index = 1
 menu.x_pos = 64
 menu.y_pos = 88
 menu.options = {}
 add(menu.options, play_option())
 add(menu.options, level_select())
 add(menu.options, difficulty_select())
 add(menu.options, create_shop())
 add(menu.options, create_visual_effects())
 create_bonus_tracker()
 create_win_tracker()
 menu.bonuses_collected = get_bonuses_collected()
 menu.total_bonuses = get_bonus_total()
 menu.update = function()
  demo.update()
  if demo.done then
   demo = create_demo(false)
  end
  if btnp(0) then
   if menu.options[menu.index].increment then
    menu.options[menu.index].increment(-1)
   end
  elseif btnp(1) then
   if menu.options[menu.index].increment then
    menu.options[menu.index].increment(1)
   end
  elseif btnp(2) then
   menu.index -= 1
  elseif btnp(3) then
   menu.index += 1
  elseif btnp(5) then
   menu.options[menu.index].action()
  elseif btnp(4) then
   menu.options[menu.index].deaction()
  end
   menu.index = mod_1(menu.index, #menu.options)
 end
 menu.draw_fun = function()
  if vfx.check_fx('bonuses') then
   print('bonuses collected: ', 16, 110, 15)
   print(menu.bonuses_collected, 92, 110, 14)
   print('/'..menu.total_bonuses, 96+flr(menu.bonuses_collected/10)*4, 110, 15)
   print('bonuses left: ', 16, 116, 15)
   print(bonuses_left, 72, 116, 14)
  end
 end
 menu.draw = function()
  local x_mid = menu.x_pos
  local y_mid = menu.y_pos
  local line_height = 10
  local char_height = 6
  local char_width = 4
  local y_start = y_mid - (char_height+(line_height*#menu.options))/2
  local y_cur = y_start
  local x_cur
  rectfill(0,0,128,128,5)
  rectfill(x_mid - 54, y_start-4, x_mid+54, y_start+48, 1)
  rect(x_mid - 54, y_start-4, x_mid+54, y_start+48, 2)
  for i = 1, #menu.options do
   string = menu.options[i].get_draw()
   string_color = menu.options[i].get_color()
   x_cur =  x_mid-(#string*char_width)/2
   print(string, x_cur, y_cur, string_color)
   if (menu.index == i) then
    rect(x_cur-2, y_cur-2, x_cur+(char_width*#string), y_cur+char_height, 13)
   end
   y_cur+=line_height
  end
  menu.draw_fun()
  if vfx.check_fx('demo') then
   demo.draw()
  end
 end
 return menu
end

function play_option()
 local item = {}
 item.get_draw = function()
  return 'play'
 end
 item.get_color = function()
  return 15
 end
 item.action = function()
  reset_level(lm.level_index)
  planet_manager.warps = get_level(lm.get_index()).warps
  planet_manager.planets = get_level(lm.get_index()).planets
  score_keeper.science_needed = get_level(lm.get_index()).science
  refresh_stars()
  gm.start_game()
 end
 item.deaction = function()
 end
 play_controller = item
 return item
end

function level_select()
 if lm then
  lm.levels = create_levels()
  return lm
 end
 local item = {}
 item.levels = create_levels()
 item.level_index = 1
 item.get_draw = function()
  return '⬅️ level '..item.get_index()..' ➡️  '
 end
 item.get_color = function()
  local col = 15
  //not won
  if win_tracker[item.level_index] == 0then
   col = 15
  //all collected
  elseif bonus_tracker[item.level_index] >= #item.levels[item.level_index].warps then
   col = 14
  else //won but not all collected
   col = 12
  end
  return col
 end
 item.increment = function(inc)
  item.level_index += inc
  item.level_index = mod_1(item.level_index, #item.levels)
  //janky code
  if item.level_index == 10 then
   player.speed = 3.9984
  end
 end
 item.deaction = function()
 end
 item.action = function()
 end
 item.get_index = function()
  return item.level_index
 end
 lm = item
 return item
end

function difficulty_select()
 if difficulty_selector then
  return difficulty_selector
 end
 local item = {}
 item.types = {'normal', 'assist'}
 item.index = 1
 item.get_draw = function()
  return '⬅️ '..item.types[item.index]..' ➡️  '
 end
 item.get_color = function()
  return item.index == 1 and 15 or 14
 end
 item.increment = function(inc)
  item.index += inc
  item.index = mod_1(item.index, #item.types)
 end
 item.deaction = function()
 end
 item.action = function()
 end
 item.get_diff = function()
  return item.types[item.index]
 end
 difficulty_selector = item
 return item
end

function create_shop()
 if shop then
  return shop
 end
 local item = {}
 item.upgrades = {{name='thrust', cost = 5, bought = false}, {name = 'brakes', cost = 5, bought = false}, {name='magnet', cost = 5, bought = false}, {name='freeze', cost = 5, bought = false}, {name='paint job', cost = 2, bought = false}}
 item.index = 1
 item.get_draw = function()
  if item.upgrades[item.index].bought == false then
   return '⬅️ '..item.upgrades[item.index].name..' -cost: '..item.upgrades[item.index].cost..' ➡️  '
  else 
   return '⬅️ '..item.upgrades[item.index].name..': purchased'..' ➡️  ' 
  end
 end
 item.get_color = function()
  return item.upgrades[item.index].bought==false and 15 or 3
 end
 item.increment = function(inc)
  item.index += inc
  item.index = mod_1(item.index, #item.upgrades)
 end
 item.deaction = function()
 end
 item.action = function() 
  //if item.upgrades[item.index].bought == false and item.upgrades[item.index].cost <= bonuses_left then
     item.upgrades[item.index].bought = true 
     bonuses_left -=   item.upgrades[item.index].cost
  //end
 end
 item.check_upgrade = function(upgrade)
  local bought = false
  for this_upgrade in all(item.upgrades) do
   if this_upgrade.name == upgrade then
    bought = this_upgrade.bought
   end
  end
  return bought
 end
 shop = item
 return item
end

function create_visual_effects()
	local item = {}
 item.fx = {{name='demo', on = true}, {name='hud', on = true}, {name = 'stars', on = true}, {name='bonuses', on = true}}
 item.index = 1
 item.get_draw = function()
  if item.fx[item.index].on == false then
   return '⬅️ '..item.fx[item.index].name..': off'..' ➡️  '
  else 
   return '⬅️ '..item.fx[item.index].name..': on'..' ➡️  ' 
  end
 end
 item.get_color = function()
  return item.fx[item.index].on==false and 2 or 15
 end
 item.increment = function(inc)
  item.index += inc
  item.index = mod_1(item.index, #item.fx)
 end
 item.deaction = function()
 end
 item.action = function() 
  item.fx[item.index].on = not item.fx[item.index].on
 end
 item.check_fx = function(fx)
  local on = false
  for this_fx in all(item.fx) do
   if this_fx.name == fx then
    on = this_fx.on
   end
  end
  return on
 end
 vfx = item
 return item
end
-->8
//game_player

function create_game_player()
 gp = {}
 gp.workers = {}
 add(gp.workers, create_game_controller())
 add(gp.workers, create_timer())
 add(gp.workers, create_player())
 add(gp.workers, create_score_keeper())
 add(gp.workers, create_planet_manager())
 gp.update = function()
  for item in all(gp.workers) do
   item.update()
  end
 end
 gp.draw = function()
  for item in all(gp.workers) do
   item.draw()
  end
 end
 return gp
end

function create_game_controller()
	local this = {}
 this.draw = function()
  rectfill(0,0,128,128,0)
  if vfx.check_fx('stars') then
   draw_stars(20)
  end
  draw_sparks()
  draw_beam()
 end
 this.update = function()
  update_sparks() //put this in a funstuff controller?
 end
 return this
end

function create_timer()
 local this = {}
 this.external_time = 1
 this.internal_time = 1
 this.draw = function() 
  local col = 7
  if this.external_time >= 7 then
   col = 14
  end
  //print("survive: ", 84, 0, 7)
  //print(this.external_time, 120, 0, col)
 end
 this.update = function()
  if not player.launched or player.dead then
   return
  end
  this.internal_time += 1
  if mod(this.internal_time, 10) == 0 then
   player.tick()
  end
  if this.internal_time >= 30 then
   this.internal_time = 0
   this.external_time += 1
   score_keeper.increment_score(1)
   if this.external_time >= 10 then
    //gm.state = 'over'
    //player.win = true
    //player.charged = true
   end
  end
 end
 return this
end

function create_player()
 local this = {}
 this.x = 64
 this.y = 120
 this.dead = false
 this.launched = false	
 this.charged = true
 this.win = false
 this.warps_collected = 0
 
 if player and player.init_speed then
  this.speed = player.init_speed
  this.direction = player.init_direction
 else
  this.direction = .25
  this.speed = 1
 end
 this.size = 4
 this.frozen = false
 this.freeze_ttl = 30
 this.mass = 1
 this.vel = {1,0}
 this.forgiveness = 10
 this.trail = {}
 this.button = -1
 this.tick = function()
  add(this.trail, {this.x, this.y})
  if #this.trail >= 10 then
   del(this.trail, this.trail[1])
  end
 end
 this.draw_trail = function()
  for i = 1, #this.trail do
   pset(this.trail[i][1], this.trail[i][2], 8)
  end
 end
 this.draw_trajectory = function(length, col, direction, speed)
 	local trajectory = {}
 	local vel = {0,0}
 	vel[1] = cos(direction or this.direction) 
  vel[2] = sin(direction or this.direction)
 	vel = scale_table(vel, speed or this.speed)
 	local x = this.x
 	local y = this.y
 	local dead = false
 	for i = 1, length do  //put this next bit in function for re-use??
 	 if dead then
 	  return
 	 end
 	 vel = add_tables(planet_manager.get_gravity(x, y, this.mass, 1, 'ship', 0), vel)  
 	 x += vel[1]
   y += vel[2]
   if mod(i, 4) == 1 then
    pset(x, y, col or 2)
   end
   if planet_manager.check_colision(x, y) then
    dead = true
   end
 	end
 end
 this.check_dead = function()
	 local dead = false
	 dead = planet_manager.check_colision(this.x, this.y)
	 if (this.x <-this.forgiveness or this.x >128+this.forgiveness or this.y < -this.forgiveness or this.y > 128+this.forgiveness) then
	  dead = true
	 end
	 return dead
 end
 
 this.update = function()
  if this.dead or gm.state == 'over' then
   if btnp(5) then
    if this.win then
     win_tracker[lm.level_index] = 1
     bonuses_left +=  max(this.warps_collected - bonus_tracker[lm.level_index],0)
     bonus_tracker[lm.level_index] = max(bonus_tracker[lm.level_index],this.warps_collected) 
    end
    score_keeper.score = 0
    _init()
    play_controller.action()
  	end
  end
   if btn(4) then 
    if this.win then
     score_keeper.score = 0
     win_tracker[lm.level_index] = 1
     bonuses_left +=  max(this.warps_collected - bonus_tracker[lm.level_index],0)
     bonus_tracker[lm.level_index] = max(bonus_tracker[lm.level_index],this.warps_collected) 
     
    end   
  		_init()
  	end
  	if this.dead then
   	return
  	end
  	if this.frozen then
  	 if this.freeze_ttl <= 0 then
  	  this.frozen = false
  	 end
  	 this.freeze_ttl -= 1
  	 return
  	end
  //end
  this.collect_warps = function()
   for warp in all(planet_manager.warps) do
    if warp.collected != true then
    local collection_radius = 4
    if shop.check_upgrade('magnet') then
     collection_radius = 12
    end
     if point_in_circle(this.x, this.y, warp.x, warp.y, collection_radius) then
      if not point_in_circle(this.x, this.y, warp.x, warp.y, 4) then
       create_beam(warp.x, warp.y)
      end
     	score_keeper.increment_score(2)
     	this.warps_collected += 1
     	warp.collected = true
     end
    end
   end
   //if planet_manager.warps and collecteds >= #planet_manager.warps then
   // gm.state = 'over'
   //end
  end
  if not this.launched then
   local mult = 1
  	if btnp(0) then 
  	 if this.button == 0 then
  	  mult = 3
  	 end
  	 this.button = 0
  		this.direction += (pi()/1000)*mult
  	elseif btnp(1) then 
   	if this.button == 1 then
  	  mult = 3
  	 end
  	 this.button = 1  	
  	 this.direction -= (pi()/1000)*mult
  	elseif btnp(2) then 
  		if this.button == 2 then
  	  mult = 10
  	 end
  	 this.button = 2
  		this.speed += .01*mult
  		this.speed = min(this.speed, 3.9984)
  	elseif btnp(3) then 
  		if this.button == 3 then
  	  mult = 10
  	 end
  	 this.button = 3
  		this.speed -= .01*mult
  		this.speed = max(this.speed, .2004)
  	elseif btn() == 0 then
  	 this.button = -1
  	end
  	if btnp(5) then //should there be power??
  	 this.launched = true
  	 this.init_speed = this.speed
  	 this.init_direction = this.direction
  	 this.vel[1] = cos(this.direction) 
    this.vel[2] = sin(this.direction)
	   this.vel = scale_table(this.vel, this.speed)
  	end
  else //launched  
   if gm.state == 'over' then
    //return
   end
   this.vel = add_tables(planet_manager.get_gravity(this.x, this.y, this.mass, 1, 'ship', 0), this.vel)  
   this.distance = planet_manager.closest_dist(this.x, this.y)
   if this.distance < 50 then
    this.score_up = sqr(50 - this.distance)/10000
    //score_keeper.increment_score(this.score_up)
   end
   this.x += this.vel[1]
   this.y += this.vel[2]
   this.direction = get_direction(this.vel)
   this.thrust = scale_table({cos(this.direction), sin(this.direction)}, .01)
   if btn(2) and (shop.check_upgrade('thrust') == true) then 
    draw_flame(20)
  	 this.vel = add_tables(this.vel, this.thrust)
  	end
  	if btn(3) and shop.check_upgrade('brakes') == true then 
  	 draw_flame(20, 1)
  	 this.thrust = scale_table(this.thrust, -1)
  	 this.vel = add_tables(this.vel, this.thrust)
  	end
  	if btnp(5) and shop.check_upgrade('freeze') == true then
  	 this.frozen = true
   end
   if this.check_dead() then
    this.dead = true
    gm.state = 'over'
   end
   this.collect_warps()
  end
 end
 this.draw = function()
  if not this.launched then
			this.draw_trajectory(100)
			if difficulty_selector.get_diff() == 'assist' then
			 this.draw_trajectory(100, 14, lm.levels[lm.level_index].assist[1], lm.levels[lm.level_index].assist[2])
			end
			if vfx.check_fx('hud') then
  		print('power:', 114-24, 108, 12)
  		draw_power(ceil(this.speed*25), 114, 12, 12, 1, false)
  	 //print('angle:', 114-24, 114, 12)
    //print(ceil((this.direction+.25)*360), 114, 114, 12)
    if difficulty_selector.get_diff() == 'assist' then
     draw_power(ceil(lm.levels[lm.level_index].assist[2]*25), 120, 12, 14, 2)
     //print('angle:', 114-24, 120, 14)
     //print(ceil((lm.levels[lm.level_index].assist[1]+.25)*360), 114, 120, 14)
    end
   end
  else //launched
   if vfx.check_fx('hud') then
    print('power:', 114-24, 108, 12)
    draw_power(ceil(this.init_speed*25), 114, 12, 12, 1)
    //print('angle:', 114-24, 114, 12)
 	  //print(ceil((this.init_direction+.25)*360), 114, 114, 12)
 	 end
   this.draw_trail(20)   	  
  end//always
  local fin_color = 7
  if shop.check_upgrade('paint job') then
   fin_color = 14
  end 
  pset(this.x-cos(this.direction-.05)*this.size, this.y-sin(this.direction-.05) * this.size, fin_color) //make it rotate around the middle??
  pset(this.x-cos(this.direction+.05)*this.size, this.y-sin(this.direction+.05) * this.size, fin_color) //make it rotate around the middle??
  pset(this.x, this.y, 8)	
  
  
  
 end
 player = this
 return this
end

function create_score_keeper()
 local this = {}
 this.score = 0
 this.draw = function()
  draw_science(this.score,this.science_needed, 36, 0, 14, 2)
  print('science: ',0,0,7)
  //print(this.science_needed, 64,0,14)
  //print('science gathered: ',0,6,7)
  //print(flr(this.score), 72, 6, 15)
  if shop.check_upgrade('freeze') then
   print('x to freeze',0,6,7)
  end
 end
 this.increment_score = function(score)
  this.score += score
 end
 this.update = function()
  if this.science_needed then
   if this.score >= this.science_needed then
    gm.state = 'over'
    player.win = true
   end
  end
 end
 score_keeper = this
 return this
end

function create_planet_manager()
 //mock out level 1
 this = {}
 this.gravity = .005
 this.get_gravity = function(x, y, r, dns, typ,id)
  local total_accel = {0,0}
  for planet in all(this.planets) do
   if planet.mass == nil then
    planet.mass = pi()*sqr(planet.r)*planet.dns
   end
   if planet.typ != 'warp' and planet.id != id and (planet.typ == 'star' or typ=='ship') and typ != 'star' then
    local dist = distance(x,y, planet.x, planet.y)
    local accel = (this.gravity*(planet.mass))/sqr(dist)
    x_accel = accel*((planet.x-x)/dist)
    y_accel = accel*((planet.y-y)/dist)
    //local max_accel = 2
    total_accel[1] += x_accel//x_accel/abs(x_accel) * min(abs(x_accel), max_accel)
    total_accel[2] += y_accel//y_accel/abs(y_accel) * min(abs(y_accel), max_accel)
   end  
  end
  return total_accel
 end
 
 this.closest_dist = function(x, y)
  return_distance = 128
  for planet in all(this.planets) do
   new_dist = distance(x, y, planet.x, planet.y)
   if return_distance > new_dist then
    return_distance = new_dist
   end
  end
  return return_distance
 end
 
 this.check_colision = function(x, y)
  local colide = false
  for planet in all(this.planets) do
   if point_in_circle(x, y, planet.x, planet.y, planet.r) then
    colide = true
   end
  end
  return colide
 end
 this.update = function()
  if not player.launched then
   return
  end
  for planet in all(this.planets) do
   if planet.mass == nil then
    planet.mass = pi()*sqr(planet.r)*planet.dns
   end
   local force = this.get_gravity(planet.x, planet.y, planet.r, planet.dns, planet.typ, planet.id)
   if planet.vel == nil then
    local d = get_direction(force)
    local perp_d = d+.25
    local vel = {cos(perp_d), sin(perp_d)}
    local scaled_vel = scale_table(vel, planet.speed)
    planet.vel = scaled_vel
   end
   //debug
   //scale_table(planet.vel, 1/mag(force))
   planet.vel = add_tables(planet.vel, force)
   planet.x += planet.vel[1]
   planet.y += planet.vel[2]
  end
 end
 this.draw = function()
  for warp in all(this.warps) do
   if warp.collected == true then
   	//circfill(warp.x, warp.y, 2, 5)
   else 
    circfill(warp.x, warp.y, 2, 12)
   end
   circ(warp.x, warp.y, 2, 6)
  end
  for planet in all(this.planets) do
   circ(planet.x, planet.y, planet.r, planet.col)
  end
 end
 planet_manager = this
 return this
end


-->8
function get_direction(vec)
 return atan2(vec[1], vec[2])
end

function draw_stars(amount)
 if not (stars and #stars == amount) then
  stars = {}
  for i = 1, amount do
   add(stars, {rand_int(0,128), rand_int(0,128), rand_int(4,7)})
  end
 end
 for star in all(stars) do
  pset(star[1], star[2], star[3])
 end
end

function refresh_stars()
 stars = nil
end

function draw_flame(amount, is_forward)
 if amount > 30 then
  return
 end
 if (amount> rand_int(0,30)) then
  spawn_spark(is_forward)
 end
end

function spawn_spark(is_forward)
 if not sparks then
  sparks = {}
 end
 add(sparks, {x = player.x, y=player.y, direction = player.direction+(is_forward and 0 or .5), col = pick({9, 10}), tim = 0, is_forward = is_forward, ttl = rand_int(5,15)})
end

function update_sparks()
 for spark in all(sparks) do
  local mult
  if spark.is_forward then
   mult = 4
  else
   mult = .2
  end
  spark.x += (cos(spark.direction)*mult*rnd())+rnd()-.5
  spark.y += (sin(spark.direction)*mult*rnd())+rnd()-.5
  spark.tim += 1
  if spark.tim >= spark.ttl then 
   del(sparks, spark)
  end
 end
end

function draw_sparks()
 for spark in all(sparks) do
  pset(spark.x, spark.y, spark.col)
 end
end

function draw_power(power, x1, y1, col1, col2, small)
 local bottom = 100
 if small == true then
  bottom = 30
 end
 rectfill(x1, y1+(bottom-power), x1+4, y1+bottom, col1)
 rect(x1, y1, x1+4, y1+bottom, col2)
end

function draw_science(science, science_needed, x1, y1, col1, col2, small)
 //local bottom = 100
 //if small == true then
 // bottom = 30
 //end
 rectfill(x1, y1, x1+(min(science, science_needed)), y1+4, col1)
 rect(x1, y1, x1+science_needed+1, y1+4, col2)
end

function create_beam(x2, y2)
 local this = {}
 this.ttl = 5
 this.x2 = x2
 this.y2 = y2 
 beam = this
end

function draw_beam()
 if not beam then
  return
 end
 beam.ttl -= 1
 if beam.ttl >= 0 then
  line(player.x,player.y, beam.x2, beam.y2, 3)
 end
end
-->8
//domain agnostic helpers

function distance(x1, y1, x2, y2)
 return sqrt(sqr(x1-x2)+sqr(y1-y2))
end

function mod(a, b) 
 return a - (flr(a/b)*b)
end

function mod_1(a, b)
 local result = mod(a,b)
 if result == 0 then
  result = b
 end
 return result
end

function wrap(int)
 if int > 128 then
  int = 0
 end
 if int < 0 then
  int = 128
 end
 return int
end

function pick(list)
 return list[rand_int(0, #list)]
end

function rand_int(lo,hi)
 return flr(rnd(hi-lo))+lo+1
end

function sqr(x)
 return x*x
end

function point_in_circle(px, py, cx, cy, cr)
 return sqr(cx - px)+sqr(cy-py) <= sqr(cr)
end

function rectangle_in_circle(rectangle, circle)
 local xn = max(rectangle[1], min(circle[1], rectangle[3]))
 local yn = max(rectangle[2], min(circle[2], rectangle[4]))
 local dx = xn - circle[1]
 local dy = yn - circle[2]
 return (sqr(dx) + sqr(dy)) <= sqr(circle[3])
end

function add_tables(t1, t2)
 if #t1 != #t2 then
  return error //todo:j cleanup??
 end
 local t3 = {}
 for i=1, #t1 do
 	add(t3, t1[i]+t2[i])
 end
 return t3
end

function scale_table(t1, el)
	local t2 = {}
	for i=1, #t1 do
 	add(t2, t1[i]*el)
 end
 return t2
end


function sprite_color(n, x, y, num)
 if not num then
  num = 1
 end
 local beginning_row = mod(n,16)*8
 local beginning_col = flr(n/16)*8
 for i = 0, 8*num-1 do
  for j = 0, 8*num-1 do
   this_color = sget(beginning_row+i, beginning_col+j) 
   this_name = cm.get_color_name(this_color)
   this_new_color = cm.get(this_name)
   if this_new_color == nil then
   else
			 pset(i+x, j+y, this_new_color)   
			end
  end
 end
end

function asin(y)
 return atan2(sqrt(1-y*y),-y)
end

function dot(v1, v2)
 return (v1[1]*v2[1]) + (v1[2]*v2[2])
end

function mag(vec)
 return sqrt(sqr(vec[1])+sqr(vec[2]))
end

function pi()
 return 3.14
end
-->8
//levels
function get_level(level)
 if not levels then
  create_levels()
 end
 return levels[level]
end

function reset_level(level_index)
 for warp in all(lm.levels[level_index].warps) do
  warp.collected = false
 end
end

function create_levels()
 levels = {}
 //level 1
 add(levels, {assist = {.078,.4403}, science = 10, warps= {{x = 64, y = 40}}, planets = {{typ = 'star', id = 1, col = 10, r = 3, dns = 100, x = 64, y = 64, speed = 0}}}) //level 1
 //level 2
 add(levels, {assist = {.3,1.02},science = 10, warps= {{x = 60, y = 40}}, planets = {{typ = 'star', id = 1, col = 10, r = 3, dns = 100, x = 64, y = 64, speed = 0}, {typ = 'planet', id = 2, col = 8, r = 2, dns = 100, x = 50, y = 50, speed = .6}}})
 //level 3
 add(levels, {assist = {.031,.4703},science = 10, warps= {{x = 100, y = 40},{x=46, y=62}}, planets = {{typ = 'star', id = 1, col = 10, r = 3, dns = 100, x = 64, y = 64, speed = 0}, {typ = 'planet', id = 2, col = 8, r = 2, dns = 100, x = 100, y = 50, speed = .4}}})
 //level 4
 add(levels, {assist = {-.2,.3703},science = 10, warps= {{x = 60, y = 40}, {x = 74, y = 74}}, planets = {{typ = 'star', id = 1, col = 10, r = 3, dns = 100, x = 64, y = 64, speed = 0}, {typ = 'planet', id = 2, col = 8, r = 2, dns = 100, x = 50, y = 50, speed = .8}, {typ = 'planet', id = 3, col = 4, r = 2, dns = 50, x = 80, y = 80, speed = .6}}})
 //level 5
 add(levels, {assist = {-.0691,.94},science = 15, warps= {{x = 10, y = 10}, {x = 113, y = 110}}, planets = {{typ = 'star', id = 1, col = 10, r = 3, dns = 100, x = 90, y = 100, speed = 0},{typ = 'star', id = 5, col = 10, r = 5, dns = 100, x = 20, y = 30, speed = 0}, {typ = 'planet', id = 2, col = 8, r = 2, dns = 100, x = 50, y = 50, speed = -1}, {typ = 'planet', id = 3, col = 4, r = 2, dns = 50, x = 80, y = 80, speed = .9}}})
 //level 6
 add(levels, {assist = {0.4565,1.1699},science = 15, warps= {{x = 28, y = 28}, {x = 90, y = 110},{x = 30, y = 100}, {x = 90, y = 40}}, planets = {{typ = 'star', id = 1, col = 10, r = 5, dns = 100, x = 90, y = 100, speed = 0}, {typ = 'star', id = 2, col = 10, r = 5, dns = 100, x = 20, y = 30, speed = 0},{typ = 'star', id = 3, col = 10, r = 3, dns = 100, x = 20, y = 100, speed = 0},{typ = 'star', id = 4, col = 10, r = 3, dns = 100, x = 100, y = 30, speed = 0}}})
 //level 7
 add(levels, {assist = {0.3564,.7801},science = 15, warps= {{x = 64, y = 28}, {x = 64, y = 110},{x = 34, y = 50}, {x = 90, y = 64}}, planets = {{typ = 'star', id = 1, col = 10, r = 5, dns = 100, x = 90, y = 100, speed = 0}, {typ = 'star', id = 2, col = 10, r = 5, dns = 100, x = 20, y = 30, speed = 0},{typ = 'star', id = 3, col = 10, r = 3, dns = 100, x = 20, y = 100, speed = 0},{typ = 'star', id = 4, col = 10, r = 3, dns = 100, x = 100, y = 30, speed = 0}, {typ = 'planet', id = 6, col = 8, r = 2, dns = 50, x = 100, y = 80, speed = 1.59}, {typ = 'planet', id = 6, col = 4, r = 2, dns = 50, x = 10, y = 110, speed = 1.05983}}})
 //level 8
 add(levels, {assist = {-.1222,.94},science = 10, warps= {{x = 20, y = 64}, {x = 64, y = 64}, {x = 110, y = 64}}, planets = {{typ = 'star', id = 1, col = 10, r = 5, dns = 100, x = 50, y = 64, speed = 0}, {typ = 'star', id = 2, col = 10, r = 5, dns = 100, x = 78, y = 64, speed = 0}, {typ = 'planet', id = 3, col = 8, r = 2, dns = 50, x = 34, y = 64, speed = 1.35}}})
 //level 9
 add(levels, {assist = {.3063,.2404},science = 10, warps= {{x = 64, y = 40}, {x = 64, y = 88}}, planets = {{typ = 'star', id = 0, col = 10, r = 4, dns = 100, x = 64, y = 64, speed = 0},{typ = 'planet', id = 1, col = 4, r = 3, dns = 100, x = 32, y = 64, speed = 1}, {typ = 'planet', id = 2, col = 8, r = 3, dns = 100, x = 64, y = 32, speed = 1}, {typ = 'planet', id = 3, col = 4, r = 3, dns = 100, x = 96, y = 64, speed = 1}, {typ = 'planet', id = 3, col = 8, r = 3, dns = 100, x = 64, y = 96, speed = 1}}})
  //level 10
 add(levels, {assist = {.2469,3.5486},science = 7, warps= {{x = 64, y = 64}}, planets = {{typ = 'star', id = 10, col = 10, r = 4, dns = 100, x = 40, y = 40, speed = 0},{typ = 'star', id = 1, col = 10, r = 4, dns = 100, x = 40, y = 88, speed = 0}, {typ = 'star', id = 2, col = 10, r = 4, dns = 100, x = 88, y = 88, speed = 0}, {typ = 'star', id = 3, col = 10, r = 4, dns = 100, x = 88, y = 40, speed = 0}, {typ = 'planet', id = 5, col = 8, r = 3, dns = 100, x = 64, y = 4, speed = 0}, {typ = 'planet', id = 6, col = 4, r = 3, dns = 100, x = 124, y = 64, speed = 0}, {typ = 'planet', id = 7, col = 4, r = 3, dns = 100, x = 4, y = 64, speed = 0}, {typ = 'planet', id = 8, col = 8, r = 3, dns = 100, x = 64, y = 124, speed = 0}}})
 return levels
end

function get_bonus_total()
 bonus_total = 0
 for level in all(levels) do
  for warp in all(level.warps) do
   bonus_total += 1
  end
 end
 return bonus_total
end

function get_bonuses_collected()
 local bonuses_collected = 0
 for bonus_count in all(bonus_tracker) do
  bonuses_collected += bonus_count
 end
 return bonuses_collected
end

function create_bonus_tracker()
 if bonus_tracker then
  return bonus_tracker
 end
 bonuses_left = 0
 bonus_tracker = {}
 for level in all(lm.levels) do
  add(bonus_tracker, 0)
 end
end

function create_win_tracker()
 if win_tracker then
  return win_tracker
 end
 win_tracker = {}
 for level in all(lm.levels) do
  add(win_tracker, 0)
 end
end
-->8
function create_demo(first_demo)
 local this = {}
 this.ship = {}
 this.ship.x = 64
 this.ship.y = 44
 this.ship.size = 4
 this.ship.direction = .25
 this.ship.speed = 1
 this.ship.vel = {0,0}
 this.planet = {}
 this.planet.x = 64
 this.planet.y = 32
 this.planet.r = 4
 this.stage = 0
 this.show_science = true
 if first_demo == false then
  this.stage = -1
 end
 this.science_needed = 10
 this.score = 0
 this.col_right = 5
 this.col_left = 5
 this.col_x = 5
 this.col_c = 5
 if first_demo == false then
  this.col_c = 14
 end
 this.col_up = 5
 this.col_down = 5
 this.done = false
 this.stage_3_ttl = 50
 this.stage_n1_ttl = 20
 this.warp = {}
 this.warp.x = 60
 this.warp.y = 20
 this.draw = function()
  rectfill(4, 4, 124, 50, 0)
  rect(4, 4, 124, 50, 2)
  pset(this.ship.x-cos(this.ship.direction-.05)*this.ship.size, this.ship.y-sin(this.ship.direction-.05) * this.ship.size, 7) //make it rotate around the middle??
  pset(this.ship.x-cos(this.ship.direction+.05)*this.ship.size, this.ship.y-sin(this.ship.direction+.05) * this.ship.size, 7) //make it rotate around the middle??
  pset(this.ship.x, this.ship.y, 8)
  circ(this.planet.x, this.planet.y, this.planet.r)
  print('science: ',5,5,7)
  //print(this.science_needed, 69,5,14)
  //print('science gathered: ',5,11,7)
  if this.show_science then
   //print(flr(this.score), 77, 11, 15)
   draw_science(this.score,this.science_needed, 36, 5, 14, 2)
  end
  print('➡️', 14, 30, this.col_right)
  print('⬅️', 6, 30, this.col_left)
  print('⬆️', 10, 24, this.col_up)
  print('⬇️', 10, 36, this.col_down)
  print('❎', 6, 42, this.col_x)
  print('🅾️', 14, 42, this.col_c)
  if not this.warp.collected then 
   circfill(this.warp.x, this.warp.y, 2, 12)
  end
  circ(this.warp.x, this.warp.y, 2, 6)
  draw_power(ceil(this.ship.speed*25), 114, 12, 12, 1, true)
 end
 this.update = function()
  if this.stage == -1 then
   this.col_c = 14
   this.stage_n1_ttl -= 1
   if this.stage_n1_ttl <= 17 then
    this.col_c = 5
   end
   if this.stage_n1_ttl <= 0 then
    this.stage = 0
   end
  end
  if this.stage == 0 then
   this.ship.direction-=.005
   this.col_right = 14
   if this.ship.direction <= .1 then
    this.col_right = 5
    this.stage = 1
   end
  end
  if this.stage == 1 then
   this.col_left = 14
   this.ship.direction+=.005
   if this.ship.direction >= .4 then
    this.stage = 1.3
    this.col_left = 5
   end
  end
  if this.stage == 1.3 then
   this.ship.speed-=.01
   this.col_down = 14
   if this.ship.speed <= .7 then
    this.col_down = 5
    this.stage = 1.7
   end
  end
  if this.stage == 1.7 then
   this.col_up = 14
   this.ship.speed+=.01
   if this.ship.speed >= 1 then
    this.stage = 2
    this.col_up = 5
    //setup launch
    this.ship.vel[1] = cos(this.ship.direction) 
    this.ship.vel[2] = sin(this.ship.direction)
    this.ship.vel = scale_table(this.ship.vel, this.ship.speed)
   end
  end
  if this.stage == 2 then
   this.score+=.1
   if this.score >= 2 and this.score <=2.1 then
    this.score += 2
    this.warp.collected = true
   end
   if this.score < .5 then
    this.col_x = 14
   else
    this.col_x = 5
   end
   local dist = distance(this.ship.x,this.ship.y, this.planet.x, this.planet.y)
   local pull = {this.planet.x-this.ship.x, this.planet.y - this.ship.y}
   pull = scale_table(pull, .1/dist)
   this.ship.vel = add_tables(this.ship.vel, pull)
   this.ship.direction = get_direction(this.ship.vel)
   this.ship.x += this.ship.vel[1]
   this.ship.y += this.ship.vel[2]
   if this.score >= 10 then
    this.stage = 3
   end
  end
  if this.stage == 3 then
   this.stage_3_ttl -= 1
   this.show_science = (mod(flr(this.stage_3_ttl/10), 2) == 0)
   if this.stage_3_ttl <= 3 then
    this.col_c = 14
   end
   if this.stage_3_ttl <= 0 then
    this.done = true
   end
  end
 end
 return this
end

__gfx__
00000000888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000800000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700800808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000800000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000800000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700808800080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000800000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
