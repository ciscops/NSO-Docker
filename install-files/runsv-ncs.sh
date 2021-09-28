printf "=====> Starting $prog\n"
setup_ncs_environment
$ncs --foreground --cd ${rundir} ${heart} ${conf}
