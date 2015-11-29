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

	function translate_x_range (
		x_range						in				varchar2
	)
	return varchar2
	
	as
	
		l_semver			semver_rec;
		l_ret_val			varchar2(50);
		l_dot_count			number;
	
	begin
	
		dbms_application_info.set_action('translate_x_range');

		if x_range = '*' or upper(x_range) = 'X' then
			l_ret_val := '>=0.0.0';
		else
			l_dot_count := length(x_range) - length(replace(x_range,'.'));
			if l_dot_count = 1 or l_dot_count = 0 then
				-- We only have major, and minor should be a x or a *
				l_semver.major := to_number(substr(x_range, 1, instr(x_range, '.') - 1));
				l_semver.minor := 0;
				l_semver.patch := 0;
				l_ret_val := '>=' || to_char(l_semver.major) || '.' || to_char(l_semver.minor) || '.' || to_char(l_semver.patch) || ' <' || to_char(l_semver.major + 1) || '.' || to_char(l_semver.minor) || '.' || to_char(l_semver.patch);
			elsif l_dot_count = 2 then
				l_semver.major := to_number(substr(x_range, 1, instr(x_range, '.') - 1));
				l_semver.minor := to_number(substr(x_range, instr(x_range, '.') + 1, instr(x_range,'.',1,2) - (instr(x_range,'.') + 1)));
				l_semver.patch := 0;
				l_ret_val := '>=' || to_char(l_semver.major) || '.' || to_char(l_semver.minor) || '.' || to_char(l_semver.patch) || ' <' || to_char(l_semver.major) || '.' || to_char(l_semver.minor + 1) || '.' || to_char(l_semver.patch);
			end if;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end translate_x_range;

	function translate_tilde_range (
		tilde_range						in				varchar2
	)
	return varchar2
	
	as
	
		l_semver			semver_rec;
		l_ret_val			varchar2(50);
		l_dot_count			number;
	
	begin
	
		dbms_application_info.set_action('translate_tilde_range');

		l_dot_count := length(tilde_range) - length(replace(tilde_range,'.'));
		if l_dot_count = 0 then
			-- We have just major
			-- Same as major.*
			l_semver.major := to_number(tilde_range);
			l_semver.minor := 0;
			l_semver.patch := 0;
			l_ret_val := '>=' || to_char(l_semver.major) || '.' || to_char(l_semver.minor) || '.' || to_char(l_semver.patch) || ' <' || to_char(l_semver.major + 1) || '.' || to_char(l_semver.minor) || '.' || to_char(l_semver.patch);
		elsif l_dot_count = 1 then
			-- We have major and minor
			l_semver.major := to_number(substr(tilde_range, 1, instr(tilde_range, '.') - 1));
			l_semver.minor := to_number(substr(tilde_range, instr(tilde_range, '.') + 1));
			l_semver.patch := 0;
			l_ret_val := '>=' || to_char(l_semver.major) || '.' || to_char(l_semver.minor) || '.' || to_char(l_semver.patch) || ' <' || to_char(l_semver.major) || '.' || to_char(l_semver.minor + 1) || '.' || to_char(l_semver.patch);
		elsif l_dot_count = 2 then
			-- We have all
			-- We have major and minor and patch
			l_semver.major := to_number(substr(tilde_range, 1, instr(tilde_range, '.') - 1));
			l_semver.minor := to_number(substr(tilde_range, instr(tilde_range, '.') + 1, instr(tilde_range,'.',1,2) - (instr(tilde_range,'.') + 1)));
			l_semver.patch := to_number(substr(tilde_range, instr(tilde_range, '.', 1, 2) + 1));
			l_ret_val := '>=' || to_char(l_semver.major) || '.' || to_char(l_semver.minor) || '.' || to_char(l_semver.patch) || ' <' || to_char(l_semver.major) || '.' || to_char(l_semver.minor + 1) || '.0';
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end translate_tilde_range;

	function translate_caret_range (
		caret_range						in				varchar2
	)
	return varchar2
	
	as
	
		l_semver			semver_rec;
		l_ret_val			varchar2(50);
		l_dot_count			number;
		l_dotval_tmp		varchar2(4);
	
	begin
	
		dbms_application_info.set_action('translate_caret_range');

		l_dot_count := length(caret_range) - length(replace(caret_range,'.'));
		if l_dot_count = 1 then
			-- Expect zero patch, and either wildcard minor or set minor
			l_semver.major := to_number(substr(caret_range, 1, instr(caret_range, '.') - 1));
			-- Get minor
			l_dotval_tmp := substr(caret_range, instr(caret_range, '.') + 1);
			if l_dotval_tmp = '*' or upper(l_dotval_tmp) = 'X' then
				if l_semver.major = 0 then
					l_ret_val := '>=0.0.0 <1.0.0';
				else
					l_ret_val := '>=' || to_char(l_semver.major) || '.0.0 <' || to_char(l_semver.major + 1) || '.0.0';
				end if;
			else
				l_semver.minor := to_number(l_dotval_tmp);
				if l_semver.major = 0 then
					l_ret_val := '>=0.' || to_char(l_semver.minor) || '.0 <0.' || to_char(l_semver.minor + 1) || '.0';
				else
					l_ret_val := '>=' || to_char(l_semver.major) || '.' || to_char(l_semver.minor) || '.0 <' || to_char(l_semver.major + 1) || '.0.0';
				end if;
			end if;
		elsif l_dot_count = 2 then
			-- We have a full version, patch can still be wildcard.
			l_semver.major := to_number(substr(caret_range, 1, instr(caret_range, '.') - 1));
			l_semver.minor := to_number(substr(caret_range, instr(caret_range, '.') + 1, instr(caret_range,'.',1,2) - (instr(caret_range,'.') + 1)));
			l_dotval_tmp := substr(caret_range, instr(caret_range, '.', 1, 2) + 1);
			if l_dotval_tmp = '*' or upper(l_dotval_tmp) = 'X' then
				l_semver.patch := 0;
			else
				l_semver.patch := to_number(l_dotval_tmp);
			end if;
			if l_semver.major = 0 and l_semver.minor = 0 and l_semver.patch = 0 then
				l_ret_val := '>=0.0.0 <0.1.0';
			elsif l_semver.major = 0 and l_semver.minor = 0 then
				l_ret_val := '>=0.0.' || to_char(l_semver.patch) || ' <0.0.' || to_char(l_semver.patch + 1);
			elsif l_semver.major = 0 then
				l_ret_val := '>=0.' || to_char(l_semver.minor) || '.' || to_char(l_semver.patch) || ' <0.' || to_char(l_semver.minor + 1) || '.0';
			else
				l_ret_val := '>=' || to_char(l_semver.major) || '.' || to_char(l_semver.minor) || '.' || to_char(l_semver.patch) || ' <' || to_char(l_semver.major + 1) || '.0.0';
			end if;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end translate_caret_range;

	function satisfies (
		semver						in				varchar2
		, logical_range				in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val					boolean := false;
		l_current_range_type		varchar2(1);
		l_range						varchar2(500);
		l_current_range_1			varchar2(500);
		l_current_range_2			varchar2(500);

		cursor c_more_ors(operations varchar2) is
			select
				rownum
				, column_value
			from
				table(semver_ninja.split_string(operations, '||'));
	
	begin
	
		dbms_application_info.set_action('satisfies');

		if valid(semver) then
			-- Let us check if we have any OR operators in the logical range.
			-- If so loop over every OR operation.
			if instr(logical_range, '||') > 0 then
				-- We have multiple range sets in an OR combination
				for ind_or in c_more_ors(logical_range) loop
					l_range := ind_or.column_value;
					if substr(trim(l_range), 1, 1) = '~' then
						-- Tilde type
						l_current_range_type := '~';
						l_current_range_1 := translate_tilde_range(clean(replace(l_range, '~')));
						l_current_range_2 := substr(l_current_range_1, instr(l_current_range_1, ' ') + 1);
						l_current_range_1 := substr(l_current_range_1, 1, instr(l_current_range_1, ' ') - 1);
					elsif substr(trim(l_range), 1, 1) = '^' then
						l_current_range_type := '^';
						l_current_range_1 := translate_caret_range(clean(replace(l_range, '^')));
						l_current_range_2 := substr(l_current_range_1, instr(l_current_range_1, ' ') + 1);
						l_current_range_1 := substr(l_current_range_1, 1, instr(l_current_range_1, ' ') - 1);
					elsif instr(replace(l_range,' '), '-') > 0 then
						l_current_range_type := '-';
					else
						-- One version range comparison
						l_current_range_type := '*';
					end if;

					-- Now we have the type and the comparison values, check if True or False
					if cmp(semver, substr(l_current_range_1, 1, regexp_instr(l_current_range_1, '[[:digit:]]') -1), substr(l_current_range_1, regexp_instr(l_current_range_1, '[[:digit:]]'))) and cmp(semver, substr(l_current_range_2, 1, regexp_instr(l_current_range_2, '[[:digit:]]') -1), substr(l_current_range_2, regexp_instr(l_current_range_2, '[[:digit:]]'))) then
						l_ret_val := true;
					end if;
				end loop;
			else
				l_range := logical_range;
				-- First we need to decide the range type
				if substr(trim(l_range), 1, 1) = '~' then
					-- Tilde type
					l_current_range_type := '~';
					l_current_range_1 := translate_tilde_range(clean(replace(l_range, '~')));
					l_current_range_2 := substr(l_current_range_1, instr(l_current_range_1, ' ') + 1);
					l_current_range_1 := substr(l_current_range_1, 1, instr(l_current_range_1, ' ') - 1);
				elsif substr(trim(l_range), 1, 1) = '^' then
					l_current_range_type := '^';
					l_current_range_1 := translate_caret_range(clean(replace(l_range, '^')));
					l_current_range_2 := substr(l_current_range_1, instr(l_current_range_1, ' ') + 1);
					l_current_range_1 := substr(l_current_range_1, 1, instr(l_current_range_1, ' ') - 1);
				elsif instr(replace(l_range,' '), '-') > 0 then
					l_current_range_type := '-';
				else
					-- One version range comparison
					l_current_range_type := '*';
				end if;

				-- Now we have the type and the comparison values, check if True or False
				if cmp(semver, substr(l_current_range_1, 1, regexp_instr(l_current_range_1, '[[:digit:]]') -1), substr(l_current_range_1, regexp_instr(l_current_range_1, '[[:digit:]]'))) and cmp(semver, substr(l_current_range_2, 1, regexp_instr(l_current_range_2, '[[:digit:]]') -1), substr(l_current_range_2, regexp_instr(l_current_range_2, '[[:digit:]]'))) then
					l_ret_val := true;
				end if;
			end if;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end satisfies;

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

	function compare (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return number
	
	as
	
		l_ret_val			number := null;
	
	begin
	
		dbms_application_info.set_action('compare');

		if eq(semver, semver_compare) then
			l_ret_val := 0;
		elsif gt(semver, semver_compare) then
			l_ret_val := 1;
		elsif gt(semver_compare, semver) then
			l_ret_val := -1;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				return l_ret_val;
	
	end compare;

	function diff (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return varchar2
	
	as
	
		l_ret_val			varchar2(25) := null;
		l_semver			semver_rec;
		l_semver_compare	semver_rec;
	
	begin
	
		dbms_application_info.set_action('diff');

		if valid(semver) and valid(semver_compare) then
			l_semver := parse_semver(semver);
			l_semver_compare := parse_semver(semver_compare);

			if l_semver.major != l_semver_compare.major then
				l_ret_val := 'major';
			elsif l_semver.minor != l_semver_compare.minor then
				l_ret_val := 'minor';
			elsif l_semver.patch != l_semver_compare.patch then
				l_ret_val := 'patch';
			end if;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				return l_ret_val;
	
	end diff;

begin

	dbms_application_info.set_client_info('semver_ninja');
	dbms_session.set_identifier('semver_ninja');

end semver_ninja;
/