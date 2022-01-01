nonce = function() end

local TEXTURE = Engine.load_texture(_modpath.."RockCube.png")

function package_init(package) 
    package:declare_package_id("com.claris.card.RockCube")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'*'})

    local props = package:get_card_props()
    props.shortname = "RockCube"
    props.damage = 0
    props.time_freeze = true
    props.element = Element.Summon
    props.description = "Place a RockCube in front"
	props.can_boost = false
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	
    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")		
		local cube = Battle.Obstacle.new(Team.Other)
		cube:set_texture(TEXTURE, true)
		cube:get_animation():load(_modpath.."RockCube.animation")
		cube:get_animation():set_state("SPAWN")
		cube:get_animation():on_complete(function()
			cube:get_animation():set_state("DEFAULT")
			cube:get_animation():set_playback(Playback.Loop)
		end)
		cube:set_health(200)
		cube.can_move_to_func = function(self, tile)
			if tile then
				if not tile:is_walkable() or tile:is_edge() then
					return false
				end
			end
			return true
		end
		cube.attack_func = function(self)
			local tile = self:get_tile()
			local hitbox = Battle.Hitbox.new(Team.Other)
			local props = HitProps.new(
				200, 
				Hit.Impact | Hit.Flinch | Hit.Flash, 
				Element.None,
				user:get_context(),
				Drag.None
			)
			hitbox:set_hit_props(props)
			user:get_field():spawn(hitbox, self:get_tile())
			self:erase()
		end
		cube.update_func = function(self, dt)
			local tile = cube:get_current_tile()
			tile:attack_entities(self)
			if not tile then
				self:erase()
			end
			if not tile:is_walkable() or tile:is_edge() then
				self:erase()
			end
			if self:is_sliding() then
				if self:can_move_to_func(tile:get_tile(self:get_facing(), 1)) then
					continue_slide = true
					saved_direction = self:get_facing()
				elseif not self:can_move_to_func(tile:get_tile(self:get_facing(), 1)) then
					continue_slide = false
					saved_direction = Direction.None
				end
			end
			if not self:is_sliding() and continue_slide then
				self:slide(self:get_tile(saved_direction, 1), frames(6), frames(0), ActionOrder.Voluntary, function() end)
			end
			if self:get_health() <= 0 then
				self:delete()
			end
		end
		cube.delete_func = function(self)
			self:erase()
		end
		user:get_field():spawn(cube, user:get_tile(user:get_facing(), 1))
	end
    return action
end