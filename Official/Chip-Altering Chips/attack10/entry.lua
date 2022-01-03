nonce = function() end

function package_init(package) 
    package:declare_package_id("com.claris.card.AttackPlus1")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'*'})

    local props = package:get_card_props()
    props.shortname = "Atk+10"
    props.damage = 0
    props.time_freeze = false
    props.element = Element.Plus
    props.description = "+10 for selected atk chip"
	props.card_class = CardClass.Standard
	props.limit = 5
	props.can_boost = false
	
	package.filter_hand_step = function(in_props, adj_cards) 
        if adj_cards:has_card_to_left() and adj_cards.left_card.can_boost then
            adj_cards.left_card.damage = adj_cards.left_card.damage + 10
            adj_cards:discard_incoming()
        end
	end
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	action.execute_func = function(self, user)
		local fx = Battle.ParticlePoof.new()
		fx:set_height(user:get_height()*2)
		actor:get_field():spawn(fx, actor:get_current_tile())
	end
	return action
end