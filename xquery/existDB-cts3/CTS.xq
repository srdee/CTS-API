(:
  Copyright 2010 The Alpheios Project, Ltd.
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
import module namespace cts="http://alpheios.net/namespaces/cts" 
            at "cts.xquery";
import module namespace response="http://exist-db.org/xquery/response";

import module namespace tan  = "http://alpheios.net/namespaces/text-analysis"   
            at "textanalysis-utils.xquery";
declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=no";

let $h := response:set-header("Access-Control-Allow-Origin","*")
let $e_query := request:get-parameter("request",())
let $e_urn :=  request:get-parameter("urn",())
let $e_level := xs:int(request:get-parameter("level","1"))
let $e_uuid := request:get-parameter("xuuid",())
let $e_xinv := request:get-data() 
let $inv := request:get-parameter("inv","alpheios-cts-inventory")
let $CTSNS := "http://chs.harvard.edu/xmlns/cts3"
let $under_copyright := $e_urn and cts:isUnderCopyright($inv,$e_urn)

let $reply :=
  if ($e_query = 'GetValidReff')
    then cts:getValidReff($inv,$e_urn,$e_level)
    else if ($e_query = 'ExpandValidReffs')
    then cts:expandValidReffs($inv,$e_urn,$e_level)
    else if ($e_query = 'GetCapabilities')
    then cts:getCapabilities($inv)
    else if ($e_query = 'GetExpandedTitle')
    then cts:getExpandedTitle($inv,$e_urn)
    else if ($e_query = 'GetPassagePlus')
    then cts:getPassagePlus($inv,$e_urn)
    else if ($e_query = 'GetPassage')
    then cts:getPassagePlus($inv,$e_urn)
    else if ($e_query = 'GetCitableText')
      then 
        if ($under_copyright) 
        then
            <reply><error>Copyright Restricted</error></reply>
        else 
            cts:getCitableText($inv,$e_urn)
    else if ($e_query = 'PARSEURN')
    then cts:parseUrn($inv,$e_urn)
    else(<reply><error code="1">INVALID REQUEST. Unsupported request.</error></reply>)

let $parsed := if ($e_urn) then cts:parseUrn($inv,$e_urn) else ()

return
    if ($reply/error)
    then
        element {QName($CTSNS, 'CTSError')} {
            <message>{$reply/error/text()}</message>,
            <code>{$reply/error/@code}</code>
        } 
    else 
    element {QName($CTSNS, $e_query)} {
        element {QName($CTSNS,"request")} {
            element {QName($CTSNS,"requestName")} {
                $e_query
            },
            element {QName($CTSNS,"requestUrn") } {
                $e_urn
            },
            element {QName($CTSNS,"psg") } {
                xs:string($parsed/passage)
            },
            element {QName($CTSNS,"workurn") } {
                xs:string($parsed/workUrn)
            },
            for $gn in $parsed/groupname return
                element {QName($CTSNS,"groupname") } {
                    attribute xml:lang { $gn/@xml:lang },
                    xs:string($gn)
                },
            for $ti in $parsed/title return
                element {QName($CTSNS,"title") } {
                    attribute xml:lang { $ti/@xml:lang },
                    xs:string($ti)
            },
            for $la in $parsed/label return
                element {QName($CTSNS,"label") } {
                    attribute xml:lang { $la/@xml:lang },
                    xs:string($la)
            }
        },
        element {QName($CTSNS,"reply") } {
                (: hack to get validating response for cts:GetPassagePlus without fixing all the code
                    which currently relies on the invalid response  - needs to move in to the cts.xquery
                    library 
                :)
                if ($e_query = 'GetPassagePlus' or $e_query = 'GetPassage')
                then
                    (element {QName($CTSNS,"passage") } {
                        element {QName("http://www.tei-c.org/ns/1.0","TEI")} {
                            tan:change-element-ns-deep ( $reply//TEI/*, "http://www.tei-c.org/ns/1.0" , '')
                        }
                    },
                    tan:change-element-ns-deep ( $reply//prevnext,$CTSNS, ""),
                    $reply//subref)
                else 
                    $reply/node()
                    
            }
    }




