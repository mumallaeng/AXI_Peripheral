//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
//Date        : Fri Jun 26 06:36:01 2026
//Host        : e051a5acff09 running 64-bit Ubuntu 22.04.5 LTS
//Command     : generate_target AXI_Peripheral_wrapper.bd
//Design      : AXI_Peripheral_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module AXI_Peripheral_wrapper
   (GPIOA,
    GPIOB,
    GPIOC,
    GPIOD,
    reset,
    rx,
    sys_clock,
    tx,
    usb_uart_rxd,
    usb_uart_txd);
  inout [7:0]GPIOA;
  inout [7:0]GPIOB;
  inout [7:0]GPIOC;
  inout [7:0]GPIOD;
  input reset;
  input rx;
  input sys_clock;
  output tx;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire [7:0]GPIOA;
  wire [7:0]GPIOB;
  wire [7:0]GPIOC;
  wire [7:0]GPIOD;
  wire reset;
  wire rx;
  wire sys_clock;
  wire tx;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  AXI_Peripheral AXI_Peripheral_i
       (.GPIOA(GPIOA),
        .GPIOB(GPIOB),
        .GPIOC(GPIOC),
        .GPIOD(GPIOD),
        .reset(reset),
        .rx(rx),
        .sys_clock(sys_clock),
        .tx(tx),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
