ad_library {

    Functions that APM uses to parse and generate XML.
    Changed to use ns_xml by ben (OpenACS).

    @author Bryan Quinn (bquinn@arsdigita.com)
    @author Ben Adida (ben@mit.edu)
    @creation-date Fri Oct  6 21:47:39 2000
    @cvs-id $Id$
} 

ad_proc -private apm_load_xml_packages {} {

    Loads XML packages into the running interpreter, if they're not
    already there. We need to load these packages once per connection,
    since AOLserver doesn't seem to deal with packages very well.

} {
    global ad_conn
    if { ![info exists ad_conn(xml_loaded_p)] } {
	# ns_xml needs to be loaded

#  	foreach file [glob "[acs_package_root_dir acs-tcl]/tcl/xml-*-procs.tcl"] {
#  	    apm_source $file
#  	}
	set ad_conn(xml_loaded_p) 1
    }

#    package require xml 1.9
}

ad_proc -private apm_required_attribute_value { element attribute } {

    Returns an attribute of an XML element, throwing an error if the attribute
    is not set.

} {
    set value [apm_attribute_value $element $attribute]
    if { [empty_string_p $value] } {
	error "Required attribute \"$attribute\" missing from <[dom::node cget $element -nodeName]>"
    }
    return $value
}

ad_proc -private apm_attribute_value {
    {
	-default ""
    }
    element attribute } {

    Parses the XML element to return the value for the specified attribute.

} {
    # set value [dom::element getAttribute $element $attribute]
    set value [ns_xml node getattr $element $attribute]

    if { [empty_string_p $value] } {
	return $default
    } else {
	return $value
    }
}

ad_proc -private apm_tag_value {
    {
	-default ""
    }
    root property_name
} {
    Parses the XML element and returns the associated property name if it exists.
} {
    # set node [lindex [dom::element getElementsByTagName $root $property_name] 0]
    set node [lindex [xml_find_child_nodes $root $property_name] 0]

    if { ![empty_string_p $node] } {
	# return [dom::node cget [dom::node cget $node -firstChild] -nodeValue]
	return [ns_xml node getcontent [lindex [ns_xml node children $node] 0]]
    } else {
	return $default
    }    
}

