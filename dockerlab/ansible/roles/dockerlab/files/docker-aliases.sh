# Bash aliases for managing Docker

# Colors
# Reset
export Reset='\e[0m'       # Text Reset
export Yellow='\e[0;33m'       # Yellow

# "docker status"
alias ds='echo -e "${Yellow}Images${Reset}"; docker images; echo -e "${Yellow}Containers${Reset}"; docker ps --all'
# "docker cleanup": Clean up volumes with status ‘exited’ and ‘dangling’ images
alias dc='docker rm --volumes $(docker ps --all --quiet --filter="status=exited") > /dev/null 2>&1; docker rmi $(docker images --filter="dangling=true" --quiet) > /dev/null 2>&1'
# Stop all running containers and clean up
alias dC='docker stop $(docker ps --quiet) > /dev/null 2>&1; docker rm --volumes $(docker ps --all --quiet --filter="status=exited") > /dev/null 2>&1; docker rmi $(docker images --filter="dangling=true" --quiet) > /dev/null 2>&1'
# "docker ssh": Open a shell console into the latest created Docker container
alias dS='docker exec --interactive --tty $(docker ps --latest --quiet) env TERM=xterm /bin/bash'
# "docker halt"
alias dh='docker stop'
# Print the IP address of the latest Docker container
alias dip='docker inspect  --format="{{ .NetworkSettings.IPAddress }}" $(docker ps --latest --quiet)'

