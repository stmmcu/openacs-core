<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="ds_instance_id.acs_kernel_id_get">      
      <querytext>
	select package_id from apm_packages
	where package_key = 'acs-developer-support'
	limit 1
    
      </querytext>
</fullquery>

 
<fullquery name="ds_require_permission.name">      
      <querytext>
      select acs_object__name(:object_id) 
      </querytext>
</fullquery>

 
<fullquery name="ds_support_url.ds_support_url">      
      <querytext>
	select site_node__url(node_id) 
	from site_nodes s, apm_packages p
	where p.package_id = s.object_id
	and p.package_key ='acs-developer-support'
	limit 1
    
      </querytext>
</fullquery>

 
</queryset>
