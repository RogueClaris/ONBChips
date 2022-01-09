nonce = function() end

local DAMAGE = 70
local TEXTURE = Engine.load_texture(_modpath.."flashman.png")
local HIT_TEXTURE = Engine.load_texture(_modpath.."hit.png")

function package_init(package) 
	package:declare_package_id("com.Dawn.Official.Flashman")
	package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
	package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'F', 'U'})

	local props = package:get_card_props()
	props.shortname = "FlashmnV2"
	props.damage = DAMAGE
	props.time_freeze = true
	props.element = Element.Elec
	props.description = "Flash attack paralyzes"
	props.limit = 1
	props.card_class = CardClass.Mega
	props.can_boost = false
	props.long_description = "Flashman appears and paralyzes all foes on the field!"
end

function card_create_action(actor, props)
    print("in create_card_action()!")
	local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	action:set_lockout(make_sequence_lockout())
	action.execute_func = function(self, user)
		local actor = self:get_actor()
		actor:hide()
		local step1 = Battle.Step.new()
		local field = user:get_field()
		local tile = user:get_tile()
		local tile_array = {}
		local friendly_query = function(ent)
			if user:is_team(ent:get_team()) then
				return true
			end
		end
		for i = 1, 6, 1 do
			for j = 1, 3, 1 do
				local tile = field:tile_at(i, j)
				if tile == user:get_tile() then
					print("user tile found, skipping")
				elseif #tile:find_characters(friendly_query) > 0 or #tile:find_obstacles(friendly_query) > 0 then
					print("friendly tile found, skipping")
				else
					table.insert(tile_array, tile)
				end
			end
		end
		local do_once = true
		local ref = self
		local do_once_part_two = true
		step1.update_func = function(self, dt)
			if do_once then
				do_once = false
				ref.formortiis = Battle.Artifact.new()
				ref.formortiis:set_facing(user:get_facing())
				ref.formortiis:set_texture(TEXTURE, true)
				ref.formortiis:sprite():set_layer(-1)
				
				boss_anim = ref.formortiis:get_animation()
				boss_anim:load(_modpath.."flashman.animation")
				boss_anim:set_state("APPEAR")
				boss_anim:refresh(ref.formortiis:sprite())
				boss_anim:on_complete(function()
					boss_anim:set_state("FLASH_ATTACK")
					boss_anim:refresh(ref.formortiis:sprite())
				end)
				field:spawn(ref.formortiis, tile)
			end
			local anim = ref.formortiis:get_animation()
			if anim:get_state() == "FLASH_ATTACK" then
				if do_once_part_two then
					do_once_part_two = false
					anim:on_frame(7, function()
						for k = 1, #tile_array, 1 do
							local spell = create_attack(user, props)
							field:spawn(spell, tile_array[k])
						end
					end)
					anim:on_complete(function()
						ref.formortiis:erase()
						step1:complete_step()
					end)
				end
			end
		end
		self:add_step(step1)
	end
	action.action_end_func = function(self)
		self:get_actor():reveal()
	end
	return action
end

function create_attack(user, props)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_facing(user:get_facing())
	spell:set_texture(HIT_TEXTURE, true)
    spell:set_hit_props(
        HitProps.new(
            props.damage,
            Hit.Impact | Hit.Flinch | Hit.Stun, 
            props.element,
            user:get_context(),
            Drag.None
        )
    )
	local anim = spell:get_animation()
    anim:load(_modpath.."hit.animation")
    anim:set_state("DEFAULT")
	anim:refresh(spell:sprite())
	anim:on_complete(function()
		spell:erase()
	end)
	spell:sprite():set_layer(-1)
	local query = function(ent)
		if Battle.Character.from(ent) ~= nil or Battle.Obstacle.from(ent) ~= nil then
			return true
		end
	end
	spell.update_func = function(self, dt)
		self:get_current_tile():attack_entities(self)
    end
	
	spell.collision_func = function(self, other)
	end
	spell.can_move_to_func = function(self, other)
		return true
	end
	spell.battle_end_func = function(self)
		spell:erase()
	end
	return spell
end