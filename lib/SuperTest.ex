# defmodule AppSupervisor do

#   	# This is the supervisor that coordinates the work among all the workers (chordNodes)
  	
# 	use Supervisor

# 	def start_link() do
# 		Supervisor.start_link(__MODULE__, [], name: :ChordSupervisor)
# 	end

# 	def start_node(name) do
# 		 Supervisor.start_child(:ChordSupervisor, [name])
# 	end
	
# 	def get_random_child do
# 		Enum.random Supervisor.which_children(:ChordSupervisor) |> Enum.map( fn item -> elem(item, 1) end)
# 	end

# 	def init([]) do
# 		children = [
# 			worker(ChordNode, [], [restart: :temporary]),
# 		]
# 		supervise(children, strategy: :simple_one_for_one)
# 	end
# end
# defmodule ChordNode do
# 	use GenServer

# 	def start_link(name \\ nil) do
# 		GenServer.start_link(__MODULE__, nil, [name: name])
# 	end

# 	def init(_) do
# 		IO.puts "ChordNode is starting" 
# 		state = %{:keys => [], :successor => nil, :predecessor => nil, :fingertable => %{}}
#     	{:ok, state}
# 	end
# end



# AppSupervisor.start_link
# Enum.map(1..5, fn i -> AppSupervisor.start_node i|>Integer.to_string|>String.to_atom end)
# IO.inspect AppSupervisor.get_random_child
# IO.inspect Supervisor.which_children :ChordSupervisor
# :timer.sleep 5000


# defmodule Testc do
	
# 	def test do
# 		try do
# 			3/0
# 		rescue
# 			e in ArithmeticError -> IO.puts("An error occurred: " <> e.message)
# 		after
# 			IO.puts "The end!"
# 		 end
# 		 IO.puts "working fine"
# 	end

# end

# Testc.test