ad_library {

    site node api

    @author rhs@mit.edu
    @author yon (yon@openforce.net)
    @creation-date 2000-09-06
    @version $Id$

}

namespace eval site_node {

    ad_proc -public new {
        {-name:required}
        {-parent_id:required}
        {-directory_p t}
        {-pattern_p t}
    } {
        create a new site node
    } {
        set extra_vars [ns_set create]
        ns_set put $extra_vars name $name
        ns_set put $extra_vars parent_id $parent_id
        ns_set put $extra_vars directory_p $directory_p
        ns_set put $extra_vars pattern_p $pattern_p

        set node_id [package_instantiate_object -extra_vars $extra_vars site_node]

        update_cache -node_id $node_id

        return $node_id
    }

    ad_proc -public new_with_package {
        {-name:required}
        {-parent_id:required}
        {-package_key:required}
        {-instance_name:required}
        {-context_id:required}
    } {
        create site node, instantiate package, mount package at new site node
    } {
        set node_id [new -name $name -parent_id $parent_id]

        set package_id [apm_package_create_instance $instance_name $context_id $package_key]

        mount -node_id $node_id -object_id $package_id

        update_cache -node_id $node_id

        # call post instantiation proc for the package
        apm_package_call_post_instantiation_proc $package_id $package_key

        return $package_id
    }

    ad_proc -public mount {
        {-node_id:required}
        {-object_id:required}
    } {
        mount object at site node
    } {
        db_dml mount_object {}
        update_cache -node_id $node_id
    }

    ad_proc -public unmount {
        {-node_id:required}
    } {
        unmount an object from the site node
    } {
        db_dml unmount_object {}
        update_cache -node_id $node_id
    }

    ad_proc -private init_cache {} {
        initialize the site node cache
    } {
        nsv_array reset site_nodes [list]

        db_foreach select_site_nodes {} {
            set node(url) $url
            set node(node_id) $node_id
            set node(directory_p) $directory_p
            set node(pattern_p) $pattern_p
            set node(object_id) $object_id
            set node(object_type) $object_type
            set node(package_key) $package_key
            set node(package_id) $package_id

            nsv_set site_nodes $url [array get node]
        }

        ns_eval {
            global tcl_site_nodes
            if {[info exists tcl_site_nodes]} {
                unset tcl_site_nodes
            }
        }
    }

    ad_proc -private update_cache {
        {-node_id:required}
    } {
        if {[db_0or1row select_site_node {}]} {
            set node(url) $url
            set node(node_id) $node_id
            set node(directory_p) $directory_p
            set node(pattern_p) $pattern_p
            set node(object_id) $object_id
            set node(object_type) $object_type
            set node(package_key) $package_key
            set node(package_id) $package_id

            nsv_set site_nodes $url [array get node]

            ns_eval {
                global tcl_site_nodes
                if {[info exists tcl_site_nodes]} {
                    array unset tcl_site_nodes "${url}*"
                }
            }
        }
    }

    ad_proc -public get {
        {-url:required}
    } {
        returns an array representing the site node that matches the given url
    } {
        # attempt an exact match
        if {[nsv_exists site_nodes $url]} {
            return [nsv_get site_nodes $url]
        }

        # attempt adding a / to the end of the url if it doesn't already have
        # one
        if {![string equal [string index $url end] "/"]} {
            append url "/"
            if {[nsv_exists site_nodes $url]} {
                return [nsv_get site_nodes $url]
            }
        }

        # chomp off part of the url and re-attempt
        while {![empty_string_p $url]} {
            set url [string trimright $url /]
            set url [string range $url 0 [string last / $url]]

            if {[nsv_exists site_nodes $url]} {
                array set node [nsv_get site_nodes $url]

                if {[string equal $node(pattern_p) t] && ![empty_string_p $node(object_id)]} {
                    return [array get node]
                }
            }
        }

        error "site node not found at url $url"
    }

}

ad_proc -deprecated site_node_create {
    {-new_node_id ""}
    {-directory_p "t"}
    {-pattern_p "t"}
    parent_node_id
    name
} {
    Create a new site node.  Returns the node_id
    @see site_node::new
} {
    return [site_node::new \
        -name $name \
        -parent_id $parent_node_id \
        -directory_p $directory_p \
        -pattern_p $pattern_p \
    ]
}

ad_proc -deprecated site_node_create_package_instance {
    { -package_id 0 }
    { -sync_p "t" }
    node_id
    instance_name
    context_id
    package_key
} {
    Creates a new instance of the specified package and flushes the
    in-memory site map (if sync_p is t).

    DRB: I've modified this so it doesn't call the package's post instantiation proc until
    after the site node map is updated.   Delaying the call in this way allows the package to
    find itself in the map.   The code that mounts a subsite, in particular, needs to be able
    to do this so it can find the nearest parent node that defines an application group (the
    code in aD ACS 4.2 was flat-out broken).

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-05

    @return The package_id of the newly mounted package
} {
    set package_id [apm_package_create_instance $instance_name $context_id $package_key]

    site_node::mount -node_id $node_id -object_id $package_id

    apm_package_call_post_instantiation_proc $package_id $package_key

    return $package_id
}

