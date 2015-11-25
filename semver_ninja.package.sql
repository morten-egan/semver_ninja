create or replace package semver_ninja

as

	/** This implements check and utility functions for the semver specification
	* http://semver.org/
	* @author Morten Egan
	* @version 0.0.1
	* @project SEMVER_NINJA
	*/
	p_version		varchar2(50) := '0.0.1';

	type tab_strings is table of varchar2(1000);

	function split_string (
		string_to_split						in				varchar2
		, delimiter							in				varchar2 default '.'
	)
	return tab_strings
	pipelined;

	/** Check if a semver is of valid format
	* @author Morten Egan
	* @param semver The semver string we want to validate
	* @return boolean True if the semver is of valid format, False if not
	*/
	function valid (
		semver						in				varchar2
	)
	return boolean;

	/** Check if a version is greater than another version
	* @author Morten Egan
	* @param semver The version to check
	* @return boolean True if the checking version is greater than the second version, False if not
	*/
	function gt (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean;

	/** Check if a version is smaller than another version
	* @author Morten Egan
	* @param semver The version to check if smaller
	* @return boolean True if the checking version is smaller than the second version, False if not
	*/
	function lt (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean;

	/** Clean a semver string, removing all spaces from right, and all non essential characters from left.
	* @author Morten Egan
	* @param semver The string to clean
	* @return varchar2 The cleaned up string
	*/
	function clean (
		semver						in				varchar2
	)
	return varchar2;

	/** Increment the version of the input according to the release
	* @author Morten Egan
	* @param semver The version to increase
	* @param release The part to increment (Major, Minor or Patch)
	* @return varchar2 The new version of the semver
	*/
	function inc (
		semver						in				varchar2
		, release					in				varchar2
	)
	return varchar2;

end semver_ninja;
/