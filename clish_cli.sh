
import clish_cli_lib.sh


# Global configuration
# ====================================


# Mendatory parse array
# Array containing arguments to parse. At the early
# stage, and outside any functuons of your app, you have ro
# set this variable like this minimal exemple:
#   SHCLI_PARSE=("$@")
#   shcli_parse
SHCLI_PARSE=()


# Determine the ececution model. There are two
# options, and you need to adapt your program.
# Default is exec, some people might want cleaner program
# and use eval mode:
#   exec: opt_parse directly loads variable as (prefixed) globals
#   eval: opt_parse output shell code to be evaluated
# Exemples:
#  shcli_parse            # Exec mode, all variables are global
#  eval "$(shcli_parse)"  # Eval mode
SHCLI_CFG_RUN_MODE=exec


# Tells how ro proceed unkown arguments. Can be:
# strict: Return failure when if opt or arg not defined
# forward: Store extra args for later parsing, but do not load them
# group: Store extra args for later use and load them (default)
# auto: Defaukt is group
SHCLI_CFG_UNKNOWN_MODE=group

# Deprevated: Should the option always before any args? Useful
# to fkrward args ro other functions. Enablkng this
# makes your app to use option asap instead forwarding
# them to its child.
# strict: no, can be disabled eothout issue
# forward: yes
# auto: yes
#SHCLI_CFG_OPT_FIRST=false


# Tells by wich prefix every generated vars are named.
# As those variables are globales, you may want to prefix them
# to avoid name colisions.
#SHCLI_FN_VPREFIX='cli_'
#SHCLI_FN_VPREFIX=''


# Shcli debug mode, set to ':' disable 
# or '_shcli_debug' to enable verbose output
SHCLI_DEBUG=:
SHCLI_DEBUG=_shcli_debug


# Command variables
_SHCLI_FN_META="CMD FUNC GROUP _EXEMPLES HELP VPREFIX ARGN ARGI _ARGS _ARGU"  

# For each commands are provided a bunch of vars describing
# the current context and the parsing status:
#  FUNC : Command name in cli
#  GROUP : Command group
#  _EXEMPLES : Exemples array
#  HELP : Help message

#  CMD : Command function name
#  VPREFIX : Variable prefix string
#  ARGN : Number of remaining args, known + unknown
#  ARGI : List of known args in _ARGS
#  _ARGS : Remaining args, no options
#  _ARGU : Array of unknown args 


# Internal metadata
_SHCLI_ARGRULES_FIELDS=';key_name;key_required;key_type;key_nargs;key_nmod;val_default;val_assert;val_transform;;key_help;'
_SHCLI_OPTRULES_FIELDS=";key_short;key_long;$_SHCLI_ARGRULES_FIELDS"


# Damn coool :D
EOL=$'\n'




# Exposed functions
# ====================================

