# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
ZSH_THEME="remy"

# ZSH plugins
plugins=(git npm brew django zsh-syntax-highlighting) 

# User configuration

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# disable the default virtualenv prompt change
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Aliases
source ~/.aliases/main

# Check if user has private aliases as well
if [ -f ~/.private_aliases ]; then
	source ~/.private_aliases
fi

# OS spesifics
if [ "$(uname)" '==' "Linux" ]; then
	source ~/.aliases/linux
	#source ~/.scripts/vboxmanage_completion.bash
	source ~/.z.sh
	# Dircolors
	eval `dircolors ~/.dir_colors`
	alias ls='ls -F --color=auto'

elif [ "$(uname)" '==' "Darwin" ]; then
	source ~/.aliases/osx
	# Z
	. `brew --prefix`/etc/profile.d/z.sh
	# Dircolors
	eval `gdircolors ~/.dir_colors`
	alias ls='gls --color'
fi

# Dircolors
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
autoload -Uz compinit
compinit

export NVM_DIR="/Users/andrroy/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# DrittRuby
export PATH="/usr/local/opt/ruby/bin:$PATH"

# Mono (C# stuff)
export PATH=/Library/Frameworks/Mono.framework/Versions/Current/bin/:${PATH}

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

