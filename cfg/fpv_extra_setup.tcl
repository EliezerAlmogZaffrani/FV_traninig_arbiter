# fpv_extra_setup.tcl

prt2log "INFO : (fpv_setup) FPV_EXTRA_SETUP Started"

### ==================================================
### General Proof settings
### ==================================================
### General default Grid mode
set fpv_proofgrid_mode local  ;# local/shell , like Jasper values, shell==NetBatch
set fpv_use_orchestration off ;# on/off/auto like Jasper values
set fpv_use_abstract_cdc      off	;# Activate abstract CDC (jitter on synchronizers)
set fpv_scoreboard_3_engine_mode {G C B N Tri Hp Ht Hps Hts}
set fpv_all_engine_mode {Tri Hp Ht Hps Hts Bm C C2 G G2 I J L R B K N Q3 U AB AD AG AM TA}
set fpv_shell_engine_threads 5 ;#up to 5   ;# per-engine Threads for shell (Netbatch) mode only

#### =================================================
### NetBatch settings
### =================================================
# default for local run:
set_engine_threads 1
### Send NB log files into jgproject dir (so it will be erased every new run)
set NB_logfiles "jgproject/NB_logfiles"
file mkdir $NB_logfiles
if {[file exists NB_logfiles] == 0 } {
    file link NB_logfiles $NB_logfiles
}
if {[array get env NB_QSLOT] == ""} {
    set NB_QSLOT ccd_logic_tbt_int
} else {
    set NB_QSLOT $env(NB_QSLOT)
}
### =================================================
### PPD/JGES/JGIS settings - save previous run result and use it
### =================================================

### First, Extract all design parameters into TCL array
array set fv_params_ar [ get_design_info -instance fv_${fv_dut}_top -list parameter]
# set FV_WR_CLK_CCS $fv_params_ar(FV_WR_CLK_CCS)
# set FV_RD_CLK_CCS $fv_params_ar(FV_RD_CLK_CCS)
# set FV_WR_CLK_PHS $fv_params_ar(FV_WR_CLK_PHS)
# set FV_RD_CLK_PHS $fv_params_ar(FV_RD_CLK_PHS)

### =================================================
### TCL ASSUMES, RESTRICTS
### =================================================
include ../src/fv_${fv_dut}_assume.tcl
include ../src/fv_${fv_dut}_restrict.tcl

### =================================================
### more clocks for multiple independent clocks
### =================================================
# clock fv_${fv_dut}_top.FV_clk wr_clk $FV_WR_CLK_CCS $FV_WR_CLK_PHS
# clock fv_${fv_dut}_top.FV_clk rd_clk $FV_RD_CLK_CCS $FV_RD_CLK_PHS


### rate (tie input signal change to their clock)
# clock -rate {wr_en wr_flush fv_${fv_dut}_top.FV_free_wr_flush} wr_clk
# clock -rate {rd_en rd_flush fv_${fv_dut}_top.FV_free_rd_flush} rd_clk
## no need to tie the data (rd_data/rd_ecc_err) - irrelevant 


# reset -clear
# reset { !wr_rst_n !rd_rst_n } 
### Extend the reset to 3 times Least Common Multiplier of both clocks
# reset -clear
# set FV_LCM_CLK_CCS [expr $FV_WR_CLK_CCS * $FV_RD_CLK_CCS * 6]
# reset { !wr_rst_n !rd_rst_n } -max_iteration $FV_LCM_CLK_CCS

### ==================================================
### Abstract CDC - jitter on synchronizers inputs
### ==================================================
# Example : % abstract -cdc -inject {bridge.xb.ofifo[0].ififo[0].ififo_i.pop_wr_ptr_sync.ff_model.ff}
if {[string equal $fpv_use_abstract_cdc on] == 1} {
    abstract -cdc
}

