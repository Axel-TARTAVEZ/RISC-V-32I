module top_tb_1_pr;

    `define ASSERT_EQ(name, signal, expected) \
        if ((signal) !== (expected)) begin \
            $display("========================================"); \
            $display("[ASSERTION FAILED] %s", name); \
            $display("   Temps   : %0t", $time); \
            $display("   Attendu : %0d (0x%h)", expected, expected); \
            $display("   Obtenu  : %0d (0x%h)", signal, signal); \
            $display("========================================"); \
            $finish; \
        end else begin \
            $display("[OK] %s", name); \
        end

    reg clk;
    reg rst;

    wire wr_en_M;
    wire [2:0] funct_3_M;
    wire [31:0] rs2_M;
    wire [31:0] o_alu_M;
    wire [31:0] o_data;
    wire [31:0] o_pc;
    wire [31:0] inst;

    // Instance du processeur (la Netlist)
    processor dut (
        .clk(clk),
        .rst(rst),
        .wr_en_M (wr_en_M),
        .funct_3_M (funct_3_M),
        .rs2_M (rs2_M),
        .o_alu_E_top (o_alu_M),
        .i_data_mem (o_data),
        .o_pc_top (o_pc),
        .i_inst_mem (inst)
    );

    // Instances des mémoires (externes au circuit routé)
    data_mem data_mem(
        .i_clk (clk),
        .i_we (wr_en_M),
        .i_func3 (funct_3_M),
        .i_data (rs2_M),
        .i_addr (o_alu_M[11:0]),
        .o_data (o_data)
    );

    inst_mem inst_mem(
        .clk (clk),
        .addr (o_pc[11:2]),
        .inst (inst)
    );

    // Génération d'horloge
    always #5 clk = ~clk;

    // --- ANNOTATION DES DÉLAIS PHYSIQUES ---
    initial begin
        // Change le chemin si nécessaire
        $sdf_annotate("RISCV-V-32I/asic/par/INNOVUS/RESULTS/design.sdf", dut);
        $display("SDF Annotation terminée.");
    end

    // --- SCÉNARIO DE TEST ---
    initial begin
        // Chargement du NOUVEAU programme
        $readmemh("programs/bin/inst_gr_1_pr.hex", inst_mem.mem);

        clk = 0;
        rst = 1;
        
        // Un reset plus long pour stabiliser la netlist physique
        #50 rst = 0;

        // On attend que les NOPs finaux soient passés (900ns de marge)
        #900; 

        $display("--- DEBUT DES VERIFICATIONS POST-ROUTAGE ---");

        // VERIFICATIONS DANS LA DATA MEMORY
        // L'adresse 0 = Mot 0, Adresse 4 = Mot 1, Adresse 8 = Mot 2, Adresse 12 = Mot 3
        // Note: Si ta data_mem s'appelle 'ram' à l'intérieur, change data_mem.mem en data_mem.ram
        // Note 2: Si ta data_mem n'ignore pas les bits de poids faible, utilise les index [0], [4], [8], [12]
        
        `ASSERT_EQ("Test ADDI (x5 = 10 à l'index 0)", data_mem.mem[0], 32'd10)
        `ASSERT_EQ("Test ADDI (x6 = 20 à l'index 1)", data_mem.mem[1], 32'd20)
        `ASSERT_EQ("Test ADD (x7 = 30 à l'index 2)",  data_mem.mem[2], 32'd30)
        `ASSERT_EQ("Test SUB (x8 = 10 à l'index 3)",  data_mem.mem[3], 32'd10)

        $display("");
        $display("SUCCES TOTAL : Groupe 1 (Post-Routage Validé !)");
        $display("");
        
        $finish;
    end
      
    initial begin
        $dumpfile("top_tb_1_pr.vcd");
        $dumpvars(0, top_tb_1_pr);  
    end

endmodule