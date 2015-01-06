                                                                                                                                                                                                                                                                                                                                                                     (:
  Copyright 2010 Cantus Foundation
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

module namespace cts = "http://alpheios.net/namespaces/cts";
import module namespace cts-utils="http://alpheios.net/namespaces/cts-utils" 
            at "cts-utils.xquery";
declare namespace ti = "http://chs.harvard.edu/xmlns/cts3/ti";
declare namespace  util="http://exist-db.org/xquery/util";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace dc="http://purl.org/dc/elements/1.1";

 

declare variable $cts:tocChunking :=
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

declare variable $cts:maxPassageNodes := 100;

(: for backwards compatibility default to alpheios inventory :)
declare function cts:parseUrn($a_urn as xs:string) {
    cts:parseUrn('alpheios-cts-inventory',$a_urn)
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
            <edition></edition>
            <passageParts>
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
        B) Or if $a_urn is a text string as identified by the prefix 'alpheiosusertext:<lang>' then returns a <dummy><usertext lang="<lang>">Text String</usertext></dummy>
        TODO this latter option is a bit of hack, should look at a better way to handle this but since most requests go through parseUrn, this was the easiest place for now
:)
declare function cts:parseUrn($a_inv as xs:string, $a_urn as xs:string)
{
    if (matches($a_urn,'^alpheiosusertext:'))
    then 
            let $parts := tokenize($a_urn,':')
            let $lang := $parts[2]
            let $text := if (count($parts) > 3) then string-join($parts[position() > 2], ' ') else $parts[3]
            return
            <dummy>
                <usertext lang="{$lang}">{$text}</usertext>
            </dummy>
    else 
            let $cat := cts:getCapabilities($a_inv)
            let $components := tokenize($a_urn,":")
            let $namespace := $components[3]
            let $workId := $components[4]
            let $workComponents := tokenize($workId,"\.")
            (: TODO do we need to handle the possibility of a work without a text group? :)
            let $textgroup := $workComponents[1]
            let $work := $workComponents[2]
            let $edition := 
                if (count($workComponents) > 2)
                then $workComponents[last()]
                else xs:string("")
            
            let $passage := $components[5]
            let $subref := $components[6]               
            return
                element ctsURN {
                    element urn { $a_urn },
                    (: urn without any passage specifics:)
                    element workUrn { concat("urn:cts:",$namespace,':',$textgroup,".",$work,".",$edition) },
                    element workLang {
                        if ($cat) then $cat//ti:textgroup[@projid=concat($namespace,':',$textgroup)]
                                        /ti:work[@projid=concat($namespace,':',$work)]/@xml:lang
                                   else ()
                    },
                    element workNoEdUrn { concat("urn:cts:",$namespace,':',$textgroup,".",$work) },                                            
                    element namespace{ $namespace },
                    (: TODO is it possible for components of the work id to be in different namespaces?? :)
                    for $gn in $cat//ti:textgroup[@projid=concat($namespace,':',$textgroup)]/ti:groupname return
                        element groupname { 
                            attribute xml:lang { $gn/@xml:lang},
                            xs:string($gn)
                        },
                    for $ti in $cat//ti:textgroup[@projid=concat($namespace,':',$textgroup)]/ti:work[@projid=concat($namespace,':',$work)]/ti:title return
                        element title { 
                            attribute xml:lang { $ti/@xml:lang},
                            xs:string($ti)
                        },
                    for $lab in $cat//ti:textgroup[@projid=concat($namespace,':',$textgroup)]
                        /ti:work[@projid=concat($namespace,':',$work)]/ti:*[@projid=concat($namespace,':',$edition)]/ti:label return
                        element label { 
                            attribute xml:lang { $lab/@xml:lang},
                            xs:string($lab)
                        },
                    element textgroup {concat($namespace,':',$textgroup)},            
                    element work {concat($namespace,':',$work)},
                    element edition {concat($namespace,':',$edition)},
                    element passage {$passage},
                    element passageParts {
                        for $r in tokenize($passage,"-")                
                        return 
                            element rangePart {
                                for $p in tokenize($r,"\.") 
                                    return element part { $p }
                            }
                    },            
                    (if ($subref)
                    then 
                        let $string := substring-before($subref,"[")
                        let $pos := replace($subref,"^.*?\[(\d+)\]$","$1")
                        return element subRef { attribute position { $pos }, $string } 
                    else ()),            
                    element fileInfo {                      
                        if (starts-with($edition,'alpheios-'))
                        then            
                            (: TODO look up the path in the TextInventory :)
                            let $parts := tokenize($edition,'-')                    
                            return
                            (
                                element basePath { 
                                    concat("/db/repository/", $namespace, "/", string-join($workComponents[position() != last()] ,"/"))
                                },
                                element fullPath {
                                    concat("/db/repository/", $namespace, "/", string-join($workComponents,"/"),".xml")
                                },
                                element alpheiosDocType { $parts[2] },
                                for $i in $parts[position() > 2] return element alpheiosEditionId {$i}
                            )   
                        else 
                            if (not($edition))
                            then 
                                element basePath { 
                                    concat("/db/repository/", $namespace, "/", string-join($workComponents,"/"))
                                }                      
                            else if ($cat) then
                                let $fullPath :=
                                    $cat//ti:textgroup[@projid=concat($namespace,':',$textgroup)]
                                        /ti:work[@projid=concat($namespace,':',$work)]
                                        /ti:*[@projid=concat($namespace,':',$edition)]
                                        /ti:online/@docname
                                    return element fullPath {
                                       xs:string($fullPath)
                                    }
                            else()
                    }
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
declare function cts:findSubRef($a_passage,$a_subref)
{         
    if ($a_passage//wd) then
        $a_passage//wd[text() = string($a_subref)][$a_subref/@position][1] 
    else $a_passage//tei:wd[text() = string($a_subref)][$a_subref/@position][1]
};

(:
    get a passage from a text
    Parameters:
        $a_inv the inventory name
        $a_urn the passage urn
    Return Value:
        getPassage reply
:)
declare function cts:getPassage($a_inv as xs:string,$a_urn as xs:string)
{    
    let $cts := cts:parseUrn($a_inv,$a_urn)    
    return                   
        let $doc := doc($cts/fileInfo/fullPath)
        let $level := count($cts/passageParts/rangePart[1]/part)
        let $entry := cts:getCatalog($a_inv,$a_urn)
        let $tocName := ($entry//ti:online//ti:citation)[position() = $level]/@label
        let $chunkSize := cts:getTocSize($tocName)
        
        let $cites := for $i in $entry//ti:online//ti:citation return $i        
        let $xpath := cts:replaceBindVariables(
            $cts/passageParts/rangePart[1]/part,
            $cts/passageParts/rangePart[2]/part,
            concat($cites[$level]/@scope, $cites[$level]/@xpath))
        let $passage_orig := 
            (: return error if we can't determine the chunk size :)
           if (not($chunkSize)) then (<l rend="error">Invalid Request</l>)
           else util:eval(concat("$doc",$xpath))
        let $subref_orig := 
            if ($cts/subRef)
            then
                cts:findSubRef($passage_orig,$cts/subRef)
            else ()                
        let $passage := if ($passage_orig and (not($cts/subRef) or ($cts/subRef and $subref_orig) )) 
            then $passage_orig
        else            
            let $parent_match := concat("^",$cts/passageParts/rangePart[1]/part[2],"-")
            let $passage_alt  := $doc//div1[@n = $cts/passageParts/rangePart[1]/part[1]]//wd[matches(@tbrefs,$parent_match) or matches(@tbref,$parent_match)][1]/..
            return if ($passage_alt) then $passage_alt else $passage_orig
        (: try again to get the subref :)
        let $subref :=
            if ($subref_orig) then $subref_orig
            else if ($passage and $cts/subRef and not ($subref_orig))
            then cts:findSubRef($passage,$cts/subRef)
            else ()                             
        let $countAll := count($passage)
        let $lang := if ($passage) then cts:getLang($passage[1]) else ""
        (: enforce limit on # of nodes returned to avoid crashing the server or browser :)
        (:let $count := if ($countAll > $cts:maxPassageNodes) then $cts:maxPassageNodes else $countAll:)
        let $count := $countAll
        let $docid := if ($doc/TEI.2/@id) then $doc/TEI.2/@id 
                      else if ($doc/tei.2/@id) then $doc/tei.2/@id
                      else if ($doc/TEI/@id) then $doc/TEI/@id
                      else ""
        let $passageAll := $passage[position() < $count+ 1]
        return   
            <reply xpath="{string($xpath)}">
                <TEI id="{$docid}">
                    {$doc//*:teiHeader,$doc//*:teiheader},
                    <text xml:lang="{$lang}">
                    <body>                      
                        {   
                            for $p in $passageAll return cts:passageWithParents($p,1,('body','TEI.2','TEI','tei.2','tei'),())
                        }
                     </body>
                  </text>
                </TEI>
                <subref>{$subref}</subref>
            </reply>
};

(:
    CTS getCapabilities request
    Parameters:
        $a_inv the inventory         
    Return Value
        the catalog entry for the requested edition
:)
declare function cts:getCapabilities($a_inv)
{    
    let $defaultPath := concat("/db/repository/inventory/",$a_inv,".xml")
    let $altPath := cts-utils:getWriteableInventoryPath($a_inv)
    let $inv := 
        if (doc-available($defaultPath)) then doc($defaultPath)
        else if (doc-available($altPath)) then doc($altPath)
        else ()
    return 
        $inv
};

(:
    CTS getValidReff request (unspecified level)
    Parameters:
        $a_inv the inventory name
        $a_urn the passage urn        
    Returns 
        the list of valid urns
:)
declare function cts:getValidReff($a_inv,$a_urn)
{    
    let $cts := cts:parseUrn($a_inv,$a_urn)
    let $doc := doc($cts/fileInfo/fullPath)
    let $entry := cts:getCatalog($a_inv,$a_urn)
    let $parts := count($cts/passageParts/rangePart[1]/part)
    (: if one or more parts of the passage component are specified, the level is implicitly
       the next level after the one supplied, otherwise retrieve all levels 
    :)   
    let $level := 
        if ($parts) then $parts+1 else count($entry//ti:online//ti:citation)
    return cts:getValidReff($a_inv,$a_urn,$level)                
};

(:
    CTS getValidReff request (with level)
    Parameters:
        $a_inv the inventory name
        $a_urn the passage urn
        $a_level citation level
    Returns 
        the list of valid urns
:)
declare function cts:getValidReff($a_inv as xs:string,$a_urn as xs:string,$a_level as xs:int)
{    
        (: this is way too slow when request is all urns in a document at all levels  - e.g urn:cts:greekLit:tlg0012.tlg001 :)
        let $cts := cts:parseUrn($a_inv,$a_urn)
        let $doc := doc($cts/fileInfo/fullPath)
        let $entry := cts:getCatalog($a_inv,$a_urn)                
        let $cites := for $i in ($entry//ti:online//ti:citation)[position() <= $a_level] return $i
        let $startParts :=
            for $l in (xs:int("1") to $a_level)
            return 
                if ($cts/passageParts/rangePart[1]/part[$l]) 
                then $cts/passageParts/rangePart[1]/part[$l] else <part></part>
        let $endParts :=
            if ($cts/passageParts/rangePart[2]) then
                for $l in (xs:int("1") to $a_level)
                return 
                    if ($cts/passageParts/rangePart[2]/part[$l]) 
                    then $cts/passageParts/rangePart[2]/part[$l] else <part></part>
            else ()
        
        let $urns := cts:getUrns($startParts,$endParts,$cites,$doc,concat($cts/workUrn,":"))
        return 
        <reply>
            <reff xmlns="http://chs.harvard.edu/xmlns/cts3">            
                    { for $u in $urns return <urn xmlns="http://chs.harvard.edu/xmlns/cts3">{$u}</urn> }
            </reff>
        </reply>
};

(:
    CTS getUrnMatchString
    Parameters:
        $a_inv the inventory name
        $a_urn the passage urn        
    Returns     
        a regex to match on
:)
declare function cts:getUrnMatchString($a_inv,$a_urn) as xs:string
{    
    let $cts := cts:parseUrn($a_inv,$a_urn)
    let $doc := doc($cts/fileInfo/fullPath)
    let $entry := cts:getCatalog($a_inv,$a_urn)
    let $parts := count(($cts/passageParts/rangePart[1])/part)
    (: get the level from the range specified :)   
    let $level := 
        if ($parts) then $parts else count($entry//ti:online//ti:citation)
    let $refs := cts:getValidReff($a_inv,$a_urn,$level)
    let $urns := for $u in $refs//urn return concat('(',replace($u,"\.","\\."),'(:|\.|-))')    
    return concat('^',string-join($urns,"|"))    
};

(:
    CTS getMatchingUrns
    Parameters:
        $a_inv the inventory name
        $a_urn the passage urn        
    Returns 
        a list of urns for matching
:)
declare function cts:getUrnMatches($a_inv,$a_urn)
{    
    let $cts := cts:parseUrn($a_inv,$a_urn)
    let $doc := doc($cts/fileInfo/fullPath)
    let $entry := cts:getCatalog($a_inv,$a_urn)
    let $parts := count($cts/passageParts/rangePart[1]/part)
    (: get the level from the range specified :)   
    let $level := 
        if ($parts) then $parts else count($entry//ti:online//ti:citation)
    let $refs := cts:getValidReff($a_inv,$a_urn,$level)
    for $u in $refs//urn return concat('(',replace($u,"\.","\\."),'(:|\.))')           
};

(:
        Recursive function to expands the urns returned by getValidReff into a TEI-compliant list, 
        starting at the supplied level, with the node containing the supplied urn expanded to the level
        of the requested urn
        Parameters:
            $a_inv the inventory name
            $a_urn the requested urn
            $a_level the starting level
         Returns the hierarchy of references as a TEI-compliant <list/>
:)
declare function cts:expandValidReffs($a_inv as xs:string,$a_urn as xs:string,$a_level as xs:int)
{
    (: TODO address situation where lines are missing ? e.g. line 9.458 Iliad :)
    let $entry := cts:getCatalog($a_inv,$a_urn)    
    let $workUrn := if ($a_level = xs:int("1")) then cts:parseUrn($a_inv,$a_urn)/workUrn else $a_urn
    let $urns := cts:getValidReff($a_inv,$workUrn,$a_level)
    let $numLevels := count($entry//ti:online//ti:citation)
    let $numUrns := count($urns//*:urn) 
    let $tocName := ($entry//ti:online//ti:citation)[position() = $a_level]/@label
    let $chunkSize := cts:getTocSize($tocName) 
    return
                <list> {
                for $i in (xs:int("1") to $numUrns)
                    return
                    if (($i + $chunkSize - 1) mod $chunkSize != xs:int("0")) 
                    then ()
                    else 
                        let $u := $urns//*:urn[$i] 
                        let $focus := $u eq $a_urn
                        let $last := 
                            if ($chunkSize > xs:int("1") )
                            then 
                                if ($urns//*:urn[($i + $chunkSize - 1)]) then $urns//*:urn[($i + $chunkSize - 1)] else $urns//*:urn[last()]
                            else()
                        let $parsed :=  cts:parseUrn($a_inv,$u)
                        let $endParsed := if ($last) then cts:parseUrn($a_inv,$last) else ()
                        let $startPart := $parsed/passageParts/rangePart[1]/part[last()]
                        let $endPart := if ($endParsed) then concat("-",$endParsed/passageParts/rangePart[1]/part[last()]) else ""
                        let $urn := 
                            if ($last) 
                            then 
                                concat(
                                    $parsed/workUrn,":",
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
                                {concat($tocName," ",$startPart,$endPart)}                                                         
                                <tei:ptr target="{$href}" xmlns:tei="http://www.tei-c.org/ns/1.0" rend="{$ptrType}"/>                          
                              {if (not($focus) and contains($a_urn,$u) and ($entry//ti:online//ti:citation)[position() = $a_level+1]) 
                               then cts:expandValidReffs($a_inv,$u,$a_level + 1)  else ()}
                            </item>
                }</list>                        
                                       
};

(:
    Recursive function to get the list of valid urns for a getValidReff request
    Parameters:   
        $a_startParts the parts of the starting passage range
        $a_endParts the parents of the ending passage range
        $a_cites the citation elements to retrieve
        $a_doc the target document
        $a_urn the base urn
    (: TODO does not support range requests properly :)        
:)
declare function cts:getUrns($a_startParts,$a_endParts,$a_cites,$a_doc,$a_urn)
{    
    let $cite := $a_cites[1]
    let $xpath := cts:replaceBindVariables(
        $a_startParts,
        $a_endParts,
        concat($cite/@scope, $cite/@xpath))                
    
    let $passage := util:eval(concat("$a_doc",$xpath))
    let $pred := replace($cite/@xpath,"^.*?\[(.*?)\].*$","$1")
    (: get the identifier bind variable :)    
    let $id := replace($pred,"^.*?@([^=]+)=.\?.+$","$1")              
    for $p in $passage
        let $id_value := xs:string($p/@*[name() = $id])
        let $urn := concat($a_urn,$id_value)        
        return        
            if(count($a_cites) > xs:int(1))
            then
                let $next_cites := $a_cites[position() > xs:int(1)]
                return cts:getUrns(
                    $a_startParts,$a_endParts,$next_cites,$a_doc,concat($urn,"."))
            else        
                $urn   
};

(:
    find the next/previous urns
    Parameters:
        $a_dir direction ('p' for previous, 'n' for next)
        $a_node the node from which to start
        $a_path the xpath template for the referenced passage
        $a_count the number of nodes in the referenced passage
        $a_urn the work urn
        $a_passageParts the passageParts elementes from the parsed urn (see cts:parseUrn)
    Return Value:
        the urn of the the next or previous reference
        if the referenced passage was a range, the urn will be a range of no more than the number of nodes
        in the referenced range
:)
declare function cts:findNextPrev($a_dir as xs:string,
                                                    $a_node as node(),
                                                    $a_path as xs:string ,
                                                    $a_count as xs:int ,
                                                    $a_urn as xs:string,
                                                    $a_passageParts as node()*) as xs:string
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
        else
            if ($a_dir = xs:string('p'))
            then
                $a_node/preceding-sibling::*[name() = $kind]
            else                 
                $a_node/following-sibling::*[name() = $kind]
    return 
        if ($next) 
        then
            let $end := if (count($next) > $a_count) then $a_count else count($next)
            let $passagePrefix := if (count($a_passageParts) > 1) then concat(string-join($a_passageParts[position() != last()],"."),'.') else "" 
            let $rangeStart := concat($passagePrefix,xs:string($next[1]/@*[name() = $id]))
            let $rangeEnd := 
                if ($end > xs:int("1")) 
                then concat("-",$passagePrefix,xs:string($next[position() = $end]/@*[name() = $id]))
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
declare function cts:getPassagePlus($a_inv as xs:string,$a_urn as xs:string)
{    
    cts:getPassagePlus($a_inv,$a_urn,false())
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
declare function cts:getPassagePlus($a_inv as xs:string,$a_urn as xs:string,$a_withSiblings as xs:boolean*)
{    
    let $cts := cts:parseUrn($a_inv,$a_urn)    
    return                   
        let $doc := doc($cts/fileInfo/fullPath)
        let $level := count($cts/passageParts/rangePart[1]/part)
        let $entry := cts:getCatalog($a_inv,$a_urn)
        let $tocName := ($entry//ti:online//ti:citation)[position() = $level]/@label
        let $chunkSize := cts:getTocSize($tocName)
        
        
        let $cites := for $i in $entry//ti:online//ti:citation return $i        
        let $xpath := cts:replaceBindVariables(
            $cts/passageParts/rangePart[1]/part,
            $cts/passageParts/rangePart[2]/part,
            concat($cites[$level]/@scope, $cites[$level]/@xpath))
        let $passage_orig := 
            (: return error if we can't determine the chunk size :)
           if (not($chunkSize)) then (<l rend="error">Invalid Request</l>)
           else util:eval(concat("$doc",$xpath))
        let $subref_orig := 
            if ($cts/subRef)
            then
                cts:findSubRef($passage_orig,$cts/subRef)
            else ()                
        let $passage := if ($passage_orig and (not($cts/subRef) or ($cts/subRef and $subref_orig) )) 
            then $passage_orig
        else            
            let $parent_match := concat("^",$cts/passageParts/rangePart[1]/part[2],"-")
            let $passage_alt  := $doc//div1[@n = $cts/passageParts/rangePart[1]/part[1]]//wd[matches(@tbrefs,$parent_match) or matches(@tbref,$parent_match)][1]/..
            return if ($passage_alt) then $passage_alt else $passage_orig
        (: try again to get the subref :)
        let $subref :=
            if ($subref_orig) then $subref_orig
            else if ($passage and $cts/subRef and not ($subref_orig))
            then cts:findSubRef($passage,$cts/subRef)
            else ()                             
        let $countAll := count($passage)
        let $lang := if ($passage) then cts:getLang($passage[1]) else ""
        (: enforce limit on # of nodes returned to avoid crashing the server or browser :)
        (:let $count := if ($countAll > $cts:maxPassageNodes) then $cts:maxPassageNodes else $countAll:)
        let $count := $countAll        
        let $name := xs:string(node-name($passage[1]))
        let $thisPath := xs:string($cites[position() = last()]/@xpath)
        let $docid := if ($doc/TEI.2/@id) then $doc/TEI.2/@id 
        			  else if ($doc/tei.2/@id) then $doc/tei.2/@id
        			  else if ($doc/TEI/@id) then $doc/TEI/@id
        			  else ""
        let $passageAll := 
            if ($a_withSiblings) then  
                for $item in $passage[position() < $count+ 1]
                return
               ($item/preceding-sibling::*[1][local-name(.) != local-name($item)],
                        $item,
                        $item/following-sibling::*[1][local-name(.) != local-name($item)])
            else $passage[position() < $count+ 1]
        return   
            <reply xpath="{string($xpath)}">
                <TEI id="{$docid}">
                    {$doc//*:teiHeader,$doc//*:teiheader}
                    <text xml:lang="{$lang}">
                    <body>                    	
                        {   
							for $p in $passageAll return cts:passageWithParents($p,1,('body','TEI.2','TEI','tei.2','tei'),())
                        }
                     </body>
                  </text>
                </TEI>
                { if ($chunkSize and $passage) then
                    <prevnext>                     
                        <prev>{ cts:findNextPrev("p",$passage[1],$thisPath,$count,$cts/workUrn,$cts/passageParts/rangePart[1]/part) }</prev>                    
                        <next>{ cts:findNextPrev("n",$passage[position() = last()],$thisPath,$count,$cts/workUrn,$cts/passageParts/rangePart[position()=last()]/part) }</next>                                            
                    </prevnext>
                    else ()
                },
                <subref>{$subref}</subref>
            </reply>                    
};

(:
    replace bind variables in the template xpath from the TextInvetory with the requested values
    Parameters
        $a_startParts the passage parts identifiers of the start of the range
        $a_endParts the passage part identifiers of the end of the range
        $a_path the template xpath containing the bind variables 
    Return Value
        the path with the bind variables replaced
:)
declare function cts:replaceBindVariables($a_startParts,$a_endParts,$a_path) as xs:string
{    
        
        if (count($a_startParts) > xs:int(0))
        then
            if (count($a_endParts) > xs:int(0)) then
                let $startRange := 
                    if ($a_startParts[1]/text()) then
                        if (matches($a_startParts[1], '^\d+$')) then
                            concat(' >= ', $a_startParts[1])
                        else 
                            concat(' >= "',xs:string($a_startParts[1]), '"') 
                    else ""
                let $endRange :=
                    if ($a_endParts[1]/text()) then
                        if (matches($a_endParts[1], '^\d+$')) then
                            concat(' <= ', $a_endParts[1])
                        else
                            concat(' <= "', xs:string($a_endParts[1]), '"' ) 
                    else ""
                let $path := replace($a_path,"^(.*?)(@[\w\d\._:\s]+)=[""']\?[""'](.*)$",concat("$1","$2",$startRange," and ", "$2", $endRange, "$3"))                
                return cts:replaceBindVariables($a_startParts[position() > 1],$a_endParts[position() >1],$path)
            else          
                let $path := 
                    if ($a_startParts[1]/text()) 
                    then 
                        replace($a_path,"^(.*?)\?(.*)$",concat("$1",xs:string($a_startParts[1]),"$2"))
                    else 
                        replace($a_path,"^(.*?)(@[\w\d\._:\s]+)=[""']\?[""'](.*)$",concat("$1","$2","$3"))
                return cts:replaceBindVariables($a_startParts[position() > 1],(),$path)
        else $a_path            
};

(:
    get a catalog entry for an edition 
    Parameters:
        $a_inv the inventory 
        $a_urn the document/passage urn
    Return Value
        the catalog entry for the requested edition
:)
declare function cts:getCatalog($a_inv as xs:string,$a_urn as xs:string) as node()*
{
    let $inv := cts:getCapabilities($a_inv)
    let $cts := cts:parseUrn($a_inv,$a_urn)
    return $inv//ti:textgroup[@projid=$cts/textgroup]/ti:work[@projid=$cts/work]/ti:*[@projid=$cts/edition]        
};

(:
    get the citation xpaths for a urn
    Parameters:
        $a_inv the inventory 
        $a_urn the document/passage urn
     Return Value
         a sequence of strings containing the citation xpaths
:)
declare function cts:getCitationXpaths($a_inv as xs:string,$a_urn as xs:string)
{
   let $entry := cts:getCatalog($a_inv,$a_urn)
   let $levels :=
       for $i in $entry//ti:online//ti:citation
       return xs:string($i/@xpath)
    return $levels       
};       

(:
    Get the document for the supplied urn
    Parameters
        $a_urn the urn
        $a_inv the inventory
    Return Value
        the document
:)
declare function cts:getDoc($a_urn as xs:string,$a_inv as xs:string)
{
    let $cts := cts:parseUrn($a_inv,$a_urn)
    return doc($cts/fileInfo/fullPath)
};

(:
    Get the title of the edition represented by the supplied urn
    Parameters
        $a_inv the text inventory
        $a_urn the urn
    Return Value
        the title
:)
declare function cts:getEditionTitle($a_inv as xs:string,$a_urn as xs:string)
{
    let $entry := cts:getCatalog($a_inv,$a_urn)
    return xs:string($entry//ti:edition/ti:label)
};

(:
    Get the full title of the supplied urn
    Parameters
        $a_inv the text inventory
        $a_urn the urn
    Return Value
        the title
:)
declare function cts:getExpandedTitle($a_inv as xs:string,$a_urn as xs:string) as xs:string
{
    let $entry := cts:getCatalog($a_inv,$a_urn)
    let $cts := cts:parseUrn($a_inv,$a_urn)
    let $start := 
        for $seq in (1 to count($cts/passageParts/rangePart[1]/part))
         return concat(($entry//ti:online//ti:citation)[position() = $seq]/@label, " ", $cts/passageParts/rangePart[1]/part[$seq])   
    let $end :=  for $seq in (1 to count($cts/passageParts/rangePart[last()]/part))
         return concat(($entry//ti:online//ti:citation)[position() = $seq]/@label, " ", $cts/passageParts/rangePart[last()]/part[$seq]) 
    let $parts := if ($end != '') then concat(string-join($start,' '), ' - ',string-join($end,' ')) else $start
    return string-join(($entry//ti:edition/ti:label,$parts), " ")
};

declare function cts:getCitableText($a_inv as xs:string, $a_urn as xs:string) as node()
{

	let $cts := cts:parseUrn($a_inv,$a_urn)
	(:
	let $refs := cts:getValidReff($a_inv,$textUrn/workUrn)
	let $first := $refs//urn[1]
	let $last := $refs//urn[last()]    
    let $firstCts := cts:parseUrn($first)
    let $lastCts := cts:parseUrn($last)
    let $urn := 
    	concat($firstCts/workUrn,':',
    	string-join($firstCts/passageParts/rangePart/part, '.'),'-',
    	string-join($lastCts/passageParts/rangePart/part,'.'))
	return cts:getPassagePlus($a_inv,$urn)	 
	:)
	return 
	<reply>
	   {doc($cts/fileInfo/fullPath)}
	</reply>
};

declare function cts:passageWithParents($a_passage as node()*, $a_pos as xs:int, $a_stop,$a_rebuild) as node()*
{	    
	let $ancestor := $a_passage[1]/ancestor::*[$a_pos]
	return
	if ($ancestor)	
	then
	   let $in_stop := 
	       for $elem in tokenize($a_stop,',')
	       return
    	       if (local-name($ancestor) = $elem)
    	       then true() else ()
       return 
        if ($in_stop) 
        then
            cts:rebuildPassage(($a_passage,$a_rebuild))
        else 
            let $a_rebuild := ($a_rebuild,
      		    element {name($ancestor)} {
      			   $ancestor/@*
      			})
      	    return cts:passageWithParents($a_passage,$a_pos+1,$a_stop,$a_rebuild)
	else
		$a_passage
		  			        
};

declare function cts:rebuildPassage($a_list as node()*) as node() 
{
    element { name($a_list[last()])} {
        $a_list[last()]/@*,
        $a_list[last()]/node(),
        if (count($a_list) > 1)
        then cts:rebuildPassage($a_list[position() < last()])
        else ()
    }
        
};

declare function cts:getLang($a_node as node()*) as xs:string*
{
    let $lang := $a_node/@*[local-name(.) = 'lang']
    return 
        if ($lang) 
        then $lang 
        else if ($a_node and $a_node/..) 
        then cts:getLang($a_node/..)
        else ""
};

(:
    Build up a CTS urn for a given node
:)
declare function cts:getUrnForNode($a_inv as xs:string, $a_cts as node(), $a_node as node(),$a_topParent as xs:string, $a_build as xs:string*) as xs:string
{
    (: TODO get the correct xpath element and attribute to use from the parsed urn :)
	if (local-name($a_node) = $a_topParent)
	then 
	   let $path := reverse($a_build)	
	   let $cleaned := for $p in $path return if ($p) then $p else ()
       return concat($a_cts/workUrn,':',string-join($cleaned,'.'))
	else if (cts:isCitationNode($a_inv,$a_cts/workUrn,$a_node))
	then 
          let $new_build := if ($a_node/@n) then
                if (count($a_build) > 0) 
                then ($a_build,xs:string($a_node/@n)) 
                else xs:string($a_node/@n)
            else $a_build
	      return cts:getUrnForNode($a_inv, $a_cts,$a_node/parent::*,$a_topParent,$new_build)
	else			
		cts:getUrnForNode($a_inv,$a_cts,$a_node/parent::*,$a_topParent,$a_build)
};

declare function cts:isCitationNode($a_inv as xs:string, $a_urn as xs:string, $a_node as node()) as xs:boolean {

    let $entry := cts:getCatalog($a_inv,$a_urn)
    let $matched :=
        for $i in $entry//ti:online//ti:citation
            let $path := replace($i/@xpath,"='\?'",'')
            (: todo this doesn't work for namespaces because it doesn't take prefixes in the xpath into account :)
            return if (local-name($a_node) = replace(substring-before($path,'['),'^[/]*/+','')) 
                then util:eval(concat("$a_node/parent::*",$path)) 
                else ()
    return count($matched) > 0
};

declare function cts:isUnderCopyright($a_inv,$a_urn) as xs:boolean {
    let $entry := cts:getCatalog($a_inv,$a_urn)
    let $memberof := $entry/ti:memberof/@collection
    let $inventory := cts:getCapabilities($a_inv)
    (: TODO need a better way of identifying copyright than match on specific string here :)
    let $collection := $inventory//ti:collection[@id = $memberof and matches(*:rights,'under copyright','i')]
    return if ($collection) then true() else false()
};

declare function cts:getRights($a_inv,$a_urn) as xs:string {
    let $entry := cts:getCatalog($a_inv,$a_urn)
    let $memberof := $entry/ti:memberof/@collection
    let $inventory := cts:getCapabilities($a_inv)
    (: TODO need a better way of identifying copyright than match on specific string here :)
    return $inventory//ti:collection[@id = $memberof]/dc:rights
};

(: get the default number of toc segments to return for a given toc type :)
declare function cts:getTocSize($a_type) as xs:int {
    if ($cts:tocChunking[@type=$a_type]) then xs:int($cts:tocChunking[@type=$a_type]/@size) else 1 
};