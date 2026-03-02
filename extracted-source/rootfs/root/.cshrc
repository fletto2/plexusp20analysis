set history=200
set prompt = 'Rootcsh > '
set noclobber
set mail=/usr/mail/root
stty erase '^H' kill '^X' ixon ixany echoe -brkint
alias c 'clear'
alias bye 'logout'
alias w '/bin/find ~ -name \!* -print'
alias me 'ps -fu csh'
alias l 'bls -F'
alias save 'delta \!get:2'
alias q 'Qoffice'
alias h 'history'
alias f 'grep \!* *'
alias sp 'echo \!* | spell'
set path = ( . /user/woody/bin /usr/plx /bin /usr/bin /v7/bin /v7/usr/bin /usr/games /usr/local/sccs /etc /usr/lib/spell )
setenv TZ PST8PDT
setenv TERM vt100  
setenv MAIL $mail
setenv EXINIT 'set ai nowrapscan redraw'
alias p  '/usr/plx/wbs < \!* &'
alias raw  '/usr/plx/wbs < \!* &'
alias fp  '/usr/plx/wbs < \!* &'
