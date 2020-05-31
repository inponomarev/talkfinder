# override the regular expressions to add capture columns and cells roles spec.
# remove once https://github.com/asciidoctor/asciidoctor/issues/1338 is fixed.
module Asciidoctor
  module Rx; end
  # BEGIN:: patch for issue #1338
  $VERBOSE = nil # silence warnings: "warning: already initialized constant"
  ColumnSpecRx = /^(?:(\d+)\*)?([<^>](?:\.[<^>]?)?|(?:[<^>]?\.)?[<^>])?(\d+%?|~)?([a-z])?(?:\[(#{CC_ANY}+)\])?$/
  CellSpecStartRx = /^[ \t]*(?:(\d+(?:\.\d*)?|(?:\d*\.)?\d+)([*+]))?([<^>](?:\.[<^>]?)?|(?:[<^>]?\.)?[<^>])?([a-z])?(?:\[(#{CC_ANY}+)\])?$/
  CellSpecEndRx = /[ \t]+(?:(\d+(?:\.\d*)?|(?:\d*\.)?\d+)([*+]))?([<^>](?:\.[<^>]?)?|(?:[<^>]?\.)?[<^>])?([a-z])?(?:\[(#{CC_ANY}+)\])?$/
  # END:: patch for issue #1338
end