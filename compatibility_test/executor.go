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
	"database/sql"
	"fmt"
	"github.com/bytewatch/ddl-executor"
	_ "github.com/go-sql-driver/mysql"
)

type ColumnDef struct {
	Name     string
	Type     string
	Key      string
	Charset  string
	Nullable string
}

type TableDef struct {
	Name    string
	Columns []*ColumnDef
}

type Executor interface {
	Exec(sql string) error
	GetTableDef(database string, name string) (*TableDef, error)
	GetCurrentDatabase() string
}

// This is a executor that use this library to exec ddl
type DdlExecutor struct {
	exector *executor.Executor
}

func NewDdlExecutor(charset string) (*DdlExecutor, error) {
	cfg := executor.Config{
		CharsetServer:       charset,
		LowerCaseTableNames: true,
		NeedAtomic:          false,
	}
	etor := DdlExecutor{
		exector: executor.NewExecutor(&cfg),
	}

	return &etor, nil
}

func (o *DdlExecutor) Exec(sql string) error {
	return o.exector.Exec(sql)
}

func (o *DdlExecutor) GetTableDef(database, table string) (*TableDef, error) {
	t, err := o.exector.GetTableDef(database, table)
	if err != nil {
		return nil, err
	}
	var columns []*ColumnDef
	for _, c := range t.Columns {
		nullable := "YES"
		if !c.Nullable {
			nullable = "NO"
		}
		columnDef := ColumnDef{
			Name:     c.Name,
			Type:     c.Type,
			Nullable: nullable,
			Key:      string(c.Key),
			Charset:  c.Charset,
		}
		columns = append(columns, &columnDef)
	}

	tableDef := TableDef{
		Name:    table,
		Columns: columns,
	}
	return &tableDef, nil
}

func (o *DdlExecutor) GetCurrentDatabase() string {
	return o.exector.GetCurrentDatabase()
}

// This is a executor that use MySQL to exec ddl
type MysqlExecutor struct {
	db *sql.DB
}

func NewMysqlExecutor(host string, port int, user string, passwd string) (*MysqlExecutor, error) {
	connStr := fmt.Sprintf("%s:%s@tcp(%s:%d)/?charset=utf8", user, passwd, host, port)
	db, err := sql.Open("mysql", connStr)
	if err != nil {
		return nil, err
	}
	err = db.Ping()
	if err != nil {
		return nil, err
	}

	etor := MysqlExecutor{
		db: db,
	}

	return &etor, nil
}

func (o *MysqlExecutor) Exec(sql string) error {
	_, err := o.db.Exec(sql)
	if err != nil {
		return err
	}
	return nil
}

func (o *MysqlExecutor) GetTableDef(database, table string) (*TableDef, error) {
	q := fmt.Sprintf("select COLUMN_NAME, COLUMN_TYPE , IS_NULLABLE, COLUMN_KEY, CHARACTER_SET_NAME from INFORMATION_SCHEMA.COLUMNS where table_schema='%s' and table_name='%s' order by ORDINAL_POSITION\n", database, table)
	rows, err := o.db.Query(q)
	if err != nil {
		return nil, err
	}

	var columns []*ColumnDef
	for rows != nil && rows.Next() {

		var name, coltype, nullable, key, charset sql.NullString
		if err := rows.Scan(&name, &coltype, &nullable, &key, &charset); err != nil {
			return nil, err
		}

		columnDef := ColumnDef{
			Name:     name.String,
			Type:     coltype.String,
			Nullable: nullable.String,
			Key:      key.String,
			Charset:  charset.String,
		}
		columns = append(columns, &columnDef)

	}
	if len(columns) == 0 {
		return nil, executor.ErrNoSuchTable.Gen(database, table)
	}

	tableDef := TableDef{
		Name:    table,
		Columns: columns,
	}
	return &tableDef, nil
}

func (o *MysqlExecutor) GetCurrentDatabase() string {
	var database string
	rows := o.db.QueryRow("select database()")
	rows.Scan(&database)
	return database
}
