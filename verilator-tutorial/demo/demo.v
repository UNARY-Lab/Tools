module demo #(
    parameter WORDSIZE = 8
)(
    input  signed [WORDSIZE-1:0] iData0,   
    input  signed [WORDSIZE-1:0] iData1,
    input  signed [WORDSIZE-1:0] iData2,
    input                         iClk,
    input                         iRstN,

    output reg signed [WORDSIZE-1:0] sum
);  
    // buffer0(b0) is used to match iData0 to output(b1) of the comparison of iData1 and iData2
    reg [WORDSIZE-1:0] b0, b1;

    always @(posedge iClk or negedge iRstN) begin
        if (!iRstN) begin
            b0 <= 0;
            b1 <= 0;
            sum <= 0;
        end else begin
            sum <= b0 + b1;
            b0 <= iData0;
            if (iData1 < iData2) begin
                b1 <= iData1;
            end else begin
                b1 <= iData2;
            end
        end
    end
endmodule
