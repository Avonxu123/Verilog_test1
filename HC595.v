`timescale 1ns / 1ps

module HC595_Driver (
    Clk,
    Reset_n,
    Data,
    SH_CP,
    ST_CP,
    DS
);
  //////adsdasdasdasd
  input Clk;
  input Reset_n;
  input Data;
  output reg SH_CP;  //时钟
  output reg ST_CP;
  output reg DS;  //串行输出

  parameter CNT_MAX = 2;
  reg [7:0] divider_cnt;   //这里留那么多是为了  降速 因为如果用杜邦线连接 速度肯定就上不去了
  //2分频-> 这里就是25M     就是 1的时候就是 上升沿 0的时候就是下降沿  下降沿翻转 上升沿采样 
  //本来的目的是 12.5M 
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) divider_cnt <= 0;
    else if (divider_cnt == CNT_MAX - 1'b1) divider_cnt <= 0;
    else divider_cnt <= divider_cnt + 1'b1;


  wire sck_plus;//这个 也是25Mhz -> 这个就是看 是否记满那么长时间 只是这里看上去是25M
  assign sck_plus = (divider_cnt == CNT_MAX - 1'b1);

  reg [5:0] SHCP_EDGE_CNT;
  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) SHCP_EDGE_CNT <= 0;
    else if (sck_plus) begin
      if (SHCP_EDGE_CNT == 6'd32) SHCP_EDGE_CNT <= 0;
      else SHCP_EDGE_CNT <= SHCP_EDGE_CNT + 1'b1;
    end

  always @(posedge Clk or negedge Reset_n)
    if (!Reset_n) begin
      SH_CP <= 0;
      ST_CP <= 0;
      DS <= 0;
    end else begin
      case (SHCP_EDGE_CNT)
        0: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[15];
        end
        1: SH_CP <= 1;
        2: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[14];
        end
        3: SH_CP <= 1;
        4: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[13];
        end
        5: SH_CP <= 1;
        6: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[12];
        end
        7: SH_CP <= 1;
        8: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[11];
        end
        9: SH_CP <= 1;
        10: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[10];
        end
        11: SH_CP <= 1;
        12: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[9];
        end
        13: SH_CP <= 1;
        14: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[8];
        end
        15: SH_CP <= 1;
        16: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[7];
        end
        17: SH_CP <= 1;
        18: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[6];
        end
        19: SH_CP <= 1;
        20: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[5];
        end
        21: SH_CP <= 1;
        22: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[4];
        end
        23: SH_CP <= 1;
        24: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[3];
        end
        25: SH_CP <= 1;
        26: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[2];
        end
        27: SH_CP <= 1;
        28: begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[1];
        end
        29: SH_CP <= 1;
        30: begin
            SH_CP <= 0;
          ST_CP <= 0;
          DS <= Data[0];
        end
        31: SH_CP <= 1;
        32: ST_CP <= 1;
        default:begin
          SH_CP <= 0;
          ST_CP <= 0;
          DS <= 0;
        end;
      endcase
    end
endmodule
