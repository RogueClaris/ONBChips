nonce = function() end

local AUDIO = Engine.load_audio(_modpath.."boom.ogg")
local TEXTURE = Engine.load_texture(_modpath.."present.png")
local EXPLOSION_TEXTURE = Engine.load_texture(_modpath.."spell_explosion.png")

function package_init(package) 
    package:declare_package_id("com.claris.card.PresentBomb")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'M', 'P'})

    local props = package:get_card_props()
    props.shortname = "Present"
    props.damage = 0
    props.time_freeze = true
    props.element = Element.Summon
    props.description = "To all a good night!"
	props.can_boost = false
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")		
		local tile_array = {}
		local cooldown = 0
		local field = user:get_field()
		local do_once = true
		local exploding = false
		for i = 0, 6, 1 do
			for j = 0, 6, 1 do
				local tile = field:tile_at(i, j)
				if tile and not tile:is_edge() then
					table.insert(tile_array, tile)
				end
			end
		end
		local present = Battle.Obstacle.new(Team.Other)
		present:set_texture(TEXTURE, true)
		present:get_animation():load(_modpath.."present.animation")
		present:get_animation():set_state("SPAWN")
		present:get_animation():on_complete(function()
			present:get_animation():set_state("DEFAULT")
			present:get_animation():set_playback(Playback.Loop)
		end)
		present:set_health(200)
		present.can_move_to_func = function(tile)
			if tile then
				if present:get_offset().y == -300 then
					return true
				else
					if not tile:is_walkable() or tile:is_edge() then
						return false
					end
				end
			end
			return true
		end
		present.battle_end_func = function(self)
			print("hi")
			tile_array = {}
			if not present:will_erase_eof() then
				present:erase()
			end
		end
		present.update_func = function(self, dt)
			local tile = present:get_current_tile()
			if self:get_health() <= 0 then
				if do_once then
					exploding = true
					Engine.play_audio(AUDIO, AudioPriority.Low)
					present:shake_camera(3, 2.0)
					present:toggle_hitbox(false)
					present:set_offset(0.0, -300.0)
					present:teleport(field:tile_at(0, 1), ActionOrder.Involuntary, function() end)
					do_once = false
				end
				for i = 0, 6, 1 do
					for j = 0, 6, 1 do
						local tile3 = field:tile_at(i, j)
						if tile3 and not tile3:is_edge() then
							local explosion2 = create_boom(user)
							field:spawn(explosion2, tile3)
						end
					end
				end
				for k = 0, #tile_array, 1 do
					if cooldown <= 0 then
						if #tile_array > 0 then
							local index = math.random(1, #tile_array)
							local tile2 = tile_array[index]
							local explosion = create_artifact_boom(user)
							field:spawn(explosion, tile2)
							table.remove(tile_array, index)
						else
							table.remove(tile_array, index)
							k = k - 1
						end
						cooldown = 0.75
					else
						cooldown = cooldown - dt
					end
				end
				if #tile_array == 0 then
					self:delete()
				end
			end
			if not exploding then
				if not tile then
					self:erase()
				end
				if not tile:is_walkable() or tile:is_edge() then
					self:erase()
				end
			end
		end
		user:get_field():spawn(present, user:get_tile(user:get_facing(), 1))
	end
    return action
end

function create_artifact_boom(user)
	local spell = Battle.Artifact.new()
	spell:set_texture(EXPLOSION_TEXTURE, true)
	spell:set_facing(user:get_facing())
	
	local anim = spell:get_animation()
    anim:load(_modpath.."spell_explosion.animation")
    anim:set_state("Default")
	anim:on_complete(function()
		spell:erase()
	end)
	spell.can_move_to_func = function(self, other)
		return true
	end
	spell.battle_end_func = function(self)
		spell:erase()
	end
	return spell
end

function create_boom(user)
	local spell = Battle.Spell.new(Team.Other)
	spell:set_facing(user:get_facing())
    spell:set_hit_props(
        HitProps.new(
            200, 
            Hit.Impact | Hit.Flinch | Hit.Flash, 
            Element.None,
            user:get_context(),
            Drag.None
        )
    )
	spell.update_func = function(self, dt)
		self:get_current_tile():attack_entities(self)
    end
	
	spell.collision_func = function(self, other)
	end
	spell.can_move_to_func = function(self, other)
		return true
	end
	spell.battle_end_func = function(self)
		spell:erase()
	end
	return spell
end