shcli_cmd()
{
  local args=("$@")
 
  # Reset env
  _shcli_fn_reset_env
  _SHCLI_OPTRULES=()
  _SHCLI_ARGRULES=()
  
  # Default command
  
  SHCLI_CFG_OPT_FIRST=false
  SHCLI_FN_VPREFIX=''
  SHCLI_CFG_UNKNOWN_MODE=forward
  
  local j= j1= narg=0
  for ((j=0;j<${#args[@]};j++)); do
    #printf '  Doing %2d: %s\n' "$j" "${args[j]}"
    
    # Prepare 
    j1=$(( $j + 1 ))
    local arg0="${args[j]}"
    local arg1="${args[j1]-}"
  
    # Manage arguments
    case "$arg0" in
        -e|--exemple)
          SHCLI_FN_EXEMPLES+=("$arg1")
          j=$j1
        ;;
        -g|--group)
          # Can be: value,flag,flag_count
          SHCLI_FN_GROUP="$arg1"
          j=$j1
        ;;
        -h|--help)
          SHCLI_FN_HELP="$arg1"
          j=$j1
        ;;
        -p|--parser)   
          # debug analotics :p
          case "${arg1}" in
            strict) SHCLI_CFG_UNKNOWN_MODE=strict ;;
            forward) SHCLI_CFG_UNKNOWN_MODE=forward ;;
            auto|group) SHCLI_CFG_UNKNOWN_MODE=group ;;
            *) 
              >&2 echo "shcli_cmd: Unknown mode: $arg1"
              return 1
              ;;
          esac
          $SHCLI_DEBUG "Cfg: Parser mode: $SHCLI_CFG_UNKNOWN_MODE"
          j=$j1
        ;;
        -n|--name|--var)
          # Can be: [0-9A-Za-z_]+
          SHCLI_FN_CMD="$arg1"
          j=$j1
          $SHCLI_DEBUG "Cfg: Cli name: $SHCLI_FN_CMD"
        ;;
        -r|--prefix)
          # Can be: [0-9A-Za-z_]+
          SHCLI_FN_VPREFIX=$arg1
          j=$j1
          $SHCLI_DEBUG "Cfg: Var prefix: $SHCLI_FN_VPREFIX"
        ;;
        -f|--opt-first)
          SHCLI_CFG_OPT_FIRST="$arg1"
          j=$j1
          $SHCLI_DEBUG "Cfg: Options first: $SHCLI_CFG_OPT_FIRST"
        ;;
        *) # Positional args
          #pos_args+=($arg0)
          case "$narg" in
            0)
              SHCLI_FN_HELP="$arg0"
              narg=$(( $narg + 1 ))
            ;;
          esac
        ;;
    esac   
  done
  
  # Define gloabal defaults
  SHCLI_FN_FUNC="${SHCLI_FN_CMD:-${FUNCNAME[1]}}"
  
  $SHCLI_DEBUG "New command $SHCLI_FN_FUNC, reset env."
  
  shcli_opt -h,--help "Show this help" \
      --type help
      
}

shcli_arg()
{
  
  local args=("$@")
  local var 
  
  # Initiate attributes
  for var in ${_SHCLI_ARGRULES_FIELDS//;/ }; do
    [ -z "$var" ] || local "$var="
    #echo "Declare var: $var=''"
  done
  
  # Preset default config
  local key_nargs=1
  local key_nmod='!'
  
  # Loop over arguments
  local j= j1= narg=0
  for ((j=0;j<${#args[@]};j++)); do
    #printf '  Doing %2d: %s\n' "$j" "${args[j]}"
    
    # Prepare 
    j1=$(( $j + 1 ))
    local arg0="${args[j]}"
    local arg1="${args[j1]-}"
  
    # Manage arguments
    case "$arg0" in
        -r|--required)
          key_required="$arg1"
          j=$j1
        ;;
        
        -o|--optional) # deprecayed, replaced by nargs/nmod
          # Can be: value,flag,flag_count
          key_mod="$arg1"
          j=$j1
        ;;
        
        
        -t|--type)
          # Can be: bool,int,string,list
          case "$arg1" in
            file)
              key_default=false
              key_nargs=1
              key_nmod='!'
              val_assert=file
            ;;
            dir)
              key_default=.
              key_nargs=1
              key_nmod='!'
              val_assert=directory
            ;;
            dirs)
              key_default=.
              key_nargs=1
              key_nmod='+'
              val_assert=directory
            ;;
            shcli_cmd)
              key_nargs=0
              key_nmod='+'
              val_assert=shcli_cmd
            ;;
            *)
              echo "Bug: Unknown argument type '$arg1' for: $@"
              exit 1
          esac
          key_type="$arg1"
          j=$j1
        ;;
        
        -A|--assert)
          # Can be: assert function
          val_assert="$arg1"
          j=$j1
        ;;
        -T|--transform)
          # Can be: transform function
          val_transform="$arg1"
          j=$j1
        ;;
        -n|--nargs)
          # Can be: *1, 0, 2, 3, 4 ... greedy, all
          # fixed: 0, 1, 2, 3 ...
          # miltiple fixed: 0:1 0:2
          # greedy: +
          # all: *
          # paterns: [required][mod]
          #   0!   : strict 0
          #   0+   : 0 or 1 pattern
          #   1+   : 
          #   3@   : 3 next args till the end
          
          local key_nargs= key_nmod=
          if [[ "$arg1" =~ ^([0-9]+)([@+!])?$ ]]; then
            key_nargs=${BASH_REMATCH[1]}
            key_nmod=${BASH_REMATCH[2]:-!}
          else
            echo "Wrong format for nargs options: '$arg1'"
            exit 1
          fi
          
          j=$j1
        ;;
        -n|--name|--var)
          # Can be: [0-9A-Za-z_]+
          key_name="$arg1"
          j=$j1
        ;;
        -h|--help)
          key_help="$arg1"
          j=$j1
        ;;
        -d|--default)
          val_default="$arg1"
          j=$j1
        ;;
        *) # Positional args
          #pos_args+=($arg0)
          
          case "$narg" in
            0) key_name="$arg0" ;;
            1) key_help="$arg0" ;;
            *) narg=$(( $narg - 1 )) ;;
          esac
          narg=$(( $narg + 1 ))
        ;;
    esac   
  done
  
  # Store attributes
  local record=";"
  for var in ${_SHCLI_ARGRULES_FIELDS//;/ }; do
    record="$record${!var};"
  done
  #>&2  echo "Record arg: $record"
 
  _SHCLI_ARGRULES+=("$record")
  
}


