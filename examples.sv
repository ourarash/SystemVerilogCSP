/-------------------------------------------------------------------------------------------------
//  Written by Arash Saifhashemi, saifhash@usc.edu
//  Basic moduels using SystemVerilogCSP
//  USC Asynchronous CAD/VLSI Group
//  University of Southern California
//  http://async.usc.edu
//-------------------------------------------------------------------------------------------------
`timescale 1ns/1fs
import SystemVerilogCSP::*;
////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Sample data_generator module
module data_generator (interface r);
  parameter WIDTH = 8;
  parameter FL = 10;
  integer SEED =6;  
  logic [WIDTH-1:0] randValue = 0;
  integer seed;
  real cycleCounter =0;
  always
  begin
    //seed = SEED;
    #100;
    cycleCounter += 1;
    //#10;
    
    if (WIDTH>1)
      randValue = {$random()} % 2**(WIDTH-1) ;
  else
      randValue = {$random()} % 2;
    
    //randValue = 1;
    $display ("Cycle= %d, Send value= %d", cycleCounter, randValue);
    //#FL;
    r.Send(randValue);
    void'(r.SingleRailToP1of4()); 
    #0;
  end
endmodule


//Sample data_bucket module
module data_bucket (interface r);
  parameter WIDTH = 8;
  parameter BL = 10;
  logic [WIDTH-1:0] ReceiveValue = 0;
  real cycleCounter=0, timeOfReceive=0, cycleTime=0;
  real averageThroughput=0, averageCycleTime=0, sumOfCycleTimes=0;
  always
  begin
    //Save the simulation time when Receive starts
    timeOfReceive = $time;
    r.Receive(ReceiveValue);
    $display("%m: Receive value=%d, Time=", ReceiveValue, $time);
    #BL;
    
    cycleCounter += 1;
    //Measuring throughput: calculate the number of Receives per unit of time  
    //CycleTime stores the time it takes from the begining to the end of the always block
    cycleTime = $time - timeOfReceive;
    averageThroughput = cycleCounter/$time;
    sumOfCycleTimes += cycleTime;
    averageCycleTime = sumOfCycleTimes / cycleCounter;
    //$display ("Execution cycle= %d, Cycle Time= %d, Average CycleTime=%f, Average Throughput=%f", cycleCounter, cycleTime, averageCycleTime, averageThroughput);
  end
endmodule

//Sample full buffer module
module tok_full_buffer (interface left, interface right);
  parameter FL = 2;
  parameter BL = 6;
  parameter WIDTH = 8;
  parameter INIT=0;
  logic [WIDTH-1:0] data=INIT;

  always
  begin
    right.Send(data);
    //$display("Sent from %m, value=%d, Time=%t", data, $time);
    #BL;
    left.Receive(data);
    #FL;
  end

endmodule

//Sample TOK full buffer module
module full_buffer (interface left, interface right);
  parameter FL = 2;
  parameter BL = 6;
  parameter WIDTH = 8;
  parameter STAT_EN=0;  //if 1, it calculate statistical information
  logic [WIDTH-1:0] data;
  real cycleCounter=0, timeOfReceive=0, cycleTime=0;
  real averageThroughput=0, averageCycleTime=0, sumOfCycleTimes=0;
  always
  begin
    timeOfReceive = $time;
    left.Receive(data);
    #FL;
    right.Send(data);
    #BL;
    cycleCounter += 1;
    //Measuring throughput: calculate the number of Receives per unit of time  
    //CycleTime stores the time it takes from the begining to the end of the always block
    cycleTime = $time - timeOfReceive;
    averageThroughput = cycleCounter/$time;
    sumOfCycleTimes += cycleTime;
    averageCycleTime = sumOfCycleTimes / cycleCounter;
    if (STAT_EN) begin
      //$display ("Execution cycle= %d, Cycle Time= %d, Average CycleTime=%f, Average Throughput=%f, Number of TokBufs=%d", cycleCounter, cycleTime, averageCycleTime, averageThroughput, ring_4_4.NUMBER_OF_TB);
    end
  end
endmodule

//Sample TOK full buffer module
module pchb_buffer (interface left, interface right);
	parameter FL = 2, PC = 2;
	parameter LCD = 2, RCD =  2, CE = 3;
	parameter WIDTH = 8;
	parameter STAT_EN=0;  //if 1, it calculate statistical information
	logic [WIDTH-1:0] inData = 'x, outData = 'x;
	logic [WIDTH-1:0] outData0=0, outData1=0;
	logic rcd = 0;
	logic  en=1;
	real cycleCounter=0, timeOfReceive=0, cycleTime=0;
	real averageThroughput=0, averageCycleTime=0, sumOfCycleTimes=0;
	integer delay;
	
	function logic CalculateResult(input logic [WIDTH-1:0] inData0, inData1);
	  logic rcd;
		//Function calculation
		outData0 = inData0;
		outData1 = inData1;
		//Convert outData0 and outData1 to outData
		outData = 'x;
		outData = outData & (~outData0) ;
		outData = outData | outData1 ;
		//RCD
		rcd = ( &(outData0 | outData1) );
		return	rcd;	//Validty of outData
	endfunction
	
	// Domino logic and rcd
	always @(left.data0 or left.data1 or en)
		if(en)
		begin
			rcd = CalculateResult (left.data0, left.data1);
			right.SplitSend		(outData, 1, FL);	//	R+
		end
		else
			rcd = 0;
	always
	begin
		fork
		begin
			left.SplitReceive	(inData, 1);	// [L]
			#LCD;
		end
		begin
			wait (rcd == 1);
			#FL;
			#RCD;
		end
		join
		#CE;
		left.SplitReceive	(inData, 2);		//	La+
		en = 0 ;
		fork
			begin
				left.SplitReceive	(inData, 3);	// [~L]
				#LCD;
			end
			begin
				right.SplitSend		(outData, 2);	//[Ra]
				#PC;
				right.SplitSend		(outData, 3);	//	R-
				#RCD;
			end
		join
		#CE;
		left.SplitReceive	(inData, 4);	//	La -
		right.SplitSend		(outData, 4);	//	[~Rack]
		en = 1;
	end
endmodule

module copy2 (interface in_I, interface out0_I, interface out1_I );
  parameter WIDTH = 8;
  parameter FL=2, BL=8;
  logic [WIDTH-1:0] data;
  genvar i;
  always
  begin
    in_I.Receive(data);
    #FL;
    wait (out0_I.status != idle  && out1_I.status != idle );
    fork
      out0_I.Send(data);
      out1_I.Send(data);
    join
    #BL; 
  end
endmodule

module copy3 (interface in_I, interface out0_I, interface out1_I, interface out2_I);
  parameter WIDTH = 8;
   parameter FL=2, BL=8;
  logic [WIDTH-1:0] data;
  genvar i;
  always
  begin
    in_I.Receive(data);
    #FL;
    wait (out0_I.status != idle  && out1_I.status != idle && out2_I.status !=idle );
    fork
      out0_I.Send(data);
      out1_I.Send(data);
      out2_I.Send(data);
    join 
    #BL;
  end
endmodule

module copy4 (interface in_I, interface out0_I, interface out1_I, interface out2_I, interface out3_I );
  parameter WIDTH = 8;
   parameter FL=2, BL=8;
  logic [WIDTH-1:0] data;
  genvar i;
  always
  begin
    in_I.Receive(data);
    #FL;
    wait (out0_I.status != idle  && out1_I.status != idle && out2_I.status !=idle && out3_I.status != idle );
    fork
      out0_I.Send(data);
      out1_I.Send(data);
      out2_I.Send(data);
      out3_I.Send(data);
    join 
    #BL;
  end
endmodule

//top level module instantiating data_generator, reciever, and the interface
module linear_pipeline;
  //instantiate interfaces
  Channel            intf  [3:0] ();
  
  //instantiate test circuit
  data_generator      dg       (intf[3]);
  full_buffer         fb2      (intf[3], intf[2]);
  full_buffer         fb1      (intf[2], intf[1]);
  full_buffer         fb0      (intf[1], intf[0]);
  data_bucket         #(.BL(20)) db       (intf[0]);
endmodule

//top level module instantiating data_generator, reciever, and the interface
module linear_pipeline2;
  //instantiate interfaces
  Channel            intf  [3:0] ();
  
  //instantiate test circuit
  data_generator     dg       (intf[3]);
  full_buffer        fb[2:0]  (intf[3:1], intf[2:0]);
  data_bucket        db       (intf[0]);
endmodule

//top level module instantiating data_generator, reciever, and the interface
module linear_pipeline3;
  //instantiate interfaces
  Channel            intf  [3:0] ();
  genvar            i;
  //instantiate test circuit
  data_generator     dg       (intf[3]);
  for (i=2 ; i>=0 ; i=i-1) begin : buffers
    full_buffer        fb  (intf[i+1], intf[i]);
  end
  data_bucket        db       (intf[0]);
endmodule

module broadcast_test;

  //instantiate interfaces
  Channel #(.WIDTH(8))                          topI    [1:0] ();
  Channel #(.WIDTH(8))                          botI    [1:0] ();
  Channel #(.NUMBER_OF_RECEIVERS(2), .WIDTH(8), .PHASE(8)) forkI ();
  
  //instantiate test circuit
  data_generator      dg       (forkI.SENDER);  
  
  full_buffer         fbt1      (.left(forkI.RECEIVER[0].r), .right(topI[1]));
  full_buffer         fbt0      (.left(topI[1].REC), .right(topI[0]));
  
  full_buffer         fbb1      (.left(forkI.RECEIVER[1].r), .right(botI[1]));  
  full_buffer         fbb0      (botI[1].REC, botI[0]);

  data_bucket          dbt       (topI[0].REC);
  data_bucket          dbb       (botI[0].REC);
endmodule

typedef enum {RECEIVE, SEND} bufferState;
module tok_full_buffer_reset (interface left, interface right, input reset);
  parameter FL = 2;
  parameter BL = 6;
  parameter WIDTH = 8;
  logic [WIDTH-1:0] data;
  integer coeff = 1;
  bufferState state = SEND;
  always @(left.status, right.status, reset)
  begin
    if (reset)
      state=SEND;
    else if(left.status!=idle && state==RECEIVE) begin
      left.Receive(data);
      state = SEND;
      #FL;
    end
    else if (right.status!=idle && state==SEND) begin 
      right.Send(data);
      state = RECEIVE;
      #BL;
    end
  end
endmodule

module Enclosed_Handshaking (interface left, interface right);
	parameter WIDTH = 8;
	logic [WIDTH-1:0] data;
	always
	begin
		left.SplitReceive	(data, 1);
		right.Send			(data);
		left.SplitReceive	(data, 2);
	end
endmodule


module Adder (interface A, interface B, interface SUM);
  parameter WIDTH = 8; 
  logic [WIDTH-1:0] a = 0, b=0, sum=0;
  always
  begin
	fork
		A.Receive(a);
		B.Receive(b);
	join
	sum = a + b ;
	SUM.Send(sum);
  end
endmodule
