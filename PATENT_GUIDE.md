# Patent Filing Guide
## Project: Low-Latency Pipelined RISC-V 32-bit Processor

---

## ⚠️ IMPORTANT NOTE FIRST

Before filing a patent, understand:
- **RISC-V ISA itself** is open standard (owned by RISC-V International) — you cannot patent the ISA
- **Your specific microarchitecture implementation** is potentially patentable
- What's novel in YOUR design must be clearly identified and different from prior art
- Student projects at REVA University may fall under university IP policy — check with your institution first

---

## WHAT IS PATENTABLE IN YOUR PROJECT

Your project contains these potentially novel/protectable elements:

### 1. Combined Hazard Mitigation Architecture
Your design integrates:
- Dual-path forwarding (EX→EX AND MEM→EX simultaneously)
- Load-use stall detection combined with selective flushing
- Branch comparator that is separate from the main ALU (avoids occupying ALU for branch resolution)

### 2. Unified Control Signal Pipeline
- A `wb_sel[1:0]` 3-way mux (ALU result / Memory data / PC+4) that cleanly handles JAL/JALR writeback without extra adders
- Carrying `pc_plus4` as a separate pipeline field for jump instructions

### 3. Configurable Flush-Stall Priority Logic
- The priority arbitration: `flush_pipe` takes precedence over `stall`, which takes precedence over normal advance
- This prevents data corruption when a branch/jump is detected simultaneously with a load-use hazard

---

## PATENT TYPES TO CONSIDER

| Type | Suitable For | Filing Authority |
|------|-------------|-----------------|
| **Indian Patent** (Provisional) | First step — establishes filing date | Indian Patent Office (IPO) |
| **Indian Patent** (Complete) | Full protection, 20-year term | Indian Patent Office |
| **Design Patent** | Block-diagram architecture as design | IPO |

For a student project, start with an **Indian Provisional Patent Application** — it costs less and gives you 12 months to file the complete specification.

---

## STEP-BY-STEP: INDIAN PROVISIONAL PATENT FILING

### Step 1 — Decide Ownership
Contact REVA University's **IP Cell / Technology Transfer Office**:
- Determine if the university has joint IP rights
- Get a "No Objection Certificate" (NOC) if filing individually
- Alternatively, file jointly with REVA University

### Step 2 — Prepare the Application

#### Required Documents:
1. **Form 1** — Application for Grant of Patent (download from ipindia.gov.in)
2. **Form 2** — Provisional/Complete Specification
3. **Statement of Inventorship** (Form 5 for PCT, not needed for provisional)

#### Form 2 — Provisional Specification must contain:

**Title:**
> "A Low-Latency Five-Stage Pipelined RISC-V 32-bit Processor Architecture with Integrated Dual-Path Data Forwarding and Combined Hazard Mitigation"

**Field of Invention:**
> Digital integrated circuit design, computer architecture, FPGA-based processor design

**Background / Problem Statement:**
- Single-cycle RISC-V processors suffer from high latency (one instruction per multiple clock cycles)
- Existing pipelined designs either use complex branch predictors (high area) or suffer high pipeline stall penalties
- Data hazards in pipelined architectures require stall cycles that reduce throughput

**Summary of Invention:**
> A five-stage pipelined RV32I processor implemented in synthesizable Verilog HDL, featuring:
> (a) dual-path EX→EX and MEM→EX data forwarding to eliminate most RAW stalls
> (b) a load-use hazard detection unit that inserts exactly one stall cycle when required
> (c) a dedicated branch condition comparator (separate from the ALU) to resolve all branch types (BEQ, BNE, BLT, BGE, BLTU, BGEU) in the EX stage
> (d) a 3-way write-back selector (wb_sel[1:0]) supporting ALU result, memory load data, and PC+4 (for JAL/JALR)

**Claims (Provisional — broad):**
1. A pipelined processor comprising five stages: Instruction Fetch, Instruction Decode, Execute, Memory Access, and Write Back, wherein said processor implements the RISC-V RV32I instruction set.
2. The processor of claim 1, further comprising a data forwarding unit configured to supply results from the EX/MEM pipeline register and the MEM/WB pipeline register to the execute stage ALU inputs.
3. The processor of claim 1, wherein a hazard detection unit monitors the ID/EX pipeline register's MemRead signal to detect load-use hazards and asserts a stall signal to freeze the program counter and IF/ID register for one clock cycle.
4. The processor of claim 1, wherein branch conditions are evaluated by a dedicated comparator circuit operating on forwarded register values, independent of the arithmetic logic unit.

**Brief Description of Drawings:**
- Figure 1: Block diagram of the five-stage pipeline
- Figure 2: Forwarding unit logic diagram
- Figure 3: Hazard detection unit
- Figure 4: Waveform showing pipeline operation and hazard resolution

**Detailed Description:**
(Attach your project report — Chapter 3 Methodology and Block Diagram section)

### Step 3 — File Online

1. Go to: **https://ipindiaonline.gov.in/epatentfiling**
2. Register as applicant → Login
3. Click **"Patent Application"** → **"Provisional Application"**
4. Fill Form 1:
   - Applicant: Your names + REVA University (if joint)
   - Address: REVA University, Kattigenahalli, Yelahanka, Bangalore-560064
5. Upload Form 2 (Provisional Specification as PDF)
6. Pay filing fee:
   - Individual/Startup: ₹1,600 (online)
   - Educational Institution: ₹4,000
7. Download the **Provisional Patent Application Number** (your priority date is established)

### Step 4 — Complete Specification (within 12 months)

Within 12 months of provisional filing:
- File **Form 2 Complete Specification** with full claims, drawings, and abstract
- File **Form 9** — Request for Examination (₹4,000 for educational institution)
- The patent will be examined and published in the Official Patent Journal

---

## EVIDENCE TO COLLECT NOW (for patent support)

Build your evidence file:
1. **Vivado simulation screenshots** — timestamped (proving reduction to practice)
2. **Waveform screenshots** showing forwarding, stall, and branch flush working
3. **Git commit history** or dated files showing development timeline
4. **Lab notebook / project logbook** with dates
5. **Your Phase-2 project report** (already submitted November 2025)
6. **Synthesis report** from Vivado showing resource utilization

---

## PRIOR ART DIFFERENTIATION

Your claims must be distinguishable from:
- Patterson & Waterman's standard RISC-V pipeline (textbook design)
- RVCoreP by Miyazaki et al. (2020) — FPGA-optimized RV32I
- NRP Processor by Li et al. (2024) — optimized decode and branch handling

**Your differentiation**: Focus on the **architectural combination** of all four features (forwarding + hazard detection + dedicated comparator + 3-way wb_sel) as a unified integrated system in synthesizable Verilog targeting low-latency embedded SoC applications.

---

## COST SUMMARY (India)

| Item | Cost |
|------|------|
| Provisional Application (Educational) | ₹4,000 |
| Complete Specification (Educational) | ₹4,000 |
| Request for Examination | ₹4,000 |
| Patent Attorney (optional but recommended) | ₹15,000–₹50,000 |
| **Total (DIY)** | **≈ ₹12,000** |

---

## HELPFUL CONTACTS

- **Indian Patent Office Bangalore**: Patent Office, Intellectual Property Building, G.S.T. Road, Guindy, Chennai-600032 (handles Karnataka filings)
- **IPO Online Portal**: https://ipindiaonline.gov.in
- **REVA University IP Cell**: Contact your HOD or Director's office
- **NASSCOM / Startup India**: Free IP support programs for student innovators
