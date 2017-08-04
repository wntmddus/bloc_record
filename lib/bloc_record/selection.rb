require 'sqlite3'

module Selection
  def find(*ids)
     if ids.length == 1
       find_one(ids.first)
     else
       ids.each do |id|
         unless id.is_a?(Numeric) && id >= 1
           raise ArgumentError.new("ID must be an integer greater than or equal to 1")
         end
       end

       rows = connection.execute <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         WHERE id IN (#{ids.join(",")});
       SQL

       rows_to_array(rows)
     end
   end

  def find_one(id)
    ids.each do |id|
      unless id.is_a?(Numeric) && id >= 1
        raise ArgumentError.new("ID must be an integer greater than or equal to 0")
      end
    end
    row = connection.get_first_row <<-SQL
    SELECT #{columns.join ","} FROM #{table}
    WHERE id = #{id};
    SQL

    init_object_from_row(row)
  end

  def find_by(attribute, value)
    if attribute.is_a?(Symbol)
      attribute = attribute.to_s
    end

    unless attribute.is_a?(String)
      raise ArgumentError.new("Input value must be a string")
    end
    row = connection.get_first_row <<-SQL
     SELECT #{columns.join ","} FROM #{table}
     WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  def find_each(options)
    rows = connection.execute <<-SQL
      SELECT #{column.join(",")} FROM #{table}
      LIMIT #{options[:batch_size]} OFFSET #{options[:start]}
    SQL

    for row in rows_to_array(rows)
      yield row
    end
  end

  def find_in_batches(options)
    rows = connection.execute <<-SQL
      SELECT #{columns.join(",")} FROM #{table}
      LIMIT #{options[:batch_size]} OFFSET #{options[:start]}
    SQL

    yield rows_to_array(rows)
  end

  def take(num=1)
    unless num.is_a?(Numeric) && num >= 1
      raise ArgumentError.new("ID must be an integer greater than or equal to 1")
    end
     if num > 1
       rows = connection.execute <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         ORDER BY random()
         LIMIT #{num};
       SQL

       rows_to_array(rows)
     else
       take_one
     end
  end

  def take_one
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY random()
       LIMIT 1;
     SQL

     init_object_from_row(row)
  end
  def first
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY id
       ASC LIMIT 1;
     SQL

     init_object_from_row(row)
  end

  def last
   row = connection.get_first_row <<-SQL
     SELECT #{columns.join ","} FROM #{table}
     ORDER BY id
     DESC LIMIT 1;
   SQL

   init_object_from_row(row)
  end
  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  private
  def init_object_from_row(row)
  if row
    data = Hash[columns.zip(row)]
    new(data)
  end
  end
  def rows_to_array(rows)
     rows.map { |row| new(Hash[columns.zip(row)]) }
  end
end
