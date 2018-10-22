defmodule HashGenerator do
	def hash(m, hash_string) do
		do_hash(m, hash_string)
	end	

	def do_hash(m, hash_string) do
		hashed = :crypto.hash(:sha, hash_string) |> binary_part(0, 8) |> :binary.bin_to_list
		int_hashed = Convert.binary_list_to_integer hashed
		base = :math.pow(2, m) |> Kernel.trunc
		rem(int_hashed, base)
	end

end

defmodule Math do
    def pow(num, power) do
        do_pow num, power, 1
    end
    defp do_pow(_num, 0, acc) do
        acc
    end
    defp do_pow(num, power, acc) when power > 0 do
        do_pow(num, power - 1, acc * num)
    end
end

defmodule Convert do
    def binary_list_to_integer (list) do         
        do_binary_list_to_integer Enum.reverse(list), 0, 0
    end
    defp do_binary_list_to_integer([], _power, acc) do
        acc
    end
    defp do_binary_list_to_integer([head | tail], power, acc) do
        do_binary_list_to_integer tail, (power+1), (acc + (head*Math.pow(2, power)))
    end
end

# pid = Kernel.inspect self()
# IO.puts String.slice pid, 5..String.length(pid)-2
# IO.puts HashGenerator.hash(3, Kernel.inspect self())
