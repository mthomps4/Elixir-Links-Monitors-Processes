defmodule Ring.Test do
  use ExUnit.Case, async: true
  describe "test-Ring" do
    test "Make Ring then crash" do
      pids = Ring.create_process 5 
      assert Enum.count(pids) === 5
      assert Ring.link_processes(pids) === :ok
      assert pids |> Enum.shuffle |> List.first |> send(:crash) === :crash
      IO.puts "Waiting 2 seconds for ring to crash" ; :timer.sleep(2000); IO.puts "All pids should have crashed by now..."
      assert pids |> Enum.map(fn pid -> Process.alive?(pid) end) === [false, false, false, false, false]
      IO.puts "Pids Alive? -- #{inspect pids |> Enum.map(fn pid -> Process.alive?(pid) end)}"
    end
  end
end