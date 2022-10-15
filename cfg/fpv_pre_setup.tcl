# fpv_pre_setup
# DONT USE YET : prt2log "INFO : (fpv_setup) FPV_PRE_SETUP Started"
puts "INFO : (fpv_setup) FPV_PRE_SETUP Started"
# assume -remove {.*TCL.*} -regexp



### ==================================================
### Global Variables
### ==================================================
# read from fpv_template.tcl
# Gilboa : must set again fv_top_module since cannot set it in fpv_template.txt
set fv_top_module training_arbiter

# before : set fv_top_module  $fv_dut
set fv_dut  $fv_top_module
### Load ScoreBoard parameter definitions
jasper_scoreboard_3 -init

if {[info exists out_dir] == 0} { set out_dir $env(PWD) }

### ==================================================
### Settings of for fpv_template
### ==================================================
# set fpv_permutations   [list \
#      { {define FPV_PERM 1_NO_SYNC} \
#        {elab_params -parameter GATE 0 -parameter DELAY_FF 1 -parameter FF_STAGES 0 -parameter DELAY_STROBE 0 -parameter SYNC 0 -parameter SCAN 0 -parameter DFT_SCAN 0} \
#        {run_post_proof {fpv_gen_report 1_NO_SYNC } } \
#      }  \
#      { {define FPV_PERM 2_SYNC} \
#        {elab_params -parameter GATE 0 -parameter DELAY_FF 1 -parameter FF_STAGES 5 -parameter DELAY_STROBE 0 -parameter SYNC 1 -parameter SCAN 0 -parameter DFT_SCAN 0} \
#        {run_post_proof {fpv_gen_report 2_SYNC } } \
#      }  \
#      { {define FPV_PERM 3} \
#        {elab_params -parameter GATE 0 -parameter DELAY_FF 1 -parameter FF_STAGES 5 -parameter DELAY_STROBE 0 -parameter SYNC 1 -parameter SCAN 0 -parameter DFT_SCAN 0} \
#        {run_post_proof {fpv_gen_report 3_SYNC_5FF } } \
#      }  \
#      ]
# 

