nonce = function() end

local DAMAGE = 100
local SLASH_TEXTURE = Engine.load_texture(_modpath.."spell_dreamsword.png")
local BLADE_TEXTURE = Engine.load_texture(_modpath.."elem_sword_blades.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.card.GaiaDream")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'G'})

    local props = package:get_card_props()
    props.shortname = "GaiaDrem"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Wood
	props.secondary_element = Element.Sword
    props.description = "Take 1/2 pwr, 3x2 slash"
	props.card_class = CardClass.Giga
	props.limit = 1
	props.can_boost = false
	
	package.filter_hand_step = function(in_props, adj_cards) 
        if adj_cards:has_card_to_right() and adj_cards.right_card.damage > 0 then
			if in_props.damage >= 500 then
				in_props.damage = 500
			else
				in_props.damage = in_props.damage + math.floor(adj_cards.right_card.damage/2)
			end
            adj_cards:discard_right()
        end
	end
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
	action:set_metadata(props)
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
				blade_anim:load(_modpath.."elem_sword_blades.animation")
				blade_anim:set_state("WOOD")
			end
		)

		self:add_anim_action(3,
			function()
				local sword = create_slash(user, props)
				local tile = user:get_tile(user:get_facing(), 1)
				actor:get_field():spawn(sword, tile)
				local fx = Battle.Artifact.new()
				fx:set_facing(sword:get_facing())
				local anim = fx:get_animation()
				fx:set_texture(SLASH_TEXTURE, true)
				anim:load(_modpath.."spell_dreamsword.animation")
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
		
	end
    return action
end

function create_slash(user, props)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_facing(user:get_facing())
	spell:highlight_tile(Highlight.Solid)
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
		local tile = spell:get_current_tile()
		local tile2 = tile:get_tile(spell:get_facing(), 1)
		if tile then
			if tile:get_tile(Direction.Up, 1) and not tile:get_tile(Direction.Up, 1):is_edge() then
				tile:get_tile(Direction.Up, 1):highlight(Highlight.Solid)
				tile:get_tile(Direction.Up, 1):attack_entities(self)
			end
			if tile:get_tile(Direction.Down, 1) and not tile:get_tile(Direction.Down, 1):is_edge() then
				tile:get_tile(Direction.Down, 1):highlight(Highlight.Solid)
				tile:get_tile(Direction.Down, 1):attack_entities(self)
			end
		end
		
		if tile2 then
			if tile2:get_tile(Direction.Up, 1) and not tile2:get_tile(Direction.Up, 1):is_edge() then
				tile2:get_tile(Direction.Up, 1):highlight(Highlight.Solid)
				tile2:get_tile(Direction.Up, 1):attack_entities(self)
			end
			if tile2:get_tile(Direction.Down, 1) and not tile2:get_tile(Direction.Down, 1):is_edge() then
				tile2:get_tile(Direction.Down, 1):highlight(Highlight.Solid)
				tile2:get_tile(Direction.Down, 1):attack_entities(self)
			end
			if not tile2:is_edge() then
				tile2:highlight(Highlight.Solid)
				tile2:attack_entities(self)
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