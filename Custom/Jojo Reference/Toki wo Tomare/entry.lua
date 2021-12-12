nonce = function() end

local DAMAGE = 30
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")
local TEXTURE = Engine.load_texture(_modpath.."knife.png")
local SHOUT_ONE = Engine.load_audio(_modpath.."ZAWARUDO.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.jojoreference.TokiwoTomare")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'D','I','O'})

    local props = package:get_card_props()
    props.shortname = "Za World"
    props.damage = DAMAGE
    props.time_freeze = true
    props.element = Element.None
    props.description = "ZA WORLD! TOKI WO TOMARE!"
	props.card_class = CardClass.Mega
	props.limit = 3
end

function card_create_action(actor, props)
    print("in create_card_action()!")
	
	Engine.play_audio(SHOUT_ONE, AudioPriority.Low)
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	
	action:set_lockout(make_animation_lockout())
	local anim_ended = false
    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")
		
        local current_x = user:get_current_tile():x()
		local dir = user:get_facing()
		local field = user:get_field()
		local tile_array = {}
		for i = current_x, 6, 1 do
			for j = 0, 6, 1 do
				local tile = field:tile_at(i, j)
				if tile and user:is_team(tile:get_team()) and not tile:is_edge() then
					table.insert(tile_array, tile)
				end
			end
		end
		Engine.play_audio(AUDIO, AudioPriority.Low)
		for i = 1, #tile_array, 1 do
			local knife = spawn_knife(user)
			field:spawn(knife, tile_array[i])
		end
	end
    return action
end

function spawn_knife(user)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_texture(TEXTURE, true)
	spell:set_facing(user:get_facing())
	spell:set_offset(0.0, -24.0)
	local direction = user:get_facing()
    spell.slide_started = false
    spell:set_hit_props(
        HitProps.new(
            DAMAGE, 
            Hit.Impact | Hit.Flinch, 
            Element.Sword,
            user:get_context(),
            Drag.None
        )
    )
	local cooldown = 0.33
	spell.update_func = function(self, dt) 
        self:get_current_tile():attack_entities(self)
		if spell:get_animation():get_state() == "POINT" then
			if cooldown <= 0 then
				if self:is_sliding() == false then 
					if self:get_current_tile():is_edge() and self.slide_started then 
						self:delete()
					end 

					local dest = self:get_tile(direction, 1)
					local ref = self
					self:slide(dest, frames(4), frames(0), ActionOrder.Voluntary, 
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
    anim:load(_modpath.."knife.animation")
    anim:set_state("SPIN")
	spell:get_animation():on_complete(
		function()
			anim:set_state("POINT")
		end
	)
	
	spell.collision_func = function(self, other)
		if spell:get_animation():get_state() == "POINT" then
			self:erase()
		end
	end
	spell.can_move_to_func = function(self, other)
		return true
	end
	return spell
end