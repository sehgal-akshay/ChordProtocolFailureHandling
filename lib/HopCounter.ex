defmodule HopCounter do
	use GenServer

	def start_link(name \\ nil) do
		GenServer.start_link(__MODULE__, nil, [name: name])
	end

	def init(_) do
		IO.puts "HopCounter is starting" 
		state = %{:counter => 0}
    	{:ok, state}
	end

	def handle_call(:get_count, _, state) do

		count = Map.get state, :counter

	    {:reply, count, state}
	end

	def handle_cast(:count, state) do

		current_count = Map.get state, :counter
		new_state = Map.put state, :counter, current_count+1

	    {:noreply, new_state}
	end

	def count do
		
		GenServer.cast(:hopcounter, :count)
	end

	def getcount do

		GenServer.call(:hopcounter, :get_count)
	end

	def print_hop_statistics(number_of_keys) do
		
		IO.puts "

			Total hop count   ===== #{inspect getcount()}
			Total number of keys == #{inspect number_of_keys}
			Average hop count ===== #{inspect getcount()/number_of_keys}
		"
	end
end