### ==================================================
### Find source DA direactory path
### ==================================================
if {[array get env CCD_DA_PATH] == ""} {
    set CCD_DA_PATH /nfs/site/proj/ccd/ccd_da
} else {
    set CCD_DA_PATH $env(CCD_DA_PATH)
}
if {[array get env JASPER_DA] == ""} {
    set JASPER_DA $CCD_DA_PATH/release/tools/cadence/jasper/
    # Private gvardi : set JASPER_DA /nfs/site/proj/ccd/ccd_da/dev/gvardi/tools/cadence/jasper/
} else {
    set JASPER_DA $env(JASPER_DA)
}
### ==================================================
### remove the STOP PROVE file
### ==================================================
if {[file exists stop_jg_tcl_now] == 1} {
  file delete stop_jg_tcl_now -force
}
### ==================================================
### Generic Jasper PROCs
### ==================================================
foreach proc { clone } {
    if {[file exists $JASPER_DA/${proc}.tcle] == 1} {
        source $JASPER_DA/${proc}.tcle
    }
    if {[file exists $JASPER_DA/${proc}.tcl] == 1} {
        source $JASPER_DA/${proc}.tcl
    }
}
### ==================================================
### PROCs
### ==================================================
proc getdatetime {} {
    ### Funny Jaspers override native tcl clock command .... When will they learn namespaces ?????
    if {[info commands tcl_clock] != ""} {
        set datetime [tcl_clock format [tcl_clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    } else {
        set datetime [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    }
return $datetime
}
proc prt2log { args } {
    set datetime [getdatetime]
    set msg "$datetime : $args"
    eval puts { $msg }
}
proc fpv_prove_status { } {
	redirect  -file jg_prove.status.rpt -force { puts " ======= Proof Grid Status =======" }
	redirect  -file jg_prove.status.rpt -append { getdatetime }
	redirect  -file jg_prove.status.rpt -append { prove -status }
	redirect  -file jg_prove.status.rpt -append { prove -status -detailed  }
}
### =================
# if {not defined env(NB_REQ_SLOT) }  { } set env(NB_REG_SLOT) $env(NB_QSLOT)
set env(NB_REG_SLOT) /pccg_ccd/logic/tbt
 
set jg_has_gui [expr [get_tool -batch] == "false"]
if {$jg_has_gui} { 

    # set default signal list for any visualize (works with double-click)
    set_visualize_preload_signal_list ../sig/default.sig
proc fpv_viscex_sel {} {
    set prop [gui -query -target -app_view fpv -widget property_table -selection]
    set prop [string replace $prop end end]
    fpv_viscex_prop $prop
}
proc fpv_viscex_prop {prop} {
    global fv_top_module
    ### Save proofgrid mode, show CEX using local machine (dont wait for NB)
    set saved_proofgrid_mode [get_proofgrid_mode]
    set_proofgrid_mode local
    set sigfile "../sig/$prop.sig"
       if { [file exists ${prop}.sig] == 1 } {
           set sigfile " ../sig/$prop.sig "
       } else {
          if { [regexp "FVENV" $prop ] && [file exists ../sig/default_FVENV.sig] == 1 } {
           prt2log "FPV INFO : Signal file $prop.sig not found"
           set sigfile { ../sig/default_FVENV.sig }
       }  else {
           prt2log "FPV INFO : Signal file using default.sig "
           set sigfile { ../sig/default.sig }
       }
       }
       prt2log "FPV INFO : Running .... \n visualize -violation -property  $prop -annotation $prop"
       visualize -violation -property  $prop \
       -annotation "$prop" -new_window

       # OLD fixed by CDNS : visualize -violation -property  <embedded>::${fv_top_module}.fv_${fv_dut}_top.$prop \
       ##     -sig_order $sigfile 
       visualize -add_sig -file $sigfile

    ### restore proofgrid mode
    set_proofgrid_mode $saved_proofgrid_mode 
}
} ; # if jg_has_gui


set jg_has_gui [expr [get_tool -batch] == "false"]
if {$jg_has_gui} { 
### ==================================================
### Configure GUI
### ==================================================
custom_gui_action -force -add ClearRun -window fpv \
        -script { \
            set datetime [date] ; \
            clear -all ; \
            puts "+##################################+" ; \
            puts "|    FPV Rerun TCL script          |" ; \
            puts "|  $datetime                       |" ; \
            puts "+##################################+" ; \
            source $JASPER_DA/fpv_setup.tcl} \
        -iconfile /p/dt/fvcoe/pub/tools/JG/latest/etc/res/images/expand_icon.png  
            #        Thu Jan 19 17:17:55 IST 2017

custom_gui_action -force -add VisCex -window fpv \
        -script { fpv_viscex_sel } \
        -iconfile /p/dt/fvcoe/pub/tools/JG/latest/etc/res/images/collapse_icon.png  
}
### ==================================================
### Reporting procs
### ==================================================
proc fpv_gen_report {{header default} } {
    global env

    set resrptscript "$env(HOME)/bin/gjg_results"
    set rptfile "jg_${header}.rpt"
    set tmpfile  "jglog_res.rpt" ; # generated by my gjg_results
    set resrptfile "jg_${header}_res.rpt"

    report -force -file $rptfile
    if {[file exists $rptfile] == 1} {exec $resrptscript $rptfile}
    if {[file exists $tmpfile] == 1} {file rename -force $tmpfile $resrptfile}
    report -summary -append -file $rptfile
}

proc fpv_check_stop_jg_tcl_now { } {
  if {[file exists stop_jg_tcl_now] == 1} {
      prt2log "FPV INFO: STOPPED JG TCL NOW by file stop_jg_tcl_now"
      prove -stop
      prove -wait
      source ../cfg/fpv_post_proof.tcl
      break
  }
}    
prt2log "INFO : (fpv_setup) FPV_PRE_SETUP is done"

