### fpv_post_proof.tcl
proc fpv_post_proof {} {global env ; source ../cfg/fpv_post_proof.tcl}
###
prt2log "INFO : (fpv_setup) FPV_POST_PROOF START"
### Sleep 5 seconds
prt2log "INFO : (fpv_setup) Wait 5 secs for proof to complete ......."
after 5000
## Report results into file.  (optional)
if {[info exists out_dir] == 0} { set out_dir $env(PWD) }
### Jasper native format report (jg.rpt=plain, unsorted)
report -force -file jg.rpt
file copy -force jg.rpt jglog_res.rpt
### CCD formatted report (jg_default.rpt=plain+summary, jglog_res.rpt=sorted )
fpv_gen_report
### ND fpv_run report (<topmodule>_res.csv, unsorted)
create_report
set pp  "jgproject/"  
file copy -force [append pp [file readlink jgproject/jg.log] ] ./jg.log

prt2log "INFO : (fpv_setup) FPV_POST_PROOF is done"

