nonce = function() end

function package_init(package) 
    package:declare_package_id("com.claris.dark.DarkCircleGun")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'R'})

    local props = package:get_card_props()
    props.shortname = "DarkCirc"
    props.damage = 300
    props.time_freeze = true
    props.element = Element.Cursor
    props.description = "STOP CURSR AND ATTACK"
	props.card_class = CardClass.Dark
	props.limit = 1
	props.long_description = "A Dark Chip. Searches the outer ring of the enemy's 3x3 area. Input A to attack."
	props.can_boost = false
end

function card_create_action(player, props)
	print("in create_card_action()!")
    local action = Battle.CardAction.new(player, "PLAYER_IDLE")
	action:set_lockout(make_sequence_lockout())
	local tile_array = {}
	action.execute_func = function(self, user)
		local step1 = Battle.Step.new()
		local step2 = Battle.Step.new()
		local do_once = true
		local do_step2_once = true
		local ref = self
		local field = user:get_field()
		local move_count = 60
		local current_moves = 0
		local direction = Direction.Right
		local slide_cooldown = 3
		local erase_array = {}
		step1.update_func = function(self, dt)
			if do_once then
				ref.artifact = Battle.Artifact.new()
				ref.artifact:set_texture(Engine.load_texture(_modpath.."cursor.png", true))
				ref.artifact:sprite():set_layer(-2)
				ref.artifact:get_animation():load(_modpath.."cursor.animation")
				ref.artifact:get_animation():set_state("SEARCH")
				ref.artifact:get_animation():refresh(ref.artifact:sprite())
				ref.artifact:get_animation():set_playback(Playback.Loop)
				ref.artifact.can_move_to_func = function(tile)
					return true
				end
				if user:get_facing() == Direction.Left then
					field:spawn(ref.artifact, field:tile_at(1, 1))
				else
					field:spawn(ref.artifact, field:tile_at(6, 1))
				end
				do_once = false
			end
			if user:input_has(Input.Pressed.Use) or current_moves >= move_count then
				ref.artifact:get_animation():set_state("FOUND")
				ref.artifact:get_animation():refresh(ref.artifact:sprite())
				table.insert(erase_array, ref.artifact)
				for i = 0, 6, 1 do
					local extra_artifact = Battle.Artifact.new()
					local spawn_tile = ref.artifact:get_tile(cursor_bounce(ref.artifact, direction, user:get_team()), 1)
					table.insert(tile_array, spawn_tile)
					direction = cursor_bounce(ref.artifact, direction, user:get_team())
					field:spawn(extra_artifact, spawn_tile)
					ref.artifact = extra_artifact
					table.insert(erase_array, ref.artifact)
				end
				self:complete_step()
			else
				if slide_cooldown <= 0 then
					ref.artifact:slide(ref.artifact:get_tile(cursor_bounce(ref.artifact, direction, user:get_team()), 1), frames(0), frames(0), ActionOrder.Voluntary, function() end)
					direction = cursor_bounce(ref.artifact, direction, user:get_team())
					slide_cooldown = 3
					current_moves = current_moves + 1
					print(current_moves)
				else
					slide_cooldown = slide_cooldown - 1
				end
			end			
		end
		step2.update_func = function(self, dt)
			for j = 1, #tile_array, 1 do
				local attack = create_attack(user, props)
				local cursor = erase_array[1]
				if cursor ~= nil then
					table.remove(erase_array, 1)
					cursor:set_texture(Engine.load_texture(_modpath.."cursor.png", true))
					cursor:sprite():set_layer(-2)
					cursor:get_animation():load(_modpath.."cursor.animation")
					cursor:get_animation():set_state("FOUND")
					cursor:get_animation():refresh(cursor:sprite())
					cursor:erase()
					field:spawn(attack, tile_array[j])
				end
			end
			self:complete_step()
		end
		self:add_step(step1)
		self:add_step(step2)
	end
	return action
end

function cursor_bounce(cursor, direction, team)
	local tile = cursor:get_tile()
	local next_direction = direction
	
	if tile:get_tile(Direction.Left, 1):is_edge() and tile:get_tile(Direction.Up, 1):is_edge() or tile:get_tile(Direction.Left, 1):get_team() == team and tile:get_tile(Direction.Up, 1):is_edge() then
		next_direction = Direction.Right
		if tile:get_tile(Direction.Right, 1):get_team() == team or tile:get_tile(Direction.Right, 1):is_edge() then
			next_direction = Direction.Down
		end
	elseif tile:get_tile(Direction.Right, 1):is_edge() and tile:get_tile(Direction.Up, 1):is_edge() or tile:get_tile(Direction.Right, 1):get_team() == team and tile:get_tile(Direction.Up, 1):is_edge() then
		next_direction = Direction.Down
		if tile:get_tile(Direction.Down, 1):get_team() == team or tile:get_tile(Direction.Down, 1):is_edge() then
			next_direction = Direction.Left
		end
	elseif tile:get_tile(Direction.Right, 1):is_edge() and tile:get_tile(Direction.Down, 1):is_edge() or tile:get_tile(Direction.Right, 1):get_team() == team and tile:get_tile(Direction.Down, 1):is_edge() then
		next_direction = Direction.Left
		if tile:get_tile(Direction.Left, 1):get_team() == team or tile:get_tile(Direction.Left, 1):is_edge() then
			next_direction = Direction.Up
		end
	elseif tile:get_tile(Direction.Left, 1):is_edge() and tile:get_tile(Direction.Down, 1):is_edge() or tile:get_tile(Direction.Left, 1):get_team() == team and tile:get_tile(Direction.Down, 1):is_edge() then
		next_direction = Direction.Up
		if tile:get_tile(Direction.Up, 1):get_team() == team or tile:get_tile(Direction.Up, 1):is_edge() then
			next_direction = Direction.Right
		end
		
	end
			
	return next_direction
end

function create_attack(user, props)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_facing(user:get_facing())
	spell:set_hit_props(
		HitProps.new(
			props.damage,
			Hit.Impact | Hit.Flinch | Hit.Flash,
			props.element,
			user:get_context(),
			Drag.None
		)
	)
	spell:set_texture(Engine.load_texture(_modpath.."spell_charged_bullet_hit.png", true))
	spell:sprite():set_layer(-2)
	local anim = spell:get_animation()
	anim:load(_modpath.."spell_charged_bullet_hit.animation")
	anim:set_state("HIT")
	anim:refresh(spell:sprite())
	anim:on_complete(function()
		spell:erase()
	end)
	spell.update_func = function(self, dt)
		local tile = self:get_tile()
		tile:attack_entities(self)
	end

	spell.can_move_to_func = function(tile)
		return true
	end

	return spell
end