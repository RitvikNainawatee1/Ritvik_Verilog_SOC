# Week 6 - Multi-Cycle CPU Design

## Objective

Design and implement a simplified CPU capable of executing a bubble sort algorithm. Your processor should be able to read an unsorted array from memory, sort it, and write the sorted array back into the memory. 
In the last week, the ISA and the hardware architecture were directly given to you, and most of the time was spent on the implementation part. This week, you will have to use the processor that you built in week 5 as a reference and modify it into a multicycle CPU.   


---
## Some General Instructions
Theory:  
First read 5.5 in the textbook and understand how the instructions are divided into various stages of execution, and also see how the data flows for each stage of an instruction.

Implementation:  
The two major parts that you need to fully redesign are the datapath and the control unit. All other components, like the decoder, ALU, register bank, etc., can be reused.

Read up on how the hardware is modified, and based on that, you have to design the hardware yourself (or you can use the one that is provided), and then move on to the control unit.  
Note: I would suggest that you design the hardware yourself, but if it's too much, you can refer to or use the one provided in the next section.  

The control unit will turn out to be an FSM. You will have to carefully keep track of what control signals (c1,c2,..) you are enabling in each instruction cycle.
It's really easy to make errors while making the control unit, so be careful.
## Architectural Overview(This is only for your reference and you may change it if you so wish)
<img width="1280" height="940" alt="photo_6192518061542281223_y" src="https://github.com/user-attachments/assets/0d128c30-fc89-42e0-9795-6707b9e77341" />
---

## References

Refer to the single cycle cpu . The ISA is the same.

Also read section 5.5 in david_patterson.pdf text.

i281 Simulator - https://www.ece.iastate.edu/~alexs/classes/i281_simulator/index.html

---

## Submission Guidelines

Push all the Verilog design files along with the screenshots of simulation waveforms showing register file contents and data memory contents.
