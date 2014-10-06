package main

import (
	"bufio"
	"io"
	"regexp"
	"strings"
	"unicode"
	"unicode/utf8"
)

var (
	// matches one or more whitespace characters
	sp = regexp.MustCompile(`[\s]+`)

	// matches and captures characters to remove space between them and words
	assoc = regexp.MustCompile(` ([,.!?:\]\)\}])|([\[\(\{]) | ([-\/]) `)

	// matches duplicate punctuation characters
	punct = regexp.MustCompile(`(\.\.\.|[?!.,"'])[?!.,]*`)

	// cleans up quotation marks
	quot = regexp.MustCompile(`(?:^"| ") (.*?) ?(?:"|$) ?`)
)

type Markov struct {
	db        *DB
	ntok      int
	terminals string
}

// NewMarkov creates a new Markov object to parse new seed text or generate
// phrases from existing stored relations.
func NewMarkov(ntok int, terminals string, db *DB) *Markov {
	if ntok < 1 {
		panic("ntok too small")
	}

	return &Markov{
		db,
		ntok,
		terminals,
	}
}

// Parse parses seed text using a tokenizer that splits text by spaces,
// punctuation, and the given list of terminal characters.
func (m *Markov) Parse(r io.Reader) error {
	s := bufio.NewScanner(r)
	s.Split(scanner(m.terminals))

	tokbuf := make([]string, m.ntok)

	// group this in one big transaction
	tx, err := m.db.Begin()
	if err != nil {
		return err
	}

	for s.Scan() {
		tok := s.Text()

		err = tx.Insert(strings.Join(tokbuf, " "), tok)
		if err != nil {
			tx.Rollback()
			return err
		}

		if strings.Contains(m.terminals, tok) {
			// flush token buffer
			tokbuf = make([]string, m.ntok)
		} else {
			// shift token buffer left 1 and append current token
			copy(tokbuf, tokbuf[1:])
			tokbuf[m.ntok-1] = tok
		}
	}

	// check for parsing errors
	err = s.Err()
	if err != nil {
		tx.Rollback()
		return err
	}

	// commit transaction
	err = tx.Commit()
	if err != nil {
		return err
	}

	return nil
}

func (m *Markov) Generate(mintok int) (string, error) {
	tokbuf := make([]string, m.ntok)
	var buf []string

	// loop until we hit the minimum length, and we end with a terminal
	for !(len(buf) >= mintok && strings.Contains(m.terminals, tokbuf[m.ntok-1])) {
		tok, err := m.db.Next(strings.Join(tokbuf, " "))
		if err != nil {
			return "", err
		}

		buf = append(buf, tok)

		// check for termination of generated phrase
		if strings.Contains(m.terminals, tok) {
			// if the terminating token isn't punctuation, add a period for funsies
			r, _ := utf8.DecodeRuneInString(tok)
			if !unicode.IsPunct(r) {
				buf = append(buf, ".")
			}

			// clear the token buf
			tokbuf = make([]string, m.ntok)
		} else {
			// left shift tokbuf and append current token
			copy(tokbuf, tokbuf[1:])
			tokbuf[m.ntok-1] = tok
		}
	}

	// join buffer into string
	str := strings.Join(buf, " ")

	// replace all whitespace+ with a single space
	str = sp.ReplaceAllLiteralString(str, " ")

	// fix apostrophes, but break single quotes... c'est la vie.
	str = strings.Replace(str, " ' ", "'", -1)

	// remove spaces between certain punctuation and words
	str = assoc.ReplaceAllString(str, "${1}")

	// clean up quotes kinda, attempting to form coherent quotations
	str = quot.ReplaceAllString(str, " \"${1}\" ")

	// strip leading spaces and punctuation
	str = strings.TrimLeft(str, " !?.,")

	// strip trailing spaces
	str = strings.TrimRight(str, " ")

	// clean up punctuation
	str = punct.ReplaceAllString(str, "${1}")

	// fix mismatched quotes
	if strings.Count(str, "\"")%2 != 0 {
		str += "\""
	}

	// clean up parens
	start := 0
	tmp := str
	nlparen := strings.Count(str, "(")
	nrparen := strings.Count(str, ")")
	for nlparen < nrparen {
		idx := strings.Index(tmp, ")")
		idx2 := strings.LastIndex(tmp[:idx], " ") + 1

		str = str[:start+idx2] + "(" + str[start+idx2:]
		start += idx
		nlparen++
		if idx+1 < len(tmp) {
			tmp = tmp[idx+1:]
		}
	}

	for nrparen < nlparen {
		str += ")"
		nrparen++
	}

	return str, nil
}

// Close closes the underlying database connection
func (m *Markov) Close() error {
	return m.db.Close()
}
