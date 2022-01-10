nonce = function() end

function package_init(package) 
    package:declare_package_id("com.Dawn.card.CrackShoot")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'A', 'G', 'T', '*'})

    local props = package:get_card_props()
    props.shortname = "CrakShot"
    props.damage = 60
    props.time_freeze = false
    props.element = Element.None
    props.description = "Shoot a panel at an enemy!"
	props.limit = 5
end

function card_create_action(actor, props)
    local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	
	action:set_lockout(make_animation_lockout())
	
	action.execute_func = function(self, user)
        local panel = nil
		local tile = user:get_tile(user:get_facing(), 1)
		self:add_anim_action(2, function()
			local hilt = self:add_attachment("HILT")
			local hilt_sprite = hilt:sprite()
			hilt_sprite:set_texture(actor:get_texture())
			hilt_sprite:set_layer(-2)
			hilt_sprite:enable_parent_shader(true)

			local hilt_anim = hilt:get_animation()
			hilt_anim:copy_from(actor:get_animation())
			hilt_anim:set_state("HAND")
		end)
		
		if panel == nil then
			self:add_anim_action(3, 
				function()
					panel = create_attack(user, props, tile)
					user:get_field():spawn(panel, tile)
				end
			)
        end
	end
    return action
end

function create_attack(user, props, tile)
	local spell = Battle.Spell.new(user:get_team())
	spell.can_move_to_func = function(self, tile)
		if tile then
			return true
		end
		return false
	end
	spell:set_facing(user:get_facing())
	if tile then
		local dust_fx = Battle.Artifact.new()
		dust_fx:set_texture(Engine.load_texture(_modpath.."dust.png"), true)
		dust_fx:set_facing(user:get_facing())
		local dust_anim = dust_fx:get_animation()
		dust_anim:load(_modpath.."dust.animation")
		dust_anim:set_state("DEFAULT")
		dust_anim:refresh(dust_fx:sprite())
		dust_anim:on_complete(function()
			dust_fx:erase()
		end)
		user:get_field():spawn(dust_fx, tile)
		if tile:is_reserved({}) and tile:is_walkable() then
			tile:set_state(TileState.Cracked)
			spell:erase()
		elseif not tile:is_reserved({}) and tile:is_walkable() then
			tile:set_state(TileState.Broken)
			spell:set_texture(Engine.load_texture(_modpath.."spell_panel_shot.png"), true)
			spell.slide_started = false
			spell:set_hit_props(
				HitProps.new(
					props.damage, 
					Hit.Impact | Hit.Flinch,
					props.element,
					user:get_context(),
					Drag.None
				)
			)
			spell:get_animation():load(_modpath.."spell_panel_shot.animation")
			if tile:get_team() == Team.Blue then
				spell:get_animation():set_state("BLUE_TEAM")
			else
				spell:get_animation():set_state("RED_TEAM")
			end
			spell:set_offset(0, 24)
			spell:get_animation():refresh(spell:sprite())
			spell:get_animation():on_complete(function()
				spell:get_animation():set_playback(Playback.Loop)
			end)
			spell.update_func = function(self, dt) 
				self:get_current_tile():attack_entities(self)
				if self:get_offset().y <= 0 then
					if self:is_sliding() == false then
						if self:get_current_tile():is_edge() and self.slide_started then 
							self:delete()
						end 
						
						local dest = self:get_tile(spell:get_facing(), 1)
						local ref = self
						self:slide(dest, frames(5), frames(0), ActionOrder.Voluntary, 
							function()
								ref.slide_started = true 
							end
						)
					end
				else
					self:set_offset(self:get_offset().x, self:get_offset().y - 4)
				end
			end
			spell.collision_func = function(self, other)
				self:delete()
			end
			Engine.play_audio(Engine.load_audio(_modpath.."sfx.ogg"), AudioPriority.Low)
		end
	end
	spell.delete_func = function(self)
		self:erase()
    end
	spell.can_move_to_func = function(self, tile)
        return true
    end
	return spell
end