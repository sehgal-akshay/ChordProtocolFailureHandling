defmodule KeyGen do
	
	@val 10000
	
	#Accepts number of keys to generate, m value
	#Returns hashed value for random pid in range 1<=x<=@val
	def generateKeys(numKeys, m) do
		
		
		Enum.map(1..numKeys, fn _-> 
					rand_num = :rand.uniform(@val)
					rand_pid = :c.pid(0, rand_num, 0)
					do_hash_pid(rand_pid, m) |> Integer.to_string |> String.to_atom
					end)

	end

	#Hashes the given pid
	defp do_hash_pid(pid, m) do

		HashGenerator.hash(m, Kernel.inspect pid)	
	end

	
end

# IO.inspect KeyGen.generateKeys(10, 8)