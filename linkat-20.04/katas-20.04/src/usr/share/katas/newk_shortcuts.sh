#!/bin/bash
if [ ! -f "$HOME"/.xbindkeysrc ]; then
	xbindkeys --defaults > "$HOME"/.xbindkeysrc
fi
if [ -z "$(grep -i newk "$HOME"/.xbindkeysrc)" ]; then
	cat /usr/share/katas/newk_shortcuts >> "$HOME"/.xbindkeysrc
	killall -s1 xbindkeys ; xbindkeys -f ~/.xbindkeysrc
fi
