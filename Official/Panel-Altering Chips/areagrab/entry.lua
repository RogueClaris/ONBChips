nonce = function() end

local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")
local FINISH_AUDIO = Engine.load_audio(_modpath.."finish_sfx.ogg")
local TEXTURE = Engine.load_texture(_modpath.."grab.png")
local FRAME1 = {1, 1.28}
local LONG_FRAME = make_frame_data({FRAME1})

function package_init(package) 
    package:declare_package_id("com.claris.card.areagrab")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'B', 'F', 'S', '*'})

    local props = package:get_card_props()
    props.shortname = "AreaGrab"
    props.damage = 0
    props.time_freeze = true
    props.element = Element.None
    props.description = "Steal the edge from enemy!"
	props.can_boost = false
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	action:override_animation_frames(LONG_FRAME)
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")
		self.tile = nil
		local opposite_team = Team.Blue
		if user:get_team() == Team.Red then
			if user:get_facing() == Direction.Right then
				self.tile = user:get_field():tile_at(1, 2)
			else
				self.tile = user:get_field():tile_at(6, 2)
			end
		else
			opposite_team = Team.Red
			self.tile = user:get_field():tile_at(6, 2)
		end
		self.dir = user:get_facing()
		self.tile_array = {nil, nil, nil}
		self.count = 1
		self.max = 6
		local ref = self
		local tile_front = nil
		local tile_up = nil
		local tile_down = nil
		local check1 = false
		local check_front = false
		local check_up = false
		local check_down = false
		
		local fx1 = nil
		local fx2 = nil
		local fx3 = nil
		for i = ref.count, ref.max, 1 do
			
			tile_front = ref.tile:get_tile(user:get_facing(), i)
			tile_up = tile_front:get_tile(Direction.Up, 1)
			tile_down = tile_front:get_tile(Direction.Down, 1)
			
			check_front = tile_front and not user:is_team(tile_front:get_team()) and not tile_front:is_edge() and not tile_front:get_team() ~= Team.Other and tile_front:get_tile(user:get_facing(), 1):get_team() == opposite_team
			check_up = tile_up and not user:is_team(tile_up:get_team()) and not tile_up:is_edge() and not tile_up:get_team() ~= Team.Other and tile_up:get_tile(user:get_facing(), 1):get_team() == opposite_team
			check_down = tile_down and not user:is_team(tile_down:get_team()) and not tile_down:is_edge() and not tile_down:get_team() ~= Team.Other and tile_down:get_tile(user:get_facing(), 1):get_team() == opposite_team
			
			if check_front or check_up or check_down then
				ref.tile_array[0] = tile_front
				if tile_up and not tile_up:is_edge() then
					ref.tile_array[1] = tile_up
				end
				if tile_down and not tile_down:is_edge() then
					ref.tile_array[2] = tile_down
				end
				break
			end
		end
		
		if #ref.tile_array > 0 and not check1 then
			Engine.play_audio(AUDIO, AudioPriority.Low)
			if ref.tile_array[0] ~= nil then
				fx1 = MakeTileSplash(user)
				user:get_field():spawn(fx1, ref.tile_array[0])
			end
			if ref.tile_array[1] ~= nil then
				fx2 = MakeTileSplash(user)
				user:get_field():spawn(fx2, ref.tile_array[1])
			end
			if ref.tile_array[2] ~= nil then
				fx3 = MakeTileSplash(user)
				user:get_field():spawn(fx3, ref.tile_array[2])
			end
			check1 = true
		end
		if #ref.tile_array > 0 then
			Engine.play_audio(FINISH_AUDIO, AudioPriority.Low)
		end
	end
    return action
end

function MakeTileSplash(user)
	local artifact = Battle.Artifact.new()
	artifact:sprite():set_texture(TEXTURE, true)
	local anim = artifact:get_animation()
	anim:load(_modpath.."areagrab.animation")
	anim:set_state("FALL")
	artifact:set_offset(0.0, -296.0)
	artifact:sprite():set_layer(-1)
	local doOnce = false
	artifact.update_func = function(self, dt)
		if self:get_offset().y >= -24 then
			if not doOnce then
				self:set_offset(0.0, 0.0)
				self:get_animation():set_state("EXPAND")
				self:get_current_tile():set_team(user:get_team(), false)
				local hitbox = Battle.Hitbox.new(user:get_team())
				local props = HitProps.new(
					10, 
					Hit.Impact,
					Element.None,
					user:get_id(),
					Drag.None
				)
				hitbox:set_hit_props(props)
				user:get_field():spawn(hitbox, self:get_current_tile())
				doOnce = true
			end
			self:get_animation():on_complete(
				function()
					self:delete()
				end
			)
		else
			self:set_offset(0.0, self:get_offset().y + 8.0)
		end
	end
	artifact.delete_func = function(self)
		self:erase()
	end
	return artifact
end