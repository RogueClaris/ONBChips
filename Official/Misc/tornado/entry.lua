nonce = function() end

local DAMAGE = 20
local TEXTURE = Engine.load_texture(_modpath.."spell_tornado.png")
local BUSTER_TEXTURE = Engine.load_texture(_modpath.."buster_fan.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

local FRAME1 = {1, 0.1}
local FRAME2 = {2, 0.05}
local FRAME3 = {3, 0.05}
local FRAMES = make_frame_data({FRAME1, FRAME3, FRAME2, FRAME3, FRAME2, FRAME3, FRAME2, FRAME3, FRAME2, FRAME3, FRAME2, FRAME1})

function package_init(package) 
    package:declare_package_id("com.claris.chip.Tornado")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'T'})

    local props = package:get_card_props()
    props.shortname = "Tornado"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Wind
    props.description = "8 attack storm 2sq ahead"
end

function card_create_action(actor, props)
    print("in create_card_action()!")
     local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
	action:override_animation_frames(FRAMES)
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
		local buster = self:add_attachment("BUSTER")
		buster:sprite():set_texture(BUSTER_TEXTURE, true)
		buster:sprite():set_layer(-1)
		
		local buster_anim = buster:get_animation()
		buster_anim:load(_modpath.."buster_fan.animation")
		buster_anim:set_state("DEFAULT")
		buster_anim:refresh(buster:sprite())
		buster_anim:set_playback(Playback.Loop)
		
		local cannonshot = create_attack(user, props)
		local tile = user:get_tile(user:get_facing(), 2)
		actor:get_field():spawn(cannonshot, tile)
		
	end
    return action
end

function create_attack(user, props)
	local spell = Battle.Spell.new(user:get_team())
	spell.hits = 8
	spell:set_facing(user:get_facing())
	spell:highlight_tile(Highlight.Solid)
	spell:set_texture(TEXTURE, true)
	spell:sprite():set_layer(-1)
	local direction = user:get_facing()
    spell:set_hit_props(
        HitProps.new(
            props.damage,
            Hit.Impact | Hit.Flinch, 
            props.element,
            user:get_context(),
            Drag.None
        )
    )
	local anim = spell:get_animation()
    anim:load(_modpath.."spell_tornado.animation")
    anim:set_state("DEFAULT")
	anim:refresh(spell:sprite())
	spell.update_func = function(self, dt) 
		self:get_current_tile():attack_entities(self)
    end
	anim:on_complete(
		function()
			if spell.hits > 1 then
				anim:set_playback(Playback.Loop)
				spell.hits = spell.hits - 1
				local hitbox = Battle.Hitbox.new(spell:get_team())
				hitbox:set_hit_props(spell:copy_hit_props())
				spell:get_field():spawn(hitbox, spell:get_current_tile())
			else
				spell:erase()
			end
		end
	)
	spell.collision_func = function(self, other)
	end
    spell.attack_func = function(self, other) 
    end

    spell.delete_func = function(self)
		self:erase()
    end

    spell.can_move_to_func = function(tile)
        return true
    end

	Engine.play_audio(AUDIO, AudioPriority.High)
	return spell
end