defmodule ThySupervisor do
  use GenServer

  # Main entry point into creating a supervisor process.
  # name of Module and a list with a single element of child_spec_list specifies a [empty] or list of child specifications

  # Fancy way of saying -- What chihld processes it should manage 
  # Example [{ThyWorker, :start_link, []}, {ThyWorker, start_link, []}]

  #######
  # API # 

  # passes second arg to init/1 
  def start_link(child_spec_list) do
    GenServer.start_link(__MODULE__, [child_spec_list])
  end

  def start_child(supervisor, child_spec) do 
    GenServer.call(supervisor, {:start_child, child_spec})
  end

  def terminate_child(supervisor, pid) when is_pid(pid) do
    GenServer.call(supervisor, {:terminate_child, pid})
  end

  def restart_child(supervisor, pid, child_spec) when is_pid(pid) do
    GenServer.call(supervisor, {:restart_child, pid, child_spec})
  end
  
  def count_children(supervisor) do
    GenServer.call(supervisor, :count_children)
  end

  def which_children(supervisor) do
    GenServer.call(supervisor, :which_children)
  end
  ############# 
  # CALLBACKS #

  # trap exit lets supervisor get exit as normal message 
  # spawns children 
  # [{<pid1>, {ThyWorker, :init, []}}, {<pid2>, {ThyWorker, :init, []}}]
  # Transform list of tuples to HashDict, with the pids as the keys of the child processes 

  # #HashDict<[pid1: {:mod1, :func1, :arg1}, pid1: {:mod2, :func2, :arg2}]>
  def init([child_spec_list]) do
    Process.flag(:trap_exit, true)
    state = child_spec_list
              |> start_children
              |> Enum.into(HashDict.new)
    {:ok, state}
  end

  # Used to shut down the supervisor process 
  def terminate(_reason, state) do 
    terminate_child(state) 
    :ok
  end

  def handle_call(:count_children, _form, state) do
    {:reply, HashDict.size(state), state}
  end

  def handle_call(:which_children, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:start_child, child_spec}, _from, state) do
    case start_child(child_spec) do
      {:ok, pid} -> 
        new_state = state |> HashDict.put(pid, child_spec)
        {:reply, {:ok, pid}, new_state}
      :error -> 
        {:reply, {:error, "error starting child"}, state}
    end
  end

  def handle_call({:terminate_child, pid}, _from, state) do
    case terminate_child(pid) do
      :ok -> 
        new_state = state |> HashDict.delete(pid)
        {:reply, :ok, new_state}
      :error -> 
        {:reply, {:error, "error terminating child"}, state}
    end
  end

  def handle_call({:restart_child, old_pid}, _from, state) do
    case HashDict.fetch(state, old_pid) do
      {:ok, child_spec} -> 
        case restart_child(old_pid, child_spec) do
          {:ok, {pid, child_spec}} -> 
            new_state = state 
                          |> HashDict.delete(old_pid)
                          |> HashDict.put(pid, child_spec)
            {:reply, {:ok, pid}, new_state}
          :error -> {:reply, {:error, "error restarting child"}, state}
        end
        _catch -> {:reply, :ok, state}
    end
  end

  # Supervisor set to trap exits 
  # when forcibly killed the supervisor receives a message {:EXIT, pid, :killed}
  # handle info set to handle this message 
  def handle_info({:EXIT, from, :killed}, state) do
    new_state = state |> HashDict.delete(from)
    {:noreply, new_state}
  end

  # Doing nothing when a child process exits normally ** finishes 
  def handle_info({:EXIT, from, :normal}, state) do
    new_state = state |> HashDict.delete(from)
    {:noreply, new_state}
  end

  # Restart child that exits weird... exits reason not above 
  def handle_info({:EXIT, old_pid, _reason}, state) do
    case HashDict.fetch(state, old_pid) do
      {:ok, child_spec} -> 
        case restart_child(old_pid, child_spec) do
          {:ok, {pid, child_spec}} -> 
            new_state = state 
                          |> HashDict.delete(old_pid) 
                          |> HashDict.put(pid, child_spec)
            {:noreply, new_state}
            :error -> {:noreply, state}
        end
      _catch -> {:noreply, state}
    end
  end
  ####
  # Private Functions 

  # makes a Synchronous call req to the supervisor. 
  # The req contains a tuple containing the :start_child atom and child specs
  # The request is handled by handle_call call back 
  # It attempts to start a new child process using the start_child/1
  # on success the caller receives {:ok, pid}
  # and the state of the supervisor is updated to new_state
  # LARGE Assumption 
  # Assumed that process are made via spawn_link 
  # Supervisor OTP Behavior expects processes to be created via spawn_link
  # links pid to supervisor 
  defp start_child({mod, fun, args}) do
    case apply(mod, fun, args) do
      pid when is_pid(pid) -> 
        Process.link(pid)
        {:ok, pid}
      _catch -> :error
    end
  end


  ## Takes a list of child specs and hands start_child a child spec 
  # all while accumulating a list of tuples 
  # each tuple contains the pid of 

  defp start_children([child_spec|rest]) do
    case start_child(child_spec) do
      {:ok, pid} ->
        [{pid, child_spec}|start_children(rest)]
      :error -> :error
    end
  end

  defp start_children([]), do: []

  defp terminate_children([]), do: :ok
  defp terminate_children(child_spec_list) do
    child_spec_list |> Enum.each(fn {pid, _child_spec} -> terminate_child(pid) end)
  end
  defp terminate_child(pid) when is_pid(pid) do
    Process.exit(pid, :kill)
    :ok
  end

  defp restart_child(pid, child_spec) when is_pid(pid) do
    case terminate_child(pid) do
      :ok -> 
        case start_child(child_spec) do
          {:ok, new_pid} -> 
            {:ok, {new_pid, child_spec}}
          :error -> :error
        end
      :error -> :error
    end
  end
end