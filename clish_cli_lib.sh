


# Internal functions
# ====================================

_shcli_debug()
{
  _SHCLI_DEBUG_LVL=${_SHCLI_DEBUG_LVL:-1}
  
  local indent=$(printf "%${_SHCLI_DEBUG_LVL}s")
  
  #local args=$@
  local args=$(sed '2,$s/^/   | /' <<< "$@")
  #>&2 printf "debug: %-10s: %s\n" "${FUNCNAME[1]}" "$args"
  >&2 printf "debug_cli:${indent%?} %s\n" "$args"
}


_shcli_fn_declare()
{  
  local sub=
  for i in $_SHCLI_FN_META; do
    case "$i" in 
      _*) sub="SHCLI_FN$i"
      # bug hete, should use previous val ...
          declare -ga "$sub=()" ;;
      *)  sub="SHCLI_FN_$i"
          declare -g  "$sub=${!sub-}" ;;
    esac
    #echo "declare $sub"
  done
}


_shcli_fn_reset_env()
{  
  for i in $_SHCLI_FN_META; do
   # echo reset $i
    case "$i" in 
      _*) declare -ga "SHCLI_FN$i=()" ;;
      *)  declare -g  "SHCLI_FN_$i="  ;;
    esac
  done    
}



_shcli_fn_load()
{
  local fun=$1
  $SHCLI_DEBUG "Reparse function meta: $fun"
  _shcli_fn_reset_env
  
  SHCLI_FN_FUNC=$fun
  
  
  #>&2 echo "yooooo fun: $fun"
  
  # Eval the shcli command line
  while read -r line; do
    #>&2 echo "yooooo $line"
    if [[ "$line" =~ ^shcli_([[:alnum:]]*)" ".* ]]; then
      cmd="${BASH_REMATCH[0]}"
      
      case "${BASH_REMATCH[1]}" in
        parse) break ;;
        cmd|opt|arg) 
        #>&2 echo "run:   ${BASH_REMATCH[0]}"
        eval "${BASH_REMATCH[0]}";;
      esac
    fi   
  done <<< "$(type $fun)"
}


_shcli_get_key_name()
{
  #set -x
  local key=$1
  if [[ "$key" =~ -*(.*) ]]; then
    key="${BASH_REMATCH[1]}"
  fi
  #echo "${key}"
  echo "${key//-/_}"
 # set +x
}


