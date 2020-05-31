require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

# remove once https://github.com/asciidoctor/asciidoctor/pull/3532 is merged.
Extensions.register do
  tree_processor do
    process do |doc|
      doc.find_by(context: :table, traverse_documents: true).each do |table|
        hrows = table.attr('hrows')
        if hrows
          rows = table.rows
          move_rows = [hrows.to_i - rows.head.size, rows.body.size].min
          if move_rows > 0
            rows.head.push(*rows.body.slice!(0, move_rows))
          end
        end
      end
    end
  end
end
