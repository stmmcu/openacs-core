ad_library {

    Routines needed by the bootstrapper to load package code. 

    @creation-date 26 May 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id $Id$
}

# FIXME: Peter M - This file cannot be watched with the APM as it re-initializes 
# the reload level to 0 everytime it is sourced. Could we move these initialization 
# to an -init.tcl file instead?

# Initialize loader NSV arrays. See apm-procs.tcl for a description of
# these arrays.
nsv_array set apm_library_mtime [list]
nsv_array set apm_version_procs_loaded_p [list]
nsv_array set apm_reload_watch [list]
nsv_array set apm_package_info [list]
nsv_set apm_properties reload_level 0

proc_doc apm_first_time_loading_p {} { 
    Returns 1 if this is a -procs.tcl file's first time loading, or 0 otherwise. 
} {
    global apm_first_time_loading_p
    return [info exists apm_first_time_loading_p]
}

ad_proc ad_after_server_initialization { name args } {

    Registers code to run after server initialization is complete.

    @param name a human-readable name for the code block (for debugging purposes).
    @param args a code block or procedure to invoke.

} {
    nsv_lappend ad_after_server_initialization . [list name $name script [info script] args $args]
}

ad_proc apm_guess_file_type { package_key path } {

    Guesses and returns the file type key corresponding to a particular path
    (or an empty string if none is known). <code>$path</code> should be
    relative to the package directory (e.g., <code>www/index.tcl</code>
    for <code>/packages/bboard/admin-www/index.tcl</code>. We use the following rules:

    <ol>
    <li>Files with extension <code>.sql</code> are considered data-model files,
    <li>Files with extension <code>.csv</code> are considered comma-separated values files.
    <li>Files with extension <code>.ctl</code> are considered sql data loader control files.
    or if any path contains the substring <code>upgrade</code>, data-model upgrade
    files.
    <li>Files with extension <code>.sqlj</code> are considered sqlj_code files.				       
    <li>Files with extension <code>.info</code> are considered package specification files.
    <li>Files with extension <code>.xql</code> are considered query files.
    <li>Files with extension <code>.java</code> are considered java code files.
    <li>Files with extension <code>.jar</code> are considered java archive files.
    <li>Files with a path component named <code>doc</code> are considered
    documentation files.
    <li>Files with extension <code>.pl</code> or <code>.sh</code> or
        which have a path component named
    <code>bin</code>, are considered shell-executable files.
    <li>Files with a path component named <code>templates</code> are considered
    template files.
    <li>Files with extension <code>.html</code> or <code>.adp</code>, in the top
    level of the package, are considered documentation files.
    <li>Files with a path component named <code>www</code> or <code>admin-www</code>
    are considered content-page files.
    <li>Files ending in <code>-procs(-)+()*.tcl)</code> or <code>-init.tcl</code> are considered
    Tcl procedure or Tcl initialization files, respectively.
    <li>File ending in <code>.tcl</code> are considered Tcl utility script files (normally
    found only in the bootstrap installer).
    <li>Files with extension <code>.xml</code> in the directory catalog are
        considered message catalog files.
    <li>Tcl procs or init files in a test directory are of type test_procs and test_init
        respectively.
    </ol>

    Rules are applied in this order (stopping with the first match).

} {
    set components [split $path "/"]
    set dirs_in_pageroot [llength [split [ns_info pageroot] "/"]]	   ;# See comments by RBM

    # Fix to cope with both full and relative paths
    if { [string index $path 0] == "/"} {                          
	set components_lesser [lrange $components $dirs_in_pageroot end] 
    } else {
	set components_lesser $components
    }
    set extension [file extension $path]
    set type ""


    # DRB: someone named a file "acs-mail-create-packages.sql" rather than
    # the conventional "acs-mail-packages-create.sql", causing it to be
    # recognized as a data_model_create file, causing it to be explicitly
    # run by the installer (the author intended it to be included by
    # acs-mail-create.sql only).  I've tightened up the regexp below to
    # avoid this problem, along with renaming the file...

    # DRB: I've tightened it up again because forums-forums-create.sql
    # was being recognized as a datamodel create script for the forums
    # package.

    if { [string equal $extension ".sql"] } {
	if { [lsearch -glob $components "*upgrade-*-*"] >= 0 } {
	    set type "data_model_upgrade"
        } elseif { [regexp -- "^$package_key-(create|drop)\.sql\$" [file tail $path] "" kind] } {
	    set type "data_model_$kind"
	} else {
	    set type "data_model"
	}
    } elseif { [string equal $extension ".csv"] } {
	set type "csv_data"
    } elseif { [string equal $extension ".ctl"] } {
	set type "ctl_file"
    } elseif { [string equal $extension ".sqlj"] } {
	set type "sqlj_code"
    } elseif { [string equal $extension ".info"] } {
	set type "package_spec"
    } elseif { [string equal $extension ".xql"] } {
	set type "query_file"
    } elseif { [string equal $extension ".java"] } {
	set type "java_code"
    } elseif { [string equal $extension ".jar"] } {
	set type "java_archive"
    } elseif { [lsearch $components "doc"] >= 0 } {
	set type "documentation"
    } elseif { [string equal $extension ".pl"] || \
	       [string equal $extension ".sh"] || \
	       [lsearch $components "bin"] >= 0 } {
	set type "shell"
    } elseif { [lsearch $components "templates"] >= 0 } {
	set type "template"
    } elseif { [llength $components] == 1 && \
              ([string equal $extension ".html"] || [string equal $extension ".adp"]) } {
		# HTML or ADP file in the top level of a package - assume it's documentation.
	set type "documentation"

        # RBM: Changed the next elseif to check for 'www' or 'admin-www' only n levels down
        # the path, since that'd be the minimum in a path counting from the pageroot

    } elseif { [lsearch $components_lesser "www"] >= 0 || [lsearch $components_lesser "admin-www"] >= 0 } {
	set type "content_page"
    } elseif { [string equal $extension ".tcl"] } {
        if { [regexp -- {-(procs|init)(-[0-9a-zA-Z]*)?\.tcl$} [file tail $path] "" kind] } {
            if { [string equal [lindex $components end-1] test] } {
                set type "test_$kind"
            } else {
                set type "tcl_$kind"
            }
        } else {
            set type "tcl_util"
        }
    } elseif { [apm_is_catalog_file "${package_key}/${path}"] } {
        set type "message_catalog"
    } 
    
    return $type
}

