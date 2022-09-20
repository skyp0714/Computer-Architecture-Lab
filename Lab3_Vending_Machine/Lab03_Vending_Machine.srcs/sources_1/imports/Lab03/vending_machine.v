// Title         : vending_machine.v
// Author      : Hunjun Lee (hunjunlee7515@snu.ac.kr), Suheon Bae (suheon.bae@snu.ac.kr)

`include "vending_machine_def.v"

module vending_machine (

	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)

	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered

	o_available_item,			// Sign of the item availability
	o_output_item,			   // Sign of the item withdrawal
	o_return_coin,			   // Sign of the coin return
	o_current_total
);

	// Ports Declaration
	input clk;
	input reset_n;

	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;

	output reg [`kNumItems-1:0] o_available_item;
	output reg [`kNumItems-1:0] o_output_item;
	output reg [`kReturnCoins-1:0] o_return_coin;
	output reg [`kTotalBits-1:0] o_current_total;

	// Net constant values (prefix kk & CamelCase)
	wire [31:0] kkItemPrice [`kNumItems-1:0];	// Price of each item
	wire [31:0] kkCoinValue [`kNumCoins-1:0];	// Value of each coin
	assign kkItemPrice[0] = 400;
	assign kkItemPrice[1] = 500;
	assign kkItemPrice[2] = 1000;
	assign kkItemPrice[3] = 2000;
	assign kkCoinValue[0] = 100;
	assign kkCoinValue[1] = 500;
	assign kkCoinValue[2] = 1000;

	// Internal states. You may add your own reg variables.
	reg [`kTotalBits-1:0] current_total, next_total; //state containing current/next amount of balance
	reg [`kItemBits-1:0] num_items [`kNumItems-1:0]; //use if needed
	reg [`kCoinBits-1:0] num_coins [`kNumCoins-1:0]; //use if needed
	reg [2:0] c_state, n_state; //state containing information of vending machine functionality
	//3 type of vending machine functionality
	//ready: ready for new inputs, soldx: xth item is sold, change: returns change
	parameter ready = 3'b100, sold0 = 3'b000, sold1 = 3'b001, sold2 = 3'b010, sold3 = 3'b011, change = 3'b111;

	// Combinational circuit for the next states
	//n_state and next_total is evaluated
	always @(*) begin
		casex(c_state)
			ready:begin		//vending machine is ready for the new inputs
				//for default cases
				n_state = ready;
				next_total = current_total;

				if(i_input_coin)begin	//when coin is inserted -> ready state
					case(i_input_coin)
						`kNumCoins'b001:begin
							n_state = ready;
							next_total = current_total + kkCoinValue[0];
						end
						`kNumCoins'b010:begin
							n_state = ready;
							next_total = current_total + kkCoinValue[1];
						end
						`kNumCoins'b100:begin
							n_state = ready;
							next_total = current_total + kkCoinValue[2];
						end
					endcase
				end else if(i_trigger_return) begin		//when return button is pressed -> return state
					n_state = change;
					next_total = current_total;
				end else begin		//when item is selected -> soldx state or ready state
					case(i_select_item)
						`kNumItems'b0001:begin
							if(current_total >= kkItemPrice[0])begin
								n_state = sold0;
								next_total = current_total - kkItemPrice[0];
							end					
						end
						`kNumItems'b0010:begin
							if(current_total >= kkItemPrice[1])begin
								n_state = sold1;
								next_total = current_total - kkItemPrice[1];
							end					
						end
						`kNumItems'b0100:begin
							if(current_total >= kkItemPrice[2])begin
								n_state = sold2;
								next_total = current_total - kkItemPrice[2];
							end					
						end
						`kNumItems'b1000:begin
							if(current_total >= kkItemPrice[3])begin
								n_state = sold3;
								next_total = current_total - kkItemPrice[3];
							end					
						end
					endcase
				end
			end
			3'b0xx: begin //4 sold states: some item is sold
				next_total = current_total;
				if(i_trigger_return)	n_state = change;
				else	n_state = ready;
			end
			change: begin //change is returned in this state
				n_state = ready;
				next_total = `kTotalBits'd0;
			end
		endcase
	end
	// Combinational circuit for the output
	integer i;
	reg [`kTotalBits-1:0] temp_change;
	always @(*) begin
		//for default cases
		o_return_coin = `kReturnCoins'd0;
		o_current_total = current_total;
		o_output_item = `kNumItems'd0;
		if(current_total < kkItemPrice[0])	o_available_item = `kNumItems'b0000;
		else if(current_total < kkItemPrice[1])	o_available_item = `kNumItems'b0001;
		else if(current_total < kkItemPrice[2])	o_available_item = `kNumItems'b0011;
		else if(current_total < kkItemPrice[3])	o_available_item = `kNumItems'b0111;
		else	o_available_item = `kNumItems'b1111;

		case(c_state)	
			//ready state is already covered above
			//sold states: outputs what items are sold
			sold0:	o_output_item = `kNumItems'b0001;
			sold1:	o_output_item = `kNumItems'b0010;
			sold2:	o_output_item = `kNumItems'b0100;
			sold3:	o_output_item = `kNumItems'b1000;
			//change state: evaluate the number of coins
			change: begin
				o_available_item = `kNumItems'd0;
				temp_change = current_total;
				o_current_total = `kTotalBits'd0;
				for(i=`kNumCoins-1;i>=0;i=i-1)begin
					o_return_coin = o_return_coin + (temp_change/kkCoinValue[i]);
					temp_change = temp_change % kkCoinValue[i];
				end
			end
		endcase
	end


	// Sequential circuit to reset or update the states
	always @(posedge clk) begin
		if (!reset_n) begin
			// TODO: reset all states.
			c_state <= ready;
			current_total <= `kTotalBits'd0;
		end
		else begin
			// TODO: update all states.
			c_state <= n_state;
			current_total <= next_total;
		end
	end

endmodule