shcli_opt()
{

  # Set default args
  local args=("$@")
  local var=  
    
  # Initiate attributes
  for var in ${_SHCLI_OPTRULES_FIELDS//;/ }; do
    [ -z "$var" ] || local "$var="
  done
  
  # Default option type
  key_nargs=1
  key_nmod='!'
  val_assert=any
  
  
  # Loop over arguments
  local j= j1= narg=0
  for ((j=0;j<${#args[@]};j++)); do
    #printf '  Doing %2d: %s\n' "$j" "${args[j]}"
    
    # Prepare 
    j1=$(( $j + 1 ))
    local arg0="${args[j]}"
    local arg1="${args[j1]-}"
  
    # Manage arguments
    case "$arg0" in
        -r|--required)
          key_required="$arg1"
          j=$j1
        ;;
        -m|--modifier)
          # Can be: value,flag,flag_count
          key_mod="$arg1"
          j=$j1
        ;;
        -n|--name|--var)
          # Can be: [0-9A-Za-z_]+
          key_name="$arg1"
          j=$j1
        ;;
        -h|--help)
          key_help="$arg1"
          j=$j1
        ;;
        -d|--default)
          val_default="$arg1"
          j=$j1
        ;;
        -t|--type)
          # Can be: bool,int,string,list
        #  key_type="$arg1"
         # j=$j1
        #;;
        
        case "$arg1" in
           any)
             
           ;;
            bool|flag_bool|flag_bool_true)
              key_default=false
              key_nargs=0
              key_nmod='+'
              val_assert=bool
            ;;
            count)
              key_nargs=0
              key_nmod='+'
              val_assert=shcli_cmd
            ;;
            help)
              val_assert=shcli_help
              key_nargs=0
            ;;
            *)
              echo "Bug: Unknown option type '$arg1' for: $@"
              exit 1
          esac
          key_type="$arg1"
          j=$j1
        ;;
        *) # Positional args
          #pos_args+=($arg0)
          
          case "$narg" in
            0)
              if [[ "$arg0" == *,* ]]; then
                key_short=${arg0%%,*}
                key_long=${arg0##*,}
              else
                key_short="$arg0"
                key_long=
              fi 
            ;;
            1) key_help="$arg0" ;;
            *) narg=$(( $narg - 1 )) ;;
          esac
          narg=$(( $narg + 1 ))
        ;;
    esac   
  done
  
  # Default attributes
  key_name=${key_name:-$(_shcli_get_key_name ${key_long-} ${key_short-})}
  key_type=${key_type:-value}
  
  # Store attributes
  local record=";"
  for var in ${_SHCLI_OPTRULES_FIELDS//;/ }; do
    record="$record${!var};"
  done
  #>&2  echo "Record opt: $record"
  
  _SHCLI_OPTRULES+=("$record")

  # enable bash debug for later use TOFIX
  #shopt -s extdebug
  
}