ad_proc -public apm_get_package_files {
   {-all_db_types:boolean}
   {-package_key:required}
   {-file_types {}}
} {
  <p>
  Returns all files, or files of a certain types, belonging to an APM
  package. Ignores files based on proc apm_include_file_p and determines file type
  of files with proc apm_guess_file_type. Only returns file with no db type or a
  db type matching that of the system.
  </p>

  <p>
  Goes directly to the filesystem to find
  files instead of using a file listing in the package info file or the database.
  </p>

  @param package_key    The key of the package to return file paths for
  @param file_types     The type of files to return. If not provided files of all types
                        recognized by the APM are returned.
  
  @return The paths, relative to the root dir of the package, of matching files.

  @author Peter Marklund

  @see apm_include_file_p
  @see apm_guess_file_type
  @see apm_guess_db_type
} {
    set package_path [acs_package_root_dir $package_key]
    set files [lsort [ad_find_all_files -check_file_func apm_include_file_p $package_path]]

    set matching_files [list]
    foreach file $files {
        set rel_path [string range $file [expr [string length $package_path] + 1] end]
        set file_type [apm_guess_file_type $package_key $rel_path]
        set file_db_type [apm_guess_db_type $package_key $rel_path]

        set type_match_p [expr [empty_string_p $file_types] || [lsearch $file_types $file_type] != -1]

        if { $all_db_types_p } {
            set db_match_p 1
        } else {
            set db_match_p [expr [empty_string_p $file_db_type] || [string equal $file_db_type [db_type]]]
        }

        if { $type_match_p && $db_match_p } {
            lappend matching_files $rel_path
        }
    }

    return $matching_files
}

