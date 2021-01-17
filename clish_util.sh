


# Other lib functions
# ====================================

dump_array ()
{
  declare -p $1
  return
 # set -x
  local str="$1[@]"
  local foo=("${!str}") 
  
  paste \
    <(printf "%s\n" "${!foo[@]}")  \
    <(printf "%s\n" "${foo[@]}") 
    
    
  # echo ====
 # array2def "$1"
}


array2def ()
{
  local str="$1[@]"
  local foo=("${!str}") 
  
  #echo yoooo2
  
  printf "$1=( "  
  for ((j=0;j<${#foo[@]};j++)); do
    printf '"%s" ' "${foo[j]}"
  done
  printf ")\n"  
  
}
  
dump_env ()
{
  local dump_action=$1
  local dump_prefix=~/tmp
  
  # Damn, this show array dearation !
  # Also dk the diff with
  # - var names vs var content : # | sed 's/=.*/=/' \
  # - functions : declare -F
  # - alias: Shell aliases
  # - env: like vars but env only
  # Todo:
  # - Set a env var to define ignore patterns
  # - Better file handling
  # - suport (color)diff
  
  case "$dump_action" in
    start) dump_dest=dump1.env ;;
    stop) dump_dest=dump2.env ;;
    *)
      >&2 echo "Unsuported dump_action: $dump_action"
      return 1
    ;;
  esac
    
  declare -p \
  | grep -v LS_COLORS \
    | LC_ALL=C sort -z | tr "\0" "\n" \
      > $dump_prefix/$dump_dest
      
  if [[ "$dump_action" == 'stop' ]]; then
    set +e  # Fix: priper shopt restore !!!
    colordiff --unified=0 $dump_prefix/dump2.env $dump_prefix/dump1.env | grep -v '@@.*'
   # | colordiff
    
    # diff $dump_prefix/dump1.env $dump_prefix/dump2.env
    rm $dump_prefix/dump2.env $dump_prefix/dump1.env
  fi
}





