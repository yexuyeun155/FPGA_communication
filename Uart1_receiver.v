module Uart1_receiver(
    Clk,
    Reset_n,
    Rx,
    Data_out,
    en_data_out
);

    input Clk;
    input Reset_n;
    input Rx;
    output reg [7:0] Data_out;
    output reg en_data_out;

	 reg [12:0] counter;
	 reg [3:0] counter_bits;
	 reg en_counter;
	 reg Rx_Delay;
	 reg [3:0] count_idles;
	 reg comfirm_idles;

// Baud rate parameters, 50_000_000 / 9600 = 5208;
parameter MCNT = 50_000_000;
parameter Baud = 9600;
parameter counter_Baud = MCNT / Baud;

// Baud rate counter
always @(posedge Clk or negedge Reset_n) begin
    if (!Reset_n)
        counter <= 0;
    else if (counter == counter_Baud)
        counter <= 0;
    else
        counter <= counter + 1;
end

// Count idles
always @(posedge Clk or negedge Reset_n) begin
    if (!Reset_n)
        count_idles <= 0;
    else if (Rx == 1 && counter == 0)
        count_idles <= count_idles + 1;
    else if (Rx == 0)
        count_idles <= 0;
end

// Confirm idles
always @(posedge Clk or negedge Reset_n) begin
    if (!Reset_n)
        comfirm_idles <= 0;
    else if (count_idles >= 12)
        comfirm_idles <= 1;
    else if (en_counter)
        comfirm_idles <= 0;
end

// Rx and Rx_Delay
always @(posedge Clk or negedge Reset_n) begin
    if (!Reset_n) begin
        Rx_Delay <= 0;
        en_counter <= 0;
    end else begin
        Rx_Delay <= Rx;
        if (~Rx & Rx_Delay & comfirm_idles)
            en_counter <= 1;
        else if (counter_bits == 9 && counter == counter_Baud)
            en_counter <= 0;
    end
end

// Bit counter
always @(posedge Clk or negedge Reset_n) begin
    if (!Reset_n)
        counter_bits <= 0;
    else if (en_counter && counter == counter_Baud) begin
        if (counter_bits == 9)
            counter_bits <= 0;
        else
            counter_bits <= counter_bits + 1;
    end else if (!en_counter)
        counter_bits <= 0;
end

// Data output
always @(posedge Clk or negedge Reset_n) begin
    if (!Reset_n)
        Data_out <= 8'b0000_0000;
    else if (en_counter && counter == counter_Baud/2) begin
        case (counter_bits)
            1: Data_out[0] <= Rx;
            2: Data_out[1] <= Rx;
            3: Data_out[2] <= Rx;
            4: Data_out[3] <= Rx;
            5: Data_out[4] <= Rx;
            6: Data_out[5] <= Rx;
            7: Data_out[6] <= Rx;
            8: Data_out[7] <= Rx;
        endcase
    end
end

// Enable data output
always @(posedge Clk or negedge Reset_n) begin
    if (!Reset_n)
        en_data_out <= 0;
    else if (counter_bits == 9 && counter == counter_Baud)
        en_data_out <= 1;
    else if (~Rx & Rx_Delay & comfirm_idles)
        en_data_out <= 0;
end

endmodule
