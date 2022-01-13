nonce = function() end

local DAMAGE = 20
local TEXTURE = Engine.load_texture(_modpath.."puck.png")
local LAUNCH_AUDIO = Engine.load_audio(_modpath.."pucklaunch.ogg")
local BOUNCE_AUDIO = Engine.load_audio(_modpath.."puckhit.ogg")
local MOB_MOVE_TEXTURE = Engine.load_texture(_modpath.."mob_move.png")
local PARTICLE_TEXTURE = Engine.load_texture(_modpath.."artifact_impact_fx.png")

function package_init(package) 
    package:declare_package_id("com.claris.dark.Hocky")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'Y'})

    local props = package:get_card_props()
    props.shortname = "DrkHcky"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Break
    props.description = "GO FOR A WILD RIDE"
	props.card_class = CardClass.Dark
	props.limit = 1
end

function card_create_action(actor, props)
    local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	
	action:set_lockout(make_animation_lockout())
	
	action.execute_func = function(self, user)
        local puck = nil
		
		self:add_anim_action(3,
			function()
				local hilt = self:add_attachment("HILT")
				local hilt_sprite = hilt:sprite()
				hilt_sprite:set_texture(actor:get_texture())
				hilt_sprite:set_layer(-2)
				hilt_sprite:enable_parent_shader(true)

				local hilt_anim = hilt:get_animation()
				hilt_anim:copy_from(actor:get_animation())
				hilt_anim:set_state("HAND")
			end
		)
		
		if puck == nil then
			self:add_anim_action(3, 
				function()
					puck = create_puck(user)
					local tile = user:get_tile(user:get_facing(), 1)
					user:get_field():spawn(puck, tile)
				end
			)
        end
	end
    return action
end

function create_puck(user)
    local spell = Battle.Spell.new(user:get_team())
	local tileCount = 15
    spell:set_texture(TEXTURE, true)
    spell:highlight_tile(Highlight.Flash)
	spell:set_offset(16.0, -16.0) --Doing my best to center the puck on the tile.
    spell.slide_started = false
	local direction = Direction.DownRight
	if user:get_current_tile():get_tile(Direction.Down, 1):is_edge() then
		direction = Direction.UpRight
	end
	if user:get_facing() == Direction.Left then
		direction = Direction.DownLeft
		if user:get_current_tile():get_tile(Direction.Down, 1):is_edge() then
			direction = Direction.UpLeft
		end
	end
    spell:set_hit_props(
        HitProps.new(
            DAMAGE, 
            Hit.Impact | Hit.Flinch | Hit.Breaking | Hit.Drag,
            Element.Break,
            user:get_context(),
            Drag.new(direction, 1)
        )
    )
	local spareProps = spell:copy_hit_props()
    spell.update_func = function(self, dt) 
        self:get_current_tile():attack_entities(self)
		--If the current tile is an edge tile, a hole, or if the direction isn't a movement direction, then delete the puck.
		if self:get_current_tile():is_edge() or self:get_current_tile():is_hole() or direction == Direction.None then
			self:delete()
		end
		spareProps.drag = Drag.new(direction, 1)
		spell:set_hit_props(spareProps)
        if self:is_sliding() == false then
            local dest = self:get_tile(direction, 1)
            local ref = self
            self:slide(dest, frames(4), frames(0), ActionOrder.Voluntary, 
                function()
                    ref.slide_started = true 
                end
            )
        end
    end
	spell.collision_func = function(self, other)
		local fx = Battle.Artifact.new()
		fx:set_texture(PARTICLE_TEXTURE, true)
		fx:get_animation():load(_modpath.."artifact_impact_fx.animation")
		fx:get_animation():set_state("BLUE")
		fx:get_animation():on_complete(function()
			fx:erase()
		end)
		spell:get_field():spawn(fx, spell:get_current_tile())
	end
    spell.attack_func = function(self, other) 
    end

    spell.delete_func = function(self)
		if not spell:get_current_tile():is_edge() then
			--if we're not on an edge tile, which happens mostly at the end of battle for some reason,
			--then spawn a mob move to visually vanish the puck when it deletes.
			--presentation!
			local fx = Battle.Artifact.new()
			fx:set_texture(MOB_MOVE_TEXTURE, true)
			fx:get_animation():load(_modpath.."mob_move.animation")
			fx:get_animation():set_state("DEFAULT")
			fx:get_animation():on_complete(function()
				fx:erase()
			end)
			spell:get_field():spawn(fx, spell:get_current_tile():x(), spell:get_current_tile():y())
		end
		self:erase()
    end

    spell.can_move_to_func = function(tile)
		--if we're out of tile moves, on a hole, or on the next tile is a hole, bye bye!
		if tileCount <= 0 or spell:get_current_tile():is_hole() or tile:is_hole() then
			spell:delete()
		end
		--if the next tile is an edge tile, bounce!
		if tile:get_tile(direction, 1):is_edge() and spell.slide_started then
			direction = Bounce(user, direction, tile, spell)
			tileCount = tileCount-1
		end
		--if the current tile is on the opposite team and the next tile is on the same team as the spell's team, bounce!
		if not spell:is_team(tile:get_team()) and spell:is_team(tile:get_tile(direction, 1):get_team()) and spell.slide_started then
			direction = Bounce(user, direction, tile, spell)
			tileCount = tileCount-1
		end
		return true
    end

	Engine.play_audio(LAUNCH_AUDIO, AudioPriority.High)

    return spell
end

function Bounce(spellcaster, direction, tile, spell)
	--Don't ask me how this works, as I'm still not sure how I did this.
	--However, it resulted in working bounces for the puck, so...haha. mood.
	returnDirection = Direction.None
	if direction == Direction.UpLeft then
		returnDirection = Direction.DownLeft
		if tile:get_tile(Direction.Left, 1):is_edge() or tile:get_tile(Direction.Left, 1):get_team() == spell:get_team() then
			returnDirection = Direction.UpRight
		end
	end
	if direction == Direction.UpRight then
		returnDirection = Direction.DownRight
		if tile:get_tile(Direction.Right, 1):is_edge() or tile:get_tile(Direction.Right, 1):get_team() == spell:get_team() then
			returnDirection = Direction.UpLeft
		end
	end
	if direction == Direction.DownLeft then
		returnDirection = Direction.UpLeft
		if tile:get_tile(Direction.Left, 1):is_edge() or tile:get_tile(Direction.Left, 1):get_team() == spell:get_team() then
			returnDirection = Direction.DownRight
		end
	end
	if direction == Direction.DownRight then
		returnDirection = Direction.UpRight
		if tile:get_tile(Direction.Right, 1):is_edge() or tile:get_tile(Direction.Right, 1):get_team() == spell:get_team() then
			returnDirection = Direction.DownLeft
		end
	end
	Engine.play_audio(BOUNCE_AUDIO, AudioPriority.Low)
	return returnDirection
end