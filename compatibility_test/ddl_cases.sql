create database if not exists test;
use test;

# -----------------------------------------------
# Both RENAME KEY and RENAME INDEX variants should be allowed 
# and produce expected results.
#
drop table if exists t1; 
create table t1 (pk int primary key, i int, j int, key a(i));
alter table t1 rename key a to b;
alter table t1 rename index b to c;

# -----------------------------------------------
# It should be impossible to rename index that doesn't exists,
# dropped or added within the same ALTER TABLE.
#
alter table t1 rename key d to e;
alter table t1 drop key c, rename key c to d;
alter table t1 add key d(j), rename key d to e; 

# -----------------------------------------------
# It should be impossible to rename index to a name
# which is already used by another index, or is used
# by index which is added within the same ALTER TABLE.
#
alter table t1 add key d(j);
alter table t1 rename key c to d;
alter table t1 drop key d;
alter table t1 add key d(j), rename key c to d;

# ----------------------------------------------- 
#
# Rename key is handled before add key, so, it would be error because 'key f not exsits'
alter table t1 add key d(j), add unique key e(i), rename key c to d , rename key f to d;

# -----------------------------------------------
# It should be possible to rename index to a name which 
# belongs to index which is dropped within the  same ALTER TABLE.
#
alter table t1 add key d(j);
alter table t1 drop key c, rename key d to c;
drop table t1;

# --------------------------------------------------
# Check that standalone RENAME KEY works as expected
# for unique and non-unique indexes.
#
create table t1 (a int, unique u(a), b int, key k(b));
alter table t1 rename key u to uu;
alter table t1 rename key k to kk;

# --------------------------------------------------
# Check how that this clause can be mixed with other
# clauses which don't affect key or its columns.
#
drop table if exists t2; 
alter table t1 rename key kk to kkk, add column c int;
alter table t1 rename key uu to uuu, add key c(c);
alter table t1 rename key kkk to k, drop key uuu;
alter table t1 rename key k to kk, rename to t2;

# --------------------------------------------------
# Check that this clause properly works even in case
# when it is mixed with clauses affecting columns in
# the key renamed.
#
alter table t2 rename key c to cc, modify column c bigint not null first;
# Create multi-component key for next example.
alter table t2 add unique u (a, b, c);
alter table t2 rename key u to uu, drop column b;
drop table t2;

# -----------------------------------------------
# Test coverage for handling of RENAME INDEX clause in
# various storage engines and using different ALTER algorithm.
#
drop table if exists t1, t2; 
create table t1 (i int, key k(i)) engine=myisam;
insert into t1 values (1);
create table t2 (i int, key k(i)) engine=memory;
insert into t2 values (1);
# MyISAM and Heap should be able to handle key renaming in-place.
alter table t1 rename key k to kk;
alter table t2 rename key k to kk;
# So by default in-place algorithm should be chosen.
alter table t1 rename key kk to kkk;
alter table t2 rename key kk to kkk;
# Copy algorithm should work as well.
alter table t1 algorithm=copy, rename key kkk to kkkk;
alter table t2 algorithm=copy, rename key kkk to kkkk;
# When renaming is combined with other in-place operation
# it still works as expected (i.e. works in-place).
alter table t1 algorithm=inplace, rename key kkkk to k, alter column i set default 100;
alter table t2 algorithm=inplace, rename key kkkk to k, alter column i set default 100;

alter table t1  rename key k to kk, add column j int;
drop table t1, t2;
drop table if exists t1; 
create table t1 (i int, key k(i)) engine=innodb;
insert into t1 values (1);

# Basic rename, inplace algorithm should be chosen
alter table t1 algorithm=inplace, rename key k to kk;

# copy algorithm should work as well.
alter table t1 algorithm=copy, rename key kk to kkk;
drop table t1;


# -----------------------------------------------
# Additional coverage for complex cases in which code
# in ALTER TABLE comparing old and new table version
# got confused.
#
drop table if exists t1; 
create table t1 ( a int, b int, c int, d int,
                  primary key (a), index i1 (b), index i2 (c) ) engine=innodb;
alter table t1 add index i1 (d), rename index i1 to x;
drop table t1;
create table t1 (a int, b int, c int, d int,
                 primary key (a), index i1 (b), index i2 (c)) engine=innodb;
