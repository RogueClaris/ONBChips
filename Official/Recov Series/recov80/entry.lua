nonce = function() end

local DAMAGE = 80
local TEXTURE = Engine.load_texture(_modpath.."spell_heal.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.recovseries.recov4")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'H', 'K', 'V', '*'})

    local props = package:get_card_props()
    props.shortname = "Recov80"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.None
    props.description = "Restore 80HP to self!"
	props.limit = 4
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_HEAL")

    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")		
		local recov = create_recov("DEFAULT", user)
		actor:get_field():spawn(recov, actor:get_current_tile())
		actor:set_health(actor:get_health() + DAMAGE)
	end
    return action
end

function create_recov(animation_state, user)
    local spell = Battle.Spell.new(Team.Other)
    spell:set_texture(TEXTURE, true)
	spell:set_facing(user:get_facing())
    spell:set_hit_props(
        HitProps.new(
            DAMAGE,
			Hit.None,
            Element.None,
            user:get_context(),
            Drag.None
        )
    )
	spell:sprite():set_layer(-1)
    local anim = spell:get_animation()
    anim:load(_modpath.."spell_heal.animation")
    anim:set_state(animation_state)
	spell:get_animation():on_complete(
		function()
			spell:erase()
		end
	)

    spell.delete_func = function(self)
		self:erase()
    end

    spell.can_move_to_func = function(tile)
        return true
    end

	Engine.play_audio(AUDIO, AudioPriority.High)

    return spell
end