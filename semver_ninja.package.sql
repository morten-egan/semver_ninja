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

	/** Return the major of a semver version
	* @author Morten Egan
	* @param semver The semver string to extract major from
	* @return number The major number (-1 if invalid semver)	
	*/
	function major (
		semver						in				varchar2
	)
	return number;

	/** Return the minor of a semver version
	* @author Morten Egan
	* @param semver The semver string to extract minor from
	* @return number The minor number (-1 if invalid semver)
	*/
	function minor (
		semver						in				varchar2
	)
	return number;

	/** Return the patch of a semver version
	* @author Morten Egan
	* @param semver The semver string to extract patch from
	* @return number The patch number (-1 if invalid semver)
	*/
	function patch (
		semver						in				varchar2
	)
	return number;

	/** Check if a version is greater than or equal to another version
	* @author Morten Egan
	* @param semver The semver to check for greater or equal
	* @param semver_compare The semver to check against
	* @return boolean True if greater or equal, False if not
	*/
	function gte (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean;

	/** Check if 2 versions are equal
	* @author Morten Egan
	* @param semver The semver to check for equality
	* @param semver_compare The semver cersion to compare equality with
	* @return boolean True if equal, False if not
	*/
	function eq (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean;

	/** Check if a version is less than or equal to another version
	* @author Morten Egan
	* @param semver The semver to check
	* @param semver_compare the semver to compare with
	* @return boolean True if less or equal to, False if not
	*/
	function lte (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean;

	/** Check for in-equality
	* @author Morten Egan
	* @param semver The semver to check
	* @param semver_compare The semver to compare in-equality against
	* @return boolean Return True if not equal, false if equal
	*/
	function neq (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean;

	/** Compare to semver versions from a operator
	* @author Morten Egan
	* @param semver The semver to check
	* @param semver_compare The semver to compare against
	* @param operator The operator to use
	* @return boolean Return true if the operator succeeds
	*/
	function cmp (
		semver						in				varchar2
		, operator					in				varchar2
		, semver_compare			in				varchar2
	)
	return boolean;

	/** Compare 2 versions against each other directly
	* @author Morten Egan
	* @param semver The first semver string
	* @param semver_compare The second semver string to compare against
	* @return number 1 if first version is greater, 0 if equal or -1 if second is greater
	*/
	function compare (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return number;

	/** Return the difference between 2 semver versions, by the name of the largest difference
	* @author Morten Egan
	* @param semver The first semver
	* @param semver_compare The second semver to compare against
	* @return varchar2 Return the highest component name with a difference (major, minor, patch)
	*/
	function diff (
		semver						in				varchar2
		, semver_compare			in				varchar2
	)
	return varchar2;

	/** This is the main check, to see if a version is satisfied, within a range.
	* @author Morten Egan
	* @param semver The version to check
	* @param logical_range The range to check against
	* @return boolean True if satisfied within range, False if not
	*/
	function satisfies (
		semver						in				varchar2
		, logical_range				in				varchar2
	)
	return boolean;

end semver_ninja;
/