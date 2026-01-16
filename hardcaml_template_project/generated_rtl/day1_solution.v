module day1_solution_top (
    direction,
    clock,
    count,
    instruction_valid,
    reset,
    hits,
    passes,
    instruction_ready,
    dial_position,
    busy
);

    input direction;
    input clock;
    input [15:0] count;
    input instruction_valid;
    input reset;
    output [31:0] hits;
    output [31:0] passes;
    output instruction_ready;
    output [6:0] dial_position;
    output busy;

    wire _24;
    wire _25;
    wire _27;
    wire [31:0] _50;
    wire [31:0] _45;
    wire [31:0] _46;
    wire [6:0] _42;
    wire _43;
    wire [31:0] _47;
    reg [31:0] _49;
    wire [31:0] _51;
    wire [31:0] _4;
    reg [31:0] _44;
    wire [31:0] _82;
    wire [6:0] _59;
    wire [6:0] _37;
    wire [6:0] _38;
    wire [6:0] _35;
    wire _36;
    wire [6:0] _40;
    wire [6:0] _32;
    wire _30;
    wire [6:0] _34;
    wire _56;
    wire _7;
    wire _54;
    reg _55;
    wire _57;
    wire _8;
    reg _28;
    wire [6:0] _41;
    reg [6:0] _58;
    wire [6:0] _60;
    wire [6:0] _9;
    reg [6:0] _26;
    wire _79;
    wire [31:0] _83;
    wire [1:0] _74;
    wire [15:0] _72;
    wire _11;
    wire [15:0] _66;
    wire [15:0] _64;
    wire [15:0] _62;
    reg [15:0] _65;
    wire [15:0] _67;
    wire [15:0] _12;
    reg [15:0] _61;
    wire _73;
    wire [1:0] _75;
    wire [1:0] _48;
    wire [15:0] _14;
    wire _69;
    wire [1:0] _70;
    wire [1:0] _22;
    wire _52;
    wire _16;
    wire _53;
    wire [1:0] _71;
    reg [1:0] _76;
    wire [1:0] _77;
    wire [1:0] _17;
    (* fsm_encoding="one_hot" *)
    reg [1:0] _23;
    reg [31:0] _84;
    wire _19;
    wire [31:0] _86;
    wire [31:0] _20;
    reg [31:0] _80;
    assign _24 = _22 == _23;
    assign _25 = ~ _24;
    assign _27 = _22 == _23;
    assign _50 = 32'b00000000000000000000000000000000;
    assign _45 = 32'b00000000000000000000000000000001;
    assign _46 = _44 + _45;
    assign _42 = 7'b0000000;
    assign _43 = _41 == _42;
    assign _47 = _43 ? _46 : _44;
    always @* begin
        case (_23)
        2'b01:
            _49 <= _47;
        default:
            _49 <= _44;
        endcase
    end
    assign _51 = _19 ? _50 : _49;
    assign _4 = _51;
    always @(posedge _11) begin
        _44 <= _4;
    end
    assign _82 = _80 + _45;
    assign _59 = 7'b0110010;
    assign _37 = 7'b0000001;
    assign _38 = _26 + _37;
    assign _35 = 7'b1100011;
    assign _36 = _26 == _35;
    assign _40 = _36 ? _42 : _38;
    assign _32 = _26 - _37;
    assign _30 = _26 == _42;
    assign _34 = _30 ? _35 : _32;
    assign _56 = 1'b0;
    assign _7 = direction;
    assign _54 = _53 ? _7 : _28;
    always @* begin
        case (_23)
        2'b00:
            _55 <= _54;
        default:
            _55 <= _28;
        endcase
    end
    assign _57 = _19 ? _56 : _55;
    assign _8 = _57;
    always @(posedge _11) begin
        _28 <= _8;
    end
    assign _41 = _28 ? _40 : _34;
    always @* begin
        case (_23)
        2'b01:
            _58 <= _41;
        default:
            _58 <= _26;
        endcase
    end
    assign _60 = _19 ? _59 : _58;
    assign _9 = _60;
    always @(posedge _11) begin
        _26 <= _9;
    end
    assign _79 = _26 == _42;
    assign _83 = _79 ? _82 : _80;
    assign _74 = 2'b10;
    assign _72 = 16'b0000000000000001;
    assign _11 = clock;
    assign _66 = 16'b0000000000000000;
    assign _64 = _61 - _72;
    assign _62 = _53 ? _14 : _61;
    always @* begin
        case (_23)
        2'b00:
            _65 <= _62;
        2'b01:
            _65 <= _64;
        default:
            _65 <= _61;
        endcase
    end
    assign _67 = _19 ? _66 : _65;
    assign _12 = _67;
    always @(posedge _11) begin
        _61 <= _12;
    end
    assign _73 = _61 == _72;
    assign _75 = _73 ? _74 : _48;
    assign _48 = 2'b01;
    assign _14 = count;
    assign _69 = _14 == _66;
    assign _70 = _69 ? _22 : _48;
    assign _22 = 2'b00;
    assign _52 = _22 == _23;
    assign _16 = instruction_valid;
    assign _53 = _16 & _52;
    assign _71 = _53 ? _70 : _23;
    always @* begin
        case (_23)
        2'b00:
            _76 <= _71;
        2'b01:
            _76 <= _75;
        2'b10:
            _76 <= _22;
        default:
            _76 <= _23;
        endcase
    end
    assign _77 = _19 ? _22 : _76;
    assign _17 = _77;
    always @(posedge _11) begin
        _23 <= _17;
    end
    always @* begin
        case (_23)
        2'b10:
            _84 <= _83;
        default:
            _84 <= _80;
        endcase
    end
    assign _19 = reset;
    assign _86 = _19 ? _50 : _84;
    assign _20 = _86;
    always @(posedge _11) begin
        _80 <= _20;
    end
    assign hits = _80;
    assign passes = _44;
    assign instruction_ready = _27;
    assign dial_position = _26;
    assign busy = _25;

endmodule

