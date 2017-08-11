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
        raise ArgumentError.new("ID must be an integer greater than or equal to 1")
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
  def method_missing(name, *args, &block)
    if name.is_a?(Symbol)
      name = name.to_s
    end

    unless name.is_a?(String)
      raise ArgumentError.new("Input value must be a string")
    end
    row = connection.get_first_row <<-SQL
     SELECT #{columns.join ","} FROM #{table}
     WHERE #{name} = #{BlocRecord::Utility.sql_strings(*args)};
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

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
     SELECT #{columns.join ","} FROM #{table}
     WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    orders = []
    args.each do |arg|
      case arg
      when String
        orders << arg
      when Symbol
        orders << arg
      when Hash
        orders << arg.map{ |key, value| "#{key} #{value}" }.join(',')
      end
    end

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order.join(',')};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        key = args.first.keys[0]
        value = args.first.values[0]
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{key} ON #{key}.#{table}_id = #{table}.id
          INNER JOIN #{value} ON #{value}.#{key}_id = #{key}.id
        SQL
      end
    end

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
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end
end