### ==================================================
### Configure Netbatch
### ==================================================
if {[string equal $fpv_proofgrid_mode shell] == 1} {
    # set_netbatch {max_licenses 1} {requirements "128G"}
    ### Format : "ijl_set_netbatch_mode nbpool nbq nbclass max_lic ?other_opts?"
    ### TBD Gilboa does not support extra args for ijl_set_netbatch, like log directory redirection
    # set_netbatch 1 pool iil_normal slot ccd_logic_tbt requirements 20G&&SLES11&&BIOSHTOFF&&4C  "--log-file-dir jgproject/NB_logfiles"
    # set_netbatch 1 pool iil_normal slot ccd_logic_tbt requirements 20G&&SLES11&&BIOSHTOFF&&4C
    prt2log "INFO : set_netbatch :  ijl_set_netbatch_mode iil_normal $NB_QSLOT 20G&&SLES11&&BIOSHTOFF&&4C 1 "
    # ijl_set_netbatch_mode <pool>   <qslot>        <requirements>        <lics=maxeng> <extra NBrun params....>
    ijl_set_netbatch_mode iil_normal $NB_QSLOT 20G&&SLES11&&BIOSHTOFF&&5C 1 "--log-file-dir $NB_logfiles"
    ### For short-fast Qslot :
    # ijl_set_netbatch_mode iil_short ccd_logic_fast 20G&&SLES11&&BIOSHTOFF&&4C 1 "--log-file-dir $NB_logfiles"
    ### For each NB machine - take 5 threads per engine (does not take more licenses????)
    set_engine_threads $fpv_shell_engine_threads
}
### ==================================================
### Configure JGES expert system
### ==================================================
# disable Visualize recomendation
expert_system -rule -disable DBG025
expert_system -rule -disable PFC101 ;# PFC101: Abstract counters (Disabled)
expert_system -rule -disable ENV016 ;# ENV016: Check if task is overconstrained (Disabled)
expert_system -rule -disable PFC009 ;# PFC009: Run sequentially deep properties with optimized engine set (Disabled)
expert_system -rule -disable DBG010 ;# DBG010: Learn more about handling Visualize overconstraints (Disabled)
expert_system -rule -disable PFC201 ;# PFC201: Disable assumptions with unreachable preconditions (Disabled)
expert_system -rule -disable ENV006 ;# ENV006: Analyze overconstrained properties (Disabled)
### ==================================================
### Configure Engines
### ==================================================
### Global target_bound "consider-as-passed" (marks with bounded v, but does not stop the engines)
# set_prove_target_bound 200
# set_prove_verbosity 5 ;# default 6
# for Liveness :
# set fpv_liveness_engine_mode {Tri Ht  Hts B Bm K }
set fpv_liveness_engine_mode {Tri Ht  Hts B Bm K G G2 AG C C2}
 

# With dynamic simulation engines : Q3, U, J
# set_engine_mode {Hp Ht Bm B D K M N Hps Hts L Q3 U AB AG AD AM TA}
### With hunt that runs L, B and simengines J,Q,U - no need for these in 'prove'
### Added TM Trace Minimization and QT for quite trace
set_engine_mode {Hp Ht D K M N Hps Hts AB AG AD AM TM QT}
# set_engine_mode {Hp Ht Bm B D K M N Hps Hts L}
# Jasper default : set_engine_mode {Hp Ht B D }
# ALL : set_engine_mode {Bm J Q3 U L R B K N H Hp Ht Hps Hts AB AG AD AM TA}
#
set_proofgrid_per_engine_max_jobs 1
set_proofgrid_per_engine_max_local_jobs 1
set_proofgrid_max_jobs 20
set_proofgrid_max_local_jobs 15
set_prove_per_property_time_limit 1s
# fpv_run default : set_prove_per_property_time_limit 30s
set_prove_per_property_time_limit_factor 3
set_proof_simplification on

