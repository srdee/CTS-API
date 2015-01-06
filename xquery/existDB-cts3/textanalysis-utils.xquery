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

(:
  Utilities supporting the text analysis services
 :)

module namespace tan  = "http://alpheios.net/namespaces/text-analysis";
declare namespace forms = "http://alpheios.net/namespaces/forms";
declare namespace tbd = "http://alpheios.net/namespaces/treebank-desc";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace oac="http://www.openannotation.org/ns/";
declare namespace cnt="http://www.w3.org/2008/content#";
declare namespace treebank="http://nlp.perseus.tufts.edu/syntax/treebank/1.5";
declare namespace align = "http://alpheios.net/namespaces/aligned-text";

import module namespace tbu="http://alpheios.net/namespaces/treebank-util"
              at "treebank-util.xquery";              
import module namespace tbm="http://alpheios.net/namespaces/treebank-morph" 
            at "treebank-morph.xquery";
import module namespace cts="http://alpheios.net/namespaces/cts" 
            at "cts.xquery";

declare variable $tan:MAX_FORMS := 500000;
declare variable $tan:MAX_LEMMAS := 500000;

(:
    Function which identifies the paths of the various Alpheios document types available for a specific
    Alpheios edition
    Parameters:
        $a_cts the ctsURN element for the document, as parsed by cts:parseUrn
    Return Value:
        A) An Element containing one element named by document type (e.g. text, treebank, morph, align, etc.) for
        each available document type for the edition
        or 
        B) if cts:parseUrn returned a dummy element because the urn was actually a text string, then it returns an
             element named toparse which has the language in a lang attribute, and the string as the text of the element
:)
declare function tan:findDocs($a_cts)
{                
        element docinfo {
            if ($a_cts/fileInfo/alpheiosEditionId)
            then
                for $i in ('treebank','morph','text','align','vocab')
                let $docname := concat($a_cts/fileInfo/basePath, "/alpheios-", $i, "-",$a_cts/fileInfo/alpheiosEditionId,".xml")
                    return
                        if (doc-available($docname))
                        then element  {$i} { $docname }                                          
                        else()
            else if ($a_cts/usertext)
                then element toparse {
                    $a_cts/usertext/@lang,
                    $a_cts/usertext/text()
                }
            else ()                
        }            
};