ad_proc -private apm_generate_package_spec { version_id } {

    Generates an XML-formatted specification for a version of a package.

} {
    set spec ""
    db_1row package_version_select {
        select t.package_key, t.package_uri, t.pretty_name, t.pretty_plural, t.package_type,
	t.initial_install_p, t.singleton_p, v.*
        from   apm_package_versions v, apm_package_types t
        where  v.version_id = :version_id
        and    v.package_key = t.package_key
    }
    ns_log Debug "APM: Writing Package Specification for $pretty_name $version_name"
    append spec "<?xml version=\"1.0\"?>
<!-- Generated by the ACS Package Manager -->

<package key=\"[ad_quotehtml $package_key]\" url=\"[ad_quotehtml $package_uri]\" type=\"$package_type\">
    <package-name>[ad_quotehtml $pretty_name]</package-name>
    <pretty-plural>[ad_quotehtml $pretty_plural]</pretty-plural>
    <initial-install-p>$initial_install_p</initial-install-p>
    <singleton-p>$singleton_p</singleton-p>

    <version name=\"$version_name\" url=\"[ad_quotehtml $version_uri]\">
    <database-support>\n"

    db_foreach supported_databases {
        select unique db_type
        from apm_package_files
        where db_type is not null
    } {
        append spec "        <database>$db_type</database>\n"
    }
    append spec "    </database-support>\n"

    db_foreach owner_info {
        select owner_uri, owner_name
        from   apm_package_owners
        where  version_id = :version_id
        order by sort_key
    } {
        append spec "        <owner"
        if { ![empty_string_p $owner_uri] } {
    	append spec " url=\"[ad_quotehtml $owner_uri]\""
        }
        append spec ">[ad_quotehtml $owner_name]</owner>\n"
    }

    ns_log Debug "APM: Writing Version summary and description"
    if { ![empty_string_p $summary] } {
        append spec "        <summary>[ad_quotehtml $summary]</summary>\n"
    }
    if { ![empty_string_p $release_date] } {
        append spec "        <release-date>[ad_quotehtml [string range $release_date 0 9]]</release-date>\n"
    }
    if { ![empty_string_p $vendor] || ![empty_string_p $vendor_uri] } {
        append spec "        <vendor"
        if { ![empty_string_p $vendor_uri] } {
    	append spec " url=\"[ad_quotehtml $vendor_uri]\""
        }
        append spec ">[ad_quotehtml $vendor]</vendor>\n"
    }
    if { ![empty_string_p $description] } {
        append spec "        <description"
        if { ![empty_string_p $description_format] } {
	    append spec " format=\"[ad_quotehtml $description_format]\""
        }
        append spec ">[ad_quotehtml $description]</description>\n"
    }

    append spec "\n"
    
    ns_log Debug "APM: Writing Dependencies."
    db_foreach dependency_info {
        select dependency_type, service_uri, service_version
        from   apm_package_dependencies
        where  version_id = :version_id
        order by dependency_type, service_uri
    } {
        append spec "        <$dependency_type url=\"[ad_quotehtml $service_uri]\" version=\"[ad_quotehtml $service_version]\"/>\n"
    } else {
        append spec "        <!-- No dependency information -->\n"
    }


    append spec "\n        <files>\n"
    ns_log Debug "APM: Writing Files." 
    db_foreach version_path "select path, file_type, db_type from apm_package_files where version_id = :version_id order by path" {
        append spec "            <file"
        if { ![empty_string_p $file_type] } {
            append spec " type=\"$file_type\""
        }
        if { ![empty_string_p $db_type] } {
            append spec " db_type=\"$db_type\""
        }
        append spec " path=\"[ad_quotehtml $path]\"/>\n"
    } else {
        append spec "            <!-- No files -->\n"
    }
    append spec "        </files>
        <parameters>\n"
    ns_log Debug "APM: Writing parameters"
    db_foreach parameter_info {
	select parameter_name, description, datatype, section_name, default_value, min_n_values, max_n_values
	  from apm_parameters
	 where package_key = :package_key
    } {
	append spec "            <parameter datatype=\"[ad_quotehtml $datatype]\" \
		min_n_values=\"[ad_quotehtml $min_n_values]\" \
		max_n_values=\"[ad_quotehtml $max_n_values]\" \
		name=\"[ad_quotehtml $parameter_name]\" "
	if { ![empty_string_p $default_value] } {
	    append spec " default=\"[ad_quotehtml $default_value]\""
	}

	if { ![empty_string_p $description] } {
	    append spec " description=\"[ad_quotehtml $description]\""
	}
	
	if { ![empty_string_p $section_name] } {
	    append spec " section_name=\"[ad_quotehtml $section_name]\""
	}

	append spec "/>\n"
    } if_no_rows {
	append spec "        <!-- No version parameters -->\n"
    }

    append spec "        </parameters>\n\n"

    
    append spec "    </version>
</package>
"
    ns_log Debug "APM: Finished writing spec."
    return $spec
}


