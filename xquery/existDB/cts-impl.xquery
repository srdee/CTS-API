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

(: Implementation-dependent routines :)

module namespace ctsi = "http://alpheios.net/namespaces/cts-implementation";

declare function ctsi:add-response-header(
  $name as xs:string,
  $value as xs:string
)
{
  xdmp:add-response-header($name, $value)
};

declare function ctsi:get-request-parameter($name as xs:string)
{
  xdmp:get-request-field($name)
};

declare function ctsi:get-request-parameter(
  $name as xs:string,
  $default as xs:string?
)
{
  xdmp:get-request-field($name, $default)
};

declare function ctsi:get-request-body()
{
  xdmp:get-request-body()
};

declare function ctsi:document-store(
  $collection as xs:string?,
  $uri as xs:string,
  $root as node()
)
{
  xdmp:document-insert(
    $uri,
    $root,
    xdmp:default-permissions(),
    (xdmp:default-collections(), $collection)
  )
};

declare function ctsi:http-get($uri as xs:string)
{
  xdmp:http-get($uri)
};

(: wrapper for XSLT call :)
declare function ctsi:xslt-transform(
  $a_input as node()?,
  $a_stylesheet as element(),
  $a_params as element(parameters)
)
{
(: for eXist
  transform:transform($a_input, $a_stylesheet, $a_params)
 :)

  let $map := map:map()
  let $_ :=
    for $param in $a_params/param
    return map:put($map, $param/@name, $param/@value/fn:string())

  return xdmp:xslt-eval($a_stylesheet, $a_input, $map)
};
