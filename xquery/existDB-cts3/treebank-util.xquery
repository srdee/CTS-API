(:
  Copyright 2009 Cantus Foundation
  http://alpheios.net

  This file is part of Alpheios.

  Alpheios is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Alpheios is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)

(:
  Utilities related to treebank format
 :)

module namespace tbu = "http://alpheios.net/namespaces/treebank-util";
declare namespace tbd = "http://alpheios.net/namespaces/treebank-desc";

(: Function to get a query for a postag component :)
declare function tbu:get-format-query(
    $a_node as node(),
    $a_category as xs:string,
    $a_value as xs:string,
    $a_defaultTb as xs:string,
    $a_configDir as xs:string
) as xs:boolean
{
    let $docTb := root($a_node)//treebank/@format
    let $tb := if ($docTb) then $docTb else $a_defaultTb
    let $desc := tbu:get-format-description($tb,$a_configDir)
    let $tbEntry := $desc//tbd:table[@type='morphology']/tbd:category[@id=$a_category]/tbd:entry[tbd:short=$a_value or tbd:long=$a_value]
    return 
        if ($tbEntry and ($a_node[substring(@postag,$tbEntry/parent::tbd:category/@n,1) = $tbEntry/tbd:short])) then true() else false()
};
(:
  Function to get format name

  Parameters:
    $a_doc          treebank document (or empty if format supplied)
    $a_defaultTb    default treebank format

  Return value:
    format name or empty if not found
 :)
declare function tbu:get-format-name(
  $a_doc as node()?,
  $a_defaultTb as xs:string?) as xs:string?
{
  (: if not found in data, use default :)
  let $tb := $a_doc/*:treebank/@format
  return if ($tb) then $tb else $a_defaultTb
};

(:
  Function to get format description

  Parameters:
    $a_tb           treebank format
    $a_configDir    directory containing configuration files

  Return value:
    description element or empty if not found
 :)
declare function tbu:get-format-description(
  $a_tb as xs:string?,
  $a_configDir as xs:string) as element(tbd:desc)?
{
  doc(concat($a_configDir,
             "/treebank-desc-",
             lower-case($a_tb),
             ".xml"))/tbd:desc
};

(:
  Function to get format metadata

  Parameters:
    $a_tb           treebank format
    $a_configDir    directory containing configuration files

  Return value:
    metadata items from format description file or empty if not found
 :)
declare function tbu:get-format-metadata(
  $a_tb as xs:string?,
  $a_configDir as xs:string) as element(tbd:desc)?
{
  let $doc :=
    doc(concat($a_configDir, "/treebank-desc-", lower-case($a_tb), ".xml"))
  return
    element desc
    {
      $doc//*:meta
    }
};


(:
  Function to convert morphology postag to full name

  Parameters:
    $a_tbd            treebank format description
    $a_category       morphological category
    $a_tag            postag

  Return value:
    equivalent long name if found, else empty
 :)
declare function tbu:postag-to-name(
  $a_tbd as element(tbd:desc),
  $a_category as xs:string,
  $a_tag as xs:string?) as xs:string?
{
  if ($a_tag)
  then
    let $table := $a_tbd/tbd:table[@type eq "morphology"]
                        /tbd:category[@id eq $a_category]
    let $entry := $table/tbd:entry[tbd:short eq substring($a_tag, $table/@n, 1)]
    return string($entry/tbd:long)
  else ()
};

(:
  Function to convert morphology postag to lexicon schema value

  Parameters:
    $a_tbd            treebank format description
    $a_category       morphological category
    $a_tag            postag

  Return value:
    equivalent name if found, else empty

  If a lexicon value is not present, the long name is used.
 :)
declare function tbu:postag-to-lexicon(
  $a_tbd as element(tbd:desc),
  $a_category as xs:string,
  $a_tag as xs:string?) as xs:string?
{
  if ($a_tag)
  then
    let $table := $a_tbd/tbd:table[@type eq "morphology"]
                        /tbd:category[@id eq $a_category]
    let $entry := $table/tbd:entry[tbd:short eq substring($a_tag, $table/@n, 1)]
    return
      if (exists($entry/tbd:lex))
      then
        string($entry/tbd:lex)
      else
        string($entry/tbd:long)
  else ()
};

(:
  Function to convert morphology code to full name

  Parameters:
    $a_tbd            treebank format description
    $a_category       morphological category
    $a_code           short code

  Return value:
    equivalent long name if found, else empty
 :)
declare function tbu:code-to-name(
  $a_tbd as element(tbd:desc),
  $a_category as xs:string,
  $a_code as xs:string?) as xs:string?
{
  if ($a_code)
  then
    let $table := $a_tbd/tbd:table[@type eq "morphology"]
                        /tbd:category[@id eq $a_category]
    return string($table/tbd:entry[tbd:short eq $a_code]/tbd:long)
  else ()
};

(:
  Function to convert morphology full name to code

  Parameters:
    $a_tbd            treebank format description
    $a_category       morphological category
    $a_name           full name

  Return value:
    equivalent code if found, else empty
 :)
declare function tbu:name-to-code(
  $a_tbd as element(tbd:desc),
  $a_category as xs:string,
  $a_name as xs:string?) as xs:string?
{
  if ($a_name)
  then
    let $table := $a_tbd/tbd:table[@type eq "morphology"]
                        /tbd:category[@id eq $a_category]
    return string($table/tbd:entry[tbd:long eq $a_name]/tbd:short)
  else ()
};

(:
  Functions to convert dependency relation name to display form/help

  Parameters:
    $a_tbd            treebank format description
    $a_rel            relation

  Return value:
    empty if no input specified, else
    1) equivalent display name, or input value if no display form found
    2) help text
 :)
declare function tbu:relation-to-display(
  $a_tbd as element(tbd:desc),
  $a_rel as xs:string?) as xs:string
{
  if ($a_rel)
  then
    let $table := $a_tbd/tbd:table[@type eq "relation"]
    let $entry := $table/tbd:entry[tbd:tb eq $a_rel]
    let $display := string($entry/tbd:disp)
    return
      if ($entry/tbd:disp) then string($entry/tbd:disp) else $a_rel
  else ()
};

declare function tbu:relation-to-help(
  $a_tbd as element(tbd:desc),
  $a_rel as xs:string?) as element()*
{
  if ($a_rel)
  then
    $a_tbd/tbd:table[@type eq "relation"]/tbd:entry[tbd:tb = $a_rel]/tbd:help
  else ()
};

(:
  Function to get entries

  Parameters:
    $a_tbd          treebank format description
    $a_type         type of entries to get

  Return value:
    list of entries for or empty if none exists
 :)
declare function tbu:get-entries(
  $a_tbd as element(tbd:desc),
  $a_type as xs:string) as element(tbd:entry)*
{
  $a_tbd/tbd:table[@type eq $a_type]/tbd:entry
};