### HUNT command configurations
### WARNING : each HUNT with a single engine (CS==engineB , SS==engineL etc...) takes max_jobs licenses !!!!!
hunt -config -strategy CS   -mode cycle_swarm -max_jobs 5 -time_limit 10m
hunt -config -strategy CS_2 -mode cycle_swarm -max_jobs 5 -time_limit 1d -first_trace_attempt {30:[50..80] 70:[80..100]}
hunt -config -strategy SS   -mode state_swarm -max_jobs 5 -time_limit 10m
hunt -config -strategy SIM  -mode simulation  -max_jobs  5 -time_limit 10m
hunt -config -strategy FORMAL  -mode formal   -max_jobs  5 -time_limit 10m

### New engineL (LeapFrog with covers with L-state-swarm technique)
#set_engineL_start_state_count 8
#set_engineL_tail_length 2
#set_engineL_max_segment_length 5
#set_engineL_segment_time_limit 30s

### New engineB (Elastic BMC with B-swarm technique)
#set_engineB_first_trace_attempt 40
#set_engineB_trace_attempt_increment 2
#set_engineB_trace_attempt_time_limit 60s
#set_engineB_before_first_mode skip
#set_engineB_before_increment_mode skip
set_engineB_bounded_proven_directive on

### prevent engine Tri to take over a whole machine
_set_property tri_threads 1


# ### =================================================
### Visualize, CEX, covers
### =================================================
### Extend the loop CEX with more cycles (= loop length)
# _set_property liveness_loop_unroll 3

### =================================================
### TASKS
### =================================================


### ==================================================
### Runtime
### ==================================================
get_design_info
# PROVE ALL
#     prove -all -bg
analyze -clear

### ===================================================
### Check FV module - sanity, files locations, parameters
### ===================================================
set saved_proofgrid_mode [get_proofgrid_mode]
set_proofgrid_mode local
set_engine_threads 1
# Gilboa/fpv_run  - If bind command returns more than 1 module - fail. must specify fv_top explicitly
## check_fv_module
## check_fv_module fv_${fv_dut}_top
### send to file and checkin
redirect -force -file fpv_check_fv_module.rpt { check_fv_module fv_${fv_dut}_top }
### restore proofgrid mode
set_proofgrid_mode $saved_proofgrid_mode 
if {[string equal [get_proofgrid_mode] "shell"] == 1} {
    set_engine_threads $fpv_shell_engine_threads
}
### ===================================================

# prove -all -time_limit 4d
### run engine L
# prove -engine_mode L  -property {.*COVER_L_.* .*slc_full.*  .*slice_full.* } -regexp -time_limit 24h -bg

### Jasper Scoreboard_3
### start with one scoreboard per outpath, single outpath=8
#if {[string equal $fpv_run_prove_stage_5_scoreboard "on"] == 1} {
#    prove -bg -property <embedded>::${fv_dut}.*scoreboard* \
#	-engine_mode $fpv_scoreboard_3_engine_mode
#    ### Try hunting deeper , since scoreboard prove did not complete
#    hunt -run -bg -strategy CS_2 -property *data_integrity* *no_overflow*
#	fpv_check_stop_jg_tcl_now
#}
### ALL :
# set_engine_mode {Tri Hp Ht Hps Hts Bm C C2 G G2 I J L R B K N Q3 U AB AG AD AM TA}
# settings for 15-engines only
set_engine_mode {Tri Hp Ht Hps Hts Bm C G I B K N AM TA TM}
# set_engine_mode {Hp Ht Bm C C2 G G2 I J L R B K N Q3 U Tri}
set_prove_per_property_time_limit 1s
set_proofgrid_per_engine_max_local_jobs 1
set_proofgrid_per_engine_max_jobs 1

set saved_proofgrid_mode [get_proofgrid_mode]
set_proofgrid_mode local
set_engine_threads 1
### run all modes (documentation assertions) - this is first, very short (PRE)
prt2log 'INFO : execute : prove  -property ASRT_FV_MODE
prove -property .*ASRT_FV_MODE.*
set_proofgrid_mode $saved_proofgrid_mode
    if {[string equal [get_proofgrid_mode] "shell"] == 1} {
	set_engine_threads $fpv_shell_engine_threads
    }
