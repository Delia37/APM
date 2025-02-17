`timescale 1ns / 1ps

module RISC_V(input clk,
              input reset,
              
              output [31:0] PC_EX,
              output [31:0] ALU_OUT_EX,
              output [31:0] PC_MEM,
              output PCSrc,
              output [31:0] DATA_MEMORY_MEM,
              output [31:0] ALU_DATA_WB,
              output [1:0] forwardA, forwardB,
              output pipeline_stall
             );
// controlul etapelor pipelineului       
wire IF_ID_write; // actovarea scrierii in IF/ID
wire PC_write;  // activarea scrierii in PC
wire PCSrc_V; // determinare daca fac sau nu un salt
wire [31:0] PC_Branch_ID;  // adresa tinta pt salt ID
wire [4:0] RD_WB;

// id
wire [31:0] PC_ID,INSTRUCTION_ID,IMM_ID,REG_DATA1_ID,REG_DATA2_ID;
wire [2:0] FUNCT3_ID;
wire [6:0] FUNCT7_ID,OPCODE_ID;
wire [4:0] RD_ID,RS1_ID,RS2_ID;

wire zero_ID,RegWrite_ID,MemtoReg_ID,MemRead_ID,MemWrite_ID,Branch_ID,ALUSrc_ID;
wire [1:0] ALUop_ID;

// ex
wire [31:0] INSTRUCTION_EX,IMM_EX,REG_DATA1_EX,REG_DATA2_EX;
wire [2:0] FUNCT3_EX;
wire [6:0] FUNCT7_EX,OPCODE_EX;
wire [4:0] RD_EX,RS1_EX,RS2_EX;

wire zero_EX,RegWrite_EX,MemtoReg_EX,MemRead_EX,MemWrite_EX,Branch_EX,ALUSrc_EX;
wire [1:0] ALUop_EX;

wire [31:0] ALU_OUT_EX_l;
wire [31:0] PC_Branch_EX;
wire [31:0] REG_DATA2_EX_FINAL;

//mem
wire zero_MEM,RegWrite_MEM,MemtoReg_MEM,MemRead_MEM,MemWrite_MEM,Branch_MEM,ALUSrc_MEM;
wire [1:0] ALUop_MEM;
wire [4:0] RD_MEM;
wire [31:0] PC_Branch_MEM;
wire [31:0] ALU_OUT_MEM;
wire [31:0] REG_DATA2_MEM_FINAL;

// wb
wire zero_WB,RegWrite_WB,MemtoReg_WB,MemRead_WB,MemWrite_WB,Branch_WB,ALUSrc_WB;
wire [1:0] ALUop_WB;
wire [31:0] READ_DATA_WB;
wire [31:0] ALU_OUT_MEM_WB;

  //////////////////////////////////////////IF signals////////////////////////////////////////////////////////
  wire [31:0] PC_IF;               //current PC
  wire [31:0] INSTRUCTION_IF;

 
 /////////////////////////////////////IF Module/////////////////////////////////////
 IF instruction_fetch(clk, reset, 
                      PCSrc, PC_write,
                      PC_Branch,
                      PC_IF,INSTRUCTION_IF);
  
  
 //////////////////////////////////////pipeline registers////////////////////////////////////////////////////
 IF_ID_reg IF_ID_REGISTER(clk,reset,
                          IF_ID_write,
                          PC_IF,INSTRUCTION_IF,
                          PC_ID,INSTRUCTION_ID);
  
  
 ////////////////////////////////////////ID Module//////////////////////////////////
 ID instruction_decode(clk,
                       PC_ID,INSTRUCTION_ID,
                       RegWrite_WB, 
                       ALU_DATA_WB,
                       RD_WB,
                       IMM_ID,
                       REG_DATA1_ID,REG_DATA2_ID,
                       FUNCT3_ID,
                       FUNCT7_ID,
                       OPCODE_ID,
                       RD_ID,
                       RS1_ID,
                       RS2_ID);
 // detectare hazard
 hazard_detection H_D(RD_EX,
                      RS1_ID,
                      RS2_ID,
                      MemRead_ID,
                      PC_write,
                      IF_ID_write,
                      pipeline_stall);
 
 
 // instantierea modulului pt calea de control
 control_path control(OPCODE_ID,
                      pipeline_stall,
                      RegWrite_ID,MemtoReg_ID,MemRead_ID,MemWrite_ID,Branch_ID,ALUSrc_ID,
                      ALUop_ID);
 
//Instantierea modulului pt registrul ID/EX
ID_EX_reg ID_EX_pipeline(clk,reset,
                              zero_ID,RegWrite_ID,MemtoReg_ID,MemRead_ID,MemWrite_ID,Branch_ID,ALUSrc_ID,
                              ALUop_ID,
                              FUNCT3_ID,
                              RD_ID,
                              RS1_ID,
                              RS2_ID,
                              FUNCT7_ID,
                              OPCODE_ID,
                              REG_DATA1_ID,REG_DATA2_ID,
                              PC_ID,
                              IMM_ID,
                              
                              zero_EX,RegWrite_EX,MemtoReg_EX,MemRead_EX,MemWrite_EX,Branch_EX,ALUSrc_EX,
                              ALUop_EX,
                              FUNCT3_EX,
                              RD_EX,
                              RS1_EX,
                              RS2_EX,
                              FUNCT7_EX,
                              OPCODE_EX,
                              REG_DATA1_EX,REG_DATA2_EX,
                              PC_EX,
                              IMM_EX);

// instantiere modul EX
EX ex(IMM_EX,
      REG_DATA1_EX,
      REG_DATA2_EX,
      PC_EX,
      FUNCT3_EX,
      FUNCT7_EX,
      RD_EX,
      RS1_EX,
      RS2_EX,
      RegWrite_EX,
      MemtoReg_EX,
      MemRead_EX,
      MemWrite_EX,
      ALUop_EX,
      ALUSrc_EX,
      Branch_EX,
      forwardA,forwardB,
      
      ALU_DATA_WB,
      ALU_OUT_MEM,
      
      zero_EX,
      ALU_OUT_EX,
      PC_Branch_EX,
      REG_DATA2_EX_FINAL);

// instantierea modulului de forwarding
forwarding fw(RS1_EX,
              RS2_EX,
              RD_MEM,
              RD_WB,
              RegWrite_MEM,
              RegWrite_WB,
              forwardA,forwardB);

// instantierea moduluiui pt registrul EX/MEM
EX_MEM EX_MEM_pipeline(clk,reset,
                                FUNCT3_EX,
                                zero_EX,RegWrite_EX,MemtoReg_EX,MemRead_EX,MemWrite_EX,Branch_EX,ALUSrc_EX,
                                ALUop_EX,
                                RD_EX,
                                PC_Branch_EX,
                                ALU_OUT_EX,
                                REG_DATA2_EX_FINAL,
                                
                                FUNC3_MEM,
                                zero_MEM,RegWrite_MEM,MemtoReg_MEM,MemRead_MEM,MemWrite_MEM,Branch_MEM,ALUSrc_MEM,
                                ALUop_MEM,
                                RD_MEM,
                                PC_MEM,
                                ALU_OUT_MEM,
                                REG_DATA2_MEM_FINAL
                                );
                                  
// determin daca se face sau nu salt cond                             
assign PCSrc_V = zero_MEM & Branch_MEM;
assign PCSrc = PCSrc_V;   
                   
//Instantierea modulului de memorie de date           
data_memory dm(clk,
               MemRead_MEM,
               MemWrite_MEM,
               ALU_OUT_MEM,
               REG_DATA2_MEM_FINAL,
               DATA_MEMORY_MEM
               );
//   memory memory_mod( clk, 
//                MemRead_MEM, MemWrite_MEM, Branch_MEM, zero_MEM,
//                FUNC3_MEM,
//                REG_DATA2_MEM,
//                ALU_OUT_MEM,
//                PCSrc,// era PC_MEM dar cred ca trebuie PCSr
//                DATA_MEMORY_MEM);                 

//instatierea modulului registru mem/wb
MEM_WB MEM_WB_pipeline(clk,reset,
                                zero_MEM,RegWrite_MEM,MemtoReg_MEM,MemRead_MEM,MemWrite_MEM,Branch_MEM,ALUSrc_MEM,
                                ALUop_MEM,
                                RD_MEM,
                                DATA_MEMORY_MEM,
                                ALU_OUT_MEM,
                                
                                zero_WB,RegWrite_WB,MemtoReg_WB,MemRead_WB,MemWrite_WB,Branch_WB,ALUSrc_WB,
                                ALUop_WB,
                                RD_WB,
                                READ_DATA_WB,
                                ALU_OUT_MEM_WB
                                );
                                
mux2_1 MUX_WB(ALU_OUT_MEM_WB,READ_DATA_WB,MemtoReg_WB,ALU_DATA_WB);

endmodule