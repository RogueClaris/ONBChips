nonce = function() end

local DAMAGE = 100
local TEXTURE = Engine.load_texture(_modpath.."WarRock_exeOSS_battle.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.wav")

function package_init(package) 
	package:declare_package_id("com.dawn.card.AreaEater")
	package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
	package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'A','O','X'})

	local props = package:get_card_props()
	props.shortname = "AreaEatr"
	props.damage = DAMAGE
	props.time_freeze = true
	props.element = Element.Sword
	props.description = "Beast steals panels!"
	props.limit = 3
end

function card_create_action(actor, props)
    print("in create_card_action()!")
	local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	action:set_lockout(make_sequence_lockout())
	action.execute_func = function(self, user)
		local step1 = Battle.Step.new()
		local field = user:get_field()
		local query = function(ent)
			if Battle.Character.from(ent) ~= nil or Battle.Obstacle.from(ent) ~= nil then
				return true
			end
			return false
		end
		local tile = user:get_tile(user:get_facing(), 1)
		local entities = #tile:find_entities(query) > 0
		local do_once = true
		step1.update_func = function(self, dt)
			if do_once then
				if tile and tile:is_reserved({}) then
					step1:complete_step()
				else
					local fx = Battle.Artifact.new()
					fx:set_facing(user:get_facing())
					local anim = fx:get_animation()
					fx:set_texture(TEXTURE, true)
					anim:load(_modpath.."area_eater.animation")
					anim:set_state("APPEAR")
					anim:on_frame(3, function()
						Engine.play_audio(AUDIO, AudioPriority.Low)
					end)
					anim:on_complete(function()
						anim:set_state("SLAP")
						print("slap started")
						anim:on_frame(4, function()
							print("anim frame 4 hit")
							local hitbox1 = Battle.Hitbox.new(user:get_team())
							local hitbox2 = Battle.Hitbox.new(user:get_team())
							local hitbox3 = Battle.Hitbox.new(user:get_team())
							local props2 = HitProps.new(
								props.damage,
								Hit.Impact | Hit.Flinch | Hit.Flash,
								props.element,
								user:get_context(),
								Drag.None
							)
							hitbox1:set_hit_props(props2)
							hitbox2:set_hit_props(props2)
							hitbox3:set_hit_props(props2)
							local tile_for_hitbox1 = tile:get_tile(user:get_facing(), 1)
							local tile_for_hitbox2 = tile_for_hitbox1:get_tile(Direction.Up, 1)
							local tile_for_hitbox3 = tile_for_hitbox1:get_tile(Direction.Down, 1)
							if #tile_for_hitbox1:find_entities(query) > 0 then
								field:spawn(hitbox1, tile_for_hitbox1)
							else
								if user:is_team(tile:get_team()) then
									tile_for_hitbox1:set_team(user:get_team(), false)
								end
							end
							
							if #tile_for_hitbox2:find_entities(query) > 0 then
								field:spawn(hitbox2, tile_for_hitbox2)
							else
								if user:is_team(tile_for_hitbox2:get_tile(Direction.reverse(user:get_facing()), 1):get_team()) then
									tile_for_hitbox2:set_team(user:get_team(), false)
								end
							end
							
							if #tile_for_hitbox3:find_entities(query) > 0 then
								field:spawn(hitbox3, tile_for_hitbox3)
							else
								if user:is_team(tile_for_hitbox3:get_tile(Direction.reverse(user:get_facing()), 1):get_team()) then
									tile_for_hitbox3:set_team(user:get_team(), false)
								end
							end
						end)
						anim:on_complete(function()
							fx:erase()
							step1:complete_step()
						end)
					end)
					field:spawn(fx, tile)
				end
			end
			do_once = false
		end
		self:add_step(step1)
	end
	return action
end