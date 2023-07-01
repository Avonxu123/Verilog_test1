module uart_byte_rx(
    Clk,
    Reset_n,
    Baud_Set,
    uart_rx,
    Data,
    Rx_Done
);
  input Clk;
  input Reset_n;
  input [2:0]Baud_Set;
  input uart_rx;
  output reg [7:0] Data;
  output reg Rx_Done;


  //两个D触发器 边沿检测
  reg [1:0] usart_rx_r;
  always @(posedge Clk) begin
    usart_rx_r[0] <= uart_rx;
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
    case (Baud_Set)
      0: bps_DR = 1000000000 / 9600 / 16 / 20;
      1: bps_DR = 1000000000 / 19200 / 16 / 20;
      2: bps_DR = 1000000000 / 38400 / 16 / 20;
      3: bps_DR = 1000000000 / 57600 / 16 / 20;
      4: bps_DR = 1000000000 / 115200 / 16 / 20;
      default: bps_DR = 1000000000 / 9600 / 16 / 20;
    endcase

  wire bps_clk_16x;//主时钟记到那么多次以后  那么就可以进行采样的标志位
  assign bps_clk_16x = (div_cnt == (bps_DR / 2));  //记到一半的时候 采样


  reg Rx_en;
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) Rx_en <= 0;
    else if (nedge_usart_tx) Rx_en <= 1;
    else if (Rx_Done || (sta_data >= 4))  //干扰 或者发送完成
      Rx_en <= 0;
  
  reg [8:0] div_cnt;//主时钟 记到27 也就是那么多个脉冲 采一次数
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) div_cnt <= 0;
    else if (Rx_en) begin
      //这里不能直接写成else if(nedge_usart_tx)  因为这个玩意就只有一个时钟
      if (div_cnt == bps_DR) div_cnt <= 0;
      else div_cnt <= div_cnt + 1'b1;
    end else div_cnt <= 0;


  reg [7:0] bps_cnt;
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) 
        bps_cnt <= 0;
    else if (Rx_en) begin
      if (bps_clk_16x) begin
        if (bps_cnt == 160) 
            bps_cnt <= 0;//这里的159就是 160个脉冲嘛 每个采样16次
        else 
            bps_cnt <= bps_cnt + 1'b1;
      end else 
        bps_cnt <= bps_cnt;
    end else 
        bps_cnt <= 0;
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
        0:begin//这里要去清0 因为如果不清0就会一直加了
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
        end
        5, 6, 7, 8, 9, 10, 11: sta_data <= sta_data + uart_rx;
        21, 22, 23, 24, 25, 26, 27: r_data[0] <= r_data[0] + uart_rx;
        37, 38, 39, 40, 41, 42, 43: r_data[1] <= r_data[1] + uart_rx;
        53, 54, 55, 56, 57, 58, 59: r_data[2] <= r_data[2] + uart_rx;
        69, 70, 71, 72, 73, 74, 75: r_data[3] <= r_data[3] + uart_rx;
        85, 86, 87, 88, 87, 90, 91: r_data[4] <= r_data[4] + uart_rx;
        101, 102, 103, 104, 105, 106, 107: r_data[5] <= r_data[5] + uart_rx;
        117, 118, 119, 120, 121, 122, 123: r_data[6] <= r_data[6] + uart_rx;
        133, 134, 135, 136, 137, 138, 139: r_data[7] <= r_data[7] + uart_rx;
        149, 150, 151, 152, 153, 154, 155: sto_data <= sto_data + uart_rx;
        default: ;
      endcase
    end
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) 
      Data <= 0;
    //这里的可以改成 
    //Data[0] <= r_data[0][2];
    //因为第3位 其实就是 1xx 如果大于等于4 这里第3位肯定是1
    else if(bps_clk_16x && (bps_cnt==159))begin
        Data[0] <= r_data[0][2];
        Data[1] <= r_data[1][2];
        Data[2] <= r_data[2][2];
        Data[3] <= r_data[3][2];
        Data[4] <= r_data[4][2];
        Data[5] <= r_data[5][2];
        Data[6] <= r_data[6][2];
        Data[7] <= r_data[7][2];
//      Data[0] <= (r_data[0]>=4)? 1'b1: 1'b0;
//      Data[1] <= (r_data[1]>=4)? 1'b1: 1'b0;
//      Data[2] <= (r_data[2]>=4)? 1'b1: 1'b0;
//      Data[3] <= (r_data[3]>=4)? 1'b1: 1'b0;
//      Data[4] <= (r_data[4]>=4)? 1'b1: 1'b0;
//      Data[5] <= (r_data[5]>=4)? 1'b1: 1'b0;
//      Data[6] <= (r_data[6]>=4)? 1'b1: 1'b0;
//      Data[7] <= (r_data[7]>=4)? 1'b1: 1'b0;
    end
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) 
      Rx_Done <= 0;
    else if(bps_clk_16x && (bps_cnt==160))
      Rx_Done <= 1;
    else
      Rx_Done <= 0;   

endmodule