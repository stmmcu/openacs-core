# tracks each file by interpreter to ensure that it is up-to-date

ad_proc -public watch_files {} {
  
  set files [list ats/paginator-procs.tcl ats/query-procs.tcl \
                  ats/debug-procs.tcl ats/filter-procs.tcl ats/util-procs.tcl]

  foreach file $files { 

    set file [ns_info tcllib]/$file

    set proc_name [info procs ::template::mtimes::tcl::$file]
    set mtime [file mtime $file]

    if { [string equal $proc_name {}] || $mtime != [$proc_name] } {

      uplevel #0 "source $file"
      proc ::template::mtimes::tcl::$file {} "return $mtime"
    }
  }
}
