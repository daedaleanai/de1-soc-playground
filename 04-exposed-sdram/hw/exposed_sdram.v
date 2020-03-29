
module exposed_sdram
  (
   // Clocks
   CLOCK_50,

   // Pushbuttons
   KEY,

   // SDRAM
   DRAM_ADDR,
   DRAM_BA,
   DRAM_CAS_N,
   DRAM_CKE,
   DRAM_CLK,
   DRAM_CS_N,
   DRAM_DQ,
   DRAM_LDQM,
   DRAM_RAS_N,
   DRAM_UDQM,
   DRAM_WE_N,

   // DDR3 SDRAM
   HPS_DDR3_ADDR,
   HPS_DDR3_BA,
   HPS_DDR3_CAS_N,
   HPS_DDR3_CKE,
   HPS_DDR3_CK_N,
   HPS_DDR3_CK_P,
   HPS_DDR3_CS_N,
   HPS_DDR3_DM,
   HPS_DDR3_DQ,
   HPS_DDR3_DQS_N,
   HPS_DDR3_DQS_P,
   HPS_DDR3_ODT,
   HPS_DDR3_RAS_N,
   HPS_DDR3_RESET_N,
   HPS_DDR3_RZQ,
   HPS_DDR3_WE_N,

   // Ethernet
   HPS_ENET_GTX_CLK,
   HPS_ENET_INT_N,
   HPS_ENET_MDC,
   HPS_ENET_MDIO,
   HPS_ENET_RX_CLK,
   HPS_ENET_RX_DATA,
   HPS_ENET_RX_DV,
   HPS_ENET_TX_DATA,
   HPS_ENET_TX_EN,

   // SD Card
   HPS_SD_CLK,
   HPS_SD_CMD,
   HPS_SD_DATA,

   // USB
   HPS_CONV_USB_N,
   HPS_USB_CLKOUT,
   HPS_USB_DATA,
   HPS_USB_DIR,
   HPS_USB_NXT,
   HPS_USB_STP,

   // UART
   HPS_UART_RX,
   HPS_UART_TX
   );

   // Clocks
   input          CLOCK_50;

   // Pushbuttons
   input  [ 3: 0] KEY;

   // SDRAM
   output [12: 0] DRAM_ADDR;
   output [ 1: 0] DRAM_BA;
   output         DRAM_CAS_N;
   output         DRAM_CKE;
   output         DRAM_CLK;
   output         DRAM_CS_N;
   inout  [15: 0] DRAM_DQ;
   output         DRAM_LDQM;
   output         DRAM_RAS_N;
   output         DRAM_UDQM;
   output         DRAM_WE_N;

   // DDR3 SDRAM
   output [14: 0] HPS_DDR3_ADDR;
   output [ 2: 0] HPS_DDR3_BA;
   output         HPS_DDR3_CAS_N;
   output         HPS_DDR3_CKE;
   output         HPS_DDR3_CK_N;
   output         HPS_DDR3_CK_P;
   output         HPS_DDR3_CS_N;
   output [3:  0] HPS_DDR3_DM;
   inout  [31: 0] HPS_DDR3_DQ;
   inout  [ 3: 0] HPS_DDR3_DQS_N;
   inout  [ 3: 0] HPS_DDR3_DQS_P;
   output         HPS_DDR3_ODT;
   output         HPS_DDR3_RAS_N;
   output         HPS_DDR3_RESET_N;
   input          HPS_DDR3_RZQ;
   output         HPS_DDR3_WE_N;

   // Ethernet
   output         HPS_ENET_GTX_CLK;
   inout          HPS_ENET_INT_N;
   output         HPS_ENET_MDC;
   inout          HPS_ENET_MDIO;
   input          HPS_ENET_RX_CLK;
   input  [ 3: 0] HPS_ENET_RX_DATA;
   input          HPS_ENET_RX_DV;
   output [ 3: 0] HPS_ENET_TX_DATA;
   output         HPS_ENET_TX_EN;

   // SD Card
   output         HPS_SD_CLK;
   inout          HPS_SD_CMD;
   inout  [ 3: 0] HPS_SD_DATA;

   // USB
   inout          HPS_CONV_USB_N;
   input          HPS_USB_CLKOUT;
   inout  [ 7: 0] HPS_USB_DATA;
   input          HPS_USB_DIR;
   input          HPS_USB_NXT;
   output         HPS_USB_STP;

   // UART
   input          HPS_UART_RX;
   output         HPS_UART_TX;

   system soc
     (
      // Clock
      .pll_0_ref_clk_clk     (CLOCK_50),
      .pll_0_ref_reset_reset (1'b0),

      // Pushbuttons
      .buttons_0_export (~KEY[3:0]),

      // SDRAM
      .pll_0_sdram_clk_clk (DRAM_CLK),
      .sdram_0_addr        (DRAM_ADDR),
      .sdram_0_ba          (DRAM_BA),
      .sdram_0_cas_n       (DRAM_CAS_N),
      .sdram_0_cke         (DRAM_CKE),
      .sdram_0_cs_n        (DRAM_CS_N),
      .sdram_0_dq          (DRAM_DQ),
      .sdram_0_dqm         ({DRAM_UDQM,DRAM_LDQM}),
      .sdram_0_ras_n       (DRAM_RAS_N),
      .sdram_0_we_n        (DRAM_WE_N),

      // DDR3 SDRAM
      .hps_0_ddr_mem_a       (HPS_DDR3_ADDR),
      .hps_0_ddr_mem_ba      (HPS_DDR3_BA),
      .hps_0_ddr_mem_ck      (HPS_DDR3_CK_P),
      .hps_0_ddr_mem_ck_n    (HPS_DDR3_CK_N),
      .hps_0_ddr_mem_cke     (HPS_DDR3_CKE),
      .hps_0_ddr_mem_cs_n    (HPS_DDR3_CS_N),
      .hps_0_ddr_mem_ras_n   (HPS_DDR3_RAS_N),
      .hps_0_ddr_mem_cas_n   (HPS_DDR3_CAS_N),
      .hps_0_ddr_mem_we_n    (HPS_DDR3_WE_N),
      .hps_0_ddr_mem_reset_n (HPS_DDR3_RESET_N),
      .hps_0_ddr_mem_dq      (HPS_DDR3_DQ),
      .hps_0_ddr_mem_dqs     (HPS_DDR3_DQS_P),
      .hps_0_ddr_mem_dqs_n   (HPS_DDR3_DQS_N),
      .hps_0_ddr_mem_odt     (HPS_DDR3_ODT),
      .hps_0_ddr_mem_dm      (HPS_DDR3_DM),
      .hps_0_ddr_oct_rzqin   (HPS_DDR3_RZQ),

      // Ethernet
      .hps_io_hps_io_gpio_inst_GPIO35  (HPS_ENET_INT_N),
      .hps_io_hps_io_emac1_inst_TX_CLK (HPS_ENET_GTX_CLK),
      .hps_io_hps_io_emac1_inst_TXD0   (HPS_ENET_TX_DATA[0]),
      .hps_io_hps_io_emac1_inst_TXD1   (HPS_ENET_TX_DATA[1]),
      .hps_io_hps_io_emac1_inst_TXD2   (HPS_ENET_TX_DATA[2]),
      .hps_io_hps_io_emac1_inst_TXD3   (HPS_ENET_TX_DATA[3]),
      .hps_io_hps_io_emac1_inst_RXD0   (HPS_ENET_RX_DATA[0]),
      .hps_io_hps_io_emac1_inst_MDIO   (HPS_ENET_MDIO),
      .hps_io_hps_io_emac1_inst_MDC    (HPS_ENET_MDC),
      .hps_io_hps_io_emac1_inst_RX_CTL (HPS_ENET_RX_DV),
      .hps_io_hps_io_emac1_inst_TX_CTL (HPS_ENET_TX_EN),
      .hps_io_hps_io_emac1_inst_RX_CLK (HPS_ENET_RX_CLK),
      .hps_io_hps_io_emac1_inst_RXD1   (HPS_ENET_RX_DATA[1]),
      .hps_io_hps_io_emac1_inst_RXD2   (HPS_ENET_RX_DATA[2]),
      .hps_io_hps_io_emac1_inst_RXD3   (HPS_ENET_RX_DATA[3]),

      // SD Card
      .hps_io_hps_io_sdio_inst_CMD (HPS_SD_CMD),
      .hps_io_hps_io_sdio_inst_D0  (HPS_SD_DATA[0]),
      .hps_io_hps_io_sdio_inst_D1  (HPS_SD_DATA[1]),
      .hps_io_hps_io_sdio_inst_CLK (HPS_SD_CLK),
      .hps_io_hps_io_sdio_inst_D2  (HPS_SD_DATA[2]),
      .hps_io_hps_io_sdio_inst_D3  (HPS_SD_DATA[3]),

      // USB
      .hps_io_hps_io_gpio_inst_GPIO09 (HPS_CONV_USB_N),
      .hps_io_hps_io_usb1_inst_D0     (HPS_USB_DATA[0]),
      .hps_io_hps_io_usb1_inst_D1     (HPS_USB_DATA[1]),
      .hps_io_hps_io_usb1_inst_D2     (HPS_USB_DATA[2]),
      .hps_io_hps_io_usb1_inst_D3     (HPS_USB_DATA[3]),
      .hps_io_hps_io_usb1_inst_D4     (HPS_USB_DATA[4]),
      .hps_io_hps_io_usb1_inst_D5     (HPS_USB_DATA[5]),
      .hps_io_hps_io_usb1_inst_D6     (HPS_USB_DATA[6]),
      .hps_io_hps_io_usb1_inst_D7     (HPS_USB_DATA[7]),
      .hps_io_hps_io_usb1_inst_CLK    (HPS_USB_CLKOUT),
      .hps_io_hps_io_usb1_inst_STP    (HPS_USB_STP),
      .hps_io_hps_io_usb1_inst_DIR    (HPS_USB_DIR),
      .hps_io_hps_io_usb1_inst_NXT    (HPS_USB_NXT),

      // UART
      .hps_io_hps_io_uart0_inst_RX (HPS_UART_RX),
      .hps_io_hps_io_uart0_inst_TX (HPS_UART_TX)
      );
endmodule
