package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/docopt/docopt-go"
)

const terminals = ".!?\n"

var usage = `Markov Chains.

Usage:
  markov from (db <db> | file <file>) generate <num> [options]
  markov into <db> parse <file>... [options]
  markov -h | --help
  markov --version

Options:
  -h, --help                  Show this screen.
  --version                   Show the version.
  -m NTOK, --min-tokens NTOK  Minimum number of tokens in generated lines. [default: 20]
  -r RANK, --rank RANK        Rank of markov chain. [default: 2]`

func main() {
	opts, err := docopt.Parse(usage, nil, true, "Markov 0.1", false)
	if err != nil {
		fmt.Println(err)
		return
	}

	switch {
	case opts["from"].(bool):
		generate(opts)
	case opts["into"].(bool):
		parse(opts)
	}
}

func generate(opts map[string]interface{}) {
	mintok, err := strconv.Atoi(opts["--min-tokens"].(string))
	if err != nil {
		fmt.Printf("--min-tokens should be an integer value")
		os.Exit(-1)
	}

	rank, err := strconv.Atoi(opts["--rank"].(string))
	if err != nil {
		fmt.Print("--rank should be an integer value\n")
		os.Exit(-1)
	}

	ngens, err := strconv.Atoi(opts["<num>"].(string))
	if err != nil {
		fmt.Print("<num> should be an integer value\n")
		os.Exit(-1)
	}

	var dbfile string
	if opts["db"].(bool) {
		dbfile = opts["<db>"].(string)
	} else {
		dbfile = ":memory:"
	}

	db, err := OpenDB(dbfile)
	if err != nil {
		fmt.Printf("failed to open database [%s]: %s\n", opts["<db>"], err)
		os.Exit(-1)
	}

	m := NewMarkov(rank, terminals, db)

	if opts["file"].(bool) {
		fnames := opts["<file>"].([]string)
		parseFiles(m, fnames)
	}

	for i := 0; i < ngens; i++ {
		line, err := m.Generate(mintok)
		if err != nil {
			fmt.Printf("error generating from chain: %s\n", err)
			os.Exit(-1)
		}
		fmt.Println(line)
	}
}

func parse(opts map[string]interface{}) {
	rank, err := strconv.Atoi(opts["--rank"].(string))
	if err != nil {
		fmt.Print("--rank should be an integer value\n")
		os.Exit(-1)
	}

	db, err := OpenDB(opts["<db>"].(string))
	if err != nil {
		fmt.Printf("failed to open database [%s]: %s\n", opts["<db>"], err)
		os.Exit(-1)
	}

	m := NewMarkov(rank, terminals, db)

	fnames := opts["<file>"].(string)
	parseFiles(m, []string{fnames})

	err = m.Close()
	if err != nil {
		fmt.Printf("error closing chain: %s\n", err)
	}
}

func parseFiles(m *Markov, fnames []string) {
	files := make([]*os.File, len(fnames))
	for i, fname := range fnames {
		f, err := os.Open(fname)
		if err != nil {
			fmt.Printf("failed to open file [%s]: %s\n", fname, err)
			os.Exit(-1)
		}
		files[i] = f
	}

	for _, file := range files {
		err := m.Parse(file)
		if err != nil {
			fmt.Printf("error parsing file [%s]: %s\n", file.Name(), err)
		}
		file.Close()
	}
}
