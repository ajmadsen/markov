package main

import (
	"database/sql"
	"math/rand"
	"time"

	_ "github.com/mxk/go-sqlite/sqlite3"
)

var tables = []string{
	`
		CREATE TABLE IF NOT EXISTS chain (
			id int,
			phrase varchar(4000) NOT NULL,
			next varchar(1000) NOT NULL,
			PRIMARY KEY (id)
		)
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
	db    *sql.DB
	query *sql.Stmt
	count *sql.Stmt
}

type TX struct {
	tx     *sql.Tx
	insert *sql.Stmt
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

	for _, table := range tables {
		_, err = tx.Exec(table)
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

	return &DB{
		db,
		query,
		count,
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

	return &TX{
		tx,
		insert,
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

	rval := rand.Intn(nsel)
	row = db.query.QueryRow(phrase, rval)
	err = row.Scan(&ret)
	if err != nil {
		return "", err
	}

	return ret, nil
}

func (tx *TX) Insert(phrase, next string) error {
	_, err := tx.insert.Exec(phrase, next)
	return err
}

func (tx *TX) Rollback() error {
	return tx.tx.Rollback()
}

func (tx *TX) Commit() error {
	return tx.tx.Commit()
}

func init() {
	rand.Seed(time.Now().UnixNano())
}
