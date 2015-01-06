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

import module namespace mapsutils = "http://github.com/ponteineptique/CTS-API"
       at "maps-utils.xquery";
import module namespace ctsx = "http://alpheios.net/namespaces/cts"
       at "cts.xquery";
import module namespace ctsi = "http://alpheios.net/namespaces/cts-implementation"
       at "cts-impl.xquery";
import module namespace tan  = "http://alpheios.net/namespaces/text-analysis"
       at "textanalysis-utils.xquery";
import module namespace console = "http://exist-db.org/xquery/console";
(:  :import module namespace map = "http://www.w3.org/2005/xpath-functions/map"; :)

declare namespace CTS = "http://chs.harvard.edu/xmlns/cts";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace error = "http://marklogic.com/xdmp/error";

let $startTime := util:system-time()
let $map := map:new()
let $_ := ctsi:add-response-header("Access-Control-Allow-Origin", "*")
let $e_query := ctsi:get-request-parameter("request", ())
let $e_urn :=  ctsi:get-request-parameter("urn", ())
let $e_level := xs:int(ctsi:get-request-parameter("level", "1"))
let $e_uuid := ctsi:get-request-parameter("xuuid", ())
let $e_xinv := ctsi:get-request-body()
let $e_inv := ctsi:get-request-parameter("inv", $ctsx:defaultInventory)
let $query := fn:lower-case($e_query)
let $e_query :=
  if ($query = 'getcapabilities') then "GetCapabilities"
  else if ($query = 'getvalidreff') then "GetValidReff"

(: GetFirstUrn, GetPrevNextUrn, GetLabel, GetPassage or GetPassagePlus. :)

  else if ($query = 'getexpandedtitle') then "GetExpandedTitle"
  else if ($query = 'getpassage') then "GetPassage"
  else if ($query = 'expandvalidreffs') then "ExpandValidReffs"
  else if ($query = 'getpassageplus') then "GetPassagePlus"
  else if ($query = 'getcitabletext') then "GetCitableText"
  else if ($query = 'parseurn') then "ParseURN"
  else $e_query

let $reply :=
try
{
  if ($query = 'getcapabilities')
  then ctsx:getCapabilities($e_inv)
  else if ($query = 'getvalidreff')
  then ctsx:getValidReff($e_inv, $e_urn, $e_level)

  else if ($query = 'getexpandedtitle')
  then ctsx:getExpandedTitle($e_inv, $e_urn)
  else if ($query = 'getpassage')
  then ctsx:getPassage($e_inv, $e_urn)
  else if ($query = 'expandvalidreffs')
  then ctsx:expandValidReffs($e_inv, $e_urn, $e_level)
  else if ($query = 'getpassageplus')
  then ctsx:getPassagePlus($e_inv, $e_urn)
  else if ($query = 'getcitabletext')
  then
    if (fn:exists($e_urn) and ctsx:isUnderCopyright($e_inv, $e_urn))
    then
      fn:error(xs:QName("COPYRIGHT"), "Copyright restricted")
    else
      ctsx:getCitableText($e_inv, $e_urn)
  else if ($query = 'parseurn')
  then
    if ($e_urn)
    then
      let $map := mapsutils:put($map, "cts", ctsx:parseUrn($e_inv, $e_urn))
      return map:get($map, "cts")
    else ()
  else
    fn:error(
      xs:QName("INVALID-REQUEST"),
      "Unsupported request: " || $e_query
    )
} catch * {
  console:log($err:description || $err:code || $err:value),
  <CTS:CTSError>
    <message>{ $err:description }</message>
    <value>{ $err:value }</value>
    <code>{ $err:code }</code>
  </CTS:CTSError>
}

let $cts := map:get($map, "cts")
let $response :=
  if (fn:node-name($reply) eq xs:QName("CTS:CTSError"))
  then
    $reply
  else
    element { "CTS:" || $e_query }
    {
      element CTS:request
      {
        attribute elapsed-time { string(seconds-from-duration(util:system-time() - $startTime) * 1000) },
        element CTS:requestName { $e_query },
        element CTS:requestUrn { $e_urn },
        element CTS:psg { xs:string($cts/passage) },
        element CTS:workurn { xs:string($cts/editionUrn) },
        for $gn in $cts/groupname
        return
          element CTS:groupname
          {
            attribute xml:lang { $gn/@xml:lang },
            xs:string($gn)
          },
        for $ti in $cts/title
        return
          element CTS:title
          {
            attribute xml:lang { $ti/@xml:lang },
            xs:string($ti)
          },
        for $la in $cts/label
        return
          element CTS:label
          {
            attribute xml:lang { $la/@xml:lang },
            xs:string($la)
          }
      },
      if ($query =
          (
            "getcapabilities",
            "getcitabletext",
            "getexpandedtitle",
            "getpassage",
            "getvalidreff"
          ))
      then
        $reply
      else
      element CTS:reply
      {
        (: hack to get validating response for ctsx:GetPassagePlus without fixing all the code
           which currently relies on the invalid response  - needs to move in to the cts.xquery
           library
         :)
        if ($query = "getpassageplus")
        then
        (
          element CTS:passage
          {
            element tei:TEI { $reply//*:TEI/* }
          },
          $reply//CTS:prevnext,
          $reply//subref
        )
        else if ($query = "getvalidreff")
        then
          $reply
        else
          $reply/node()
      }
    }

return
  element { fn:name($response) }
  {
    $response/@*,
    $response/*
  }