ad_proc -private apm_parse_catalog_path { file_path } {
    Given the path of a file attempt to extract package_key, 
    prefix, charset and locale
    information from the path assuming the path is on valid format
    for a message catalog file. If the parsing fails
    then the file is not considered a catalog file and the
    empty list is returned.

    @param file_path   Path of file, relative to the OpenACS /packages dir, 
    one of its parent directories, or absolute path.

    @author Peter Marklund
} {
    array set filename_info {}

    # Catalog filepaths are on the form
    # package_key/catalog/optional_prefix_package_key.language.country.charset.xml
    set regexp_pattern "(?i)(\[^/\]+)/catalog/(.*)\\1\\.(\[a-z\]{2,3}_\[a-z\]{2})\\.(\[^.\]+)\\.xml\$"
    if { ![regexp $regexp_pattern $file_path match package_key prefix locale charset] } {
        return [list]
    }

    set filename_info(package_key) $package_key
    set filename_info(prefix) $prefix
    set filename_info(locale) $locale
    set filename_info(charset) $charset

    return [array get filename_info]
}

ad_proc -public apm_is_catalog_file { file_path } {
    Given a file path return 1 if
    the path represents a message catalog file and 0 otherwise.

    @param file_path Should be absolute or relative to OpenACS /packages dir
    or one of its parent dirs.

    @see apm_parse_catalog_path
    @author Peter Marklund
} {
    array set filename_info [apm_parse_catalog_path $file_path]

    if { [array size filename_info] == 0 } {
        # Parsing failed
        set return_value 0
    } else {
        # Parsing succeeded
        set prefix $filename_info(prefix)
        if { [empty_string_p $prefix] } {
            # No prefix - this is considered a catalog file
            set return_value 1
        } else {
            # Catalog files don't have a prefix before the package_key
            set return_value 0
        }
    }

    return $return_value
}

ad_proc -private apm_guess_db_type { package_key path } {

    Guesses and returns the database type key corresponding to a particular path
    (or an empty string if none is known). <code>$path</code> should be
    relative to the package directory (e.g., <code>www/index.tcl</code>
    for <code>/packages/bboard/admin-www/index.tcl</code>.  

    We consider two cases:

    1. Data model files.
    
       If the path contains a string matching "sql/" followed by a database type known
       to this version of OpenACS, the file is assumed to be specific to that database type.
       The empty string is returned for all other data model files.

       Example: "sql/postgresql/apm-create.sql" is assumed to be the PostgreSQL-specific
       file used to create the APM datamodel.

       If the path contains a string matching "sql/common" the file is assumed to be
       compatible with all supported RDBMS's and a blank db_type is returned.

       Otherwise "oracle" is returned.  This is a hardwired kludge to allow us to
       handle legacy ACS 4 packages.

    2. Other files.

       If it is a tcl, xql, or sqlj file not under the sql dir and whose name 
       ends in a dash and database type, the file is assumed to be specific to 
       that database type.

       Example: "tcl/10-database-postgresql-proc.tcl" is asusmed to be the file that
       defines the PostgreSQL-specific portions of the database API.

} {
    set components [split $path "/"]
    set file_type [apm_guess_file_type $package_key $path]]

    if { [string match "data_model*" $file_type] ||
         [string mtach "ctl_file" $file_type] } {
        set sql_index [lsearch $components "sql"]
        if { $sql_index >= 0 } {
            set db_dir [lindex $components [expr $sql_index + 1]]
            if { [string equal $db_dir "common"] } {
                return ""
            }
            foreach known_database_type [db_known_database_types] {
                if { [string equal [lindex $known_database_type 0] $db_dir] } {
                    return $db_dir
                }
            }
        }
        return "oracle"
    }

    set file_name [file tail $path]
    foreach known_database_type [nsv_get ad_known_database_types .] {
        if { [regexp -- "\-[lindex $known_database_type 0]\.(xql|tcl|sqlj)\$" $file_name match] } {
            return [lindex $known_database_type 0]
        }
    }

    return ""
}

ad_proc apm_package_supports_rdbms_p {
    {-package_key:required}
} {
    Returns 1 if the given package supports the rdbms of the system and 0 otherwise.
    The package is considedered to support the given rdbms if there is at least one
    file in the package of matching db_type, or if there are no files in the package
    of a certain db type.

    @author Peter Marklund
} {    
    set system_db_type [db_type]

    set has_db_types_p 0

    foreach file [apm_get_package_files -all_db_types -package_key $package_key] {
       set db_type [apm_guess_db_type $package_key $file]
       if { ![empty_string_p $db_type] } {
            set has_db_types_p 1
        }
        
        if { [string equal $system_db_type $db_type] } {
            return 1
        }
     }

    return [expr ! $has_db_types_p]
}

