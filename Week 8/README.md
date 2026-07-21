# Making the Pipelined Processor

The pipelined processor is closer to the single-cycle implementation than the multicycle one in the sense that the control is not really a finite state machine
So, try modifying the single-cycle data path and control, and I have provided the code snippets to make your life easier, but if it's confusing, ask me anytime.

# Step 1: Modifying the data-path
Split the datapath into 5 different stages: IF|ID|EX|MEM|WB 
Now add the pipeline registers and try to follow a naming convention, for example, IF_ID_RX_out for the output of the RX field register stored between IF and ID stages. Being verbose will help you while writing the code and debugging

This is the modified data path 
<img width="1280" height="686" alt="photo_6251273510504304945_y" src="https://github.com/user-attachments/assets/400a2162-e736-4905-a72f-b85187c61fec" />

Some major changes made to the data path are as follows
### Pipeline Registers
*there will be a lot of them  
Every meaningful or useful output from one stage is stored in pipeline registers for use by the next stage, similar to the multi-cycle implementation. This includes instruction fields, operands, ALU outputs, immediates, PC values, and eventually control signals. You can take care of control signals later; first, make the data path properly. 
The inputs to the registers write select are permanently fixed to RX and RY, respectively, for registers 1 and 2;

### Swap block
Without this block, data forwarding will become complicated 
This block is to correct for the fact that in the original single-cycle control unit, for instructions MOVEE, STORE, STOREF, and LOAD, the register fields used for register 1 and register 2 are swapped  
The swap_en signal is asserted when an instruction is one of the 4 instructions  
This way, data forwarding will be the same as the one mentioned in Hennessy and Patterson 

### PC update logic
Branch condition calculation is done in the ID stage, and the new pc is calculated in the EXE stage

# Step 2: Control unit
As mentioned earlier, the swap_en signal has to be added to the list of outputs to the control unit, and that's about it
You don't have to change the control_unit.v file much 
Next, start making pipeline registers.

# Step 3: Handling Data Hazards
## Data Forwarding
Refer to h&p for the theory 
This is a direct implementation of the data forwarding mentioned in h&p 
```verilog
  reg [7:0] ID_EX_reg1_forw, ID_EX_reg2_forw; // these are the outputs after compensating for data forwarding
  always@(*) begin
    ID_EX_reg1_forw = ID_EX_reg1_out;
	 ID_EX_reg2_forw = ID_EX_reg2_out;
    if(EX_MEM_c[10]) begin //checking if reg write enable is active
		if({EX_MEM_c[8], EX_MEM_c[9]}==ID_EX_instruction[11:10])
			ID_EX_reg1_forw = EX_result;
		if({EX_MEM_c[8], EX_MEM_c[9]}==ID_EX_instruction[9:8])
			ID_EX_reg2_forw = EX_result;
	 end
	 
	 if(MEM_WB_c[10]) begin
		if({MEM_WB_c[8], MEM_WB_c[9]}==ID_EX_instruction[11:10] && {EX_MEM_c[8], EX_MEM_c[9]}!=ID_EX_instruction[11:10])
			ID_EX_reg1_forw = regfile_inp;
		if({MEM_WB_c[8], MEM_WB_c[9]}==ID_EX_instruction[9:8] && {EX_MEM_c[8], EX_MEM_c[9]}!=ID_EX_instruction[9:8])
			ID_EX_reg2_forw = regfile_inp;
	 end
  end
```
Modify this thing with your variable names.  
The swap module will be instantiated after this, taking in ID_EX_reg1_forw, ID_EX_reg2_forw as inputs  
## Data Stalls for load-use and flag-use cases
```verilog
  reg data_stall; //for stall cycle
  always@(*) begin
		data_stall=0;
		if(ID_EX_c[17]) begin
			if(ID_EX_instruction[11:10]==IF_ID_instruction[11:10] || ID_EX_instruction[11:10]==IF_ID_instruction[9:8]) begin
				data_stall =1;
			end
		end
		if ( (IF_ID_instruction[15:13]==4'b111) && ID_EX_c[14]) begin //this takes care of the data stalling for when flags are to be used for a branch instruction, when they are not ready
          data_stall = 1;
      end
  end
```
Instead of stalling for the flags to be ready, you can also try data forwarding if you so wish but its not required for the submission 
You have to disable the enable for pc register and the IF/ID pipeline registers during a stall, i.e., the enable signal will be !data_stall 
And flush the ID/EX pipeline register outputs, i.e., make them zero 
# Step 4: Handling Control Hazards
There are many schemes implemented here, but we will be using static branch prediction, branch-not-taken, to be precise 
You can do dynamic branch prediction if you are brave enough to complete it before the deadline, or after the SoC is done as well 

You have to flush the pipeline registers and pc registers accordingly if a branch is taken 
ID_EX_c[2] will determine if a branch is taken 
ID_EX_c[2]) ? pc_branch : pc_seq will be the input to pc register
IF/ID and ID/EX pipeline registers are flushed if ID_EX_c[2] is asserted 
example: 
(data_stall||ID_EX_c[2])? 19'b0 :c will be the input for the ID/EX pipeline register for control signals, taking the stall and control hazard into account

# Step 5: Debug
Run the bubble sort routine and try to check for the pc register, in particular, if there are any issues
# Step 6: Submission
Submit the screenshot of the testbench showing that the array is sorted or the waveform showing that the array is sorted, and all the project files in the Week 8 folder, and we are done

<img width="320" height="320" alt="годжо" src="https://github.com/user-attachments/assets/1664eaf1-54a3-4d4e-a8b5-1edfa035ddcf" />











