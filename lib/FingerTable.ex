defmodule FingerTable do

def generate(pid_N_map, m) do
	
	nodes = Enum.sort(Map.values pid_N_map)
	nodes = Enum.map(nodes, fn i -> i |> Atom.to_string |> String.to_integer end)
	IO.puts "nodes == #{inspect nodes}"

	Enum.each pid_N_map, fn {_, n} ->

			fingertable = Enum.reduce(0..m-1, %{}, fn i, acc->
				 n = n |> Atom.to_string |> String.to_integer
				 fingertable_val = rem(n + :math.pow(2, i) |> Kernel.trunc, :math.pow(2, m) |> Kernel.trunc)
				 nodes_greater = Enum.filter(nodes, fn x -> x>=fingertable_val 
									end)
				 min_greater_node =
				 	if nodes_greater == [] do
				 		Enum.min nodes
				 	else
				 		Enum.min nodes_greater
				 	end
				 Map.put acc, i, min_greater_node|>Integer.to_string|>String.to_atom
			end)
			ChordNodeCoordinator.set_fingertable(n, fingertable)
			# IO.inspect fingertable
	end
end

#Fixes the fingertable for only one node - nodeN
def fix_finger(nodeN, m) do
	
	n = nodeN |> Atom.to_string |> String.to_integer
	fixed_fingertable = Enum.reduce(0..m-1, %{}, fn i, acc->
		 fingertable_val = rem(n + :math.pow(2, i) |> Kernel.trunc, :math.pow(2, m) |> Kernel.trunc)
		 				   |> Integer.to_string |> String.to_atom
		 #Yields the result of find successor using chain calls
		 search_result = ChordNodeCoordinator.find_successor nodeN, fingertable_val
		 #Here search_result will return :nil if the target node has dies/left
		 if search_result != :nil do
		 	Map.put acc, i, search_result
		 else
		 	acc
		 end
	end)
	ChordNodeCoordinator.set_fingertable(nodeN, fixed_fingertable)

end
end