



module usart_rx (
    Clk,
    Reset_n,
    Baud_set,
    usart_rx,
    Data,
    Rx_Done
);
  input Clk;
  input Reset_n;
  input Baud_set;
  input usart_rx;
  output [7:0] Data;
  output Rx_Done;


  //两个D触发器 边沿检测
  reg [1:0] usart_rx_r;
  always @(posedge Clk) begin
    usart_rx_r[0] <= usart_rx;
    usart_rx_r[1] <= usart_rx_r[0];
  end
  wire pedge_usart_tx;  //上升沿检测 先0后1
  //assign pedge_usart_tx=(usart_rx_r[1]==0)&&(usart_rx_r[0]==1);
  //前一种时刻的值为0 后一种时刻的值为1 
  assign pedge_usart_tx = (usart_rx_r == 2'b01);  //这样写也是一样的  省事

  wire nedge_usart_tx;  //下降沿检测 先1后0
  //assign nedge_usart_tx=(usart_rx_r[1]==0)&&(usart_rx_r[0]==1);
  //前一种时刻的值为1 后一种时刻的值为0 
  assign nedge_usart_tx = (usart_rx_r == 2'b10);  //这样写也是一样的  省事

  //接收 一位检测16次（一般情况下） 那么就是
  //1000000000/115200/16/20 =27次
  //1000000000/9600/16/20=325次
  reg [8:0] bps_DR;
  always @(*)
    case (Baud_set)
      0: bps_DR = 1000000000 / 9600 / 16 / 20;
      1: bps_DR = 1000000000 / 19200 / 16 / 20;
      2: bps_DR = 1000000000 / 38400 / 16 / 20;
      3: bps_DR = 1000000000 / 57600 / 16 / 20;
      4: bps_DR = 1000000000 / 115200 / 16 / 20;
      default: bps_DR = 1000000000 / 9600 / 16 / 20;
    endcase

  wire bps_clk_16x;
  assign bps_clk_16x = (bps_cnt == bps_DR / 2);  //记到一半的时候 采样


  reg Rx_en;
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) Rx_en <= 0;
    else if (nedge_usart_tx) Rx_en <= 1;
    else if (Rx_Done || (sta_data >= 4))  //干扰 或者发送完成
      Rx_en <= 0;
  reg [8:0] div_cnt;
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) div_cnt <= 0;
    else if (Rx_en) begin
      //这里不能直接写成else if(nedge_usart_tx)  因为这个玩意就只有一个时钟
      if (div_cnt == bps_DR) div_cnt <= 0;
      else div_cnt <= div_cnt + 1'b1;
    end else div_cnt <= 0;


  reg [7:0] bps_cnt;
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) bps_cnt <= 0;
    else if (Rx_en) begin
      if (bps_clk_16x) begin
        if (bps_cnt == 159) bps_cnt <= 0;
        else bps_cnt <= bps_cnt + 1'b1;
      end else bps_cnt <= bps_cnt;
    end else bps_cnt <= 0;
  //二维数组
  //reg[位宽-1：0]  寄存器名字 [数组宽度-1:0] 其实这也就是一个一维数组 只能一个一个
  reg [2:0] r_data[7:0];
  reg [2:0] sta_data;
  reg [2:0] sto_data;
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) begin
      sta_data  <= 0;
      sto_data  <= 0;
      r_data[0] <= 0;
      r_data[1] <= 0;
      r_data[2] <= 0;
      r_data[3] <= 0;
      r_data[4] <= 0;
      r_data[5] <= 0;
      r_data[6] <= 0;
      r_data[7] <= 0;
    end else if (bps_clk_16x) begin
      case (bps_cnt)
        5, 6, 7, 8, 9, 10, 11: sta_data <= sta_data + usart_rx;
        21, 22, 23, 24, 25, 26, 27: r_data[0] <= r_data[0] + usart_rx;
        37, 38, 39, 40, 41, 42, 43: r_data[1] <= r_data[1] + usart_rx;
        53, 54, 55, 56, 57, 58, 59: r_data[2] <= r_data[2] + usart_rx;
        69, 70, 71, 72, 73, 74, 75: r_data[3] <= r_data[3] + usart_rx;
        85, 86, 87, 88, 87, 90, 91: r_data[4] <= r_data[4] + usart_rx;
        101, 102, 103, 104, 105, 106, 107: r_data[5] <= r_data[5] + usart_rx;
        117, 118, 119, 120, 121, 122, 123: r_data[6] <= r_data[6] + usart_rx;
        133, 134, 135, 136, 137, 138, 139: r_data[7] <= r_data[7] + usart_rx;
        149, 150, 151, 152, 153, 154, 155: sto_data <= sto_data + usart_rx;
        default: ;
      endcase
    end
endmodule
