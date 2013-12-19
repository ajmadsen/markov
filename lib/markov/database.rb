require 'sqlite3'

module Markov
  class Database

    SCHEMA = <<-SQL
      CREATE TABLE IF NOT EXISTS `chains` (
        `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
        `name` text NOT NULL UNIQUE,
        `rank` integer NOT NULL
      );

      CREATE TABLE IF NOT EXISTS `words` (
        `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
        `word` text NOT NULL UNIQUE
      );

      CREATE TABLE IF NOT EXISTS `states` (
        `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
        `list` text NOT NULL UNIQUE
      );

      CREATE TABLE IF NOT EXISTS `associations` (
        `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
        `chain_id` integer REFERENCES `chains`(`id`) ON DELETE CASCADE,
        `state_id` integer REFERENCES `states`(`id`),
        `next_state_id` integer REFERENCES `words`(`id`)
      );

      PRAGMA foreign_keys = ON;
    SQL

    def initialize(database)
      @db = SQLite3::Database.new database
      @db.execute_batch SCHEMA

      @select_chain_id = @db.prepare "SELECT `id`,`rank` FROM `chains` WHERE `name` = ? LIMIT 1"
      @select_chains = @db.prepare "SELECT `name`,`rank` FROM `chains`"
      @select_chains_with_records = @db.prepare <<-SQL
        SELECT
          `chains`.`name`,
          `chains`.`rank`,
          (
            SELECT COUNT(*)
            FROM `associations`
            WHERE `chain_id` = `chains`.`id`
          ) AS `associated_records`
        FROM `chains`
      SQL
      @insert_chain = @db.prepare "INSERT INTO `chains`(`name`,`rank`) VALUES(?,?)"
      @delete_chain = @db.prepare "DELETE FROM `chains` WHERE `name` = ?"
      @select_word_id = @db.prepare "SELECT `id` FROM `words` WHERE `word` = ? LIMIT 1"
      @insert_word = @db.prepare "INSERT INTO `words`(`word`) VALUES(?)"
      @select_state_id = @db.prepare "SELECT `id` FROM `states` WHERE `list` = ? LIMIT 1"
      @insert_state = @db.prepare "INSERT INTO `states`(`list`) VALUES(?)"
      @select_associations = @db.prepare <<-SQL
        SELECT `words`.`word`
        FROM `associations` AS `A`
        LEFT JOIN `words`
        ON `words`.`id` = `A`.`next_state_id`
        WHERE `A`.`state_id` = ?
              AND `A`.`chain_id` = ?
      SQL
      @insert_association = @db.prepare "INSERT INTO `associations`(`chain_id`,`state_id`,`next_state_id`) VALUES(?,?,?)"

      @cache = {
        :chain => {},
        :word  => {},
        :state => {},
        :assoc => {}
      }
    end

    def get_chain(name)
      row = @cache[:chain][name]
      return row unless row.nil?
      @select_chain_id.execute name do |result|
        row = result.next
      end
      @cache[:chain][name] = row
    end

    def get_chains(with_records=false)
      stmt = with_records ? @select_chains_with_records : @select_chains
      if block_given?
        stmt.execute do |result|
          r = nil; yield r until (r = result.next).nil?
        end
      else
        stmt.execute!
      end
    end

    def put_chain(name, rank)
      @insert_chain.execute name, rank
      @cache[:chain][[name, rank]] = @db.last_insert_row_id
    end

    def delete_chain(name)
      @delete_chain.execute name
      @db.changes
    end

    def get_word(word)
      row = @cache[:word][word]
      return row unless row.nil?
      @select_word_id.execute word do |result|
        row = result.next
      end
      @cache[:word][word] = row ? row.first : nil
    end

    def put_word(word)
      @insert_word.execute word
      @cache[:word][word] = @db.last_insert_row_id
    end

    def get_state(list)
      row = @cache[:state][list]
      return row unless row.nil?
      @select_state_id.execute list do |result|
        row = result.next
      end
      @cache[:state][list] = row ? row.first : nil
    end

    def put_state(list)
      @insert_state.execute list
      @cache[:state][list] = @db.last_insert_row_id
    end

    def get_associations(chain, state)
      associations = @cache[:assoc][[chain, state]]
      return associations unless associations.nil?
      @select_associations.execute state, chain do |result|
        associations = result.entries.flatten
      end
      @cache[:assoc][[chain, state]] = associations
    end

    def put_association(chain, state, next_state)
      @insert_association.execute chain, state, next_state
      @db.last_insert_row_id
    end

    def transaction
      @db.transaction do |db|
        yield db
      end
    end

    def vacuum
      @db.execute "VACUUM"
    end
  end
end
