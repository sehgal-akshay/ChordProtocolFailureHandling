		defmodule ChordStabilizer do

			@m 20

			use GenServer

			def start_link do
				GenServer.start_link(__MODULE__, [], name: :chord_stabilizer)
			end

			def init(_) do
				IO.puts "ChordStabilizer is starting" 
		    	{:ok, :ok}
			end

			def handle_cast({:stabilize, current_node}, state) do

				successor = ChordNodeCoordinator.get_successor current_node
				successor_predecessor = ChordNodeCoordinator.get_predecessor(successor)
				
				if successor_predecessor == current_node do
					if successor != nil do
						ChordStabilizerCoordinator.stabilize successor
					end
				else
					if successor_predecessor == :nil do
						
						IO.puts "Stabilizer : A node has left"
						ChordNodeCoordinator.set_predecessor successor, current_node

					else

						IO.puts "Stabilizer : A new node has joined"
						IO.puts "Stabilizing at node #{inspect current_node} to successor_predecessor = #{inspect successor_predecessor}, successor = #{inspect successor}}"

						ChordNodeCoordinator.set_successor current_node, successor_predecessor
						ChordNodeCoordinator.set_predecessor successor_predecessor, current_node
						# fix_finger current_node, AppSupervisor.get_child_count
						
						#Continue stabilization after the fix
						ChordStabilizerCoordinator.stabilize successor_predecessor

					end
				end
			    {:noreply, state}
			end

			def handle_cast({:fix_finger, current_node}, state) do

				FingerTable.fix_finger current_node, @m
				successor = ChordNodeCoordinator.get_successor current_node

				#Continue fix_finger after the stabilizer is complete
				ChordStabilizerCoordinator.fix_finger successor
			    {:noreply, state}
			end
			
			# defp fix_finger(current_node, k) do 

			# 	FingerTable.fix_finger current_node, @m
			# 	successor = ChordNodeCoordinator.get_successor current_node

			# 	IO.puts "Fix_Finger at node #{inspect current_node}, successor = #{inspect successor}}"

			# 	if k>1 do
			# 		#Continue fix_finger after the fix
			# 		fix_finger successor, k-1
			# 	end
			# end

			def start(start_node) do
				
				IO.puts "Stabilizer is running ....."
				Supervisor.start_child(:stabilizer_supervisor, [])
				#Starts stabilization at a random node 
				ChordStabilizerCoordinator.stabilize start_node
				ChordStabilizerCoordinator.fix_finger start_node
			end
		end

		defmodule ChordStabilizerCoordinator do

			def stabilize(start_node) do
				GenServer.cast(:chord_stabilizer, {:stabilize, start_node})
			end

			def fix_finger(start_node) do
				GenServer.cast(:chord_stabilizer, {:fix_finger, start_node})
			end
		end
