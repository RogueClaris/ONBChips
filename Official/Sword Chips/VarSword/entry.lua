nonce = function() end

local DAMAGE = 160
local SLASH_TEXTURE = Engine.load_texture(_modpath.."spell_sword_slashes.png")
local BLADE_TEXTURE = Engine.load_texture(_modpath.."spell_sword_blades.png")
local DREAM_TEXTURE = Engine.load_texture(_modpath.."spell_dreamsword.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

function package_init(package) 
	package:declare_package_id("com.clarisAndKonst.card.VarSword")
	package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
	package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'B', 'K', 'V', 'W'})

	local props = package:get_card_props()
	props.shortname = "VarSwrd"
	props.damage = DAMAGE
	props.time_freeze = false
	props.element = Element.Sword
	props.description = "A magical shifting sword."
	props.limit = 3
end



local recipes = {
	{
		name = "long",
		pattern = {
			{ "down" },
			{ "down", "right" },
			{ "right" }
		}
	},
	{
		name = "wide",
		pattern = {
			{ "up" },
			{ "right" },
			{ "down" }
		}
	},
	{
		name = "fighter",
		pattern = {
			{ "left" },
			{ "down" },
			{ "right" },
			{ "up" },
			{ "left" }
		}
	},
	{
		name = "sonic",
		pattern = {
			{ "left" },
			{ "b" },
			{ "right" },
			{ "b" }
		}
	},
	{
		name = "dream",
		pattern = {
			{ "down" },
			{ "left" },
			{ "up" },
			{ "right" },
			{ "down" }
		}
	},
}

local function deep_clone(t)
	if type(t) ~= "table" then
		return t
	end

	local o = {}
	for k, v in pairs(t) do
		o[k] = deep_clone(v)
	end
	return o
end

local function contains(t, value)
	for k, v in ipairs(t) do
		if v == value then
			return true
		end
	end
	return false
end

local function get_first_completed_recipe(matching)
	for _, recipe in ipairs(matching) do
		if recipe.current_step > #recipe.pattern then
			return recipe.name
		end
	end

	return nil
end