alter table t1 add index i1 (d), rename index i1 to i2, drop index i2;
drop table t1;
create table t1 (i int, key x(i)) engine=InnoDB;
alter table t1 drop key x, add key X(i), alter column i set default 10;
drop table t1;



drop table if exists t1; 
create table t1 (pk int primary key, i int, j int, key a(i));
# -----------------------------------------------
# It should be impossible to modify column that doesn't
# exists, dropped or added within the same ALTER TABLE.
# 
alter table t1 modify z int unsigned;
alter table t1 drop i, modify i int unsigned;
alter table t1 add z int , modify z int unsigned;

# -----------------------------------------------
# It should be impossible to change column  to a name
# which is already used by another column, or used by a column
# is added within the same ALTER TABLE.
#
alter table t1 add k int;
alter table t1 change k i int;
alter table t1 drop k;
alter table t1 add k int, change i  k int unsigned;

# -----------------------------------------------
# Rename key is handled before add key, so, it would be error because 'column l not exsits'
#
alter table t1 add k int, add l int, change i  k int unsigned , change l k int unsigned;

# -----------------------------------------------
# It should be possible to change column to a name which 
# belongs to column which is dropped within the same ALTER TABLE.
#
alter table t1 add k int;
alter table t1 drop j, change k j int;


# -----------------------------------------------
# Test primary key, unique key and normal key
# 
drop table if exists t1;
create table `t1` (
  `id` int(10) unsigned  auto_increment,
  primary key (`id`)
) engine=innodb ;
drop table `t1`;
#
drop table if exists t1;
create table `t1` (
  `name` varchar(255) character set utf8 not null default '',
  `id`  int unsigned not null auto_increment,
  `varchar_var` varchar(255) default null,
  `float_var` float default null,
  `float_var2` float(5,2) default null,
  `json_var` json default null,
  primary key (`id`),
  unique key `idx` (`varchar_var`,`float_var`)
) engine=innodb default charset=gbk;
# test unique key
drop table if exists t1;
create table `t1` (
  `id` int unsigned not null ,
  `my_first` int default null,
  `my_second` int(11) default null,
  `my_third` varchar(255) default null,
  `my_forth` int(11) not null,
  `data` json default null,
  primary key (`id`)
) engine=innodb default charset=utf8mb4;
alter table t1 add unique key (`my_first`,`my_second`,`my_third`), add unique key (`my_second`);
# test primary key;
alter table t1 drop primary key;
alter table t1 add primary key (`my_first`,`my_second`,`my_third`);
# test normal key;
alter table t1 add  key (`my_first`,`my_second`,`my_third`), add  key (`my_second`);

# -----------------------------------------------
# Test all mysql types
# 
drop table if exists t1;
create table t1 (
 tinyint_var tinyint not null ,
 tinyint_var2 tinyint unsigned not null ,
 smallint_var smallint not null ,
 smallint_var2 smallint unsigned not null ,
 mediumint_var mediumint not null ,
 mediumint_var2 mediumint unsigned not null ,
 int_var int not null ,
 int_var2 int unsigned not null ,
 bigint_var bigint not null ,
 bigint_var2 bigint  unsigned not null ,
 tinytext_var tinytext not null ,
 mediumtext_var mediumtext not null ,
 text_var text character set binary not null ,
 longtext_var longtext not null ,
 tinyblob_var tinyblob not null ,
 mediumblob_var mediumblob not null ,
 blob_var blob not null ,
 longblob_var longblob not null ,
 date_var date not null ,
 float_var float not null ,
 double_var double not null ,
 decimal_var decimal(10, 2) not null ,
 datetime_var datetime not null ,
 timestamp_var timestamp not null ,
 time_var time not null ,
 year_var year not null ,
 enum_var enum('1', '2', '3') not null ,
 set_var set('1', '2', '3') not null ,
 bool_var bool not null ,
 char_var char(10) not null ,
 varchar_var varchar(100) not null ,
 binary_var binary(20) not null ,
 varbinary_var varbinary(20) not null,
 primary key(int_var)
) engine=innodb default charset=utf8 ;

# -----------------------------------------------
# Test add column with after clause
# 
drop table if exists t1;
create table t1 (
 col1 int not null auto_increment primary key,
 col2 varchar(30) not null,
 col3 varchar (20) not null,
 col4 varchar(4) not null,
 col5 enum('pending', 'active', 'disabled') not null,
 col6 int not null, to_be_deleted int);

