package main

import (
	"database/sql"
	"log"
	"math/rand"
	"time"

	_ "github.com/mxk/go-sqlite/sqlite3"
)

var initStmts = []string{
	`
		CREATE TABLE IF NOT EXISTS chain (
			id integer NOT NULL,
			phrase varchar(4000) NOT NULL,
			next varchar(1000) NOT NULL,
			PRIMARY KEY (id)
		)
	`,
	`
		CREATE INDEX IF NOT EXISTS ix_chain_phrase
		ON chain(phrase)
	`,
}

const (
	insertStmt = `
		INSERT INTO chain (
			  phrase
			, next
		) VALUES (?,?)
	`
	queryStmt = `
		SELECT next
		FROM chain
		WHERE phrase = ?
		LIMIT 1
		OFFSET ?
	`
	countStmt = `
		SELECT COUNT(*)
		FROM chain
		WHERE phrase = ?
	`
)

type DB struct {
	db     *sql.DB
	query  *sql.Stmt
	count  *sql.Stmt
	insert *sql.Stmt
}

type TX struct {
	tx     *sql.Tx
	insert *sql.Stmt
	db     *DB
}

func OpenDB(filename string) (*DB, error) {
	db, err := sql.Open("sqlite3", filename)
	if err != nil {
		return nil, err
	}

	tx, err := db.Begin()
	if err != nil {
		return nil, err
	}

	for _, stmt := range initStmts {
		_, err = tx.Exec(stmt)
		if err != nil {
			tx.Rollback()
			return nil, err
		}
	}

	err = tx.Commit()
	if err != nil {
		return nil, err
	}

	query, err := db.Prepare(queryStmt)
	if err != nil {
		return nil, err
	}

	count, err := db.Prepare(countStmt)
	if err != nil {
		return nil, err
	}

	insert, err := db.Prepare(insertStmt)
	if err != nil {
		return nil, err
	}

	return &DB{
		db,
		query,
		count,
		insert,
	}, nil
}

func (db *DB) Begin() (*TX, error) {
	tx, err := db.db.Begin()
	if err != nil {
		return nil, err
	}

	insert, err := tx.Prepare(insertStmt)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	_, err = tx.Exec(`
		DROP INDEX IF EXISTS ix_chain_phrase
	`)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	return &TX{
		tx,
		insert,
		db,
	}, nil
}

func (db *DB) Next(phrase string) (string, error) {
	var (
		nsel int
		ret  string
	)

	row := db.count.QueryRow(phrase)
	err := row.Scan(&nsel)
	if err != nil {
		return "", err
	}
	//log.Printf("db: %d choices for phrase: %s", nsel, phrase)

	rval := rand.Intn(nsel)
	row = db.query.QueryRow(phrase, rval)
	err = row.Scan(&ret)
	if err != nil {
		return "", err
	}
	//log.Printf("db: selected [%d]: %s", rval, ret)

	return ret, nil
}

func (db *DB) Insert(phrase, next string) error {
	_, err := db.insert.Exec(phrase, next)
	return err
}

func (db *DB) Close() error {
	db.count.Close()
	db.query.Close()
	return db.db.Close()
}

func (tx *TX) Insert(phrase, next string) error {
	_, err := tx.insert.Exec(phrase, next)
	return err
}

func (tx *TX) Rollback() error {
	log.Print("Rollback!")
	tx.insert.Close()
	return tx.tx.Rollback()
}

func (tx *TX) Commit() error {
	log.Print("Commit!")
	// clean up associated
	tx.insert.Close()

	// rebuild index
	_, err := tx.tx.Exec(`
		CREATE INDEX ix_chain_phrase
		ON chain(phrase)
	`)
	if err != nil {
		return err
	}

	// do actual commit
	log.Print("actual log")
	err = tx.tx.Commit()
	if err != nil {
		return err
	}

	return nil
}

func init() {
	rand.Seed(time.Now().UnixNano())
}
