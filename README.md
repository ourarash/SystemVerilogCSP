# SystemVerilogCSP
SystemVerilog Library for Modeling Asynchronous Circuits

SystemVerilogCSP is a SystemVerilog package for modeling channel-based digital asynchronous circuits. A SystemVerilog interface is used to model CSP-like communication events. The interfaces enable explicit handshaking of channel wires as well as abstract CSP events. This enables abstract connections between modules that are described at different levels of abstraction facilitating both verification and design.

Features:

- CSP-Like communication actions (Send/Receive)
- One-to-many (broadcast) channels
- Any-to-one channels
- Split communication


#Example:
```systemverilog
//Sample full buffer module
module full_buffer (interface left, interface right);
  parameter FL = 2;
  parameter BL = 6;
  parameter WIDTH = 8;
  logic [WIDTH-1:0] data;
  always
  begin
    left.Receive(data);
    #FL;
    right.Send(data);
    #BL;
  end
endmodule
```
