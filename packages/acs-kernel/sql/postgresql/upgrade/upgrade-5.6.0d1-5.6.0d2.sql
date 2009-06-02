alter table persons add bio text;

create function inline_0 ()
returns integer as '
declare
  one_user_id integer;
  bio_id integer;
  attr_id integer;
begin

  bio_id := attribute_id
            from acs_attributes
            where object_type = ''person''
            and attribute_name = ''bio'';

  for one_user_id in select user_id from users loop
    if exists(select attr_value
              from acs_attribute_values
              where object_id = one_user_id
              and attribute_id = bio_id) then
      update persons
      set bio = (select attr_value
                 from acs_attribute_values
                 where object_id = one_user_id
                 and attribute_id = bio_id)
      where person_id = one_user_id;
    end if;
  end loop;

  delete from acs_attribute_values
  where attribute_id = bio_id;

  perform acs_attribute__drop_attribute (''person'',''bio'');
  perform acs_attribute__drop_attribute (''person'',''bio_mime_type'');

  attr_id := acs_attribute__create_attribute (
        ''person'',
        ''bio'',
        ''string'',
        ''#acs-kernel.Bio#'',
        ''#acs-kernel.Bios#'',
        null,
        null,
        null,
	0,
	1,
        null,
        ''type_specific'',
        ''f''
      );

  return 0;

end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

