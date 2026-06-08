typeset -g __last_cmd

TRAPDEBUG() {
  __last_cmd=$ZSH_DEBUG_CMD
  print -u2 -- "cmd: $ZSH_DEBUG_CMD"
  print -u2 -- "previous status: $prev_status"
  print -u2 -- "pipeline status: ${pipestatus[*]}"
  print -u2 -- "location: ${funcfiletrace[1]:-${(%):-%N:%i}}"
  print -u2 -- "function stack: ${(j: -> :)funcstack}"
  print -u2 -- "file trace: ${(j: -> :)funcfiletrace}"
  print -u2 -- "source trace: ${(j: -> :)funcsourcetrace}"
  print -u2 -- "eval context: ${(j: -> :)zsh_eval_context}"
  print -u2 -- "subshell level: $ZSH_SUBSHELL"
}

TRAPERR() {
  local _status=$?

  print -u2 -- "Exit status: $_status"
  print
  print -u2 -- "Line: $LINENO"
  print -u2 -- "Location: ${funcfiletrace[1]:-$0:$LINENO}"
  print -u2 -- "Command: $__last_cmd"

  return $_status
}

ls funky


print hello
