defmodule ChordNode do
	use GenServer

	def start_link(name \\ nil) do
		GenServer.start_link(__MODULE__, nil, [name: name])
	end

	def init(_) do
		IO.puts "ChordNode is starting" 
		state = %{:keys => [], :successor => nil, :predecessor => nil, :fingertable => %{}}
    	{:ok, state}
	end

	def handle_call(:stop, _, state) do
	    {:stop, :normal, state}
	end 

	def handle_call(:get_fingertable, _, state) do
		fingertable = Map.get(state, :fingertable)
	    {:reply, fingertable, state}
	end

	def handle_call(:get_successor, _, state) do
		successor = Map.get(state, :successor)
	    {:reply, successor, state}
	end

	def handle_call(:get_predecessor, _, state) do
		predecessor = Map.get(state, :predecessor)
	    {:reply, predecessor, state}
	end

	def handle_call(:get_keys, _, state) do
		keys = Map.get(state, :keys)
	    {:reply, keys, state}
	end


	def handle_call({:find_successor, search_node, current_node}, _, state) do 
		
		successor = Map.get(state, :successor)
		# IO.puts "successor -- #{successor}, current_node -- #{current_node},search_node -- #{search_node}"
		fingertable = Map.get(state, :fingertable)
		nodes = Enum.sort(Map.values fingertable)

		search_node_i = search_node |> Atom.to_string |> String.to_integer
		current_node_i = current_node |> Atom.to_string |> String.to_integer
		successor_i = successor |> Atom.to_string |> String.to_integer

		nodes_lesser = Enum.filter(nodes, fn x -> x |> Atom.to_string |> String.to_integer <= search_node_i 
										end)

		search_result =

			if search_node_i == current_node_i do
				current_node
			else
				if ((search_node_i > current_node_i && search_node_i <= successor_i) || 
					(current_node_i > successor_i && (search_node_i >= current_node_i || search_node_i <= successor_i) )) do
					
					successor
				else
					if length(nodes_lesser) != 0 do

						nodes_lesser_i = Enum.map nodes_lesser, fn x -> String.to_integer Atom.to_string x end
						max_lesser_node = Enum.max(nodes_lesser_i) |> Integer.to_string |> String.to_atom
						# IO.puts "Found max_lesser_node = #{max_lesser_node} at current_node = #{current_node}, search_node == #{search_node}, successor = #{successor}, fingertable = #{inspect fingertable}"
						if GenServer.whereis(max_lesser_node) != :nil do
							ChordNodeCoordinator.find_successor(max_lesser_node, search_node)
						else
							IO.puts "max_lesser_node = #{max_lesser_node} no longer exists. It is dead/left."
							:nil
						end
					else 	
							#Send key to successor list
							# IO.puts "Sending to successor, search_node == #{search_node}, successor = #{successor}"
							pid_existing_node = GenServer.whereis(successor)
							if pid_existing_node != :nil do
								ChordNodeCoordinator.find_successor(successor, search_node)
							else
								IO.puts "successor = #{successor} no longer exists. It is dead/left."
								:nil
							end
					end
				end
			end

	    {:reply, search_result , state}
	end

	def handle_call({:leave, leaving_node}, _, state) do

		###### leaving_node is the current node ########
		successor = Map.get(state, :successor)
		predecessor = Map.get(state, :predecessor)
		# IO.inspect "fingertable = #{inspect fingertable} at #{inspect self()} for key #{inspect key}"

		IO.puts "Node is leaving, leaving_node == #{leaving_node}, successor = #{successor}"
			
		ChordNodeCoordinator.set_successor(predecessor, successor)
		ChordNodeCoordinator.set_predecessor(successor, :nil)

		keys = Map.get state, :keys
		
		if keys != :nil && length(keys) != 0 do
			
			IO.puts "Moving keys to successor. Transfering keys=#{inspect keys} since node #{leaving_node} is leaving ..."
			ChordNodeCoordinator.transfer_keys successor, keys
		end
		#Set fields of leaving_node to :nil -> Equivalent to leaving the ring
		# ChordNodeCoordinator.set_successor(leaving_node, :nil)
		# ChordNodeCoordinator.set_predecessor(leaving_node, :nil)
		IO.puts ">>>>>>>> #{inspect leaving_node} terminated"
		# terminate()
		AppSupervisor.terminate_child(leaving_node)
		# ChordStabilizerCoordinator.stop leaving_node
		{:reply, state, state}
	end

	def handle_cast({:set_successor, successor}, state) do
		new_state = Map.put(state, :successor, successor)
		#Update the first entry in the fingertable which is the successor
		fingertable = Map.get(new_state, :fingertable)
		fingertable = Map.put(fingertable, 0, successor)
		new_state = Map.put(new_state, :fingertable, fingertable)
	    {:noreply, new_state}
	end

	def handle_cast({:set_predecessor, predecessor}, state) do
		new_state = Map.put(state, :predecessor, predecessor)
	    {:noreply, new_state}
	end

	def handle_cast({:set_fingertable, fingertable}, state) do
		new_state = Map.put(state, :fingertable, fingertable)
	    {:noreply, new_state}
	end

	def handle_cast({:add_key, key}, state) do
		IO.puts "Adding key .."
		new_state = Map.put(state, :keys, Enum.concat(Map.get(state, :keys), [key]))
		{:noreply, new_state}
	end

	def handle_cast({:store_key, key, current_N}, state) do

		successor = Map.get(state, :successor)
		fingertable = Map.get(state, :fingertable)
		# IO.inspect "fingertable = #{inspect fingertable} at current_N=#{inspect current_N} for key=#{inspect key}"

		#All the nodes in the fingertable
		nodes = Enum.sort(Map.values fingertable)

		key_i = key |> Atom.to_string |> String.to_integer
		current_N_i = current_N |> Atom.to_string |> String.to_integer
		successor_i = successor |> Atom.to_string |> String.to_integer

		nodes_lesser = Enum.filter(nodes, fn x -> x |> Atom.to_string |> String.to_integer <= key_i 
										end)

		if (key_i == current_N_i) do
			
			IO.puts "Adding to keys list, key == #{key}, successor = #{successor}"
			ChordNodeCoordinator.add_key(current_N, key)	
		else

			if ((key_i > current_N_i && key_i <= successor_i) || 
				(current_N_i > successor_i && (key_i >= current_N_i || key_i <= successor_i) )) do
					#If there is no max node less than key and key lies with successor, add key to successor list
					IO.puts "Adding to keys list, key == #{key}, successor = #{successor}"
					ChordNodeCoordinator.add_key(successor, key)
			else

				#Count the hop
				HopCounter.count
				
				if length(nodes_lesser) != 0 do
						nodes_lesser_i = Enum.map nodes_lesser, fn x -> String.to_integer Atom.to_string x end
						max_lesser_node = Enum.max(nodes_lesser_i) |> Integer.to_string |> String.to_atom
						# IO.puts "Found max_lesser_node = #{max_lesser_node} at current_N = #{current_N}, key == #{key}, successor = #{successor}, fingertable = #{inspect fingertable}"
						ChordNodeCoordinator.store_key(max_lesser_node, key)
				else 
						#Send key to successor list
						# IO.puts "Sending to successor, key == #{key}, successor = #{successor}"
						ChordNodeCoordinator.store_key(successor, key)
				end
			end
		end

		{:noreply, state}
	end

	def handle_cast({:join, new_node, current_N}, state) do

		successor = Map.get(state, :successor)
		fingertable = Map.get(state, :fingertable)
		# IO.inspect "fingertable = #{inspect fingertable} at current_node = #{inspect current_N}"

		#All the nodes in the fingertable
		nodes = Enum.sort(Map.values fingertable)

		# IO.puts "At #{inspect self()}"
		new_node_i = new_node |> Atom.to_string |> String.to_integer
		current_N_i = current_N |> Atom.to_string |> String.to_integer
		successor_i = successor |> Atom.to_string |> String.to_integer

		nodes_lesser = Enum.filter(nodes, fn x -> x |> Atom.to_string |> String.to_integer <= new_node_i 
										end)

		# IO.inspect "fingertable = #{inspect fingertable}, new_node_i = #{inspect new_node_i} , current_node = #{inspect current_N_i}, successor_i = #{successor_i}"
		if ((new_node_i > current_N_i && new_node_i <= successor_i) || 
			(current_N_i > successor_i && (new_node_i >= current_N_i || new_node_i <= successor_i)) ) do
				#If there is no max node less than key and key lies with successor, add key to successor list
				
			IO.puts "Node #{inspect new_node} has joined the ring ..."
			ChordNodeCoordinator.set_successor(new_node, successor)
			ChordNodeCoordinator.set_predecessor(successor, new_node)
			# ChordNodeCoordinator.set_successor(current_N, new_node)
		else
			# IO.puts "Here................. , new_node == #{new_node}, successor = #{successor}"

			if length(nodes_lesser) != 0 do
				nodes_lesser_i = Enum.map nodes_lesser, fn x -> String.to_integer Atom.to_string x end
				max_lesser_node = Enum.max(nodes_lesser_i) |> Integer.to_string |> String.to_atom
				# IO.puts "Found max_lesser_node = #{max_lesser_node} at current_N = #{current_N}, new_node == #{new_node}, successor = #{successor}, fingertable = #{inspect fingertable}"
				ChordNodeCoordinator.join(max_lesser_node, new_node)
			else 
					#Send key to successor list
					# IO.puts "Sending to successor, new_node == #{new_node}, successor = #{successor}"
					ChordNodeCoordinator.join(successor, new_node)
			end
		end

		{:noreply, state}
	end

	def handle_cast({:transfer_keys, keys_transferred}, state) do
		
		keys_current = Map.get state, :keys
		#Update the first entry in the fingertable which is the successor
		keys  = Enum.concat keys_current, keys_transferred
		new_state = Map.put(state, :keys, keys)
	    {:noreply, new_state}
	end

	defp terminate(_ \\ 1) do
	    # IO.inspect :terminating
	    Process.exit self(), :normal
	end
