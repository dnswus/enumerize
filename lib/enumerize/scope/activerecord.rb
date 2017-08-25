module Enumerize
  module Scope
    module ActiveRecord
      def enumerize(name, options={})
        super

        _enumerize_module.dependent_eval do
          if self < ::ActiveRecord::Base
            if options[:scope]
              _define_activerecord_scope_methods!(name, options)
            end
          end
        end
      end

      private

      def _define_activerecord_scope_methods!(name, options)
        scope_name = options[:scope] == true ? "with_#{name}" : options[:scope]

        define_singleton_method scope_name do |*values|
          values = enumerized_attributes[name].find_values(*values).map(&:value)
          values = values.first if values.size == 1

          if options[:multiple]
            where("#{name} && ARRAY[?]::varchar[]", values)
          else
            where(name => values)
          end
        end

        if options[:scope] == true && !options[:multiple]
          define_singleton_method "without_#{name}" do |*values|
            values = enumerized_attributes[name].find_values(*values).map(&:value)
            where(arel_table[name].not_in(values))
          end
        end

        if options[:multiple]
          define_singleton_method "with_all_#{name}" do |*values|
            values = enumerized_attributes[name].find_values(*values).map(&:value)
            values = values.first if values.size == 1

            where("#{name} @> ARRAY[?]::varchar[]", values)
          end
        end
      end
    end
  end
end
