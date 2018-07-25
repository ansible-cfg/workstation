# TODO dhc

* vault installation
* intall, execute stow & clone dotfiles
* bazel autocomplete from https://github.com/bazelbuild/bazel/tree/master/scripts/zsh_completion to 
cp scripts/zsh_completion/_bazel /usr/local/share/zsh/site-functions/
* cleanup redundant aliases
* yum install zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz xz-devel
* setup pyenv to ~/.pyenv
* setup pyenvvirtualenv
* dhc setup siehe cmd.md
* code repos etc mal syncen mit dem was wirklich gecloned ist

# TODO now

* myke
* Install fortio
* Backup .dot folders (when it makes sense)
* Mouse Backbutton geht nicht
* Alternate gitclient?
* farmctl & farmapi?


# Manual steps

* Gnome: Settings: Online Accounts: Login with Google
* Gnome extensions: install:
    * https://extensions.gnome.org/extension/1036/extensions/
    * https://extensions.gnome.org/extension/750/openweather/
    * https://extensions.gnome.org/extension/104/netspeed/
    * https://extensions.gnome.org/extension/55/media-player-indicator/
    * https://extensions.gnome.org/extension/307/dash-to-dock/
    * https://extensions.gnome.org/extension/657/shelltile/
    * https://extensions.gnome.org/extension/701/top-panel-workspace-scroll/
    * https://extensions.gnome.org/extension/512/wikipedia-search-provider/
* Chrome: Keyring & Login with Google
* Spotify: Login
* Rambox: Login with Google
* https://www.if-not-true-then-false.com/2015/fedora-nvidia-guide/

# Testing:

* Virtual Box 
    * with proxy +> Verified 24.02
        use_proxy_for_bootstrap = true
        activate = true
    * without proxy +> Verified 24.02
        use_proxy_for_bootstrap = false
        activate = false
* VMWare
    * without proxy +> Verified 24.02
        use_proxy_for_bootstrap = false
        activate = false

* Pipe directly from GitHub
    * with proxy (VirtualBox) +> TODO Verified 24.02
        use_proxy_for_bootstrap = true
        activate = true
    * without proxy (VMWare) +> Verified 24.02
        use_proxy_for_bootstrap = false
        activate = false
