create function acs_sc_contract__new(varchar,text)
returns integer as '
declare
    p_contract_name		alias for $1;
    p_contract_desc		alias for $2;
    v_contract_id		integer;
begin

    v_contract_id := acs_object__new(
                null,
                ''acs_sc_contract'',
                now(),
                null,
                null,
                null
            );

    insert into acs_sc_contract (
        contract_id,
        contract_name,
        contract_desc
    ) values (
        v_contract_id,
        p_contract_name,
        p_contract_desc
    );

    return v_contract_id;

end;' language 'plpgsql';



create function acs_sc_contract__get_id(varchar)
returns integer as '
declare
    p_contract_name             alias for $1;
    v_contract_id               integer;
begin

    select contract_id into v_contract_id
    from acs_sc_contract
    where contract_name = p_contract_name;

    return v_contract_id;

end;' language 'plpgsql';



create function acs_sc_contract__get_name(integer)
returns varchar as '
declare
    p_contract_id		alias for $1;
    v_contract_name		varchar;
begin

    select contract_name into v_contract_name
    from acs_sc_contract
    where contract_id = p_contract_id;

    return v_contract_name;

end;' language 'plpgsql';



create function acs_sc_contract__delete(integer)
returns integer as '
declare
    p_contract_id		alias for $1;
begin

    delete from acs_sc_contract
    where contract_id = p_contract_id;

    return 0;

end;' language 'plpgsql';



create function acs_sc_contract__delete(varchar)
returns integer as '
declare
    p_contract_name		alias for $1;
    v_contract_id		integer;
begin

    v_contract_id := acs_sc_contract__get_id(p_contract_name);

    perform acs_sc_contract__delete(v_contract_id);

    return 0;

end;' language 'plpgsql';



create function acs_sc_operation__new(varchar,varchar,text,boolean,integer,varchar,varchar)
returns integer as '
declare
    p_contract_name		alias for $1;
    p_operation_name            alias for $2;
    p_operation_desc		alias for $3;
    p_operation_iscachable_p	alias for $4;
    p_operation_nargs		alias for $5;
    p_operation_inputtype	alias for $6;
    p_operation_outputtype	alias for $7;
    v_contract_id               integer;
    v_operation_id		integer;
    v_operation_inputtype_id	integer;
    v_operation_outputtype_id	integer;
begin

    v_contract_id := acs_sc_contract__get_id(p_contract_name);

    v_operation_id := acs_object__new(
                         null,
                         ''acs_sc_operation'',
                         now(),
                         null,
                         null,
                         null
                     );

     v_operation_inputtype_id := acs_sc_msg_type__get_id(p_operation_inputtype);

     v_operation_outputtype_id := acs_sc_msg_type__get_id(p_operation_outputtype);

    insert into acs_sc_operation (
        contract_id,
        operation_id,
	contract_name,
	operation_name,
	operation_desc,
	operation_iscachable_p,
	operation_nargs,
	operation_inputtype_id,
	operation_outputtype_id
    ) values (
        v_contract_id,
        v_operation_id,
	p_contract_name,
	p_operation_name,
	p_operation_desc,
	p_operation_iscachable_p,
	p_operation_nargs,
	v_operation_inputtype_id,
	v_operation_outputtype_id
    );

    return v_operation_id;

end;' language 'plpgsql';



create function acs_sc_operation__get_id(varchar,varchar)
returns integer as '
declare
    p_contract_name		alias for $1;
    p_operation_name            alias for $2;
    v_operation_id               integer;
begin

    select operation_id into v_operation_id
    from acs_sc_operation
    where contract_name = p_contract_name 
    and operation_name = p_operation_name;

    return v_operation_id;

end;' language 'plpgsql';



create function acs_sc_operation__delete(integer)
returns integer as '
declare
    p_operation_id		alias for $1;
begin

    delete from acs_sc_operation
    where operation_id = p_operation_id;

    return 0;

end;' language 'plpgsql';



create function acs_sc_operation__delete(varchar,varchar)
returns integer as '
declare
    p_contract_name		alias for $1;
    p_operation_name		alias for $2;
    v_operation_id		integer;
begin

    v_operation_id := acs_sc_operation__get_id(
		          p_contract_name,
			  p_operation_name
		      );

    perform acs_sc_operation__delete(v_operation_id);

    return v_operation_id;

end;' language 'plpgsql';



create function acs_sc_impl__new(varchar,varchar,varchar)
returns integer as '
declare
    p_impl_contract_name	alias for $1;
    p_impl_name			alias for $2;
    p_impl_owner_name		alias for $3;
    v_impl_id			integer;
begin

    v_impl_id := acs_object__new(
                null,
                ''acs_sc_implementation'',
                now(),
                null,
                null,
                null
            );

    insert into acs_sc_impl (
        impl_id,
	impl_name,
        impl_owner_name,
	impl_contract_name
    ) values (
        v_impl_id,
	p_impl_name,
	p_impl_owner_name,
	p_impl_contract_name
    );

    return v_impl_id;

end;' language 'plpgsql';



create function acs_sc_impl__get_id(varchar,varchar)
returns integer as '
declare
    p_impl_contract_name	alias for $1;
    p_impl_name			alias for $2;
    v_impl_id			integer;
