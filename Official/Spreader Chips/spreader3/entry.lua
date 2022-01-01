nonce = function() end

local DAMAGE = 90
local BUSTER_TEXTURE = Engine.load_texture(_modpath.."spread_buster.png")
local BURST_TEXTURE = Engine.load_texture(_modpath.."spread_impact.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.card.Spreader3")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'Q', 'R', 'S', '*'})

    local props = package:get_card_props()
    props.shortname = "Spreadr3"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.None
    props.description = "Spread to adjacent panels!"
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
	
	action:set_lockout(make_animation_lockout())

    action.execute_func = function(self, user)
		local buster = self:add_attachment("BUSTER")
		buster:sprite():set_texture(BUSTER_TEXTURE, true)
		buster:sprite():set_layer(-1)
		
		local buster_anim = buster:get_animation()
		buster_anim:load(_modpath.."spread_buster.animation")
		buster_anim:set_state("DEFAULT")
		
		local cannonshot = create_attack(user)
		local tile = user:get_tile(user:get_facing(), 1)
		actor:get_field():spawn(cannonshot, tile)
	end
    return action
end

function create_attack(user)
	local spell = Battle.Spell.new(user:get_team())
	spell.slide_started = false
	local direction = user:get_facing()
    spell:set_hit_props(
        HitProps.new(
            DAMAGE, 
            Hit.Impact, 
            Element.None,
            user:get_context(),
            Drag.None
        )
    )
	spell.update_func = function(self, dt) 
        self:get_current_tile():attack_entities(self)
        if self:is_sliding() == false then
            if self:get_current_tile():is_edge() and self.slide_started then 
                self:delete()
            end 
			
            local dest = self:get_tile(direction, 1)
            local ref = self
            self:slide(dest, frames(1), frames(0), ActionOrder.Voluntary, 
                function()
                    ref.slide_started = true 
                end
            )
        end
    end
	spell.collision_func = function(self, other)
		local fx = Battle.Artifact.new()
		fx:set_texture(BURST_TEXTURE, true)
		fx:get_animation():load(_modpath.."spread_impact.animation")
		fx:get_animation():set_state("DEFAULT")
		fx:get_animation():on_complete(function()
			fx:erase()
		end)
		fx:set_height(-16.0)
		local tile = self:get_current_tile()
		if tile and not tile:is_edge() then
			spell:get_field():spawn(fx, tile)
		end
	end
    spell.attack_func = function(self, other) 
		local fx = Battle.Artifact.new()
		fx:set_texture(BURST_TEXTURE, true)
		fx:get_animation():load(_modpath.."spread_impact.animation")
		fx:get_animation():set_state("DEFAULT")
		fx:get_animation():on_complete(function()
			fx:erase()
		end)
		fx:set_height(-16.0)
		local tile = self:get_current_tile():get_tile(Direction.UpLeft, 1)
		if tile and not tile:is_edge() then
			spell:get_field():spawn(fx, tile)
			tile:attack_entities(self)
		end
		local fx2 = Battle.Artifact.new()
		fx2:set_texture(BURST_TEXTURE, true)
		fx2:get_animation():load(_modpath.."spread_impact.animation")
		fx2:get_animation():set_state("DEFAULT")
		fx2:get_animation():on_complete(function()
			fx2:erase()
		end)
		fx2:set_height(-16.0)
		tile = self:get_current_tile():get_tile(Direction.Up, 1)
		if tile and not tile:is_edge() then
			spell:get_field():spawn(fx2, tile)
			tile:attack_entities(self)
		end
		local fx3 = Battle.Artifact.new()
		fx3:set_texture(BURST_TEXTURE, true)
		fx3:get_animation():load(_modpath.."spread_impact.animation")
		fx3:get_animation():set_state("DEFAULT")
		fx3:get_animation():on_complete(function()
			fx3:erase()
		end)
		fx3:set_height(-16.0)
		tile = self:get_current_tile():get_tile(Direction.UpRight, 1)
		if tile and not tile:is_edge() then
			spell:get_field():spawn(fx3, tile)
			tile:attack_entities(self)
		end
		local fx4 = Battle.Artifact.new()
		fx4:set_texture(BURST_TEXTURE, true)
		fx4:get_animation():load(_modpath.."spread_impact.animation")
		fx4:get_animation():set_state("DEFAULT")
		fx4:get_animation():on_complete(function()
			fx4:erase()
		end)
		fx4:set_height(-16.0)
		tile = self:get_current_tile():get_tile(Direction.Left, 1)
		if tile and not tile:is_edge() then
			spell:get_field():spawn(fx4, tile)
			tile:attack_entities(self)
		end
		local fx5 = Battle.Artifact.new()
		fx5:set_texture(BURST_TEXTURE, true)
		fx5:get_animation():load(_modpath.."spread_impact.animation")
		fx5:get_animation():set_state("DEFAULT")
		fx5:get_animation():on_complete(function()
			fx5:erase()
		end)
		fx5:set_height(-16.0)
		tile = self:get_current_tile():get_tile(Direction.Right, 1)
		if tile and not tile:is_edge() then
			spell:get_field():spawn(fx5, tile)
			tile:attack_entities(self)
		end
		local fx6 = Battle.Artifact.new()
		fx6:set_texture(BURST_TEXTURE, true)
		fx6:get_animation():load(_modpath.."spread_impact.animation")
		fx6:get_animation():set_state("DEFAULT")
		fx6:get_animation():on_complete(function()
			fx6:erase()
		end)
		fx6:set_height(-16.0)
		tile = self:get_current_tile():get_tile(Direction.DownLeft, 1)
		if tile and not tile:is_edge() then
			spell:get_field():spawn(fx6, tile)
			tile:attack_entities(self)
		end
		local fx7 = Battle.Artifact.new()
		fx7:set_texture(BURST_TEXTURE, true)
		fx7:get_animation():load(_modpath.."spread_impact.animation")
		fx7:get_animation():set_state("DEFAULT")
		fx7:get_animation():on_complete(function()
			fx7:erase()
		end)
		fx7:set_height(-16.0)
		tile = self:get_current_tile():get_tile(Direction.Down, 1)
		if tile and not tile:is_edge() then
			spell:get_field():spawn(fx7, tile)
			tile:attack_entities(self)
		end
		local fx8 = Battle.Artifact.new()
		fx8:set_texture(BURST_TEXTURE, true)
		fx8:get_animation():load(_modpath.."spread_impact.animation")
		fx8:get_animation():set_state("DEFAULT")
		fx8:get_animation():on_complete(function()
			fx8:erase()
		end)
		fx8:set_height(-16.0)
		tile = self:get_current_tile():get_tile(Direction.DownRight, 1)
		if tile and not tile:is_edge() then
			spell:get_field():spawn(fx8, tile)
			tile:attack_entities(self)
		end
		self:erase()
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