# This finctiom default all known variables before a parsing run
_shcli_prepare_parse()
{

  # Prepare shared vars
  _SHCLI_EXEC_HEAD=()
  _SHCLI_EXEC_MAIN=()
  _SHCLI_EXEC_TAIL=()
  _SHCLI_SKIP=0
  _SHCLI_RULE=
  
  # Reindex array, especially if it has been
  # manipulated between two parse. This avoid
  # uncontiguous indexes
  SHCLI_PARSE=("${SHCLI_PARSE[@]}")
  
  # Unpack arguments
  _shcli_unpack

  # Define defaults options
  local name= rule= i=
  for i in "${!_SHCLI_OPTRULES[@]}"; do 
    _shcli_parse_set opt_init  "${_SHCLI_OPTRULES[i]}"
  done 
  
  # Define default arguments
  for i in "${!_SHCLI_ARGRULES[@]}"; do 
    _shcli_parse_set arg_init "${_SHCLI_ARGRULES[i]}"
  done
}


shcli_parse()
{

  
  # Get exevution model from first arg, deprecated
  SHCLI_CFG_RUN_MODE=${1:-$SHCLI_CFG_RUN_MODE}
  
  
 # $SHCLI_DEBUG "Parser config: exec=$SHCLI_CFG_RUN_MODE mode=$SHCLI_CFG_UNKNOWN_MODE prefix=$SHCLI_FN_VPREFIX"
  $SHCLI_DEBUG "Parser command: ${SHCLI_FN_FUNC} ${SHCLI_PARSE[@]}"
  ( IFS=$'\n' ; $SHCLI_DEBUG "Opts rules:${EOL}" "${_SHCLI_OPTRULES[*]}" )
  ( IFS=$'\n' ; $SHCLI_DEBUG "Args rules:${EOL}" "${_SHCLI_ARGRULES[*]}" )
  
  
  # Prepare env
  # ---
  _shcli_prepare_parse
  


  # Configure the loop settings
  # ---
  
  # Tracks unknown pos arga
  local args_unknown=()
  local opt_unkown=()
  
  # Track known pos args
  local args_known=()
   
  # Track current args SH_PARSE indexes
  local i=0 i1=1
  
  # Track known pos args indexes
  local arg_kn_idx=0 
  
  # Track unknown pos args index
  local arg_nk_idx=0
  # Track unknown pos args SH_PARSE ids
  local args_ids=""
  
  # Track if we met an arg yet
  local before_args=true


  
  # Loop over args :D
  # ---
  
  for ((i;i<${#SHCLI_PARSE[@]};i++)); do   
    
    i1=$(( $i + 1 )) 
    local arg0="${SHCLI_PARSE[i]-}"
    local arg1="${SHCLI_PARSE[i1]-}"
  #  printf '  Doing %2d-%-2d: %s\n' "$i" $i1 "$arg0 -> $arg1"
    
    
    case "$arg0" in
      --)
        $SHCLI_DEBUG "Stop process args"
        args_unknown+=("${SHCLI_PARSE[@]:$j1}")
        break
      ;;
      -*)
        # Options
        # ---
        
        # We enter in the option world
        local rule=$(_shcli_rule_match "$arg0")    
        
        if $before_args && [[ -n "$rule" ]]; then
          # A rule has been found for this command
          # so we process it
          _shcli_parse_set opt "$rule" "${SHCLI_PARSE[@]:$i}"
        
        else
          # We enter in the unknown option world
          # We try to automagically process them.
          
          local key_name="$(_shcli_get_key_name "$arg0")"
        
          case "$SHCLI_CFG_UNKNOWN_MODE" in
            strict)
              >&2 printf "Undeclared option: %s\n" "$arg0"
              return 1
            ;;
            forward)
              $SHCLI_DEBUG "  Forward: $arg0"
              opt_unknown+=("$arg0")
            ;;
            group)
              if [[ "$arg1" =~ ^[^-].* ]]; then
                $SHCLI_DEBUG "  Set: $key_name=$arg1 (autodetect greedy)"
            #    _shcli_set_var "${key_type:-value}" "$key_name" "$arg1"    
                _shcli_parse_set opt_auto ";;;$key_name;" "${SHCLI_PARSE[@]:$i}"
            
                opt_unknown+=("$arg0" "$arg1")
              else
                $SHCLI_DEBUG "  Set: $key_name='' (autodetect no greedy)"
                #_shcli_set_var "${key_type:-value}" "$key_name" "$arg1"   
                _shcli_parse_set opt_auto ";;;$key_name;" "${SHCLI_PARSE[@]:$i}"
            
                opt_unknown+=("$arg0")
              fi
            ;;
          esac
        fi
        
      ;;
      *)
        # Positional args
        # ---
        
        # We are here in the positional world
        # We try to match existing positional args
        # to named variables
        
        # Set the first arg marker to false
        if $SHCLI_CFG_OPT_FIRST; then
          before_args=false
        fi
        
        
        if [[ "$arg_kn_idx" -lt "${#_SHCLI_ARGRULES[@]}" ]]; then
          # Positional arg has been preset
          
          
          _shcli_parse_set arg "${_SHCLI_ARGRULES[arg_kn_idx]}" "${SHCLI_PARSE[@]:$i}"
         # echo "Skip args: $_SHCLI_SKIP"
          # returns
          
          
          #IFS=';' read -r _ ${_SHCLI_ARGRULES_FIELDS//;/ } <<< "${_SHCLI_ARGRULES[arg_kn_idx]}"
          #_shcli_set_var argval "$key_name" "$arg0"
          arg_kn_idx=$(( $arg_kn_idx + 1 ))
          #args_known+=("$arg0")
          
         # $_SHCLI_SKIP
          echo "arg match: ${SHCLI_PARSE[@]:$i:$i+$_SHCLI_SKIP}"
          args_known+=("${SHCLI_PARSE[@]:$i:$i+$_SHCLI_SKIP}")
          #$SHCLI_DEBUG "  Set: arg[$arg_kn_idx]: $key_name=$arg0 (known)"
          
        else
        
          # Positional arg has not been set, what ro do with it?
          case "$SHCLI_CFG_UNKNOWN_MODE" in
            strict) 
              >&2 printf "Undeclared positional arg: %s\n" "$arg0"
              return 1
            ;;
            forward) 
              $SHCLI_DEBUG "  Forward: $arg0"
            ;;
            group)
              arg_nk_idx=$(( $arg_nk_idx + 1 ))
              $SHCLI_DEBUG "  Set: _arg$arg_nk_idx=$arg0 (audetect)"
              _shcli_set_var varinit "_arg$arg_nk_idx" "$arg0"
            ;;
          esac
        
          # Convenient acces to undeclared pos args
          args_ids="${args_ids:+$args_ids }${#args_unknown[@]}"
          args_unknown+=("$arg0")
        
        fi
      ;;
    esac
    
    
    # Set the next index to get, depending _SHCLI_SKIP
    i=$(( $i + $_SHCLI_SKIP ))
    _SHCLI_SKIP=0  
 
  done

  # Add parser vars
  $SHCLI_DEBUG "Set function vars: \$SHCLI_FN_*"
  
  SHCLI_FN_ARGS=("${args_known[@]}")
  SHCLI_FN_ARGI=$args_ids
  SHCLI_FN_ARGU=("${args_unknown[@]}")
  SHCLI_FN_ARGN=$(( ${#args_unknown[@]} -1 ))
 
  # Set var for next loop 
  SHCLI_PARSE=( "${opt_unknown[@]}" "${args_unknown[@]}" )
   
  # Export fonction meta
  local OLDIFS=$IFS
  IFS=$EOL
  _SHCLI_EXEC_TAIL+=($(declare -p ${!SHCLI_FN_*}))
  IFS=$OLDIFS
  
  # Append header and tail
  local local_code=( \
    "${_SHCLI_EXEC_HEAD[@]}" \
    "${_SHCLI_EXEC_MAIN[@]}" \
    "${_SHCLI_EXEC_TAIL[@]}")
    
  # Run?
  case "$SHCLI_CFG_RUN_MODE" in
    eval)
      # Remove local or not ? nope ...
      $SHCLI_DEBUG "Render the code to be evaluated:"
      printf '%s\n' "${local_code[*]}"
    ;;
    exec|-|*)
      local global_code=$( IFS=$'\n'; printf '%s\n' "${local_code[*]}" | sed 's/local //' )
      $SHCLI_DEBUG "Code to be executed:$EOL${global_code}"
      eval "$global_code" 
      
      
    ;;
    *) >&2 printf "shcli_parse: Unknown execution model: $SHCLI_CFG_RUN_MODE"
    return 1
    ;;
  esac
  
  # Clean env
  _SHCLI_ARGRULES=()
  unset _SHCLI_EXEC_HEAD _SHCLI_EXEC_MAIN \
    _SHCLI_EXEC_TAIL _SHCLI_SKIP
}



