
module instruction_memory (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    // Memoire de 256 mots de 32 bits
    logic [31:0] memory [0:255];

    integer i;

    // Initialisation pour la simulation
    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'h00000013; // NOP RISC-V

        $readmemh("program/program.hex", memory);
    end

    // Lecture combinatoire
    always_comb begin
        if ((address < 32'd1024) &&
            (address[1:0] == 2'b00))
            instruction = memory[address[9:2]];
        else
            instruction = 32'h00000013;
    end

endmodule