(:
    Recursive function to compare two sets of InflectionType elements per the Alpheios lexicon.xsd
        Parameters:
            $a_infl1 the first InflectionType element
            $a_infl2 the second InflectionType Element
            $a_index the index of the child element from $a_infl1 currently being compared
        Return value:
            true if they match, false if not
:)
declare function tan:matchMorph($a_infl1 as node()*, $a_infl2 as node()*, $a_index as xs:int) as xs:boolean*
{
    let $n := $a_infl1[position() = $a_index]
    let $next := $a_infl1[position() = $a_index+1]
    let $p := $a_infl2/*[local-name(.) = local-name($n)]
    return
        if ($n/*)
        then
          tan:matchMorph($n/*,$a_infl2,xs:int('1'))          
        else
          if ($n/text() eq $p/text())
          then 
            if ($next)
            then
                tan:matchMorph($a_infl1,$a_infl2,$a_index+1)
            else 
                true()
          else 
            false()

};

(:
    Function for identifying the most likely inflection from a given inflection set for a word and document
    TODO - not yet implemented, for now just returns the entire set
    Parameters:
        $a_docinfo an element with the paths of the available Alpheios documents for the edition, as returned by tan:findDocs
        $a_inflSet the set of inflections
    Return Value:
        The inflections filtered down to those which are most likely
:)
declare function tan:filterInflections($a_docinfo,$a_inflSet)
{
    (: TODO identify the correct algorithm, but for now just return the set :)
    $a_inflSet//forms:infl
};

(:
    Function which retrieves the individual words from a document edition
    Parameters:
        $a_docid the cts urn for the document edition
        $a_excludePofs flag to indicate pofs list is an exclude rather than an include list
        $a_pofs the parts of speech to include or exclude         
    Returns:
        A sequence of <lemma> elements for each word in the document. The text of the element is the lemma of the word
        and the element has the following required attributes:
            @lang - the language
            @form - the form used in this instance of the lemma
        and the following optional attributes:
            @count - the number of times the specific form appeared in the document (may not be known at this point)
            @ sense - number identifying the dictionary sense for the lemma (not currently used, needs work to identify the source)
        If the document has treebank data in the repository, the lemmas and forms will be drawn from the treebank, otherwise they
        wil be drawn from the morphology data document, which may have multiple possible lemmas for each form             
:)
declare function tan:getWords($a_docid as xs:string, $a_excludePofs as xs:boolean, $a_pofs as xs:string*)
{
    let $cts := cts:parseUrn($a_docid)
    let $docinfo := tan:findDocs($cts)
    let $collName := '/db/repository/vocabulary'
   
    (: are we pulling words for one or more citations or the entire document :) 
    let $passage := if ($cts/passageParts/rangePart) then true() else false()
    
    (: cached directory name chops urn:cts and replaces : with _ and [] with # :)
    let $cacheDir := 
        replace(
          replace(
                replace($a_docid,'urn:cts:',''),
                ':',
                '_'),
          '[\[\]]','#')
    let $cacheFileName := concat(
        if ($a_excludePofs) then 'not_' else 'all_',
        string-join($a_pofs,'_'),
        '.vb.xml')
    let $cachePath := concat($collName, '/', $cacheDir,'/',$cacheFileName)
    return
        if (xmldb:collection-available(concat($collName,'/',$cacheDir)) and doc-available($cachePath)) 
        then doc($cachePath)
        else 
           let $words :=                   
                (: create a set of lemma elements for each distinct lemma identified by the word elements in the document, 
                sorted by lemma, then within each lemma by form 
                :)          
                if ($docinfo/treebank)
                then         
                    let $doc := doc($docinfo/treebank)            
                    let $tbFormat := tbu:get-format-name($doc,'aldt')
                    let $tbDesc := tbu:get-format-description($tbFormat, "/db/xq/config")
                    let $p_match :=
                      if (count($a_pofs) > 0)  
                        then concat("^(",string-join(
                            (for $p in $a_pofs return 
                              xs:string($tbDesc/tbd:table[@type eq "morphology"]/tbd:category[@id eq 'pos']/tbd:entry[tbd:long/text() = $p]/tbd:short)
                            ),"|"),")")
                        else ""                                                  
                    let $lang := xs:string($doc/treebank/@*[local-name(.) = 'lang'])
                    let $tbRefs := tan:getTreebankRefs($cts,false()) 
                    let $xsl := doc('/db/xslt/treebank-to-lemma.xsl')
                    let $params :=
                                <parameters>
                                    <param name="e_lang" value="{$lang}"/>
                                    <param name="e_refs" value="{$tbRefs}"/>
                                    <param name="e_pmatch" value="{$p_match}"/>
                                    <param name="e_excludePofs" value="{if ($a_excludePofs) then '1' else '0'}"/>
                                </parameters>
                    return 
                       transform:transform($doc, $xsl, $params)//lemma
                else if ($docinfo/morph)
                    (:
                        just take all lemma possibilities found for each form for now, but   
                        TODO eventually need to add some intelligence to figure out which of multiple morphological possibilities is most likely 
                    :)
                    then
                        let $doc := doc($docinfo/morph)
                        let $lang := xs:string($doc/forms:forms/@*[local-name(.) = 'lang'])
                        let $p_match := 
                            if (count($a_pofs) > 0)
                            then concat('^',string-join($a_pofs,'|'),'$')
                            else ""                
                        let $u_match := cts:getUrnMatchString('alpheios-cts-inventory',$a_docid)
                        
                        let $lemmas :=
                            if ($p_match)
                            then 
                                if ($a_excludePofs)
                                then $doc/forms:forms/forms:inflection[forms:urn[matches(.,$u_match)]]/
                                    forms:words/forms:word/forms:entry/forms:dict[not(matches(forms:pofs,$p_match))] 
                                  else $doc/forms:forms/forms:inflection[forms:urn[matches(.,$u_match)]]/
                                      forms:words/forms:word/forms:entry/forms:dict[matches(forms:pofs,$p_match) 
                                      or matches(following-sibling::forms:infl/forms:pofs,$p_match)]
                              else $doc/forms:forms/forms:inflection[forms:urn[matches(.,$u_match)]]/
                                      forms:words/forms:word/forms:entry/forms:dict
                          let $all :=
                                for $i in $lemmas
                                    let $hdwd := $i/forms:hdwd/text()
                                    let $sense := if (matches($i/forms:hdwd,"\d+$")) then replace($hdwd,"^(.*?)(\d+)$","$2") else ""
                                    let $lemma:= if (matches($i/forms:hdwd,"\d+$")) then replace($hdwd,"^(.*?)(\d+)$","$1") else $hdwd                        
                                    let $form := $i/ancestor::forms:inflection/@form
                                    let $urns := $i/parent::forms:entry/parent::forms:word/parent::forms:words/parent::forms:inflection/forms:urn[matches(text(),$u_match)]
                                    let $count := count($urns)
                                    return 
                                        <lemma sense="{$sense}" lang="{$lang}" form="{$form}" count="{$count}" lemma="{$lemma}">{
                                            $urns                                            
                                        }</lemma>                                            
                          (: need to dedupe morphology to add in infl elements for same hdwd entry -- see arabic فی :)
                          (: note transformation uses XSLT 2.0 group-by function :)
                          let $xsl := doc('/db/xslt/alpheios-vocab-group-lemmas.xsl')      
                          return transform:transform(<lemmas>{$all}</lemmas>, $xsl, ())/*
                else if ($docinfo/toparse)
                    (: tokenize the user supplied text and pass it to the morphology service for the language :)
                    then
                      let $parsed := tan:getMorph($docinfo/toparse)
                      let $lang := $docinfo/toparse/@lang
                      let $p_match := 
                            if (count($a_pofs) > 0)
                            then concat('^',string-join($a_pofs,'|'),'$')
                            else ""          
                      let $entries :=                  
                           if ($p_match)
                           then 
                               if ($a_excludePofs)
                               then $parsed/word/entry[dict[not(matches(pofs,$p_match))] or infl[not(matches(pofs,$p_match))]] 
                               else $parsed/word/entry[matches(dict/pofs,$p_match) or matches(infl/pofs,$p_match)]                              
                           else $parsed/word/entry
                      for $i in $entries
                              let $hdwd := $i/dict/hdwd/text()
                              let $sense := if (matches($i/dict/hdwd,"\d+$")) then replace($hdwd,"^(.*?)(\d+)$","$2") else ""
                              let $lemma:= if (matches($i/dict/hdwd,"\d+$")) then replace($hdwd,"^(.*?)(\d+)$","$1") else $hdwd                        
                              let $form := $i/../form
                              let $position:= count($i/ancestor::word/preceding-sibling::word[form=$form]) + 1                      
                              return 
                                  <lemma sense="{$sense}" lang="{$lang}" form="{$form}" count="1" lemma="{$lemma}">
                                      <forms:urn>{concat($form/text(),'[',$position,']')}</forms:urn>
                                  </lemma>
                else()                      
                let $total := count($words)
                let $returned := if ($total > $tan:MAX_LEMMAS) then $tan:MAX_LEMMAS else $total
                let $truncated  := for $i in $words[position() <= $tan:MAX_LEMMAS] return $i               
                let $result: = 
                    <result count="{$returned}" total="{$total}" truncated="{$total - $returned}" 
                        treebank="{exists($docinfo/treebank)}" pmatch="{        if (count($a_pofs) > 0)
                            then concat('^',string-join($a_pofs,'|'),'$')
                            else ""                }" excludepofs="{$a_excludePofs}">
                        <words>{for $i in $truncated order by $i/@lemma, $i/@form return $i}</words>
                    </result>
                let $stored := if (not($docinfo/toparse)) 
                               then
                                    let $do_store := 
                                        if (xmldb:collection-available(concat($collName, '/', $cacheDir))) then true() else
                                            xmldb:create-collection($collName, $cacheDir)
                                    return 
                                        if ($do_store) then xmldb:store(concat($collName,'/',$cacheDir), 
                                                                        $cacheFileName, $result) else ()
                               else ()
                return $result
};

(:
    Function which gets the morphology of each word in a document edition or part
    Parameters:
        $a_docid the cts urn for the document edition or part
        $a_pofs the part of speech to which to limit the retrieval
    Return Value
        A <forms/> element containing the sequence of <inflection> elements for each word in th document
        The <inflection/> element contains the following attribute:
            @treebank=<true|false> indicates whether the morphology came from the treebank
         And a child element <instances/> which contains a child <instance/> element for each instance of the form in the document edition or part.
         The <instance> elements each contains a <urn/> element with a cts urn pointing back to the location of the form within the document, and
         one or more <infl/> elements identifying the morphology of the form
                         
:)
declare function tan:getInflections($a_docid as xs:string, $a_pofs as xs:string*)
{
    let $cts := cts:parseUrn($a_docid)
    let $docinfo := tan:findDocs($cts)
    let $part := $cts/passageParts/rangePart[1]/part[1]
    let $u_match := cts:getUrnMatchString('alpheios-cts-inventory',$a_docid)
    let $forms := 
        if ($docinfo/morph)
        then 
            let $doc := doc($docinfo/morph)        
            let $refdoc := doc($docinfo/text)
            let $tbdoc := doc($docinfo/treebank)
            for $i in ($doc/forms:forms/forms:inflection[forms:words and  
                                                                               (forms:words/forms:word/forms:entry/forms:dict/forms:pofs=$a_pofs or
                                                                                forms:words/forms:word/forms:entry/forms:infl/pofs=$a_pofs) and
                                                                                matches(forms:urn,$u_match)])            
            return element inflection {
                        $doc/forms:forms/@xml:lang,
                        $i/@form,
                        <instances> {
                            for $u in $i/*:urn[matches(text(),$u_match)]                      
                            return
                                (: if we we can disambiguate the morphology using a treebank, do so :) 
                                if (exists($docinfo/treebank) and exists($docinfo/text))
                                then                      
                                    let $reply := cts:getPassagePlus("alpheios-cts-inventory",$u)
                                    let $aref := $reply/subref/wd                                                                         
                                    let $tbref :=                                    
                                        if ($aref[1])
                                        then
                                            if ($aref[1]/@tbrefs) then xs:string($aref[1]/@tbrefs) else xs:string($aref[1]/@tbref)
                                        else ""                                                                           
                                        let $tbmorph := tbm:get-morphology($tbdoc,$tbref)
                                        let $tbinfl :=  for $infl in $i//forms:infl where tan:matchMorph($tbmorph//*:infl,$infl,xs:int('1')) return $infl                                    
                                        (:TODO there shouldn't ever be more than one match, but we should confirm that :)
                                        return
                                            <instance treebank="true"> {
                                                $u,
                                                $tbinfl[1]                                                                     
                                           }</instance>                                                               
                                else
                                    (: otherwise, use alternative approach to filter the possibilities :)
                                    let $filteredInfls := tan:filterInflections($docinfo,$i)
                                    for $infl in $filteredInfls
                                    return
                                        <instance treebank="false"> {
                                            $u,
                                            $infl                                                                     
                                       }</instance>
                         }</instances>
                    }            
            else ()
        let $total := count($forms)
        let $returned := if ($total > $tan:MAX_FORMS) then $tan:MAX_FORMS else $total
        return
                <result count="{$returned}" total="{$total}" truncated="{$total - $returned}" treebank="{exists($docinfo/treebank)}">
                    <forms>
                    {$forms[position() <= $tan:MAX_FORMS ]}
                   </forms>
                </result>                    
};

(: Recursively change the namespace for all the elements in supplied parent node
    Based upon the Functx library method by the same name
    Parameters:
        $a_nodes the nodes to be changed
        $a_newns the new namespace
        $a_prefix the namespace prefix    
:)
declare function tan:change-element-ns-deep ( $a_nodes as node()* , $a_newns as xs:string , $a_prefix as xs:string )  as node()* {
       
  for $node in $a_nodes
  return if ($node instance of element())
         then (element
               {QName ($a_newns,
                          concat($a_prefix,
                                    if ($a_prefix = '')
                                    then ''
                                    else ':',
                                    local-name($node)))}
               {$node/@*,
                tan:change-element-ns-deep($node/node(),
                                           $a_newns, $a_prefix)})
         else if ($node instance of document-node())
         then tan:change-element-ns-deep($node/node(),
                                           $a_newns, $a_prefix)
         else $node
 } ;

(: compare a list of lemmatized words to a tei-compliant vocabulary list  returning the lemmas which matched :)
declare function tan:matchLemmas( $a_words as node()*, $a_vocab as node()*,$a_stripper, $a_toDrop as xs:string*) as node()*
{
        for $i in $a_words
            let $word := 
                if ($a_stripper and $a_toDrop)
                then
                    transform:transform(
                        <dummy/>,
                        $a_stripper,
                        <parameters><param name="e_in" value="{$i/@lemma}"/><param name="e_toDrop" value="{$a_toDrop}"/></parameters>
                   )
               else $i/@lemma
            let $match :=
                if ($a_stripper and $a_toDrop)
                then 
                    $a_vocab/tei:form[@type="lemma" and 
                        transform:transform(
                            <dummy/>,
                            $a_stripper,
                            <parameters><param name="e_in" value="{text()}"/><param name="e_toDrop" value="{$a_toDrop}"/></parameters>
                       ) = $word]
                    else $a_vocab/tei:form[@type="lemma" and text() = $word]
            return 
                if ($match)
                then 
                     let $matchSense := $match/../tei:sense/@n = $i/@sense
                     let $matchForm := $match/../tei:form[@type="inflection"]/text() = $i/@form
                     return                 
                          element lemma {
                              $i/@*,
                              attribute matchWord {$word},
                              attribute matchSense {$matchSense},
                              attribute matchForm {$matchForm},
                              $i/forms:urn
                          }
                  else ()                                                
};

(: Alternate version of matchLemmas which returns the lemmas missed instead of found :)
(: TODO need to add ability for language-specific plugin to process alternatives for each word if no matches found e.g. in arabic stripping vowels :)
declare function tan:matchLemmas( $a_missed as xs:boolean, $a_words as node()*, $a_vocab as node()*,$a_stripper, $a_toDrop as xs:string) as node()*
{ 
            if ($a_missed)
            then
                for $i in $a_words
                    let $word := 
                    if ($a_stripper and $a_toDrop)
                    then
                        transform:transform(
                            <dummy/>,
                            $a_stripper,
                            <parameters><param name="e_in" value="{$i/@lemma}"/><param name="e_toDrop" value="{$a_toDrop}"/></parameters>
                       )
                   else $i/@lemma
                   let $match :=
                        if ($a_stripper and $a_toDrop)
                        then 
                            $a_vocab/tei:form[@type="lemma" and 
                                transform:transform(
                                    <dummy/>,
                                    $a_stripper,
                                    <parameters><param name="e_in" value="{text()}"/><param name="e_toDrop" value="{$a_toDrop}"/></parameters>
                               ) = $word]
                        else $a_vocab/tei:form[@type="lemma" and text() = $word]                        
                    return 
                        if (not($match))
                        then                                          
                                  element lemma {
                                      $i/@*,
                                      attribute matchWord {$word},
                                      $i/forms:urn
                                  }
                          else ()
            else tan:matchLemmas( $a_words, $a_vocab, $a_stripper, $a_toDrop)                                                         
};

(: this function is incomplete :)
declare function tan:matchVocab( $a_vocab as node()*, $a_words as node()*) as node()*
{
        for $i in $a_vocab
            let $match :=
                    $a_words[@lemma = $i/tei:form[@type="lemma"]/text()]
            return
                $match                                        
};

(:
    Function which tokenizes an element containing a text string (whose language should be identified in the @lang attribute of the element)
    and if an alpheios-lexicon-compliant morphology service has been defined for the language, pass the words to the service and return the morphology
    for the words in the string
    TODO the following should be configurable:
        - location of morphology service
        - pre and post transforms on the morphology output
:)
declare function tan:getMorph($a_text)
{
      let $xsl := doc('/db/xslt/alpheios-tokenize.xsl')      
      let $params := <parameters><param name="e_lang" value="{$a_text/@lang}"/></parameters>
      let $wds := transform:transform($a_text, $xsl, $params)
      let $svcurl := tan:getMorphService($a_text/@lang)
      let $morph := 
          if ($svcurl) then
                if ($a_text/@lang = 'ara')
                then              
                    let $decode_xsl := doc('/db/xslt/uni2buck.xsl')              
                    let $encode_xsl := doc('/db/xslt/morph-buck2uni.xsl')
                    for $w in $wds//tei:wd
                        let $buck_w:= transform:transform($w, $decode_xsl, ())
                        let $url := replace($svcurl,'WORD',encode-for-uri($buck_w))
                        let $morph := httpclient:get(xs:anyURI($url),false(),())
                        (: TODO: this is stripping the senses out before transforming to unicode
                                       we need to isolate the sense in an attribute so it can be used for matching :)
                        return transform:transform($morph, $encode_xsl, ())//word
                      
                else if ($a_text/@lang = 'grc')
                then              
                    let $decode_xsl := doc('/db/xslt/alpheios-uni2betacode.xsl')              
                    let $encode_xsl := doc('/db/xslt/morph-beta-uni.xsl')
                    for $w in $wds//tei:wd
                      let $params := <parameters><param name="e_in" value="{$w}"/></parameters>              
                      let $beta_w:= transform:transform($w, $decode_xsl,$params)
                      (:let $beta_w := $w:)
                        let $url := replace($svcurl,'WORD',encode-for-uri($beta_w))
                        let $morph := httpclient:get(xs:anyURI($url),false(),())
                        (: TODO: this is stripping the senses out before transforming to unicode
                                       we need to isolate the sense in an attribute so it can be used for matching :)
                        return transform:transform($morph, $encode_xsl, ())//word
                else if ($a_text/@lang = 'lat')
                then              
                    for $w in $wds//tei:wd
                        let $url := replace($svcurl,'WORD',encode-for-uri($w))
                        let $morph := httpclient:get(xs:anyURI($url),false(),())
                        return $morph//word
                else()
            else()
     return <words>{$morph}</words>
};

declare function tan:get_OACTreebank($a_nodes as node()*) as node()*
{
	let $targets := $a_nodes//oac:Annotation[oac:hasBody]
	for $target in $targets
		return
			(: to do -- support body refs as well as inline :)
			for $body in $target/oac:hasBody
				let $uri := $body/@rdf:resource
				for $s in $target/oac:Body[@rdf:about=$uri]/cnt:rest//treebank:sentence
				(: drop the namespaces :)
				return tan:change-element-ns-deep($s,"","")
};

declare function tan:get_OACAlignment($a_nodes as node()*) as node()*
{
	let $targets := $a_nodes//oac:Annotation[oac:hasBody]
	for $target in $targets
		return
			(: to do -- support body refs as well as inline :)
			for $body in $target/oac:hasBody
				let $uri := $body/@rdf:resource
				return $target/oac:Body[@rdf:about=$uri]/cnt:rest/align:sentence
};

declare function tan:get_OACMorph($a_nodes as node()*) as node()*
{
	let $targets := $a_nodes//oac:Annotation[oac:hasBody]
	let $morph_all := 
		for $target in $targets
		    let $urn := xs:string($target/oac:hasTarget/rdf:Description/@rdf:about)
		    let $cts := cts:parseUrn($urn)
		    let $form := xs:string($cts/subRef)
		    return
				<forms:inflection>
					<forms:urn>{$urn}</forms:urn>
					<forms:word>
					<forms:form>{$form}</forms:form>
					{
				 		for $body in $target/oac:hasBody
						  let $uri := $body/@rdf:resource
						  (: to do -- support body refs as well as inline :)
							for $entry in $target/oac:Body[@rdf:about=$uri]/cnt:rest/entry
								return tan:change-element-ns-deep($entry,"http://alpheios.net/namespaces/forms","forms")
					}
					</forms:word>
				</forms:inflection>
	return <forms:forms>{$morph_all}</forms:forms>
			
};

declare function tan:getTreebankRefs($a_cts as node(), $a_sentencesOnly as xs:boolean) as xs:string* 
{
    let $collName := '/db/repository/refs'
    let $cacheFile :=
          replace(
            replace(
                replace($a_cts/urn,'urn:cts:',''),
                ':',
                '_'),
                 '[\[\]]','#')
    return
        if (doc-available(concat($collName,'/',$cacheFile, '.xml')))
        then 
            concat($collName, '/',$cacheFile, '.xml')
        else
            let $nodes := 
                if ($a_cts/passageParts/rangePart)
                then
                    cts:getPassagePlus("alpheios-cts-inventory",xs:string($a_cts/urn))
                else
                    cts:getCitableText("alpheios-cts-inventory",xs:string($a_cts/urn))
            let $index :=
                for $node in ($nodes//text//wd,$nodes//tei:text//tei:wd)		
                    let $urn := cts:getUrnForNode("alpheios-cts-inventory",$a_cts,$node,'body',()) 
                    let $refs := ($node/@tbref,$node/@tbrefs)
                    let $tokenized := for $r in $refs return tokenize($r, ' ')
                    (: return words or sentences per request :)
                    let $allrefs := 
                        if ($a_sentencesOnly)
                        then
                            distinct-values(for $r in $tokenized order by $r return substring-before($r,"-"))
                        else 
                            distinct-values(for $r in $tokenized order by $r return $r)
                    for $ref in $allrefs return <ref urn="{$urn}">{$ref}</ref>
			let $stored := xmldb:store($collName,concat($cacheFile, '.xml'), <refs>{$index}</refs>)
            return concat($collName, '/',$cacheFile, '.xml')
};

declare function tan:getMorphService($a_lang as xs:string) as xs:string*
{
    let $config := doc('/db/xq/config/services.xml')
    return $config/services/morphology/service[@xml:lang=$a_lang]
};




