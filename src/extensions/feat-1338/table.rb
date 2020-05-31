# override the "initialize" method to inherit roles from the column.
# remove once https://github.com/asciidoctor/asciidoctor/issues/1338 is fixed.
module Asciidoctor
  class Table::Cell < AbstractBlock
    def initialize column, cell_text, attributes = {}, opts = {}
      super column, :table_cell
      @source_location = opts[:cursor].dup if @document.sourcemap
      if column
        cell_style = column.attributes['style'] unless (in_header_row = column.table.header_row?)
        # REVIEW feels hacky to inherit all attributes from column
        update_attributes column.attributes
      end
      # NOTE if attributes is defined, we know this is a psv cell; implies text needs to be stripped
      if attributes
        if attributes.empty?
          @colspan = @rowspan = nil
        else
          # BEGIN:: patch for issue #1338
          if (column_role = column.role)
            role = attributes.delete('role')
            if role
              attributes['role'] = column_role + ' ' + role
            end
          end
          # END:: patch for issue #1338
          @colspan, @rowspan = (attributes.delete 'colspan'), (attributes.delete 'rowspan')
          # TODO delete style attribute from @attributes if set
          cell_style = attributes['style'] || cell_style unless in_header_row
          update_attributes attributes
        end
        if cell_style == :asciidoc
          asciidoc = true
          inner_document_cursor = opts[:cursor]
          if (cell_text = cell_text.rstrip).start_with? LF
            lines_advanced = 1
            lines_advanced += 1 while (cell_text = cell_text.slice 1, cell_text.length).start_with? LF
            # NOTE this only works if we remain in the same file
            inner_document_cursor.advance lines_advanced
          else
            cell_text = cell_text.lstrip
          end
        elsif cell_style == :literal
          literal = true
          cell_text = cell_text.rstrip
          # QUESTION should we use same logic as :asciidoc cell? strip leading space if text doesn't start with newline?
          cell_text = cell_text.slice 1, cell_text.length while cell_text.start_with? LF
        else
          normal_psv = true
          # NOTE AsciidoctorJ uses nil cell_text to create an empty cell
          cell_text = cell_text ? cell_text.strip : ''
        end
      else
        @colspan = @rowspan = nil
        if cell_style == :asciidoc
          asciidoc = true
          inner_document_cursor = opts[:cursor]
        end
      end
      # NOTE only true for non-header rows
      if asciidoc
        # FIXME hide doctitle from nested document; temporary workaround to fix
        # nested document seeing doctitle and assuming it has its own document title
        parent_doctitle = @document.attributes.delete('doctitle')
        # NOTE we need to process the first line of content as it may not have been processed
        # the included content cannot expect to match conditional terminators in the remaining
        # lines of table cell content, it must be self-contained logic
        # QUESTION should we reset cell_text to nil?
        # QUESTION is is faster to check for :: before splitting?
        inner_document_lines = cell_text.split LF, -1
        if (unprocessed_line1 = inner_document_lines[0]).include? '::'
          preprocessed_lines = (PreprocessorReader.new @document, [unprocessed_line1]).readlines
          unless unprocessed_line1 == preprocessed_lines[0] && preprocessed_lines.size < 2
            inner_document_lines.shift
            inner_document_lines.unshift(*preprocessed_lines) unless preprocessed_lines.empty?
          end
        end unless inner_document_lines.empty?
        @inner_document = Document.new inner_document_lines, standalone: false, parent: @document, cursor: inner_document_cursor
        @document.attributes['doctitle'] = parent_doctitle unless parent_doctitle.nil?
        @subs = nil
      elsif literal
        @content_model = :verbatim
        @subs = BASIC_SUBS
      else
        if normal_psv && (cell_text.start_with? '[[') && LeadingInlineAnchorRx =~ cell_text
          Parser.catalog_inline_anchor $1, $2, self, opts[:cursor], @document
        end
        @content_model = :simple
        @subs = NORMAL_SUBS
      end
      @text = cell_text
      @style = cell_style
    end
  end
end