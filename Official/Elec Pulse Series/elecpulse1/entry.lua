nonce = function() end

local DAMAGE = 100
local TEXTURE = Engine.load_texture(_modpath.."elecpulse.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")
local FRAME1 = {1, 0.05}
local FRAME2 = {2, 0.05}
local FRAME3 = {3, 0.05}
local FRAMES = make_frame_data({FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3})

function package_init(package) 
    package:declare_package_id("com.claris.card.ElecPulse1")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'J', 'L', 'S'})

    local props = package:get_card_props()
    props.shortname = "ElcPuls1"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Elec
    props.description = "Sprd elec puls that paralyzes"
	props.limit = 1
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
	action:override_animation_frames(FRAMES)
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
		local buster = self:add_attachment("BUSTER")
		buster:sprite():set_texture(TEXTURE, true)
		buster:sprite():set_layer(-1)
		
		local buster_anim = buster:get_animation()
		buster_anim:load(_modpath.."elecpulse.animation")
		buster_anim:set_state("BUSTER")
		
		local cannonshot = create_pulse("PULSE", user)
		local tile = user:get_tile(user:get_facing(), 1)
		actor:get_field():spawn(cannonshot, tile)
	end
    return action
end

function create_pulse(animation_state, user)
    local spell = Battle.Spell.new(user:get_team())
	spell:highlight_tile(Highlight.Solid)
	spell:set_facing(user:get_facing())
	spell:set_offset(45.0, -54.0)
	local direction = user:get_facing()
    spell:set_hit_props(
        HitProps.new(
            DAMAGE, 
            Hit.Impact | Hit.Stun | Hit.Pierce | Hit.Retangible, 
            Element.Elec,
            user:get_context(),
            Drag.None
        )
    )
	
	local anim = spell:get_animation()
    anim:load(_modpath.."elecpulse.animation")
    anim:set_state(animation_state)
	spell:get_animation():on_complete(
		function()
			spell:erase()
		end
	)
	
    spell.update_func = function(self, dt)
		local tile = spell:get_current_tile():get_tile(direction, 1)
		if tile and not tile:is_edge() then	
			tile:highlight(Highlight.Solid)
			tile:attack_entities(self)
		end
		local tile2 = tile:get_tile(Direction.Up, 1)
		local tile3 = tile:get_tile(Direction.Down, 1)
		if tile2 and not tile2:is_edge() then	
			tile2:highlight(Highlight.Solid)
			tile2:attack_entities(self)
		end
		if tile3 and not tile3:is_edge() then	
			tile3:highlight(Highlight.Solid)
			tile3:attack_entities(self)
		end
        spell:get_current_tile():attack_entities(self)
    end
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

	Engine.play_audio(AUDIO, AudioPriority.Low)

    return spell
end