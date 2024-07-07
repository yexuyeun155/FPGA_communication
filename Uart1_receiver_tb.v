
`timescale 1ns/1ps
module Uart1_receiver_tb();
    reg Clk;
    reg Reset_n;
    wire Rx;
    wire [7:0] Data_out;
    wire en_data_out;

    reg [25:0] data;
    reg [7:0] data1;
    reg [12:0] counter; // 扩展计数器宽度以匹配波特率

    parameter MCNT = 50_000_000;
    parameter Baud = 9600;
    parameter counter_Baud = MCNT / Baud;

    assign Rx = data[0];

    Uart1_receiver Uart1_receiver_Ins(
        .Clk(Clk),
        .Reset_n(Reset_n),
        .Rx(Rx),
        .Data_out(Data_out),
        .en_data_out(en_data_out)
    );

    initial begin
        Clk = 0;
        data1 = 8'b1110_0101;
        data = {1'b1, data1, 1'b0, 16'hffff}; // 起始位(0) + 数据位 + 停止位(1)
        Reset_n = 0;
        counter = 0;
        #17;
        Reset_n = 1;
        #16000_000;
        $stop;
    end

    always #10 Clk = !Clk; // 时钟周期为20ns，50MHz

    always @(posedge Clk) begin
        if (counter == counter_Baud)
            counter <= 0;
        else
            counter <= counter + 1;

        if (counter == 0)
            data <= {data[0], data[25:1]}; // 右移一位，填充停止位
    end
endmodule
