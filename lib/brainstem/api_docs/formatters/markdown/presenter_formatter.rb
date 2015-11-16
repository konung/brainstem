require 'active_support/core_ext/string/inflections'
require 'brainstem/api_docs/formatters/abstract_formatter'
require 'brainstem/api_docs/formatters/markdown/helper'

module Brainstem
  module ApiDocs
    module Formatters
      module Markdown
        class PresenterFormatter < AbstractFormatter
          include Helper


          def initialize(presenter, options = {})
            self.presenter = presenter
            self.output    = ""
            super options
          end


          attr_accessor :presenter,
                        :output


          def call
            return output if presenter.nodoc?

            format_title!
            format_brainstem_key!
            format_description!
            format_fields!
            format_filters!
            format_sort_orders!
            format_associations!

            output
          end


          #####################################################################
          private
          #####################################################################

          def format_title!
            output << md_h4(presenter.title)
          end


          def format_brainstem_key!
            output << md_p("Top-level key: #{md_inline_code(presenter.brainstem_key)}")
          end


          def format_description!
            output << md_p(presenter.description) unless presenter.description.empty?
          end


          def format_fields!
            output << md_h5("Fields")

            if presenter.valid_fields.any?
              output << md_ul do
                presenter.valid_fields.values.inject("") do |buffer, field|
                  text = md_inline_code(field.name.to_s)
                  text << " (#{md_inline_code(field.type.to_s.capitalize)})"

                  if field.description || field.options && field.options[:if]
                    text << "\n"
                    text << md_li(field.description, 1) if field.description

                    if field.options[:if]
                      conditions = field.options[:if]
                        .map {|cond| presenter.conditionals[cond].description || "" }
                        .delete_if(&:empty?)
                        .join(" and ")

                      text << md_li("visible when #{conditions}", 1) unless conditions.empty?
                    end

                    text.chomp!
                  end

                  buffer += md_li text
                end
              end
            else
              output << md_p("No fields were listed.")
            end
          end


          def format_filters!
            output << md_h5("Filters")

            if presenter.valid_filters.any?
              output << md_ul do
                presenter.valid_filters.inject("") do |buffer, (name, opts)|
                  text = md_inline_code(name)

                  if opts[:info]
                    text << "\n"
                    text << md_li(opts[:info], 1)
                    text.chomp!
                  end

                  buffer += md_li(text)
                end
              end

            else
              output << "No filters were listed."
            end
          end


          def format_sort_orders!
            output << md_h5("Sort Orders")

            if presenter.valid_sort_orders.any?
              output << md_ul do
                presenter.valid_sort_orders.inject("") do |buffer, (name, opts)|
                  text = "#{md_inline_code(name.to_s)}"

                  if presenter.default_sort_field == name.to_s
                    text += " - #{md_strong("default")} (#{presenter.default_sort_direction})"
                  end

                  if opts[:info]
                    text += "\n" + md_li(opts[:info], 1)
                    text.chomp!
                  end

                  buffer += md_li(text)
                end
              end
            else
              output << md_p("No sort orders were listed.")
            end
          end


          def format_associations!
            output << md_h5("Associations")

            if presenter.valid_associations.any?
              output << md_ul do
                presenter.valid_associations.inject("") do |buffer, (_, association)|
                  text  = md_inline_code(association.name)

                  if association.description && !association.description.empty?
                    text << "\n"
                    text << md_li(association.description, 1)
                    text.chomp!
                  end

                  buffer << md_li(text)
                end
              end
            else
              output << md_p("No associations were listed.")
            end
          end
        end
      end
    end
  end
end

Brainstem::ApiDocs::FORMATTERS[:presenter][:markdown] = \
  Brainstem::ApiDocs::Formatters::Markdown::PresenterFormatter.method(:call)