end

defmodule ChordNodeCoordinator do

	def get_successor(nodeN) do
		GenServer.call(nodeN, :get_successor)
	end

	def get_predecessor(nodeN) do
		GenServer.call(nodeN, :get_predecessor)
	end

	def get_fingertable(nodeN) do
		GenServer.call(nodeN, :get_fingertable)
	end

	def set_fingertable(nodeN, fingertable) do
		GenServer.cast(nodeN, {:set_fingertable,fingertable})
	end

	def set_predecessor(nodeN, predecessor) do
		IO.inspect "setting #{inspect predecessor} as predecessor to nodeN #{inspect nodeN}"
		GenServer.cast(nodeN, {:set_predecessor, predecessor})
	end

	def set_successor(nodeN, successor) do
		IO.inspect "setting #{inspect successor} as successor to nodeN #{inspect nodeN}"
		GenServer.cast(nodeN, {:set_successor, successor})
	end

	def get_keys(nodeN) do
		GenServer.call(nodeN, :get_keys)
	end

	def find_successor(start_node, search_node) do
		if GenServer.whereis(start_node) != :nil do
			# IO.puts "start_node = #{inspect start_node} found in GenServer"
			GenServer.call(start_node, {:find_successor, search_node, start_node})
		else
			:nil
		end
	end

	#Just adds the key to the node's key list
	def add_key(nodeN, key) do
		GenServer.cast(nodeN, {:add_key, key})
	end

	#Transfers list of keys to nodeN
	def transfer_keys(nodeN, keys) do
		GenServer.cast(nodeN, {:transfer_keys, keys})
	end

	#Store key is uses chord algorithm to store the key in the correct node
	def store_key(start_node, key) do
		GenServer.cast(start_node, {:store_key, key, start_node})
	end

	#Join is used to join a new node to the chord ring
	def join(start_node, new_node) do
		GenServer.cast(start_node, {:join, new_node, start_node})
	end

	#Join is used to exit a given node from the chord ring
	def leave(leaving_node) do
		GenServer.call(leaving_node, {:leave, leaving_node})
	end
end