function card_create_action(actor, props)
	local matching = deep_clone(recipes)

	for _, recipe in ipairs(matching) do
		recipe.current_step = 1
	end

	local action = Battle.CardAction.new(actor, "IDLE")
	action:set_lockout(make_sequence_lockout())

	local remaining_time = 50 -- 50 frame timer

	local step1 = Battle.Step.new()
	step1.update_func = function()
		remaining_time = remaining_time - 1

		if remaining_time < 0 or not actor:input_has(Input.Pressed.Use) and not actor:input_has(Input.Held.Use) or get_first_completed_recipe(matching) ~= nil then
			step1:complete_step()
			return
		end

		local drop_list = {}
		local inputs = {
			up = actor:input_has(Input.Pressed.Up),
			down = actor:input_has(Input.Pressed.Down),
			left = actor:input_has(Input.Pressed.Left),
			right = actor:input_has(Input.Pressed.Right),
			b = actor:input_has(Input.Pressed.Shoot)
		}

		local function inputs_fail(required_inputs)
			-- has an input that should not be held
			for name, held in pairs(inputs) do
				if held and not contains(required_inputs, name) then
					return true
				end
			end
			return false
		end

		local function inputs_match(required_inputs)
			for _, name in ipairs(required_inputs) do
				if not inputs[name] then
					return false
				end
			end
			return true
		end

		for i, recipe in ipairs(matching) do
			local last_required_inputs = recipe.pattern[recipe.current_step - 1]
			local required_inputs = recipe.pattern[math.min(recipe.current_step, #recipe.pattern)]
			local fails_current_requirements = inputs_fail(required_inputs)

			if fails_current_requirements and (not last_required_inputs or inputs_fail(last_required_inputs)) then
				-- has an input that failed to match the current + previous requirements
				drop_list[#drop_list + 1] = i
			elseif not fails_current_requirements and recipe.current_step <= #recipe.pattern and inputs_match(required_inputs) then
				-- has all of the required inputs to continue
				recipe.current_step = recipe.current_step + 1
			end
		end

		for i, v in ipairs(drop_list) do
			table.remove(matching, v - i + 1)
		end
	end
	action:add_step(step1)


	local step2 = Battle.Step.new()
	step2.update_func = function()
		local attack_name = get_first_completed_recipe(matching)

		print(attack_name)

		if attack_name == "wide" then
			take_wide_action(actor, props)
		elseif attack_name == "sonic" then
			take_sonic_action(actor, props)
		elseif attack_name == "long" then
			take_long_action(actor, props)
		elseif attack_name == "dream" then
			take_dream_action(actor, props)
		elseif attack_name == "fighter" then
			take_fighter_action(actor, props)
		else
			take_default_action(actor, props)
		end
		step2:complete_step()
	end
	action:add_step(step2)

	return action
end

-- actual attacks
function take_default_action(actor, props)
	local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
	action:add_anim_action(2, function()
		local hilt = action:add_attachment("HILT")
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
	action:add_anim_action(3, function()
		local sword = create_normal_slash(actor, props)
		local tile = actor:get_tile(actor:get_facing(), 1)
		local fx = Battle.Artifact.new()
		fx:set_facing(sword:get_facing())
		local anim = fx:get_animation()
		fx:set_texture(SLASH_TEXTURE, true)
		anim:load(_modpath.."spell_sword_slashes.animation")
		anim:set_state("DEFAULT")
		anim:on_complete(function()
			fx:erase()
			sword:erase()
		end)
		local field = actor:get_field()
		field:spawn(fx, tile)
		field:spawn(sword, tile)
	end)
	actor:card_action_event(action, ActionOrder.Involuntary)
end

function take_wide_action(actor, props)
	local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
	action:add_anim_action(2, function()
		local hilt = action:add_attachment("HILT")
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
	action:add_anim_action(3, function()
		local sword = create_wide_slash(actor, props)
		local tile = actor:get_tile(actor:get_facing(), 1)
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
		local field = actor:get_field()
		field:spawn(fx, tile)
		field:spawn(sword, tile)
	end)
	actor:card_action_event(action, ActionOrder.Involuntary)
end

function take_sonic_action(actor, props)
	local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
	action:add_anim_action(2, function()
		local hilt = action:add_attachment("HILT")
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
	action:add_anim_action(3, function()
		local sword = create_sonic_slash(actor, props)
		local tile = actor:get_tile(actor:get_facing(), 1)
		local fx = Battle.Artifact.new()
		fx:set_facing(sword:get_facing())
		local field = actor:get_field()
		field:spawn(sword, tile)
	end)
	actor:card_action_event(action, ActionOrder.Involuntary)
end

function take_long_action(actor, props)
	local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
	action:add_anim_action(2, function()
		local hilt = action:add_attachment("HILT")
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
	action:add_anim_action(3, function()
		local sword = create_long_slash(actor, props)
		local tile = actor:get_tile(actor:get_facing(), 1)
		local fx = Battle.Artifact.new()
		fx:set_facing(sword:get_facing())
		local anim = fx:get_animation()
		fx:set_texture(SLASH_TEXTURE, true)
		anim:load(_modpath.."spell_sword_slashes.animation")
		anim:set_state("LONG")
		anim:on_complete(function()
			fx:erase()
			sword:erase()
		end)
		local field = actor:get_field()
		field:spawn(fx, tile)
		field:spawn(sword, tile)
	end)
	actor:card_action_event(action, ActionOrder.Involuntary)
end

function take_fighter_action(actor, props)
	local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
	action:add_anim_action(2, function()
		local hilt = action:add_attachment("HILT")
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
	action:add_anim_action(3, function()
		local sword = create_fighter_slash(actor, props)
		local tile = actor:get_tile(actor:get_facing(), 1)
		local fx = Battle.Artifact.new()
		fx:set_facing(sword:get_facing())
		local anim = fx:get_animation()
		fx:set_texture(SLASH_TEXTURE, true)
		anim:load(_modpath.."spell_sword_slashes.animation")
		anim:set_state("BIG")
		anim:on_complete(function()
			fx:erase()
			sword:erase()
		end)
		local field = actor:get_field()
		field:spawn(fx, tile)
		field:spawn(sword, tile)
	end)
	actor:card_action_event(action, ActionOrder.Involuntary)
end

function take_dream_action(actor, props)
	local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
	action:add_anim_action(2, function()
		local hilt = action:add_attachment("HILT")
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
	action:add_anim_action(3, function()
		local sword = create_dream_slash(actor, props)
		local tile = actor:get_tile(actor:get_facing(), 1)
		local fx = Battle.Artifact.new()
		fx:set_facing(sword:get_facing())
		local anim = fx:get_animation()
		fx:set_texture(DREAM_TEXTURE, true)
		anim:load(_modpath.."spell_dreamsword.animation")
		anim:set_state("DEFAULT")
		anim:on_complete(function()
			fx:erase()
			sword:erase()
		end)
		local field = actor:get_field()
		field:spawn(fx, tile)
		field:spawn(sword, tile)
	end)
	actor:card_action_event(action, ActionOrder.Involuntary)
end

-- slashes
function create_normal_slash(user, props)
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

function create_wide_slash(user, props)
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
		if not self:get_tile():get_tile(Direction.Up, 1):is_edge() then
			self:get_tile():get_tile(Direction.Up, 1):highlight(Highlight.Flash)
			self:get_tile():get_tile(Direction.Up, 1):attack_entities(self)
		end
		if not self:get_tile():get_tile(Direction.Down, 1):is_edge() then
			self:get_tile():get_tile(Direction.Down, 1):highlight(Highlight.Flash)
			self:get_tile():get_tile(Direction.Down, 1):attack_entities(self)
		end
		self:get_tile():attack_entities(self)
	end

	spell.can_move_to_func = function(tile)
		return true
	end

	Engine.play_audio(AUDIO, AudioPriority.Low)

	return spell
end

function create_long_slash(user, props)
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
		if not self:get_tile():get_tile(user:get_facing(), 1):is_edge() then
			self:get_tile():get_tile(user:get_facing(), 1):highlight(Highlight.Flash)
			self:get_tile():get_tile(user:get_facing(), 1):attack_entities(self)
		end
		self:get_tile():attack_entities(self)
	end

	spell.can_move_to_func = function(tile)
		return true
	end

	Engine.play_audio(AUDIO, AudioPriority.Low)

	return spell
end

function create_dream_slash(user, props)
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
		local tile = spell:get_current_tile()
		local tile2 = tile:get_tile(spell:get_facing(), 1)
		if tile then
			if tile:get_tile(Direction.Up, 1) and not tile:get_tile(Direction.Up, 1):is_edge() then
				tile:get_tile(Direction.Up, 1):highlight(Highlight.Flash)
				tile:get_tile(Direction.Up, 1):attack_entities(self)
			end
			if tile:get_tile(Direction.Down, 1) and not tile:get_tile(Direction.Down, 1):is_edge() then
				tile:get_tile(Direction.Down, 1):highlight(Highlight.Flash)
				tile:get_tile(Direction.Down, 1):attack_entities(self)
			end
		end
		
		if tile2 then
			if tile2:get_tile(Direction.Up, 1) and not tile2:get_tile(Direction.Up, 1):is_edge() then
				tile2:get_tile(Direction.Up, 1):highlight(Highlight.Flash)
				tile2:get_tile(Direction.Up, 1):attack_entities(self)
			end
			if tile2:get_tile(Direction.Down, 1) and not tile2:get_tile(Direction.Down, 1):is_edge() then
				tile2:get_tile(Direction.Down, 1):highlight(Highlight.Flash)
				tile2:get_tile(Direction.Down, 1):attack_entities(self)
			end
			if not tile2:is_edge() then
				tile2:highlight(Highlight.Flash)
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

function create_sonic_slash(user, props)
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
	local anim = spell:get_animation()
	spell:set_texture(SLASH_TEXTURE, true)
	anim:load(_modpath.."spell_sword_slashes.animation")
	anim:set_state("WIDE")
	spell.update_func = function(self, dt)
		if not self:get_tile():get_tile(Direction.Up, 1):is_edge() then
			self:get_tile():get_tile(Direction.Up, 1):highlight(Highlight.Flash)
			self:get_tile():get_tile(Direction.Up, 1):attack_entities(self)
		end
		if not self:get_tile():get_tile(Direction.Down, 1):is_edge() then
			self:get_tile():get_tile(Direction.Down, 1):highlight(Highlight.Flash)
			self:get_tile():get_tile(Direction.Down, 1):attack_entities(self)
		end
		self:get_tile():attack_entities(self)
		if self:is_sliding() == false then
						if self:get_current_tile():is_edge() and self.slide_started then 
								self:delete()
						end 

						local dest = self:get_tile(spell:get_facing(), 1)
						local ref = self
						self:slide(dest, frames(4), frames(0), ActionOrder.Voluntary, 
								function()
										ref.slide_started = true 
								end
						)
				end
	end
	spell.collision_func = function(self, other)
		self:delete()
	end
	spell.delete_func = function(self)
		self:erase()
		end
	spell.can_move_to_func = function(tile)
		return true
	end

	Engine.play_audio(AUDIO, AudioPriority.Low)

	return spell
end

function create_fighter_slash(user, props)
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
		if not self:get_tile():get_tile(user:get_facing(), 1):is_edge() then
			self:get_tile():get_tile(user:get_facing(), 1):highlight(Highlight.Flash)
			self:get_tile():get_tile(user:get_facing(), 1):attack_entities(self)
		end
		if not self:get_tile():get_tile(user:get_facing(), 2):is_edge() then
			self:get_tile():get_tile(user:get_facing(), 2):highlight(Highlight.Flash)
			self:get_tile():get_tile(user:get_facing(), 2):attack_entities(self)
		end
		self:get_tile():attack_entities(self)
	end

	spell.can_move_to_func = function(tile)
		return true
	end

	Engine.play_audio(AUDIO, AudioPriority.Low)

	return spell
end