fpv_check_stop_jg_tcl_now

### run FV_ENV - sanity check that must pass. remove it if too long
#### Dont run it on local machine  - save debug time.
if {[string equal [get_proofgrid_mode] shell] == 1} {
    prt2log 'INFO : execute : prove  -property ASRT_FVENV -time_limit 10m -bg'
    prove -bg -property .*ASRT_FVENV.* -regexp -time_limit 2m
    fpv_check_stop_jg_tcl_now
}
prove -bg -property .*ASRT_FVENV.* -regexp -time_limit 2m

### ---------------------------------------------------------------
### Jasper SCoreboard_3
# prove -property .*gen_async_fifo_cntrl.fpv_scoreboard_3.scoreboard.* \
#	-engine_mode $fpv_scoreboard_3_engine_mode
prove -property <embedded>::gen_async_fifo_cntrl.fpv_scoreboard_3.scoreboard.* \
    -engine_mode $fpv_scoreboard_3_engine_mode

### ---------------------------------------------------------------
### prevent engine Tri to take over a whole machine
# _set_property tri_threads 3
### Start with fast Tri engine, bg,
# prt2log 'INFO : execute : prove -all -bg -engine_mode Tri -per_property_time_limit 1s
# prove -all -bg -engine_mode Tri -per_property_time_limit 1s
fpv_check_stop_jg_tcl_now

### ================  lets go hunting ..... ======================================
# prt2log 'INFO : execute : hunt SS over SAFETY property with guiding COVERS'
# prt2log 'INFO : execute : hunt -run -bg -strategy SS -property { ASRT_what_goes_in_will_come_out_DEPTH_reads   *COVR_FV_DUT_used_space_counter }'

#hunt -run -bg -strategy SS \
#	-time_limit 2d \
#	-property { \
#	<embedded>::gen_async_fifo_cntrl.fv_gen_async_fifo_cntrl_top.ASRT_what_goes_in_will_come_out_DEPTH_reads  \
#	<embedded>::gen_async_fifo_cntrl.fv_gen_async_fifo_cntrl_top.GLBLidx1.*COVR_FV_DUT_used_space_counter \
#}
#
# prt2log 'INFO : execute : hunt -run -strategy CS -property ASRT_what_goes_in_will_come_out_DEPTH_reads'
# hunt -run -bg -strategy CS -property .*ASRT_what_goes_in_will_come_out_DEPTH_reads.* -time_limit 1d
## CS_2 : longer timeout
# prt2log 'INFO : execute : hunt -run -strategy CS_2 -property ASRT_what_goes_in_will_come_out_DEPTH_reads'
# hunt -run -bg -strategy CS_2 -property .*ASRT_what_goes_in_will_come_out_DEPTH_reads.* -time_limit 4d
fpv_check_stop_jg_tcl_now

### Try Bswarm with engineB - several attempts in parallel (note the licenses)
#prt2log 'INFO : execute : prove property .*_LIV_.* -engine_mode B'
#prove -property .*_LIV_.* -engine_mode B -bg -first_trace_attempt 30
#prove -property .*_LIV_.* -engine_mode B -bg -first_trace_attempt 50
#prove -property .*_LIV_.* -engine_mode B -bg -first_trace_attempt 100
#prove -property .*_LIV_.* -engine_mode B -bg -first_trace_attempt 200
fpv_check_stop_jg_tcl_now

# prove -all -time_limit 4d -bg
 

