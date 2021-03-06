nonce = function() end

local DAMAGE = 400
local SLASH_TEXTURE = Engine.load_texture(_modpath.."spell_darksword.png")
local BLADE_TEXTURE = Engine.load_texture(_modpath.."spell_sword_blades.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.dark.DarkSword")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'*'})

    local props = package:get_card_props()
    props.shortname = "DrkSword"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Sword
    props.description = "USE LARGE SWORD AND SLICE"
	props.card_class = CardClass.Dark
	props.limit = 1
	props.long_description = "A Dark Chip. Slashes 3x2 ahead, but forces you to move forward constantly when not inputting."
	props.can_boost = false
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
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
				local sword = create_slash(user)
				local tile = user:get_tile(user:get_facing(), 1)
				local tile2 = user:get_tile(user:get_facing(), 2)
				local sharebox1 = Battle.SharedHitbox.new(sword, 0.15)
				sharebox1:set_hit_props(sword:copy_hit_props())
				local sharebox2 = Battle.SharedHitbox.new(sword, 0.15)
				sharebox2:set_hit_props(sword:copy_hit_props())
				local sharebox3 = Battle.SharedHitbox.new(sword, 0.15)
				sharebox3:set_hit_props(sword:copy_hit_props())
				local sharebox4 = Battle.SharedHitbox.new(sword, 0.15)
				sharebox4:set_hit_props(sword:copy_hit_props())
				local sharebox5 = Battle.SharedHitbox.new(sword, 0.15)
				sharebox5:set_hit_props(sword:copy_hit_props())
				actor:get_field():spawn(sharebox2, tile:get_tile(Direction.Down, 1))
				actor:get_field():spawn(sharebox3, tile2:get_tile(Direction.Down, 1))
				actor:get_field():spawn(sword, tile)
				actor:get_field():spawn(sharebox4, tile2)
				actor:get_field():spawn(sharebox1, tile:get_tile(Direction.Up, 1))
				actor:get_field():spawn(sharebox5, tile2:get_tile(Direction.Up, 1))
				local fx = Battle.Artifact.new()
				fx:set_facing(sword:get_facing())
				actor:get_field():spawn(fx, tile)
				local anim = fx:get_animation()
				fx:set_texture(SLASH_TEXTURE, true)
				anim:load(_modpath.."spell_darksword.animation")
				anim:set_state("DEFAULT")
				anim:on_complete(
					function()
						fx:erase()
						sword:erase()
					end
				)
				actor:get_field():spawn(fx, tile)
			end
		)
		local move_bug = Battle.Component.new(user, Lifetimes.Battlestep)
		move_bug.update_func = function(self, dt)
			local owner = self:get_owner()
			if not owner:is_teleporting() and not(owner:input_has(Input.Pressed.Left) or owner:input_has(Input.Held.Left) or owner:input_has(Input.Pressed.Up) or owner:input_has(Input.Held.Up) or owner:input_has(Input.Pressed.Down) or owner:input_has(Input.Held.Down) or owner:input_has(Input.Held.Use) or owner:input_has(Input.Pressed.Shoot) or owner:input_has(Input.Held.Shoot) or owner:input_has(Input.Pressed.Special) or owner:input_has(Input.Held.Special)) then
				owner:teleport(owner:get_tile(owner:get_facing(), 1), ActionOrder.Voluntary)
			end
		end
		user:register_component(move_bug)
	end
    return action
end

function create_slash(user)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_facing(user:get_facing())
	spell:highlight_tile(Highlight.Flash)
	spell:set_hit_props(
		HitProps.new(
			DAMAGE,
			Hit.Impact | Hit.Flinch | Hit.Flash,
			Element.Sword,
			user:get_context(),
			Drag.None
		)
	)
	spell.update_func = function(self, dt)
		local tile = spell:get_current_tile()
		local tile2 = tile:get_tile(spell:get_facing(), 1)
		if tile then
			if tile:get_tile(Direction.Up, 1) and not tile:get_tile(Direction.Up, 1):is_edge() then
				tile:get_tile(Direction.Up, 1):highlight(Highlight.Flash)
			end
			if tile:get_tile(Direction.Down, 1) and not tile:get_tile(Direction.Down, 1):is_edge() then
				tile:get_tile(Direction.Down, 1):highlight(Highlight.Flash)
			end
		end
		
		if tile2 then
			if tile2:get_tile(Direction.Up, 1) and not tile2:get_tile(Direction.Up, 1):is_edge() then
				tile2:get_tile(Direction.Up, 1):highlight(Highlight.Flash)
			end
			if tile2:get_tile(Direction.Down, 1) and not tile2:get_tile(Direction.Down, 1):is_edge() then
				tile2:get_tile(Direction.Down, 1):highlight(Highlight.Flash)
			end
			if not tile2:is_edge() then
				tile2:highlight(Highlight.Flash)
			end
		end
		tile:attack_entities(self)
	end

	spell.can_move_to_func = function(tile)
		return true
	end

	Engine.play_audio(AUDIO, AudioPriority.Low)

	return spell
end