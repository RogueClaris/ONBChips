nonce = function() end

local DAMAGE = 20
local TEXTURE = Engine.load_texture(_modpath.."spell_zapring.png")
local BUSTER_TEXTURE = Engine.load_texture(_modpath.."buster_zapring.png")
local AUDIO = Engine.load_audio(_modpath.."fwish.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.card.Zapring")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'*'})

    local props = package:get_card_props()
    props.shortname = "Zap Ring"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Elec
    props.description = "Ring stuns enmy ahead!"
end

--[[
    1. megaman loads buster
    2. zapring flies out
--]]

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
	
	action:set_lockout(make_animation_lockout())

    action.execute_func = function(self, user)
		local buster = self:add_attachment("BUSTER")
		buster:sprite():set_texture(BUSTER_TEXTURE, true)
		buster:sprite():set_layer(-1)
		
		local buster_anim = buster:get_animation()
		buster_anim:load(_modpath.."buster_zapring.animation")
		buster_anim:set_state("DEFAULT")
		
		local cannonshot = create_zap("DEFAULT", user)
		local tile = user:get_tile(user:get_facing(), 1)
		actor:get_field():spawn(cannonshot, tile)
	end
    return action
end

function create_zap(animation_state, user)
    local spell = Battle.Spell.new(user:get_team())
    spell:set_texture(TEXTURE, true)
    spell:highlight_tile(Highlight.Solid)
	spell:set_offset(0.0, 16.0)
	local direction = user:get_facing()
    spell.slide_started = false
	
    spell:set_hit_props(
        HitProps.new(
            DAMAGE, 
            Hit.Impact | Hit.Stun | Hit.Flinch, 
            Element.Elec,
            user:get_context(),
            Drag.None
        )
    )
	
    local anim = spell:get_animation()
    anim:load(_modpath.."spell_zapring.animation")
    anim:set_state(animation_state)

    spell.update_func = function(self, dt) 
        self:get_current_tile():attack_entities(self)

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
    end

    spell.attack_func = function(self, other) 
        -- nothing
    end
	
	spell.collision_func = function(self, other)
		self:erase()
	end
	
    spell.delete_func = function(self) 
    end

    spell.can_move_to_func = function(tile)
        return true
    end

	Engine.play_audio(AUDIO, AudioPriority.Low)

    return spell
end