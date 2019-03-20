module FitParser
  class File
    class Data < BinData::Record
      class_attribute :global_message_number, instance_writer: false
      class_attribute :dev_definitions, instance_writer: false

      def self.generate(definition, dev_definitions = nil)
        msg_num = definition.global_message_number.snapshot
        type = Definitions.get_name(msg_num) || "data_record_#{msg_num}"

        Class.new(self) do
          self.global_message_number = msg_num
          self.dev_definitions = dev_definitions

          endian definition.endianness

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def record_type
              :#{type}
            end
          RUBY

          definition.fields_arr.each do |field|
            code = ''
            field_raw_name_sanitized = field.raw_name.gsub('/', '_').gsub('+', '').gsub('%', '').gsub('-', '')

            # in case the field size is a multiple of the field length, we must build an array
            if field.type != 'string' && field.size > field.length
              code << "array :#{field_raw_name_sanitized}, :type => :#{field.type}, :initial_length => #{field.size/field.length}\n"
            else
              # string are not null terminated when they have exactly the lenght of the field
              code << "#{field.type} :#{field_raw_name_sanitized}"
              if field.type == 'string'
                code << ", :read_length => #{field.size}, :trim_padding => true"
              end
              code << "\n"
            end

            code << "def #{field.name}\n"

            if field.scale && field.scale != 1
              scale = field.scale
              if scale.is_a?(Integer)
                code << "scale = #{scale.inspect}.0\n"
              else
                code << "scale = #{scale.inspect}\n"
              end
            else
              code << "scale = nil\n"
            end

            if field.dyn_data
              code << "dyn = #{field.dyn_data}\n"
            else
              code << "dyn = nil\n"
            end
            code << <<-RUBY
                get_value #{field_raw_name_sanitized}.snapshot, '#{field.real_type}', scale, dyn
              end
            RUBY

            class_eval code, __FILE__, __LINE__ + 1
          end

          definition.dev_fields_arr.each do |field|
            next unless dev_definitions
            developer_data = dev_definitions[field[:developer_data_index].to_s]
            next unless developer_data
            data = developer_data[field[:field_number].to_s]
            field.base_type_number = data[:raw_field_2]
            field.name = data[:raw_field_3].downcase.gsub(' ', '_').gsub('.', '').gsub('%', '')
            field.scale = data[:raw_field_6] && data[:raw_field_6] != 255 ? data[:raw_field_6] : nil
            code = ''
            field_raw_name_sanitized = field.raw_name.gsub('/', '_').gsub('+', '').gsub('%', '').gsub('-', '')

            # in case the field size is a multiple of the field length, we must build an array
            if field.type != 'string' && field.field_size > field.length
              code << "array :#{field_raw_name_sanitized}, :type => :#{field.type}, :initial_length => #{field.field_size/field.length}\n"
            else
              # string are not null terminated when they have exactly the lenght of the field
              code << "#{field.type} :#{field_raw_name_sanitized}"
              if field.type == 'string'
                code << ", :read_length => #{field.field_size}, :trim_padding => true"
              end
              code << "\n"
            end

            code << "define_method \"#{field.name}\" do\n"

            if field.scale && field.scale != 1
              scale = field.scale
              if scale.is_a?(Integer)
                code << "scale = #{scale.inspect}.0\n"
              else
                code << "scale = #{scale.inspect}\n"
              end
            else
              code << "scale = nil\n"
            end

            if field.dyn_data
              code << "dyn = #{field.dyn_data}\n"
            else
              code << "dyn = nil\n"
            end

            code << <<-RUBY
                get_value #{field_raw_name_sanitized}.snapshot, '#{field.real_type}', scale, dyn
              end
            RUBY

            class_eval code, __FILE__, __LINE__ + 1
          end

          private

          # return the dynamic value if relevant
          # otherwise, it returns value (scaled if necessary)
          def get_value(raw_value, raw_type, raw_scale, dyn_data)
            val = get_dyn_value(dyn_data, raw_value)
            return val unless val.nil?
            if raw_scale
              if raw_value.is_a? Enumerable
                raw_value.map { |elt| elt / raw_scale }
              else
                raw_value / raw_scale
              end
            else
              get_real_value raw_type, raw_value
            end
          end

          # return the value based on real type
          def get_real_value(real_type, raw_value)
            type = Type.get_type(real_type.to_sym)
            # TODO: manage case where an array is returned
            type ? type.value(raw_value) : raw_value
          end

          def get_dyn_value(dyn_data, raw_value)
            return nil if dyn_data.nil?
            dyn_data.each do |key, dyn|
              # make sure method exist before calling send (all fields are not always defined)
              if respond_to?("raw_#{dyn[:ref_field_name]}") && dyn[:ref_field_values].include?(send("raw_#{dyn[:ref_field_name]}"))
                return get_real_value(dyn[:type], raw_value)
              end
            end
            nil
          end
        end
      end
    end
  end
end
