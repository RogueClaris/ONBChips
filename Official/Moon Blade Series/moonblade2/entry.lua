nonce = function() end

local DAMAGE = 110
local TEXTURE = Engine.load_texture(_modpath.."Moonblade.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.card.MoonBlade2")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'G', 'O', 'V'})

    local props = package:get_card_props()
    props.shortname = "MoonBld2"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Sword
    props.description = "Slices enemies around"
end
function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	
	action:set_lockout(make_animation_lockout())

    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")
		local tile = user:get_current_tile()
		local slash = nil
		
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
		
		if slash == nil then
			self:add_anim_action(3, 
				function()
					slash = create_slash("DEFAULT", user)
					actor:get_field():spawn(slash, tile)
				end
			)
        end
	end
    return action
end

function create_slash(animation_state, user)
    local spell = Battle.Spell.new(user:get_team())
    spell:set_texture(TEXTURE, true)
	spell:set_facing(user:get_facing())
    spell:set_hit_props(
        HitProps.new(
            DAMAGE, 
            Hit.Impact | Hit.Flinch, 
            Element.Sword,
            user:get_context(),
            Drag.None
        )
    )	
    local anim = spell:get_animation()
    anim:load(_modpath.."Moonblade.animation")
    anim:set_state(animation_state)
	spell:get_animation():on_complete(
		function()
			spell:erase()
		end
	)
    spell.update_func = function(self, dt) 
		if self:get_current_tile():get_tile(Direction.UpLeft, 1) then
			self:get_current_tile():get_tile(Direction.UpLeft, 1):highlight(Highlight.Flash)
			self:get_current_tile():get_tile(Direction.UpLeft, 1):attack_entities(self)
		end
		if self:get_current_tile():get_tile(Direction.Up, 1) then
			self:get_current_tile():get_tile(Direction.Up, 1):highlight(Highlight.Flash)
			self:get_current_tile():get_tile(Direction.Up, 1):attack_entities(self)
		end
		if self:get_current_tile():get_tile(Direction.UpRight, 1) then
			self:get_current_tile():get_tile(Direction.UpRight, 1):highlight(Highlight.Flash)
			self:get_current_tile():get_tile(Direction.UpRight, 1):attack_entities(self)
		end
		if self:get_current_tile():get_tile(Direction.Right, 1) then
			self:get_current_tile():get_tile(Direction.Right, 1):highlight(Highlight.Flash)
			self:get_current_tile():get_tile(Direction.Right, 1):attack_entities(self)
		end
		if self:get_current_tile():get_tile(Direction.Left, 1) then
			self:get_current_tile():get_tile(Direction.Left, 1):highlight(Highlight.Flash)
			self:get_current_tile():get_tile(Direction.Left, 1):attack_entities(self)
		end
		if self:get_current_tile():get_tile(Direction.DownLeft, 1) then
			self:get_current_tile():get_tile(Direction.DownLeft, 1):highlight(Highlight.Flash)
			self:get_current_tile():get_tile(Direction.DownLeft, 1):attack_entities(self)
		end
		if self:get_current_tile():get_tile(Direction.Down, 1) then
			self:get_current_tile():get_tile(Direction.Down, 1):highlight(Highlight.Flash)
			self:get_current_tile():get_tile(Direction.Down, 1):attack_entities(self)
		end
		if self:get_current_tile():get_tile(Direction.DownRight, 1) then
			self:get_current_tile():get_tile(Direction.DownRight, 1):highlight(Highlight.Flash)
			self:get_current_tile():get_tile(Direction.DownRight, 1):attack_entities(self)
		end
    end
	spell.collision_func = function(self, other)
	end
    spell.attack_func = function(self, other)
    end

    spell.delete_func = function(self)
		self:erase()
    end

    spell.can_move_to_func = function(tile)
        return true
    end

	Engine.play_audio(AUDIO, AudioPriority.High)

    return spell
end