Title : Implementation of Chord Protocol

Command to Start : mix run lib/Initializer.ex 25 3

25 - numNodes
3  - numRequests

Maximum value tested : numNodes = 2000, m = 20. Time taken 1.30s.

Note : Default m-value (fingertable size) is 20. It should be changed at the top of Initializer.ex and ChordStabilizer.ex files @m 20.

Implementation/Working
----------------------

Here we initialize the ring with 2 Nodes and do a join() for the remaining 25-2 = 23 nodes. 
Each node sends numRequests number of requests at an interval of 1 ms. Each node will get a key from the HashGenerator and will perform a store_key() operation. After that the program calculates the hop count and exits.

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

