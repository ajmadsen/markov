require 'sequel'

module Markov
  class Chain < Sequel::Model
    plugin :schema
    set_schema do
      primary_key :id
      String      :name, unique: true
      Integer     :rank, null: false, default: 1
    end

    one_to_many   :pairings, eager: [:group, :word]

    create_table if not table_exists?
  end

  class Group < Sequel::Model
    plugin :schema
    set_schema do
      primary_key :id
      String      :list, null: false, unique: true
    end

    many_to_many  :words, join_table: :pairings

    create_table if not table_exists?
  end

  class Word < Sequel::Model
    plugin :schema
    set_schema do
      primary_key :id
      String      :word, null: false, unique: true
    end

    many_to_many  :groups, join_table: :pairings

    create_table if not table_exists?
  end

  class Pairing < Sequel::Model
    plugin :schema
    set_schema do
      primary_key :id
      foreign_key :chain_id, :chains
      foreign_key :group_id, :groups
      foreign_key :word_id,  :words
      Integer     :count, null: false, default: 0
    end

    many_to_one   :chain
    many_to_one   :group
    many_to_one   :word

    create_table if not table_exists?
  end
end