# Shortcuts
# ====================================


shopt -s expand_aliases
alias _cmd='shcli_cmd '
alias _opt='shcli_opt '
alias _arg='shcli_arg '
alias _parse='shcli_parse '

# These are development shortcurts, not to be used
# on production. 




# Other useful libs 
# ====================================

# This place gather optional libraries
# for other module to let the whole
# thing interact with everyrhing. it's
# quite good modular system :)


# Function that integrate into shapp lookup hook
# Return result in SHCLI_FN_CMD var, so must be sourced
# Input:
#   env:
#   args:
#   opts:
#   stdin:
#   stdN:
# Output:
#   env: SHCLI_FN_CMD=$cmd_run
#   stdout: <None>
#   stderr:
#   std3:
#   rc:



shcli_shapp_router__shcli()
{
  # Store arguments in array
  SHCLI_PARSE=("$@")
  # SHCLI_DEBUG=_shcli_debug
  
  # Options and arguments
  shcli_cmd                  "Main command dispatcher" \
      --name                     $SHAPP_NAME \
      --parser                   forward \
      --prefix                   _shcli_ \
      --opt-first                true
      
  shcli_opt -f,--force       "Force operations" \
      --type                     flag_bool \
      --default                  "false" \
      --nargs                    3  
  shcli_opt -D,--debug-router  "Show dispatcher debug infos" \
      --type                     flag_bool \
      --var                      debug \
      --default                  false
  
  shcli_arg command            "Command to run" \
      --type                     shcli_cmd
  
  
  # Old nota:
  # BUG: You cannot use any lib from clish inside clish ....
  # Where ? Should be part of the header, in shcli
  # Because this is the default we want fkr ebery
  # apps !
 
  #set -x
  #SHCLI_DEBUG=_shcli_debug
  # Parse options and args a first time, and forward
  shcli_parse -
  
  echo "command to run:  $_shcli_command"
  
  local cmd_ok=$_shcli_command
  
  # Enable debug mode 
  if $_shcli_debug ; then
    SHCLI_DEBUG=_shcli_debug
    $SHCLI_DEBUG '~~~ shcli_dispatcher'
    $SHCLI_DEBUG "Debug mode enabled for app: $SHAPP_NAME (-C)"
  else
    # Disable app debig
    SHCLI_DEBUG=:
  fi
  
  if false; then
  
  # Find the good command (the dispatcher!)
  local namespaces="${SHAPP_MODS//|/ }"
  for ns in $namespaces; do
  
    local cmd_test="${ns}_cli__$_shcli_command"
    local cmd_ok=
    
    # Test result
    $SHCLI_DEBUG "Testing func: $cmd_test"
    if declare -f $cmd_test >&/dev/null; then
      $SHCLI_DEBUG "Func match: $cmd_test"
      cmd_ok=$cmd_test
    fi
    
    for i in $SHCLI_FN_ARGI; do
      local cmd_child=${SHCLI_FN_ARGU[$i]}
      cmd_test="${cmd_test}_${cmd_child}"
       
      # Test result
      $SHCLI_DEBUG "Testing func: $cmd_test"
      if declare -f $cmd_test >&/dev/null; then
        $SHCLI_DEBUG "Func match: $cmd_test"
        cmd_ok=$cmd_test
        unset SHCLI_PARSE[i]
      fi
      
    done
    
    # Quit loop if found func in this namespace
    [[ -z "$cmd_ok" ]] || break
     
  done
  
  # Check result and logs
  if [[ -z "$cmd_ok" ]]; then
    >&2 printf "Bug: Unknown command '%s' from $namespaces\n" "${SHCLI_FN_ARGS[*]}"
    return 1
  fi
  
  fi
  
  # Run the command
  $SHCLI_DEBUG "shcli router run: $cmd_ok -- ${SHCLI_PARSE[@]}"
  $cmd_ok "${SHCLI_PARSE[@]}"
  
}
