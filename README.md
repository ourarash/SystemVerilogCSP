# SystemVerilogCSP
SystemVerilog Library for Modeling Asynchronous Circuits

SystemVerilogCSP (SVC) is a SystemVerilog package for modeling channel-based digital asynchronous circuits. A SystemVerilog interface is used to model CSP-like communication events. The interfaces enable explicit handshaking of channel wires as well as abstract CSP events. This enables abstract connections between modules that are described at different levels of abstraction facilitating both verification and design.

Features:

- CSP-Like communication actions (Send/Receive)
- One-to-many (broadcast) channels
- Any-to-one channels
- Split communication


# Example:
Here is a simple full buffer where send and receive actions use the abstract Send and Receive functions calls on left and right channels. See examples.sv for more samples.

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

# More Info:
Related paper: Arash Saifhashemi and Peter A. Beerel. [SystemVerilogCSP:  Modeling Digital Asynchronous Circuits Using SystemVerilog Interfaces. CPA-2011: WoTUG-33, pages 287–302. IOS Press, 2011 site] (http://wotug.kent.ac.uk/papers/CPA-2011/SaifhashemiBeerel11/SaifhashemiBeerel11.pdf)

