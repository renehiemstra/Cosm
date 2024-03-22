# signal that cosm prompt is active
export COSM_PROMPT=1

# supress depracation warning
export BASH_SILENCE_DEPRECATION_WARNING=1

# define cosm prompt
function customp {
    BOLD="\[$(tput bold)\]"
    NORMAL="\[$(tput sgr0)\]"
    GREEN="\[$(tput setaf 2)\]"
    WHITE="\[$(tput setaf 7)\]"
    PROMPT="\[cosm>\]"
    PS1="$BOLD$GREEN$PROMPT$NORMAL$WHITE "
}
customp

# reload environment variables in every command
function before_command() {
  case "$BASH_COMMAND" in
    $PROMPT_COMMAND)
      ;;
    *)
      if [ -f .cosm/.env ]; then
        source .cosm/.env
      fi
      ;;
  esac
}
trap before_command DEBUG