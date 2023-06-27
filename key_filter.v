`timescale 1ns / 1ns

module key_filter(
    Clk,
    Reset_n,
    Key,
    Key_P_Flag,
    Key_R_Flag,
    );
    
    input Clk;
    input Reset_n;
    input Key;
    output reg Key_P_Flag;
    output reg Key_R_Flag;
    
    
    reg [1:0] r_Key;
    always@(posedge Clk)
        r_Key <= {r_Key[0],Key};

    //这个上面和下面是等价的
    //always@(posedge Clk) begin
    //    r_Key[0] <= Key;
    //    r_Key[1] <= r_Key[0];
    //end
    
    wire pegde_key;
    assign pegde_key = (r_Key == 2'b01);    
    wire negde_key;
    assign negde_key = (r_Key == 2'b10);

    reg[19:0] cnt;//20ms的计数器

    //先写状态 - 4个状态
    localparam IDLE = 0 ;
    reg [1:0] ; state;
    always@(posedge Clk or negedge Reset_n)
    if(!Reset_n)
        state <=0;
        Key_R_Flag <= 1'b0;
        cnt <= 0;
        Key_P_Flag <= 1'b0;
    else begin
        case (state)
            0:  begin
                Key_R_Flag <= 0;
                if (negde_key) begin
                    state <= 1;
                end else
                    state <= 0;
            end

            1:  if(pegde_key&&(cnt < 1000000 - 1))
                    state <= 0;
                else if (cnt >= 1000000 - 1) begin
                    state <= 2;
                    cnt <= 0;
                    Key_P_Flag <= 1;
                else
                    cnt <= cnt + 1'b1;
                    state <= 1;
                end
            2:  begin
                    Key_P_Flag <= 1'b0;
                if (pegde_key) begin
                    state <= 3;
                end
                else
                    state <= 2;
            end

            3:
                if(negde_key&&(cnt < 1000000 - 1))
                    state <= 2;      
                else if(cnt >= 1000000 - 1)begin
                    state <= 0;
                    cnt <= 0;
                    Key_R_Flag <= 1'b1;
                else
                    cnt <= cnt + 1'b1;
                    state <= 3;
            end
            default: 
        endcase
    end
endmodule
