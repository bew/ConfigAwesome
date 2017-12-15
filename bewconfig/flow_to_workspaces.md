


## Describe the needed actions

- create WS (with name?)
- rename WS
- delete WS (only if empty?)
- move WS left/right
- move client to WS left/right
- goto WS left/right/N


## How to do these actions

Menu **workspace action**:
- create WS
- rename WS
- delete WS (only if empty?)
- move WS left/right

### Shortcuts:

- `M-h/l` -> goto WS left/right
- `M-S-h/l` -> move client to WS left/right
  (But this already moves tag left/right)

=> bad idea, I'll instantly run out of valid and/or logical shortcuts...

Using mode, I can have 2 modes for moving clients, managing containers, acting on tags or workspaces based on the mode.
Or the mode can be a simple keymap, which include another keymap of common keybinds, parameterized on the type of container used.
The mode keymap can replace another keymap or be applied, so that other elready 'running' keymaps can work, when one mode or the other is used.

Idea: the mode workspaces could be dismissed (re-repleaced by the mode tags) when a non-related keybind is used? so that it'll easily fall back to mode tags, when you're finished with the workspaces manipulations..

- mode tags (inside a given workspace)
  * client movement would move the client to another tag in the workspace
  * rename would rename the tag
  * container movement would move the tag left/right

- mode workspaces
  * client movement would move the client to another workspace
  * rename would rename the workspace
  * container movement would move the workspace left/right


:tada: cool workspaces!!