ad_proc -public site_node_delete_package_instance {
    {-node_id:required}
} {
    Wrapper for apm_package_instance_delete

    @author Arjun Sanyal (arjun@openforc.net)
    @creation-date 2002-05-02
} {
    db_transaction {
        set package_id [site_nodes::get_package_id_from_node_id -node_id $node_id]
        site_node::unmount -node_id $node_id
        apm_package_instance_delete $package_id
    }
}

ad_proc -public site_node_mount_application {
    {-sync_p "t"}
    {-return "package_id"}
    parent_node_id
    instance_name
    package_key
    package_name
} {
    Creates a new instance of the specified package and mounts it
    beneath parent_node_id.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-05

    @param sync_p If "t", we flush the in-memory site map
    @param return You can specify what is returned: the package_id or node_id
           (now ignored, always return package_id)
    @param parent_node_id The node under which we are mounting this
           application
    @param instance_name The instance name for the new site node
    @param package_key The type of package we are mounting
    @param package_name The name we want to give the package we are
           mounting.
    @return The package id of the newly mounted package or the new
           node id, based on the value of $return

} {
    # if there is an object mounted at the parent_node_id then use that
    # object_id, instead of the parent_node_id, as the context_id
    if {![db_0or1row get_context {}]} {
        set context_id $parent_node_id
    }

    return [site_node::new_with_package \
        -name $instance_name \
        -parent_id $parent_node_id \
        -package_key $package_key \
        -instance_name $package_name \
        -context_id $context_id \
    ]
}

ad_proc -public site_map_unmount_application {
    { -sync_p "t" }
    { -delete_p "f" }
    node_id
} {
    Unmounts the specified node.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-07

    @param sync_p If "t", we flush the in-memory site map
    @param delete_p If "t", we attempt to delete the site node. This
         will fail if you have not cleaned up child nodes
    @param node_id The node_id to unmount

} {
    db_transaction {
        site_node::unmount -node_id $node_id

        if {[string equal $delete_p t]} {
            db_exec_plsql node_delete {}	
        }
    }
}

ad_proc -deprecated site_node {url} {
    Returns an array in the form of a list. This array contains
    url, node_id, directory_p, pattern_p, and object_id for the
    given url. If no node is found then this will throw an error.
} { 
    return [site_node::get -url $url]
}

ad_proc -public site_node_id {url} {
    Returns the node_id of a site node. Throws an error if there is no
    matching node.
} {
    array set node [site_node::get -url $url]
    return $node(node_id)
}

ad_proc -public site_nodes_sync {args} {
    Brings the in memory copy of the url hierarchy in sync with the
    database version.
} {
    site_node::init_cache
}

ad_proc -public site_node_closest_ancestor_package {
    { -default "" }
    { -url "" }
    package_key
} {
    Finds the package id of a package of specified type that is
    closest to the node id represented by url (or by ad_conn url).Note
    that closest means the nearest ancestor node of the specified
    type, or the current node if it is of the correct type.

    <p>

    Usage:

    <pre>
    # Pull out the package_id of the subsite closest to our current node
    set pkg_id [site_node_closest_ancestor_package "acs-subsite"]
    </pre>

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 1/17/2001

    @param default The value to return if no package can be found
    @param current_node_id The node from which to start the search
    @param package_key The type of the package for which we are looking

    @return <code>package_id</code> of the nearest package of the
    specified type (<code>package_key</code>). Returns $default if no
    such package can be found.

} {
    if {[empty_string_p $url]} {
	set url [ad_conn url]
    }

    # Try the URL as is.
    if {[catch {nsv_get site_nodes $url} result] == 0} {
	array set node $result
	if { [string eq $node(package_key) $package_key] } {
	    return $node(package_id)
	}
    }

    # Add a trailing slash and try again.
    if {[string index $url end] != "/"} {
	append url "/"
	if {[catch {nsv_get site_nodes $url} result] == 0} {
	    array set node $result
	    if { [string eq $node(package_key) $package_key] } {
		return $node(package_id)
	    }
	}
    }

    # Try successively shorter prefixes.
    while {$url != ""} {
	# Chop off last component and try again.
	set url [string trimright $url /]
	set url [string range $url 0 [string last / $url]]
	
	if {[catch {nsv_get site_nodes $url} result] == 0} {
	    array set node $result
	    if {$node(pattern_p) == "t" && $node(object_id) != "" && [string eq $node(package_key) $package_key] } {
		return $node(package_id)
	    }
	}
    }

    return $default
}

ad_proc -public site_node_closest_ancestor_package_url {
    { -default "" }
    { -package_key "acs-subsite" }
} {
    Returns the url stub of the nearest application of the specified
    type.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-05

    @param package_key The type of package for which we're looking
    @param default The default value to return if no package of the
    specified type was found

} {
    set subsite_pkg_id [site_node_closest_ancestor_package $package_key]
    if {[empty_string_p $subsite_pkg_id]} {
	# No package was found... return the default
	return $default
    }

    return [db_string select_url {} -default ""]
}
