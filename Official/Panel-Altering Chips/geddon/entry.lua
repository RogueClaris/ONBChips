nonce = function() end

local TEXTURE = Engine.load_texture(_modpath.."poof.png")
local AUDIO = Engine.load_audio(_modpath.."break.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.card.Geddon1")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'A', 'L', 'R', '*'})

    local props = package:get_card_props()
    props.shortname = "Geddon"
    props.damage = 0
    props.time_freeze = true
    props.element = Element.None
    props.description = "Breaks all empty panels"
	props.card_class = CardClass.Standard
	props.limit = 2
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	action:set_lockout(make_sequence_lockout())
	local field = actor:get_field()
	local tile_array = {}
	local cooldown = 0
	action.execute_func = function(self, user)
        print("in custom card action execute_func()!")
		for i = 0, 6, 1 do
			for j = 0, 6, 1 do
				local tile = field:tile_at(i, j)
				if tile and not tile:is_edge() and tile:get_state() ~= TileState.Broken then
					table.insert(tile_array, tile)
				end
			end
		end
		local step1 = Battle.Step.new()
		step1.update_func = function(self, dt)
			for k = 0, #tile_array, 1 do
				if cooldown <= 0 then
					if #tile_array > 0 then
						local index = math.random(1, #tile_array)
						local tile2 = tile_array[index]
						if tile2:get_state() ~= TileState.Broken and tile2:get_state() ~= TileState.Cracked then
							local fx = Battle.Artifact.new()
							fx:set_texture(TEXTURE, true)
							fx:get_animation():load(_modpath.."poof.animation")
							fx:get_animation():set_state("DEFAULT")
							fx:get_animation():on_complete(function()
								fx:erase()
							end)
							field:spawn(fx, tile2)
							if not tile2:is_reserved({}) then
								tile2:set_state(TileState.Broken)
							else
								tile2:set_state(TileState.Cracked)
							end
							Engine.play_audio(AUDIO, AudioPriority.Low)
							table.remove(tile_array, index)
						else
							table.remove(tile_array, index)
							k = k - 1
						end
						cooldown = 0.75
					else
						self:complete_step()
					end
				else
					cooldown = cooldown - dt
				end
			end
		end
		self:add_step(step1)
	end
	return action
end