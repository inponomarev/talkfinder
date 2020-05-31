# override the "convert_table" method to add the cell role on the <entry> element.
# remove once https://github.com/asciidoctor/asciidoctor/issues/1338 is fixed.
class DocBook5Converter < (Asciidoctor::Converter.for 'docbook5')
  register_for 'docbook5'

  def convert_table node
    has_body = false
    result = []
    pgwide_attribute = (node.option? 'pgwide') ? ' pgwide="1"' : ''
    if (frame = node.attr 'frame', 'all', 'table-frame') == 'ends'
      frame = 'topbot'
    end
    grid = node.attr 'grid', nil, 'table-grid'
    result << %(<#{tag_name = node.title? ? 'table' : 'informaltable'}#{common_attributes node.id, node.role, node.reftext}#{pgwide_attribute} frame="#{frame}" rowsep="#{['none', 'cols'].include?(grid) ? 0 : 1}" colsep="#{['none', 'rows'].include?(grid) ? 0 : 1}"#{(node.attr? 'orientation', 'landscape', 'table-orientation') ? ' orient="land"' : ''}>)
    if (node.option? 'unbreakable')
      result << '<?dbfo keep-together="always"?>'
    elsif (node.option? 'breakable')
      result << '<?dbfo keep-together="auto"?>'
    end
    result << %(<title>#{node.title}</title>) if tag_name == 'table'
    col_width_key = if (width = (node.attr? 'width') ? (node.attr 'width') : nil)
                      TABLE_PI_NAMES.each do |pi_name|
                        result << %(<?#{pi_name} table-width="#{width}"?>)
                      end
                      'colabswidth'
                    else
                      'colpcwidth'
                    end
    result << %(<tgroup cols="#{node.attr 'colcount'}">)
    node.columns.each do |col|
      result << %(<colspec colname="col_#{col.attr 'colnumber'}" colwidth="#{col.attr col_width_key}*"/>)
    end
    node.rows.to_h.each do |tsec, rows|
      next if rows.empty?
      has_body = true if tsec == :body
      result << %(<t#{tsec}>)
      rows.each do |row|
        result << '<row>'
        row.each do |cell|
          colspan_attribute = cell.colspan ? %( namest="col_#{colnum = cell.column.attr 'colnumber'}" nameend="col_#{colnum + cell.colspan - 1}") : ''
          rowspan_attribute = cell.rowspan ? %( morerows="#{cell.rowspan - 1}") : ''
          # NOTE <entry> may not have whitespace (e.g., line breaks) as a direct descendant according to DocBook rules
          # BEGIN:: patch for issue #1338
          entry_start = %(<entry align="#{cell.attr 'halign'}" valign="#{cell.attr 'valign'}"#{(role = cell.role) ? %( role="#{role}") : ''}#{colspan_attribute}#{rowspan_attribute}>)
          # END:: patch for issue #1338
          if tsec == :head
            cell_content = cell.text
          else
            case cell.style
            when :asciidoc
              cell_content = cell.content
            when :literal
              cell_content = %(<literallayout class="monospaced">#{cell.text}</literallayout>)
            when :header
              cell_content = (cell_content = cell.content).empty? ? '' : %(<simpara><emphasis role="strong">#{cell_content.join '</emphasis></simpara><simpara><emphasis role="strong">'}</emphasis></simpara>)
            else
              cell_content = (cell_content = cell.content).empty? ? '' : %(<simpara>#{cell_content.join '</simpara><simpara>'}</simpara>)
            end
          end
          entry_end = (node.document.attr? 'cellbgcolor') ? %(<?dbfo bgcolor="#{node.document.attr 'cellbgcolor'}"?></entry>) : '</entry>'
          result << %(#{entry_start}#{cell_content}#{entry_end})
        end
        result << '</row>'
      end
      result << %(</t#{tsec}>)
    end
    result << '</tgroup>'
    result << %(</#{tag_name}>)

    logger.warn 'tables must have at least one body row' unless has_body
    result.join LF
  end
end
