nonce = function() end

local DAMAGE = 90
local TEXTURE = Engine.load_texture(_modpath.."Moonblade.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.card.MoonBlade1")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'E', 'N', 'Z'})

    local props = package:get_card_props()
    props.shortname = "MoonBld1"
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
		
		self:add_anim_action(2,
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
					slash = create_slash("DEFAULT", user, props)
					actor:get_field():spawn(slash, tile)
				end
			)
        end
	end
    return action
end

function create_slash(animation_state, user, props)
    local spell = Battle.Spell.new(user:get_team())
    spell:set_texture(TEXTURE, true)
	spell:set_facing(user:get_facing())
    spell:set_hit_props(
        HitProps.new(
            props.damage, 
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
			local hitbox_ul = Battle.Hitbox.new(spell:get_team())
			hitbox_ul:set_hit_props(props)
			field:spawn(hitbox_ul, self:get_current_tile():get_tile(Direction.UpLeft, 1))
		end
		if self:get_current_tile():get_tile(Direction.Up, 1) then
			self:get_current_tile():get_tile(Direction.Up, 1):highlight(Highlight.Flash)
			local hitbox_u = Battle.Hitbox.new(spell:get_team())
			hitbox_u:set_hit_props(props)
			field:spawn(hitbox_u, self:get_current_tile():get_tile(Direction.Up, 1))
		end
		if self:get_current_tile():get_tile(Direction.UpRight, 1) then
			self:get_current_tile():get_tile(Direction.UpRight, 1):highlight(Highlight.Flash)
			local hitbox_ur = Battle.Hitbox.new(spell:get_team())
			hitbox_ur:set_hit_props(props)
			field:spawn(hitbox_ur, self:get_current_tile():get_tile(Direction.UpRight, 1))
		end
		if self:get_current_tile():get_tile(Direction.Right, 1) then
			self:get_current_tile():get_tile(Direction.Right, 1):highlight(Highlight.Flash)
			local hitbox_r = Battle.Hitbox.new(spell:get_team())
			hitbox_r:set_hit_props(props)
			field:spawn(hitbox_ur, self:get_current_tile():get_tile(Direction.Right, 1))
		end
		if self:get_current_tile():get_tile(Direction.Left, 1) then
			self:get_current_tile():get_tile(Direction.Left, 1):highlight(Highlight.Flash)
			local hitbox_l = Battle.Hitbox.new(spell:get_team())
			hitbox_l:set_hit_props(props)
			field:spawn(hitbox_l, self:get_current_tile():get_tile(Direction.Left, 1))
		end
		if self:get_current_tile():get_tile(Direction.DownLeft, 1) then
			self:get_current_tile():get_tile(Direction.DownLeft, 1):highlight(Highlight.Flash)
			local hitbox_dl = Battle.Hitbox.new(spell:get_team())
			hitbox_dl:set_hit_props(props)
			field:spawn(hitbox_dl, self:get_current_tile():get_tile(Direction.DownLeft, 1))
		end
		if self:get_current_tile():get_tile(Direction.Down, 1) then
			self:get_current_tile():get_tile(Direction.Down, 1):highlight(Highlight.Flash)
			local hitbox_d = Battle.Hitbox.new(spell:get_team())
			hitbox_d:set_hit_props(props)
			field:spawn(hitbox_d, self:get_current_tile():get_tile(Direction.Down, 1))
		end
		if self:get_current_tile():get_tile(Direction.DownRight, 1) then
			self:get_current_tile():get_tile(Direction.DownRight, 1):highlight(Highlight.Flash)
			local hitbox_dr = Battle.Hitbox.new(spell:get_team())
			hitbox_dr:set_hit_props(props)
			field:spawn(hitbox_dr, self:get_current_tile():get_tile(Direction.DownRight, 1))
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