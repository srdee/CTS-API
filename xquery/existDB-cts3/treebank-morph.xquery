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
  Extract morphology for treebank word and convert it to lexicon format
 :)

module namespace tbm = "http://alpheios.net/namespaces/treebank-morph";
import module namespace tbu="http://alpheios.net/namespaces/treebank-util"
              at "treebank-util.xquery";

(:
  Function to create element for single morphology category

  Parameters:
    $a_tbd          treebank format description
    $a_name         name of element to create
    $a_category     name of category to use
    $a_tag          postag attribute from treebank

  Return value:
    element with specified name if value from postag is non-empty
    else empty
 :)
declare function tbm:morph-element(
  $a_tbd as element(),
  $a_name as xs:string,
  $a_category as xs:string,
  $a_tag as xs:string) as element()?
{
  let $value := tbu:postag-to-lexicon($a_tbd, $a_category, $a_tag)
  return
  if ($value)
  then
    element { $a_name } { $value }
  else ()
};

(:
  Function to get morphology for word

  Parameters:
    $a_doc         treebank document
    $a_ids         ids of words (in form <sentence#>-<word#>)

  Return value:
    <words> element in lexicon format,
    or <error> element if word not found
 :)
declare function tbm:get-morphology(
  $a_doc as node()?,
  $a_ids as xs:string*) as element()?
{
  (: check arguments :)
  if (not($a_doc)) then element error { "Treebank not specified" } else
  if (count($a_ids) eq 0) then element error { "Word(s) not specified" } else

  let $words :=
    for $id in $a_ids
    let $word :=
      $a_doc//sentence[@id = substring-before($id, "-")]
             /word[@id = substring-after($id, "-")]
    return
    if ($word)
    then
      element wrapper { attribute id { $id }, $word }
    else
      element error { concat("Word ", $id, " not found") }

  (: get treebank format :)
  let $tb := tbu:get-format-name($a_doc, "aldt")
  let $tbDesc := tbu:get-format-description($tb, "/db/xq/config")

  return
  element words
  {
    for $w in $words
    return
    if (local-name($w) eq "wrapper")
    then
      let $word := $w/word
      return
      element word
      {
        attribute id { $w/@id },
        element form
        {
          $word/../@xml:lang,
          text { $word/@form }
        },
        element entry
        {
          element dict
          {
            element hdwd
            {
              $word/../@xml:lang,
              text { $word/@lemma }
            },
            tbm:morph-element($tbDesc, "pofs", "pos", $word/@postag)
          },
          element infl
          {
            tbm:morph-element($tbDesc, "pofs", "pos", $word/@postag),
            tbm:morph-element($tbDesc, "pers", "person", $word/@postag),
            tbm:morph-element($tbDesc, "num", "number", $word/@postag),
            tbm:morph-element($tbDesc, "tense", "tense", $word/@postag),
            tbm:morph-element($tbDesc, "mood", "mood", $word/@postag),
            tbm:morph-element($tbDesc, "voice", "voice", $word/@postag),
            tbm:morph-element($tbDesc, "gend", "gender", $word/@postag),
            tbm:morph-element($tbDesc, "case", "case", $word/@postag),
            tbm:morph-element($tbDesc, "comp", "degree", $word/@postag)
          }
        }
      }
     else $w
  }
};