local naughty = require("naughty")


local toast = function(text, options)
	if not options then
		options = {}
	end
	options.text = text
	naughty.notify(options)
end

return {
	utils = {
		toast = toast
	},
	tag = { -- TODO functions
		-- PUBLIC PUBLIC PUBLIC PUBLIC PUBLIC PUBLIC PUBLIC PUBLIC PUBLIC
		selectNext = false,
		selectPrev = false,

		moveTagToRight = false,
		moveTagToLeft = false,

		renameCurrentTag = false, -- with a popup, or in the tag tab

		getClients = false,

		--[[
			createNew:	-> in current worksace
						-> in new workspace
						-> in specified workspace
		]]
		createNew = false,

		-- PRIVATE PRIVATE PRIVATE PRIVATE PRIVATE PRIVATE PRIVATE PRIVATE
		getTagData = false
	},
	client = {
		getFocused = false,
		getAt = false, -- coords (x,y) OR mouse cursor

		--TODO: Faire un system de makage avancé des clients
		isMarked = false,
		setMark = false,

		--[[
			moveTo: -> a Tag
						-> c
					-> a Workspace
						-> at first available Tag
						-> create new tag
		]]
		moveTo = false,
	}
}




--[[

idee pour un nouveau type de tag:

montrer momentanement un tag (un tag avec des truc d'help par exemple)
  -> quitter ce tag momentané avec {modkey + Esc}
  -> remettre le comportement de {modkey + Esc}

type de tag ? System de flags pour qu'un tag ai les caracteristique de plusieurs categories de tag
-> moment-tag
-> dialog-tag
-> help-tag
-> config-tag



]]
