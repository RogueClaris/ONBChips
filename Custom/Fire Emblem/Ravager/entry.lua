nonce = function() end

local DAMAGE = 300
local TEXTURE = Engine.load_texture(_modpath.."Formortiis.png")
local AUDIO = Engine.load_audio(_modpath.."Formortiis.ogg")
local EXPLOSION_TEXTURE = Engine.load_texture(_modpath.."spell_explosion.png")

function package_init(package) 
	package:declare_package_id("com.Dawn.FireEmblem.Formortiis")
	package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
	package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'D', 'F', 'L'})

	local props = package:get_card_props()
	props.shortname = "Ravager"
	props.damage = DAMAGE
	props.time_freeze = true
	props.element = Element.Break
	props.description = "DEMON KING SHATTERS"
	props.limit = 1
	props.card_class = CardClass.Giga
	props.can_boost = false
end

function card_create_action(actor, props)
    print("in create_card_action()!")
	local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	action:set_lockout(make_sequence_lockout())
	action.execute_func = function(self, user)
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
		local cooldown = 1
		step1.update_func = function(self, dt)
			if do_once then
				user:hide()
				do_once = false
				Engine.play_audio(AUDIO, AudioPriority.Low)
				local formortiis = Battle.Artifact.new()
				formortiis:set_facing(user:get_facing())
				formortiis:set_texture(TEXTURE, true)
				formortiis:sprite():set_layer(-1)
				
				local boss_anim = formortiis:get_animation()
				boss_anim:load(_modpath.."Formortiis.animation")
				boss_anim:set_state("BODY")
				
				
				local arm = Battle.Artifact.new()
				arm:set_facing(user:get_facing())
				arm:set_texture(TEXTURE, true)
				arm:sprite():set_layer(-2)
				
				local arm_anim = arm:get_animation()
				arm_anim:load(_modpath.."Formortiis.animation")
				arm_anim:set_state("ARM")
				
				arm_anim:on_complete(function()
					arm:erase()
					formortiis:erase()
					user:reveal()
					for k = 1, #tile_array, 1 do
						local spell = create_attack(user, props)
						field:spawn(spell, tile_array[k])
						step1:complete_step()
					end
				end)
				field:spawn(formortiis, tile)
				field:spawn(arm, tile)
			end
		end
		self:add_step(step1)
	end
	return action
end

function create_attack(user, props)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_facing(user:get_facing())
	spell:set_texture(EXPLOSION_TEXTURE, true)
    spell:set_hit_props(
        HitProps.new(
            props.damage,
            Hit.Impact | Hit.Flinch | Hit.Flash, 
            props.element,
            user:get_context(),
            Drag.None
        )
    )
	local anim = spell:get_animation()
    anim:load(_modpath.."spell_explosion.animation")
    anim:set_state("Default")
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
		if #self:get_tile():find_entities(query) > 0 then
			self:get_tile():set_state(TileState.Cracked)
		else
			self:get_tile():set_state(TileState.Broken)
		end
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