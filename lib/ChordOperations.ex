	defmodule ChordOperations do

	#Stores the given list of keys in the chord ring using chord protocol
	def storeKeys(keys, start_node) do
		
		# keys = Enum.slice keys, 0, 5
		Enum.each keys, fn key ->
					# key = Enum.random keys
					IO.inspect "Storing key == #{key}"
					#Starting node is selected at random to initiate :store_key
					ChordNodeCoordinator.store_key start_node, key
		end
	end

	def initializeSuccessors(pid_N_map) do

		IO.puts "Initializing successor pointers for all nodes ..."

		sorted_pid_N_list = Map.to_list(pid_N_map) |> 
					 	   Enum.sort_by(&(elem(&1, 1)))
		sorted_pid_N_map =  sorted_pid_N_list|> 
					 	   Map.new

		IO.puts "sorted_pid_N_map === #{inspect Map.to_list(pid_N_map) |> 
					 	   Enum.sort_by(&(elem(&1, 1)))}"
		:timer.sleep 1000

		sorted_pid_N_map |> Enum.with_index |>  Enum.each(fn { _ , i} ->
				
				pid = elem(Enum.at(sorted_pid_N_list, i),0)
				current_N = elem(Enum.at(sorted_pid_N_list, i),1)
				successor = 
					if i+1 < map_size(sorted_pid_N_map) do
						elem(Enum.at(sorted_pid_N_list, i+1),1)
					else
						elem(Enum.at(sorted_pid_N_list, 0),1)
					end
				IO.puts "current_pid = #{inspect pid}, current_N=#{current_N}, s=#{successor}"
				ChordNodeCoordinator.set_successor pid, successor
		end)
	end

	def initializePredecessors(pid_N_map) do

		IO.puts "Initializing predecessor pointers for all nodes ..."

		sorted_pid_N_list = Map.to_list(pid_N_map) |> 
					 	   Enum.sort_by(&(elem(&1, 1)))
		sorted_pid_N_map =  sorted_pid_N_list|> 
					 	   Map.new

		IO.puts "sorted_pid_N_map === #{inspect Map.to_list(pid_N_map) |> 
					 	   Enum.sort_by(&(elem(&1, 1)))}"
		:timer.sleep 1000

		sorted_pid_N_map |> Enum.with_index |>  Enum.each(fn { _ , i} ->
				
				IO.puts "#{i+1}, #{map_size(sorted_pid_N_map)}"

				pid = elem(Enum.at(sorted_pid_N_list, i),0)
				current_N = elem(Enum.at(sorted_pid_N_list, i),1)
				predecessor = 
					if i-1 >= 0 do
						elem(Enum.at(sorted_pid_N_list, i-1),1)
					else
						elem(Enum.at(sorted_pid_N_list, map_size(sorted_pid_N_map)-1),1)
					end
				IO.puts "current_pid = #{inspect pid}, current_N=#{current_N}, p=#{predecessor}"
				ChordNodeCoordinator.set_predecessor pid, predecessor
		end)
	end

	def node_join(m, pid_N_map) do
		
		IO.puts "Joining node to chord ring..."
		enter_ring_node = elem(Enum.at(pid_N_map,0) ,1)
		new_node = get_new_node m, pid_N_map
		{:ok, new_pid} = AppSupervisor.start_node new_node
		pid_N_map = Map.put pid_N_map, new_pid, new_node
		IO.puts "New pid_N_map is #{inspect pid_N_map}, new_pid=#{inspect new_pid}, new_node=#{inspect new_node}"
		IO.puts "-----------------------New node joining is #{inspect new_node}-------------------------"

		ChordNodeCoordinator.join enter_ring_node, new_node
		# :timer.sleep 2000
		printSuccessors pid_N_map
		printPredecessors pid_N_map
		printFingerTables pid_N_map
		{new_pid, new_node}
	end

	defp get_new_node(m, pid_N_map) do
		new_node = HashGenerator.hash(m, Integer.to_string(Enum.random 1..(:math.pow(m, 5) |> Kernel.trunc)))
				   |>Integer.to_string|>String.to_atom

		if Enum.member? Map.values(pid_N_map), new_node do
			get_new_node m, pid_N_map
		else
			new_node 
		end  
	end

	defp get_random_node(pid_N_map) do
				
		random_leaving_node_pid = AppSupervisor.get_random_child
		if !Enum.member? Map.keys(pid_N_map), random_leaving_node_pid do
			get_random_node pid_N_map
		else
			random_leaving_node = Map.get pid_N_map, random_leaving_node_pid
			if random_leaving_node == :nil do
				get_random_node pid_N_map
			else
				{random_leaving_node, random_leaving_node_pid}
			end
		end 
	end

	def node_leave(pid_N_map) do
		
		IO.puts "leaving node from chord ring..."
		{random_leaving_node, random_leaving_node_pid} = get_random_node(pid_N_map)
		IO.puts "Random node leaving is #{inspect random_leaving_node}"
		pid_N_map = Map.delete pid_N_map, random_leaving_node_pid
		IO.puts "New pid_N_map is #{inspect pid_N_map}, random_leaving_node=#{inspect random_leaving_node}"
		ChordNodeCoordinator.leave random_leaving_node
		# :timer.sleep 2000
		printSuccessors pid_N_map
		printPredecessors pid_N_map
		printFingerTables pid_N_map
		{random_leaving_node_pid, random_leaving_node}
	end

	#Prints all the keys stored in all the nodes in the chord ring as %{node, [keys..]}
	def printKeys(pid_N_map) do
		
		pids = Map.keys pid_N_map
		pid_keys_map = 
				Enum.reduce pids, %{}, fn pid, acc ->
					keys = ChordNodeCoordinator.get_keys pid
					node = Map.get pid_N_map, pid
					Map.put acc, node, keys
				end
		IO.inspect "keys ========== #{inspect pid_keys_map, charlists: :as_lists}"

	end

	#Prints all the fingertables stored in all the nodes in the chord ring as %{node, fingertable}
	def printFingerTables(pid_N_map) do
		
		pids = Map.keys pid_N_map
		pid_fingertable_map = 
				Enum.reduce pids, %{}, fn pid, acc ->
					fingertables = ChordNodeCoordinator.get_fingertable pid
					node = Map.get pid_N_map, pid
					Map.put acc, node, fingertables
				end
		IO.inspect pid_fingertable_map
	end

	#Prints all the successors stored in all the nodes in the chord ring as %{node, successor}
	def printSuccessors(pid_N_map) do
		
		pids = Map.keys pid_N_map
		# IO.inspect "#{inspect pid_N_map}"
		pid_successors_map = 
				Enum.reduce pids, %{}, fn pid, acc ->
					successor = ChordNodeCoordinator.get_successor pid
					# IO.puts "pids === #{inspect pid}"
					node = Map.get pid_N_map, pid
					# IO.puts "node = #{node}, succ = #{successor}"
					Map.put acc, node, successor
				end
		IO.inspect "successors_map = #{inspect pid_successors_map}"

	end

	#Prints all the predecessors stored in all the nodes in the chord ring as %{node, predecessor}
	def printPredecessors(pid_N_map) do
		
		pids = Map.keys pid_N_map
		# IO.inspect "#{inspect pid_N_map}"
		pid_predecessors_map = 
				Enum.reduce pids, %{}, fn pid, acc ->
					predecessor = ChordNodeCoordinator.get_predecessor pid
					# IO.puts "pids === #{inspect pid}"
					node = Map.get pid_N_map, pid
					# IO.puts "node = #{node}, pred = #{predecessor}"
					Map.put acc, node, predecessor
				end
		IO.inspect "predecessors_map = #{inspect pid_predecessors_map}"

	end
	end

	# ChordOperations.initializeSuccessors(%{a: 3, b: 2, c: 1})