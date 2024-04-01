



  # Debugging tools
  # =================
  #
  # There are some debugging tools:
  #  _shcli_dump_ctx 
  #  SHAPP_DEBUG=_shapp_debug
  #  set -x
  #  declare -p VAR
  #  dump_env start|stop
  # 
  # Bad ideas:
  # Call _parse two times. Each _parse shift args
  



# Select the command resolver you want to use.
# Two are availables:
# simple: Simple word resolver
# shcli: Leverage shcli parser to get multi words commands
SHAPP_LOOKUP='shcli'


# Shcli debug mode, set to ':' disable 
# or '_shapp_debug' to enable verbose output
SHAPP_DEBUG=:
#SHAPP_DEBUG=_shapp_debug


# Display tips
SHAPP_TIP='printf "tip: %s"'

# Add basic main, help amd example commands to
# your app. Good when you start to prototype,
# bur should be disabled for prod.
SHAPP_BASE_APP=true
SHAPP_BASE_APP=false

# Base mods to lookup for cli commands
SHAPP_MODS="shapp"


# Common functions ?
# ====================================


_shapp_debug()
{
  local args=$@
  #>&2 printf "debug: %-10s: %s\n" "${FUNCNAME[1]}" "$args"
  >&2 printf "debug_app: %s\n" "$args"
}






# Base example application
# ====================================

shapp_cli__()
{
  echo 'Hello world!'
}

shapp_cli__help()
{

  # Parse args
  cli_all=false
  for arg in $@; do
    case "$arg" in
      -a) cli_all=true ;;
    esac
  done
  
  cat <<EOF
  Usage: $SHAPP_NAME [COMMAND]  
  
EOF
  
  # Define vars
  local varz="_ cmd"
  if $cli_all; then
    pat=$SHAPP_MODS
    varz="mod cmd"
  else 
    pat=$SHAPP_NAME 
  fi
  
  # Loop over commands
  echo "  Commands:"
  local mod= cmd=
  while IFS=';' read -r $varz _; do
    printf "    %-16s%-16s\n" \
      "${cmd//_/ }" \
      "${mod:+($mod)}"
  done <<< "$(_shapp_filter_commands $pat )"
  
  if $cli_all; then
    printf "\n  Loading order: %s\n" "${SHAPP_MODS//|/,}"
  fi
  
}






# Debugging cli
# ====================================

shapp_cli__inspect()
{
  local app_path="$( dirname $(realpath $0 ))"
  
  >&2 echo "App path: $app_path"
          
  >&2 printf "\nCli functions:\n"
  declare -F \
    | sed -En '/_cli__/s/.*-f /  /p' \
      | LC_ALL=C sort
   
  >&2 printf "\nGlobal Vars:\n"
  declare -p | sed -En '
    / -[ax-] _?SH/{
      s/^declare -[ax-] /  /
      p
    }' | LC_ALL=C sort
    
  # Specific cli debug
  
  #set -x
  printf "\nCheck leaking FN vars:\n"
  
 # local r=$(
  
  declare -p | grep -i shcli | grep _FN_ | sed -En 's/^declare -[ax-] /  /p' |
  while IFS== read -r key val ;do 
      #echo "$key"
      local short=${key##*_FN_}
     # echo $short
     #  set -x
      if [[ ":${_SHCLI_FN_META//[ _]/:}:" == *:$short:* ]]; then
        echo OK: $key
      else
        echo "KO:   $key"
      fi
     # for i in $_SHCLI_FN_META; do
     # grep -v "$i" <<< "$line"
      #done
  done
    
   # | sed -En '/_cli__/s/.*-f /  /p' \
    #  | LC_ALL=C sort   
  
  #declare -p | grep VPREFIX
}


# Internal libs
# ====================================

_shapp_filter_commands()
{
  local filter=${1:-$SHAPP_MODS}
  
  declare -F | \
     sed -En "
       /($filter)_cli__/{
         s/^.* //
         s/_cli__/;/
         p
       }"
}


  
# Cli controllers and lookups
# ====================================

shapp_router__simple()
{
  local args=("$@")  
  
  # Find the good command (the dispatcher!)
  local namespaces="${SHAPP_MODS//|/ }"
  for ns in $namespaces; do
  
    local cmd_test="${ns}_cli__"
    local cmd_ok=
    
    local i=
    for ((i=0;i<${#args[@]};i++)); do
    
      local cmd_child=${args[$i]}
      cmd_test="${cmd_test}_${cmd_child}"
       
      # Test result
      $SHCLI_DEBUG "Testing func: $cmd_test"
      if declare -f $cmd_test >&/dev/null; then
        $SHCLI_DEBUG "Func match: $cmd_test"
        cmd_ok=$cmd_test
        unset args[i]
      fi  
    done
    
    # Quit loop if found func in this namespace
    [[ -z "$cmd_ok" ]] || break    
  done
  
  # Check result and logs
  if [[ -z "$cmd_ok" ]]; then
    >&2 printf "Error: Unknown command '%s' from $namespaces\n" "${args[*]}"
    return 1
  fi
  
  # Run the command
  $SHCLI_DEBUG "shapp simple router run: $cmd_ok -- ${args[@]}"
  $cmd_ok "${args[@]}"
  
}


# Shapp application loader
# ====================================

shapp_start()
{
  #set -x 
  
  SHAPP_NAME="$1"
  shift 1
  local args=("$@")
  
  # Detect other plugins
  SHAPP_MODS="$SHAPP_NAME${SHAPP_MODS:+|$SHAPP_MODS}"
  
  # Find the best router
  local routers="shcli_shapp_router__shcli shapp_router__simple"
  for fun in $routers; do
    declare -f $fun >&/dev/null || continue
    $fun "${args[@]}"
    break
  done
  
}