### =========  LIVENESS ===============================================
### Jasper recommendation from JGES for deep LIV properties : engines should be  G C AG N Tri
### Practical : Tri and Hps also do a good job. Bm is only for the covers of liveness
prt2log 'INFO : execute : prove -property ASRT_LIV -regexp -bg  -engine_mode $fpv_liveness_engine_mode -prove_time_limit 4d -per_property_time_limit 30s'
# set_proofgrid_per_engine_max_local_jobs 2
if {[string equal [get_proofgrid_mode] shell] == 1} {
    set_proofgrid_per_engine_max_jobs 2 	; # default 2
    set_proofgrid_per_engine_max_local_jobs 1
} else {
    set_proofgrid_per_engine_max_jobs 1
    set_proofgrid_per_engine_max_local_jobs 1
}
if {[string equal $fpv_use_orchestration on] == 1} {
    prove -bg -property .*ASRT_LIV.* -regexp        \
	-orchestration on                           \
	-time_limit 4d -per_property_time_limit 30s  \
	-per_engine_max_jobs 2
} else {
    prove -bg -property .*ASRT_LIV.* -regexp        \
	-engine_mode $fpv_liveness_engine_mode         \
	-time_limit 4d -per_property_time_limit 30s  \
	-per_engine_max_jobs 2
}

fpv_check_stop_jg_tcl_now
 

## Weekend NB regression
if {[string equal [get_proofgrid_mode] shell] == 1} {
    set_proofgrid_max_jobs 15		 ; # default 0 - unlimited
    set_proofgrid_max_local_jobs 15     ; # default 15
    set_proofgrid_per_engine_max_jobs 1 ; # default 2
    set_proofgrid_per_engine_max_local_jobs 1
    # Fewer engines (max_jobs)
    set_engine_mode {Tri Hp Ht Hps Hts Bm C G L B N Q3 QT}
    # with 24 engines : set_engine_mode {Tri Hp Ht Hps Hts Bm C C2 G G2 I J L R B K N Q3 U AB AD AG AM TA}
} else {
    set_proofgrid_max_jobs 15		 ; # default 15
    set_proofgrid_max_local_jobs 15	 ; # default 15
    set_proofgrid_per_engine_max_jobs 1
    set_proofgrid_per_engine_max_local_jobs 1
    set_engine_mode {Tri Hp Ht Hps Hts Bm N L R B Q3 QT}
}

### ---------------------------------------------------------------
### prove "-from" - compare bug hunting speed
### 1. prove the helper assertion (COVR_fifo_full)
# prove -property   <embedded>::gen_async_fifo_cntrl.fv_gen_async_fifo_cntrl_top.COVR_fifo_full
### 2. prove -from
# prove -property  <embedded>::gen_async_fifo_cntrl.fv_gen_async_fifo_cntrl_top.ASRT_what_goes_in_will_come_out_DEPTH_reads     -from  <embedded>::gen_async_fifo_cntrl.fv_gen_async_fifo_cntrl_top.COVR_fifo_full
fpv_check_stop_jg_tcl_now
### ---------------------------------------------------------------

# -orchestration $fpv_use_orchestration      \
#   -orchestration on -save_ppd ./jg_ppd 	\

### run a short prooof only for PRE stage (no engines)
prove -bg -simplification_only -all
fpv_check_stop_jg_tcl_now

### Finally prove all the rest .....
### Using the saved ppd from previous runs
# prove -bg -all                                  \
#    -time_limit 4d 				\
#    -per_property_time_limit 1m 		\
#	-orchestration on -with_ppd ./jg_ppd

### PROVE finally all the rest, full regression with no timelimit
#if {[string equal $fpv_run_prove_stage_8_ALL "on"] == 1} {
    prt2log "INFO : execute : prove -bg -all  orchestration $fpv_use_orchestration"
    prove -bg -all       				\
	-orchestration $fpv_use_orchestration      	\
	-time_limit 4d 					\
	-per_property_time_limit 1m 			\

fpv_check_stop_jg_tcl_now
#}

### Reporting moved to fpv_post_proof.tcl

# prove -stop - done now with avoid_prove 1 settings in fpv_template.txt
### Moved reporting stuff to fpv_post_proof.tcl
prt2log "INFO : (fpv_setup) FPV_EXTRA_SETUP IS DONE"

