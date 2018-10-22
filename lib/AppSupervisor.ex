defmodule AppSupervisor do

  	# This is the supervisor that coordinates the work among all the workers (chordNodes)
  	
	use Supervisor

	def start_link() do
		Supervisor.start_link(__MODULE__, [], name: :chord_supervisor)
	end
	
	def start_node(name) do
		 Supervisor.start_child(:chord_supervisor, [name])
	end

	def init([]) do
		children = [
			worker(ChordNode, [], [restart: :temporary]),
		]
		supervise(children, strategy: :simple_one_for_one)
	end

	#To get a random child from the supervisor
	def get_random_child do
		
		Enum.random Supervisor.which_children(:chord_supervisor) |> Enum.map( fn item -> elem(item, 1) end)
	end

	def terminate_child(child) do
		
		Supervisor.terminate_child(:chord_supervisor, child)
	end

	def get_child_count do
		
		length Supervisor.which_children(:chord_supervisor)
	end

	defmodule StabilizerSupervisor do
		
		use Supervisor

		def start_link() do
			Supervisor.start_link(__MODULE__, [], name: :stabilizer_supervisor)
		end
		
		def init([]) do
			children = [
				worker(ChordStabilizer, [], [restart: :temporary]),
			]
			supervise(children, strategy: :simple_one_for_one)
		end

	end

	defmodule HopCounterSupervisor do
		
		use Supervisor

		def start_link() do
			Supervisor.start_link(__MODULE__, [], name: :hopcounter_supervisor)
		end
		
		def init([]) do
			children = [
				worker(HopCounter, [], [restart: :temporary]),
			]
			supervise(children, strategy: :simple_one_for_one)
		end

		def start_node do
		 	Supervisor.start_child(:hopcounter_supervisor, [:hopcounter])
		end
	end

end

