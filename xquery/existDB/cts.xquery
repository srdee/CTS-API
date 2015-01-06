xquery version "3.0"; 
(:
  Copyright 2010-2014 The Alpheios Project, Ltd.
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

(: Beginnings of the CTS Repository Interface Implementation :)
(: TODO LIST
            support ranges subreferences
            namespacing on cts responses
            getPassage
            getValidReff
            typecheck the function parameters and return values
            make getNextPrev recursive so that it can point to first/last in next/previous book, etc.
:)

module namespace ctsx = "http://alpheios.net/namespaces/cts";

import module namespace cts-utils="http://alpheios.net/namespaces/cts-utils"
       at "cts-utils.xquery";
import module namespace ctsi = "http://alpheios.net/namespaces/cts-implementation"
       at "cts-impl.xquery";
import module namespace console = "http://exist-db.org/xquery/console";

declare namespace CTS = "http://chs.harvard.edu/xmlns/cts";
declare namespace ti = "http://chs.harvard.edu/xmlns/cts";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace dc = "http://purl.org/dc/elements/1.1/";

declare variable $ctsx:tocChunking :=
(
    <tocChunk type="Book" size="1"/>,
    <tocChunk type="Column" size="1"/>,
    <tocChunk type="Volume" size="1"/>,
    <tocChunk type="Section" size="1"/>,
    <tocChunk type="Chapter" size="1"/>,
    <tocChunk type="Article" size="1"/>,
    <tocChunk type="Line" size="30"/>,
    <tocChunk type="Verse" size="30"/>,
    <tocChunk type="Fragment" size="1"/>,
    <tocChunk type="Page" size="1"/>,
    <tocChunk type="Entry" size="1"/>
);

declare variable $ctsx:maxPassageNodes := 100;
declare variable $ctsx:defaultInventory := "alpheios-cts-inventory";

(: for backwards compatibility default to alpheios inventory :)
declare function ctsx:parseUrn($a_urn as xs:string)
{
  ctsx:parseUrn($ctsx:defaultInventory, $a_urn)
};
(:
    function to parse a CTS Urn down to its individual parts
    Parameters:
        $a_urn: the CTS URN (e.g. urn:cts:greekLit:tlg012.tlg002.alpheios-text-grc1)
    Return value:
        A) if $a_urn is a valid cts urn: an element adhering to the following
        <ctsUrn>
            <namespace></namespace>
            <groupname></groupname>
            <title></title>
            <label></label>
            <workUrn></workUrn>
            <textgroup></textgroup>
            <work></work>
            <version></version>
            <passageParts>
                <rangePart>
                    <part></part>
                    <part><part>
                </rangePart>
                <rangePart>
                    <part></part>
                    <part><part>
                </rangePart>
            </passageParts>
            <subref position="">
            </subref>
            <fileInfo>
                <basePath></basePath>
                <alpheiosEditionId></alpheiosEditionId>
                <alpheiosDoctype></alpheiosDocType>
            </fileInfo>
        <ctsUrn>
        B) Or if $a_urn is a text string as identified by the prefix 'alpheiosusertext:<lang>' then
        returns a <dummy><usertext lang="<lang>">Text String</usertext></dummy>
        TODO this latter option is a bit of hack, should look at a better way to handle this
        but since most requests go through parseUrn, this was the easiest place for now
:)
declare function ctsx:parseUrn($a_inv as xs:string, $a_urn as xs:string)
{
  if (fn:matches($a_urn, '^alpheiosusertext:'))
  then
    let $parts := fn:tokenize($a_urn,':')
    let $lang := $parts[2]
    let $text := fn:string-join(fn:subsequence($parts, 3), ' ')
    return
      <dummy>
        <usertext lang="{$lang}">{$text}</usertext>
      </dummy>
  else
    let $components := fn:tokenize($a_urn, ":")
    let $namespace := $components[3]
    let $workComponents := fn:tokenize($components[4], "\.")
    (: TODO do we need to handle the possibility of a work without a text group? :)
    let $textgroup := $workComponents[1]
    let $work := $workComponents[2]

    let $passage := $components[5]
    let $passageComponents := fn:tokenize($components[5], "-")
    let $part1 := $passageComponents[1]
    let $part2 := $passageComponents[2]
    let $part2 := if (fn:empty($part2)) then $part1 else $part2

    let $namespaceUrn := fn:string-join($components[1 to 3], ":")
    let $groupUrn := $namespaceUrn || ":" || $textgroup
    let $workUrn := $groupUrn || "." || $work
    let $cat := ctsx:getCapabilities($a_inv, $groupUrn, $workUrn)
    let $catwork :=
      $cat//ti:textgroup[@urn eq $groupUrn]/ti:work[@urn eq $workUrn]
    let $version :=
      (: if version specified, use it :)
      if (fn:count($workComponents) > 2)
      then
        $workComponents[fn:last()]
      (: otherwise use default for the work :)
      else
        fn:substring-after(
          $catwork/(ti:edition|ti:translation)[@default]/@urn,
          ":"
        )
    let $versionUrn := $workUrn || "." || $version
    let $catversion := $catwork/(ti:edition|ti:translation)[@urn eq $versionUrn]

    return
      element ctsURN
      {
        element urn { $a_urn },
        (: urn without any passage specifics:)
        element groupUrn { $groupUrn },
        element versionUrn { $versionUrn },
        element versionLang { $catversion/@xml:lang },
        element workUrn { $workUrn },
        element workLang { $catwork/@xml:lang },
        element namespace{ $namespace },
        (: TODO is it possible for components of the work id to be in different namespaces?? :)
        for $gn in $cat//ti:textgroup[@urn eq $groupUrn]
                        /ti:groupname
        return
          element groupname
          {
            $gn/@xml:lang,
            xs:string($gn)
          },
        for $ti in $catwork/ti:title
        return
          element title
          {
            attribute xml:lang { $ti/@xml:lang},
            xs:string($ti)
          },
        for $lab in $catversion/ti:label
        return
          element label
          {
            attribute xml:lang { $lab/@xml:lang},
            xs:string($lab)
          },
        element passage { $passage },
        element passageParts
        {
          ctsx:_parseRangePart($part1),
          ctsx:_parseRangePart($part2)
        },
        element fileInfo
        {
          if (fn:starts-with($version, 'alpheios-'))
          then
            (: TODO look up the path in the TextInventory :)
            let $parts := fn:tokenize($version,'-')
            return
            (
              element basePath
              {
                "/db/repository/" ||
                $namespace ||
                "/" ||
                fn:string-join(
                  fn:subsequence($workComponents, 1, fn:count($workComponents) - 1),
                  "/"
                )
              },
              element fullPath
              {
                if (fn:exists($catversion))
                then
                  $catversion/ti:online/@docname/fn:string()
                else
                  "/db/repository/" ||
                  $namespace ||
                  "/" ||
                  fn:string-join($workComponents, "/") ||
                  $version ||
                  ".xml"
              },
              element alpheiosDocType { $parts[2] },
              for $i in fn:subsequence($parts, 3)
              return element alpheiosEditionId { $i }
            )
          else if (fn:not($version))
          then
            element basePath
            {
              "/db/repository/" ||
              $namespace ||
              "/" ||
              fn:string-join($workComponents, "/")
            }
          else if ($catversion)
          then
            element fullPath { $catversion/ti:online/@docname/fn:string() }
          else()
        }
      }
};

