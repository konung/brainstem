require 'active_support/hash_with_indifferent_access'
require 'forwardable'

# A hash-like object that accepts a parent configuration object that defers to
# the parent in the absence of one of its own keys (thus simulating inheritance).
module Brainstem
  module DSL
    class Configuration
      extend Forwardable

      # Returns a new configuration object.
      #
      # @params [Object] parent_configuration The parent configuration object
      #   which the new configuration object should use as a base.
      def initialize(parent_configuration = nil)
        @parent_configuration  = parent_configuration || ActiveSupport::HashWithIndifferentAccess.new
        @storage               = ActiveSupport::HashWithIndifferentAccess.new

        self.nonheritable_keys =
          parent_configuration.respond_to?(:nonheritable_keys) &&
          parent_configuration.nonheritable_keys ||
          []
      end

      def [](key)
        get!(key)
      end

      def []=(key, value)
        existing_value = get!(key)
        if existing_value.is_a?(Configuration)
          raise 'You cannot override a nested value'
        elsif existing_value.is_a?(InheritableAppendSet)
          raise 'You cannot override an inheritable array once set'
        else
          @storage[key] = value
        end
      end

      def nest!(key)
        get!(key)
        @storage[key] ||= Configuration.new
      end

      def array!(key)
        get!(key)
        @storage[key] ||= InheritableAppendSet.new
      end


      #
      # Marks a key in the configuration as nonheritable, which means that it:
      #
      # - will appear in the list of keys for this object;
      # - will return as set when fetched from this object;
      # - will return in the +to_h+ output from this object;
      # - will be included when iterating with +#each+ from this object;
      #
      # - will not appear in the list of keys for any child object;
      # - will return +nil+ when fetched from any child object;
      # - will not return in the +#to_h+ output from any child object;
      # - will not be included when iterating with +#each+ from any child object.
      #
      # @param [Symbol,String] key the key to append to the list of nonheritable
      #   keys
      #
      def nonheritable!(key)
        key = key.to_s
        self.nonheritable_keys << key unless self.nonheritable_keys.include?(key)
      end


      attr_accessor :nonheritable_keys


      #
      # Returns the keys in this configuration object that are visible to child
      # configuration objects (i.e. heritable keys).
      #
      # @return [Array] keys
      #
      def keys_visible_to_children
        keys - nonheritable_keys
      end


      #
      # Returns a hash of this object's storage, less those pairs that are
      # not visible to children.
      #
      # @return [Hash] the hash, less nonheritable pairs.
      #
      def pairs_visible_to_children
        to_h.reject {|k, v| !keys_visible_to_children.include?(k.to_s) }
      end


      #
      # Returns the union of all keys in this configuration plus those that are
      # heritable in the parent.
      #
      # @return [Array] keys
      #
      def keys
        if @parent_configuration.respond_to?(:keys_visible_to_children)
          @parent_configuration.keys_visible_to_children | @storage.keys
        else
          @parent_configuration.keys | @storage.keys
        end
      end


      #
      # Returns a list of nonheritable keys for the parent configuration, if
      # the parent configuration actually keeps track of it. Otherwise returns
      # an empty array.
      #
      # @return [Array<String>] the list of nonheritable keys in the
      #   parent configuration.
      #
      def parent_nonheritable_keys
        if @parent_configuration.respond_to?(:nonheritable_keys)
          @parent_configuration.nonheritable_keys
        else
          []
        end
      end


      #
      # Returns whether a key is nonheritable in this configuration object's
      # parent configuration.
      #
      # Is of arity -1 so it can be easily passed to methods that yield
      # either a key, or a key/value tuple.
      #
      # @param [Symbol,String] key the key to check for nonheritability.
      #
      def key_nonheritable_in_parent?(*key)
        parent_nonheritable_keys.include?(key.first.to_s)
      end


      #
      # An inversion of +key_nonheritable_in_parent+. Returns true if the
      # key is not marked as nonheritable in the parent configuration.
      #
      # Is of arity -1 so it can be easily passed to methods that yield
      # either a key, or a key/value tuple.
      #
      # @param [Symbol,String] key the key to check for heritability.
      #
      def key_inheritable_in_parent?(*key)
        !key_nonheritable_in_parent?(key.first.to_s)
      end


      #
      # Returns a hash of this object's storage merged over the heritable pairs
      # of its parent configurations.
      #
      # @return [Hash] the merged hash
      #
      def to_h
        if @parent_configuration.respond_to?(:pairs_visible_to_children)
          @parent_configuration.pairs_visible_to_children.merge(@storage)
        else
          @parent_configuration.to_h.merge(@storage)
        end
      end


      #
      # Returns the value for the given key, or if it could not be found:
      #   - Raises a +KeyError+ if not passed a default or a block;
      #   - Returns the default if it is passed a default but no block;
      #   - Calls and returns the block if passed a block but no default;
      #   - Calls the block with the default and returns the block if passed a
      #       default and a block.
      #
      # @params [Symbol,String] key the key to look up
      # @params [Object] default the default to return
      # @params [Proc] block the block to call
      #
      # @see http://ruby-doc.org/core-2.2.1/Hash.html#method-i-fetch
      #
      def fetch(key, default = nil, &block)
        val = get!(key)
        return val if val

        if default && !block_given?
          default
        elsif block_given?
          default ? block.call(default) : block.call
        else
          raise KeyError
        end
      end


      def has_key?(key)
        @storage.has_key?(key) ||
          (@parent_configuration.has_key?(key) &&
           key_inheritable_in_parent?(key))
      end

      def length
        keys.length
      end

      def each
        keys.each do |key|
          yield key, get!(key)
        end
      end

      delegate :empty? => :keys

      private

      # @api private
      #
      # Retrieves the value stored at key.
      #
      # - If +key+ is already defined, it returns that;
      # - If +key+ in the parent is marked as nonheritable, it returns
      #   +nil+;
      # - If +key+ in the parent is a +Configuration+, returns a new
      #   +Configuration+ with the parent set;
      # - If +key+ in the parent is an +InheritableAppendSet+, returns a new
      #   +InheritableAppendSet+ with the parent set;
      # - Elsewise returns the parent configuration's value for the key.
      #
      def get!(key)
        @storage[key] || begin
          if key_nonheritable_in_parent?(key)
            nil
          elsif @parent_configuration[key].is_a?(Configuration)
            @storage[key] = Configuration.new(@parent_configuration[key])
          elsif @parent_configuration[key].is_a?(InheritableAppendSet)
            @storage[key] = InheritableAppendSet.new(@parent_configuration[key])
          else
            @parent_configuration[key]
          end
        end
      end

      # An Array-like object that provides `push`, `concat`, `each`, `empty?`, and `to_a` methods that act the combination
      # of its own entries and those of a parent InheritableAppendSet, if present.
      class InheritableAppendSet
        extend Forwardable

        def initialize(parent_array = nil)
          @parent_array = parent_array || []
          @storage = []
        end

        def push(item)
          @storage.push item
        end
        alias_method :<<, :push

        def concat(items)
          @storage.concat items
        end

        def to_a
          @parent_array.to_a + @storage
        end

        delegate [:each, :empty?] => :to_a
      end
    end
  end
end