alter table t1
 add column col4_5 varchar(20) not null after col4,
 add column col7 varchar(30) not null after col5,
 add column col8 datetime not null, drop column to_be_deleted,
 change column col2 fourth varchar(30) not null after col3,
 modify column col6 int not null first;
drop table t1;

# -----------------------------------------------
# Test alter table ... enable/disable keys;
# 
create table t1 (n1 int not null, n2 int, n3 int, n4 float,
                unique(n1),
                key (n1, n2, n3, n4),
                key (n2, n3, n4, n1),
                key (n3, n4, n1, n2),
                key (n4, n1, n2, n3) );
alter table t1 disable keys;

drop table if exists t1;
create table t1 (i int unsigned not null auto_increment primary key);
alter table t1 rename t2;
alter table t2 rename t1, add c char(10) comment "no comment";

drop table if exists t1;
create table t1 (
  host varchar(16) binary not null default '',
  user varchar(16) binary not null default '',
  primary key  (host,user),
  key  (host)
) engine=myisam;
alter table t1 disable keys;
alter table t1 enable keys;
drop table t1;

drop table if exists t1;
create table t1 ( a varchar(10) not null primary key ) engine=myisam;
alter table t1 modify a varchar(10);
alter table t1 modify a varchar(10) not null;

# -----------------------------------------------
# Test implict key;
# 
drop table if exists t1;
create table `t1` (
  `id` int(11) not null unique,
  `name` varchar(255) not null unique,
  `age` int(11) default null
) engine=innodb default charset=utf8mb4;
alter table t1 modify `id` int(11);
alter table t1 modify `id` int(11) not null;
alter table t1 add unique key(name);
alter table t1 drop key name;
alter table t1 drop key name_2;
alter table t1 add unique key(name);
alter table t1 modify `name` varchar(255) not null, modify `id` int(11);
alter table t1 add unique key(name);
alter table t1 drop key name;

# -----------------------------------------------
# Test drop and add an auto_increment column;
# 
drop table if exists t1;
create table t1 (i int unsigned not null auto_increment primary key);
alter table t1 drop i,add i int  not null auto_increment, drop primary key, add primary key (i);
drop table t1;

# -----------------------------------------------
# Test convert charset
# 
drop table if exists t1;
create table t1 (a char(10) character set koi8r);
alter table t1 default character set latin1;
#alter table t1 convert to character set latin1;
alter table t1 default character set cp1251;
drop table t1;
# test that table character set does not affect blobs;
drop table if exists t1;
create table t1 (myblob longblob,mytext longtext, myvarchar varchar(255)) default charset latin1 collate latin1_general_cs;
alter table t1 character set latin2;
drop table t1;

# -----------------------------------------------
# 
create table city_demo (city varchar(50) not null);
alter table city_demo add key (city(6));
drop table city_demo;


# -----------------------------------------------
# Test rename table to an existing table
# 
drop table if exists t1, t2;
create table t1 (name char(15));
create table t2 (name char(15));
alter table t1 rename t2;
drop table t1;
drop table t2;

# -----------------------------------------------
# Test rename table cross database
# 
drop table if exists t1;
create table t1 (c1 int);
create database anothertest;

# move table to other database;
alter table t1 rename anothertest.t1;
# assure that it has moved;
drop table t1;
# move table back;
alter table anothertest.t1 rename t1;
# Assure that it is back;
drop table t1;
# Now test for correct message if no database is selected;
create table t1 (c1 int);

use anothertest;
# Drop the current db. This de-selects any db;
drop database anothertest;
# Now test for correct message;
alter table test.t1 rename t1;
# Check that explicit qualifying works even with no selected db;
alter table test.t1 rename test.t1;



# -----------------------------------------------
# Test fulltext key and foreign key
# 
use test;
drop table t1;
#
drop table if exists t1;
create table t1(f1 int);
alter table t1 add column f2 datetime not null, add column f21 date not null;
alter table t1 add column f4 datetime not null default '2002-02-02',
  add column f41 date not null default '2002-02-02';
