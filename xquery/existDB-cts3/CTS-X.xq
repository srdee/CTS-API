(:
  Copyright 2012 The Alpheios Project, Ltd.
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
import module namespace cts-x="http://alpheios.net/namespaces/cts-x" 
            at "cts-x.xquery";
import module namespace cts="http://alpheios.net/namespaces/cts" 
            at "cts.xquery";
import module namespace tan  = "http://alpheios.net/namespaces/text-analysis"   
            at "textanalysis-utils.xquery";

let $e_query := request:get-parameter("request",())
let $e_urn :=  request:get-parameter("urn",())
let $e_level := xs:int(request:get-parameter("level","1"))
let $e_uuid := request:get-parameter("xuuid",())
let $e_data := request:get-data() 
let $inv := request:get-parameter("inv","alpheios-cts-inventory")
let $replyNS := "http://alpheios.net/namespaces/cts-x"
let $under_copyright := $e_urn and cts:isUnderCopyright($inv,$e_urn)

let $reply :=
    if ($under_copyright) 
    then
        <reply><error>Copyright Restricted</error></reply>
    else
		if ($e_query = 'CreateCitableText')
	    then cts-x:createCitableText($e_urn,$e_uuid,$e_data)
	    else if ($e_query = 'DeleteCitableText')
	    then cts-x:deleteCitableText($e_urn,$e_uuid)
	    else if ($e_query = 'UpdatePassage')
	    then cts-x:updatePassage($inv,$e_urn,<update>{$e_data}</update>)
	    else if ($e_query = 'PARSEURN')
	    then cts:parseUrn($inv,$e_urn)
	    else if ($e_query = 'LISTURN')
	    then cts-x:getAllOnline($inv)
	     else if ($e_query = 'GETCATALOG')
	    then cts:getCatalog($inv,$e_urn)
	    else(<reply><error code="1">INVALID REQUEST. Unsupported request.</error></reply>)

return
    if ($reply/error)
    then
        element {QName($replyNS, 'CTSXError')} {
            <message>{$reply/error/text()}</message>,
            <code>{$reply/error/@code}</code>,
            $reply/error
        } 
    else 
    element {QName($replyNS, $e_query)} {
        element {QName($replyNS,"request")} {
            element {QName($replyNS,"requestName")} {
                $e_query
            },
            element {QName($replyNS,"requestUrn") } {
                $e_urn
            },
            element {QName($replyNS,"groupname") } {
            }
        },
        element {QName($replyNS,"reply") } {
              $reply/node()            
		}
    }




