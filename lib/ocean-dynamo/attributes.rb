module OceanDynamo
  module Attributes

    def self.included(base)
      base.extend(ClassMethods)
    end
  

    # ---------------------------------------------------------
    #
    #  Class methods
    #
    # ---------------------------------------------------------

    module ClassMethods

      def dynamo_schema(table_hash_key=:id, 
                        table_range_key=nil,
                        locking: :lock_version,
                        timestamps: [:created_at, :updated_at],
                        **keywords,
                        &block)
        self.lock_attribute = locking
        self.timestamp_attributes = timestamps
        # Init
        self.fields = HashWithIndifferentAccess.new
        attribute(table_hash_key, :string, default: "")
        self.global_secondary_indexes = Hash.new
        if table_range_key
          attribute(table_range_key, :string, default: "")
          self.validates(table_range_key, presence: true)
        end
        timestamp_attributes.each { |name| attribute name, :datetime } if timestamp_attributes
        attribute(lock_attribute, :integer, default: 0) if locking
        block.call
        # Define attribute accessors
        fields.each { |name, md| define_attribute_accessors(name) }
        # Return table name
        super
      end

    end


    # ---------------------------------------------------------
    #
    #  Instance variables and methods
    #
    # ---------------------------------------------------------

    #
    # The hash of attributes and their values. Keys are strings.
    #
    attr_reader :attributes

    attr_reader :destroyed      # :nodoc:
    attr_reader :new_record     # :nodoc:


    def initialize(attrs={})
      @attributes = Hash.new
      fields.each do |name, md| 
        write_attribute(name, evaluate_default(md[:default], md[:type]))
      end
      raise UnknownPrimaryKey unless table_hash_key
      set_belongs_to_association(attrs)
      # Barf on unknown attributes here?
      attrs && attrs.delete_if { |k, v| !fields.has_key?(k) }
      super(attrs)
      yield self if block_given?
    end


    #
    # Returns the value of the hash key attribute
    #
    def hash_key
      read_attribute(table_hash_key)
    end


    #
    # Returns the value of the range key attribute or false if the
    # table doesn't have a range_key.
    #
    def range_key
      table_range_key && read_attribute(table_range_key)
    end


    def [](attribute)
      read_attribute attribute
    end


    def []=(attribute, value)
      write_attribute attribute, value
    end


    def id
      hash_key
    end


    def id=(value)
      write_attribute(table_hash_key, value)
    end


    def id?
      hash_key.present?
    end


    def read_attribute_for_validation(key)
      @attributes[key.to_s]
    end


    def read_attribute(attr_name)
      attr_name = attr_name.to_s
      attr_name = table_hash_key.to_s if attr_name == 'id'
      if fields.has_key?(attr_name)
        @attributes[attr_name]
      else
        raise ActiveModel::MissingAttributeError, "can't read unknown attribute '#{attr_name}"
      end
    end


    def write_attribute(attr_name, value)
      attr_name = attr_name.to_s
      attr_name = table_hash_key.to_s if attr_name == 'id'
      if fields.has_key?(attr_name)
        @attributes[attr_name] = type_cast_attribute_for_write(attr_name, value)
      else
        raise ActiveModel::MissingAttributeError, "can't write unknown attribute '#{attr_name}'"
      end
    end


    def to_key
      return nil unless persisted?
      key = respond_to?(:id) && id
      return nil unless key
      table_range_key ? [key, range_key] : [key]
    end


    def assign_attributes(values, without_protection: false)
      return if values.blank?
      values = values.stringify_keys
      set_belongs_to_association(values)
      # if values.respond_to?(:permitted?)
      #   unless values.permitted?
      #     raise ActiveModel::ForbiddenAttributesError
      #   end
      # end
      values.each { |k, v| _assign_attribute(k, v) }
    end


    def type_cast_attribute_for_write(name, value, metadata=fields[name],
                                      type: metadata[:type])
      case type
      when :reference
        return value
      when :string
        return nil if value == nil
        return value.collect(&:to_s) if value.is_a?(Array)
        value
      when :integer
        return nil if value == nil || value == false || value.is_a?(String) && value.blank?
        return value.collect(&:to_i) if value.is_a?(Array)
        value.to_i
      when :float
        return nil if value == nil || value == false || value.is_a?(String) && value.blank?
        return value.collect(&:to_f) if value.is_a?(Array)
        value.to_f
      when :boolean
        return nil if value == nil
        return true if value == true
        return true if value == "true"
        false
      when :datetime
        return value.to_time(:utc) if value.is_a?(String)
        return nil if value == nil || !value.kind_of?(Time)
        value
      when :serialized
        return nil if value == nil
        value
      else
        raise UnsupportedType.new(type.to_s)
      end
    end


    private

    def _assign_attribute(k, v) # :nodoc:
      public_send("#{k}=", v)
    rescue NoMethodError
      if respond_to?("#{k}=")
        raise
      else
        raise UnknownAttributeError, "unknown attribute: '#{k}'"
      end
    end


    protected

    def evaluate_default(default, type) # :nodoc:
      return default.call if default.is_a?(Proc)
      return "" if default == nil && type == :string
      return default.clone if default.is_a?(Array) || default.is_a?(String)   # Instances need their own copies
      default
    end

  end
end
