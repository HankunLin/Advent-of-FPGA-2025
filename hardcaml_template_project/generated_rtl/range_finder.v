module range_finder (
    data_in,
    data_in_valid,
    clear,
    clock,
    finish,
    start,
    range$valid,
    range$value
);

    input [15:0] data_in;
    input data_in_valid;
    input clear;
    input clock;
    input finish;
    input start;
    output range$valid;
    output [15:0] range$value;

    wire [15:0] _42;
    wire _27;
    wire [15:0] _28;
    wire [15:0] _29;
    wire [15:0] _24;
    wire [15:0] _25;
    reg [15:0] _31;
    wire [15:0] _1;
    reg [15:0] min;
    wire [15:0] _3;
    wire _36;
    wire [15:0] _37;
    wire _5;
    wire [15:0] _38;
    wire [15:0] _35;
    reg [15:0] _39;
    wire [15:0] _6;
    reg [15:0] max;
    wire [15:0] _40;
    reg [15:0] _43;
    wire [15:0] _7;
    wire gnd;
    wire vdd;
    wire [1:0] _20;
    wire _10;
    wire _12;
    wire [1:0] _46;
    wire [1:0] _41;
    wire _14;
    wire [1:0] _45;
    wire [1:0] _30;
    wire _16;
    wire [1:0] _44;
    reg [1:0] _47;
    wire [1:0] _17;
    (* fsm_encoding="one_hot" *)
    reg [1:0] _21;
    reg _50;
    wire _18;
    assign _42 = 16'b0000000000000000;
    assign _27 = _3 < min;
    assign _28 = _27 ? _3 : min;
    assign _29 = _5 ? _28 : min;
    assign _24 = 16'b1111111111111111;
    assign _25 = _16 ? _24 : min;
    always @* begin
        case (_21)
        2'b00:
            _31 <= _25;
        2'b01:
            _31 <= _29;
        default:
            _31 <= min;
        endcase
    end
    assign _1 = _31;
    always @(posedge _12) begin
        if (_10)
            min <= _42;
        else
            min <= _1;
    end
    assign _3 = data_in;
    assign _36 = max < _3;
    assign _37 = _36 ? _3 : max;
    assign _5 = data_in_valid;
    assign _38 = _5 ? _37 : max;
    assign _35 = _16 ? _42 : max;
    always @* begin
        case (_21)
        2'b00:
            _39 <= _35;
        2'b01:
            _39 <= _38;
        default:
            _39 <= max;
        endcase
    end
    assign _6 = _39;
    always @(posedge _12) begin
        if (_10)
            max <= _42;
        else
            max <= _6;
    end
    assign _40 = max - min;
    always @* begin
        case (_21)
        2'b10:
            _43 <= _40;
        default:
            _43 <= _42;
        endcase
    end
    assign _7 = _43;
    assign gnd = 1'b0;
    assign vdd = 1'b1;
    assign _20 = 2'b00;
    assign _10 = clear;
    assign _12 = clock;
    assign _46 = _14 ? _30 : _21;
    assign _41 = 2'b10;
    assign _14 = finish;
    assign _45 = _14 ? _41 : _21;
    assign _30 = 2'b01;
    assign _16 = start;
    assign _44 = _16 ? _30 : _21;
    always @* begin
        case (_21)
        2'b00:
            _47 <= _44;
        2'b01:
            _47 <= _45;
        2'b10:
            _47 <= _46;
        default:
            _47 <= _21;
        endcase
    end
    assign _17 = _47;
    always @(posedge _12) begin
        if (_10)
            _21 <= _20;
        else
            _21 <= _17;
    end
    always @* begin
        case (_21)
        2'b10:
            _50 <= vdd;
        default:
            _50 <= gnd;
        endcase
    end
    assign _18 = _50;
    assign range$valid = _18;
    assign range$value = _7;

endmodule
module range_finder_top (
    data_in_valid,
    data_in,
    finish,
    start,
    clear,
    clock,
    range$valid,
    range$value
);

    input data_in_valid;
    input [15:0] data_in;
    input finish;
    input start;
    input clear;
    input clock;
    output range$valid;
    output [15:0] range$value;

    wire [15:0] _16;
    wire _3;
    wire [15:0] _5;
    wire _7;
    wire _9;
    wire _11;
    wire _13;
    wire [16:0] _15;
    wire _17;
    assign _16 = _15[16:1];
    assign _3 = data_in_valid;
    assign _5 = data_in;
    assign _7 = finish;
    assign _9 = start;
    assign _11 = clear;
    assign _13 = clock;
    range_finder
        range_finder
        ( .clock(_13),
          .clear(_11),
          .start(_9),
          .finish(_7),
          .data_in(_5),
          .data_in_valid(_3),
          .range$valid(_15[0:0]),
          .range$value(_15[16:1]) );
    assign _17 = _15[0:0];
    assign range$valid = _17;
    assign range$value = _16;

endmodule