drop table t1;
#
create table t1 (a varchar(500));
alter table t1 add b text ;
alter table t1 add KEY(b(50));
alter table t1 add d INT;
drop table t1;
#
create table t1 (s char(8) binary);
alter table t1 modify s char(10) binary;
drop table t1;
create table t1 (s binary(8));
alter table t1 modify s binary(10);
drop table t1;
#
drop table if exists ti1, ti2, ti3, tm1, tm2, tm3;
create table ti1(a int not null, b int, c int) engine=innodb;
create table tm1(a int not null, b int, c int) engine=myisam;
create table ti2(a int primary key auto_increment, b int, c int) engine=innodb;
create table tm2(a int primary key auto_increment, b int, c int) engine=myisam;
alter table ti1;
alter table tm1;

alter table ti1 add column d varchar(200);
alter table tm1 add column d varchar(200);
alter table ti1 add column d2 varchar(200);
alter table tm1 add column d2 varchar(200);
alter table ti1 add column e enum('a', 'b') first;
alter table tm1 add column e enum('a', 'b') first;
alter table ti1 add column f int after a;
alter table tm1 add column f int after a;

alter table ti1 add index ii1(b);
alter table tm1 add index im1(b);
alter table ti1 add unique index ii2 (c);
alter table tm1 add unique index im2 (c);
alter table ti1 add fulltext index ii3 (d);
alter table tm1 add fulltext index im3 (d);
alter table ti1 add fulltext index ii4 (d2);
alter table tm1 add fulltext index im4 (d2);

alter table ti1 add primary key(a);
alter table ti1 add primary key(a);
alter table tm1 add primary key(a);

alter table ti1 drop index ii3;
alter table tm1 drop index im3;

alter table ti1 drop column d2;
alter table tm1 drop column d2;

alter table ti1 drop index ii1;
alter table tm1 drop index im1;
alter table ti1 add constraint fi1 foreign key (b) references ti2(a);
alter table tm1 add constraint fm1 foreign key (b) references tm2(a);
alter table tm1 add constraint fm2 foreign key (b) references tm2(a);
# it should fails because fm1 is replace by fm2
alter table tm1 drop index fm1;
alter table ti1 add index (b);
alter table tm1 add index (b);
alter table ti1 drop index fi1;
alter table tm1 drop index fm2;

alter table ti1 alter column b set default 1;
alter table tm1 alter column b set default 1;
alter table ti1 alter column b drop default;
alter table tm1 alter column b drop default;
#drop table ti1, ti2, tm1, tm2;
#
drop table if exists ti1; 
create table ti1(a int primary key auto_increment, b int) engine=innodb;
insert into ti1(b) values (1), (2);
alter table ti1 rename to ti3, add index ii1(b);
alter table ti3 drop index ii1, auto_increment 5;
alter table ti3 add index ii1(b), auto_increment 7;
drop table ti3;
#
drop table if exists t1; 
create table t1(id int, name varchar(200));
alter table t1 add index idx1(name);
alter table t1 add index idx1(id), drop index idx1;
alter table t1 drop name, add index idx1(id);
alter table t1 add name varchar(200);
alter table t1 drop name, add name varchar(300),  add index idx1(id);
alter table t1 add name varchar(200), add name1 varchar(200), drop name, drop name1;
alter table t1 add name varchar(200), drop name, add name varchar(300),  add index idx1(id);
# 
drop table if exists t1, t2; 
create table t1(id int, name varchar(200));
create table t2 like t1;
drop table t1, t3;
drop table t1;
drop table t2;
#
drop table if exists t1; 
create table t1(id int, name varchar(200));
alter table t1 add key name_idx (name);
# it should fails, because name_idx is dropped implicitly
alter table t1 drop name, rename key name_idx to name_idx2;

# -----------------------------------------------
# Test foreign key with sub table and parent table
# 
drop table if exists product_order, product, customer; 
create table product (
    category int not null, id int not null,
    price decimal,
    primary key(category, id)
)   engine=innodb;

create table customer (
    id int not null,
    primary key (id)
)   engine=innodb;

create table product_order (
    no int not null auto_increment,
    product_category int not null,
    product_id int not null,
    customer_id int not null,

    primary key(no),
    index (product_category, product_id),
    index (customer_id),

    foreign key (product_category, product_id)
    references product(category, id),

    foreign key (customer_id)
    references customer(id)
)   engine=innodb;

