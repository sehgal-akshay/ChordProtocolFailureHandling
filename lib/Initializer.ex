		defmodule Initalizer do

			@m 20

			def start do
				args = System.argv()
			    numNodes = String.to_integer(Enum.at(args, 0))     
			    numRequests = String.to_integer(Enum.at(args, 1))  
			    leaveNodes = String.to_integer(Enum.at(args, 2))        
			    
			    IO.puts "

			    #########################################

			    		numNodes    : #{numNodes}
			    		numRequests : #{numRequests}
			    		leaveNodes  : #{leaveNodes}
			    		m           : #{@m}

			    #########################################
			    "
			    :timer.sleep 1000
			    if numNodes > :math.pow(2, @m) |> Kernel.trunc do
			    	
			    	IO.puts "numNodes is greater than :math.pow(2, m). Please enter numNodes in the range 0 to #{:math.pow(2, @m)}"
					System.halt		    
			    end
			    IO.puts "Initializing chord with 2 Nodes and joining #{numNodes-2} nodes and starting #{numRequests}"
			    :timer.sleep 1000
			    __init__ numNodes, numRequests, leaveNodes   
			end

			defp __init__(numNodes, numRequests, leaveNodes) do

				AppSupervisor.start_link
				__init__hopcounter__()
				initNnodes numNodes, numRequests,leaveNodes
			end

			#Initializing the hop counter
			defp __init__hopcounter__ do
				
				AppSupervisor.HopCounterSupervisor.start_link
				AppSupervisor.HopCounterSupervisor.start_node
			end

			#Initializing the stabilizer supervisor
			defp __init__stabilizer__ (pid_N_map) do
				
				AppSupervisor.StabilizerSupervisor.start_link
				ChordStabilizer.start elem(Enum.at(pid_N_map,0) ,1)
			end

			#Initializing numNodes in one go
			defp initNnodes(numNodes, numRequests, leaveNodes) do
				
				#Initialize with 2 nodes

				n_values = Enum.map(1..2, fn i -> HashGenerator.hash(@m, Integer.to_string i)|>Integer.to_string|>String.to_atom  end)
				pid_N_map = Enum.reduce(n_values, %{}, fn n_value, acc -> 
								res = AppSupervisor.start_node n_value 
								Map.put acc, elem(res ,1), n_value
							end)
				pid_N_map = generateRing pid_N_map
				ChordOperations.initializeSuccessors pid_N_map
				ChordOperations.initializePredecessors pid_N_map
				ChordOperations.printFingerTables pid_N_map
				__init__stabilizer__ pid_N_map
				# Generate numNodes*2 number of keys
				# ChordOperations.printFingerTables pid_N_map
				# Join the remaining numNodes-2 to the chord ring 
				pid_N_map = Enum.reduce(1..numNodes-2, pid_N_map, fn _, acc -> 
						    {a, b} = ChordOperations.node_join @m, acc 
					        Map.put acc, a, b
						    end)
				
				# :timer.sleep numNodes*1000
				# generateStorePrintKeys numNodes*2, pid_N_map
				init_program numRequests, pid_N_map
				:timer.sleep 3000
				pid_N_map = Enum.reduce(1..leaveNodes, pid_N_map, fn _, acc -> 
						    {a, _} = ChordOperations.node_leave acc 
					        Map.delete acc, a
						    end)
			    IO.puts "Final pid_N_map = #{inspect pid_N_map}, Final ring size = #{map_size pid_N_map}"
			end

			defp generateRing(pid_N_map) do
				
				FingerTable.generate pid_N_map, @m
				pid_N_map
			end

			defp init_program(numRequests, pid_N_map) do

				Enum.each(1..numRequests, fn _ ->
					Enum.each(pid_N_map, fn {_, node} ->
						keys = KeyGen.generateKeys 1, @m
						ChordOperations.storeKeys keys, node
					end)
					:timer.sleep 1000
					ChordOperations.printKeys pid_N_map
				end)
				HopCounter.print_hop_statistics numRequests*map_size(pid_N_map)
			end
		end
		Initalizer.start

