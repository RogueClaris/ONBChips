nonce = function() end

local DAMAGE = 30
local APPEAR = Engine.load_audio(_modpath.."appear.ogg")
local FWISH = Engine.load_audio(_modpath.."attack.ogg")
local TEXTURE = Engine.load_texture(_modpath.."snake.png")
local SNAKE_FINISHED = true

function package_init(package) 
    package:declare_package_id("com.claris.card.Snake")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'L'})

    local props = package:get_card_props()
    props.shortname = "Snake"
    props.damage = DAMAGE
    props.time_freeze = true
    props.element = Element.Wood
    props.description = "Call out snakes from hole"
	props.card_class = CardClass.Standard
	props.limit = 3
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	
	action:set_lockout(make_sequence_lockout())
	local anim_ended = false
    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")
		local step1 = Battle.Step.new()
        local current_x = user:get_current_tile():x()
		local dir = user:get_facing()
		local field = user:get_field()
		local tile_array = {}
		for i = current_x, 6, 1 do
			for j = 0, 6, 1 do
				local tile = field:tile_at(i, j)
				if tile and user:is_team(tile:get_team()) and not tile:is_edge() and not tile:is_reserved({}) and tile:get_state() == TileState.Broken then
					table.insert(tile_array, tile)
				end
			end
		end
		local DO_ONCE = false
		step1.update_func = function(self, dt)
			if not DO_ONCE then
				DO_ONCE = true
				for i = 1, #tile_array, 1 do
					Engine.play_audio(APPEAR, AudioPriority.Low)
					local snake = spawn_snake(user, props)
					field:spawn(snake, tile_array[i])
				end
			end
			if SNAKE_FINISHED then
				self:complete_step()
			end
		end
		self:add_step(step1)
	end
    return action
end

function spawn_snake(user, props)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_texture(TEXTURE, true)
	spell:set_facing(user:get_facing())
	spell:set_offset(0.0, -24.0)
	local direction = user:get_facing()
    spell.slide_started = false
	SNAKE_FINISHED = false
    spell:set_hit_props(
        HitProps.new(
            props.damage, 
            Hit.Impact | Hit.Flinch, 
            Element.Wood,
            user:get_context(),
            Drag.None
        )
    )
	local target = user:get_field():find_nearest_characters(user, 
		function(found)
			if not user:is_team(found:get_team()) and found:get_health() > 0 then
				return true
			end
		end
	)
	local cooldown = 0.131
	local DO_ONCE = false
	spell.update_func = function(self, dt) 
        self:get_current_tile():attack_entities(self)
		if spell:get_animation():get_state() == "ATTACK" then
			if not DO_ONCE then
				Engine.play_audio(FWISH, AudioPriority.Low)
				DO_ONCE = true
			end
			if cooldown <= 0 then
				if self:is_sliding() == false then 
					if self:get_current_tile():is_edge() and self.slide_started then 
						SNAKE_FINISHED = true
						self:delete()
					end 
					local dest = spell:get_tile(direction, 1)
					if target[1] ~= nil then
						dest = target[1]:get_current_tile()
					end
					local ref = self
					self:slide(dest, frames(3), frames(0), ActionOrder.Voluntary, 
						function()
							ref.slide_started = true 
						end
					)
				end
			else
				cooldown = cooldown - dt
			end
		end
    end
	
	local anim = spell:get_animation()
    anim:load(_modpath.."snake.animation")
    anim:set_state("APPEAR")
	spell:get_animation():on_complete(
		function()
			anim:set_state("ATTACK")
		end
	)
	
	spell.collision_func = function(self, other)
		SNAKE_FINISHED = true
		self:erase()
	end
	spell.can_move_to_func = function(self, other)
		return true
	end
	return spell
end