ad_page_contract {
    Show internationalization status for a certain package version.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 8 October 2002
    @cvs-id $Id$  
} {
    version_id:integer,notnull    
    {pre_select_files_p "1"}
    {show_status_p "0"}
    {file_type adp}
}

db_1row package_version_info "select pretty_name, version_name from apm_package_version_info where version_id = :version_id"

set page_title "Internationalization of $pretty_name $version_name"
set context_bar [ad_context_bar $page_title]

set file_option_list [list]
set adp_preselect_list [list]
set package_key [apm_package_key_from_version_id $version_id]
foreach file [lsort [ad_find_all_files [acs_package_root_dir $package_key]]] {	

    set file_regexp [ad_decode $file_type adp {\.adp$} {\.tcl$}]
    
    if { [regexp $file_regexp $file match] } {
        set relative_path [ad_make_relative_path $file]

        # Get statistics on number of message tags
        if { $show_status_p } {

            set file_id [open $file r]
            set file_contents [read $file_id]

            set number_of_message_tags [llength [lang::util::get_temporary_tags_indices $file_contents]]

            if { [string equal $file_type adp] } {
                # We are dealing with adp files
                set number_of_message_keys [llength [lang::util::get_hash_indices $file_contents]]
                set adp_text_result_list [lang::util::replace_adp_text_with_message_tags $file report]
                set number_of_text_snippets [llength [lindex $adp_text_result_list 0]]
                
                set status_string "$number_of_text_snippets texts, $number_of_message_tags tags, $number_of_message_keys keys"
            } else {
                # We are dealing with tcl files

                set status_string "$number_of_message_tags tags"
            }
                
            close $file_id

        } else {
            set status_string ""
        }

        # Checkbox label in first element and value in second
        lappend file_option_list [list "$relative_path $status_string" $relative_path]

        if { $pre_select_files_p } {
            lappend adp_preselect_list $relative_path
        }

    }
}

form create file_list_form -action [ad_decode $file_type adp "version-i18n-process" "version-i18n-process-2"]

element create file_list_form version_id \
        -datatype integer \
        -widget hidden \
        -value $version_id

element create file_list_form files \
        -datatype text \
        -widget checkbox \
        -label "ADP Templates" \
        -options $file_option_list \
        -values $adp_preselect_list

set action_label "Action to take on files"
if { [string equal $file_type adp] } {
    element create file_list_form file_action \
        -datatype text \
        -widget checkbox \
        -label $action_label \
        -options {{{Replace text with tags} replace_text} {{Replace tags with keys and insert into catalog} replace_tags}} \
        -values {replace_text replace_tags} \
        -section action_section
} else {
    # TCL files
    element create file_list_form tcl_action_inform \
            -datatype text \
            -widget inform \
            -label $action_label \
            -value "Replace tags with keys and insert into catalog"

    # We need to export the file action
    element create file_list_form file_action \
            -datatype text \
            -widget hidden \
            -value replace_tags
}

if { $pre_select_files_p } {
    set pre_select_filter "<a href=\"version-i18n?[export_vars -url -override {{pre_select_files_p 0}} {version_id file_type show_status_p}]\">Unselect all files</a>"
} else {
    set pre_select_filter "<a href=\"version-i18n?[export_vars -url -override {{pre_select_files_p 1}} {version_id file_type show_status_p}]\">Select all files</a>"
}

if { $show_status_p } {
    set status_filter "<a href=\"version-i18n?[export_vars -url -override {{show_status_p 0}} {version_id file_type pre_select_files_p}]\">Hide I18N status of files</a>"
} else {
    set status_filter "<a href=\"version-i18n?[export_vars -url -override {{show_status_p 1}} {version_id file_type pre_select_files_p}]\">Show I18N status of files</a>"
}

if { [string equal $file_type adp] } {
    set file_type_filter "<b>Show adp files</b> | <a href=\"version-i18n?[export_vars -url -override {{file_type tcl}} {version_id pre_select_files_p show_status_p}]\">Show tcl files</a>"
} else {
    set file_type_filter "<a href=\"version-i18n?[export_vars -url -override {{file_type adp}} {version_id pre_select_files_p show_status_p}]\">Show adp files</a> | <b>Show tcl files</b>"
}

ad_return_template
