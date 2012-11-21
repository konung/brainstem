require 'date'

module ApiPresenter
  class Base

    TIME_CLASSES = [Time]
    begin
      require 'active_support/time_with_zone'
      TIME_CLASSES << ActiveSupport::TimeWithZone
    rescue LoadError
    end

    class FieldProxy
      attr_reader :method_name

      def initialize(method_name = nil, options = {}, &block)
        if block_given?
          @block = block
        elsif method_name
          @method_name = method_name
        else
          raise ArgumentError, "Method name or block is required"
        end
      end

      def call(model)
        @block ? @block.call : model.send(@method_name)
      end
    end

    class AssociationField < FieldProxy
      attr_reader :association_name, :json_name

      def initialize(*)
        @json_name, @association_name = options[:json_name], options[:association_name]
        super(*)
      end
    end

    class OptionalField < FieldProxy; end

    class << self
      def presents(*klasses)
        ApiPresenter.add_presenter_class(self, *klasses)
      end

      def default_sort_order(sort_string = nil)
        if sort_string
          @default_sort_order = sort_string
        else
          @default_sort_order
        end
      end

      def sort_order(name, order = nil, &block)
        @sort_orders ||= {}
        @sort_orders[name] = (block_given? ? block : order)
      end

      def sort_orders
        @sort_orders
      end

      def filter(name, options = {}, &block)
        @filters ||= {}
        @filters[name] = [options, block]
      end

      def filters
        @filters
      end

      def helper(mod)
        include mod
        extend mod
      end
    end

    def default_sort_order
      self.class.default_sort_order
    end

    def sort_orders
      self.class.sort_orders
    end

    def filters
      self.class.filters
    end

    def present(model)
      raise "Please override #present(model) in your subclass of ApiPresenter::Base"
    end

    def present_and_post_process(model, fields = [], associations = [])
      post_process(present(model), model, fields, associations)
    end

    def post_process(struct, model, fields = [], associations = [])
      load_associations!(model, struct, associations)
      load_optional_fields!(model, struct, fields)
      struct = dates_to_strings(struct)
      datetimes_to_epoch(struct)
    end

    def group_present(models, fields = [], associations = [])
      custom_preload models, fields, associations

      models.map do |model|
        present_and_post_process model, fields, associations
      end
    end

    def custom_preload(models, fields = [], associations = [])
      # Subclasses can overload this if they wish.
    end

    def datetimes_to_epoch(struct)
      case struct
      when Array
        struct.map { |value| datetimes_to_epoch value }
      when Hash
        struct.inject({}) { |memo, (k, v)| memo[k] = datetimes_to_epoch v; memo }
      when *TIME_CLASSES # Time, ActiveSupport::TimeWithZone
        struct.to_i
      else
        struct
      end
    end

    def dates_to_strings(struct)
      case struct
        when Array
          struct.map { |value| dates_to_strings value }
        when Hash
          struct.inject({}) { |memo, (k, v)| memo[k] = dates_to_strings v; memo }
        when Date
          struct.strftime('%F')
        else
          struct
      end
    end

    def load_optional_fields!(model, struct, fields)
      struct.to_a.each do |key, value|
        if value.is_a?(OptionalField)
          if fields.include?(key)
            struct[key] = value.call(model)
          else
            struct.delete key
          end
        end
      end
    end

    def load_associations!(model, struct, associations)
      struct.to_a.each do |key, value|
        if value.is_a?(AssociationField)
          struct.delete key
          id_attr = value.method_name ? "#{value.method_name}_id" : nil
          if id_attr && model.class.columns_hash.has_key?(id_attr)
            struct["#{key}_id".to_sym] = model.send(id_attr)
          elsif associations.include?(key)
            result = value.call(model)
            if result.is_a?(Array)
              struct["#{key.to_s.singularize}_ids".to_sym] = result.map {|a| a.is_a?(ActiveRecord::Base) ? a.id : a }
            else
              if result.is_a?(ActiveRecord::Base)
                struct["#{key.to_s.singularize}_id".to_sym] = result.id
              else
                struct["#{key.to_s.singularize}_id".to_sym] = result
              end
            end
          end
        end
      end
    end

    def association(method_name = nil, &block)
      AssociationField.new method_name, &block
    end

    def optional_field(field_name = nil, &block)
      OptionalField.new field_name, &block
    end
  end
end