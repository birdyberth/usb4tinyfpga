/*

This is a wrapper for the tinyfpga_bx_usbserial code from David Williams (davidthings) found https://github.com/davidthings/tinyfpga_bx_usbserial
Which is inspired by the code form Lawrie Griffiths https://github.com/lawrie/tiny_usb_examples and Luke Valenty https://github.com/tinyfpga/TinyFPGA-Bootloader

*/


module usb_pipeline (
  input clk_16mhz, //16Mhz Clock
  inout pin_usb_p, //USB pins
  inout pin_usb_n,
  output pin_usb_pu,

  input [7:0] usb_tx_data,
  input usb_tx_enable,
  output usb_tx_done
);
//PLL pour USB
wire clk_48mhz;
wire clk_locked;
// Use an icepll generated pll
pll pll48( .clock_in(clk_16mhz), .clock_out(clk_48mhz), .locked( clk_locked ) );

// Generate reset signal
reg [5:0] reset_cnt = 0;
wire reset = ~reset_cnt[5];
always @(posedge clk_48mhz)
  if ( clk_locked )
    reset_cnt <= reset_cnt + reset;

// uart pipeline in
reg       uart_in_valid;
reg       uart_in_ready;

// wire [7:0] uart_out_data;
// wire       uart_out_valid;
// wire       uart_out_ready;

// usb uart - this instanciates the entire USB device.
usb_uart uart (
  .clk_48mhz  (clk_48mhz),
  .reset      (reset),

  // pins
  .pin_usb_p(pin_usb_p),
  .pin_usb_n(pin_usb_n),

  // uart pipeline in
  .uart_in_data(usb_tx_data),
  .uart_in_valid(uart_in_valid),
  .uart_in_ready(uart_in_ready),

  //.uart_out_data(uart_out_data),
  //.uart_out_valid(uart_out_valid),
  //.uart_out_ready(uart_out_ready)
);

// USB Host Detect Pull Up
assign pin_usb_pu = 1'b1;

//Pulse valid for 1 byte transfer when usb_tx_enable is set
reg[2:0] count48mhz = 0;
always @(posedge clk_48mhz) begin
  if (usb_tx_enable == 1'b1)
    count48mhz <= count48mhz + 1;
  else
    count48mhz <= 0;
end
always @(posedge clk_48mhz) begin
  if ((count48mhz > 0) && (count48mhz <= 2)) //uart_in_valid must be set to 1 for n+1 complete clock cycles (48MHz) for usb_uart to transfer n bytes
    uart_in_valid <= 1'b1;
  else
    uart_in_valid <= 1'b0;
end
assign usb_tx_done = count48mhz == 0;
endmodule // usb_pipeline
