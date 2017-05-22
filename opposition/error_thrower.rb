class ErrorThrower
  def task_name_occupied_exception(identifier)
    raise format_error("Multiple definitions of task \"#{identifier}\" found.", "Make sure task names are unique.")
  end

  def var_not_found_exception(identifier)
    raise format_error("Variable \"#{identifier}\" was not found in any reachable scope.", "Make sure \"#{identifier}\" is defined in a reachable scope before referencing it.")
  end

  def task_not_found_exception(identifier)
    raise format_error("Task \"#{identifier}\" was not found in the program.", "Make sure \"#{identifier}\" is defined before calling it.")
  end

  def invalid_arg_list_size_exception(task_to_call, param_list, arg_list)
    raise format_error("The size of argument list #{arg_list} is not the same as that of parameter list #{param_list} in task #{task_to_call}.", "Make sure that the size of #{arg_list} matches that of #{param_list}.")
  end

  def invalid_step_exception(step)
    raise format_error("Invalid step counter found #{step}.", "Use only values above 0.")
  end

  def invalid_terminator_stmt_excepction(found_in, stmt)
    raise format_error("Invalid step counter found #{step}.", "Use only values above 0.")
  end

  def invalid_step_exception(step)
    raise format_error("Invalid step counter found #{step}.", "Use only values above 0.")
  end

  def format_error(error, solution)
    "\n\n\tOpps! Rino has encountered an error:\n\n\t\t#{error}\n\n\tSolution:\n\n\t\t#{solution}\n\n"
  end
end