ad_proc -public apm_read_package_info_file { path } {

    Reads a .info file, returning an array containing the following items:

    <ul>
    <li><code>path</code>: a path to the file read
    <li><code>mtime</code>: the mtime of the file read
    <li><code>provides</code> and <code>$requires</code>: lists of dependency
    information, containing elements of the form <code>[list $url $version]</code>
    <li><code>owners</code>: a list of owners containing elements of the form
    <code>[list $url $name]</code>
    <li><code>files</code>: a list of files in the package,
    containing elements of the form <code>[list $path
    $type]</code>
    <li>Element and attribute values directly from the XML specification:
    <code>package.key</code>,
    <code>package.url</code>,
    <code>package.type</code>
    <code>pretty-plural</code>
    <code>initial-install-p</code>
    <code>singleton-p</code>
    <code>name</code> (the version name, e.g., <code>3.3a1</code>,
    <code>url</code> (the version URL),
    <code>package-name</code>,
    <code>option</code>,
    <code>summary</code>,
    <code>description</code>,
    <code>release-date</code>,
    <code>vendor</code>,
    <code>group</code>,
    <code>vendor.url</code>, and
    <code>description.format</code>.

    </ul>
    
    This routine will typically be called like so:
    
    <blockquote><pre>array set version_properties [apm_read_package_info_file $path]</pre></blockquote>

    to populate the <code>version_properties</code> array.

    <p>If the .info file cannot be read or parsed, this routine throws a
    descriptive error.

} {
    global ad_conn

    # If the .info file hasn't changed since last read (i.e., has the same
    # mtime), return the cached info list.
    set mtime [file mtime $path]
    if { [nsv_exists apm_version_properties $path] } {
	set cached_version [nsv_get apm_version_properties $path]
	if { [lindex $cached_version 0] == $mtime } {
	    return [lindex $cached_version 1]
	}
    }

    # Set the path and mtime in the array.
    set properties(path) $path
    set properties(mtime) $mtime

    apm_load_xml_packages

    ns_log "Notice" "Reading specification file at $path"

    set file [open $path]
    set xml_data [read $file]
    close $file

    set xml_data [xml_prepare_data $xml_data]

    # set tree [dom::DOMImplementation parse $xml_data]
    set tree [ns_xml parse $xml_data]
    # set package [dom::node cget $tree -firstChild]
    set root_node [ns_xml doc root $tree]
    ns_log Notice "XML: root node is [ns_xml node name $root_node]"
    set package $root_node

    # set root_name [dom::node cget $package -nodeName]
    set root_name [ns_xml node name $package]

    # Debugging Children
    set root_children [ns_xml node children $root_node]

    ns_log Notice "XML - there are [llength $root_children] child nodes"
    foreach child $root_children {
	ns_log Notice "XML - one root child: [ns_xml node name $child]"
    }

    if { ![string equal $root_name "package"] } {
	ns_log Notice "XML: the root name is $root_name"
	error "Expected <package> as root node"
    }
    set properties(package.key) [apm_required_attribute_value $package key]
    set properties(package.url) [apm_required_attribute_value $package url]
    set properties(package.type) [apm_attribute_value -default "apm_application" $package type]
    set properties(package-name) [apm_tag_value $package package-name]
    set properties(initial-install-p) [apm_tag_value -default "f" $package initial-install-p]
    set properties(singleton-p) [apm_tag_value -default "f" $package singleton-p]
    set properties(pretty-plural) [apm_tag_value -default "$properties(package-name)s" $package pretty-plural]


    # set versions [dom::element getElementsByTagName $package version]
    set versions [xml_find_child_nodes $package version]

    if { [llength $versions] != 1 } {
	error "Package must contain exactly one <version> node"
    }
    set version [lindex $versions 0]
    
    set properties(name) [apm_required_attribute_value $version name]
    set properties(url) [apm_required_attribute_value $version url]


    # Set an entry in the properties array for each of these tags.
    foreach property_name { summary description release-date vendor } {
	set properties($property_name) [apm_tag_value $version $property_name]
    }


    # Set an entry in the properties array for each of these attributes:
    #
    #   <vendor url="...">           -> vendor.url
    #   <description format="...">   -> description.format

    foreach { property_name attribute_name } {
	vendor url
	description format
    } {
	# set node [lindex [dom::element getElementsByTagName $version $property_name] 0]
	set node [lindex [xml_find_child_nodes $version $property_name] 0]
	if { ![empty_string_p $node] } {
	    # set properties($property_name.$attribute_name) [dom::element getAttribute $node $attribute_name]
	    set properties($property_name.$attribute_name) [apm_attribute_value $node $attribute_name]
	} else {
	    set properties($property_name.$attribute_name) ""
	}
    }

    # We're done constructing the properties array - save the properties into the
    # moby array which we're going to return.

    set properties(properties) [array get properties]

    # Build lists of the services provided by and required by the package.

    set properties(provides) [list]
    set properties(requires) [list]

    foreach dependency_type { provides requires } {
	# set dependency_types [dom::element getElementsByTagName $version $dependency_type]
	set dependency_types [xml_find_child_nodes $version $dependency_type]

	foreach node $dependency_types {
	    set service_uri [apm_required_attribute_value $node url]
	    set service_version [apm_required_attribute_value $node version]
	    lappend properties($dependency_type) [list $service_uri $service_version]
	}
    }

    # Build a list of the files contained in the package.

    set properties(files) [list]

    # set nodes [dom::element getElementsByTagName $version "files"]
    set files [xml_find_child_nodes $version files]

    foreach node $files {
	# set file_nodes [dom::element getElementsByTagName $node "file"]
	set file_nodes [xml_find_child_nodes $node file]
	
	foreach file_node $file_nodes {
	    set file_path [apm_required_attribute_value $file_node path]
	    # set type [dom::element getAttribute $file_node type]
	    set type [apm_attribute_value $file_node type]
	    # set db_type [dom::element getAttribute $file_node db_type]
	    set db_type [apm_attribute_value $file_node db_type]
	    # Validate the file type: it must be null (unknown type) or
	    # some value in [apm_file_type_keys].
	    if { ![empty_string_p $type] && [lsearch -exact [apm_file_type_keys] $type] < 0 } {
		error "Invalid file type \"$type\""
	    }
	    # Validate the database type: it must be null (unknown type) or
	    # some value in [apm_db_type_keys].
	    if { ![empty_string_p $db_type] && [lsearch -exact [apm_db_type_keys] $db_type] < 0 } {
		error "Invalid database type \"$db_type\""
	    }
	    lappend properties(files) [list $file_path $type $db_type]
	}
    }

    # Build a list of the package's owners (if any).

    set properties(owners) [list]

    # set owners [dom::element getElementsByTagName $version "owner"]
    set owners [xml_find_child_nodes $version owner]

    foreach node $owners {
	# set url [dom::element getAttribute $node url]
	set url [apm_attribute_value $node url]
	# set name [dom::node cget [dom::node cget $node -firstChild] -nodeValue]
	set name [ns_xml node getcontent [lindex [ns_xml node children $node] 0]]
	lappend properties(owners) [list $name $url]
    }

    # Build a list of the packages parameters (if any)

    set properties(parameters) [list]
    ns_log Debug "APM: Reading Parameters"

    # set parameters [dom::element getElementsByTagName $version "parameters"]
    set parameters [xml_find_child_nodes $version parameters]

    foreach node $parameters {
	# set parameter_nodes [dom::element getElementsByTagName $node "parameter"]
	set parameter_nodes [xml_find_child_nodes $node parameter]

	foreach parameter_node $parameter_nodes {	  
	    # set default_value [dom::element getAttribute $parameter_node default]
	    set default_value [apm_attribute_value $parameter_node default]
	    # set min_n_values [dom::element getAttribute $parameter_node min_n_values]
	    set min_n_values [apm_attribute_value $parameter_node min_n_values]
	    # set max_n_values [dom::element getAttribute $parameter_node max_n_values]
	    set max_n_values [apm_attribute_value $parameter_node max_n_values]
	    # set description [dom::element getAttribute $parameter_node description]
	    set description [apm_attribute_value $parameter_node description]
	    # set section_name [dom::element getAttribute $parameter_node section_name]
	    set section_name [apm_attribute_value $parameter_node section_name]
	    # set datatype [dom::element getAttribute $parameter_node datatype]
	    set datatype [apm_attribute_value $parameter_node datatype]
	    # set name [dom::element getAttribute $parameter_node name]
	    set name [apm_attribute_value $parameter_node name]

	    ns_log Debug "APM: Reading parameter $name with default $default_value"
	    lappend properties(parameters) [list $name $description $section_name $datatype $min_n_values $max_n_values $default_value]
	}
    }

    # Serialize the array into a list.
    set return_value [array get properties]

    # Cache the property info based on $mtime.
    nsv_set apm_version_properties $path [list $mtime $return_value]

    return $return_value
}

