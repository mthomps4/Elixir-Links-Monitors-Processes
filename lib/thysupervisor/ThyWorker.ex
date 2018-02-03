defmodule ThyWorker do
  def start_link do
    spawn(fn -> loop end)
  end

  def loop do
    receive do 
      :stop -> :ok
      msg -> 
        IO.inspect msg 
        loop
    end
  end
end


# Begin by creatign a worker 
# iex {:ok, sup_pid} = ThySupervisor.start_link([])
# {:ok, #PID<0.86.0>}

# {:ok, child_pid} = ThySupervisor.start_child(sup_pid, {ThyWorker, :start_link, []})

# Process.info(sup_pid, :links) 
#  > {:links, [#PID_FROM_SHELL, PID_CHILD]}

# Process.exit(child_pid, :crash)

# Process.info(sup_pid, :links)
# > {:links, [#PID_FROM_SHELL, #New_child_pid]}

# ThySupervisor.which_children(sup_pid)
# > #HashDict<[{#CHILD_PID, {ThyWorker, :start_link, []}}]> 
# ^ Child pid with child_spec 