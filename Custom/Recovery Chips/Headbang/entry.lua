nonce = function() end

local TEXTURE = Engine.load_texture(_modpath.."spell_heal.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.Dawn.card.Headbang")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'*'})

    local props = package:get_card_props()
    props.shortname = "Headbang"
    props.damage = 0
    props.time_freeze = true
    props.element = Element.Break
    props.description = "Soul of Rock!"
	props.card_class = CardClass.Standard
	props.limit = 1
	props.long_description = "Style on 'em! Headbang away and heal up!"
end

function card_create_action(user, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(user, "PLAYER_THROW")
	local frame1 = {1, 0.1}
	local frame2 = {2, 0.1}
	local frame3 = {3, 0.1}
	local frame4 = {4, 0.1}
	local frame_list = make_frame_data({frame1, frame2, frame3, frame2, frame3, frame2, frame3, frame2, frame3, frame2, frame3, frame2, frame3, frame2, frame3, frame2, frame3, frame2, frame3, frame2, frame3, frame4})
	action:override_animation_frames(frame_list)
	action:set_lockout(make_animation_lockout())
	action.execute_func = function(self, user2)
		self:add_anim_action(#frame_list, function()
			local field = user:get_field()
			local query = function(ent)
				if Battle.Character.from(ent) ~= nil then
					return true
				end
			end
			for i = 0, 6, 1 do
				for j = 0, 3, 1 do
					local tile = field:tile_at(i, j)
					if not tile:is_edge() then
						local list = tile:find_entities(query)
						if #list > 0 then
							for k = 0, #list, 1 do
								if list[k] then
									local heal_spell = create_recov("DEFAULT", list[k])
									list[k]:set_health(list[k]:get_health() + 1)
									field:spawn(heal_spell, list[k]:get_tile())
								end
							end
						end
					end
				end
			end
		end)
	end
	return action
end

function create_recov(animation_state, user)
    local spell = Battle.Spell.new(Team.Other)
    spell:set_texture(TEXTURE, true)
	spell:set_facing(user:get_facing())
    spell:set_hit_props(
        HitProps.new(
            1,
			Hit.None,
            Element.None,
            user:get_context(),
            Drag.None
        )
    )
	spell:sprite():set_layer(-1)
    local anim = spell:get_animation()
    anim:load(_modpath.."spell_heal.animation")
    anim:set_state(animation_state)
	spell:get_animation():on_complete(
		function()
			spell:erase()
		end
	)

    spell.delete_func = function(self)
		self:erase()
    end

    spell.can_move_to_func = function(tile)
        return true
    end

	Engine.play_audio(AUDIO, AudioPriority.High)

    return spell
end