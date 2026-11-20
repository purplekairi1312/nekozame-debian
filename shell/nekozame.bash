# nekozame-debian, for bash (setup.sh adds a line sourcing this to ~/.bashrc)
NZ_SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/nekozame"

# nekozame's colours in gum (the setup's questions)
[ -r "$NZ_SHARE/os/colors.sh" ] && . "$NZ_SHARE/os/colors.sh"

# nekozame's commands are in ~/.local/bin
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac

# fastfetch with the bubble logo (nekozame-fetch picks the picture or the text one)
if [ -x "$HOME/.local/bin/nekozame-fetch" ]; then
    alias fastfetch=nekozame-fetch
    alias neofetch=nekozame-fetch
fi

# cava in nekozame's colours, unless you have your own ~/.config/cava/config
if [ ! -e "${XDG_CONFIG_HOME:-$HOME/.config}/cava/config" ] && [ -r "$NZ_SHARE/os/cava/config" ]; then
    alias cava="cava -p '$NZ_SHARE/os/cava/config'"
fi

# the prompt: you@machine in pink, the folder in baby blue, the arrow pink (red after a
# command that failed). NEKOZAME_PROMPT=off in ~/.bashrc, before this line, keeps yours
if [ "${NEKOZAME_PROMPT:-on}" != off ]; then
    _nz_pink='\[\e[38;2;255;192;229m\]' _nz_blue='\[\e[38;2;184;228;255m\]'
    _nz_lilac='\[\e[38;2;217;184;214m\]' _nz_red='\[\e[38;2;255;179;200m\]' _nz_off='\[\e[0m\]'
    _nekozame_prompt() {
        local s=$? arrow="$_nz_pink"
        [ "$s" -eq 0 ] || arrow="$_nz_red"
        PS1="${_nz_pink}\u${_nz_lilac}@${_nz_pink}\h ${_nz_blue}\w ${arrow}❯${_nz_off} "
        # the tab title: the folder
        printf '\e]2;%s\a' "${PWD/#$HOME/\~}"
    }
    case ";${PROMPT_COMMAND:-};" in
        *";_nekozame_prompt;"*) ;;
        *) PROMPT_COMMAND="_nekozame_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
    esac
fi
unset NZ_SHARE
