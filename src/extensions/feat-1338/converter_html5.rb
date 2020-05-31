# override the "convert_table" method to add the cell role on the <th> or <td> element.
# remove once https://github.com/asciidoctor/asciidoctor/issues/1338 is fixed.
class Html5Converter < (Asciidoctor::Converter.for 'html5')
  register_for 'html5'

  def convert_table node
    result = []
    id_attribute = node.id ? %( id="#{node.id}") : ''
    classes = ['tableblock', %(frame-#{node.attr 'frame', 'all', 'table-frame'}), %(grid-#{node.attr 'grid', 'all', 'table-grid'})]
    if (stripes = node.attr 'stripes', nil, 'table-stripes')
      classes << %(stripes-#{stripes})
    end
    styles = []
    if (autowidth = node.option? 'autowidth') && !(node.attr? 'width')
      classes << 'fit-content'
    elsif (tablewidth = node.attr 'tablepcwidth') == 100
      classes << 'stretch'
    else
      styles << %(width: #{tablewidth}%;)
    end
    classes << (node.attr 'float') if node.attr? 'float'
    if (role = node.role)
      classes << role
    end
    class_attribute = %( class="#{classes.join ' '}")
    style_attribute = styles.empty? ? '' : %( style="#{styles.join ' '}")

    result << %(<table#{id_attribute}#{class_attribute}#{style_attribute}>)
    result << %(<caption class="title">#{node.captioned_title}</caption>) if node.title?
    if (node.attr 'rowcount') > 0
      slash = @void_element_slash
      result << '<colgroup>'
      if autowidth
        result += (Array.new node.columns.size, %(<col#{slash}>))
      else
        node.columns.each do |col|
          result << ((col.option? 'autowidth') ? %(<col#{slash}>) : %(<col style="width: #{col.attr 'colpcwidth'}%;"#{slash}>))
        end
      end
      result << '</colgroup>'
      node.rows.to_h.each do |tsec, rows|
        next if rows.empty?
        result << %(<t#{tsec}>)
        rows.each do |row|
          result << '<tr>'
          row.each do |cell|
            if tsec == :head
              cell_content = cell.text
            else
              case cell.style
              when :asciidoc
                cell_content = %(<div class="content">#{cell.content}</div>)
              when :literal
                cell_content = %(<div class="literal"><pre>#{cell.text}</pre></div>)
              else
                cell_content = (cell_content = cell.content).empty? ? '' : %(<p class="tableblock">#{cell_content.join '</p>
<p class="tableblock">'}</p>)
              end
            end

            cell_tag_name = (tsec == :head || cell.style == :header ? 'th' : 'td')
            # BEGIN:: patch for issue #1338
            cell_class_attribute = %( class="tableblock halign-#{cell.attr 'halign'} valign-#{cell.attr 'valign'}#{(role = cell.role) ? " #{role}" : ''}")
            # END:: patch for issue #1338
            cell_colspan_attribute = cell.colspan ? %( colspan="#{cell.colspan}") : ''
            cell_rowspan_attribute = cell.rowspan ? %( rowspan="#{cell.rowspan}") : ''
            cell_style_attribute = (node.document.attr? 'cellbgcolor') ? %( style="background-color: #{node.document.attr 'cellbgcolor'};") : ''
            result << %(<#{cell_tag_name}#{cell_class_attribute}#{cell_colspan_attribute}#{cell_rowspan_attribute}#{cell_style_attribute}>#{cell_content}</#{cell_tag_name}>)
          end
          result << '</tr>'
        end
        result << %(</t#{tsec}>)
      end
    end
    result << '</table>'
    result.join LF
  end
end
