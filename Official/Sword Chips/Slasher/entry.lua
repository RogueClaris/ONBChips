nonce = function() end

local DAMAGE = 240
local SLASH_TEXTURE = Engine.load_texture(_modpath.."spell_sword_slashes.png")
local BLADE_TEXTURE = Engine.load_texture(_modpath.."spell_sword_blades.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.card.Slasher")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'B', 'I', 'R'})

    local props = package:get_card_props()
    props.shortname = "Slasher"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Sword
    props.description = "Cuts when A btn is held!"
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	action:set_lockout(make_sequence_lockout())
    action.execute_func = function(self, user)
		local step1 = Battle.Step.new()
		local cooldown = 10
		local slashed = false
		local tile_array = {}
		local field = user:get_field()
		local ref = self
		local do_once = true
		for i = 0, 6, 1 do
			for j = 0, 6, 1 do
				local tile = field:tile_at(i, j)
				if tile and not tile:is_edge() and user:is_team(tile:get_team()) then
					table.insert(tile_array, tile)
				end
			end
		end
		local query = function(character)
			return character:get_current_tile():get_team() == user:get_team()
		end
		step1.update_func = function(self, dt)
			if cooldown > 0 then
				if user:input_has(Input.Held.Use) then
					for k = 1, #tile_array, 1 do
						local triggered = #tile_array[k]:find_characters(query) > 0
						if triggered and not tile_array[k]:contains_entity(user) then
							if do_once then
								local action2 = Battle.CardAction.new(user, "PLAYER_SWORD")
								action2:set_lockout(make_animation_lockout())
								slashed = true
								action2.execute_func = function(self, user2)
								end
								action2:add_anim_action(2, function()
									local hilt = action2:add_attachment("HILT")
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
								end)
								action2:add_anim_action(2, function()
									local sword = create_slash(user, props)
									local tile = user:get_tile(user:get_facing(), 1)
									local fx = Battle.Artifact.new()
									fx:set_facing(sword:get_facing())
									local anim = fx:get_animation()
									fx:set_texture(SLASH_TEXTURE, true)
									anim:load(_modpath.."spell_sword_slashes.animation")
									anim:set_state("WIDE")
									anim:on_complete(function()
										fx:erase()
										sword:erase()
									end)
									field:spawn(fx, tile_array[k])
									field:spawn(sword, tile_array[k])
									self:complete_step()
								end)
								user:card_action_event(action2, ActionOrder.Involuntary)
								do_once = false
							end
						end
						if slashed then
							self:complete_step()
							break
						end
					end
				elseif user:input_has(Input.Released.Use) then
					self:complete_step()
				end
				cooldown = cooldown - dt
				if slashed then
					self:complete_step()
				end
			else
				self:complete_step()
			end
		end
		self:add_step(step1)
	end
    return action
end

function create_slash(user, props)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_facing(user:get_facing())
	spell:highlight_tile(Highlight.Flash)
	spell:set_hit_props(
		HitProps.new(
			props.damage,
			Hit.Impact | Hit.Flinch | Hit.Flash,
			props.element,
			user:get_context(),
			Drag.None
		)
	)
	spell.update_func = function(self, dt)
		self:get_tile():attack_entities(self)
	end

	spell.can_move_to_func = function(tile)
		return true
	end

	Engine.play_audio(AUDIO, AudioPriority.Low)

	return spell
end