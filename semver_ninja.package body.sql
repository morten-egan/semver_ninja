create or replace package body semver_ninja

as

	type semver_rec is record (
		major			number
		, minor			number
		, patch			number
	);

	function split_string (
		string_to_split						in				varchar2
		, delimiter							in				varchar2 default '.'
	)
	return tab_strings
	pipelined
	
	as
	
		cursor c_tokenizer(ci_string in varchar2, ci_delimiter in varchar2) is
			select 
				regexp_substr(str, '[^' || ci_delimiter || ']+', 1, level) as splitted_element,
				level as element_no
			from 
				(select rownum as id, ci_string str from dual)
			connect by instr(str, ci_delimiter, 1, level - 1) > 0
			and id = prior id
			and prior dbms_random.value is not null;
	
	begin
	

		for c1 in c_tokenizer(string_to_split, delimiter) loop
			pipe row(c1.splitted_element);
		end loop;
	
	
		return;
	
		exception
			when others then
				raise;
	
	end split_string;

	function construct_semver (
		semver						in				semver_rec
	)
	return varchar2
	
	as
	
		l_ret_val			varchar2(150);
	
	begin
	
		dbms_application_info.set_action('construct_semver');

		l_ret_val := semver.major || '.' || semver.minor || '.' || semver.patch;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end construct_semver;

	function parse_semver (
		semver						in				varchar2
	)
	return semver_rec
	
	as
	
		l_ret_val			semver_rec;
	
	begin
	
		dbms_application_info.set_action('parse_semver');

		l_ret_val.major := null;
		l_ret_val.minor := null;
		l_ret_val.patch := null;

		for x in (select rownum, column_value from table(semver_ninja.split_string(semver,'.'))) loop
			if length(x.column_value) > 1 and substr(x.column_value,1,1) = '0' then
				l_ret_val.major := null;
				l_ret_val.minor := null;
				l_ret_val.patch := null;
			else
				if x.rownum = 1 then
					l_ret_val.major := x.column_value;
				elsif x.rownum = 2 then
					l_ret_val.minor := x.column_value;
				elsif x.rownum = 3 then
					l_ret_val.patch := x.column_value;
				else
					l_ret_val.major := null;
					l_ret_val.minor := null;
					l_ret_val.patch := null;
				end if;
			end if;
		end loop;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				l_ret_val.major := null;
				l_ret_val.minor := null;
				l_ret_val.patch := null;
				return l_ret_val;
	
	end parse_semver;

	function valid (
		semver						in				varchar2
	)
	return boolean
	
	as
	

		l_ret_val			boolean := false;
		l_semver			semver_rec;
	
	begin
	
		dbms_application_info.set_action('valid');

		l_semver.major := null;
		l_semver.minor := null;
		l_semver.patch := null;

		l_semver := parse_semver(clean(semver));

		if l_semver.major is null or l_semver.minor is null or l_semver.patch is null then
			l_ret_val := false;
		else
			l_ret_val := true;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				return l_ret_val;
	
	end valid;

	function gt (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
		l_semver			semver_rec;
		l_semver_compare	semver_rec;
	
	begin
	
		dbms_application_info.set_action('gt');

		if valid(semver) and valid(semver_compare) then
			l_semver := parse_semver(semver);
			l_semver_compare := parse_semver(semver_compare);

			if l_semver.major > l_semver_compare.major then
				l_ret_val := true;
			elsif l_semver.major = l_semver_compare.major then
				-- Same major, go on to compare minor
				if l_semver.minor > l_semver_compare.minor then
					l_ret_val := true;
				elsif l_semver.minor = l_semver_compare.minor then
					-- Same minor, compare patch
					if l_semver.patch > l_semver_compare.patch then
						l_ret_val := true;
						-- TODO: Compare pre-releases when implemented
					else
						l_ret_val := false;
					end if;
				else
					l_ret_val := false;
				end if;
			else
				l_ret_val := false;
			end if;
		else
			l_ret_val := false;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end gt;

	function lt (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
	
	begin
	
		dbms_application_info.set_action('lt');

		-- Fastest way to do this, is just to reverse the semvers and do greater than
		l_ret_val := gt(semver_compare, semver);
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end lt;

	function clean (
		semver						in				varchar2
	)
	return varchar2
	
	as
	
		l_ret_val			varchar2(150) := semver;
	
	begin
	
		dbms_application_info.set_action('clean');

		l_ret_val := rtrim(l_ret_val);
		l_ret_val := ltrim(l_ret_val);
		-- Now that we have remove spaces, we will remove some of the characters
		-- that people tend to prefix versions with
		l_ret_val := ltrim(l_ret_val, '=');
		l_ret_val := ltrim(l_ret_val, 'v');
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end clean;

	function inc (
		semver						in				varchar2
		, release					in				varchar2
	)
	return varchar2
	
	as
	
		l_semver			semver_rec;
		l_ret_val			varchar2(150);
	
	begin
	
		dbms_application_info.set_action('inc');

		if valid(semver) then
			l_semver := parse_semver(semver);
			if upper(release) = 'MAJOR' then
				l_semver.major := l_semver.major + 1;
				l_semver.minor := 0;
				l_semver.patch := 0;
			elsif upper(release) = 'MINOR' then
				l_semver.minor := l_semver.minor + 1;
				l_semver.patch := 0;
			elsif upper(release) = 'PATCH' then
				l_semver.patch := l_semver.patch + 1;
			end if;
			l_ret_val := construct_semver(l_semver);
		else
			l_ret_val := semver;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end inc;

	function major (
		semver						in				varchar2
	)
	return number
	
	as
	
		l_semver			semver_rec;
		l_ret_val			number := -1;
	
	begin
	
		dbms_application_info.set_action('major');

		l_semver := parse_semver(semver);

		l_ret_val := l_semver.major;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				return l_ret_val;
	
	end major;

	function minor (
		semver						in				varchar2
	)
	return number
	
	as
	
		l_semver			semver_rec;
		l_ret_val			number := -1;
	
	begin
	
		dbms_application_info.set_action('minor');

		l_semver := parse_semver(semver);

		l_ret_val := l_semver.minor;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				return l_ret_val;
	
	end minor;

	function patch (
		semver						in				varchar2
	)
	return number
	
	as
	
		l_semver			semver_rec;
		l_ret_val			number := -1;
	
	begin
	
		dbms_application_info.set_action('patch');

		l_semver := parse_semver(semver);

		l_ret_val := l_semver.patch;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				return l_ret_val;
	
	end patch;

	function gte (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
		l_semver			semver_rec;
		l_semver_compare	semver_rec;
	
	begin
	
		dbms_application_info.set_action('gte');

		if valid(semver) and valid(semver_compare) then
			l_semver := parse_semver(semver);
			l_semver_compare := parse_semver(semver_compare);

			if l_semver.major > l_semver_compare.major then
				l_ret_val := true;
			elsif l_semver.major = l_semver_compare.major and l_semver.minor > l_semver_compare.minor then
				l_ret_val := true;
			elsif l_semver.major = l_semver_compare.major and l_semver.minor = l_semver_compare.minor and l_semver.patch > l_semver_compare.patch then
				l_ret_val := true;
			elsif l_semver.major = l_semver_compare.major and l_semver.minor = l_semver_compare.minor and l_semver.patch = l_semver_compare.patch then
				l_ret_val := true;
			else
				l_ret_val := false;
			end if;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				return l_ret_val;
	
	end gte;

	function eq (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
		l_semver			semver_rec;
		l_semver_compare	semver_rec;
	
	begin
	
		dbms_application_info.set_action('eq');

		if valid(semver) and valid(semver_compare) then
			l_semver := parse_semver(semver);
			l_semver_compare := parse_semver(semver_compare);

			if l_semver.major = l_semver_compare.major and l_semver.minor = l_semver_compare.minor and l_semver.patch = l_semver_compare.patch then
				l_ret_val := true;
			else
				l_ret_val := false;
			end if;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				return l_ret_val;
	
	end eq;

	function lte (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
	
	begin
	
		dbms_application_info.set_action('lte');

		if eq(semver, semver_compare) then
			l_ret_val := true;
		elsif gt(semver_compare, semver) then
			l_ret_val := true;
		else
			l_ret_val := false;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				return l_ret_val;
	
	end lte;

	function neq (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
	
	begin
	
		dbms_application_info.set_action('neq');

		if eq(semver, semver_compare) then
			l_ret_val := false;
		else
			l_ret_val := true;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				return l_ret_val;
	
	end neq;

	function cmp (
		semver						in				varchar2
		, operator					in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
		l_semver			semver_rec;
		l_semver_compare	semver_rec;
	
	begin
	
		dbms_application_info.set_action('cmp');

		if valid(semver) and valid(semver_compare) then
			if operator = '=' then
				if eq(semver, semver_compare) then
					l_ret_val := true;
				end if;
			elsif operator = '>=' then
				if gte(semver, semver_compare) then
					l_ret_val := true;
				end if;
			elsif operator = '<=' then
				if lte(semver, semver_compare) then
					l_ret_val := true;
				end if;
			elsif operator = '>' then
				if gt(semver, semver_compare) then
					l_ret_val := true;
				end if;
			elsif operator = '<' then
				if lt(semver, semver_compare) then
					l_ret_val := true;
				end if;
			end if;
		else
			l_ret_val := false;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				return l_ret_val;
	
	end cmp;

begin

	dbms_application_info.set_client_info('semver_ninja');
	dbms_session.set_identifier('semver_ninja');

end semver_ninja;
/