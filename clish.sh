#/usr/bin/env bash

# shcli.sh
# ====================================

# Order matterz ??? shouldnot ...
import clish_app.sh  # shapp_
import clish_cli.sh  # shcli_



CLISH_TUTOR=${CLISH_TUTOR:-true}
#CLISH_TUTOR=false


# Base app example
# ====================================


if $CLISH_TUTOR ; then

  SHAPP_MODS="clish${SHAPP_MODS:+|$SHAPP_MODS}"

  clish_cli__()
  {
    # This is a required function 
  
 
    cat <<EOF
Hello World!

This is an template function to illustrate how
quickly is to develop your own cli. 
To make your own program, you need to create
a function called '${SHAPP_NAME}_cli__' like this:

EOF
    return
    
    cat << EOF
${SHAPP_NAME}_cli__()
{
  echo "This is my super app called: \$SHAPP_NAME !"
}

If you want to add new commands, just create thos functions:
${SHAPP_NAME}_cli__hello
${SHAPP_NAME}_cli__enable
${SHAPP_NAME}_cli__disable

Then you can call like this:
${0##*/} hello
${0##*/} enable MYPACKAGE

See this example:
$(declare -f shcli_app_cli__example )
EOF

  }


  # This is an example command.
  clish_cli__example()
  { 
    shcli_cmd "Example command" 
    shcli_opt -f,--full   "Show full example" \
      --type flag_bool
    shcli_parse -
  
    # Start example message
    echo "This is a commmand sample you can use to make your own."
  
    # Show function declaration ?
    full="${SHCLI_FN_VPREFIX}full"
    if ${!full}; then
      $SHAPP_DEBUG "Function code:"
      declare -f shcli_cli__example
    fi
  }
  
  
  # This is an example command.
  clish_cli__help()
  { 
  
      # BUG: SHOULD NIT HAVE SHCLI REF HERE
    shcli_opt -a,--all    "Show all functions" \
      --type flag_bool 
    shcli_parse -
    
    echo $SHCLI_FN_VPREFIX
    
    local args=
    $cli_all || args='-a'
  
    echo Help command
    echo
    echo "It is also possible to override internal functions."
    echo "You can still call old command:"
    echo
    echo "~~~"
    shapp_cli__help  $args
    echo "~~~"
  }
fi





# Beta



# Clish plugins or maybe shapp plugin
# ====================================

_shcli_help_fun_long()
{
#  set -x
  local fun=$1
  #echo "Help: $fun"
  local display_cmd=false
  

  
  
  #local usage="$(_shcli_help_fun_short $fun | sed 's/  */ /g')"
 # echo -e "\n  Usage:${usage//  / }"
  
  printf "  Usage: %s\n" "$(_shcli_help_part_usage)"


    
  true || paste \
      <(printf "%s\n" "${!_SHCLI_OPTRULES[@]}") \
      <(printf "%s\n" "${_SHCLI_OPTRULES[@]}") 
 
  # Display headers
  if [[ -n "${SHCLI_FN_HELP-}" ]]; then
    echo "    ${SHCLI_FN_HELP-}"
  fi
  
  # Disllay exemoles
  local j
  if [[ "${#SHCLI_FN_EXEMPLES[@]}" -gt 0 ]]; then
    printf "\n  Exemples: \n"
    for ((j=0;j<${#SHCLI_FN_EXEMPLES[@]};j++)); do
   
      local line="${SHCLI_FN_EXEMPLES[j]}"
      printf "    %s\n" "$line"
    done
  fi
 
  # Display arguments
  if [[ "${#_SHCLI_ARGRULES[@]}" -gt 0 ]]; then
    printf "\n  Arguments: \n"
    for ((j=0;j<${#_SHCLI_ARGRULES[@]};j++)); do
      j1=$(( $j + 1 ))
    
      local rule="${_SHCLI_ARGRULES[j]}"
      IFS=';' read -r _ ${_SHCLI_ARGRULES_FIELDS//;/ } <<< "$rule"
     
      printf "    %-16s %s\n" "$key_name" "$key_help"
      if [[ "$key_name" == 'command' ]]; then
        display_cmd=true
      fi
    done
  fi
  
  # Display commands
  if $display_cmd ; then
    printf "\n  Commands: \n"
           #SHAPP_NAME
    local pat="${SHAPP_NAME}${SHCLI_FN_GROUP:+_$SHCLI_FN_GROUP}"
    local fn=$(declare -F | sed -En "/${pat}_cli__/s/^.*_cli__//p")
    #echo "fn: >$fn< $pat"
    
    for i in $fn ; do
         printf "    %s\n" "$i"
    done
  fi
  
  # Display options
  if [[ "${#_SHCLI_OPTRULES[@]}" -gt 0 ]]; then
    printf "\n  Options: \n"
    for ((j=0;j<${#_SHCLI_OPTRULES[@]};j++)); do
      j1=$(( $j + 1 ))
      
      local rule="${_SHCLI_OPTRULES[j]}"
     # IFS=';' read -r _ short long kname kmod kreq vtype vdefault _other _ <<< "$line"
      IFS=';' read -r _ ${_SHCLI_OPTRULES_FIELDS//;/ } <<< "$rule"
          # _SHCLI_OPTRULES_FIELDS=';key_short;key_long;key_name;
          # key_required;key_type;val_default;val_assert;;key_help;'
  
  
      printf "    %-16s %s\n" "$key_short${key_long+,$key_long}" "$key_help"
    done
  fi
  
  echo ""
}


_shcli_help_part_usage()
{
  # Inline usage
  local usage
  if [[ -n "${SHCLI_FN_CMD-}" ]]; then
    usage="$SHAPP_NAME ${SHCLI_FN_CMD}"
  else
    local name=${SHCLI_FN_NAME//*_cli__}
    usage="$SHAPP_NAME ${name//_/ }"
  fi
  
  
  #local usage="${SHCLI_FN_CMD:-${SHCLI_FN_NAME}}"
  if [[ "${#_SHCLI_ARGRULES[@]}" -gt 0 ]]; then
    
    for ((j=0;j<${#_SHCLI_ARGRULES[@]};j++)); do
      local rule="${_SHCLI_ARGRULES[j]}"
      IFS=';' read -r _  kname kmod kreq vtype vdefault _other _ <<< "$rule"
      usage="$usage <${kname}>"
    done
  fi
  
  printf "%s" "$usage"
  
}


_shcli_help_fun_short()
{
  local fun=$1
  
  #_shcli_fn_load $fun
  
  
  # Display arguments
  local usage="${SHCLI_FN_NAME}"
  if [[ "${#_SHCLI_ARGRULES[@]}" -gt 0 ]]; then
    
    for ((j=0;j<${#_SHCLI_ARGRULES[@]};j++)); do
      local rule="${_SHCLI_ARGRULES[j]}"
      IFS=';' read -r _  kname kmod kreq vtype vdefault _other _ <<< "$rule"
      usage="$usage <${kname}>"
    done
  fi
  
  printf "  %-20s %s\n" "$usage" "${SHCLI_FN_HELP-}"
}