_shcli_unpack()
{
  local j= rule= r=()
  
  for ((j=0;j<${#SHCLI_PARSE[@]};j++)); do
    rule="${SHCLI_PARSE[j]}"
    
    # Parse each argument, and expand them
    if [[ "$rule" =~ ^([0-9A-Za-z-]*)=(.*) ]]; then
     # echo "rule: $rule"
      r+=( "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" )
    elif [[ "$rule" =~ ^-(([0-9A-Za-z]{2,})*)$ ]]; then
      local m="${BASH_REMATCH[1]}"
      for ((i=0; i<${#m}; i++)); do
        r+=("-${m:$i:1}")
      done   
    else
      r+=("$rule")
    fi  
  done
  SHCLI_PARSE=("${r[@]}")
   

   #paste \
  #  <(printf "%s\n" "${!r[@]}") \
  #  <(printf "%s\n" "${r[@]}") 
}


_shcli_rule_match()
{
  local cmd="$1"
  #set -x
  # Search for matching rules
  for i in "${!_SHCLI_OPTRULES[@]}"; do        
   # >&2 echo "$cmd VS ${_SHCLI_OPTRULES[i]}"
    if [[ "${_SHCLI_OPTRULES[i]}" =~ .*\;$cmd\;.* ]]; then
      echo "${BASH_REMATCH[0]}"
     # >&2 echo "   >>> $cmd VS ${_SHCLI_OPTRULES[i]}"
      break
    fi
  done
}


_shcli_dump_ctx()
{
  #echo -e "VARS:  ${!SHCLI_@}  " | tr ' ' '\n'
  #echo -e "$(declare -p ${!SHCLI_@})" | sed -E 's/^declare //;/1/!s/(.)/  | \1/' # | sort
  
  for i in ${!SHCLI_*}; do
    #echo "  > $i:"
    declare -p $i | sed -E '1s/^/  /;2,$s/^/  | /'
  done
}


# Beta functions
# ====================================



_shcli_set_var ()
{
   #set -x
  >&2 echo "SET VAR DEPRECATED: $@"
  
  local key_type=$1
  local key_name="$2"
  shift 2
  local key_val=$@
  local skip=false
  
  $SHCLI_DEBUG "  Set ${SHCLI_FN_VPREFIX}$key_name ($key_type) to $key_val?"
  
  if [[ $key_type == _* ]]; then
    key_type="${key_type#_}"
    skip=true
  else
    key_name="${SHCLI_FN_VPREFIX}$key_name"
  fi
  
  
 # >&2 echo "DEFINE: $key_type $key_name ?($key_val)"
  case "${key_type}" in
  
    # Iniit variables
    varinit)
      _SHCLI_EXEC_MAIN+=("local $key_name='$key_val'")
    ;;
    argval)
      _SHCLI_EXEC_MAIN+=("$key_name='$key_val'")
    ;;
    
    # Special variables (_)
    help)
      _SHCLI_EXEC_TAIL+=("_shcli_fn_load $SHCLI_FN_FUNC")
      _SHCLI_EXEC_TAIL+=("_shcli_help_fun_long $SHCLI_FN_FUNC")
      _SHCLI_EXEC_TAIL+=("exit")
      #_SHCLI_SKIP=9999999
    ;;
    array)
      local t=$(declare -p $key_val)
      _SHCLI_EXEC_MAIN+=("$key_name=${t#*=}")
    ;;
    
    
    # Values
    value)
      _SHCLI_EXEC_MAIN+=("$key_name='$key_val'")
      $skip || _SHCLI_SKIP=$(( _SHCLI_SKIP + 1 ))
    ;;
    value_concat_words)
      _SHCLI_EXEC_MAIN+=("$key_name=\"\$$key_name \$$key_val\"")
      $skip || _SHCLI_SKIP=$(( _SHCLI_SKIP + 1 ))
    ;;
    value_concat_lines)
      _SHCLI_EXEC_MAIN+=("$key_name=\"\$$key_name\n\$$key_val\"")
      $skip || _SHCLI_SKIP=$(( _SHCLI_SKIP + 1 ))
    ;;
    
        
    # Booleans flags
    flag_count|flag_sum)
      _SHCLI_EXEC_MAIN+=("$key_name=\$(( \$$key_name + 1 ))")
    ;;
    flag_bool)
      _SHCLI_EXEC_MAIN+=("$key_name=true")
    ;;
    flag_nbool)
      _SHCLI_EXEC_MAIN+=("$key_name=false")
    ;;
   
    # Error management
    *)
      >&2 printf "Unknown key type for %s: %s\n" "$key_name" "$key_type"
      return 1
    ;;
  esac
  
  set +x
}






# test asserts

