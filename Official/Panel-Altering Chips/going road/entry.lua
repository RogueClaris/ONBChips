nonce = function() end

local DAMAGE = 0
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")
local FINISH_AUDIO = Engine.load_audio(_modpath.."finish_sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.claris.card.Comingroad2")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'*'})

    local props = package:get_card_props()
    props.shortname = "GoingRd"
    props.damage = DAMAGE
    props.time_freeze = true
    props.element = Element.None
    props.description = "Bring foe right to you!"
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	
	action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")

        self.tile = actor:get_current_tile()
		self.dir = actor:get_facing()
		self.count = 0
		self.max = 6
		Engine.play_audio(AUDIO, AudioPriority.Low)
		
		local step1 = Battle.Step.new()
		
		local ref = self
		local tile = nil
		step1.update_func = function(self, dt) 
			for i = ref.count, ref.max, 1
			do
				tile = ref.tile:get_tile(ref.dir, i)
				if tile and tile:get_team() ~= ref.tile:get_team() and not tile:is_edge() then
					if ref.dir == Direction.Left then
						tile:set_state(TileState.DirectionLeft)
					else
						tile:set_state(TileState.DirectionRight)
					end
				end
			end
			self:complete_step()
		end
		self:add_step(step1)
	end
    return action
end