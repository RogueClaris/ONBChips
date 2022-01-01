nonce = function() end

local DAMAGE = 140
local TEXTURE = Engine.load_texture(_modpath.."elecpulse.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")
local FRAME1 = {1, 0.05}
local FRAME2 = {2, 0.05}
local FRAME3 = {3, 0.05}
local FRAMES = make_frame_data({FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3, FRAME1, FRAME2, FRAME3})

function package_init(package) 
    package:declare_package_id("com.claris.card.ElecPulse3")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'A', 'J', 'S'})

    local props = package:get_card_props()
    props.shortname = "ElcPuls3"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Elec
    props.description = "Sprd elec puls hits w/HP bug."
	props.limit = 2
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
	action:override_animation_frames(FRAMES)
	action:set_lockout(make_animation_lockout())
    local cannonshot = create_pulse(actor, props)
	action.execute_func = function(self, user)
		local buster = self:add_attachment("BUSTER")
		buster:sprite():set_texture(TEXTURE, true)
		buster:sprite():set_layer(-1)
		
		local buster_anim = buster:get_animation()
		buster_anim:load(_modpath.."elecpulse.animation")
		buster_anim:set_state("BUSTER")
		
		local fx = buster:add_attachment("PULSE")
		fx:sprite():set_texture(TEXTURE, true)
		fx:sprite():set_layer(-2)
		
		local fx_anim = fx:get_animation()
		fx_anim:load(_modpath.."elecpulse.animation")
		fx_anim:set_state("PULSE")
		
		local tile = user:get_tile(user:get_facing(), 1)
		actor:get_field():spawn(cannonshot, tile)
		
		fx_anim:on_complete(function()
			fx:erase()
		end)
	end
	action.action_end_func = function(self)
		cannonshot:erase()
	end
    return action
end

function create_pulse(user, props)
    local spell = Battle.Spell.new(user:get_team())
	spell:highlight_tile(Highlight.Solid)
	spell:set_facing(user:get_facing())
	local direction = user:get_facing()
    spell:set_hit_props(
        HitProps.new(
            props.damage, 
            Hit.Impact | Hit.Flinch | Hit.Pierce,
            Element.Elec,
            user:get_context(),
            Drag.None
       	)
	)
	local sharebox1 = Battle.SharedHitbox.new(spell, 1.2)
	sharebox1:set_hit_props(spell:copy_hit_props())
	local sharebox2 = Battle.SharedHitbox.new(spell, 1.2)
	sharebox2:set_hit_props(spell:copy_hit_props())
	local sharebox3 = Battle.SharedHitbox.new(spell, 1.2)
	sharebox3:set_hit_props(spell:copy_hit_props())
	local field = user:get_field()
	local do_once = true
    spell.update_func = function(self, dt)
		local tile = spell:get_current_tile():get_tile(direction, 1)
		if tile and not tile:is_edge() then	
			field:spawn(sharebox1, tile)
			tile:highlight(Highlight.Solid)
		end
		local tile2 = tile:get_tile(Direction.Up, 1)
		local tile3 = tile:get_tile(Direction.Down, 1)
		if tile2 and not tile2:is_edge() then	
			field:spawn(sharebox2, tile2)
			tile2:highlight(Highlight.Solid)
		end
		if tile3 and not tile3:is_edge() then	
			field:spawn(sharebox3, tile3)
			tile3:highlight(Highlight.Solid)
		end
		if do_once then
			if tile and not tile:is_edge() then	
				field:spawn(sharebox1, tile)
			end
			if tile2 and not tile2:is_edge() then	
				field:spawn(sharebox2, tile2)
			end
			if tile3 and not tile3:is_edge() then	
				field:spawn(sharebox3, tile3)
			end
			do_once = false
			spell:get_current_tile():attack_entities(self)
		end
    end
	spell.collision_func = function(self, other)
	end
    spell.attack_func = function(self, other) 
		local hp_bug = Battle.Component.new(other, Lifetimes.Battlestep)
		hp_bug.scene_inject_func = function(self)
			self.cooldown = 1
		end
		hp_bug.update_func = function(self, dt)
			if self:get_owner():get_health() > 1 then
				self.cooldown = self.cooldown - dt
				if self.cooldown < 0 then
					self:get_owner():set_health(self:get_owner():get_health() - 1)
					self.cooldown = 1
				end
			end
		end
		other:register_component(hp_bug)
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