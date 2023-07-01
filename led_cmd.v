module led_cmd (
    Clk,
    Reset_n,
    rx_data,
    rx_done,
    Ctrl,
    time_set
);

  input Clk;
  input Reset_n;
  input [7:0] rx_data;
  input rx_done;
  output reg [7:0] Ctrl;
  output reg [31:0] time_set;

  //协议的实现
  reg [7:0] data_str[7:0];
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) begin
      data_str[0] <= 0;
      data_str[1] <= 0;
      data_str[2] <= 0;
      data_str[3] <= 0;
      data_str[4] <= 0;
      data_str[5] <= 0;
      data_str[6] <= 0;
      data_str[7] <= 0;
    end else if (rx_done) begin //移位  每来一个新的数据都把他变成最高位
      data_str[7] <= rx_data;
      data_str[6] <= data_str[7];
      data_str[5] <= data_str[6];
      data_str[4] <= data_str[5];
      data_str[3] <= data_str[4];
      data_str[2] <= data_str[3];
      data_str[1] <= data_str[2];
      data_str[0] <= data_str[1];
    end

    always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) begin
        Ctrl <= 0;
        time_set <= 0;
    end
    else if (rx_done) begin
        if((data_str[0] == 8'h55 )&&(data_str[7] == 8'hF0 )&&(data_str[1] == 8'hA5 ))begin
            time_set[7:0] <= data_str[2];
            time_set[15:8] <= data_str[3];
            time_set[23:16] <= data_str[4];
            time_set[31:24] <= data_str[5];
            Ctrl <= data_str[6]
        end
    end 

endmodule
