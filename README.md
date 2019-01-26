# ChordProtocolFailureHandling

Reference : https://pdos.csail.mit.edu/papers/ton:chord/paper-ton.pdf, www.github.com/aswinsureshk/chordprotocol

The aim is to handle any node failure that may occur in the www.github.com/aswinsureshk/chordprotocol project.

Looking to simulate the solution proposed in the paper "Chord: A Scalable Peer-to-peer Lookup Protocol
for Internet Applications" by Ion Stoica, Robert Morris, David Liben-Nowell, David R. Karger, M. Frans Kaashoek, Frank Dabek, Hari Balakrishnan in Elixir and using the GenServer Supervisor Design model.

Defined Abstract : 

A fundamental problem that confronts peer-to-peer applications is the
efficient location of the node that stores a desired data item. This paper
presents Chord, a distributed lookup protocol that addresses this problem.
Chord provides support for just one operation: given a key, it maps the
key onto a node. Data location can be easily implemented on top of Chord
by associating a key with each data item, and storing the key/data pair at
the node to which the key maps. Chord adapts efficiently as nodes join
and leave the system, and can answer queries even if the system is continuously
changing. Results from theoretical analysis and simulations show
that Chord is scalable: communication cost and the state maintained by
each node scale logarithmically with the number of Chord nodes

Title : FailureHandling of Chord Protocol

Command to Start : mix run lib/Initializer.ex 25 3 10

25 - numNodes
3  - numRequests
10 - leaveNodes

Maximum value tested : numNodes = 2000, m = 20. Time taken 1.30s.

Note : Default m-value (fingertable size) is 20. It should be changed at the top of Initializer.ex and ChordStabilizer.ex files @m 20.

Implementation/Working
----------------------

Here we initialize the ring with 2 Nodes and do a join() for the remaining 25-2 = 23 nodes. 
Each node sends numRequests number of requests concurrently at an interval of 1 ms. Each node will get a key from the HashGenerator and will perform a store_key() operation. 

After that the program calculates the hop count and leave_node() is called leaveNodes number of times. Hence a total of leaveNodes number of nodes will leave the ring. At an application level, the node leaving will do a "notify" which does the following :

1. Ask the predecessor to update its successor to the leaving node's parent.
2. Ask the successor to update its predecessor to :nil.
3. Tranfer its keys (if present) to its successor.
4. The leaving node terminates by asking the AppSupervisor to terminate this child.

The ChordNode module (each node in the ring) will handle this leaving scenario by returning a :nil to the caller of find_successor() if if the successor at any point is not alive.

The ChordStabilizer module will handle this time-out issue that it may face while concurrent calculation of fixfinger entries if this leaving node is present in the fingertable of other nodes by checking if it has received a :nil from find_successor() or not. The fixfinger will automatically get corrected after a while when stabilize gets completed.

Before exit, we see that the ring size has reduced by leaveNodes times (as this info is fetched via the ChordOperations), and the finger tables of all the nodes are corrected, and all the nodes are stabilized.

The module explanations are given below : 

AppSupervisor.ex -> The Supervisors in the application. There are three supervisors. AppSupervisor is the supervisor which manages the ChordNodes which correspond to each node in the ring. StabilizerSupervisor is the supervisor which manages the ChordStabilizer. HopCountSupervisor is the supervisor which manages the supervisor module which manages the HopCounter module.

ChordNode.ex -> The Genserver node module which correspond to each node in the ring.

ChordStabilizer.ex -> This is the stabilizer module which does the stabilize and fixfinger operations. The ChordStabilizer is a separate Genserver which runs in concurrent mode with respect to the nodes. Whenever a node is found to be unstabilized, the stabilizer will stabilize the node. The fixfinger works at all times modifying the fingertables of all the nodes in the ring. It does a calculation of val = [n + :math.pow(2*i)] mod(2*m), when n is the current node value and m is the m-value and i is the ith element in the fingertable. Then we call a result = find_successor(val) to get the correct node value for the fingertable entry. The find_successor is a chain call to the consecutive the node in the ring until the result is found.

FingerTable.ex -> This module handles the fingertable operations like generate and fixfinger.

Initializer.ex -> This is the entry module where user input is taken and the ring is created via the join(), ChordNode and ChordStabilizer modules are initiated and numRequest requests are created from each node at a burst interval of 1ms.

HopCounter.ex -> This module handles the hopcount operations. Whenever a hop is made, a signal is sent to the HopCounter which will increment the counter and hence total hop count is calculated. this module will calculate the average hops as well.

HashGenerator.ex -> This module is responsible for hashing where it will do an sha-has on the range 0 to :math.pow(2, m) where m is the m-value.

ChordOperations.ex -> This module is responsible for all the operations that can be performed on the nodes in the ring like store_key, print etc. This is just an interface to interact with the ring. It will trigger a call/cast on one of the node in the ring at random to do its task. 

KeyGen.ex -> This is a key generator module.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `project3` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:project3, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/project3](https://hexdocs.pm/project3).

