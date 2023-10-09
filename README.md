# usb4tinyfpga

This project is based on the code from David Williams (davidthings) found here : https://github.com/davidthings/tinyfpga_bx_usbserial/

I was trying to incorporate usbserial into a project and I found it was hard to respect the timing requirements for data throughput with a 48Mhz clock on the tinyFPGA BX. As I'm still a beginner in Veriloguese, it was quite daunting to try to optimize for speed knowing that the code I wrote was working, but just too slowly for the limited tinyFPGA.

Moreover, this is USB 1 implementation, which means that the theoretical data rate is 12 Mbps, i.e max 1.5 Mbytes/s. It just doesn't make any sense that the pipeline can pass one **byte** on a 48Mhz rate. Somewhere, some data must be dropped and I don't like that. I know that's what the `uart_ready` signal is for, but the `uart_valid` and `uart_data` still have to be pulsed on a 48MHz clock.

This is why I constrained the 48MHz clock domain to a wrapper named usb_pipeline.v, into the usb folder. I'm using two signals, `usb_tx_enable` and `usb_tx_done` to asynchronously pass the data into the usb_serial pipeline. This way, I can run the rest of my hardware blocks at any clock rate I like and pass the timing requirements.

I struggled a bit to find out how to actually use the usb_serial pipeline in other things that a simple loopback, this is why I am including in this repo an example of a state machine that demonstrate how to send data (usb4tinyfpga_top.v). For now I've only written the device to host (TX) direction, as it was the only one I needed for my project (ah the good old `Serial.print()`). Also, I've included a minimalist python script (usbcom.py) to print data to the console, for completeness of the example.
