`timescale 1ns/1ps

module data_memory (
    input  logic        clk,
    input  logic        rst,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [2:0]  funct3,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    output logic [31:0] read_data,
    output logic        valid
);

    logic [31:0] memory [0:255];

    logic [7:0]  word_index;
    logic [1:0]  byte_offset;
    logic [31:0] selected_word;
    logic [7:0]  selected_byte;
    logic [15:0] selected_half;

    integer i;

    assign word_index = address[9:2];
    assign byte_offset = address[1:0];
    assign selected_word = memory[word_index];

    // Selection des octets
    always_comb begin
        case (byte_offset)
            2'b00: selected_byte = selected_word[7:0];
            2'b01: selected_byte = selected_word[15:8];
            2'b10: selected_byte = selected_word[23:16];
            2'b11: selected_byte = selected_word[31:24];
            default: selected_byte = 8'b0;
        endcase

        if (byte_offset[1] == 1'b0)
            selected_half = selected_word[15:0];
        else
            selected_half = selected_word[31:16];
    end

    // Validation des adresses
    always_comb begin
        valid = 1'b1;

        if (mem_read || mem_write) begin
            if (address >= 32'd1024)
                valid = 1'b0;
            else begin
                case (funct3)
                    3'b000, 3'b100:
                        valid = 1'b1;

                    3'b001, 3'b101:
                        valid = (byte_offset[0] == 1'b0);

                    3'b010:
                        valid = (byte_offset == 2'b00);

                    default:
                        valid = 1'b0;
                endcase

                if (mem_write &&
                    (funct3 == 3'b100 ||
                     funct3 == 3'b101))
                    valid = 1'b0;
            end
        end
    end

    // Lecture de la memoire
    always_comb begin
        read_data = 32'b0;

        if (mem_read && valid) begin
            case (funct3)

                // LB
                3'b000:
                    read_data = {
                        {24{selected_byte[7]}},
                        selected_byte
                    };

                // LH
                3'b001:
                    read_data = {
                        {16{selected_half[15]}},
                        selected_half
                    };

                // LW
                3'b010:
                    read_data = selected_word;

                // LBU
                3'b100:
                    read_data = {24'b0, selected_byte};

                // LHU
                3'b101:
                    read_data = {16'b0, selected_half};

                default:
                    read_data = 32'b0;
            endcase
        end
    end

    // Ecriture dans la memoire
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 256; i = i + 1)
                memory[i] <= 32'b0;
        end
        else if (mem_write && valid) begin
            case (funct3)

                // SB
                3'b000: begin
                    case (byte_offset)
                        2'b00:
                            memory[word_index][7:0]
                                <= write_data[7:0];

                        2'b01:
                            memory[word_index][15:8]
                                <= write_data[7:0];

                        2'b10:
                            memory[word_index][23:16]
                                <= write_data[7:0];

                        2'b11:
                            memory[word_index][31:24]
                                <= write_data[7:0];
                    endcase
                end

                // SH
                3'b001: begin
                    if (byte_offset[1] == 1'b0)
                        memory[word_index][15:0]
                            <= write_data[15:0];
                    else
                        memory[word_index][31:16]
                            <= write_data[15:0];
                end

                // SW
                3'b010:
                    memory[word_index] <= write_data;

                default: begin
                end
            endcase
        end
    end

endmodule