begin

    select impl_id into v_impl_id
    from acs_sc_impl
    where impl_name = p_impl_name
    and impl_contract_name = p_impl_contract_name;

    return v_impl_id;

end;' language 'plpgsql';


create function acs_sc_impl__get_name(integer)
returns varchar as '
declare
    p_impl_id			alias for $1;
    v_impl_name			varchar;
begin

    select impl_name into v_impl_name
    from acs_sc_impl
    where impl_id = p_impl_id;

    return v_impl_name;

end;' language 'plpgsql';



create function acs_sc_impl__delete(varchar,varchar)
returns integer as '
declare
    p_impl_contract_name	alias for $1;
    p_impl_name			alias for $2;
begin

    delete from acs_sc_impl
    where impl_contract_name = p_impl_contract_name
    and impl_name = p_impl_name;

    return 0;

end;' language 'plpgsql';






create function acs_sc_impl_alias__new(varchar,varchar,varchar,varchar,varchar)
returns integer as '
declare
    p_impl_contract_name	alias for $1;
    p_impl_name			alias for $2;
    p_impl_operation_name	alias for $3;
    p_impl_alias		alias for $4;
    p_impl_pl			alias for $5;
    v_impl_id			integer;
begin

    v_impl_id := acs_sc_impl__get_id(p_impl_contract_name,p_impl_name);

    insert into acs_sc_impl_alias (
        impl_id,
	impl_name,
	impl_contract_name,
	impl_operation_name,
	impl_alias,
	impl_pl
    ) values (
        v_impl_id,
	p_impl_name,
	p_impl_contract_name,
	p_impl_operation_name,
	p_impl_alias,
	p_impl_pl
    );

    return v_impl_id;

end;' language 'plpgsql';




create function acs_sc_impl_alias__delete(varchar,varchar)
returns integer as '
declare
    p_impl_contract_name	alias for $1;
    p_impl_name			alias for $2;
    p_impl_operation_name	alias for $3;
    v_impl_id			integer;
begin

    v_impl_id := acs_sc_impl__get_id(p_impl_name);

    delete from acs_sc_impl_alias 
    where impl_contract_name = p_impl_contract_name 
    and impl_name = p_impl_name
    and impl_operation_name = p_impl_operation_name;

    return v_impl_id;

end;' language 'plpgsql';



create function acs_sc_binding__new(integer,integer)
returns integer as '
declare
    p_contract_id		alias for $1;
    p_impl_id			alias for $2;
    v_contract_name		varchar;
    v_impl_name			varchar;
    v_count			integer;
begin

    v_contract_name := acs_sc_contract__get_name(p_contract_id);
    v_impl_name := acs_sc_impl__get_name(p_impl_id);

    select count(*) into v_count
    from acs_sc_operation
    where contract_id = p_contract_id
    and operation_name not in (select impl_operation_name
		       	       from acs_sc_impl_alias
			       where impl_contract_name = v_contract_name
			       and impl_id = p_impl_id);

    if v_count > 0 then
        raise exception ''Binding of % to % failed.'', v_contract_name, v_impl_name;
    end if;

    insert into acs_sc_binding (
        contract_id,
	impl_id
    ) values (
        p_contract_id,
	p_impl_id
    );

    return 0;

end;' language 'plpgsql';



create function acs_sc_binding__new(varchar,varchar)
returns integer as '
declare
    p_contract_name		alias for $1;
    p_impl_name			alias for $2;
    v_contract_id		integer;
    v_impl_id			integer;
    v_count			integer;
begin

    v_contract_id := acs_sc_contract__get_id(p_contract_name);

    v_impl_id := acs_sc_impl__get_id(p_contract_name,p_impl_name);

    perform acs_sc_binding__new(v_contract_id,v_impl_id);

    return 0;

end;' language 'plpgsql';


create function acs_sc_binding__delete(integer,integer)
returns integer as '
declare
    p_contract_id		alias for $1;
    p_impl_id			alias for $2;
begin

    delete from acs_sc_binding
    where contract_id = p_contract_id
    and impl_id = p_impl_id;

    return 0;
end;' language 'plpgsql';


create function acs_sc_binding__delete(varchar,varchar)
returns integer as '
declare
    p_contract_name		alias for $1;
    p_impl_name			alias for $2;
    v_contract_id		integer;
    v_impl_id			integer;
begin

    v_contract_id := acs_sc_contract__get_id(p_contract_name);

    v_impl_id := acs_sc_impl__get_id(p_contract_name,p_impl_name);

    perform acs_sc_binding__delete(v_contract_id,v_impl_id);

    return 0;

end;' language 'plpgsql';



create function acs_sc_binding__exists_p(varchar,varchar)
returns integer as '
declare
    p_contract_name		alias for $1;
    p_impl_name			alias for $2;
    v_contract_id		integer;
    v_impl_id			integer;
    v_exists_p			integer;
begin

    v_contract_id := acs_sc_contract__get_id(p_contract_name);

    v_impl_id := acs_sc_impl__get_id(p_contract_name,p_impl_name);

    select case when count(*)=0 then 0 else 1 end into v_exists_p
    from acs_sc_binding
    where contract_id = v_contract_id
    and impl_id = v_impl_id;

    return v_exists_p;

end;' language 'plpgsql';




