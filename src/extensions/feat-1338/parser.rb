# override "parse_colspecs" method to use the fifth regular expression group (ie. column roles spec).
# remove once https://github.com/asciidoctor/asciidoctor/issues/1338 is fixed.
module Asciidoctor
  class Parser
    def self.parse_colspecs records
      records = records.delete ' ' if records.include? ' '
      # check for deprecated syntax: single number, equal column spread
      if records == records.to_i.to_s
        return ::Array.new(records.to_i) { {'width' => 1} }
      end

      specs = []
      # NOTE -1 argument ensures we don't drop empty records
      ((records.include? ',') ? (records.split ',', -1) : (records.split ';', -1)).each do |record|
        if record.empty?
          specs << {'width' => 1}
          # TODO might want to use scan rather than this mega-regexp
        elsif (m = ColumnSpecRx.match(record))
          spec = {}
          if m[2]
            # make this an operation
            colspec, rowspec = m[2].split '.'
            if !colspec.nil_or_empty? && TableCellHorzAlignments.key?(colspec)
              spec['halign'] = TableCellHorzAlignments[colspec]
            end
            if !rowspec.nil_or_empty? && TableCellVertAlignments.key?(rowspec)
              spec['valign'] = TableCellVertAlignments[rowspec]
            end
          end

          if (width = m[3])
            # to_i will strip the optional %
            spec['width'] = width == '~' ? -1 : width.to_i
          else
            spec['width'] = 1
          end

          # make this an operation
          if m[4] && TableCellStyles.key?(m[4])
            spec['style'] = TableCellStyles[m[4]]
          end

          # BEGIN:: patch for issue #1338
          if m[5]
            spec['role'] = m[5].split('.').map { |r| r.strip }.reject { |r| r.empty? }.join(' ')
          end
          # END:: patch for issue #1338

          if m[1]
            1.upto(m[1].to_i) { specs << spec.merge }
          else
            specs << spec
          end
        end
      end
      specs
    end

    def self.parse_cellspec(line, pos = :end, delimiter = nil)
      m, rest = nil, ''

      if pos == :start
        if line.include? delimiter
          spec_part, delimiter, rest = line.partition delimiter
          if (m = CellSpecStartRx.match spec_part)
            return [{}, rest] if m[0].empty?
          else
            return [nil, line]
          end
        else
          return [nil, line]
        end
      else # pos == :end
        if (m = CellSpecEndRx.match line)
          # NOTE return the line stripped of trailing whitespace if no cellspec is found in this case
          return [{}, line.rstrip] if m[0].lstrip.empty?
          rest = m.pre_match
        else
          return [{}, line]
        end
      end

      spec = {}
      if m[1]
        colspec, rowspec = m[1].split '.'
        colspec = colspec.nil_or_empty? ? 1 : colspec.to_i
        rowspec = rowspec.nil_or_empty? ? 1 : rowspec.to_i
        if m[2] == '+'
          spec['colspan'] = colspec unless colspec == 1
          spec['rowspan'] = rowspec unless rowspec == 1
        elsif m[2] == '*'
          spec['repeatcol'] = colspec unless colspec == 1
        end
      end

      if m[3]
        colspec, rowspec = m[3].split '.'
        if !colspec.nil_or_empty? && TableCellHorzAlignments.key?(colspec)
          spec['halign'] = TableCellHorzAlignments[colspec]
        end
        if !rowspec.nil_or_empty? && TableCellVertAlignments.key?(rowspec)
          spec['valign'] = TableCellVertAlignments[rowspec]
        end
      end

      if m[4] && TableCellStyles.key?(m[4])
        spec['style'] = TableCellStyles[m[4]]
      end

      # BEGIN:: patch for issue #1338
      if m[5]
        spec['role'] = m[5].split('.').map { |r| r.strip }.reject { |r| r.empty? }.join(' ')
      end
      # END:: patch for issue #1338

      [spec, rest]
    end
  end
end