ad_proc apm_source { __file } {
    Sources $__file in a clean environment, returning 1 if successful or 0 if not.
    Records that the file has been sourced and stores its mtime in the nsv array
    apm_library_mtime
} {
    if { ![file exists $__file] } {
		ns_log "Error" "Unable to source $__file: file does not exist."
	return 0
    }

    # Actually do the source.
    if { [catch { source $__file }] } {
	global errorInfo
		ns_log "Error" "Error sourcing $__file:\n$errorInfo"
	return 0
    }

    nsv_set apm_library_mtime [ad_make_relative_path $__file] [file mtime $__file]    

    return 1
}

# Special boot strap load file routine.  

ad_proc apm_bootstrap_load_file { root_directory file } {
    Source a single file during initial bootstrapping and set APM data.
} {
    set relative_path [string range $file \
        [expr { [string length "$root_directory/packages"] + 1 }] end]
    ns_log "Notice" "Loading packages/$relative_path..."

    apm_source $file
}

ad_proc apm_bootstrap_load_libraries {
    {-load_tests:boolean 0}
    {-init:boolean}
    {-procs:boolean}
    package_key
} {
    Scan all the files in the package and load those asked for by the init
    and procs flags.

    This proc is an analog of apm_load_libraries.  We can't call
    apm_load_libraries during the initial portion of the bootstrap process
    because the acs-kernal datamodel may not exist.

    @author Don Baccus (dhogaza@pacifier.com)


    @param package_key The package to load (normally acs-tcl)
    @param init Load initialization files
    @param procs Load the proc library files
} {

    set root_directory [nsv_get acs_properties root_directory]
    set db_type [nsv_get ad_database_type .]

    # This is the first time each of these files is being loaded (see
    # the documentation for the apm_first_time_loading_p proc).
    global apm_first_time_loading_p
    set apm_first_time_loading_p 1

    set files [ad_find_all_files $root_directory/packages/$package_key]
    if { [llength $files] == 0 } {
		error "Unable to locate $root_directory/packages/$package_key/*."
    }

    foreach file [lsort $files] {

        set file_db_type [apm_guess_db_type $package_key $file]
        set file_type [apm_guess_file_type $package_key $file]

        if {([empty_string_p $file_db_type] || \
             [string equal $file_db_type $db_type]) &&
            ([string equal $file_type tcl_procs] && $procs_p ||
             [string equal $file_type tcl_init] && $init_p)} {

                 # Don't source acs-automated-testing tests before that package has been
                 # loaded
                 if { ! $load_tests_p && [regexp {tcl/test/[^/]+$} $file match] } {
                     continue
                 } 

		 apm_bootstrap_load_file $root_directory $file

            # Call db_release_unused_handles, only if the library defining it
            # (10-database-procs.tcl) has been sourced yet.
            if { [llength [info procs db_release_unused_handles]] != 0 } {
                db_release_unused_handles
            }
        } elseif { ( [empty_string_p $file_db_type] ||
	             [string equal $file_db_type $db_type] ) &&
	           ( [string equal $file_type tcl_util] ) } {
	    ns_log warning "apm_boostrap_load_file skipping $file because it isn't either a -procs.tcl or -init.tcl file"
	}
    }

    unset apm_first_time_loading_p
}

proc apm_bootstrap_load_queries { package_key } {

    # Load up queries.

    set root_directory [nsv_get acs_properties root_directory]
    set db_type [nsv_get ad_database_type .]

    # DRB: We can't parse the $package_key.info file at this point in time, primarily because
    # grabbing the package information uses not only the XML file but tables from the APM,
	# which haven't been loaded yet if we're installing.  So we just snarf all of the
	# queryfiles in this package that match the current database or no database
    # (which we interpret to mean all supported databases).

    set files [ad_find_all_files $root_directory/packages/$package_key]
    if { [llength $files] == 0 } {
	error "Unable to locate $root_directory/packages/$package_key/*."
    }

    foreach file [lsort $files] {

        set file_db_type [apm_guess_db_type $package_key $file]
        set file_type [apm_guess_file_type $package_key $file]

        if {[string equal $file_type query_file] &&
            ([empty_string_p $file_db_type] || [string equal $file_db_type $db_type])} {
	    db_qd_load_query_file $file
        } 
    }
}
