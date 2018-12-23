// Copyright 2019 ByteWatch All Rights Reserved.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//    http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"bufio"
	"flag"
	"fmt"
	"github.com/pingcap/parser"
	"github.com/pingcap/parser/ast"
	"github.com/pingcap/parser/model"
	_ "github.com/pingcap/tidb/types/parser_driver"
	"io"
	"log"
	"os"
	"strings"
)

var (
	etor Executor
)

func needExec(in ast.Node) bool {
	switch in.(type) {
	case *ast.UseStmt:
		return true

	case *ast.SetStmt:
		return true
	}

	return isDdl(in)
}

func isDdl(in ast.Node) bool {
	switch in.(type) {
	case *ast.CreateDatabaseStmt:
		return true

	case *ast.CreateTableStmt:
		return true

	case *ast.CreateIndexStmt:
		return true

	case *ast.DropDatabaseStmt:
		return true

	case *ast.DropTableStmt:
		return true

	case *ast.DropIndexStmt:
		return true

	case *ast.AlterTableStmt:
		return true

	case *ast.RenameTableStmt:
		return true
	}

	return false

}

func getSqlName(str model.CIStr) string {
	return str.O
}

type TableId struct {
	Database string
	Table    string
}

func genTableId(database, table string) TableId {
	if database == "" {
		database = etor.GetCurrentDatabase()
	}
	return TableId{
		Database: database,
		Table:    table,
	}
}

func getAffectedTable(in ast.Node) (tables []TableId) {
	switch stmt := in.(type) {
	case *ast.CreateDatabaseStmt:

	case *ast.CreateTableStmt:
		databaseName := getSqlName(stmt.Table.Schema)
		tableName := getSqlName(stmt.Table.Name)
		tables = append(tables, genTableId(databaseName, tableName))

	case *ast.CreateIndexStmt:
		databaseName := getSqlName(stmt.Table.Schema)
		tableName := getSqlName(stmt.Table.Name)
		tables = append(tables, genTableId(databaseName, tableName))

	case *ast.DropDatabaseStmt:

	case *ast.DropTableStmt:

	case *ast.DropIndexStmt:
		databaseName := getSqlName(stmt.Table.Schema)
		tableName := getSqlName(stmt.Table.Name)
		tables = append(tables, genTableId(databaseName, tableName))

	case *ast.AlterTableStmt:
		databaseName := getSqlName(stmt.Table.Schema)
		tableName := getSqlName(stmt.Table.Name)
		tables = append(tables, genTableId(databaseName, tableName))

	case *ast.RenameTableStmt:

		newDatabaseName := getSqlName(stmt.NewTable.Schema)
		newTableName := getSqlName(stmt.NewTable.Name)
		tables = append(tables, genTableId(newDatabaseName, newTableName))
	}

	return

}

func main() {
	var executorType string
	var host, user, passwd string
	var port int
	var charset string

	flag.StringVar(&executorType, "type", "lib", "executor type: 'mysql' or 'lib'. 'mysql' means to exec ddl with MySQL, 'lib' means to exec ddl with this library")
	flag.StringVar(&host, "h", "localhost", "the MySQL host")
	flag.IntVar(&port, "P", 3306, "the MySQL port")
	flag.StringVar(&user, "u", "root", "the MySQL user")
	flag.StringVar(&passwd, "p", "", "the MySQL passwd")
	flag.StringVar(&charset, "charset", "", "the charset this library to use. Please set it to MySQL's server charset")
	flag.Parse()

	var err error
	if executorType == "mysql" {
		// Use mysql to execute ddl
		etor, err = NewMysqlExecutor(host, port, user, passwd)
	} else {
		etor, err = NewDdlExecutor(charset)
	}
	if err != nil {
		log.Fatalf("new executor error:%s\n", err)
	}

	sqlParser := parser.New()
	r := os.Stdin
	rb := bufio.NewReaderSize(r, 1024*16)
	sql := ""
	for {
		line, err := rb.ReadString('\n')
		if err == io.EOF {
			break
		} else if err != nil {
			log.Fatalf("read error: %s\n", err)
		}

		// Ignore '\n' on Linux or '\r\n' on Windows
		line = strings.TrimRightFunc(line, func(c rune) bool {
			return c == '\r' || c == '\n'
		})

		lineTrimed := strings.TrimSpace(line)
		if lineTrimed == "" {
			continue
		}
		if lineTrimed[0] == '#' {
			continue
		}
		if lineTrimed[0] == '-' && lineTrimed[1] == '-' {
			continue
		}

		sql = sql + line
		if lineTrimed[len(lineTrimed)-1] != ';' {
			continue
		}

		stmtNodes, err := sqlParser.Parse(sql, "", "")
		if err != nil {
			log.Fatalf("parse error: %s\nsql: %s\n", err, sql)
		}
		for _, stmtNode := range stmtNodes {
			if needExec(stmtNode) {
				fmt.Printf("%s\n", stmtNode.Text())
				err = etor.Exec(sql)
				if err != nil {
					// Print the sql error into stdout
					fmt.Printf("%s\n", err)
				}
				if isDdl(stmtNode) {
					tables := getAffectedTable(stmtNode)
					for _, table := range tables {
						tableDef, err := etor.GetTableDef(table.Database, table.Table)
						if err != nil {
							fmt.Printf("%s\n", err)
							continue
						}
						dumpTableDef(tableDef)

					}
				}
			}
		}
		sql = ""
	}

}

func dumpTableDef(tableDef *TableDef) {
	for _, columnDef := range tableDef.Columns {
		fmt.Printf("%s.%s %s %s %s %s\n",
			tableDef.Name, columnDef.Name, columnDef.Type, columnDef.Key, columnDef.Charset, columnDef.Nullable)
	}
}
