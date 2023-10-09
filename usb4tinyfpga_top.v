module usb4tinyfpga_top (
  input CLK, //16Mhz Clock
  inout USBP, //USB pins
  inout USBN,
  output USBPU
);

reg [7:0] usb_tx_data;
reg usb_tx_enable;
reg usb_tx_done;

usb_pipeline usb_magic (
  .clk_16mhz(CLK),
  .pin_usb_p(USBP),
  .pin_usb_n(USBN),
  .pin_usb_pu(USBPU),
  .usb_tx_data(usb_tx_data),
  .usb_tx_enable(usb_tx_enable),
  .usb_tx_done(usb_tx_done)
);


//Read serial data
parameter s_IDLE                 = 2'b00;
parameter s_TRANSFER_USB         = 2'b01;
parameter s_WAIT_USB             = 2'b10;
parameter s_DONE                 = 2'b11;

reg [1:0] StateMachine = 0;
reg [7:0] buffer [0:6];
reg [2:0] bufferpt;
reg [23:0] tickcount = 0;
always @ (posedge CLK) begin
  case(StateMachine)
    s_IDLE :
      begin
        if (tickcount >= 15_999_999)
          begin
            tickcount <= 0;
            StateMachine <= s_TRANSFER_USB;
          end
        else
          begin
            tickcount <= tickcount + 1;
            usb_tx_enable <= 1'b0;
            // The data to be transmitted is filled at some point
            // For the example, send Hello!\n in ascii
            bufferpt <= 0;
            buffer[0] <= 72;
            buffer[1] <= 101;
            buffer[2] <= 108;
            buffer[3] <= 108;
            buffer[4] <= 111;
            buffer[5] <= 33;
            buffer[6] <= 10;
            StateMachine <= s_IDLE;
          end
      end

    s_WAIT_USB :
      begin
        if (usb_tx_done == 1'b1)
          StateMachine <= s_TRANSFER_USB;
        else
          begin
            usb_tx_enable <= 1'b0;
            StateMachine <= s_WAIT_USB;
          end
      end

    s_TRANSFER_USB :
      begin
        if (bufferpt < 7)
          begin
            usb_tx_data <= buffer[bufferpt];
            bufferpt <= bufferpt + 1;
            usb_tx_enable <= 1'b1;
            StateMachine <= s_WAIT_USB;
          end
        else
          begin
            usb_tx_enable <= 1'b0;
            StateMachine <= s_IDLE;
          end
      end

    s_DONE :
      begin
        StateMachine <= s_DONE;
      end

  endcase
end
endmodule // usb4tinyfpga_top
