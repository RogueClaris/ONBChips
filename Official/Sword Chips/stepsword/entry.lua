nonce = function() end

local DAMAGE = 160
local SLASH_TEXTURE = Engine.load_texture(_modpath.."spell_sword_slashes.png")
local BLADE_TEXTURE = Engine.load_texture(_modpath.."spell_sword_blades.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.card.StepSword01")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'B', 'L', 'P'})

    local props = package:get_card_props()
    props.shortname = "StepSwrd"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Sword
    props.description = "Use WideSwrd 2sq ahead"
	props.limit = 2
end

function card_create_action(actor, props)
    print("in create_card_action()!")
	if actor:get_current_tile():get_tile(actor:get_facing(), 2) and not actor:get_current_tile():get_tile(actor:get_facing(), 2):is_reserved({actor:get_id()}) then
		local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
		
		action:set_lockout(make_animation_lockout())

		action.execute_func = function(self, user)
			print("in custom card action execute_func()!")
			actor_tile = actor:get_current_tile()
			warp_tile = actor:get_current_tile():get_tile(user:get_facing(), 2)
			
			if warp_tile and not warp_tile:is_edge() and not warp_tile:is_reserved({actor:get_id()}) then
				warp_tile:add_entity(actor)
				actor_tile:remove_entity_by_id(actor:get_id())
				self:add_anim_action(2, 
					function()
						local hilt = self:add_attachment("HILT")
						local hilt_sprite = hilt:sprite()
						hilt_sprite:set_texture(actor:get_texture())
						hilt_sprite:set_layer(-2)
						hilt_sprite:enable_parent_shader(true)
						
						local hilt_anim = hilt:get_animation()
						hilt_anim:copy_from(actor:get_animation())
						hilt_anim:set_state("HILT")

						local blade = hilt:add_attachment("ENDPOINT")
						local blade_sprite = blade:sprite()
						blade_sprite:set_texture(BLADE_TEXTURE)
						blade_sprite:set_layer(-1)

						local blade_anim = blade:get_animation()
						blade_anim:load(_modpath.."spell_sword_blades.animation")
						blade_anim:set_state("DEFAULT")
					end
				)
				
				self:add_anim_action(3,
					function()
						local sword = create_slash(user, props)
						local tile = user:get_tile(user:get_facing(), 1)
						local sharebox1 = Battle.SharedHitbox.new(sword, 0.15)
						sharebox1:set_hit_props(sword:copy_hit_props())
						local sharebox2 = Battle.SharedHitbox.new(sword, 0.15)
						sharebox2:set_hit_props(sword:copy_hit_props())
						actor:get_field():spawn(sharebox1, tile:get_tile(Direction.Up, 1))
						actor:get_field():spawn(sword, tile)
						actor:get_field():spawn(sharebox2, tile:get_tile(Direction.Down, 1))
						local fx = Battle.Artifact.new()
						fx:set_facing(sword:get_facing())
						actor:get_field():spawn(fx, tile)
						local anim = fx:get_animation()
						fx:set_texture(SLASH_TEXTURE)
						anim:load(_modpath.."spell_sword_slashes.animation")
						anim:set_state("WIDE")
						anim:on_complete(
							function()
								fx:erase()
								sword:erase()
							end
						)
					end
				)
			end
		end
		action.action_end_func = function(self)
			actor_tile:add_entity(actor)
			warp_tile:remove_entity_by_id(actor:get_id())
		end
		
		return action
	end
	return Battle.CardAction.new(actor, "PLAYER_IDLE")
end

function create_slash(user, props)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_facing(user:get_facing())
	spell:highlight_tile(Highlight.Flash)
	spell:set_hit_props(
		HitProps.new(
			props.damage,
			Hit.Impact | Hit.Flinch | Hit.Flash,
			Element.Sword,
			user:get_context(),
			Drag.None
		)
	)
	spell.update_func = function(self, dt)
		if not self:get_tile():get_tile(Direction.Up, 1):is_edge() then
			self:get_tile():get_tile(Direction.Up, 1):highlight(Highlight.Flash)
		end
		if not self:get_tile():get_tile(Direction.Down, 1):is_edge() then
			self:get_tile():get_tile(Direction.Down, 1):highlight(Highlight.Flash)
		end
		self:get_tile():attack_entities(self)
	end

	spell.can_move_to_func = function(tile)
		return true
	end

	Engine.play_audio(AUDIO, AudioPriority.Low)

	return spell
end