_shcli_parse_set ()
{

  # Parse args
  local rule_type="$1"
  local rule_vals="$2"
  shift 2
  local key_vals=($@)
  
  
  # Detect arg type
  local rule_fields
  case "$rule_type" in
    opt*) rule_fields=${_SHCLI_OPTRULES_FIELDS//;/ } ;;
    arg*) rule_fields=${_SHCLI_ARGRULES_FIELDS//;/ } ;;
    *) echo "Bug: Unsuported parse method: $rule_type"
      exit 1 ;;
  esac
  
  # Read opt/arg metadata
  IFS=';' read -r _ ${rule_fields} _ <<< "$rule_vals" 
  
  # Prepare operations
  local prefix=
  
  case "$rule_type" in
    *_auto)
    ;;
    *_input)
      # Handle user input
    ;; 
    *_declare|*_init) 
      # Variable declararions
      prefix="local "
         
      local cmd="${prefix}${SHCLI_FN_VPREFIX}${key_name}='${val_default}'"
      $SHCLI_DEBUG "Declare: $cmd"
      _SHCLI_EXEC_MAIN+=("$cmd  # define")
      return
    ;;
  esac
  
  
 # Parse args and opts !!! 
  
  # Debug
  #cho " > $key_name=$key_vals"
  #for r in $rule_fields; do
  #  echo "  > $r=${!r}"
  # done
  #set -x
 
  
   
  # Assign functions
  local fn_assert="_shcli_assert_${val_assert:-any}"
  local fn_transform="_shcli_transform_${val_transform:-none}"
  
  # Shared vars
  _SHCLI_KEY_VALUE=
  
  
  
  # Prepare loop execution
  local max=${#key_vals[@]}
  local exit_on_fail=true
  local skip_on_fail=false
  case "$key_nmod" in
    !) 
      exit_on_fail=true
      skip_on_fail=false
      
      if [[ "$key_nargs" -gt "$max" ]]; then
        echo "Error: Missing arg for $key_name: $@"
        exit 1
      fi
      max=${key_nargs}
    ;;
    +) 
      exit_on_fail=false
      skip_on_fail=true
    ;;
    @) 
      exit_on_fail=false
      skip_on_fail=false
      # Bug: this combination leads to uncontigis
      # args ... arf ...
      exit_on_fail=true # fix :/
    ;;
  esac
  
  # Get key value(s)
  _SHCLI_DEBUG_LVL=3
  local i=0
  local vals=()
  for ((i=0;i<$max;i++)); do
    local key_val=${key_vals[i]}
    
    # Quit if wrong type
    local arr=("${vals[@]}" "$key_val")
    
    # Test if value pass assertion
    if $fn_assert "${arr[@]}"; then
      vals=("${arr[@]}")
      _SHCLI_SKIP=$i
      #_SHCLI_SKIP=$(( $i + 1 ))
    else
      case "$key_nmod" in
        !)
          echo "Error: Wrong required value! $key_name=...$key_val"
          exit 1
        ;;
        +@)
          break
        ;;
      esac
    fi
  done
   
  # Ensure minimum vals are found
  if [[ "$_SHCLI_SKIP" -lt "$key_nargs" ]]; then
    echo "Error: Missing value for option for $key_name: $rule_vals"
    exit 1
  fi

  # Transform value
  if declare -f $fn_transform >& /dev/null; then
    $fn_transform "${_SHCLI_KEY_VALUE:-${vals[@]}}"
  fi
  
  # Reset global var
  _SHCLI_KEY_VALUE="${_SHCLI_KEY_VALUE:-${vals[@]}}"
  
  # Craft command
  _SHCLI_DEBUG_LVL=1
  local cmd="${prefix}${SHCLI_FN_VPREFIX}${key_name}='${_SHCLI_KEY_VALUE}'"  
  $SHCLI_DEBUG "Use $_SHCLI_SKIP arg(s): $cmd"
 
  # Exec and clean
  _SHCLI_EXEC_MAIN+=("$cmd")
  unset _SHCLI_KEY_VALUE
  
  
  set +x
}


_shcli_assert_any()
{
  return 0
}

_shcli_assert_bool()
{
  case "${1-}" in
    0|true|True|yes|Yes|On)
     _SHCLI_KEY_VALUE=true; return 0 ;;
    1|false|False|no|No|Off)
      _SHCLI_KEY_VALUE=false; return 0 ;;
  esac
  return 1
}

_shcli_assert_int()
{
  case "${1-}" in
    [0-9][0-9]*) return 0 ;;
  esac
  return 1
}

_shcli_assert_float()
{
  case "${1-}" in
    [0-9][0-9.]*) return 0 ;;
  esac
  return 1
}

_shcli_assert_word()
{
  case "${1-}" in
    [0-9A-Za-z_][0-9A-Za-z_-]*) return 0 ;;
  esac
  return 1
}

_shcli_assert_file()
{
  [ -f "${1-}" ]
}

_shcli_assert_dir()
{
  [ -d "${1-}" ]
}

_shcli_assert_func()
{
  type "${1-}" | grep -q function
}

_shcli_assert_shcli_cmd()
{
  local args="${@}"
  local namespaces="${SHAPP_MODS//|/ }"
  
  for ns in $namespaces; do
    local cmd_test="${ns}_cli__${args// /_}"
    $SHCLI_DEBUG "Assert func: $cmd_test"
    
    if declare -f $cmd_test >&/dev/null; then
      $SHCLI_DEBUG "  Func asserted: $cmd_test"
      _SHCLI_KEY_VALUE=$cmd_test
      return 0
    fi  
  done
  
  return 1
}


_shcli_transform_none()
{
  _SHCLI_KEY_VALUE="${@}"
}
_shcli_transform_array()
{
  _SHCLI_KEY_VALUE=("${@}")
}

_shcli_transform_bool()
{
  case "${1-}" in
    0|true|True|yes|Yes) _SHCLI_KEY_VALUE=true ;;
    1|false|False|no|No) _SHCLI_KEY_VALUE=false ;;
    *) printf "Unsupported bool: '${1-}'"
      return 1 ;;
  esac
}




parse_arg_var()
{ :; }

parse_nargs()
{ :; }

parse_nargs_files()
{ :; }

parse_nargs_func()
{ :; }




