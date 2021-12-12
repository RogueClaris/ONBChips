nonce = function() end

local DAMAGE = 0
local BUSTER_TEXTURE = Engine.load_texture(_modpath.."darkcannon.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.dark.DarkCannon")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'X'})

    local props = package:get_card_props()
    props.shortname = "DarkCan"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.None
    props.description = "INCREASE ATK WITH DAMAGE"
	props.card_class = CardClass.Dark
	props.limit = 1
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
	
	action:set_lockout(make_async_lockout(0.22))

    action.execute_func = function(self, user)
		local buster = self:add_attachment("BUSTER")
		buster:sprite():set_texture(BUSTER_TEXTURE, true)
		buster:sprite():set_layer(-1)
		
		local buster_anim = buster:get_animation()
		buster_anim:load(_modpath.."darkcannon.animation")
		buster_anim:set_state("DEFAULT")
		
		local cannonshot = create_attack(user)
		local tile = user:get_tile(user:get_facing(), 1)
		actor:get_field():spawn(cannonshot, tile)
	end
    return action
end

function create_attack(user, spell)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_facing(user:get_facing())
	spell.slide_started = false
	DAMAGE = user:get_max_health() - user:get_health()
	if DAMAGE > 1000 then
		DAMAGE = 1000
	end
    spell:set_hit_props(
        HitProps.new(
            DAMAGE, 
            Hit.Impact | Hit.Flinch | Hit.Pierce | Hit.Flash,
            Element.Cursor,
            user:get_context(),
            Drag.None
        )
    )
	spell.update_func = function(self, dt) 
        self:get_current_tile():attack_entities(self)
        if self:is_sliding() == false then
            if self:get_current_tile():is_edge() and self.slide_started then 
                self:delete()
            end 
			
            local dest = self:get_tile(spell:get_facing(), 1)
            local ref = self
            self:slide(dest, frames(1), frames(0), ActionOrder.Voluntary, 
                function()
                    ref.slide_started = true 
                end
            )
        end
    end
	spell.collision_func = function(self, other)
		self:delete()
	end
    spell.attack_func = function(self, other) 
    end

    spell.delete_func = function(self)
		self:erase()
    end

    spell.can_move_to_func = function(tile)
        return true
    end

	Engine.play_audio(AUDIO, AudioPriority.Low)
	return spell
end