declare %private function ctsx:_parseRangePart($part1)
{
  if (fn:empty($part1)) then () else

  let $subparts := fn:tokenize($part1, "@")
  let $subref := $subparts[2]
  return
    element rangePart
    {
      for $p in fn:tokenize($subparts[1], "\.")
      return element part { $p },

      if (fn:exists($subref))
      then
        if (fn:matches($subref, ".*\[.*\]"))
        then
          let $string := fn:substring-before($subref, "[")
          let $pos := fn:substring-before(fn:substring-after($subref, "["), "]")
          let $pos :=
            if ($pos castable as xs:positiveInteger)
            then
              xs:positiveInteger($pos)
            else
              fn:error(
                xs:QName("BAD-SUBREF"),
                "Subref index not a positive integer: " || $pos
              )
          return element subRef { attribute position { $pos }, $string }
        else
          element subRef { attribute position { 1 }, $subref }
      else ()
    }
};

(: function to retrieve a subreference from a document
    Parameters:
        $a_urn: the CTS URN
    Return Value:
        <reply>
            <TEI>
                [the referenced element]
            </TEI>
          </reply>
:)

declare function ctsx:findSubRef($a_passage,$a_subref)
{
  if ($a_passage//wd)
  then
    $a_passage//wd[. = $a_subref][$a_subref/@position][1]
  else
    $a_passage//tei:wd[. = $a_subref][$a_subref/@position][1]
};

(:
    get a passage from a text
    Parameters:
        $a_inv the inventory name
        $a_urn the passage urn
    Return Value:
        getPassage reply
:)
declare function ctsx:getPassage(
  $a_inv as xs:string,
  $a_urn as xs:string
) as element(CTS:reply)
{
  element CTS:reply
  {
    element CTS:urn { $a_urn },
    ctsx:extractPassage($a_inv, $a_urn)
  }
};

(:
    CTS getCapabilities request
    Parameters:
        $a_inv - the inventory name
        $a_groupid - group id (optional)
        $a_workid - work id (optional) 
    Return Value
        the requested catalog entries

    If group and work ids are supplied, only that work will be returned
    otherwise all works in the inventory will be returned
:)
declare function ctsx:getCapabilities($a_inv)
{
  (: get all works in inventory :)
  ctsx:getCapabilities($a_inv, (), ())
};
declare function ctsx:getCapabilities($a_inv, $a_groupUrn, $a_workUrn)
{
  let $ti := (/ti:TextInventory[@tiid = $a_inv])[1]
  let $groups :=
    (: specified work :)
    if (fn:exists($a_groupUrn) and fn:exists($a_workUrn))
    then /ti:textgroup[@tiid eq $a_inv][@urn eq $a_groupUrn]
    (: else all groups in inventory :)
    else /ti:textgroup[@tiid eq $a_inv]
  let $groupUrns := fn:distinct-values($groups/@urn)
  let $works :=
    (: specified work :)
    if (fn:exists($a_groupUrn) and fn:exists($a_workUrn))
    then /ti:work[@groupUrn = $groupUrns][@urn eq $a_workUrn]
    (: all works in inventory :)
    else /ti:work[@groupUrn = $groupUrns]

  return
    element CTS:reply
    {
      element ti:TextInventory
      {
        (:
        attribute {concat('xmlns:', "ti")} { "http://chs.harvard.edu/xmlns/cts3/ti" },
        attribute {concat('xmlns:', "dc")} { "http://purl.org/dc/elements/1.1/" },
        attribute tiversion { "5.0.rc.1" },
        :)
        $ti/@*,
        $ti/*,
        for $group in $groups
        let $groupWorks := $works[@groupUrn eq $group/@urn]
        where fn:count($groupWorks) gt 0
        order by $group/@urn
        return
          element ti:textgroup
          {
            $group/@urn,
            $group/*,
            for $work in $groupWorks
            order by $work/@urn
            return
              element ti:work
              {
                $work/(@urn,@xml:lang),
                $work/*,
                for $version in
                  /(ti:edition|ti:translation)[@workUrn eq $work/@urn]
                order by $version/@urn
                return
                  element { fn:node-name($version) }
                  {
                    $version/@urn,
                    $version/*
                  }
              }
          }
      }
    }
};

(:
    CTS getValidReff request (with or without specified level)
    Parameters:
        $a_inv the inventory name
        $a_urn the passage urn
        $a_level citation level
    Returns
        the list of valid urns
:)
declare function ctsx:getValidReff($a_inv, $a_urn) as element(CTS:reply)
{
  let $cts := ctsx:parseUrn($a_inv, $a_urn)
  let $entry := ctsx:getCatalogEntry($cts)
  let $nparts := fn:count($cts/passageParts/rangePart[1]/part)
  return
    ctsx:getValidReff(
      $a_inv,
      $a_urn,
      (: if one or more parts of the passage component are specified, the level is implicitly
         the next level after the one supplied, otherwise retrieve all levels
      :)
      if ($nparts ge 1)
      then $nparts + 1
      else fn:count($entry/ti:online//ti:citation)
    )
};
declare function ctsx:getValidReff(
  $a_inv as xs:string,
  $a_urn as xs:string,
  $a_level as xs:int
) as element(CTS:reply)
{
  element CTS:reply
  {
    element CTS:reff { ctsx:getValidUrns($a_inv, $a_urn, $a_level) }
  }
};

(:
  CTS getValidUrns request
  Parameters:
    $a_inv the inventory name
    $a_urn the passage urn
    $a_level citation level
  Returns
    the list of valid urns

  Note: This code depends on the format of xpath attributes being
    /<element>[@<attribute>='?']
  That is, steps in the path are defined by specified elements containing
  specified attributes.
  Removing "='?'" yields the steps needed for enumerating all elements at a given level.
  Substituting a specific value for '?' yields a step for mapping URN passage components
  to elements.
:)
declare function ctsx:getValidUrns(
  $a_inv as xs:string,
  $a_urn as xs:string,
  $a_level as xs:int
) as element(CTS:urn)*
{
  let $cts := ctsx:parseUrn($a_inv, $a_urn)
  let $startVals := $cts/passageParts/rangePart[1]/part[1 to $a_level]/fn:string()
  let $endVals := $cts/passageParts/rangePart[2]/part[1 to $a_level]/fn:string()

  let $entry := ctsx:getCatalogEntry($cts)
  let $cites := fn:subsequence($entry/ti:online//ti:citation, 1, $a_level)
  let $scope := $cites[1]/@scope
  (: get paths without equality test :)
  let $steps := $cites/@xpath/fn:replace(., "^(.*\[.*@[^=]+)=.\?.+(\].*)$", "$1$2")
  (: get attributes from steps :)
  let $ids := $steps!fn:replace(., "^.*\[.*(@[^=])\].*$", "$1")
  let $doc := fn:doc($cts/fileInfo/fullPath)

  return
    ctsx:_getUrns(
      util:eval("$doc" || $scope),
      $cts/versionUrn || ":",
      "",
      $steps,
      $ids,
      $startVals,
      $endVals
    ) ! element CTS:urn { . }
};

(:
    CTS getUrnMatchString
    Parameters:
        $a_inv the inventory name
        $a_urn the passage urn
    Returns
        a regex to match on
:)
declare function ctsx:getUrnMatchString($a_inv,$a_urn) as xs:string
{
  let $cts := ctsx:parseUrn($a_inv, $a_urn)
  let $entry := ctsx:getCatalogEntry($cts)
  let $parts := fn:count(($cts/passageParts/rangePart[1])/part)
  (: get the level from the range specified :)
  let $level :=
    if ($parts) then $parts else fn:count($entry/ti:online//ti:citation)
  let $urns :=
    for $u in ctsx:getValidUrns($a_inv, $a_urn, $level)
    return
    (
      '(' ||
      fn:replace($u, "\.", "\\.") ||
      '(:|\.|-))'
    )

  return ('^' || fn:string-join($urns, "|"))
};

(:
    CTS getMatchingUrns
    Parameters:
        $a_inv the inventory name
        $a_urn the passage urn
    Returns
        a list of urns for matching
:)
declare function ctsx:getUrnMatches($a_inv,$a_urn)
{
  let $cts := ctsx:parseUrn($a_inv,$a_urn)
  let $entry := ctsx:getCatalogEntry($cts)
  let $parts := fn:count($cts/passageParts/rangePart[1]/part)
  (: get the level from the range specified :)
  let $level :=
    if ($parts)
    then $parts
    else fn:count($entry/ti:online//ti:citation)
  for $u in ctsx:getValidUrns($a_inv, $a_urn, $level)
  return
  (
    '(' ||
    fn:replace($u, "\.", "\\.") ||
    '(:|\.))'
  )
};

(:
        Recursive function to expands the urns returned by getValidUrns into a TEI-compliant list,
        starting at the supplied level, with the node containing the supplied urn expanded to the level
        of the requested urn
        Parameters:
            $a_inv the inventory name
            $a_urn the requested urn
            $a_level the starting level
         Returns the hierarchy of references as a TEI-compliant <list/>
:)
declare function ctsx:expandValidReffs($a_inv as xs:string,$a_urn as xs:string,$a_level as xs:int)
{
    (: TODO address situation where lines are missing ? e.g. line 9.458 Iliad :)
    let $cts := ctsx:parseUrn($a_inv,$a_urn)
    let $entry := ctsx:getCatalogEntry($cts)
    let $versionUrn := if ($a_level = 1) then $cts/versionUrn else $a_urn
    let $urns := ctsx:getValidUrns($a_inv,$versionUrn,$a_level)
    let $numLevels := fn:count($entry/ti:online//ti:citation)
    let $numUrns := fn:count($urns)
    let $tocName := ($entry/ti:online//ti:citation)[$a_level]/@label
    let $chunkSize := ctsx:getTocSize($tocName)
    return
                <list> {
                for $i in (1 to $numUrns)
                    return
                    if (($i + $chunkSize - 1) mod $chunkSize != 0)
                    then ()
                    else
                        let $u := $urns[$i]
                        let $focus := $u eq $a_urn
                        let $last :=
                          if ($chunkSize > 1)
                          then
                            if ($urns[($i + $chunkSize - 1)])
                            then $urns[($i + $chunkSize - 1)]
                            else $urns[fn:last()]
                          else()
                        let $parsed :=  ctsx:parseUrn($a_inv,$u)
                        let $endParsed := if ($last) then ctsx:parseUrn($a_inv,$last) else ()
                        let $startPart := $parsed/passageParts/rangePart[1]/part[last()]
                        let $endPart := if ($endParsed) then concat("-",$endParsed/passageParts/rangePart[1]/part[last()]) else ""
                        let $urn :=
                            if ($last)
                            then
                                concat(
                                    $parsed/versionUrn,":",
                                    string-join($parsed/passageParts/rangePart[1]/part,"."),"-",
                                    string-join($endParsed/passageParts/rangePart[1]/part,"."))
                            else
                                $u
                        let $href :=
                            if ($a_level = $numLevels)
                            then
                                concat("alpheios-get-ref.xq?inv=",$a_inv,"&amp;urn=",$urn)
                            else
                                 concat("alpheios-get-toc.xq?inv=",$a_inv,"&amp;urn=",$urn,"&amp;level=",$a_level+1)
                        let $ptrType := if ($a_level = $numLevels) then 'text' else 'toc'
                        return
                          <item>
                            { $tocName || " " || $startPart || $endPart }
                            <tei:ptr target="{ $href }" xmlns:tei="http://www.tei-c.org/ns/1.0" rend="{$ptrType}"/>
                            {
                              if (fn:not($focus) and 
                                  fn:contains($a_urn, $u) and
                                  fn:exists(($entry/ti:online//ti:citation)[$a_level + 1])
                                 )
                              then ctsx:expandValidReffs($a_inv,$u,$a_level + 1)
                              else ()
                            }
                            </item>
                }</list>
};

(:
    find the next/previous urns
    Parameters:
        $a_dir direction ('p' for previous, 'n' for next)
        $a_node the node from which to start
        $a_path the xpath template for the referenced passage
        $a_count the number of nodes in the referenced passage
        $a_urn the work urn
        $a_passageParts the passageParts elementes from the parsed urn (see ctsx:parseUrn)
    Return Value:
        the urn of the the next or previous reference
        if the referenced passage was a range, the urn will be a range of no more than the number of nodes
        in the referenced range
:)
declare function ctsx:findNextPrev(
  $a_dir as xs:string,
  $a_node as node(),
  $a_path as xs:string ,
  $a_count as xs:int ,
  $a_urn as xs:string,
  $a_passageParts as node()*
) as xs:string
{
  let $kind := xs:string(node-name($a_node))
  let $name := replace($a_path,"^/(.*?)\[.*$","$1")
  let $pred := replace($a_path,"^.*?\[(.*?)\].*$","$1")
  (: remove the identifier bind variable from the path :)
  let $path := replace($pred,"@[^=]+=.\?.(\s+(and)|(or))?","")
  (: get the identifier bind variable :)
  let $id := replace($pred,"^.*?@([^=]+)=.\?.+$","$1")
  let $next :=
    if ($path)
    then
      (: apply additional non-id predicates in xpath :)
      (: TODO check the context of the util:eval($path) here :)
      if ($a_dir = xs:string('p'))
      then
        util:eval(concat("$a_node/preceding-sibling::*[name() = $kind and ",$path,"][1]"))
      else
        util:eval(concat("$a_node/following-sibling::*[name() = $kind and ",$path,"][1]"))
    else if ($a_dir = xs:string('p'))
    then
      $a_node/preceding-sibling::*[name() = $kind]
    else
      $a_node/following-sibling::*[name() = $kind]
  return
    if ($next)
    then
      let $end :=
        if (fn:count($next) > $a_count)
        then $a_count
        else fn:count($next)
      let $passagePrefix :=
        if (fn:count($a_passageParts) > 1)
        then
          fn:concat(
            fn:string-join(
              fn:subsequence(
                $a_passageParts,
                1,
                fn:count($a_passageParts) - 1
              ),
              "."
            ),
            "."
          )
        else ""
      let $rangeStart := concat($passagePrefix,xs:string($next[1]/@*[name() = $id]))
      let $rangeEnd :=
        if ($end > 1)
        then concat("-",$passagePrefix,xs:string($next[$end]/@*[name() = $id]))
        else ""
      return concat($a_urn,":",$rangeStart,$rangeEnd)
    (:TODO recurse up the path to find the next node of this kind in the next parent node :)
    else ""
};

(:
    CTS getPassagePlus request, returns the requested passage plus previous/next references
    Parameters:
        $a_inv the inventory name
        $a_urn the passage urn
    Return Value:
        <reply>
            <TEI>
               [ passage elements ]
            </TEI>
        </reply>
        <prevnext>
            <prev>[previous urn]</prev>
            <next>[next urn]</next>
        </prevnext>
:)
declare function ctsx:getPassagePlus($a_inv as xs:string,$a_urn as xs:string)
{
  ctsx:getPassagePlus($a_inv, $a_urn, fn:false())
};

(:
    CTS getPassagePlus request, returns the requested passage plus previous/next references
    Parameters:
        $a_inv the inventory name
        $a_urn the passage urn
        $a_withSiblings - alpheios extension to get sibling unciteable elements for passages (for display - e.g. speaker)
    Return Value:
        <reply>
            <TEI>
               [ passage elements ]
            </TEI>
        </reply>
        <prevnext>
            <prev>[previous urn]</prev>
            <next>[next urn]</next>
        </prevnext>
:)
declare function ctsx:getPassagePlus(
  $a_inv as xs:string,
  $a_urn as xs:string,
  $a_withSiblings as xs:boolean*
)
{
  let $cts := ctsx:parseUrn($a_inv, $a_urn)
  let $doc := fn:doc($cts/fileInfo/fullPath)
  let $level := fn:count($cts/passageParts/rangePart[1]/part)
  let $entry := ctsx:getCatalogEntry($cts)
  let $tocName := ($entry/ti:online//ti:citation)[$level]/@label
  let $chunkSize := ctsx:getTocSize($tocName)

  let $cites := $entry/ti:online//ti:citation
  let $xpath :=
    ctsx:replaceBindVariables(
      $cts/passageParts/rangePart[1]/part,
      $cts/passageParts/rangePart[2]/part,
      $cites[1]/@scope,
      fn:subsequence($cites, 1, $level)/@xpath
    )
  let $passage_orig :=
    (: return error if we can't determine the chunk size :)
    if (fn:not($chunkSize))
    then <l rend="error">Invalid Request</l>
    else util:eval("$doc" || $xpath)
  let $subref_orig :=
    if ($cts/subRef)
    then ctsx:findSubRef($passage_orig,$cts/subRef)
    else ()
  let $passage :=
    if ($passage_orig and
        (fn:not($cts/subRef) or ($cts/subRef and $subref_orig)))
    then $passage_orig
    else
      let $parent_match :=
        fn:concat("^",$cts/passageParts/rangePart[1]/part[2],"-")
      let $passage_alt :=
        $doc//div1[@n = $cts/passageParts/rangePart[1]/part[1]]
            //wd[matches(@tbrefs,$parent_match) or matches(@tbref,$parent_match)][1]
            /..
      return
        if ($passage_alt) then $passage_alt else $passage_orig
  (: try again to get the subref :)
  let $subref :=
    if ($subref_orig)
    then $subref_orig
    else
      if ($passage and $cts/subRef and fn:not($subref_orig))
      then ctsx:findSubRef($passage,$cts/subRef)
      else ()
  let $countAll := count($passage)
  let $lang := if ($passage) then ctsx:getLang($passage[1]) else ""
  (: enforce limit on # of nodes returned to avoid crashing the server or browser :)
  (:let $count := if ($countAll > $ctsx:maxPassageNodes) then $ctsx:maxPassageNodes else $countAll:)
  let $count := $countAll
  let $name := xs:string(node-name($passage[1]))
  let $thisPath := xs:string($cites[last()]/@xpath)
  let $docid :=
    if ($doc/TEI.2/@id)
    then $doc/TEI.2/@id
    else if ($doc/tei.2/@id)
    then $doc/tei.2/@id
    else if ($doc/TEI/@id)
    then $doc/TEI/@id
    else ""
  let $passageAll :=
    if ($a_withSiblings)
    then
      for $item in fn:subsequence($passage, 1, $count)
      return
      (
        $item/preceding-sibling::*[1][local-name(.) != local-name($item)],
        $item,
        $item/following-sibling::*[1][local-name(.) != local-name($item)]
      )
    else fn:subsequence($passage, 1, $count)
  return
    <reply xpath="{string($xpath)}">
      <TEI id="{$docid}">
      {
        $doc//*:teiHeader,$doc//*:teiheader
      }
        <text xml:lang="{$lang}">
          <body>
          {
            for $p in $passageAll
            return
              ctsx:passageWithParents(
                $p,
                1,
                ('body','TEI.2','TEI','tei.2','tei')
              )
          }
          </body>
        </text>
      </TEI>
      {
        if ($chunkSize and $passage)
        then
          element CTS:prevnext
          {
            element CTS:prev
            {
              ctsx:findNextPrev(
                "p",
                $passage[1],
                $thisPath,
                $count,
                $cts/versionUrn,
                $cts/passageParts/rangePart[1]/part
              )
            },
            element CTS:next
            {
              ctsx:findNextPrev(
                "n",
                $passage[fn:last()],
                $thisPath,
                $count,
                $cts/versionUrn,
                $cts/passageParts/rangePart[fn:last()]/part
              )
            }
          }
        else ()
      },
      <subref>{$subref}</subref>
    </reply>
};

(:
    replace bind variables in the template xpath from the TextInventory with the requested values
    Parameters
        $a_startParts the passage parts identifiers of the start of the range
        $a_endParts the passage part identifiers of the end of the range
        $a_scope the base scope of the range
        $a_paths the template xpaths containing the bind variables
    Return Value
        the full path with the bind variables replaced
:)
declare function ctsx:replaceBindVariables(
  $a_startParts,
  $a_endParts,
  $a_scope,
  $a_paths
) as xs:string
{
  $a_scope ||
  fn:string-join(
    for $path at $i in $a_paths
    return ctsx:_rbv($a_startParts[$i], $a_endParts[$i], $path),
    ""
  )
};

declare %private function ctsx:_rbv(
  $a_start,
  $a_end,
  $a_path
) as xs:string
{
  if (fn:exists($a_start))
  then
    if (fn:exists($a_end))
    then
      let $startRange :=
        if ($a_start/text())
        then
          if (fn:matches($a_start, '^\d+$'))
          then
            ' >= ' || $a_start
          else
            ' >= "' || $a_start || '"'
        else ""
      let $endRange :=
        if ($a_end/text())
        then
          if (fn:matches($a_end, '^\d+$'))
          then
            ' <= ' || $a_end
          else
            ' <= "' || $a_end || '"'
        else ""
      return
        fn:replace(
          $a_path,
          "^(.*?)(@[\w\d\._:\s]+)=[""']\?[""'](.*)$",
          fn:concat("$1", "$2", $startRange, " and ", "$2", $endRange, "$3")
        )
    else
      if ($a_start/text())
      then
        fn:replace(
          $a_path,
          "^(.*?)\?(.*)$",
          fn:concat("$1", $a_start, "$2")
        )
      else
        fn:replace(
          $a_path,
          "^(.*?)(@[\w\d\._:\s]+)=[""']\?[""'](.*)$",
          fn:concat("$1", "$2", "$3")
        )
  else
    $a_path
};

(:
    replace bind variables in the template xpath from the TextInventory with the requested values
    Parameters
        $a_passageParts the passage parts identifiers
        $a_scope the base scope of the range
        $a_paths the template xpaths containing the bind variables
    Return Value
        the full path with the bind variables replaced
:)
declare function ctsx:replaceBindVariables(
  $a_passageParts,
  $a_scope,
  $a_paths
) as xs:string
{
  $a_scope ||
  fn:string-join(
    for $path at $i in $a_paths
    return ctsx:_rbv($a_passageParts[$i], $path),
    ""
  )
};

declare %private function ctsx:_rbv($a_part, $a_path) as xs:string
{
  if (fn:empty($a_part)) then $a_path else

  if ($a_part/text())
  then
    fn:replace(
      $a_path,
      "^(.*?)\?(.*)$",
      fn:concat("$1", $a_part, "$2")
    )
  else
    fn:replace(
      $a_path,
      "^(.*?)(@[\w\d\._:\s]+)=[""']\?[""'](.*)$",
      fn:concat("$1", "$2", "$3")
    )
};

(:
    get a catalog entry for a version
    Parameters:
      $a_cts - parsed URN
    Return Value
      the catalog entry for the requested version
:)
declare function ctsx:getCatalogEntry($a_cts) as node()*
{
    console:log(("cts", $a_cts, "end")),
  let $version :=
    /(ti:edition|ti:translation)
      [@workUrn eq $a_cts/workUrn]
      [@urn eq $a_cts/versionUrn]

  let $_ :=
    if (fn:empty($version))
    then fn:error(xs:QName("BAD-URN"), "Version not found: " || $a_cts/urn)
    else ()

  return $version
};

(:
    Get the document for the supplied urn
    Parameters
        $a_urn the urn
        $a_inv the inventory
    Return Value
        the document
:)
declare function ctsx:getDoc($a_urn as xs:string,$a_inv as xs:string)
{
  fn:doc(ctsx:parseUrn($a_inv, $a_urn)/fileInfo/fullPath)
};

(:
    Get the title of the edition represented by the supplied urn
    Parameters
        $a_inv the text inventory
        $a_urn the urn
    Return Value
        the title
:)
declare function ctsx:getVersionTitle(
  $a_inv as xs:string,
  $a_urn as xs:string
) as xs:string?
{
  ctsx:getCatalogEntry(ctsx:parseUrn($a_inv, $a_urn))
    //(ti:edition|ti:translation)/ti:label
};

(:
    Get the full title of the supplied urn
    Parameters
        $a_inv the text inventory
        $a_urn the urn
    Return Value
        the title
:)
declare function ctsx:getExpandedTitle(
  $a_inv as xs:string,
  $a_urn as xs:string
) as element(CTS:reply)
{
  let $cts := ctsx:parseUrn($a_inv,$a_urn)
  let $entry := ctsx:getCatalogEntry($cts)
  let $labels := $entry/ti:online//ti:citation/@label
  let $parts :=
    for $rangePart in $cts/passageParts/rangePart
    let $base :=
      fn:string-join(
        for $part at $i in $rangePart/part
        return $labels[$i] || " " || $part,
        " "
      )
    return
      if (fn:exists($rangePart/subRef))
      then
        $base ||
        " @" ||
        $rangePart/subRef ||
        "[" ||
        $rangePart/subRef/@position ||
        "]"
      else $base
  let $range :=
    if ($parts[1] ne $parts[2])
    then $parts[1] || " - " || $parts[2]
    else $parts[1]
  return
    element CTS:reply { $entry//ti:label || " " || $range }
};

declare function ctsx:getCitableText(
  $a_inv as xs:string,
  $a_urn as xs:string
) as node()
{
  let $cts := ctsx:parseUrn($a_inv,$a_urn)
  (:
  let $urns := ctsx:getValidUrns($a_inv,$textUrn/versionUrn)
  let $first := $urns[1]
  let $last := $urns[fn:last()]
  let $firstCts := ctsx:parseUrn($first)
  let $lastCts := ctsx:parseUrn($last)
  let $urn :=
    fn:concat(
      $firstCts/versionUrn,
      ':',
      fn:string-join($firstCts/passageParts/rangePart/part, '.'),
      '-',
      fn:string-join($lastCts/passageParts/rangePart/part,'.')
    )
  return ctsx:getPassagePlus($a_inv,$urn)
  :)
  return
  <CTS:reply>
     { fn:doc($cts/fileInfo/fullPath) }
  </CTS:reply>
};

declare function ctsx:passageWithParents($a_passage as node()*, $a_pos as xs:int, $a_stop) as node()*
{
  let $ancestor := $a_passage[1]/ancestor::*[$a_pos]
  return
    if ($ancestor)
    then
      let $in_stop :=
        for $elem in $a_stop
        return if (local-name($ancestor) = $elem) then true() else ()
      return
        if ($in_stop)
        then
          $a_passage
        else
          element {name($ancestor)}
          {
            $ancestor/@*,
            ctsx:passageWithParents($a_passage, $a_pos + 1, $a_stop)
          }
    else
      $a_passage

};

declare function ctsx:getLang($a_node as node()*) as xs:string*
{
    let $lang := $a_node/@*[local-name(.) = 'lang']
    return
        if ($lang)
        then $lang
        else if ($a_node and $a_node/..)
        then ctsx:getLang($a_node/..)
        else ""
};

(:
    Build up a CTS urn for a given node
:)
declare function ctsx:getUrnForNode($a_inv as xs:string, $a_cts as node(), $a_node as node(),$a_topParent as xs:string, $a_build as xs:string*) as xs:string
{
    (: TODO get the correct xpath element and attribute to use from the parsed urn :)
  if (local-name($a_node) = $a_topParent)
  then
     let $path := reverse($a_build)
     let $cleaned := for $p in $path return if ($p) then $p else ()
       return concat($a_cts/versionUrn,':',string-join($cleaned,'.'))
  else if (ctsx:isCitationNode($a_inv,$a_cts/versionUrn,$a_node))
  then
          let $new_build := if ($a_node/@n) then
                if (count($a_build) > 0)
                then ($a_build,xs:string($a_node/@n))
                else xs:string($a_node/@n)
            else $a_build
        return ctsx:getUrnForNode($a_inv, $a_cts,$a_node/parent::*,$a_topParent,$new_build)
  else
    ctsx:getUrnForNode($a_inv,$a_cts,$a_node/parent::*,$a_topParent,$a_build)
};

declare function ctsx:isCitationNode(
  $a_inv as xs:string,
  $a_urn as xs:string,
  $a_node as node()
) as xs:boolean
{
  let $entry := ctsx:getCatalogEntry(ctsx:parseUrn($a_inv, $a_urn))
  let $matched :=
    for $i in $entry/ti:online//ti:citation
    let $path := fn:replace($i/@xpath, "='\?'", "")
    (: todo this doesn't work for namespaces because it doesn't take prefixes in the xpath into account :)
    return
      if (fn:local-name($a_node) eq
          fn:replace(fn:substring-before($path, "["), "^[/]*/+", ""))
      then
        util:eval("$a_node/parent::*" || $path)
      else ()
  return fn:count($matched) > 0
};

declare function ctsx:isUnderCopyright($a_inv,$a_urn) as xs:boolean
{
  let $rights := ctsx:getRights($a_inv, $a_urn)

  (: TODO need a better way of identifying copyright than match on specific string here :)
  return $rights!fn:matches(., "under copyright", "i") = fn:true()
};

declare function ctsx:getRights($a_inv, $a_urn) as xs:string*
{
  let $entry := ctsx:getCatalogEntry(ctsx:parseUrn($a_inv, $a_urn))

  return
    ctsx:getCapabilities($a_inv)
      //ti:collection[@id = $entry/ti:memberof/@collection]/dc:rights
};

(: get the default number of toc segments to return for a given toc type :)
declare function ctsx:getTocSize($a_type) as xs:int
{
  if ($ctsx:tocChunking[@type = $a_type])
  then xs:int($ctsx:tocChunking[@type = $a_type]/@size)
  else 1
};

(:
  ctsx:_extractPassage - recursive function to extract passage
    $a_base - base node
    $a_path1 - starting path of subpassage to extract
    $a_path2 - ending path of subpassage to extract

  If $a_path1 is null then all nodes up to the node
  specified by $a_path2 should be extracted.
  If $a_path2 is null then all nodes after the node
  specified by $a_path1 should be extracted.
:)
declare function ctsx:_extractPassage(
  $a_base as node(),
  $a_path1 as xs:string*,
  $a_path2 as xs:string*
) as node()*
{
  (: if no paths, return all subnodes :)
  if (fn:empty($a_path1) and fn:empty($a_path2)) then $a_base/node() else

  (: evaluate next steps in paths :)
  let $step1 := fn:head($a_path1)
  let $step2 := fn:head($a_path2)
  let $n1 :=
    if (fn:exists($a_path1) and fn:exists($step1))
    then util:eval("$a_base/" || $step1)
    else ()
  let $n2 :=
    if (fn:exists($a_path2) and fn:exists($step2))
    then util:eval("$a_base/" || $step2)
    else ()

  return
    (: if steps are identical :)
    if ($n1 is $n2)
    then
      (: build subnode and recurse :)
      element { fn:node-name($n1) }
      {
        $n1/@*,
        ctsx:_extractPassage($n1, fn:tail($a_path1), fn:tail($a_path2))
      }
    (: if everything from node to end :)
    else if (fn:exists($n1) and fn:empty($step2))
    then
    (
      element { fn:node-name($n1) }
      {
        $n1/@*,
        ctsx:_extractPassage($n1, fn:tail($a_path1), ())
      },
      $a_base/node()[$n1 << .]
    )
    (: if everything from start to node :)
    else if (fn:exists($n2) and fn:empty($step1))
    then
    (
      (: MarkLogic seems to evaluate ">> $n2" much faster than "<< $n2" :)
      $a_base/node()[fn:not(. >> $n2) and fn:not(. is $n2)],
      element { fn:node-name($n2) }
      {
        $n2/@*,
        ctsx:_extractPassage($n2, (), fn:tail($a_path2))
      }
    )
    (: if steps diverge :)
    else if (fn:exists($n1) and fn:exists($n2))
    then
    (
      (: take all children of start from subnode on :) 
      element { fn:node-name($n1) }
      {
        $n1/@*,
        ctsx:_extractPassage($n1, fn:tail($a_path1), ())
      },
      (: take everything in between the nodes :)
      $a_base/node()[($n1 << .) and fn:not(. >> $n2) and fn:not(. is $n2)],
      (: take all children of end up to subnode :)
      element { fn:node-name($n2) }
      {
        $n2/@*,
        ctsx:_extractPassage($n2, (), fn:tail($a_path2))
      }
    )
    (: bad step - return nothing :)
    else ()
};

declare function ctsx:extractPassage($a_inv, $a_urn)
{
  let $cts := ctsx:parseUrn($a_inv,$a_urn)
  let $doc := fn:doc($cts/fileInfo/fullPath)
  let $level1 := fn:count($cts/passageParts/rangePart[1]/part)
  let $level2 := fn:count($cts/passageParts/rangePart[2]/part)

  (: range endpoints must have same depth :)
  let $_ :=
    if ($level1 ne $level2)
    then
      fn:error(xs:QName("BAD-RANGE"), "Endpoints of range have different depths: " || $a_urn)
    else ()

  let $entry := ctsx:getCatalogEntry($cts)
  let $cites := $entry/ti:online//ti:citation

  (: subrefs must be in leaf citation nodes :)
  let $_ :=
    for $part in $cts/passageParts/rangePart
    where fn:exists($part/subRef) and
          (fn:count($part/part) ne fn:count($cites))
    return
      fn:error(xs:QName("BAD-RANGE"), "Subref must be in leaf citation node: " || $a_urn)

  (: find passage paths in doc :)
  let $xpath1 :=
    ctsx:replaceBindVariables(
      $cts/passageParts/rangePart[1]/part,
      $cites[1]/@scope,
      fn:subsequence($cites, 1, $level1)/@xpath
    )
  let $xpath2 :=
    ctsx:replaceBindVariables(
      $cts/passageParts/rangePart[2]/part,
      $cites[1]/@scope,
      fn:subsequence($cites, 1, $level2)/@xpath
    )

  (: find passage start and end nodes in doc :)
  let $n1 := util:eval("$doc" || $xpath1)
  let $n2 := util:eval("$doc" || $xpath2)

  (: end node must not precede start node :)
  let $_ :=
    if ($n2 << $n1)
    then fn:error(xs:QName("BAD-RANGE"), "Endpoints out of order: " || $a_urn)
    else ()

  return
    (: extract full passage :)
    ctsx:_extractPassage(
      $doc,
      fn:tail(fn:tokenize($xpath1, "/")),
      fn:tail(fn:tokenize($xpath2, "/"))
    )
};

(:
  Recursive function to get the list of valid URNs for a getValidReff request
  Parameters:
    $a_node - base node in target document
    $a_urn - the base urn
    $a_sep - separator between base URN and remainder of URN
    $a_steps - XPath steps for each level
    $a_ids - id attributes for each level
    $a_startVals - components of start of URN passage
    $a_endVals - components of end of URN passage

  Return value:
    enumeration of URNs
:)
declare %private function ctsx:_getUrns(
  $a_node as node(),
  $a_urn as xs:string,
  $a_sep as xs:string,
  $a_steps as xs:string*,
  $a_ids as xs:string*,
  $a_startVals as xs:string*,
  $a_endVals as xs:string*
) as xs:string*
{
  if (fn:empty($a_steps)) then $a_urn else

  let $step := fn:head($a_steps)
  let $path := "$a_node" || $step
  let $nodes := util:eval("$a_node" || $step)
  let $idVals := util:eval("$nodes/" || fn:head($a_ids))
  let $start :=
    if (fn:exists($a_startVals))
    then fn:index-of($idVals, fn:head($a_startVals))
    else 1
  let $end :=
    if (fn:exists($a_endVals))
    then fn:index-of($idVals, fn:head($a_endVals))
    else fn:count($idVals)
  let $numNodes := ($end - $start) + 1

  for $node at $i in fn:subsequence($nodes, $start, $numNodes)
  return
    ctsx:_getUrns(
      $node,
      $a_urn || $a_sep || $idVals[$start + $i - 1],
      ".",
      fn:tail($a_steps),
      fn:tail($a_ids),
      if ($i eq 1) then fn:tail($a_startVals) else (),
      if ($i eq $numNodes) then fn:tail($a_endVals) else ()
    )
};