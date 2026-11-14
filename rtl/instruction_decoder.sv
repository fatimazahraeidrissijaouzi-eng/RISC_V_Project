module instruction_decoder (
    input  logic [31:0] instruction,
    output logic [6:0] opcode,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [31:0] immediate,
    output logic valid
);

    // EXTRACTION DES CHAMPS

    assign opcode = instruction[6:0];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign funct7 = instruction[31:25];

    // DECODAGE DES INSTRUCTIONS

    always_comb begin

        immediate = 32'b0;
        valid = 1'b0;

        case (opcode)

            // R-TYPE : ALU
            7'b0110011: begin

                case (funct3)

                    3'b000, 3'b101:
                        valid =
                            (funct7 == 7'b0000000) ||
                            (funct7 == 7'b0100000);

                    default:
                        valid =
                            (funct7 == 7'b0000000);

                endcase
            end

            // I-TYPE : ALU IMMEDIATE
            7'b0010011: begin

                immediate = {
                    {20{instruction[31]}},
                    instruction[31:20]
                };

                valid = 1'b1;

                // SLLI
                if (funct3 == 3'b001)
                    valid = (funct7 == 7'b0000000);

                // SRLI / SRAI
                if (funct3 == 3'b101)
                    valid =
                        (funct7 == 7'b0000000) ||
                        (funct7 == 7'b0100000);
            end

            // LOAD
            7'b0000011: begin

                immediate = {
                    {20{instruction[31]}},
                    instruction[31:20]
                };

                valid =
                    (funct3 == 3'b000) ||
                    (funct3 == 3'b001) ||
                    (funct3 == 3'b010) ||
                    (funct3 == 3'b100) ||
                    (funct3 == 3'b101);
            end

            // STORE
            7'b0100011: begin

                immediate = {
                    {20{instruction[31]}},
                    instruction[31:25],
                    instruction[11:7]
                };

                valid =
                    (funct3 == 3'b000) ||
                    (funct3 == 3'b001) ||
                    (funct3 == 3'b010);
            end

            // BRANCH
            7'b1100011: begin

                immediate = {
                    {19{instruction[31]}},
                    instruction[31],
                    instruction[7],
                    instruction[30:25],
                    instruction[11:8],
                    1'b0
                };

                valid =
                    (funct3 == 3'b000) ||
                    (funct3 == 3'b001) ||
                    (funct3 == 3'b100) ||
                    (funct3 == 3'b101) ||
                    (funct3 == 3'b110) ||
                    (funct3 == 3'b111);
            end

            // LUI ET AUIPC
            7'b0110111, 7'b0010111: begin

                immediate = {
                    instruction[31:12],
                    12'b0
                };

                valid = 1'b1;
            end

            // JAL
            7'b1101111: begin

                immediate = {
                    {11{instruction[31]}},
                    instruction[31],
                    instruction[19:12],
                    instruction[20],
                    instruction[30:21],
                    1'b0
                };

                valid = 1'b1;
            end

            // JALR
            7'b1100111: begin

                immediate = {
                    {20{instruction[31]}},
                    instruction[31:20]
                };

                valid = (funct3 == 3'b000);
            end

            default: begin
                immediate = 32'b0;
                valid = 1'b0;
            end

        endcase
    end

endmodule